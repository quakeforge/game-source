/***********************************************
*                                              *
*              FrikBot Misc Code               *
*   "Because you can't name it anything else"  *
*                                              *
***********************************************/

/*
This program is in the Public Domain. My crack legal
team would like to add:

RYAN "FRIKAC" SMITH IS PROVIDING THIS SOFTWARE "AS IS"
AND MAKES NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE
ACCURACY, CAPABILITY, EFFICIENCY, MERCHANTABILITY, OR
FUNCTIONING OF THIS SOFTWARE AND/OR DOCUMENTATION. IN
NO EVENT WILL RYAN "FRIKAC" SMITH BE LIABLE FOR ANY
GENERAL, CONSEQUENTIAL, INDIRECT, INCIDENTAL,
EXEMPLARY, OR SPECIAL DAMAGES, EVEN IF RYAN "FRIKAC"
SMITH HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES, IRRESPECTIVE OF THE CAUSE OF SUCH DAMAGES. 

You accept this software on the condition that you
indemnify and hold harmless Ryan "FrikaC" Smith from
any and all liability or damages to third parties,
including attorney fees, court costs, and other
related costs and expenses, arising out of your use
of this software irrespective of the cause of said
liability. 

The export from the United States or the subsequent
reexport of this software is subject to compliance
with United States export control and munitions
control restrictions. You agree that in the event you
seek to export this software, you assume full
responsibility for obtaining all necessary export
licenses and approvals and for assuring compliance
with applicable reexport restrictions. 

Any reproduction of this software must contain
this notice in its entirety. 
*/

#include "libfrikbot.h"

struct bot_data_t = {
	string name;
	float pants, shirt;
};

bot_data_t [32] bot_data = {
	{"Vincent",   11,  0},
	{"Bishop",     1,  3},
	{"Nomad",     13,  2},
	{"Hudson",     7,  6},
	{"Lore",      12,  6},
	{"Servo",      4,  4},
	{"Gort",       2,  5},
	{"Kryten",    10,  3},
	{"Pimp Bot",   9,  4},
	{"Max",        4,  7},
	{"Marvin",     3, 11},
	{"Erwin",     13, 12},
	{"FrikBot",   11,  2},
	{"Krosis",     0,  2},
	{"Gypsy",      8,  9},
	{"Hal",        5, 10},
	{"Orion",      0, 11},
	{"Centauri",   3,  1},
	{"Draco",      2, 13},
	{"Casseopia",  6,  7},
	{"Herculese",  6, 12},
	{"Zeus",       4,  4},
	{"Shiva",      5,  2},
	{"Charon",     3, 10},
	{"Apollo",     4,  9},
	{"Jupiter",    7,  4},
	{"Saturn",    11,  3},
	{"Uranus",    12, 13},
	{"Neptune",    2, 11},
	{"Pluto",      2,  0},
	{"Mars",       9,  8},
	{"Mercury",   10,  5},
};

/*
BotName

Sets bot's name and colors
*/
string (integer r)
BotName =
{
	self.b_num = r;
	if (r < 0 || r >= 32)
		return NIL;
	self.b_pants = bot_data[r].pants;
	self.b_shirt = bot_data[r].shirt;
	return bot_data[r].name;
};

string ()
PickARandomName =
{
	local integer y, test;
	local string h;
	local entity t;
	y = TRUE;
	while (y) {
		test = (integer) (32 * random ());
		h = BotName (test);
		t = find (NIL, netname, h);
		if (t == NIL)
			y = FALSE;
	}
	return h;
};

// I didn't like the old code so this is very stripped down

entity b_originator;
float b_topic;
/* FBX Topics

b_originator == self
 1 - sign on
 2 - killed targ
 3 - team message "friendly eyes"
 4 - team message "on your back"
 5 - team message "need back up"
 6 - excuses
 ----
 7 - gameover
 ----
 8 - welcoming someone onto server
 9 - ridicule lost frag (killed self?)
 10 - ridicule lost frag (lava)
 11 - lag
b_originator == targ
*/
void (float tpic)
bot_start_topic =
{
	if (random() < 0.2) {
		b_topic = tpic;
		b_originator = self;
	} else
		b_topic = 0;
};

void ()
bot_chat =
{
	local float r;

	if (b_options & OPT_NOCHAT)
		return;

	r = ceil (6 * random ());
	
	if (self.b_chattime > time) {
		if (self.b_skill < 2)
			self.keys = self.button0 = self.button2 = 0;
		return;
	} else if (self.b_chattime) {
		switch (b_topic) {
		case 1:
			if (b_originator == self) {
				switch (r) {
				case 1:
					BotSay (": lo all\n");
					bot_start_topic (8);
					break;
				case 2:
					BotSay (": hey everyone\n");
					bot_start_topic (8);
					break;
				case 3:
					BotSay (": prepare to be fragged!\n");
					bot_start_topic (0);
					break;
				case 4:
					BotSay (": boy this is laggy\n");
					bot_start_topic (11);
					break;
				case 5:
					BotSay (": #mm getting some lag here\n");
					bot_start_topic (11);
					break;
				default:
					BotSay(": hi everyone\n");
					bot_start_topic (8);
					break;
				}
			}
			break;
		case 2:
			if (b_originator == self) {
				switch (r) {
				case 1:
					BotSay (": take that\n");
					break;
				case 2:
					BotSay (": yehaww!\n");
					break;
				case 3:
					BotSay (": wh00p\n");
					break;
				case 4:
					BotSay (": j00_sawk();\n");
					break;
				case 5:
					BotSay (": i rule\n");
					break;
				default:
					BotSay (": eat that\n");
					break;
				}
				bot_start_topic (0);
			}
			break;
		case 3:
			if (b_originator == self) {
				if (r < 3)
					BotSayTeam (": friendly eyes\n");
				else
					BotSayTeam (": team eyes\n");
				bot_start_topic (0);
			}
			break;
		case 4:
			if (b_originator == self) {
				if (r < 3)
					BotSayTeam (": on your back\n");
				else
					BotSayTeam (": I'm with you\n");
				bot_start_topic (0);
			}
			break;
		case 5:
			if (b_originator == self) {
				if (r < 3)
					BotSayTeam (": I need help\n");
				else
					BotSayTeam (": need backup\n");
				bot_start_topic (0);
			}
			break;
		case 6:
			if (b_originator == self) {
				switch (r) {
				case 1:
					BotSay (": sun got in my eyes\n");
					bot_start_topic (0);
					break;
				case 2:
					BotSay (": mouse needs cleaning\n");
					bot_start_topic (0);
					break;
				case 3:
					BotSay (": i meant to do that\n");
					bot_start_topic (0);
					break;
				case 4:
					BotSay (": lag\n");
					bot_start_topic (11);
					break;
				case 5:
					BotSay (": killer lag\n");
					bot_start_topic (11);
					break;
				default:
					BotSay (": 100% lag\n");
					bot_start_topic (11);
					break;
				}
			}
			break;
		case 7:
			switch (r) {
			case 1:
				BotSay (": gg\n");
				break;
			case 2:
				BotSay (": gg all\n");
				break;
			case 3:
				BotSay (": that was fun\n");
				break;
			case 4:
				BotSay (": good game\n");
				break;
			case 5:
				BotSay (": pah\n");
				break;
			default:
				BotSay (": hrm\n");
				break;
			}
			bot_start_topic (0);
			break;
		case 8:
			if (b_originator != self) {
				switch (r) {
				case 1:
					BotSay (": heya\n");
					bot_start_topic (0);
					break;
				case 2:
					BotSay (": welcome\n");
					bot_start_topic (0);
					break;
				case 3:
					BotSayInit ();
					BotSay2 (": hi ");
					BotSay2 (b_originator.netname);
					BotSay2 ("\n");
					bot_start_topic (0);
					break;
				case 5:
					BotSayInit ();
					BotSay2 (": hey ");
					BotSay2 (b_originator.netname);
					BotSay2 ("\n");
					bot_start_topic (0);
					break;
				case 6:
					BotSay (": howdy\n");
					bot_start_topic (0);
					break;
				default:
					BotSay(": lo\n");
					bot_start_topic(0);	
					break;
				}
			}
			break;
		case 9:
			if (b_originator != self) {
				switch (r) {
				case 1:
					BotSay (": hah\n");
					break;
				case 2:
					BotSay (": heheh\n");
					break;
				case 3:
					BotSayInit ();
					BotSay2 (": good work ");
					BotSay2 (b_originator.netname);
					BotSay2 ("\n");
					break;
				case 4:
					BotSayInit ();
					BotSay2 (": nice1 ");
					BotSay2 (b_originator.netname);
					BotSay2 ("\n");
					break;
				case 5:
					BotSay (": lol\n");
					break;
				default:
					BotSay (": :)\n");
					break;
				}
				b_topic = 6;
			}
			break;
		case 10:
			if (b_originator != self) {
				switch (r) {
				case 1:
					BotSay (": have a nice dip?\n");
					break;
				case 2:
					BotSay (": bah I hate levels with lava\n");
					break;
				case 3:
					BotSayInit();
					BotSay2 (": good job ");
					BotSay2 (b_originator.netname);
					BotSay2 ("\n");
					break;
				case 4:
					BotSayInit ();
					BotSay2 (": nice backflip ");
					BotSay2 (b_originator.netname);
					BotSay2 ("\n");
					break;
				case 5:
					BotSay (": watch your step\n");
					break;
				default:
					BotSay (": hehe\n");
					break;
				}
				b_topic = 6;
			}
			break;
		case 11:
			if (b_originator != self) {
				switch (r) {
				case 1:
					BotSayInit ();
					BotSay2 (": yeah right ");
					BotSay2 (b_originator.netname);
					BotSay2 ("\n");
					bot_start_topic (0);
					break;
				case 2:
					BotSay (": ping\n");
					bot_start_topic (0);
					break;
				case 3:
					BotSay (": shuddup, you're an lpb\n");
					bot_start_topic (0);
					break;
				case 4:
					BotSay (": lag my eye\n");
					bot_start_topic (0);
					break;
				case 5:
					BotSay (": yeah\n");
					bot_start_topic (11);
					break;
				default:
					BotSay (": totally\n");
					bot_start_topic (11);
					break;
				}
			}
		default:
			break;
		}
		self.b_chattime = 0;
	} else if (b_topic) {
		if (random () < 0.5) {
			if (self == b_originator) {
				if (b_topic <= 7)
					self.b_chattime = time + 2;
			} else {
				if (b_topic >= 7)
					self.b_chattime = time + 2;
			}
		}
	}
};

void ()
KickABot =
{
	local entity ty;

	ty = find (NIL, classname, "player");
	while (ty != NIL) {
		if (!(ty.ishuman)) {
			BotDisconnect (ty);
			ty.ishuman = TRUE;
			ty = NIL;
		} else
			ty = find (ty, classname, "player");
	}
};

/*
Simplified origin checking. 

God, I wish I had inline
*/
vector (entity ent)
realorigin =
{
	// even more simplified...
	return (ent.absmin + ent.absmax) * 0.5;
};

/*
fisible

a version of visible that checks for corners
of the bounding boxes
*/
float (entity targ)
fisible =
{
	local float		thruwater = 0, pc1 = 0, pc2 = 0;
	local vector	spot1, org;

	org = realorigin (targ);
	spot1 = self.origin + self.view_ofs;
	
	if (targ.solid == SOLID_BSP) {
		traceline (spot1, org, TRUE, self);
		if (trace_ent == targ)
			return TRUE;
		else if (trace_fraction == 1)
			return TRUE;
		return FALSE;
	} else {
		pc1 = pointcontents (org);
		pc2 = pointcontents (spot1);
		if (targ.classname == "player")
			thruwater = FALSE;
		else if (pc1 == CONTENT_LAVA)
			return FALSE;
		else	
			thruwater = TRUE;
	}
	
	if (pc1 < -1) {
		// targ's origin is in water or other liquid
		if (pc2 != pc1) {
			// look for their head
			traceline (spot1, org + targ.mins, TRUE, self);
			// cross the water check
			if (trace_inopen)
				if (trace_inwater)
					if (!thruwater)
						return FALSE;
			if (trace_ent == targ)
				return TRUE;
			else if (trace_fraction == 1)
				return TRUE;
			return FALSE;
		}
	} else {
		if (pc2 != pc1) {
			traceline (spot1, org + targ.maxs, TRUE, self);
			if (trace_inopen)
				if (trace_inwater)
					if (!thruwater)
						return FALSE;
			if (trace_ent == targ)
				return TRUE;
			else if (trace_fraction == 1)
				return TRUE;
			return FALSE;
		}
	}
	traceline (spot1, org, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	traceline (spot1, org + targ.maxs, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	traceline (spot1, org + targ.mins, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	return FALSE;
};


/*
sisible

Now this is getting ridiculous. Simple visible,
used when we need just a simple traceline nothing else
*/
float (entity targ)
sisible =
{
	traceline (self.origin, targ.origin, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
};

/*
angcomp

subtracts one angle from another
*/
float (float y1, float y2)
angcomp = 
{
	local float answer;

	y1 = frik_anglemod (y1);
	y2 = frik_anglemod (y2);

	answer = y1 - y2;
	if (answer > 180)
		answer -= 360;
	else if (answer < -180)
		answer += 360;
	return answer;
};

/*
fov

is the entity in the bot's field of view
*/
float (entity targ)
fov =
{
	local float		g;
	local vector	yawn;

	yawn = realorigin (targ);
	yawn = (yawn + targ.view_ofs) - (self.origin + self.view_ofs);
	yawn = normalize (yawn);
	yawn = vectoangles (yawn);
	g = angcomp (self.v_angle_x, yawn_x);
	if (fabs (g) > 45)
		return FALSE;
	g = angcomp (self.v_angle_y, yawn_y);
	if (fabs (g) > 60)
		return FALSE;
	return TRUE;
};

float (float v)
frik_anglemod =
{
	return v - floor (v / 360) * 360;
};
