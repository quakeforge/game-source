/***********************************************
*                                              *
*            FrikBot Movement AI               *
*     "The slightly better movement AI"        *
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

@implementation Bot (Move)
- (void) jump
{
	// TODO check for precision, etc.
	ent.button2 = TRUE;
}

- (integer) can_rj
{
	// this returns true of the bot can rocket/superjump/hook
	// if your mod doesn't have an RL you can just return FALSE all the time
	// if it has a hook or some other means for the bot to get to high places
	// you can check here for that capability

	// am I dumb?
	if (b_skill == 0)
		return FALSE;

	// quad = bad
	if (ent.items & 4194304)
		return FALSE;

	// do I have rockets & RL?
	if (!((ent.items & 32) && (ent.ammo_rockets > 0)))
		return FALSE;

	// do I have pent?
	if (ent.items & 1048576)
		return TRUE;

	if (ent.health > 50)
		return TRUE;
	else
		return FALSE;
}

- (integer) recognize_plat: (integer) flag
{
	if ((ent.classname != "waypoint") && !(ent.flags & FL_ONGROUND))
		return FALSE;
	traceline (ent.origin, ent.origin - '0 0 64', TRUE, ent);
	if (trace_ent != NIL) {
		if (flag) {
			// afect bot movement too
			if (keys & KEY_MOVEUP) {
				if (trace_ent.velocity_z > 0)
					keys &= ~KEY_MOVE;
			} else if (keys & KEY_MOVEDOWN) {
				if (trace_ent.velocity_z < 0)
					keys &= ~KEY_MOVE;
			}
		}
		return TRUE;
	} else
		return FALSE;
}

-(integer)keysForDir: (vector) sdir
{
	local integer outkeys;
	local float tang;
	local vector keydir;

	outkeys = 0;
	if (sdir_x || sdir_y) {
		// Everything is tested against 60 degrees, this allows the bot to
		// overlap the keys 30 degrees on each diagonal 45 degrees might look
		// more realistic

 		keydir = vectoangles (sdir);
		tang = angcomp (keydir_y, ent.v_angle_y);
		if ((tang <= 150) && (tang >= 30))
			outkeys |= KEY_MOVELEFT;
		else if ((tang >= -150) && (tang <= -30))
			outkeys |= KEY_MOVERIGHT;
		if (fabs(tang) <= 60)
			outkeys |= KEY_MOVEFORWARD;
		else if (fabs(tang) >= 120)
			outkeys |= KEY_MOVEBACK;
	}
	if (sdir_z > 0.7)
		outkeys |= KEY_MOVEUP;
	else if (sdir_z < 0.7)
		outkeys |= KEY_MOVEDOWN;
	return outkeys;
}

/*
frik_obstructed

Bot has hit a ledge or wall that he should
manuever around.
*/
-(void)obstructed: (vector) whichway : (integer) danger
{
	local float dist;
	local vector disway, org;

// TODO: something
	if (b_aiflags & AI_BLIND)
		return;
	org = realorigin(targets[0]);

	if (danger) {
		b_aiflags |= AI_DANGER;
		keys = [self keysForDir:'0 0 0' - whichway];
	}
	if (b_aiflags & AI_PRECISION)
		return;


	if (targets[0]) {
		if (b_aiflags & AI_OBSTRUCTED) {
			if (!(b_aiflags & AI_DANGER)) {
				b_aiflags &= ~AI_OBSTRUCTED;
				return;
			} else if (!danger)
				return;
		}
		obs_dir = whichway;
		disway_x = whichway_y * -1;
		disway_y = whichway_x;
		disway_z = 0;
		dist = vlen (org - (ent.origin + disway));
		disway_x = whichway_y;
		disway_y = whichway_x * -1;
		wallhug = (vlen (org - (ent.origin + disway)) > dist);
		b_aiflags |= AI_OBSTRUCTED;
		
	} else {
		disway_x = whichway_y * -1;
		disway_y = whichway_x;
		disway_z = 0;
		dist = vlen (disway - obs_dir);
		disway_x = whichway_y;
		disway_y = whichway_x * -1;
		wallhug = (vlen (disway - obs_dir) < dist);
		obs_dir = whichway;

		b_aiflags |= AI_OBSTRUCTED;
	}
}

/*
frik_obstacles

Detects small bumps the bot needs to jump over
or ledges the bot should avoid falling in.
Also responsible for jumping gaps.
*/
-(void)obstacles
{
	local vector start, stop, ang;
	local float test, conts, dist, hgt;

	if (!(ent.flags & FL_ONGROUND))
		return;
	if (b_aiflags & AI_BLIND)
		return;

	ang = normalize(ent.velocity);
	ang_z = 0;
	start = ent.origin + ang * 32; // ahem
	start_z = ent.origin_z + ent.maxs_z;
	stop = start;
	stop_z = ent.origin_z + ent.mins_z;
	traceline (start, stop - '0 0 256', TRUE, ent);
	if (trace_allsolid || trace_startsolid)
		return;
	hgt = trace_endpos_z - stop_z;

	if (hgt > 18) {
		[self jump];
		return;
	}
	if (hgt >= 0)
		return;

	conts = pointcontents (trace_endpos + '0 0 4');
	start = stop - '0 0 8';
	stop = start + ang *  256;
	traceline (start, stop, TRUE, ent);
	test = vlen(trace_endpos - start);
	if (test <= 20)
		return; // it's a walkable gap, do nothing
	ang_x = ent.velocity_y * -1;
	ang_y = ent.velocity_x;
	ang = normalize (ang);
	traceline (start - (ang * 10), start + (ang * 10), TRUE, ent);
	if ((trace_fraction != 1) || trace_startsolid)
		return; // gap is only 20 wide, walkable	
	ang = ent.velocity;
	ang_z = 0;
	dist = ((540 / sv_gravity) * vlen (ang))/* + 32*/;
	if (test > dist) {
		// I can't make it
		if (conts < -3) {
			// bad stuff down dare
			[self obstructed: ang :TRUE];
			return;
		} else {
			if (targets[0]) {
				stop = realorigin(targets[0]);
				if ((stop_z - ent.origin_z) < -32)
					return; // safe to fall
			}
			[self obstructed: ang :FALSE];
			return;
		}
	} else {
		ang = normalize(ang);
		//look for a ledge
		traceline (ent.origin, ent.origin + (ang * (test + 20)), TRUE, ent); 
		if (trace_fraction != 1) {
			if (conts < -3) {
				// bad stuff down dare
				[self obstructed: ang :TRUE];
				return;
			} else {
				if (targets[0]) {
					stop = realorigin(targets[0]);
					if ((stop_z - ent.origin_z) < -32)
						return; // safe to fall
				}
				[self obstructed: ang :FALSE];
				return;
			}
		}

		if (targets[0]) {
			// getting furter away from my target?
			test = vlen (targets[0].origin - (ang + ent.origin));
			if (test > vlen (targets[0].origin - ent.origin)) {
				if (conts < -3) {
					// bad stuff down dare
					[self obstructed: ang :TRUE];
					return;
				} else {
					[self obstructed: ang :FALSE];
					return;
				}
			}
		}
	}
	if (hgt < -18) {
		if (targets[0]) {
			stop = realorigin (targets[0]);
			if ((stop_z - ent.origin_z) < -32)
				return; // safe to fall
		}
		[self jump];
	}
	// go for it

}

/*
After frik_obstructed, the bot uses the
following funtion to move "around" the obstacle

I have no idea how well it will work
*/
-(void)dodge_obstruction
{
	local vector way, org;
	local float oflags, yaw;

	if (!(b_aiflags & AI_OBSTRUCTED))
		return;
	if ((b_aiflags & (AI_BLIND | AI_PRECISION))
		|| !(ent.flags & FL_ONGROUND)) {
		b_aiflags &= ~AI_OBSTRUCTED;
		return;
	}

	// perform a walkmove check to see if the obs_dir is still obstructed
	// walkmove is less forgiving than frik_obstacles, so I dunno 
	// how well this will work

	oflags = ent.flags;
	org = ent.origin;

	yaw = vectoyaw (obs_dir);
	if (walkmove (yaw, 32))
		b_aiflags &= ~AI_OBSTRUCTED;
	else {
		if (b_aiflags & AI_DANGER) {
			way = '0 0 0' - obs_dir;
		} else if (wallhug) {
			way.x = obs_dir.y * -1;
			way.y = obs_dir.x;
		} else {
			way.x = obs_dir.y;
			way.y = obs_dir.x * -1;
		}
		way_z = 0;
		keys &= ~KEY_MOVE;
		keys |= [self keysForDir: way];
	}
	
	// fix the bot
	ent.origin = org;
	ent.flags = oflags;
}

/*
movetogoal and walkmove replacements

blah
*/
-(void) movetogoal
{
	local vector way;
	local float g;

	if (targets[0] == NIL) {
		makevectors(v_angle);
		[self walkmove: v_forward];
		return;
	}
	way = realorigin(targets[0]) - ent.origin;
	if (vlen(way) < 25) {
		keys &= ~KEY_MOVE;
		return;
	}

	way = normalize (way);
	keys &= ~KEY_MOVE;
	keys |= [self keysForDir: way];

	[self dodge_obstruction];
	[self recognize_plat: TRUE];

	if (b_aiflags & AI_PRECISION) {
		g = angcomp (v_angle.x, b_angle.x);
		if (fabs (g) > 10)
			keys &= ~KEY_MOVE;
		g = angcomp (v_angle.y, b_angle.y);
		if (fabs(g) > 10)
			keys &= ~KEY_MOVE;
	}
}

-(integer)walkmove: (vector) weird
{
	// okay so it's not walkmove
	// sue me
 	keys &= ~KEY_MOVE;
	keys |= [self keysForDir: weird];

	[self dodge_obstruction];
	[self recognize_plat: TRUE];
	if (b_aiflags & AI_OBSTRUCTED)
		return FALSE;
	else
		return TRUE;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
The "hook" method of navigation. This nav
system is copyrighted 1999 by Ryan "Frika C" 
Smith, keep that in mind when you steal it.

I brought this back because normal roaming
won't work - the bot gets distracted by it's
own waypoints.
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)roam
{
	local float loopcount, flag, dist;
	local vector org, ang, org1;

	loopcount = 26;
	flag = FALSE;
	while ((loopcount > 0) && !flag) {
		loopcount--;
		org = ent.origin + ent.view_ofs;
		ang = ent.angles;
		ang_y = frik_anglemod (ang_y - 90 + (180 * random ()));
		ang_x = 0; // avoid upward sloping
		makevectors (ang);
		traceline (org, org + v_forward * 2300, TRUE, ent);
		if (trace_fraction != 1) {
			org1 = trace_endpos;
			ang = normalize (trace_plane_normal);
			ang_z = 0; // avoid upward sloping
			traceline (org1, org1 + (ang * 2300), TRUE, ent);
			if ((trace_fraction != 1) && (vlen(trace_endpos - org1) >= 64)) {
				org = trace_endpos;
				traceline (org, ent.origin + ent.view_ofs, TRUE, ent);
				if (trace_fraction != 1) {
					dist = vlen (org1 - org) /2;
					org = org1 + (ang * dist);
					traceline(org, org - '0 0 48', TRUE, ent);
					if (trace_fraction != 1) {
						[self spawnTempWaypoint:org];
						flag = TRUE;
					}
				}
			}
		}
	}
	b_angle.y = v_angle.y + 10;
}
@end
