#include "common.qh"

#include "mdl.qh"
#include "mdl_eyes.qh"

void() mdl_setup_eyes = {
	setmodel(self, "progs/eyes.mdl");
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);

	self.view_ofs = '0 0 22';

	self.mdl_func = mdl_func_void;
	self.mdl_think = NOTHING_function;
};

void() mdl_eyes_init = {
	precache_model("progs/eyes.mdl");
};
