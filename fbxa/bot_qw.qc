
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
* Comment out the following functions in defs.qc
sound, stuffcmd, sprint, aim, centerprint, setspawnparms
WriteByte, WriteChar, WriteShort, WriteLong, WriteCoord
WriteAngle, WriteString, WriteEntity
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

// ----- entity fields ---
.float	wallhug, keys, oldkeys, ishuman;
.float	b_frags, b_clientno, b_shirt, b_pants; 
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
float		active_clients1, active_clients2;
float		max_clients, real_frametime;
float		bot_count, b_options, lasttime;
float		waypoint_mode, dump_mode; 
float		waypoints, direct_route, userid;
float		sv_friction, sv_gravity;
float		sv_accelerate, sv_maxspeed, sv_stopspeed;
entity		fixer;
entity		route_table;
entity		b_temp1, b_temp2, b_temp3;
entity 		player_head, player_tail, phys_head, way_head;
float		busy_waypoints;

float coop = 0; // hack

// ----------Commands---------
void(entity e, float chan, string samp, float vol, float atten) frik_sound = #8;
void(entity client, string s)		frik_stuffcmd	= #21;
void(entity client, float level, string s)	frik_sprint	= #24;
vector(entity e, float sped)		frik_aim = #44;	
void(entity client, string s)		frik_centerprint	= #73;
void(entity e)				frik_setspawnparms	= #78;
void(float to, float f)			frik_WriteByte	= #52;
void(float to, float f)			frik_WriteChar	= #53;
void(float to, float f)			frik_WriteShort	= #54;
void(float to, float f)			frik_WriteLong	= #55;
void(float to, float f)			frik_WriteCoord	= #56;
void(float to, float f)			frik_WriteAngle	= #57;
void(float to, string s)		frik_WriteString	= #58;
void(float to, entity s)		frik_WriteEntity	= #59;

//----------------------------------------------------------------------------

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function redclarations. These allow function 
designed to work for clients (sprint, so forth)
to mainly not complain when working with a bot

Although these shouldn't be needed anymore,
as the bots truly are clients now, if you don't
stop the SZ_ buffer from filling up by disabling
direct messages to the bots, it crashes quake :-(

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void(entity	client, string s) stuffcmd =
{
	if (client.ishuman)
		frik_stuffcmd(client, s);
};

void(entity	e) setspawnparms =
{
	if (e.ishuman)
		frik_setspawnparms(e);
	else
		SetNewParms();
};
void(entity	client, float level, string s) sprint =
{
	if (client.ishuman)
		frik_sprint(client, level, s);
};
void(entity	client, string s) centerprint =
{
	if (client.ishuman)
		frik_centerprint(client, s);
};

vector(entity e, float sped) aim =
{
	e.missile_speed = sped;
	return frik_aim(e, sped);
};

void(entity e, float chan, string samp, float vol, float atten) sound = 
{
	frik_sound(e, chan, samp, vol, atten);
	if (samp == "items/inv3.wav")
		return;
	else if (e.classname == "player")
		e.b_sound = time + 1;
	else if (other.classname == "player")
		other.b_sound = time + 1;
};
void(float to, float f) WriteByte =
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteByte(to, f);
};
void(float to, float f) WriteChar =		
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteChar(to, f);
};
void(float to, float f) WriteShort =	
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteShort(to, f);
};
void(float to, float f) WriteLong = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteLong(to, f);
};
void(float to, float f) WriteCoord = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteCoord(to, f);
};
void(float to, float f) WriteAngle = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteAngle(to, f);
};
void(float to, string s) WriteString = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteString(to, s);
};
void(float to, entity s) WriteEntity = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteEntity(to, s);
};


float(float clientno) ClientIsActive =
{
	if(clientno > 16)
	{
		if(active_clients2 & ClientBitFlag(clientno - 16))
			return TRUE;
		else
			return FALSE;
	}
	else
	{
		if(active_clients1 & ClientBitFlag(clientno))
			return TRUE;
		else
			return FALSE;
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Stuff mentioned up top
it just links the bot into the mod

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() ClientFixRankings =
{
	local float cno;
	if (self.switch_wallhug > time)
		return;
	self.switch_wallhug = 0;

	b_temp2 = nextent(NIL);
	cno = 0;

	while (cno < max_clients)
	{
		if (!b_temp2.ishuman)
		{
			if (ClientIsActive(cno))
				UpdateClient(b_temp2);
		}
		cno = cno + 1;
		b_temp2 = nextent(b_temp2);
	}
};
		
void() ClientInRankings =
{
	local float cno;

	if (!self.phys_obj) {
		// oh no, the server killed our data. THE BASTARD!
		// ie, incoming player
		local entity e;

		// repair the link
		if (player_head != self) {
			e = player_head;
			while (e) {
				if (e._next == self) {
					self._last = e;
					e = NIL;
				} else {
					e = e._next;
				}
			}
		}
		if (player_tail != self) {
			e = player_tail;
			while (e) {
				if (e._last == self) {
					self._next = e;
					e = NIL;
				} else {
					e = e._last;
				}
			}
		}
		// unlink it again
		if (self._last)
			self._last._next = self._next;
		else if (self._next)
			player_head = self._next;
		if (self._next)
			self._next._last = self._last;
		else if (self._last)
			player_tail = self._last;
		self._last = self._next = NIL;
	}
	if (player_head)
		player_head._last = self;
	self._next = player_head;
	player_head = self;
	if (!player_tail)
		player_tail = self;
	userid = userid + 1;
	self.b_userid = userid;
	
	if (!self.phys_obj)
	{
		b_temp2 = phys_head;
		while (b_temp2 != NIL && b_temp2.owner != self)
			b_temp2 = b_temp2._next;
		self.phys_obj = b_temp2;
	}

	if (self.ishuman == 2)
	{
		self.ishuman = FALSE;
		return;
	}
   	cno = self.colormap - 1;
	BotInvalidClientNo (cno);
	if(cno > 16)
		active_clients2 = active_clients2 | ClientBitFlag(cno - 16);
	else
		active_clients1 = active_clients1 | ClientBitFlag(cno);
	self.b_clientno = cno;
	self.ishuman = TRUE;
	self.switch_wallhug = time + 1;
};


void() ClientDisconnected =
{
	if (player_head == self)
		player_head = self._next;
	if (player_tail == self)
		player_tail = self._last;
	if (self._next)
		self._next._last = self._last;
	if (self._last)
		self._last._next = self._next;
	if(self.b_clientno > 16)
		active_clients2 = active_clients2 - (active_clients2 & ClientBitFlag(self.b_clientno - 16));
	else
		active_clients1 = active_clients1 - (active_clients1 & ClientBitFlag(self.b_clientno));
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
	if (self.b_frags != self.frags)
	{
		if (self.b_frags > self.frags)
		{
			if (pointcontents(self.origin) == CONTENT_LAVA)
				bot_start_topic(10);
			else
				bot_start_topic(9);
		}
		else
			bot_start_topic(2);
		self.b_frags = self.frags;
		if (!self.ishuman)
		{
			WriteByte(2, 14);
			WriteByte(2, self.b_clientno);
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
	local entity ent, fisent;
	local float numents = 0;
	
	// spawn entities for the physics
	ent = nextent(NIL);
	max_clients = 0;

	while(ent != NIL)
	{
		max_clients = max_clients + 1;
		ent = nextent(ent);
	}

	ent = nextent(NIL);
	fisent = NIL;
	while (numents < max_clients)
	{

		phys_head = spawn();
		if (fisent)
			fisent._next = phys_head;
		phys_head._last = fisent;
		fisent = phys_head;
		ent.phys_obj = phys_head;
		phys_head.classname = "phys_obj";
		phys_head.owner = ent;
		numents = numents + 1;
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
	WriteByte(2, 14 );
	WriteByte(2, who.b_clientno);
	WriteShort(2, who.frags);
	WriteByte(2, 36);
	WriteByte(2, who.b_clientno);
	WriteShort(2, 100 * (3 - who.b_skill));
	WriteByte(2, 37);                // update entertime
	WriteByte(2, who.b_clientno);          // client number
	WriteLong(2, time - who.b_entertime);   // client entertime
	WriteByte(2, 40 );            // update userinfo
	WriteByte(2, who.b_clientno);      // client number
	WriteLong(2, who.b_userid);      // client userid
	WriteByte(2, 92); // '\'
	WriteByte(2, 98); // 'b'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 116); // 't'
	WriteByte(2, 116); // 't'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 109); // 'm'
	WriteByte(2, 99); // 'c'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 108); // 'l'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 114); // 'r'
	WriteByte(2, 92); // '\'
	if(who.b_pants > 9)
	{
		WriteByte(2, 49);
		WriteByte(2, 38 + who.b_pants);
	}
	else
		WriteByte(2, 48 + who.b_pants);
	WriteByte(2, 92);  // '\'
	WriteByte(2, 116); // 't'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 112); // 'p'
	WriteByte(2, 99);  // 'c'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 108); // 'l'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 114); // 'r'
	WriteByte(2, 92);  // '\'
	if(who.b_shirt > 9)
	{
		WriteByte(2, 49);
		WriteByte(2, 38 + who.b_shirt);
	}
	else
		WriteByte(2, 48 + who.b_shirt);
	WriteByte(2, 92);  // '\'
	WriteByte(2, 116); // 't'
	WriteByte(2, 101); // 'e'
	WriteByte(2, 97);  // 'a'
	WriteByte(2, 109); // 'm'
	WriteByte(2, 92);  // '\'
	WriteByte(2, 98);  // 'b'
	WriteByte(2, 111); // 'o'
	WriteByte(2, 116); // 't'
	// FIXME: do teams properly
	// note this has no effect on infokey
	WriteByte(2, 92 );  // '\'
	WriteByte(2, 115); // 's'
	WriteByte(2, 107); // 'k'
	WriteByte(2, 105); // 'i'
	WriteByte(2, 110); // 'n'
	WriteByte(2, 92);  // '\'
	WriteByte(2, 98);  // 'b'
	WriteByte(2, 97);  // 'a'
	WriteByte(2, 115); // 's'
	WriteByte(2, 101); // 'e'
	WriteByte(2, 92);  // '\'
	WriteByte(2, 110); // 'n'
	WriteByte(2, 97);  // 'a'
	WriteByte(2, 109); // 'm'
	WriteByte(2, 101); // 'e'
	WriteByte(2, 92);  // '\'
	WriteString( 2, who.netname);
};

float(float clientno) ClientBitFlag =
{
	local float bitflag;
	bitflag = 1;
	while(clientno > 0)
	{
		bitflag = bitflag * 2;
		clientno = clientno - 1;
	}
	return bitflag;
};

float() ClientNextAvailable =
{
	local float clientno;
	// I want to do this top down, but QW won't let me
	clientno = 0;
	while(clientno < max_clients)
	{
		clientno = clientno + 1;

		if(!ClientIsActive(clientno))
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
	while (num > 0)
	{
		num = num - 1;
		upsy = nextent(upsy);
	} 
	return upsy;
};

void(float whatbot, float whatskill) BotConnect =
{
	local float f;
	local entity uself;
	
	f = ClientNextAvailable();
	uself = self;
	if(f == -1)
	{
		bprint(PRINT_HIGH, "Unable to connect a bot, server is full.\n");
		return;
	}
	if(f > 16)
		active_clients2 = active_clients2 | ClientBitFlag(f - 16);
	else
		active_clients1 = active_clients1 | ClientBitFlag(f);
	bot_count = bot_count + 1;
	self = GetClientEntity(f);
	bot_start_topic(1);
	self.b_clientno = f;
	self.colormap = f + 1;
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

	if (self.b_clientno != -1)
	{
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
		if(self.b_clientno > 16)
			active_clients2 = active_clients2 - (active_clients2 & ClientBitFlag(self.b_clientno - 16));
		else
			active_clients1 = active_clients1 | (active_clients1 & ClientBitFlag(self.b_clientno));
		self.b_clientno = -1;
   	}
	self = uself;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInvalidClientNo
kicks a bot if a player connects and takes the bot's space

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(float clientno) BotInvalidClientNo =
{
	local entity bot;

	bot = GetClientEntity(clientno);
	if(bot.b_clientno > 0)
	{
		if (!bot.ishuman)
		{
			bot.b_clientno = -1;
			BotDisconnect(bot);
			if(self.b_clientno > 16)
      				active_clients2 = active_clients2 | ClientBitFlag(self.b_clientno - 16);
			else
      				active_clients1 = active_clients1 | ClientBitFlag(self.b_clientno);
			//BotConnect(bot.b_num, bot.b_skill); 
			return;
		}
	}
};

void() BotFrame =
{
	local float num;
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
	while (num < max_clients)
	{
		if (self.ishuman == FALSE)
		{
			if (self.b_clientno > 0)
			{
				frik_obstacles();
				CL_KeyMove();
				SV_ClientThink();
				SV_Physics_Client();
				// this is sickening	
				if (self.phys_obj)
				{
					if (self.phys_obj.modelindex != self.modelindex)
					{
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
	
	if (self.impulse == 100)
	{
		h = infokey(NIL, "skill");
		f = stof(h);
		BotConnect(0, f);
	}
	else if (self.impulse == 102)
		KickABot();
	else
		return;
	self.impulse = 0;
};
