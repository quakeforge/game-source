/*----------------------------------------------------------------
POXbot spawning routines

These started getting long so I threw them in a seperate file.
----------------------------------------------------------------*/
//
// standing
//
$frame stand1 stand2 stand3 stand4 stand5

$frame axstnd1 axstnd2 axstnd3 axstnd4 axstnd5 axstnd6
$frame axstnd7 axstnd8 axstnd9 axstnd10 axstnd11 axstnd12


//POX - New naming routine (doesn't allow duplicate names)
//Modified version of  name code from Doombot Skeleton v0.23 by Roscoe A. Sincero    
float (string st) check_bot_name =
{

// checks to see if the name is already used.

   local entity	  botname;
   botname = find(world, classname, "bot");
   while (botname != world)
   {
      if (botname.netname == st)
      {
	 // name already used
	 return TRUE;
      }
      botname = find(botname, classname, "bot");
   }

};

string() bot_name =
{
   local float r;
   local string st;

      do
      {
	 r = random ();

	 if (r < 0.07)
	    st = "BadMan";
	 else if (r < 0.10)
	    st = "koRnewt";
	 else if (r < 0.13)
	    st = "FreakFace";
	 else if (r < 0.17)
	    st = "Udie!";
	 else if (r < 0.25)
	    st = "kILLer";
	 else if (r < 0.32)
	    st = "Sunshine";
	 else if (r < 0.36)
	    st = "Happy";
	 else if (r < 0.46)
	    st = "sICKO";
	 else if (r < 0.48)
	    st = "choke";
	 else if (r < 0.53)
	    st = "TrasH";
	 else if (r < 0.55)
	    st = "Johny5";
	 else if (r < 0.59)
	    st = "who?";
	 else if (r <0.62)
	    st = "BOO!";
	 else if (r < 0.68)
	    st = "Radley";
	 else if (r <0.72)
	    st = "Homer";
	 else if (r < 0.74)
	    st = "ScoRCh";
	 else if (r < 0.78)
	    st = "The Wind";
	 else if (r < 0.80)
	    st = "Reap-err";
	 else if (r < 0.82)
	    st = "LameO";
	 else if (r < 0.84)
	    st = "BOB";
	 else if (r < 0.86)
	    st = "gUMp";
	 else if (r < 0.89)
	    st = "C64";
	 else if (r < 0.92)
	    st = "Arse";
	 else if (r < 0.94)
	    st = "BIGhead";
	 else if ( r < 0.97)
	    st = "Santa";
	 else if (r < 1)
	    st = "Dung";
      
	 }
	 
   while (check_bot_name (st));

   return st;

};


// ------------------------------------------------
void() respawn_bot =
// ------------------------------------------------
{

local entity spot;

// putting him back in game

	CopyToBodyQue (self);//POX - dead bodies remain
	
	spot = SelectSpawnPoint();
	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;	
	spawn_tfog (self.origin);
	spawn_tdeath (self.origin, self);
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	makevectors(self.angles);
	self.velocity = self.velocity + v_forward*20;

//POX - Reset PowerUps
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.invincible_time = 0;
	
	
	//POX v1.2 - missed this - dead bots with powerups could respawn 'glowing'
	self.effects = 0;

	
// making him normal again
//	setmodel(self, self.mdl);

//Predator Mode
	if (deathmatch & DM_PREDATOR)
	{
		//self.skin = 0;
		//setmodel(self, "progs/eyes.mdl");
					
		self.invisible_time = 1;
		self.invisible_finished = time + 9999999999;

	}
	else
		self.skin = self.skinsave;
	
	setmodel(self, self.mdl);

//POX - DarkMode
	if (deathmatch & DM_DARK)
		flash_on(self);
		
//Lastman Standing (Although bots are counted out at death, they don't go away till respawn - same for players)
	if (self.frags <= 0 && (deathmatch & DM_LMS))
	{
		self.think = SUB_Remove;
		self.nextthink = time + 0.1;
		return;
	}
		
	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_AIM;
	self.ideal_yaw = self.angles * '0 1 0';
	self.yaw_speed = 120;
	self.view_ofs = '0 0 22';
	self.frame = $stand1;
	self.button1 = 90;

// finishing his characteristics

//POX - reset ammo
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
	
	self.items = IT_TSHOT;
	self.currentammo = self.ammo_shells = self.ammo_shells + 25;
	self.weapon = IT_TSHOT;
	self.health = 100;
	self.max_health = 100;
	self.classname = "bot";
	self.enemy = world;
	self.goalentity = world;
	self.search_time = 0;
	
	// POX v1.1 - spawn with 50 armour points
	self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
	self.armorvalue = 50;
	self.armortype = 0.9;

	//FFA Mode
	if (deathmatch & DM_FFA)
	{
		self.invincible_finished = time + 3;
		self.invincible_time = 1;
		self.items = IT_BONESAW | IT_TSHOT | IT_COMBOGUN | IT_PLASMAGUN | IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER | IT_INVULNERABILITY | IT_ARMOR3;
		self.health = 200;
		self.max_health = 200;
		self.armorvalue = 250;
		self.ammo_shells = 100;
		self.ammo_nails = 200;
		self.ammo_rockets = 100;
		self.ammo_cells = 200;	
		self.armortype = 0.9;
		
		sound (self, CHAN_VOICE, "items/protect.wav", 1, ATTN_NORM);
	}

// making him stand for a bit
	self.pausetime = time + 5;
	self.nextthink = time + 0.1;
	self.think = self.th_stand;
	
	self.bot_needs_item = FALSE; //POX - clear any needed items


//POX v1.11 - spawn bots AFTER all players are in
/*
	msgUpdateNameToAll (self.fClientNo, self.netname);
	msgUpdateColorsToAll (self.fClientNo, self.fShirt, self.fPants);
	msgUpdateFragsToAll (self.fClientNo, self.frags);
*/
};



// ------------------------------------------------
void(float teem) create_bot =
// ------------------------------------------------
{
local entity bot, spot, plr;
local float r, cno, sn, pn;

//POX - NoBots option
if (deathmatch & DM_NOBOTS)
	{
		bprint ("No bots allowed in this game.\n");
		return;
	}


//POX - added for bot ranking support
if (botcounter == 8)
   {
      // already reached maximum number of bots.
      bprint ("Maximum number of bots has been\n");
      bprint ("reached. Only 8 bots are allowed.\n");
      return;
   }

   cno = clientNextAvailable ();

	if (cno == -1)
	{
	bprint ("Server is full.  Unable to spawn bot.\n");
	return;
	}

// initializing the entity
	bot = spawn();

//POX - added for bot ranking support
	botcounter = botcounter + 1;
	
	spot = SelectSpawnPoint();
	bot.origin = spot.origin + '0 0 1';
	bot.angles = spot.angles;
	bot.fixangle = TRUE;	
	spawn_tfog (bot.origin);
	spawn_tdeath (bot.origin, bot);
	bot.solid = SOLID_SLIDEBOX;
	bot.movetype = MOVETYPE_STEP;

// defining his animation
//POX - added a couple new skins for bots

	bot.mdl = "progs/player.mdl";
	
//POX1.01b - FIX for friendly team bot skin (use base skin)
	if (teamplay && teem == 2)
		bot.skin = 0;
	else
	{
		if (random() < 0.5)
			bot.skin = 1;
		else
			bot.skin = 2;
	}
		
	bot.skinsave = bot.skin;

	bot.frame = $stand1;
	bot.th_stand = bot_stand1;
	bot.th_walk = bot_walk1;
	bot.th_run = bot_run1;
	bot.th_pain = bot_pain;
	bot.th_die = bot_die;
	bot.th_missile = bot_attack;

// arming and naming him
	bot.items = bot.items | IT_TSHOT;
	bot.currentammo = bot.ammo_shells = bot.ammo_shells + 25;
	bot.weapon = IT_TSHOT;
	bot.health = 100;
	bot.max_health = 100;
	bot.classname = "bot";

//POX - Added for Powerup Support
	bot.super_damage_finished = 0;
	bot.radsuit_finished = 0;
	bot.invisible_finished = 0;
	bot.invincible_finished = 0;
	bot.effects = 0;
	bot.invincible_time = 0;

// POX v1.1 - spawn with 50 armour points
	self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
	self.armorvalue = 50;
	self.armortype = 0.9;
	
//POX - Added for Ranking Support
   clientSetUsed (cno);

	bot.fClientNo = cno;
	bot.colormap = cno + 1;

	if (!teamplay)
	{	
		bot.fShirt = floor (random() * 13);
		bot.fPants = floor (random() * 13);
	}

/*	
POX - I've changed tutor bot team rules to support multiple clients (in theory).
Only one all bot team is allowed, but you can mix bots and clients on other teams.
This is kind of a hack since every client can create a team bot and/or an all bot team bot.
I should implement a user config that limits the number of team members,
currently only the server limit will do this, and real clients will always boot a bot when
they join if there isn't any space.
*/
sn = -1;
pn = -1;
	//POX - Create a Friendly Team Bot
	if (teamplay && teem == 2)
	{
		bot.team = self.team;
		
	//POX - This is a hack to get the proper colours to show in the rankings (colormap didn't work(?))
	//POX - It tests every combination of colours (plus a few more for good luck) until the right one is found
			while (sn < 15)
			{
				while (pn < 15)
				{
					//POX - FIX ME - cvars always refer to the server (maybe force teams to wear solid colours)
					if (cvar("_cl_color") == (sn*16) + pn)
					{
						
						//bot.colormap = self.colormap;						
						bot.fShirt = sn;
						bot.fPants = pn;
						
						sn = 15;
						pn = 15;
					}
		
					pn = pn + 1;
				}
	
			sn = sn + 1;
			pn = 0;
			}			
		}
		
	//POX - Create an all Bot Team Bot (bad guys)
	if (teamplay && teem == 1)
		{
			bot.team = 16; //POX - I figured team 17 would never exist so I used it for the all bot team	
			//POX - all bot team is always white on white
			bot.fShirt = 0;
			bot.fPants = 0;
		}

	
	//Predator Mode
	if (deathmatch & DM_PREDATOR)
	{
		//setmodel(bot, "progs/eyes.mdl");
		//bot.skin = 0;
		
		bot.invisible_time = 1;
		bot.invisible_finished = time + 9999999999;
		
	}
	
	setmodel(bot, bot.mdl);
	
	//Dark Mode
	if (deathmatch & DM_DARK)
		flash_on(bot);

		
	//Last Man Standing
	if (deathmatch & DM_LMS)
	{
		lms_plrcount = lms_plrcount + 1;
		
		if (fraglimit_LMS == 0)
			bot.frags = 5;
		else
			bot.frags = fraglimit_LMS;
	}

	//FFA Mode
	if (deathmatch & DM_FFA)
	{
		bot.invincible_finished = time + 5;
		bot.invincible_time = 1;
		bot.items = IT_BONESAW | IT_TSHOT | IT_COMBOGUN | IT_PLASMAGUN | IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER | IT_INVULNERABILITY | IT_ARMOR3;
		bot.health = 200;
		bot.max_health = 200;
		bot.armorvalue = 250;
		bot.ammo_shells = 100;
		bot.ammo_nails = 200;
		bot.ammo_rockets = 100;
		bot.ammo_cells = 200;	
		bot.armortype = 0.9;
		
		sound (bot, CHAN_VOICE, "items/protect.wav", 1, ATTN_NORM);
	}
	
	bot.netname = bot_name();			

//POX - Added for Ranking Support
   msgUpdateNameToAll( bot.fClientNo, bot.netname );
   msgUpdateColorsToAll( bot.fClientNo, bot.fShirt, bot.fPants );
   msgUpdateFragsToAll( bot.fClientNo, bot.frags );
	
	bprint(bot.netname);
	bprint(" entered the game\n");

// polishing him up
	setsize (bot, VEC_HULL_MIN, VEC_HULL_MAX);	
	bot.ideal_yaw = bot.angles * '0 1 0';
	bot.yaw_speed = 120;
	bot.view_ofs = '0 0 22';
	bot.takedamage = DAMAGE_AIM;
	bot.attack_state = 0;
	bot.button1 = 90;
	bot.nextthink = time + 0.1 + random();
	bot.think = bot.th_walk;

/*POX v1.11 - Cloak is back to eyes (bot powerup check is less accurate now, but good enough)
//POX - This part is a hack - it allows the Player who spawned the bot to check it's powerups
//POX - This was necessary for the new cloak effect to work with bots
//POX - The down side is, when a player disconnects, his bots must go with him

	self.total_spawned_bots = self.total_spawned_bots + 1;
	
	if (self.total_spawned_bots == 1)
		self.bot_a = bot;
	if (self.total_spawned_bots == 2)
		self.bot_b = bot;
	if (self.total_spawned_bots == 3)
		self.bot_c = bot;
	if (self.total_spawned_bots == 4)
		self.bot_d = bot;
	if (self.total_spawned_bots == 5)
		self.bot_e = bot;
	if (self.total_spawned_bots == 6)
		self.bot_f = bot;
	if (self.total_spawned_bots == 7)
		self.bot_g = bot;
	if (self.total_spawned_bots == 8)
		self.bot_h = bot;
*/

//POX - Define BotPrefs - semi-random based on skill level setting
//Skill 1 (default) will spawn randomized bots (but no extremely bad or good ones)

local float	r;

//POX - speed
	if (skill == 0)
		bot.botpref_speed	= 0.1;
	
	if (skill == 1)
	{
		r = random() - 0.5;
		if (r < 0.06)
			r = 0.06;
		if (r > 0.09)
			r = 0.09;
			
		bot.botpref_speed = r;
	}
	
	if (skill == 2)
		bot.botpref_speed	= 0.07;
	
	if (skill > 2)
		bot.botpref_speed	= 0.05;

//POX - health awarness
	r = floor(random() * 30 + (10*skill) + 20);
	
	if (r < 60)
		r = 60;
	
	bot.botpref_health = r;

//POX - aim
	if (skill == 0)
		bot.botpref_aim = 0.25;
	
	if (skill == 1)
	{
		r = random();
		if (r < 0.05)
			r = 0.05;
		if (r > 0.2)
			r = 0.2;
			
		bot.botpref_aim = r;
	}
	
	if (skill == 2)
		bot.botpref_aim = 0.1;
	
	if (skill > 2)
		bot.botpref_aim = 0;

//POX - Client Awareness
	if (skill == 0)
		bot.botpref_aware = FALSE;
	else if (skill == 1 || skill == 2)
	{
		r = random();
		if (r < skill*0.4)
			bot.botpref_aware = TRUE;
		else
			bot.botpref_aware = FALSE;
	}
	else
		bot.botpref_aware = TRUE;
		
//POX - Attack Styles
		r = floor(random() * 3);
		
		if (r == 1 && random() > 0.5)
			bot.botpref_attack == AS_RUSH;
		else if (r == 2)
			bot.botpref_attack == AS_RETREAT;
		else
			bot.botpref_attack == AS_SMART;
		
		if (skill == 2 && random() >0.2)
			bot.botpref_attack == AS_SMART;
		
		if (skill > 2)
			bot.botpref_attack == AS_SMART;

//POX - Best Weapon Pref
		r = random();
		
		if (r > 0.5)
			bot.botpref_weapon = IT_PLASMAGUN;
		else
			bot.botpref_weapon = IT_ROCKET_LAUNCHER;


//POX - Reaction Time	
		if (skill == 0)
			bot.botpref_react = 0.1;
		
		if (skill == 1 || skill == 2)
		{
			r = random ();
			if (r > 0.1)
				r = 0.1;
			else if (r < 0.09)
				r = 0.09;
			
			bot.botpref_react = r;
		}
		
		if (skill > 2)
			bot.botpref_react == 0.01;

	
};
