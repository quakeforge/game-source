#include "config.rh"

#include "paroxysm.rh"

void() bubble_bob;

void() InitBodyQue;
void() main =
{
	dprint ("main function\n");
	
	// these are just commands the the prog compiler to copy these files
	precache_file ("progs.dat");
	precache_file ("gfx.wad");
	precache_file ("quake.rc");
	precache_file ("default.cfg");

	precache_file ("end1.bin");
	precache_file2 ("end2.bin");

	precache_file ("demo1.dem");
	precache_file ("demo2.dem");
	precache_file ("demo3.dem");

	// these are all of the lumps from the cached.ls files
	precache_file ("gfx/palette.lmp");
	precache_file ("gfx/colormap.lmp");

	precache_file2 ("gfx/pop.lmp");

	precache_file ("gfx/complete.lmp");
	precache_file ("gfx/inter.lmp");

	precache_file ("gfx/ranking.lmp");
	precache_file ("gfx/vidmodes.lmp");
	precache_file ("gfx/finale.lmp");
	precache_file ("gfx/conback.lmp");
	precache_file ("gfx/qplaque.lmp");

	precache_file ("gfx/menudot1.lmp");
	precache_file ("gfx/menudot2.lmp");
	precache_file ("gfx/menudot3.lmp");
	precache_file ("gfx/menudot4.lmp");
	precache_file ("gfx/menudot5.lmp");
	precache_file ("gfx/menudot6.lmp");

	precache_file ("gfx/menuplyr.lmp");
	precache_file ("gfx/bigbox.lmp");
	precache_file ("gfx/dim_modm.lmp");
	precache_file ("gfx/dim_drct.lmp");
	precache_file ("gfx/dim_ipx.lmp");
	precache_file ("gfx/dim_tcp.lmp");
	precache_file ("gfx/dim_mult.lmp");
	precache_file ("gfx/mainmenu.lmp");
	
	precache_file ("gfx/box_tl.lmp");
	precache_file ("gfx/box_tm.lmp");
	precache_file ("gfx/box_tr.lmp");
	
	precache_file ("gfx/box_ml.lmp");
	precache_file ("gfx/box_mm.lmp");
	precache_file ("gfx/box_mm2.lmp");
	precache_file ("gfx/box_mr.lmp");
	
	precache_file ("gfx/box_bl.lmp");
	precache_file ("gfx/box_bm.lmp");
	precache_file ("gfx/box_br.lmp");
	
	precache_file ("gfx/sp_menu.lmp");
	precache_file ("gfx/ttl_sgl.lmp");
	precache_file ("gfx/ttl_main.lmp");
	precache_file ("gfx/ttl_cstm.lmp");
	
	precache_file ("gfx/mp_menu.lmp");
	
	precache_file ("gfx/netmen1.lmp");
	precache_file ("gfx/netmen2.lmp");
	precache_file ("gfx/netmen3.lmp");
	precache_file ("gfx/netmen4.lmp");
	precache_file ("gfx/netmen5.lmp");
	
	precache_file ("gfx/sell.lmp");
	
	precache_file ("gfx/help0.lmp");
	precache_file ("gfx/help1.lmp");
	precache_file ("gfx/help2.lmp");
	precache_file ("gfx/help3.lmp");
	precache_file ("gfx/help4.lmp");
	precache_file ("gfx/help5.lmp");

	precache_file ("gfx/pause.lmp");
	precache_file ("gfx/loading.lmp");

	precache_file ("gfx/p_option.lmp");
	precache_file ("gfx/p_load.lmp");
	precache_file ("gfx/p_save.lmp");
	precache_file ("gfx/p_multi.lmp");

	// sounds loaded by C code
	precache_sound ("misc/menu1.wav");
	precache_sound ("misc/menu2.wav");
	precache_sound ("misc/menu3.wav");

	precache_sound ("ambience/water1.wav");
	precache_sound ("ambience/wind2.wav");

	// shareware
	precache_file ("maps/start.bsp");

	precache_file ("maps/e1m1.bsp");
	precache_file ("maps/e1m2.bsp");
	precache_file ("maps/e1m3.bsp");
	precache_file ("maps/e1m4.bsp");
	precache_file ("maps/e1m5.bsp");
	precache_file ("maps/e1m6.bsp");
	precache_file ("maps/e1m7.bsp");
	precache_file ("maps/e1m8.bsp");

	// registered
	precache_file2 ("gfx/pop.lmp");

	precache_file2 ("maps/e2m1.bsp");
	precache_file2 ("maps/e2m2.bsp");
	precache_file2 ("maps/e2m3.bsp");
	precache_file2 ("maps/e2m4.bsp");
	precache_file2 ("maps/e2m5.bsp");
	precache_file2 ("maps/e2m6.bsp");
	precache_file2 ("maps/e2m7.bsp");

	precache_file2 ("maps/e3m1.bsp");
	precache_file2 ("maps/e3m2.bsp");
	precache_file2 ("maps/e3m3.bsp");
	precache_file2 ("maps/e3m4.bsp");
	precache_file2 ("maps/e3m5.bsp");
	precache_file2 ("maps/e3m6.bsp");
	precache_file2 ("maps/e3m7.bsp");

	precache_file2 ("maps/e4m1.bsp");
	precache_file2 ("maps/e4m2.bsp");
	precache_file2 ("maps/e4m3.bsp");
	precache_file2 ("maps/e4m4.bsp");
	precache_file2 ("maps/e4m5.bsp");
	precache_file2 ("maps/e4m6.bsp");
	precache_file2 ("maps/e4m7.bsp");
	precache_file2 ("maps/e4m8.bsp");

	precache_file2 ("maps/end.bsp");

	precache_file2 ("maps/dm1.bsp");
	precache_file2 ("maps/dm2.bsp");
	precache_file2 ("maps/dm3.bsp");
	precache_file2 ("maps/dm4.bsp");
	precache_file2 ("maps/dm5.bsp");
	precache_file2 ("maps/dm6.bsp");
};

entity	lastspawn;

/*QUAKED worldspawn (0 0 0) ?
	Only used for the world entity.
	Set message to the level name.
	Set sounds to the cd track to play.

	World Types:
		0: medieval
		1: metal
		2: base
*/
void() worldspawn =
{
#ifdef NETQUAKE
	BotInit ();
#endif

	lastspawn = world;
	InitBodyQue ();

#ifdef NETQUAKE
	CamSpawn ();
#endif

	// custom map attributes
	if (@self.model == "maps/e1m8.bsp")
		cvar_set ("sv_gravity", "100");
	else
		cvar_set ("sv_gravity", "790");

#ifdef QUAKEWORLD
	cvar_set ("sv_friction", "3.12");

	// make sure gamedir is "paroxysm"
	if (infokey (world, "*gamedir") != "paroxysm") 
		error ("Gamedir must be \"paroxysm\"\n");
#else
	// Set deathmatch to options specified in the setup menu
	deathmatch = cvar("deathmatch");
#endif

	// LMS has its own fraglimit
	fraglimit_LMS = cvar("fraglimit");
		
	// the area based ambient sounds MUST be the first precache_sounds

	// player precaches	
	W_Precache ();			// get weapon precaches


	// Menu sounds (needed for C code)
	precache_sound ("misc/menu1.wav");
	precache_sound ("misc/menu2.wav");
	precache_sound ("misc/menu3.wav");

	/*
		These are sounds used by the C physics code
	*/
	precache_sound ("demon/dland2.wav");		// landing thud
	precache_sound ("misc/h2ohit1.wav");		// landing splash

	// setup precaches, always needed
	precache_sound ("items/itembk2.wav");		// item respawn sound
	precache_sound ("player/plyrjmp8.wav");		// player jump
	precache_sound ("player/land.wav");			// player landing
	precache_sound ("player/land2.wav");		// player hurt landing
	precache_sound ("player/drown1.wav");		// drowning pain
	precache_sound ("player/drown2.wav");		// drowning pain
	precache_sound ("player/gasp1.wav");		// gasping for air
	precache_sound ("player/gasp2.wav");		// taking breath
	precache_sound ("player/h2odeath.wav");		// drowning death

	precache_sound ("items/protect.wav");		// Needed for FFA
	precache_sound ("items/protect2.wav");		// Needed for FFA
	precache_sound ("items/protect3.wav");		// Needed for FFA
	
	precache_sound ("items/inv1.wav");			// Needed for Predator mode
	precache_sound ("items/inv2.wav");			// Needed for Predator mode
	precache_sound ("items/inv3.wav");			// Needed for Predator mode
	precache_model ("progs/eyes.mdl");

	precache_sound ("misc/talk.wav");			// talk
	precache_sound ("player/teledth1.wav");		// telefrag
	precache_sound ("misc/r_tele1.wav");		// teleport sounds
	precache_sound ("misc/r_tele2.wav");
/*
	precache_sound ("misc/r_tele3.wav");
	precache_sound ("misc/r_tele4.wav");
*/
	precache_sound ("misc/r_tele5.wav");

	precache_sound ("weapons/lock4.wav");		// ammo pick up
	precache_sound ("weapons/pkup.wav");		// weapon up
	precache_sound ("items/armor1.wav");		// armor up
	precache_sound ("weapons/lhit.wav");		// lightning
	precache_sound ("weapons/lstart.wav");		// lightning start
	precache_sound ("items/damage3.wav");

//	precache_sound ("misc/power.wav");			// lightning for boss

	// player gib sounds
	precache_sound ("player/gib.wav");			// player gib sound
	precache_sound ("player/udeath.wav");		// player gib sound
	precache_sound ("player/tornoff2.wav");		// gib sound

	// player pain sounds
	precache_sound ("player/pain1.wav");
	precache_sound ("player/pain2.wav");
	precache_sound ("player/pain3.wav");
	precache_sound ("player/pain4.wav");
	precache_sound ("player/pain5.wav");
	precache_sound ("player/pain6.wav");

	// player death sounds
	precache_sound ("player/death1.wav");
	precache_sound ("player/death2.wav");
	precache_sound ("player/death3.wav");
	precache_sound ("player/death4.wav");
	precache_sound ("player/death5.wav");
	precache_sound ("boss1/sight1.wav");

	// Footstep sounds
	precache_sound ("misc/foot1.wav");
	precache_sound ("misc/foot2.wav");
	precache_sound ("misc/foot3.wav");
	precache_sound ("misc/foot4.wav");

	// Narration ("Eliminated!") for LMS
	precache_sound ("nar/n_elim.wav");

	// Regen Stations (v1.2)
	precache_sound ("items/shield1.wav");
	precache_sound ("items/shield2.wav");
	precache_sound ("items/shield3.wav");
	precache_sound ("misc/null.wav");

#ifdef QUAKEWORLD
	// Axe sounds	
	precache_sound ("weapons/ax1.wav");			// ax swoosh
	precache_sound ("player/axhit1.wav");		// ax hit meat
	precache_sound ("player/axhit2.wav");		// ax hit world
#endif

	// World sounds
	precache_sound ("player/h2ojump.wav");		// player jumping into water
	precache_sound ("player/inh2o.wav");		// player enter water
	precache_sound ("misc/inh2ob.wav");			// player reenter water
	precache_sound ("misc/outwater.wav");		// leaving water sound
	precache_sound ("misc/owater2.wav");		// leaving water sound
	precache_sound ("misc/water1.wav");			// swimming
	precache_sound ("misc/water2.wav");			// swimming
	precache_sound ("misc/uwater.wav");			// swimming

	precache_sound ("player/slimbrn2.wav");		// player enter slime

	precache_sound ("player/inlava.wav");		// player enter lava
	precache_sound ("player/lburn1.wav");		// lava burn
	precache_sound ("player/lburn2.wav");		// lava burn

	precache_model ("progs/player.mdl");

	precache_model ("progs/null.mdl");
	precache_model ("progs/h_player.mdl");
	precache_model ("progs/gib1.mdl");
	precache_model ("progs/gib2.mdl");
	precache_model ("progs/gib3.mdl");

	precache_model ("progs/s_bubble.spr");	// drowning bubbles
	precache_model ("progs/s_explod.spr");	// sprite explosion

	// Weapon models
#ifdef QUAKEWORLD
	precache_model ("progs/v_axe.mdl");
#else
	precache_model ("progs/v_bsaw.mdl");
#endif
	precache_model ("progs/v_tshot.mdl");
	precache_model ("progs/v_plasma.mdl");
	precache_model ("progs/v_gren.mdl");
	precache_model ("progs/v_combo.mdl");
	precache_model ("progs/v_nailg.mdl");
	precache_model ("progs/v_nailgl.mdl");
	precache_model ("progs/v_rhino.mdl");
//	precache_model ("progs/v_light.mdl");	// flashlight model -- not yet
	precache_model ("progs/null.spr");		// current flashlight model

#if 0
	// Cloaked weapons - removed v1.11
	precache_model ("progs/vb_bsaw.mdl");
	precache_model ("progs/vb_tshot.mdl");
	precache_model ("progs/vb_plasm.mdl");
	precache_model ("progs/vb_gren.mdl");
	precache_model ("progs/vb_combo.mdl");
	precache_model ("progs/vb_nailg.mdl");
	precache_model ("progs/vb_rhino.mdl");
#endif

	// "bullet" models
	precache_model ("progs/grenade.mdl");
	precache_model ("progs/lavaball.mdl");
	precache_model ("progs/s_spike.mdl");
	precache_model ("progs/spike.mdl");

	precache_model ("progs/backpack.mdl");
	precache_model ("progs/zom_gib.mdl");

	/*
		Light animation tables. 'a' is total darkness, 'z' is maxbright.
	*/
	// 0 normal
	lightstyle (0, "m");
	
	// 1 FLICKER (first variety)
	lightstyle (1, "mmnmmommommnonmmonqnmmo");
	
	// 2 SLOW STRONG PULSE
	lightstyle (2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");
	
	// 3 CANDLE (first variety)
	lightstyle (3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");
	
	// 4 FAST STROBE
	lightstyle (4, "mamamamamama");
	
	// 5 GENTLE PULSE 1
	lightstyle (5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");
	
	// 6 FLICKER (second variety)
	lightstyle (6, "nmonqnmomnmomomno");
	
	// 7 CANDLE (second variety)
	lightstyle (7, "mmmaaaabcdefgmmmmaaaammmaamm");
	
	// 8 CANDLE (third variety)
	lightstyle (8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");
	
	// 9 SLOW STROBE (fourth variety)
	lightstyle (9, "zzzzzzgggggggggggg");

	/*
		New lightstyles
	*/	
	// 12 SLOW STROBE2
	lightstyle (12, "ggggggzzzzzzgggggg");
	// 13 SLOW STROBE3
	lightstyle (13, "ggggggggggggzzzzzz");
	
	// 10 FLUORESCENT FLICKER
	lightstyle (10, "bbbbbmmmccmmamambbbmmbbbbmmaammmcccmamamm");
	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle (11, "abcdefghijklmnopqrrqponmlkjihgfedcba");
	
	// styles 32-62 are assigned by the light program for switchable lights
	// 63 testing
	lightstyle (63, "a");
};

void() StartFrame =
{
#ifdef NETQUAKE
	BotFrame ();
#endif

	teamplay = cvar ("teamplay");

#ifdef QUAKEWORLD
	timelimit = cvar ("timelimit") * 60;
	fraglimit = cvar ("fraglimit");
	
	deathmatch = cvar ("deathmatch");
#else
	skill = cvar ("skill");
#endif

	framecount = framecount + 1;
};

/*
	BODY QUEUE
*/
entity	bodyque_head;

void() bodyque =
{	// just here so spawn functions don't complain after the world
	// creates bodyques
};

void() InitBodyQue =
{
	bodyque_head = spawn();
	bodyque_head.classname = "bodyque";
	bodyque_head.owner = spawn();
	bodyque_head.owner.classname = "bodyque";
	bodyque_head.owner.owner = spawn();
	bodyque_head.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner = bodyque_head;

#ifdef NETQUAKE
	// VisWeap: Double the length of the bodyque to account for weapons.
	bodyque_head.owner.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.owner.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner.owner.owner.owner.owner = spawn();
	bodyque_head.owner.owner.owner.owner.owner.owner.owner.owner.classname = "bodyque";
	bodyque_head.owner.owner.owner.owner.owner.owner.owner.owner.owner = bodyque_head;
#endif
};

// make a body que entry for the given ent so the ent can be
// respawned elsewhere
void(entity ent) CopyToBodyQue =
{
	bodyque_head.angles = ent.angles;
	bodyque_head.model = ent.model;
	bodyque_head.modelindex = ent.modelindex;
	bodyque_head.frame = ent.frame;
	bodyque_head.colormap = ent.colormap;
	bodyque_head.movetype = ent.movetype;
	bodyque_head.velocity = ent.velocity;

#ifdef NETQUAKE
	bodyque_head.skin = ent.skin;	// Multiple skin support
#endif

	bodyque_head.flags = 0;

	// allow heads to still float after player respawns
	if ((ent.classname == "player") && (ent.think == bubble_bob)) {
		bodyque_head.think = ent.think;
		bodyque_head.nextthink = ent.nextthink;
		bodyque_head.cnt = ent.cnt;
	}

	setorigin (bodyque_head, ent.origin);
	setsize (bodyque_head, ent.mins, ent.maxs);

#ifdef NETQUAKE
    CamCopyBody (ent, bodyque_head);
#endif

	bodyque_head = bodyque_head.owner;
};

#ifdef NETQUAKE
float	lms_gameover;	// Send a game over message if true
#endif
