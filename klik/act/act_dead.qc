
#include "common.qh"
#include "client.qh"

#include "weapon.qh"
#include "damage.qh"

#include "act.qh"
#include "act_dead.qh"

#include "override.qh"

#define STOP_EPSILON	0.1

void() dead_prethink = {
	if (vlen(self.movedir) > vlen(self.velocity)) {
		self.velocity = '0 0 0';
	} else {
		/* FIXME: Use e, decay per frame. */
		if (time >= self.pain_finished) {
			self.velocity *= 0.9;
			self.pain_finished = time + 0.1;
		}

		if (self.velocity_x > -STOP_EPSILON && self.velocity_x < STOP_EPSILON)
			self.velocity_x = 0;
		if (self.velocity_y > -STOP_EPSILON && self.velocity_y < STOP_EPSILON)
			self.velocity_y = 0;
		if (self.velocity_z > -STOP_EPSILON && self.velocity_z < STOP_EPSILON)
			self.velocity_z = 0;
	}

	if (time >= self.air_finished) {
		if (self.button0 || self.button2 || self.impulse) {
			self.button0 = self.button1 = self.button2 = 0;
			self.impulse = 0;

			PutClientInGame();
			return;
		}
	}

	self.movedir = self.velocity;
};

void() dead_postthink = {
	local vector vieworg;

	self.dmg_take = 0;
	self.dmg_save = 0;

	vieworg = vieworigin(self);

	if (pointcontents(vieworg + self.velocity*sv_maxtic) != pointcontents(vieworg)) {
		self.movetype = MOVETYPE_NONE;
		self.velocity = '0 0 0';
		setorigin(self, self.origin);
	}
};

float() dead_takeitem = { return FALSE; };
float(float d) dead_takedamage = { return FALSE; };

void() act_setup_dead = {
	act_setup();

	weapon_select_by_impulse(0);

	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.movetype = MOVETYPE_NOCLIP;

	self.deadflag = DEAD_NONLIVING;

	self.impulse = 0;
	self.button0 = self.button1 = self.button2 = 0;
	self.flags &= ~FL_JUMPRELEASED;

	/* Dead people don't have stuff. */
	self.items = 0;
	self.effects = 0;

	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
	self.currentammo = 0;

	self.itemfield_1 = 0;
	self.itemfield_2 = 0;
	self.itemfield_3 = 0;
	self.itemfield_4 = 0;

	/* May need to change these if clients don't act the same. */
	self.armorvalue = 0;
	self.health = 0.001; // Avoid stupid death roll.

	self.gravity = 0;
	self.maxspeed = 0;
	self.mass = 0;

	self.movedir = self.velocity;
	self.movedir_z -= sv_gravity * sv_maxtic;	/* Gravity hack. */
	self.pain_finished = time + 0.1;
	self.air_finished = time + 2;

	override_set_th_takeitem(self, dead_takeitem);
	override_set_th_takedamage(self, dead_takedamage);

	override_set_prethink(self, dead_prethink);
	override_set_actthink(self, NOTHING_function);
	override_set_postthink(self, dead_postthink);

	dead_postthink();	/* make sure we don't noclip when near walls */
};
