#include "common.qh"

#include "mapents_util.qh"
#include "damage.qh"

#include "mapents_triggers.qh"

float(float d) _takedamage_use = {
	if (time < self.attack_finished)
		return FALSE;

	self.attack_finished = time + self.wait;

	self.health -= d;

	if (self.health <= 0) {
		self.health = self.max_health;

		if (util_use_targets())
			self.use();
	}

	deathmsg_nodisplay();

	if (self.wait <= 0) {
		self.solid = SOLID_NOT;
		util_map_entity_cull();
	}

	return FALSE; /* Lie */
};

void() _trigger_generic_touch = {
	local void() selfuse;

	if (!is_living(other))
		return;

	if (time < self.attack_finished)
		return;

	self.attack_finished = time + self.wait;

	selfuse = self.use;
	self.use = NOTHING_function; /* Avoid endless loop */
	if (util_use_targets())
		selfuse();
	self.use = selfuse;

	if (self.wait <= 0) {
		self.solid = SOLID_NOT;
		util_map_entity_cull();
	}
};

/*QUAKED trigger_generic (.5 .5 .5) NOTOUCH
Variable sized repeatable trigger.  Must be targeted at one or more entities.
If "model" is set, the trigger will set it as its model.
If "health" is set, trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
If "wait" is set, the trigger waits some time before able to trigger again.
If "count" is > 0, the trigger will only trigger count times.
If notouch is set, the trigger is only fired by other entities, not by touching or killing.
"noise1" is played at the trigger when triggered, if set.
"noise2" is played to the activator when triggered, if set.
"message" is displayed when triggered, if set.
*/
void() trigger_generic = {
	/* Get mins/maxs */
	setmodel(self, self.model);

	/* Avoid displaying triggers */
	self.model = "";
	self.modelindex = 0;

	if (self.health) {
		self.max_health = self.health;
		self.solid = SOLID_BBOX;

		self.takedamage = DAMAGE_YES;
		self.th_takedamage = _takedamage_use;
	}

	if (!self.solid) {
		if (!(self.spawnflags & SPAWNFLAGS_TRIGGER_NOTOUCH)) {
			self.solid = SOLID_TRIGGER;
			self.touch = _trigger_generic_touch;
		}
	}

	/* FIXME: This is a hackaround for qwsv */
	if (self.origin == '0 0 0') {
		self.origin = (self.mins + self.maxs) * 0.5;
		self.mins = self.mins - self.origin;
		self.maxs = self.maxs - self.origin;
		setsize(self, self.mins, self.maxs);
		setorigin(self, self.origin);
	}

	if (!self.use)
		self.use = NOTHING_function;

	util_map_entity_init();
	util_map_entity_cull();
};

/*QUAKED info_teleport_destination (.5 .5 .5) (-8 -8 -8) (8 8 32)
This is the destination marker for a teleporter.  It should have a "targetname"
field with the same value as a teleporter's "target" field.
*/
void() info_teleport_destination = {
	self.origin = self.origin + '0 0 27';
	info_notnull();
};

void() _trigger_teleport_touch = {
	local entity spot;
	local float spd;

	if (!is_teleportable(other))
		return;

	spot = find(world, targetname, self.target);
	if (!spot) {
		damage(other, other, other, DAMAGE_MUSTDIE, NOTHING_function);
		return;
	}

	effect_teleport_fog(other.origin);
	teleport(other, spot);

	spd = vlen(other.velocity);
	makevectors(other.angles);
	other.velocity = v_forward * spd;
};

#define SPAWNFLAGS_SILENT 2
/*QUAKED trigger_teleport (.5 .5 .5) ? PLAYER_ONLY SILENT
Any object touching this will be transported to the corresponding
info_teleport_destination entity. You must set the "target" field,
and create an object with a "targetname" field that matches.
 
If the trigger_teleport has a targetname, it will only teleport
entities when it has been fired.
*/
void() trigger_teleport = {
	if (!(self.spawnflags & SPAWNFLAGS_SILENT) && !self.noise)
		self.noise = "ambience/hum1.wav";
	setmodel(self, self.model);

	self.model = NULL_string;
	self.modelindex = 0;

	util_map_entity_init();

	self.solid = SOLID_TRIGGER;

	self.touch = _trigger_teleport_touch;
	self.use = _trigger_teleport_touch;
};

void() _trigger_hurt_deathmsg = {
	bprint(PRINT_DEATH, name(self), " was in the wrong place.\n");
};

void() _trigger_hurt_use = {
	damage(other, self, self, self.dmg, _trigger_hurt_deathmsg);
};

/*QUAKED trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
*/
void() trigger_hurt = {
	if (!self.wait) self.wait = 1;

	trigger_generic();
	self.use = _trigger_hurt_use;
};

#define SPAWNFLAGS_PUSH_ONCE 1
#define SPAWNFLAGS_PUSH_ADD 2
void() _trigger_push_use = {
	if (!is_solid(other))
		return;

	if (!util_use_targets())
		return;

	if (self.spawnflags & SPAWNFLAGS_PUSH_ADD)
		other.velocity = other.velocity + self.movedir;
	else
		other.velocity = self.movedir;

	if (!is_living(other))
		return;

	if (self.noise3)
		sound(other, CHAN_AUTO, self.noise3, 1, ATTN_NORM);
};

/*QUAKED trigger_push (.5 .5 .5) ? PUSH_ADD PUSH_ONCE
Pushes the player
*/
void() trigger_push = {
	if (!self.wait) self.wait = 1;

	if (!self.speed)	self.speed = 1000;

	if (!self.noise1 && !self.noise2 && !self.noise3)
		self.noise3 = "ambience/windfly.wav";

	if (self.noise3)	precache_sound(self.noise3);

	if (self.spawnflags & SPAWNFLAGS_PUSH_ONCE)
		self.count = 1;

	trigger_generic();

	util_set_movedir();
	self.movedir = self.movedir * self.speed * 10;

	self.use = _trigger_push_use;
};


#define SPAWNFLAGS_NO_INTERMISSION 1
void() _trigger_changelevel_do = {
	local string nextmap;

	nextmap = self.map;
	if (!self.map) nextmap = "start.bsp";

	changelevel(nextmap);
};

void() _trigger_changelevel_use = {
	if (!is_living(other) || !is_cl(other))
		return;

	// Bleah.
	self.touch = NOTHING_function;
	self.think = _trigger_changelevel_do;
	self.nextthink = time;
};

/*QUAKED trigger_changelevel (.5 .5 .5) ? NO_INTERMISSION
When a player touches this, the level changes.  The level
will change to the map set in the map variable.  If it is
not set, the map will change to a random level in the list.

If NO_INTERMISSION is set, the view will not go to an
info_intermission spot and display stats in co-op games.
*/
void() trigger_changelevel = {
	trigger_generic();
	self.use = _trigger_changelevel_use;
};
