#include "common.qh"

#include "damage.qh"
#include "effect.qh"
#include "mdl.qh"

#include "misc.qh"

#include "bodyque.qh"

float _bodyque_current;
entity bodyque_head;

void ()
bodyque_init =
{
	local float i;
	local entity e;

	e = bodyque_head = spawn ("BODYQUE");
	bodyque_head.owner = bodyque_head;
	for (i = 1; i < CONFIG_BODYQUE_MAX; i++) {
		bodyque_head.owner = spawn ("BODYQUE");
		bodyque_head.owner.chain = bodyque_head;
		bodyque_head = bodyque_head.owner;
	}
	e.chain = bodyque_head;
	bodyque_head.owner = e;

	precache_sound ("zombie/z_miss.wav");

	precache_sound ("player/gib.wav");
	precache_sound ("player/udeath.wav");
};

void ()
_bodyque_fade_think =
{
	local vector org;

	if (self.mdl_think) {
		if (!self.mdl_thought)
			self.mdl_think ();
		self.mdl_thought = FALSE;
	}

	org = self.origin;
	org_z = org_z + self.maxs_z;
	if (pointcontents (org) == CONTENT_SOLID) {
		_bodyque_current = _bodyque_current - 1;
		remove (self);
		return;
	}

	self.nextthink = time + 0.1;
};

void ()
_bodyque_fade_from_reality =
{
	local entity new_bodyque;

	if (_bodyque_current >= CONFIG_BODYQUE_FADE_MAX)
		return;

	new_bodyque = spawn("BODYQUE");

	// Link the new entity in, let the old one fade
	if (bodyque_head.owner != bodyque_head) {
		new_bodyque.owner = bodyque_head.owner;
		new_bodyque.chain = bodyque_head.chain;

		new_bodyque.owner.chain = new_bodyque;
		new_bodyque.chain.owner = new_bodyque;
	} else {
		// This happens if CONFIG_BODYQUE_MAX == 1
		new_bodyque.owner = new_bodyque;
		new_bodyque.chain = new_bodyque;
	}

	bodyque_head.movetype = MOVETYPE_NOCLIP;
	bodyque_head.think = _bodyque_fade_think;
	bodyque_head.nextthink = time + 0.1;
	bodyque_head.velocity = '0 0 -10';

	bodyque_head = new_bodyque;
	
	_bodyque_current = _bodyque_current + 1;
};

void ()
_bodyque_think =
{
	if (self.mdl_think) {
		if (!self.mdl_thought)
			self.mdl_think ();
		self.mdl_thought = FALSE;
	}

	self.nextthink = time + 0.1;
};

entity (entity body)
bodyque_que =
{
	local entity ret;

	if (bodyque_head.count)
		_bodyque_fade_from_reality ();

	ret = bodyque_head;

	bodyque_head.deadflag = DEAD_DEAD;

	bodyque_head.count = TRUE;
	bodyque_head.model = body.model;
	bodyque_head.modelindex = body.modelindex;
	bodyque_head.mins = body.mins;
	bodyque_head.maxs = body.maxs;
	bodyque_head.size = body.size;
	bodyque_head.angles = body.angles;
	bodyque_head.frame = body.frame;
	bodyque_head.colormap = body.colormap;
	bodyque_head.movetype = body.movetype;
	bodyque_head.velocity = body.velocity;
	bodyque_head.avelocity = body.avelocity;
	bodyque_head.health = body.health;
	bodyque_head.mass = body.mass;

	bodyque_head.solid = SOLID_NOT;
	bodyque_head.movetype = MOVETYPE_BOUNCE;

	bodyque_head.takedamage = DAMAGE_NO;

	bodyque_head.mdl_func = body.mdl_func;
	bodyque_head.mdl_mod = body.mdl_mod;
	bodyque_head.mdl_think = body.mdl_think;
	bodyque_head.mdl_thought = body.mdl_thought;

	setorigin(bodyque_head, body.origin);
	setsize(bodyque_head, body.mins, body.maxs);

	bodyque_head.think = _bodyque_think;
	bodyque_head.nextthink = time + 0.1;

	bodyque_head = bodyque_head.owner;

	return ret;
};
