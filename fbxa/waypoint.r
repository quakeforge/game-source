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

@static void () waypoint_init =
{
	waypoint_array = [[Array alloc] init];
	if (!waypoint_queue)
		waypoint_queue = [[List alloc] init];
	if (!waypoint_thinker) {
		waypoint_thinker = spawn ();
		waypoint_thinker.classname = "waypoint_thinker";
	}
};

@implementation Waypoint

-(id)init
{
	if (!waypoint_array)
		waypoint_init ();
	return [super init];
}

-(id)initAt:(vector)org
{
	[self init];
	[waypoint_array addItem: self];
	origin = org;
	search_time = time;
	items = -1;
	if ([waypoint_array count] == 1) {
		local id obj = [Waypoint class];
		local IMP imp = [obj methodForSelector: @selector (fixWaypoints)];
		waypoint_thinker.think = (void ()) imp;
		waypoint_thinker.nextthink = time;
	}
	return self;
}

-(id)initFromEntity:(entity)ent
{
	[self initAt:ent.origin];
	//FIXME do entity based init
}

-(void)setOrigin:(vector)org
{
	origin = org;
}

-(vector)origin
{
	return origin;
}

-(vector)realorigin
{
	return origin;
}

-(integer)isLinkedTo:(Waypoint)way
{
	local integer i;

	if (way == self || !way || !self)
		return 0;

	for (i = 0; i < 4; i++) {
		if (links[i] == way) {
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
		if (!links[i]) {
			links[i] = way;
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
		if (!links[i]) {
			links[i] = way;
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
		if (links[i] == way) {
			flags &= ~(AI_TELELINK_1 << i);
			links[i] = NIL;
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
	waypoint_init ();
}

+(Waypoint)waypointForNum:(integer)num
{
	if (!num)
		return NIL;
	return [waypoint_array getItemAt:num - 1];
}

-(void)fix
{
	local integer i, tmp;

	for (i = 0; i < 4; i++) {
		tmp = (integer)links[i];
		links[i] = [Waypoint waypointForNum:tmp];
	}
}

+(void) fixWaypoints
{
	[waypoint_array makeObjectsPerformSelector:@selector(fix)];
}

+(Waypoint)find:(vector)org radius:(float)rad
{
	local vector dif;
	local float dist;
	local integer i, count;
	local Waypoint way = NIL, w;

	rad = rad * rad;			// radius squared

	count = [waypoint_array count];
	for (i = 0; i < count; i++) {
		w = [waypoint_array getItemAt:i];
		dif = w.origin - org;
		dist = dif * dif;		// dist squared, really
		if (dist < rad) {
			w.chain = way;
			way = w;
		}
	}
	return way;
}

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Route & path table management

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

-(void)clearRoute
{
	busy = FALSE;
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
	[waypoint_array makeObjectsPerformSelector:@selector (clearRouteForBot)
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
		if (!e2.busy)
			busy_waypoints = busy_waypoints + 1;
		e2.busy = TRUE;
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
			if (links[i]) {
				traceline (origin, links[i].origin, TRUE, /*self*/NIL);
				if (trace_fraction == 1)
					[self followLink:links[i] :AI_TELELINK_1 << i];
			}
		}
 	} else {
		for (i = 0; i < 4; i++) {
			if (links[i]) {
				[self followLink:links[i] :AI_TELELINK_1 << i];
			}
		}
	}

	busy_waypoints--;
	busy = FALSE;

	if (busy_waypoints <= 0) {
		if (direct_route) {
			[route_table getPath:route_table.targets[0] :FALSE];
			direct_route = FALSE;
		}
	}
	if (waypoint_thinker.@this = [waypoint_queue removeItemAtHead]) {
		local id obj = waypoint_thinker.@this;
		local IMP imp = [obj methodForSelector: @selector (waypointThink)];
		waypoint_thinker.think = (void ()) imp;
		waypoint_thinker.nextthink = time;
	}
}

-(id)queueForThink
{
	if (waypoint_thinker.@this) {
		[waypoint_queue addItemAtTail: self];
	} else {
		local IMP imp = [self methodForSelector: @selector (waypointThink)];
		waypoint_thinker.think = (void ()) imp;
		waypoint_thinker.nextthink = time;
		waypoint_thinker.@this = self;
	}
	return self;
}

-(integer)priority:(Bot)bot
{
		if (flags & AI_SNIPER)
			return 30;
		else if (flags & AI_AMBUSH)
			return 30;
		return 0;
}

-(float)searchTime
{
	return search_time;
}

-(void)setSearchTime:(float)st
{
	search_time = st;
}

-(string)classname
{
	return is_temp ? "temp_waypoint" : "waypoint";
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
};

void(vector org, vector bit1, integer bit4, integer flargs) make_way =
{
	local Waypoint y = [[Waypoint alloc] initAt:org];
	waypoint_mode = WM_LOADED;
	y.flags = flargs;
	y.links[0] = (Waypoint) (integer) bit1_x;
	y.links[1] = (Waypoint) (integer) bit1_y;
	y.links[2] = (Waypoint) (integer) bit1_z;
	y.links[3] = (Waypoint) (integer) bit4;
};
