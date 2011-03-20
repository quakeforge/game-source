#include "common.qh"
#include "mapents_util.qh"
#include "items.qh"
#include "weapon.qh"
#include "act.qh"
#include "misc.qh"
#include "mdl_player.qh"
#include "mdl_eyes.qh"

#include "override.qh"
#include "damage.qh"

#include "equip.qh"

#include "mapents_powerup.qh"

/* FIXME: These don't handle powerups that grant stuff others grant. */
float(entity powerup) powerup_check_remove = {
	if ((self.itemfield_1 & powerup.itemfield_1) != powerup.itemfield_1)
		return TRUE;
	if ((self.itemfield_2 & powerup.itemfield_2) != powerup.itemfield_2)
		return TRUE;
	if ((self.itemfield_3 & powerup.itemfield_3) != powerup.itemfield_3)
		return TRUE;
	if ((self.itemfield_4 & powerup.itemfield_4) != powerup.itemfield_4)
		return TRUE;

	return FALSE;
};

void(entity powerup) powerup_remove = {
	self.itemfield_1 -= (self.itemfield_1 & powerup.itemfield_1);
	self.itemfield_2 -= (self.itemfield_2 & powerup.itemfield_2);
	self.itemfield_3 -= (self.itemfield_3 & powerup.itemfield_3);
	self.itemfield_4 -= (self.itemfield_4 & powerup.itemfield_4);

	self.items -= (self.items & powerup.items);
	self.effects -= (self.effects & powerup.effects);

	override_destroy(self, powerup);
};

float() _powerup_takeitem = {
	local entity powerup;
	powerup = override_findself();

	if ((powerup.itemfield_1 & other.itemfield_1)
	 || (powerup.itemfield_2 & other.itemfield_2)
	 || (powerup.itemfield_3 & other.itemfield_3)
	 || (powerup.itemfield_4 & other.itemfield_4)) {
		if ((time+other.attack_finished) > powerup.attack_finished) {
			/* Act like we don't have it, to renew.. */
			powerup_remove(powerup);
		}
	}
	
	if (powerup.th_takeitem)
		return powerup.th_takeitem();
	return FALSE;
};

void() _powerup_prethink = {
	local entity powerup;
	powerup = override_findself();

	if (powerup_check_remove(powerup))
		powerup_remove(powerup);

	if (powerup.prethink)
		powerup.prethink();
};

void() _powerup_think = {
	local entity powerup;
	powerup = override_findself();

	if (time > powerup.attack_finished) {
		powerup_remove(powerup);
	} else if (time >= powerup.air_finished) {
		if (is_cl(self))
			stuffcmd(self, "bf\n");

		if (powerup.noise) {
			sound(self, CHAN_AUTO, powerup.noise, 1, ATTN_NORM);
			powerup.noise = nil;
		}

		powerup.air_finished += 1;
	}

	if (powerup.actthink)
		powerup.actthink();
};

void() _powerup_postthink = {
	local entity powerup;
	powerup = override_findself();

	self.items |= powerup.items;
	self.effects |= powerup.effects;

	if (powerup.postthink)
		powerup.postthink();
};

// ===================================================================== //

float(float dmg) _suit_takedamage = {
	local entity powerup;
	powerup = override_findself();

	if (dmg < DAMAGE_SHOULDDIE && self.dmg_inflictor == world) {
		/* Magic formula */
		dmg -= 20*frametime;
		dmg /= 30*frametime;

		if (dmg <= 0) {
			override_halt();
			deathmsg_nodisplay();
			return FALSE;
		}
	}

	if (powerup.th_takedamage)
		return powerup.th_takedamage(dmg);
	return FALSE;
};

void() _suit_prethink = {
	local entity powerup;
	powerup = override_findself();

	if (powerup_check_remove(powerup)) {
		powerup_remove(powerup);
	} else {
		self.air_finished = time + 12;
	}

	if (powerup.prethink)
		powerup.prethink();
};

#define STR_EQUIPID_SUIT	"Environmental Suit"
void() _suit_activate = {
	local entity powerup;

	powerup = override_create(other, "OVERRIDE_SUIT", OVERPRIO_SUIT);
	powerup.th_takeitem = _powerup_takeitem;
	powerup.th_takedamage = _suit_takedamage;
	powerup.prethink = _suit_prethink;
	powerup.actthink = _powerup_think;
	powerup.postthink = _powerup_postthink;
	override_finalize(powerup);

	equip_grant(powerup, EQUIPID_SUIT);
	powerup.items = IT_SUIT;
	powerup.attack_finished = time + self.attack_finished;

	powerup.noise = "items/suit2.wav";
	powerup.air_finished = powerup.attack_finished - 3;
};
/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime
*/
void() item_artifact_envirosuit = {
	self.netname = STR_EQUIPID_SUIT;
	if (!self.model) self.model = "progs/suit.mdl";
	if (!self.noise2) self.noise2 = "items/suit.wav";
	if (!self.attack_finished) self.attack_finished = 30;
	if (!self.mins && !self.maxs) {
		self.mins = '-16 -16 -24';
		self.maxs = '16 16 32';
	}
	if (!self.wait && !self.delay) {
		self.wait = 55;
		self.delay = 10;
	}

	precache_sound("items/suit2.wav");

	equip_grant(self, EQUIPID_SUIT);
	self.th_activate = _suit_activate;

	item_generic();
};

// ===================================================================== //

void() item_artifact_super_damage;
void() _quad_die = {
	local entity powerup;
	powerup = override_findself();

	if ((powerup.attack_finished - time) >= 4) {
		local entity oldself;

		oldself = self;

		self = spawn("ITEM_ARTIFACT_SUPER_DAMAGE");
		self.origin = center(oldself);

		self.movetype = MOVETYPE_TOSS;
		self.velocity_x = crandom()*200;
		self.velocity_y = crandom()*200;
		self.velocity_z = 320;

		self.wait = -1;
		self.attack_finished = powerup.attack_finished - time;

		self.think = SUB_remove;
		self.nextthink = time + 20 + random()*10;

		item_artifact_super_damage();

		bprint(PRINT_HIGH, name(oldself), " dropped a Quad with ", ftos(floor(self.attack_finished)), " seconds remaining.\n");

		self = oldself;
	}

	if (powerup.th_die)
		powerup.th_die();
};

void(entity missile) _quad_attack = {
	local entity powerup;
	powerup = override_findself();

	if (time >= powerup.pain_finished) {
		sound(self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		powerup.pain_finished = time + 1;
	}
	
	missile.dmg *= 4;
	missile.mass *= 4;

	if (powerup.th_attack)
		powerup.th_attack(missile);
};

#define STR_EQUIPID_QUAD "Quad Damage"
void() _quad_activate = {
	local entity powerup;

	powerup = override_create(other, "OVERRIDE_QUAD", OVERPRIO_QUAD);
	powerup.th_takeitem = _powerup_takeitem;
	powerup.th_attack = _quad_attack;
	powerup.th_die = _quad_die;
	powerup.prethink = _powerup_prethink;
	powerup.actthink = _powerup_think;
	powerup.postthink = _powerup_postthink;
	override_finalize(powerup);

	equip_grant(powerup, EQUIPID_QUAD);
	powerup.items = IT_QUAD;
	powerup.effects = EF_BLUE;
	powerup.attack_finished = time + self.attack_finished;

	powerup.noise = "items/damage2.wav";
	powerup.air_finished = powerup.attack_finished - 3;
};
/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
Attacks from the player will do 4x damage
*/
void() item_artifact_super_damage = {
	self.netname = STR_EQUIPID_QUAD;
	if (!self.model) self.model = "progs/quaddama.mdl";
	if (!self.noise2) self.noise2 = "items/damage.wav";
	if (!self.mins && !self.maxs) {
		self.mins = '-16 -16 -24';
		self.maxs = '16 16 32';
	}
	if (!self.attack_finished) self.attack_finished = 30;
	if (!self.wait && !self.delay) {
		self.wait = 55;
		self.delay = 10;
	}
	if (!self.effects) self.effects = EF_BLUE;

	if (sv_spawning) {
		precache_sound("items/damage3.wav");
		precache_sound("items/damage2.wav");
	}

	equip_grant(self, EQUIPID_QUAD);
	self.th_activate = _quad_activate;

	item_generic();
};

// ===================================================================== //

float(float dmg) _pentagram_takedamage = {
	local entity powerup;
	powerup = override_findself();

	if (dmg == DAMAGE_MUSTDIE)
		return powerup.th_takedamage(dmg);

	if (dmg == DAMAGE_SHOULDDIE) {
		if (self.dmg_attacker == self)
			return powerup.th_takedamage(dmg);

		local entity oldattacker, oldinflictor;
		local float damaged;

		oldattacker = self.dmg_attacker;
		oldinflictor = self.dmg_inflictor;

		damaged = damage(self.dmg_attacker, self, self.dmg_inflictor, dmg, self.deathmsg);

		other = self.dmg_attacker = oldattacker;
		oldinflictor = self.dmg_inflictor;

		if (!damaged)
			return powerup.th_takedamage(dmg);
	}

	damage_push(dmg);
	damage_armor(dmg);
	self.dmg_save = 0;	// Avoid flashy stuff

	if (time >= powerup.pain_finished) {
		sound(self, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
		powerup.pain_finished = time + 1.0;
	}

	deathmsg_nodisplay();

	override_halt();
	return FALSE;
};

#define STR_EQUIPID_PENTAGRAM "Pentagram of Protection"
void() _pentagram_activate = {
	local entity powerup;

	powerup = override_create(other, "OVERRIDE_PENTAGRAM", OVERPRIO_PENTAGRAM);
	powerup.th_takeitem = _powerup_takeitem;
	powerup.th_takedamage = _pentagram_takedamage;
	powerup.prethink = _powerup_prethink;
	powerup.actthink = _powerup_think;
	powerup.postthink = _powerup_postthink;
	override_finalize(powerup);

	equip_grant(powerup, EQUIPID_PENTAGRAM);
	powerup.items = IT_INVULNERABILITY;
	powerup.effects = EF_RED;
	powerup.attack_finished = time + self.attack_finished;

	powerup.noise = "items/protect2.wav";
	powerup.air_finished = powerup.attack_finished - 3;
};
/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable
*/
void() item_artifact_invulnerability = {
	self.netname = STR_EQUIPID_PENTAGRAM;
	if (!self.model) self.model = "progs/invulner.mdl";
	if (!self.noise2) self.noise2 = "items/protect.wav";
	if (!self.mins && !self.maxs) {
		self.mins = '-16 -16 -24';
		self.maxs = '16 16 32';
	}
	if (!self.attack_finished) self.attack_finished = 30;
	if (!self.wait && !self.delay) {
		self.wait = 60;
		self.delay = 10;
	}
	if (!self.effects) self.effects = EF_RED;

	precache_sound("items/protect3.wav");
	precache_sound("items/protect2.wav");

	equip_grant(self, EQUIPID_PENTAGRAM);
	self.th_activate = _pentagram_activate;

	item_generic();
};

// ===================================================================== //

void() _ring_prethink = {
	local entity powerup;
	powerup = override_findself();

	if (powerup_check_remove(powerup)) {
		mdl_setup_player();
		powerup_remove(powerup);
	}

	if (powerup.prethink)
		powerup.prethink();
};

void() _ring_think = {
	local entity powerup;
	powerup = override_findself();

	if (time > powerup.pain_finished) {
		sound(self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
		powerup.pain_finished = time + 1 + (random() * 3);
	}

	if (time > powerup.attack_finished) {
		mdl_setup_player();
		powerup_remove(powerup);
	} else if (time >= powerup.air_finished) {
		if (is_cl(self))
			stuffcmd(self, "bf\n");

		if (powerup.noise) {
			sound(self, CHAN_AUTO, powerup.noise, 1, ATTN_NORM);
			powerup.noise = nil;
		}

		powerup.air_finished += 1;
	}

	if (powerup.actthink)
		powerup.actthink();
};

#define STR_EQUIPID_RING "Ring of Shadows"
void() _ring_activate = {
	local entity powerup, oldself;

	powerup = override_create(other, "OVERRIDE_RING", OVERPRIO_RING);
	powerup.th_takeitem = _powerup_takeitem;
	powerup.prethink = _ring_prethink;
	powerup.actthink = _ring_think;
	powerup.postthink = _powerup_postthink;
	override_finalize(powerup);

	equip_grant(powerup, EQUIPID_RING);
	powerup.items = IT_INVISIBILITY;
	powerup.attack_finished = time + self.attack_finished;

	powerup.noise = "items/inv2.wav";
	powerup.air_finished = powerup.attack_finished - 3;

	oldself = self;
	self = other;
	mdl_setup_eyes();
	self = oldself;
};
/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is eyes model
*/
void() item_artifact_invisibility = {
	self.netname = STR_EQUIPID_RING;
	if (!self.model) self.model = "progs/invisibl.mdl";
	if (!self.noise2) self.noise2 = "items/inv1.wav";
	if (!self.mins && !self.maxs) {
		self.mins = '-16 -16 -24';
		self.maxs = '16 16 32';
	}
	if (!self.attack_finished) self.attack_finished = 30;
	if (!self.wait && !self.delay) {
		self.wait = 60;
		self.delay = 10;
	}

	precache_sound("items/inv3.wav");
	precache_sound("items/inv2.wav");

	equip_grant(self, EQUIPID_RING);
	self.th_activate = _ring_activate;

	item_generic();
};

// ===================================================================== //

float() _megahealth_takeitem = {
	local entity powerup;
	powerup = override_findself();

	if ((powerup.itemfield_1 & other.itemfield_1)
	 || (powerup.itemfield_2 & other.itemfield_2)
	 || (powerup.itemfield_3 & other.itemfield_3)
	 || (powerup.itemfield_4 & other.itemfield_4)) {
		if (self.health < (self.max_health*2.5)) {
			/* Act like we don't have it, to renew.. */
			powerup_remove(powerup);
		}
	}
	
	if (powerup.th_takeitem)
		return powerup.th_takeitem();
	return FALSE;
};

void() _megahealth_think = {
	local entity powerup;
	powerup = override_findself();

	if (self.health <= self.max_health) {
		powerup_remove(powerup);
	} else if (time >= powerup.attack_finished) {
		self.health -= 0.1;
		if (self.health <= self.max_health) {
			self.health = self.max_health;
			powerup_remove(powerup);
		}
	}

	if (powerup.actthink)
		powerup.actthink();
};

#define STR_EQUIPID_MEGAHEALTH "Megahealth"
void() _megahealth_activate = {
	local entity powerup;

	powerup = override_create(other, "OVERRIDE_MEGAHEALTH", OVERPRIO_MEGAHEALTH);
	powerup.th_takeitem = _megahealth_takeitem;
	powerup.prethink = _powerup_prethink;
	powerup.actthink = _megahealth_think;
	powerup.postthink = _powerup_postthink;
	override_finalize(powerup);

	equip_grant(powerup, EQUIPID_MEGAHEALTH);
	powerup.attack_finished = time + 3;

	other.health += self.attack_finished;
	if (other.health > (other.max_health*2.5))
		other.health = other.max_health*2.5;
};
/*
*/
void() item_megahealth = {
	if (!self.model) self.model = "maps/b_bh100.bsp";
	if (!self.noise2) self.noise2 = "items/r_item2.wav";
	if (!self.mins && !self.maxs) {
		self.mins = '0 0 0';
		self.maxs = '32 32 56';
	}
	if (!self.wait && !self.delay) {
		self.wait = 30;
		self.delay = 40;
	}

	if (!self.attack_finished) self.attack_finished = 100;

	equip_grant(self, EQUIPID_MEGAHEALTH);
	self.th_activate = _megahealth_activate;

	item_generic();
};
