#include "common.qh"

#include "mapents_util.qh"
#include "misc.qh"

#include "items.qh"

.float() th_takeitem;

void() _item_regen_think = {
	self.solid = SOLID_TRIGGER;
	setmodel(self, self.model);
	sound(self, CHAN_VOICE, self.noise7, 1, ATTN_NORM);
};

void() item_remove_regen = {
	local float del;

	self.solid = SOLID_NOT;
	self.modelindex = 0;
	
	del = self.wait + random()*self.delay;
	if (del <= 0) {
		safe_remove(self);
		return;
	}

	self.think = _item_regen_think;
	self.nextthink = time + del;
};

void() item_generic_touch = {
	if (!other.th_takeitem)
		return;

	if (!util_check_targets()) return;

	if (!switcheroo(other, self, other.th_takeitem))
		return;

	util_use_targets();

	item_remove_regen();
};

void() item_generic = {
	if (!self.noise7)
		self.noise7 = "items/itembk2.wav";

	if (sv_spawning)
		precache_sound(self.noise7);

	self.solid = SOLID_TRIGGER;
	self.touch = item_generic_touch;

	util_map_entity_init();

	self.flags |= FL_ITEM;

	if (!self.wait && !self.delay) {
		self.wait = 20;
		self.delay = 5;
	}

	if (sv_spawning) {
		self.think = util_map_entity_drop;
		self.nextthink = time + 0.2; // Let everything else drop to floor.
	}
};
