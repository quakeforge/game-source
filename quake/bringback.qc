// bring back qc file, contains all the functions added to create the
// 'respawn effect
// void bringback ();  declared in ogre.qc ( first file its referanced in);
// void savecritter ();  ""

integer respawn_enabled = 1;

@static {

void () hes_dead_jim = [ self.frame, im_alive, 10 ] { }

void () im_alive = [ 0, (self.th_walk), 0.2 ]
{
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	self.takedamage = DAMAGE_AIM;

	if ((mapname != "end") && (random() < 0.5))
		self.origin = self.oldorigin;
	
	setmodel(self, self.weaponmodel);
	self.health = self.max_health;
	
	switch (self.classname) {
		case "monster_demon1":
		case "monster_ogre":
		case "monster_shalrath":
		case "monster_shambler":
			setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
			break;
		case "monster_dog":
			setsize (self, '-32 -32 -24', '32 32 40');
			break;
		case "monster_fish":
			setsize (self, '-16 -16 -24', '16 16 24');
			self.flags = self.flags + FL_SWIM;
			break;
		case "monster_wizard":
			setsize (self, '-16 -16 -24', '16 16 40');
			self.flags = self.flags + FL_FLY;
			break;
		default:
			// about 3/4 of quakes critters use this size
			setsize (self, '-16 -16 -24', '16 16 40');
			break;
	}
	
	spawn_tdeath (self.origin, self);
	spawn_tfog (self.origin);

	//Don't stay angry at everyone.
	self.enemy = NIL;
	
	//We have to set the origin no matter what kind of creature it is, so the
	//thing becomes solid again. (Maybe, maybe not? Can't hurt anyway...)
	if (!(self.flags & FL_FLY) && !(self.flags & FL_SWIM)) {
		setorigin (self, self.origin + '0 0 1');
		droptofloor ();
	} else {
		//Flyer/Fish
		setorigin (self, self.origin);
	}
}

};

void () savecritter =
{
	// .max_health was only used by player until now
	self.max_health = self.health;
	// .oldorigin only used by secret doors, until now.
	self.oldorigin  = self.origin;
	// .weaponmodel is only used to show the players current weapon (on the hud)
	self.weaponmodel = self.model;
};

void () bringback =
{
	if (!respawn_enabled)
		return;

	hes_dead_jim ();
};
