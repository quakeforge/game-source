#include "common.qh"
#include "misc.qh"
#include "effect.qh"

#include "mapents_util.qh"
#include "damage.qh"

#define IMPLEMENT_MAPENTS
#include "mapents.qh"

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() _intermission_loop_chain = {
	self.enemy = intermission_head;
};

void() info_intermission = {
	util_map_entity_init();

	if (!intermission_head) {
		self.think = _intermission_loop_chain;
		self.nextthink = time;
	}

	self.enemy = intermission_head;
	intermission_head = self;
};

void() _spawn_point_loop_chain = {
	self.enemy = spawn_head;
};

void() _spawn_point_init = {
	local entity oldself;

	util_map_entity_init();

	if (self.count > spawn_head.count) {
		oldself = self;
		while (spawn_head) {
			self = spawn_head;
			util_map_entity_cull();
			spawn_head = spawn_head.enemy;
		}
		self = oldself;
	} else if (self.count < spawn_head.count) {
		util_map_entity_cull();
		return;
	}

	if (!spawn_head) {
		self.think = _spawn_point_loop_chain;
		self.nextthink = time;
	}

	self.enemy = spawn_head;
	spawn_head = self;
};

/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The single player starting point for a level.
*/
void() info_player_start = { self.count = 0; _spawn_point_init(); };

/*QUAKED info_player_start2 (1 0 0) (-16 -16 24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 = { self.count = 0; _spawn_point_init(); };

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
A spawn point for non-teamplay deathmatch games
*/
void() info_player_deathmatch = { self.count = 100; _spawn_point_init(); };

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
A spawn point for coop games
*/
void() info_player_coop = { self.count = 0; _spawn_point_init(); };

/*QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Doesn't do anything. Use it for ambients.
*/
void() info_notnull = {
	util_map_entity_init();
	util_map_entity_cull();
};

#define SPAWNFLAGS_START_OFF	1
/*QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
*/
void() _light_use = {
	if (self.spawnflags & SPAWNFLAGS_START_OFF) {
		lightstyle(self.style, self.noise4);
		self.spawnflags -= SPAWNFLAGS_START_OFF;
	} else {
		lightstyle(self.style, self.noise3);
		self.spawnflags |= SPAWNFLAGS_START_OFF;
	}
};

void() light = {
	util_map_entity_init();

	if (!self.noise3)	self.noise3 = "a";
	if (!self.noise4)	self.noise4 = "m";

	self.use = _light_use;
	if (self.spawnflags & SPAWNFLAGS_START_OFF)
		lightstyle(self.style, self.noise3);
	else
		lightstyle(self.style, self.noise4);

	util_map_entity_cull();
};

/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
*/
void() _misc_fireball_deathmsg = {
	local float r;
	local string nname;
	r = random();

	nname = name(self);
	
	if (r < 0.25)		bprint(PRINT_DEATH, nname, " catches a lava ball.\n");
	else if (r < 0.5)	bprint(PRINT_DEATH, "A lavaball gives ", nname, " a hug.\n");
	else if (r < 0.75)	bprint(PRINT_DEATH, nname, " was struck down by the lava gods.\n");
	else			bprint(PRINT_DEATH, nname, " gets coated with liquid brimstone.\n");
};

void() _misc_fireball_touch = {
	damage(other, self, self, 20, _misc_fireball_deathmsg);
	safe_remove(self);
};

void() _misc_fireball_think = {
	local entity fireball;
	local vector dir;

	fireball = spawn("FIREBALL");
	fireball.netname = "a lavaball";
	setmodel(fireball, self.weaponmodel);
	setorigin(fireball, self.origin);

	fireball.solid = SOLID_TRIGGER;
	fireball.movetype = MOVETYPE_TOSS;
	fireball.touch = _misc_fireball_touch;

	makevectors(self.angles);
	dir = v_forward*500 + v_right*crandom()*50 + v_up*crandom()*50;
	dir = normalize(dir);
	fireball.velocity = dir * self.speed;
	fireball.mass = 20;

	self.nextthink = time + (random() * 5) + 3;
};

void() misc_fireball = {
	util_map_entity_init();

	if (!self.angles)	self.angles = '-90 0 0';
	if (!self.speed)	self.speed = 200;
	if (!self.weaponmodel)	self.weaponmodel = "progs/lavaball.mdl";

	precache_model(self.weaponmodel);

	self.think = _misc_fireball_think;
	self.nextthink = time + (random() * 5);
};

/*QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
Exploding box.
*/

void() _misc_explobox_deathmsg = {
	local float r;
	local string nname;
	
	nname = name(self);
	
	r = random();
	if (self.dmg_attacker.dmg_attacker == self) {
		if (r < 0.5)	bprint(PRINT_DEATH, nname, " learns what combustible means the hard way.\n");
		else		bprint(PRINT_DEATH, nname, " trips on some live ammo.\n");
	} else {
		if (r < 0.5)	bprint(PRINT_DEATH, nname, " has fun at the gunpowder factory.\n");
		else		bprint(PRINT_DEATH, nname, " eats ", name(self.dmg_attacker.dmg_attacker), "'s box of joy.\n");
	}
};

float(float d)
_misc_explobox_damage = {
	self.health -= d;

	if (self.health <= 0) {
		util_use_targets();

		self.takedamage = DAMAGE_NO;

		self.velocity = '0 0 0';
		damage_attack(self);

		damage_radius(self, self.dmg_attacker, self, _misc_explobox_deathmsg);

		effect_explosion(center(self));

		deathmsg_nodisplay();
		remove(self);
	}

	deathmsg_nodisplay();
	return FALSE; // lie
};

void() misc_explobox = {
	if (!self.model) self.model = "maps/b_explob.bsp";
	if (!self.mins && !self.maxs) {
		self.mins = '0 0 0';
		self.maxs = '32 32 64';
	}

	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;

	util_map_entity_init();

	if (!self.health) self.health = 20;
	if (!self.dmg) self.dmg = 160;
	if (!self.mass) self.mass = self.dmg * 8;
	if (!self.lip) self.lip = self.dmg;
	if (!self.speed) self.speed = 1000;

	self.netname = "combustible cargo";

	self.takedamage = DAMAGE_AIM;

	self.max_health = self.health; // for respawn.

	util_map_entity_drop();

	self.th_takedamage = _misc_explobox_damage;
};

/*QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
*/
void() _func_wall_use = { self.frame = 1 - self.frame; };
void() func_wall = {
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;

	util_map_entity_init();

	self.use = _func_wall_use;

	util_map_entity_cull();
};

/*QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
*/
void() func_illusionary = {
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;

	util_map_entity_init();

	self.use = _func_wall_use;

	util_map_entity_cull();
};
