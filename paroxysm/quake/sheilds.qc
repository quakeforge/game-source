/* Frank Condello 09.28.98 - made for the Paroxysm Quake Mod.
EMAIL: pox@planetquake.com
WEB: http://www.planetquake.com/paroxysm/
=========================================================================
*/

//Armor regeneration stations
//surprisingly little coding required to get this going
//Had to add a value/type check routine in T_Damage

//Armour is now gained by standing at Regen_stations,
//The colour of armour only indocates how much you have, it is always the same strength

//Here's a breakdown:
//1 - 50 points is blue
//51 - 150 points is yellow
//151 - 255 points is red

.float armregen;


//RegenStation Default Ambient Sound
void() regen_ambientsound =
{
	ambientsound (self.origin, "ambience/regen1.wav", 0.5, ATTN_STATIC);
};

//POX v1.11 - particle stream replaced by a mdl with client side animation (for POXworld)

/*
//A paritcle effect for regen stations
void() regen_make_smoke =
{
	particle (self.origin + '0 0 +6', '1 1 36', self.clr, 12);
	particle (self.origin + '0 0 +6', '-1 -1 36', self.clr, 12);
	self.nextthink = time + 0.1;
};
*/

void(float colour) regen_streamer =
{
	local entity streamer;
	
	streamer = spawn();
	streamer.solid = SOLID_TRIGGER;
	streamer.movetype = MOVETYPE_TOSS;
	
	setmodel(streamer, "progs/stream.mdl");

	setsize (streamer, '-16 -16 0', '16 16 56');

	streamer.velocity = '0 0 0';
	setorigin(streamer, self.origin);
	
	streamer.skin = colour;
	
	regen_ambientsound();
	
};


void() regen_touch =
{   
local	float	type, bit;
local string snd;

	if (self.attack_finished > time)
	{
		return; // delay not over yet
	}
	
	if (other.classname != "player" && other.classname != "bot")
		return;
	
	if (other.armorvalue >= self.armregen)
		return; // already have max armour that station can give

//POX - 1.01b - Doubled Regen Speed
	other.armorvalue = other.armorvalue + 2;
	
	//Due to poor touch recogniton on non-clients
	if (other.classname == "bot")
		other.armorvalue = other.armorvalue + 1;

	//Cap armour
	if (other.armorvalue > self.armregen)
		other.armorvalue = self.armregen;
	
	if (other.armorvalue > 150) //Equivlent to Red (level 3) Armour
	{
		type = 0.8;
		snd = "items/sheild3.wav";
		bit = IT_ARMOR3;
		self.attack_finished = time + 0.04;
	}
	else if (other.armorvalue > 50) //Equivlent to Yellow (level 2) Armour
	{
		type = 0.8;
		snd = "items/sheild2.wav";
		bit = IT_ARMOR2;
		self.attack_finished = time + 0.025;
	}
	else if (other.armorvalue > 1) //Equivlent to Blue (level 1) Armour
	{
		type = 0.8;
		snd = "items/sheild1.wav";
		bit = IT_ARMOR1;
		self.attack_finished = time + 0.01;
	}
	else //you aint got squat
	{
		type = 0;
		snd = "misc/null.wav";
		bit = 0;
	}
	
	//set armour type
	other.armortype = type;
	other.items = other.items - (other.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)) + bit;
	sound (other, CHAN_AUTO, snd, 1, ATTN_NORM);
	
	//POX - 1.01b - Don't allow armour to rot while recharging
	other.armor_rot = time + 5;

};

//Regen triggers for custom maps - can be BIG (whole rooms)
void() regen_station =
{	
	precache_sound("items/sheild1.wav");
	precache_sound("items/sheild2.wav");
	precache_sound("items/sheild3.wav");
	precache_sound("misc/null.wav");
	
	if (self.armregen <= 0)
		self.armregen = 50;

	InitTrigger ();
	self.touch = regen_touch;
	//self.netname = "regen station";

};


//These replace armor in existing Maps
void() item_armor1 =
{
	precache_sound("items/sheild1.wav");
	precache_sound("items/sheild2.wav");
	precache_sound("items/sheild3.wav");
	precache_sound("misc/null.wav");
	precache_sound("ambience/regen1.wav");
	
	precache_model ("progs/regen.mdl");
	precache_model ("progs/stream.mdl");
	
	self.touch = regen_touch;

	setmodel (self, "progs/regen.mdl");
	self.skin = 0;
	setsize (self, '-16 -16 0', '16 16 56');
	
	self.solid = SOLID_TRIGGER;
	//some existing DM maps rely on Droptofloor for proper placement
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;

	self.armregen = 50;
	//self.netname = "regen station";
	
	regen_streamer(0);
	
};


void() item_armor2 =
{
	precache_sound("items/sheild1.wav");
	precache_sound("items/sheild2.wav");
	precache_sound("items/sheild3.wav");
	precache_sound("misc/null.wav");
	precache_sound("ambience/regen1.wav");
	
	precache_model ("progs/regen.mdl");
	precache_model ("progs/stream.mdl");
	
	self.touch = regen_touch;

	setmodel (self, "progs/regen.mdl");
	self.skin = 1;
	setsize (self, '-16 -16 0', '16 16 56');
	self.solid = SOLID_TRIGGER;
	//some existing DM maps rely on Droptofloor for proper placement
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	
	self.armregen = 150;
	//self.netname = "regen station";
	
	regen_streamer(1);

};


void() item_armorInv =
{
	precache_sound("items/sheild1.wav");
	precache_sound("items/sheild2.wav");
	precache_sound("items/sheild3.wav");
	precache_sound("misc/null.wav");
	precache_sound("ambience/regen1.wav");
	
	precache_model ("progs/regen.mdl");
	precache_model ("progs/stream.mdl");
	
	self.touch = regen_touch;

	setmodel (self, "progs/regen.mdl");
	self.skin = 2;
	setsize (self, '-16 -16 0', '16 16 56');
	self.solid = SOLID_TRIGGER;
	//some existing DM maps rely on Droptofloor for proper placement
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	
	self.armregen = 250;
	//self.netname = "regen station";
	
	regen_streamer(2);

};


