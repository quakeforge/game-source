#include "common.qh"
#include "server.qh"
#include "delays.qh"

.float delay_health, delay_armorvalue, delay_currentammo;
.float delay_items, delay_effects;

.float delay_ammo_shells, delay_ammo_nails;
.float delay_ammo_rockets, delay_ammo_cells;

.float delay_dmg_take, delay_dmg_save;

.float delay_time, delay_last_change;

#define all_func(func)				\
void() func##_all = {				\
	local entity oldself;			\
	local float i;				\
						\
	oldself = self;				\
						\
	self = world;				\
	for (i = 0; i < max_clients; i++) {	\
		self = nextent(self);		\
						\
		if (!is_cl(self))		\
			continue;		\
						\
		func();				\
	}					\
						\
	self = oldself;				\
}



#define do_fields()		\
	do_(health);		\
	do_(armorvalue);	\
	do_(currentammo);	\
	do_(items);		\
	do_(effects);		\
	do_(ammo_shells);	\
	do_(ammo_nails);	\
	do_(ammo_rockets);	\
	do_(ammo_cells)

void() delays_swapin_stats = {
	local float tmp;

#define do_(field)				\
	tmp = self.field;			\
	self.field = self.delay_##field;	\
	self.delay_##field = tmp

	do_fields();
#undef do_
};

all_func(delays_swapin_stats);

// ===================================================================== //

float() delays_changed = {
#define do_(field)						\
	if (floor(self.field) != floor(self.delay_##field))	\
		return TRUE
	do_fields();
#undef do_

	return FALSE;
};

// ===================================================================== //

void() delays_force_update = {
	self.delay_time = 0;
};


all_func(delays_force_update);

// ===================================================================== //

void() delays_swapout_stats = {
	if (delays_changed())
		self.delay_last_change = time;

	self.delay_dmg_take += self.dmg_take; self.dmg_take = 0;
	self.delay_dmg_save += self.dmg_save; self.dmg_save = 0;
	
	if (time < self.delay_time) {
		delays_swapin_stats();
		return;
	}

#define do_(field)	self.delay_##field = self.field
	do_fields();
#undef do_

	self.dmg_take = ceil(self.delay_dmg_take); self.delay_dmg_take = 0;
	if (self.dmg_take > 255) self.dmg_take = 255;

	self.dmg_save = ceil(self.delay_dmg_save); self.delay_dmg_save = 0;
	if (self.dmg_save > 255) self.dmg_save = 255;

	if ((self.delay_last_change - time) >= -CONFIG_STATS_DELAY)
		self.delay_time = time + CONFIG_STATS_DELAY;
};

all_func(delays_swapout_stats);
