#include "client.qh"
#include "common.qh"
#include "menu.qh"
#include "misc.qh"

/*
void() menu_team = {
	if (team_ischosen(self))
		menu_set(menu_equip);

	if (util_menu_needs_print() && is_cl(self)) {
		centerprint(self,
			"Team\n"
			"\<\-\-\-\-\>\n"
			"1\b.\b Red\n"
			"2\b.\b Blue\n"
			"\n"
			"0\b.\b Auto\n"
		);
	}
	
	if (self.impulse == 1) {
		team_join(TEAM_RED);
	} else if (self.impulse == 2) {
		team_join(TEAM_BLUE);
	} else if (self.impulse == 10 || self.button0 || self.button1 || self.button2) {
		team_join_auto();
	}
	
	self.impulse = 0;
	self.button0 = self.button1 = self.button2 = 0;
};
*/

void() menu_intro = {
	if (!self.menu_state)
		self.menu_state = time + 3;
	else if (time >= self.menu_state) {
		if (is_cl(self))
			centerprint(self, "");
		PutClientInGame();
		return;
	}

	if (util_menu_needs_print()) {
		if (is_cl(self))
		centerprint(self,
			"\[ This server is running Klik 0.0.7 \]\n"
			"\[          by Zinx Verituse         \]\n"
			"\[  http://staff.xmms.org/zinx/klik  \]\n"
			"\n"
			"\<[ It's a Quake World. ]\>\n"
		);
	}	
};
