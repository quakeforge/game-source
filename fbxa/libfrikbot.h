#include "Entity.h"

@class PLItem;

@class Bot;
@class Waypoint;
@class EditorState;

struct bot_data_t {
	string name;
	float pants, shirt;
};
typedef struct bot_data_t bot_data_t;

@interface Target: Entity
{
@public
	Waypoint *current_way;
	int hold_select;
	Target *_last;
	EditorState *editor;
}
+(Target *)forEntity:(entity)e;
-(vector)realorigin;
-(vector)origin;
-(int)canSee:(Target *)targ ignoring:(entity)ignore;
-(void)setOrigin:(vector) org;
-(int)recognizePlat:(int)flag;
-(int)ishuman;
-(int)priority:(Bot *)bot;
-(Waypoint *)findWaypoint:(Waypoint *)start;
-(float)searchTime;
-(void)setSearchTime:(float)st;
-(string)classname;
@end

typedef int waytest_t (Waypoint *way, void *data);

@interface Waypoint: Target
{
@public
	Waypoint *links[4];
	int flags;
	vector origin;

	int is_temp;

	int bot_bits;
	int busy;	//???
	float distance;
	Waypoint *enemy;
	float search_time;

	Waypoint *chain;
}
+(void)loadFile:(string)path;
+(void)clearAll;
+(Waypoint *)waypointForNum:(int)num;
+(void)fixWaypoints;
+(PLItem *)plist;
+(void)check:(Target *)ent;

+(void)clearRouteTable;
+(void)clearMyRoute:(Bot *) bot;
+(Waypoint *)find:(vector)org radius:(float)rad;
+(Waypoint *)nearest:(vector)org start:(Waypoint *) start
			    test:(waytest_t) test data:(void*)data;

+(void)removeWaypoint:(Waypoint *)way;

+(void)showAll;
+(void)hideAll;
-(void)deselect;
-(void)select;

-(int)id;
-(id)init;
-(id)initAt:(vector)org;
-(id)initFromEntity:(entity)ent;

-(int)isLinkedTo:(Waypoint *)way;
-(int)linkWay:(Waypoint *)way;
-(int)teleLinkWay:(Waypoint *)way;
-(void)unlinkWay:(Waypoint *)way;

-(void)followLink:(Waypoint *)e2 :(int)bBit;
-(void)waypointThink;

-(void)clearLinks;
-(void)clearRoute;
-(void)clearRouteForBot:(Bot *)bot;

-(id)queueForThink;
@end

@class Array;

@interface Bot: Target
{
@public
	int keys;
	int buttons;
	int impulse;
	vector b_angle;
	vector mouse_emu;

	int wallhug;
	int ishuman;
	float b_frags;		// for detecting score changes
	int b_clientno;
	int b_clientflag;
	float b_shirt;
	float b_pants;
	float ai_time;
	float b_sound;
	float missile_speed;
	int b_skill;
	float switch_wallhug;
	int b_aiflags;
	int b_num;
	float b_chattime;
	float b_entertime;
	int route_failed;
	int dyn_flags;
	int dyn_plat;
	float dyn_time;
	Waypoint *temp_way;
	Waypoint *last_way;
	Waypoint *last_waypoint; //FIXME see findRoute
	Target *targets[4];
	entity avoid;
	vector obs_dir;
	vector b_dir;
	vector dyn_dest;
	vector punchangle;

	float teleport_time;
	float portal_time;
}
- (id) init;
- (id) initWithEntity: (entity) e named:(bot_data_t *)name skill:(int)skill;
- (id) initFromPlayer: (entity) e;
- (void) preThink;
- (void) postThink;
- (void) frame;
- (void) disconnect;

- (void) updateClient;
- (void) releaseEditor;
@end

@interface Bot (Misc)
+(bot_data_t *)name:(int)r;
+(bot_data_t *)randomName;
-(int)fov:(entity)targ;

+(void)kick;
-(void)add;
@end

@interface Bot (Move)
- (void)sendMove;
- (void)jump;
- (int)canRJ;
- (int)recognizePlat: (int) flag;
- (int)keysForDir: (vector) sdir;
- (void)obstructed: (vector) whichway : (int) danger;
- (void)obstacles;
- (void)dodgeObstruction;
- (void)movetogoal;
- (int)walkmove: (vector) weird;
- (void)roam;
@end

@interface Bot (AI)
-(int)targetOnstack:(Target *)scot;
-(void)targetAdd:(Target *)e;
-(void)targetDrop:(Target *)e;
-(void)targetClearAll;
-(void)lost:(Target *)targ :(int)success;
-(void)checkLost:(Target *)targ;
-(void)handleAI;
-(void)path;
-(void)lookForCrap:(int)scope;
-(void)angleSet;
-(void)AI;
-(int)priorityForThing:(Target *)thing;
@end

@interface Bot (Fight)
-(float)sizePlayer:(Target *)targ;
-(void)dodgeStuff;
-(void)weaponSwitch:(float)brange;
-(void)shoot;
-(void)fightStyle;
@end

@interface Bot (Way)
-(void)deleteWaypoint:(Waypoint *)what;
-(entity)findThing:(string)s;
-(Waypoint *)findRoute:(Waypoint *)lastone;
-(void)markPath:(Target *)this;
-(void)getPath:(Target *)this :(int)direct;
-(int)beginRoute;
-(void)spawnTempWaypoint:(vector)org;
-(void)dynamicWaypoint;

-(int)canSee:(Target *)targ;
@end

@interface Bot (Chat)
-(void)startTopic:(int)topic;
-(void)say:(string)msg;
-(void)say2:(string)msg;
-(void)sayTeam:(string)msg;
-(void)sayInit;
-(void)chat;
@end

#define FALSE 0
#define TRUE 1

/* punchangle
 *	bot	fake kick?
 */
@extern .vector	punchangle; // HACK - Don't want to screw with bot_phys

// --------defines-----

// used for the physics & movement AI
#define KEY_MOVEUP 		0x001
#define KEY_MOVEDOWN 	0x002
#define KEY_MOVELEFT 	0x004
#define KEY_MOVERIGHT 	0x008
#define KEY_MOVEFORWARD	0x010
#define KEY_MOVEBACK	0x020
#define KEY_LOOKUP		0x040
#define KEY_LOOKDOWN	0x080
#define KEY_LOOKLEFT	0x100
#define KEY_LOOKRIGHT	0x200

#define KEY_LOOK		(KEY_LOOKRIGHT|KEY_LOOKLEFT|KEY_LOOKDOWN|KEY_LOOKUP)
#define KEY_MOVE		(KEY_MOVEBACK|KEY_MOVEFORWARD|KEY_MOVERIGHT\
						 |KEY_MOVELEFT|KEY_MOVEDOWN|KEY_MOVEUP)

// these are aiflags for waypoints
// some overlap to the bot
#define AI_TELELINK_1	0x00001	// link type
#define AI_TELELINK_2	0x00002	// link type
#define AI_TELELINK_3	0x00004	// link type
#define AI_TELELINK_4	0x00008	// link type
#define AI_DOORFLAG		0x00010	// read ahead
#define AI_PRECISION	0x00020	// read ahead + point
#define AI_SURFACE		0x00040	// point 
#define AI_BLIND		0x00080	// read ahead + point
#define AI_JUMP			0x00100	// point + ignore
#define AI_DIRECTIONAL	0x00200	// read ahead + ignore
#define AI_PLAT_BOTTOM	0x00400	// read ahead 
#define AI_RIDE_TRAIN	0x00800	// read ahead 
#define AI_SUPER_JUMP	0x01000	// point + ignore + route test
#define AI_SNIPER		0x02000	// point type 
#define AI_AMBUSH		0x04000	// point type
#define AI_DOOR_NO_OPEN	0x08000	// read ahead
#define AI_DIFFICULT	0x10000	// route test
#define AI_TRACE_TEST	0x20000	// route test

// addition masks
#define AI_POINT_TYPES 		(AI_AMBUSH|AI_SNIPER|AI_SUPER_JUMP|AI_JUMP\
							 |AI_BLIND|AI_SURFACE|AI_PRECISION)
#define AI_READAHEAD_TYPES	(AI_DOOR_NO_OPEN|AI_RIDE_TRAIN|AI_PLAT_BOTTOM\
							 |AI_DIRECTIONAL)
#define AI_IGNORE_TYPES		(AI_SUPER_JUMP|AI_DIRECTIONAL|AI_JUMP)

// these are flags for bots/players (dynamic/editor flags)
#define AI_OBSTRUCTED	1
#define AI_HOLD_SELECT	2
#define AI_ROUTE_FAILED	2
#define AI_WAIT			4
#define AI_DANGER		8

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
@extern Bot *players[32];
@extern float		real_frametime;
@extern float		bot_count, b_options;
@extern float		lasttime;
@extern float		waypoint_mode;
@extern float		dump_mode; 
@extern float		direct_route;
@extern float		sv_gravity;
@extern Bot			*route_table;
@extern int		busy_waypoints;

@extern float coop;

// -------ProtoTypes------
// external, in main code
@extern Bot *BotConnect (int whatbot, int whatskill);
@extern void()				ClientConnect;
@extern void()				ClientDisconnect;
@extern void()				SetNewParms;

// rankings
@extern int (entity e) ClientNumber;

@extern void(vector org, vector bit1, int bit4, int flargs) make_way;

@extern void () map_dm1;
@extern void () map_dm2;
@extern void () map_dm3;
@extern void () map_dm4;
@extern void () map_dm5;
@extern void () map_dm6;

// ai & misc
@extern Array *bot_array;
@extern float(float y1, float y2)	angcomp;
@extern float(entity ent, entity targ, vector targ_origin)		sisible;
@extern vector(entity ent)		realorigin;
@extern float(float v)			frik_anglemod;

@extern void DeveloperLightning(Waypoint *e1, Waypoint *e2, int flag);

/*
	angles is pitch yaw roll
	move is forward right up
*/
@extern void (entity cl, float sec, vector angles, vector move, int buttons, int impulse) SV_UserCmd;
@extern void () Break;
@extern string (int i) itos;

@extern int bot_way_linker;
@extern int bot_move_linker;
@extern int bot_chat_linker;
@extern float stagger_think;
@extern int bot_fight_linker;

#include "defs.h"
