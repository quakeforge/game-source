#include "common.qh"

#include "bodyque.qh"
#include "mdl.qh"

.void(float func, float extra) mdl_func;
.float mdl_mod;

.void() mdl_think;
.float mdl_thought;
.float mdl_var;

void() _mdl_bodyque_think = {
	if (!self.mdl_thought)	self.mdl_think();
	self.mdl_thought = FALSE;

	self.nextthink = time + 0.1;
};

entity(float func, float extra) mdl_bodyque_and_func = {
	local entity stemp, ret;

	stemp = self;
	ret = self = bodyque_que(self);
	if (self.mdl_func)
		self.mdl_func(func, extra);
	self = stemp;

	return ret;
};

void(float func, float extra) mdl_func_void = {};
