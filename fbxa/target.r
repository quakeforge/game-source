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
#include "hash.h"
#include "List.h"

@static hashtab_t target_tab;

struct target_s {
	@defs (Target)
};

@static unsigned (void []ele, void []unused) target_get_hash =
{
	local Target t = ele;
	return ((unsigned[])&t.ent)[0];
};

@static integer (void []e1, void[]e2, void []unused) target_compare =
{
	local Target t1 = e1;
	local Target t2 = e2;
	return t1.ent == t2.ent;
};

@implementation Target

+(Target)forEntity:(entity)e
{
	local Target t;
	local struct target_s ele;

	if (!e)
		return NIL;

	if (e.classname == "player")
		return e.@this;

	if (!target_tab) {
		target_tab = Hash_NewTable (1021, NIL, NIL, NIL);
		Hash_SetHashCompare (target_tab, target_get_hash, target_compare);
	}
	ele.ent = e;
	t = Hash_FindElement (target_tab, &ele);
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

-(integer)canSee:(Target)targ ignoring:(entity)ignore
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

- (integer) recognizePlat: (integer) flag
{
	local vector org = [self origin];
	traceline (org, org - '0 0 64', TRUE, ent);
	if (trace_ent != NIL)
		return TRUE;
	else
		return FALSE;
}

-(integer)ishuman
{
	return 0;
}

-(integer)priority:(Bot)bot
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
	local integer ishuman = [self ishuman];

	org = [self realorigin];

	if (start) {
		dst = vlen ([start origin] - org);
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
				if (sisible (ent, NIL, t.origin)) {
					dst = tdst;
					best = t;
				}
			}
		}
	} 
	return best;
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
