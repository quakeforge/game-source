#include "config.rh"

#include "paroxysm.rh"

/*
	Breakable object code

	These are really cool entities, but try not to overuse them.
*/
#define SPAWN_GLASS		2
#define SPAWN_METAL		4
#define SPAWN_WOOD		8

.integer gib_caught; // if a gib bounces more than 4 times it's removed

vector (float dm, vector dir) VelocityForRubble =
{
	local vector	v, gib_dir;

	gib_dir = normalize (dir);

	v_x = 90 * gib_dir_x + (random () * 70 - 35);
	v_y = 90 * gib_dir_y + (random () * 70 - 35);
	v_z = 200 + 100 * random ();

	if (dm > -50) {
		v *= 0.9;
	} else if (dm > -200) {
		v *= 2;
	} else {
		v *= 10;
	}

	return v;
};

void () brik_touch =
{
	local float		vol; // randomize the volume so it don't sound like shit

	vol = random ();

	if (@self.velocity == '0 0 0') {
		@self.avelocity = '0 0 0';
		@self.solid = SOLID_NOT;
		@self.touch = nil;
		@self.think = SUB_Remove;
		@self.nextthink = time + (2 * random());
		return;
	}

	if (@self.gib_caught > 4) {
		remove (@self);
		return;
	}

	// Gib already bounced twice, so remove damage (too easy to get killed)
	if (@self.gib_caught > 1)
		@self.dmg = 0;

	if (@self.dmg) { // do damage if set
		if (other.takedamage) {
			T_Damage (other, @self, @self.owner, @self.dmg);
			remove (@self);
		}
	}

	@self.gib_caught++;

	if (!(@self.cnt))
		return;

	if (vol < 0.3) // mute low volume
		return;

	if (pointcontents(@self.origin) == CONTENT_SOLID) {	// bounce sound
		switch (@self.cnt) {
			case 1:
				sound (@self, CHAN_AUTO, "ambience/brik_hit.wav", vol, ATTN_NORM);
				break;
			case 2:
				sound (@self, CHAN_AUTO, "ambience/brikhit2.wav", vol, ATTN_NORM);
				break;
			case 3:
				sound (@self, CHAN_AUTO, "ambience/methit1.wav", vol, ATTN_NORM);
				break;
			case 4:
				sound (@self, CHAN_AUTO, "ambience/woodhit1.wav", vol, ATTN_NORM);
				break;
			case 6:
				sound (@self, CHAN_AUTO, "ambience/methit2.wav", vol, ATTN_NORM);
				break;
			case 8:
				sound (@self, CHAN_AUTO, "ambience/woodhit2.wav", vol, ATTN_NORM);
				break;
		}
	}
};

void (string gibname, float dm, vector ddir) ThrowRubble =
{
	local entity	new;
	local float		sndrnd;

	new = spawn ();
	sndrnd = random ();

	// new.origin = @self.origin doesnt work because the origin
	// is at world (0,0,0).
	new.origin_x = @self.absmin_x + (random() * @self.size_x);
	new.origin_y = @self.absmin_y + (random() * @self.size_y);
	new.origin_z = @self.absmin_z + (random() * @self.size_z);

	setmodel (new, gibname);
	setsize (new, '0 0 0', '0 0 0');

	if (sndrnd < 0.25)
		new.cnt = 1;
	else if (sndrnd < 0.5)
		new.cnt = 2;

	// No bounce sound for glass since initial sound drags on for a bit
	if (@self.spawnflags & SPAWN_GLASS)
		new.cnt = 0;
	
	if (@self.spawnflags & SPAWN_METAL)
		new.cnt *= 3;	// Play metal bounce on 3 & 6
	
	if (@self.spawnflags & SPAWN_WOOD) {
		new.cnt *= 4;	// Play wood bounce on 4 & 8
		new.skin = 1;	// Change skin to wood if wood gib
	}

	new.velocity = VelocityForRubble (dm, ddir);
	new.movetype = MOVETYPE_BOUNCE;
	new.classname = "rubble";
	new.solid = SOLID_BBOX;
	new.touch = brik_touch;
	new.avelocity_x = random () * 600;
	new.avelocity_y = random () * 600;
	new.avelocity_z = random () * 600;
	new.think = SUB_Remove;
	new.ltime = time;
	new.nextthink = time + 10 + random () * 10;
	new.dmg = @self.dmg;
	new.frame = 0;
	new.flags = 0;
};

/*
	wall_killed

	Called when a wall is destroyed. Throws "gibs" (rubble).
*/
void () wall_killed =
{
	local entity	sndspot;
	local float		rubble_count = 0;
	local string	md1, md2, md3, md4;

	sndspot = spawn();
	sndspot.origin = @self.absmin;
	setorigin (sndspot, sndspot.origin);

	if (@self.spawnflags & SPAWN_GLASS)
		sound (sndspot, CHAN_AUTO, "ambience/glassbrk.wav", 1, ATTN_NORM);
	else if (@self.spawnflags & SPAWN_METAL)
		sound (sndspot, CHAN_AUTO, "ambience/metbrk.wav", 1, ATTN_NORM);
	else if (@self.spawnflags & SPAWN_WOOD)
		sound (sndspot, CHAN_AUTO, "ambience/woodbrk.wav", 1, ATTN_NORM);
	else // New rubble sound
		sound (sndspot, CHAN_AUTO, "ambience/wall01.wav", 1, ATTN_NORM);

	remove (sndspot);

	// determine volume of destroyed wall and throw rubble accordingly
	rubble_count = (@self.size_x * @self.size_y * @self.size_z) / 64000;

	if (rubble_count > 5)
		rubble_count = 6;

	if (@self.spawnflags & SPAWN_GLASS) {
		md4 = md3 = md2 = md1 = "progs/glassrub.md";

		while (rubble_count > -1) {
			@self.dest_x = (random () * 100) - 50;
			@self.dest_y = (random () * 100) - 50;
			@self.dest_z = (random () * 100);

			// This was cut down by 1/5 to deal with packet overflow errors
			ThrowRubble (md1, -100, @self.dest);
			ThrowRubble (md2, -100, @self.dest);
			ThrowRubble (md3, -100, @self.dest);
			ThrowRubble (md4, -100, @self.dest);
			rubble_count--;
		}
	} else {
		if (@self.spawnflags & SPAWN_METAL) {
			md1 = "progs/mwrub1.mdl";
			md2 = "progs/mwrub2.mdl";
			md4 = md3 = "progs/mwrub3.mdl";
		} else if (@self.spawnflags & SPAWN_WOOD) {
			md1 = "progs/mwrub1.mdl";
			md4 = md2 = "progs/mwrub2.mdl";
			md3 = "progs/mwrub3.mdl";
		} else {
			md1 = "progs/rubble1.mdl";
			md4 = md2 = "progs/rubble2.mdl";
			md3 = "progs/rubble3.mdl";
		}

		while (rubble_count > -1) {
			@self.dest_x = (random () * 100) - 50;
			@self.dest_y = (random () * 100) - 50;
			@self.dest_z = (random () * 100);

			ThrowRubble (md1, @self.health, @self.dest);
			ThrowRubble (md2, @self.health, @self.dest);
			ThrowRubble (md3, @self.health, @self.dest);
			ThrowRubble (md4, @self.health, @self.dest);
			rubble_count--;
		}
	}
	activator = @self;

	SUB_UseTargets ();
     
	@self.no_obj = TRUE; // mine fix - mines will detonate if spawnmaster.no_obj = TRUE (blown up)
	remove (@self);
};

void() wall_pain =
{
	if (@self.health > 0)
		@self.health = @self.max_health;
};

void() wall_use =
{
	@self.health = -100;
	@self.dest_x = (random () * 10) - 5;
	@self.dest_y = (random () * 10) - 5;
	@self.dest_z = (random () * 10);
	wall_killed ();
};

/*QUAKED exploding_wall
When the exploding wall is shot, it "gibs" into rubble.
Can also be triggered to explode.

"target"	all entities with a matching targetname will be used when killed
"health"	the amount of damage needed to destroy the wall instead of touched
"dmg"		damage caused when hit by a gib

New Spawnflags added for PAROXYSM:

SPAWN_GLASS - glass explosion

SPAWN_METAL - metal shrapnel

SPAWN_WOOD - wood splintering

- no spawnflags is concrete rubble

Although it is possible to combine different types of explosions on one object,
it is not recommended. You can easily get overflow errors on large objects AND
since wood and metal share a gib model, no metal skins will be used if the
wood spawnflag is set.
*/
void() exploding_wall =
{
	setmodel (@self, @self.model);
	
	// New precache routine
	
	precache_sound("zombie/z_hit.wav"); // for damage
	
	if (@self.spawnflags & SPAWN_GLASS) {
		precache_model("progs/glassrub.mdl");
		precache_sound("ambience/glassbrk.wav");
	} else if (@self.spawnflags & SPAWN_METAL) {
		precache_model("progs/mwrub1.mdl");
		precache_model("progs/mwrub2.mdl");
		precache_model("progs/mwrub3.mdl");
		precache_sound("ambience/metbrk.wav");
		precache_sound("ambience/methit1.wav");
		precache_sound("ambience/methit2.wav");
	} else if (@self.spawnflags & SPAWN_WOOD) {
		precache_model("progs/mwrub1.mdl");
		precache_model("progs/mwrub2.mdl");
		precache_model("progs/mwrub3.mdl");
		precache_sound("ambience/woodbrk.wav");
		precache_sound("ambience/woodhit1.wav");
		precache_sound("ambience/woodhit2.wav");
	} else { // precache concrete
		precache_model("progs/rubble1.mdl");
		precache_model("progs/rubble2.mdl");
		precache_model("progs/rubble3.mdl");
		precache_sound("ambience/wall01.wav");
		precache_sound("ambience/brik_hit.wav");
		precache_sound("ambience/brikhit2.wav");
	}

	@self.solid = SOLID_BBOX;
	@self.movetype = MOVETYPE_NONE;
	
	// POX v1.2 - default gib damage to 1
	if (!@self.dmg)
		@self.dmg = 1;
	
	@self.nobleed = TRUE;

	if (@self.health) {
		@self.max_health = @self.health;
		@self.th_die = wall_killed;
		@self.takedamage = DAMAGE_YES;
	} else {
		@self.max_health = 100;
		@self.th_die = wall_killed;
		@self.takedamage = DAMAGE_YES;
	}

	@self.th_pain = wall_pain;

	if (@self.targetname) {
		@self.use = wall_use;
		@self.max_health = 10000;
	}
};
