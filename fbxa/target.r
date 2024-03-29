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

#include <Array.h>
#include <hash.h>

#include "libfrikbot.h"
#include "waypoint.h"

@static hashtab_t *target_tab;

typedef struct target_s {
	@defs (Target)
} target_t;

@static unsigned target_get_hash (void *ele, void *unused)
{
	local Target *t1 = (Target *) ele;
	return *(unsigned*)(&t1.ent);
};

@static int target_compare (void *e1, void*e2, void *unused)
{
	local Target *t1 = (Target *) e1;
	local Target *t2 = (Target *) e2;
	return t1.ent == t2.ent;
};

@implementation Target

+(void)initialize
{
	target_tab = Hash_NewTable (1021, nil, nil, nil);
	Hash_SetHashCompare (target_tab, target_get_hash, target_compare);
}

+(Target *)forEntity:(entity)e
{
	local Target *t;
	static target_t ele;//FIXME want local, but...

	if (!e)
		return nil;

	if (e.classname == "player")
		return e.@this;

	ele.ent = e;
	t = (Target *) Hash_FindElement (target_tab, &ele);
	if (t)
		return t;

	t = [[Target alloc] initWithEntity:e];
	Hash_AddElement (target_tab, t);
	return t;
}

-(vector)realorigin
{
	return realorigin (ent);
}

-(vector)origin
{
	return ent.origin;
}

-(int)canSee:(Target *)targ ignoring:(entity)ignore
{
	local vector	spot1, spot2;

	spot1 = [self origin];
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

-(void)setOrigin:(vector)org
{
}

- (int) recognizePlat: (int) flag
{
	local vector org = [self origin];
	traceline (org, org - '0 0 64', TRUE, ent);
	if (trace_ent != nil)
		return TRUE;
	else
		return FALSE;
}

-(int)ishuman
{
	return 0;
}

-(int)priority:(Bot *)bot
{
	if ((ent.flags & FL_ITEM) && ent.model && ent.search_time < time) {
		// ugly hack
		if (_last != bot)
			return 20;
		switch (ent.classname) {
			case "item_artifact_super_damage":
				return 65;
			case "item_artifact_invulnerability":
				return 65;
			case "item_health":
				if (ent.spawnflags & 2)
					return 55;
				if (bot.ent.health < 40)
					return 55 + 50;
				break;
			case "progs/armor.mdl":
				if (bot.ent.armorvalue < 200) {		
					if (ent.skin == 2)
						return 60;
					else if (bot.ent.armorvalue < 100)			
						return 60 + 25;
				}
				break;
			case "weapon_supershotgun":
				if (!(bot.ent.items & IT_SUPER_SHOTGUN))
					return 25;
				break;
			case "weapon_nailgun":
				if (!(bot.ent.items & IT_NAILGUN))
					return 30;
				break;
			case "weapon_supernailgun":
				if (!(bot.ent.items & IT_SUPER_NAILGUN))
					return 35;
				break;
			case "weapon_grenadelauncher":
				if (!(bot.ent.items & IT_GRENADE_LAUNCHER))
					return 45;
				break;
			case "weapon_rocketlauncher":
				if (!(bot.ent.items & IT_ROCKET_LAUNCHER))
					return 60;
				break;
			case "weapon_lightning":
				if (!(bot.ent.items & IT_LIGHTNING))
					return 50;
				break;
		}
	} else if ((ent.flags & FL_MONSTER) && ent.health > 0)
		return 45;
	return 0;
}

static int
waypoint_visible (Waypoint *way, void *data)
{
	Bot        *bot = (Bot *) data;

	// real players cut through ignore types
	if (bot.ishuman || !(way.flags & AI_IGNORE_TYPES)) {
		traceline (bot.ent.origin, way.origin, TRUE, bot.ent);
		if (trace_fraction == 1) {
			return 1;
		}
	}
	return 0;
}
/*
FindWaypoint

This is used quite a bit, by many different
functions big lag causer

Finds the closest, fisible, waypoint to e
*/
-(Waypoint *)findWaypoint:(Waypoint *)start
{
	local Waypoint *best, *t;
	local float dst, tdst;
	local vector org;
	local int count, i;
	local int ishuman = [self ishuman];

	org = [self realorigin];

	if (start) {
		dst = vlen ([start origin] - org);
		best = start;
	} else {
		dst = 100000;
		best = nil;
	}
	return [Waypoint nearest:ent.origin start:start
						test:waypoint_visible data:self];
}

-(float)searchTime
{
	return ent.search_time;
}

-(void)setSearchTime:(float)st
{
	ent.search_time = st;
}

-(string)classname
{
	return ent.classname;
}

@end
