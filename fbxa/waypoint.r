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

Array waypoint_array;
@static entity waypoint_thinker;
@static List waypoint_queue;

@implementation Waypoint

-(id)init
{
	if (!waypoint_array) {
		waypoint_array = [[Array alloc] init];
		waypoint_queue = [[List alloc] init];
		waypoint_thinker = spawn ();
		waypoint_thinker.classname = "waypoint_thinker";
	}
/*XXX
	ent.classname = "temp_waypoint";
	ent.solid = SOLID_TRIGGER;
	ent.movetype = MOVETYPE_NOCLIP;
	setsize(ent, VEC_HULL_MIN, VEC_HULL_MAX); // FIXME: convert these to numerical
*/
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

-(void)setOrigin:(vector)org
{
	origin = org;
}

-(vector)origin
{
	return origin;
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
	if (waypoint_array)
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
	flag = bot.b_clientflag;
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

-(void)followLink:(Waypoint)e2 :(integer)bBit
{
	local float dist;
	
	if (flags & bBit)
		dist = items;
	else
		dist = vlen(origin - e2.origin) + items;

	// check if this is an RJ link
	if (e2.flags & AI_SUPER_JUMP) {
		if (![route_table canRJ])
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
		e2.enemy = self;
		[e2 queueForThink];
	}
}

-(void)waypointThink
{
	local integer i;

	if (items == -1)
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
			[route_table getPath:route_table.targets[0] :FALSE];
			direct_route = FALSE;
		}
	}
	if (waypoint_thinker.@this = [waypoint_queue removeItemAtHead]) {
		local id obj = waypoint_thinker.@this;
		local IMP imp = [obj methodForSelector: @selector (waypointThink)];
		(IMP)waypoint_thinker.think = imp;
		waypoint_thinker.nextthink = time;
	}
}

-(id)queueForThink
{
	if (waypoint_thinker.@this) {
		[waypoint_queue addItemAtTail: self];
	} else {
		local IMP imp = [self methodForSelector: @selector (waypointThink)];
		(IMP)waypoint_thinker.think = imp;
		waypoint_thinker.nextthink = time;
		waypoint_thinker.@this = self;
	}
	return self;
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
	search_time = time;
	solid = SOLID_TRIGGER;
	movetype = MOVETYPE_NONE;
	setorigin(self, origin);
	
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	waypoints = waypoints + 1;
	if (!way_head) {
		way_head = self;
		way_foot = self;
	} else {
		way_foot._next = self;
		_last = way_foot;
		way_foot = self;
	}

	count = waypoints;
	waypoint_mode = WM_LOADED;
	if (count == 1) {
		think = FixWaypoints; // wait until all bsp loaded points are spawned
		nextthink = time;
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
