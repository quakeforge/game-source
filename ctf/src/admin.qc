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

//---------------------------------------------------------------------------
//Quake
//
//Copyright (c) 1995-96 by Dave Kirsch
//---------------------------------------------------------------------------
//admin - remove server admin functions
//---------------------------------------------------------------------------

// NOTE:  THE FOLLOWING VALUES ARE THE PASSWORD USED TO ENABLE
// REMOTE ACCESS.
//
// The have the following properties and requirements:
// a. Must not be an existing impulse
// b. Must be entered in the specified order
// c. Must be in the range 1 to 255 excluding previously used impulses
//
// They must be entered in the correct order which gives 256*256*256 or
// 16777216 possible passwords.  If a specified order wasn't given, it
// would only be 768 possibilities.
//
// BY DEFAULT, REMOTE ADMIN ACCESS IS DISABLED
// This is done by setting the admin passwords all to -1.
//
// If you wanted to enable it, pick three random numbers (that aren't
// existing impulses) and put 'em here, for example:
//
//		float	ADMIN_PWD_1	= 179;
//		float	ADMIN_PWD_2	= 131;
//		float	ADMIN_PWD_3	= 157;
//
// which would give you a password of 179, 131 and 157.  To send this from
// a Quake client, do a bind like this:
//
// bind p "impulse 179;wait;impulse 131;wait;impulse 157"
//
// When you hit p, you'll be granted remote admin functionality.
//
// Currently the only admin functions available right now are kick
// team change, and level change.  They are bound to impulse 151, 
// impulse 152 and impuluse 153 respectively.
//
// The way it works is after you enter the admin password, do an
// impulse 151/152/153.  You'll get a list of players on the server with their
// numbers.  Send the next impulse with the number of the player
// to act the command on.

// CHANGE THE FOLLOWING THREE -1 NUMBERS TO YOUR ADMIN PASSWD
float	ADMIN_PWD_1	= -1;  // change me to first number of the passwd
float	ADMIN_PWD_2	= -1;  // change me to second number of the passwd
float	ADMIN_PWD_3	= -1;  // change me to third number of the passwd

float	ADMIN_KICK = 151;
float	ADMIN_TEAMCHANGE = 152;
float	ADMIN_CHANGEMAP = 153;
float	ADMIN_GIVERUNE = 154;
float	ADMIN_TIMELIMIT = 156;
float	ADMIN_FRAGLIMIT = 157;

// used for admin to change maps
void(string nmap) AdminChangeLevel =
{
	local entity o;

	bprint(self.netname);
	bprint(" has changed the level to ");
	bprint(nmap);
	bprint("\n");

	o = spawn();
	o.map = nmap;
	nextmap = o.map;
	gameover = TRUE;

	o.think = execute_changelevel;
	o.nextthink = time + 0.1;
};

void() CheckAdminCmd =
{
	local float n;
	local entity p;
	local string st;

	if (ADMIN_PWD_1 < 0 || ADMIN_PWD_2 < 0 || ADMIN_PWD_3 < 0)
		return; // disabled

	if (self.impulse == ADMIN_PWD_1 && self.accesslvl == 0) {
		self.accesslvl = self.accesslvl + 1;
		return;

	} else if (self.impulse == ADMIN_PWD_2 && self.accesslvl == 1) {
		self.accesslvl = self.accesslvl + 1;
		return;

	} else if (self.impulse == ADMIN_PWD_3 && self.accesslvl == 2) {
		self.accesslvl = self.accesslvl + 1;

		bprint(self.netname);
		bprint(" has become a sysop\n");

		sprint(self, "Admin Impulse Codes:\n");
		st = ftos(ADMIN_KICK);
		sprint(self, st);
		sprint(self, " to kick\nImpulse ");
		st = ftos(ADMIN_TEAMCHANGE);
		sprint(self, st);
		sprint(self, " to switch teamplayer\n");
		st = ftos(ADMIN_CHANGEMAP);
		sprint(self, st);
		sprint(self, " to change map\n");
		st = ftos(ADMIN_GIVERUNE);
		sprint(self, st);
		sprint(self, " to give rune\n");
		st = ftos(ADMIN_TIMELIMIT);
		sprint(self, st);
		sprint(self, " to set timelimit\n");
		st = ftos(ADMIN_FRAGLIMIT);
		sprint(self, st);
		sprint(self, " to set fraglimit\n");
		self.accessparm = 0;
		return;
	}

	if (self.accesslvl < 3) {
		self.accesslvl = 0;
		self.accessparm = 0;
		return; // must be a sysop beyond this point
	}

	if (self.accessparm == 1) { // kick cmd

		n = self.impulse - 1;
		p = find(world, classname, "player");
		while (p != world && n > 0) {
			p = find(p, classname, "player");
			n = n - 1;
		}

		if (p != world) {
			sprint(p, "\n\nYou have been kicked.\nGo abuse somewhere else.\n");
			stuffcmd(p, "disconnect\n");
			bprint(p.netname);
			bprint(" was kicked by ");
			bprint(self.netname);
			bprint("\n");
		} else {
			sprint(self, "Can't kick #");
			st = ftos(self.impulse);
			sprint(self, st);
			sprint(self, "\n");
		}

		self.accessparm = 0;
		return;

	} else if (self.accessparm == 2) { // switch teams

		n = self.impulse - 1;
		p = find(world, classname, "player");
		while (p != world && n > 0) {
			p = find(p, classname, "player");
			n = n - 1;
		}

		if (p != world) {
			TeamCaptureDropFlagOfPlayer(p);
			centerprint(p, "YOU HAVE SWITCHED TEAMS!");
			if (p.lastteam == TEAM_COLOR1) {
				p.team = p.lastteam = TEAM_COLOR2;
				st = ftos(TEAM_COLOR2 - 1);
			} else {
				p.team = p.lastteam = TEAM_COLOR1;
				st = ftos(TEAM_COLOR1 - 1);
			}
			stuffcmd(p, "color ");
			stuffcmd(p, st);
			stuffcmd(p, "\n");
			bprint(p.netname);
			bprint(" changed teams (by ");
			bprint(self.netname);
			bprint(")\n");
		} else {
			sprint(self, "Can't change #");
			st = ftos(self.impulse);
			sprint(self, st);
			sprint(self, "\n");
		}

		self.accessparm = 0;
		return;

	} else if (self.accessparm == 3) { // select episode

		if (self.impulse == 1) {
			self.accessparm = 4;

			sprint(self, "Choose Level:\n");
			sprint(self, "1 e1m1 Slipgate Complex\n");
			sprint(self, "2 e1m2 Castle of the Damned\n");
			sprint(self, "3 e1m3 The Necropolis\n");
			sprint(self, "4 e1m4 The Grisly Grotto\n");
			sprint(self, "5 e1m5 Gloom Keep\n");
			sprint(self, "6 e1m6 The Door To Chthon\n");
			sprint(self, "7 e1m7 The House of Chthon\n");
			sprint(self, "8 e1m8 Ziggurat Vertigo\n");

			self.impulse = 0;
			return;

		} else if (self.impulse == 2) {
			self.accessparm = 5;

			sprint(self, "Choose Level:\n");
			sprint(self, "1 e2m1 The Installation\n");
			sprint(self, "2 e2m2 Ogre Citadel\n");
			sprint(self, "3 e2m3 Crypt of Decay\n");
			sprint(self, "4 e2m4 The Ebon Fortress \n");
			sprint(self, "5 e2m5 The Wizard's Manse\n");
			sprint(self, "6 e2m6 The Dismal Oubliette\n");
			sprint(self, "7 e2m7 Underearth\n");

			self.impulse = 0;
			return;

		} else if (self.impulse == 3) {
			self.accessparm = 6;

			sprint(self, "Choose Level:\n");
			sprint(self, "1 e3m1 Termination Central\n");
			sprint(self, "2 e3m2 The Vaults of Zin\n");
			sprint(self, "3 e3m3 The Tomb of Terror\n");
			sprint(self, "4 e3m4 Satan's Dark Delight\n");
			sprint(self, "5 e3m5 Wind Tunnels\n");
			sprint(self, "6 e3m6 Chambers of Torment\n");
			sprint(self, "7 e3m7 The Haunted Halls\n");

			self.impulse = 0;
			return;

		} else if (self.impulse == 4) {
			self.accessparm = 7;

			sprint(self, "Choose Level:\n");
			sprint(self, "1 e4m1 The Sewage System\n");
			sprint(self, "2 e4m2 The Tower of Despair\n");
			sprint(self, "3 e4m3 The Elder God Shrine\n");
			sprint(self, "4 e4m4 The Palace of Hate\n");
			sprint(self, "5 e4m5 Hell's Atrium\n");
			sprint(self, "6 e4m6 The Pain Maze\n");
			sprint(self, "7 e4m7 Azure Agony\n");
			sprint(self, "8 e4m8 The Nameless City\n");

			self.impulse = 0;
			return;

		} else if (self.impulse == 5) {
			self.accessparm = 8;

			sprint(self, "Choose Level:\n");
			sprint(self, "1 dm1 Place of Two Deaths\n");
			sprint(self, "2 dm2 Claustrophobopolis\n");
			sprint(self, "3 dm3 The Abandoned Base\n");
			sprint(self, "4 dm4 The Bad Place\n");
			sprint(self, "5 dm5 The Cistern\n");
			sprint(self, "6 dm6 The Dark Zone\n");

			self.impulse = 0;
			return;

		} else if (self.impulse == 6) {
			self.accessparm = 9;

			sprint(self, "Choose Level:\n");
			sprint(self, "1 ctf1 McKinley Base\n");
			sprint(self, "2 ctf2 The Kiln\n");
			sprint(self, "3 ctf3 Dysphoria\n");
			sprint(self, "4 ctf4 The Forgotten Mines\n");
			sprint(self, "5 ctf5 Da Ancient War Grounds\n");
			sprint(self, "6 ctf6 Vertigo\n");
			sprint(self, "7 ctf7 Tale of Two Cities\n");
			sprint(self, "8 ctf8 The Strongbox\n");

			self.impulse = 0;
			return;

		} else if (self.impulse == 7) {
			self.accessparm = 10;

			sprint(self, "Choose Level:\n");
			sprint(self, "1 ctf2m1 McKinley Station\n");
			sprint(self, "2 ctf2m2 The Warzone\n");
			sprint(self, "3 ctf2m3 Spill the Blood\n");
			sprint(self, "4 ctf2m4 Ruins of NeoMinonk\n");
			sprint(self, "5 ctf2m5 Disciple War Grounds\n");
			sprint(self, "6 ctf2m6 The Two Towers\n");
			sprint(self, "7 ctf2m7 Gloom Castles\n");
			sprint(self, "8 ctf2m8 Capturephobolis\n");

			self.impulse = 0;
			return;
		}
		sprint(self, "Invalid episode\n");
		self.accessparm = 0;
		return;

	} else if (self.accessparm == 4) {

		if (self.impulse == 1)		AdminChangeLevel("e1m1");
		else if (self.impulse == 2)	AdminChangeLevel("e1m2");
		else if (self.impulse == 3)	AdminChangeLevel("e1m3");
		else if (self.impulse == 4)	AdminChangeLevel("e1m4");
		else if (self.impulse == 5)	AdminChangeLevel("e1m5");
		else if (self.impulse == 6)	AdminChangeLevel("e1m6");
		else if (self.impulse == 7)	AdminChangeLevel("e1m7");
		else if (self.impulse == 8)	AdminChangeLevel("e1m8");
		else sprint(self, "Invalid map\n");
		self.impulse = 0;
		self.accessparm = 0;
		return;
			
	} else if (self.accessparm == 5) {

		if (self.impulse == 1)		AdminChangeLevel("e2m1");
		else if (self.impulse == 2)	AdminChangeLevel("e2m2");
		else if (self.impulse == 3)	AdminChangeLevel("e2m3");
		else if (self.impulse == 4)	AdminChangeLevel("e2m4");
		else if (self.impulse == 5)	AdminChangeLevel("e2m5");
		else if (self.impulse == 6)	AdminChangeLevel("e2m6");
		else if (self.impulse == 7)	AdminChangeLevel("e2m7");
		else sprint(self, "Invalid map\n");
		self.impulse = 0;
		self.accessparm = 0;
		return;
			
	} else if (self.accessparm == 6) {

		if (self.impulse == 1)		AdminChangeLevel("e3m1");
		else if (self.impulse == 2)	AdminChangeLevel("e3m2");
		else if (self.impulse == 3)	AdminChangeLevel("e3m3");
		else if (self.impulse == 4)	AdminChangeLevel("e3m4");
		else if (self.impulse == 5)	AdminChangeLevel("e3m5");
		else if (self.impulse == 6)	AdminChangeLevel("e3m6");
		else if (self.impulse == 7)	AdminChangeLevel("e3m7");
		else sprint(self, "Invalid map\n");
		self.impulse = 0;
		self.accessparm = 0;
		return;
			
	} else if (self.accessparm == 7) {

		if (self.impulse == 1)		AdminChangeLevel("e4m1");
		else if (self.impulse == 2)	AdminChangeLevel("e4m2");
		else if (self.impulse == 3)	AdminChangeLevel("e4m3");
		else if (self.impulse == 4)	AdminChangeLevel("e4m4");
		else if (self.impulse == 5)	AdminChangeLevel("e4m5");
		else if (self.impulse == 6)	AdminChangeLevel("e4m6");
		else if (self.impulse == 7)	AdminChangeLevel("e4m7");
		else if (self.impulse == 8)	AdminChangeLevel("e4m8");
		else sprint(self, "Invalid map\n");
		self.impulse = 0;
		self.accessparm = 0;
		return;
			
	} else if (self.accessparm == 8) {

		if (self.impulse == 1)		AdminChangeLevel("dm1");
		else if (self.impulse == 2)	AdminChangeLevel("dm2");
		else if (self.impulse == 3)	AdminChangeLevel("dm3");
		else if (self.impulse == 4)	AdminChangeLevel("dm4");
		else if (self.impulse == 5)	AdminChangeLevel("dm5");
		else if (self.impulse == 6)	AdminChangeLevel("dm6");
		else sprint(self, "Invalid map\n");
		self.impulse = 0;
		self.accessparm = 0;
		return;
			
	} else if (self.accessparm == 9) {

		if (self.impulse == 1)		AdminChangeLevel("ctf1");
		else if (self.impulse == 2)	AdminChangeLevel("ctf2");
		else if (self.impulse == 3)	AdminChangeLevel("ctf3");
		else if (self.impulse == 4)	AdminChangeLevel("ctf4");
		else if (self.impulse == 5)	AdminChangeLevel("ctf5");
		else if (self.impulse == 6)	AdminChangeLevel("ctf6");
		else if (self.impulse == 7)	AdminChangeLevel("ctf7");
		else if (self.impulse == 8)	AdminChangeLevel("ctf8");
		else sprint(self, "Invalid map\n");
		self.impulse = 0;
		self.accessparm = 0;
		return;

	} else if (self.accessparm == 10) {

		if (self.impulse == 1)		AdminChangeLevel("ctf2m1");
		else if (self.impulse == 2)	AdminChangeLevel("ctf2m2");
		else if (self.impulse == 3)	AdminChangeLevel("ctf2m3");
		else if (self.impulse == 4)	AdminChangeLevel("ctf2m4");
		else if (self.impulse == 5)	AdminChangeLevel("ctf2m5");
		else if (self.impulse == 6)	AdminChangeLevel("ctf2m6");
		else if (self.impulse == 7)	AdminChangeLevel("ctf2m7");
		else if (self.impulse == 8)	AdminChangeLevel("ctf2m8");
		else sprint(self, "Invalid map\n");
		self.impulse = 0;
		self.accessparm = 0;
		return;

	} else if (self.accessparm == 20) { // give rune
		if (self.impulse == 1) {
			self.player_flag |= ITEM_RUNE1_FLAG;
			sprint(self, "You now have the Earth Magic rune\n");
		} else if (self.impulse == 2) {
			self.player_flag |= ITEM_RUNE2_FLAG;
			sprint(self, "You now have the Black Magic rune\n");
		} else if (self.impulse == 3) {
			self.player_flag |= ITEM_RUNE3_FLAG;
			sprint(self, "You now have the Hell Magic rune\n");
		} else if (self.impulse == 4) {
			self.player_flag |= ITEM_RUNE4_FLAG;
			sprint(self, "You now have the Elder Magic rune\n");
		}

		self.accessparm = 0;
		return;

	} else if (self.accessparm == 21) { // time limit
		st = ftos(self.impulse);
		localcmd("timelimit ");
		localcmd(st);
		localcmd("\n");
		self.accessparm = 0;
		return;

	} else if (self.accessparm == 22) { // frag limit
		st = ftos(self.impulse);
		localcmd("fraglimit ");
		localcmd(st);
		localcmd("\n");
		self.accessparm = 0;
		return;

	}

	self.accessparm = 0;

	if (self.impulse == ADMIN_KICK) {

		sprint(self, "Kick:\n");
		p = find(world, classname, "player");
		n = 1;
		while (p != world) {
			st = ftos(n);
			if (n < 10)
				sprint(self, " ");
			sprint(self, st);
			sprint(self, " ");
			sprint(self, p.netname);
			sprint(self, "\n");
			p = find(p, classname, "player");
			n = n + 1;
		}

		self.accessparm = 1;

	} else if (self.impulse == ADMIN_TEAMCHANGE) {

		sprint(self, "Switch:\n");
		p = find(world, classname, "player");
		n = 1;
		while (p != world) {
			st = ftos(n);
			if (n < 10)
				sprint(self, " ");
			sprint(self, st);
			sprint(self, " ");
			sprint(self, p.netname);
			sprint(self, "\n");
			p = find(p, classname, "player");
			n = n + 1;
		}

		self.accessparm = 2;

	} else if (self.impulse == ADMIN_CHANGEMAP) {
		sprint(self, "Select Episode:\n");
		sprint(self, "1 Dimension of the Doomed\n");
		sprint(self, "2 Realm of Black Magic\n");
		sprint(self, "3 Netherworld\n");
		sprint(self, "4 The Elder World\n");
		sprint(self, "5 The Deathmatch Arenas\n");
		sprint(self, "6 Capture Levels - One\n");
		sprint(self, "7 Capture Levels - Two\n");

		self.accessparm = 3;

	} else if (self.impulse == ADMIN_GIVERUNE) {
		sprint(self, "Give Rune:\n");
		sprint(self, "1 Earth Magic - Regeneration\n");
		sprint(self, "2 Black Magic - Strength\n");
		sprint(self, "3 Hell Magic - Haste\n");
		sprint(self, "4 Elder Magic - Regen\n");

		self.accessparm = 20;

	} else if (self.impulse == ADMIN_TIMELIMIT) {
		sprint(self, "Enter timelimit via impulse\n");
		self.accessparm = 21;

	} else if (self.impulse == ADMIN_FRAGLIMIT) {
		sprint(self, "Enter fraglimit via impulse\n");
		self.accessparm = 22;

	}

	self.impulse = 0;
	return;
};


