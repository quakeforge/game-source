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
* Change all occurrences of "self" to "@self". One way of doing this is to
pass the code through a preprocessor with "-Dself=@self"
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
* Add this to PlayerPreThink in client.qc at the very top
BotPreFrame(); // FrikBot
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
*/

#include <Array.h>

#include "libfrikbot.h"
#include "cmd.h"
#include "editor.h"

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
	[Waypoint fixWaypoints];
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
float		sv_gravity;
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
void () Break = #6;

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
BotPreFrame =
{
	[@self.@this preThink];
}

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
	local Bot p = NIL;

	p = players[cl_no];
	players[cl_no] = NIL;
	if (p) {
		local entity e = p.ent;
		local integer i;
		for (i = 0; i < 32; i++) {
			if (!players[i])
				continue;
			if (players[i].ent.enemy == e)
				[players[i] lost:p:0];
		}
		[p releaseEditor];
	}
	[p release];
};

// BotConnect and related functions. -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

integer (entity cl)
ClientNumber =
{
	local entity e = NIL;
	local integer f = -1;

	do {
		f++;
		e = nextent (e);
	} while (f < 33 && e != cl);
	if (f == 33)
		Break ();
	return f;
};

Bot (integer whatbot, integer whatskill)
BotConnect =
{
	local entity cl;
	local Bot bot;
	local bot_data_t [] name;

	cl = SV_AllocClient ();
	if (!cl) {
		bprint (PRINT_HIGH, "Unable to connect a bot, server is full.\n");
		return NIL;
	}

	if (whatbot)
		name = [Bot name:whatbot];
	else
		name = [Bot randomName];

	bot = [[Bot alloc] initWithEntity: cl named:name skill:whatskill];
	[bot startTopic:1];
	return bot;
};

/*
Bot Impulses. Allows the player to perform bot
related functions.
*/
void () BotImpulses =
{
	local integer f;
	local string h;
	local Target t = @self.@this;

	if (t.editor)
		[EditorState impulse];

	switch (@self.impulse) {
	case 100:
		h = infokey (NIL, "skill");
		f = (integer) stof (h);
		BotConnect (0, f);
		break;
	case 102:
		[Bot kick];
		break;
	case 104:
		[EditorState impulse];
		break;
	default:
		return;
	}
	@self.impulse = 0;
};

void ()
bot_add_f =
{
	local integer whatbot = 0;
	local integer skill;
	local integer c = Cmd_Argc ();

	if (c == 1) {
		skill = (integer) stof (infokey (NIL, "skill"));
	} else if (c == 2) {
		skill = (integer) stof (Cmd_Argv (1));
	} else {
		whatbot = (integer) stof (Cmd_Argv (1));
		skill = (integer) stof (Cmd_Argv (2));
	}
	BotConnect (whatbot, skill);
};

void ()
bot_kick_f =
{
	[Bot kick];
};

void ()
bot_loadway_f =
{
	if (Cmd_Argc () != 2) {
		dprint ("usage: bot_loadway <path>\n");
		return;
	}
	[Waypoint loadFile:Cmd_Argv (1)];
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
	Cmd_AddCommand ("bot_add", bot_add_f);
	Cmd_AddCommand ("bot_kick", bot_kick_f);
	Cmd_AddCommand ("bot_loadway", bot_loadway_f);

	precache_model ("progs/s_light.spr");
	precache_model ("progs/s_bubble.spr");
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Rankings 'utilities'. Written by Alan Kivlin,
this code just fools clients by sending precisely
the same network messages as when a real player
signs on to the server.
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(Waypoint e1, Waypoint e2, integer flag) DeveloperLightning =
{
	// used to show waypoint links for debugging
	WriteByte (MSG_BROADCAST, 23);
	if (flag)
		WriteByte (MSG_BROADCAST, 6);	// TE_LIGHTNING2
	else
		WriteByte (MSG_BROADCAST, 17);	// TE_LIGHTNINGBLOOD
	WriteEntity (MSG_BROADCAST, e2.ent);
	WriteCoordV (MSG_BROADCAST, e1.origin);
	WriteCoordV (MSG_BROADCAST, e2.origin);
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

	[self add];

	players[cl_no] = self;

	b_clientno = cl_no + 1;
	b_clientflag = 1 << cl_no;
	
	//ent.colormap = (float) (cl_no + 1);
	//ent.team = b_pants + 1;

	b_entertime = time;

	ent.netname = name.name;
	b_pants = name.pants;
	b_shirt = name.shirt;

	//b_num = I
	bot_count++;
	if (skill > 3)
		skill = 3;
	else if (skill < 0)
		skill = 0;
	b_skill = skill;
	ishuman = FALSE;
	[self updateClient];

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
	[bot_array removeObject:self];
}

-(void)frame
{
	[self obstacles];
	[self preThink];
	[self sendMove];
	[self AI];
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

- (integer) ishuman
{
	return ishuman;
}

- (void) releaseEditor
{
	if (editor)
		[EditorState close_menu];
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
	sv_gravity = cvar ("sv_gravity");
	real_frametime = time - lasttime; // in QW frametime is fuxx0red
	lasttime = time;

	for (i = 0; i < 32; i++) {
		if (players[i] && !players[i].ishuman)
			[players[i] frame];
	}
};
