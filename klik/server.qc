#include "common.qh"

#include "server.qh"

#include "damage.qh"
#include "bodyque.qh"
#include "weapon.qh"
#include "client.qh"
#include "sz_watch.qh"

#include "mdl_player.qh"
#include "mdl_eyes.qh"

#include "act_player.qh"

#include "delays.qh"

#include "mapents.qh"

float max_clients;

// Various cvars [possibly] referenced by QC
float rocket_jump;

float sv_mintic, sv_maxtic;

float sv_gravity;
float sv_stopspeed, sv_maxspeed, sv_spectatormaxspeed;
float sv_accelerate, sv_airaccelerate, sv_wateraccelerate;
float sv_friction, sv_waterfriction;

float cl_rollangle, cl_rollspeed;

#define	SV_FRAMES_BEFORE_SPAWN	3

void() main = {
	local entity walk;

	/* Must be first. */
	max_clients = 0;
	walk = world;
	while (walk = nextent(walk)) max_clients++;

	sv_spawning = SV_FRAMES_BEFORE_SPAWN;

	damage_init();
	bodyque_init();
	weapon_init();
	client_init();
	SZ_init();

	mdl_player_init();
	mdl_eyes_init();

	act_player_init();
};

float players_frame_started;
void() StartFrame = {
	if (sv_spawning) {
		sv_spawning = sv_spawning - 1;
		if (!sv_spawning) {
			if (!intermission_head)
				intermission_head = spawn_head;

			if (!spawn_head)
				error("Unable to find a spawn point.\n");
		}
	}

	SZ_frame();

	rocket_jump = stof(infokey(world, "rj"));
	if (rocket_jump <= 1) rocket_jump = 0;

	sv_mintic = cvar("sv_mintic");
	sv_maxtic = cvar("sv_maxtic");

	sv_gravity = cvar("sv_gravity");

	sv_stopspeed = cvar("sv_stopspeed");
	sv_maxspeed = cvar("sv_maxspeed");
	sv_spectatormaxspeed = cvar("sv_spectatormaxspeed");

	sv_accelerate = cvar("sv_accelerate");
	sv_airaccelerate = cvar("sv_airaccelerate");
	sv_wateraccelerate = cvar("sv_wateraccelerate");

	sv_friction = cvar("sv_friction");
	sv_waterfriction = cvar("sv_waterfriction");

	cl_rollangle = cvar("cl_rollangle");
	cl_rollspeed = cvar("cl_rollspeed");

	PlayerStartFrame();
	players_frame_started = -1;
};

/* This is really called by QSG engines */
// void() EndFrame = { };

void() PlayerStartFrame = {
	if (players_frame_started == -1) {
		/* First player after StartFrame */
		players_frame_started = TRUE;
		return;
	}

	if (players_frame_started)
		return;

	players_frame_started = TRUE;

	delays_swapin_stats_all();
};

void() PlayerEndFrame = {
	/* Unfortunately, a newmis can us damage this frame,
	   after our postthink has been called.  Damn. */
	/* We just force an update this frame for now. */
	if (newmis) {
		delays_force_update_all();
	} else {
		players_frame_started = FALSE;
		delays_swapout_stats_all();
	}
};
