/*
======================================
FrikBot X (Version 0.10.0) QW
======================================

This program is in the Public Domain. My crack legal
team would like to add:

RYAN "FRIKAC" SMITH IS PROVIDING THIS SOFTWARE "AS IS"
AND MAKES NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE
ACCURACY, CAPABILITY, EFFICIENCY, MERCHANTABILITY, OR
FUNCTIONING OF THIS SOFTWARE AND/OR DOCUMENTATION. IN
NO EVENT WILL RYAN "FRIKAC" SMITH BE LIABLE FOR ANY
GENERAL, CONSEQUENTIAL, INDIRECT, INCIDENTAL,
EXEMPLARY, OR SPECIAL DAMAGES, EVEN IF RYAN "FRIKAC"
SMITH HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES, IRRESPECTIVE OF THE CAUSE OF SUCH DAMAGES. 

You accept this software on the condition that you
indemnify and hold harmless Ryan "FrikaC" Smith from
any and all liability or damages to third parties,
including attorney fees, court costs, and other
related costs and expenses, arising out of your use
of this software irrespective of the cause of said
liability. 

The export from the United States or the subsequent
reexport of this software is subject to compliance
with United States export control and munitions
control restrictions. You agree that in the event you
seek to export this software, you assume full
responsibility for obtaining all necessary export
licenses and approvals and for assuring compliance
with applicable reexport restrictions. 

Any reproduction of this software must contain
this notice in its entirety. 

======================================
These installation instructions only apply to QuakeWorld (as does this entire
file). For Normal Quake, please refer to bot.qc

--------------------------------------
To install on a new mod, do all this:
--------------------------------------
FIXME installing and linking instrunctions here
--------------------------------------
* Comment out the following functions in defs.qc
sound, aim, setspawnparms
--------------------------------------
* Add this to worldspawn() in world.qc, right at the very top, before InitBodyQue();
BotInit();  // FrikBot
--------------------------------------
* add this line to StartFrame() in world.qc, at the very top
BotFrame(); // FrikBot
--------------------------------------
* Add this line to PlayerPostThink in client.qc at the very top
BotImpulses (); // FrikBot
--------------------------------------
* Add the following line to the very top of Client Connect in client.qc
ClientInRankings(); // FrikBot
--------------------------------------
* Add these lines to the very top of ClientDisconnect in client.qc
ClientDisconnected(); // FrikBot
--------------------------------------
* Add these lines to the very top of SpectatorConnect in spectate.qc
ClientFixRankings(); // FrikBot
--------------------------------------
*/

#include "libfrikbot.h"

integer []bot_way_ref;
integer []bot_move_ref;
integer []bot_chat_ref;
float []stagger_think_ref;
integer []bot_fight_ref;

void ()
bot_map_load =
{
	// place your qc loaded waypoints here
	switch (mapname) {
	case "dm1":
		map_dm1 ();
		break;
	case "dm2":
		map_dm2 ();
		break;
	case "dm3":
		map_dm3 ();
		break;
	case "dm4":
		map_dm4 ();
		break;
	case "dm5":
		map_dm5 ();
		break;
	case "dm6":
		map_dm6 ();
		break;
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Variables and shtuff

bot.qc has become pretty much a header file
for all variable in the bot...
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

Bot [32] players;

// -------globals-----
float       real_frametime;
float		bot_count, b_options, lasttime;
float		waypoint_mode, dump_mode; 
float		direct_route;
float		sv_friction, sv_gravity;
float		sv_accelerate, sv_maxspeed, sv_stopspeed;
Bot			route_table;
integer		busy_waypoints;

float coop = 0; // hack

void(entity e, float chan, string samp, float vol, float atten) frik_sound = #8;
vector(entity e, float sped)       frik_aim = #44; 
void(entity e)             frik_setspawnparms  = #78;

entity () SV_AllocClient = #0;
void (entity e) SV_FreeClient = #0;
void (entity e, string str) SV_SetUserinfo = #0;
void (entity e, integer ping) SV_SetPing = #0;
void (entity cl, float sec, vector angles, vector move, integer buttons, integer impulse) SV_UserCmd = #0;
void (entity cl) SV_Spawn = #0;


//----------------------------------------------------------------------------

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function redeclarations. These allow function 
designed to work for clients (sprint, so forth)
to mainly not complain when working with a bot

Although these shouldn't be needed anymore,
as the bots truly are clients now, if you don't
stop the SZ_ buffer from filling up by disabling
direct messages to the bots, it crashes quake :-(
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void (entity e)
setspawnparms =
{
   if (((Bot)e.@this).ishuman)
	   frik_setspawnparms (e);
   else
	   SetNewParms ();
};

vector (entity e, float sped)
aim =
{
   ((Bot)e.@this).missile_speed = sped;
   return frik_aim (e, sped);
};

void (entity e, float chan, string samp, float vol, float atten)
sound = 
{
   frik_sound (e, chan, samp, vol, atten);
   if (samp == "items/inv3.wav")
	   return;
   else if (e.classname == "player")
	   ((Bot)e.@this).b_sound = time + 1;
   else if (other.classname == "player")
	   ((Bot)other.@this).b_sound = time + 1;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Stuff mentioned up top
it just links the bot into the mod
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void ()
ClientFixRankings =
{
	local integer cno;
	local Bot bot = @self.@this;
	local entity btmp;
	local Bot btmp_bot;

	if (bot.switch_wallhug > time)
		return;
	bot.switch_wallhug = 0;

	btmp = nextent (NIL);
	for (cno = 0; cno < 32; cno++) {
		btmp_bot = btmp.@this;
		if (!btmp_bot.ishuman) {
			if (players[cno])
				[btmp_bot updateClient];
		}
		cno++;
		btmp = nextent (btmp);
	}
};

void ()
ClientInRankings =
{
	local integer cl_no = ClientNumber (@self);

	if (!players[cl_no])
		players[cl_no] = [[Bot alloc] initFromPlayer:@self];
};

void ()
ClientDisconnected =
{
	local integer cl_no = ClientNumber (@self);
	players[cl_no] = NIL;
};

// BotInit ====================================================================

void ()
BotInit =
{
	[Waypoint clearAll];
	bot_way_ref = &bot_way_linker;
	bot_move_ref = &bot_move_linker;
	bot_chat_ref = &bot_chat_linker;
	stagger_think_ref = &stagger_think;
	bot_fight_ref = &bot_fight_linker;
	bot_map_load ();
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Rankings 'utilities'. Written by Alan Kivlin,
this code just fools clients by sending precisely
the same network messages as when a real player
signs on to the server.
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(Waypoint e1, Waypoint e2, integer flag) DeveloperLightning = {};

// BotConnect and related functions. -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

integer (entity cl)
ClientNumber =
{
	local entity e = NIL;
	local integer f = -1;

	do {
		f++;
		e = nextent (e);
	} while (e != cl);
	return f;
};

void (integer whatbot, integer whatskill)
BotConnect =
{
	local entity cl;
	local Bot bot;
	local bot_data_t [] name;
	
	cl = SV_AllocClient ();
	if (!cl) {
		bprint (PRINT_HIGH, "Unable to connect a bot, server is full.\n");
		return;
	}

	if (whatbot)
		name = [Bot name:whatbot];
	else
		name = [Bot randomName];

	bot = [[Bot alloc] initWithEntity: cl named:name skill:whatskill];
	[bot startTopic:1];
};

/*
Bot Impulses. Allows the player to perform bot
related functions.
*/
void () BotImpulses =
{
	local integer f;
	local string h;
	
	if (@self.impulse == 100) {
		h = infokey (NIL, "skill");
		f = (integer) stof (h);
		BotConnect (0, f);
	} else if (@self.impulse == 102)
		[Bot kick];
	else
		return;
	@self.impulse = 0;
};

@implementation Bot
- (id) init
{
	return [super init];
}

- (id) initWithEntity:(entity) e named:(bot_data_t [])name skill:(integer)skill
{
	local integer cl_no = ClientNumber (e);
	local entity uself;

	SV_Spawn (e);

	if (!(self = [super initWithEntity:e]))
		return NIL;

	players[cl_no] = self;

	b_clientno = cl_no + 1;
	b_clientflag = 1 << cl_no;
	
	//ent.colormap = (float) (cl_no + 1);
	//ent.team = b_pants + 1;

	b_entertime = time;

	ent.netname = name.name;
	b_pants = name.pants;
	b_shirt = name.shirt;

	[self updateClient];
	//b_num = I
	bot_count++;
	if (skill > 3)
		skill = 3;
	else if (skill < 0)
		skill = 0;
	b_skill = skill;
	ishuman = FALSE;

	uself = @self;
	@self = ent;
	SetNewParms ();
	ClientConnect ();
	PutClientInServer ();
	@self = uself;

	return self;
}

- (id) initFromPlayer: (entity) e
{
	local integer cno;

	if (!(self = [super initWithEntity:e]))
		return NIL;

   	cno = (integer)e.colormap - 1;
	b_clientno = cno;
	ishuman = TRUE;
	switch_wallhug = time + 1;
	return self;
}

- (void) preThink
{
	local entity uself;

	if (switch_wallhug)
		ClientFixRankings ();
	if (b_frags != ent.frags) {
		if (b_frags > ent.frags) {
			if (pointcontents (ent.origin) == CONTENT_LAVA)
				[self startTopic:10];
			else
				[self startTopic:9];
		} else
			[self startTopic:2];
		b_frags = ent.frags;
	}
	[self dynamicWaypoint];

	uself = @self;
	@self = ent;
	PlayerPreThink ();
	@self = uself;
}

- (void) postThink
{
	local entity uself;

	uself = @self;
	@self = ent;
	PlayerPostThink ();
	@self = uself;
}

-(void)disconnect
{
	local entity uself;

	uself = @self;
	@self = ent;
	ClientDisconnect ();
	@self = uself;

	bot_count--;

	SV_FreeClient (ent);
}

-(void)frame
{
	[self obstacles];
	[self AI];
	[self sendMove];
}

-(void) updateClient
{
	local string bottomcolor = ftos (b_pants);
	local string topcolor = ftos (b_shirt);

	SV_SetPing (ent, 100 * (3 - b_skill));
	SV_SetUserinfo (ent, "\\bottomcolor\\" + bottomcolor
					+ "\\topcolor\\" + topcolor
					+ "\\team\\bot\\skin\\base\\name\\" + ent.netname);
	// FIXME: do teams properly
}

-(integer)ishuman
{
	return ishuman;
}
@end

void ()
BotFrame =
{
	local string h;
	local integer i;
	
	h = infokey (NIL, "bot_options");
	b_options = stof (h);
	
	// for the sake of speed
	sv_maxspeed = cvar ("sv_maxspeed");
	sv_gravity = cvar ("sv_gravity");
	sv_friction = cvar ("sv_friction");
	sv_accelerate = cvar ("sv_accelerate");
	sv_stopspeed = cvar ("sv_stopspeed");
	real_frametime = time - lasttime; // in QW frametime is fuxx0red
	lasttime = time;

	for (i = 0; i < 32; i++) {
		if (players[i] && !players[i].ishuman)
			[players[i] frame];
	}
};
