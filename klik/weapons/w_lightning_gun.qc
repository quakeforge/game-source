#include "common.qh"

#include "weapon.qh"
#include "equip.qh"
#include "damage.qh"
#include "misc.qh"
#include "effect.qh"

#define STR_EQUIPID_LIGHTNING_GUN	"Lightning Gun"

void() _deathmsg_shaft = {
	local string def_name, att_name;
	local float r;

	def_name = name(self);
	att_name = name(self.dmg_attacker);

	r = random()*4;
	if (r < 1)	bprint(PRINT_DEATH, def_name, " accepts ", att_name, "'s shaft.\n");
	else if (r < 2)	bprint(PRINT_DEATH, att_name, " gives ", def_name, " the shaft.\n");
	else if (r < 3)	bprint(PRINT_DEATH, def_name, " got smitten by ", att_name, ".\n");
	else		bprint(PRINT_DEATH, att_name, " fries up some ", def_name, " bacon.\n");
};

void() _deathmsg_discharge = {
	local string def_name, att_name;
	local float r;

	def_name = name(self);
	att_name = name(self.dmg_attacker);

	if (self.dmg_attacker == self) {
		r = random()*2;
		if (r < 1)	bprint(PRINT_DEATH, def_name, " conducts electricity.\n");
		else		bprint(PRINT_DEATH, def_name, " tries to become a lightbulb.\n");
	} else {
		r = random()*3;
		if (r < 1)	bprint(PRINT_DEATH, def_name, " accepts ", att_name, "'s discharge.\n");
		else if (r < 2)	bprint(PRINT_DEATH, att_name, " sends ", def_name, " a jolt.\n");
		else		bprint(PRINT_DEATH, def_name, " conducts electricity with ", att_name, ".\n");
	}
};

void(vector p1, vector p2, float d) _w_lightning_gun_trace_damage =
{
	local entity            e1, e2;
	local vector            f;


	f = p2 - p1;
	f = normalize (f);
	f_y = f_x = -f_y;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	ghost_inflictor.classname = "LIGHTNING";
	ghost_inflictor.dmg = d;
	ghost_inflictor.mass = ghost_inflictor.dmg * 8;
	ghost_inflictor.velocity = v_forward * 1000;

	damage_attack(ghost_inflictor);

	traceline (p1, p2, FALSE, self);
	e1 = trace_ent;
	damage(trace_ent, self, ghost_inflictor, ghost_inflictor.dmg, _deathmsg_shaft);

	traceline (p1 + f, p2 + f, FALSE, self);
	e2 = trace_ent;
	if (trace_ent != e1)
		damage(trace_ent, self, ghost_inflictor, ghost_inflictor.dmg, _deathmsg_shaft);

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2)
		damage(trace_ent, self, ghost_inflictor, ghost_inflictor.dmg, _deathmsg_shaft);
};


void(entity ignore, entity attacker, entity inflictor, void() deathmessage)
damage_radius_lightning = {
	local entity head;
	local vector iorg, org;
	local float points;
	local float d, m, r;
	local float cont;

	d = inflictor.dmg;
	m = inflictor.mass;
	r = inflictor.lip;

	iorg = center(inflictor);

	for (head = findradius(iorg, r + 40); head; head = head.chain) {
		if (head == ignore)
			continue;

		if (!_damage_radius_can_hit(iorg, head))
			continue;

		cont = pointcontents(trace_endpos);
		if (cont < CONTENT_LAVA || cont > CONTENT_WATER)
			continue;

		org = center(head);

		points = r - (0.5 * vlen(iorg - org));
		if (points <= 0)
			continue;

		inflictor.dmg = (points * d) / r;
		inflictor.mass = (points * m) / r;
		damage(head, attacker, inflictor, inflictor.dmg, deathmessage);
	}
};

void() _w_lightning_gun_beam =
{
	local   vector          org;
	local   float           cells;

	org = shootorigin(self);

// explode if under water
	if (self.waterlevel > 1)
	{
		self.mdl_func(MDL_FUNC_IDLE, 0);

		cells = self.ammo_cells;
		self.ammo_cells = 0;

		ghost_inflictor.classname = "DISCHARGE";
		ghost_inflictor.origin = self.origin;
		ghost_inflictor.velocity = '0 0 0';
		ghost_inflictor.dmg = 35*cells;
		ghost_inflictor.mass = ghost_inflictor.dmg * 8;
		ghost_inflictor.lip = ghost_inflictor.dmg;
		ghost_inflictor.speed = 1000;

		damage_radius_lightning(world, self, ghost_inflictor, _deathmsg_discharge);
		return;
	}

	if (self.t_width < time) {
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}

	makevectors(self.v_angle);
	
	traceline (org, org + v_forward*600, TRUE, self);

	effect_lightning2(self, org, trace_endpos);
	effect_smallkick(self);

	_w_lightning_gun_trace_damage(self.origin, trace_endpos, 30);
};

//============================================================================

void() _w_lightning_gun_think = {
	self.weaponframe++;

	if (self.weaponframe == 5)
		self.weaponframe = 1;

	/* FIXME: Use short circuit logic here when compiler supports */
	if (!self.button0 || self.impulse || self.weaponframe < 1 || self.weaponframe > 5) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
		self.mdl_func(MDL_FUNC_IDLE, 0);
		return;
	}

	if (!util_weapon_use_ammo(ammo_cells, 1)) {
		self.weaponframe = 0;
		self.w_think = NOTHING_function;
		self.mdl_func(MDL_FUNC_IDLE, 0);
		return;
	}

	_w_lightning_gun_beam();
	
	self.attack_finished = time + 0.2;
};

/* WEAPON 8 lightning_gun */
float(float action)
w_lightning_gun = {
	if (action == WEAPON_AMMO) {
		self.items |= IT_CELLS;
		return self.ammo_cells;
	} else if (action == WEAPON_WEIGHT) {
		local vector point;
		local float cont;

		point = self.origin;
		point_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		cont = pointcontents(point);
		if (cont >= CONTENT_LAVA && cont <= CONTENT_WATER)
			return -60;

		return 60;
	} else if (action == WEAPON_SELECTABLE) {
		if (!equip_query(self, EQUIPID_LIGHTNING_GUN))
			return 0;
		if (self.ammo_cells >= 1)
			return 1;
		return -1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.mdl_mod = (self.mdl_mod & ~MDL_MOD_WEP_MASK) | MDL_MOD_WEP_LIGHTNING_GUN;
		
		weaponprint(STR_EQUIPID_LIGHTNING_GUN);
	} else if (action == WEAPON_FIRE) {
		sound(self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
		self.w_think = _w_lightning_gun_think;
		self.w_think();
		self.w_thought = TRUE;
	} else if (action == WEAPON_INIT) {
		precache_model("progs/v_light.mdl");
		precache_sound("weapons/lstart.wav");
		precache_sound("weapons/lhit.wav");
	}
	
	return 0;
};
