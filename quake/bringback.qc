// bring back qc file, contains all the functions added to create the
// 'respawn effect
// void bringback ();  declared in ogre.qc ( first file its referanced in);
// void savecritter ();  ""

integer respawn_enabled;

void () savecritter =
{
	// .max_health was only used by player untill now
	self.max_health = self.health;
	// .oldorigin only used by secret doors, untill now.
	self.oldorigin  = self.origin;
	// .weaponmodel is only used to show the players currentweapon (on the hud)
	self.weaponmodel = self.model;
};

void () bringback =
{
	if (!respawn_enabled)
		return;

	self.frags++;

	if (self.frags == 50) {
		//ThrowGib ("progs/gib1.mdl", self.health);
		//ThrowGib ("progs/gib2.mdl", self.health);
		//ThrowGib ("progs/gib3.mdl", self.health);
		spawn_tfog (self.origin);
		setmodel (self, "");
	}
	if (self.frags > 100) {
		self.solid = SOLID_SLIDEBOX;
		self.movetype = MOVETYPE_STEP;
		self.takedamage = DAMAGE_AIM;

		self.frags = 1;

		if (mapname != "end")	
			self.origin = self.oldorigin;
		
		setmodel(self, self.weaponmodel);
		self.health = self.max_health;

		// about 3/4 of quakes critters use this size
		setsize (self, '-16 -16 -24', '16 16 40');

		if (self.classname == "monster_demon1")
			setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
		if (self.classname == "monster_ogre")
			setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
		if (self.classname == "monster_shalrath")
			setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
		if (self.classname == "monster_shambler")
			setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
		if (self.classname == "monster_dog")
			setsize (self, '-32 -32 -24', '32 32 40');
		if (self.classname == "monster_fish") {
			setsize (self, '-16 -16 -24', '16 16 24');
			self.flags = self.flags + FL_SWIM;
		}
		if (self.classname == "monster_wizard")
			self.flags = self.flags + FL_FLY;
		
		spawn_tfog (self.origin);
		spawn_tdeath (self.origin, self);
		if (FindTarget) {
			self.think = self.th_run;
		} else {
			self.think = self.th_walk;
		}

		if (!(self.flags & FL_FLY) && !(self.flags & FL_SWIM)) {
			self.origin_z = self.origin_z + 1;	
			droptofloor ();
		}
	}
};
