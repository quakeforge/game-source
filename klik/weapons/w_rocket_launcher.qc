#include "common.qh"

#include "weapon.qh"
#include "equip.qh"
#include "damage.qh"
#include "misc.qh"
#include "effect.qh"

#define STR_EQUIPID_ROCKET_LAUNCHER	"Rocket Launcher"

void() _deathmsg_rocket_launcher = {
	local string def_nname, att_nname;
	local float r;

	def_nname = name(self);
	att_nname = name(self.dmg_attacker);

	if (self == self.dmg_attacker) {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " uses his melee rocket launcher.\n");
		else		bprint(PRINT_DEATH, def_nname, " doesn't know how to use a rocket launcher.\n");
	} else {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " rides ", att_nname, "'s rocket.\n");
		else		bprint(PRINT_DEATH, att_nname, "'s rocket got friendly with ", def_nname, ".\n");
	}
};

void() _rocket_touch =
{
	local float damg, contents;

	contents = pointcontents(self.origin);

	if (contents == CONTENT_SKY) {
		remove(self);
		return;
	}

	if (contents >= CONTENT_LAVA && contents <= CONTENT_WATER) {
		self.dmg *= 0.9;
		self.lip *= 0.8;
		self.mass *= 1.5;
		self.speed *= 0.8;
	}

	damg = self.dmg - 0.2*random()*self.dmg;
	damage(other, self.goalentity, self, damg, _deathmsg_rocket_launcher);

	self.velocity = '0 0 0';
	damage_radius(other, self.goalentity, self, _deathmsg_rocket_launcher);

	effect_explosion(self.origin);

	safe_remove(self);
};

void() _w_rocket_launcher_think = {
	self.weaponframe++;
	if (self.weaponframe < 1 || self.weaponframe > 6) {
		self.w_think = NOTHING_function;
		self.weaponframe = 0;
	}
};

void() _w_rocket_launcher_fire = {
	local vector dir;
	local entity missile;

	if (!util_weapon_use_ammo(ammo_rockets, 1))
		return;

	sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	makevectors(self.v_angle);

	dir = aim(self, 1000);
	missile = spawn_missile("ROCKET", "progs/missile.mdl", shootorigin(self), dir, 1000);
	missile.dmg = 120;
	missile.mass = missile.dmg * 8;
	missile.lip = missile.dmg;

	missile.touch = _rocket_touch;

	damage_attack(missile);

	self.weaponframe = 1;
	self.w_think = _w_rocket_launcher_think;
	self.mdl_func(MDL_FUNC_FIRE, 0);

	effect_smallkick(self);

	self.attack_finished = time + 0.8;
};

/* WEAPON 7 rocket_launcher */
float(float action)
w_rocket_launcher = {
	if (action == WEAPON_AMMO) {
		self.items |= IT_ROCKETS;
		return self.ammo_rockets;
	} else if (action == WEAPON_WEIGHT) {
		return 55;
	} else if (action == WEAPON_SELECTABLE) {
		if (!equip_query(self, EQUIPID_ROCKET_LAUNCHER))
			return 0;
		if (self.ammo_rockets >= 1)
			return 1;
		return -1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) | MDL_MOD_WEP_ROCKET_LAUNCHER;
		
		weaponprint(STR_EQUIPID_ROCKET_LAUNCHER);
	} else if (action == WEAPON_FIRE) {
		_w_rocket_launcher_fire();
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_rock2.mdl");
		precache_model("progs/missile.mdl");
		precache_sound("weapons/sgun1.wav");
	}
	
	return 0;
};
