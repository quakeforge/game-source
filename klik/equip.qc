#include "common.qh"
#include "equip.qh"
#include "math.qh"

.float equip_state;

..float itemfield;
.float itemfield_1;
.float itemfield_2;
.float itemfield_3;
.float itemfield_4;

float(entity e, float eid) equip_flag = {
	if (eid < 24) {
		e.itemfield = itemfield_1;
	} else if (eid < 48) {
		e.itemfield = itemfield_2;
		eid -= 24;
	} else if (eid < 72) {
		e.itemfield = itemfield_3;
		eid -= 48;
	} else if (eid < 96) {
		e.itemfield = itemfield_4;
		eid -= 72;
	}

	return shl(1, eid);	/* FIXME: use (1 << eid) when the compiler isn't b0rk */
};

float(entity e, float eid) equip_query = {
	eid = equip_flag(e, eid);

	if (e.(e.itemfield) & eid)
		return TRUE;
	else
		return FALSE;
};

float(entity e, float eid) equip_grant = {
	eid = equip_flag(e, eid);

	if (e.(e.itemfield) & eid)
		return FALSE;

	e.(e.itemfield) |= eid;

	return TRUE;
};

float(entity e, float eid) equip_remove = {
	eid = equip_flag(e, eid);

	if (e.(e.itemfield) & eid) {
		e.(e.itemfield) -= eid;
		return TRUE;
	}

	return FALSE;
};

float _equip_iter_id;
/* Returns EQUIPID_* or -1 when done */
float(entity iteme) equip_iter = {
	local float ret, flag;

	while (1) {
		if (_equip_iter_id >= EQUIPID_LAST) {
			_equip_iter_id = 0;
			return -1;
		}

		flag = equip_flag(iteme, _equip_iter_id);

		ret = _equip_iter_id;
		_equip_iter_id++;

		if (iteme.(iteme.itemfield) & flag)
			return ret;
	}

	return -1;	/* Keep compiler from complaining */
};
