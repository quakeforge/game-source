#include "act.qh"

#include "common.qh"

#include "items.qh"
#include "damage.qh"
#include "misc.qh"
#include "teleport.qh"

#include "override.qh"

.entity overrider, overrider_self;
.float overrider_priority;

// ===================================================================== //

/* Let's make my life simpler when I add new ones, mmmkay? */
#define all_funcs()								\
	one_func(float(), f_v, th_takeitem, (), return, FALSE);			\
										\
	one_func(void(entity missile), v_e, th_attack, (missile), , );		\
										\
	one_func(float(float dmg), f_f, th_takedamage, (dmg), return, FALSE);	\
	one_func(float(float dmg), f_f, th_dealdamage, (dmg), return, dmg);	\
										\
	one_func(void(), v_v, th_die, (), , );					\
	one_func(void(), v_v, th_kill, (), , );					\
										\
	one_func(void(), v_v, prethink, (), , );				\
	one_func(void(), v_v, actthink, (), , );				\
	one_func(void(), v_v, postthink, (), , );				\
										\
	one_func(float(vector org), f_c, th_teleport, (org), return, TRUE);	\
										\
	one_func(float(entity missile), f_e, th_projectile, (missile), return, TRUE)


#define all_types()								\
	one_type(void(), v_v);							\
	one_type(float(), f_v);							\
	one_type(void(entity ent), v_e);					\
	one_type(float(float flt), f_f);					\
	one_type(float(vector vec), f_c);					\
	one_type(float(entity ent), f_e)

// ===================================================================== //

/* default passthru functions */
#define one_func(type1,type2,func,args,return,val)	\
type1 _passthru_##func = {				\
	local entity ovr;				\
	ovr = override_findself();			\
	if (ovr.func)					\
		return ovr.func args;			\
	return val;					\
}

all_funcs();

#undef one_func

/* for the override_set_FUNCTION macros in override.qh */
#define one_type(type1,type2)						\
	void(entity e, .type1 fld, type1 func) override_set_##type2 = {\
		if (e.overrider)					\
			e.overrider.fld = func;				\
		else							\
			e.fld = func;					\
	}

all_types();

#undef one_type

// ===================================================================== //

void(entity e1, entity e2) _override_swap = {
#define one_type(type1,type2)		local type1 t_##type2
	all_types();
#undef one_type

	/* Swap all the functions */
#define one_func(type1,type2,func,args,return,val)	\
		t_##type2 = e1.func;			\
		e1.func = e2.func;			\
		e2.func = t_##type2

	all_funcs();

#undef one_func
};

// ===================================================================== //

entity(entity e, string override_class, float priority) override_create = {
	local entity ovr, ovr2;

	for (ovr = e.overrider; ovr; ovr = ovr.overrider) {
		if (ovr.classname == override_class) {
			ovr2 = ovr.overrider;
			if (!ovr2) ovr2 = e;
			_override_swap(ovr, ovr2);
			return ovr;
		}
	}

	/* Move to the tail.. */
	for (ovr = e; ovr.overrider; ovr = ovr.overrider) {
		if (ovr.overrider.overrider_priority > priority)
			break;
	}

	ovr2 = ovr.overrider;
	ovr.overrider = spawn(override_class);
	ovr.overrider.owner = ovr;
	ovr.overrider.overrider = ovr2;
	if (ovr2) ovr2.owner = ovr.overrider;

	if (!ovr2) ovr2 = e;

	ovr = ovr.overrider;
	ovr.overrider_priority = priority;
	ovr.goalentity = ovr2;

	/* Set default passthru funcs for ovr */
#define one_func(type1,type2,func,args,return,val)	\
		ovr.func = _passthru_##func

	all_funcs();

#undef one_func

	return ovr;
};

void(entity ovr) override_finalize = {
	_override_swap(ovr, ovr.goalentity);
};

entity() override_findself = {
	local entity ovrself;

	ovrself = self.overrider_self;
	if (!ovrself) {
		/* Move to the end of the list */
		for (ovrself = self.overrider; ovrself.overrider; ovrself = ovrself.overrider) ;
	}

	self.overrider_self = ovrself.owner;
	if (self.overrider_self == self)
		self.overrider_self = world;
	
	return ovrself;
};

void() override_halt = {
	self.overrider_self = world;
};

void(entity e, entity ovr) override_destroy = {
	local entity ovr2;

	ovr2 = ovr.overrider;
	if (!ovr2) ovr2 = e;

	/* Copy the funcs from ovr to ovr2 */
#define one_func(type1,type2,func,args,return,val)	\
		ovr2.func = ovr.func

	all_funcs();

#undef one_func

	if (ovr.overrider) ovr.overrider.owner = ovr.owner;
	ovr.owner.overrider = ovr.overrider;

	ovr.think = SUB_remove;
	ovr.nextthink = time;
};
