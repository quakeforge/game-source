/***********************************************
*                                              *
*            FrikBot General AI                *
*     "The I'd rather be playing Quake AI"     *
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

float stagger_think;

@implementation Bot (AI)
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

target_onstack

checks to see if an entity is on the bot's stack

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(integer)target_onstack:(entity)scot
{
	if (scot == NIL)
		return FALSE;
	else if (targets[0] == scot)
		return 1;
	else if (targets[1] == scot)
		return 2;
	else if (targets[2] == scot)
		return 3;
	else if (targets[3] == scot)
		return 4;
	else
		return FALSE;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

target_add

adds a new entity to the stack, since it's a
LIFO stack, this will be the bot's new target1

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)target_add:(entity)e
{
	if (e == NIL)
		return;
	if ([self target_onstack:e])
		return;

	targets[3] = targets[2];
	targets[2] = targets[1];
	targets[1] = targets[0];
	targets[0] = e;
	ent.search_time = time + 5;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

target_drop

Removes an entity from the bot's target stack.
The stack will empty everything up to the object
So if you have target2 item_health, target1
waypoint, and you drop the health, the waypoint
is gone too.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)target_drop:(entity)e
{
	switch ([self target_onstack:e]) {
	case 1:
		targets[0] = targets[1];
		targets[1] = targets[2];
		targets[2] = targets[3];
		targets[3] = NIL;
		break;
	case 2:
		targets[0] = targets[2];
		targets[1] = targets[3];
		targets[2] = targets[3] = NIL;
		break;
	case 3:
		targets[0] = targets[3];
		targets[1] = targets[2] = targets[3] = NIL;
		break;
	case 4:
		targets[0] = targets[1] = targets[2] = targets[3] = NIL;
	default:
		break;
	}
	ent.search_time = time + 5;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_lost

Bot has lost its target.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)lost:(WayPoint)targ :(integer)success
{
	if (!targ)
		return;

	[self target_drop:targ];
	if (targ.ent.classname == "waypoint")
		targ.b_sound &= ~(ClientBitFlag (b_clientno));

	// find a new route
	if (!success) {
		targets[0] = targets[1] = targets[2] = targets[3] = NIL;
		last_way = [self findWayPoint:current_way];
		[WayPoint clearMyRoute:self];
		b_aiflags = 0;
	} else {
		if (targ.ent.classname == "item_artifact_invisibility")
			if (ent.items & 524288)
				bot_start_topic (3);
                
				/*XXX
                if (targ.ent.flags & FL_ITEM) {
					if (!targ.ent.model)
						targ.prev = NIL;
					else
						targ.prev = ent;
                }
				*/
        }

	if (targ.ent.classname != "player")
		targ.search_time = time + 5;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_check_lost

decide if my most immediate target should be
removed.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)check_lost:(WayPoint)targ
{
	local vector dist;

	dist = realorigin (targ.ent) - ent.origin;
	dist_z = 0;

	if (targ == NIL)
		return;

	// waypoints and items are lost if you get close enough to them
	if (targ.ent.flags & FL_ITEM) {
		if (vlen (targ.ent.origin - ent.origin) < 32)
			[self lost:targ :TRUE];
		else if (!targ.ent.model)
			[self lost:targ :TRUE];
	} else if (targ.ent.classname == "waypoint") {
		if (!(b_aiflags & (AI_SNIPER | AI_AMBUSH))) {
			if (b_aiflags & AI_RIDE_TRAIN) {
				if (vlen (targ.origin - ent.origin) < 48)
					[self lost:targ :TRUE];
			} else if (b_aiflags & AI_PRECISION) {
				if (vlen (targ.origin - ent.origin) < 24)
					[self lost:targ :TRUE];
			} else if (vlen (targ.origin - ent.origin) < 32)
				[self lost:targ :TRUE];
		}
	} else if (targ.ent.classname == "temp_waypoint") {
		if (vlen (targ.origin - ent.origin) < 32)
			[self lost:targ :TRUE];
	} else if (targ.ent.classname == "player") {
		if (targ.ent.health <= 0)
			[self lost:targ :TRUE];
		else if ((coop) || (teamplay && targ.ent.team == ent.team)) {
			if (targ.targets[0].ent.classname == "player") {
				//XXX if (!targ.targets[0].ishuman)
					[self lost:targ :TRUE];
			} else if (targ.ent.teleport_time > time) {
				// try not to telefrag teammates
				keys &= 960;
			} else if (vlen (targ.origin - ent.origin) < 128) {
				if (vlen (targ.origin - ent.origin) < 48)
					[self walkmove: ent.origin - targ.origin];
				else {
					keys &= 960;
					bot_start_topic (4);
				}
				ent.search_time = time + 5; // never time out
			} else if (![self canSee:targ])
				[self lost:targ :FALSE];	
		} else if (waypoint_mode > WM_LOADED) {
			if (vlen (targ.origin - ent.origin) < 128) {
				[self lost:targ :TRUE];	
			}
		}
	} else if (targ.ent.classname == "func_button") {
		// buttons are lost of their frame changes
		if (targ.ent.frame) {
			[self lost:targ :TRUE];
			if (ent.enemy == targ.ent)
				ent.enemy = NIL;
//			if (target[0])
//				bot_get_path (target[0], TRUE);
		}
	} else if ((targ.ent.movetype == MOVETYPE_NONE) && (targ.ent.solid == SOLID_TRIGGER)) {
		// trigger_multiple style triggers are lost if their thinktime changes
		if (targ.ent.nextthink >= time) {
			[self lost:targ :TRUE];
//			if (target[0])
//				bot_get_path (target[0], TRUE);
		}
	}
	// lose any target way above the bot's head
	// FIXME: if the bot can fly in your mod..
	if ((targ.ent.origin_z - ent.origin_z) > 64) {
		dist = targ.ent.origin - ent.origin;
		dist_z = 0;
		if (vlen (dist) < 32)
			if (ent.flags & FL_ONGROUND)
				if (![self recognize_plat:FALSE])
					[self lost:targ :FALSE];
	} else if (targ.ent.classname == "train") {
		if ([self recognize_plat:FALSE])
			[self lost:targ :TRUE];
	}
	// targets are lost if the bot's search time has expired
	if (time > ent.search_time)
		[self lost:targ :FALSE];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_handle_ai

This is a 0.10 addition. Handles any action
based b_aiflags.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)handle_ai
{
	local entity newt;
	local vector v;

	// handle ai flags -- note, not all aiflags are handled
	// here, just those that perform some sort of action

	// wait is used by the ai to stop the bot until his search time expires / or route changes

	if (b_aiflags & AI_WAIT)
		keys &= 960;

	if (b_aiflags & AI_DOORFLAG) {
		// was on a door when spawned
		// if there is nothing there now
		if (![ent.@this recognize_plat:FALSE]) {
			newt = [self findThing: "door"]; // this is likely the door responsible (crossfingers)

			if (b_aiflags & AI_DOOR_NO_OPEN) {
				if (newt.nextthink)
					keys &= 960; // wait until it closes
				else {
					[self lost:last_way :FALSE];
				}
			} else {
				if (newt.targetname) {
					newt = find (NIL, target, newt.targetname);
					if (newt.health > 0) {
						ent.enemy = newt;
						[self weapon_switch:1];
					} else {
					//	target_drop (last_way);
						[self target_add:newt];
					//	bot_get_path (newt, TRUE);
					}
				}
				b_aiflags &= ~AI_DOORFLAG;
			}
		}
	}

	if (b_aiflags & AI_JUMP) {
		if (ent.flags & FL_ONGROUND) {
			[self jump];
			b_aiflags &= ~AI_JUMP;
		}
	} else if (b_aiflags & AI_SUPER_JUMP) {
		if (ent.weapon != 32)
			ent.impulse = 7;
		else if (ent.flags & FL_ONGROUND) {
			b_aiflags &= ~AI_SUPER_JUMP;
			if ([self can_rj]) {
				[self jump];
				v_angle.x = b_angle.x = 80;
				ent.button0 = TRUE;
			} else
				[self lost: targets[0] :FALSE];
		}
	}
	if (b_aiflags & AI_SURFACE) {
		if (ent.waterlevel > 2) {
			keys = KEY_MOVEUP;
			ent.button2 = TRUE; // swim!
		} else
			b_aiflags &= ~AI_SURFACE;
	}
	if (b_aiflags & AI_RIDE_TRAIN) {
		// simple, but effective
		// this can probably be used for a lot of different
		// things, not just trains (door elevators come to mind)
		if (![ent.@this recognize_plat:FALSE]) {
			// if there is nothing there now
			keys &= 960;
		} else {
			if ([self recognize_plat:FALSE]) {
				v = realorigin (trace_ent) + trace_ent.origin - ent.origin;
				v_z = 0;
				if (vlen (v) < 24)
					keys &= 960;
				else {
					b_aiflags |= AI_PRECISION;
					keys = [self keysForDir:v];
				}
			}
		}
	}
	if (b_aiflags & AI_PLAT_BOTTOM) {
		newt = [self findThing:"plat"];
		if (newt.state != 1) {
			v =  ent.origin - realorigin (newt);
			v_z = 0;
			if (vlen (v) > 96)
				keys &= 960;
			else
				[self walkmove:v];
		} else
			b_aiflags &= ~AI_PLAT_BOTTOM;
	}
	if (b_aiflags & AI_DIRECTIONAL) {
		if ((normalize (last_way.origin - ent.origin) * b_dir) > 0.4) {
			b_aiflags &= ~AI_DIRECTIONAL;
			[self lost:targets[0] :TRUE];
		}
	}
	if (b_aiflags & AI_SNIPER) {
		b_aiflags |= AI_WAIT | AI_PRECISION | AI_SNIPER;
		// FIXME: Add a switch to wep command
		// FIXME: increase delay?
	}
	if (b_aiflags & AI_AMBUSH) {
		b_aiflags |= AI_WAIT | AI_AMBUSH;
		// FIXME: Add a switch to wep command
		// FIXME: increase delay?
	}
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_path

Bot will follow a route generated by the
begin_route set of functions in bot_way.qc.
This code, while it works pretty well, can get
confused

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)path
{

	local WayPoint jj, tele;
	local entity e;

	[self check_lost:targets[0]];
	if (!targets[0]) {
		keys=0;
		return;
	}
	if ([self target_onstack:last_way])
		return; // old waypoint still being hunted

	jj = [self findRoute:last_way];
	if (!jj) {
		// this is an ugly hack
		/*XXX
		if (targets[0].current_way != last_way) {
			if (targets[0].classname != "temp_waypoint")
				if (targets[0].classname != "player")
					[self lost:targets[0] :FALSE];
		}
		*/

		return;
	}

	// update the bot's special ai features

	// Readahed types are AI conditions to perform while heading to a waypoint
	// point types are AI flags that should be executed once reaching a waypoint

	b_aiflags = (jj.flags & AI_READAHEAD_TYPES) | (last_way.flags & AI_POINT_TYPES);
	[self target_add:jj];
	if (last_way) {
		if ([last_way isLinkedTo:jj] == 2) {
			// waypoints are telelinked
			tele = [self findThing:"trigger_teleport"].@this; // this is probbly the teleport responsible
			[self target_add:tele];
		}
		traceline (last_way.origin, jj.origin, FALSE, ent); // check for blockage
   		if (trace_fraction != 1) {
			if (trace_ent.classname == "door" && !(b_aiflags & AI_DOOR_NO_OPEN)) {
				// a door blocks the way
				// linked doors fix
				if (trace_ent.owner)
					trace_ent = trace_ent.owner;
				if ((trace_ent.health > 0) && (ent.enemy == NIL)) {
					ent.enemy = trace_ent;
					[self weapon_switch:1];
					b_aiflags = b_aiflags | AI_BLIND; // nick knack paddy hack
				} else if (trace_ent.targetname) {
					e = find (NIL, target, trace_ent.targetname);
					if (e.health > 0) {
						ent.enemy = e;
						[self weapon_switch:1];
					} else {
//						target_drop (jj);
						[self target_add:e];
//						bot_get_path (tele, TRUE);
						b_aiflags |= AI_BLIND; // give a bot a bone	
						return;
					}					
				}		
			} else if (trace_ent.classname == "func_wall") {
				// give up
				[self lost:targets[0] :FALSE];
				return;
			}
		}
	}
	// this is used for AI_DRIECTIONAL
	b_dir = normalize (jj.origin - last_way.origin);

	last_way = jj;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Priority Look. What a stupid name. This is where
the bot finds things it wants to kill/grab.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
// priority scale
// 0 - 10 virtually ignore
// 10 - 30 normal item range
// 30 - 50 bot will consider this a target worth changing course for
// 50 - 90 bot will hunt these as vital items

// *!* Make sure you add code to bot_check_lost to remove the target *!*

-(float)priority_for_thing:(entity)thing
{
	local float thisp;

	thisp = 0;
	// This is the most executed function in the bot. Careful what you do here.
	if ((thing.flags & FL_ITEM) && thing.model && thing.search_time < time) {
		// ugly hack
		//XXX if (thing._last != ent)
		//XXX 	thisp = 20;
		if (thing.classname == "item_artifact_super_damage")
			thisp = 65;
		else if (thing.classname == "item_artifact_invulnerability")
			thisp = 65;
		else if (thing.classname == "item_health") {
			if (thing.spawnflags & 2)
				thisp = 55;
			if (ent.health < 40)
				thisp = thisp + 50;
		} else if (thing.model == "progs/armor.mdl") {
			if (ent.armorvalue < 200) {		
				if (thing.skin == 2)
					thisp = 60;
				else if (ent.armorvalue < 100)			
					thisp = thisp + 25;
			}
		} else if (thing.classname == "weapon_supershotgun") {
			if (!(ent.items & 2)) // IT_SUPER_SHOTGUN  
				thisp = 25;
		} else if (thing.classname == "weapon_nailgun") {
			if (!(ent.items & 4)) // IT_NAILGUN 
				thisp = 30;
		} else if (thing.classname == "weapon_supernailgun") {
			if (!(ent.items & 8)) // IT_SUPER_NAILGUN
				thisp = 35;
		} else if (thing.classname == "weapon_grenadelauncher") {
			if (!(ent.items & 16)) // IT_GRENADE_LAUNCHER
				thisp = 45;
		} else if (thing.classname == "weapon_rocketlauncher") {
			if (!(ent.items & 32)) // IT_ROCKET_LAUNCHER
				thisp = 60;
		} else if (thing.classname == "weapon_lightning") {
			if (!(ent.items & 64)) // IT_LIGHTNING
				thisp = 50;
		}
	} else if ((thing.flags & FL_MONSTER) && thing.health > 0)
		thisp = 45;
	else if (thing.classname == "player") { 
		if (thing.health > 0) {
			if (thing == ent)
				return 0;
			else {
				if (thing.items & IT_INVISIBILITY) //FIXME
					thisp = 2;
				else if (coop) {
					thisp = 100;
					//XXX if (thing.targets[0].classname == "player")
					//XXX 	if (!thing.targets[0].ishuman)
					//XXX 		return 0;
				} else if (teamplay && thing.team == ent.team) {
					thisp = 100;
					//XXX if (thing.targets[0].classname == "player")
					//XXX 	return 0;
				} else
					thisp = 30;
			}
		}
	} else if (thing.classname == "waypoint") {
		//XXX if (thing.b_aiflags & AI_SNIPER)
		//XXX 	thisp = 30;
		//XXX else if (thing.b_aiflags & AI_AMBUSH)
		//XXX 	thisp = 30;
	}
	if (pointcontents (thing.origin) < -3)
		return 0;
	if (thisp) {
		/*XXX
		if (thing.current_way) {
			// check to see if it's unreachable
			if (thing.current_way.items == -1)
				return 0;
			else
				thisp += (13000 - thing.current_way.items) * 0.05; 
		}
		*/
	} 		
	return thisp;
}

-(void)look_for_crap:(integer)scope
{
	local entity foe, best = NIL;
	local float thatp, bestp, dist;

	if (scope == 1)
		foe = findradius (ent.origin, 13000);
	else
		foe = findradius (ent.origin, 500);

	bestp = 1;
	while (foe) {
		thatp = [self priority_for_thing:foe];
		if (thatp)
			if (!scope)
				if (!sisible (ent, foe))
					thatp = 0;
		if (thatp > bestp) {
			bestp = thatp;
			best = foe;
			dist = vlen (ent.origin - foe.origin);
		}
		foe = foe.chain;
	}
	if (best == NIL)
		return;
	if (![self target_onstack:best]) {	
		[self target_add:best];
		if (scope) {
			[self get_path:best :FALSE];
			b_aiflags |= AI_WAIT;
		}
	}
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_angle_set

Sets the bots look keys & b_angle to point at
the target - used for fighting and just
generally making the bot look good.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)angle_set
{
	local float h;
	local vector view;
	
	if (ent.enemy) {
		if (ent.enemy.items & 524288)
			if (random () > 0.2)
				return;
		if (missile_speed == 0)
			missile_speed = 10000;
		if (ent.enemy.solid == SOLID_BSP) {
			view = (((ent.enemy.absmin + ent.enemy.absmax) * 0.5) - ent.origin);
		} else {
			h = vlen (ent.enemy.origin - ent.origin) / missile_speed;
			if (ent.enemy.flags & FL_ONGROUND)
				view = ent.enemy.velocity * h;
			else
				view = (ent.enemy.velocity - (sv_gravity * '0 0 1') * h) * h;
			view = ent.enemy.origin + view;  
			// FIXME: ?
			traceline (ent.enemy.origin, view, FALSE, ent);
			view = trace_endpos;
			
			if (ent.weapon == 32) 
				view = view - '0 0 22';

			view = normalize (view - ent.origin);
		}
		view = vectoangles (view);
		view_x = view_x * -1;
		b_angle = view;
	} else if (targets[0]) {
		view = realorigin (targets[0]);
		if (targets[0].flags & FL_ITEM)
			view = view + '0 0 48';
		view -= (ent.origin + ent.view_ofs);
		view = vectoangles (view);
		view_x *= -1;
		b_angle = view;
	} else
		b_angle.x = 0;
	// HACK HACK HACK HACK
	// The bot falls off ledges a lot because of "turning around"
	// so let the bot use instant turn around when not hunting a player
	if (b_skill == 3) {
		keys = keys & 63;
		v_angle = b_angle;
		while (v_angle.x < -180)
			v_angle.x += 360;
		while (v_angle.x > 180)
			v_angle.x -= 360;
	} else if ((ent.enemy == NIL || ent.enemy.movetype == MOVETYPE_PUSH) && targets[0].classname != "player") {
		keys = keys & 63;
		v_angle = b_angle;
		while (v_angle.x < -180)
			v_angle.x += 360;
		while (v_angle.x > 180)
			v_angle.x -= 360;
	} else if (b_skill < 2) {
		// skill 2 handled in bot_phys
		if (b_angle.x > 180)
			b_angle.x -= 360;
		keys = keys & 63;

		if (angcomp (b_angle.y, v_angle.y) > 10)
			keys = KEY_LOOKLEFT;
		else if (angcomp(b_angle.y, v_angle.y) < -10)
			keys |= KEY_LOOKRIGHT;
		if (angcomp(b_angle.x, v_angle.x) < -10)
			keys |= KEY_LOOKUP;
		else if (angcomp (b_angle.x, v_angle.x) > 10)
			keys |= KEY_LOOKDOWN;
	}
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotAI

This is the main ai loop. Though called every
frame, the ai_time limits it's actual updating

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)AI
{
	// am I dead? Fire randomly until I respawn
	// health < 1 is used because fractional healths show up as 0 on normal player
	// status bars, and the mod probably already compensated for that

	if (ent.health < 1) { 
		ent.button0 = floor (random() * 2);
		ent.button2 = 0;
		keys = 0;
		b_aiflags = 0;
		[WayPoint clearMyRoute:self];
		targets[0] = targets[1] = targets[2] = targets[3] = ent.enemy = NIL;
		last_way = NIL;
		return;
	}
		
	// stagger the bot's AI out so they all don't think at the same time, causing game
	// 'spikes'
	if (b_skill < 2) {
		if (ai_time > time)
			return;

		ai_time = time + 0.05;
		if (bot_count > 0) {
			if ((time - stagger_think) < (0.1 / bot_count))
				ai_time += 0.1 / (2 * bot_count);
		} else
			return;
	}
	if (ent.view_ofs == '0 0 0')
		bot_start_topic (7);
	stagger_think = time;

	// shut the bot's buttons off, various functions will turn them on by AI end
	ent.button2 = 0;
	ent.button0 = 0;

	// target1 is like goalentity in normal Quake monster AI.
	// it's the bot's most immediate target
	if (route_table == self) {
		if (busy_waypoints <= 0) {
			if (waypoint_mode < WM_EDITOR)
				[self look_for_crap:TRUE];
		}
		b_aiflags = 0;
		keys = 0;
	} else if (targets[0]) {
		[self movetogoal];
		[self path];
	} else {
		if (waypoint_mode < WM_EDITOR) {
			if (route_failed) {
				[self roam];
				route_failed = 0;
			} else if (![self begin_route]) {	
				[self look_for_crap:FALSE];
			}
			keys = 0;
		} else {
			b_aiflags = AI_WAIT;
			keys = 0;
		}
	}

	// bot_angle_set points the bot at it's goal (ent.enemy or target1)
	[self angle_set];

	// fight my enemy. Enemy is probably a field QC coders will most likely
	// use a lot for their own needs, since it's unused on a normal player
	// FIXME
	if (ent.enemy)
		[self fight_style];
	else if (random () < 0.2)
		if (random () < 0.2)
			[self weapon_switch:-1];
	[self dodge_stuff];

	// checks to see if bot needs to start going up for air
	if (ent.waterlevel > 2) {
		if (time > (ent.air_finished - 2)) {
			traceline (ent.origin, ent.origin + '0 0 6800', TRUE, ent);
			if (trace_inopen) {
				keys = KEY_MOVEUP;
				ent.button2 = TRUE; // swim!
				return; // skip ai flags for now - this is life or death
			}
		}
	}

	// b_aiflags handling
	if (b_aiflags)
		[self handle_ai]; 
	else
		bot_chat (); // don't want chat to screw him up if he's rjing or something
}

@end
