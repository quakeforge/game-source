#include "common.qh"
#include "server.qh"
#include "weapon.qh"
#include "misc.qh"

#include "mapents_util.qh"
#include "damage.qh"

#include "mapents_movewall.qh"

/* movewalls!  The replacement for doors/plats/trains. */
/* Internally:
	when used:

	a movewall will start to go self.goalentity.pos2, at
	self.goalentity.speed.  You may change pos2 when the
	state event occurs.

	self.state will reflect the current state, the first state
	being 0, between the first and second being 0.5, and
	increasing to 1 once it reaches the second.  it will increase
	the same way until it reaches the first goalentity, which is 0.
	states are in the goalentity's .style

	self.goalentity will be set to self.goalentity.goalentity

	a state event will occur.
	(state events are triggered by calling self.w_think, if it exists.)

	after it reaches the position, self.state will reflect the
	self.goalentity.style of the new position, and a state
	event will be triggered.

	-- snip --

	movewalls start with an undefined state (i.e., it will be
	0 if it just spawned and you don't set it)

	You must provide your own self.blocked function.

	You must also provide a means of calling self.use(),
	or rely on it being a target.
*/

void() _deathmsg_squish = {
	bprint (PRINT_DEATH, name(self), " was squished.\n");
};

.vector finaldest;
void() _move_to_pos_done = {
	self.velocity = '0 0 0';
	setorigin (self, self.finaldest);
	self.nextthink = -1;

	if (self.think1)
		self.think1 ();
};

/* calculate velocity and direction to move to position at spd. */
/* _ONLY_ use this with MOVETYPE_PUSH's! */
void(vector position, float spd, void() think_func) util_move_to_pos = {
	local float		dist;
	local vector	offs;

	self.finaldest = position;
	self.speed = spd;

	offs = position - self.origin;
	dist = vlen (offs);
	offs *= (1/ dist);

	self.velocity = offs * spd;

	self.think1 = think_func;
	self.think = _move_to_pos_done;
	self.nextthink = self.ltime + (dist / spd);

	if (self.nextthink <= self.ltime)
		self.nextthink = self.ltime + sv_mintic;
};

void() _movewall_done = {
	self.state += 0.5;

	if (self.w_think)
		self.w_think ();
};

void() _movewall_use = {
	local float spd;

	if (!self.goalentity) {
		/* Ugh. */
		dprint("Activated unfinalized movewall\n");
		return;
	}

	/* Avoid multiple activations per frame */
	if (self.origin == self.goalentity.pos2)
		return;

	spd = self.goalentity.speed;
	if (!spd)
		spd = self.speed;
	util_move_to_pos (self.goalentity.pos2 - self.view_ofs, spd,
					  _movewall_done);

	self.state = self.goalentity.style - 0.5;
	self.goalentity = self.goalentity.goalentity;

	if (self.w_think)
		self.w_think ();
};

void() movewall_init = {
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.deadflag = DEAD_NONLIVING;

	self.use = _movewall_use;
};

// ========================================================================
/* Two states, no more, no less.  pos2 contains the next position. */
/* Plays self.noise3 when starting to move, and self.noise4 when stopping. */
/* damages blocking entities if self.dmg (per second if it doesn't go back) */
/* when state is 1, waits for self.wait seconds, then activates again. */

void() _movewall_wait_think = {
	if (self.pain_finished <= self.ltime) {
		_movewall_use ();
		return;
	}

	self.nextthink = self.pain_finished;
};

void() _movewall_state0_use = {
	if (self.state != 0)
		return;
	_movewall_use ();
};

void() _movewall_binary_think = {
	if (floor(self.state) != self.state) {
		local vector tmp;

		if (self.noise3)
			sound (self, CHAN_BODY, self.noise3, 1, ATTN_NORM);

		tmp = self.pos2;
		self.pos2 = self.pos1;
		self.pos1 = tmp;
		self.style = 1 - self.style;
	} else {
		if (self.noise4)
			sound (self, CHAN_BODY|CHAN_NO_PHS_ADD, self.noise4, 1, ATTN_NORM);

		if (self.state == 1) {
			self.think = _movewall_wait_think;
			self.nextthink = self.ltime + self.wait;
		}
	}
};

void() _movewall_block_ignore = {
	if (self.dmg)
		damage (other, self, self, self.dmg * frametime, _deathmsg_squish);

	/* recalculate the move.. */
	if (self.nextthink && self.think == _movewall_done)
		util_move_to_pos (self.finaldest, self.speed, self.think1);
};

void() _movewall_block_goback = {
	if (self.dmg)
		damage(other, self, self, self.dmg, _deathmsg_squish);
	_movewall_use();
};

void() _movewall_trigger_touch = {
	self = self.owner;
	self.flags |= FL_JUMPRELEASED;
	self.touch ();
	self.flags &= ~FL_JUMPRELEASED;
};

entity(vector org, vector tmin, vector tmax) _movewall_spawn_trigger = {
	local entity	trigger;

	trigger = spawn ("TRIGGER");

	trigger.solid = SOLID_TRIGGER;
	trigger.movetype = MOVETYPE_NONE;

	trigger.touch = _movewall_trigger_touch;

	trigger.owner = self;

	setsize (trigger, tmin, tmax);
	setorigin (trigger, org);

	return trigger;
};

// ========================================================================

/* doors... state 0 is closed, state 1 is open. */
/* self.owner is the head of a list of linked doors. */
/* self.enemy is the next in the list. */

#define SPAWNFLAGS_DOOR_START_OPEN 1
#define SPAWNFLAGS_DOOR_DONT_LINK 4
#define SPAWNFLAGS_DOOR_GOLD_KEY 8		// legacy
#define SPAWNFLAGS_DOOR_SILVER_KEY 16	// legacy
#define SPAWNFLAGS_DOOR_TOGGLE 32

float(float d) _movewall_door_takedamage = {
	local entity oldself;

	if (self.owner.state != 0) {
		deathmsg_nodisplay ();
		return FALSE;
	}

	oldself = self;
	self = self.owner;

	self.health -= d;

	if (self.health <= 0) {
		self.health = self.max_health;

		while (self) {
			if (util_use_targets ()) {
				self.use ();

				/* Hack for id compat... */
				/* Use target if you need it to go more
				   than once */
				self.message = "";
				self.noise1 = NIL;
				self.noise2 = NIL;
			}

			self = self.enemy;
		}
	}

	self = oldself;

	deathmsg_nodisplay ();
	return FALSE;	// lie
};

void() _movewall_door_touch = {
	local entity	oldself;

	if (!is_living (other))
		return;

	oldself = self;

	self = self.owner;

	if (self.state != 0) {
		while (self) {
			self.pain_finished = self.ltime + self.wait;
			self = self.enemy;
		}
	} else {
		while (self) {
			if (util_use_targets ()) {
				_movewall_use ();

				/* Hack for id compat... */
				/* Use target if you need it to go more
				   than once */
				self.message = "";
				self.noise1 = NIL;
				self.noise2 = NIL;
			}
			self = self.enemy;
		}
	}

	self = oldself;
};

void() _door_link = {
	local entity	head, tail;

	tail = self;
	tail.owner = self;

	head = self;
	while (1) {
		head = find (head, classname, self.classname);
		if (!head)
			break;

		if (head.spawnflags & SPAWNFLAGS_DOOR_DONT_LINK)
			continue;

		if (!util_entities_touch (self, head))
			continue;

		if (head.owner != head)
			objerror ("Crosslinked doors\n");

		tail.enemy = head;
		tail = head;

		tail.nextthink = -1;	// Avoid trying to link again.
		tail.owner = self;

		/* *Sigh*.  Id compat. */
		if (tail.noise1)
			self.noise1 = tail.noise1;
		if (tail.noise2)
			self.noise2 = tail.noise2;
		if (tail.noise3)
			self.noise3 = tail.noise3;
		if (tail.noise4)
			self.noise4 = tail.noise4;
		if (tail.noise5)
			self.noise5 = tail.noise5;
		if (tail.noise6)
			self.noise6 = tail.noise6;
		if (tail.message)
			self.message = tail.message;

		if (tail.health)
			self.health = tail.health;
		if (tail.targetname)
			self.targetname = tail.targetname;

		tail.message = "";

		tail.noise1 = NIL;
		tail.noise2 = NIL;
		tail.noise3 = NIL;
		tail.noise4 = NIL;
		tail.noise5 = NIL;
		tail.noise6 = NIL;
	}

	tail.enemy = world;

	head = self;
	while (self) {
		self.health = head.health;
		self.targetname = head.targetname;

		if (!self.health && !self.targetname) {
			if (!self.items) {
				local vector tmin, tmax;

				tmin = self.mins - '60 60 8';
				tmax = self.maxs + '60 60 8';
				_movewall_spawn_trigger(self.origin, tmin, tmax);
			}

			self.touch = _movewall_door_touch;
		} else {
			if (self.health) {
				self.takedamage = DAMAGE_YES;
				self.th_takedamage = _movewall_door_takedamage;
			}
		}

		self = self.enemy;
	}

	self = head;
};

void() func_door = {
	if (!self.noise5) {
		switch (world.worldtype) {
		case 0:
			self.noise5 = "doors/medtry.wav";
			self.noise6 = "doors/meduse.wav";
			break;
		case 1:
			self.noise5 = "doors/runetry.wav";
			self.noise6 = "doors/runeuse.wav";
			break;
		case 2:
			self.noise5 = "doors/basetry.wav";
			self.noise6 = "doors/baseuse.wav";
			break;
		default:
			break;
		}
	}

	if (!self.noise3) {
		switch (self.sounds) {
		case 1:
			self.noise3 = "doors/doormv1.wav";
			self.noise4 = "doors/drclos4.wav";
			break;
		case 2:
			self.noise3 = "doors/hydro1.wav";
			self.noise4 = "doors/hydro2.wav";
			break;
		case 3:
			self.noise3 = "doors/stndr1.wav";
			self.noise4 = "doors/stndr2.wav";
			break;
		case 4:
			self.noise3 = "doors/ddoor1.wav";
			self.noise4 = "doors/ddoor2.wav";
			break;
		default:
			break;
		}
	}

	if (self.noise3)
		precache_sound(self.noise3);
	if (self.noise4)
		precache_sound(self.noise4);

	if (self.message != "" && !self.noise1 && !self.noise2)
		self.noise2 = "misc/talk.wav";

	if (!self.speed)
		self.speed = 100;
	if (!self.wait)
		self.wait = 3;
	if (!self.lip)
		self.lip = 8;

	if (!self.dmg)
		self.dmg = 2;
	if (self.dmg < 0)
		self.dmg = 0;

	if (self.spawnflags & SPAWNFLAGS_DOOR_SILVER_KEY) {
		self.spawnflags |= SPAWNFLAGS_CHECK_ITEMS;
		self.items |= IT_KEY1;
		self.wait = -1;
	}

	if (self.spawnflags & SPAWNFLAGS_DOOR_GOLD_KEY) {
		self.spawnflags |= SPAWNFLAGS_CHECK_ITEMS;
		self.items |= IT_KEY2;
		self.wait = -1;
	}

	self.max_health = self.health;

	movewall_init ();

	util_map_entity_init ();

	util_set_movedir ();

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir * (fabs (self.movedir * self.size)
											- self.lip);

	if (self.spawnflags & SPAWNFLAGS_DOOR_START_OPEN) {
		setorigin (self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	self.state = 0;
	self.style = 1 - self.state;

	self.touch = NOTHING_function;

	self.goalentity = self;

	self.use = _movewall_door_touch;

	self.blocked = _movewall_block_goback;
	self.w_think = _movewall_binary_think;

	self.owner = self;	// In case we get triggered before 0.1

	self.think = _door_link;
	self.nextthink = self.ltime + 0.1;
};

// ========================================================================

/* plats.. state 0 is the 'top' position, state 1 is 'bottom' */

#define	SPAWNFLAGS_PLAT_LOW_TRIGGER 1

void() _movewall_plat_touch = {
	if (!(self.flags & FL_JUMPRELEASED))
		return;

	_movewall_door_touch ();
};

void() func_plat = {
	local vector tmin, tmax;

	if (!self.noise3) {
		if (self.sounds == 1) {
			self.noise3 = "plats/plat1.wav";
			self.noise4 = "plats/plat2.wav";
		} else if (self.sounds == 0 || self.sounds == 2) {
			self.noise3 = "plats/medplat1.wav";
			self.noise4 = "plats/medplat2.wav";
		}
	}

	if (self.noise3)
		precache_sound(self.noise3);
	if (self.noise4)
		precache_sound(self.noise4);

	if (!self.speed)
		self.speed = 150;
	if (!self.wait)
		self.wait = 1;

	movewall_init ();

	util_map_entity_init ();

	if (!self.height)
		self.height = self.size_z - 8;

	self.pos1 = self.origin;
	self.pos2 = self.origin;
	self.pos2_z -= self.height;

	// =============
	tmin = self.mins + '25 25 0';
	tmax = self.maxs - '25 25 -8';
	tmin_z = tmax_z - (self.pos1_z - self.pos2_z + 8);

	if (self.spawnflags & SPAWNFLAGS_PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;

	if (self.size_x <= 50)
		tmin_x = (self.mins_x + self.maxs_x) * 0.5 + 1;
	if (self.size_y <= 50)
		tmin_y = (self.mins_y + self.maxs_y) * 0.5 + 1;

	_movewall_spawn_trigger(self.pos1, tmin, tmax);
	// =============

	if (!self.targetname) {
		setorigin (self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;

		self.style = 1;
	} else {
		self.style = 0;
	}

	self.state = 1 - self.style;

	self.owner = self;

	self.goalentity = self;

	self.use = _movewall_plat_touch;

	self.touch = _movewall_plat_touch;
	self.blocked = _movewall_block_goback;
	self.w_think = _movewall_binary_think;
};

// ========================================================================

/* buttons, out pos1, in pos2 */

void() _movewall_button_think = {
	if (floor (self.state) != self.state) {
		local vector	tmp;

		if (self.state == 0.5) {
			if (self.noise3)
				sound (self, CHAN_BODY, self.noise3, 1, ATTN_NORM);
		}

		tmp = self.pos2;
		self.pos2 = self.pos1;
		self.pos1 = tmp;
		self.style = 1 - self.style;
	} else {
		if (self.state == 1) {
			if (self.noise4)
				sound (self, CHAN_BODY|CHAN_NO_PHS_ADD, self.noise4, 1,
					   ATTN_NORM);

			self.think = _movewall_wait_think;

			if (util_use_targets ()) {
				self.frame = 1;
				self.nextthink = self.ltime + self.wait;
			} else {
				self.nextthink = self.ltime + 0.5;
			}
		} else {
			self.frame = 0;
		}
	}
};

void() _movewall_button_touch = {
	if (!is_living (other))
		return;
	if (self.state != 0)
		return;

	self.use ();
};

float(float d) _movewall_button_takedamage = {
	deathmsg_nodisplay ();

	if (self.state != 0)
		return FALSE;

	self.health -= d;

	if (self.health <= 0) {
		self.health = self.max_health;
		self.use ();
	}

	return FALSE;	// lie
};

void() func_button = {
	if (!self.noise3) {
		switch (self.sounds) {
		case 0:
			self.noise3 = "buttons/airbut1.wav";
			break;
		case 1:
			self.noise3 = "buttons/switch21.wav";
			break;
		case 2:
			self.noise3 = "buttons/switch02.wav";
			break;
		case 3:
			self.noise3 = "buttons/switch04.wav";
			break;
		default:
			break;
		}
	}
	
	if (self.noise3)
		precache_sound (self.noise3);
	if (self.noise4)
		precache_sound (self.noise4);

	if (!self.speed)
		self.speed = 40;
	if (!self.wait)
		self.wait = 1;
	if (!self.lip)
		self.lip = 4;

	movewall_init ();

	util_map_entity_init ();

	util_set_movedir ();

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir * (fabs (self.movedir * self.size)
											- self.lip);

	self.style = 1;
	self.state = 1 - self.style;

	if (!self.health && !self.targetname) {
		self.touch = _movewall_button_touch;
	} else {
		if (self.health) {
			self.takedamage = DAMAGE_YES;
			self.th_takedamage = _movewall_button_takedamage;
		}
		
		self.touch = NOTHING_function;
	}

	self.goalentity = self;

	self.blocked = _movewall_block_ignore;
	self.w_think = _movewall_button_think;
};

// ========================================================================

#define SPAWNFLAGS_SECRET_ONCE 1
#define SPAWNFLAGS_SECRET_1ST_LEFT 2
#define SPAWNFLAGS_SECRET_1ST_DOWN 4
#define SPAWNFLAGS_SECRET_NO_SHOOT 8
#define SPAWNFLAGS_SECRET_YES_SHOOT 16

/* 'secret door', has several points it moves to. */
/*
	state 0 is closed
	state 1 is back
	state 2 is to the side (fully open)
*/
/* noise3 is played when transitioning */
/* noise4 is played when the transition is complete */

/* pos1 is state 0 position */

void() _movewall_secret_use = {
	// Stay open...
	if (self.count == 2 && self.state == 2)
		self.nextthink = self.ltime + self.wait;

	if (self.state != 0)
		return;

	_movewall_use ();
};

.vector dest1, dest2;
void() _movewall_secret_think = {
	if (floor (self.state) != self.state) {
		if (self.count == 0 && self.state == 0.5) {
			self.message = NIL;
			self.noise2 = NIL;

			if (!util_use_targets ()) {
				self.velocity = '0 0 0';
				setorigin (self, self.pos1);

				self.state = 0;
				self.nextthink = -1;

				return;
			}
		}

		if (self.noise3)
			sound (self, CHAN_BODY, self.noise3, 1, ATTN_NORM);

		return;
	}

	if (self.noise4)
		sound (self, CHAN_BODY|CHAN_NO_PHS_ADD, self.noise4, 1, ATTN_NORM);

	self.think = _movewall_use;
	self.nextthink = self.ltime + 1.0;

	if (self.count == 0) {
		if (self.state == 0) {
			self.style = 1;
			self.pos2 = self.dest1;
		} else if (self.state == 1) {
			self.style = 2;
			self.pos2 = self.dest2;
		}
	} else if (self.count == 1 && self.state == 2) {
		if (self.spawnflags & SPAWNFLAGS_SECRET_ONCE) {
			self.nextthink = -1;
		} else {
			self.style = 1;
			self.pos2 = self.dest1;

			self.nextthink = self.ltime + self.wait;
		}
	} else if (self.count == 2 && self.state == 1) {
		self.style = 0;
		self.pos2 = self.pos1;
	} else if (self.count == 1 && self.state == 0) {
		self.style = 1;
		self.pos2 = self.dest1;

		self.nextthink = -1;
	}

	self.attack_finished = self.nextthink;

	self.count = self.state;
};

float(float d) _movewall_secret_takedamage = {
	self.use ();
	deathmsg_nodisplay ();
	return FALSE;
};

void() _movewall_secret_touch = {
	if (!is_living (other))
		return;

	if (time < self.attack_finished)
		return;

	self.attack_finished = time + 2;

	if (self.message) {
		if (is_cl (other))
			centerprint (other, self.message);

		if (self.noise2)
			sound (other, CHAN_ITEM, self.noise2, self.volume,
				   self.attenuation);
	}
};

/*QUAKED func_door_secret (0 .5 .8) ? SECRET_ONCE SECRET_1ST_LEFT SECRET_1ST_DOWN SECRET_NO_SHOOT SECRET_YES_SHOOT
Secret door. Slides back, then to the side. Angle determines direction.
wait		# of seconds before coming back
1st_left	1st move is left of arrow
1st_down	1st move is down from arrow
no_shoot	not shootable
yes_shoot	even if targeted, keep shootable

t_width		override WIDTH to move back (or height if going down)
t_length	override LENGTH to move sideways
dmg		damage to inflict when blocked (default 2)
*/

void() func_door_secret = {
	if (!self.noise3) {
		switch (self.sounds) {
		case 1:
			self.noise1 = "doors/latch2.wav";
			self.noise3 = "doors/winch2.wav";
			self.noise4 = "doors/drclos4.wav";
			break;
		case 2:
			self.noise3 = "doors/airdoor1.wav";
			self.noise4 = "doors/airdoor2.wav";
			break;
		case 0:
		case 3:
			self.noise3 = "doors/basesec1.wav";
			self.noise4 = "doors/basesec2.wav";
			break;
		default:
			break;
		}
	}

	if (self.message != "" && !self.noise2)
		self.noise2 = "misc/talk.wav";

	if (self.noise3)
		precache_sound(self.noise3);
	if (self.noise4)
		precache_sound(self.noise4);

	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;

	if (!self.speed)
		self.speed = 50;
	if (!self.wait)
		self.wait = 5;
	if (!self.dmg)
		self.dmg = 2;

	movewall_init ();

	util_map_entity_init ();

	self.use = _movewall_secret_use;

	// ===============

	util_set_movedir();

	if (!self.t_width) {
		if (self.spawnflags & SPAWNFLAGS_SECRET_1ST_DOWN)
			self.t_width = fabs (v_up * self.size);
		else
			self.t_width = fabs (v_right * self.size);
	}

	if (!self.t_length) {
		self.t_length = fabs (v_forward * self.size);
	}

	self.pos1 = self.origin;

	if (self.spawnflags & SPAWNFLAGS_SECRET_1ST_DOWN) {
		self.dest1 = self.pos1 - v_up * self.t_width;
	} else {
		if (self.spawnflags & SPAWNFLAGS_SECRET_1ST_LEFT)
			v_right = '0 0 0' - v_right;

		self.dest1 = self.pos1 + v_right * self.t_width;
	}

	self.dest2 = self.dest1 + v_forward * self.t_length;

	self.state = 0;
	self.style = 1 - self.state;

	self.pos2 = self.dest1;

	self.sounds = 0;

	// ===============

	if (!self.targetname || (self.spawnflags & SPAWNFLAGS_SECRET_YES_SHOOT)) {
		self.takedamage = DAMAGE_YES;
		self.th_takedamage = _movewall_secret_takedamage;
	}

	self.goalentity = self;

	self.blocked = _movewall_block_ignore;
	self.touch = _movewall_secret_touch;
	self.w_think = _movewall_secret_think;
};

// ========================================================================

/* Trains.  Joy. */

void() _movewall_train_think = {
	if (floor(self.state) != self.state) {
		if (self.count != self.state && self.noise3)
			sound (self, CHAN_VOICE, self.noise3, 1, ATTN_NORM);
	} else {
		if (self.noise4)
			sound (self, CHAN_VOICE|CHAN_NO_PHS_ADD, self.noise4, 1,
				   ATTN_NORM);

		self.think = _movewall_wait_think;
		self.nextthink = self.ltime + self.wait;
	}
	
	self.count = self.state;
};

void() _train_finalize = {
	local entity	oldself;

	oldself = self;
	while (self) {
		if (self.goalentity)
			break;	// Looped. FIXME: Use short circuit when compiler supports

		if (!self.target)
			objerror ("Train without target\n");
		self.goalentity = find (world, targetname, self.target);
		if (!self.goalentity)
			objerror ("Unable to find train target\n");

		self = self.goalentity;
		self.pos2 = self.origin;
	}
	self = oldself;

	setorigin (self, self.goalentity.origin - self.view_ofs);

	if (!self.targetname) {
		self.think = _movewall_wait_think;
		self.nextthink = self.ltime + sv_mintic;
	}
};

/*QUAKED func_train (0 .5 .8)
*/
void() func_train = {
	if (!self.noise3) {
		if (self.sounds == 1) {
			self.noise3 = "plats/train1.wav";
			self.noise4 = "plats/train2.wav";
		}
	}

	if (self.noise3)
		precache_sound(self.noise3);
	if (self.noise4)
		precache_sound(self.noise4);

	if (!self.speed)
		self.speed = 100;
	if (!self.wait)
		self.wait = 0.1;
	if (!self.dmg)
		self.dmg = 2;
	if (self.dmg < 0)
		self.dmg = 0;

	self.view_ofs = self.mins;

	self.blocked = _movewall_block_ignore;
	self.w_think = _movewall_train_think;

	movewall_init();

	util_map_entity_init();

	// Make sure all the targetnames are set
	self.think = _train_finalize;
	self.nextthink = self.ltime + sv_mintic;
};
