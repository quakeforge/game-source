#include "common.qh"
#include "menu.qh"

.float menu_state;
.float menu_time;
.void() menu_think;

void(void() menu_func) menu_set = {
	self.menu_state = 0;
	self.menu_time = 0;
	self.menu_think = menu_func;
};

float() util_menu_needs_print = {
	if (time > self.menu_time) {
		self.menu_time = time + 1.4;
		return TRUE;
	}
	
	return FALSE;
};
