#include "common.qh"

#include "mapents_util.qh"
#include "items.qh"

#include "mapents_items.qh"

#define SPAWNFLAGS_HEALTH_ROTTEN	1
#define SPAWNFLAGS_HEALTH_MEGA		2

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) ROTTEN MEGA
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/
@extern void() item_megahealth;

void() item_health = {
	if (self.spawnflags & SPAWNFLAGS_HEALTH_ROTTEN) {
		self.model = "maps/b_bh10.bsp";
		self.noise2 = "items/r_item1.wav";
		self.health = 15;
	} else if (self.spawnflags & SPAWNFLAGS_HEALTH_MEGA) {
		item_megahealth();
		return;
	} else {
		if (!self.model) self.model = "maps/b_bh25.bsp";
		if (!self.noise2) self.noise2 = "items/health1.wav";
		if (!self.health) self.health = 25;
	}
	
	if (self.mins == '0 0 0' && self.maxs == '0 0 0')
		setsize(self, '0 0 0', '32 32 56');
	
	item_generic();
};

/*QUAKED item_armor (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() item_armor = {
	if (!self.model) self.model = "progs/armor.mdl";
	if (!self.noise2) self.noise2 = "items/armor1.wav";
	if (self.mins == '0 0 0' && self.maxs == '0 0 0')
		setsize(self, '-16 -16 0', '16 16 56');
	item_generic();
};

// ========================================================================

/*QUAKED item_ammo (0 .5 .8) (0 0 0) (32 32 32)
*/
void() item_ammo = {
	if (!self.model) self.model = "progs/backpack.mdl";
	if (!self.noise2) self.noise2 = "weapons/lock4.wav";
	if (self.mins == '0 0 0' && self.maxs == '0 0 0')
		setsize(self, '0 0 0', '32 32 56');
	if (!self.wait && !self.delay) {
		self.wait = 25;
		self.delay = 10;
	}
	item_generic();
};

