#define FALSE 0
#define TRUE 1

// ----- entity fields ---
@extern .float	wallhug, keys, oldkeys, ishuman;
@extern .float	b_frags;
@extern .integer b_clientno;
@extern .float  b_shirt, b_pants; 
@extern .float	priority, ai_time, b_sound, missile_speed;
@extern .float	portal_time, b_skill, switch_wallhug;
@extern .float	b_aiflags, b_num, b_chattime;
@extern .float	b_entertime, b_userid; // QW shtuff
@extern .float	b_menu, b_menu_time, b_menu_value;
@extern .float route_failed, dyn_flags, dyn_time;
@extern .float dyn_plat;
@extern .entity	temp_way, last_way, phys_obj;
@extern .entity	target1, target2, target3, target4;
@extern .entity	_next, _last;
@extern .entity	current_way;
@extern .vector	b_angle, b_dest, mouse_emu, obs_dir;
@extern .vector	movevect, b_dir;
@extern .vector dyn_dest;
@extern .vector	punchangle; // HACK - Don't want to screw with bot_phys

// --------defines-----
#define SVC_UPDATENAME	13
#define SVC_UPDATEFRAGS	14
#define SVC_UPDATECOLORS	17

// used for the physics & movement AI
#define KEY_MOVEUP 		1
#define KEY_MOVEDOWN 	2
#define KEY_MOVELEFT 	4
#define KEY_MOVERIGHT 	8
#define KEY_MOVEFORWARD	16
#define KEY_MOVEBACK	32
#define KEY_LOOKUP		64
#define KEY_LOOKDOWN	128
#define KEY_LOOKLEFT	256
#define KEY_LOOKRIGHT	512

// these are aiflags for waypoints
// some overlap to the bot
#define AI_TELELINK_1	1	// link type
#define AI_TELELINK_2	2	// link type
#define AI_TELELINK_3	4	// link type
#define AI_TELELINK_4	8	// link type
#define AI_DOORFLAG		16	// read ahead
#define AI_PRECISION	32	// read ahead + point
#define AI_SURFACE		64	// point 
#define AI_BLIND		128	// read ahead + point
#define AI_JUMP		256	// point + ignore
#define AI_DIRECTIONAL	512	// read ahead + ignore
#define AI_PLAT_BOTTOM	1024	// read ahead 
#define AI_RIDE_TRAIN	2048	// read ahead 
#define AI_SUPER_JUMP	4096	// point + ignore + route test
#define AI_SNIPER		8192	// point type 
#define AI_AMBUSH		16384	// point type
#define AI_DOOR_NO_OPEN	32768	// read ahead
#define AI_DIFFICULT	65536	// route test
#define AI_TRACE_TEST	131072	// route test

// these are flags for bots/players (dynamic/editor flags)
#define AI_OBSTRUCTED	1
#define AI_HOLD_SELECT	2
#define AI_ROUTE_FAILED	2
#define AI_WAIT		4
#define AI_DANGER		8

// addition masks
#define AI_POINT_TYPES 	29152
#define AI_READAHEAD_TYPES	36528
#define AI_IGNORE_TYPES	4864

#define WM_UNINIT		0
#define WM_DYNAMIC		1
#define WM_LOADING		2
#define WM_LOADED		3
// editor modes aren't available in QW, but we retain support of them
// since the editor is still built into the AI in places
#define WM_EDITOR		4
#define WM_EDITOR_DYNAMIC	5
#define WM_EDITOR_DYNLINK	6

#define OPT_NOCHAT	2

// -------globals-----
@extern entity [32] players;
@extern integer		max_clients;
@extern float		real_frametime;
@extern float		bot_count, b_options, lasttime;
@extern float		waypoint_mode, dump_mode; 
@extern float		waypoints, direct_route, userid;
@extern float		sv_friction, sv_gravity;
@extern float		sv_accelerate, sv_maxspeed, sv_stopspeed;
@extern entity		fixer;
@extern entity		route_table;
@extern entity		b_temp1, b_temp2, b_temp3;
@extern entity 		way_head;
@extern float		busy_waypoints;

@extern float coop;

// -------ProtoTypes------
// external
@extern void()				ClientConnect;
@extern void()				ClientDisconnect;
@extern void()				SetNewParms;

// fight
@extern void(float brange) bot_weapon_switch;
@extern void() bot_fight_style;
@extern void() bot_dodge_stuff;

// rankings
@extern integer (entity e) ClientNumber;
@extern float(integer clientno)		ClientBitFlag;
@extern integer()				ClientNextAvailable;
@extern void(float whatbot, float whatskill) BotConnect;
@extern void(entity bot)			BotDisconnect;
@extern void(float clientno)		BotInvalidClientNo;
@extern void(entity who)			UpdateClient;

// waypointing
@extern void()				DynamicWaypoint;
@extern entity(vector org)		make_waypoint;
@extern void()				ClearAllWays;
@extern void()				FixWaypoints;
@extern float()				begin_route;
@extern void(entity this, float direct)			bot_get_path;
@extern void()				WaypointThink;
@extern entity(entity start)				FindWayPoint;
@extern void() ClearMyRoute;
@extern entity(entity lastone) FindRoute;
@extern float (entity e1, entity e2) CheckLinked;
@extern void(vector org) SpawnTempWaypoint;
@extern void(vector org, vector bit1, float bit4, float flargs) make_way;

@extern void () map_dm1;
@extern void () map_dm2;
@extern void () map_dm3;
@extern void () map_dm4;
@extern void () map_dm5;
@extern void () map_dm6;

// physics & movement
@extern float(entity e)			bot_can_rj;
@extern void()				bot_jump;
@extern void()				frik_bot_roam;
@extern float(vector weird)		frik_walkmove;
@extern void()				frik_movetogoal;
@extern void()				frik_obstacles;
@extern float(float flag)			frik_recognize_plat;
@extern float(vector sdir)		frik_KeysForDir;
@extern void(vector whichway, float danger) frik_obstructed;
@extern void()				SV_Physics_Client;
@extern void()				SV_ClientThink;
@extern void() 				CL_KeyMove;
@extern entity(string s) FindThing;

// ai & misc
@extern void() BotAI;
@extern string()				PickARandomName;
@extern float(entity targ)		fov;
@extern float(float y1, float y2)	angcomp;
@extern float(entity targ1, entity targ2)		wisible;
@extern float(entity targ)		sisible;
@extern float(entity targ)		fisible;
@extern vector(entity ent)		realorigin;
@extern void(entity ent)			target_drop;
@extern void(entity ent)			target_add;
@extern void()				KickABot;
@extern void()				BotImpulses;
@extern void(entity targ, float success) bot_lost;
@extern string(float r)			BotName;
@extern float(float v)			frik_anglemod;
@extern void() bot_chat;
@extern void(float tpic) bot_start_topic;

@extern void(string h) BotSay;
@extern void() BotSayInit;
@extern void(string h) BotSay2;
@extern void(string h) BotSayTeam;
@extern void(entity e1, entity e2, float flag) DeveloperLightning;

#include "defs.h"
