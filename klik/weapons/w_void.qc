#include "common.qh"
#include "weapon.qh"

/* WEAPON 0 void */
float(float action)
w_void = {
	if (action == WEAPON_AMMO) {
		return 0;
	} else if (action == WEAPON_WEIGHT) {
		return -10000;
	} else if (action == WEAPON_SELECTABLE) {
		return 1;
	} else if (action == WEAPON_SELECT) {
		self.weaponmodel = "";
		self.weaponframe = 0;
		self.mdl_mod &= ~MDL_MOD_WEP_MASK;
	}
	/* FIRE and INIT don't do a darn thing */

	return 0;
};
