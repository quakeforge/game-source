#include "Entity.h"

@class Bot;
@class WayPoint;

@interface Target: Entity
{
}
-(vector)realorigin;
-(integer)canSee:(Target)targ ignoring:(entity)ignore;
@end

@interface WayPoint: Target
{
@public
	WayPoint [4] targets;
	WayPoint next, prev;
	integer flags;
	vector origin;
	integer count;

	integer b_pants, b_skill, b_shirt, b_frags, b_sound;
	integer keys;
	float items;
	WayPoint enemy;
	float search_time;
}
+(void)clearAll;
+(WayPoint)waypointForNum:(integer)num;
+(void)fixWaypoints;

+(void)clearRouteTable;
+(void)clearMyRoute:(Bot) bot;

-(void)fix;
//-(id)init;
-(id)initAt:(vector)org;
-(id)initFromEntity:(entity)ent;

-(integer)isLinkedTo:(WayPoint)way;
-(integer)linkWay:(WayPoint)way;
-(integer)teleLinkWay:(WayPoint)way;
-(void)unlinkWay:(WayPoint)way;

-(void)followLink:(WayPoint)e2 :(integer)b_bit;
-(void)waypointThink;
@end

@interface Bot: Target
{
@public
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
	integer dyn_flags, dyn_plat;
	float dyn_time;
	WayPoint temp_way, last_way, current_way;
	entity [4] targets;
	entity avoid;
	vector obs_dir;
	vector b_dir;
	vector dyn_dest;
	vector punchangle;

	float teleport_time, portal_time;
}
- (id) init;
- (id) initWithEntity: (entity) e;
@end

@interface Bot (Misc)
-(string)name:(integer)r;
-(string)randomName;
-(void)start_topic:(integer)topic;
-(void)chat;
-(integer)fov:(entity)targ;

+(void)kick;
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
-(integer)target_onstack:(entity)scot;
-(void)target_add:(entity)e;
-(void)target_drop:(entity)e;
-(void)lost:(WayPoint)targ :(integer)success;
-(void)check_lost:(WayPoint)targ;
-(void)handle_ai;
-(void)path;
-(float)priority_for_thing:(entity)thing;
-(void)look_for_crap:(integer)scope;
-(void)angle_set;
-(void)AI;
@end

@interface Bot (Fight)
-(float)size_player:(entity)e;
-(void)dodge_stuff;
-(void)weapon_switch:(float)brange;
-(void)shoot;
-(void)fight_style;
@end

@interface Bot (Way)
-(WayPoint)findWayPoint:(WayPoint)start;
-(void)deleteWaypoint:(WayPoint)what;
-(entity)findThing:(string)s;
-(WayPoint)findRoute:(WayPoint)lastone;
-(void)mark_path:(entity)this;
-(void)get_path:(WayPoint)this :(integer)direct;
-(integer)begin_route;
-(void)spawnTempWaypoint:(vector)org;
-(void)dynamicWaypoint;

-(integer)canSee:(Target)targ;
@end

#define FALSE 0
#define TRUE 1

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
@extern integer		waypoints;
@extern float		direct_route, userid;
@extern float		sv_friction, sv_gravity;
@extern float		sv_accelerate, sv_maxspeed, sv_stopspeed;
@extern entity		fixer;
@extern Bot			route_table;
@extern entity		b_temp1, b_temp2, b_temp3;
@extern WayPoint	way_head;
@extern float		busy_waypoints;

@extern float coop;

// -------ProtoTypes------
// external
@extern void()				ClientConnect;
@extern void()				ClientDisconnect;
@extern void()				SetNewParms;

// rankings
@extern integer (entity e) ClientNumber;
@extern integer(integer clientno)		ClientBitFlag;
@extern integer()				ClientNextAvailable;
@extern void(integer whatbot, integer whatskill) BotConnect;
@extern void(entity bot)			BotDisconnect;
@extern void(float clientno)		BotInvalidClientNo;
@extern void(entity who)			UpdateClient;

@extern void(vector org, vector bit1, integer bit4, integer flargs) make_way;

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

// ai & misc
@extern float(entity targ)		fov;
@extern float(float y1, float y2)	angcomp;
@extern float(entity ent, entity targ)		sisible;
@extern vector(entity ent)		realorigin;
@extern void()				BotImpulses;
@extern float(float v)			frik_anglemod;
@extern void() bot_chat;
@extern void(float tpic) bot_start_topic;

@extern void(string h) BotSay;
@extern void() BotSayInit;
@extern void(string h) BotSay2;
@extern void(string h) BotSayTeam;
@extern void(WayPoint e1, WayPoint e2, integer flag) DeveloperLightning;

/*
	angles is pitch yaw roll
	move is forward right up
*/
@extern void (entity cl, float sec, vector angles, vector move, integer buttons, integer impulse) SV_UserCmd;

#include "defs.h"
