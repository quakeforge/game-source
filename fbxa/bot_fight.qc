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

/*
weapon_range

_x "sweet spot range" - try to maintain this range if possible
_y minimum range bot can be to be effective (rl/gl) (move away)
_z maximum range bot can be to be effective (lg/axe) (move in)
*/
vector (float wep)
weapon_range =
{
	switch (wep) {
	case 4096:	// IT_AXE
		return '48 0 64';
	case 1:		// IT_SHOTGUN
		return '128 0 99999';
	case 2:		// IT_SUPER_SHOTGUN
		return '128 0 99999';
	case 4:		// IT_NAILGUN
		return '180 0 3000';
	case 8:		// IT_SUPER_NAILGUN
		return '180 0 3000';
	case 16:	// IT_GRENADE_LAUNCHER
		return '180 48 3000';
	case 32:	// IT_ROCKET_LAUNCHER
		return '180 48 3000';
	case 64:	// IT_LIGHTNING
		return '350 0 512';
	default:
		break;
	}
};

@implementation Bot (Fight)
-(float)size_player:(entity)e
{
	local float		sz;

	sz = e.health + e.armorvalue * e.armortype;
	switch (e.weapon) {
	case 4096:
		sz -= 50;
		break;
	case 64:
		sz += 60;
		break;
	case 32:
		sz += 60;
		break;
	case 16:
		sz += 50;
		break;
	case 8:
		sz += 50;
		break;
	case 4:
		sz += 40;
		break;
	case 2:
		sz += 40;
		break;
	case 1:
		sz += 10;
		break;
	default:
		break;
	}

	if (e.items & 4194304) // Quad
		sz += 200;
	if (e.items & 1048576) // Invul
		sz += 300;
	if (e.items & 524288) // Invis
		sz += 250;
	return sz;
}

-(void)dodge_stuff
{
	local entity	foe;
	local float		foedist, avdist, foesz, flen, tsz;
	local vector	v;

	if (waypoint_mode > WM_LOADED)
		return;

	self.avoid = NIL;

	if (ent.enemy) {
		v = ent.origin - realorigin (ent.enemy);
		foedist = vlen (v);
		foesz = [self size_player:ent.enemy];
	} else {
		foedist = 3000;
		foesz = 9999999;
	}
	avdist = 256;

	foe = find (NIL, classname, "grenade");
	while (foe) {
		flen = vlen (foe.origin - ent.origin);
		if (flen < avdist) {
			avdist = flen;
			self.avoid = foe;
		}
		foe = find (foe, classname, "grenade");
	}
	if (!self.avoid) {
		foe = find (NIL, classname, "missile");
		while (foe) {
			if (foe.owner != ent) {
				flen = vlen (foe.origin - ent.origin);
				if (flen < avdist) {
					avdist = flen;
					self.avoid = foe;
				}
			}
			foe = find(foe, classname, "missile");
		}
		if (!self.avoid) {
			foe = find(NIL, classname, "spike");
			while (foe) {
				if (foe.owner != ent) {
					flen = vlen(foe.origin - ent.origin);
					if (flen < avdist) {
						avdist = flen;
						self.avoid = foe;
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
							tsz = [self size_player:foe];
							if (tsz < foesz) {
								if ([self canSee:foe]) {
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
		local integer i = 0;
		local Bot foe;
		for (i = 0; i < 32; i++) {
			if (!(foe = players[i]))
				continue;
			if(foe != self) {
				if (foe.ent.modelindex != 0) {
					if (foe.ent.health > 0) {
						if (!(teamplay && ent.team == foe.ent.team)) {
							flen = vlen (foe.ent.origin - ent.origin);
							if (flen < foedist) {
								tsz = [self size_player:foe];
								if (tsz < foesz) {
									/*XXX
									if (fov(foe) || foe.b_sound > time || self.b_skill == 3) {
										if ([self canSee:foe]) {
											ent.enemy = foe;
											foedist = vlen (foe.origin - ent.origin);
										}
									}
									*/
								}
							}
						}
					}
				}
			}
		}
	}
}

/*
bot_weapon_switch

Pick a weapon based on range / ammo
*/
-(void)weapon_switch:(float)brange
{
	local float		it, flag = 0, pulse = 0;
	local vector	v;

	it = ent.items & 127;

	while (it) {
		if ((ent.ammo_rockets >= 1) && (it & 32)) {
			flag = 32;
			pulse = 7;
		} else if (ent.waterlevel <= 1 && ent.ammo_cells >= 1 && (it & 64)) {
			flag = 64;
			pulse = 8;
		} else if (ent.ammo_nails >= 2 && (it & 8)) {
			flag = 8;
			pulse = 5;
		} else if ((ent.ammo_rockets >= 1) && (it & 16)) {
			flag = 16;
			pulse = 6;
		} else if (ent.ammo_shells >= 2 && (it & 2)) {
			flag = 2;
			pulse = 3;
		} else if (ent.ammo_nails >= 1 && (it & 4)) {
			flag = 4;
			pulse = 4;
		} else if (ent.ammo_shells >= 1 && (it & 1)) {
			flag = 1;
			pulse = 2;
		} else {
			if (pulse)
				ent.impulse = pulse;
			return;
		}

		if (brange == -1) {
			if (pulse)
				ent.impulse = pulse;
			return;
		}

		v = weapon_range (flag);
		if (brange < v_y || brange > v_z)
			it = it - flag;
		else {
			if (pulse)
				ent.impulse = pulse;
			return;
		}
	}
}

-(void)shoot
{
	// quick little function to stop making him shoot the wrong way ! Argh
	local float g;

	g = angcomp (v_angle.x, b_angle.x);
	if (fabs (g) > 30)
		return; // argh, too far away
	g = angcomp (v_angle.y, b_angle.y);
	if (fabs (g) > 30)
		return; // not again!
	ent.button0 = TRUE;
}

/*
Bot_fight_style

This is the core of the bot's thinking when
attacking an enemy. 
*/
-(void)fight_style
{
	local float		foedist, mysz, foesz;
	local vector	v, v1 = '0 0 0', v2 = '0 0 0', org;

	if (ent.enemy.health <= 0) {
		ent.enemy = NIL;
		return;
	} else if (!ent.enemy.takedamage) {
		ent.enemy = NIL;
		return;
	} else if (![self canSee:ent.enemy]) {
		ent.enemy = NIL;
		return;
	}

	org = realorigin (ent.enemy);
	makevectors (self.v_angle);

	// decide if I should shoot
	foedist = vlen (org - ent.origin);
	v = weapon_range (ent.weapon);
	if (foedist > v_y && foedist < v_z) {
		traceline (ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + v_forward * v_z, FALSE, ent);
		if (vlen(trace_endpos - (ent.origin + ent.view_ofs)) >= v_y) {
			// try to avoid shooting teammates
			if (trace_ent.classname == "player")
				if ((trace_ent.team == ent.team && teamplay) || (coop))
					return;
			[self shoot];
		}
	} else
		[self weapon_switch:foedist];

	if (!(self.b_aiflags & (AI_PRECISION | AI_BLIND | AI_OBSTRUCTED))) {
		foesz = [self size_player:ent.enemy];
		mysz = [self size_player:self] + 5;

		if (foesz > mysz) {
			if (teamplay) {
				if (random () < 0.02) {
					[self start_topic:5];
					self.b_chattime = 1;
				}
			}
			return;
		} else if (mysz < 140)
			return;
		else if (self.avoid) {
			if (self.avoid.velocity)
				v = self.avoid.velocity;
			else
				v = normalize (self.avoid.origin - ent.origin);
			v1_x = v_y;
			v1_y = v_y * -1;
			v2_x = v_y;
			v2_y = v_y * -1;
			foedist = vlen (self.avoid.origin - (ent.origin + v1));
			if (foedist < vlen (self.avoid.origin - (ent.origin + v2)))
				[self walkmove:v2];
			else
				[self walkmove:v1];
		} else if (!(ent.enemy.flags & FL_MONSTER)) {
			if (foedist + 32 <  v_x)
				[self walkmove:ent.origin - org];
			else if (foedist - 32 >  v_x)
				[self walkmove:org - ent.origin];
			else if (self.wallhug)
				[self walkmove:v_right];
			else
				[self walkmove:v_right * -1];
		}
	} else {
		foesz = [self size_player:ent.enemy];
		mysz = [self size_player:self] + 5;

		if (foesz > mysz)
			return;
		else if (mysz < 140)
			return;
		self.keys &= 960;
	}
}
@end
