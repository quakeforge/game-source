/*
Breakable Object code taken for Zerstršyer
(originally from someone else(?) - looks a lot like Hipnotic's rubble code...)

Modified for PAROXYSM:
Added options for Glass, Metal and Wood gibs (default is concrete)
Sound has been greatly improved
Added damage variable so gibs can hurt things
Added a patch to remove gibs caught in objects (so you don't get a 'buzz' sound or see a gib spining like crazy)
Fixed some problems with overflow errors (too many gibs!)

These are really cool entities but try to use the few and far between.

*/

float SPAWN_GLASS	 = 2;
float SPAWN_METAL	 = 4;
float SPAWN_WOOD	 = 8;
.float gib_caught; //if a gib bounces more than 4 times it's removed

//-------------------------------------------------------------------
//Added this to facilitate the intergration of the Wall Gib code taken
//from Zerstoer without redoing ALL other calls to VelocityForDamage
//-------------------------------------------------------------------

vector(float dm, vector dir) VelocityForRubble =
{
	local vector v, gib_dir;


	gib_dir = normalize(dir);



	v_x = 90 * gib_dir_x + (random() * 70 - 35);

	v_y = 90 * gib_dir_y + (random() * 70 - 35);

	v_z = 200 + 100 * random();

	if (dm > -50)
	{
//		dprint ("level 1\n");
		v = v * 0.9;
	}
	else if (dm > -200)
	{
//		dprint ("level 3\n");
		v = v * 2;
	}
	else
		v = v * 10;

	return v;
};
//----------------------------------

void() brik_touch =
{
	local float	vol; //vary the hit volume so it don't so so crap!
	
	vol = random();
	
	if (self.velocity == '0 0 0')
	{
		self.avelocity = '0 0 0';
		self.solid = SOLID_NOT;
		self.touch = SUB_Null;
		self.think = SUB_Remove;
		self.nextthink = time + (2 * random());
		return;
	}
	
	
	if (self.gib_caught > 4)
	{
		remove(self);
		return;
	}
	
	//gib already bounced twice so remove damage (it's too easy to die when hit)
	if (self.gib_caught > 1)
		self.dmg = 0;

	if (self.dmg) // do damage if set
	{
		if (other.takedamage)
		{
			T_Damage (other, self, self.owner, self.dmg);
			remove (self);
		}
	}
		
	self.gib_caught = self.gib_caught + 1;
	
	if (!(self.cnt))
		return;
	
	if ((random() < 0.5) || (vol < 0.3)) // mute low volume and random hits to reduce the chance of audio glitches
		return;
		
	//if (self.attack_finished < time)
	if (pointcontents(self.origin) > -3)
	{
	//bounce sound
		if (self.cnt == 1)
		 sound (self, CHAN_AUTO, "ambience/brik_hit.wav", vol, ATTN_NORM);   
		else if (self.cnt == 2)
		 sound (self, CHAN_AUTO, "ambience/brikhit2.wav", vol, ATTN_NORM);
		else if (self.cnt == 3)
		 sound (self, CHAN_AUTO, "ambience/methit1.wav", vol, ATTN_NORM);
		else if (self.cnt == 6)
		 sound (self, CHAN_AUTO, "ambience/methit2.wav", vol, ATTN_NORM);
		else if (self.cnt == 4)
		 sound (self, CHAN_AUTO, "ambience/woodhit1.wav", vol, ATTN_NORM);
		else if (self.cnt == 8)
		 sound (self, CHAN_AUTO, "ambience/woodhit2.wav", vol, ATTN_NORM);
		 
	//self.attack_finished = time + 0.3;
	}
};


void(string gibname, float dm, vector ddir) ThrowRubble=
{
local	entity new;
local float sndrnd;

	new = spawn();
	sndrnd = random();
	// new.origin = self.origin doesnt work because the origin
	// is at world (0,0,0).
	new.origin_x = self.absmin_x + (random() * self.size_x);
	new.origin_y = self.absmin_y + (random() * self.size_y);
	new.origin_z = self.absmin_z + (random() * self.size_z);
	setmodel (new, gibname);
	setsize (new, '0 0 0', '0 0 0');

	if (sndrnd < 0.25)
		new.cnt = 1;
	else if (sndrnd < 0.5)
		new.cnt = 2;
		
	//No bounce sound for glass since initial sound drags on for a bit
	if (self.spawnflags & SPAWN_GLASS)
		new.cnt = 0;
	
	if (self.spawnflags & SPAWN_METAL)
		new.cnt = new.cnt*3; //Play metal bounce on 3 & 6
	
	if (self.spawnflags & SPAWN_WOOD)
	{
		new.cnt = new.cnt*4;	//Play wood bounce on 4 & 8
		new.skin = 1;			//Change skin to wood if wood gib
	}

	new.velocity = VelocityForRubble (dm, ddir);
	new.movetype = MOVETYPE_BOUNCE;
	new.classname = "rubble";
	new.solid = SOLID_BBOX;
	new.touch = brik_touch;
	new.avelocity_x = random()*600;
	new.avelocity_y = random()*600;
	new.avelocity_z = random()*600;
	new.think = SUB_Remove;
	new.ltime = time;
	new.nextthink = time + 10 + random()*10;
	new.dmg = self.dmg;
	new.frame = 0;
	new.flags = 0;
};

void () wall_killed =
// called when the wall is destroyed.
// throws gibs (rubble).
{
	local entity sndspot;
	local float rubble_count = 0;

	sndspot = spawn();
	sndspot.origin = self.absmin;
	setorigin(sndspot, sndspot.origin);
	if (self.spawnflags & SPAWN_GLASS)
		sound (sndspot, CHAN_AUTO, "ambience/glassbrk.wav", 1, ATTN_NORM);
	else if (self.spawnflags & SPAWN_METAL)
		sound (sndspot, CHAN_AUTO, "ambience/metbrk.wav", 1, ATTN_NORM);
	else if (self.spawnflags & SPAWN_WOOD)
		sound (sndspot, CHAN_AUTO, "ambience/woodbrk.wav", 1, ATTN_NORM);
	else // New rubble sound
		sound (sndspot, CHAN_AUTO, "ambience/wall01.wav", 1, ATTN_NORM);

	remove(sndspot);
	// determine volume of destroyed wall and throw rubble accordingly
	rubble_count = (self.size_x * self.size_y * self.size_z) / 64000;
	if (rubble_count > 5)
		rubble_count = 6;

      if (self.spawnflags & SPAWN_GLASS)
      {
	  while (rubble_count > -1) {
			self.dest_x = (random() * 100) - 50;
			self.dest_y = (random() * 100) - 50;
			self.dest_z = (random() * 100);
			//This was cut down by 1/5 to deal with packet overflow errors
		ThrowRubble ("progs/glassrub.mdl", -100, self.dest);
		ThrowRubble ("progs/glassrub.mdl", -100, self.dest);
		ThrowRubble ("progs/glassrub.mdl", -100, self.dest);
		ThrowRubble ("progs/glassrub.mdl", -100, self.dest);
		rubble_count = rubble_count - 1;
	   }
	}
	
	else if (self.spawnflags & SPAWN_METAL)
	{
	     while (rubble_count > -1) {
			self.dest_x = (random() * 100) - 50;
			self.dest_y = (random() * 100) - 50;
			self.dest_z = (random() * 100);
		 ThrowRubble ("progs/mwrub1.mdl", self.health, self.dest);
		 ThrowRubble ("progs/mwrub2.mdl", self.health, self.dest);
		 ThrowRubble ("progs/mwrub3.mdl", self.health, self.dest);
		 ThrowRubble ("progs/mwrub3.mdl", self.health, self.dest);
		 rubble_count = rubble_count - 1;
	     }
	}
	
	 else if (self.spawnflags & SPAWN_WOOD)
	{
	     while (rubble_count > -1) {
			self.dest_x = (random() * 100) - 50;
			self.dest_y = (random() * 100) - 50;
			self.dest_z = (random() * 100);
		 ThrowRubble ("progs/mwrub1.mdl", self.health, self.dest);
		 ThrowRubble ("progs/mwrub2.mdl", self.health, self.dest);
		 ThrowRubble ("progs/mwrub3.mdl", self.health, self.dest);
		 ThrowRubble ("progs/mwrub2.mdl", self.health, self.dest);
		 rubble_count = rubble_count - 1;
	     }
	}
	
	else
	{
	     while (rubble_count > -1) {
			self.dest_x = (random() * 100) - 50;
			self.dest_y = (random() * 100) - 50;
			self.dest_z = (random() * 100);
		 ThrowRubble ("progs/rubble1.mdl", self.health, self.dest);
		 ThrowRubble ("progs/rubble2.mdl", self.health, self.dest);
		 ThrowRubble ("progs/rubble3.mdl", self.health, self.dest);
		 ThrowRubble ("progs/rubble2.mdl", self.health, self.dest);
		 rubble_count = rubble_count - 1;
	     }
	}
	activator = self;
	  SUB_UseTargets();
     
      self.no_obj = TRUE; //mine fix - mines will detonate if spawnmaster.no_obj = TRUE (blown up)
      remove(self);
};

void(entity attacker, float damage) wall_pain =
{
	if(self.health > 0)
		self.health = self.max_health;
};

void() wall_use =
{
	self.health = -100;
	self.dest_x = (random() * 10) - 5;
	self.dest_y = (random() * 10) - 5;
	self.dest_z = (random() * 10);
	wall_killed();
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

Although it is possible to combine different types of explosions on one object, it is
not recommended. You can easily get overflow errors on large objects AND since wood and metal
share a gib model, no metal skins will be used if the wood spawnflag is set.

*/
void() exploding_wall =
{
	setmodel (self, self.model);
	
	//New precache routine
	
	precache_sound("zombie/z_hit.wav"); // for damage
	
	if (self.spawnflags & SPAWN_GLASS)
	{
		precache_model("progs/glassrub.mdl");
		precache_sound("ambience/glassbrk.wav");
	}
	else if (self.spawnflags & SPAWN_METAL)
	{
		precache_model("progs/mwrub1.mdl");
	precache_model("progs/mwrub2.mdl");
	precache_model("progs/mwrub3.mdl");
	precache_sound("ambience/metbrk.wav");
		precache_sound("ambience/methit1.wav");
		precache_sound("ambience/methit2.wav");
	}
	else if (self.spawnflags & SPAWN_WOOD)
	{
		precache_model("progs/mwrub1.mdl");
	precache_model("progs/mwrub2.mdl");
	precache_model("progs/mwrub3.mdl");
		precache_sound("ambience/woodbrk.wav");
		precache_sound("ambience/woodhit1.wav");
		precache_sound("ambience/woodhit2.wav");
	}
   
	else //precache concrete
	{
		precache_model("progs/rubble1.mdl");
		precache_model("progs/rubble2.mdl");
		precache_model("progs/rubble3.mdl");
		precache_sound("ambience/wall01.wav");
		precache_sound("ambience/brik_hit.wav");
		precache_sound("ambience/brikhit2.wav");
	}
	
	self.solid = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	
	//POX v1.2 - default gib damage to 1
	if (!self.dmg)
		self.dmg = 1;
	
	//Added 9.18.98 for PAROXYSM for no-bleed patch
	self.nobleed = TRUE;

	if (self.health)
	{
		self.max_health = self.health;
		self.th_die = wall_killed;
		self.takedamage = DAMAGE_YES;
	}
	else
	{
		self.max_health = 100;
		self.th_die = wall_killed;
		self.takedamage = DAMAGE_YES;
	}
	self.th_pain = wall_pain;
	if (self.targetname)
	{
		self.use = wall_use;
		self.max_health = 10000;
	}
};
