#include "common.qh"

#include "misc.qh"
#include "override.qh"

#include "mdl.qh"
#include "mdl_player.qh"
#include "mdl_void.qh"

#include "act_player.qh"
#include "act_dead.qh"

#include "equip.qh"
#include "items.qh"
#include "menu.qh"

#include "weapon.qh"
#include "server.qh"
#include "damage.qh"

#include "teleport.qh"

void() client_init = {
	precache_model("progs/player.mdl");
	precache_model("progs/eyes.mdl");
};

// This is the first function called by C code for a new player.
void() SetNewParms = {
	parm1 = CONFIG_START_CURRENCY;
	
	parm2 = parm3 = parm4 = parm5 = 0;

	parm6 = CONFIG_START_HEALTH + CONFIG_START_ARMOR*999;
	parm7 = CONFIG_START_ARMOR_TYPE;
	parm8 = CONFIG_MAX_HEALTH + CONFIG_MAX_ARMOR*999;

	parm9 = CONFIG_START_SHELLS + CONFIG_START_NAILS*999;
	parm10 = CONFIG_START_ROCKETS + CONFIG_START_CELLS*999;
	parm11 = CONFIG_MAX_SHELLS + CONFIG_MAX_NAILS*999;
	parm12 = CONFIG_MAX_ROCKETS + CONFIG_MAX_CELLS*999;

	parm15 = weapon_player_parm1_default();
	parm16 = EQUIP_STATE_CHOOSE;
};

void() SetDeadParms = {
	SetNewParms();
};

// Called when about to change maps
void() SetChangeParms = {
	/* Currency */
	parm1 = self.currency;

	/* Purchased items */
	parm2 = self.itemfield_1;
	parm3 = self.itemfield_2;
	parm4 = self.itemfield_3;
	parm5 = self.itemfield_4;

	/* Health and such */
	if (self.health < 0) self.health = 0;

	parm6 = self.health + self.armorvalue*999;
	parm7 = self.armortype;
	parm8 = self.max_health + self.max_armor*999;

	/* Ammo */
	parm9 = self.ammo_shells + self.ammo_nails*999;
	parm10 = self.ammo_rockets + self.ammo_cells*999;
	parm11 = self.max_ammo_shells + self.max_ammo_nails*999;
	parm12 = self.max_ammo_rockets + self.max_ammo_cells*999;

	/* Wheeee */
	parm15 = weapon_player_parm1();
	parm16 = self.equip_state;

	/* H4x0r */
	if (self.deadflag)
		SetDeadParms();
};

void() DecodeParms = {
	/* Currency */
	self.currency = parm1;

	/* Purchased items */
	self.itemfield_1 = parm2;
	self.itemfield_2 = parm3;
	self.itemfield_3 = parm4;
	self.itemfield_4 = parm5;

	equip_grant(self, EQUIPID_SHOTGUN);

	/* Health and such */
	self.armorvalue = floor(parm6 / 999);
	self.armortype = parm7;

	self.health = parm6 - self.armorvalue*999;

	self.max_armor = floor(parm8 / 999);
	self.max_health = parm8 - self.max_armor*999;

	/* Ammo */
	self.ammo_nails = floor(parm9 / 999);
	self.ammo_shells = parm9 - self.ammo_nails*999;

	self.ammo_rockets = floor(parm10 / 999);
	self.ammo_cells = parm10 - self.ammo_rockets*999;

	self.max_ammo_nails = floor(parm11 / 999);
	self.max_ammo_shells = parm11 - self.max_ammo_nails*999;

	self.max_ammo_rockets = floor(parm12 / 999);
	self.max_ammo_cells = parm12 - self.max_ammo_rockets*999;

	/* Wheeee */
	weapon_player_parm1_decode(parm15);
	self.equip_state = parm16;

	SetDeadParms();
};

void() RemoveClientFromGame = {
	self.classname = "player_outofgame";
	mdl_setup_void();
	act_setup_dead();
};

void() PutClientInGame = {
	local entity ent;
	local float spawncount;

	menu_set(NOTHING_function);

	self.classname = "player";

	DecodeParms();

	mdl_setup_player();
	act_setup_player();

	self.velocity = '0 0 0';
	self.flags &= ~FL_INWATER;

	/* FIXME: Hack to avoid jumping on spawn.... */
	self.velocity_z = -270;

	/* Select a spawn point.. */
	for (spawncount = 5; spawncount > 0; spawncount--) {
		spawn_head = random_enemy_chain(spawn_head);
		ent = findradius(spawn_head.origin, 100);
		while (ent) {
			if (ent.classname == "player")
				break;
			ent = ent.chain;
		}
		
		if (!ent)
			break;
	}

	teleport(self, spawn_head);
};

// Called right after ClientConnect, and on new maps.
void() PutClientInServer = {
	local entity spot;

	/* Hack to get pmodel for servers that check it */
	self.model = "progs/player.mdl";
	self.modelindex = 0;

	intermission_head = spot = random_enemy_chain(intermission_head);
	self.origin = spot.origin;
	self.angles = spot.angles;
	self.fixangle = TRUE;

	self.velocity = '0 0 0';

	weapon_player_init();

	menu_set(menu_intro);

	RemoveClientFromGame();
};

void() _deathmsg_suicide = {
	local float r;
	local string nname;
	
	nname = name(self);
	
	r = random();
	if (r < 0.25)		bprint(PRINT_DEATH, nname, " says good bye to this cruel world.\n");
	else if (r < 0.5)	bprint(PRINT_DEATH, nname, " takes the easy way out.\n");
	else if (r < 0.75)	bprint(PRINT_DEATH, nname, " suicides.\n");
	else			bprint(PRINT_DEATH, nname, " stands at the wrong end of his shotgun.\n");
};

// C Code calls this when the player issues a 'kill' command.
void()
ClientKill = {
	damage(self, self, self, DAMAGE_MUSTDIE, _deathmsg_suicide);
};

void() _client_th_kill = {
	if (other == self)	self.frags--;
	else			self.frags++;
	logfrag(self, other);
};

// Called after the client is fully connected
void() ClientConnect = {
	bprint(PRINT_HIGH, name(self), " connected\n");
	self.flags |= FL_CLIENT;

	override_set_th_kill(self, _client_th_kill);
};

// Called when the client disconnects
void() ClientDisconnect = {
	self.flags = 0;
	bprint(PRINT_HIGH, name(self), " disconnected with ", ftos(self.frags), " frags\n");

	override_set_th_kill(self, NOTHING_function);
	self.deathmsg1 = NULL_string;
	damage(self, self, self, DAMAGE_MUSTDIE, NOTHING_function);
};
