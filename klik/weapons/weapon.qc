#include "common.qh"

#include "weapon.qh"

.float weapon_imp;
.float weapons;		/* Alas, a bitfield. */

void() weapon_init = {
	weapon_init_weapons();
};

void() weapon_player_init = {
	self.weapons = 0;
	self.weapon_imp = 0;

	weapon_select_by_impulse(0);
};

float(float ex) exp2 = {
	local float n;

	n = 1;

	if (ex >= 0) {
		while (ex-- > 0)
			n *= 2;
	} else {
		while (ex++ < 0)
			n *= 0.5;
	}
	
	return n;
};

float() weapon_player_parm1 = {
	local float parm, ex;

	/* upper 19 bits of mantissa is self.weapons & 0x007fffe0 */
	/* sign is self.weapons & 0x00800000 */
	/* 8 bits of exponent is signed self.weapons & 0x1f */
	/* lower 4 bits of mantissa is (self.weapon_imp << 1) + 1 */

	parm = self.weapons & 8388576;	/* 0x007fffe0 */
	parm |= self.weapon_imp*2 + 1;

	ex = floor(self.weapons & 31);	/* 0x1f */
	if (ex >= 16) ex -= 16;

	parm *= exp2(ex);

	if (parm & 8388608)	/* 0x800000 */
		parm = -parm;

	return parm;
};

float() weapon_player_parm1_default = {
	return 1;	/* weapons 0x000000 weapon_imp 0 */
};

void(float parm) weapon_player_parm1_decode = {
	local float ex, imp, topbit;

	if (parm < 0) {
		topbit = 8388608; /* 0x800000 */
		parm = -parm;
	} else {
		topbit = 0;
	}

	/* Hooo boy.  This is the slow way. */
	ex = 0;
	if (floor(parm) != parm) {
		/* Negative exponent */
		while (floor(parm) != parm) {
			parm *= 2;
			ex--;
		}

		ex += 8;
	} else {
		local float nparm;

		/* Positive exponent */
		nparm = parm * 0.5;
		while (floor(nparm) == nparm) {
			parm = nparm;
			nparm *= 0.5;
			ex++;

			if (ex == 127)
				break;
		}
	}

	self.weapons = topbit | (parm & 8388576) | ex;	/* 0x007fffe0 */
	imp = floor((parm & 31) * 0.5);		/* 0x1f */

	weapon_select_by_impulse(imp);

	if (!self.weapon_imp)
		weapon_select_best();
};

void() _weapon_fire = {
	if (!self.weapon_imp)
		return;

	if (self.w_func(WEAPON_SELECTABLE) <= 0) {
		weapon_select_best();
		if (self.w_func(WEAPON_SELECTABLE) <= 0)
			return;
	}

	self.w_func(WEAPON_FIRE);
};

void() weapon_player_impulse = {
	if (self.attack_finished >= time)
		return;

	if (self.impulse >= 1 && self.impulse <= 8) {
		weapon_select_by_impulse(self.impulse);
		self.impulse = 0;
	}
	
	if (self.button0)
		_weapon_fire();
};

float(float imp) util_impulse_to_IT = {
	if (imp == 1)
		return IT_AXE;
	else if (imp == 2)
		return IT_SHOTGUN;
	else if (imp == 3)
		return IT_SUPER_SHOTGUN;
	else if (imp == 4)
		return IT_NAILGUN;
	else if (imp == 5)
		return IT_SUPER_NAILGUN;
	else if (imp == 6)
		return IT_GRENADE_LAUNCHER;
	else if (imp == 7)
		return IT_ROCKET_LAUNCHER;
	else if (imp == 8)
		return IT_LIGHTNING;
	return 0;
};

void() weapon_set_ammo = {
	self.items &= ~(IT_SHELLS|IT_NAILS|IT_ROCKETS|IT_CELLS);
	if (!self.w_func)
		self.currentammo = 0;
	else
		self.currentammo = self.w_func(WEAPON_AMMO);
};

void(float imp, float idx, float(float action) func) _weapon_select = {
	local float bits, bitmask;

	self.weapon_imp = imp;

	bits = imp*3;
	bitmask = 7*bits;
	bitmask = -bitmask - 1;
	self.weapons &= bitmask;
	self.weapons |= idx*bits;

	self.weapon = util_impulse_to_IT(imp);
	self.w_think = NOTHING_function;
	self.w_func = func;
	self.w_func(WEAPON_SELECT);
};

void(string s) weaponprint = {
	if (is_cl(self))
		centerprint(self, "\[ ", s, " \]\n");
};

float(.float ammo_field, float ammo) util_weapon_use_ammo = {
	if (self.ammo_field < ammo)
		return FALSE;
	self.ammo_field -= ammo;

	return TRUE;
};

float(.float ammo_field, float max_ammo, float ammo) util_weapon_give_ammo = {
	local float ret;

	if (max_ammo > 999) max_ammo = 999;
	ret = increase_field(ammo_field, ammo, max_ammo);

	return ret;
};
