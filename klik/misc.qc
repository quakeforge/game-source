#include "common.qh"
#include "protocol.qh"
#include "misc.qh"
#include "server.qh"
#include "teleport.qh"
#include "weapon.qh"

.float tl_notsolid;

// ===================================================================== //

entity(string clname) spawn = {
	local entity e;

	e = BUILTIN_spawn();
	e.classname = clname;

	return e;
};

// ===================================================================== //

void() SUB_remove = { remove(self); };

void(entity e) safe_remove = {
	e.takedamage = DAMAGE_NO;
	e.solid = SOLID_NOT;
	e.model = NIL;
	e.modelindex = 0;

	e.think = SUB_remove;
	e.nextthink = time;
};

// ===================================================================== //

void() SUB_makestatic = { makestatic(self); };

void(entity e) safe_makestatic = {
	if (sv_spawning) {
		makestatic(self);
		return;
	}

	e.takedamage = DAMAGE_NO;
	e.solid = SOLID_NOT;

	e.think = SUB_makestatic;
	e.nextthink = time;
};

// ===================================================================== //

void() _sound_vector_think = {
	sound(self, CHAN_VOICE, self.noise1, self.volume, self.attenuation);
	remove(self);
};
void(vector org, string samp, float vol, float atten) sound_vector = {
	local entity e;

	e = spawn("SOUND");
	e.origin = org;
	e.noise1 = samp;
	e.volume = vol;
	e.attenuation = atten;

	e.think = _sound_vector_think;
	e.nextthink = time;
};

// ===================================================================== //

float(vector org) _missile_th_teleport = {
	self.owner = world;
	return TRUE;
};

void(entity mis) missile_check_teleport;
void() _missile_always_trigger = {
	self.think = SUB_remove;
	self.nextthink = self.attack_finished;

	if (self.movetype != MOVETYPE_FLYMISSILE && self.movetype != MOVETYPE_FLY)
		return;

	tl_proj_begin();
	/* Make sure we're still going to hit the thing */
	traceline(self.origin, self.origin + self.velocity * sv_maxtic*2, FALSE, self);
	if (trace_ent == self.enemy)	tl_touch(trace_ent, self);
	else				self.enemy = world;
	tl_proj_end();

	missile_check_teleport(self);
};

void(entity mis) missile_check_teleport = {
	local float duration;

	tl_proj_begin();

	trace_ent = mis;
	trace_endpos = mis.origin;
	duration = mis.attack_finished - time;

	while (duration > sv_maxtic) {
		traceline(trace_endpos, trace_endpos + mis.velocity*duration, FALSE, trace_ent);

		if (!trace_ent || trace_ent.solid == SOLID_BSP) {
			/* Don't bother tracing through BSP, it won't happen. */
			break;
		}

		if (tl_issolid(trace_ent) || mis.enemy == trace_ent || (duration*trace_fraction) <= sv_maxtic) {
			/* We hit a triggered trigger,
			   a solid ent, or something we _just_ hit */
			if (trace_fraction == 0) {
				/* We're not going anywhere. Fudge it. */
				break;
			}
			/* Trace on past it. */
			duration -= duration*trace_fraction;
			continue;
		}

		/* Reached a [new] trigger */
		mis.enemy = trace_ent;
		mis.think = _missile_always_trigger;
		mis.nextthink = time + duration*trace_fraction - sv_maxtic;
		break;
	}

	tl_proj_end();
};

entity(string clname, string mod, vector org, vector dir, float spd) spawn_missile = {
	newmis = spawn(clname);

	newmis.owner = self;
	newmis.goalentity = self;

	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.deadflag = DEAD_NONLIVING;

	newmis.th_teleport = _missile_th_teleport;

	setmodel(newmis, mod);
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, org);

	newmis.angles = vectoangles(dir);
	newmis.speed = spd;
	newmis.velocity = dir * spd;

	newmis.attack_finished = time + (6000 / spd);

	newmis.think = SUB_remove;
	newmis.nextthink = newmis.attack_finished;

	missile_check_teleport(newmis);

	return newmis;
};

// ===================================================================== //

entity tl_first;
.entity tl_next;
void() tl_proj_begin = {
	local entity walk;

	tl_first = world;
	for (walk = nextent(world); walk; walk = nextent(walk)) {
		if (walk.solid != SOLID_TRIGGER)
			continue;

		walk.tl_next = tl_first;
		tl_first = walk;

		walk.solid = SOLID_BBOX;
		walk.tl_notsolid = TRUE;
		setorigin(walk, walk.origin); // relink
	}
};

void() tl_proj_end = {
	local entity walk;

	for (walk = tl_first; walk; walk = walk.tl_next) {
		walk.solid = SOLID_TRIGGER;
		walk.tl_notsolid = FALSE;
		setorigin(walk, walk.origin); // relink
	}
};

void(entity trigger, entity fake_proj) tl_touch = {
	local entity oldself, oldother;

	if (!trigger.touch)
		return;

	tl_proj_end();

	oldself = self;
	oldother = other;

	self = trigger;
	other = fake_proj;

	self.touch();

	self = oldself;
	other = oldother;

	tl_proj_begin();
};

// ===================================================================== //

string(entity e) name = {
	if (e.netname) return e.netname;
	if (e.classname) return e.classname;

	if (e.velocity)
		return "an unidentified flying object";
	return "an unidentified stationary object";
};

// ===================================================================== //

void(.string fld, string match, void(entity e) func) foreach = {
	local entity ent;

	ent = world;
	while ((ent = find(ent, fld, match))) {
		if (!func) {
			dprint("NULL function in foreach, classname: ", ent.classname, "\n");
			continue;
		}

		func(ent);
	}
};

void(.string fld, string match, .void() func) foreach_field = {
	local entity oldself;

	oldself = self;

	self = world;
	while ((self = find(self, fld, match))) {
		if (!self.func) {
			dprint("NULL function in foreach_field, classname: ", self.classname, "\n");
			continue;
		}

		self.func();
	}

	self = oldself;
};

// ===================================================================== //

float(entity newself, entity newother, float() func) switcheroo = {
	local entity oldself, oldother;
	local float ret;

	oldself = self;
	oldother = other;

	self = newself;
	other = newother;

	ret = func();

	self = oldself;
	other = oldother;

	return ret;
};

// ===================================================================== //

float(float current, float increment, float max) increase_bound = {
	local float diff;

	diff = max - current;
	if (diff <= 0) return current;
	if (diff > increment) diff = increment;
	return current + diff;
};

float(.float fld, float increment, float max) increase_field = {
	local float new;

	new = increase_bound(self.fld, increment, max);
	if (new == self.fld)
		return FALSE;

	self.fld = new;

	return TRUE;
};

// ===================================================================== //

/* Not to be confused with maxspeed */
float(entity e) calc_max_speed = {
	local float spd;

	spd = e.maxspeed;

	if (self.waterlevel >= 2)
		spd = spd * 0.7;	// Bah.  Hard coded in engine.
	else if (!self.waterlevel && !(self.flags & FL_ONGROUND)) {
		if (spd > 30)
			spd = 30;	// Also hard coded.
	}
	
	return spd;
};

// ===================================================================== //

entity _xprint_client;
float _xprint_level;
void(entity client, float level) xprint_start = {
	_xprint_client = client;
	_xprint_level = level;
};

void(string str) xprint_str = {
	msg_entity = _xprint_client;
	WriteByte(MSG_ONE, SVC_PRINT);
	WriteByte(MSG_ONE, _xprint_level);
	WriteString(MSG_ONE, str);
};

// ===================================================================== //

entity(.string fld, string str) find_random = {
	local float r, numents;
	local entity ent;

	numents = 0;
	r = floor(random() * 512);

	while (1) {
		ent = find(world, fld, str);
		if (!ent) return world;

		while (ent) {
			numents++;

			r--;
			if (r <= 0) return ent;

			ent = find(ent, fld, str);
		}

		r -= numents * floor(r / numents);
	}

	return world;
};

// ===================================================================== //

entity(entity ech) random_enemy_chain = {
	local entity walk;
	local float tot, r;

	r = floor(random()*64) + 1;

	tot = 1;
	for (walk = ech.enemy; walk != ech; walk = walk.enemy) {
		r--;
		if (r <= 0)
			return walk;

		tot++;
	}

	if (!tot)
		return ech;

	/* Ok, only look at half the remaining ones */
	tot = floor(tot * 0.5);
	if (!tot)
		return ech.enemy;

	r -= tot * floor(r / tot);

	for (walk = ech.enemy; walk; walk = walk.enemy) {
		if (r <= 0)
			return walk;

		r--;
	}

	return world;
};

// ===================================================================== //

