
#include "paroxysm.rh"

// POX - had to make room for Paroxysm's DM modes......
/* ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR */
.entity quadcore;		// + POX - used by the dual model quad
void() SUB_regen =
{
	@self.model = @self.mdl;		// restore original model
	@self.solid = SOLID_TRIGGER;	// allow it to be touched again
	sound (@self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (@self, @self.origin);
	
	// + POX - dual model quad...
	if (@self.classname == "item_artifact_super_damage") {
		@self.quadcore.model = @self.quadcore.mdl;
		setorigin (@self.quadcore, @self.quadcore.origin);
	}
	// - POX
};
/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(@self.origin));
	dprint ("\n");
	remove (@self);
};
void() q_touch;
void() q_touch =
{
	local string	s;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	@self.mdl = @self.model;
	sound (other, CHAN_VOICE, @self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	@self.solid = SOLID_NOT;
	other.items |= IT_QUAD;
	@self.model = string_null;
		//if (deathmatch == 4)
		//{
		//	other.armortype = 0;
		//	other.armorvalue = 0 * 0.01;
		//	other.ammo_cells = 0;
		//}
// do the apropriate action
	other.super_time = 1;
	other.super_damage_finished = @self.cnt;
	s=ftos(rint(other.super_damage_finished - time));
	bprint (PRINT_LOW, other.netname);
	//if (deathmatch == 4)
	//	bprint (PRINT_LOW, " recovered an OctaPower with ");
	//else 
		bprint (PRINT_LOW, " recovered a Quad with ");
	bprint (PRINT_LOW, s);
	bprint (PRINT_LOW, " seconds remaining!\n");
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

void(float timeleft) DropQuad =
{
	local entity	item;

	item = spawn ();
	item.origin = @self.origin;
	
	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);
	
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/poxquad2.mdl");
	setsize (item, '-16 -16 -24', '16 16 32');

	item.effects = EF_BLUE;
	item.flags = FL_ITEM;
	item.noise = "items/damage.wav";
	item.cnt = time + timeleft;
	item.touch = q_touch;
	item.nextthink = time + timeleft;    // remove it with the time left on it
	item.think = SUB_Remove;
};

void() r_touch;
void() r_touch =
{
	local string	s;
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	@self.mdl = @self.model;
	sound (other, CHAN_VOICE, @self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	@self.solid = SOLID_NOT;
	other.items |= IT_INVISIBILITY;
	@self.model = string_null;
// do the apropriate action
	other.invisible_time = 1;
	other.invisible_finished = @self.cnt;
	s=ftos(rint(other.invisible_finished - time));
	bprint (PRINT_LOW, other.netname);
	bprint (PRINT_LOW, " recovered a Ring with ");
	bprint (PRINT_LOW, s);
	bprint (PRINT_LOW, " seconds remaining!\n");
      
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};
void(float timeleft) DropRing =
{
	local entity	item;
	item = spawn();
	item.origin = @self.origin;
	
	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);
	
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.noise = "items/inv1.wav";
	setmodel (item, "progs/invisibl.mdl");
	setsize (item, '-16 -16 -24', '16 16 32');
	item.cnt = time + timeleft;
	item.touch = r_touch;
	item.nextthink = time + timeleft;    // remove after 30 seconds
	item.think = SUB_Remove;
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
	@self.mdl = @self.model;		// so it can be restored on respawn
	@self.flags = FL_ITEM;		// make extra wide
	@self.solid = SOLID_TRIGGER;
	@self.movetype = MOVETYPE_TOSS;	
	@self.velocity = '0 0 0';
	@self.origin_z = @self.origin_z + 6;
	oldz = @self.origin_z;
	if (!droptofloor())
	{
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(@self.origin));
		dprint ("\n");
		remove(@self);
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
	@self.nextthink = time + 0.2;	// items start after other solids
	@self.think = PlaceItem;
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
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	@self.touch = health_touch;
	if (@self.spawnflags & H_ROTTEN)
	{
		precache_model("maps/b_bh10.bsp");
		precache_sound("items/health1.wav");
		setmodel(@self, "maps/b_bh10.bsp");
		@self.noise = "items/health1.wav";
		@self.healamount = 15;
		@self.healtype = 0;
	}
	else
	if (@self.spawnflags & H_MEGA)
	{
		precache_model("maps/b_bh100.bsp");
		precache_sound("items/r_item2.wav");
		setmodel(@self, "maps/b_bh100.bsp");
		@self.noise = "items/r_item2.wav";
		@self.healamount = 100;
		@self.healtype = 2;
	}
	else
	{
		precache_model("maps/b_bh25.bsp");
		precache_sound("items/health1.wav");
		setmodel(@self, "maps/b_bh25.bsp");
		@self.noise = "items/health1.wav";
		@self.healamount = 25;
		@self.healtype = 1;
	}
	setsize (@self, '0 0 0', '32 32 56');
	StartItem ();
};
void() health_touch =
{
	local string	s;
	
	//if (deathmatch == 4)
	//	if (other.invincible_time > 0)
	//		return;
	if (other.classname != "player")
		return;
	
	if (@self.healtype == 2) // Megahealth?	Ignore max_health...
	{
		if (other.health >= 250)
			return;
		if (!T_Heal(other, @self.healamount, 1))
			return;
	}
	else
	{
		if (!T_Heal(other, @self.healamount, 0))
			return;
	}
	
	sprint(other, PRINT_LOW, "You receive ");
	s = ftos(@self.healamount);
	sprint(other, PRINT_LOW, s);
	sprint(other, PRINT_LOW, " health\n");
	
// health touch sound
	sound(other, CHAN_ITEM, @self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	
	@self.model = string_null;
	@self.solid = SOLID_NOT;
	// Megahealth = rot down the player's super health
	if (@self.healtype == 2)
	{
		other.items |= IT_SUPERHEALTH;
		//if (deathmatch != 4)
		//{
			@self.nextthink = time + 5;
			@self.think = item_megahealth_rot;
		//}
		@self.owner = other;
	}
	else
	{
		//if (deathmatch != 2)		  // deathmatch 2 is the silly old rules
		//{
			@self.nextthink = time + 20;
			@self.think = SUB_regen;
		//}
	}
	
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};	
void() item_megahealth_rot =
{
	other = @self.owner;
	
	if (other.health > other.max_health)
	{
		other.health = other.health - 1;
		@self.nextthink = time + 1;
		return;
	}
// it is possible for a player to die and respawn between rots, so don't
// just blindly subtract the flag off
	other.items &= ~IT_SUPERHEALTH;
	
	//if (deathmatch != 2)	  // deathmatch 2 is silly old rules
	//{
		@self.nextthink = time + 20;
		@self.think = SUB_regen;
	//}
};
/* + POX - see sheilds.qc
//ARMOR
/* - POX
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
	//POX - Max200 cells (changed from 100)		    
	if (other.ammo_cells > 200)
		other.ammo_cells = 200;		
};
float(float w) RankForWeapon =
{
	if (w == IT_LIGHTNING)
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
float (float w) WeaponCode =
{
	if (w == IT_COMBOGUN)
		return 3;
	if (w == IT_PLASMAGUN)
		return 4;
	if (w == IT_SUPER_NAILGUN)
		return 5;
	if (w == IT_GRENADE_LAUNCHER)
		return 6;
	if (w == IT_ROCKET_LAUNCHER)
		return 7;
	if (w == IT_LIGHTNING)
		return 8;
	return 1;
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
// change @self.weapon if desired
	or = RankForWeapon (@self.weapon);
	nr = RankForWeapon (new);
	if ( nr < or )
		@self.weapon = new;
};
/*
=============
weapon_touch
=============
*/

void() weapon_touch =
{
	local	float	hadammo, best, new = NIL, old;
	local	entity	stemp;
	local	float	leave = NIL;
	// For client weapon_switch
	local	float	w_switch;
	if (!(other.flags & FL_CLIENT))
		return;
	if ((stof(infokey(other,"w_switch"))) == 0)
		w_switch = 8;
	else
		w_switch = stof(infokey(other,"w_switch"));
	
// if the player was using his best weapon, change up to the new one if better		
	stemp = @self;
	@self = other;
	best = W_BestWeapon();
	@self = stemp;
// POX - leave is useless in POX since weapons are never allowed to be picked up if posessed
	//if (deathmatch == 2 || deathmatch == 3 || deathmatch == 5)
	//	leave = 1;
	//else
	//	leave = 0;
// POX - Don't bother checking if weapon is in inventory
	if (other.items & @self.weapon)
	{
		activator = other;
		SUB_UseTargets();	//Just in case it's required to get out of somewhere
		return;
	}
// POX- changed classnames to constants
	switch (@self.weapon) {
		case IT_PLASMAGUN:
			hadammo = other.ammo_rockets;
			new = IT_PLASMAGUN;
			other.ammo_cells += 22;
			break;
		case IT_SUPER_NAILGUN:
			hadammo = other.ammo_rockets;
			new = IT_SUPER_NAILGUN;
			other.ammo_nails += 30;
			break;
		case IT_COMBOGUN:
			hadammo = other.ammo_rockets;
			new = IT_COMBOGUN;
			other.ammo_shells += 5;
			other.ammo_rockets += 2;
			other.which_ammo = 0;	// Change ammo to shells if set to rockets
			break;
		case IT_ROCKET_LAUNCHER:
			hadammo = other.ammo_rockets;			
			new = IT_ROCKET_LAUNCHER;
			other.ammo_rockets += 5;
			break;
		case IT_GRENADE_LAUNCHER:
			hadammo = other.ammo_rockets;			
			new = IT_GRENADE_LAUNCHER;
			other.ammo_rockets += 5;
			break;
		default:
			objerror ("weapon_touch: Unknown classname.");
	}

	sprint (other, PRINT_LOW, "You got the ");
	sprint (other, PRINT_LOW, @self.netname);
	sprint (other, PRINT_LOW, "\n");
// weapon touch sound
	sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	bound_other_ammo ();
// change to the weapon
	old = other.items;
	other.items |= new;
	
	stemp = @self;
	@self = other;
	//POX - check for autoswitch
	if (deathmatch & DM_AUTOSWITCH)
	{
		if ( WeaponCode(new) <= w_switch )
		{
			if (@self.flags & FL_INWATER)
			{
				if (new != IT_LIGHTNING)
				{
					Deathmatch_Weapon (old, new);
				}
			}
			else
			{		 
				Deathmatch_Weapon (old, new);
			}
		}
	}
	else
		@self.weapon = new;
	W_SetCurrentAmmo();
	@self = stemp;
	if (leave)
		return;
	//if (deathmatch!=3 || deathmatch !=5)
	//{
	// remove it in single player, or setup for respawning in deathmatch
		@self.model = string_null;
		@self.solid = SOLID_NOT;
		//if (deathmatch != 2)
			@self.nextthink = time + 30;
		@self.think = SUB_regen;
	//}
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};
// + POX - models/netnames changed
/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supershotgun =
{
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	precache_model ("progs/g_combo.mdl");
	setmodel (@self, "progs/g_combo.mdl");
	@self.weapon = IT_COMBOGUN;
	@self.netname = "Combo Gun";
	@self.touch = weapon_touch;
	setsize (@self, '-16 -16 0', '16 16 56');
	StartItem ();
};
/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_nailgun =
{
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	precache_model ("progs/g_plasma.mdl");
	setmodel (@self, "progs/g_plasma.mdl");
	@self.weapon = IT_PLASMAGUN;
	@self.netname = "Plasma Gun";
	@self.touch = weapon_touch;
	setsize (@self, '-16 -16 0', '16 16 56');
	StartItem ();
};
/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_supernailgun =
{
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	precache_model ("progs/g_nailg.mdl");
	setmodel (@self, "progs/g_nailg.mdl");
	@self.weapon = IT_SUPER_NAILGUN;
	@self.netname = "Nailgun";
	@self.touch = weapon_touch;
	setsize (@self, '-16 -16 0', '16 16 56');
	StartItem ();
};
/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_grenadelauncher =
{
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	precache_model ("progs/g_gren.mdl");
	setmodel (@self, "progs/g_gren.mdl");
	@self.weapon = IT_GRENADE_LAUNCHER;
	@self.netname = "Grenade Launcher";
	@self.touch = weapon_touch;
	setsize (@self, '-16 -16 0', '16 16 56');
	StartItem ();
};
/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void() weapon_rocketlauncher =
{
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	precache_model ("progs/g_rhino.mdl");
	setmodel (@self, "progs/g_rhino.mdl");
	@self.weapon = IT_ROCKET_LAUNCHER;
	@self.netname = "Anihilator";
	@self.touch = weapon_touch;
	setsize (@self, '-16 -16 0', '16 16 56');
	StartItem ();
};
// + POX - PlasmaGun also replaces Thunderbolt in existing levels
void() weapon_lightning =
{
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	precache_model ("progs/g_plasma.mdl");
	setmodel (@self, "progs/g_plasma.mdl");
	@self.weapon = IT_PLASMAGUN;
	@self.netname = "Plasma Gun";
	@self.touch = weapon_touch;
	setsize (@self, '-16 -16 0', '16 16 56');
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
	stemp = @self;
	@self = other;
	best = W_BestWeapon();
	@self = stemp;
// shotgun
	if (@self.weapon == 1)
	{
		if (other.ammo_shells >= 100)
			return;
		other.ammo_shells = other.ammo_shells + @self.aflag;
		//+ POX - switch ammo to shells for ComboGun
		other.which_ammo = 0;
	}
// spikes
	if (@self.weapon == 2)
	{
		if (other.ammo_nails >= 200)
			return;
		other.ammo_nails = other.ammo_nails + @self.aflag;
	}
//	rockets
	if (@self.weapon == 3)
	{
		if (other.ammo_rockets >= 100)
			return;
		other.ammo_rockets = other.ammo_rockets + @self.aflag;
	}
//	cells
	if (@self.weapon == 4)
	{
		// + POX - changed max cells to 200
		if (other.ammo_cells >= 200)
			return;
		other.ammo_cells = other.ammo_cells + @self.aflag;
	}
	bound_other_ammo ();
	
	sprint (other, PRINT_LOW, "You got the ");
	sprint (other, PRINT_LOW, @self.netname);
	sprint (other, PRINT_LOW, "\n");
// ammo touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
// change to a better weapon if appropriate
if (deathmatch & DM_AUTOSWITCH)
{
	if ( other.weapon == best )
	{
		stemp = @self;
		@self = other;
		@self.weapon = W_BestWeapon();
		W_SetCurrentAmmo ();
		@self = stemp;
	}
}
// if changed current ammo, update it
	stemp = @self;
	@self = other;
	W_SetCurrentAmmo();
	@self = stemp;
// remove it in single player, or setup for respawning in deathmatch
	@self.model = string_null;
	@self.solid = SOLID_NOT;
	//if (deathmatch != 2)
		@self.nextthink = time + 30;
// Xian -- If playing in DM 3.0 mode, halve the time ammo respawns	  
//	if (deathmatch == 3 || deathmatch == 5)	       
//		@self.nextthink = time + 15;
	@self.think = SUB_regen;
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};
float WEAPON_BIG2 = 1;
/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_shells =
{
	//if (deathmatch == 4)
	//	return;
	
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	
	@self.touch = ammo_touch;
	if (@self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_shell1.bsp");
		setmodel (@self, "maps/bspmdls/b_shell1.bsp");
		@self.aflag = 40;
	}
	else
	{
		precache_model ("maps/bspmdls/b_shell0.bsp");
		setmodel (@self, "maps/bspmdls/b_shell0.bsp");
		@self.aflag = 20;
	}
	@self.weapon = 1;
	@self.netname = "shells";
	setsize (@self, '0 0 0', '32 32 56');
	StartItem ();
};
/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_spikes =
{
	//if (deathmatch == 4)
	//	return;
	
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	@self.touch = ammo_touch;
	if (@self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_nail1.bsp");
		setmodel (@self, "maps/bspmdls/b_nail1.bsp");
		@self.aflag = 50;
	}
	else
	{
		precache_model ("maps/bspmdls/b_nail0.bsp");
		setmodel (@self, "maps/bspmdls/b_nail0.bsp");
		@self.aflag = 25;
	}
	@self.weapon = 2;
	@self.netname = "nails";
	setsize (@self, '0 0 0', '32 32 56');
	StartItem ();
};
/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_rockets =
{
	//if (deathmatch == 4)
	//	return;
	
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	@self.touch = ammo_touch;
	if (@self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_rock1.bsp");
		setmodel (@self, "maps/bspmdls/b_rock1.bsp");
		@self.aflag = 10;
	}
	else
	{
		precache_model ("maps/bspmdls/b_rock0.bsp");
		setmodel (@self, "maps/bspmdls/b_rock0.bsp");
		@self.aflag = 5;
	}
	@self.weapon = 3;
	@self.netname = "rockets";
	setsize (@self, '0 0 0', '32 32 56');
	StartItem ();
};
/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/
void() item_cells =
{
	//if (deathmatch == 4)
	//	return;
	
	// + POX - no items in FFA mode
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
	@self.touch = ammo_touch;
	if (@self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/bspmdls/b_batt1.bsp");
		setmodel (@self, "maps/bspmdls/b_batt1.bsp");
		@self.aflag = 12;
	}
	else
	{
		precache_model ("maps/bspmdls/b_batt0.bsp");
		setmodel (@self, "maps/bspmdls/b_batt0.bsp");
		@self.aflag = 6;
	}
	@self.weapon = 4;
	@self.netname = "cells";
	setsize (@self, '0 0 0', '32 32 56');
	StartItem ();
};
/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/
float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	// + POX - no items in FFA mode (just in case, for older maps)
	if (deathmatch & DM_FFA)
	{
		remove(@self);
		return;
	}
		
	@self.touch = ammo_touch;
	if (@self.spawnflags & WEAPON_SHOTGUN)
	{
		if (@self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/bspmdls/b_shell1.bsp");
			setmodel (@self, "maps/bspmdls/b_shell1.bsp");
			@self.aflag = 40;
		}
		else
		{
			precache_model ("maps/bspmdls/b_shell0.bsp");
			setmodel (@self, "maps/bspmdls/b_shell0.bsp");
			@self.aflag = 20;
		}
		@self.weapon = 1;
		@self.netname = "shells";
	}
	if (@self.spawnflags & WEAPON_SPIKES)
	{
		if (@self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/bspmdls/b_nail1.bsp");
			setmodel (@self, "maps/bspmdls/b_nail1.bsp");
			@self.aflag = 40;
		}
		else
		{
			precache_model ("maps/bspmdls/b_nail0.bsp");
			setmodel (@self, "maps/bspmdls/b_nail0.bsp");
			@self.aflag = 20;
		}
		@self.weapon = 2;
		@self.netname = "spikes";
	}
	if (@self.spawnflags & WEAPON_ROCKET)
	{
		if (@self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/bspmdls/b_rock1.bsp");
			setmodel (@self, "maps/bspmdls/b_rock1.bsp");
			@self.aflag = 10;
		}
		else
		{
			precache_model ("maps/bspmdls/b_rock0.bsp");
			setmodel (@self, "maps/bspmdls/b_rock0.bsp");
			@self.aflag = 5;
		}
		@self.weapon = 3;
		@self.netname = "rockets";
	}
	
	setsize (@self, '0 0 0', '32 32 56');
	StartItem ();
};
/*
===============================================================================
KEYS
===============================================================================
*/
void() key_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if (other.items & @self.items)
		return;
	sprint (other, PRINT_LOW, "You got the ");
	sprint (other, PRINT_LOW, @self.netname);
	sprint (other,PRINT_LOW, "\n");
	sound (other, CHAN_ITEM, @self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	other.items |= @self.items;
	@self.solid = SOLID_NOT;
	@self.model = string_null;
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};
void() key_setsounds =
{
	if (world.worldtype == 0)
	{
		precache_sound ("misc/medkey.wav");
		@self.noise = "misc/medkey.wav";
	}
	if (world.worldtype == 1)
	{
		precache_sound ("misc/runekey.wav");
		@self.noise = "misc/runekey.wav";
	}
	if (world.worldtype == 2)
	{
		precache_sound2 ("misc/basekey.wav");
		@self.noise = "misc/basekey.wav";
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
		setmodel (@self, "progs/w_s_key.mdl");
		@self.netname = "silver key";
	}
	else if (world.worldtype == 1)
	{
		precache_model ("progs/m_s_key.mdl");
		setmodel (@self, "progs/m_s_key.mdl");
		@self.netname = "silver runekey";
	}
	else if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_s_key.mdl");
		setmodel (@self, "progs/b_s_key.mdl");
		@self.netname = "silver keycard";
	}
	key_setsounds();
	@self.touch = key_touch;
	@self.items = IT_KEY1;
	setsize (@self, '-16 -16 -24', '16 16 32');
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
		setmodel (@self, "progs/w_g_key.mdl");
		@self.netname = "gold key";
	}
	if (world.worldtype == 1)
	{
		precache_model ("progs/m_g_key.mdl");
		setmodel (@self, "progs/m_g_key.mdl");
		@self.netname = "gold runekey";
	}
	if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_g_key.mdl");
		setmodel (@self, "progs/b_g_key.mdl");
		@self.netname = "gold keycard";
	}
	key_setsounds();
	@self.touch = key_touch;
	@self.items = IT_KEY2;
	setsize (@self, '-16 -16 -24', '16 16 32');
	StartItem ();
};
/*
===============================================================================
END OF LEVEL RUNES
===============================================================================
*/
void() sigil_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	
	@self.target_id_finished = time + 4;//POX don't let TargetID override centerprints
	
	centerprint (other, "You got the rune!");
	sound (other, CHAN_ITEM, @self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	@self.solid = SOLID_NOT;
	@self.model = string_null;
	serverflags &= ~15;
	@self.classname = "";		// so rune doors won't find it
	
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};

/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/
void() item_sigil =
{
	if (!@self.spawnflags)
		objerror ("no spawnflags");

	precache_sound ("misc/runekey.wav");
	@self.noise = "misc/runekey.wav";
	if (@self.spawnflags & 1) {
		precache_model ("progs/end1.mdl");
		setmodel (@self, "progs/end1.mdl");
	} if (@self.spawnflags & 2) {
		precache_model2 ("progs/end2.mdl");
		setmodel (@self, "progs/end2.mdl");
	} if (@self.spawnflags & 4) {
		precache_model2 ("progs/end3.mdl");
		setmodel (@self, "progs/end3.mdl");
	} if (@self.spawnflags & 8) {
		precache_model2 ("progs/end4.mdl");
		setmodel (@self, "progs/end4.mdl");
	}

	@self.touch = sigil_touch;
	setsize (@self, '-16 -16 -24', '16 16 32');
	StartItem ();
};
/*
===============================================================================
POWERUPS
===============================================================================
*/
void() powerup_touch;
void() powerup_touch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	sprint (other, PRINT_LOW, "You got the ");
	sprint (other,PRINT_LOW,  @self.netname);
	sprint (other,PRINT_LOW, "\n");
	@self.mdl = @self.model;
	
	if ((@self.classname == "item_artifact_invulnerability") ||
		(@self.classname == "item_artifact_invisibility"))
		@self.nextthink = time + 75; // POX - 5 minutes was way too long (not that these are in any maps)
	else
		@self.nextthink = time + 60;
	
	@self.think = SUB_regen;
	sound (other, CHAN_VOICE, @self.noise, 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	@self.solid = SOLID_NOT;
	other.items |= @self.items;
	@self.model = string_null;
// do the apropriate action
	if (@self.classname == "item_artifact_envirosuit")
	{
		other.rad_time = 1;
		other.radsuit_finished = time + 30;
	}
	
	if (@self.classname == "item_artifact_invulnerability")
	{
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
	}
	
	if (@self.classname == "item_artifact_invisibility")
	{
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
	}
	if (@self.classname == "item_artifact_super_damage")
	{
		@self.quadcore.mdl = @self.quadcore.model;
		@self.quadcore.model = string_null;
		
		other.super_time = 1;
		other.super_damage_finished = time + 30;
	}      
	activator = other;
	SUB_UseTargets();				// fire all targets / killtargets
};
//POX - just changed the look of these (and some respawn times)

/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
	@self.touch = powerup_touch;
	precache_model ("progs/poxmegs.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	@self.noise = "items/protect.wav";
	setmodel (@self, "progs/poxmegs.mdl");
	@self.netname = "MegaShields";
	@self.effects |= EF_RED;
	@self.items = IT_INVULNERABILITY;
	setsize (@self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
	@self.touch = powerup_touch;
	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");
	@self.noise = "items/suit.wav";
	setmodel (@self, "progs/suit.mdl");
	@self.netname = "Biosuit";
	@self.items = IT_SUIT;
	setsize (@self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
	// + POX - Everyone's already invisible in DM_PREDATOR
	if (deathmatch & DM_PREDATOR)
		remove(@self);
	
	@self.touch = powerup_touch;
	precache_model ("progs/cloak.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	@self.noise = "items/inv1.wav";
	setmodel (@self, "progs/cloak.mdl");
	@self.netname = "Cloaking Device";
	@self.items = IT_INVISIBILITY;
	setsize (@self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

//POX - A little hack to get a multi-model item for a cool effect
void() Spawn_QuadCore =
{	
	local	entity qcore;
	
	qcore = spawn ();
	qcore.owner = @self;	
	qcore.solid = SOLID_TRIGGER;
	qcore.movetype = MOVETYPE_TOSS;
	
	setmodel (qcore, "progs/poxquad2.mdl");
	setsize (qcore, '-16 -16 -24', '16 16 32');
	
	qcore.velocity = '0 0 0';
	setorigin(qcore, @self.origin);
	qcore.origin_z = qcore.origin_z + 6;
	
	@self.quadcore = qcore;
	
	qcore.nextthink = time + 999999999;
	qcore.think = NIL;
};

/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
	@self.touch = powerup_touch;
	precache_model ("progs/poxquad.mdl");
	precache_model ("progs/poxquad2.mdl");
	
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	
	@self.noise = "items/damage.wav";
	setmodel (@self, "progs/poxquad.mdl");
	@self.netname = "Quad Damage";
	@self.items = IT_QUAD;
	@self.effects |= EF_BLUE;
	setsize (@self, '-16 -16 -24', '16 16 32');
	
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
	local float		best, old, new;
	local entity	stemp;
	local float		acount;
	local float		b_switch;

	//if (deathmatch == 4)
	//	if (other.invincible_time > 0)
	//		return;
	if ((stof (infokey (other, "b_switch"))) == 0)
		b_switch = 8;
	else
		b_switch = stof(infokey(other,"b_switch"));
	
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
		
	acount = 0;
	sprint (other, PRINT_LOW, "You get ");
 
	/*
	if (deathmatch == 4)
	{	
		other.health = other.health + 10;
		sprint (other, PRINT_LOW, "10 additional health\n");
		if ((other.health > 250) && (other.health < 300))
			sound (other, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
		else
			sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
		stuffcmd (other, "bf\n");
		remove(@self);
		if (other.health >299)
		{		
			if (other.invincible_time != 1)
			{			
				other.invincible_time = 1;
				other.invincible_finished = time + 30;
				other.items |= IT_INVULNERABILITY;
				
				other.super_time = 1;
				other.super_damage_finished = time + 30;
				other.items |= IT_QUAD;
				other.ammo_cells = 0;		
		
	
				sound (other, CHAN_VOICE, "boss1/sight1.wav", 1, ATTN_NORM);
				stuffcmd (other, "bf\n");		
				bprint (PRINT_HIGH, other.netname);
				bprint (PRINT_HIGH, " attains bonus powers!!!\n");
			}
		}
		@self = other;
		return;
	}*/
	
	if (@self.items)
		if ((other.items & @self.items) == 0) {
			acount = 1;
			sprint (other, PRINT_LOW, "the ");
			sprint (other, PRINT_LOW, @self.netname);
		}
 
// if the player was using his best weapon, change up to the new one if better		
	stemp = @self;
	@self = other;
	best = W_BestWeapon ();
	@self = stemp;
// change weapons
	other.ammo_shells += @self.ammo_shells;
	other.ammo_nails += @self.ammo_nails;
	other.ammo_rockets += @self.ammo_rockets;
	other.ammo_cells += @self.ammo_cells;

	new = @self.items;
	if (!new)
		new = other.weapon;
	old = other.items;
	other.items |= @self.items;
	
	bound_other_ammo ();
	if (@self.ammo_shells) {
		if (acount)
			sprint(other, PRINT_LOW, ", ");
		acount = 1;
		s = ftos(@self.ammo_shells);
		sprint (other, PRINT_LOW, s);
		sprint (other, PRINT_LOW, " shells");
	} if (@self.ammo_nails) {
		if (acount)
			sprint(other, PRINT_LOW, ", ");
		acount = 1;
		s = ftos(@self.ammo_nails);
		sprint (other, PRINT_LOW, s);
		sprint (other, PRINT_LOW, " nails");
	} if (@self.ammo_rockets) {
		if (acount)
			sprint(other, PRINT_LOW, ", ");
		acount = 1;
		s = ftos(@self.ammo_rockets);
		sprint (other, PRINT_LOW, s);
		sprint (other, PRINT_LOW, " rockets");
	} if (@self.ammo_cells) {
		if (acount)
			sprint(other, PRINT_LOW, ", ");
		acount = 1;
		s = ftos(@self.ammo_cells);
		sprint (other, PRINT_LOW, s);
		sprint (other,PRINT_LOW, " cells");
	}
	
	//if ( (deathmatch==3 || deathmatch == 5) & ( (WeaponCode(new)==6) || (WeaponCode(new)==7) ) & (other.ammo_rockets < 5) )
	//	other.ammo_rockets = 5;
	
	// + POX - Health in packs for FFA mode
	if (@self.healamount)
	{
		if (!T_Heal(other, @self.healamount, 0)) {
			SUB_Null ();
		} else {
			if (acount)
				sprint(other, PRINT_LOW, ", ");

			s = ftos(@self.healamount);
			sprint(other, PRINT_LOW, " ");
			sprint(other, PRINT_LOW, s);
			sprint(other, PRINT_LOW, " health");
		}
	}
	// - POX
	
	sprint (other, PRINT_LOW, "\n");
// backpack touch sound
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	remove(@self);
	@self = other;
	
// change to the weapon
	
//POX - dm_autoswitch check
if (deathmatch & DM_AUTOSWITCH)
{	
	if ( WeaponCode(new) <= b_switch )
	{
		if (@self.flags & FL_INWATER)
		{
			if (new != IT_LIGHTNING)
			{
				Deathmatch_Weapon (old, new);
			}
		}
		else
		{		 
			Deathmatch_Weapon (old, new);
		}
	}
}
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
	
	// + POX - DM_FFA check
	if (!(@self.ammo_shells + @self.ammo_nails + @self.ammo_rockets + @self.ammo_cells) && !(deathmatch & DM_FFA))
		return; // nothing in it
	item = spawn();
	item.origin = @self.origin - '0 0 24';
	
	// + POX - DM_FFA (Only health in packs)
	if (!(deathmatch & DM_FFA))	{
		item.items = @self.weapon;
		if (item.items == IT_AXE)
			item.netname = "Axe";
		else if (item.items == IT_TSHOT)
			item.netname = "tShot";
		else if (item.items == IT_COMBOGUN)
			item.netname = "Combo Gun";
		else if (item.items == IT_PLASMAGUN)
			item.netname = "Plasma Gun";
		else if (item.items == IT_SUPER_NAILGUN)
			item.netname = "Nail Gun";
		else if (item.items == IT_GRENADE_LAUNCHER)
			item.netname = "Grenade Launcher";
		else if (item.items == IT_ROCKET_LAUNCHER)
			item.netname = "Annihilator";
		else
			item.netname = "";
	} else {
		item.healamount = 25;
		item.healtype = 1;
	}

	item.ammo_shells = @self.ammo_shells;
	item.ammo_nails = @self.ammo_nails;
	item.ammo_rockets = @self.ammo_rockets;
	
	// round rockets up to nearest integer incase someone died between rhino barrel fires
	item.ammo_rockets = rint (item.ammo_rockets);
	item.ammo_cells = @self.ammo_cells;
	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);
	
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
	// + POX - changed to 30 secs
	item.nextthink = time + 30;    // remove after 1 minutes
	item.think = SUB_Remove;
};
