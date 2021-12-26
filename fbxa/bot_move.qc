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

int bot_move_linker;

float (int keys, int key) key_state =
{
	return ((keys & key) != 0) ? 1.0 : 0.0;
};

void (vector start, vector mins, vector maxs, vector end, float type,
      entity passent) tracebox = #98;              // Wrapper around SV_Move.


@implementation Bot (Move)

-(void)sendMove
{
	local vector movevect = '0 0 0';
	local float anglespeed;
	local vector view;
	local vector probe, start;
	local int obstructed = 0;

	movevect.y += (350 * key_state (keys, KEY_MOVERIGHT));
	movevect.y -= (350 * key_state (keys, KEY_MOVELEFT));

	movevect.x += (200 * key_state (keys, KEY_MOVEFORWARD));
	movevect.x -= (200 * key_state (keys, KEY_MOVEBACK));

	movevect.z += (200 * key_state (keys, KEY_MOVEUP));
	movevect.z -= (200 * key_state (keys, KEY_MOVEDOWN));

	if (!(b_aiflags & AI_PRECISION))
		movevect *= 2;

	if (b_skill != 2) {
		// use mouse emulation
		anglespeed = 1.5 * real_frametime;
		// 1.5 is the default cl_anglespeedkey & bot always has +speed
		ent.v_angle.y += anglespeed * key_state (keys, KEY_LOOKLEFT) * 140;
		// 140 is default cl_yawspeed
		ent.v_angle.y -= anglespeed * key_state (keys, KEY_LOOKRIGHT) * 140;
		// 140 is default cl_yawspeed
		ent.v_angle.x -= anglespeed * key_state (keys, KEY_LOOKUP) * 150;
		// 150 is default cl_pitchspeed
		ent.v_angle.x += anglespeed * key_state (keys, KEY_LOOKDOWN) * 150;
		// 150 is default cl_pitchspeed
	} else {
		view.x = angcomp (b_angle.x, ent.v_angle.x);
		view.y = angcomp (b_angle.y, ent.v_angle.y);
		view.z = 0;
		if (vlen (view) > 30) {
			mouse_emu += (view * 30);
			if (vlen(mouse_emu) > 180)
				mouse_emu = normalize (mouse_emu) * 180;
		} else
			mouse_emu = view * (1 / real_frametime);
		ent.v_angle += mouse_emu * real_frametime;

		
	}
	start = ent.origin;
	//start.z += 16;			// step offset
	makevectors (ent.v_angle);
	probe = v_forward * movevect.x + v_right * movevect.y + ent.velocity;
	probe.z = 0;
	if (probe) {
		probe = normalize (probe);
		probe = probe * 32 + start;
		tracebox (start, ent.mins, ent.maxs, probe, 1, ent);
		if (trace_fraction != 1) {
			obstructed = 1;
			probe = (probe - start);
			if (trace_fraction)
				probe *= trace_fraction;
			else
				probe = normalize (probe);
		}
	}
	//dprint (itos (buttons) + " " + itos (impulse) + "\n");
	//dprint (ftos (real_frametime) + "\n");
	SV_UserCmd (ent, real_frametime, ent.v_angle, movevect, buttons, impulse);
	impulse = 0;
	if (obstructed)
		[self obstructed:probe:FALSE];
}

- (void) jump
{
	// TODO check for precision, etc.
	buttons |= 4;
}

- (int) canRJ
{
	// this returns true of the bot can rocket/superjump/hook
	// if your mod doesn't have an RL you can just return FALSE all the time
	// if it has a hook or some other means for the bot to get to high places
	// you can check here for that capability

	// am I dumb?
	if (b_skill == 0)
		return FALSE;

	// quad = bad
	if (ent.items & IT_QUAD)
		return FALSE;

	// do I have rockets & RL?
	if (!((ent.items & IT_ROCKET_LAUNCHER) && (ent.ammo_rockets > 0)))
		return FALSE;

	// do I have pent?
	if (ent.items & IT_INVULNERABILITY)
		return TRUE;

	if (ent.health > 50)
		return TRUE;
	else
		return FALSE;
}

- (int) recognizePlat: (int) flag
{
	local int ret;

	if (!(ent.flags & FL_ONGROUND))
		return FALSE;
	ret = [super recognizePlat:flag];
	if (ret && flag) {
		// afect bot movement too
		if (keys & KEY_MOVEUP) {
			if (trace_ent.velocity.z > 0)
				keys &= ~KEY_MOVE;
		} else if (keys & KEY_MOVEDOWN) {
			if (trace_ent.velocity.z < 0)
				keys &= ~KEY_MOVE;
		}
	}
	return ret;
}

-(int)keysForDir: (vector) sdir
{
	local int outkeys;
	local float tang;
	local vector keydir;

	outkeys = 0;
	if (sdir.x || sdir.y) {
		// Everything is tested against 60 degrees, this allows the bot to
		// overlap the keys 30 degrees on each diagonal 45 degrees might look
		// more realistic

 		keydir = vectoangles (sdir);
		tang = angcomp (keydir.y, ent.v_angle.y);
		if ((tang <= 150) && (tang >= 30))
			outkeys |= KEY_MOVELEFT;
		else if ((tang >= -150) && (tang <= -30))
			outkeys |= KEY_MOVERIGHT;
		if (fabs(tang) <= 60)
			outkeys |= KEY_MOVEFORWARD;
		else if (fabs(tang) >= 120)
			outkeys |= KEY_MOVEBACK;
	}
	if (sdir.z > 0.7)
		outkeys |= KEY_MOVEUP;
	else if (sdir.z < 0.7)
		outkeys |= KEY_MOVEDOWN;
	return outkeys;
}

/*
frik_obstructed

Bot has hit a ledge or wall that he should
manuever around.
*/
-(void)obstructed: (vector) whichway : (int) danger
{
	local float dist;
	local vector disway, org;

// TODO: something
	if (b_aiflags & AI_BLIND)
		return;

	if (danger) {
		b_aiflags |= AI_DANGER;
		keys = [self keysForDir:-whichway];
	}
	if (b_aiflags & AI_PRECISION)
		return;

	disway.z = 0;

	if (targets[0]) {
		if (b_aiflags & AI_OBSTRUCTED) {
			if (!(b_aiflags & AI_DANGER)) {
				b_aiflags &= ~AI_OBSTRUCTED;
				return;
			} else if (!danger)
				return;
		}
		org = [targets[0] realorigin];
		obs_dir = whichway;
		disway.x = whichway.y * -1;
		disway.y = whichway.x;
		dist = vlen (org - (ent.origin + disway));
		disway.x = whichway.y;
		disway.y = whichway.x * -1;
		wallhug = (vlen (org - (ent.origin + disway)) > dist);
		b_aiflags |= AI_OBSTRUCTED;
		
	} else {
		disway.x = whichway.y * -1;
		disway.y = whichway.x;
		dist = vlen (disway - obs_dir);
		disway.x = whichway.y;
		disway.y = whichway.x * -1;
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
	ang.z = 0;
	start = ent.origin + ang * 32; // ahem
	start.z = ent.origin.z + ent.maxs.z;
	stop = start;
	stop.z = ent.origin.z + ent.mins.z;
	traceline (start, stop - '0 0 256', TRUE, ent);
	if (trace_allsolid || trace_startsolid)
		return;
	hgt = trace_endpos.z - stop.z;

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
	ang.x = ent.velocity.y * -1;
	ang.y = ent.velocity.x;
	ang = normalize (ang);
	traceline (start - (ang * 10), start + (ang * 10), TRUE, ent);
	if ((trace_fraction != 1) || trace_startsolid)
		return; // gap is only 20 wide, walkable	
	ang = ent.velocity;
	ang.z = 0;
	dist = ((540 / sv_gravity) * vlen (ang))/* + 32*/;
	if (test > dist) {
		// I can't make it
		if (conts < -3) {
			// bad stuff down dare
			[self obstructed: ang :TRUE];
			return;
		} else {
			if (targets[0]) {
				stop = [targets[0] realorigin];
				if ((stop.z - ent.origin.z) < -32)
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
					stop = [targets[0] realorigin];
					if ((stop.z - ent.origin.z) < -32)
						return; // safe to fall
				}
				[self obstructed: ang :FALSE];
				return;
			}
		}

		if (targets[0]) {
			local vector org = [targets[0] origin];
			// getting furter away from my target?
			test = vlen (org - (ang + ent.origin));
			if (test > vlen (org - ent.origin)) {
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
			stop = [targets[0] realorigin];
			if ((stop.z - ent.origin.z) < -32)
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
-(void)dodgeObstruction
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
		way.z = 0;
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

	if (targets[0] == nil) {
		makevectors(ent.v_angle);
		[self walkmove: v_forward];
		return;
	}
	way = [targets[0] realorigin] - ent.origin;
	if (vlen(way) < 25) {
		keys &= ~KEY_MOVE;
		return;
	}

	way = normalize (way);
	keys &= ~KEY_MOVE;
	keys |= [self keysForDir: way];

	[self dodgeObstruction];
	[self recognizePlat: TRUE];

	if (b_aiflags & AI_PRECISION) {
		g = angcomp (ent.v_angle.x, b_angle.x);
		if (fabs (g) > 10)
			keys &= ~KEY_MOVE;
		g = angcomp (ent.v_angle.y, b_angle.y);
		if (fabs(g) > 10)
			keys &= ~KEY_MOVE;
	}
}

-(int)walkmove: (vector) weird
{
	// okay so it's not walkmove
	// sue me
 	keys &= ~KEY_MOVE;
	keys |= [self keysForDir: weird];

	[self dodgeObstruction];
	[self recognizePlat: TRUE];
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
		ang.y = frik_anglemod (ang.y - 90 + (180 * random ()));
		ang.x = 0; // avoid upward sloping
		makevectors (ang);
		traceline (org, org + v_forward * 2300, TRUE, ent);
		if (trace_fraction != 1) {
			org1 = trace_endpos;
			ang = normalize (trace_plane_normal);
			ang.z = 0; // avoid upward sloping
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
	b_angle.y = ent.v_angle.y + 10;
}
@end
