#include "common.qh"
#include "misc.qh"
#include "act.qh"
#include "server.qh"
#include "menu.qh"
#include "mdl.qh"
#include "weapon.qh"

void() PlayerPreThink = {
	if (is_cl(self))
		PlayerStartFrame();

	if (self.prethink)
		self.prethink();
};

void() act_think = {
	if (!is_autothink(self)) {
		frametime = 0.1;
		PlayerPreThink();
	}

	/*if (0.1 seconds have passed) {*/
		if (self.actthink)
			self.actthink();

		if (self.menu_think)
			self.menu_think();

		if (self.mdl_think && !self.mdl_thought)
			self.mdl_think();
		self.mdl_thought = FALSE;

		if (self.w_think && !self.w_thought)
			self.w_think();
		self.w_thought = FALSE;
	/*}*/

	self.nextthink = time + 0.1;	/* FIXME: Use sv_mintic here when non-client? */

	if (!is_autothink(self))
		PlayerPostThink();
};

void() PlayerPostThink = {
	if (self.postthink)
		self.postthink();

	if (is_cl(self))
		PlayerEndFrame();
};

void() act_setup = {
	self.think = act_think;
	self.nextthink = time;
};
