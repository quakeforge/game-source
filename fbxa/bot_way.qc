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

@static Array waypoint_array;

@implementation Target

-(vector)realorigin
{
	return realorigin (ent);
}

-(integer)canSee:(Target)targ ignoring:(entity)ignore
{
	local vector	spot1, spot2;

	spot1 = ent.origin;
	spot2 = [targ realorigin];
	
	do {
		traceline (spot1, spot2, TRUE, ignore);
		spot1 = realorigin(trace_ent);
                ignore = trace_ent;
	} while ((trace_ent != world) && (trace_fraction != 1));
	if (trace_endpos == spot2)
		return TRUE;
	else 
		return FALSE;
}
@end

// Waypoint Linking code ======================================================

@implementation Waypoint

-(id)init
{
	if (!waypoint_array)
		waypoint_array = [[Array alloc] init];
	return [super init];
}

-(id)initAt:(vector)org
{
	[self init];
	[waypoint_array addItem: self];
	return self;
}

-(id)initFromEntity:(entity)ent
{
	[self initAt:ent.origin];
}
/*
entity (vector org)
make_waypoint = 
{
	local entity point;

	point = spawn ();
	point.classname = "waypoint";

	point.search_time = time; // don't double back for me;
	point.solid = SOLID_TRIGGER;
	point.movetype = MOVETYPE_NONE;
	point.items = -1;
	setorigin (point, org);
	
	setsize (point, VEC_HULL_MIN, VEC_HULL_MAX);
	waypoints++;
	if (!way_head) {
		way_head = point;
		way_foot = point;
	} else {
		way_foot._next = point;
		point._last = way_foot;
		way_foot = point;
	}

	point.count = waypoints;
	if (waypoint_mode > WM_LOADED) // editor modes
		setmodel (point, "progs/s_bubble.spr"); 
	return point;
};
*/

-(integer)isLinkedTo:(Waypoint)way
{
	local integer i;

	if (way == self || !way || !self)
		return 0;

	for (i = 0; i < 4; i++) {
		if (targets[i] == way) {
			if (flags & (AI_TELELINK_1 << i))
				return 2;
			return 1;
		}
	}
	return 0;
}

-(integer)linkWay:(Waypoint)way
{
	local integer i;

	if (self == way || !self || !way)
		return 0;
	else if ([self isLinkedTo:way])
		return 0; // already linked!!!

	for (i = 0; i < 4; i++) {
		if (!targets[i]) {
			targets[i] = way;
			return 1;
		}
	}
	return 0;
}

// Link Ways part 2, used only for teleporters
-(integer)teleLinkWay:(Waypoint)way
{
	local integer i;

	if (self == way || !self || !way)
		return 0;
	else if ([self isLinkedTo:way])
		return 0; // already linked!!!

	for (i = 0; i < 4; i++) {
		if (!targets[i]) {
			targets[i] = way;
			flags |= AI_TELELINK_1 << i;
			return 1;
		}
	}
	return 0;
}

-(void)unlinkWay:(Waypoint)way
{
	local integer i;

	if (self == way || !self || !way)
		return;
	else if (![self isLinkedTo:way])
		return;

	for (i = 0; i < 4; i++) {
		if (targets[i] == way) {
			flags &= ~(AI_TELELINK_1 << i);
			targets[i] = NIL;
		}
	}
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Waypoint Loading from file

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

+(void)clearAll
{
	[waypoint_array free];
	waypoint_array = [[Array alloc] init];
}

+(Waypoint)waypointForNum:(integer)num
{
	return [waypoint_array getItemAt:num];
}

-(void)fix
{
	targets[0] = [Waypoint waypointForNum:b_pants];
	targets[1] = [Waypoint waypointForNum:b_skill];
	targets[2] = [Waypoint waypointForNum:b_shirt];
	targets[3] = [Waypoint waypointForNum:b_frags];
}

+(void) fixWaypoints
{
	[waypoint_array makeObjectsPerformSelector:@selector(fix)];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Route & path table management

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)clearRoute
{
	keys = FALSE;
	enemy = NIL;
	items = -1; // not in table
}

+(void)clearRouteTable
{
	// cleans up route table
	[waypoint_array makeObjectsPerformSelector:@selector (clearRoute)];
}

-(void)clearRouteForBot:(Bot)bot
{
	local integer flag;
	flag = ClientBitFlag(bot.b_clientno);
	b_sound &= ~flag;
}

+(void)clearMyRoute:(Bot) bot
{
	[waypoint_array makeObjectsPerformSelector:@selector (clearRoute)
					withObject:bot];
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

WaypointThink

Calculates the routes. We use thinks to avoid
tripping the runaway loop counter

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)followLink:(Waypoint)e2 :(integer)b_bit
{
	local float dist;
	
	if (flags & b_bit)
		dist = items;
	else
		dist = vlen(self.origin - e2.origin) + self.items;

	// check if this is an RJ link
	if (e2.flags & AI_SUPER_JUMP) {
		if (![route_table can_rj])
			return;
	}
	if (e2.flags & AI_DIFFICULT)
		dist = dist + 1000;

	dist = dist + random() * 100; // add a little chaos

	if ((dist < e2.items) || (e2.items == -1)) {
		if (!e2.keys)
			busy_waypoints = busy_waypoints + 1;
		e2.keys = TRUE;
		e2.items = dist;
		(IMP)e2.ent.think = [self methodFor: @selector (waypointThink)];
		e2.ent.nextthink = time;
		e2.enemy = self;
	}
}

-(void)waypointThink
{
	local integer i;

	if (self.items == -1)
		return;
	// can you say ugly?
	if (flags & AI_TRACE_TEST) {
		for (i = 0; i < 4; i++) {
			if (targets[i]) {
				traceline (origin, targets[i].origin, TRUE, /*self*/NIL);
				if (trace_fraction == 1)
					[self followLink:targets[i].origin :AI_TELELINK_1 << i];
			}
		}
 	} else {
		for (i = 0; i < 4; i++) {
			if (targets[i]) {
				[self followLink:targets[i].origin :AI_TELELINK_1 << i];
			}
		}
	}

	busy_waypoints--;
	keys = FALSE;

	if (busy_waypoints <= 0) {
		if (direct_route) {
			[route_table get_path:route_table.targets[0] :FALSE];
			direct_route = FALSE;
		}
	}
}

@end


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BSP/QC Waypoint loading

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() waypoint =
{	
	local Waypoint way = [[Waypoint alloc] initFromEntity: @self];
/*
	self.search_time = time;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	setorigin(self, self.origin);
	
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	waypoints = waypoints + 1;
	if (!way_head) {
		way_head = self;
		way_foot = self;
	} else {
		way_foot._next = self;
		self._last = way_foot;
		way_foot = self;
	}

	self.count = waypoints;
	waypoint_mode = WM_LOADED;
	if (self.count == 1) {
		self.think = FixWaypoints; // wait until all bsp loaded points are spawned
		self.nextthink = time;
	}
*/
};

void(vector org, vector bit1, integer bit4, integer flargs) make_way =
{
	local Waypoint y = [[Waypoint alloc] initAt:org];
	//local entity y;
	//waypoint_mode = WM_LOADED;
	//y = make_waypoint(org);
	y.flags = flargs;
	y.b_pants = (integer)bit1_x;
	y.b_skill = (integer)bit1_y;
	y.b_shirt = (integer)bit1_z;
	y.b_frags = bit4;
	/*
	if (y.count == 1) {
		y.think = FixWaypoints; // wait until all qc loaded points are spawned
		y.nextthink = time;
	}
	*/
};

@implementation Bot (Way)

/*
FindWaypoint

This is used quite a bit, by many different
functions big lag causer

Finds the closest, fisible, waypoint to e
*/
-(Waypoint)findWaypoint:(Waypoint)start
{
	local Waypoint best, t;
	local float dst, tdst;
	local vector org;
	local integer count, i;

	org = realorigin (ent);

	if (start) {
		dst = vlen (start.origin - org);
		best = start;
	} else {
		dst = 100000;
		best = NIL;
	}
	count = [waypoint_array count];
	for (i = 0; i < count; i++) {
		t = [waypoint_array getItemAt:i];
		// real players cut through ignore types
		if (dst < 20)
			return best;
		if (!(t.flags & AI_IGNORE_TYPES) || ishuman) {
			tdst = vlen (t.origin - org);
			if (tdst < dst) {
				if (sisible (ent, t.ent)) {
					dst = tdst;
					best = t;
				}
			}
		}
	} 
	return best;
}

-(void)deleteWaypoint:(Waypoint)what
{
	if (self.current_way == what)
		self.current_way = NIL;
	[waypoint_array removeItem:what];
	[what free];
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
of a route calculated by the begin_route and
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

	flag = ClientBitFlag(b_clientno);
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


-(void)mark_path:(entity)this
{
	local Waypoint t;
	local integer flag;
	local Bot bot = (Bot)this.@this;

	[Waypoint clearMyRoute:self];

	t = [this.@this findWaypoint:bot.current_way];
	// FIXME
	// ugh, better way to find players please!!!
	if (this.classname != "player")
		bot.current_way = t;
		
	if (t.enemy == NIL) {
		[self lost:this :FALSE];
		if (waypoint_mode == WM_DYNAMIC)
			route_failed = TRUE;
		return;
	}

	flag = ClientBitFlag(b_clientno);

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

begin_route and bot_get_path

PLEASE NOTE: bot_get_path replaces the old
calls to begin_route. 

Routing isn't done all at once now, but in two
stages, the bot will calc a route *THEN*
choose a target, *THEN* mark a path.

Boy it's confusing.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(integer)begin_route
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
		last_way.items = vlen(self.last_way.origin - ent.origin);
		last_way.ent.nextthink = time;
		(IMP)last_way.ent.think = [self methodFor: @selector(waypointThink)];
		last_way.keys = TRUE;
		busy_waypoints = 1;
		return TRUE;
	} else {
		route_table = NIL;
		busy_waypoints = 0;
		return FALSE;
	}
}

-(void)get_path:(Waypoint)this :(integer)direct
{
	if (this == NIL)
		return;

	if (route_table == self) {
		if (busy_waypoints <= 0) {
			route_table = NIL;
			[self mark_path:this];
		}
		return;
	}
	if (direct) {
		if([self begin_route])
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
/*XXX
	local entity tep;

	if (!self.temp_way)
		self.temp_way = tep = spawn();
	else
		tep = self.temp_way;

	tep.classname = "temp_waypoint";
	tep.search_time = 0;
	tep.solid = SOLID_TRIGGER;
	tep.movetype = MOVETYPE_NOCLIP;
	setorigin(tep, org);
	target_add(tep);
	setsize(tep, VEC_HULL_MIN, VEC_HULL_MAX); // FIXME: convert these to numerical
*/
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
		if (self.ishuman) {
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
	if (!self.ishuman)
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
					if (self.current_way.flags & AI_BLIND)
						self.current_way.flags |= AI_PRECISION;
					else
						self.current_way.flags |= AI_BLIND;
				}
			}
		}
		self.dyn_dest = '0 0 0';
		self.current_way = NIL;
		self.dyn_flags = 0;
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
	if (self.dyn_time > time)
		return;
	self.dyn_time = time + 0.2;

	// display the links for editor mode
	if (editor) {
		if (self.current_way) {
			local Waypoint way = self.current_way;
			local integer i;

			for (i = 0; i < 4; i++) {
				if (way.targets[i]) {
					DeveloperLightning (way, way.targets[i],
										way.flags & (AI_TELELINK_1 << i));
				}
			}
		}
		if (self.b_aiflags & AI_HOLD_SELECT)
			return;
	}

	t = [self findWaypoint:current_way];
	if (t) {
		dist = vlen (ent.origin - t.origin);
		if (dist < 192) {
			if (dist < 64) {
				if (t != self.current_way) {
					if (dynlink) {
						if (!self.dyn_flags) {
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
				self.current_way = t;
				self.dyn_flags = 0;
			}
			dyn_dest = ent.origin + ent.view_ofs;
			return;
		}
	}

	if ([self recognize_plat:FALSE]) {
		if (vlen(trace_ent.velocity) > 0) {
			if (self.dyn_plat)
				return;
			self.dyn_plat = TRUE;
			if (!self.dyn_flags)
				self.dyn_flags = 1;
			//bprint("on a plat!!!!!\n");
		} else
			self.dyn_plat = FALSE;
	} else
		dyn_plat = FALSE;

	if (dyn_flags == 2)
		dyn_dest = ent.origin + ent.view_ofs;
	else if (self.dyn_dest == '0 0 0')
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

	if ([self recognize_plat:FALSE]) {
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
