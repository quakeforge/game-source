
//These are  item routines for the POXbot
//It seemed better to write new code for this rather than messing with item.qc.
//This	gives a lot more control over bot-specific stuff

//---------------------------------------
//Health
//---------------------------------------
void()	bot_grab_health =
{
	
	//Needed so packs don't make a health sound in FFA mode
	if (self.goalentity.classname != "pack")
	{
		if (self.goalentity.healamount == 100)
			sound (self, CHAN_ITEM, "items/r_item2.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_ITEM, "items/health1.wav", 1, ATTN_NORM);
	}
				
	self.health = self.health + self.goalentity.healamount;
	
	//max health out at 100 unless megahealth
	if (self.health > self.max_health && self.goalentity.healtype != 2)
		self.health = self.max_health;
	
	//max out megahealth
	if (self.health > 250)
		self.health = 250;

};

void() bound_bot_ammo;

// - POX v1.1 - took a hint from the URQW patch and cleaned this up a bit (got rid of classnames)
//---------------------------------------
//Weapons
//---------------------------------------

//Returns TRUE if bot has the weapon
float(entity weap)	bot_has_weapon =
{
	if (weap.weapon == IT_PLASMAGUN && (!(self.items & IT_PLASMAGUN)))
		return FALSE;
	
	else if (weap.weapon == IT_SUPER_NAILGUN && (!(self.items & IT_SUPER_NAILGUN)))
		return FALSE;
			
	else if (weap.weapon == IT_COMBOGUN && (!(self.items & IT_COMBOGUN)))
		return FALSE;

	else if (weap.weapon == IT_GRENADE_LAUNCHER && (!(self.items & IT_GRENADE_LAUNCHER)))
		return FALSE;

	else if (weap.weapon == IT_ROCKET_LAUNCHER && (!(self.items & IT_ROCKET_LAUNCHER)))
		return FALSE;
	
	else
		return TRUE;

};


void()	bot_grab_weapon =
{
	local	float		weap;

	if (self.goalentity.weapon == IT_PLASMAGUN)
		{
			self.currentammo = self.ammo_cells = self.ammo_cells + 12;
			sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
			weap = IT_PLASMAGUN;
		}
			
	else if (self.goalentity.weapon == IT_SUPER_NAILGUN)
		{
			self.currentammo = self.ammo_nails = self.ammo_nails + 30;
			sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
			weap = IT_SUPER_NAILGUN;
		}
			
	else if (self.goalentity.weapon == IT_COMBOGUN)
		{
			self.ammo_rockets = self.ammo_rockets + 2;
			self.currentammo = self.ammo_shells = self.ammo_shells + 5;
			sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
			weap = IT_COMBOGUN;
		}
			
	else if (self.goalentity.weapon == IT_ROCKET_LAUNCHER)
		{
			self.currentammo = self.ammo_rockets = self.ammo_rockets + 5;
			sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
			weap = IT_ROCKET_LAUNCHER;
		}
			
	else if (self.goalentity.weapon == IT_GRENADE_LAUNCHER)
		{
			self.currentammo = self.ammo_rockets = self.ammo_rockets + 5;
			sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
			weap = IT_GRENADE_LAUNCHER;
		}
		
		bound_bot_ammo();
		self.items = self.items | weap;
		self.weapon = weap;
		
		/*TESTING
		bprint(self.netname);
		bprint(" got the ");
		bprint(self.goalentity.netname);
		bprint ("\n");
		*/	
		
};

//---------------------------------------
//Ammo
//---------------------------------------
//Returns TRUE if bot already has max amount of certain ammo
float(entity am) bot_max_ammo =
{
	if (am.weapon == 1 && (self.ammo_shells < 100))
		return FALSE;
	
	else if (am.weapon  == 2 && (self.ammo_nails < 200))
		return FALSE;
			
	else if (am.weapon  == 3 && (self.ammo_rockets < 100))
		return FALSE;

	else if (am.weapon  == 4 && (self.ammo_cells < 200))
		return FALSE;

	else
		return TRUE;

};

void() bound_bot_ammo =
{
	if (self.ammo_shells > 100)
		self.ammo_shells = 100;
	if (self.ammo_nails > 200)
		self.ammo_nails = 200;
	if (self.ammo_rockets > 100)
		self.ammo_rockets = 100;		
	if (self.ammo_cells > 200)
		self.ammo_cells = 200;	
	return;
	
};

void()	bot_grab_ammo =
{
	sound (self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);	
		
	if (self.goalentity.weapon == 1)
		self.ammo_shells = self.ammo_shells + self.goalentity.aflag;
			
	else if (self.goalentity.weapon == 2)
		self.ammo_nails = self.ammo_nails + self.goalentity.aflag;
		
	else if (self.goalentity.weapon == 3)
		self.ammo_rockets = self.ammo_rockets + self.goalentity.aflag;
			
	else if (self.goalentity.weapon == 4)
		self.ammo_cells = self.ammo_cells + self.goalentity.aflag;

/*TESTING
	bprint(self.netname);
	bprint(" got ");
	bprint(ftos(self.goalentity.aflag));
	bprint (" ammo\n");
*/
			
	bound_bot_ammo();	
};
									
//-------------------------------------------------------------
//This Section handles PowerUps (Quad, Cloalk, MegaShields)
//-------------------------------------------------------------

void() bot_grab_powerup =
{
	if (self.health <= 0)
		return;

	sound (self, CHAN_VOICE, self.goalentity.noise, 1, ATTN_NORM);

	self.items = self.items | self.goalentity.items;

// do the apropriate action
	if (self.goalentity.classname == "item_artifact_envirosuit")
	{
		self.rad_time = 1;
		self.radsuit_finished = time + 30;
	}
	
	if (self.goalentity.classname == "item_artifact_invulnerability")
	{
		self.invincible_time = 1;
		self.invincible_finished = time + 30;
	}
	
	if (self.goalentity.classname == "item_artifact_invisibility")
	{
		self.invisible_time = 1;
		self.invisible_finished = time + 30;
	}

	if (self.goalentity.classname == "item_artifact_super_damage")
	{
		self.super_time = 1;
		self.super_damage_finished = time + 30;
	}	

	//POX - no target use for bots
	//activator = other;
	//SUB_UseTargets();				// fire all targets / killtargets
};

