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
#include "Array.h"

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

Array bot_array;

@implementation Bot (Misc)
/*
BotName

Sets bot's name and colors
*/
+(bot_data_t [])name:(integer)r
{
	if (r < 0 || r >= 32)
		return NIL;
	return &bot_data[r];
}

+(bot_data_t [])randomName
{
	local integer test;
	local bot_data_t [] h;
	local entity t;

	while (1) {
		test = (integer) (32 * random ());
		h = [Bot name:test];
		t = find (NIL, netname, h.name);
		if (t == NIL)
			return h;
	}
}

+(void)kick
{
	local Bot ty;

	ty = [bot_array removeItemAt:0];
	if (ty)
		[ty disconnect];
}

/*
fov

is the entity in the bot's field of view
*/
-(integer)fov:(entity)targ
{
	local float		g;
	local vector	yawn;

	yawn = realorigin (targ);
	yawn = (yawn + targ.view_ofs) - (ent.origin + ent.view_ofs);
	yawn = normalize (yawn);
	yawn = vectoangles (yawn);
	g = angcomp (ent.v_angle_x, yawn_x);
	if (fabs (g) > 45)
		return FALSE;
	g = angcomp (ent.v_angle_y, yawn_y);
	if (fabs (g) > 60)
		return FALSE;
	return TRUE;
}
@end

float (float v)
frik_anglemod =
{
	return v - floor (v / 360) * 360;
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
sisible

Now this is getting ridiculous. Simple visible,
used when we need just a simple traceline nothing else
*/
float (entity ent, entity targ)
sisible =
{
	traceline (ent.origin, targ.origin, TRUE, ent);
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
