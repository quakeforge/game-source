#include "common.qh"

#include "misc.qh"
#include "damage.qh"

#include "server.qh"

void() damage_init = {
	ghost_inflictor = spawn("GHOST_INFLICTOR");
};

void(entity from, entity to) deathmsg_copy = {
	to.deathmsg1 = from.deathmsg1;
	to.deathmsg2 = from.deathmsg2;
	to.deathmsg3 = from.deathmsg3;
	to.deathmsg4 = from.deathmsg4;
	to.deathmsg5 = from.deathmsg5;
	to.deathmsg6 = from.deathmsg6;
};

string(entity e, string s) _deathmsg_custom_str = {
	if (s == "name(self)") return name(self);
	if (s == "name(attacker)") return name(self.dmg_attacker);
	if (s == "name(inflictor)") return name(self.dmg_inflictor);
	return s;
};

void() _deathmsg_custom = {
	local string s1, s2, s3, s4, s5, s6;

	s1 = s2 = s3 = s4 = s5 = s6 = "";

	s1 = _deathmsg_custom_str(self, self.deathmsg1);
	if (s1)	s2 = _deathmsg_custom_str(self, self.deathmsg2);
	if (s2)	s3 = _deathmsg_custom_str(self, self.deathmsg3);
	if (s3)	s4 = _deathmsg_custom_str(self, self.deathmsg4);
	if (s4) s5 = _deathmsg_custom_str(self, self.deathmsg5);
	if (s5) s6 = _deathmsg_custom_str(self, self.deathmsg6);

	// I don't use separate bprints, because iD in all its wisdom
	// made them unreliable -- I'd rather lose the whole thing than parts.
	bprint(PRINT_DEATH, s1, s2, s3, s4, s5, s6);
};

void() deathmsg_nodisplay = {
	//XXX refcount_dec(self.dmg_attacker);
	//XXX refcount_dec(self.dmg_inflictor);
	self.dmg_attacker = world;
	self.dmg_inflictor = world;

	self.deathmsg = NOTHING_function;
};

void() deathmsg_display = {
	if (self.th_die)
		self.th_die();

	if (other.th_kill) {
		local entity oldself, oldother;

		oldself = self;
		oldother = other;
	
		self = oldother;
		other = oldself;

		self.th_kill();

		self = oldself;
		other = oldother;
	}

	self.deathmsg();
	deathmsg_nodisplay();
};

float(float d) damage_armor = {
	local float adamg, rest;

	adamg = d * self.armortype;
	if (self.armorvalue < adamg)
		adamg = self.armorvalue;

	rest = d - adamg;

	self.armorvalue = self.armorvalue - adamg;
	if (self.armorvalue <= 0) {
		self.armorvalue = 0;
		self.armortype = 0.0;
	}

	return rest;
};

void(float d) damage_push = {
	local vector vel;

	if (self.mass == 0) {
		d = 0;
	} else {
		if (self.dmg_attacker == self)
			d = (self.dmg_inflictor.mass + d*rocket_jump) / self.mass;
		else
			d = self.dmg_inflictor.mass / self.mass;
	}

	if (self.dmg_inflictor.velocity == '0 0 0') {
		vel = normalize(self.origin - self.dmg_inflictor.origin);
		vel *= self.dmg_inflictor.speed;
	} else {
		vel = self.dmg_inflictor.velocity;
	}

	self.velocity += d * vel;
};

// deathmessage _IS_ overridden if inflictor.deathmsg1
float(entity ent, entity attacker, entity inflictor, float d, void() deathmessage)
damage = {
	local entity oldself, oldother;
	local float wasdamaged;

	if (!ent.takedamage)
		return FALSE;

	oldself = self;
	oldother = other;
		
	ent.dmg_attacker = attacker;
	ent.dmg_inflictor = inflictor;

	//XXX refcount_inc(ent.dmg_attacker);
	//XXX refcount_inc(ent.dmg_inflictor);

	if (inflictor.deathmsg1)
		ent.deathmsg = _deathmsg_custom;
	else
		ent.deathmsg = deathmessage;

	if (attacker.th_dealdamage) {
		self = attacker;
		other = ent;
		
		d = self.th_dealdamage(d);
		
		self = oldself;
		other = oldother;

		if (d < 0) return FALSE;
	}

	self = ent;
	other = attacker;

	wasdamaged = self.th_takedamage(d);

	self = oldself;
	other = oldother;

	return wasdamaged;
};

float(vector org, entity e) _damage_radius_can_hit = {
	if (e.movetype == MOVETYPE_PUSH) {
		traceline(org, center(e), TRUE, world);

		if (trace_fraction == 1 || trace_ent == e)
			return TRUE;
		return FALSE;
	}

	traceline(org, e.origin, TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(org, e.origin + '15 15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(org, e.origin + '15 -15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(org, e.origin + '-15 15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(org, e.origin + '-15 -15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;

	return FALSE;
};

void(entity ignore, entity attacker, entity inflictor, void() deathmessage)
damage_radius = {
	local entity head;
	local vector iorg, org;
	local float points;
	local float d, m, r;

	d = inflictor.dmg;
	m = inflictor.mass;
	r = inflictor.lip;

	iorg = center(inflictor);

	for (head = findradius(iorg, r + 40); head; head = head.chain) {
		if (head == ignore)
			continue;

		if (!_damage_radius_can_hit(iorg, head))
			continue;

		org = center(head);

		points = r - (0.5 * vlen(iorg - org));
		if (points <= 0)
			continue;

		if (head == attacker)
			points *= 0.5;

		inflictor.dmg = (points * d) / r;
		inflictor.mass = (points * m) / r;

		damage(head, attacker, inflictor, inflictor.dmg, deathmessage);
	}
};
