
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
Place all included bot*.qc files in the subdirectory "frikbot"
in your source folder, then...

* Add the following lines to progs.src right after the defs.qc line
frikbot/map_dm1.qc
frikbot/map_dm2.qc
frikbot/map_dm3.qc
frikbot/map_dm4.qc
frikbot/map_dm5.qc
frikbot/map_dm6.qc
frikbot/bot_qw.qc
frikbot/bot_way.qc
frikbot/bot_fight.qc 
frikbot/bot_ai.qc
frikbot/bot_misc.qc
frikbot/bot_phys.qc
frikbot/bot_move.qc
--------------------------------------
* Add this to worldspawn() in world.qc, right at the very top, before InitBodyQue();
BotInit();  // FrikBot
--------------------------------------
* add this line to StartFrame() in world.qc, at the very top
BotFrame(); // FrikBot
--------------------------------------
* Add these two lines to PlayerPreThink in client.qc at the very top
if (BotPreFrame()) // FrikBot
	return;
--------------------------------------
* Add this line to PlayerPostThink in client.qc at the very top
if (BotPostFrame()) // FrikBot
	return;
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

void() bot_map_load =
{
	// place your qc loaded waypoints here

	if (mapname == "dm1")
		map_dm1();
	else if (mapname == "dm2")
		map_dm2();
	else if (mapname == "dm3")
		map_dm3();
	else if (mapname == "dm4")
		map_dm4();
	else if (mapname == "dm5")
		map_dm5();
	else if (mapname == "dm6")
		map_dm6();
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Variables and shtuff

bot.qc has become pretty much a header file
for all variable in the bot...

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

entity [32] players;
entity [32] phys_objects;

// ----- entity fields ---
.float	wallhug, keys, oldkeys, ishuman;
.float	b_frags, b_shirt, b_pants; 
.integer b_clientno;
.float	priority, ai_time, b_sound, missile_speed;
.float	portal_time, b_skill, switch_wallhug;
.float	b_aiflags, b_num, b_chattime;
.float	b_entertime, b_userid; // QW shtuff
.float	b_menu, b_menu_time, b_menu_value;
.float route_failed, dyn_flags, dyn_time;
.float dyn_plat;
.entity	temp_way, last_way, phys_obj;
.entity	target1, target2, target3, target4;
.entity	_next, _last;
.entity	current_way;
.vector	b_angle, b_dest, mouse_emu, obs_dir;
.vector	movevect, b_dir;
.vector dyn_dest;
.vector	punchangle; // HACK - Don't want to screw with bot_phys


// -------globals-----
integer		max_clients;
float       real_frametime;
float		bot_count, b_options, lasttime;
float		waypoint_mode, dump_mode; 
float		waypoints, direct_route, userid;
float		sv_friction, sv_gravity;
float		sv_accelerate, sv_maxspeed, sv_stopspeed;
entity		fixer;
entity		route_table;
entity		b_temp1, b_temp2, b_temp3;
entity 		way_head;
float		busy_waypoints;

float coop = 0; // hack

entity () SV_AllocClient = #0;
void (entity e) SV_FreeClient = #0;
void (entity e, string str) SV_SetUserinfo = #0;

//----------------------------------------------------------------------------


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Stuff mentioned up top
it just links the bot into the mod

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() ClientFixRankings =
{
	local integer cno;
	if (self.switch_wallhug > time)
		return;
	self.switch_wallhug = 0;

	b_temp2 = nextent(NIL);
	cno = 0;

	while (cno < max_clients) {
		if (!b_temp2.ishuman) {
			if (players[cno])
				UpdateClient(b_temp2);
		}
		cno++;
		b_temp2 = nextent(b_temp2);
	}
};
		
void() ClientInRankings =
{
	local float cno;
	local integer cl_no = ClientNumber (self);

	players[cl_no] = self;
	self.b_clientno = cl_no + 1;
	userid++;
	self.b_userid = userid;
	
	self.phys_obj = phys_objects[cl_no];

	if (self.ishuman == 2) {
		self.ishuman = FALSE;
		return;
	}
   	cno = self.colormap - 1;
	self.b_clientno = (integer) cno;
	self.ishuman = TRUE;
	self.switch_wallhug = time + 1;
};


void() ClientDisconnected =
{
	local integer cl_no = ClientNumber (self);
	players[cl_no] = NIL;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotPreFrame & BotPostFrame, used to make the
bot easier to install

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float () BotPreFrame =
{
	if (self.b_clientno == -1)
		return TRUE;
	if (self.ishuman)
		if (self.switch_wallhug)
			ClientFixRankings();
	if (self.b_frags != self.frags) {
		if (self.b_frags > self.frags) {
			if (pointcontents(self.origin) == CONTENT_LAVA)
				bot_start_topic(10);
			else
				bot_start_topic(9);
		} else
			bot_start_topic(2);
		self.b_frags = self.frags;
		if (!self.ishuman) {
			WriteByte(2, 14);
			WriteByte(2, (float)self.b_clientno);
			WriteShort(2, self.frags);
		}
	}
	DynamicWaypoint();
	return FALSE;
};
float () BotPostFrame =
{
	if (self.b_clientno == -1)
		return TRUE;
	if (self.ishuman)
		BotImpulses();
	return FALSE;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Chat code

The rest of this code is in bot_rank.qc

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void(string h) BotSay = // simulate talking by composing a 'chat' message
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 3);
	WriteByte(MSG_ALL, 1);
	WriteString(MSG_ALL, self.netname);
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 3);
	WriteByte(MSG_ALL, 2);
	WriteString(MSG_ALL, h);
};
void() BotSayInit =
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 3);
	WriteByte(MSG_ALL, 1);
	WriteString(MSG_ALL, self.netname);
};
void(string h) BotSay2 =
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 3);
	WriteByte(MSG_ALL, 2);
	WriteString(MSG_ALL, h);
};
void(string h) BotSayTeam = 
{
	// FBX QW doesn't support teamplay...yet
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInit

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


void() BotInit =
{
	local entity ent;
	local integer numents = 0;
	
	// spawn entities for the physics
	ent = nextent(NIL);
	max_clients = 0;

	while(ent != NIL) {
		max_clients = max_clients + 1;
		ent = nextent(ent);
	}

	ent = nextent(NIL);
	while (numents < max_clients) {

		phys_objects[numents] = spawn();
		phys_objects[numents].classname = "phys_obj";
		phys_objects[numents].owner = ent;
		numents++;
		ent = nextent(ent);
	}
	bot_map_load();
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Rankings 'utilities'. Written by Alan Kivlin,
this code just fools clients by sending precisely
the same network messages as when a real player
signs on to the server.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


void(entity who) UpdateClient =
{
	local string bottomcolor = ftos (who.b_pants);
	local string topcolor = ftos (who.b_shirt);
	dprint (who.netname + "\n");
	WriteByte(2, 14 );
	WriteByte(2, (float)who.b_clientno);
	WriteShort(2, who.frags);
	WriteByte(2, 36);
	WriteByte(2, (float)who.b_clientno);
	WriteShort(2, 100 * (3 - who.b_skill));
	WriteByte(2, 37);                // update entertime
	WriteByte(2, (float)who.b_clientno);          // client number
	WriteLong(2, time - who.b_entertime);   // client entertime
	SV_SetUserinfo (who, "\\bottomcolor\\" + bottomcolor
					+ "\\topcolor\\" + topcolor
					+ "\\team\\bot\\skin\\base\\name\\" + who.netname);
	// FIXME: do teams properly
};

float(integer clientno) ClientBitFlag =
{
	local float bitflag;
	bitflag = 1;
	while(clientno > 0) {
		bitflag = bitflag * 2;
		clientno = clientno - 1;
	}
	return bitflag;
};

integer() ClientNextAvailable =
{
	local integer clientno;
	// I want to do this top down, but QW won't let me
	clientno = 0;
	while(clientno < max_clients) {
		clientno = clientno + 1;

		//FIXME if(!ClientIsActive(clientno))
			return clientno;
	}
	return -1;
};


void(entity e1, entity e2, float flag) DeveloperLightning = {};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotConnect and related functions.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/				
entity(float num) GetClientEntity =
{
	local entity upsy;
	upsy = NIL;
	num = num + 1;
	while (num > 0) {
		num = num - 1;
		upsy = nextent(upsy);
	} 
	return upsy;
};

integer (entity cl) ClientNumber =
{
	local entity e = NIL;
	local integer f = -1;

	do {
		f++;
		e = nextent (e);
	} while (e != cl);
	return f;
};

void(float whatbot, float whatskill) BotConnect =
{
	local integer f;
	local entity uself;
	
	//f = ClientNextAvailable();
	uself = self;
	self = SV_AllocClient ();
	if (!self) {
		bprint(PRINT_HIGH, "Unable to connect a bot, server is full.\n");
		self = uself;
		return;
	}
	bot_count++;
	bot_start_topic(1);
	f = ClientNumber (self) + 1;
	self.b_clientno = f;
	self.colormap = (float) f + 1;
	if (whatbot)
		self.netname = BotName(whatbot);
	else
		self.netname = PickARandomName();

	// players can set skill all weird, so leave these checks in
	whatskill = rint(whatskill);
	if (whatskill > 3)
		whatskill = 3;
	else if (whatskill < 0)
		whatskill = 0;
	self.b_skill = whatskill;
	self.b_entertime = time;
	self.team = self.b_pants + 1;
	UpdateClient(self);
	SetNewParms();
	self.ishuman = 2;
	ClientConnect();
	PutClientInServer();
	self = uself;
};

void(entity bot) BotDisconnect =
{
	local entity uself;
	uself = self;
	self = bot;

	bot_count = bot_count - 1;

	ClientDisconnect();

	if (self.b_clientno != -1) {
      		// the bot's client number is not in use by a real player so we
		// must remove it's entry in the rankings
		// Quake engine sets all fields to 0, can only do the most important here
		self.b_frags = self.frags = 0;
		self.netname = "";
		self.classname = "";
		self.health = 0;
		self.items = 0;
		self.armorvalue = 0;
		self.weaponmodel = "";
		self.b_pants = 0;
		self.b_shirt = 0;
		self.ammo_shells = self.ammo_nails = self.ammo_rockets = self.ammo_cells = 0;
		UpdateClient(self);
		self.b_clientno = -1;
   	}
	self = uself;
};

void() BotFrame =
{
	local integer num;
	local string h;
	
	h = infokey(NIL, "bot_options");
	b_options = stof(h);
	
	// for the sake of speed
	sv_maxspeed = cvar("sv_maxspeed");
	sv_gravity = cvar("sv_gravity");
	sv_friction = cvar("sv_friction");
	sv_accelerate = cvar("sv_accelerate");
	sv_stopspeed = cvar("sv_stopspeed");
	real_frametime = time - lasttime; // in QW frametime is fuxx0red
	lasttime = time;
	
	self = nextent(NIL);
	num = 0;
	while (num < max_clients) {
		if (self.ishuman == FALSE) {
			if (self.b_clientno > 0) {
				frik_obstacles();
				CL_KeyMove();
				SV_ClientThink();
				SV_Physics_Client();
				// this is sickening	
				if (self.phys_obj) {
					if (self.phys_obj.modelindex != self.modelindex) {
						setmodel(self.phys_obj, "progs/player.mdl");
						self.phys_obj.modelindex = self.modelindex;
					}
					self.phys_obj.frame = self.frame;
					self.phys_obj.angles = self.angles;
					self.phys_obj.colormap = self.colormap;
					self.phys_obj.effects = self.effects;
				}
			}
		}
		self = nextent(self);
		num = num + 1;
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Impulses. Allows the player to perform bot
related functions.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() BotImpulses =
{
	local float f;
	local string h;
	
	if (self.impulse == 100) {
		h = infokey(NIL, "skill");
		f = stof(h);
		BotConnect(0, f);
	} else if (self.impulse == 102)
		KickABot();
	else
		return;
	self.impulse = 0;
};
