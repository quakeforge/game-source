#include "common.qh"

#include "damage.qh"
#include "mdl.qh"
#include "client.qh"
#include "server.qh"
#include "misc.qh"
#include "items.qh"

#include "weapon.qh"
#include "equip.qh"

#include "act.qh"
#include "act_player.qh"

#include "override.qh"

void ()
act_player_init =
{
	precache_sound ("player/plyrjmp8.wav");
	precache_sound ("player/h2ojump.wav");

	precache_sound ("player/land.wav");
	precache_sound ("player/land2.wav");
	
	precache_sound ("player/inh2o.wav");
	precache_sound ("player/slimbrn2.wav");
	precache_sound ("player/inlava.wav");

	precache_sound ("misc/water1.wav");
	precache_sound ("misc/water2.wav");
	
	precache_sound ("player/drown1.wav");
	precache_sound ("player/drown2.wav");

	precache_sound ("player/lburn1.wav");
	precache_sound ("player/lburn2.wav");

	precache_sound ("player/gasp1.wav");
	precache_sound ("player/gasp2.wav");
	
	precache_sound ("misc/outwater.wav");

	precache_sound ("player/pain1.wav");
	precache_sound ("player/pain2.wav");
	precache_sound ("player/pain3.wav");
	precache_sound ("player/pain4.wav");
	precache_sound ("player/pain5.wav");
	precache_sound ("player/pain6.wav");

	precache_sound ("player/death1.wav");
	precache_sound ("player/death2.wav");
	precache_sound ("player/death3.wav");
	precache_sound ("player/death4.wav");
	precache_sound ("player/death5.wav");

	precache_sound ("player/gib.wav");
	precache_sound ("player/udeath.wav");
	
	precache_sound ("player/h2odeath.wav");

	precache_model ("progs/backpack.mdl");
	precache_sound ("weapons/lock4.wav");
	precache_sound ("items/itembk2.wav");
};

// ========================================================================

void (float scl)
player_throw_ammo =
{
	local entity player;

	player = self;

	self = spawn ("BACKPACK");

	if (scl > 1) {
		/* FIXME: This is actually a hack to avoid powerups */
#define qg(eid)					\
		if (equip_query (player, eid))	\
			equip_grant (self, eid)	\

		qg (EQUIPID_SUPER_SHOTGUN);
		qg (EQUIPID_NAILGUN);
		qg (EQUIPID_SUPER_NAILGUN);
		qg (EQUIPID_GRENADE_LAUNCHER);
		qg (EQUIPID_ROCKET_LAUNCHER);
		qg (EQUIPID_LIGHTNING_GUN);
#undef qg

		player.itemfield_1 = 0;
		player.itemfield_2 = 0;
		player.itemfield_3 = 0;
		player.itemfield_4 = 0;

		scl = 1;
	}

	self.ammo_shells = player.ammo_shells * scl;
	player.ammo_shells -= self.ammo_shells;
	self.ammo_nails = player.ammo_nails * scl;
	player.ammo_nails -= self.ammo_nails;
	self.ammo_rockets = player.ammo_rockets * scl;
	player.ammo_rockets -= self.ammo_rockets;
	self.ammo_cells = player.ammo_cells * scl;
	player.ammo_cells -= self.ammo_cells;

	if (!self.ammo_shells && !self.ammo_nails && !self.ammo_rockets
		&& !self.ammo_cells && !self.itemfield_1 && !self.itemfield_2
		&& !self.itemfield_3 && !self.itemfield_4) {
		remove (self);
		self = player;
		return;
	}

	self.origin = center (player);

	self.movetype = MOVETYPE_TOSS;
	self.velocity_x = crandom () * 100;
	self.velocity_y = crandom () * 100;
	self.velocity_z = 200;

	self.mins = '-16 -16 0';
	self.maxs = '16 16 56';

	self.model = "progs/backpack.mdl";
	self.noise2 = "weapons/lock4.wav";
	self.noise7 = "items/itembk2.wav";

	self.wait = -1;

	self.think = SUB_remove;
	self.nextthink = time + 20 + random () *20;

	item_generic ();

	self = player;
};

void ()
player_die =
{
	local float r;

	if (self.health > CONFIG_GIB_HEALTH) {
		if (self.waterlevel >= 3) {
			self.noise = "player/h2odeath.wav";
		} else {
			r = random () * 5;
			if (r < 1)
				self.noise = "player/death1.wav";
			else if (r < 2)
				self.noise = "player/death2.wav";
			else if (r < 3)
				self.noise = "player/death3.wav";
			else if (r < 4)
				self.noise = "player/death4.wav";
			else
				self.noise = "player/death5.wav";
		}
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NONE);

		player_throw_ammo (2);
		mdl_bodyque_and_func (MDL_FUNC_DIE, floor (random () * 5));
	} else {
		r = random () * 2;
		if (r < 1)
			self.noise = "player/gib.wav";
		else
			self.noise = "player/udeath.wav";

		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
		mdl_bodyque_and_func (MDL_FUNC_GIB, 0);
	}

	makevectors (self.angles);	/* Not v_angle! */
	self.velocity = (v_forward * -200) + (v_up * 100);

	if (self.v_angle_x < 75 && self.v_angle_x > -75) {
		self.angles = self.v_angle;
		self.angles_x += 20;
		self.fixangle = TRUE;
	}

	/* FIXME: Hack. */
	setorigin (self, vieworigin (self));
	RemoveClientFromGame ();
};

// ========================================================================

float (float d)
_player_takedamage_core =
{
	self.health -= d;
	self.dmg_take += d;

	if (floor (self.health) <= 0) {
		deathmsg_display ();
		player_die ();
	} else {
		deathmsg_nodisplay ();
		self.mdl_func (MDL_FUNC_PAIN, d);
	}

	return TRUE;
};

float (float d)
player_takedamage =
{
	local float taked, r;

	damage_push (d);

	taked = damage_armor (d);
	self.dmg_save += (d - taked);

	if (taked <= 0)
		return FALSE;

	if (self.pain_finished < time) {
		if ((self.mdl_mod & MDL_MOD_SWIM_IN) && self.air_finished < (time + random () * 9)) {
			r = random () * 2;
			if (r < 1)
				self.noise = "player/drown2.wav";
			else
				self.noise = "player/drown1.wav";
		} else {
			r = random () * 5;
			if (r < 1)
				self.noise = "player/pain1.wav";
			else if (r < 2)
				self.noise = "player/pain2.wav";
			else if (r < 3)
				self.noise = "player/pain3.wav";
			else if (r < 4)
				self.noise = "player/pain4.wav";
			else if (r < 5)
				self.noise = "player/pain5.wav";
			else
				self.noise = "player/pain6.wav";
		}
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

		self.pain_finished = time + 1;
	}
	
	return _player_takedamage_core (taked);
};

// ========================================================================

float (float d)
_player_takedamage_drown =
{
	local float r;

	if (d <= 0)
		return FALSE;

	if (self.pain_finished < time) {
		r = random () * 2;
		if (r < 1)
			self.noise = self.noise3;
		else
			self.noise = self.noise4;

		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

		self.pain_finished = time + 1;
	}

	return _player_takedamage_core (d);
};

float (float d)
_player_takedamage_melt =
{
	local float taked, r;

	taked = damage_armor (d);
	self.dmg_save += d - taked;

	if (taked <= 0)
		return FALSE;

	if (self.pain_finished < time) {
		r = random () * 2;
		if (r < 1)
			self.noise = self.noise3;
		else
			self.noise = self.noise4;

		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

		self.pain_finished = time + 1;
	}

	return _player_takedamage_core (taked);
};

float (float d, float (float d) damg_func, void () deathmessage)
_player_damage_custom =
{
	local float ret;

	override_set_th_takedamage (self, damg_func);
	ret = damage (self, self, world, d, deathmessage);
	override_set_th_takedamage (self, player_takedamage);
	
	return ret;
};

// ========================================================================

void ()
_deathmsg_player_liquid =
{
	local string def_nname;
	local float r;

	def_nname = name (self);

	switch (self.watertype) {
	case CONTENT_WATER:
		r = random () * 2;
		if (r < 1)
			bprint (PRINT_DEATH, def_nname, " sleeps with the fishes.\n");
		else
			bprint (PRINT_DEATH, def_nname, " hunts for air.\n");
		break;
	case CONTENT_SLIME:
		r = random () * 2;
		if (r < 1)
			bprint (PRINT_DEATH, def_nname, " can't exist on slime alone.\n");
		else
			bprint (PRINT_DEATH, def_nname, " floats in slime.\n");
		break;
	case CONTENT_LAVA:
		r = random () * 3;
		if (r < 1)
			bprint (PRINT_DEATH, def_nname, " swam in a volcano.\n");
		else if (r < 2)
			bprint (PRINT_DEATH, def_nname, " turned into hot slag.\n");
		else
			bprint (PRINT_DEATH, def_nname, " parties with Chthon.\n");
		break;
	default:
		bprint (PRINT_DEATH, def_nname, " gulps it down.\n");
		break;
	}
};

void ()
_deathmsg_player_fall =
{
	local string def_name;
	local float r;

	def_name = name (self);

	r = random () * 3;
	if (r < 1)
		bprint (PRINT_DEATH, def_name, " landed head-first.\n");
	else if (r < 2)
		bprint (PRINT_DEATH, def_name, " cratered.\n");
	else
		bprint (PRINT_DEATH, def_name,
				" took a nose dive into the ground.\n");
};

// ========================================================================

/* This is so stupid. */
float ()
_player_jump =
{
	if (!self.button2) {
		self.flags |= FL_JUMPRELEASED;
		return FALSE;
	}

	if (!(self.flags & FL_ONGROUND))
		return FALSE;

	if (!(self.flags & FL_JUMPRELEASED))
		return FALSE;

	self.mdl_func (MDL_FUNC_JUMP, 0);

	self.flags &= ~FL_JUMPRELEASED;
	self.button2 = 0;

	return TRUE;
};

void ()
_player_water_jump =
{
	if (self.waterlevel <= 1) {
		if (_player_jump())
			sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
		return;
	}

	if (self.waterlevel <= 2) {
		if (_player_jump ())
			sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
	}

	/* Yeah.  The engine is a piece of crap. */
	if (self.button2) {
		if (self.flags & FL_ONGROUND) {
			self.flags &= ~FL_ONGROUND;
			self.origin_z++;
		}
	}
};

/* This is called every frame... */
void ()
player_prethink =
{
	/* Gasp for air if we weren't swimming..
	/* Checking here rather than later, with mdl_mod is a HACK */
	/* It avoids the gasp when the player hasn't communicated
	   with the server in a while (it happens..) */
	if (self.waterlevel < 3) {
		if (self.mdl_mod & MDL_MOD_SWIM_IN) {
			if (self.air_finished < time)
				sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
			else if (self.air_finished < (time + 9))
				sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
		}

		self.air_finished = time + 12;
	}

	/* Let the MDL (and us) know we're swimming */
	self.mdl_mod &= ~MDL_MOD_SWIM;
	if (self.waterlevel >= 3)
		self.mdl_mod |= MDL_MOD_SWIM_IN;
	else if (self.waterlevel >= 1)
		self.mdl_mod |= MDL_MOD_SWIM_OVER;

	/* Handle environmental damage */
	if (self.watertype == CONTENT_SLIME) {
		self.noise3 = "player/lburn1.wav";
		self.noise4 = "player/lburn2.wav";
		_player_damage_custom (4 * self.waterlevel * frametime,
							   _player_takedamage_melt,
							   _deathmsg_player_liquid);
	} else if (self.watertype == CONTENT_LAVA) {
		self.noise3 = "player/lburn1.wav";
		self.noise4 = "player/lburn2.wav";
		_player_damage_custom (50 * self.waterlevel * frametime,
							   _player_takedamage_melt,
							   _deathmsg_player_liquid);
	}

	/* Try to breathe :) */
	if (self.air_finished < time) {
		local float damg;

		damg = (time - self.air_finished) * 0.2;
		if (damg > 1.5)
			damg = 1.5;

		self.noise3 = "player/drown1.wav";
		self.noise4 = "player/drown2.wav";
		_player_damage_custom (damg, _player_takedamage_drown,
							   _deathmsg_player_liquid);
	}

	/* Enter/exit water, swim sound */
	if (!self.waterlevel) {
		if (self.flags & FL_INWATER) {
			sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
			self.flags &= ~FL_INWATER;
		}

		if (_player_jump())
			sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	} else {
		if (!(self.flags & FL_INWATER)) {
			if (self.watertype == CONTENT_WATER)
				self.noise = "player/inh2o.wav";
			else if (self.watertype == CONTENT_SLIME)
				self.noise = "player/slimbrn2.wav";
			else if (self.watertype == CONTENT_LAVA)
				self.noise = "player/inlava.wav";
			sound (self, CHAN_BODY, self.noise, 1, ATTN_NORM);

			self.flags = (self.flags & ~FL_JUMPRELEASED) | FL_INWATER;
			
			self.water_finished = 0;
		}

		if (self.mdl_mod&MDL_MOD_SWIM) {
			local float increment, mxspeed;

			increment = vlen (self.origin - self.pos1);
			mxspeed = calc_max_speed (self);
			if (increment > mxspeed)
				increment = mxspeed;

			self.water_finished += increment;
			if (self.water_finished >= mxspeed) {
				self.water_finished = 0;
				if (random () < 0.5)
					self.noise = "misc/water1.wav";
				else
					self.noise = "misc/water2.wav";
				sound (self, CHAN_BODY, self.noise, 1, ATTN_NORM);
			}
		}

		_player_water_jump ();
	}

	self.pos1 = self.origin;

#if DEBUG
	debug_impulse ();
#endif
	weapon_player_impulse ();
};

/* This is not called every frame */
void ()
player_think =
{	// The player does not think.
};

/* FIXME: We should check to see if we actually collided.
          I don't know how to at the moment... */
void ()
player_velocity_damage =
{
	local vector vel, dir;
	local float v1, v2;

	vel = self.movedir;
	self.movedir = self.velocity;

	/* Did we just teleport? */
	if (self.teleport_time)
		return;

	/* Did we slow down a lot? */
	v1 = vlen (vel);
	v2 = vlen (self.velocity);
	if (v2 >= v1)
		return;

	vel = vel - self.velocity;
	vel_z = vel_z * 2;
	v1 = vlen (vel);

	/* Find the largest magnitude dir */
	vel_x = fabs (vel_x);
	vel_y = fabs (vel_y);
	vel_z = fabs (vel_z);

	dir = '0 0 1';
	if (vel_y > (vel * dir))
		dir = '0 1 0';
	if (vel_x > (vel * dir))
		dir = '1 0 0';

	/* Play sounds, apply damage */
	if (v1 > CONFIG_LAND_SOUND) {
		if (dir_z && (self.watertype == CONTENT_WATER)) {
			self.noise = "player/h2ojump.wav";
		} else if (v1 > CONFIG_LAND_HURT) {
			self.noise = "player/land2.wav";
			self.pain_finished = time + 1;
			damage (self, self, world, 5, _deathmsg_player_fall);
		} else {
			self.noise = "player/land.wav";
		}

		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	}
};

/* This is also called every frame... */
void ()
player_postthink =
{
	player_velocity_damage ();

	self.items &= ~(IT_ARMOR1|IT_ARMOR2|IT_ARMOR3);
	if (self.armortype >= 0.8)
		self.items |= IT_ARMOR3;
	else if (self.armortype >= 0.6)
		self.items |= IT_ARMOR2;
	else if (self.armortype >= 0.3)
		self.items |= IT_ARMOR1;

	update_weapon_flags ();
	weapon_set_ammo ();
};

// ========================================================================

void (float nitem, string str1, string str2)
_item_xprint_strs =
{
	if (!is_cl (self))
		return;
	if (!str1)
		return;

	if (nitem == 1) {
		stuffcmd (self, "bf\n");
		xprint_start (self, PRINT_LOW);
		xprint_str ("You get ");
	} else if (nitem > 1)
		xprint_str (", ");

	xprint_str (str1);
	if (str2)
		xprint_str (str2);
};

void (float nitem, string str1, string str2)
_item_xprint_strs_last =
{
	if (!is_cl(self))
		return;
	if (!str1)
		return;

	if (nitem == 1) {
		stuffcmd (self, "bf\n");
		xprint_start (self, PRINT_LOW);
		xprint_str ("You get ");
	}

	if (nitem == 2)
		xprint_str (" and ");
	else if (nitem > 2)
		xprint_str (", and ");

	xprint_str (str1);
	if (str2)
		xprint_str (str2);

	xprint_str ("\n");
};

float nitem;
string str1, str2;
void (.float fld, float max, string sing, string plur)
_player_takefield =
{
	local float new, diff;

	new = increase_bound (self.fld, other.fld, max);
	if (new > 999)
		new = 999;
	if (new > self.fld) {
		diff = floor (new) - floor (self.fld);
		if (!diff)
			diff = new - self.fld;

		_item_xprint_strs (nitem, str1, str2);
		str1 = ftos (diff);
		if (diff == 1)
			str2 = sing;
		else
			str2 = plur;
		nitem++;

		self.fld = new;
	}
};

float ()
player_takeitem =
{
	local float eid;

	nitem = 0;
	str1 = nil;
	str2 = nil;

	while ((eid = equip_iter (other)) != -1) {
		if (equip_query (self, eid))
			continue;

		equip_grant (self, eid);

		_item_xprint_strs (nitem, str1, str2);
		str1 = "the ";
		str2 = equip_id_to_string (eid);
		nitem++;
	}

	_player_takefield (ammo_shells, self.max_ammo_shells, " shell", " shells");
	_player_takefield (ammo_nails, self.max_ammo_nails, " nail", " nails");
	_player_takefield (ammo_rockets, self.max_ammo_rockets, " rocket",
					   " rockets");
	_player_takefield (ammo_cells, self.max_ammo_cells, " cell", " cells");

	if (other.armorvalue <= self.max_armor) {
		if ((other.armorvalue * other.armortype)
			> (self.armorvalue * self.armortype)) {
			self.armorvalue = other.armorvalue;
			self.armortype = other.armortype;

			_item_xprint_strs (nitem, str1, str2);
			str2 = nil;
			if (self.armortype >= 0.8)
				str1 = "strong armor";
			else if (self.armortype >= 0.6)
				str1 = "medium armor";
			else if (self.armortype >= 0.3)
				str1 = "light armor";
			else
				str1 = "really crappy armor";
			nitem++;
		}
	}

	_player_takefield (health, self.max_health, " health", " health");

	_item_xprint_strs_last (nitem, str1, str2);

	if (nitem)
		return TRUE;
	return FALSE;
};

// ===================================================================== //

void ()
act_setup_player ={
	act_setup ();

	self.movedir = '0 0 0';

	self.solid = SOLID_SLIDEBOX;
	self.takedamage = DAMAGE_AIM;
	self.movetype = MOVETYPE_WALK;

	self.deadflag = DEAD_NO;

	self.gravity = 1;
	self.maxspeed = sv_maxspeed;
	self.mass = 1000;

	self.air_finished = time + 12;
	self.pain_finished = 0;
	self.water_finished = 0;

	override_set_th_takeitem (self, player_takeitem);

	override_set_th_takedamage (self, player_takedamage);

	override_set_prethink (self, player_prethink);
	override_set_actthink (self, player_think);
	override_set_postthink (self, player_postthink);
};
