#include "common.qh"

#include "weapon.qh"
#include "damage.qh"

#include "effect.qh"

void() _w_axe_deathmsg = {
	local float r;
	local string att_nname, def_nname;
	
	r = random();

	def_nname = name(self);
	att_nname = name(self.dmg_attacker);

	if (r < 0.25)		bprint(PRINT_DEATH, def_nname, " gets chopped down to size by ", att_nname, ".\n");
	else if (r < 0.5)	bprint(PRINT_DEATH, att_nname, " mames ", def_nname, " with a rusty axe.\n");
	else if (r < 0.75)	bprint(PRINT_DEATH, def_nname, " loses his scalp to ", att_nname, ".\n");
	else			bprint(PRINT_DEATH, att_nname, "'s axe penetrates ", def_nname, " straight to the bone.\n");
};

void() _w_axe_fire =
{
	local	vector	source;

	source = shootorigin(self);
	
	makevectors (self.v_angle);
	traceline (source, source + v_forward*64, FALSE, self);
	if (trace_fraction == 1.0)
		return;

	ghost_inflictor.classname = "AXE";
	ghost_inflictor.dmg = 20;
	ghost_inflictor.mass = ghost_inflictor.mass * 8;
	ghost_inflictor.velocity = v_forward*1000;

	damage_attack(ghost_inflictor);

	if (!damage(trace_ent, self, ghost_inflictor, ghost_inflictor.dmg, _w_axe_deathmsg)) {
		/* We hit the world. */
		sound(self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		effect_gun_spark(trace_endpos, v_forward * 250, 3);
	}
};

void() _w_axe_think_1 = {
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 3)
		_w_axe_fire();
	if (self.weaponframe <= 1 || self.weaponframe > 4) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
	}
};

void() _w_axe_think_2 = {
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 7)
		_w_axe_fire();
	if (self.weaponframe <= 5 || self.weaponframe > 8) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
	}
};

/* WEAPON 1 axe */
float(float action)
w_axe = {
	if (action == WEAPON_AMMO) {
		return 0;
	} else if (action == WEAPON_WEIGHT) {
		return 1;
	} else if (action == WEAPON_SELECTABLE) {
		return TRUE;
	} else if (action == WEAPON_FIRE) {
		self.attack_finished = time + 0.5;
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);

		if (random() < 0.5) {
			self.weaponframe = 1;
			self.w_think = _w_axe_think_1;
		} else {
			self.weaponframe = 5;
			self.w_think = _w_axe_think_2;
		}
		self.w_thought = TRUE;

		self.mdl_func(MDL_FUNC_FIRE, 0);
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_axe.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) | MDL_MOD_WEP_AXE;

		weaponprint("Axe");
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_axe.mdl");
		precache_sound("player/axhit1.wav");
		precache_sound("player/axhit2.wav");
		precache_sound("weapons/ax1.wav");
	}
	
	return 0;
};
