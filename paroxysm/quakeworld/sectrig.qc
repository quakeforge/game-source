// + POX moved prototypes from weapons.qc for use here
void(float shotcount, vector dir, vector spread) FireBullets2;
void(float damage) spawn_touchblood;
void() muzzleflash;

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore, string dtype) T_RadiusDamage;
void(vector org, float damage) SpawnBlood;
void() SuperDamageSound;

float SECOND_TRIGGER = 15;	// Impulse constant for second trigger (more readable than 15)

void(vector org) launch_shrapnel; //Predeclare

void()	player_shot1;
void()	player_gshot1;
void()	player_plasma1;
void()	player_plasma2;
void()	player_mplasma1;
void()	player_nail1;
void()	player_rocket1;
void()	player_rocketload1;
void()	player_grenade1;
void()	player_reshot1;
void()	player_tshot1;
void()	player_shrap1;
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;


//Some nitty-gritty from weapons.qc ...

float() crandom =
{
	return 2*(random() - 0.5);
};


vector() wall_velocity =
{
	local vector	vel;
	
	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;
	
	return vel;
};

/*
================
Triple Barrel Shot for T-shot
Close Range Gibber - long range spread
================
*/
void() W_FireTShot =
{
	local vector dir;

	sound (self ,CHAN_WEAPON, "weapons/ts3fire.wav", 1, ATTN_NORM); 

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_BIGKICK);
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -80;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - 3;
	dir = aim (self, 100000);
	//POX - 1.01b2 - increased spread, reduced amount
	//POX - 1.1	- made FireBullets2 (twice the damge, half the pellets + 1 :)
	FireBullets2 (12, dir, '0.16 0.1 0'); //make priming this thing worth while!
};


//=================================================================================
//Start MegaPlasmaBurst - Used by PlasmaGun's Second Trigger
//=================================================================================

void() T_MplasmaTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner
	
	if (self.voided) {
		return;
	}
	
	self.voided = 1;
	
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 120 + random()*20;
	
	T_RadiusDamage (self, self.owner, damg, world, "megaplasma");

	sound (self, CHAN_WEAPON, "weapons/mplasex.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte (MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord (MSG_MULTICAST, self.origin_x);
	WriteCoord (MSG_MULTICAST, self.origin_y);
	WriteCoord (MSG_MULTICAST, self.origin_z);
	multicast (self.origin, MULTICAST_PHS);

	remove(self);

};


//launch_megaplasma

void() launch_megaplasma =
{
	local vector	dir;
	
	self.currentammo = self.ammo_cells = self.ammo_cells - 9;
	
	sound (self, CHAN_WEAPON, "weapons/mplasma.wav", 1, ATTN_NORM);

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_BIGKICK);
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -270;

	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "megaplasma";
	newmis.effects = newmis.effects | EF_BLUE;

// set speed
	dir = aim ( self, 1000 );
	newmis.velocity = dir * 0.01;
	newmis.avelocity = '300 300 300';
	newmis.angles = vectoangles(newmis.velocity);
	newmis.velocity = normalize(newmis.velocity);
	newmis.velocity = newmis.velocity * 950;
	
	newmis.touch = T_MplasmaTouch;
	
// set duration
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 5;
	setmodel (newmis, "progs/plasma.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, self.origin + v_forward*12 + '0 0 12');
};

//End MegaPlasmaBurst
//=================================================================================


//=============================================================================
//
// START PumkinBall CODE - Used by SuperShotgun's Second Trigger (Impact Grenades)														
//
//=============================================================================

void() T_PballTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner
	
	if (self.voided) {
		return;
	}
	
	self.voided = 1;
	
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
	damg = 100 + random()*20;

	T_RadiusDamage (self, self.owner, damg, world, "impactgrenade");

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte (MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord (MSG_MULTICAST, self.origin_x);
	WriteCoord (MSG_MULTICAST, self.origin_y);
	WriteCoord (MSG_MULTICAST, self.origin_z);
	multicast (self.origin, MULTICAST_PHS);

	remove(self);
};

/*
================
W_FirePball
================
*/
void() W_FirePball =
{
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
	
	sound (self, CHAN_AUTO, "weapons/ssgrnde.wav", 1, ATTN_NORM);

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_BIGKICK);
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -150;

	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "impactgrenade";
		
// set newmis speed	

	makevectors (self.v_angle);

	newmis.velocity = v_forward*700 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;

	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = T_PballTouch;
	
// set newmis duration
	newmis.nextthink = time + 2.5;

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, self.origin + v_forward*4);
};

// END PumkinBall CODE														
//=============================================================================



//=============================================================================
//
// START MINE CODE (based on hipnotic's proximity mine - uh... hacked to death) 
// Used for the Grenade Launcher's Second Trigger
// This is some laughable, sick code
// But it works.
//
//=============================================================================

void() M_DamExplode =
{	
	if (self.voided) {
		return;
	}
	self.voided = 1;
	
	T_RadiusDamage (self, self.owner, 95, world, "mine");
	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte (MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord (MSG_MULTICAST, self.origin_x);
	WriteCoord (MSG_MULTICAST, self.origin_y);
	WriteCoord (MSG_MULTICAST, self.origin_z);
	multicast (self.origin, MULTICAST_PHS);
	
	remove (self);
};

/*
================
MineExplode
================
*/

//explode immediately! (for doors, plats and breakable objects
void() MineImExplode =
{
	self.takedamage = DAMAGE_NO;
	self.deathtype = "mine";
	self.owner = self.lastowner;
	M_DamExplode();
};

void() MineExplode =
{
	self.takedamage = DAMAGE_NO;
	self.deathtype = "mine";
	self.nextthink = time + random()*0.15; //gives a more organic explosion when multiple mines explode at once
	self.owner = self.lastowner;
	self.think = M_DamExplode;
};

/*
================
MineTouch
================
*/
void() MineTouch =
	{
   
	if (other == self)
	{
		return;
	}
	
	if (other.solid == SOLID_TRIGGER)
	{
		sound (self, CHAN_AUTO, "weapons/bounce.wav", 1, ATTN_NORM);
		return;
	}
	
	if (other.classname == "grenade")
	{	
		sound (self, CHAN_AUTO, "weapons/bounce2.wav", 1, ATTN_NORM);
		self.nextthink = time + 1;
		return;
	}
	
	if (other.classname == "mine")
	{	
		sound (self, CHAN_AUTO, "weapons/bounce2.wav", 1, ATTN_NORM);
		self.nextthink = time + 1;
		return;
	}
	
	if (other.classname == "minearm")
	{	
		sound (self, CHAN_AUTO, "weapons/bounce2.wav", 1, ATTN_NORM);
		self.nextthink = time + 1;
		return;
	}
	
	if (other.classname == "minearmed")
	{	
		sound (self, CHAN_AUTO, "weapons/bounce.wav", 1, ATTN_NORM);
		self.classname = "minearm";
		self.nextthink = time + 1;
		return;
	}
	
	if (other.classname == "player")
	{
		sound (self, CHAN_BODY, "weapons/minedet.wav", 1, ATTN_NORM);
		MineExplode();
		self.nextthink = time + 0.4;
		return;
	}
		
	if (other.takedamage == DAMAGE_AIM)
	{
		MineExplode();
		self.think();
		return;
	}
	
	self.movetype = MOVETYPE_NONE;
	self.classname = "minearm";
	self.spawnmaster = other;
	self.nextthink = time + 0.1;
};

/*
================
MineArm
================
*/
void() MineArm =
	{
	local entity   head;
	local float    detonate;
   
	if (self.classname == "minearm")
	{
		sound (self, CHAN_WEAPON, "weapons/armed.wav", 1, ATTN_NORM);
		setsize (self, '-3 -3 -3', '3 3 3');
		self.owner = world;
		self.takedamage = DAMAGE_YES;
		self.skin = 1;
		self.classname = "minearmed";
		muzzleflash(); //Will this work?
	}

	if ((time > self.delay) || (self.spawnmaster.no_obj == TRUE))
	{
	sound (self, CHAN_BODY, "weapons/minedet.wav", 1, ATTN_NORM);
		MineImExplode();
		//self.nextthink = time + 0.4;
		return;
	}
	
	// No click or delay when velocity triggers mine (so they don't float when doors open)
	// Although the 'organic' explosion' part in the detonate code might leave it hanging...
	if (vlen(self.spawnmaster.velocity) > 0)
	{
		MineImExplode();
		return;
	}
	
	// Mines explode on touch, but for some reason most monsters don't detonate them (?)
	// So had to use a findradius function to look for monsters, it's a small radius though
	// Ogres still don't always detonate mines (?)
	head = findradius(self.origin, 39);
	detonate = 0;
   
	if (self.health < 0)
		detonate = 1;
   
	while (head)
	{
		if ((head != self) && (head.health > 0) && ((head.flags & (FL_CLIENT|FL_MONSTER)) || (head.classname == "bot")) && (head.classname!=self.classname))
			detonate = 1;

		traceline(self.origin,head.origin,TRUE,self);
		if (trace_fraction != 1.0)
			detonate = 0;
      
	if (detonate==1)
	{
		sound (self, CHAN_BODY, "weapons/minedet.wav", 1, ATTN_NORM);
		MineExplode();
		self.nextthink = time + 0.25;
		return;
	}
		head = head.chain;
	}
	
	self.nextthink = time + 0.1;
};
/*
================
W_FireMine
================
*/
void() W_FireMine =
{		
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	sound (self, CHAN_AUTO, "weapons/ssgrnde.wav", 1, ATTN_NORM);
  
	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -100;
  
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
    newmis.lastowner = self;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "mine";
	newmis.takedamage = DAMAGE_NO;
	newmis.health = 1;

	//POX v1.2 - mines don't bleed....
	newmis.nobleed = TRUE;

// set missile speed

	makevectors (self.v_angle);

	if (self.v_angle_x)
		newmis.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		newmis.velocity = aim(self, 10000);
		newmis.velocity = newmis.velocity * 600;
		newmis.velocity_z = 200;
	}

   newmis.avelocity = '100 600 100';

   newmis.angles = vectoangles(newmis.velocity);

   newmis.touch = MineTouch;

// set missile duration
   newmis.nextthink = time + 0.2;
   newmis.delay = time + 15;
   newmis.think = MineArm;
   newmis.th_die = MineExplode;

   setmodel (newmis, "progs/grenade.mdl");
   setorigin (newmis, self.origin + v_forward*4);
   setsize (newmis, '-1 -1 -1', '0 0 0');
 
};

// END MINE CODE														
//=============================================================================


//=============================================================================
//
// Shrapnel Bomb - Nailgun Second Trigger (1 rocket + 30 nails, remotely detonated)
//
//=============================================================================

//----------------------------------------------------------
//These functions launch a single spike in a random direction

void() spikenal_touch =
{	
	if (self.voided) {
		return;
	}
	self.voided = 1;
	
	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{	
		spawn_touchblood (12);
		other.deathtype = "shrapnel";
		T_Damage (other, self, self.owner, 12);
		remove(self);
	}
	
	else if (random() > 0.9)
	{
		WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
		WriteByte (MSG_MULTICAST, TE_SPIKE);
		WriteCoord (MSG_MULTICAST, self.origin_x);
		WriteCoord (MSG_MULTICAST, self.origin_y);
		WriteCoord (MSG_MULTICAST, self.origin_z);
		multicast (self.origin, MULTICAST_PHS);
		remove(self);
	}

};

//POX - Get a random vector for Shrapnel
vector() VelocityForShrapnel =
{
	local vector v;

	v_x = 200 * crandom();
	v_y = 200 * crandom();
	v_z = 200 * crandom();
	
	if (random() > 0.5)
		v_z = v_z - (v_z*2);
	
	v = v * 6;

	return v;
};

//POX - Shrapnel = fast, bouncy spikes with a short life
void(vector org) launch_shrapnel =
{
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self.owner;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	
	newmis.touch = spikenal_touch;
	newmis.classname = "spikenal";
	
	newmis.velocity = VelocityForShrapnel();
	newmis.avelocity_x = random()*800;
	newmis.avelocity_y = random()*800;
	newmis.avelocity_z = random()*800;
	
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 3;
	
	setmodel (newmis, "progs/mwrub1.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);
	
};

//----------------------------------------------------------
//and now the bomb code...

void() ShrapnelExplode =
{	
	local float n;
	
	if (self.voided) {
		return;
	}
	self.voided = 1;

//POX - 1.0b1 - A LOT less Shrapnel!

	launch_shrapnel(self.origin);
	launch_shrapnel(self.origin);
	launch_shrapnel(self.origin);
	launch_shrapnel(self.origin);
	launch_shrapnel(self.origin);

	T_RadiusDamage (self, self.owner, 160, world, "shrapnel");
	
	if (self.owner != world)
		self.owner.shrap_detonate = FALSE;//Enable next launch
	
	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte (MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord (MSG_MULTICAST, self.origin_x);
	WriteCoord (MSG_MULTICAST, self.origin_y);
	WriteCoord (MSG_MULTICAST, self.origin_z);
	multicast (self.origin, MULTICAST_PHS);

	remove (self);
};

void() ShrapnelDetonate =
{
	sound (self, CHAN_BODY, "weapons/minedet.wav", 1, ATTN_NORM);	
	self.think = ShrapnelExplode;
	self.nextthink = time + 0.1;
};

//Wait for a detonation impulse or time up
void() ShrapnelThink =
{	
	if (self.shrap_time < time)
		ShrapnelDetonate();
	
	if (self.owner == world)
		return;
	
	//Owner died so change to world and wait for detonate
	if (self.owner.health <= 0)
	{
		self.owner.shrap_detonate = FALSE;//Enable next launch
		self.owner = world;
		self.nextthink = self.shrap_time;
		self.think = ShrapnelDetonate;
		return;
	}
	
	if (self.owner.shrap_detonate == 2)
		ShrapnelDetonate();
	else
		self.nextthink = time + 0.1;
};

void() ShrapnelTouch =
{
	local	float	r;
	
	r = random();
	
	if (other == self.owner)
		return;		// don't explode on owner
	
	if (other.takedamage == DAMAGE_AIM)
	{
		ShrapnelDetonate();
		return;
	}
	
	//pick a bounce sound
	if (r < 0.75)
		sound (self, CHAN_VOICE, "weapons/bounce.wav", 1, ATTN_NORM);
	else
		sound (self, CHAN_VOICE, "weapons/bounce2.wav", 1, ATTN_NORM);
		
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

// End shrapnel bomb
//=============================================================================


/*
================
W_FireShrapnel
================
*/
void() W_FireShrapnel =
{
	self.ammo_rockets = self.ammo_rockets - 1;
	self.currentammo = self.ammo_nails = self.ammo_nails - 30;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	
	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -115;

	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;

	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "shrapnel";
	
	newmis.shrap_time = time + 120;

// set newmis speed
	makevectors (self.v_angle);

	if (self.v_angle_x)
		newmis.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		newmis.velocity = aim(self, 10000);
		newmis.velocity = newmis.velocity * 600;
		newmis.velocity_z = 200;
	}

	newmis.avelocity = '300 300 300';

	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = ShrapnelTouch;
	
// set newmis duration
	newmis.nextthink = time + 0.1;
	newmis.think = ShrapnelThink;

	setmodel (newmis, "progs/grenade.mdl");
	newmis.skin = 2;
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, self.origin);
};

/*
============
W_SecondTrigger

Second Trigger Impulses

POX v1.1 - seperated this from weapons.qc - cleaned it up a bit
============
*/
void() W_SecondTrigger =
{
	//Don't fire during intermission
    if (intermission_running)
	return;
	
// check for NailGun's second Trigger
	if (self.weapon == IT_SUPER_NAILGUN)
	{ 
		if (!self.shrap_detonate) // Check if a bomb is already set
		{
			// check for nails and rockets
			if ((self.ammo_nails < 30) || (self.ammo_rockets < 1))
			{	
				sound (self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
				sprint (self, PRINT_HIGH, "Not enough ammo...\n");
			}
			else if (self.st_shrapnel < time)
			{
				self.weaponframe = 0;
				SuperDamageSound();
				self.st_shrapnel = time + 0.1; // Allow a fast detonate
				player_shrap1();
				W_FireShrapnel();
			
				self.shrap_detonate = TRUE;
			}
			else
				sound (self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
		}
		else
		{
			sound (self, CHAN_WEAPON, "weapons/shrapdet.wav", 1, ATTN_NORM);
			SuperDamageSound();
			self.st_shrapnel = time + 0.7; // Time out before next launch
			self.shrap_detonate = 2; //Tell the bomb to blow!
		}
	}


// check for t-shot prime
	if (self.weapon == IT_TSHOT)
	{
		//already primed
		if (self.prime_tshot == TRUE)
			SUB_Null;
		
		//not enough ammo
		else if (self.ammo_shells < 3)
		{
			SUB_Null;
		}
		else
		{	
			self.st_tshotload = time + 0.9; //give the reload a chance to happen
			
			//make a reload sound!
			sound (self, CHAN_WEAPON, "weapons/tsload.wav", 1, ATTN_NORM);
	
			player_reshot1(); //play prime animation
	
			self.prime_tshot = TRUE; //set the prime bit
		}
	}

// check for rhino reload
	if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		//already reloaded
		if (self.reload_rocket == 0)
			SUB_Null;
		
		//if no rockets go away
		else if (self.ammo_rockets < 1)
		{
			SUB_Null;
		}
		else
		{	
			self.st_rocketload = time + 0.6; //give the reload a chance to happen
			
			sound (self, CHAN_WEAPON, "weapons/rhinore.wav", 1, ATTN_NORM);
	
			player_rocketload1(); //play reload animation
	
			self.reload_rocket = 0; //reset reload bit
		}
	}
		

// check for Plasmagun second Trigger
	if (self.weapon == IT_PLASMAGUN)
	{ 
		// check for cells
		if (self.ammo_cells < 9)
		{
			sound (self, CHAN_AUTO, "weapons/mfire2.wav", 1, ATTN_NORM);
		}
		
		else
		
		if (self.st_mplasma < time)
		{
			if (self.waterlevel > 1) //explode under water
			{
				sound (self, CHAN_WEAPON, "weapons/mplasex.wav", 1, ATTN_NORM);
				self.ammo_cells = 0;
				W_SetCurrentAmmo ();
				T_RadiusDamage (self, self, 250, world, "waterplasma");
				return;
			}

			self.weaponframe = 0;
			SuperDamageSound();
			self.st_mplasma = time + 1.9;
			player_mplasma1();
			launch_megaplasma();
			
		}
		else
		 SUB_Null;
	}

// check for Super Shotgun second Trigger
	if (self.weapon == IT_COMBOGUN)
	{ 
	
		// check for rockets
		if (self.ammo_rockets < 1)
		{	
			self.items = self.items - ( self.items & (IT_SHELLS) );
			self.items = self.items | IT_ROCKETS;
			self.currentammo = self.ammo_rockets;
			self.which_ammo = 1;
			sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
		}
		
		else
		
		if (self.st_pball < time)
		{
			self.items = self.items - ( self.items & (IT_SHELLS) );
			self.items = self.items | IT_ROCKETS;
			self.currentammo = self.ammo_rockets;
			self.which_ammo = 1;
			player_gshot1();
			SuperDamageSound();
			W_FirePball();
			self.st_pball = time + 0.9;
		}
		else
		sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
	}
	
// check for GrenadeLauncher second Trigger
	if (self.weapon == IT_GRENADE_LAUNCHER)
	{	
		// check for rockets
		if (self.ammo_rockets < 1)
		{	
			sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
		}
		
		else
		if (self.st_mine < time)
		{	
			player_grenade1();
			W_FireMine();
			
			//big delay between refires helps keep the # of mines down in a deathmatch game
			self.st_mine = time + 1.25;

		}
		else
		sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
	}
	
	self.impulse = 0;
};
