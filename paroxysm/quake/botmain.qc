/*
POXbots - by Frank Condello (for the Paroxysm Deathmatch Mod)
pox@planetquake.com - http://www.planetquake.com/paroxysm/

This is a modified version of the Tutor Bot by Darryl "Coffee" Atchison (see below)

The Roaming, Targeting and Fighting AI are essentially the same as the original with some changes
and additions - most changes are related to Fighting - bots use all of the Paroxysm weapons (except the bonesaw),
including second triggers (except mines and shrapnelbombs)

Bots have a set of personality variables set when spawned (botprefs) that can
dramatically alter the bots success during a game. Bots have attack types (rush,
retreat, smart-(combination attack types)) favorite weapons, alertness, accuracy, health awareness,
reaction speed, etc..

These variables are set randomly at spawn so you can get a variety of bot skill levels in a game.
I may make these user-configurable in the future (they are currently semi-configurable via skill level).

The most notable change is the addition of true item usage. A seperate file (botgrab.qc)
contains all the code necessary to determine items and define their usage. POXbots do not start with a random weapon.
They all start with the tShot and must find and grab other weapons.
Heath is used as well as Megahealth (with rot). Bots also understand how to use the new sheild generators
and pick up ammo and backpacks. Bots now check for items during combat and roaming so any accidental
item touches are registered. Bots have 'smart' item seeking based on prefs and needs (eg. low health, no weapon).

The naming function has been re-written - no duplicate bot names are allowed and their is a limit
of 8 bots per game - Skins are chosen at random (only two skins right now).

Some other changes:
- Bots die quicker in liquids and have better liquid avoidance
- smater jumping - step/ramp recognition (needs work)
- footstep sound (just like players)
- dead bot bodies remain (CARNAGE!)
- replaced the landing thud sound with a null wav file (the thud gets anoying)
- numerous little 'fixes' -- I may have broke some stuff to begin with ;)

I've commented the changes made with the prefix: POX-

Here's the original Tutor Bot Header...
NOTE: these install instructions WILL NOT WORK with these modified files!

---------------------------------------------------------------------------

		T U T O R   B O T



		Author:		Darryl "Coffee" Atchison
					coffee@planetquake.com

		Website:		http://www.planetquake.com/minion/tutorial/main.htm
					http://www.planetquake.com

		Version:		1.0
					1.10.99
				



		I n s t r u c t i o n s

		Yes, you heard correctly, this one file acts as an almost-
	fully-functional bot. You can plug him into deathmatch patches and
	mods. Or you can read his tutorials and customize him.
		Here's what to do.


	1. Open up the PROGS.SRC file, and insert the words "tutor.qc"
		without quotes after the words "misc.qc" 


	2. Open up the file CLIENT.QC and scroll down to ClientObituary().
		You'll see an early line looking like this:		

		if (targ.classname == "player")

	Change it to this:

		if (targ.classname == "player" || targ.classname == "bot")
	
	About 20 lines down, you see this line:

		if (attacker.classname == "player")

	Change it to this:

		if (attacker.classname == "player" || attacker.classname == "bot")


	3. Open up WEAPONS.QC and add this line to the top of the file:

		void(float teem) create_bot;

	Then, down below, add these lines to ImpulseCommands():

		if (self.impulse == 100)
			create_bot(1);
		if (self.impulse == 101)
			create_bot(2);


	4. Compile as you normally would and enjoy.


---------------------------------------------------------------------------
*/

/*
==========================================================================
==========================================================================
==========================================================================

	Section 1: AI

	Don't let this part worry you. Basically it's just walking and
	running thoughts. He'll check around himself for items, use
	movetogoal() to navigation, then grab his goal when he's close
	enough. He always looks for enemy bots and players. In addition,
	he must manually check for water, lava, and gaps in front of him.
	Remember, though, he's made to be simple, not smart.

==========================================================================
==========================================================================
==========================================================================
*/


// declaring the routines before they are called
void() bot_jump1;
void() respawn_bot;
void() bot_check_ammo;
float() bot_bestweapon;
void() bot_set_currentammo;

void() bot_regen1;					//POX - Regen Animation (stand)
.float regenstop;						//POX - Holds the armour station's max armour count
.entity		lastgoalentity;			//POX- saves last goal target so any item touched on the way can be picked up
.float	bot_step_finished;		//POX - footstep sound timeout
.float	bot_needs_item;		//POX - TRUE or FALSE - retreat and go for item
.float	needs_search_time;	//POX - Bots will give up on a needed item after about 3 seconds if under attack


//POX - BotPrefs
.float	botpref_health;					//how soon a bot looks for health
.float	botpref_aim	;						//average quality of aim
.float	botpref_weapon;					//Prefered best weapon (Plasma Gun or Anihilator)
.float	botpref_attack;					//lean toward RUSH , RETREAT, or SMART attack styles
//.float	botpref_camp;					//determines if a bot is a camper or not (TRUE or FALSE)
.float	botpref_react;						//Time delay between seeing enemy and firing
.float	botpref_aware;					//Determines whether or not a bot will 'see' you even if you're not infront of him
//.float	botpref_goof;						//Bots can make mistakes too (missfire)
.float	botpref_speed;					//How fast the bot moves and reacts overall
.float	bot_speed;							//Holds the next think time

//POX Attack style constants
float		AS_RUSH = 1;
float		AS_RETREAT = 2;
float		AS_SMART = 0;

void() bot_attack;


//POX- new Function - made this found target because Id's had a LOT of stuff in there just for monsters
//POX - This also supports new AI - item search during combat (bot_search_for_needed)
void() bot_FoundTarget =
{	

//Bot gave up on item
	if (self.needs_search_time < time)
		self.bot_needs_item = FALSE;
	
//Bot is trying to get an item
	if (self.bot_needs_item)
	{
		//bprint("bot_needs overides new target\n");
		return;
	}
	else
	{
		self.goalentity = self.enemy;
		//bprint("Enemy found\n");
	
		self.think = self.th_run;
		self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
		self.nextthink = time + self.botpref_react;
	}
};

//POX- New Function - Footsteps - called when moving on solid ground
void() bot_footstep =
{
	local float r;
	
	if (self.bot_step_finished > time)
		return;
	
	//No footsteps under water
	//I didn't bother checking the water level here, but it should be accurate enough
	if (self.waterlevel)
		return;
				
	r = random();
	if (r < 0.25)
			sound (self, CHAN_AUTO, "misc/foot1.wav", 0.3, ATTN_NORM);
	else if (r < 0.5)
		sound (self, CHAN_AUTO, "misc/foot2.wav", 0.3, ATTN_NORM);
	else if (r < 0.75)
		sound (self, CHAN_AUTO, "misc/foot3.wav", 0.3, ATTN_NORM);
	else
		sound (self, CHAN_AUTO, "misc/foot4.wav", 0.3, ATTN_NORM);
		
	self.bot_step_finished = time + self.botpref_speed + 0.2;
		
};

//POX - new item search routine - called during combat if taking a beating
//Only look for health or a better weapon
// ------------------------------------------------
void() bot_search_for_needed =
// ------------------------------------------------
{
local entity item;
local float	n;

// already found something
if (self.goalentity.flags & FL_ITEM)
	return;

// checks a radius around him for items - shorter radius
	item = findradius(self.origin, 1200);

//POX- Bot prefers health, then weapons during combat - Will not search for anything else
	while(item)
		{
		if ( (item.flags & FL_ITEM) && visible(item) && item.model != string_null)
			{
				if ((item.healtype == 2) || (item.touch == powerup_touch)) // MegaHealth or powerup
					n = 1;
				else if (self.health < self.botpref_health  && item.healamount)
					n = 1;
				else if ((item.touch == weapon_touch) && (self.weapon == IT_TSHOT) && (bot_has_weapon(item)))
					n = 1;
				else
					n = 0;
				
				if (n)
				{
					self.search_time = time + 20;
					self.goalentity = item;
					self.bot_needs_item = TRUE;
					self.needs_search_time = time + 3 + random();
					
					/*TESTING
					bprint(self.netname);
					bprint(" needs that ");
					bprint(item.netname);
					bprint("\n");
					return;
					*/
				}
			
			}
		item = item.chain;
		}

};

// ------------------------------------------------
void() bot_search_for_items =
// ------------------------------------------------
{
local entity item;

//POX - don't search if a needed item is spotted
	if (self.bot_needs_item == TRUE)
		return;
	
//POX - Don't stray if going for a regen station
	if (self.goalentity.armregen || self.regenstop)
		return;

// he gives up on that item and marks it to avoid it for a while
	if (time > self.search_time && self.goalentity != world)
		{
		self.goalentity.search_time = time + 30;
		self.goalentity = world;
		}

	if (self.goalentity != world)
		return;

//POX - I made the bots check a larger radius and not check for visibility (helps them roam?)

// checks a radius around him for items
	item = findradius(self.origin, 2500);

//POX- Bot prefers health, then weapons, then ammo (depends on health & weapon status & bot prefs)
	while(item)
		{
		if ( (item.flags & FL_ITEM) && item.model != string_null && time > item.search_time)
			{
				if (self.health < self.botpref_health && !item.healamount)
					item = item.chain;
				else if (self.weapon == IT_TSHOT && !item.weapon)
					item = item.chain;
				else if (self.items & item.items)
					item = item.chain;
				else if ( !item.aflag || (item.aflag && bot_max_ammo(item)) )
					item = item.chain;
				else
					{
						self.search_time = time + 10;
						self.goalentity = item;
					}
				}
		item = item.chain;
		}

};

/*
POX-
Lots of additions here....see botgrab.qc
Bots now only start with the tShot and PulseGun (like real players) and must find a better weapon
Bots look for stuff more often, and use most items Weapons, health, ammo, and backpacks are all used
Armour stations are used as well as MegaHealth, which and rots like player's.
All powerups are used (except for the BioSuit, even though they can pick it up)
*/

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_grab_items =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
local	float		bnew;
local	float		bold;
// sees if he's close enough to pick that item up

	if (self.goalentity == world)
		return;
	
	//POX - not close enough so go away
	if (!(vlen(self.origin - self.goalentity.origin) <= 70))
		return;
	
	//POX - touching a player can null him out (?)
	//POX - This was an early problem and this check is probably nolonger necessary due to increased item discrimination
	if (!(self.goalentity.flags & FL_ITEM))
		return;
	
	//POX - Shouldn't happen but...
	if (self.goalentity.model == string_null)
		{
			self.goalentity = world;
			self.bot_needs_item = FALSE;
			return;
		}
	
	//POX - If Bot Health is maxed out and target is a health pack, leave it alone - except for MegaHealth
	if (self.goalentity.healamount	&&  self.health >= self.max_health && self.goalentity.healtype != 2)
	{
		self.bot_needs_item = FALSE;
		self.goalentity = world;
		return;
	}
	
	
	//POX- Already have weapon so leave it
	if	(self.goalentity.touch == weapon_touch && bot_has_weapon(self.goalentity))
	{
		self.bot_needs_item = FALSE;
		self.goalentity.search_time = time + 20;
		self.goalentity = world;
		return; 
	}
	
	//POX- Already has max ammo so leave it
	if	(self.goalentity.classname == "ammo" && bot_max_ammo(self.goalentity))
	{
		self.bot_needs_item = FALSE;
		self.goalentity.search_time = time + 20;
		self.goalentity = world;
		return; 
	}
	
	//POX- Backpack Pick up - Does not re-spawn
	if (vlen(self.origin - self.goalentity.origin) <= 70 && self.goalentity.classname == "pack")
	{
		sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
		self.ammo_shells = self.ammo_shells + self.goalentity.ammo_shells;
		self.ammo_nails = self.ammo_nails + self.goalentity.ammo_nails;
		self.ammo_rockets = self.ammo_rockets + self.goalentity.ammo_rockets;
		self.ammo_cells = self.ammo_cells + self.goalentity.ammo_cells;
		
		bound_bot_ammo();
		
		bnew = self.goalentity.items;
		
		if (!bnew)
			bnew = self.weapon;
		
		bold = self.items;
		self.items = self.items | bnew;
		
		//POX - Packs contain health in FFA mode, so check for it here
		if (self.goalentity.healamount)
			bot_grab_health();
			
		remove(self.goalentity);
		self.goalentity = world;
		self.bot_needs_item = FALSE; //POX - Reset this even if the target wasn't picked up (the Bot should find it again quickly)			
		return;
	}

	//Pick up a re-spawn item
	if (vlen(self.origin - self.goalentity.origin) <= 70)
	{
		self.goalentity.search_time = time + 60;
		self.goalentity.solid = SOLID_NOT;
		self.goalentity.model = string_null;
		
		//POX - Needed for the dual model Quad hack
		if (self.goalentity.classname == "item_artifact_super_damage")
		{
			self.goalentity.quadcore.mdl = self.quadcore.model;
			self.goalentity.quadcore.model = string_null;
		}
		
		//POX - Turn off the powerup's 'glow'
		if (self.goalentity.classname == "item_artifact_super_damage" || self.goalentity.classname == "item_artifact_invulnerability" || self.goalentity.classname == "item_artifact_invisibility")
			self.goalentity.effects = self.goalentity.effects - (self.goalentity.effects & EF_DIMLIGHT);
			
		//POX - respawn times vary for powerups
		if (self.goalentity.touch == powerup_touch)
		{	
			if ((self.goalentity.classname == "item_artifact_invulnerability") || (self.goalentity.classname == "item_artifact_invisibility"))
				self.goalentity.nextthink = time + 75;
			else
				self.goalentity.nextthink = time + 60;
		}
		else //POX regular respawn
			self.goalentity.nextthink = time + 30;
		
		self.goalentity.think = SUB_regen;
		
		//POX-Health Pack (botgrab.qc)
		if (self.goalentity.healamount)
			bot_grab_health();
		
		//POX-Weapons (botgrab.qc)
		else if (self.goalentity.touch == weapon_touch)
			bot_grab_weapon();
		
		//POX-Ammo (botgrab.qc)
		else if (self.goalentity.classname == "ammo")
			bot_grab_ammo();
		
		//POX - Powerups - Quad, Cloak & MegaSheilds (botgrab.qc)
		else if (self.goalentity.touch == powerup_touch)
			bot_grab_powerup();
		
				
	//POX- If a bot was looking for something during combat, get him to chase his enemy again
	if (self.enemy)
	{
		self.goalentity = self.enemy;	
		//bprint("enemy is now goal\n");
	}
	else
		self.goalentity = world;
		
	self.bot_needs_item = FALSE; //POX - Reset this even if the target was picked up (the Bot should find it again quickly)
	}
	
};

/*
POX- new Function
Added for better item support
Bots are forced to grab stuff that's close to them (if they need it)
*/

.float close_time;

// -----------------------------------------
void() bot_check_close =
// -----------------------------------------
{

local entity item;

//POX - Don't stray if going for or standing at regen station
	if (self.goalentity.armregen)
		return;

//check a small radius
	item = findradius(self.origin, 300);

	while(item)
		{
		if ( (item.flags & FL_ITEM) && visible(item) && item.model != string_null)
			{
				//Don't go for health if healthy, only MegaHealth
				if (item.healamount && self.health >= self.max_health && item.healtype !=2)
					item = item.chain;
				//Don't go for a weapon if already in inventory
				else if ((item.touch == weapon_touch) && (bot_has_weapon(item)))
					item = item.chain;
				//Don't go for ammo if already maxed out
				else if (item.aflag && bot_max_ammo(item))
					item = item.chain;	
				else
				{
					//save old target, target new item, try to grab the item then revert to old target
					self.lastgoalentity = self.goalentity;
					self.goalentity = item;
					
					//give'm a little nudge in the right direction
					movetogoal(1);
					
					bot_grab_items();
					
					//Keep switching goals just in case it's an enemy
					self.goalentity = self.lastgoalentity;
				}
			}
		item = item.chain;
		}

};

/*
POX- new Function
Added for better item support
NOT REALLY A TOUCH FUNCTION!!
This is called during combat and roaming so bots can pick up stuff they accidentally 'touch'
There is no item discrimination here (it's checked in bot_grab_items)
*/
// -----------------------------------------
void() bot_check_touch =
// -----------------------------------------
{

local entity item;

//check a small radius (touch distance)
	item = findradius(self.origin, 70);

	while(item)
		{
		if ( (item.flags & FL_ITEM) && item.model != string_null)
			{
					//save old target, target new item, grab the item then revert to old target
					self.lastgoalentity = self.goalentity;
					self.goalentity = item;
					bot_grab_items();
					self.goalentity = self.lastgoalentity;				
			}
		item = item.chain;
		}

};


/*
POX- new Function
Bots select an attack based on prefs and enemy's weapon
Returns TRUE if enemy has a better weapon.
This function also doubles as an Attack Style Selection based on botprefs
*/
// -----------------------------------------
float() better_weapon =
// -----------------------------------------
{
local	float		sweap = 0;
local	float		eweap = 0;
	
	
	//Attack Style - Rush
	if (self.botpref_attack == AS_RUSH && random() > 0.02)
		return FALSE;
	
	//Attack Style - Retreat
	if (self.botpref_attack == AS_RETREAT && random() > 0.02)
		return TRUE;
	
	//Can't fake out a bot by running around with an empty Anihilator
	if (self.enemy.currentammo < 1)
		return FALSE;	
	
	//Smart Attack
	if (self.weapon == IT_TSHOT)
		sweap = 1;
	if (self.weapon == IT_SUPER_NAILGUN)
		sweap = 2;
	if (self.weapon == IT_GRENADE_LAUNCHER)
		sweap = 3;
	if (self.weapon == IT_PLASMAGUN)
		sweap = 4;
	if (self.weapon == IT_COMBOGUN)
		sweap = 5;
	if (self.weapon == IT_ROCKET_LAUNCHER)
		sweap = 6;
		
	if (self.enemy.weapon == IT_TSHOT || self.enemy.weapon == IT_BONESAW)
		eweap = 0;
	if (self.enemy.weapon == IT_SUPER_NAILGUN)
		eweap = 2;
	if (self.enemy.weapon == IT_GRENADE_LAUNCHER)
		eweap = 3;
	if (self.enemy.weapon == IT_PLASMAGUN)
		eweap = 4;
	if (self.enemy.weapon == IT_COMBOGUN)
		eweap = 5;
	if (self.enemy.weapon == IT_ROCKET_LAUNCHER)
		eweap = 6;
	
	//if enemy is a bot and has an equal strength weapon, do a reatreat attack (this will tend to spread out fighting bots - needs work)
	if (eweap == sweap && self.enemy.classname == "bot")
		return TRUE;
	//if enemy weapon is better, do retreat attack
	else if (eweap > sweap)
		return TRUE;
	//Bot's weapon is better so chase enemy
	else
		return FALSE;

};

// --------------------------------
void() bot_run_slide =
// --------------------------------
{
local float	ofs;
	
// this is a cool strafing routine

	if (self.lefty)
		ofs = 90;
	else
		ofs = -90;

	makevectors(self.angles);
	if (walkmove (self.angles_y + ofs, 20))
		{
		if (ofs == -90)
			{
			makevectors(self.angles);
			self.flags = self.flags - (self.flags & FL_ONGROUND);
			self.velocity = self.velocity + v_right * 300;
			}
		else
			{
			makevectors(self.angles);
			self.flags = self.flags - (self.flags & FL_ONGROUND);
			self.velocity = self.velocity + v_right * -300;
			}
		return;
		}

	self.lefty = 1 - self.lefty;

	walkmove (self.angles_y - ofs, 20);

		if (ofs == -90)
			{
			makevectors(self.angles);
			self.flags = self.flags - (self.flags & FL_ONGROUND);
			self.velocity = self.velocity + v_right * 300;
			}
		else
			{
			makevectors(self.angles);
			self.flags = self.flags - (self.flags & FL_ONGROUND);
			self.velocity = self.velocity + v_right * -300;
			}
};

// ----------------------
void() bot_ai_back=
// ----------------------
{
	makevectors(self.angles);
	if (pointcontents(self.origin + v_forward*36 + '0 0 36') == CONTENT_SOLID || pointcontents(self.origin + v_forward*22 + '0 0 36') == CONTENT_SOLID)
		bot_run_slide();
	else
	{
		self.flags = self.flags - (self.flags & FL_ONGROUND);
		self.velocity = v_forward*-460;
	}
};

// -----------------------------------------
void() jump_forward =
// -----------------------------------------
{

// propels him into the air

	if (!(self.flags & FL_ONGROUND))
		return;

	self.flags = self.flags - (self.flags & FL_ONGROUND);
	makevectors(self.angles);
	
	self.velocity = self.velocity + (v_forward * 220);
	self.velocity_z = self.velocity_z + 220;

};

//POX - I've incorporated norse_waterlevel for liquid detection (see botliq.qc)
//POX - These guys still suck hard when it comes to liquids (can't swim), I try to kill them quickly
// ------------------------------------------------
void() check_for_water =
// ------------------------------------------------
{
	self.waterlevel = norse_waterlevel(self);
	
	//POX - No liquid detected
	if (self.waterlevel == 0)
		return;
	
	//POX - Water detected below head so don't bother
	if (self.waterlevel < 2 && self.watertype2 == CONTENT_WATER)
		return; 
	
	//POX - water above head
	if (self.waterlevel > 2 && self.watertype2 == CONTENT_WATER && time > self.pain_finished)
		{
		T_Damage (self, world, world, 8);
		self.pain_finished = time + 0.8;
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM);
		}
		
	//POX - Slime - anywhere
	if (self.watertype2 == CONTENT_SLIME && time > self.pain_finished)
		{
		T_Damage (self, world, world, self.waterlevel*15);
		self.pain_finished = time + 0.2;
		sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		}
		
	//POX - Lava - anywhere
	if (self.watertype2 == CONTENT_LAVA && time > self.pain_finished)
		{
		T_Damage (self, world, world, self.waterlevel*35);
		self.pain_finished = time + 0.05;
		sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		}

	self.flags = self.flags - (self.flags & FL_ONGROUND);
	
//POX - Give'm an extra boost if in deep
	if (self.waterlevel > 2)
		self.velocity_z = self.velocity_z + 40;

// he'll try to swim upward here
	self.velocity = self.velocity + (v_forward * 140);
	self.velocity_z = self.velocity_z + 180;
	if (random() < 0.4)
		self.velocity_x = self.velocity_x + 90;
	else if (random() > 0.8)
		self.velocity_y = self.velocity_y + 90;

};


//POX - Bots will avoid jumping into liquids
//POX - This still needs LOTS of work, broken ground over liquids confuses these guys (DM4 is a good example)
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() check_for_ledge =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
local vector	spot, spot2, look;
local float	n;

// movetogoal() will never move over a legde, so we have to 
// check for a break in front of him and force him to jump
	
	n = 30;
	
	if (random() < 0.4)
		return;

	if (!(self.flags & FL_ONGROUND))
		return;
	
	makevectors (self.angles);
	spot = self.origin + (v_forward * 60);
	spot = spot - '0 0 35';
	
	//POX - check closer for a step
	spot2 = self.origin + (v_forward * 40);
	spot2 = spot2 - '0 0 35';

	look = spot - '0 0 8';
	
	//particle (spot2 +  '0 0 24', '0 0 0', 500, 5);	//TESTING
	//particle (spot2 -  '0 0 24', '0 0 0', 500, 5);	//TESTING
	
	//POX - Don't bother to check for liquid if solid ground is ahead (or a step up/down)
	if (pointcontents(spot) == CONTENT_SOLID || pointcontents(spot2 + '0 0 24') == CONTENT_SOLID || pointcontents(spot2 - '0 0 24') == CONTENT_SOLID)
		return;
	
	//FIXME!
	//POX - Check for a gap (not big enough to fall through)
	//if (pointcontents(spot + '24 0 0') == CONTENT_SOLID)
	//	return;
	
	//POX - check for liquid at a series of depths
	while (n > 0)
	{

		if (pointcontents(look) == CONTENT_LAVA || pointcontents(look) == CONTENT_SLIME) 
		{		
				n = -1;
				self.angles_y = self.angles_y + self.button1; //POX - Turn 90
				return;
		}
		else if (pointcontents(look) == CONTENT_WATER)
		{		
				n = -1;
				self.angles_y = self.angles_y  + self.button1; //POX - Turn 90
				return;
		}
		
		//POX - Found a ledge so jump
		else if (pointcontents(look) == CONTENT_SOLID)
		{	
			n = -1;
		}
				
		//particle (liq, '0 0 0', 500, 5); //TESTING
		
		look = look - '0 0 8';
		n = n - 1;
		
	}
	

//POX - Double Check (do I need this?)
if (pointcontents(spot) == CONTENT_EMPTY)
	bot_jump1();



};



// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
float() bot_look_for_players =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
	local entity	client;
	local float		r;

// this is just like id's FindTarget(), he's looking for clients

//POX - If a bot is beating on another bot, decide if he'll stay on that target or turn to a client
//Higher skill bots will usually choose the client (skill 3 always choose client) - ya it's dirty fight'n
if (self.enemy.classname == "bot" && random() * 3 > skill)
	return FALSE;

	client = checkclient ();
	if (!client)
		return FALSE;


	if (teamplay)
		if (self.team == client.team)
			return FALSE;

	if (client.classname == "KasCam")
		return FALSE;

	if (client == self.enemy)
		return FALSE;

	if (client.flags & FL_NOTARGET)
		return FALSE;
		
	//POX - bots may not notice invisible players
	if (client.items & IT_INVISIBILITY && random() > 0.4)
		return FALSE;

	r = range (client);
	if (r == RANGE_FAR)
		return FALSE;
		
	if (!visible (client))
		return FALSE;

	if (r == RANGE_NEAR && self.botpref_aware == FALSE)
	{
		if (client.show_hostile < time && !infront (client))
			return FALSE;
	}

	else if (r == RANGE_MID)
	{
		if ((!infront (client)) && (random() < 0.8))
			return FALSE;
	}
	
	self.enemy = client;
	
	bot_FoundTarget ();

	return TRUE;
};



// ------------------------------------------------
void() bot_look_for_bots =
// ------------------------------------------------
{
local entity found, foe;

// bots aren't clients, so we have to check fo them manually
// we just see if any of the bots in the entity list are visible
 
	if (self.enemy)
		return;

	found = world;
	foe = find(world, classname, "bot");

	while(foe)
		{
		if (visible(foe) && foe != self && foe.health > 0) 
			found = foe;
		if (teamplay && found.team == self.team)
			found = world;
		if ((foe.items & IT_INVISIBILITY) && (random() < 0.4)) //POX - check for invisibility
			found = world;
		foe = find(foe, classname, "bot");
		}
	
	if (found != world)
		{
			self.enemy = found;
			bot_FoundTarget ();	
		}
};


// ----------------------
void() bot_face =
// ----------------------
{
// this turns him directly toward his enemy

	self.angles_y = vectoyaw(self.enemy.origin - self.origin);
};

/*
POX - New Regen Station Functions
If a bot is happy with his weapons and health, he'll go for armour
These three functions work together, first he'll target a nearby station,
when reached, he'll stand at it until he's maxed out or an enemy is spotted
*/
.float	lastarmorvalue;		//POX- A hacky fix for bots not standing close enough to a regen station
	
//POX - This is very similar to bot_stand, the rules for walking again are slightly different
// -----------------------------------------
void() bot_regen =
// -----------------------------------------
{
local float	turn;
	
	BotCheckPowerups (self);
		
//POX - Force a turn if facing a wall
//POX - I could probably make this neater by using a traceline...
	makevectors(self.angles);

		if (pointcontents(self.origin + v_forward*20) == CONTENT_SOLID)
		turn = TRUE;
	else if (pointcontents(self.origin + v_forward*36) == CONTENT_SOLID)
		turn = TRUE;
	else if (pointcontents(self.origin + v_forward*52) == CONTENT_SOLID)
		turn = TRUE;
	else if (pointcontents(self.origin + v_forward*68) == CONTENT_SOLID)
		turn = TRUE;
	else
		turn = FALSE;
		
	bot_look_for_bots();
	bot_look_for_players();

//Armour maxed out (for current station)
	if (self.armorvalue >= self.regenstop)
	{
		self.regenstop = 0;
		self.goalentity = world;
		self.think = self.th_walk;
		return;
	}
	
// do a cute little turn
//POX - Added wall detection so bots don't stare at walls when standing/camping (needs work)
	if (random() < 0.1 || turn == TRUE)
		self.angles_y = self.angles_y - 45;
	else if (random() > 0.9)
		self.angles_y = self.angles_y + 15;

//POX - HACK! - bots standing still don't trigger touch (?) so this will move'em *slightly* side to side (not noticeable)
//POX - Due to this hack, bots will regen slower than real clients so their armour is incremented by 2 at each think (in shields.qc)
	walkmove (self.angles_y + 90, 2);	
	walkmove (self.angles_y - 90, 2);
	
//POX - sometimes a bot won't stand close enough to a  regen station.
//POX - This checks if the armour is actually increasing after standing for 2 second
//POX - THIS DOESN'T ALWAYS WORK (?) - Hence the next check
		if (self.lastarmorvalue == self.armorvalue && self.pausetime < time - 6)
			self.regenstop = 0;

//POX - spawning over a regen station that's near a weapon can mess these guys up so I forced a move after 8 seconds
		if (self.pausetime < time)
			self.regenstop = 0;
			
	
	self.nextthink = time + 0.05;

};


// -----------------------------------------
void() bot_regen_touch =
// -----------------------------------------
{

local entity regen;

//check a  VERY small radius since they must 'physically' touch regen triggers
	regen = findradius(self.origin, 20);

	while(regen)
		{
		if (regen.armregen > self.armorvalue)
			{
					//Touching a regen station with better armor value
					self.regenstop = regen.armregen;
					self.lastarmorvalue = self.armorvalue;
					self.pausetime = time + 8;
					bot_regen1();
			}
		regen = regen.chain;
		}

};


// -----------------------------------------
void() bot_regen_find =
// -----------------------------------------
{

local entity regen;

	regen = findradius(self.origin, 800);

	while(regen)
		{
		if (regen.armregen > self.armorvalue && visible(regen))
			{
					//Found a regen station with better count than current armour
					self.goalentity = regen;
					movetogoal(1); //nudge'em
			}
		regen = regen.chain;
		}

};


// ----------------------
void() bot_stand =
// ----------------------
{
local float	turn;
local entity	item;

// POX - This is called in the bot's main functions - not as accurate as player's per-frame check but it's good enough 
	
//POX - Check DM rules so a bot can end a game at max frags
	CheckRules ();
	
	BotCheckPowerups (self);
	
//POX - Force a turn if facing a wall (needs work)
	makevectors(self.angles);

	if (pointcontents(self.origin + v_forward*20) == CONTENT_SOLID)
		turn = TRUE;
	else if (pointcontents(self.origin + v_forward*36) == CONTENT_SOLID)
		turn = TRUE;
	else if (pointcontents(self.origin + v_forward*52) == CONTENT_SOLID)
		turn = TRUE;
	else if (pointcontents(self.origin + v_forward*68) == CONTENT_SOLID)
		turn = TRUE;
	else
		turn = FALSE;
	
// do a cute little turn
	if (random() < 0.1 || turn == TRUE)
		self.angles_y = self.angles_y - 45;
	else if (random() > 0.9)
		self.angles_y = self.angles_y + 15;	

//POX - stand still if on plat, if not check for other stuff
//POX - Bot Plat detection is more like Plat Bot detection
//POX - Plats know when a bot is on them, and set on_moveplat to time + 1frame when moving, it's a little hacky but  it	 really works well
	if (self.on_moveplat > time)
		return;
	
	bot_look_for_bots();
	bot_look_for_players();
	check_for_water();
	
//POX - accidental item touch - It could happen at item/bot respawn
	bot_check_touch();
	
//POX - If an item is close by, go into walk / search mode
	item = findradius(self.origin, 400);
	
	while(item)
		{
			if ( (item.flags & FL_ITEM) && item.model != string_null)
				self.think = self.th_walk;
			item = item.chain;
		}

//POX - Don't stand around if Health is low
	if (self.health < self.botpref_health)
	{
		self.think = self.th_walk;
		return;
	}

//POX - Don't stand around if best weapon is tShot
	if (self.weapon == IT_TSHOT)
	{
		self.think = self.th_walk;
		return;
	}

	if (time > self.pausetime)
	{
		self.think = self.th_walk;
		return;
	}
	
	
	self.nextthink = time + 0.05;

};


// ******************************
void() coffee_move =
// ******************************
{

//POX - Platform recognition - only checked during roaming, if fighting, he'll keep doing his attack dance
if (self.on_moveplat > time)
	self.think = self.th_stand;

// this is the best subroutine i've ever written, and probably the
// most powerful bot roaming function. i hope you credit me if you use
// it. basically he strafes along a wall, then turns at a 45 or -45
// degree angle at the wall's corner. i have seen my bots do laps
// around entire levels with these three lines of code
	
	if (walkmove (self.angles_y, 20) == FALSE)
	{
		if (walkmove (self.angles_y + self.button1, 20) == FALSE)
			self.angles_y = self.angles_y + (self.button1 / 2);
	}
	
//POX - This reduces the facing-the-wall-strafe by turning away from the wall
//POX - This checks above the head for a wall (so steps will work) - some barriers will still be strafe-navigated
	makevectors(self.angles);

//POX - the random call is there so they'll occasionally run into walls (mainly for teleport/button use)
	if ( (pointcontents(self.origin + v_forward*80 + '0 0 36') == CONTENT_SOLID || pointcontents(self.origin + v_forward*60 + '0 0 36') == CONTENT_SOLID) && (random() > 0.2) )
		self.angles_y = self.angles_y + (self.button1 / 4);	
	else if (pointcontents(self.origin + v_forward*36 + '0 0 36') == CONTENT_SOLID || pointcontents(self.origin + v_forward*22 + '0 0 36') == CONTENT_SOLID)
		self.angles_y = self.angles_y + (self.button1 / 3);

// every so often, he'll change his wall-hugging direction
	if (random() <= 0.02)
	{	
		if (random() > 0.5)
		{
			if (self.button1 == 90)
				self.button1 = -90;
			else
				self.button1 = 90;
		}
	}

//POX - Make a footstep sound
	bot_footstep();

//POX - Bots sometimes avoid death in liquids (?)
//POX - This is the second attempt to put them to rest
	if (self.health < 1)
		self.th_die();

};


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_walk =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
	
// this is his main AI routine, where he will look for items and enemies
	
	self.nextthink = time + 0.05;
	
	if (self.bot_speed > time)
		return;
	
	BotCheckPowerups (self);
	
	self.bot_speed = time + self.botpref_speed;
	
//POX - Check DM rules so a bot can end a game at max frags
	CheckRules ();

//POX - Caught these guys running around with whatever weapon they grabbed last
	bot_check_ammo();
	
	//POX - reset max armour count
	if(self.regenstop)
		self.regenstop = 0;

	bot_look_for_bots();
	bot_look_for_players();
	
	if (!(self.flags & FL_ONGROUND))
		return;
	
	//regular item search and grab
	bot_search_for_items();
	bot_grab_items();

	//accidental item touch
	bot_check_touch();
	bot_check_close();

	check_for_ledge();
	check_for_water();
	
//POX - If  health is good look for armour
//This is the only time when a bot will actively seek armour, but since armour
//stations work by touch, a bot can accidentally gain armour just by running around
	if (self.health > self.botpref_health - 20)
	{
		bot_regen_find();
		bot_regen_touch();
	}


//POX - This if statement fixed a few problems I have seen with	 these bots ignoring enemies, firing at walls...
//POX - It just tells them to look for stuff if they aren't going after a bot, player, or item
//POX - There must be something I missed elsewhere causing these guys to target junk they can't reach
	if (self.goalentity.classname != "bot" || self.goalentity.classname != "player" || !(self.goalentity.flags & FL_ITEM) || self.goalentity.model == string_null)
	{
		self.goalentity = world;
		self.enemy = world;
		
		bot_look_for_bots();
		bot_look_for_players();

	}

// of course movetogoal() is id's C function, it moves randomly
// toward what his self.goalentity is; don't let it worry you,
// this function takes a long time to get where its going
// the coffee_move is his cool running function

	if (self.goalentity != world)
	{
		movetogoal(20);
		//POX - Make a footstep sound
		bot_footstep();
	}
	else
	{
		coffee_move();
	}
		
		
};



/*Moved above jump_forward for use in bot_ai_back
// --------------------------------
void() bot_run_slide =
// --------------------------------
{
	local float	ofs;
	
// this is a cool strafing routine
	
	//POX - Make a footstep sound
	bot_footstep();

	if (self.lefty)
	{
		ofs = 90;
		ofs = ofs + floor(random() * 15);
	}
	else
	{
		ofs = -90;
		ofs = ofs - floor(random() * 15);
	}

	bot_footstep();
	
	if (walkmove (self.angles_y + ofs, 20))
		return;
		
	self.lefty = 1 - self.lefty;
	
	walkmove (self.angles_y - ofs, 20);

};
*/

// ----------------------
void() bot_strafe =
// ----------------------
{
local float	r;

// this routine is called every frame during combat, 
// so he strafes and dodges even while shooting
	
	self.nextthink = time + 0.05;
	
	if (self.bot_speed > time)
		return;
	
	BotCheckPowerups (self);
	
	self.bot_speed = time + self.botpref_speed;
		
	bot_check_ammo();
	
//POX- accidental item touch
	bot_check_touch();
	bot_check_close();
	
//	check_for_ledge();
	check_for_water();
	
	
	if (!visible(self.enemy))
		{
			self.think = self.th_walk;
			return;
		}

	bot_face();

//POX - Added so bots won't try to back up if already far enough away
	r = range (self.enemy);
	
//POX - If a Bot is low on Health or is out-armed during combat, he'll look for any good stuff near by and try to grab it
	if (self.health < self.botpref_health || better_weapon() == TRUE)
	{
			bot_search_for_needed();
			bot_grab_items();
			
			if (self.goalentity.flags & FL_ITEM)
			{
				movetogoal(20);
				//POX - Make a footstep sound
				bot_footstep(); 
			}
			
			//If no needed items are near by, back up until some are
			else //if (walkmove (self.angles_y - 180, 20) == FALSE)
				bot_ai_back();//bot_run_slide();
	}


//POX- If the bot got here, he's got a lot of health and a good weapon so choose an attack type

// stepping backwards for a long distance shot
//POX - even AS_RUSH bots will back up for a rocket attack
	else if ( (self.weapon == IT_ROCKET_LAUNCHER) && (r != RANGE_MID || r != RANGE_FAR) )
	{
			if (walkmove (self.angles_y - 180, 20) == FALSE)
				bot_run_slide();
	}
	
	//POX - Check for SMART, RETREAT or RUSH Attack
	//POX - TRUE = retreat
	else if	 (better_weapon())
	{
		
		//if (walkmove (self.angles_y - 180, 20) == FALSE)
				bot_ai_back();//bot_run_slide();
	}

// chasing the player here
	else if (!(better_weapon()))
	{
		movetogoal(20);
		//POX - Make a footstep sound
		bot_footstep();
	}
	else
		bot_run_slide();


};



// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_run =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{

// his fighting thoughts. after a short while, he'll give up 
// on his enemy, but if he can see him, he'll always attack
	
	//self.nextthink = time + 0.05;
	
	BotCheckPowerups (self);
	
	if (!(self.flags & FL_ONGROUND))
		return;
	
//POX - A hacky fix to make sure these guys have a real target
	if (self.goalentity.classname != "bot" || self.goalentity.classname != "player" || !(self.goalentity.flags & FL_ITEM) || self.goalentity.model == string_null)
	{
		self.goalentity = world;
		self.enemy = world;
			
		bot_look_for_bots();
		bot_look_for_players();
		
	}

	if (visible(self.enemy))
		self.search_time = time + 0.4;

	if (time > self.search_time || self.enemy.health <= 0)
		{
		self.goalentity = world;
		self.enemy = world;
		self.pausetime = time + 4;
		
		if (random() > 0.7)
			self.think = self.th_stand;
		else
			self.think = self.th_walk;
			
		return;
		}

	bot_strafe();
	
	//POX - Added extra checks to make sure they only target other bots or players only.
	if (visible(self.enemy) && time > self.attack_finished && self.enemy != self && (self.enemy.classname == "bot" || self.enemy.classname == "player") )
		self.th_missile();

};




/*
==========================================================================
==========================================================================
==========================================================================

	Section 2: Weapons

	This section is the simplest, basically dull stuff. It checks for
	his best weapon and sets the relevant ammo. It gives him a free
	weapon. And it does the actual firing of the weapons. The key
	difference between a player weapon routine and a bot weapon 
	routine is the aiming. In player routines, you'll see a line
	like this:

		dir = aim (self, 100000);

	If you want a bot to share that subroutine, basically all you need
	to do is change it to this:

		if (self.classname == "player")
			dir = aim (self, 100000);
			else dir = normalize(self.enemy.origin - self.origin);
			
	This allows the bot to aim directly at his enemy.


==========================================================================
==========================================================================
==========================================================================
*/


void() bot_run1;


//POX - Nolonger needed - bots will always drop a pack unless gibbed (same for players)
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//void() bot_drop_pack =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//{
//	if (random () < 0.9)
//		DropBackpack();
//};



//POX- Changed for new Paroxysm Weapons
//POX - Minimum ammo now reflects second triggers as well
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
float() bot_bestweapon =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
	local	float	it;
	
	it = self.items;

//POX - Added weapon Preference
	if (self.ammo_rockets >= 1 && (it & IT_ROCKET_LAUNCHER) && (self.botpref_weapon == IT_ROCKET_LAUNCHER) )
		return IT_ROCKET_LAUNCHER;
	else if (self.ammo_cells >= 9 && (it & IT_PLASMAGUN) && (self.botpref_weapon == IT_PLASMAGUN) )
		return IT_PLASMAGUN;
	else if (self.ammo_rockets >= 1 && (it & IT_ROCKET_LAUNCHER) )
		return IT_ROCKET_LAUNCHER;
	else if (self.ammo_cells >= 9 && (it & IT_PLASMAGUN) )
		return IT_PLASMAGUN;
	else if (self.ammo_shells >= 2 && (it & IT_COMBOGUN) )
		return IT_COMBOGUN;
	else if (self.ammo_rockets >= 1 && (it & IT_GRENADE_LAUNCHER) )
		return IT_GRENADE_LAUNCHER;
	else if (self.ammo_nails >= 6 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;

		return IT_TSHOT;

};


// --------------------------------
void() bot_set_currentammo =
// --------------------------------
{
	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );
	
      if (self.weapon == IT_TSHOT)
	{
		self.currentammo = self.ammo_shells;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_COMBOGUN)
	{
		self.currentammo = self.ammo_shells;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_PLASMAGUN)
	{
		self.currentammo = self.ammo_cells;
		self.items = self.items | IT_CELLS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.items = self.items | IT_ROCKETS;
	}
	else
	{
		self.currentammo = 0;
		self.weaponmodel = "";
		self.weaponframe = 0;
	}
	
};


// -------------------------
void() bot_check_ammo =
// -------------------------
{
	//if (self.currentammo > 0)
	//	return;

	//if (self.weapon == IT_BONESAW)
	//	return;

	self.weapon = bot_bestweapon();

	bot_set_currentammo();
	
	//if (!self.invis_check)
	//	getmodel(self.weapon, self);

};


// -------------------------------------
vector() bot_aim_at_enemy =
// -------------------------------------
{
	local	vector	dir;
	local float chance;

//Predator Mode / invisible enemy
	if (self.enemy.items & IT_INVISIBILITY)
		chance = floor(random() * 10);
	else
		chance = 0;

	if (chance < 2)
	{
		//POX- bot aim is affected by botpref_aim (higher values are worse)
			if (range(self.enemy) != RANGE_MELEE)//POX - be accurate at close range
			{
				dir = self.enemy.origin - self.enemy.velocity*self.botpref_aim;
				return normalize (dir - self.origin);
			}
			else
				return normalize(self.enemy.origin - self.origin);
	}
	//Bad aim for Pred mode
	else if (chance == 2)
		return normalize((self.enemy.origin - '50 0 0') - self.origin);
	else if (chance == 9)
		return normalize((self.enemy.origin - '75 0 0') - self.origin);
	else
		return normalize((self.enemy.origin + '20 0 0') - self.origin); 

};

//FIXED?
//POX - Bot missiles sometimes Hang (?)
//I couldn't find the cause so I added these new thinks for projectiles
/*POX v1.11
void()	bot_missile_think =
{
	
	self.nextthink = time + 5;
		
	if(!self.velocity)
		self.nextthink = time + 0.01;
	
	self.think = SUB_Remove;
};
*/

//POX- new function - PlasmaGun Second Trigger
void() bot_fire_MPlasma = 
// -----------------------------
{
	//Had to double check this (somehow this happens once and a while)
	if (self.ammo_cells < 9 || self.ammo_cells > 201)
	{
		self.ammo_cells = 0;
		return;
	}
	
	self.currentammo = self.ammo_cells = self.ammo_cells - 9;
	sound (self, CHAN_WEAPON, "weapons/mplasma.wav", 1, ATTN_NORM);
	
	bot_face();
	
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "megaplasma";
	newmis.effects = newmis.effects | EF_BRIGHTFIELD | EF_BRIGHTLIGHT;

	newmis.velocity = bot_aim_at_enemy() * 1200;
	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = T_MplasmaTouch;
	
	//POX v1.11
	//newmis.nextthink = time + 0.05;
	//newmis.think = bot_missile_think;
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;

	setmodel (newmis, "progs/plasma.mdl");
	setsize (newmis, '-1 -1 -1', '1 1 1');
	setorigin (newmis, self.origin + v_forward*8 + '0 0 16');

};

//POX- new function - ComboGun Second Trigger
//FIXME - obituary calls this buckshot (?ammo changes too fast?)
.float	pball_finish;	//second trigger timeout

void() bot_fire_PBall = 
// -----------------------------
{
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	sound (self, CHAN_WEAPON, "weapons/ssgrnde.wav", 1, ATTN_NORM);
	
	bot_face();
	
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "impactgrenade";

	
	//------------------------------------
	makevectors (self.v_angle);
	
	newmis.velocity = bot_aim_at_enemy() * 700;
	newmis.velocity_z = newmis.velocity_z + 200;
	
	newmis.angles = vectoangles(newmis.velocity);
	//------------------------------------
	
	newmis.touch = T_PballTouch;
	
	//POX v1.11
	//newmis.nextthink = time + 0.05;
	//newmis.think = bot_missile_think;
	newmis.nextthink = time + 3;
	newmis.think = SUB_Remove;

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '-1 -1 -1', '1 1 1');
	setorigin (newmis, self.origin + v_forward*8 + '0 0 16');
	
};

/* Replaced by the BoneSaw (Bots don't use the BoneSaw)
// -------------------------------------
void() bot_fire_pulsegun =
// -------------------------------------
{
local entity missile;

	sound (self, CHAN_WEAPON, "weapons/pulse.wav", 1, ATTN_NORM);
	
	bot_face();
	
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;

	missile.velocity = bot_aim_at_enemy() * 1100;
	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = Pulse_Touch;
	missile.nextthink = time + 0.05;
	missile.think = bot_missile_think;

	setmodel (missile, "progs/p_spike.mdl");
	setsize (missile, '-1 -1 -1', '1 1 1');
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');

};
*/

// -------------------------------------
void() bot_fire_supershotgun =
// -------------------------------------
{
local vector dir;

	self.currentammo = self.ammo_shells = self.ammo_shells - 2;
	bot_face();
	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM); 
	self.effects = self.effects | EF_MUZZLEFLASH;
	dir = bot_aim_at_enemy();
	FireBullets (14, dir, '0.14 0.1 0');

};


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_fire_shotgun =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
local vector dir;
	
	if (self.weapon == IT_COMBOGUN)
		{
		bot_fire_supershotgun();
		return;
		}
	
	//POX - This is a hack since Bots don't use the BoneSaw
	if (self.ammo_shells < 1)
		self.ammo_shells = 10;
		
	/*
	if (self.ammo_shells < 1)
	{
		bot_fire_pulsegun();
		return;
	}
	*/
	
	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	
	bot_face();

	sound (self, CHAN_WEAPON, "weapons/tsfire.wav", 1, ATTN_NORM);	
	self.effects = self.effects | EF_MUZZLEFLASH;

	dir = bot_aim_at_enemy();
	FireBullets (6, dir, '0.04 0.04 0');

};


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_fire_supernailgun =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
local vector dir;

	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	sound (self, CHAN_WEAPON, "weapons/nailgun.wav", 1, ATTN_NORM);
	
	bot_face();
	
	dir = bot_aim_at_enemy();
	launch_spike (self.origin + '0 6 16', dir);
	newmis.touch = spike_touch;
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
};


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_fire_nailgun = //POX - Actually, this is the PlasmaGun
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
local vector dir;
	
	if (self.weapon == IT_SUPER_NAILGUN)
		{
		bot_fire_supernailgun();
		return;
		}

	self.currentammo = self.ammo_cells = self.ammo_cells - 1;
	sound (self, CHAN_WEAPON, "weapons/plasma.wav", 1, ATTN_NORM);
	
	bot_face();
	
	dir = bot_aim_at_enemy();
	launch_plasma (self.origin + '0 6 16', dir);
	newmis.touch = plasma_touch;
	setmodel (newmis, "progs/laser.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);

};


// """"""""""""""""""""""""""""
void() bot_fire_grenade =
// ----------------------------
{

	//POX - PlasmaGun Second Trigger (shared animation)
	if (self.weapon == IT_PLASMAGUN)
		{
		bot_fire_MPlasma();
		return;
		}
		
	//POX - ComboGun Second Trigger (shared animation)
	if (self.weapon == IT_COMBOGUN)
	{
		bot_fire_PBall();
		return;
	}
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	self.effects = self.effects | EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "weapons/ssgrnde.wav", 1, ATTN_NORM);

	bot_face();
	
	newmis = spawn ();
	newmis.voided = 0;	
	newmis.owner = self;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;

// set missile speed	
	makevectors (self.v_angle);

//POX - slightly better vertical aim
	newmis.velocity = bot_aim_at_enemy() * 580;
	newmis.velocity_z = newmis.velocity_z + 200;
	
	//newmis.velocity = newmis.velocity * 580;
	//newmis.velocity_z = 300;

	newmis.avelocity = '300 300 300';

	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = GrenadeTouch;
	
// set missile duration
	newmis.nextthink = time + 2.5;
	newmis.think = GrenadeExplode;

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, self.origin);

};


// =============================
void() bot_fire_rocket = 
// -----------------------------
{
local vector	spot1, spot2;
local float		dist;

	if (self.weapon == IT_GRENADE_LAUNCHER)
		{
		bot_fire_grenade();
		return;
		}
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 0.5;
	
	bot_face();
	
//POX - For better aiming of toss projectiles
	spot1 = self.origin + self.view_ofs;
	spot2 = self.enemy.origin + self.enemy.view_ofs;
	
	dist = vlen (spot1 - spot2);
	
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "rocket";

	//=---------------------------------------------
	makevectors (self.v_angle);
	
	//POX - Much better verical aim
	
	newmis.velocity =  bot_aim_at_enemy() * 1100;
	
	if (dist > 500)
		newmis.velocity_z = newmis.velocity_z + (dist*0.3) + (random()*8);
	else
		newmis.velocity_z = newmis.velocity_z + 180 + (random()*8);
	
	//bprint(ftos(dist*0.3));
	//bprint("\n");
	
	newmis.angles = vectoangles(newmis.velocity);
	//=---------------------------------------------
	
	newmis.touch = T_MissileTouch;
	
	//POX v1.11
	//newmis.nextthink = time + 0.05;
	//newmis.think = bot_missile_think;
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '-1 -1 -1', '1 1 1');
	setorigin (newmis, self.origin + v_forward*8 + '0 0 16');
};


/* POX - not needed
// ==============================
void() bot_lightning =
// ------------------------------
{
	local	vector	org, dir;
	
	self.effects = self.effects | EF_MUZZLEFLASH;

	bot_face();


	makevectors(self.angles);
	org = self.origin + '0 0 8' + (v_forward * 8);

	dir = bot_aim_at_enemy();

	traceline (org, self.origin + dir*600, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING1);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (org, trace_endpos, self, 10);

	sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
	self.currentammo = self.ammo_cells = self.ammo_cells - 1;
};


/*
==========================================================================
==========================================================================
==========================================================================

	Section 3: Animation

	This is a bunch of ugly stuff, and you don't really need to
	understand all of it. It merely defines his animation frames and
	sequences. After that you have his pain, death, and attack routines.
	Lastly, we have his spawn/respawn subroutine.

==========================================================================
==========================================================================
==========================================================================
*/

/*POX - frames are referenced by absolute numbers for  reuse in different visibleweapon models
// Frame macros

$cd /raid/quake/id1/models/player_4
$origin 0 -6 24
$base base		
$skin skin

$frame axrun1 axrun2 axrun3 axrun4 axrun5 axrun6

$frame rockrun1 rockrun2 rockrun3 rockrun4 rockrun5 rockrun6

//
// standing
//
$frame stand1 stand2 stand3 stand4 stand5

$frame axstnd1 axstnd2 axstnd3 axstnd4 axstnd5 axstnd6
$frame axstnd7 axstnd8 axstnd9 axstnd10 axstnd11 axstnd12


//
// pain
//
$frame axpain1 axpain2 axpain3 axpain4 axpain5 axpain6

$frame pain1 pain2 pain3 pain4 pain5 pain6


//
// death
//

$frame axdeth1 axdeth2 axdeth3 axdeth4 axdeth5 axdeth6
$frame axdeth7 axdeth8 axdeth9

$frame deatha1 deatha2 deatha3 deatha4 deatha5 deatha6 deatha7 deatha8
$frame deatha9 deatha10 deatha11

$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9

$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11 deathc12 deathc13 deathc14 deathc15

$frame deathd1 deathd2 deathd3 deathd4 deathd5 deathd6 deathd7
$frame deathd8 deathd9

$frame deathe1 deathe2 deathe3 deathe4 deathe5 deathe6 deathe7
$frame deathe8 deathe9

//
// attacks
//
$frame nailatt1 nailatt2

$frame light1 light2

$frame rockatt1 rockatt2 rockatt3 rockatt4 rockatt5 rockatt6

$frame shotatt1 shotatt2 shotatt3 shotatt4 shotatt5 shotatt6

$frame axatt1 axatt2 axatt3 axatt4 axatt5 axatt6

$frame axattb1 axattb2 axattb3 axattb4 axattb5 axattb6

$frame axattc1 axattc2 axattc3 axattc4 axattc5 axattc6

$frame axattd1 axattd2 axattd3 axattd4 axataxattd6
*/

// movement animation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//POX - added for Armour Regen Station Support
void() bot_regen1		=[	6,	bot_regen2	] {bot_regen();};
void() bot_regen2		=[7,	bot_regen3	] {bot_regen();};
void() bot_regen3		=[	8,	bot_regen4	] {bot_regen();};
void() bot_regen4		=[	9,	bot_regen1	] {bot_regen();};

void() bot_stand1		=[	6,	bot_stand2	] {bot_stand();};
void() bot_stand2		=[	7,	bot_stand3	] {bot_stand();};
void() bot_stand3		=[	8,	bot_stand4	] {bot_stand();};
void() bot_stand4		=[	9,	bot_stand1 ] {bot_stand();};


void()	bot_walk1		=[	0,	bot_walk2	] {bot_walk();};
void()	bot_walk2		=[	1,	bot_walk3	] {bot_walk();};
void()	bot_walk3		=[	2,	bot_walk4	] {bot_walk();};
void()	bot_walk4		=[	3,	bot_walk5	] {bot_walk();};
void()	bot_walk5		=[	4,	bot_walk6	] {bot_walk();};
void()	bot_walk6		=[	5,	bot_walk1	] {bot_walk();};

void()	bot_run1		=[	0,	bot_run2	] {bot_run();};
void()	bot_run2		=[	1,	bot_run3	] {bot_run();};
void()	bot_run3		=[	2,	bot_run4	] {bot_run();};
void()	bot_run4		=[	3,	bot_run5	] {bot_run();};
void()	bot_run5		=[	4,	bot_run6	] {bot_run();};
void()	bot_run6		=[	5,	bot_run1	] {bot_run();};

void()	bot_jump1		=[	0,	bot_jump2	] {jump_forward();};
void()	bot_jump2		=[	0,	bot_jump3	] {};
void()	bot_jump3		=[	0,	bot_jump4	] {};
void()	bot_jump4		=[	0,	bot_jump5	] {};
void()	bot_jump5		=[0,	bot_walk1	] {};


// attack animation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//POX - Added a few things here, SuperDamage sound is checked, and the weapon fire calls support POX weapons

void()	bot_rock1		=[	14,	bot_rock2	] {bot_strafe(); self.effects = self.effects | EF_MUZZLEFLASH;
sound (self, CHAN_WEAPON, "weapons/rhino.wav", 1, ATTN_NORM); bot_fire_rocket(); SuperDamageSound();self.nextthink = time + 0.1;};
void()	bot_rock2		=[	15,	bot_rock3	] {bot_strafe(); bot_fire_rocket();};
void()	bot_rock3		=[	16,	bot_rock4	] {bot_strafe();};
void()	bot_rock4		=[	16,	bot_run1		] {bot_strafe();};

void()	bot_gren1		=[	15,	bot_gren2	] {bot_strafe(); self.effects = self.effects | EF_MUZZLEFLASH; bot_fire_grenade(); SuperDamageSound();};
void()	bot_gren2		=[	16,	bot_gren3	] {bot_strafe();};
void()	bot_gren3		=[	17,	bot_gren4	] {bot_strafe();};
void()	bot_gren4		=[	18,	bot_gren5	] {bot_strafe();};
void()	bot_gren5		=[	19,	bot_run1	] {bot_strafe();};

void()	bot_shot1		=[	15,	bot_shot2	] {bot_strafe(); self.effects = self.effects | EF_MUZZLEFLASH; bot_fire_shotgun(); SuperDamageSound();};
void()	bot_shot2		=[	16,	bot_shot3	] {bot_strafe();};
void()	bot_shot3		=[	17,	bot_shot4	] {bot_strafe();};
void()	bot_shot4		=[	18,	bot_shot5	] {bot_strafe();};
void()	bot_shot5		=[	19,	bot_run1	] {bot_strafe();};


//POX - 102b - Made this simpler, and fixed attack_finished check
void()	bot_nail1		=[	15,	bot_nail2	] {bot_strafe(); bot_fire_nailgun(); self.effects = self.effects | EF_MUZZLEFLASH; SuperDamageSound();};
void()	bot_nail2		=[	16,	bot_run1	] {bot_strafe();
if (visible(self.enemy) && self.ammo_nails > 0 && self.enemy.health > 0)
	bot_attack();
else
	bot_run1(); };


void() th_respawn =
{
	self.think = respawn_bot;
	self.nextthink = time + 1;
};

void()	bot_pain1		=[	10,	bot_pain2	] {};
void()	bot_pain2		=[	11,	bot_pain3	] {};
void()	bot_pain3		=[	12,	bot_pain4	] {};
void()	bot_pain4		=[	13,	bot_pain5	] {};
void()	bot_pain5		=[	14,	bot_run1		] {};

void()	bot_painb1		=[	10,	bot_painb2	] {};
void()	bot_painb2		=[	11,	bot_painb3	] {};
void()	bot_painb3		=[	12,	bot_painb4	] {};
void()	bot_painb4		=[	13,	bot_run1	] {};

void()	bot_die1		=[	33,	bot_die2	] {};
void()	bot_die2		=[	34,	bot_die3	] {};
void()	bot_die3		=[	35,	bot_die4	] {self.solid = SOLID_NOT; DropBackpack(); };
void()	bot_die4		=[	36,	bot_die5	] {};
void()	bot_die5		=[	37,	bot_die6	] {};
void()	bot_die6		=[	38,	bot_die7	] {};
void()	bot_die7		=[	39,	bot_die8	] {};
void()	bot_die8		=[	40,	bot_die9	] {};
void()	bot_die9		=[	41,	bot_die10	] {};
void()	bot_die10		=[	42,	bot_die11	] {};
void()	bot_die11		=[	43,	th_respawn	] {};

void()	bot_dieb1		=[	44,	bot_dieb2	 ] {};
void()	bot_dieb2		=[	45,	bot_dieb3	 ] {};
void()	bot_dieb3		=[	46,	bot_dieb4	 ] {self.solid = SOLID_NOT; DropBackpack(); };
void()	bot_dieb4		=[	47,	bot_dieb5	 ] {};
void()	bot_dieb5		=[	48,	bot_dieb6	 ] {};
void()	bot_dieb6		=[	49,	bot_dieb7	 ] {};
void()	bot_dieb7		=[	50,	bot_dieb8	 ] {};
void()	bot_dieb8		=[	51,	bot_dieb9	 ] {};
void()	bot_dieb9		=[	52,	th_respawn	 ] {};

void()	bot_diec1		=[	53,	bot_diec2	 ] {};
void()	bot_diec2		=[	54,	bot_diec3	 ] {};
void()	bot_diec3		=[	55,	bot_diec4	 ] {self.solid = SOLID_NOT; DropBackpack(); };
void()	bot_diec4		=[	56,	bot_diec5	 ] {};
void()	bot_diec5		=[	57,	bot_diec6	 ] {};
void()	bot_diec6		=[	58,	bot_diec7	 ] {};
void()	bot_diec7		=[	59,	bot_diec8	 ] {};
void()	bot_diec8		=[	60,	bot_diec9	 ] {};
void()	bot_diec9		=[	61,	bot_diec10	 ] {};
void()	bot_diec10	=[	62,	bot_diec11	 ] {};
void()	bot_diec11	=[	63,	bot_diec12	 ] {};
void()	bot_diec12	=[	64,	bot_diec13	 ] {};
void()	bot_diec13	=[	65,	bot_diec14	 ] {};
void()	bot_diec14	=[	66,	bot_diec15	 ] {};
void()	bot_diec15	=[	67,	th_respawn	 ] {};

void()	bot_died1		=[	68,	bot_died2	 ] {};
void()	bot_died2		=[	69,	bot_died3	 ] {};
void()	bot_died3		=[	70,	bot_died4	 ] {self.solid = SOLID_NOT; DropBackpack(); };
void()	bot_died4		=[	71,	bot_died5	 ] {};
void()	bot_died5		=[	72,	bot_died6	 ] {};
void()	bot_died6		=[	73,	bot_died7	 ] {};
void()	bot_died7		=[	74,	bot_died8	 ] {};
void()	bot_died8		=[	75,	bot_died9	 ] {};
void()	bot_died9		=[	76,	th_respawn	 ] {};

void()	bot_diee1		=[	77,	bot_diee2	 ] {};
void()	bot_diee2		=[	78,	bot_diee3	 ] {};
void()	bot_diee3		=[	79,	bot_diee4	 ] {self.solid = SOLID_NOT; DropBackpack(); };
void()	bot_diee4		=[	80,	bot_diee5	 ] {};
void()	bot_diee5		=[81,	bot_diee6	 ] {};
void()	bot_diee6		=[	82,	bot_diee7	 ] {};
void()	bot_diee7		=[	83,	bot_diee8	 ] {};
void()	bot_diee8		=[	84,	bot_diee9	 ] {};
void()	bot_diee9		=[	85,	th_respawn	 ] {};

void() BotPainSound =
{
	local float		rs;

	if (self.health < 0)
		return;
	
	rs = rint((random() * 5) + 1);
	
	self.noise = "";
	if (rs == 1)
		self.noise = "player/pain1.wav";
	else if (rs == 2)
		self.noise = "player/pain2.wav";
	else if (rs == 3)
		self.noise = "player/pain3.wav";
	else if (rs == 4)
		self.noise = "player/pain4.wav";
	else if (rs == 5)
		self.noise = "player/pain5.wav";
	else
		self.noise = "player/pain6.wav";

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	return;
};

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void(entity attacker, float damage)	bot_pain =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
	//helps with LAN packet crashes
	if (random() < 0.5) //Go into pain frames less often
		return;
	
// POX - get mad at attacker - even other bots (usually)
	if (attacker != self.enemy && attacker != world)
		{
		self.enemy = attacker;
		bot_FoundTarget();
		}
	
	if (self.pain_finished > time)
		return;

	if (random() < 0.35)
		return;
	
	BotPainSound(); //POX v1.11 - this is only for shooting type pain
	
	self.pain_finished = time + 2;
	
	if (self.weapon == IT_ROCKET_LAUNCHER)
		bot_painb1();
	else
		bot_pain1();

};



// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() gib_bot =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{

	//POX - make a nice gib in Gib mode
	if (deathmatch & DM_GIB)
		self.health = self.health - 40;
	
	//POX-changed self to head model for multi skin support
	ThrowGib ("progs/gib3.mdl", self.health);
	ThrowGib ("progs/gib1.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
		 
	setmodel (self, "progs/h_player.mdl");
	setsize (self, '0 0 0', '0 0 0');

	self.deadflag = DEAD_DEAD;
	self.think = th_respawn;
	self.nextthink = time + 1;

	if (damage_attacker.classname == "teledeath")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

	if (damage_attacker.classname == "teledeath2")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}
		
	if (random() < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);

};




// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_die =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
local float i;

// we're turning the bot off here and playing his death scene
	
	self.invisible_finished = 0;
	self.invisible_time = 0;
	
	self.skin = self.skinsave; //incase died as eyes
	
	self.deadflag = DEAD_DYING;
	self.solid = SOLID_NOT;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.movetype = MOVETYPE_TOSS;
	if (self.velocity_z < 10)
		self.velocity_z = self.velocity_z + random()*300;

//POX - change back to proper skin and get death model (incase he's invisible)
	self.modelindex = modelindex_death;
	self.frame = 44;
	
		
//POX - visible weapon toss
	ThrowWeapon(self.weapon);

	
//POX check for Gib Mode as well as a regular gib
	if (self.health < -40 || (deathmatch & DM_GIB))
		{
		gib_bot();
		return;
		}
	
	DeathSound();

	i = floor(random() * 5);

	if (i == 0)
		bot_die1();
	else if (i == 1)
		bot_dieb1();
	else if (i == 2)
		bot_diec1();
	else if (i == 3)
		bot_died1();
	else
		bot_diee1();
	
};



//POX  a few more attacks added for second triggers
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void() bot_attack =
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{
// this routine decides which animation sequence to play
	
	//self.think = self.th_walk;
	//self.nextthink = time + 0.05;
	
	if (time < self.attack_finished)
	{
		bot_run1 ();
		return;
	}

	bot_check_ammo();
	
	if (self.weapon == IT_TSHOT)
		{
		self.attack_finished = time + 0.4;
		bot_shot1();
		}
	//POX - Impact grenade (ComboGun Second Trigger)
	else if (self.weapon == IT_COMBOGUN && random() > 0.4 && self.ammo_rockets > 1 && self.pball_finish < time && range(self.enemy) == RANGE_NEAR)
		{
		self.pball_finish = time + 0.9;
		self.which_ammo = 1;//POX - needed for proper obituary
		bot_gren1();
		}
	else if (self.weapon == IT_COMBOGUN)
		{
		self.attack_finished = time + 0.5;
		self.which_ammo = 0;//POX - needed for proper obituary
		bot_shot1();
		}
	//POX - MegaPlasma Burst (Plasma Gun Second Trigger)
	else if (self.weapon == IT_PLASMAGUN && (range(self.enemy) != RANGE_MELEE) &&  self.ammo_cells > 9 && random() > 0.6)
		{
		self.attack_finished = time + 1.9;
		bot_gren1();
		}
	else if (self.weapon == IT_PLASMAGUN)
		{
		self.attack_finished = time + 0.1;
		bot_nail1();
		}			
	else if (self.weapon == IT_SUPER_NAILGUN)
		{
		self.attack_finished = time + 0.1;
		bot_nail1();
		}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
		self.attack_finished = time + 0.8;
		bot_gren1();
		}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
		self.attack_finished = time + 0.7;
		bot_rock1();
		}
		
};

//POX - I split the spawning functions from this main file (see botspawn.qc)
