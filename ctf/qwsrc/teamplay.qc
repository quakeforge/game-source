/*
	#FILENAME#

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

	$Id$
*/

/****************************************************************************
 * ThreeWave Capture The Flag
 ****************************************************************************
 * Based on John Spikles Complete Enhanced Teamplay
 ****************************************************************************
 * Version 4.0 rewrite Mar 21, 1997
 ****************************************************************************/

/** Defs **/

/** MODIFIABLE CONSTANTS **/

float TEAM_DEFAULT_PENALTY =    1;      // Default frag penalty
float TEAM_STRICT_COOP =	0;	// Strict Coop

// Team colors
float TEAM_COLOR1       =       4;
float TEAM_COLOR2       =       13;

/** End of MODIFIABLE CONSTANTS **/

// Globals

entity team1_lastspawn;
entity team2_lastspawn;
float	nextteamupdtime;	// time until next team update
float last_flag_capture;	// time of last capture
float last_capture_team;	// last team that captured

float teamscr1;			// team 1's teamscr score
float teamscr2;			// team 2's teamscr score
float lastteamscrtime;		// last time we calculated it
float TEAMSCRTIME = 1;

// Teamplay bitfield entries

float TEAM_HEALTH_PROTECT =     1;      // No health damage from friendly fire
float TEAM_ARMOR_PROTECT =      2;      // No armor damage from friendly fire
float TEAM_ATTACKER_DAMAGE =    4;      // Attacker takes damage from hitting teammates
float TEAM_FRAG_PENALTY =       8;      // One frag penalty for killing teammate
float TEAM_DEATH_PENALTY =      16;     // Die when you kill a teammate.
float TEAM_LOCK_COLORS =        32;     // Allow only team colors
float TEAM_STATIC_TEAMS =       64;     // Don't allow players to switch teams
float TEAM_DROP_ITEMS = 	128;	// Allow players to drop packs and 
float TEAM_CAPTURE_FLAG =	256;	// Play capture the flag
float TEAM_DISABLE_GRAPPLE = 2048; // team selection

float TEAM_CAPTURE_CAPTURE_BONUS = 15; // what you get for capture
float TEAM_CAPTURE_TEAM_BONUS = 10; // what your team gets for capture
float TEAM_CAPTURE_RECOVERY_BONUS = 1; // what you get for recovery
float TEAM_CAPTURE_FLAG_BONUS = 0; // what you get for picking up enemy flag
float TEAM_CAPTURE_FRAG_CARRIER_BONUS = 2; // what you get for fragging
	//enemy flag carrier
float TEAM_CAPTURE_FLAG_RETURN_TIME = 40; // seconds until auto return

// XXX EXPERT CTF Additional scoring system

// bonuses

float TEAM_CAPTURE_CARRIER_DANGER_PROTECT_BONUS = 2; // bonus for fraggin someone
// who has recently hurt your flag carrier
float TEAM_CAPTURE_CARRIER_PROTECT_BONUS = 1; // bonus for fraggin someone while
// either you or your target are near your flag carrier
float TEAM_CAPTURE_FLAG_DEFENSE_BONUS = 1; // bonus for fraggin someone while
// either you or your target are near your flag
float TEAM_CAPTURE_RETURN_FLAG_ASSIST_BONUS = 1; // awarded for returning a flag that causes a
// capture to happen almost immediately
float TEAM_CAPTURE_FRAG_CARRIER_ASSIST_BONUS = 2; // award for fragging a flag carrier if a
// capture happens almost immediately

// radii

float TEAM_CAPTURE_TARGET_PROTECT_RADIUS = 400; // the radius around an object being
// defended where a target will be worth extra frags
float TEAM_CAPTURE_ATTACKER_PROTECT_RADIUS = 400; // the radius around an object being
// defended where an attacker will get extra frags when making kills

// timeouts

float TEAM_CAPTURE_CARRIER_DANGER_PROTECT_TIMEOUT = 4;
float TEAM_CAPTURE_CARRIER_FLAG_SINCE_TIMEOUT = 2;
float TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT = 6;
float TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT = 4;

float TEAM_CAPTURE_UPDATE_TIME = 120;

// END EXPERT CTF

// flag status used in cnt field of flag
float FLAG_AT_BASE = 0;
float FLAG_CARRIED = 1;
float FLAG_DROPPED = 2;


// Prototypes
float() W_BestWeapon;
void() W_SetCurrentAmmo;
void() bound_other_ammo;
void(float o, float n) Deathmatch_Weapon;
void() BackpackTouch;
void(entity who, string s) TeamPlayerUpdate;
void() TeamCaptureResetUpdate;

// Return a name for the color of a team
string(float Team) GetTeamColor =
{
	if(Team == 0) return("Grey");
	else if(Team == 1) return("Brown");
	else if(Team == 2) return("Steel blue");
	else if(Team == 3) return("Green");
	else if(Team == 4) return("Red");
	else if(Team == 5) return("Olive");
	else if(Team == 6) return("Orange");
	else if(Team == 7) return("Peech");
	else if(Team == 8) return("Purple");
	else if(Team == 9) return("Majenta");
	else if(Team == 10) return("Tan");
	else if(Team == 11) return("Aqua");
	else if(Team == 12) return("Yellow");
	else if(Team == 13) return("Blue");
	else if(Team == 14) return("Bright Orange");
	else if(Team == 15) return("Bright Red");
	return "Unknown";
};

// Return a name for the color of a team
string(float Team) GetShortTeamColor =
{
	Team = Team & 15; // color loops

	if(Team == 0) return("grey");
	else if(Team == 1) return("brwn");
	else if(Team == 2) return("sblu");
	else if(Team == 3) return("grn");
	else if(Team == 4) return("red");
	else if(Team == 5) return("olve");
	else if(Team == 6) return("orng");
	else if(Team == 7) return("pch");
	else if(Team == 8) return("purp");
	else if(Team == 9) return("majn");
	else if(Team == 10) return("tan");
	else if(Team == 11) return("aqua");
	else if(Team == 12) return("ylw");
	else if(Team == 13) return("blue");
	else if(Team == 14) return("bojn");
	else if(Team == 15) return("bred");
	return "Unknown";
};

// *XXX* EXPERT CTF
// Just a quickie to return the ASCII-ized team names for CTF
string(float Team) GetCTFTeam =
{

	if (Team == TEAM_COLOR1) return "“≈ƒ";
	if (Team == TEAM_COLOR2) return "¬Ã’≈";
	return "";
};


/*
================
TeamPrintSettings

Print out current teamplay options
================
*/

void() TeamPrintSettings =
{
	local string s;
	
	sprint(self, PRINT_HIGH, "The following Teamplay options are set:\n");
	
	if(teamplay < 0)
	{
		sprint(self,  PRINT_HIGH, "Frag penalty manually set to ");
		s = ftos(teamplay);
		sprint(self,  PRINT_HIGH, s);
		sprint(self,  PRINT_HIGH, "\n");
		return;
	}
	
	if(!teamplay) 
	{
		sprint(self,  PRINT_HIGH, "None\n");
		return;
	}
	
	if(1 == teamplay)
	{
		sprint(self, PRINT_HIGH, "ID's original teamplay 1\n");
		return;
	}
	
	if(teamplay & TEAM_HEALTH_PROTECT)
		sprint(self, PRINT_HIGH, "Health-Protect ");
	
	if(teamplay & TEAM_ARMOR_PROTECT)
		sprint(self, PRINT_HIGH, "Armor-Protect ");
		
	if(teamplay & TEAM_ATTACKER_DAMAGE)
		sprint(self, PRINT_HIGH, "Mirror-Damage ");
		
	if(teamplay & TEAM_FRAG_PENALTY)
		sprint(self, PRINT_HIGH, "Frag-Penalty ");
		
	if(teamplay & TEAM_DEATH_PENALTY)
		sprint(self, PRINT_HIGH, "Death-Penalty ");
		
	if(teamplay & TEAM_LOCK_COLORS)
		sprint(self, PRINT_HIGH, "Lock-Colors ");
		
	if(teamplay & TEAM_STATIC_TEAMS)
		sprint(self, PRINT_HIGH, "Static-Teams ");
		
	if(teamplay & TEAM_DROP_ITEMS)
		sprint(self, PRINT_HIGH, "Drop-Items (Backpack Impulse 20, Weapon Impulse 21) ");
		
	if(teamplay & TEAM_CAPTURE_FLAG)
		sprint(self, PRINT_HIGH, "Capture-The-Flag ");

	sprint(self, PRINT_HIGH, "\n");
};

/*
================
TeamArmorDam

Return TRUE if the target's armor can take damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamArmorDam =
{
        if( teamplay < 0 || gamestart)
                return TRUE;
        if( (teamplay & TEAM_ARMOR_PROTECT) && 
			attacker.steam == targ.steam && 
			attacker != targ) {
			// Armor is protected
			return FALSE;
        }
        return TRUE;
};

/*
================
TeamHealthDam

Return TRUE if the target can take health damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamHealthDam =
{
        if( teamplay < 0 || gamestart)
        {
                return TRUE;
        }
        if(attacker.steam == targ.steam && attacker != targ)
        {
                // Attacker and target are on the same team.
                if( teamplay & TEAM_ATTACKER_DAMAGE )
                {
                        // Damage applied to teammate.
                        T_Damage(attacker, inflictor, attacker, damage);
                }
                if( teamplay & TEAM_HEALTH_PROTECT )
                {
                        // Health is protected
                        return FALSE;
                }
        }
        return TRUE;
};

/*
================
TeamPFrags

Return the number of frags we should penalize attacker for killing targ.
================
*/

float(entity targ, entity attacker) TeamPFrags =
{
        if( teamplay < 0 )
                return (-1 * teamplay);
        if (targ != attacker && targ.steam == attacker.steam)
        {
                // targ and attacker are on the same team
                if( teamplay < 0 )
                {
                        // teamplay indicates frag penalty
                        return ( -1 * teamplay );
                }
                if( teamplay & TEAM_FRAG_PENALTY )
                {
                        // default penalty
                        return TEAM_DEFAULT_PENALTY;
                }
        }
        // No frag penalty
        return 0;
};

/*
================
TeamFragPenalty

If attacker should be penalized for killing targ, penalize attacker
and return TRUE.
================
*/

float(entity targ, entity attacker) TeamFragPenalty =
{
        local float f;

        f = TeamPFrags(targ, attacker);

        if( f )
        {
                // We should penalize some frags.
                attacker.frags = attacker.frags - f;
                return TRUE;
        }
        // No penalty
        return FALSE;
};

/*
=================
TeamDeathPenalty

If attacker should be killed for killing targ, kill attacker and
add a frag to offset the one attacker will lose for killing himself.
*/

void(entity targ, entity attacker) TeamDeathPenalty =
{
        //Don't kill anyone if teamplay is negative.
        if ( teamplay < 0 )
                return;

        if ( (teamplay & TEAM_DEATH_PENALTY) &&
			attacker != targ && attacker.steam == targ.steam)
        {
                //We should kill the attacker.
                T_Damage(attacker,attacker,attacker,1000);
                //Add a frag to offset the self-kill penalty.
                attacker.frags = attacker.frags + 1;
        }
};

/*
==================
TeamColorIsLegal

Return TRUE if the indicated color is legal
==================
*/
float(float color) TeamColorIsLegal =
{
        // All colors are legal if teamplay is negative.
        if( teamplay < 0 )
                return TRUE;
        // All colors are legal if TEAM_LOCK_COLORS is off.
        if( !(teamplay & TEAM_LOCK_COLORS) )
                return TRUE;
        if(color == TEAM_COLOR1)
                return TRUE;
        if(color == TEAM_COLOR2)
                return TRUE;
		return FALSE;
};

void() TeamSkinSet =
{
	if (self.ctfskinno == 1)
		self.ctfskin = "ctfr1";
	else if (self.ctfskinno == 2)
		self.ctfskin = "ctfr2";
	else if (self.ctfskinno == 3)
		self.ctfskin = "ctfb1";
	else if (self.ctfskinno == 4)
		self.ctfskin = "ctfb2";
	else if (self.steam == TEAM_COLOR1) 
		self.ctfskin = "ctfr1";
	else if (self.steam == TEAM_COLOR2) 
		self.ctfskin = "ctfb1";
	else
		self.ctfskin = "base";
};

void() TeamSkinAssign = 
{
	if (!(teamplay & TEAM_CAPTURE_FLAG))
		return;

	if (self.steam == TEAM_COLOR1)
		self.ctfskinno = 1;
	else
		self.ctfskinno = 3;
	if (random() < 0.5)
		self.ctfskinno = self.ctfskinno + 1;
	self.player_flag = self.player_flag - (self.player_flag & 65280);
	self.player_flag = self.player_flag + (self.ctfskinno * 256);

	TeamSkinSet();
};

float(float tcolor, float bcolor) CrossDressCheck =
{
	// All colors are legal is teamplay is negative.
	if(teamplay < 0)
		return FALSE;
	// All colors are legal is TEAM_LOCK_COLORS is off.
	if( !(teamplay & TEAM_LOCK_COLORS) )
		return FALSE;
	if(tcolor == TEAM_COLOR1 && bcolor == TEAM_COLOR2)
		return TRUE;
	if(tcolor == TEAM_COLOR2 && bcolor == TEAM_COLOR1)
		return TRUE;
	return FALSE;
};

/*
==================
TeamAssign

Check if the team self is on is legal, and put self in a legal team if not.
==================
*/
void() TeamAssign =
{
	local float TEAM1;
	local float TEAM2;
	local float newcolor;
	local entity p;
	local string n; 

	if (self.steam >= 0)  
		if(TeamColorIsLegal(self.steam)) {
			TeamSkinAssign();
			return;
		}

	// Assign the player to a team.

	// Sum the players on all the teams.
	TEAM1 = 0;
	TEAM2 = 0;

	p = find (world, classname, "player");

	while(p)
	{
		if (p != self && !(p.player_flag & PF_GHOST)) {
			if (p.steam == TEAM_COLOR1)
				TEAM1 = TEAM1 + 1;
			else if (p.steam == TEAM_COLOR2)
				TEAM2 = TEAM2 + 1;
		}
		p = find(p, classname, "player");
	}

	// Find the team with the least players.
	if (TEAM1 < TEAM2 || ((TEAM1 == TEAM2) && (random() < 0.5)))
		newcolor = TEAM_COLOR1;
	else
		newcolor = TEAM_COLOR2;

	// Put the player on a the new team.
	sprint(self, PRINT_HIGH, "You have been assigned to ");
	n = GetTeamColor(newcolor);
	sprint(self, PRINT_HIGH, n);
	sprint(self, PRINT_HIGH, " team.\n");

	self.steam = newcolor;
	TeamSkinAssign();

	self.player_flag = self.player_flag | TEAM_STUFF_COLOR;
};

/*
===============
TeamCheckLock

Check for team changing and perform whatever actions are neccessary.
===============
*/
void() TeamCheckLock =
{
        local   float   n;
        local   string  s, t;
		local	float	pteam;

        // Don't do anything if teamplay is negative
        if ( teamplay < 0 )
                return;

		if (gamestart) {
			s = infokey(self, "bottomcolor");
			pteam = stof(s);
			if (pteam != 0)
				stuffcmd(self, "setinfo bottomcolor 0\n");
			self.steam = -1;
			return;
		}


		if (self.player_flag & TEAM_STUFF_COLOR) {
			self.player_flag = self.player_flag - TEAM_STUFF_COLOR;
			s = ftos(self.steam);
			stuffcmd(self, "setinfo bottomcolor ");
			stuffcmd(self, s);
			stuffcmd(self, "\n");

			s = infokey(self, "topcolor");
			n = stof(s);
			if (CrossDressCheck(n, self.steam)) {
				s = ftos(self.steam);
				stuffcmd(self, "setinfo topcolor ");
				stuffcmd(self, s);
				stuffcmd(self, "\n");
			}

			s = GetShortTeamColor(self.steam);
			stuffcmd(self, "setinfo team ");
			stuffcmd(self, s);
			stuffcmd(self, "\n");

			if (teamplay & TEAM_CAPTURE_FLAG) {
				stuffcmd(self, "setinfo skin ");
				stuffcmd(self, self.ctfskin);
				stuffcmd(self, "\n");
			}
			


			self.lastteamset = time;
			return;
		}

		s = infokey(self, "bottomcolor");
		pteam = stof(s);

		// Check to see if the player has changed skins
		if (self.steam > 0 && time - self.lastteamset > 2) {
			if (teamplay & TEAM_CAPTURE_FLAG)
				if (infokey(self, "skin") != self.ctfskin) {
					stuffcmd(self, "setinfo skin ");
					stuffcmd(self, self.ctfskin);
					stuffcmd(self, "\n");
					self.lastteamset = time;
				}

			s = GetShortTeamColor(self.steam);
			if (infokey(self, "team") != s) {
				stuffcmd(self, "setinfo team ");
				stuffcmd(self, s);
				stuffcmd(self, "\n");
				self.lastteamset = time;
			}
		}

		// check for crossdressing
		s = infokey(self, "topcolor");
		n = stof(s);
		if (CrossDressCheck(n, self.steam)) {
			s = ftos(self.steam);
			stuffcmd(self, "setinfo topcolor ");
			stuffcmd(self, s);
			stuffcmd(self, "\n");
			return;
		}

        // Check to see if the player has changed colors
		if (time - self.lastteamset > 2 && pteam != self.steam) 
		{
			// Player has changed colors

			// If teams are static and we've been on some team already,
			// put us back on the team we were on.

			if ((teamplay & TEAM_STATIC_TEAMS) && (self.steam >= 0)) {

				if (TeamColorIsLegal(self.steam)) {
					// changing teams sucks, kill him

					// if he has tried to change teams several
					// times, kick him off the server.
					if (self.suicide_count > 3) {
						sprint(self, PRINT_HIGH, "You were told you can't change teams.\nGo play color games somewhere else.\n");
						stuffcmd(self, "disconnect\n");
						bprint(PRINT_MEDIUM, self.netname);
						bprint(PRINT_MEDIUM, " has bad color sense\n");
					}
					// case base respawn
					self.killed = 99;
					T_Damage(self,self,self,1000);  // Kill the player
					self.killed = 2;
					// trying to change teams counts as a suicide
					self.suicide_count = self.suicide_count + 1;
					logfrag(self, self); // he pays for it

					sprint(self, PRINT_HIGH, "You cannot change teams.\n");
					stuffcmd(self, "setinfo bottomcolor ");
					s = ftos(self.steam);
					stuffcmd(self, s);
					stuffcmd(self, "\n");
					self.lastteamset = time;
					return;
				} else {
						// If we're on an illegal team, force a change.
						self.steam = -1;
				}
			} else

			// If teamlock is turned off, don't do anything more.
			if ( !(teamplay & TEAM_LOCK_COLORS) )
				return;

			if (self.steam >= 0) {
				// case base respawn
				self.killed = 99;
				T_Damage(self,self,self,1000);  // Kill the player
				self.killed = 0;
			}

			self.steam = pteam;
			self.frags = 0;                 // Zero out frags
			TeamAssign();
        }
};

/*
=======================
TossBackPack

Original idea by Vhold
Rewritten by John Spickes

Toss out a backpack containing some ammo from your current weapon,
and any weapons you don't have.
=======================
*/
void() TossBackpack =
{
	local entity 	item;

        // If we don't have any ammo, return (except AXE/GRAPPLE) 
        if(self.currentammo <= 0)
        {
                if (self.weapon != IT_AXE &&  self.weapon != IT_GRAPPLE)
		return;
        }

	item = spawn();

	// See if you have the Shotgun or Super Shotgun on
        if ( (self.weapon == IT_SHOTGUN) || (self.weapon == IT_SUPER_SHOTGUN)) {
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		}
		else
		{
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}		
	
	// See if you have neither the Shotgun or Super Shotgun
        if ( !(self.items & IT_SHOTGUN) && !(self.items & IT_SUPER_SHOTGUN)) {
		if( self.ammo_shells >= 20 ) {
			item.ammo_shells = 20;
			self.ammo_shells = self.ammo_shells - 20;
		}
		else
		{
			item.ammo_shells = self.ammo_shells;
			self.ammo_shells = 0;
		}
	}		
	
	// See if we are using a nailgun
        if ( (self.weapon == IT_NAILGUN) || (self.weapon == IT_SUPER_NAILGUN) )
	{
		if( self.ammo_nails >= 20 )
		{
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		}
		else
		{
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}	
	// Check to see if we have neither nailgun
        if ( !(self.items & IT_NAILGUN) && !(self.items & IT_SUPER_NAILGUN) )
	{
		if( self.ammo_nails >= 20 )
		{
			item.ammo_nails = 20;
			self.ammo_nails = self.ammo_nails - 20;
		}
		else
		{
			item.ammo_nails = self.ammo_nails;
			self.ammo_nails = 0;
		}
	}	
	
	// See if we are using a grenade or rocket launcher
        if ( (self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER) )
	{
		if( self.ammo_rockets >= 10 )
		{
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		}
		else
		{
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}
	// See if we have neither the Grenade or rocket launcher
        if ( !(self.items & IT_GRENADE_LAUNCHER) && !(self.items & IT_ROCKET_LAUNCHER) )
	{
		if( self.ammo_rockets >= 10 )
		{
			item.ammo_rockets = 10;
			self.ammo_rockets = self.ammo_rockets - 10;
		}
		else
		{
			item.ammo_rockets = self.ammo_rockets;
			self.ammo_rockets = 0;
		}
	}

	// See if we're using the lightning gun
	if ( self.weapon == IT_LIGHTNING )
	{	
		if( self.ammo_cells >= 20 )
		{
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		}
		else
		{
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}
	// see if we don't have the lightning gun
        if ( !(self.items & IT_LIGHTNING) )
	{	
		if( self.ammo_cells >= 20 )
		{
			item.ammo_cells = 20;
			self.ammo_cells = self.ammo_cells - 20;
		}
		else
		{
			item.ammo_cells = self.ammo_cells;
			self.ammo_cells = 0;
		}
	}
	 

	if (!item.ammo_shells && !item.ammo_nails && !item.ammo_rockets &&
		!item.ammo_cells) {
		// we didn't put anything in
		remove(item);
		return;
	}

	item.owner = self;
	makevectors(self.v_angle);

	setorigin(item, self.origin + '0 0 16');
	item.velocity = aim(self, 1000);
	item.velocity = item.velocity * 500;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;

	setmodel (item, "progs/backpack.mdl");
	setsize(item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
	item.nextthink = time + 120;	// remove after 2 minutes
	item.think = SUB_Remove;

	W_SetCurrentAmmo();

};

void() Team_weapon_touch =
{
	local	float	hadammo, best, new, old;
	local entity stemp;

	if (!(other.flags & FL_CLIENT))
		return;
	// Don't let the owner pick up his own weapon for a second.
	if ( (other == self.owner) && ( (self.nextthink - time) > 119 ) )
		return;

// if the player was using his best weapon, change up to the new one if better		
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

	if (self.classname == "weapon_nailgun")
	{
		hadammo = other.ammo_nails;			
		new = IT_NAILGUN;
	}
	else if (self.classname == "weapon_supernailgun")
	{
		hadammo = other.ammo_rockets;			
		new = IT_SUPER_NAILGUN;
	}
	else if (self.classname == "weapon_supershotgun")
	{
		hadammo = other.ammo_rockets;			
		new = IT_SUPER_SHOTGUN;
	}
	else if (self.classname == "weapon_rocketlauncher")
	{
		hadammo = other.ammo_rockets;			
		new = IT_ROCKET_LAUNCHER;
	}
	else if (self.classname == "weapon_grenadelauncher")
	{
		hadammo = other.ammo_rockets;			
		new = IT_GRENADE_LAUNCHER;
	}
	else if (self.classname == "weapon_lightning")
	{
		hadammo = other.ammo_rockets;			
		new = IT_LIGHTNING;
	}
	else
		objerror ("Team_weapon_touch: unknown classname");

	sprint (other, PRINT_LOW, "You got the ");
	sprint (other, PRINT_LOW, self.netname);
	sprint (other, PRINT_LOW, "\n");
// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	bound_other_ammo ();

// change to the weapon
	old = other.items;
	other.items = other.items | new;
	
	remove(self);
	self = other;

	if (!deathmatch)
		self.weapon = new;
	else
		Deathmatch_Weapon (old, new);

	W_SetCurrentAmmo();

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};
        
void() TossWeapon =
{
	local entity item;
	
	if (deathmatch != 1)
		return;  // only in deathmatch 1

	if( (self.weapon == IT_AXE) || (self.weapon == IT_SHOTGUN) || (self.weapon == IT_GRAPPLE) )
		return;
		
	item = spawn();
	item.owner = self;
	makevectors(self.v_angle);

	setorigin(item, self.origin + '0 0 16');
	item.velocity = aim(self, 1000);
	item.velocity = item.velocity * 500;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_BOUNCE;
	
	if(self.weapon == IT_SUPER_SHOTGUN)
	{
		setmodel (item, "progs/g_shot.mdl");
		item.weapon = IT_SUPER_SHOTGUN;
		item.netname = "Double-barrelled Shotgun";
		item.classname = "weapon_supershotgun";
		self.items = self.items - IT_SUPER_SHOTGUN;
	}

	if( self.weapon == IT_NAILGUN )
	{
		setmodel (item, "progs/g_nail.mdl");
		item.weapon = IT_NAILGUN;
		item.netname = "nailgun";
		item.classname = "weapon_nailgun";
		self.items = self.items - IT_NAILGUN;
	}
		
	if( self.weapon == IT_SUPER_NAILGUN)
	{
		setmodel (item, "progs/g_nail2.mdl");
		item.weapon = IT_SUPER_NAILGUN;
		item.netname = "Super Nailgun";
		item.classname = "weapon_supernailgun";
		self.items = self.items - IT_SUPER_NAILGUN;
	}
	
	if( self.weapon == IT_GRENADE_LAUNCHER)
	{
		setmodel (item, "progs/g_rock.mdl");
		item.weapon = 3;
		item.netname = "Grenade Launcher";
		item.classname = "weapon_grenadelauncher";
		self.items = self.items - IT_GRENADE_LAUNCHER;
	}
	
	if( self.weapon == IT_ROCKET_LAUNCHER )
	{
		setmodel (item, "progs/g_rock2.mdl");
		item.weapon = 3;
		item.netname = "Rocket Launcher";
		item.classname = "weapon_rocketlauncher";
		self.items = self.items - IT_ROCKET_LAUNCHER;
	}
	
	if( self.weapon == IT_LIGHTNING )
	{
		setmodel (item, "progs/g_light.mdl");
		item.weapon = 3;
		item.netname = "Thunderbolt";
		item.classname = "weapon_lightning";
		self.items = self.items - IT_LIGHTNING;
	}
	setsize(item, '-16 -16 0', '16 16 56');
	item.touch = Team_weapon_touch;
	item.think = SUB_Remove;
	item.nextthink = time + 120;
	
	self.weapon = W_BestWeapon();
	W_SetCurrentAmmo();
};

void(entity flg) RegenFlag =
{
	flg.movetype = MOVETYPE_TOSS;
	flg.solid = SOLID_TRIGGER;
	setmodel(flg, flg.mdl);
	setorigin(flg, flg.oldorigin);
	flg.angles = flg.mangle;
	flg.cnt = FLAG_AT_BASE; // it's at home base
	flg.owner = world;
	flg.velocity = '0 0 0';
	sound (flg, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
};

void(entity flg) TeamCaptureReturnFlag =
{
	local entity p;

	RegenFlag(flg);

	p = find(world, classname, "player");
	while (p != world) {
		if (p.steam != flg.steam)
			TeamPlayerUpdate(p, "Enemy flag has been returned to base!");
		else if (p.steam == flg.steam)
			TeamPlayerUpdate(p, "Your flag has been returned to base!");
		p = find(p, classname, "player");
	}
};

void () TeamCaptureRegenFlags =
{
	local entity f;

	f = find(world, classname, "item_flag_team1");
	if (f != world)
		RegenFlag(f);
	f = find(world, classname, "item_flag_team2");
	if (f != world)
		RegenFlag(f);
};

void(entity flg) TeamDropFlag =
{
	local entity item, f, oself;
	local entity p;

	p = flg.owner;

	bprint(PRINT_HIGH, p.netname);
	if (p.steam == TEAM_COLOR1)
		bprint(PRINT_HIGH, " ÏÔÛÙ the ¬Ã’≈ flag!\n"); // blue
	else
		bprint(PRINT_HIGH, " ÏÔÛÙ the “≈ƒ flag!\n"); // red
	p.effects = p.effects - (p.effects & (EF_FLAG1 | EF_FLAG2));

	flg.origin = p.origin - '0 0 24';
	flg.cnt = FLAG_DROPPED;
	flg.velocity_z = 300;
	flg.velocity_x = 0;
	flg.velocity_y = 0;
	flg.flags = FL_ITEM;
	flg.solid = SOLID_TRIGGER;
	flg.movetype = MOVETYPE_TOSS;
	setmodel(flg, flg.mdl);
	setsize(self, '-16 -16 0', '16 16 74');
	// return it after so long
	flg.super_time = time + TEAM_CAPTURE_FLAG_RETURN_TIME;
};

void(entity player) TeamCaptureDropFlagOfPlayer =
{
	local string kn;
	local entity e;

	if (!(player.player_flag & ITEM_ENEMY_FLAG))
		return;
	if (player.steam == TEAM_COLOR1) 
		kn = "item_flag_team2";
	else
		kn = "item_flag_team1";
	player.player_flag = player.player_flag - ITEM_ENEMY_FLAG;
	e = find(world, classname, kn);
	if (e != world)
		TeamDropFlag(e);
};

// possum: 3 loops in one.  Hopefully this will help prevent an
// occasional server lockup when a player picks up and then captures the
// flag in rapid succession
void() LoopThroughPlayersAfterCapture =
{
	local entity p;

	// count up teamscr
	lastteamscrtime = time + TEAMSCRTIME;
	teamscr1 = teamscr2 = 0;

	// Ok, let's do the player loop, hand out the bonuses, add up
	// the scores, and inform the players about the capture

	p = find(world, classname, "player");
	while (p != world) {

		// Ok, let's do the player loop, hand out the bonuses
		self = p;
		self.killed = 0;
		if (self.steam == other.steam && self != other)
			self.frags = self.frags + TEAM_CAPTURE_TEAM_BONUS;
		if (self.steam != other.steam) {
			// *XXX* EXPERT CTF
			// reset the last_hurt_carrier variable in all enemy
			// players, so that you don't get bonuses for defending
			// the flag carrier if the flag carrier has already
			// completed a capture
			self.last_hurt_carrier = -5;
		} else if (self.steam == other.steam) {
			// done to all players on the capturing team
			// *XXX* EXPERT CTF
			// award extra points for capture assists
			if (self.last_returned_flag + TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT > time) {
				bprint(PRINT_HIGH, self.netname);
				bprint(PRINT_HIGH, " gets an assist for returning his flag!\n");
				self.frags = self.frags + TEAM_CAPTURE_RETURN_FLAG_ASSIST_BONUS;
			}
			if (self.last_fragged_carrier + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT > time) {
				bprint(PRINT_HIGH, self.netname);
				bprint(PRINT_HIGH, " gets an assist for fragging the flag carrier!\n");
				self.frags = self.frags + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_BONUS;
			}
		}
		self.player_flag = self.player_flag - (self.player_flag & ITEM_ENEMY_FLAG);
		
		// count up teamscr
		if (p.steam == TEAM_COLOR1)
			teamscr1 = teamscr1 + p.frags;
		else if (p.steam == TEAM_COLOR2)
			teamscr2 = teamscr2 + p.frags;

		// inform players about capture
		if ((p.steam == TEAM_COLOR1 && other.steam == TEAM_COLOR2) ||
			(p.steam == TEAM_COLOR2 && other.steam == TEAM_COLOR1))
			TeamPlayerUpdate(p, "Your flag was captured!");
		else if (p.steam == other.steam)
			TeamPlayerUpdate(p, "Your team captured the flag!");

		// remove any flags
		p.effects = p.effects - (p.effects & (EF_FLAG1 | EF_FLAG2));

		p = find(p, classname, "player");
	}
};

void() TeamCaptureFlagTouch =
{
	local entity p, oself;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if (self.steam == other.steam) {
		// same team, if the flag is *not* at the base, return
		// it to base.  we overload the 'cnt' field for this
		if (self.cnt == FLAG_AT_BASE) {
			// the flag is at home base.  if the player has the enemy
			// flag, he's just won!

			if (other.player_flag & ITEM_ENEMY_FLAG) {
				bprint(PRINT_HIGH, other.netname);
				if (other.steam == TEAM_COLOR1)
					bprint(PRINT_HIGH, " „·ÙıÚÂ‰ the ¬Ã’≈ flag!\n"); // blue
				else
					bprint(PRINT_HIGH, " „·ÙıÚÂ‰ the “≈ƒ flag!\n"); // red
				other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));

				last_flag_capture = time;
				last_capture_team = other.steam;

				sound (other, CHAN_VOICE, "misc/flagcap.wav", 1, ATTN_NONE);

				// other gets another 10 frag bonus
				other.frags = other.frags + TEAM_CAPTURE_CAPTURE_BONUS;

				// possum: 3 loops in one
				LoopThroughPlayersAfterCapture();

				// respawn flags
				TeamCaptureRegenFlags();
				return;
			}
			return; // its at home base already
		}	
		// hey, its not home.  return it by teleporting it back
		bprint(PRINT_HIGH, other.netname);
		if (other.steam == TEAM_COLOR1)
			bprint(PRINT_HIGH, " ÚÂÙıÚÓÂ‰ the “≈ƒ flag!\n"); // red
		else
			bprint(PRINT_HIGH, " ÚÂÙıÚÓÂ‰ the ¬Ã’≈ flag!\n"); // blue
		other.frags = other.frags + TEAM_CAPTURE_RECOVERY_BONUS;
		// *XXX* EXPERT CTF set time when player last returned his flag
		other.last_returned_flag = time;
		sound (other, CHAN_ITEM, self.noise1, 1, ATTN_NORM);
		TeamCaptureReturnFlag(self);
		return;
	}

	// hey, its not our flag, pick it up
	bprint(PRINT_HIGH, other.netname);
	if (other.steam == TEAM_COLOR1)
		bprint(PRINT_HIGH, " ÁÔÙ the ¬Ã’≈ flag!\n"); // blue
	else
		bprint(PRINT_HIGH, " ÁÔÙ the “≈ƒ flag!\n"); // red
	if (TEAM_CAPTURE_FLAG_BONUS)
		other.frags = other.frags + TEAM_CAPTURE_FLAG_BONUS;
//	TeamPlayerUpdate(other, "YOU GOT THE ENEMY FLAG!\n\nRETURN TO BASE!");
	TeamPlayerUpdate(other, "Ÿœ’ «œ‘ ‘»≈ ≈Œ≈ÕŸ ∆Ã¡«\n\n“≈‘’“Œ ‘œ ¬¡”≈");
	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	other.player_flag = other.player_flag + ITEM_ENEMY_FLAG;
	other.items = other.items | self.items;

	// *XXX* EXPERT CTF set the time at which the carrier picked up the flag
	other.flag_since = time;

	// pick up the flag
	self.cnt = FLAG_CARRIED;
	self.solid = SOLID_NOT;
	self.owner = other;
	if (self.steam == TEAM_COLOR1)
		self.owner.effects = self.owner.effects | EF_FLAG1;
	else // must be other team
		self.owner.effects = self.owner.effects | EF_FLAG2;
	setmodel(self, "");

	p = find(world, classname, "player");
	while (p != world) {
		if (p != other) {
			if (p.steam != other.steam)
				TeamPlayerUpdate(p, "Your flag has been taken!");
			else if (p.steam == other.steam)
				TeamPlayerUpdate(p, "Your team has the enemy flag!");
		}
		p = find(p, classname, "player");
	}
};

void() TeamCaptureFlagThink =
{
	local entity e;
	local vector v;
	local float f;
	local string s;

	self.nextthink = time + 0.1;

	if (self.cnt == FLAG_AT_BASE)
		return; // just sitting around waiting to be picked up

	if (self.cnt == FLAG_DROPPED) {
		if (time - self.super_time > TEAM_CAPTURE_FLAG_RETURN_TIME)
			TeamCaptureReturnFlag(self);
		return;
	}

	if (self.cnt != FLAG_CARRIED)
		objerror("Flag in invalid state\n");
};

// self is player
entity() TeamCaptureSpawn =
{
	
	if (!(teamplay & TEAM_CAPTURE_FLAG))
		return world;

	if (self.steam == TEAM_COLOR1) {
		team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
		if (team1_lastspawn == world)
			team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
		return team1_lastspawn;
	} else if (self.steam == TEAM_COLOR2) {
		team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
		if (team2_lastspawn == world)
			team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
		return team2_lastspawn;
	}
	return world;
};

/*
	From byron@caseware.com Wed Oct 16 18:57:44 1996
	Date: Wed, 16 Oct 1996 21:22:37 -0400
	From: Byron Long <byron@caseware.com>
	To: zoid@mindlink.net
	Subject: Team Status Command (source code included) :-)

	A co-worker of mine wondered if it was possible to add a function to
	your capture the flag code that would give a status report on an
	impulse. I think he may have mailed you, but I wrote a quick version
	myself, which your welcome to use if you like the feature (it offsets
	some of the problems with the chat capabilities in Quake so it seems
	like a worthwhile feature). Feel free to change it
	as necessary.
*/

// *Capture The Flag - Status report by Wonko
void() TeamFlagStatusReport =
{
	local entity flag1, flag2, p;

	if (!(teamplay & TEAM_CAPTURE_FLAG)) {
		sprint(self, PRINT_HIGH, "Capture the Flag is not enabled.\n");
		return;
	}

	// Find the flags at home base
	flag1 = find (world,classname, "item_flag_team1");
	flag2 = find (world,classname, "item_flag_team2");

	if (self.classname == "spectator") {
		if (flag1 != world && flag1.cnt == FLAG_CARRIED) {
			sprint(self, PRINT_HIGH, flag1.owner.netname);
			sprint(self, PRINT_HIGH, " has the “≈ƒ flag.\n");
		} else {
			sprint(self, PRINT_HIGH, "The “≈ƒ flag is ");
			if (flag1 == world)
				sprint(self, PRINT_HIGH, "missing!\n");
			if (flag1.cnt == FLAG_AT_BASE)
				sprint(self, PRINT_HIGH, "at base.\n");
			else if (flag1.cnt == FLAG_DROPPED)
				sprint(self, PRINT_HIGH, "lying about.\n");
			else
				sprint(self, PRINT_HIGH, " corrupt.\n");
		}
		if (flag2 != world && flag2.cnt == FLAG_CARRIED) {
			sprint(self, PRINT_HIGH, flag2.owner.netname);
			sprint(self, PRINT_HIGH, " has the ¬Ã’≈ flag. ");
		} else {
			sprint(self, PRINT_HIGH, "The ¬Ã’≈ flag is ");
			if (flag2 == world)
				sprint(self, PRINT_HIGH, "missing!\n");
			if (flag2.cnt == FLAG_AT_BASE)
				sprint(self, PRINT_HIGH, "at base.\n");
			else if (flag2.cnt == FLAG_DROPPED)
				sprint(self, PRINT_HIGH, "lying about.\n");
			else
				sprint(self, PRINT_HIGH, " corrupt.\n");
		}
		return;
	}

	// If on team 2 switch meanings of flags
	if (self.steam != TEAM_COLOR1) {
		p = flag1;
		flag1 = flag2;
		flag2 = p;
	}

	if (flag1 != world && flag1.cnt == FLAG_CARRIED) {
		sprint(self, PRINT_HIGH, flag1.owner.netname);
		sprint(self, PRINT_HIGH, " has your flag. ");
	} else {
		sprint(self, PRINT_HIGH, "Your flag is ");
		if (flag1 == world)
			sprint(self, PRINT_HIGH, "missing! ");
		if (flag1.cnt == FLAG_AT_BASE)
			sprint(self, PRINT_HIGH, "in your base. ");
		else if (flag1.cnt == FLAG_DROPPED)
			sprint(self, PRINT_HIGH, "lying about. ");
		else
			sprint(self, PRINT_HIGH, " corrupt. ");
	}

	if (flag2 != world && flag2.cnt == FLAG_CARRIED) {
		if (self == flag2.owner) 
			sprint(self, PRINT_HIGH, "You have the enemy flag.\n");
		else {
			sprint(self, PRINT_HIGH, flag2.owner.netname);
			sprint(self, PRINT_HIGH, " has the enemy flag.\n");
		}
	} else {
		sprint(self, PRINT_HIGH, "The enemy flag is ");
		if (flag2 == world)
			sprint(self, PRINT_HIGH, "missing!\n");
		if (flag2.cnt == FLAG_AT_BASE)
			sprint(self, PRINT_HIGH, "in their base.\n");
		else if (flag2.cnt == FLAG_DROPPED)
			sprint(self, PRINT_HIGH, "lying about.\n");
		else
			sprint(self, PRINT_HIGH, " corrupt.\n");
	}
};

/////////////////////////////////////////////////////////////////////////

$cd id1/models/flag
$base base
$skin skin

void() place_flag = {
	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;	
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	self.think = TeamCaptureFlagThink;
	self.touch = TeamCaptureFlagTouch;
	self.nextthink = time + 0.1;
	self.cnt = FLAG_AT_BASE;
	self.mangle = self.angles;
	self.effects = self.effects | EF_DIMLIGHT;
	if (!droptofloor()) {
		dprint ("Flag fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
	self.oldorigin = self.origin; // save for flag return
};

// ZOID Capture the flag
void() item_flag_team1 =
{
	if (!deathmatch || !(cvar("teamplay") & TEAM_CAPTURE_FLAG)) {
		remove(self);
		return;
	}

	self.steam = TEAM_COLOR1;
	self.items = IT_KEY2;
	precache_model ("progs/flag.mdl");
	setmodel (self, "progs/flag.mdl");
	self.skin = 0;
	precache_sound ("misc/flagtk.wav");			// flag taken
	precache_sound ("misc/flagcap.wav");			// flag capture
	precache_sound ("doors/runetry.wav");
	self.noise = "misc/flagtk.wav";
	self.noise1 = "doors/runetry.wav";
	setsize(self, '-16 -16 0', '16 16 74');
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = place_flag;
};

void() item_flag_team2 =
{
	if (!deathmatch || !(cvar("teamplay") & TEAM_CAPTURE_FLAG)) {
		remove(self);
		return;
	}

	self.steam = TEAM_COLOR2;
	self.items = IT_KEY1;
	precache_model ("progs/flag.mdl");
	setmodel (self, "progs/flag.mdl");
	self.skin = 1;
	precache_sound ("misc/flagtk.wav");			// flag taken
	precache_sound ("misc/flagcap.wav");			// flag capture
	precache_sound ("doors/runetry.wav");
	self.noise = "misc/flagtk.wav";
	self.noise1 = "doors/runetry.wav";
	setsize(self, '-16 -16 0', '16 16 74');
	// make it glow
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = place_flag;
};

// Team base starting locations
void() info_player_team1 =
{
};

void() info_player_team2 =
{
};

/*QUAKED func_ctf_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
Only appears in CTF teamplay
*/
void() func_ctf_wall =
{
	if (cvar("teamplay") & TEAM_CAPTURE_FLAG) {
		self.angles = '0 0 0';
		self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
		self.solid = SOLID_BSP;
		setmodel (self, self.model);
	} else
		remove(self);
};

