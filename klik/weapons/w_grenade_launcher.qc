#include "common.qh"

#include "weapon.qh"
#include "equip.qh"
#include "damage.qh"
#include "misc.qh"
#include "effect.qh"

#define STR_EQUIPID_GRENADE_LAUNCHER	"Grenade Launcher"

void() _deathmsg_grenade_launcher = {
	local string def_nname, att_nname;
	local float r;

	def_nname = name(self);
	att_nname = name(self.dmg_attacker);

	if (self == self.dmg_attacker) {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " tries to put the pin back in.\n");
		else		bprint(PRINT_DEATH, def_nname, " launches the pin.\n");
	} else {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_nname, " eats ", att_nname, "'s pineapple.\n");
		else		bprint(PRINT_DEATH, att_nname, "'s pineapple blows ", def_nname, " across the level.\n");
	}
};

void() _grenade_explode = {
	local float contents;

	contents = pointcontents(self.origin);

	if (contents >= CONTENT_LAVA && contents <= CONTENT_WATER) {
		self.dmg *= 0.9;
		self.lip *= 0.8;
		self.mass *= 1.5;
		self.speed *= 0.8;
	}

	self.velocity = '0 0 0';
	damage_radius(world, self.goalentity, self, _deathmsg_grenade_launcher);

	effect_explosion(self.origin);

	safe_remove(self);
};

void() _grenade_touch =
{
	if (other.takedamage != DAMAGE_AIM) {
		sound(self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);
		return;
	}

	if (pointcontents(self.origin) == CONTENT_SKY) {
		remove(self);
		return;
	}

	_grenade_explode();
};

void() _w_grenade_launcher_think = {
	self.weaponframe++;
	if (self.weaponframe < 1 || self.weaponframe > 6) {
		self.w_think = NOTHING_function;
		self.weaponframe = 0;
	}
};

void() _w_grenade_launcher_fire = {
	local vector dir;
	local entity missile;

	if (!util_weapon_use_ammo(ammo_rockets, 1))
		return;

	sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	makevectors(self.v_angle);

	dir = v_forward*600 + v_up*200 + crandom()*v_right*10 + crandom()*v_up*10;
	missile = spawn_missile("PINEAPPLE", "progs/grenade.mdl", shootorigin(self), dir, 1);

	missile.movetype = MOVETYPE_BOUNCE;

	missile.avelocity_x = crandom()*360;
	missile.avelocity_y = crandom()*360;
	missile.avelocity_z = crandom()*360;

	missile.dmg = 120;
	missile.mass = missile.dmg * 8;
	missile.lip = missile.dmg;
	missile.speed = 800;

	missile.touch = _grenade_touch;

	missile.think = _grenade_explode;
	missile.nextthink = time + 2.5;

	damage_attack(missile);

	self.weaponframe = 1;
	self.w_think = _w_grenade_launcher_think;
	self.mdl_func(MDL_FUNC_FIRE, 0);

	effect_smallkick(self);

	self.attack_finished = time + 0.6;
};

/* WEAPON 6 grenade_launcher */
float(float action)
w_grenade_launcher = {
	if (action == WEAPON_AMMO) {
		self.items |= IT_ROCKETS;
		return self.ammo_rockets;
	} else if (action == WEAPON_WEIGHT) {
		return 50;
	} else if (action == WEAPON_SELECTABLE) {
		if (!equip_query(self, EQUIPID_GRENADE_LAUNCHER))
			return 0;
		if (self.ammo_rockets >= 1)
			return 1;
		return -1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) | MDL_MOD_WEP_GRENADE_LAUNCHER;
		
		weaponprint(STR_EQUIPID_GRENADE_LAUNCHER);
	} else if (action == WEAPON_FIRE) {
		_w_grenade_launcher_fire();
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_rock.mdl");
		precache_model("progs/grenade.mdl");
		precache_sound("weapons/grenade.wav");
		precache_sound("weapons/bounce.wav");
	}
	
	return 0;
};
