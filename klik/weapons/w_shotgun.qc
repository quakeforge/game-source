#include "common.qh"
#include "misc.qh"

#include "weapon.qh"
#include "equip.qh"
#include "damage.qh"
#include "effect.qh"

#define STR_EQUIPID_SHOTGUN	"Shotgun"

#define PUFF_RADIUS	60	/* FIXME: Base on spread too! */

void() _deathmsg_shotgun = {
	local string def_nname, att_nname;
	local float r;

	def_nname = name(self);
	att_nname = name(self.dmg_attacker);

	if (self.dmg_attacker == self) {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " eats lead.\n");
		else		bprint(PRINT_DEATH, def_nname, " can't aim a shotgun.\n");
	} else {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " eats a load of ", att_nname, "'s buckshot.\n");
		else		bprint(PRINT_DEATH, att_nname, " fills ", def_nname, " full of lead.\n");
	}
};

void() _deathmsg_super_shotgun = {
	local float r;
	local string def_nname, att_nname;

	def_nname = name(self);
	att_nname = name(self.dmg_attacker);

	if (self.dmg_attacker == self) {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " gets 2 shells.\n");
		else		bprint(PRINT_DEATH, def_nname, " practices hunting with a teleporter.\n");
	} else {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " eats two loads of ", att_nname, "'s buckshot.\n");
		else		bprint(PRINT_DEATH, att_nname, " makes ", def_nname, " radiation resistant.\n");
	}
};

entity(vector org, vector dir, entity ent) spawn_puff_damage = {
	local entity inflictor;

	inflictor = world;
	while ((inflictor = find(inflictor, classname, "PUFF"))) {
		if (vlen(inflictor.origin - org) > PUFF_RADIUS)
			continue;

		if (inflictor.enemy == ent)
			break;
	}

	if (!inflictor) {
		inflictor = spawn("PUFF");
		inflictor.solid = SOLID_BBOX;
		inflictor.movetype = MOVETYPE_FLY;
		inflictor.deadflag = DEAD_NONLIVING;

		inflictor.velocity = dir;
		inflictor.angles = vectoangles(dir);

		inflictor.owner = ent;
		inflictor.enemy = ent;

		inflictor.origin = org;	// Don't bother linking.
	}

	inflictor.count++;
	
	return inflictor;
};

void(float shotcount, vector spread, void() deathmessage) _fire_bullets =
{
	local	vector	dir, direction;
	local	vector	src;

	local	entity	ignore, puff;
	local	float	t_dmg, t_mass;

	local	float	dist_left;

	makevectors(self.v_angle);
	dir = aim(self, 10000);
	src = shootorigin(self);


	/* See what a single missile would take.. */
	ghost_inflictor.classname = "BULLET";
	ghost_inflictor.velocity = dir*10000;
	ghost_inflictor.dmg = 4;
	ghost_inflictor.mass = ghost_inflictor.dmg;
	damage_attack(ghost_inflictor);
	t_dmg = ghost_inflictor.dmg;
	t_mass = ghost_inflictor.mass;


	/* Create the puff damage entities */
	tl_proj_begin();

	ignore = self;
	dist_left = 8192;

	do {
		/* FIXME: Remove '0' when compiler is fixed */
		for (0; shotcount > 0; shotcount--) {
			direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;
			traceline(src, src + direction*dist_left, FALSE, ignore);

			puff = spawn_puff_damage(trace_endpos, dir, trace_ent);
			puff.health = dist_left;
		}

		puff = world;
		while ((puff = find(puff, classname, "PUFF"))) {
			tl_touch(puff.enemy, puff);

			if (!tl_issolid(puff.enemy)) {
				dist_left = puff.health - (dist_left*trace_fraction);
				if (dist_left > 100)
					break;
			} else {
				puff.dmg = t_dmg * puff.count;
				puff.mass = t_mass * puff.mass;
				if (!damage(puff.enemy, self, puff, puff.dmg, deathmessage))
					effect_gun_spark(puff.origin, puff.velocity, puff.count);
			}

			puff.classname = "REMOVED_PUFF";
			safe_remove(puff);
		}

		if (!puff)
			break;

		src = puff.origin;
		ignore = puff.enemy;
		shotcount = puff.count;

		makevectors(puff.angles);
		dir = v_forward;

		remove(puff);
	} while (1);

	tl_proj_end();
};

void() _w_shotgun_think = {
	self.weaponframe++;
	if (self.weaponframe < 1 || self.weaponframe > 6) {
		self.w_think = NOTHING_function;
		self.weaponframe = 0;
	}
};

void() _w_shotgun_fire =
{
	if (!util_weapon_use_ammo(ammo_shells, 1))
		return;

	sound(self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM); 

	_fire_bullets(6, '0.04 0.04 0', _deathmsg_shotgun);

	self.weaponframe = 1;
	self.w_think = _w_shotgun_think;
	self.mdl_func(MDL_FUNC_FIRE, 0);
	effect_smallkick(self);

	self.attack_finished = time + 0.5;
};

/* WEAPON 2 shotgun */
float(float action)
w_shotgun = {
	if (action == WEAPON_AMMO) {
		self.items |= IT_SHELLS;
		return self.ammo_shells;
	} else if (action == WEAPON_WEIGHT) {
		return 20;
	} else if (action == WEAPON_SELECTABLE) {
		if (!equip_query(self, EQUIPID_SHOTGUN))
			return 0;
		if (self.ammo_shells >= 1)
			return 1;
		return -1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_shot.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) | MDL_MOD_WEP_SHOTGUN;

		weaponprint(STR_EQUIPID_SHOTGUN);
	} else if (action == WEAPON_FIRE) {
		_w_shotgun_fire();
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_shot.mdl");
		precache_sound("weapons/guncock.wav");
	}

	return 0;
};

// ================================================================

#define STR_EQUIPID_SUPER_SHOTGUN	"Super Shotgun"

void() _w_super_shotgun_fire =
{
	if (self.ammo_shells == 1) {
		_w_shotgun_fire();
		return;
	}

	if (!util_weapon_use_ammo(ammo_shells, 2))
		return;

	sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM); 

	_fire_bullets(14, '0.14 0.08 0', _deathmsg_super_shotgun);

	self.weaponframe = 1;
	self.w_think = _w_shotgun_think;
	self.mdl_func(MDL_FUNC_FIRE, 0);
	effect_smallkick(self);

	self.attack_finished = time + 0.7;
};

/* WEAPON 3 super_shotgun */
float(float action)
w_super_shotgun = {
	if (action == WEAPON_AMMO) {
		self.items |= IT_SHELLS;
		return self.ammo_shells;
	} else if (action == WEAPON_WEIGHT) {
		return 40;
	} else if (action == WEAPON_SELECTABLE) {
		if (!equip_query(self, EQUIPID_SUPER_SHOTGUN))
			return 0;
		if (self.ammo_shells >= 2)
			return 1;
		return -1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) | MDL_MOD_WEP_SUPER_SHOTGUN;

		weaponprint(STR_EQUIPID_SUPER_SHOTGUN);
	} else if (action == WEAPON_FIRE) {
		_w_super_shotgun_fire();
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_shot2.mdl");
		precache_sound("weapons/shotgn2.wav");
	}
	
	return 0;
};
