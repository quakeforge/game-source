#include "Entity.h"

@interface Bot: Entity
{
	//model modelindex
	//frame angles colormap effects
	//owner

	//movetype solid touch <size> watertype flags think nextthink 

	integer keys, oldkeys;
	integer buttons, impulse;
	vector v_angle, b_angle;
	vector mouse_emu;

	integer wallhug;
	integer ishuman;
	float b_frags;
	integer b_clientno;
	float b_shirt, b_pants;
	float ai_time;
	float b_sound;
	float missile_speed;
	float portal_time;
	integer b_skill;
	float switch_wallhug;
	integer b_aiflags;
	integer b_num;
	float b_chattime;
	float b_entertime;
	float b_menu, b_menu_time, b_menu_value;
	integer route_failed;
	integer dyn_flags, dyn_time, dyn_plat;
	entity temp_way, last_way, current_way;
	entity [4] target;
	entity _next, _last;
	vector obs_dir;
	vector b_dir;
	vector dyn_dest;
	vector punchangle;
}
- (id) init;
- (id) initWithEntity: (entity) e;
@end

@interface Bot (Physics)
- (void)sendMove;
@end

@interface Bot (Move)
- (void)jump;
- (integer)can_rj;
- (integer)recognize_plat: (integer) flag;
- (integer)keysForDir: (vector) sdir;
- (void)obstructed: (vector) whichway : (integer) danger;
- (void)obstacles;
- (void)dodge_obstruction;
- (void)movetogoal;
- (integer)walkmove: (vector) weird;
- (void)roam;
@end

@interface Bot (AI)
@end

#define FALSE 0
#define TRUE 1

// ----- entity fields ---
/* wallhug
 *	bot	follow walls on left (false) or right (true)
 */
@extern .float	wallhug;
/* keys
 *	wp	if true, waypoint isn't busy (?)
 *	bot	key press states for emulating a keyboard player
 */
@extern .float	keys;
/* oldkeys
 *	bot	used for checking for keystate changes
 */
@extern .float	oldkeys;
/* ishuman
 *	bot	0 = bot, 1 = human, 2 = bot spawning (moves to 0)
 */
@extern .float	ishuman;
/* b_frags
 *	wp	target4 waypoint number
 *	bot	previous frag count. used for detecting suicides
 */
@extern .float	b_frags;
/* b_clientno
 *	bot	client number (1-32)
 */
@extern .integer b_clientno;
/* b_shirt
 *	wp	target3 waypoint number
 *	bot	shirt color
 */
@extern .float  b_shirt;
/* b_pants
 *	wp	target1 waypoint number
 *	bot	pants color
 */
@extern .float	b_pants; 
/* ai_time
 *	bot	ai thinking framerate control
 */
@extern .float	ai_time;
/* b_sound
 *	wp	if this waypoint is on a bot's route, the bit corresponding to the bot
 *		client number will be set
 *	bot	end time of current playing sound (for bots hearing enemies)
 */
@extern .float	b_sound;
/* missile_speed
 *	?	?
 */
@extern .float	missile_speed;
/* portal_time
 *	?	dynamic waypoints?
 */
@extern .float	portal_time;
/* b_skill
 *	wp	target2 waypoint number
 *	bot	skill level: 0 = easy, 3 = nightmare
 */
@extern .integer b_skill;
/* switch_wallhug
 *	bot	client linking stuff (bad name!!)
 */
@extern .float	switch_wallhug;
/* b_aiflags
 *	wp
 *	bot
 */
@extern .float	b_aiflags;
/* b_num
 *	bot	bot number
 */
@extern .integer	b_num;
/* b_chattime
 *	bot	control of bot chatting and movement (can't talk and walk:)
 */
@extern .float	b_chattime;
/* b_entertime
 *	bot	used for keeping track of bot play time
 */
@extern .float	b_entertime;
/* b_menu, b_menu_time, b_menu_value
 *	?	waypoint editing stuff
 */
@extern .float	b_menu, b_menu_time, b_menu_value;
/* route_failed
 *	bot	if waypoint routing fails, go into roam mode
 */
@extern .float	route_failed;
/* dyn_flags, dyn_time, dyn_plat
 *	?	dynamic waypoint stuff
 */
@extern .float	dyn_flags, dyn_time, dyn_plat;
/* temp_way
 *	bot	roam mode stuff
 */
@extern .entity	temp_way;
/* last_way
 *	bot	previous waypoint ?
 */
@extern .entity	last_way;
/* phys_obj
 *	bot	actual physical entity of bot
 */
@extern .entity	phys_obj;
/* targetN
 *	bot	LIFO stack of goals for the bot to achieve
 */
@extern .entity	target1, target2, target3, target4;
/* _next, _last
 *	wp	linked list of waypoints
 *	bot	linked list of possible foes
 */
@extern .entity	_next, _last;
/* current_way
 *	wp	?
 *	bot	currently saught waypoint?
 */
@extern .entity	current_way;
/* b_angle
 *	bot	desired view angle
 */
@extern .vector	b_angle;
/* mouse_emu
 *	bot	mouse movement emulation for mousing bots :)
 */
@extern .vector	mouse_emu;
/* obs_dir
 *	bot	obstruction direction?
 */
@extern .vector	obs_dir;
/* movevect
 *	bot	desired motion vector
 */
@extern .vector	movevect;
/* b_dir
 *	bot	direction to waypoint
 */
@extern .vector	b_dir;
/* dyn_dest
 *	?	dynamic waypoint stuff
 */
@extern .vector	dyn_dest;
/* punchangle
 *	bot	fake kick?
 */
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
@extern void(integer whatbot, integer whatskill) BotConnect;
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
@extern string(integer r)			BotName;
@extern float(float v)			frik_anglemod;
@extern void() bot_chat;
@extern void(float tpic) bot_start_topic;

@extern void(string h) BotSay;
@extern void() BotSayInit;
@extern void(string h) BotSay2;
@extern void(string h) BotSayTeam;
@extern void(entity e1, entity e2, float flag) DeveloperLightning;

/*
	angles is pitch yaw roll
	move is forward right up
*/
@extern void (entity cl, float sec, vector angles, vector move, integer buttons, integer impulse) SV_UserCmd;

#include "defs.h"
