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

//POX v1.2 - moved to client.qc
//.float armregen;


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

//Particle emiting entity
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
	if (other.regen_finished > time) //already touched
		return;

	if (other.classname != "player")
		return;
	
	if (other.armorvalue >= self.armregen)
	{
		other.regen_finished = time;
		return; // already have max armour that station can give
	}
	
	other.armregen = self.armregen;
	other.regen_finished = time + 0.2;
	
};

//Regen triggers for custom maps - can be BIG (whole rooms)
void() regen_station =
{	

	if (self.armregen <= 0)
		self.armregen = 50;

	InitTrigger ();
	self.touch = regen_touch;
	//self.netname = "regen station";

};


//These replace armor in existing Maps
void() item_armor1 =
{

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


