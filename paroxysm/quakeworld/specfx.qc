/* Frank Condello 09.28.98 - made for the Paroxysm MacQuake Mod.
EMAIL: pox@planetquake.com
WEB: http://www.planetquake.com/paroxysm
=========================================================================
Custom Paroxysm visual and audio effects
These are simple little ambient effects that are customizable within Quiver.
Feel free to use this code in anyway.
=========================================================================
*/
//NOT USED IN POXworld
.float spark_freq; // To avoid 'not a feild' server errors
void() e_spark =
{remove(self);};
void() a_drip =
{remove(self);};
/*
=================================================================================================
Custom Sound Entity (cust_sound)
The lack of a Mac sound editor that produces looping .wav files in a format that Quake understands
prompted the creation of this function. Then I added some options to make it worth while.
snd_attn - sets the sound's attenuation (defaults to ATTN_NORM (1))
snd_volume - sets the sounds overall volume (typically values of 0.5 to 1) default is 1
strt_onoff - 0 = initially on, 1 = initially off
snd_rep - number of times to play the sound (-2 is infinite loop)
snd_loop - delay in seconds before playing sound again (use sound length for looping sounds)
snd_rand - random seed, this number is multiplied by random() and added to loop (default 0 is no random)
the_snd - directory path to the sound - example: "misc/mysound.wav" NOTE: "sound/" is NOT needed
targetname - sounds can be triggered by using a targetname.
TOGGLE_SND - spawn flag, determines if sounds can be toggled on and off.
BUGS
1. Quake won't start playing these sounds on the first frame - (Unless you precache every possible sound
at world_spawn)
HACKY FIX - If you need a sound to play right away;
Position a trigger in such a way that it is touched when the player enters the map - NOT touching the
player initially (doesn't work on frame 1 remember?). Try making a trigger 4 units tall and place
info_player_start just above it. Not pretty, but it does the trick - Don't forget to set
strt_onoff to 1 (initially off) for this to work
2. When Quake no longer 'hears' or more arcurately - 'sees' the sound, it kills it until it comes into view
again. This causes the sound to stop playing and remsume at the NEXT loop point when it is in view, so for
sounds that must be looped constantly, I would reccomend using the ambient_sound function (see below)
=================================================================================================
*/
//NOTE: some of these .floats are used in ambient_sound as well (see below)
float TOGGLE_SND = 1;
.float snd_attn;
.float snd_volume;
.float strt_onoff;
.float snd_rep;
.float snd_rand;
.float snd_loop;
.float snd_strt;
.string the_snd;
void() sound_think;
void() play_sound;
void() sound_wait =
{	
	// hang around until next use
	self.nextthink = time + 60*10;
	self.think = sound_wait;
};
void() stop_sound =
{
	// if sound is set to toggle, silence it and set use to play
	if (self.spawnflags & TOGGLE_SND)
	{
		sound (self, CHAN_VOICE, "misc/null.wav", 0, self.snd_attn);
		self.use = play_sound;
		sound_wait();
	}
	
	// sound doesn't toggle so kill it
	else
	{
		sound (self, CHAN_VOICE, "misc/null.wav", 0, self.snd_attn);
		remove (self);
	}
};
void() play_sound = 
{
	//infinite repeat
	if (self.snd_rep == -2)
	{
		sound (self, CHAN_VOICE, self.the_snd, self.snd_volume, self.snd_attn);
		sound_think();
	}
	
	// sound is done
	else if (self.snd_rep == 0)
		remove (self);
	
	// play the sound and reduce repititions by 1
	if (self.snd_rep >= 1) 
	{
		sound (self, CHAN_VOICE, self.the_snd, self.snd_volume, self.snd_attn);
		self.snd_rep = self.snd_rep - 1;
		sound_think();
	}
	
};
void() sound_think =
{	
	// if sound is toggled, set next use to stop
	if (self.spawnflags & TOGGLE_SND)
		self.use = stop_sound;
	
	// determine user-defined loop time then play the sound
	self.nextthink = time + (random()*self.snd_rand) + self.snd_loop;
	self.think = play_sound;
};
void() cust_sound =
{	
	precache_sound (self.the_snd);
	precache_sound ("misc/null.wav");
	
	//default attenuation to NORM if not specified
	if(!self.snd_attn)
		self.snd_attn = 2;
	
	self.snd_attn = self.snd_attn - 1;// needed so the default to NORM works (since 0 = NONE)
	
	//default volume to one if not specified
	if(self.snd_volume <= 0)
		self.snd_volume = 1;
	
	// start sound if not triggered
	if (!self.targetname)	
		play_sound();
	
	// start sound if initially on, set use to stop_sound
	if (self.strt_onoff == 0)
	{	
		self.use = stop_sound;
		play_sound();
	}
		
	// start sound when triggered
	if (self.strt_onoff == 1)
	{
		self.use = play_sound;
	}
	
};
	
//Made this so custom ambient sounds could be called with a single function
//ONLY WORKS WITH LOOPED .WAV FILES
//Added a targetname attribute so ambient sounds can be triggered.
//NOTE: These sounds can not be stopped once started
//To my knowledge you can't make these with existing Mac sound editors
//(you can make looping wavs, just not ones Quake will loop)
//CoolEdit 1.5 (for Windows) is the only editor that can create these looping wavs (to my knowledge)
void() ambientsound_go =
{
	ambientsound (self.origin, self.the_snd, self.snd_volume, self.snd_attn);
};
void() ambient_sound =
{
	precache_sound (self.the_snd);
	
	//default volume to one if not specified
	if(self.snd_volume <= 0)
		self.snd_volume = 1;
	
	//default attenuation to NORM if not specified
	if(!self.snd_attn)
		self.snd_attn = 2;
	
	self.snd_attn = self.snd_attn - 1;// needed so the default to NORM works (since 0 = NONE)
	
	//start right away if not triggered
	if(!self.targetname)
	{
	//Needs to start on the second frame since that's when entities not called in world_spawn are created
		self.nextthink = time + 0.1; 
		self.think = ambientsound_go;
	}
	
	//wait for trigger
	else
		self.use = ambientsound_go;
};
/*
colour_light is a small hack to try and simulate coloured lighting.
It does this by calling the built-in v_cshift function
This can be used for 'atmospheric' effects like outdoor haze and darkness.
This function is overriden by Quake when under liquids and by the background flash when an item is picked up
The GL Quake command 'gl_polyblend 0' also negates this entity.
colourvalue - this is the only parameter, must be in this format;
v_cshift R G B I\n
where R is Red (0 - 255), G is Green (0 - 255), B is Rlue (0 - 255), and I is Intensity (0 - 255)
This effect works poorly in small increments in GL Quake, no colour will be noticeable until about an
intesity of about 5 (depending on the colour) and some colour/intensity combinations result in ugly
banding. It's best to test colour levels in the console before applying them in your map.
These entities are activated by touch (the colour shift only occurs when the player is touching the trigger field)
But can also be enabled/disabled by using a targetname.
The string must be exactly as shown (including the v_cshift and the carraige return
at the end) I could have used multiple stuffcmd statements to make it more user friendly but.. eh.
*/
void() colourlight_wait;
.string colourvalue;
float CLSTART_OFF = 1;
void() colourlight_off =
{
	if(other.classname != "player")
		return;
	
	//turn it off and reset		
	stuffcmd (other, "v_cshift 0 0 0 0\n");
	self.use = colourlight_wait;
	self.touch = SUB_Null;
	
};
void() colourlight_toggle =
{
	//called after light is triggered a second time
	self.touch = colourlight_off;
};
	
void() colourlight_use =
{	
	if(other.classname != "player")
		return;
	
	//POX v1.2 - better clearing of v_cshift (in PostThink)
	if(other.cshift_finished > time)
		return;
	
	stuffcmd (other, self.colourvalue);
	
	//POX v1.2 - better clearing of v_cshift (in PostThink)
	other.cshift_off = FALSE;
	other.cshift_finished = time + 0.1; //check every frame
	
	//if targetted, alow it to be shut down
	if(self.targetname)
		self.use = colourlight_toggle;
	
};
void() colourlight_wait =
{
	//activated by a trigger so wait for touch
	self.touch = colourlight_use;
};
void() colour_light =
{		
	InitTrigger ();
	
	//Can be made active by use of a targetname
	//Must be triggered by touch
	
	if((!self.targetname) || !(self.spawnflags & CLSTART_OFF))
		self.touch = colourlight_use;
	else
	{
		self.use = colourlight_wait;
		self.touch = SUB_Null;
	}
};
/*
particle_stream
Changed for Paroxysm v1.11's new regen stations
Creates a regen stream-pulse model with out a grate and no touch
This entity should be used in conjunction with a regen_station trigger
clr = skin# (0 = blue, 1 = yellow, 2 = red)
*/
.float clr;
void() regen_ambientsound;
void() particle_stream =
{
	precache_sound("ambience/regen1.wav");
	precache_model ("progs/stream.mdl");
	
	self.angles = '0 0 0';
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	setmodel(self, "progs/stream.mdl");
	
	//POX v1.2 - just in case
	if(self.clr > 2 || self.clr < 0)
		self.clr = 0;
	
	self.skin = self.clr;
	
	//POX v1.2 Fixed sound orign (makestatic messed it up?)
	regen_ambientsound ();
	makestatic (self);
	
};
/*
POX v1.2
misc_explobox
BSP based explo_box'es
Try to use rectangular objects, since entites use bounding box collision detection 
*/
void() bsp_explode =
{
	self.takedamage = DAMAGE_NO;
	self.trigger_field.classname = "explo_box";
	
	// did say self.owner
	T_RadiusDamage (self.trigger_field, self.trigger_field, self.dmg, world, "");
	sound (self.trigger_field, CHAN_VOICE, "weapons/r_exp3.wav", 1, ATTN_NORM);
	
	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte (MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord (MSG_MULTICAST, self.trigger_field.origin_x);
	WriteCoord (MSG_MULTICAST, self.trigger_field.origin_y);
	WriteCoord (MSG_MULTICAST, self.trigger_field.origin_z);
	multicast (self.origin, MULTICAST_PHS);

	remove (self);
	remove (self.trigger_field);
};
void() misc_explobsp =
{
	local entity spot;
	
	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	
	setmodel (self, self.model);
	setsize( self, self.mins, self.maxs );
	precache_sound ("weapons/r_exp3.wav");
	
	if (!self.health)
		self.health = 20;
	
	if (!self.dmg)
		self.dmg = 160;
	
	self.th_die = bsp_explode;
	self.takedamage = DAMAGE_AIM;
	self.nobleed = TRUE;
	
	//POX 1.2 - HACK!
	//put a null entity at the center of the model to hold the explosion position
	spot = spawn(); 
	setmodel (spot, string_null);
	spot.origin_x = self.absmin_x + (self.size_x * 0.5);
	spot.origin_y = self.absmin_y + (self.size_y * 0.5);
	spot.origin_z = self.absmin_z + (self.size_z * 0.5);
	setsize (spot, '0 0 0', '0 0 0');
	self.trigger_field = spot;
};
