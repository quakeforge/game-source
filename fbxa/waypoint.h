#ifndef __fbxa_waypoint_h
#define __fbxa_waypoint_h

@class PLItem;

@class Waypoint;

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

#define WM_UNINIT		0
#define WM_DYNAMIC		1
#define WM_LOADING		2
#define WM_LOADED		3
#define WM_EDITOR		4
#define WM_EDITOR_DYNAMIC	5
#define WM_EDITOR_DYNLINK	6

#endif//__fbxa_waypoint_h
