float   modelindex_eyes, modelindex_player;

// LEVEL CHANGING / INTERMISSION ==============================================

string	nextmap;

float   intermission_running;
float   intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void ()
info_intermission =
{
	self.angles = self.mangle;      // so C can get at it
};

void ()
SetChangeParms =
{
	if (self.health <= 0) {
		SetNewParms ();
		return;
	}

	// remove items
	self.items &= ~(IT_KEY1 | IT_KEY2 | IT_INVISIBILITY |
					IT_INVULNERABILITY | IT_SUIT | IT_QUAD);

	// cap super health
	if (self.health > 100)
		self.health = 100;
	if (self.health < 50)
		self.health = 50;
	parm1 = self.items;
	parm2 = self.health;
	parm3 = self.armorvalue;
	if (self.ammo_shells < 25)
		parm4 = 25;
	else
		parm4 = self.ammo_shells;
	parm5 = self.ammo_nails;
	parm6 = self.ammo_rockets;
	parm7 = self.ammo_cells;
	parm8 = self.weapon;
	parm9 = self.armortype * 100;
};

void ()
SetNewParms =
{
	parm1 = IT_SHOTGUN | IT_AXE;
	parm2 = 100;
	parm3 = 0;
	parm4 = 25;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 1;
	parm9 = 0;
};

void ()
DecodeLevelParms =
{
	if (serverflags) {
		if (world.model == "maps/start.bsp")
			SetNewParms ();		// take away all stuff on starting new episode
	}

	self.items = parm1;
	self.health = parm2;
	self.armorvalue = parm3;
	self.ammo_shells = parm4;
	self.ammo_nails = parm5;
	self.ammo_rockets = parm6;
	self.ammo_cells = parm7;
	self.weapon = parm8;
	self.armortype = parm9 * 0.01;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity ()
FindIntermission =
{
	local entity	spot;
	local float		cyc;

	// look for info_intermission first
	spot = find (world, classname, "info_intermission");
	if (spot) {       // pick a random one
		cyc = 4 * random ();
		while (cyc > 1) {
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

	// then look for the start position
	spot = find (world, classname, "info_player_start");
	if (spot)
		return spot;

	objerror ("FindIntermission: no spot");
	return nil;		//FIXME need noreturn
};

void ()
GotoNextMap =
{
	local string	newmap;

	// ZOID: 12-13-96, samelevel is overloaded, only 1 works for same level
	if (cvar ("samelevel") == 1)     // if samelevel is set, stay on same level
		changelevel (mapname);
	else {
		// configurable map lists, see if the current map exists as a
		// serverinfo/localinfo var
		newmap = infokey (world, mapname);
		if (newmap != "")
			changelevel (newmap);
		else
			changelevel (nextmap);
	}
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void ()
IntermissionThink =
{
	if (time < intermission_exittime)
		return;
	if (!self.button0 && !self.button1 && !self.button2)
		return;

	GotoNextMap ();
};

/*
============
execute_changelevel

The global "nextmap" has been set previously.
Take the players to the intermission spot
============
*/
void ()
execute_changelevel =
{
	local entity	pos;

	intermission_running = 1;

	// enforce a wait time before allowing changelevel
	intermission_exittime = time + 5;

	pos = FindIntermission ();

	// play intermission music
	WriteBytes (MSG_ALL, SVC_CDTRACK, 3.0, SVC_INTERMISSION);
	WriteCoordV (MSG_ALL, pos.origin);
	WriteAngleV (MSG_ALL, pos.mangle);

	other = find (world, classname, "player");
	while (other != world) {
		other.takedamage = DAMAGE_NO;
		other.solid = SOLID_NOT;
		other.movetype = MOVETYPE_NONE;
		other.modelindex = 0;
		other = find (other, classname, "player");
	}       
};

void ()
changelevel_touch =
{
	if (other.classname != "player")
		return;

	// ZOID, 12-13-96, noexit isn't supported in QW.  Overload samelevel
	if ((cvar ("samelevel") == 2) || ((cvar ("samelevel") == 3)
									  && (mapname != "start"))) {
		T_Damage (other, self, self, 50000);
		return;
	}

	bprint (PRINT_HIGH, other.netname);
	bprint (PRINT_HIGH," exited the level\n");

	nextmap = self.map;

	SUB_UseTargets ();

	self.touch = SUB_Null;

	// we can't move people right now, because touch functions are called
	// in the middle of C movement code, so set a think time to do it
	self.think = execute_changelevel;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void ()
trigger_changelevel =
{
	if (!self.map)
		objerror ("chagnelevel trigger doesn't have map");

	InitTrigger ();
	self.touch = changelevel_touch;
};

// PLAYER GAME EDGE FUNCTIONS =================================================

void () set_suicide_frame;

// called by ClientKill and DeadThink
void ()
respawn =
{
	// make a copy of the dead body for appearances sake
	CopyToBodyQueue (self);
	// set default spawn parms
	SetNewParms ();
	// respawn              
	PutClientInServer ();
};

/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
	bprint (PRINT_MEDIUM, self.netname);
	bprint (PRINT_MEDIUM, " suicides\n");
	set_suicide_frame ();
	self.modelindex = modelindex_player;
	logfrag (self, self);
	self.frags -= 2;    // extra penalty
	respawn ();
};

float (vector v)
CheckSpawnPoint =
{
	return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity ()
SelectSpawnPoint =
{
	local entity	spot, spots, thing;
	local float		pcount, numspots, totalspots;

	numspots = 0;
	totalspots = 0;

	// testinfo_player_start is found only in regioned levels
	spot = find (world, classname, "testplayerstart");
	if (spot)
		return spot;

	// choose a info_player_deathmatch point

	// ok, find all spots that don't have players nearby
	spots = world;
	spot = find (world, classname, "info_player_deathmatch");
	while (spot) {
		totalspots++;

		thing = findradius (spot.origin, 84);
		pcount = 0;               
		while (thing) {
			if (thing.classname == "player")
				pcount++;                      
			thing = thing.chain;      
		}
		if (pcount == 0) {
			spot.goalentity = spots;
			spots = spot;
			numspots++;
		}

		// Get the next spot in the chain
		spot = find (spot, classname, "info_player_deathmatch");                
	}
	totalspots--;
	if (!numspots) {
		// ack, they are all full, just pick one at random
//		bprint (PRINT_HIGH, "Ackk! All spots are full. Selecting random spawn spot\n");
		totalspots = rint ((random () * totalspots));
		spot = find (world, classname, "info_player_deathmatch");       
		while (totalspots > 0) {
			totalspots--;
			spot = find (spot, classname, "info_player_deathmatch");
		}
		return spot;
	}

	// We now have the number of spots available on the map in numspots

	// Generate a random number between 1 and numspots
	numspots--;
	numspots = rint ((random () * numspots));

	spot = spots;
	while (numspots > 0) {
		spot = spot.goalentity;
		numspots--;
	}
	return spot;
};

float (entity e)
ValidateUser =
{
/*
	local string	userclan, s;
	local float		rank, rankmin, rankmax;

	// if the server has set "clan1" and "clan2", then it
	// is a clan match that will allow only those two clans in
	s = serverinfo ("clan1");
	if (s) {
		userclan = masterinfo (e, "clan");
		if (s == userclan)
			return true;
		s = serverinfo ("clan2");
		if (s == userclan)
			return true;
		return false;
	}

	// if the server has set "rankmin" and/or "rankmax" then
	// the users rank must be between those two values
	s = masterinfo (e, "rank");
	rank = stof (s);

	s = serverinfo ("rankmin");
	if (s) {
		rankmin = stof (s);
		if (rank < rankmin)
			return false;
	}
	s = serverinfo ("rankmax");
	if (s) {
		rankmax = stof (s);
		if (rankmax < rank)
			return false;
	}

*/
	return 1;
};

void () DecodeLevelParms;
void () PlayerDie;
void () W_SetCurrentAmmo;
void () player_stand1;
void (entity attacker, float damage) player_pain;
void (vector org, entity death_owner) spawn_tdeath;
void (vector org) spawn_tfog;

/*
===========
PutClientInServer

called each time a player enters a new level
============
*/
void ()
PutClientInServer =
{
	local entity	spot;

	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;                   // initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;

	DecodeLevelParms ();
	
	W_SetCurrentAmmo ();

	self.attack_finished = time;
	self.th_pain = player_pain;
	self.th_die = PlayerDie;
	
	self.deadflag = DEAD_NO;
	// pausetime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;
	
	spot = SelectSpawnPoint ();

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;           // turn this way immediately

	// oh, this is a hack!
	setmodel (self, "progs/eyes.mdl");
	modelindex_eyes = self.modelindex;

	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	
	self.view_ofs = '0 0 22';

	// Mod - Xian (May.20.97)
	// Bug where player would have velocity from their last kill
	self.velocity = '0 0 0';

	player_stand1 ();
	
	makevectors (self.angles);
	spawn_tfog (self.origin + v_forward*20);

	spawn_tdeath (self.origin, self);

	// Set Rocket Jump Modifiers
	if (stof (infokey (world, "rj")) != 0)
		rj = stof (infokey (world, "rj"));

	if (deathmatch == 4) {
		self.ammo_shells = 0;
		if (stof (infokey (world, "axe")) == 0) {
			self.ammo_nails = 255;
			self.ammo_shells = 255;
			self.ammo_rockets = 255;
			self.ammo_cells = 255;
			self.items |= (IT_NAILGUN | IT_SUPER_NAILGUN | IT_SUPER_SHOTGUN |
						   IT_ROCKET_LAUNCHER | IT_LIGHTNING);
		}
		self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
		self.items |= (IT_ARMOR3 | IT_INVULNERABILITY);
		self.armorvalue = 200;
		self.armortype = 0.8;
		self.health = 250;
		self.invincible_time = 1;
		self.invincible_finished = time + 3;
	}

	if (deathmatch == 5) {
		self.ammo_nails = 80;
		self.ammo_shells = 30;
		self.ammo_rockets = 10;
		self.ammo_cells = 30;
		self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
		self.items |= (IT_NAILGUN | IT_SUPER_NAILGUN | IT_SUPER_SHOTGUN |
					   IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER |
					   IT_LIGHTNING | IT_ARMOR3 | IT_INVULNERABILITY);
		self.armorvalue = 200;
		self.armortype = 0.8;
		self.health = 200;
		self.invincible_time = 1;
		self.invincible_finished = time + 3;
	}
};

// QUAKED FUNCTIONS ===========================================================

/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void ()
info_player_start =
{
};

/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void ()
info_player_start2 =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void ()
info_player_deathmatch =
{
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void ()
info_player_coop =
{
};

// RULES ======================================================================

// go to the next level for deathmatch
void ()
NextLevel =
{
	local entity	o;

	if (nextmap != "")
		return; // already done

	if (mapname == "start") {
		if (!cvar ("registered")) {
			mapname = "e1m1";
		} else if (!(serverflags & 1)) {
			mapname = "e1m1";
			serverflags |= 1;
		} else if (!(serverflags & 2)) {
			mapname = "e2m1";
			serverflags |= 2;
		} else if (!(serverflags & 4)) {
			mapname = "e3m1";
			serverflags |= 4;
		} else if (!(serverflags & 8)) {
			mapname = "e4m1";
			serverflags -= 7;	//FIXME &= ~7?
		}
 
		o = spawn ();
		o.map = mapname;
	} else {
		// find a trigger changelevel
		o = find(world, classname, "trigger_changelevel");
		if (!o || mapname == "start") {
			// go back to same map if no trigger_changelevel
			o = spawn ();
			o.map = mapname;
		}
	}

	nextmap = o.map;

	if (o.nextthink < time) {
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
void ()
CheckRules =
{       
	if (timelimit && time >= timelimit)
		NextLevel ();
	if (fraglimit && self.frags >= fraglimit)
		NextLevel ();
};

//============================================================================

void ()
PlayerDeathThink =
{
	local float		forward;

	if ((self.flags & FL_ONGROUND)) {
		forward = vlen (self.velocity) - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else    
			self.velocity = forward * normalize (self.velocity);
	}

	// wait for all buttons released
	if (self.deadflag == DEAD_DEAD) {
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

	// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	respawn ();
};

void ()
PlayerJump =
{
	if (self.flags & FL_WATERJUMP)
		return;
	
	if (self.waterlevel >= 2) {
		// play swiming sound
		if (self.swim_flag < time) {
			self.swim_flag = time + 1;
			if (random () < 0.5)
				sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}
		return;
	}

	if (!(self.flags & FL_ONGROUND))
		return;
	if (!(self.flags & FL_JUMPRELEASED))
		return;         // don't pogo stick

	self.flags &= ~FL_JUMPRELEASED;
	self.button2 = 0;

	// player jumping sound
	sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
};

.float  dmgtime;

void ()
WaterMove =
{
//	dprint (ftos (self.waterlevel));
	if (self.movetype == MOVETYPE_NOCLIP)
		return;
	if (self.health < 0)
		return;

	if (self.waterlevel != 3) {
		if (self.air_finished < time)
			sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		self.air_finished = time + 12;
		self.dmg = 2;
	} else if (self.air_finished < time) {
       // drown!
		if (self.pain_finished < time) {
			self.dmg += 2;
			if (self.dmg > 15)
				self.dmg = 10;
			T_Damage (self, world, world, self.dmg);
			self.pain_finished = time + 1;
		}
	}
	
	if (!self.waterlevel) {
		if (self.flags & FL_INWATER) {       
			// play leave water sound
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}

	if (self.watertype == CONTENT_LAVA) {
		// do damage
		if (self.dmgtime < time) {
			if (self.radsuit_finished > time)
				self.dmgtime = time + 1;
			else
				self.dmgtime = time + 0.2;

			T_Damage (self, world, world, 10 * self.waterlevel);
		}
	} else if (self.watertype == CONTENT_SLIME) {
		// do damage
		if (self.dmgtime < time && self.radsuit_finished < time) {
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4 * self.waterlevel);
		}
	}
	
	if (!(self.flags & FL_INWATER)) {
		// player enter water sound
		switch (self.watertype) {
		case CONTENT_LAVA:
			sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
			break;
		case CONTENT_WATER:
			sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
			break;
		case CONTENT_SLIME:
			sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);
			break;
		}
		self.flags |= FL_INWATER;
		self.dmgtime = 0;
	}
};

void ()
CheckWaterJump =
{
	local vector	start, end;

	// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8; 
	v_forward_z = 0;
	normalize (v_forward);
	end = start + v_forward * 24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1) {			// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward * 24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1) {		// open at eye level
			self.flags |= FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags &= ~FL_JUMPRELEASED;
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
void ()
PlayerPreThink =
{
	if (intermission_running) {
		IntermissionThink ();   // otherwise a button could be missed between
		return;                                 // the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;         // intermission or finale

	makevectors (self.v_angle);             // is this still used

        self.deathtype = "";

	CheckRules ();
	WaterMove ();
/*
	if (self.waterlevel == 2)
		CheckWaterJump ();
*/

	if (self.deadflag >= DEAD_DEAD) {
		PlayerDeathThink ();
		return;
	}
	
	if (self.deadflag == DEAD_DYING)
		return; // dying, so do nothing

	if (self.button2)
		PlayerJump ();
	else
		self.flags |= FL_JUMPRELEASED;

	// teleporters can force a non-moving pause time        
	if (time < self.pausetime)
		self.velocity = '0 0 0';

	if (time > self.attack_finished && self.currentammo == 0 && self.weapon
		!= IT_AXE) {
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
	}
};
	
/*
================
CheckPowerups

Check for turning off powerups
================
*/
void ()
CheckPowerups =
{
	if (self.health <= 0)
		return;

	// invisibility
	if (self.invisible_finished) {
		// sound and screen flash when items starts to run out
		if (self.invisible_sound < time) {
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((3 * random ()) + 1);
		}

		if (self.invisible_finished < time + 3) {
			if (self.invisible_time == 1) {
				sprint (self, PRINT_HIGH, "Ring of Shadows magic is fading\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}

			if (self.invisible_time < time) {
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time) {		// just stopped
			self.items -= IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}

		// use the eyes
		self.frame = 0;
		self.modelindex = modelindex_eyes;
	} else
		self.modelindex = modelindex_player;    // don't use eyes

	// invincibility
	if (self.invincible_finished) {
		// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3) {
			if (self.invincible_time == 1) {
				sprint (self, PRINT_HIGH, "Protection is almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}

			if (self.invincible_time < time) {
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}
		
		if (self.invincible_finished < time) {       // just stopped
			self.items &= ~IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}

		if (self.invincible_finished > time) {
			self.effects |= (EF_DIMLIGHT | EF_RED);
		} else {
			self.effects &= ~(EF_DIMLIGHT | EF_RED);
		}
	}

	// super damage
	if (self.super_damage_finished) {
		// sound and screen flash when items starts to run out
		if (self.super_damage_finished < time + 3) {
			if (self.super_time == 1) {
				if (deathmatch == 4)
					sprint (self, PRINT_HIGH, "OctaPower is wearing off\n");
				else
					sprint (self, PRINT_HIGH, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}         
			
			if (self.super_time < time) {
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time) {       // just stopped
			self.items &= ~IT_QUAD;
			if (deathmatch == 4) {
				self.ammo_cells = 255;
				self.armorvalue = 1;
				self.armortype = 0.8;
				self.health = 100;
			}
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
		if (self.super_damage_finished > time) {
			self.effects |= (EF_DIMLIGHT | EF_BLUE);
		} else {
			self.effects &= ~(EF_DIMLIGHT | EF_BLUE);
		}
	}       

	// suit 
	if (self.radsuit_finished) {
		self.air_finished = time + 12;				// don't drown

		// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3) {
			if (self.rad_time == 1) {
				sprint (self, PRINT_HIGH, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}
			
			if (self.rad_time < time) {
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time) {			// just stopped
			self.items &= ~IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}       
};

void () W_WeaponFrame;

/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void ()
PlayerPostThink =
{
//	dprint ("post think\n");
	if (self.view_ofs == '0 0 0')
		return;         // intermission or finale
	if (self.deadflag)
		return;

	// check to see if player landed and play landing sound 
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND)) {
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650) {
			self.deathtype = "falling";
			T_Damage (self, world, world, 5); 
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
		} else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
	}

	self.jump_flag = self.velocity_z;

	CheckPowerups ();

	W_WeaponFrame ();
};

/*
===========
ClientConnect

called when a player connects to a server
============
*/
void ()
ClientConnect =
{
	bprint (PRINT_HIGH, self.netname);
	bprint (PRINT_HIGH, " entered the game\n");

	// a client connecting during an intermission can cause problems
	if (intermission_running)
		GotoNextMap ();
};

/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void ()
ClientDisconnect =
{
	// let everyone else know
	bprint (PRINT_HIGH, self.netname);
	bprint (PRINT_HIGH, " left the game with ");
	bprint (PRINT_HIGH, ftos (self.frags));
	bprint (PRINT_HIGH, " frags\n");
	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
	set_suicide_frame ();
};

/*
===========
ClientObituary

called when a player dies
============
*/
void (entity targ, entity attacker)
ClientObituary =
{
	local float		rnum;
	local string	deathstring, deathstring2, attackerteam, targteam;

	rnum = random ();
	//ZOID 12-13-96: self.team doesn't work in QW.  Use keys
	attackerteam = infokey (attacker, "team");
	targteam = infokey (targ, "team");

	if (targ.classname == "player") {
		if (deathmatch > 3)	 {
			if (targ.deathtype == "selfwater") {
				bprint (PRINT_MEDIUM, targ.netname);
				bprint (PRINT_MEDIUM," electrocutes himself.\n ");
				targ.frags = targ.frags - 1;
				return;
			}
		}

		switch (attacker.classname) {
		case "teledeath":
			bprint (PRINT_MEDIUM,targ.netname);
			bprint (PRINT_MEDIUM," was telefragged by ");
			bprint (PRINT_MEDIUM,attacker.owner.netname);
			bprint (PRINT_MEDIUM,"\n");
			logfrag (attacker.owner, targ);

			attacker.owner.frags = attacker.owner.frags + 1;
			return;
		case "teledeath2":
			bprint (PRINT_MEDIUM,"Satan's power deflects ");
			bprint (PRINT_MEDIUM,targ.netname);
			bprint (PRINT_MEDIUM,"'s telefrag\n");

			targ.frags = targ.frags - 1;
			logfrag (targ, targ);
			return;
		case "teledeath3":
			// double 666 telefrag (can happen often in deathmatch 4)
			bprint (PRINT_MEDIUM,targ.netname);
			bprint (PRINT_MEDIUM," was telefragged by ");
			bprint (PRINT_MEDIUM,attacker.owner.netname);
			bprint (PRINT_MEDIUM, "'s Satan's power\n");
			targ.frags = targ.frags - 1;
			logfrag (targ, targ);
			return;
		}
	
		if (targ.deathtype == "squish") {
			if (teamplay && targteam == attackerteam && attackerteam != ""
				&& targ != attacker) {
				logfrag (attacker, attacker);
				attacker.frags = attacker.frags - 1; 
				bprint (PRINT_MEDIUM,attacker.netname);
				bprint (PRINT_MEDIUM," squished a teammate\n");
				return;
			} else if (attacker.classname == "player" && attacker != targ) {
				bprint (PRINT_MEDIUM, attacker.netname);
				bprint (PRINT_MEDIUM," squishes ");
				bprint (PRINT_MEDIUM,targ.netname);
				bprint (PRINT_MEDIUM,"\n");
				logfrag (attacker, targ);
				attacker.frags = attacker.frags + 1;
				return;
			} else {
				targ.frags--;					// killed self
				logfrag (targ, targ);
				bprint (PRINT_MEDIUM,targ.netname);
				bprint (PRINT_MEDIUM," was squished\n");
				return;
			}
		}

		if (attacker.classname == "player") {
			if (targ == attacker) {
				attacker.frags--;				// killed self
				logfrag (attacker, attacker);
				bprint (PRINT_MEDIUM,targ.netname);
				if (targ.deathtype == "grenade")
					bprint (PRINT_MEDIUM," tries to put the pin back in\n");
				else if (targ.deathtype == "rocket")
					bprint (PRINT_MEDIUM," becomes bored with life\n");
				else if (targ.weapon == 64 && targ.waterlevel > 1) {
					switch (targ.watertype) {
					case CONTENT_SLIME:
						bprint (PRINT_MEDIUM," discharges into the slime\n");
						break;
					case CONTENT_LAVA:
						bprint (PRINT_MEDIUM," discharges into the lava\n");
						break;
					default:
						bprint (PRINT_MEDIUM," discharges into the water.\n");
						break;
					}
				} else
					bprint (PRINT_MEDIUM," becomes bored with life\n");
				return;
			} else if ((teamplay == 2) && (targteam == attackerteam) &&
					   (attackerteam != "")) {
				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks his glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";
				bprint (PRINT_MEDIUM, attacker.netname);
				bprint (PRINT_MEDIUM, deathstring);
				attacker.frags--;
				//ZOID 12-13-96:  killing a teammate logs as suicide
				logfrag (attacker, attacker);
				return;
			} else {
				attacker.frags++;
				logfrag (attacker, targ);

				deathstring = deathstring2 = "'s quad rocket\n";

				switch (targ.deathtype) {
				case "nail":
					deathstring = " was nailed by ";
					deathstring2 = "\n";
					break;
				case "supernail":
					deathstring = " was punctured by ";
					deathstring2 = "\n";
					break;
				case "grenade":
					deathstring = " eats ";
					deathstring2 = "'s pineapple\n";
					if (targ.health < -40) {
						deathstring = " was gibbed by ";
						deathstring2 = "'s grenade\n";
					}
					break;
				case "rocket":
					if (attacker.super_damage_finished > 0 && targ.health
						< -40) {
						rnum = random ();
						if (rnum < 0.3)
							deathstring = " was brutalized by ";
						else if (rnum < 0.6)
							deathstring = " was smeared by ";
						else {
							bprint (PRINT_MEDIUM, attacker.netname);
							bprint (PRINT_MEDIUM, " rips ");
							bprint (PRINT_MEDIUM, targ.netname);
							bprint (PRINT_MEDIUM, " a new one\n");
							return;
						}
					} else {
						deathstring = " rides ";
						deathstring2 = "'s rocket\n";
						if (targ.health < -40) {
							deathstring = " was gibbed by ";
							deathstring2 = "'s rocket\n" ;
						}
					}
					break;
				default:
					switch (attacker.weapon) {
					case IT_AXE:
						deathstring = " was ax-murdered by ";
						deathstring2 = "\n";
						break;
					case IT_SHOTGUN:
						deathstring = " chewed on ";
						deathstring2 = "'s boomstick\n";
						break;
					case IT_SUPER_SHOTGUN:
						deathstring = " ate 2 loads of ";
						deathstring2 = "'s buckshot\n";
						break;
					case IT_LIGHTNING:
						deathstring = " accepts ";
						if (attacker.waterlevel > 1)
							deathstring2 = "'s discharge\n";
						else
							deathstring2 = "'s shaft\n";
						break;
					default:
						deathstring = " dies mysteriously ";
						deathstring2 = " progs bug\n";
						break;
					}
				}
				bprint (PRINT_MEDIUM, targ.netname);
				bprint (PRINT_MEDIUM, deathstring);
				bprint (PRINT_MEDIUM, attacker.netname);
				bprint (PRINT_MEDIUM, deathstring2);
			}
			return;
		} else {
			logfrag (targ, targ);
			targ.frags = targ.frags - 1;            // killed self

			bprint (PRINT_MEDIUM, targ.netname);
			switch (targ.watertype) {
			case -3:
				if (random () < 0.5)
					bprint (PRINT_MEDIUM, " sleeps with the fishes\n");
				else
					bprint (PRINT_MEDIUM, " sucks it down\n");
				return;
			case -4:
				if (random () < 0.5)
					bprint (PRINT_MEDIUM, " gulped a load of slime\n");
				else
					bprint (PRINT_MEDIUM, " can't exist on slime alone\n");
				return;
			case -5:
				if (targ.health < -15) {
					bprint (PRINT_MEDIUM, " burst into flames\n");
					return;
				}
				if (random () < 0.5)
					bprint (PRINT_MEDIUM, " turned into hot slag\n");
				else
					bprint (PRINT_MEDIUM, " visits the Volcano God\n");
				return;
			default:
				break;
			}

			if (attacker.classname == "explo_box") {
				bprint (PRINT_MEDIUM, " blew up\n");
				return;
			}

			switch (targ.deathtype) {
			case "falling":
				bprint (PRINT_MEDIUM, " fell to his death\n");
				return;
			case "nail":
			case "supernail":
				bprint (PRINT_MEDIUM, " was spiked\n");
				return;
			case "laser":
				bprint (PRINT_MEDIUM, " was zapped\n");
				return;
			case "fireball":
				bprint (PRINT_MEDIUM, " ate a lavaball\n");
				return;
			case "trigger_changelevel":
				bprint (PRINT_MEDIUM, " tried to leave\n");
				return;
			default:
				break;
			}

			bprint (PRINT_MEDIUM, " died\n");
		}
	}
};
