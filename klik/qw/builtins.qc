/* Builtin functions */

entity()		BUILTIN_spawn		= #14;
void(entity e)		remove			= #15;

void(entity e, vector o)	setorigin	= #2;
void(entity e, string m)	setmodel	= #3;	// set movetype and solid first
void(entity e, vector min, vector max)	setsize	= #4;

string(string s)	precache_sound		= #19;
string(string s)	precache_model		= #20;
string(string s)	precache_file		= #68;	// no effect except for -copy
string(string s)	precache_sound2		= #76;	// registered version only
string(string s)	precache_model2		= #75;	// registered version only
string(string s)	precache_file2		= #77;	// registered version only
void (float style, string value) lightstyle	= #35;

// debug functions
void()			BUILTIN_break		= #6;	// shatter progs
void(string e, ...)	error			= #10;
void(string e, ...)	objerror		= #11;
void()			coredump		= #28;	// prints all edicts
void()			traceon			= #29;	// turns statment trace on
void()			traceoff		= #30;

void(entity e, float chan, string samp, float vol, float atten) sound	= #8;

void(vector ang)	makevectors	= #1;	// sets v_forward, etc globals
vector(vector v)	normalize	= #9;
float(vector v)		vlen		= #12;
float(vector v)		vectoyaw	= #13;
vector(vector v)	vectoangles	= #51;
vector(entity e, float speed) aim	= #44;	// returns the shooting vector

float()			random		= #7;	// returns 0 - 1
string(float f)		ftos		= #26;
float(string s)		stof		= #81;	// convert string to float
string(vector v)	vtos		= #27;
float(float v)		rint		= #36;	// round to nearest int
float(float v)		floor		= #37;	// largest integer <= v
float(float v)		ceil		= #38;	// smallest integer >= v
float(float f)		fabs		= #43;

// sets trace_* globals
// nomonsters can be:
// An entity will also be ignored for testing if forent == test,
// forent->owner == test, or test->owner == forent
// a forent of world is ignored
void(vector v1, vector v2, float nomonsters, entity forent) traceline = #16;
float(vector v)			pointcontents	= #41;	// returns a CONTENT_*
float(entity e)			checkbottom	= #40;	// true if self is on ground
float()					droptofloor	= #34;	// TRUE if landed on floor
float(float yaw, float dist)	walkmove	= #32;  // returns TRUE or FALSE
void(float step)			movetogoal	= #67;

entity()			checkclient		= #17;	// returns a client to look for
entity(entity start, .string fld, string match)	find	= #18;
entity(vector org, float rad)	findradius		= #22;
entity(entity e)		nextent			= #47;	// for looping through all ents

void(float level, string s, ...)	bprint		= #23;
void(entity client, float level, string s, ...)	sprint	= #24;
void(entity client, string s, ...)	centerprint	= #73;	// sprint, but centered
void(string s, ...)			dprint		= #25;
void(entity e)				eprint		= #31;	// prints an entire edict

float(string s)			cvar			= #45;	// return cvar.value
void(string var, string val)	cvar_set		= #72;	// sets cvar.value
string(entity e, string key)	infokey			= #80;	// get a key value (world = serverinfo)
void(string s1, ...)		localcmd		= #46;	// put string into local que
void(entity client, string s)	stuffcmd		= #21;

void() ChangeYaw	= #49;			// turn towards self.ideal_yaw
						// at self.yaw_speed
// direct client message generation
void(float to, vector v)		WriteAngleV		= #0;
void(float to, vector v)		WriteCoordV		= #0;
void(float to, ...)			WriteBytes		= #0;
void(float to, float f)		WriteByte		= #52;
void(float to, float f)		WriteChar		= #53;
void(float to, float f)		WriteShort		= #54;
void(float to, float f)		WriteLong		= #55;
void(float to, float f)		WriteCoord		= #56;
void(float to, float f)		WriteAngle		= #57;
void(float to, string s)		WriteString		= #58;
void(float to, entity s)		WriteEntity		= #59;
void(vector where, float set)	multicast		= #82;	// sends the temp message to a set

void(entity e)			BUILTIN_makestatic	= #69;
void(string s)			changelevel		= #70;


void(vector pos, string samp, float vol, float atten) BUILTIN_ambientsound = #74;

void(entity e)	setspawnparms		= #78;	// set parm1... to the
						// values at level start
						// for coop respawn

void(entity killer, entity killee)	logfrag		= #79;       // add to stats
