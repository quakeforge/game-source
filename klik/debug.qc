#include "common.qh"
#include "debug.qh"

void() debug_impulse = {
	local float imp;

	imp = self.impulse;
	self.impulse = 0;

	{
		self.impulse = imp;
	}
};
