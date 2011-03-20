#include "common.qh"

#include "mapents_util.qh"
#include "damage.qh"
#include "effect.qh"
#include "misc.qh"

#define SPAWNFLAG_SUPERSPIKE	1
#define SPAWNFLAG_LASER		2

void() _trap_genericshooter_deathmsg = {
	bprint(PRINT_DEATH, name(self), " trips a trap.\n");
};

void() _trap_genericshooter_touch = {
	if (!damage(other, self.owner, self, self.dmg, _trap_genericshooter_deathmsg)) {
		if (self.noise2) sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM);
		effect_nail_spark(self.origin, self.velocity);
	}
	safe_remove(self);
};

void() _trap_genericshooter_use = {
	local entity missile;

	if (self.noise1) sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	missile = spawn_missile("TRAP_MISSILE", self.weaponmodel, self.origin, self.movedir, self.speed);

	missile.dmg_inflictor = world;

	missile.effects |= self.items;

	missile.dmg = self.dmg;
	deathmsg_copy(self, missile);

	missile.noise2 = self.noise2;
	
	missile.touch = _trap_genericshooter_touch;

	missile.think = SUB_remove;
	missile.nextthink = time + (6000 / self.speed);
};

void() _trap_genericshooter_think = {
	self.use();
	self.nextthink = time + self.wait;
};

/*QUAKED trap_genericshooter (0 .5 .8) (-8 -8 -8) (8 8 8)
weaponmodel, speed, dmg, items, noise1, noise2
*/
void() trap_genericshooter = {
	util_map_entity_init();

	if (!self.weaponmodel) {
		objerror("trap_genericshooter without weaponmodel\n");
		safe_remove(self);
	}

	precache_model(self.weaponmodel);
	if (self.noise1) precache_sound(self.noise1);
	if (self.noise2) precache_sound(self.noise2);

	makevectors(self.angles);
	self.movedir = v_forward;

	if (self.delay) {
		self.think = _trap_genericshooter_think;
		self.nextthink = time + self.delay;
		if (!self.wait)
			self.wait = self.delay;
	}

	self.use = _trap_genericshooter_use;
};

/*QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
When triggered, fires a spike in the direction set in QuakeEd.
Laser is only for REGISTERED.
*/
void() trap_spikeshooter = {
	if (self.spawnflags & SPAWNFLAG_LASER) {
		self.weaponmodel = "progs/laser.mdl";
		self.noise1 = "enforcer/enfire.wav";
		self.noise2 = "enforcer/enfstop.wav";
		self.speed = 600;
		self.dmg = 15;
		self.items = EF_DIMLIGHT;
	} else if (self.spawnflags & SPAWNFLAG_SUPERSPIKE) {
		self.weaponmodel = "progs/s_spike.mdl";
		self.noise1 = "weapons/spike2.wav";
		self.noise2 = nil;
		self.speed = 1000;
		self.dmg = 18;
	} else {
		self.weaponmodel = "progs/spike.mdl";
		self.noise1 = "weapons/spike2.wav";
		self.noise2 = nil;
		self.speed = 1000;
		self.dmg = 9;
	}
	
	self.mass = self.dmg;

	trap_genericshooter();
};

/*QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
*/
void() trap_shooter = {
	if (!self.wait)
		self.wait = 1;
	self.speed = 500;	// Beats me.
	self.delay = self.nextthink + self.wait;
	trap_spikeshooter();
};
