#include "common.qh"
#include "effect.qh"

#include "weapon.qh"
#include "equip.qh"

#include "damage.qh"
#include "misc.qh"

#define STR_EQUIPID_NAILGUN	"Nailgun"

void() _deathmsg_nailgun = {
	local string def_nname, att_nname;
	local float r;

	def_nname = name(self);
	att_nname = name(self.dmg_attacker);

	if (self.dmg_attacker == self) {
		bprint(PRINT_DEATH, def_nname, " enjoys the pain.\n");
	} else {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " was nailed by ", att_nname, ".\n");
		else		bprint(PRINT_DEATH, att_nname, " nailed ", def_nname, ".\n");
	}
};

void() _spike_touch =
{
	if (pointcontents(self.origin) == CONTENT_SKY) {
		remove(self);
		return;
	}

	if (!damage(other, self.goalentity, self, self.dmg, _deathmsg_nailgun))
		effect_nail_spark(self.origin, self.velocity);

	safe_remove(self);
};

void(float ox, float damg, string mod) _nailgun_fire_spike =
{
	local vector    dir;
	local entity    missile;
	
	makevectors (self.v_angle);

	dir = aim(self, 1000);
	missile = spawn_missile("NAIL", mod, shootorigin(self) + v_right*ox, dir, 1000);
	missile.dmg = damg;
	missile.mass = missile.dmg * 8;

	missile.touch = _spike_touch;

	damage_attack(missile);

	effect_muzzleflash();
	effect_smallkick(self);
};

//============================================================================

void() _w_nailgun_think = {
	self.weaponframe++;
	if (self.weaponframe == 9)
		self.weaponframe = 1;

	/* FIXME: Use short circuit logic here when compiler supports */
	if (!self.button0 || self.weaponframe < 1 || self.weaponframe > 8) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
		self.mdl_func(MDL_FUNC_IDLE, 0);
		return;
	}

	if (!util_weapon_use_ammo(ammo_nails, 1)) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
		self.mdl_func(MDL_FUNC_IDLE, 0);
		return;
	}

	sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	if (self.weaponframe & 1)	_nailgun_fire_spike(4, 9, "progs/spike.mdl");
	else				_nailgun_fire_spike(-4, 9, "progs/spike.mdl");

	self.attack_finished = time + 0.2;
};

/* WEAPON 4 nailgun */
float(float action)
w_nailgun = {
	if (action == WEAPON_AMMO) {
		self.items |= IT_NAILS;
		return self.ammo_nails;
	} else if (action == WEAPON_WEIGHT) {
		return 30;
	} else if (action == WEAPON_SELECTABLE) {
		if (!equip_query(self, EQUIPID_NAILGUN))
			return 0;
		if (self.ammo_nails >= 1)
			return 1;
		return -1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) | MDL_MOD_WEP_NAILGUN;
		
		weaponprint(STR_EQUIPID_NAILGUN);
	} else if (action == WEAPON_FIRE) {
		self.mdl_func(MDL_FUNC_FIRE, 0);

		self.w_think = _w_nailgun_think;
		self.w_think();
		self.w_thought = TRUE;
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_nail.mdl");
		precache_model("progs/spike.mdl");
		precache_sound("weapons/rocket1i.wav");
	}
	
	return 0;
};

//============================================================================

#define STR_EQUIPID_SUPER_NAILGUN	"Super Nailgun"

void() _w_super_nailgun_think = {
	self.weaponframe++;
	if (self.weaponframe == 9)
		self.weaponframe = 1;

	/* FIXME: Use short circuit logic here when compiler supports */
	if (!self.button0 || self.weaponframe < 1 || self.weaponframe > 8) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
		self.mdl_func(MDL_FUNC_IDLE, 0);
		return;
	}

	if (!util_weapon_use_ammo(ammo_nails, 2)) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
		self.mdl_func(MDL_FUNC_IDLE, 0);
		return;
	}

	sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	_nailgun_fire_spike(0, 18, "progs/s_spike.mdl");

	self.attack_finished = time + 0.2;
};

/* WEAPON 5 super_nailgun */
float(float action)
w_super_nailgun = {
	if (action == WEAPON_AMMO) {
		self.items |= IT_NAILS;
		return self.ammo_nails;
	} else if (action == WEAPON_WEIGHT) {
		return 45;
	} else if (action == WEAPON_SELECTABLE) {
		if (!equip_query(self, EQUIPID_SUPER_NAILGUN))
			return 0;
		if (self.ammo_nails >= 2)
			return 1;
		return -1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) + MDL_MOD_WEP_SUPER_NAILGUN;
		
		weaponprint(STR_EQUIPID_SUPER_NAILGUN);
	} else if (action == WEAPON_FIRE) {
		self.mdl_func(MDL_FUNC_FIRE, 0);

		self.w_think = _w_super_nailgun_think;
		self.w_think();
		self.w_thought = TRUE;
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_nail2.mdl");
		precache_model("progs/s_spike.mdl");
		precache_sound("weapons/spike2.wav");
	}
	
	return 0;
};
