#include "common.qh"
#include "misc.qh"
#include "server.qh"

#include "mapents_util.qh"

.void() th_activate;

void() util_map_entity_init = {
	self.deadflag = DEAD_NONLIVING;

	if (self.noise && sv_spawning) {
		if (!self.volume)
			self.volume = 0.5;
		if (!self.attenuation)
			self.attenuation = ATTN_STATIC;

		precache_sound (self.noise);
		ambientsound (center (self), self.noise, self.volume,
					  self.attenuation);
	} else {
		if (!self.volume)
			self.volume = 1.0;
		if (!self.attenuation)
			self.attenuation = ATTN_NORM;
	}

	if (sv_spawning) {
		if (self.noise1)
			precache_sound (self.noise1);
		if (self.noise2)
			precache_sound (self.noise2);
		if (self.noise5)
			precache_sound (self.noise5);
		if (self.noise6)
			precache_sound (self.noise6);
	}

	if (self.mangle)
		self.angles = self.mangle;

	if (self.model) {
		if (sv_spawning)
			precache_model (self.model);
		setmodel (self, self.model);
	}

	setsize (self, self.mins, self.maxs);
	setorigin (self, self.origin);	// Links BSP models
};

void() util_map_entity_cull = {
	if (self.solid || self.takedamage)
		return;

	if (self.nextthink > time)
		return;

	if (!sv_spawning) {
		if (self.targetname) {
			if (find (world, target, self.targetname))
				return;
		}
	
		if (self.target) {
			local entity oldself;

			oldself = self;

			self = world;
			while ((self = find(self, targetname, self.target))) {
				if (self == oldself)
					continue;

				util_map_entity_cull ();
			}
		
			self = oldself;
		}
	} else {
		if (self.targetname || self.target) {
			self.think = util_map_entity_cull;
			self.nextthink = time + sv_mintic;
			return;
		}
	}

	if (self.model)
		safe_makestatic (self);
	else
		safe_remove (self);
};

void() util_map_entity_drop = {
	self.origin = self.origin + '0 0 2';
	if (!droptofloor ()) {
		dprint (self.classname, " fell out of level from ", vtos (self.origin),
				"\n");
		remove (self);
		return;
	}
};

float() util_check_targets = {
//	if (self.spawnflags & (SPAWNFLAGS_CHECK_ITEMS|SPAWNFLAGS_TAKE_ITEMS)) {
//	}
	return TRUE;
};

float() util_use_targets = {
	if (!util_check_targets ())
		return FALSE;

	if (self.noise1)
		sound (self, CHAN_VOICE, self.noise1, self.volume, self.attenuation);
	if (self.noise2)
		sound (other, CHAN_ITEM, self.noise2, self.volume, self.attenuation);

	if (self.message && is_cl (other))
		centerprint (other, self.message);

	if (self.th_activate)
		self.th_activate ();

	if (self.target)
		foreach_field (targetname, self.target, use);

	if (self.killtarget)
		foreach (targetname, self.killtarget, safe_remove);

	if (self.count > 0) {
		self.count--;
		if (!self.count) {
			self.targetname = NIL;
			self.target = NIL;
			self.killtarget = NIL;

			self.use = NOTHING_function;
			self.touch = NOTHING_function;

			util_map_entity_cull ();
		}
	}
	
	return TRUE;
};

float(entity e) is_living = {
	return (e.deadflag == DEAD_NO) && is_solid (e);
};

float(entity e) is_solid = {
	return (e.solid != SOLID_NOT && e.solid != SOLID_TRIGGER);
};

float(entity e) is_teleportable = {
	return (e.movetype != MOVETYPE_NONE &&
			e.movetype != MOVETYPE_PUSH &&
			e.movetype != MOVETYPE_NOCLIP &&
			(e.solid == SOLID_BBOX || e.solid == SOLID_SLIDEBOX));
};

void() util_set_movedir = {
	if (self.mangle != '0 0 0')
		self.angles = self.mangle;

	if (self.angles == '0 -1 0') {
		self.movedir = '0 0 1';
	} else if (self.angles == '0 -2 0') {
		self.movedir = '0 0 -1';
	} else {
		makevectors(self.angles);
		self.movedir = v_forward;
	}

	self.angles = '0 0 0';
};

float(entity ent1, entity ent2) util_entities_touch = {
	if (ent1.mins_x > ent2.maxs_x)
		return FALSE;
	if (ent1.mins_y > ent2.maxs_y)
		return FALSE;
	if (ent1.mins_z > ent2.maxs_z)
		return FALSE;

	if (ent2.mins_x > ent1.maxs_x)
		return FALSE;
	if (ent2.mins_y > ent1.maxs_y)
		return FALSE;
	if (ent2.mins_z > ent1.maxs_z)
		return FALSE;

	return TRUE;
};
