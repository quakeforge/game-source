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


.float laststattime;		// time of last status update
.float motd_count;
.float statstate;			// is the status bar on?

float teamscr1;			// team 1's teamscr score
float teamscr2;			// team 2's teamscr score
float lastteamscrtime;		// last time we calculated it

float TEAMSCRTIME = 1;
float PLAYERSTATTIME = 1.75;

void() MOTD =
{
	if (self.motd_count < 4) {
		self.motd_count = self.motd_count + 1;
		if (gamestart) {
			centerprint(self, "Welcome!\nRunning ThreeWave CTF 4.21\n\n√¡–‘’“≈ ‘»≈ ∆Ã¡«!\n\nChoose an exit...\n"); //red
			return;
		}
		if (self.team == TEAM_COLOR1)
			centerprint(self, "Welcome!\nRunning ThreeWave CTF 4.21\n\n√¡–‘’“≈ ‘»≈ ∆Ã¡«!\n\nYou are “≈ƒ team\n"); //red
		else
			centerprint(self, "Welcome!\nRunning Threewave CTF 4.21\n\n√¡–‘’“≈ ‘»≈ ∆Ã¡«!\n\nYou are ¬Ã’≈ team"); //blue
		return;
	}
	sprint(self, "Impulse 70 to turn off status bar\n");
	sprint(self, "Impulse 71 through 81 to set status bar resolution\n");
	sprint(self, "71:200 72:240 73:300 74:350 75:384 76:400 77:480 78:600 79:768 81:1024\n");
	self.motd_count = 0;
};

void() MOTD_ChooseTeam =
{
	if (self.motd_count < 6) {
		self.motd_count = self.motd_count + 1;
		centerprint(self, "Welcome!\nRunning ThreeWave CTF 4.21\n\n√¡–‘’“≈ ‘»≈ ∆Ã¡«!\n\nPress 1 for “≈ƒ team\nPress 2 for ¬Ã’≈ team\nOr Press Jump for automatic team\n");
		return;
	}
	self.motd_count = 0;
};

void() TeamCaptureCheckUpdate =
{
	local entity p;

	if (gamestart)
		return; // handled by vote exit
	if (lastteamscrtime > time)
		return;

	lastteamscrtime = time + TEAMSCRTIME;

	// count up teamscr
	teamscr1 = teamscr2 = 0;
	p = find(world, classname, "player");
	while (p != world) {
		if (p.lastteam == TEAM_COLOR1)
			teamscr1 = teamscr1 + p.frags;
		else if (p.lastteam == TEAM_COLOR2)
			teamscr2 = teamscr2 + p.frags;
		p = find(p, classname, "player");
	}
};

void() TeamCaptureResetUpdate =
{
	lastteamscrtime = 0;
	TeamCaptureCheckUpdate();
};

void() TeamEndScore = 
{
	local string s;

	if (gamestart)
		return;

	lastteamscrtime = 0;
	TeamCaptureCheckUpdate();

	if (teamscr1 > teamscr2) {
		bprint("“≈ƒ team won the level with ");
		s = ftos(teamscr1);
		bprint(s);
		bprint(" points!\n");
		bprint("¬Ã’≈ team lost with ");
		s = ftos(teamscr2);
		bprint(s);
		bprint(" points.\n");
	} else if (teamscr1 < teamscr2) {
		bprint("¬Ã’≈ team won the level with ");
		s = ftos(teamscr2);
		bprint(s);
		bprint(" points!\n");
		bprint("“≈ƒ team lost with ");
		s = ftos(teamscr1);
		bprint(s);
		bprint(" points.\n");
	} else {
		bprint("¬Ã’≈ and “≈ƒ team tied level with ");
		s = ftos(teamscr1);
		bprint(s);
		bprint(" points!\n");
	}
};

string(entity who) TeamSetStatRes =
{
	if (who.statstate > 7) // 768 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 7) // 600 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 6) // 480 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 5) // 400
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 4) // 384 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 3) // 350 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 2) // 300 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 1) // 240 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	// 200 
	return "\n\n\n\n\n\n\n\n\n\n\n\n";
};

string(entity who) TeamSetStatRes2 =
{
	if (who.statstate > 7) // 768 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 7) // 600 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 6) // 480 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 5) // 400
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 4) // 384 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 3) // 350 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 2) // 300 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	else if (who.statstate == 1) // 240 
		return "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	// 200 
	return "\n\n\n\n\n\n\n\n\n\n\n";
};

void() TeamCapturePlayerUpdate =
{
	local entity e;
	local string n, t, s1, s2, s3, res;

	if (self.laststattime > time)
		return;

	TeamCaptureCheckUpdate();

	self.laststattime = time + PLAYERSTATTIME;

	if (self.motd_count) {
		if (self.observer)
			MOTD_ChooseTeam();
		else
			MOTD();
		return;
	}

	if (self.statstate < 0)
		return;

	res = TeamSetStatRes(self);

	if (gamestart) {
		if (vote_leader == world)
			centerprint2(self, res, "                    Choose an exit...");
		else {
			res = TeamSetStatRes2(vote_leader);
			n = ftos(voteexit_time - time);
			centerprint5(self, res, vote_leader.message,
				" leads\n", n, " seconds until exit");
		}
		return;
	}

	//.1234567890123456789012345678901234567
	// Res.R.B.             Capture The Flag
	// Res.R.B.                     BLUE 999

	if (self.player_flag & ITEM_RUNE1_FLAG)
		s1 = "Resist  Ö";
	else if (self.player_flag & ITEM_RUNE2_FLAG)
		s1 = "StrengthÖ";
	else if (self.player_flag & ITEM_RUNE3_FLAG)
		s1 = "Haste   Ö";
	else if (self.player_flag & ITEM_RUNE4_FLAG)
		s1 = "Regen   Ö";
	else
		s1 = "        Ö";
	
	e = find(world, classname, "item_flag_team1");
	if (e.cnt == FLAG_AT_BASE)
		s2 = " Ö";
	else if (e.cnt == FLAG_CARRIED)
		s2 = "RÖ";
	else
		s2 = "“Ö";

	e = find(world, classname, "item_flag_team2");
	if (e.cnt == FLAG_AT_BASE)
		s3 = " Ö";
	else if (e.cnt == FLAG_CARRIED)
		s3 = "BÖ";
	else
		s3 = "¬Ö";
		
	if (teamscr1 == 0 && teamscr2 == 0) {
		centerprint5(self, res, s1, s2, s3, "         Capture The Flag");		// CTFBOT
		return;
	}
	
	if (time < (last_flag_capture + 6))
	{
		if (last_capture_team == TEAM_COLOR1)
		{
			if (teamscr1 > teamscr2) {
				t = "Red Capture!   RED ";
				n = ftos(teamscr1 - teamscr2);
			} else if (teamscr1 < teamscr2) {
				t = "Red Capture!  BLUE ";
				n = ftos(teamscr2 - teamscr1);
			} else {
				t = "Red Capture!  TIED ";
				n = "";
			}
		}
		else
		{
			if (teamscr1 > teamscr2) {
				t = "Blue Capture!  RED ";
				n = ftos(teamscr1 - teamscr2);
			} else if (teamscr1 < teamscr2) {
				t = "Blue Capture! BLUE ";
				n = ftos(teamscr2 - teamscr1);
			} else {
				t = "Blue Capture! TIED ";
				n = "";
			}
		}
	}
	else
	{
		if (teamscr1 > teamscr2) {
			t = "               RED ";
			n = ftos(teamscr1 - teamscr2);
		} else if (teamscr1 < teamscr2) {
			t = "              BLUE ";
			n = ftos(teamscr2 - teamscr1);
		} else {
			t = "              TIED ";
			n = "";
		}
	}
	centerprint7(self, res, s1, s2, s3, "    ", t, n);		//
};

void(entity who, string s) TeamPlayerUpdate =
{
	local string n, res;

	TeamCaptureCheckUpdate();
	who.laststattime = time + PLAYERSTATTIME;

	if (who.statstate < 0) {
		centerprint(who, s);
		return;
	}

	res = TeamSetStatRes2(who);

	if (teamscr1 == 0 && teamscr2 == 0) {
		centerprint3(who, res, s, "\n                       Capture The Flag");
	} else if (teamscr1 > teamscr2) {
		n = ftos(teamscr1 - teamscr2);
		centerprint4(who, res, s, "\n                               RED ", n);
	} else if (teamscr1 < teamscr2) {
		n = ftos(teamscr2 - teamscr1);
		centerprint4(who, res, s, "\n                               BLUE ", n);
	} else
		centerprint3(who, res, s, "\n                               TIED");
};

void(entity who, string s1, string s2) TeamPlayerUpdate2 =
{
	local string n, res;

	TeamCaptureCheckUpdate();
	who.laststattime = time + PLAYERSTATTIME;

	if (who.statstate < 0) {
		centerprint2(who, s1, s2);
		return;
	}

	res = TeamSetStatRes2(who);

	if (teamscr1 == 0 && teamscr2 == 0) {
		centerprint4(who, res, s1, s2, "\n                       Capture The Flag");
		return;
	} else if (teamscr1 > teamscr2) {
		n = ftos(teamscr1 - teamscr2);
		centerprint5(who, res, s1, s2, "\n                               RED ", n);
	} else if (teamscr1 < teamscr2) {
		n = ftos(teamscr2 - teamscr1);
		centerprint5(who, res, s1, s2, "\n                               BLUE ", n);
	} else {
		centerprint4(who, res, s1, s2, "\n                               TIED");
		return;
	}
};

