#include "config.rh"
#include "paroxysm.rh"

/* Frank Condello 09.28.98 - made for the Paroxysm Quake Mod.
EMAIL: pox@planetquake.com
WEB: http://www.planetquake.com/paroxysm/
=========================================================================
*/

//Armor regeneration stations
//surprisingly little coding required to get this going
//Had to add a value/type check routine in T_Damage

// Armor is gained by standing at regen stations.
// The color of armor only indocates how much power your armor has left;
// all armor protects the same amount.

// A breakdown:
// 1 - 50 points is blue
// 51 - 150 points is yellow
// 151 - 255 points is red

// Regen Station default ambient sound
void() regen_ambientsound =
{
	ambientsound (self.origin, "ambience/regen1.wav", 0.5, ATTN_STATIC);
};

// Particle stream replaced by a model with client side animation
#if 0
// A particle effect for regen stations
void (void) regen_make_smoke =
{
	particle (self.origin + '0 0 +6', '1 1 36', self.clr, 12);
	particle (self.origin + '0 0 +6', '-1 -1 36', self.clr, 12);
	self.nextthink = time + 0.1;
};
#endif

// Particle-emiting entity
void (float color) regen_streamer =
{
	local entity	streamer;

	streamer = spawn ();
	streamer.solid = SOLID_TRIGGER;
	streamer.movetype = MOVETYPE_TOSS;

	setmodel (streamer, "progs/stream.mdl");
	setsize (streamer, '-16 -16 0', '16 16 56');
	streamer.velocity = '0 0 0';
	setorigin (streamer, self.origin);

	streamer.skin = color;

	regen_ambientsound ();
};

void () regen_touch =
{   
	if (other.classname != "player")
		return;

	if (other.regen_finished > time)	// already touched
		return;

	if (other.armorvalue >= self.armregen) { // Station can't give more
		other.regen_finished = time;
		return;
	}

	other.armregen = self.armregen;
	other.regen_finished = time + 0.2;
	
};

// Regen triggers for custom maps - can be BIG (whole rooms)
void () regen_station =
{	
	if (self.armregen <= 0)
		self.armregen = 50;
	InitTrigger ();
	self.touch = regen_touch;
	//self.netname = "regen station";
};

void (float type, float value) item_armor =
{
	if (type < 0 || type > 2)	// sanity checking
		return;

	precache_sound ("ambience/regen1.wav");

	precache_model ("progs/regen.mdl");
	precache_model ("progs/stream.mdl");

	self.touch = regen_touch;
	setmodel (self, "progs/regen.mdl");
	self.skin = type;
	setsize (self, '-16 -16 0', '16 16 56');
	self.solid = SOLID_TRIGGER;

	// Some existing DM maps rely on Droptofloor for proper placement
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	//self.netname = "regen station";

	self.armregen = value;

	regen_streamer (type);
};

// Replace armor pickups in existing maps
void () item_armor1 =
{
	item_armor (0, 50);
};

void () item_armor2 =
{
	item_armor (1, 150);
};

void() item_armorInv =
{
	item_armor (2, 250);
};
