/***********************************************
*                                              *
*             FrikBot Waypoints                *
*         "The better than roaming AI"         *
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
#include "List.h"

integer bot_way_linker;

@implementation Bot (Way)

-(void)deleteWaypoint:(Waypoint)what
{
	if (current_way == what)
		current_way = NIL;
	[waypoint_array removeItem:what];
	[what dealloc];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FindRoute & FindThing used by the pathing code
in bot_ai.qc

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


-(entity)findThing:(string)s
{
	local entity t;
	local float tdst, dst;
	local entity best;
	dst = 100000;
	best = NIL;
	t = find (NIL, classname, s);
	while (t != NIL) {
		tdst = vlen(((t.absmin + t.absmax) * 0.5) - ent.origin);
		if (tdst < dst) {
			dst = tdst;
			best = t;
		} 
		t = find(t, classname, s);
	}
	return best;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

FindRoute, this is a key function in the
pathing. The name is a bit misleading, this
code finds the closest waypoint that is part
of a route calculated by the beginRoute and
end_route routines This is a definite path to
an object.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(Waypoint)findRoute:(Waypoint)lastone
{
	// kinda like FindWaypoint, only of this bots route though
	local Waypoint t, best;
	local float dst, tdst;
	local integer flag;
	local integer count, i;

	flag = b_clientflag;
	dst = 100000;
	best = NIL;
	count = [waypoint_array count];
	for (i = 0; i < count; i++) {
		t = [waypoint_array getItemAt:i];
		tdst = vlen(t.origin - ent.origin);
		if ((tdst < dst) &&  (t.b_sound & flag)) {
			if ((lastone == NIL) || ([lastone isLinkedTo:t])) {
				dst = tdst;
				best = t;
			}
		} 
	} 
	return best;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Mark_path

After the route has been found, mark it with
bitflags  so the table can be used for a
different bot.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


-(void)markPath:(Target)this
{
	local Waypoint t;
	local integer flag;

	[Waypoint clearMyRoute:self];

	t = [this findWaypoint:this.current_way];
	// FIXME
	// ugh, better way to find players please!!!
	if ([this classname] != "player")
		this.current_way = t;
		
	if (t.enemy == NIL) {
		[self lost:this :FALSE];
		if (waypoint_mode == WM_DYNAMIC)
			route_failed = TRUE;
		return;
	}

	flag = b_clientflag;

	while(t) {
		if (t.b_sound & flag)
			return;
		if (t == last_way)
			return;
		t.b_sound |= flag;
		t = t.enemy; 	
	}
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

beginRoute and getPath

PLEASE NOTE: getPath replaces the old
calls to beginRoute. 

Routing isn't done all at once now, but in two
stages, the bot will calc a route *THEN*
choose a target, *THEN* mark a path.

Boy it's confusing.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(integer)beginRoute
{
	if (busy_waypoints > 0)
		return FALSE;
	
	if (route_table) {
		if (!route_table.ishuman) {
			if (route_table.b_clientno != -1)
				return FALSE;
		}
	}

	route_table = self;
	[Waypoint clearRouteTable];
	last_way = [self findWaypoint:current_way];

	if (last_way != NIL) {
		last_way.items = vlen(last_way.origin - ent.origin);
		[last_way queueForThink];
		last_way.busy = TRUE;
		busy_waypoints = 1;
		return TRUE;
	} else {
		route_table = NIL;
		busy_waypoints = 0;
		return FALSE;
	}
}

-(void)getPath:(Target)this :(integer)direct
{
	if (this == NIL)
		return;

	if (route_table == self) {
		if (busy_waypoints <= 0) {
			route_table = NIL;
			[self markPath:this];
		}
		return;
	}
	if (direct) {
		if([self beginRoute])
			direct_route = TRUE;
		else
			[self lost:this :FALSE];
		return;
	}
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Temporary Marker code

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)spawnTempWaypoint:(vector)org
{	
	local Waypoint tep;

	if (!temp_way)
		temp_way = tep = [[Waypoint alloc] init];
	else
		tep = temp_way;

	[tep setOrigin:org];
	tep.search_time = 0;
	tep.is_temp = 1;

	[self targetAdd:tep];
}

/*
Dynamic Waypoint spawning and linking. Not
very good all things considered.
*/
-(void)dynamicWaypoint
{
	local Waypoint t;
	local float dist, dynlink = 0, dynpoint = 0, editor = 0;

	if (teleport_time > portal_time) {
		if (!(ent.flags & FL_WATERJUMP)) {
			dyn_flags = 2;
			if (!ishuman) {
				[self lost:targets[0] :TRUE];
				ent.enemy = NIL;
			}
		}
		portal_time = teleport_time;
	}
	// stacking everything on waypoint_mode might've been good for the editor,
	// but it sucks to beat hell for this code.

	// convert waypoint_mode to something more usable..
	if (waypoint_mode > WM_LOADED) {
		if (ishuman) {
			if (waypoint_mode == WM_EDITOR_DYNLINK)
				dynlink = 1;
			else if (waypoint_mode == WM_EDITOR_DYNAMIC)
				dynlink = dynpoint = 1;
			editor = 1;
		}
	} else if (waypoint_mode == WM_DYNAMIC)
		dynlink = dynpoint = 1;

	// if there's nothing for dynamic to do..
	if (!dynpoint) {
		if (!editor)
			return;
	}
	// for speed sake, I won't have bots dynamic waypoint in coop
	if (!ishuman)
		if (coop)
			return;
	// don't waypoint in single player
	//XXX if (max_clients < 2)
	//XXX 	return; 
	// if you're dead
	else if (ent.health <= 0) {
		if (dynpoint) {
			if (current_way) {
				if (pointcontents(ent.origin) < -4) {
					if (current_way.flags & AI_BLIND)
						current_way.flags |= AI_PRECISION;
					else
						current_way.flags |= AI_BLIND;
				}
			}
		}
		dyn_dest = '0 0 0';
		current_way = NIL;
		dyn_flags = 0;
		return;
	}

	// you shouldn't be making waypoints mid air
	if (dynpoint) {
		if (!((ent.flags & FL_ONGROUND) || ent.waterlevel == 3)) {
			if (dyn_flags != 2) {
				dyn_flags = 1;
			}
			return;
		}
	}
	// keep from doing the rest of this every frame
	if (dyn_time > time)
		return;
	dyn_time = time + 0.2;

	// display the links for editor mode
	if (editor) {
		if (current_way) {
			local Waypoint way = current_way;
			local integer i;

			for (i = 0; i < 4; i++) {
				if (way.links[i]) {
					DeveloperLightning (way, way.links[i],
										way.flags & (AI_TELELINK_1 << i));
				}
			}
		}
		if (b_aiflags & AI_HOLD_SELECT)
			return;
	}

	t = [self findWaypoint:current_way];
	if (t) {
		dist = vlen (ent.origin - t.origin);
		if (dist < 192) {
			if (dist < 64) {
				if (t != current_way) {
					if (dynlink) {
						if (!dyn_flags) {
							if ([t canSee:current_way ignoring:ent])
								[t linkWay:current_way];
						}
						if (dyn_flags == 2)
							[current_way teleLinkWay:t];
						else if ([t canSee:current_way ignoring:ent])
							[current_way linkWay:t];
					}
					if (editor) {
						setmodel(t.ent, "progs/s_light.spr");
						if (current_way)
							setmodel(current_way.ent, "progs/s_bubble.spr");
					}
				}
				current_way = t;
				dyn_flags = 0;
			}
			dyn_dest = ent.origin + ent.view_ofs;
			return;
		}
	}

	if ([self recognizePlat:FALSE]) {
		if (vlen(trace_ent.velocity) > 0) {
			if (dyn_plat)
				return;
			dyn_plat = TRUE;
			if (!dyn_flags)
				dyn_flags = 1;
			//bprint("on a plat!!!!!\n");
		} else
			dyn_plat = FALSE;
	} else
		dyn_plat = FALSE;

	if (dyn_flags == 2)
		dyn_dest = ent.origin + ent.view_ofs;
	else if (dyn_dest == '0 0 0')
		dyn_dest = ent.origin + ent.view_ofs;
	if (!dynpoint)
		return;
	t = [[Waypoint alloc] initAt:dyn_dest];

	if (!dyn_flags) {
		if ([t canSee:current_way ignoring:ent])
			[t linkWay:current_way];
	}
	if (dyn_flags == 2)
		[current_way teleLinkWay: t];
	else if ([t canSee:current_way ignoring:ent])
		[current_way linkWay:t];

	if (editor) {
		setmodel(t.ent, "progs/s_light.spr");
		if (current_way)
			setmodel(current_way.ent, "progs/s_bubble.spr");
	}
	current_way = t;
	dyn_flags = 0;
	
	dyn_dest = ent.origin + ent.view_ofs;

	if ([self recognizePlat:FALSE]) {
		if (trace_ent.classname == "door")
			t.flags |= AI_DOORFLAG;
	}
}

-(integer)canSee:(Target)targ
{
	local float		thruwater = 0, pc1 = 0, pc2 = 0;
	local vector	spot1, org;

	org = [targ realorigin];
	spot1 = ent.origin + ent.view_ofs;
	
	if (targ.ent.solid == SOLID_BSP) {
		traceline (spot1, org, TRUE, ent);
		if (trace_ent == targ.ent)
			return TRUE;
		else if (trace_fraction == 1)
			return TRUE;
		return FALSE;
	} else {
		pc1 = pointcontents (org);
		pc2 = pointcontents (spot1);
		if (targ.ent.classname == "player")
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
			traceline (spot1, org + targ.ent.mins, TRUE, ent);
			// cross the water check
			if (trace_inopen)
				if (trace_inwater)
					if (!thruwater)
						return FALSE;
			if (trace_ent == targ.ent)
				return TRUE;
			else if (trace_fraction == 1)
				return TRUE;
			return FALSE;
		}
	} else {
		if (pc2 != pc1) {
			traceline (spot1, org + targ.ent.maxs, TRUE, ent);
			if (trace_inopen)
				if (trace_inwater)
					if (!thruwater)
						return FALSE;
			if (trace_ent == targ.ent)
				return TRUE;
			else if (trace_fraction == 1)
				return TRUE;
			return FALSE;
		}
	}
	traceline (spot1, org, TRUE, ent);
	if (trace_ent == targ.ent)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	traceline (spot1, org + targ.ent.maxs, TRUE, ent);
	if (trace_ent == targ.ent)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	traceline (spot1, org + targ.ent.mins, TRUE, ent);
	if (trace_ent == targ.ent)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	return FALSE;
}
@end
