// prototypes
void () W_WeaponFrame;
void () W_SetCurrentAmmo;
void () player_pain;
void () player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;

.float 	uwmuffle;								// under water muffle sound timeout
.float	onwsound;								// on water sound timeout
.float	outwsound;								// head out of water sound flag
.float	inwsound;								// head back in water sound flag

.float cshift_finished;
.float cshift_off;
.float armor_rot;

/*
=============================================================================

				LEVEL CHANGING / INTERMISSION

=============================================================================
*/

// POX v1.1 moved to weapons.qc
//float	intermission_running;
float	intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};

//POX v1.2
.float configed;

void() SetChangeParms =
{	
	//POX v1.1 - fresh start for everyone on changelevel
	
	//POX v1.2 - parms are used to store the Target ID toggle
	parm1 = self.target_id_toggle;

};

void() SetNewParms =
{
	// Quake Complains if this function isn't defined
};


void() DecodeLevelParms =
{
	//POX v1.2 - parms are used to store the Taget ID toggle
	if(!self.target_id_toggle && !self.target_id_temp)
		self.target_id_toggle = parm1;
	
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local	entity spot;
	local	float cyc;

// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot) {		// pick a random one
		cyc = random() * 4;
		while (cyc > 1) {
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc--;
		}
		return spot;
	}

// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;
	
// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;
	
	objerror ("FindIntermission: no spot");
};


string nextmap;
void() GotoNextMap =
{
	if (cvar ("samelevel"))	// if samelevel is set, stay on same level
		changelevel (mapname);
	else
		changelevel (nextmap);
};


void() ExitIntermission =
{
// skip any text in deathmatch
	if (deathmatch) {
		GotoNextMap ();
		return;
	}
	
	intermission_exittime = time + 1;
	intermission_running = intermission_running + 1;

	GotoNextMap();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!self.button0 && !self.button1 && !self.button2)
		return;
	
	ExitIntermission ();
};

void() execute_changelevel =
{
	local entity	pos;

	intermission_running = 1;
	
// enforce a wait time before allowing changelevel
	if (deathmatch)
		intermission_exittime = time + 5;
	else
		intermission_exittime = time + 2;

	WriteBytes (MSG_ALL, SVC_CDTRACK, 3.0, 3.0);
	
	pos = FindIntermission ();

	other = find (world, classname, "player");
	while (other != world) {
		other.view_ofs = '0 0 0';
		other.angles = other.v_angle = pos.mangle;
		other.fixangle = TRUE;		// turn this way immediately
		other.nextthink = time + 0.5;
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		setorigin (other, pos.origin);
		other = find (other, classname, "player");
	}	

	WriteByte (MSG_ALL, SVC_INTERMISSION);
};


void() changelevel_touch =
{
	local entity	pos;

	if (other.classname != "player")
		return;

	if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start"))) {
		T_Damage (other, self, self, 50000);
		return;
	}

	if (coop || deathmatch) {
		bprint (other.netname);
		bprint (" exited the level\n");
	}
	
	nextmap = self.map;

	SUB_UseTargets ();

	if ((self.spawnflags & 1) && (deathmatch == 0)) {	// NO_INTERMISSION
		GotoNextMap ();
		return;
	}
	
	self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!self.map)
		objerror ("chagnelevel trigger doesn't have map");
	
	InitTrigger ();
	self.touch = changelevel_touch;
};


/*
=============================================================================

				PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{	
	/*POX v1.1 no coop...
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn		
		PutClientInServer ();
	}
	else*/ if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// set default spawn parms
		//SetNewParms (); POX v1.1
		// respawn		
		PutClientInServer ();
	}
	else
	{	// restart the entire server
		localcmd ("restart\n");
	}
};


void() NextLevel;
/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
// KasCam ->
    if (self.classname == "KasCam") {
        return;
    }
// <- KasCam
	bprint (self.netname);
	bprint (" suicides\n");
	set_suicide_frame ();
	
	//self.modelindex = modelindex_player;
	//getmodel(self.weapon, self);
	
	self.frags = self.frags - 2;	// extra penalty
	
	//POX v1.12 - forgot about stink'n suidcides
	if ((deathmatch & DM_LMS) && (self.LMS_registered))
	{
		if (self.frags <= 0)
		{
			lms_plrcount = lms_plrcount - 1;
			
			self.frags = 0;
			
			bprint(self.netname);
			bprint(" is eliminated!\n");
			
			sound (self, CHAN_BODY, "nar/n_elim.wav", 1, ATTN_NONE);
	
			if (lms_plrcount <= 1) //1 player left so end the game 
				NextLevel ();
		}
	}
	
	respawn ();
};


float(vector v) CheckSpawnPoint =
{
	return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
	local	entity spot;
	local	entity thing;
	local	float  pcount;
	
// testinfo_player_start is only found in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;
		
// choose a info_player_deathmatch point
	if (coop)
	{
		lastspawn = find(lastspawn, classname, "info_player_coop");
		if (lastspawn == world)
			lastspawn = find (lastspawn, classname, "info_player_start");
		if (lastspawn != world)
			return lastspawn;
	}
	else if (deathmatch)
	{
		spot = lastspawn;
		while (1)
		{
			spot = find(spot, classname, "info_player_deathmatch");
			if (spot != world)
			{
				if (spot == lastspawn)
					return lastspawn;
				pcount = 0;
				thing = findradius(spot.origin, 32);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					lastspawn = spot;
					return spot;
				}
			}
		}
	}

	if (serverflags)
	{	// return with a rune to start
		spot = find (world, classname, "info_player_start2");
		if (spot)
			return spot;
	}
	
	spot = find (world, classname, "info_player_start");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");
	
	return spot;
};

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
//void() DecodeLevelParms; POX v1.1
void() PlayerDie;


void() PutClientInServer =
{
	local	entity spot;

	//spot = SelectSpawnPoint ();
	
	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	
	self.movetype = MOVETYPE_WALK;
	
	//POX v1.2 - remove items
	self.items &= ~(IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) );
	
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	
	self.effects = 0;
	self.invincible_time = 0;
	
// POX v1.1 - this stuff is nolonger handled by DecodeLevelParms
	self.items = IT_BONESAW | IT_TSHOT;
	self.ammo_shells = 25;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;	
	self.weapon = IT_TSHOT;
		
// POX v1.1 - spawn with 50 armour points
	self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR1;
	self.armorvalue = 50;
	self.armortype = 0.9;
	
//added 12/14/98 to resest reload_rocket after death
	self.reload_rocket = 0;

//added 12/22/98 to resest triple shot after death
	self.prime_tshot = FALSE;
	
	DecodeLevelParms (); //POX v1.2 - restore Target ID value
	
	//W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;
	
	self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;
	
	spot = SelectSpawnPoint ();

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately
	
	
//ChaseCam
	if ( self.aflag )
		CCamChasePlayer ();
//ChaseCam
	
	//Put client into the Dm setup menu
	if (deathmatch && world.model == "maps/start.bsp")
	{
		InitMenu();
		return;
     }


//Predator mode POX v1.11 - back to eyes
	if (deathmatch & DM_PREDATOR)
	{
		sound (self, CHAN_AUTO, "items/inv1.wav", 1, ATTN_NORM);
		stuffcmd (self, "bf\n");
		
		self.items |= IT_INVISIBILITY;
		self.invisible_time = 1;
		self.invisible_finished = time + 9999999999;
	}
	
	// oh, this is a hack!
	
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;
	
	//TEMPORARY!!!
	//setmodel (self, "progs/player.mdl");
	//modelindex_player = self.modelindex;
	
// Sine we're hack'n...
	setmodel (self, "progs/death_p.mdl");
	modelindex_death = self.modelindex;

	setmodel (self, "progs/bsaw_p.mdl");
	modelindex_saw_p = self.modelindex;

	setmodel (self, "progs/tshot_p.mdl");
	modelindex_tshot_p = self.modelindex;
	
	setmodel (self, "progs/combo_p.mdl");
	modelindex_combo_p = self.modelindex;
	
	setmodel (self, "progs/plasma_p.mdl");
	modelindex_plasma_p = self.modelindex;

	setmodel (self, "progs/nail_p.mdl");
	modelindex_nail_p = self.modelindex;

	setmodel (self, "progs/gren_p.mdl");
	modelindex_gren_p = self.modelindex;

	setmodel (self, "progs/rhino_p.mdl");
	modelindex_rock_p = self.modelindex;

//	setmodel (self, "progs/flame_p.mdl");
//	modelindex_flame_p = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	
	self.view_ofs = '0 0 22';

// Mod - Xian (May.20.97)
// Bug where player would have velocity from their last kill
// Modified by numb (Nov, 98)
	self.velocity = '0 0 0';
    self.velocity = normalize(self.velocity);
    
//Dark Mode
	if (deathmatch & DM_DARK)
	{	
		//pOx 1.4 - reset flashlight (always start on)
		//self.flash_flag = FALSE;
		//stuffcmd (self, "impulse 21\n");
		
		if (cvar("gl_cull") == 1)
			stuffcmd (self, "gl_flashblend 0\n");
	}
	
	else if (cvar("gl_cull") == 1)
		stuffcmd (self, "gl_flashblend 1\n");


//Last Man Standing Rules
	if (time < 30 && (deathmatch & DM_LMS) && !self.LMS_registered)
	{
		if (fraglimit_LMS == 0)
			self.frags = 5;
		else
			self.frags = fraglimit_LMS;
		
		self.LMS_registered = TRUE;
		lms_plrcount = lms_plrcount + 1;
	}

	
	player_stand1 ();
	
	//Check if dead in LMS mode
	if ((deathmatch & DM_LMS) && self.frags <= 0)
	{
		self.frags = 0;
		self.impulse = 250;
		//CamClientInit ();
	}

// + POX v1.1 changed the way this is handled - DM_FFA
	if (deathmatch & DM_FFA)
	{	
		self.ammo_nails = 200;
		self.ammo_shells = 200;
		self.ammo_rockets = 100;
		self.ammo_cells = 200;
		self.items |= IT_PLASMAGUN;
		self.items |= IT_SUPER_NAILGUN;
		self.items |= IT_COMBOGUN;
		self.items |= IT_ROCKET_LAUNCHER;
		self.items |= IT_GRENADE_LAUNCHER;
		
		self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR3;
		self.armorvalue = 250;
		self.armortype = 0.9;
		self.health = 200;
		self.items |= IT_INVULNERABILITY;
		self.invincible_time = 1;
		self.invincible_finished = time + 3;
		
		self.weapon = IT_ROCKET_LAUNCHER;
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rhino.mdl";
		self.weaponframe = 0;
		self.items |= IT_ROCKETS;
		
		self.max_health = 200;
		sound (self, CHAN_AUTO, "items/protect.wav", 1, ATTN_NORM);
		stuffcmd (self, "bf\n");
	}

	if (deathmatch || coop)
	{
		makevectors(self.angles);
		spawn_tfog (self.origin + v_forward*20);
		stuffcmd (self, "tele_zoom\n");
	}

	spawn_tdeath (self.origin, self);
	
	W_SetCurrentAmmo (); // VisWeap MOD: I moved this to the end so it will set the right model.
	
};


/*
=============================================================================

				QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
	local entity o;

	if (mapname == "start")
	{
		if (!cvar("registered"))
		{
			mapname = "e1m1";
		}
		else if (!(serverflags & 1))
		{
			mapname = "e1m1";
			serverflags |= 1;
		}
		else if (!(serverflags & 2))
		{
			mapname = "e2m1";
			serverflags |= 2;
		}
		else if (!(serverflags & 4))
		{
			mapname = "e3m1";
			serverflags |= 4;
		}
		else if (!(serverflags & 8))
		{
			mapname = "e4m1";
			serverflags = serverflags - 7;
		}

		o = spawn();
		o.map = mapname;
	}
	else
	{
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");

		// go back to start if no trigger_changelevel
		if (!o)
		{
			mapname = "start";
			o = spawn();
			o.map = mapname;
		}
	}

	nextmap = o.map;
	gameover = TRUE;
	
	if (o.nextthink < time)
	{
		o.think = execute_changelevel;
		o.nextthink = time + 0.1;
	}
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
	local	float		timelimit;
	local	float		fraglimit;
	
	if (gameover)	// someone else quit the game already
		return;
		
	timelimit = cvar("timelimit") * 60;
	fraglimit = cvar("fraglimit");
	
	if (timelimit && time >= timelimit)
	{
		NextLevel ();
		return;
	}
	
	if (fraglimit && self.frags >= fraglimit && !(deathmatch & DM_LMS))
	{
		NextLevel ();
		return;
	}
	
	if (lms_gameover == TRUE)
	{
		NextLevel ();
		return;
	}
	
};

//============================================================================

void() PlayerDeathThink =
{
	local entity	old_self;
	local float		forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else	
			self.velocity = forward * normalize(self.velocity);
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

//POX - don't let players lay around as dead guys during LMS
	if (!self.button2 && !self.button1 && !self.button0 && !(deathmatch & DM_LMS))
		return;

// wait for any button down

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn();
};


void() PlayerJump =
{
	local vector start, end;
	
	if (self.flags & FL_WATERJUMP)
		return;
	
	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;

		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	self.flags &= ~FL_JUMPRELEASED);

	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
	
	self.button2 = 0;
// player jumping sound
	sound (self, CHAN_VOICE, "player/plyrjmp8.wav", 1, ATTN_NORM);
	self.velocity_z = self.velocity_z + 270;
};


/*
==========
WaterMove


==========
*/
.float	dmgtime;

void() WaterMove =
{
//dprint (ftos(self.waterlevel));
	if (self.movetype == MOVETYPE_NOCLIP)
		return;
	if (self.health < 0)
		return;

	if (self.waterlevel != 3)
	{
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	}
	else if (self.air_finished < time)
	{	// drown!
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 2;
			if (self.dmg > 15)
				self.dmg = 10;
			T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}
	
	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{	
			// play leave water sound
			sound (self, CHAN_AUTO, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
			
			//POX v1.2 - fixed rare cases of underwater sound not cancelling out
			if (self.outwsound == 1)
			{
				sound (self, CHAN_BODY, "misc/owater2.wav", 0.5, ATTN_NORM);
				self.outwsound = 0;
				self.inwsound = 1;
				self.uwmuffle = time;
			}

		}		
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{	// do damage
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

			T_Damage (self, world, world, 10*self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{	// do damage
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4*self.waterlevel);
		}
	}
	
	if ( !(self.flags & FL_INWATER) )
	{	

// player enter water sound

		if (self.watertype == CONTENT_LAVA)
			sound (self, CHAN_AUTO, "player/inlava.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_AUTO, "player/inh2o.wav", 1, ATTN_NORM);
		if (self.watertype == CONTENT_SLIME)
			sound (self, CHAN_AUTO, "player/slimbrn2.wav", 1, ATTN_NORM);

		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}
	
	if (! (self.flags & FL_WATERJUMP) )
		self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;

//POX v1.1 - New water movement sounds - moved from PreThink (same as QW src)
if (self.waterlevel >= 3)
{
		self.onwsound = time;
		self.outwsound = 1;
	
		if (self.inwsound == 1)
		{
			sound (self, CHAN_VOICE, "misc/inh2ob.wav", 1, ATTN_NORM);
			self.inwsound = 0;
		}
	
		if (self.uwmuffle < time)
		{
			sound (self, CHAN_BODY, "misc/uwater.wav", 1, ATTN_STATIC);
			self.uwmuffle = time + 3.58;
		}
	}
	
	if (self.waterlevel == 2)
	{	
		if (self.outwsound == 1)
		{
			sound (self, CHAN_BODY, "misc/owater2.wav", 1, ATTN_NORM);
			self.outwsound = 0;
			self.inwsound = 1;
			//POX v1.1 - not needed, see footstep routine in player.qc
			//self.onwsound = time + 1.9;
		}
		
		self.uwmuffle = time;
		
		/* POX v1.1 - now done in footstep routine
		if (self.onwsound < time)
		{	
			if (random() < 0.5)
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			
			self.onwsound = time + random()*2;
		}
		*/
	}

};

void() CheckWaterJump =
{
	local vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8; 
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags |= FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags &= ~FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
	
	local	float	mspeed, aspeed;
	local	float	r;
	
	if (intermission_running)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale
	
	
//ChaseCam
	if ( self.aflag )
		CCamChasePlayer ();
//ChaseCam
	
	makevectors (self.v_angle);		// is this still used

	CheckRules ();
	WaterMove ();
	
	if (self.waterlevel == 2)
		CheckWaterJump ();
		
	
	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink ();
		return;
	}
	
	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

	if (self.button2)
	{
		PlayerJump ();
	}
	else
		self.flags |= FL_JUMPRELEASED;

// teleporters can force a non-moving pause time	
	if (time < self.pausetime)
		self.velocity = '0 0 0';

/* BEST WEAPON MARKER */
if (deathmatch & DM_AUTOSWITCH)
{
	if(time > self.attack_finished && self.currentammo == 0 && self.weapon != IT_BONESAW)
		{
			self.weapon = W_BestWeapon ();
			W_SetCurrentAmmo ();
		}
}
/* BEST WEAPON MARKER */
};

/*
================
CheckPowerups

Check for turning off powerups
================
*/

void() CheckPowerups =
{	

	if (self.health <= 0)
		return;

//POX - 1.01b - Rot armour down to 150
//Armour Rot
	if (self.armorvalue > 150 && self.armor_rot < time)
	{
		self.armorvalue = self.armorvalue - 1;
		self.armor_rot = time + 1;
		
	//POX v1.1 - change armour to Yellow
	if (self.armorvalue == 150)
		self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + IT_ARMOR2;
	}

// invisibility
	if (self.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}


		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint (self, "Cloak is failing...\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}
			
			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{       // just stopped
			self.items = self.items - IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}
		
	// use the eyes
		self.frame = 0;
		self.modelindex = modelindex_eyes;
	}
	else
		//self.modelindex = modelindex_player;	// don't use eyes
		getmodel(self.weapon, self);


// invincibility
	if (self.invincible_finished)
	{
// sound and screen flash when items starts to run out		
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint (self, "MegaShields are almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}
			
			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}
		
		if (self.invincible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
		
		//POX - ignore light effects in Dark Mode
		if (!(deathmatch & DM_DARK))
		{
			if (self.invincible_finished > time)
				self.effects |= EF_DIMLIGHT;
			else
				self.effects &= ~EF_DIMLIGHT);
		}
	}

// super damage
	if (self.super_damage_finished)
	{

// sound and screen flash when items starts to run out

		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				sprint (self, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}	  
			
			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.items = self.items - IT_QUAD;
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
		
		//POX - ignore light effects in Dark Mode
		if (!(deathmatch & DM_DARK))
		{
			if (self.super_damage_finished > time)
				self.effects |= EF_DIMLIGHT;
			else
				self.effects &= ~EF_DIMLIGHT);
		}
	}	

// suit	
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;		// don't drown

// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint (self, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}
			
			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.items = self.items - IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}	

};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{

	local	float	mspeed, aspeed;
	local	float	r;
	
	if (time < 1.5)	
		stuffcmd (self, "bf\n");//POX v1.2 - clear overrun v_cshifts!
	
	
	//POX v1.2 - cshift fix (colour_light)
	if (self.cshift_finished < time)
	{
		if (!self.cshift_off)
		{
			stuffcmd (self, "v_cshift 0 0 0 0\n");
			self.cshift_off = TRUE;
		}
	}
	
// KasCam ->
    if ((self.classname == "KasCam") && !intermission_running)
    {
        CamThink();
        return;
    }
// <- KasCam


//POX - Menu System
	if (deathmatch && world.model == "maps/start.bsp" && !intermission_running)
	{
		MenuThink();
		return;
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	
	if (self.deadflag)
		return;
		
// do weapon stuff

	W_WeaponFrame ();

// check to see if player landed and play landing sound	
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
	{	
		//DISABLED since additions to PlayerPreThink() now handle ALL water sounds
		
		//if (self.watertype == CONTENT_WATER)
		//	sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		//else
		
		if (self.jump_flag < -650)
		{
			T_Damage (self, world, world, 5); 
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
			self.deathtype = "falling";
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	CheckPowerups ();
	
	if (time < 15 && (!deathmatch))
		centerprint(self, "Paroxysm is Deathmatch Only.\nSelect Multiplayer in the main menu\n");	
	//else if (time < 3)
	//	centerprint(self, "Paroxysm v1.3\n");

	
};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
	//local float cno;

// KasCam ->
    if ((self.netname == "CamClient") || (self.netname == ""))
    {
    	stuffcmd (self, "autocam\n");
        //self.impulse = 250;
    }
	else
	{
// <- KasCam
	
	//POX - v1.3 - default TargetID to on
	self.target_id_temp = TRUE;
	self.target_id_toggle = TRUE;
	
	//POX v.11 FINALLY nailed this one
	//Players have 30 seconds to join an LMS game, or they are put into observer till changelevel
		if (!deathmatch & DM_LMS)
		{
			bprint (self.netname);
			bprint (" entered the game\n");
			centerprint(self, "Paroxysm v1.3\n");
			self.target_id_finished = time + 4;//POX v1.12 don't let TargetID override centerprints
		}
		else if ((time < 30) && (deathmatch & DM_LMS))	//POX 1.21
		{
			bprint (self.netname);
			bprint (" entered the game\n");
			centerprint(self, "Paroxysm v1.3\nLast Man Standing Rules Apply.");
			self.target_id_finished = time + 4;//POX v1.12 don't let TargetID override centerprints
		}
		else
		{
			bprint (self.netname);
			bprint (" entered the game late! Observing till next round.\n");
			
			self.LMS_late = TRUE;
			stuffcmd (self, "autocam\n");
			//self.impulse = 250;
		}
	}
	
	// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();

};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;
	// if the level end trigger has been activated, just return
	// since they aren't *really* leaving

	
	// let everyone else know
// KasCam ->
    if (CamDisconnect()) {
// KasCam <-
	bprint (self.netname);
	bprint (" left the game with ");
	bprint (ftos(self.frags));
	bprint (" frags\n");

	clientSetFree (self.fClientNo);
	
	//POX v1.11
	if (deathmatch & DM_LMS && self.classname == "player")
	{
		lms_plrcount = lms_plrcount - 1;
		
		if (lms_plrcount <= 1) //1 player left so end the game 
			lms_gameover = TRUE;
	}

	//sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
	set_suicide_frame ();
// KasCam ->
    }
// <- KasCam
};

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker) ClientObituary =
{
	local	float rnum;
	local	string deathstring, deathstring2;
	local	entity nar;
	rnum = random();
	
	//POX v1.2 - Changed this so obituary taunts work in DM_LMS
	//Lastman Standing POX v1.11 cleaned this up a bit
	if (deathmatch & DM_LMS)
	{
		if (targ.classname == "player")
			targ.frags = targ.frags - 1;
		
		if (targ.frags <= 0 && (targ.classname == "player"))
		{
			bprint(targ.netname);
			bprint(" is eliminated!\n");
			lms_plrcount = lms_plrcount - 1;
			
			sound (targ, CHAN_BODY, "nar/n_elim.wav", 1, ATTN_NONE);
			
			if (lms_plrcount <= 1) //1 player left so end the game 
				lms_gameover = TRUE;
			
			return;
		}
		
	}


	if (targ.classname == "player")
	{
		if (attacker.classname == "teledeath")
		{
			bprint (targ.netname);
			bprint (" was telefragged by ");
			bprint (attacker.owner.netname);
			bprint ("\n");
			
			if (!(deathmatch & DM_LMS)) //POX 1.2 - do regular obituary taunts in LMS mode
				attacker.owner.frags = attacker.owner.frags + 1;
         
			return;
		}

		if (attacker.classname == "teledeath2")
		{
			bprint ("MegaShields deflect ");
			bprint (targ.netname);
			bprint ("'s telefrag\n");
			
			if (!(deathmatch & DM_LMS)) //POX 1.2 - do regular obituary taunts in LMS mode
				targ.frags = targ.frags - 1;
		
			return;
		}

		if (attacker.classname == "player")
		{
			if (targ == attacker)
			{	
				if (!(deathmatch & DM_LMS)) //POX 1.2 - do regular obituary taunts in LMS mode
					attacker.frags = attacker.frags - 1;// killed self
				
				bprint (targ.netname);
				
				if (targ.weapon == 64 && targ.waterlevel > 1)
				{
					bprint (" discharges into the water.\n");
					return;
				}
				if (targ.weapon == IT_GRENADE_LAUNCHER)
					bprint (" tries to put the pin back in\n");
				else
					bprint (" becomes bored with life\n");
				
				return;
			}
			else if ( (teamplay == 2) && (targ.team > 0)&&(targ.team == attacker.team) )
			{
				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks his glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";
				bprint (attacker.netname);
				bprint (deathstring);
				
				if (!(deathmatch & DM_LMS)) //POX 1.2 - do regular obituary taunts in LMS mode
					attacker.frags = attacker.frags - 1;
			
				return;
			}
			else
			{
				if (!(deathmatch & DM_LMS)) //POX 1.2 - do regular obituary taunts in LMS mode
					attacker.frags = attacker.frags + 1;
	
				rnum = attacker.weapon;
				
				if (rnum == IT_BONESAW)
				{
					deathstring = " was butchered by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_TSHOT)
				{
					deathstring = " chewed on ";
					deathstring2 = "'s boomstick\n";
				}

				//Changed Combo Gun blurbs depending on the ammo
				if ((rnum == IT_COMBOGUN) && (attacker.which_ammo == 1))
				{
					deathstring = " swallowed ";
					deathstring2 = "'s pumkin ball\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s impact grenade\n";
					}
				}
				
				if ((rnum == IT_COMBOGUN) && (attacker.which_ammo == 0))
				{
					deathstring = " ate 2 loads of ";
					deathstring2 = "'s buckshot\n";
				}
				
			
				if (rnum == IT_PLASMAGUN)
				{
					deathstring = " was plugged by ";
					deathstring2 = "\n";
					if (targ.health < -40)
					{
						deathstring = " was discombobulated by ";
						deathstring2 = "'s plasma burst\n";
					}
				}
				if (rnum == IT_SUPER_NAILGUN)
				{
					deathstring = " was nailed by ";
					deathstring2 = "\n";
				}
				if (rnum == IT_GRENADE_LAUNCHER)
				{
					deathstring = " eats ";
					deathstring2 = "'s pineapple\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s grenade\n";
					}
				}
				if (rnum == IT_ROCKET_LAUNCHER)
				{
					deathstring = " rides ";
					deathstring2 = "'s rocket\n";
					if (targ.health < -40)
					{
						deathstring = " was gibbed by ";
						deathstring2 = "'s rockets\n" ;
					}
				}
				
				bprint (targ.netname);
				bprint (deathstring);
				bprint (attacker.netname);
				bprint (deathstring2);		
			}
			
			return;
		}
		else
		{
			if (!(deathmatch & DM_LMS)) //POX 1.2 - do regular obituary taunts in LMS mode
				targ.frags = targ.frags - 1;
		 
			bprint (targ.netname);
			
			// tricks and traps
			if (attacker.classname == "explo_box")
			{
				bprint (" blew up\n");
				return;
			}
			if (attacker.solid == SOLID_BSP && attacker != world)
			{	
				bprint (" was squished\n");
				return;
			}
			if (attacker.classname == "trap_shooter" || attacker.classname == "trap_spikeshooter")
			{
				bprint (" was spiked\n");
				return;
			}
			if (attacker.classname == "fireball")
			{
				bprint (" ate a lavaball\n");
				return;
			}
			if (attacker.classname == "trigger_changelevel")
			{
				bprint (" tried to leave\n");
				return;
			}
			//POX - orphaned shrapnel grenade
			if (attacker.classname == "shrapnel" || attacker.classname == "spikenal")
			{
				bprint (" got too close to a shrapnel bomb\n");
				return;
			}

			// in-water deaths

			rnum = targ.watertype;
				
			if (rnum == -3)
			{
				if (random() < 0.5)
					bprint (" sleeps with the fishes\n");
				else
					bprint (" sucks it down\n");
				return;
			}
			else if (rnum == -4)
			{
				if (random() < 0.5)
					bprint (" gulped a load of slime\n");
				else
					bprint (" can't exist on slime alone\n");
				return;
			}
			else if (rnum == -5)
			{
				if (targ.health < -15)
				{
					bprint (" burst into flames\n");
					return;
				}
				if (random() < 0.5)
					bprint (" turned into hot slag\n");
				else
					bprint (" visits the Volcano God\n");
				return;
			}

			// fell to their death?
			if (targ.deathtype == "falling")
			{
				targ.deathtype = "";
				bprint (" fell to his death\n");
				return;
			}

			// hell if I know; he's just dead!!!
			bprint (" died\n");
		}
	}
};
