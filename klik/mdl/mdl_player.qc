#include "common.qh"
#include "effect.qh"

#include "misc.qh"

#include "mdl.qh"
#include "mdl_player.qh"

// running
$frame axrun1 axrun2 axrun3 axrun4 axrun5 axrun6

$frame rockrun1 rockrun2 rockrun3 rockrun4 rockrun5 rockrun6


// standing
$frame stand1 stand2 stand3 stand4 stand5

$frame axstnd1 axstnd2 axstnd3 axstnd4 axstnd5 axstnd6
$frame axstnd7 axstnd8 axstnd9 axstnd10 axstnd11 axstnd12


// pain
$frame axpain1 axpain2 axpain3 axpain4 axpain5 axpain6

$frame pain1 pain2 pain3 pain4 pain5 pain6


// death
$frame axdeth1 axdeth2 axdeth3 axdeth4 axdeth5 axdeth6
$frame axdeth7 axdeth8 axdeth9

$frame deatha1 deatha2 deatha3 deatha4 deatha5 deatha6 deatha7 deatha8
$frame deatha9 deatha10 deatha11

$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9

$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11 deathc12 deathc13 deathc14 deathc15

$frame deathd1 deathd2 deathd3 deathd4 deathd5 deathd6 deathd7
$frame deathd8 deathd9

$frame deathe1 deathe2 deathe3 deathe4 deathe5 deathe6 deathe7
$frame deathe8 deathe9


// attacks
$frame nailatt1 nailatt2

$frame light1 light2

$frame rockatt1 rockatt2 rockatt3 rockatt4 rockatt5 rockatt6

$frame shotatt1 shotatt2 shotatt3 shotatt4 shotatt5 shotatt6

$frame axatt1 axatt2 axatt3 axatt4 axatt5 axatt6

$frame axattb1 axattb2 axattb3 axattb4 axattb5 axattb6

$frame axattc1 axattc2 axattc3 axattc4 axattc5 axattc6

$frame axattd1 axattd2 axattd3 axattd4 axattd5 axattd6

void() _mdl_player_axe_walk = {
	self.frame++;
	if (self.frame < $axrun1 || self.frame > $axrun6)
		self.frame = $axrun1;
};

void() _mdl_player_gun_walk = {
	self.frame++;
	if (self.frame < $rockrun1 || self.frame > $rockrun6)
		self.frame = $rockrun1;
};

void() _mdl_player_axe_idle = {
	self.frame++;
	if (self.frame < $axstnd1 || self.frame > $axstnd12)
		self.frame = $axstnd1;
};

void() _mdl_player_gun_idle = {
	self.frame++;
	if (self.frame < $stand1 || self.frame > $stand5)
		self.frame = $stand1;
};

void() mdl_player_idle =
{
	self.mdl_think = mdl_player_idle;

	if ((self.flags & FL_ONGROUND) && (self.velocity_x || self.velocity_y)) {
		if ((self.mdl_mod&MDL_MOD_WEP_MASK) == MDL_MOD_WEP_AXE)
			_mdl_player_axe_walk();
		else	_mdl_player_gun_walk();
	} else {
		if ((self.mdl_mod&MDL_MOD_WEP_MASK) == MDL_MOD_WEP_AXE)
			_mdl_player_axe_idle();
		else	_mdl_player_gun_idle();
	}
	
	self.mdl_thought = TRUE;
};

void() _mdl_player_axe_pain = {
	self.frame++;
	if (self.frame < $axpain1 || self.frame > $axpain6)
		mdl_player_idle();
};

void() _mdl_player_gun_pain = {
	self.frame++;
	if (self.frame < $pain1 || self.frame > $pain6)
		mdl_player_idle();
};

void(float d) mdl_player_pain = {
	local vector impact_dir;

	if (time < self.mdl_var)
		return;
	self.mdl_var = time + 0.2;

	impact_dir = '0 0 0' - self.dmg_inflictor.velocity;
	impact_dir = normalize(impact_dir);
	effect_blood(self.origin, impact_dir, d);

	if (self.mdl_think != mdl_player_idle)
		return;

	if ((self.mdl_mod&MDL_MOD_WEP_MASK) == MDL_MOD_WEP_AXE) {
		self.frame = $axpain1;
		self.mdl_think = _mdl_player_axe_pain;
	} else {
		self.frame = $pain1;
		self.mdl_think = _mdl_player_gun_pain;
	}
	
	self.mdl_thought = TRUE;
};

void() _mdl_player_death = {
	self.frame++;
	if (self.frame >= self.count) {
		self.mdl_think = NOTHING_function;
		return;
	}
};

void(float type) mdl_player_die = {
	self.angles_x = 0;
	self.angles_z = 0;

	self.avelocity_x = 0;
	self.avelocity_z = 0;

	if ((self.mdl_mod&MDL_MOD_WEP_MASK) == MDL_MOD_WEP_AXE) {
		self.frame = $axdeth1; self.count = $axdeth9;
		setsize(self, VEC_HULL_MIN, '16 16 0');
	} else {
		if (type == 0) {
			self.frame = $deatha1; self.count = $deatha11;
			setsize(self, VEC_HULL_MIN, '16 16 -12');
		} else if (type == 1) {
			self.frame = $deathb1; self.count = $deathb9;
			setsize(self, VEC_HULL_MIN, '16 16 0');
		} else if (type == 2) {
			self.frame = $deathc1; self.count = $deathc15;
			setsize(self, VEC_HULL_MIN, '16 16 -12');
		} else if (type == 3) {
			self.frame = $deathd1; self.count = $deathd9;
			setsize(self, VEC_HULL_MIN, '16 16 -12');
		} else {
			self.frame = $deathe1; self.count = $deathe9;
			setsize(self, VEC_HULL_MIN, '16 16 18');
		}
	}

	self.mdl_think = _mdl_player_death;
	self.mdl_thought = TRUE;
};

/* Rocket, grenade launcher, etc */
void() _mdl_player_fire = {
	self.frame++;
	if (self.frame < $rockatt1 || self.frame > $rockatt6)
		mdl_player_idle();
};

void() mdl_player_fire = {
	self.frame = $rockatt1;
	self.mdl_think = _mdl_player_fire;
	effect_muzzleflash();
	self.mdl_thought = TRUE;
};

/* shotgun, super shotgun. */
void() _mdl_player_fire_shotgun = {
	self.frame++;
	if (self.frame < $shotatt1 || self.frame > $shotatt6)
		mdl_player_idle();
};

void() mdl_player_fire_shotgun = {
	self.frame = $shotatt1;
	self.mdl_think = _mdl_player_fire_shotgun;
	effect_muzzleflash();
	self.mdl_thought = TRUE;
};

/* lightning gun */
void() _mdl_player_fire_lightning = {
	self.frame++;
	if (self.frame < $light1 || self.frame > $light2)
		self.frame = $light1;
	effect_muzzleflash();
};

void() mdl_player_fire_lightning = {
	self.frame = $light1;
	self.mdl_think = _mdl_player_fire_lightning;
	effect_muzzleflash();
	self.mdl_thought = TRUE;
};

/* nailgun, super nailgun */
void() _mdl_player_fire_nail = {
	self.frame++;
	if (self.frame < $nailatt1 || self.frame > $nailatt2)
		self.frame = $nailatt1;
};

void() mdl_player_fire_nail = {
	self.frame = $nailatt2;
	self.mdl_think = _mdl_player_fire_nail;
	self.mdl_think();
	effect_muzzleflash();
	self.mdl_thought = TRUE;
};

/* Axe */
void() _mdl_player_fire_axe_a = {
	self.frame++;
	if (self.frame < $axatt1 || self.frame > $axatt4)
		mdl_player_idle();
};

void() _mdl_player_fire_axe_b = {
	self.frame++;
	if (self.frame < $axattb1 || self.frame > $axattb4)
		mdl_player_idle();
};

void() _mdl_player_fire_axe_c = {
	self.frame++;
	if (self.frame < $axattc1 || self.frame > $axattc4)
		mdl_player_idle();
};

void() _mdl_player_fire_axe_d = {
	self.frame++;
	if (self.frame < $axattd1 || self.frame > $axattd4)
		mdl_player_idle();
};

void() mdl_player_fire_axe = {
	local float r;
	
	r = random();
	if (r < 0.25) {
		self.frame = $axatt1;
		self.mdl_think = _mdl_player_fire_axe_a;
	} else if (r < 0.5) {
		self.frame = $axattb1;
		self.mdl_think = _mdl_player_fire_axe_b;
	} else if (r < 0.75) {
		self.frame = $axattc1;
		self.mdl_think = _mdl_player_fire_axe_c;
	} else {
		self.frame = $axattd1;
		self.mdl_think = _mdl_player_fire_axe_d;
	}
	
	self.mdl_think();
	self.mdl_thought = 1;
};

/* :) */
void() mdl_player_gib = {
	local entity gib;
	local float r, gibs, velmag;
	local vector vel, giborg;

	velmag = vlen(self.velocity);
	if (velmag == 0)
		vel = '0 0 1';
	else	vel = self.velocity * (1/velmag);
	if (velmag < 200) velmag = 200;
	if (vel == '0 0 0')
		vel = '0 0 1';

	self.mass /= 6;

	gibs = 5 + crandom()*1;
	giborg = center(self);
	while (gibs-- > 0) {
		gib = spawn("PLAYER_GIB");

		gib.solid = SOLID_NOT;
		gib.movetype = MOVETYPE_BOUNCE;

		gib.mass = self.mass;

		gib.avelocity_x = crandom()*300;
		gib.avelocity_y = crandom()*300;
		gib.avelocity_z = crandom()*300;

		gib.velocity_x = vel_x + crandom()*0.2;
		gib.velocity_y = vel_y + crandom()*0.2;
		gib.velocity_z = vel_z + crandom()*0.2;
		gib.velocity = normalize(gib.velocity) * velmag;

		r = random()*3;
		if (r < 1)		gib.model = "progs/gib1.mdl";
		else if (r < 2)		gib.model = "progs/gib2.mdl";
		else			gib.model = "progs/gib3.mdl";

		setsize(gib, '0 0 0', '0 0 0');
		setmodel(gib, gib.model);
		setorigin(gib, giborg);

		gib.think = SUB_remove;
		gib.nextthink = time + 5 + random()*10;
	}

	self.avelocity = '0 0 0';
	self.angles_x = random()*360;
	self.angles_y = random()*360;
	self.angles_z = random()*360;

	self.velocity_x = vel_x + crandom()*0.1;
	self.velocity_y = vel_y + crandom()*0.1;
	self.velocity_z = vel_z + crandom()*0.1;
	self.velocity = normalize(self.velocity) * velmag;

	setsize(self, '0 0 0', '0 0 0');
	setmodel(self, "progs/h_player.mdl");
	setorigin(self, self.origin + self.view_ofs);
	self.view_ofs = '0 0 0';

	self.mdl_think = NOTHING_function;
	self.mdl_func = mdl_func_void;
};

void() mdl_player_init = {
	precache_model("progs/player.mdl");
	precache_model("progs/h_player.mdl");

	precache_model("progs/gib1.mdl");
	precache_model("progs/gib2.mdl");
	precache_model("progs/gib3.mdl");
};

void(float func, float extra) mdl_func_player = {
	if (func == MDL_FUNC_IDLE)		mdl_player_idle();
	else if (func == MDL_FUNC_JUMP)		{ extra = 0; }
	else if (func == MDL_FUNC_PAIN)		mdl_player_pain(extra);
	else if (func == MDL_FUNC_FIRE) {
		local float wmod;

		wmod = self.mdl_mod & MDL_MOD_WEP_MASK;

		if (wmod == MDL_MOD_WEP_AXE)			mdl_player_fire_axe();
		else if (wmod == MDL_MOD_WEP_SHOTGUN)		mdl_player_fire_shotgun();
		else if (wmod == MDL_MOD_WEP_SUPER_SHOTGUN)	mdl_player_fire_shotgun();
		else if (wmod == MDL_MOD_WEP_NAILGUN)		mdl_player_fire_nail();
		else if (wmod == MDL_MOD_WEP_SUPER_NAILGUN)	mdl_player_fire_nail();
		else if (wmod == MDL_MOD_WEP_GRENADE_LAUNCHER)	mdl_player_fire();
		else if (wmod == MDL_MOD_WEP_ROCKET_LAUNCHER)	mdl_player_fire();
		else if (wmod == MDL_MOD_WEP_LIGHTNING_GUN)	mdl_player_fire_lightning();
		else						mdl_player_fire();
	}
	else if (func == MDL_FUNC_DIE)		mdl_player_die(extra);
	else if (func == MDL_FUNC_GIB)		mdl_player_gib();
	else					mdl_player_idle();
};

void() mdl_setup_player = {
	self.model = "progs/player.mdl";
	setmodel(self, self.model);
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';

	self.mdl_func = mdl_func_player;
	self.mdl_func(MDL_FUNC_IDLE, 0);
	self.mdl_var = 0;
};
