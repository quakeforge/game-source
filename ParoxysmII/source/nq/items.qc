void() W_SetCurrentAmmo;
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */

.entity quadcore;		//POX - used by the dual model quad

void() SUB_regen =
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
	sound (self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
	
	if (self.classname == "item_artifact_super_damage")
	{
		self.quadcore.model = self.quadcore.mdl;
		setorigin (self.quadcore, self.quadcore.origin);
	}
	
	if (self.classname == "item_artifact_super_damage" || self.classname == "item_artifact_invulnerability" || self.classname == "item_artifact_invisibility")
		self.effects |= EF_DIMLIGHT;
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(self.origin));
	dprint ("\n");
	remove (self);
};



/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	local float	oldz;

	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;	
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;
	if (!droptofloor())
	{
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
	self.nextthink = time + 0.2;	// items start after other solids
	self.think = PlaceItem;
};

/*
=========================================================================

HEALTH BOX

=========================================================================
*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0)
		return 0;
	if ((!ignore) && (e.health >= other.max_health))
		return 0;
	healamount = ceil(healamount);

	e.health = e.health + healamount;
	if ((!ignore) && (e.health >= other.max_health))
		e.health = other.max_health;
		
	if (e.health > 250)
		e.health = 250;
	return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then 
rot you down to your maximum health limit, 
one point per second.
*/

float	H_ROTTEN = 1;
float	H_MEGA = 2;
.float	healamount, healtype;
void() health_touch;
void() item_megahealth_rot;

void() item_health =
{	
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	self.touch = health_touch;

	if (self.spawnflags & H_ROTTEN)
	{
		precache_model("maps/bspmdls/b_bh10.bsp");

		precache_sound("items/health1.wav");
		setmodel(self, "maps/bspmdls/b_bh10.bsp");
		self.noise = "items/health1.wav";
		self.healamount = 15;
		self.healtype = 0;
	}
	else
	if (self.spawnflags & H_MEGA)
	{
		precache_model("maps/bspmdls/b_bh100.bsp");
		precache_sound("items/r_item2.wav");
		setmodel(self, "maps/bspmdls/b_bh100.bsp");
		self.noise = "items/r_item2.wav";
		self.healamount = 100;
		self.healtype = 2;
	}
	else
	{
		precache_model("maps/bspmdls/b_bh25.bsp");
		precache_sound("items/health1.wav");
		setmodel(self, "maps/bspmdls/b_bh25.bsp");
		self.noise = "items/health1.wav";
		self.healamount = 25;
		self.healtype = 1;
	}
	setsize (self, '0 0 0', '32 32 56');
	self.netname = "Health Pack";
	StartItem ();
};


void() health_touch =
{
	local	float amount;
	local	string	s;
	
	if (other.classname != "player")
		return;
	
	if (self.healtype == 2) // Megahealth?  Ignore max_health...
	{
		if (other.health >= 250)
			return;
		if (!T_Heal(other, self.healamount, 1))
			return;
	}
	else
	{
		if (!T_Heal(other, self.healamount, 0))
			return;
	}
	
	sprint(other, "You receive ");
	s = ftos(self.healamount);
	sprint(other, s);
	sprint(other, " health\n");
	
// health touch sound
	sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	stuffcmd (other, "bf\n");
	
	self.model = string_null;
	self.solid = SOLID_NOT;

	// Megahealth = rot down the player's super health
	if (self.healtype == 2)
	{
		other.items |= IT_SUPERHEALTH;
		self.nextthink = time + 5;
		self.think = item_megahealth_rot;
		self.owner = other;
	}
	else
	{
		//if (deathmatch != 2)		// deathmatch 2 is the silly old rules
		//{
			if (deathmatch)
				self.nextthink = time + 20;
			self.think = SUB_regen;
		//}
	}
	
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};	

void() item_megahealth_rot =
{
	other = self.owner;
	
	if (other.health > other.max_health)
	{
		other.health = other.health - 1;
		self.nextthink = time + 1;
		return;
	}

// it is possible for a player to die and respawn between rots, so don't
// just blindly subtract the flag off
	other.items &= ~IT_SUPERHEALTH);
	
	if (deathmatch >= 1)	// deathmatch 2 is silly old rules
	{
		self.nextthink = time + 20;
		self.think = SUB_regen;
	}
};

/*
===============================================================================

ARMOR - New Regen Stations Replace armor (see sheilds.qc)

===============================================================================
*/
/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
	if (other.ammo_shells > 100)
		other.ammo_shells = 100;
	if (other.ammo_nails > 200)
		other.ammo_nails = 200;
	if (other.ammo_rockets > 100)
		other.ammo_rockets = 100;		
	if (other.ammo_cells > 200)
		other.ammo_cells = 200;		
};


float(float w) RankForWeapon =
{
	if (w == IT_FLAMETHROWER)
		return 1;
	if (w == IT_ROCKET_LAUNCHER)
		return 2;
	if (w == IT_SUPER_NAILGUN)
		return 3;
	if (w == IT_GRENADE_LAUNCHER)
		return 4;
	if (w == IT_COMBOGUN)
		return 5;
	if (w == IT_PLASMAGUN)
		return 6;
	return 7;
};

/*
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float		ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
=============
*/
void(float old, float new) Deathmatch_Weapon =
{
	local float or, nr;

// change self.weapon if desired
	or = RankForWeapon (self.weapon);
	nr = RankForWeapon (new);
	if ( nr < or )
		self.weapon = new;
};

/*
=============
weapon_touch
=============
*/
float() W_BestWeapon;

void() weapon_touch =
{
	local	float	hadammo, best, new, old;
	local	entity	stemp;
	local	float	leave;

	if (!(other.flags & FL_CLIENT))
		return;

// if the player was using his best weapon, change up to the new one if better		
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

//POX v1.1 - leave is useless in POX since weapons are never allowed to be picked up if posessed
	//if (deathmatch || coop)
	//if (coop)
	//	leave = 1;
	//else
	//	leave = 0;
	

	// POX - Don't bother checking if weapon is in inventory
	if (other.items & self.weapon)
	{
		activator = other;
		SUB_UseTargets();	//Just in case it's required to get out of somewhere
		return;
	}

// POX- changed classnames to constants

	if (self.weapon == IT_PLASMAGUN)
	{
		hadammo = other.ammo_rockets;			
		new = IT_PLASMAGUN;
		other.ammo_cells = other.ammo_cells + 22;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		hadammo = other.ammo_rockets;			
		new = IT_SUPER_NAILGUN;
		other.ammo_nails = other.ammo_nails + 30;
	}
	else if (self.weapon == IT_COMBOGUN)
	{
		hadammo = other.ammo_rockets;			
		new = IT_COMBOGUN;
		other.ammo_shells = other.ammo_shells + 5;
		other.ammo_rockets = other.ammo_rockets + 2;
		other.which_ammo = 0; //Change ammo to shells if it's set to rockets
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		hadammo = other.ammo_rockets;			
		new = IT_ROCKET_LAUNCHER;
		other.ammo_rockets = other.ammo_rockets + 5;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		hadammo = other.ammo_rockets;			
		new = IT_GRENADE_LAUNCHER;
		other.ammo_rockets = other.ammo_rockets + 5;
	}
	else
		objerror ("weapon_touch: unknown classname");

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other, "\n");
// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

	bound_other_ammo ();

// change to the weapon
	old = other.items;
	other.items |= new;
	
	stemp = self;
	self = other;

// change weapon to item picked up unless DM_AUTOSWITCH
	if (deathmatch & DM_AUTOSWITCH)
		Deathmatch_Weapon (old, new);
	else
		self.weapon = new;

	W_SetCurrentAmmo();

	self = stemp;

	if (leave)
		return;

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
	if (deathmatch >= 1)
		self.nextthink = time + 30;
	self.think = SUB_regen;
	
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supershotgun =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	precache_model ("progs/g_combo.mdl");
	setmodel (self, "progs/g_combo.mdl");
	self.weapon = IT_COMBOGUN;
	self.netname = "Combo Gun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_nailgun =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	precache_model ("progs/g_plasma.mdl");
	setmodel (self, "progs/g_plasma.mdl");
	self.weapon = IT_PLASMAGUN;
	self.netname = "Plasma Gun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supernailgun =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	precache_model ("progs/g_nailg.mdl");
	setmodel (self, "progs/g_nailg.mdl");
	self.weapon = IT_SUPER_NAILGUN;
	self.netname = "Nailgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);

	precache_model ("progs/g_gren.mdl");
	setmodel (self, "progs/g_gren.mdl");
	self.weapon = IT_GRENADE_LAUNCHER;
	self.netname = "Grenade Launcher";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);

	precache_model ("progs/g_rhino.mdl");
	setmodel (self, "progs/g_rhino.mdl");
	self.weapon = IT_ROCKET_LAUNCHER;
	self.netname = "Anihilator";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	precache_model ("progs/g_plasma.mdl");
	setmodel (self, "progs/g_plasma.mdl");
	self.weapon = IT_PLASMAGUN;
	self.netname = "Plasma Gun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
local entity	stemp;
local float		best;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

// if the player was using his best weapon, change up to the new one if better		
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;


// shotgun
	if (self.weapon == 1)
	{
		if (other.ammo_shells >= 100)
			return;
		other.ammo_shells = other.ammo_shells + self.aflag;
		other.which_ammo = 0;
	}

// spikes
	if (self.weapon == 2)
	{
		if (other.ammo_nails >= 200)
			return;
		other.ammo_nails = other.ammo_nails + self.aflag;
	}

//	rockets
	if (self.weapon == 3)
	{
		if (other.ammo_rockets >= 100)
			return;
		other.ammo_rockets = other.ammo_rockets + self.aflag;
		other.which_ammo = 1;
	}

//	cells
	if (self.weapon == 4)
	{
		if (other.ammo_cells >= 200)
			return;
		other.ammo_cells = other.ammo_cells + self.aflag;
	}

	bound_other_ammo ();
	
	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other, "\n");
// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

/* BEST WEAPON MARKER */
// change to a better weapon if appropriate
if (deathmatch & DM_AUTOSWITCH)
{
	if ( other.weapon == best )
	{
		stemp = self;
		self = other;
		self.weapon = W_BestWeapon();
		W_SetCurrentAmmo ();
		self = stemp;
	}
}
/* BEST WEAPON MARKER */

// if changed current ammo, update it
	stemp = self;
	self = other;
	W_SetCurrentAmmo();
	self = stemp;

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = SOLID_NOT;
	if (deathmatch >= 1)
		self.nextthink = time + 30;
	self.think = SUB_regen;

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};




float WEAPON_BIG2 = 1;

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_shell1.bsp");
		setmodel (self, "maps/bspmdls/b_shell1.bsp");
		self.aflag = 40;
	}
	else
	{
		precache_model ("maps/bspmdls/b_shell0.bsp");
		setmodel (self, "maps/bspmdls/b_shell0.bsp");
		self.aflag = 20;
	}
	self.weapon = 1;
	self.netname = "shells";
	self.classname = "ammo";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{

	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_nail1.bsp");
		setmodel (self, "maps/bspmdls/b_nail1.bsp");
		self.aflag = 50;
	}
	else
	{
		precache_model ("maps/bspmdls/b_nail0.bsp");
		setmodel (self, "maps/bspmdls/b_nail0.bsp");
		self.aflag = 25;
	}
	self.weapon = 2;
	self.netname = "nails";
	self.classname = "ammo";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_rock1.bsp");
		setmodel (self, "maps/bspmdls/b_rock1.bsp");
		self.aflag = 10;
	}
	else
	{
		precache_model ("maps/bspmdls/b_rock0.bsp");
		setmodel (self, "maps/bspmdls/b_rock0.bsp");
		self.aflag = 5;
	}
	self.weapon = 3;
	self.netname = "rockets";
	self.classname = "ammo";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
	//POX-no items in FFA mode
	if (deathmatch & DM_FFA)
		remove(self);
	
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_batt1.bsp");
		setmodel (self, "maps/bspmdls/b_batt1.bsp");
		self.aflag = 12;
	}
	else
	{
		precache_model ("maps/bspmdls/b_batt0.bsp");
		setmodel (self, "maps/bspmdls/b_batt0.bsp");
		self.aflag = 6;
	}
	self.weapon = 4;
	self.netname = "cells";
	self.classname = "ammo";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


//POX - This is used in a bunch of Id's original maps, so it's left in for backward compatibility
/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_SHOTGUN)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/bspmdls/b_shell1.bsp");
			setmodel (self, "maps/bspmdls/b_shell1.bsp");
			self.aflag = 40;
		}
		else
		{
			precache_model ("maps/bspmdls/b_shell0.bsp");
			setmodel (self, "maps/bspmdls/b_shell0.bsp");
			self.aflag = 20;
		}
		self.weapon = 1;
		self.netname = "shells";
		self.classname = "ammo";
	}

	if (self.spawnflags & WEAPON_SPIKES)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/bspmdls/b_nail1.bsp");
			setmodel (self, "maps/bspmdls/b_nail1.bsp");
			self.aflag = 40;
		}
		else
		{
			precache_model ("maps/bspmdls/b_nail0.bsp");
			setmodel (self, "maps/bspmdls/b_nail0.bsp");
			self.aflag = 20;
		}
		self.weapon = 2;
		self.netname = "spikes";
		self.classname = "ammo";
	}

	if (self.spawnflags & WEAPON_ROCKET)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/bspmdls/b_rock1.bsp");
			setmodel (self, "maps/bspmdls/b_rock1.bsp");
			self.aflag = 10;
		}
		else
		{
			precache_model ("maps/bspmdls/b_rock0.bsp");
			setmodel (self, "maps/bspmdls/b_rock0.bsp");
			self.aflag = 5;
		}
		self.weapon = 3;
		self.netname = "rockets";
		self.classname = "ammo";
	}
	
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
local entity	stemp;
local float		best;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if (other.items & self.items)
		return;

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other,"\n");

	sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	other.items |= self.items;

	if (!coop)
	{	
		self.solid = SOLID_NOT;
		self.model = string_null;
	}

	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};


void() key_setsounds =
{
	if (world.worldtype == 0)
	{
		precache_sound ("misc/medkey.wav");
		self.noise = "misc/medkey.wav";
	}
	if (world.worldtype == 1)
	{
		precache_sound ("misc/runekey.wav");
		self.noise = "misc/runekey.wav";
	}
	if (world.worldtype == 2)
	{
		precache_sound2 ("misc/basekey.wav");
		self.noise = "misc/basekey.wav";
	}
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key1 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		self.netname = "silver key";
	}
	else if (world.worldtype == 1)
	{
		precache_model ("progs/m_s_key.mdl");
		setmodel (self, "progs/m_s_key.mdl");
		self.netname = "silver runekey";
	}
	else if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_s_key.mdl");
		setmodel (self, "progs/b_s_key.mdl");
		self.netname = "silver keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY1;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_g_key.mdl");
		setmodel (self, "progs/w_g_key.mdl");
		self.netname = "gold key";
	}
	if (world.worldtype == 1)
	{
		precache_model ("progs/m_g_key.mdl");
		setmodel (self, "progs/m_g_key.mdl");
		self.netname = "gold runekey";
	}
	if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_g_key.mdl");
		setmodel (self, "progs/b_g_key.mdl");
		self.netname = "gold keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = IT_KEY2;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/


/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch;


void() powerup_touch =
{
local entity	stemp;
local float		best;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	sprint (other, "You got the ");
	sprint (other, self.netname);
	sprint (other,"\n");

	if (deathmatch)
	{
		self.mdl = self.model;
		
		if ((self.classname == "item_artifact_invulnerability") ||
			(self.classname == "item_artifact_invisibility"))
			self.nextthink = time + 75;
		else
			self.nextthink = time + 60;
		
		self.think = SUB_regen;
	}	

	sound (other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.solid = SOLID_NOT;
	other.items |= self.items;
	self.model = string_null;
	
	if (self.classname == "item_artifact_super_damage")
	{
		self.effects &= ~EF_DIMLIGHT);
		self.quadcore.mdl = self.quadcore.model;
		self.quadcore.model = string_null;
		
		other.super_time = 1;
		other.super_damage_finished = time + 30;
	}

// do the apropriate action
	if (self.classname == "item_artifact_envirosuit")
	{
		other.rad_time = 1;
		other.radsuit_finished = time + 30;
	}
	
	if (self.classname == "item_artifact_invulnerability")
	{
		self.effects &= ~EF_DIMLIGHT);
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
	}
	
	if (self.classname == "item_artifact_invisibility")
	{		
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
		self.effects &= ~EF_DIMLIGHT);
	}


	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};



/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{

	self.touch = powerup_touch;

	precache_model ("progs/poxmegs.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel (self, "progs/poxmegs.mdl");
	self.netname = "MegaShields";
	self.items = IT_INVULNERABILITY;
	
	self.effects |= EF_DIMLIGHT;
	
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();

};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
	self.touch = powerup_touch;

	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = "Biosuit";
	self.items = IT_SUIT;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
	
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
	//POX - Everyone's already invisible
	if (deathmatch & DM_PREDATOR)
		remove(self);

	self.touch = powerup_touch;

	precache_model ("progs/cloak.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel (self, "progs/cloak.mdl");
	self.netname = "Cloaking Device";
	self.items = IT_INVISIBILITY;
	
	self.effects |= EF_DIMLIGHT;
	
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
	
};



//POX - A little hack to get a multi-model item for a cool effect
void() Spawn_QuadCore =
{	
	local	entity qcore;
	
	qcore = spawn ();
	qcore.owner = self;	
	qcore.solid = SOLID_TRIGGER;
	qcore.movetype = MOVETYPE_TOSS;
	
	setmodel (qcore, "progs/poxquad2.mdl");
	setsize (qcore, '-16 -16 -24', '16 16 32');
	
	qcore.velocity = '0 0 0';
	setorigin(qcore, self.origin);
	qcore.origin_z = qcore.origin_z + 6;
	
	self.quadcore = qcore;
	
	qcore.nextthink = time + 999999999;
	qcore.think = SUB_Null;
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
	self.touch = powerup_touch;

	precache_model ("progs/poxquad.mdl");
	precache_model ("progs/poxquad2.mdl");
	
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	
	self.noise = "items/damage.wav";
	setmodel (self, "progs/poxquad.mdl");
	self.netname = "Quad Damage";
	self.items = IT_QUAD;
	setsize (self, '-16 -16 -24', '16 16 32');
	
	self.effects |= EF_DIMLIGHT;
	
	Spawn_QuadCore ();
	
	StartItem ();

};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void() BackpackTouch =
{
	local string	s;
	local	float	best, old, new;
	local		entity	stemp;
	local	float	acount;
	
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	acount = 0;
	sprint (other, "You get ");

	if (self.items)
		if ((other.items & self.items) == 0)
		{
			acount = 1;
			sprint (other, "the ");
			sprint (other, self.netname);
		}

// if the player was using his best weapon, change up to the new one if better		
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

// change weapons
	other.ammo_shells = other.ammo_shells + self.ammo_shells;
	other.ammo_nails = other.ammo_nails + self.ammo_nails;
	other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
	other.ammo_cells = other.ammo_cells + self.ammo_cells;

	new = self.items;
	if (!new)
		new = other.weapon;
	old = other.items;
	other.items |= new;
	
	bound_other_ammo ();

	if (self.ammo_shells)
	{
		if (acount)
			sprint(other, ", ");
		acount = 1;
		s = ftos(self.ammo_shells);
		sprint (other, s);
		sprint (other, " shells");
	}
	if (self.ammo_nails)
	{
		if (acount)
			sprint(other, ", ");
		acount = 1;
		s = ftos(self.ammo_nails);
		sprint (other, s);
		sprint (other, " nails");
	}
	if (self.ammo_rockets)
	{
		if (acount)
			sprint(other, ", ");
		acount = 1;
		s = ftos(self.ammo_rockets);
		sprint (other, s);
		sprint (other, " rockets");
	}
	if (self.ammo_cells)
	{
		if (acount)
			sprint(other, ", ");
		acount = 1;
		s = ftos(self.ammo_cells);
		sprint (other, s);
		sprint (other, " cells");
	}
	
	//POX - Health in packs for FFA mode
	if (self.healamount)
	{
		if (!T_Heal(other, self.healamount, 0))
			SUB_Null;
		else
		{
			if (acount)
				sprint(other, ", ");
			s = ftos(self.healamount);
			sprint(other, " ");
			sprint(other, s);
			sprint(other, " health");
		}
	}
	
	sprint (other, "\n");
// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");

// remove the backpack, change self to the player
	remove(self);
	self = other;

/* BEST WEAPON MARKER */
// change to the weapon
	//if (!deathmatch)
	//	self.weapon = new;
	//else
	if (deathmatch & DM_AUTOSWITCH)
		Deathmatch_Weapon (old, new);
/* BEST WEAPON MARKER */

	W_SetCurrentAmmo ();
};

/*
===============
DropBackpack
===============
*/

void() DropBackpack =
{
	local entity	item;

	if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells) && !(deathmatch & DM_FFA))
		return;	// nothing in it

	item = spawn();
	item.origin = self.origin - '0 0 24';
	
	if (!(deathmatch & DM_FFA))
	{
		item.items = self.weapon;
		
		//if (item.items == IT_BONESAW)
		//	item.netname = "Bonesaw";
		//else if (item.items == IT_TSHOT)
		//	item.netname = "tShot";
		//else
		if (item.items == IT_COMBOGUN)
			item.netname = "Combo Gun";
		else if (item.items == IT_PLASMAGUN)
			item.netname = "Plasma Gun";
		else if (item.items == IT_SUPER_NAILGUN)
			item.netname = "Nailgun";
		else if (item.items == IT_GRENADE_LAUNCHER)
			item.netname = "Grenade Launcher";
		else if (item.items == IT_ROCKET_LAUNCHER)
			item.netname = "Anihilator";
		//else if (item.items == IT_FLAMETHROWER)
		//	item.netname = "FlameThrower";
		else
			item.netname = "";
	}
	else //POX v1.1 moved this up here
	{
		item.healamount = 25;
		item.healtype = 1;
	}

	item.ammo_shells = self.ammo_shells;
	item.ammo_nails = self.ammo_nails;
	
	item.ammo_rockets = self.ammo_rockets;
//round rockets up to nearest integer incase someone died in between rhino barrel fires
	item.ammo_rockets = rint(item.ammo_rockets);
	
	item.ammo_cells = self.ammo_cells;

	
	//FIXED?
	// bot can drop ridiculous amounts of ammo so cap it
	if (self.classname == "bot")
	{
		if (item.ammo_shells > 50)
			item.ammo_shells = 30;
		if (item.ammo_nails > 100)
			item.ammo_nails = 70;
		if (item.ammo_rockets > 50)
			item.ammo_rockets = 20;		
		if (item.ammo_cells > 100)
			item.ammo_cells = 60;
	
	//FIXED?
	//bots sometimes have negative ammo values - this can mess up a real player
		if (item.ammo_shells < 1)
			item.ammo_shells = 0;
		if (item.ammo_nails  < 1)
			item.ammo_nails = 0;
		if (item.ammo_rockets  < 1)
			item.ammo_rockets = 0;		
		if (item.ammo_cells  < 1)
			item.ammo_cells = 0;
	}
	
	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);
	
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.classname = "pack";
	item.touch = BackpackTouch;
	// POX v1.1 changed to 30 secs
	item.nextthink = time + 30;	// remove after 2 minutes
	item.think = SUB_Remove;
};
