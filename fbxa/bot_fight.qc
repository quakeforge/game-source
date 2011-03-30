/***********************************************
*                                              *
*             FrikBot Fight Code               *
*      "Because I ain't no Ghandi code"        *
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

int bot_fight_linker;

/*
weapon_range

.x "sweet spot range" - try to maintain this range if possible
.y minimum range bot can be to be effective (rl/gl) (move away)
.z maximum range bot can be to be effective (lg/axe) (move in)
*/
vector (int wep)
weapon_range =
{
	switch (wep) {
	case IT_AXE:
		return '48 0 64';
	case IT_SHOTGUN:
		return '128 0 99999';
	case IT_SUPER_SHOTGUN:
		return '128 0 99999';
	case IT_NAILGUN:
		return '180 0 3000';
	case IT_SUPER_NAILGUN:
		return '180 0 3000';
	case IT_GRENADE_LAUNCHER:
		return '180 48 3000';
	case IT_ROCKET_LAUNCHER:
		return '180 48 3000';
	case IT_LIGHTNING:
		return '350 0 512';
	default:
		return '0 0 0';
	}
};

@implementation Bot (Fight)
-(float)sizePlayer:(Target *)targ
{
	local float		sz;
	local entity e = targ.ent;

	sz = e.health + e.armorvalue * e.armortype;
	switch (e.weapon) {
	case IT_AXE:
		sz -= 50;
		break;
	case IT_LIGHTNING:
		sz += 60;
		break;
	case IT_ROCKET_LAUNCHER:
		sz += 60;
		break;
	case IT_GRENADE_LAUNCHER:
		sz += 50;
		break;
	case IT_SUPER_NAILGUN:
		sz += 50;
		break;
	case IT_NAILGUN:
		sz += 40;
		break;
	case IT_SUPER_SHOTGUN:
		sz += 40;
		break;
	case IT_SHOTGUN:
		sz += 10;
		break;
	default:
		break;
	}

	if (e.items & IT_QUAD)
		sz += 200;
	if (e.items & IT_INVULNERABILITY)
		sz += 300;
	if (e.items & IT_INVISIBILITY)
		sz += 250;
	return sz;
}

-(void)dodgeStuff
{
	local entity	foe;
	local float		foedist, avdist, foesz, flen, tsz;
	local vector	v;

	if (waypoint_mode > WM_LOADED)
		return;

	avoid = nil;

	if (ent.enemy) {
		v = ent.origin - realorigin (ent.enemy);
		foedist = vlen (v);
		foesz = [self sizePlayer:[Target forEntity:ent.enemy]];
	} else {
		foedist = 3000;
		foesz = 9999999;
	}
	avdist = 256;

	foe = find (nil, classname, "grenade");
	while (foe) {
		flen = vlen (foe.origin - ent.origin);
		if (flen < avdist) {
			avdist = flen;
			avoid = foe;
		}
		foe = find (foe, classname, "grenade");
	}
	if (!avoid) {
		foe = find (nil, classname, "missile");
		while (foe) {
			if (foe.owner != ent) {
				flen = vlen (foe.origin - ent.origin);
				if (flen < avdist) {
					avdist = flen;
					avoid = foe;
				}
			}
			foe = find(foe, classname, "missile");
		}
		if (!avoid) {
			foe = find(nil, classname, "spike");
			while (foe) {
				if (foe.owner != ent) {
					flen = vlen(foe.origin - ent.origin);
					if (flen < avdist) {
						avdist = flen;
						avoid = foe;
					}
				}
				foe = find (foe, classname, "spike");
			}
		}
	}
	if (coop) {
		if (!ent.enemy) {
			foe = findradius (ent.origin, foedist);
			while (foe) {
				if (foe.flags & FL_MONSTER) {
					if (foe.health > 0) {
						flen = vlen (foe.origin - ent.origin);
						if (flen < foedist) {
							local Target *targ = [Target forEntity:foe];
							tsz = [self sizePlayer:targ];
							if (tsz < foesz) {
								if ([self canSee:targ]) {
									ent.enemy = foe;
									foedist = flen;
									foesz = tsz;
								}
							}
						}
					}
				}
				foe = foe.chain;
			}
		}		
	} else {
		local int i = 0;
		local Bot *foe;
		for (i = 0; i < 32; i++) {
			if (!(foe = players[i])) continue;
			if (foe == self) continue;
			if (foe.ent.modelindex == 0) continue;
			if (foe.ent.health <= 0) continue;
			if (teamplay && ent.team == foe.ent.team) continue;
			flen = vlen (foe.ent.origin - ent.origin);
			if (flen >= foedist) continue;
			tsz = [self sizePlayer:foe];
			if (tsz > foesz) continue;
			if ([self fov:foe.ent] || foe.b_sound > time || b_skill == 3) {
				if ([self canSee:foe]) {
					ent.enemy = foe.ent;
					foedist = vlen ([foe origin] - ent.origin);
				}
			}
		}
	}
}

/*
weaponSwitch

Pick a weapon based on range / ammo
*/
-(void)weaponSwitch:(float)brange
{
	local int	it, flag = 0, pulse = 0;
	local vector	v;

	it = (int) ent.items & 127;

	while (it) {
		if ((ent.ammo_rockets >= 1) && (it & IT_ROCKET_LAUNCHER)) {
			flag = IT_ROCKET_LAUNCHER;
			pulse = 7;
		} else if (ent.waterlevel <= 1 && ent.ammo_cells >= 1
				   && (it & IT_LIGHTNING)) {
			flag = IT_LIGHTNING;
			pulse = 8;
		} else if (ent.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN)) {
			flag = IT_SUPER_NAILGUN;
			pulse = 5;
		} else if ((ent.ammo_rockets >= 1) && (it & IT_GRENADE_LAUNCHER)) {
			flag = IT_GRENADE_LAUNCHER;
			pulse = 6;
		} else if (ent.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN)) {
			flag = IT_SUPER_SHOTGUN;
			pulse = 3;
		} else if (ent.ammo_nails >= 1 && (it & IT_NAILGUN)) {
			flag = IT_NAILGUN;
			pulse = 4;
		} else if (ent.ammo_shells >= 1 && (it & IT_SHOTGUN)) {
			flag = IT_SHOTGUN;
			pulse = 2;
		} else {
			if (pulse)
				impulse = pulse;
			return;
		}

		if (brange == -1) {
			if (pulse)
				impulse = pulse;
			return;
		}

		v = weapon_range (flag);
		if (brange < v.y || brange > v.z)
			it &= ~flag;
		else {
			if (pulse)
				impulse = pulse;
			return;
		}
	}
}

-(void)shoot
{
	// quick little function to stop making him shoot the wrong way ! Argh
	local float g;

	g = angcomp (ent.v_angle.x, b_angle.x);
	if (fabs (g) > 30)
		return; // argh, too far away
	g = angcomp (ent.v_angle.y, b_angle.y);
	if (fabs (g) > 30)
		return; // not again!
	buttons |= 1;
}

/*
fightStyle

This is the core of the bot's thinking when
attacking an enemy. 
*/
-(void)fightStyle
{
	local float		foedist, mysz, foesz;
	local vector	v, v1 = '0 0 0', v2 = '0 0 0', org;

	if (ent.enemy.health <= 0) {
		ent.enemy = nil;
		return;
	} else if (!ent.enemy.takedamage) {
		ent.enemy = nil;
		return;
	} else if (![self canSee:[Target forEntity:ent.enemy]]) {
		ent.enemy = nil;
		return;
	}

	org = realorigin (ent.enemy);
	makevectors (ent.v_angle);

	// decide if I should shoot
	foedist = vlen (org - ent.origin);
	v = weapon_range ((int)ent.weapon);
	if (foedist > v.y && foedist < v.z) {
		traceline (ent.origin + ent.view_ofs,
				   ent.origin + ent.view_ofs + v_forward * v.z, FALSE, ent);
		if (vlen(trace_endpos - (ent.origin + ent.view_ofs)) >= v.y) {
			// try to avoid shooting teammates
			if (trace_ent.classname == "player")
				if ((trace_ent.team == ent.team && teamplay) || (coop))
					return;
			[self shoot];
		}
	} else
		[self weaponSwitch:foedist];

	if (!(b_aiflags & (AI_PRECISION | AI_BLIND | AI_OBSTRUCTED))) {
		foesz = [self sizePlayer:[Target forEntity:ent.enemy]];
		mysz = [self sizePlayer:self] + 5;

		if (foesz > mysz) {
			if (teamplay) {
				if (random () < 0.02) {
					[self startTopic:5];
					b_chattime = 1;
				}
			}
			return;
		} else if (mysz < 140)
			return;
		else if (avoid) {
			if (avoid.velocity)
				v = avoid.velocity;
			else
				v = normalize (avoid.origin - ent.origin);
			v1.x = v.y;
			v1.y = v.y * -1;
			v2.x = v.y;
			v2.y = v.y * -1;
			foedist = vlen (avoid.origin - (ent.origin + v1));
			if (foedist < vlen (avoid.origin - (ent.origin + v2)))
				[self walkmove:v2];
			else
				[self walkmove:v1];
		} else if (!(ent.enemy.flags & FL_MONSTER)) {
			if (foedist + 32 <  v.x)
				[self walkmove:ent.origin - org];
			else if (foedist - 32 >  v.x)
				[self walkmove:org - ent.origin];
			else if (wallhug)
				[self walkmove:v_right];
			else
				[self walkmove:v_right * -1];
		}
	} else {
		foesz = [self sizePlayer:[Target forEntity:ent.enemy]];
		mysz = [self sizePlayer:self] + 5;

		if (foesz > mysz)
			return;
		else if (mysz < 140)
			return;
		keys &= ~KEY_MOVE;
	}
}
@end
