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

targetOnstack

checks to see if an entity is on the bot's stack

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(integer)targetOnstack:(Target)scot
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

targetAdd

adds a new entity to the stack, since it's a
LIFO stack, this will be the bot's new targets[0]

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)targetAdd:(Target)e
{
	if (e == NIL)
		return;
	if ([self targetOnstack:e])
		return;

	targets[3] = targets[2];
	targets[2] = targets[1];
	targets[1] = targets[0];
	targets[0] = e;
	[self setSearchTime:time + 5];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

targetDrop

Removes an entity from the bot's target stack.
The stack will empty everything up to the object
So if you have target2 item_health, targets[0]
waypoint, and you drop the health, the waypoint
is gone too.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)targetDrop:(Target)e
{
	switch ([self targetOnstack:e]) {
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
	[self setSearchTime:time + 5];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_lost

Bot has lost its target.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)lost:(Target)targ :(integer)success
{
	if (!targ)
		return;

	[self targetDrop:targ];
	if ([targ isKindOfClass:[Waypoint class]])
		[(Waypoint)targ clearRouteForBot:self];

	// find a new route
	if (!success) {
		targets[0] = targets[1] = targets[2] = targets[3] = NIL;
		last_way = [self findWaypoint:current_way];
		[Waypoint clearMyRoute:self];
		b_aiflags = 0;
	} else {
		if (targ.ent.classname == "item_artifact_invisibility")
			if (ent.items & IT_INVISIBILITY)
				[self startTopic:3];
                
                if (targ.ent.flags & FL_ITEM) {
					if (!targ.ent.model)
						targ._last = NIL;
					else
						targ._last = self;
                }
        }

	if (targ.ent.classname != "player")
		[self setSearchTime:time + 5];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

checkLost

decide if my most immediate target should be
removed.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)checkLost:(Target)targ
{
	local vector dist;

	if (targ == NIL)
		return;

	dist = [targ realorigin] - ent.origin;
	dist_z = 0;

	// waypoints and items are lost if you get close enough to them
	if ([targ isKindOfClass:[Waypoint class]]) {
		local Waypoint way = (Waypoint) targ;
		if (!(b_aiflags & (AI_SNIPER | AI_AMBUSH))) {
			if (b_aiflags & AI_RIDE_TRAIN) {
				if (vlen (way.origin - ent.origin) < 48)
					[self lost:way :TRUE];
			} else if (b_aiflags & AI_PRECISION) {
				if (vlen (way.origin - ent.origin) < 24)
					[self lost:way :TRUE];
			} else if (vlen (way.origin - ent.origin) < 32)
				[self lost:way :TRUE];
		}
		//temp_waypoint
		if (vlen (way.origin - ent.origin) < 32)
			[self lost:way :TRUE];
	} else if ([targ isKindOfClass:[Bot class]]) {
		local Bot bot = (Bot) targ;
		if (bot.ent.health <= 0)
			[self lost:bot :TRUE];
		else if ((coop) || (teamplay && bot.ent.team == ent.team)) {
			if (bot.targets[0].ent.classname == "player") {
				if (![bot.targets[0] ishuman])
					[self lost:bot :TRUE];
			} else if (bot.ent.teleport_time > time) {
				// try not to telefrag teammates
				keys &= ~KEY_MOVE;
			} else if (vlen (bot.ent.origin - ent.origin) < 128) {
				if (vlen (bot.ent.origin - ent.origin) < 48)
					[self walkmove: ent.origin - bot.ent.origin];
				else {
					keys &= ~KEY_MOVE;
					[self startTopic:4];
				}
				[self setSearchTime:time + 5]; // never time out
			} else if (![self canSee:bot])
				[self lost:bot :FALSE];	
		} else if (waypoint_mode > WM_LOADED) {
			if (vlen (bot.ent.origin - ent.origin) < 128) {
				[self lost:bot :TRUE];	
			}
		}
	} else {
		if (targ.ent.flags & FL_ITEM) {
			if (vlen (targ.ent.origin - ent.origin) < 32)
				[self lost:targ :TRUE];
			else if (!targ.ent.model)
				[self lost:targ :TRUE];
		} else if (targ.ent.classname == "func_button") {
			// buttons are lost of their frame changes
			if (targ.ent.frame) {
				[self lost:targ :TRUE];
				if (ent.enemy == targ.ent)
					ent.enemy = NIL;
	//			if (target[0])
	//				[self getPath:target[0] :TRUE];
			}
		} else if ((targ.ent.movetype == MOVETYPE_NONE)
				   && (targ.ent.solid == SOLID_TRIGGER)) {
			// trigger_multiple style triggers are lost if their thinktime
			// changes
			if (targ.ent.nextthink >= time) {
				[self lost:targ :TRUE];
	//			if (target[0])
	//				[self getPath:target[0] :TRUE];
			}
		}
	}
	// lose any target way above the bot's head
	// FIXME: if the bot can fly in your mod..
	if ((targ.ent.origin_z - ent.origin_z) > 64) {
		dist = targ.ent.origin - ent.origin;
		dist_z = 0;
		if (vlen (dist) < 32)
			if (ent.flags & FL_ONGROUND)
				if (![self recognizePlat:FALSE])
					[self lost:targ :FALSE];
	} else if (targ.ent.classname == "train") {
		if ([self recognizePlat:FALSE])
			[self lost:targ :TRUE];
	}
	// targets are lost if the bot's search time has expired
	if (time > [self searchTime])
		[self lost:targ :FALSE];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

handleAI

This is a 0.10 addition. Handles any action
based b_aiflags.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)handleAI
{
	local entity newt;
	local vector v;

	// handle ai flags -- note, not all aiflags are handled
	// here, just those that perform some sort of action

	// wait is used by the ai to stop the bot until his search time expires / or route changes

	if (b_aiflags & AI_WAIT)
		keys &= ~KEY_MOVE;

	if (b_aiflags & AI_DOORFLAG) {
		// was on a door when spawned
		// if there is nothing there now
		if (![last_way recognizePlat:FALSE]) {
			newt = [self findThing: "door"]; // this is likely the door responsible (crossfingers)

			if (b_aiflags & AI_DOOR_NO_OPEN) {
				if (newt.nextthink)
					keys &= ~KEY_MOVE; // wait until it closes
				else {
					[self lost:last_way :FALSE];
				}
			} else {
				if (newt.targetname) {
					newt = find (NIL, target, newt.targetname);
					if (newt.health > 0) {
						ent.enemy = newt;
						[self weaponSwitch:1];
					} else {
					//	targetDrop (last_way);
						[self targetAdd:[Target forEntity:newt]];
					//	[self getPath:newt :TRUE];
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
			impulse = 7;
		else if (ent.flags & FL_ONGROUND) {
			b_aiflags &= ~AI_SUPER_JUMP;
			if ([self canRJ]) {
				[self jump];
				ent.v_angle_x = b_angle.x = 80;
				buttons |= 1;
			} else
				[self lost: targets[0] :FALSE];
		}
	}
	if (b_aiflags & AI_SURFACE) {
		if (ent.waterlevel > 2) {
			keys = KEY_MOVEUP;
			buttons |= 4; // swim!
		} else
			b_aiflags &= ~AI_SURFACE;
	}
	if (b_aiflags & AI_RIDE_TRAIN) {
		// simple, but effective
		// this can probably be used for a lot of different
		// things, not just trains (door elevators come to mind)
		if (![last_way recognizePlat:FALSE]) {
			// if there is nothing there now
			keys &= ~KEY_MOVE;
		} else {
			if ([self recognizePlat:FALSE]) {
				v = realorigin (trace_ent) + trace_ent.origin - ent.origin;
				v_z = 0;
				if (vlen (v) < 24)
					keys &= ~KEY_MOVE;
				else {
					b_aiflags |= AI_PRECISION;
					keys |= [self keysForDir:v];
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
				keys &= ~KEY_MOVE;
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
beginRoute set of functions in bot_way.qc.
This code, while it works pretty well, can get
confused

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)path
{

	local Waypoint jj;
	local entity e, tele;

	[self checkLost:targets[0]];
	if (!targets[0]) {
		keys=0;
		return;
	}
	if ([self targetOnstack:last_way])
		return; // old waypoint still being hunted

	jj = [self findRoute:last_way];
	if (!jj) {
		// this is an ugly hack
		if (targets[0].current_way != last_way) {
			local string cn = [targets[0] classname];
			if (cn != "temp_waypoint")
				if (cn != "player")
					[self lost:targets[0] :FALSE];
		}

		return;
	}

	// update the bot's special ai features

	// Readahed types are AI conditions to perform while heading to a waypoint
	// point types are AI flags that should be executed once reaching a waypoint

	b_aiflags = (jj.flags & AI_READAHEAD_TYPES)
				| (last_way.flags & AI_POINT_TYPES);
	[self targetAdd:jj];
	if (last_way) {
		if ([last_way isLinkedTo:jj] == 2) {
			// waypoints are telelinked
			tele = [self findThing:"trigger_teleport"]; // this is probbly the teleport responsible
			[self targetAdd:[Target forEntity:tele]];
		}
		traceline (last_way.origin, jj.origin, FALSE, ent); // check for blockage
   		if (trace_fraction != 1) {
			if (trace_ent.classname == "door"
				&& !(b_aiflags & AI_DOOR_NO_OPEN)) {
				// a door blocks the way
				// linked doors fix
				if (trace_ent.owner)
					trace_ent = trace_ent.owner;
				if ((trace_ent.health > 0) && (ent.enemy == NIL)) {
					ent.enemy = trace_ent;
					[self weaponSwitch:1];
					b_aiflags = b_aiflags | AI_BLIND; // nick knack paddy hack
				} else if (trace_ent.targetname) {
					e = find (NIL, target, trace_ent.targetname);
					if (e.health > 0) {
						ent.enemy = e;
						[self weaponSwitch:1];
					} else {
//						targetDrop (jj);
						[self targetAdd:[Target forEntity:e]];
//						[self getPath:tele :TRUE];
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

// *!* Make sure you add code to checkLost to remove the target *!*

-(integer)priority:(Bot)bot
{
	local integer p;

	if (ent.health <= 0)
		return 0;
	if (ent.items & IT_INVISIBILITY) //FIXME
		p = 2;
	else if (coop) {
		if (targets[0].ent.classname == "player")
			if (![targets[0] ishuman])
				return 0;
		p = 100;
	} else if (teamplay && ent.team == bot.ent.team) {
		if (targets[0].ent.classname == "player")
			return 0;
		p = 100;
	} else
		p = 30;
	return p;
}

-(integer)priorityForThing:(Target)thing
{
	local integer p;
	// This is the most executed function in the bot. Careful what you do here.
	if (pointcontents ([thing origin]) < -3)
		return 0;

	p = [thing priority:self];

	if (thing.current_way) {
		// check to see if it's unreachable
		if (thing.current_way.items == -1)
			return 0;
		else
			p += (integer) ((13000 - thing.current_way.items) * 0.05);
	}
	return p;
}

-(void)lookForCrap:(integer)scope
{
	local Target foe, best = NIL;
	local Waypoint way;
	local integer thatp, bestp;
	local float radius;

	if (scope == 1)
		radius = 13000;
	else
		radius = 500;

	foe = [Target forEntity:findradius (ent.origin, radius)];
	bestp = 1;
	while (foe) {
		if (foe != self) {
			thatp = [self priorityForThing:foe];
			if (thatp)
				if (!scope)
					if (!sisible (ent, foe.ent, foe.ent.origin))
						thatp = 0;
			if (thatp > bestp) {
				bestp = thatp;
				best = foe;
			}
		}
		foe = [Target forEntity:foe.ent.chain];
	}

	way = [Waypoint find:ent.origin radius:radius];
	while (way) {
		thatp = [self priorityForThing:way];
		if (thatp)
			if (!scope)
				if (!sisible (ent, NIL, way.origin))
					thatp = 0;
		if (thatp > bestp) {
			bestp = thatp;
			best = way;
		}
		way = way.chain;
	}

	if (best == NIL)
		return;
	if (![self targetOnstack:best]) {	
		[self targetAdd:best];
		if (scope) {
			[self getPath:best :FALSE];
			b_aiflags |= AI_WAIT;
		}
	}
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

angleSet

Sets the bots look keys & b_angle to point at
the target - used for fighting and just
generally making the bot look good.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
-(void)angleSet
{
	local float h;
	local vector view;
	
	if (ent.enemy) {
		if (ent.enemy.items & IT_INVISIBILITY)
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
		view = [targets[0] realorigin];
		if (targets[0].ent.flags & FL_ITEM)
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
		keys &= ~KEY_LOOK;
		ent.v_angle = b_angle;
		while (ent.v_angle.x < -180)
			ent.v_angle.x += 360;
		while (ent.v_angle.x > 180)
			ent.v_angle.x -= 360;
	} else if ((ent.enemy == NIL || ent.enemy.movetype == MOVETYPE_PUSH)
			   && (targets[0] ? [targets[0] classname] != "player" : 1)) {
		keys &= ~KEY_LOOK;
		ent.v_angle = b_angle;
		while (ent.v_angle.x < -180)
			ent.v_angle.x += 360;
		while (ent.v_angle.x > 180)
			ent.v_angle.x -= 360;
	} else if (b_skill < 2) {
		// skill 2 handled in bot_phys
		if (b_angle.x > 180)
			b_angle.x -= 360;
		keys &= ~KEY_LOOK;

		if (angcomp (b_angle.y, ent.v_angle.y) > 10)
			keys |= KEY_LOOKLEFT;
		else if (angcomp(b_angle.y, ent.v_angle.y) < -10)
			keys |= KEY_LOOKRIGHT;
		if (angcomp(b_angle.x, ent.v_angle.x) < -10)
			keys |= KEY_LOOKUP;
		else if (angcomp (b_angle.x, ent.v_angle.x) > 10)
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
	// health < 1 is used because fractional healths show up as 0 on normal
	// playerstatus bars, and the mod probably already compensated for that

	if (ent.health < 1) { 
		buttons = (integer) (random() * 2);
		keys = 0;
		b_aiflags = 0;
		[Waypoint clearMyRoute:self];
		targets[0] = targets[1] = targets[2] = targets[3] = NIL;
		ent.enemy = NIL;
		last_way = NIL;
		return;
	}
		
	// stagger the bot's AI out so they all don't think at the same time,
	// causing game 'spikes'
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
		[self startTopic:7];
	stagger_think = time;

	// shut the bot's buttons off, various functions will turn them on by AI
	// end
	buttons = 0;

	// targets[0] is like goalentity in normal Quake monster AI.
	// it's the bot's most immediate target
	if (route_table == self) {
		if (busy_waypoints <= 0) {
			if (waypoint_mode < WM_EDITOR)
				[self lookForCrap:TRUE];
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
			} else if (![self beginRoute]) {	
				[self lookForCrap:FALSE];
			}
			keys = 0;
		} else {
			b_aiflags = AI_WAIT;
			keys = 0;
		}
	}

	// angleSet points the bot at it's goal (ent.enemy or targets[0])
	[self angleSet];

	// fight my enemy. Enemy is probably a field QC coders will most likely
	// use a lot for their own needs, since it's unused on a normal player
	// FIXME
	if (ent.enemy)
		[self fightStyle];
	else if (random () < 0.2)
		if (random () < 0.2)
			[self weaponSwitch:-1];
	[self dodgeStuff];

	// checks to see if bot needs to start going up for air
	if (ent.waterlevel > 2) {
		if (time > (ent.air_finished - 2)) {
			traceline (ent.origin, ent.origin + '0 0 6800', TRUE, ent);
			if (trace_inopen) {
				keys = KEY_MOVEUP;
				buttons |= 4;		// swim!
				return; // skip ai flags for now - this is life or death
			}
		}
	}

	// b_aiflags handling
	// don't want chat to screw him up if he's concentrating
	if (b_aiflags)
		[self handleAI]; 
	else
		[self chat];
}

@end
