#include "config.rh"

#include "client.rh"
#include "paroxysm.rh"

// prototypes

float	modelindex_eyes, modelindex_player;

// POX - more prototypes
.float	armor_rot;		//POX - Holds the armor rot time out

/*
=============================================================================
				LEVEL CHANGING / INTERMISSION
=============================================================================
*/

string nextmap;

//float	  intermission_running; 	// POX - moved to poxdefs.qc
float	intermission_exittime;


/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
	@self.angles = @self.mangle;	// so C can get at it
};

//POX v1.2
.float configed;

void() SetChangeParms =
{	
	//POX v1.1 - fresh start for everyone on changelevel
	
	//POX v1.2 - parms are used to store the Taget ID toggle, and to prevent running autoexec.cfg more than once per session
	parm1 = @self.target_id_toggle;
	parm2 = TRUE;
};

void() SetNewParms =
{
	// Quake Complains if this function isn't defined
};

void() DecodeLevelParms =
{
#ifdef QUAKEWORLD
	localcmd ("serverinfo playerfly 1");
#endif

	//POX v1.2 - parms are used to store the Taget ID toggle, and to prevent running autoexec.cfg more than once per session
	if(!@self.target_id_toggle && !@self.target_id_temp)
		@self.target_id_toggle = parm1;

#ifdef QUAKEWORLD
	@self.configed = parm2;

	if(!@self.target_id_toggle && !@self.target_id_temp)
		@self.target_id_toggle = parm1;
	
	@self.configed = parm2;
	
	//POX v1.2 - run autoexec.cfg ONCE when first joining server only!
	if (!@self.configed) {
		@self.configed = TRUE;
		stuffcmd (@self, "exec autoexec.cfg\n");
	}
#endif
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
	local entity	spot;
	local float		cyc;

	// look for info_intermission first
	if ((spot = find (world, classname, "info_intermission"))) {	// pick a random one
		cyc = random() * 4;
		while (cyc > 1) {
			spot = find (spot, classname, "info_intermission");
			if (!spot)
				spot = find (spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

	// then look for the start position
	if ((spot = find (world, classname, "info_player_start")))
		return spot;

	objerror ("FindIntermission: no spot");
	return nil;
};

void() GotoNextMap =
{
	/*
		configurable map lists, see if the current map exists as a
		serverinfo/localinfo var
	*/
	local string	newmap = INFOKEY (world, mapname);

	//ZOID: 12-13-96, samelevel is overloaded, only 1 works for same level
	if (cvar ("samelevel") == 1) {	// if samelevel is set, stay on same level
		changelevel (mapname);
	} else {
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
void() IntermissionThink =
{
	if (time < intermission_exittime)
		return;

	if (!@self.button0 && !@self.button1 && !@self.button2)
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
void() execute_changelevel =
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

void() changelevel_touch =
{
	if (other.classname != "player")
		return;
// if "noexit" is set, blow up the player trying to leave
//ZOID, 12-13-96, noexit isn't supported in QW.	 Overload samelevel
//	if ((cvar("noexit") == 1) || ((cvar("noexit") == 2) && (mapname != "start")))
	if ((cvar("samelevel") == 2) || ((cvar("samelevel") == 3) && (mapname != "start"))) {
		T_Damage (other, @self, @self, 50000);
		return;
	}
	BPRINT (PRINT_HIGH, other.netname);
	BPRINT (PRINT_HIGH," exited the level\n");
	
	nextmap = @self.map;
	SUB_UseTargets ();
	@self.touch = SUB_Null;
// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
	@self.think = execute_changelevel;
	@self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
	if (!@self.map)
		objerror ("chagnelevel trigger doesn't have map");
	
	InitTrigger ();
	@self.touch = changelevel_touch;
};
/*
=============================================================================
				PLAYER GAME EDGE FUNCTIONS
=============================================================================
*/

void() respawn =
{
	// make a copy of the dead body for appearances sake
	CopyToBodyQue (@self);
	// set default spawn parms
//	SetNewParms (); //POX v1.12
	// respawn		
	PutClientInServer ();
};

void() NextLevel; //POX v1.12

/*
============
ClientKill
Player entered the suicide command
============
*/
void() ClientKill =
{	
	//POX v1.12 - don't let LMS observers suicide!
	if (@self.classname == "LMSobserver") {
		sprint (@self, PRINT_HIGH, "Observers can't suicide!\n");
		return;
	}

	BPRINT (PRINT_MEDIUM, @self.netname);
	BPRINT (PRINT_MEDIUM, " suicides\n");
	set_suicide_frame ();
	@self.modelindex = modelindex_player;
	LOGFRAG (@self, @self);
	@self.frags -= 2;	// extra penalty

	//POX v1.12 - forgot about stink'n suicides
	if ((deathmatch & DM_LMS) && (@self.LMS_registered)) {
		if (@self.frags <= 0) {
			lms_plrcount = lms_plrcount - 1;
			
			@self.frags = 0;
			@self.LMS_registered = 0;
			@self.LMS_observer = 2;

			BPRINT (PRINT_HIGH, @self.netname);
			BPRINT (PRINT_HIGH, " is eliminated!\n");
			
			sound (@self, CHAN_BODY, "nar/n_elim.wav", 1, ATTN_NONE);

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
	local float 	numspots, pcount, totalspots;
	local entity	spot, spots, thing;

	numspots = 0;
	totalspots = 0;

	// testinfo_player_start is only found in regioned levels
	
	if ((spot = find (world, classname, "testplayerstart")))
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

		if (!pcount) {
			spot.goalentity = spots;
			spots = spot;
			numspots = numspots + 1;
		}

		// Get the next spot in the chain
		spot = find (spot, classname, "info_player_deathmatch");		
	}
	totalspots--;

	if (!numspots) {
		// ack, they are all full, just pick one at random
//		BPRINT (PRINT_HIGH, "Ack! All spots are full. Selecting random spawn spot\n");
		totalspots = rint (random () * totalspots);
		spot = find (world, classname, "info_player_deathmatch");
		do {
			spot = find (world, classname, "info_player_deathmatch");
		} while (totalspots-- > 0);
		return spot;
	}

// We now have the number of spots available on the map in numspots

	// Generate a random number between 1 and numspots
	numspots--;
	
	numspots = rint((random() * numspots ) );
	spot = spots;
	while (numspots > 0) {
		spot = spot.goalentity;
		numspots--;
	}
	return spot;
};

/*
===========
ValidateUser
============
*/
float(entity e) ValidateUser =
{
/*
	local string	userclan, s;
	local float	rank, rankmin, rankmax;
// if the server has set "clan1" and "clan2", then it
// is a clan match that will allow only those two clans in
	s = serverinfo("clan1");
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
	s = serverinfo("rankmin");
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
	return true;
*/
	return 1;
};

/*
===========
PutClientInServer
called each time a player enters a new level
============
*/
void() PutClientInServer =
{
	local entity	spot;
	
	// remove items
	@self.items &= ~(IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD);
	
	if (deathmatch & DM_LMS && @self.LMS_observer) {
		SpawnObserver ();
		return;
	}
	
	@self.classname = "player";
	@self.health = 100;
	@self.takedamage = DAMAGE_AIM;
	@self.solid = SOLID_SLIDEBOX;
	@self.movetype = MOVETYPE_WALK;
	@self.show_hostile = 0;
	@self.max_health = 100;
	@self.flags = FL_CLIENT;
	@self.air_finished = time + 12;
	@self.dmg = 2;			// initial water damage
	@self.super_damage_finished = 0;
	@self.radsuit_finished = 0;
	@self.invisible_finished = 0;
	@self.invincible_finished = 0;
	@self.effects = 0;
	@self.invincible_time = 0;
	
	// Give player some stuff
	@self.items = IT_AXE | IT_TSHOT;
	@self.ammo_shells = 25;
	@self.ammo_nails = 0;
	@self.ammo_rockets = 0;
	@self.ammo_cells = 0;	
	@self.weapon = IT_TSHOT;
	
	// Give player 50 points of blue armor
	@self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
	@self.items |= IT_ARMOR1;
	@self.armorvalue = 50;
	@self.armortype = 0.9;

	DecodeLevelParms (); // exec autoconfig if needed, restore Target ID value
	
	W_SetCurrentAmmo ();
	@self.attack_finished = time;
	@self.th_pain = player_pain;
	@self.th_die = PlayerDie;
	
	@self.deadflag = DEAD_NO;

	// pausetime is set by teleporters to keep the player from moving a while
	@self.pausetime = 0;
	
	// reset reload_rocket after death
	@self.reload_rocket = 0;

	// reset T-Shot after death
	@self.prime_tshot = FALSE;

	spot = SelectSpawnPoint ();
	@self.origin = spot.origin + '0 0 1';
	@self.angles = spot.angles;
	@self.fixangle = TRUE;		// turn this way immediately
	
	// oh, this is a hack!
	setmodel (@self, "progs/eyes.mdl");
	modelindex_eyes = @self.modelindex;
	setmodel (@self, "progs/player.mdl");
	modelindex_player = @self.modelindex;
	setsize (@self, VEC_HULL_MIN, VEC_HULL_MAX);
	
	@self.view_ofs = '0 0 22';

// Mod - Xian (May.20.97)
// Bug where player would have velocity from their last kill
	@self.velocity = '0 0 0';
	player_stand1 ();
	
	makevectors (@self.angles);
	spawn_tfog (@self.origin + v_forward * 20);
	spawn_tdeath (@self.origin, @self);

	// Set Rocket Jump Modifiers
	if (!(rj = stof (INFOKEY (world, "rj")))) {
		rj = 1;
	}

/*
	New deathmatch modes
*/
	// Last Man Standing
	if ((deathmatch & DM_LMS) && !@self.LMS_registered) {
		if (!fraglimit_LMS)
			@self.frags = 5;
		else
			@self.frags = fraglimit_LMS;
		
		@self.LMS_registered = TRUE;
		lms_plrcount++;
	}

	// Dark Mode - more stuff in Player_PostThink - doesn't work here (?)
	if (deathmatch & DM_DARK)
		flash_on (@self);
	
	// just in case a player dies in a colour_light field
//	stuffcmd (@self, "v_cshift 1 1 1 0\n");
	
	// Free For All mode
	if (deathmatch & DM_FFA) {	
		@self.ammo_nails = 200;
		@self.ammo_shells = 200;
		@self.ammo_rockets = 100;
		@self.ammo_cells = 200;
		@self.items |= IT_PLASMAGUN;
		@self.items |= IT_SUPER_NAILGUN;
		@self.items |= IT_COMBOGUN;
		@self.items |= IT_ROCKET_LAUNCHER;
		@self.items |= IT_GRENADE_LAUNCHER;
		
		@self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
		@self.items |= IT_ARMOR3;

		@self.armorvalue = 250;
		@self.armortype = 0.9;
		@self.health = 200;
		@self.items |= IT_INVULNERABILITY;
		@self.invincible_time = 1;
		@self.invincible_finished = time + 3;
		
		@self.weapon = IT_ROCKET_LAUNCHER;
		@self.currentammo = @self.ammo_rockets;
		@self.weaponmodel = "progs/v_rhino.mdl";
		@self.weaponframe = 0;
		@self.items |= IT_ROCKETS;
		
		@self.max_health = 200;
		sound (@self, CHAN_AUTO, "items/protect.wav", 1, ATTN_NORM);
		stuffcmd (@self, "bf\n");
	}
	
	// + POX - Predator mode
	if (deathmatch & DM_PREDATOR) {	
		sound (@self, CHAN_AUTO, "items/inv1.wav", 1, ATTN_NORM);
		stuffcmd (@self, "bf\n");

		@self.items |= IT_INVISIBILITY;
		@self.invisible_time = 1;
		@self.invisible_finished = time + 1999999999;
	}
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
	NextLevel ()

	go to the next level for deathmatch
*/
void() NextLevel =
{
	local entity	o;
	
	// + POX
	if (deathmatch & DM_LMS)
		lms_plrcount = 0;
	// - POX
	
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
			serverflags -= 7;
		}
 
		o = spawn ();
		o.map = mapname;
	} else {	// find a trigger changelevel
		o = find (world, classname, "trigger_changelevel");
		if (!o || mapname == "start") {	// go back to same map if no trigger_changelevel
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
void() CheckRules =
{     
	// Last Man Standing
	if ((deathmatch & DM_LMS) && lms_gameover) {
		NextLevel ();
		return;
	}

	if (timelimit && time >= timelimit)
		NextLevel ();
	
	if (fraglimit && @self.frags >= fraglimit)
		NextLevel ();
};

//============================================================================
void() PlayerDeathThink =
{
	local float		forward;

	if ((@self.flags & FL_ONGROUND)) {
		forward = vlen (@self.velocity);
		forward -= 20;
		if (forward <= 0)
			@self.velocity = '0 0 0';
		else	
			@self.velocity = forward * normalize (@self.velocity);
	}

	// wait for all buttons released
	if (@self.deadflag == DEAD_DEAD) {
		if (@self.button2 || @self.button1 || @self.button0)
			return;

		@self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

	// don't let players lay around as dead guys during a Last Man Standing game
	if (deathmatch & DM_LMS) {
		if (!(@self.button2 || @self.button1 || @self.button0))
			return;

		stuffcmd (@self, "wait;wait;wait;wait;wait;wait\n");
	}

	// wait for any button down
	if (!(@self.button2 || @self.button1 || @self.button0))
		return;

	@self.button0 = @self.button1 = @self.button2 = 0;
	respawn ();
};


void() PlayerJump =
{
	if (@self.flags & FL_WATERJUMP)
		return;
		
// + POX - Removed (new water sounds handled in WaterMove)
#if 0
	if (@self.waterlevel >= 2) {	// play swimming sound
		if (@self.swim_flag < time) {
			@self.swim_flag = time + 1;
			if (random () < 0.5)
				sound (@self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			else
				sound (@self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
		}
		return;
	}
#endif

// + POX - velocities changed in fluids
	if (@self.waterlevel >= 2) {
		switch (@self.watertype) {
			case CONTENT_WATER:
				@self.velocity_z = 100;
				break;
			case CONTENT_SLIME:
				@self.velocity_z = 80;
				break;
			default:
				@self.velocity_z = 50;
		}
		return;
	}
// - POX

	if (!(@self.flags & FL_ONGROUND))
		return;

	if (!(@self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick

	@self.flags &= ~FL_JUMPRELEASED;
	@self.button2 = 0;

	// player jumping sound
	sound (@self, CHAN_VOICE, "player/plyrjmp8.wav", 1, ATTN_NORM);
};

.float	dmgtime;

/*
===========
WaterMove
============
*/
void() WaterMove =
{
//	dprint (ftos (@self.waterlevel));
	if (@self.movetype == MOVETYPE_NOCLIP)
		return;
	if (@self.health < 0)
		return;
	if (@self.waterlevel != 3) {
		if (@self.air_finished < time)
			sound (@self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
		else if (@self.air_finished < time + 9)
			sound (@self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		@self.air_finished = time + 12;
		@self.dmg = 2;
	} else if (@self.air_finished < time) {	// drown!
		if (@self.pain_finished < time) {
			@self.dmg += 2;

			if (@self.dmg > 15)
				@self.dmg = 10;

			T_Damage (@self, world, world, @self.dmg);
			@self.pain_finished = time + 1;
		}
	}

	if (!@self.waterlevel) {
		if (@self.flags & FL_INWATER) {	// play leave water sound
			sound (@self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			@self.flags &= ~FL_INWATER;
			
			//POX v1.2 - fixed rare cases of underwater sound not cancelling out
			if (@self.outwsound == 1) {
				sound (@self, CHAN_BODY, "misc/owater2.wav", 0.5, ATTN_NORM);
				@self.outwsound = 0;
				@self.inwsound = 1;
				@self.uwmuffle = time;
			}
		}
		return;
	}

	switch (@self.watertype) {
		case CONTENT_LAVA:	// do damage
			if (@self.dmgtime < time) {
				if (@self.radsuit_finished > time)
					@self.dmgtime = time + 1;
				else
					@self.dmgtime = time + 0.2;

				T_Damage (@self, world, world, 10*@self.waterlevel);
			}
			break;
		case CONTENT_SLIME:	// do damage
			if (@self.dmgtime < time && @self.radsuit_finished < time) {
				@self.dmgtime = time + 1;
				T_Damage (@self, world, world, 4*@self.waterlevel);
			}
			break;
		default:
			break;
	}
	
	if (!(@self.flags & FL_INWATER)) {	// player enter water sound
		switch (@self.watertype) {
			case CONTENT_LAVA:
				sound (@self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
			case CONTENT_SLIME:
				sound (@self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);
			case CONTENT_WATER:
				sound (@self, CHAN_VOICE, "player/inh2o.wav", 1, ATTN_NORM);
			default:
				@self.flags |= FL_INWATER;
				@self.dmgtime = 0;
		}
	}	

// + POX - New water movement sounds
if (@self.waterlevel >= 3) {
		@self.onwsound = time;
		@self.outwsound = 1;
	
		if (@self.inwsound == 1) {
			sound (@self, CHAN_VOICE, "misc/inh2ob.wav", 1, ATTN_NORM);
			@self.inwsound = 0;
		}

		if (@self.uwmuffle < time) {
			sound (@self, CHAN_BODY, "misc/uwater.wav", 1, ATTN_STATIC);
			@self.uwmuffle = time + 3.58;
		}
	}
	
	if (@self.waterlevel == 2) {	
		if (@self.outwsound == 1) {
			sound (@self, CHAN_BODY, "misc/owater2.wav", 1, ATTN_NORM);
			@self.outwsound = 0;
			@self.inwsound = 1;
			//@self.onwsound = time + 1.9;
		}
		
		//POXnote
		//CheckWaterJump (); Not used in QW?
		
		@self.uwmuffle = time;
		
		/* POX - now done in footstep routine
		if (@self.onwsound < time) {	
			if (random() < 0.5)
				sound (@self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
			else
				sound (@self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
			
			@self.onwsound = time + random () * 2;
		}
		*/
	}
// - POX
};
void() CheckWaterJump =
{
	local vector start, end;
// check for a jump-out-of-water
	makevectors (@self.angles);
	start = @self.origin;
	start_z = start_z + 8; 
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, @self);
	if (trace_fraction < 1) {		// solid at waist
		start_z += @self.maxs_z - 8;
		end = start + v_forward * 24;
		@self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, @self);
		if (trace_fraction == 1) {	// open at eye level
			@self.flags |= FL_WATERJUMP;
			@self.velocity_z = 225;
			@self.flags &= ~FL_JUMPRELEASED;
			@self.teleport_time = time + 2;	// safety net
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
	if (intermission_running) {
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}
	if (@self.view_ofs == '0 0 0')
		return;		// intermission or finale
	makevectors (@self.v_angle);		// is this still used
	@self.deathtype = "";
	
	CheckRules ();
	
	// + POX - for LMS observer - POX 1.2 moved above WaterMove();
	if (deathmatch & DM_LMS && @self.LMS_observer) {	
		if (@self.deadflag >= DEAD_DEAD) {
			PlayerDeathThink ();
			return;
		}
		return;
	}
	// - POX
	WaterMove ();
/*
	if (@self.waterlevel == 2)
		CheckWaterJump ();
*/
	if (@self.deadflag >= DEAD_DEAD) {
		PlayerDeathThink ();
		return;
	}
	
	if (@self.deadflag == DEAD_DYING)
		return; // dying, so do nothing
	
	if (@self.button2) {
		PlayerJump ();
	}
	else
		@self.flags |= FL_JUMPRELEASED;
// teleporters can force a non-moving pause time	
	if (time < @self.pausetime)
		@self.velocity = '0 0 0';
	
	// POX
	if (deathmatch & DM_AUTOSWITCH) {
	
		if (time > @self.attack_finished && @self.currentammo == 0 && @self.weapon != IT_AXE) {
			@self.weapon = W_BestWeapon ();
			W_SetCurrentAmmo ();
		}
	}
};
	
/*
================
CheckPowerups
Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (@self.health <= 0)
		return;
// + POX - Rot armour down to 150 (max 250)
	if (@self.armorvalue > 150 && @self.armor_rot < time) {
		@self.armorvalue -= 1;
		@self.armor_rot = time + 1;

		// change armour to Yellow
		if (@self.armorvalue == 150) {
			@self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
			@self.items |= IT_ARMOR2;
		}
	}
// - POX
// invisibility
	if (@self.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (@self.invisible_sound < time) {
			sound (@self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			@self.invisible_sound = time + ((random() * 3) + 1);
		}
		if (@self.invisible_finished < time + 3) {
			if (@self.invisible_time == 1) {
				sprint (@self, PRINT_HIGH, "Cloak is failing...\n");
				stuffcmd (@self, "bf\n");
				sound (@self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				@self.invisible_time = time + 1;
			}
			
			if (@self.invisible_time < time) {
				@self.invisible_time = time + 1;
				stuffcmd (@self, "bf\n");
			}
		}
		if (@self.invisible_finished < time) {	// just stopped
			@self.items &= ~IT_INVISIBILITY;
			@self.invisible_finished = 0;
			@self.invisible_time = 0;
		}
		
	// use the eyes
		@self.frame = 0;
		@self.modelindex = modelindex_eyes;
	}
	else
		@self.modelindex = modelindex_player;	// don't use eyes
// invincibility
	if (@self.invincible_finished) {
// sound and screen flash when items starts to run out
		if (@self.invincible_finished < time + 3) {
			if (@self.invincible_time == 1) {
				sprint (@self, PRINT_HIGH, "MegaShields are almost burned out...\n");
				stuffcmd (@self, "bf\n");
				sound (@self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				@self.invincible_time = time + 1;
			}
			
			if (@self.invincible_time < time) {
				@self.invincible_time = time + 1;
				stuffcmd (@self, "bf\n");
			}
		}
		
		if (@self.invincible_finished < time) {	// just stopped
			@self.items &= ~IT_INVULNERABILITY;
			@self.invincible_time = 0;
			@self.invincible_finished = 0;
		}
		// + POX - ignore light effects in Dark Mode
		if (@self.invincible_finished > time && !(deathmatch & DM_DARK)) {
			@self.effects |= EF_DIMLIGHT;
			@self.effects |= EF_RED;
		} else {
			@self.effects &= ~EF_DIMLIGHT;
			@self.effects &= ~EF_RED;
		}
	}
// super damage
	if (@self.super_damage_finished) {
// sound and screen flash when items starts to run out
		if (@self.super_damage_finished < time + 3) {
			if (@self.super_time == 1) {
//				if (deathmatch == 4)
//					sprint (@self, PRINT_HIGH, "OctaPower is wearing off\n");
//				else
					sprint (@self, PRINT_HIGH, "Quad Damage is wearing off\n");
				stuffcmd (@self, "bf\n");
				sound (@self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				@self.super_time = time + 1;
			}

			if (@self.super_time < time) {
				@self.super_time = time + 1;
				stuffcmd (@self, "bf\n");
			}
		}
		if (@self.super_damage_finished < time) {	// just stopped
			@self.items &= ~IT_QUAD;
/*			
			if (deathmatch == 4) {
				@self.ammo_cells = 255;
				@self.armorvalue = 1;
				@self.armortype = 0.8;
				@self.health = 100;
			}
*/
			@self.super_damage_finished = 0;
			@self.super_time = 0;
		}

		if (@self.super_damage_finished > time) {
			@self.effects |= EF_DIMLIGHT;
			@self.effects |= EF_BLUE;
		} else {
			@self.effects &= ~EF_DIMLIGHT;
			@self.effects &= ~EF_BLUE;
		}
	}	

	// suit 
	if (@self.radsuit_finished) {
		@self.air_finished = time + 12;		// don't drown

		if (@self.radsuit_finished < time + 3) { // sound and flash when running out
			if (@self.rad_time == 1) {
				sprint (@self, PRINT_HIGH, "Air supply in Biosuit expiring\n");
				stuffcmd (@self, "bf\n");
				sound (@self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				@self.rad_time = time + 1;
			}

			if (@self.rad_time < time) {
				@self.rad_time = time + 1;
				stuffcmd (@self, "bf\n");
			}
		}

		if (@self.radsuit_finished < time) {	// just stopped
			@self.items &= ~IT_SUIT;
			@self.rad_time = 0;
			@self.radsuit_finished = 0;
		}
	}	
};

//POX v1.2 - PlayerRegen - for better handling of regen staion touch
.float armregen;
.float regen_finished;
void () PlayerRegen =
{   
	local float		type, bit;
	local string	snd;
	
	if (@self.armorvalue >= @self.armregen) {
		@self.regen_finished = time;
		return; // already have max armour that station can give
	}

	@self.armorvalue += 3;
	
	// Cap armour
	if (@self.armorvalue > @self.armregen)
		@self.armorvalue = @self.armregen;
	if (@self.armorvalue > 150) {	// Equivalent to Red (level 3) Armour
		type = 0.8;
		snd = "items/shield3.wav";
		bit = IT_ARMOR3;
	} else if (@self.armorvalue > 50) { // Equivlent to Yellow (level 2) Armour
		type = 0.8;
		snd = "items/shield2.wav";
		bit = IT_ARMOR2;
	} else if (@self.armorvalue > 1) {	// Equivlent to Blue (level 1) Armour
		type = 0.8;
		snd = "items/shield1.wav";
		bit = IT_ARMOR1;
	} else {	//you aint got squat
		type = 0;
		snd = "misc/null.wav";
		bit = 0;
	}
	
	// set armour type
	@self.armortype = type;
	@self.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
	@self.items |= bit;
	sound (@self, CHAN_AUTO, snd, 1, ATTN_NORM);
	
	//POX - 1.01b - Don't allow armour to rot while recharging
	@self.armor_rot = time + 5;
};

/*
================
PlayerPostThink
Called every frame after physics are run
================
*/
void () PlayerPostThink =
{
	//POX v1.2 - clear overrun v_cshifts!
	if (time < 1.5) 
		stuffcmd (@self, "bf\n");

	//POX v1.2 - cshift auto reset for colour_light
	if (@self.cshift_finished < time) {
		if (!@self.cshift_off) {
			stuffcmd (@self, "v_cshift 0 0 0 0\n");
			@self.cshift_off = TRUE;
		}
	}

	if (@self.view_ofs == '0 0 0')
		return;		// intermission or finale
	
	if (@self.deadflag)
		return;
	
	//+POX TESTING
	//local string howmanyplayers;
	//howmanyplayers = ftos(lms_plrcount);
	//sprint (@self, PRINT_HIGH, howmanyplayers);
	//-POX TESTING
	
	// + POX - for LMS observer
	if (deathmatch & DM_LMS && @self.LMS_observer) {
		ObserverThink ();
		return;
	}
	// - POX

	// check to see if player landed and play landing sound 
	if ((@self.jump_flag < -300) && (@self.flags & FL_ONGROUND)) {
		if (@self.jump_flag < -650) {
			local float	d;

			@self.deathtype = "falling";

			d = (@self.jump_flag + 625) * -0.1;	// scale damage by fall height
			T_Damage (@self, world, world, d);
			sound (@self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
		} else {
			sound (@self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
		}
	}
	@self.jump_flag = @self.velocity_z;

	//POX v1.2 - better regen touch handling
	if (@self.regen_finished > time)
		PlayerRegen ();
	
	CheckPowerups ();
	W_WeaponFrame ();
};
/*
===========
ClientConnect
called when a player connects to a server
============
*/
void() ClientConnect =
{
	/*
		Hard-code some environmental changes to prevent tampering a little...

		NOTE: autoexec.cfg is called at DecodeLevelParms (QW ignores it when
		called from quake.rc - which is also ignored)
	*/
	// POX v1.12 added 'fov 90' (mostly for lms_observer additions)
	stuffcmd (@self, "alias rules impulse 253; alias secondtrigger impulse 15; alias idtarget impulse 16; alias gllight impulse 17; wait; fov 90; v_idlescale 0.54; v_ipitch_cycle 3.5; v_ipitch_level 0.4; v_iroll_level 0.1; v_iyaw_level 0; v_kickpitch 0.8; v_kickroll 0.8; scr_conspeed 900; cl_bobcycle 0.8; cl_bobup 0; cl_bob 0.015\n");

	// LMS late-joiners get booted to spectate
	if (!(deathmatch & DM_LMS)) {
		BPRINT (PRINT_HIGH, @self.netname);
		BPRINT (PRINT_HIGH, " entered the game\n");
		centerprint (@self, "Paroxysm II v1.2.0\n");
	} else if (time < 40) { // Allow entrants for up to 40 secs after changelevel
		BPRINT (PRINT_HIGH, @self.netname);
		BPRINT (PRINT_HIGH, " entered the game\n");
			
		if (!lms_plrcount)
			centerprint (@self, "Paroxysm II v1.2.0\nLast Man Standing Rules Apply.\n\nWaiting for players...");
		else
			centerprint (@self, "Paroxysm II v1.2.0\nLast Man Standing Rules Apply.");
	} else {	// After 40 secs, If there are two or more players, go into observer mode
		if (!lms_plrcount) {	//First player arrived, let him wait around
			BPRINT (PRINT_HIGH, @self.netname);
			BPRINT (PRINT_HIGH, " entered the game\n");
			centerprint (@self, "Paroxysm II v1.2.0\nLast Man Standing Rules Apply.\n\nWaiting for players...");
		} else if (lms_plrcount == 1) { // second player arrived, so go to the next map (for a fair start)
			BPRINT (PRINT_HIGH, @self.netname);
			BPRINT (PRINT_HIGH, " entered the game\n");
			NextLevel ();	
		} else {	// LMS Game allready started so boot to observe
			BPRINT (PRINT_HIGH, @self.netname);
			BPRINT (PRINT_HIGH, " entered the game late!");
			// LMS reconnect as spectator
			@self.LMS_observer = 1;
		}
	}

	// a client connecting during an intermission can cause problems
	if (intermission_running)
		GotoNextMap ();
};

/*
	ClientDisconnect

	called when a player disconnects from a server
*/
void() ClientDisconnect =
{
	// let everyone else know
	BPRINT (PRINT_HIGH, @self.netname);
	BPRINT (PRINT_HIGH, " left the game with ");
	BPRINT (PRINT_HIGH, ftos (@self.frags));
	BPRINT (PRINT_HIGH, " frags\n");
	sound (@self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);

	if ((deathmatch & DM_LMS) && (@self.LMS_registered)) {
		lms_plrcount--;
		
		if (lms_plrcount <= 1) // 1 or 0 players left, end the game 
			NextLevel ();
	}
	
	set_suicide_frame ();
};

/*
	ClientObituary (entity, entity)

	called when a player dies
*/
void(entity targ, entity attacker) ClientObituary =
{
	local float 	rnum;
	local string	deathstring = "", deathstring2;
#ifdef QUAKEWORLD
	local string	attackerteam;
	local string	targteam;
#else
	local float	attackerteam;
	local float	targteam;
#endif
	local int	gibbed = (targ.health < -40);

#ifdef QUAKEWORLD
	attackerteam = INFOKEY (attacker, "team");
	targteam = INFOKEY (targ, "team");
#else
	attackerteam = attacker.team;
	targteam = targ.team;
#endif

	rnum = random ();

	if (targ.classname == "player") {
		if (deathmatch & DM_LMS) {	// Last Man Standing frag stuff...
			targ.frags--;
			//LOGFRAG (attacker, targ); // we don't log frags until the end

			if (targ.frags <= 0) {
				BPRINT (PRINT_HIGH, targ.netname + " is eliminated!\n");
				lms_plrcount--;

				sound (targ, CHAN_BODY, "nar/n_elim.wav", 1, ATTN_NONE);

				if (lms_plrcount <= 1) {	// end of game
					lms_gameover = TRUE; // Check this in CheckRules (so frag logging is still done)
					return;
				}

				// Put 'em into LMS observer mode at next spawn
				targ.frags = 0;
				targ.LMS_registered = 0;
				targ.LMS_observer = 2;
			}
		}
	
		if (attacker.classname == "teledeath") {
			LOGFRAG (attacker.owner, targ);

			if (!(deathmatch & DM_LMS)) // don't add frags in Last Man Standing
				attacker.owner.frags++;

			BPRINT (PRINT_MEDIUM, targ.netname
									+ " was telefragged by "
									+ attacker.owner.netname
									+ "\n");
			return;
		}

		if (attacker.classname == "teledeath2") {
			LOGFRAG (targ, targ);

			if (!(deathmatch & DM_LMS))
				targ.frags--;

			BPRINT (PRINT_MEDIUM, "MegaShields deflect "
									+ targ.netname
									+ "'s telefrag!\n");
			return;
		}

		// double MegaShield telefrag
		if (attacker.classname == "teledeath3") {
			LOGFRAG (targ, targ);

			if (!(deathmatch & DM_LMS)) // do regular obituary taunts in LMS
				targ.frags--;

			BPRINT (PRINT_MEDIUM, targ.netname
									+ " was telefragged by "
									+ attacker.owner.netname
									+ "'s MegaShield's power\n");
			return;
		}

		if (targ.deathtype == "squish") {
			if (attacker.classname == "player") {
				if (teamplay) {
					if ((targteam != "") && (targteam == attackerteam) && (targ != attacker)) {
						LOGFRAG (attacker, attacker);

						if (!(deathmatch & DM_LMS))
							attacker.frags--;

						BPRINT (PRINT_MEDIUM, attacker.netname + " squished a teammate\n");
						return;
					}
				}

				if (attacker != targ) {
					LOGFRAG (attacker, targ);

					if (!(deathmatch & DM_LMS))
						attacker.frags++;

					BPRINT (PRINT_MEDIUM, attacker.netname + " squishes "
											+ targ.netname + "\n");
					return;
				}
			} else {
				LOGFRAG (targ, targ);

				if (!(deathmatch & DM_LMS))
					targ.frags--;

				BPRINT (PRINT_MEDIUM, targ.netname + " was squished\n");
				return;
			}
		}

		if (attacker.classname == "player") {
			if (targ == attacker) { 	// killed self (dumbass!)
				LOGFRAG (attacker, attacker);
				
				if (!(deathmatch & DM_LMS))
					attacker.frags--;

				deathstring2 = "\n";

				switch (targ.deathtype) {
					case "grenade":
						if (rnum < 0.5)
							deathstring = " tries to put the pin back in";
						else
							deathstring = " throws the pin";
						break;

					case "impactgrenade":
						deathstring = " eats his own impact grenade";
						break;

					case "megaplasma":
						deathstring = " plays with the plasma";
						break;

					case "mine":
						if (rnum < 0.67)
							deathstring = " forgot where his phase mine was";
						else
							deathstring = " found his phase mine";
						break;

					case "nail":
						deathstring = " nails himself to the wall";
						break;

					case "rocket":
						if (rnum < 0.5)
							deathstring = " finds his rocket tasty";
						else
							deathstring = " plays \"Doctor Strangelove\"";
						break;

					case "shrapnel":
						if (rnum < 0.9)
							deathstring = " finds out what a shrapnel bomb does";
						else
							deathstring = " give us up the bomb";
						break;

					case "supernail":
						deathstring = " decides to use himself for a pin cushion";
						break;

					default:
						if (targ.weapon == IT_PLASMAGUN
								&& targ.waterlevel > 1) {
							deathstring = " discharges into the ";
							if (targ.watertype == CONTENT_SLIME)
								deathstring2 = "slime\n";
							else if (targ.watertype == CONTENT_LAVA)
								deathstring2 = "lava\n";
							else
								deathstring2 = "water\n";
						} else {
							deathstring = " becomes bored with life";
						}
				}

				BPRINT (PRINT_MEDIUM, targ.netname);
				BPRINT (PRINT_MEDIUM, deathstring);
				BPRINT (PRINT_MEDIUM, deathstring2);

				return;
			} else if ((teamplay & 2)
						&& (targteam == attackerteam)
						&& (attackerteam != "")) {

				LOGFRAG (attacker, attacker);
				
				if (!(deathmatch & DM_LMS))
					attacker.frags--;

				if (rnum < 0.25)
					deathstring = " mows down a teammate\n";
				else if (rnum < 0.50)
					deathstring = " checks his glasses\n";
				else if (rnum < 0.75)
					deathstring = " gets a frag for the other team\n";
				else
					deathstring = " loses another friend\n";

				BPRINT (PRINT_MEDIUM, attacker.netname);
				BPRINT (PRINT_MEDIUM, deathstring);

				return;
			} else {
				LOGFRAG (attacker, targ);
				
				if (!(deathmatch & DM_LMS))
					attacker.frags++;
				
				deathstring2 = "\n";

				switch (targ.deathtype) {
					case "nail":
						deathstring = " was nailed by ";
						break;

					case "supernail":
						deathstring = " was punctured by ";
						break;

					case "grenade":
						if (gibbed) {
							deathstring = " was gibbed by ";
							deathstring2 = "'s grenade\n";
							break;
						}
						deathstring = " eats ";
						deathstring2 = "'s pineapple\n";
						break;

					case "rocket":
						if (attacker.super_damage_finished > 0)
							deathstring2 = "'s quad rocket\n";
						else 
							deathstring2 = "'s rocket\n";

						if (gibbed) {
							if (rnum < 0.3) {
								deathstring = " was brutalized by ";
							} else if (rnum < 0.6) {
								deathstring = " was smeared by ";
							} else {
								BPRINT (PRINT_MEDIUM, attacker.netname
													+ " rips " + targ.netname
													+ " a new one!\n");
								return;
							}
						} else {
							deathstring = " rides ";
						}
						break;

					case "megaplasma":
						if (gibbed)
							deathstring = " was discombobulated by ";
						else
							deathstring = " bites ";
						deathstring2 = "'s plasma burst\n";
						break;

					case "impactgrenade":
						if (gibbed)
							deathstring = " was gibbed by ";
						else
							deathstring = " swallows ";
						deathstring2 = "'s impact grenade\n";
						break;

					case "mine":
						if (gibbed)
							deathstring = " is chum thanks to ";
						else
							deathstring = " stepped on ";
						deathstring2 = "'s phase mine\n";
						break;

					case "shrapnel":
						if (gibbed)
							deathstring = " gets a face full of ";
						else
							deathstring = " got too close to ";
						deathstring2 = "'s shrapnel bomb\n";
						break;
					default:
#ifdef QUAKEWORLD
						if (attacker.weapon == IT_AXE) {
#else
						if (attacker.weapon == IT_BONESAW) {
#endif
							deathstring = " was butchered by ";
							deathstring2 = "\n";
						} else if (attacker.weapon == IT_TSHOT) {
							deathstring = " chewed on ";
							deathstring2 = "'s boomstick\n";
						} else if (attacker.weapon == IT_COMBOGUN) {
							deathstring = " ate 2 loads of ";
							deathstring2 = "'s buckshot\n";
						} else if (attacker.weapon == IT_PLASMAGUN) {
							deathstring = " got burned by ";
							deathstring2 = "'s plasma\n";
						}
						break;
				}
				BPRINT (PRINT_MEDIUM, targ.netname + deathstring
									+ attacker.netname + deathstring2);
			}
			return;
		} else {	// traps, world stuff
			LOGFRAG (targ, targ);

			if (!(deathmatch & DM_LMS)) //POX 1.2 - do regular obituary taunts in LMS mode
				targ.frags--;

			if (attacker.classname == "explo_box" || attacker.classname == "explo_bsp")	{
				deathstring = " blew up\n";
			} else if (targ.deathtype == "falling") {
				deathstring = " fell to his death\n";
			} else if (targ.deathtype == "nail" || targ.deathtype == "supernail") {
				deathstring = " was spiked\n";
			} else if (targ.deathtype == "laser") {
				deathstring = " was zapped\n";
			} else if (attacker.classname == "fireball") {
				deathstring = " ate a lavaball\n";
			} else if (attacker.classname == "trigger_changelevel") {
				deathstring = " tried to leave\n";
			} else if (targ.watertype == CONTENT_SLIME) {
				if (rnum < 0.5)
					deathstring = " gulped down a load of slime\n";
				else
					deathstring = " can't exist on slime alone\n";
			} else if (targ.watertype == CONTENT_LAVA) {
				if (targ.health < -15) {
					deathstring = " burst into flames\n";
				} else if (rnum < 0.5) {
					deathstring = " turned into hot slag\n";
				} else {
					deathstring = " visits the Volcano God\n";
				}
			} else if (targ.watertype == CONTENT_WATER) {
				if (rnum < 0.5)
					deathstring = " sleeps with the fishes\n";
				else
					deathstring = " sucks it down\n";
			} else {
				if (rnum < 0.5)
					deathstring = " bought the farm\n";
				else
					deathstring = " died\n";
			}

			BPRINT (PRINT_MEDIUM, targ.netname + deathstring);
			return;
		}
	}
};
