#include "common.qh"

#include "mdl.qh"
#include "mdl_void.qh"

void() mdl_setup_void = {
	self.modelindex = 0;	/* Don't use setmodel */
	setsize(self, '0 0 0', '0 0 0');
	self.view_ofs = '0 0 0';

	self.mdl_func = mdl_func_void;
	self.mdl_think = NOTHING_function;
};
