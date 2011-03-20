#include "common.qh"
#include "misc.qh"

#include "mapents.qh"
#include "mapents_util.qh"
#include "items.qh"
#include "mapents_triggers.qh"
#include "mapents_items.qh"
#include "mapents_movewall.qh"

#include "equip.qh"

// ===============================================================

/*QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
*/
void ()
info_null =
{
	remove (self);
};

// ===============================================================

/*QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
*/
void ()
light_fluoro =
{
	self.noise = "ambience/fl_hum1.wav";
	light ();
};

/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
void ()
light_fluorospark =
{
	if (!self.style)
		self.style = 10;

	self.noise = "ambience/buzz1.wav";
	light();
};

/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
void ()
light_globe =
{
	self.model = "progs/s_light.spr";
	light();
};

/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
*/
void ()
light_torch_small_walltorch =
{
	self.model = "progs/flame.mdl";
	self.noise = "ambience/fire1.wav";
	light ();
};

/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
*/
void ()
light_flame_large_yellow =
{
	self.model = "progs/flame2.mdl";
	self.frame = 1;
	self.noise = "ambience/fire1.wav";
	light ();
};

/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
*/
void ()
light_flame_small_yellow =
{
	self.model = "progs/flame2.mdl";
	self.noise = "ambience/fire1.wav";
	light ();
};

/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
*/
void ()
light_flame_small_white =
{
	self.model = "progs/flame2.mdl";
	self.noise = "ambience/fire1.wav";
	light ();
};

// ====================================================================

/*QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY
*/
void ()
misc_explobox2 =
{
	self.model = "maps/b_exbox2.bsp";
	self.noise = "weapons/r_exp3.wav";
	self.dmg = 160;

	if (!self.mins && !self.maxs) {
		self.mins = '0 0 0';
		self.maxs = '32 32 32';
	}

	misc_explobox ();
};

// ====================================================================

/*QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_suck_wind =
{
	self.noise = "ambience/suck1.wav";
	self.volume = 1.0;
	info_notnull ();
};

/*QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_drone =
{
	self.noise = "ambience/drone6.wav";
	info_notnull ();
};

/*QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_flouro_buzz =
{
	self.noise = "ambience/buzz1.wav";
	self.volume = 1.0;
	info_notnull ();
};

/*QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_drip =
{
	self.noise = "ambience/drip1.wav";
	info_notnull ();
};

/*QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_comp_hum =
{
	self.noise = "ambience/comp1.wav";
	self.volume = 1.0;
	info_notnull ();
};

/*QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_thunder =
{
	self.noise = "ambience/thunder1.wav";
	info_notnull ();
};

/*QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_light_buzz =
{
	self.noise = "ambience/fl_hum1.wav";
	info_notnull ();
};

/*QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_swamp1 =
{
	self.noise = "ambience/swamp1.wav";
	info_notnull ();
};

/*QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
*/
void ()
ambient_swamp2 =
{
	self.noise = "ambience/swamp2.wav";
	info_notnull ();
};

// ===========================================================================

void ()
path_corner =
{
	info_notnull ();
};

// ===========================================================================

/*QUAKED trigger_multiple (.5 .5 .5) ? notouch
Variable sized repeatable trigger.  Must be targeted at one or more entities.
If "health" is set, the trigger must be killed to activate each time.
If "delay" is set, the trigger waits some time after activating before firing.
"wait" : Seconds between triggerings. (.2 default)
If notouch is set, the trigger is only fired by other entities, not by touching.
NOTOUCH has been obsoleted by trigger_relay!
sounds
1)      secret
2)      beep beep
3)      large switch
4)
set "message" to text string
*/
void ()
trigger_multiple =
{
	switch (self.sounds) {
	case 1:
		self.noise1 = "misc/secret.wav";
		break;
	case 2:
		self.noise1 = "misc/talk.wav";
		break;
	case 3:
		self.noise1 = "misc/trigger1.wav";
		break;
	}

	trigger_generic ();

	if (!self.wait)
		self.wait = 0.2;

	self.count = 0;
};

/*QUAKED trigger_once (.5 .5 .5) ? notouch
*/
void ()
trigger_once =
{
	trigger_multiple ();
	self.count = 1;
};

/*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
*/
void ()
trigger_relay =
{
	self.spawnflags |= SPAWNFLAGS_TRIGGER_NOTOUCH;
	trigger_multiple ();
};

#define SPAWNFLAGS_NOMESSAGE 1
void ()
_trigger_counter_use =
{
	local float doprint;

	doprint = !(self.spawnflags & SPAWNFLAGS_NOMESSAGE) && is_cl (other);

	self.count--;
	if (self.count <= 0) {
		if (doprint) centerprint (other, "Sequence completed!");

		self.count = self.max_health;
		util_use_targets ();
	} else {
		if (doprint) {
			if (self.count > 3)
				centerprint (other, "There are more to go...");
			else if (self.count > 2)
				centerprint (other, "Only 3 more to go...");
			else if (self.count > 1)
				centerprint (other, "Only 2 more to go...");
			else
				centerprint (other, "Only 1 more to go...");
		}
	}
};

/*QUAKED trigger_counter (.5 .5 .5) ? SPAWNFLAGS_NOMESSAGE
Wait decrease count by 1 until it reaches 0, then activate targets.
*/
void ()
trigger_counter =
{
	util_map_entity_init ();

	self.model = nil;
	self.modelindex = 0;

	if (!self.count)
		self.count = 2;

	self.use = _trigger_counter_use;

	self.think = util_map_entity_cull;
	self.nextthink = time + 0.1;
};

/*QUAKED trigger_secret (.5 .5 .5) ?
*/
void ()
trigger_secret =
{
	if (!self.message)
		self.message = "You found a secret area!";
	if (!self.sounds)
		self.sounds = 1;
	if (self.sounds > 2)
		self.sounds = 0;

	trigger_multiple ();

	self.count = 1;
};

/*QUAKED trigger_setskill (.5 .5 .5) ?
sets skill level to the value of "message".
Only used on start map.
*/
void ()
trigger_setskill =
{
	remove (self);
};

/*QUAKED trigger_onlyregistered (.5 .5 .5) ?
Only fires if playing the registered version, otherwise prints the message
*/
void ()
trigger_onlyregistered =
{
	self.message = "";
	self.wait = -1;
	trigger_generic ();
};

/*QUAKED trigger_monsterjump (.5 .5 .5) ?
Walking monsters that touch this will jump in the direction of the trigger's angle
"speed" default to 200, the speed thrown forward
"height" default to 200, the speed thrown upwards
*/
void ()
trigger_monsterjump =
{
	remove (self);
};

/*QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
*/
void ()
func_episodegate =
{
	if (!(serverflags & self.spawnflags)) {
		remove (self);
		return;
	}
	
	func_wall ();
};

/*QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
*/
void ()
func_bossgate =
{
	if ((serverflags & 15) == 15) {
		remove (self);
		return;
	}
	
	func_wall ();
};


/* Monsters */
void () monster_boss =		{ remove(self); };
void () monster_demon1 =	{ remove(self); };
void () monster_dog =		{ remove(self); };
void () monster_enforcer =	{ remove(self); };
void () monster_fish =		{ remove(self); };
void () monster_hell_knight =	{ remove(self); };
void () monster_knight =		{ remove(self); };
void () monster_ogre =		{ remove(self); };
void () monster_ogre_marksman =	{ remove(self); };
void () monster_oldone =		{ remove(self); };
void () monster_shalrath =	{ remove(self); };
void () monster_shambler =	{ remove(self); };
void () monster_army =		{ remove(self); };
void () monster_tarbaby =	{ remove(self); };
void () monster_wizard =		{ remove(self); };
void () monster_zombie =		{ remove(self); };

// =========================================================================

void ()
item_weapon =
{
	if (!self.noise2)
		self.noise2 = "weapons/pkup.wav";
	if (!self.mins && !self.maxs) {
		self.mins = '-16 -16 0';
		self.maxs = '16 16 56';
	}
	if (!self.wait && !self.delay) {
		self.wait = 25;
		self.delay = 10;
	}
	item_generic ();
};

/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
weapon_supershotgun =
{
	self.netname = STR_EQUIPID_SUPER_SHOTGUN;
	if (!self.model)
		self.model = "progs/g_shot.mdl";
	if (!self.ammo_shells)
		self.ammo_shells = 5;
	equip_grant (self, EQUIPID_SUPER_SHOTGUN);
	item_weapon ();
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
weapon_nailgun =
{
	self.netname = STR_EQUIPID_NAILGUN;
	if (!self.model)
		self.model = "progs/g_nail.mdl";
	if (!self.ammo_nails)
		self.ammo_nails = 30;
	equip_grant (self, EQUIPID_NAILGUN);
	item_weapon ();
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
weapon_supernailgun =
{
	self.netname = STR_EQUIPID_SUPER_NAILGUN;
	if (!self.model)
		self.model = "progs/g_nail2.mdl";
	if (!self.ammo_nails)
		self.ammo_nails = 30;
	equip_grant (self, EQUIPID_SUPER_NAILGUN);
	item_weapon ();
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
weapon_grenadelauncher =
{
	self.netname = STR_EQUIPID_GRENADE_LAUNCHER;
	if (!self.model)
		self.model = "progs/g_rock.mdl";
	if (!self.ammo_rockets)
		self.ammo_rockets = 5;
	equip_grant (self, EQUIPID_GRENADE_LAUNCHER);
	item_weapon ();
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
weapon_rocketlauncher =
{
	self.netname = STR_EQUIPID_ROCKET_LAUNCHER;
	if (!self.model)
		self.model = "progs/g_rock2.mdl";
	if (!self.ammo_rockets)
		self.ammo_rockets = 5;
	equip_grant (self, EQUIPID_ROCKET_LAUNCHER);
	item_weapon ();
};

/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
weapon_lightning =
{
	self.netname = STR_EQUIPID_LIGHTNING_GUN;
	if (!self.model)
		self.model = "progs/g_light.mdl";
	if (!self.ammo_cells)
		self.ammo_cells = 15;
	equip_grant (self, EQUIPID_LIGHTNING_GUN);
	item_weapon ();
};

// ========================================================================

#define SPAWNFLAGS_AMMO_BIG 1

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) BIG
*/
void ()
item_shells =
{
	if (self.spawnflags & SPAWNFLAGS_AMMO_BIG) {
		self.model = "maps/b_shell1.bsp";
		self.ammo_shells = 40;
	} else {
		self.model = "maps/b_shell0.bsp";
		self.ammo_shells = 20;
	}
	item_ammo ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) BIG
*/
void ()
item_spikes =
{
	if (self.spawnflags & SPAWNFLAGS_AMMO_BIG) {
		self.model = "maps/b_nail1.bsp";
		self.ammo_nails = 50;
	} else {
		self.model = "maps/b_nail0.bsp";
		self.ammo_nails = 25;
	}
	item_ammo ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) BIG
*/
void ()
item_rockets =
{
	if (self.spawnflags & SPAWNFLAGS_AMMO_BIG) {
		self.model = "maps/b_rock1.bsp";
		self.ammo_rockets = 10;
	} else {
		self.model = "maps/b_rock0.bsp";
		self.ammo_rockets = 5;
	}
	item_ammo ();
};

/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) BIG
*/
void ()
item_cells =
{
	if (self.spawnflags & SPAWNFLAGS_AMMO_BIG) {
		self.model = "maps/b_batt1.bsp";
		self.ammo_cells = 12;
	} else {
		self.model = "maps/b_batt0.bsp";
		self.ammo_cells = 6;
	}
	item_ammo ();
};


// ========================================================================

/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
item_armor1 =
{
	self.skin = 0;
	self.armorvalue = 100;
	self.armortype = 0.3;
	item_armor ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
item_armor2 =
{
	self.skin = 1;
	self.armorvalue = 150;
	self.armortype = 0.6;
	item_armor ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/
void ()
item_armorInv =
{
	self.skin = 2;
	self.armorvalue = 200;
	self.armortype = 0.8;
	item_armor ();
};

// ========================================================================

/*QUAKED misc_teleporttrain (0 .5 .8) (-8 -8 -8) (8 8 8)
*/
void ()
misc_teleporttrain =
{
	self.model = "progs/teleport.mdl";
	self.dmg = -1;

	self.avelocity = '100 200 300';

	func_train ();
};
