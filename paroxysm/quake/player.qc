
void() bubble_bob;

/*
==============================================================================

PLAYER

==============================================================================
*/

//POX - Frame macros deleted (frames are now called by absolute values to simplify visible weapon animations)

//POX - added entity discrimination for bot support
void(float weap, entity me) getmodel =

{
	if(me.health <= 0)
		return;
	if (weap == IT_TSHOT)

		me.modelindex = modelindex_tshot_p;

	else if (weap == IT_COMBOGUN)

		me.modelindex = modelindex_combo_p;

	else if (weap == IT_PLASMAGUN)

		me.modelindex = modelindex_plasma_p;

	else if (weap == IT_SUPER_NAILGUN)

		me.modelindex = modelindex_nail_p;

	else if (weap == IT_GRENADE_LAUNCHER)

		me.modelindex = modelindex_gren_p;

	else if (weap == IT_ROCKET_LAUNCHER)

		me.modelindex = modelindex_rock_p;

	else
		me.modelindex = modelindex_saw_p;

};

/*
==============================================================================
PLAYER
==============================================================================
*/

void() player_run;

void()	player_stand1 =[	6,	player_stand1	]
{
	//self.weaponframe=0;
	if (self.velocity_x || self.velocity_y)
	{
		self.walkframe=0;
		player_run();
		return;
	}

	if (self.weapon == IT_BONESAW)

	{

		self.weaponframe = self.weaponframe + 1;

		if(self.weaponframe >= 3)

		{

			self.weaponframe = 0;

			if (self.view_ofs != '0 0 0')

				sound (self, CHAN_AUTO, "weapons/sawidle.wav", 1, ATTN_NORM);

		}
		
	}
	else
		self.weaponframe=0;

	if (self.walkframe >= 4)
		self.walkframe = 0;
		
	self.frame = 6 + self.walkframe;
		
	self.walkframe = self.walkframe + 1;	
};

void()	player_run =[0, player_run	]
{
	//self.weaponframe=0;
	if (!self.velocity_x && !self.velocity_y)
	{
		self.walkframe=0;
		player_stand1();
		return;
	}

	if (self.weapon == IT_BONESAW)

	{

		self.weaponframe = self.weaponframe + 1;

		if(self.weaponframe >= 3)

		{

			self.weaponframe = 0;

			if (self.view_ofs != '0 0 0')

				sound (self, CHAN_AUTO, "weapons/sawidle.wav", 1, ATTN_NORM);

		}

	}
	else
		self.weaponframe=0;
		
	if (self.walkframe == 6)
		self.walkframe = 0;
	self.frame = self.walkframe;

//POX v1.1 - changed to include water sounds for swimming and walking in shallow water
// strat footstep routine (modified from Hipnotic's QW source code)

      self.spawnsilent = self.spawnsilent + vlen(self.origin - self.old_velocity);
      self.old_velocity = self.origin;
      
      if (self.waterlevel < 3 && self.classname == "player") // no footsteps underwater, for observers
      {
				if (self.spawnsilent > 95)
				{
					local float r;
					
					if (self.spawnsilent > 190)
						self.spawnsilent = 0;
					else
						self.spawnsilent = 0.5*(self.spawnsilent - 95);
			
					r = random();
	    
					if (self.waterlevel)
			{
						if (r < 0.25)
							sound (self, CHAN_AUTO, "misc/water1.wav", 1, ATTN_NORM);
						else if (r < 0.5)
							sound (self, CHAN_AUTO, "misc/water2.wav", 1, ATTN_NORM);
						else if (r < 0.75)
							sound (self, CHAN_AUTO, "misc/owater2.wav", 0.75, ATTN_NORM);
				 }
				 else if (self.flags & FL_ONGROUND)
			{
						if (r < 0.25)
							sound (self, CHAN_AUTO, "misc/foot1.wav", 0.75, ATTN_NORM);
						else if (r < 0.5)
							sound (self, CHAN_AUTO, "misc/foot2.wav", 0.75, ATTN_NORM);
						else if (r < 0.75)
							sound (self, CHAN_AUTO, "misc/foot3.wav", 0.75, ATTN_NORM);
						else
							sound (self, CHAN_AUTO, "misc/foot4.wav", 0.75, ATTN_NORM);
				}
				}
		}
	
	self.walkframe = self.walkframe + 1;
};

/*
//used for PulseGun fire
void()	player_pulse1 = [$shotatt1, player_pulse2	] {self.weaponframe=1;
self.effects = self.effects | EF_MUZZLEFLASH;};
void()	player_pulse2 = [$shotatt2, player_pulse3	] {self.weaponframe=2;};
void()	player_pulse3 = [$shotatt3, player_pulse4	] {self.weaponframe=3;};
void()	player_pulse4 = [$shotatt4, player_pulse5	] {self.weaponframe=4;};
void()	player_pulse5 = [$shotatt5, player_run	] {self.weaponframe=5;};

//used for PulseGun 'flex'
//not called if deathmatch since player will slide
void()	player_pflex1 = [$shotatt1, player_pflex2	] {self.weaponframe=6;};
void()	player_pflex2 = [$shotatt2, player_pflex3	] {self.weaponframe=7;};
void()	player_pflex3 = [$shotatt3, player_pflex4	] {self.weaponframe=8;};
void()	player_pflex4 = [$shotatt4, player_pflex5	] {self.weaponframe=9;};
void()	player_pflex5 = [$shotatt5, player_pflex6	] {self.weaponframe=10;};
void()	player_pflex6 = [$shotatt5, player_run	] {self.weaponframe=11;};
*/

//used for t-sht and combo gun
void()	player_shot1 =	[15, player_shot2	] {self.weaponframe=1;
self.effects = self.effects | EF_MUZZLEFLASH;};
void()	player_shot2 =	[16, player_shot3	] {self.weaponframe=2;};
void()	player_shot3 =	[17, player_shot4	] {self.weaponframe=3;};
void()	player_shot4 =	[18, player_shot5	] {self.weaponframe=4;};
void()	player_shot5 =	[18, player_shot6	] {self.weaponframe=5;};
void()	player_shot6 =	[19, player_run ] {self.weaponframe=6;};
	
// New Frame Macro For T-Shot 3 barrel fire
void()	player_tshot1 = [15, player_tshot2	] {self.weaponframe=1;
self.effects = self.effects | EF_MUZZLEFLASH;};
void()	player_tshot2 = [16, player_tshot3	] {self.weaponframe=16;};//triple flare frame
void()	player_tshot3 = [17, player_tshot4	] {self.weaponframe=3;};
void()	player_tshot4 = [18, player_tshot5	] {self.weaponframe=4;};
void()	player_tshot5 = [18, player_tshot6	] {self.weaponframe=5;};
void()	player_tshot6 = [19, player_run ] {self.weaponframe=6;};
// End 3 barrel fire Macro

// New Frame Macro For T-Shot pump
// DM player may slide a little too much during this animation (?)
void()	player_reshot1 =	[15, player_reshot2	] {self.weaponframe=7;};
void()	player_reshot2 =	[17, player_reshot3	] {self.weaponframe=8;};
void()	player_reshot3 =	[18, player_reshot4	] {self.weaponframe=9;};
void()	player_reshot4 =	[19, player_reshot5	] {self.weaponframe=10;};
void()	player_reshot5 =	[19, player_reshot6	] {self.weaponframe=11;};
void()	player_reshot6 =	[18, player_reshot7	] {self.weaponframe=12;};
void()	player_reshot7 =	[17, player_reshot8	] {self.weaponframe=13;};
void()	player_reshot8 =	[17, player_reshot9	] {self.weaponframe=14;};
void()	player_reshot9 =	[15, player_run ] {self.weaponframe=15;};
// End T-shot prime Macro

// New Frame Macro For SuperShotgun Second Trigger (Impact Grenades)
void()	player_gshot1 = [15, player_gshot2	] {self.weaponframe=2;
self.effects = self.effects | EF_MUZZLEFLASH;};
void()	player_gshot2 = [16, player_gshot3	] {self.weaponframe=3;};
void()	player_gshot3 = [17, player_gshot4	] {self.weaponframe=4;};
void()	player_gshot4 = [18, player_gshot5	] {self.weaponframe=5;};
void()	player_gshot5 = [19, player_run ] {self.weaponframe=6;};
// End SuperShotgun Second Trigger Macro

// New Frame Macro For Nailgun Second Trigger (Shrapnel Bomb)
void()	player_shrap1 = [15, player_shrap2	] {
self.effects = self.effects | EF_MUZZLEFLASH;};
void()	player_shrap2 = [16, player_run ] {};
// End Nailgun Second Trigger Macro

//POX - this plays the saw off animation
void()	player_sawoff1 = [15, player_sawoff2] {self.weaponframe=5;sound (self, CHAN_WEAPON, "weapons/sawoff.wav", 1, ATTN_NORM);};
void()	player_sawoff2 = [16, player_sawoff3] {self.weaponframe=4;};
void()	player_sawoff3 = [15, player_run] {self.weaponframe=3;};

//POX - this sets up the start animation
void() player_bonesaw1 = [15, player_bonesaw2]
{
	self.weaponframe = 4;
	
	sound (self, CHAN_WEAPON, "weapons/sawon.wav", 1, ATTN_NORM);
	
	self.saw_on = TRUE;
	
	if (!self.button0)
		{player_sawoff1();self.saw_on = FALSE;return;}

};

void() player_bonesaw3; //predeclare

//POX - this cycles the startup animation
void() player_bonesaw2 = [16, player_bonesaw3]
{

	if (!self.button0)
		{player_sawoff1();self.saw_on = FALSE;return;}
	
	self.weaponframe = 5;
		
	W_FireSaw();
	SuperDamageSound();

};

//POX - these two play the firing animation
void() player_bonesaw3 = [15, player_bonesaw4]
{

	if (!self.button0)
		{player_sawoff1();self.saw_on = FALSE;return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 12)
		self.weaponframe = 6;

};

void() player_bonesaw4 = [16, player_bonesaw3]
{

	sound (self, CHAN_WEAPON, "weapons/sawatck.wav", 1, ATTN_NORM);
	
	if (!self.button0)
		{player_sawoff1();self.saw_on = FALSE;return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 12)
		self.weaponframe = 6;
	
	W_FireSaw();
	SuperDamageSound();

};

//============================================================================

/* Bye-bye Quake Axe
void()	player_axe1 =	[$axatt1, player_axe2	] {self.weaponframe=1;};
void()	player_axe2 =	[$axatt2, player_axe3	] {self.weaponframe=2;};
void()	player_axe3 =	[$axatt3, player_axe4	] {self.weaponframe=3;W_FireAxe();};
void()	player_axe4 =	[$axatt4, player_run	] {self.weaponframe=4;};

void()	player_axeb1 =	[$axattb1, player_axeb2 ] {self.weaponframe=5;};
void()	player_axeb2 =	[$axattb2, player_axeb3 ] {self.weaponframe=6;};
void()	player_axeb3 =	[$axattb3, player_axeb4 ] {self.weaponframe=7;W_FireAxe();};
void()	player_axeb4 =	[$axattb4, player_run	] {self.weaponframe=8;};

void()	player_axec1 =	[$axattc1, player_axec2 ] {self.weaponframe=1;};
void()	player_axec2 =	[$axattc2, player_axec3 ] {self.weaponframe=2;};
void()	player_axec3 =	[$axattc3, player_axec4 ] {self.weaponframe=3;W_FireAxe();};
void()	player_axec4 =	[$axattc4, player_run	] {self.weaponframe=4;};

void()	player_axed1 =	[$axattd1, player_axed2 ] {self.weaponframe=5;};
void()	player_axed2 =	[$axattd2, player_axed3 ] {self.weaponframe=6;};
void()	player_axed3 =	[$axattd3, player_axed4 ] {self.weaponframe=7;W_FireAxe();};
void()	player_axed4 =	[$axattd4, player_run	] {self.weaponframe=8;};
*/
//============================================================================

//POX - 102b - A really stupid overlook caused the nailgun and plasmagun to ignore attack_finshed (st_nailgun and st_plasma)
//This has now been fixed, and will hopefully prevent packet errors

void() player_nail1   =[15, player_nail2  ] 
{	
	if (self.st_nailgun > time)
		return;
	
	if (self.ammo_nails < 1)
		{
			sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
			self.st_nailgun = time + 0.4;
			player_run ();return;
		}
	else
	{
		self.effects = self.effects | EF_MUZZLEFLASH;

		if (!self.button0)
			{player_run ();return;}
		self.weaponframe = self.weaponframe + 1;
		if (self.weaponframe == 9)
			self.weaponframe = 1;
		SuperDamageSound();
		W_FireNails (3);
		
		if (self.flags & FL_ONGROUND)
			self.velocity = self.velocity + v_forward*-20;
		
		self.st_nailgun = time + 0.1;
	}
};
void() player_nail2   =[16, player_nail1  ]
{
	if (self.st_nailgun > time)
		return;
	
	if (self.ammo_nails < 1)
		{	
			sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
			self.st_nailgun = time + 0.4;
			player_run ();return;
		}
	else
	{
	
		self.effects = self.effects | EF_MUZZLEFLASH;

		if (!self.button0)
			{player_run ();return;}
		self.weaponframe = self.weaponframe + 1;
		if (self.weaponframe == 9)
			self.weaponframe = 1;
		SuperDamageSound();
		W_FireNails (-3);
		
		if (self.flags & FL_ONGROUND)
			self.velocity = self.velocity + v_forward*-20;
		
		self.st_nailgun = time + 0.1;
		
	}
};

//============================================================================
//============================================================================

void() player_plasma1	=[15, player_plasma2  ]
{	
	if (self.st_plasma > time)
		return;
		
	if (self.ammo_cells < 1)
	{	
		sound (self, CHAN_WEAPON, "weapons/mfire2.wav", 1, ATTN_NORM);
		player_run ();
		self.st_plasma = time + 0.4;
		return;
	}
	else
	{
		self.effects = self.effects | EF_MUZZLEFLASH;
		
		if (!self.button0)
			{player_run ();return;}
		
		self.weaponframe = 1;
		self.LorR = 1;
		
		SuperDamageSound();
		W_FirePlasma (6);
		
		
		if (self.flags & FL_ONGROUND)
			self.velocity = self.velocity + v_forward*-20;
		
		
		self.st_plasma = time + 0.1;
	}

};

void() player_plasma2	=[16, player_plasma1  ]
{	
	if (self.st_plasma > time)
		return;
		
	if (self.ammo_cells < 1)
	{	
		sound (self, CHAN_WEAPON, "weapons/mfire2.wav", 1, ATTN_NORM);
		player_run ();
		self.st_plasma = time + 0.4;
		return;
	}
	
	else
	{
		
		self.effects = self.effects | EF_MUZZLEFLASH;
		
		if (!self.button0)
			{player_run ();return;}
		
		self.weaponframe = 2;
		self.LorR = 0;
		
		SuperDamageSound();
		W_FirePlasma (-7);
		
		
		if (self.flags & FL_ONGROUND)
			self.velocity = self.velocity + v_forward*-20;
			
		
		self.st_plasma = time + 0.1;
	}

};

//Had to seperate Grenade Macro from Anihilator
//to make room for new rhino animations
void() player_grenade1	 =[15, player_grenade2	] {self.weaponframe=1;
self.effects = self.effects | EF_MUZZLEFLASH;};
void() player_grenade2	 =[16, player_grenade3	] {self.weaponframe=2;};
void() player_grenade3	 =[17, player_grenade4	] {self.weaponframe=3;};
void() player_grenade4	 =[18, player_grenade5	] {self.weaponframe=4;};
void() player_grenade5	 =[18, player_grenade6	] {self.weaponframe=5;};
void() player_grenade6	 =[19, player_run  ] {self.weaponframe=6;};


//MegaPlasma Burst
void() player_mplasma1	 =[15, player_mplasma2	] {self.weaponframe=0;};
void() player_mplasma2	 =[16, player_run  ] {};

// rhino fire sequence
void() player_rocket1	=[14, player_rocket2  ] {self.weaponframe=1;
W_FireRocket('0 0 16');
//sound is timed for double shot (two single shot sounds had inconsistant results)
sound (self, CHAN_WEAPON, "weapons/rhino.wav", 1, ATTN_NORM);
	
	if (self.flags & FL_ONGROUND)
		self.velocity = v_forward* -25;

self.punchangle_x = -3;
self.effects = self.effects | EF_MUZZLEFLASH;};
void() player_rocket2	=[15, player_rocket3  ] {self.weaponframe=2;
W_FireRocket('0 0 24');};
void() player_rocket3	=[16, player_run  ] {self.weaponframe=3;};

//rhino Reload sequence
void() player_rocketload1   =[6, player_rocketload2  ] {self.weaponframe=4;};
void() player_rocketload2   =[17, player_rocketload3  ] {self.weaponframe=5;};
void() player_rocketload3   =[18, player_rocketload4  ] {self.weaponframe=6;};
void() player_rocketload4   =[18, player_rocketload5  ] {self.weaponframe=7;};
void() player_rocketload5   =[19, player_rocketload6  ] {self.weaponframe=8;};
void() player_rocketload6   =[17, player_run  ] {self.weaponframe=9;};


void(float num_bubbles) DeathBubbles;

void() PainSound =
{
local float		rs;

	if (self.health < 0)
		return;

	if (damage_attacker.classname == "teledeath")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

// water pain sounds
	if (self.watertype == CONTENT_WATER && self.waterlevel == 3)
	{
		DeathBubbles(1);
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM);
		return;
	}

// slime pain sounds
	if (self.watertype == CONTENT_SLIME)
	{
// FIX ME	put in some steam here
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}
	
	/*
	if (self.pain_finished > time)
	{
		self.axhitme = 0;
		return;
	}
	self.pain_finished = time + 0.5;

// don't make multiple pain sounds right after each other

// ax pain sound
	if (self.axhitme == 1)
	{
		self.axhitme = 0;
		sound (self, CHAN_VOICE, "player/axhit1.wav", 1, ATTN_NORM);
		return;
	}
	*/

	rs = rint((random() * 5) + 1);

	self.noise = "";
	if (rs == 1)
		self.noise = "player/pain1.wav";
	else if (rs == 2)
		self.noise = "player/pain2.wav";
	else if (rs == 3)
		self.noise = "player/pain3.wav";
	else if (rs == 4)
		self.noise = "player/pain4.wav";
	else if (rs == 5)
		self.noise = "player/pain5.wav";
	else
		self.noise = "player/pain6.wav";

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	return;
};

void()	player_pain1 =	[10,	player_pain2	] {PainSound();self.weaponframe=0;};
void()	player_pain2 =	[11,	player_pain3	] {};
void()	player_pain3 =	[12,	player_pain4	] {};
void()	player_pain4 =	[13,	player_pain5	] {};
void()	player_pain5 =	[14,	player_run	] {};


void()	player_painb1 = [10,	player_painb2	] {PainSound();self.weaponframe=0;};
void()	player_painb2 = [11,	player_painb3	] {};
void()	player_painb3 = [12,	player_painb4	] {};
void()	player_painb4 = [14,	player_run	] {};


/*
void()	player_axpain1 =	[	$axpain1,	player_axpain2	] {PainSound();self.weaponframe=0;};
void()	player_axpain2 =	[	$axpain2,	player_axpain3	] {};
void()	player_axpain3 =	[	$axpain3,	player_axpain4	] {};
void()	player_axpain4 =	[	$axpain4,	player_axpain5	] {};
void()	player_axpain5 =	[	$axpain5,	player_axpain6	] {};
void()	player_axpain6 =	[	$axpain6,	player_run	] {};
*/

void(entity attacker, float damage) player_pain =
{
	if (self.weaponframe)
		return;

	//if (self.invisible_finished > time)
	//	return;		// eyes don't have pain frames

	/*
	if (self.weapon == IT_BONESAW)
		player_axpain1 ();
	else
	*/
	
	if (self.weapon == IT_ROCKET_LAUNCHER)
		player_painb1 ();
	else
		player_pain1 ();
};

void() player_diea1;
void() player_dieb1;
void() player_diec1;
void() player_died1;
void() player_diee1;
//void() player_die_ax1;

void() DeathBubblesSpawn =
{
local entity	bubble;
	if (self.owner.waterlevel != 3)
		return;
	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.owner.origin + '0 0 24');
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.classname = "bubble";
	bubble.frame = 0;
	bubble.cnt = 0;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.nextthink = time + 0.1;
	self.think = DeathBubblesSpawn;
	self.air_finished = self.air_finished + 1;
	if (self.air_finished >= self.bubble_count)
		remove(self);
};

void(float num_bubbles) DeathBubbles =
{
local entity	bubble_spawner;
	
	bubble_spawner = spawn();
	setorigin (bubble_spawner, self.origin);
	bubble_spawner.movetype = MOVETYPE_NONE;
	bubble_spawner.solid = SOLID_NOT;
	bubble_spawner.nextthink = time + 0.1;
	bubble_spawner.think = DeathBubblesSpawn;
	bubble_spawner.air_finished = 0;
	bubble_spawner.owner = self;
	bubble_spawner.bubble_count = num_bubbles;
	return;
};


void() DeathSound =
{
local float		rs;

	// water death sounds
	if (self.waterlevel == 3)
	{
		DeathBubbles(20);
		sound (self, CHAN_VOICE, "player/h2odeath.wav", 1, ATTN_NONE);
		return;
	}
	
	rs = rint ((random() * 4) + 1);
	if (rs == 1)
		self.noise = "player/death1.wav";
	if (rs == 2)
		self.noise = "player/death2.wav";
	if (rs == 3)
		self.noise = "player/death3.wav";
	if (rs == 4)
		self.noise = "player/death4.wav";
	if (rs == 5)
		self.noise = "player/death5.wav";

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
	return;
};


void() PlayerDead =
{
	self.nextthink = -1;
// allow respawn after a certain time
	self.deadflag = DEAD_DEAD;
};

vector(float dm) VelocityForDamage =
{
	local vector v;

	v_x = 100 * crandom();
	v_y = 100 * crandom();
	v_z = 200 + 100 * random();

	if (dm > -50)
	{
//		dprint ("level 1\n");
		v = v * 0.7;
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

void(string gibname, float dm) ThrowGib =
{
	local	entity new;

	new = spawn();
	new.origin = self.origin;
	setmodel (new, gibname);
	setsize (new, '0 0 0', '0 0 0');
	new.velocity = VelocityForDamage (dm);
	new.movetype = MOVETYPE_BOUNCE;
	new.solid = SOLID_NOT;
	new.avelocity_x = random()*600;
	new.avelocity_y = random()*600;
	new.avelocity_z = random()*600;
	new.think = SUB_Remove;
	new.ltime = time;
	new.nextthink = time + 10 + random()*10;
	new.frame = 0;
	new.flags = 0;
};

void(string gibname, float dm) ThrowHead =
{
	setmodel (self, gibname);
	self.frame = 0;
	self.nextthink = -1;
	self.movetype = MOVETYPE_BOUNCE;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.view_ofs = '0 0 8';
	setsize (self, '-16 -16 0', '16 16 56');
	self.velocity = VelocityForDamage (dm);
	self.origin_z = self.origin_z - 24;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = crandom() * '0 600 0';
};

void(float weap) ThrowWeapon =

{

	local	entity new;


	new = spawn();

	new.origin = self.origin;

	if (weap == IT_TSHOT) setmodel (new, "progs/d_tshot.mdl");

	else if (weap == IT_COMBOGUN) setmodel (new, "progs/d_combo.mdl");

	else if (weap == IT_PLASMAGUN) setmodel (new, "progs/d_plasma.mdl");

	else if (weap == IT_SUPER_NAILGUN) setmodel (new, "progs/d_nail.mdl");

	else if (weap == IT_GRENADE_LAUNCHER) setmodel (new, "progs/d_gren.mdl");

	else if (weap == IT_ROCKET_LAUNCHER) setmodel (new, "progs/d_rhino.mdl");

	else  setmodel (new, "progs/d_bsaw.mdl");
	
	//TEMPORARY PATCH!!!
	//else
	//{
	//	remove(new);
	//	return;
	//}
	

	setsize (new, '0 0 0', '0 0 0');

	new.velocity_x = 150 * crandom();

	new.velocity_y = 150 * crandom();

	new.velocity_z = 100 + 200 * random();



	new.movetype = MOVETYPE_BOUNCE;

	new.solid = SOLID_NOT;

	new.avelocity_y = random()*600;

	new.angles_y = 50 * crandom();

	new.angles_y = anglemod(self.angles_y + new.angles_y);

	new.frame = 0;

	new.flags = 0;

	CopyToBodyQue(new);

	remove(new);

};

void() GibPlayer =
{
	//POX - make a nice gib in Gib mode
	if (deathmatch & DM_GIB)
		self.health = self.health - 40;

	ThrowHead ("progs/h_player.mdl", self.health);
	ThrowGib ("progs/gib1.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);

	self.deadflag = DEAD_DEAD;

	if (damage_attacker.classname == "teledeath")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

	if (damage_attacker.classname == "teledeath2")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}
		
	if (random() < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);
};

void() PlayerDie =
{
	local	float	i;
	
	//self.items = self.items - (self.items & IT_INVISIBILITY);
	self.invisible_finished = 0;	// don't die as eyes
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	//self.modelindex = modelindex_player;	// don't use eyes
	
	self.modelindex = modelindex_death;
	self.frame = 44;
	
	//self.skin = 0;
	
	//POX v1.11 - clear the target print so it doesn't obscure the scoreboard
	if (self.target_id_toggle)
		centerprint (self, "");
	
	ThrowWeapon(self.weapon);
	
	self.weaponmodel="";
	self.view_ofs = '0 0 -8';
	self.deadflag = DEAD_DYING;
	self.solid = SOLID_NOT;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.movetype = MOVETYPE_TOSS;
	if (self.velocity_z < 10)
		self.velocity_z = self.velocity_z + random()*300;
	
//POX check for gib mode as well as regular gib
	if (self.health < -40 || (deathmatch & DM_GIB))
	{	
		GibPlayer ();
		return;
	}

	if (deathmatch || coop)
		DropBackpack();

	DeathSound();
	
	self.angles_x = 0;
	self.angles_z = 0;
	
	/*
	if (self.weapon == IT_AXE)
	{
		player_die_ax1 ();
		return;
	}
	*/
	
	i = 1 + floor(random()*6);
	
	if (i == 1)
		player_diea1();
	else if (i == 2)
		player_dieb1();
	else if (i == 3)
		player_diec1();
	else if (i == 4)
		player_died1();
	else
		player_diee1();

};

void() set_suicide_frame =
{	// used by klill command and diconnect command
	if (self.model == "progs/h_player.mdl")
		return; // allready gibbed
	
//POX - 1.01b - to simplify things, and to correct some errors brought on by the Visible Weapon patch,
//just gib suicides and dissconnects
	GibPlayer();
	
	/*
	self.modelindex = modelindex_death;
	self.frame = 43;
	
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_TOSS;
	self.deadflag = DEAD_DEAD;
	self.nextthink = -1;
	*/
};


// VisWeap MOD: replaced all frame refs with numbers in all death scenes. 
void()	player_diea1	=	[	33,	player_diea2	] {};
void()	player_diea2	=	[	34,	player_diea3	] {};
void()	player_diea3	=	[	35,	player_diea4	] {};
void()	player_diea4	=	[	36,	player_diea5	] {};
void()	player_diea5	=	[	37,	player_diea6	] {};
void()	player_diea6	=	[	38,	player_diea7	] {};
void()	player_diea7	=	[	39,	player_diea8	] {};
void()	player_diea8	=	[	40,	player_diea9	] {};
void()	player_diea9	=	[	41,	player_diea10	] {};
void()	player_diea10	=	[	42,	player_diea11	] {};
void()	player_diea11	=	[	43,	player_diea11 ] {PlayerDead();};

void()	player_dieb1	=	[	44,	player_dieb2	] {};
void()	player_dieb2	=	[	45,	player_dieb3	] {};
void()	player_dieb3	=	[	46,	player_dieb4	] {};
void()	player_dieb4	=	[	47,	player_dieb5	] {};
void()	player_dieb5	=	[	48,	player_dieb6	] {};
void()	player_dieb6	=	[	49,	player_dieb7	] {};
void()	player_dieb7	=	[	50,	player_dieb8	] {};
void()	player_dieb8	=	[	51,	player_dieb9	] {};
void()	player_dieb9	=	[	52,	player_dieb9	] {PlayerDead();};

void()	player_diec1	=	[	53,	player_diec2	] {};
void()	player_diec2	=	[	54,	player_diec3	] {};
void()	player_diec3	=	[	55,	player_diec4	] {};
void()	player_diec4	=	[	56,	player_diec5	] {};
void()	player_diec5	=	[	57,	player_diec6	] {};
void()	player_diec6	=	[	58,	player_diec7	] {};
void()	player_diec7	=	[	59,	player_diec8	] {};
void()	player_diec8	=	[	60,	player_diec9	] {};
void()	player_diec9	=	[	61,	player_diec10	] {};
void()	player_diec10	=	[	62,	player_diec11	] {};
void()	player_diec11	=	[	63,	player_diec12	] {};
void()	player_diec12	=	[	64,	player_diec13	] {};
void()	player_diec13	=	[	65,	player_diec14	] {};
void()	player_diec14	=	[	66,	player_diec15	] {};
void()	player_diec15	=	[	67,	player_diec15 ] {PlayerDead();};

void()	player_died1	=	[	68,	player_died2	] {};
void()	player_died2	=	[	69,	player_died3	] {};
void()	player_died3	=	[	70,	player_died4	] {};
void()	player_died4	=	[	71,	player_died5	] {};
void()	player_died5	=	[	72,	player_died6	] {};
void()	player_died6	=	[	73,	player_died7	] {};
void()	player_died7	=	[	74,	player_died8	] {};
void()	player_died8	=	[	75,	player_died9	] {};
void()	player_died9	=	[	76,	player_died9	] {PlayerDead();};

void()	player_diee1	=	[	77,	player_diee2	] {};
void()	player_diee2	=	[	78,	player_diee3	] {};
void()	player_diee3	=	[	79,	player_diee4	] {};
void()	player_diee4	=	[	80,	player_diee5	] {};
void()	player_diee5	=	[	81,	player_diee6	] {};
void()	player_diee6	=	[	82,	player_diee7	] {};
void()	player_diee7	=	[	83,	player_diee8	] {};
void()	player_diee8	=	[	84,	player_diee9	] {};
void()	player_diee9	=	[	85,	player_diee9	] {PlayerDead();};

/*
void()	player_die_ax1	=	[	$axdeth1,	player_die_ax2	] {};
void()	player_die_ax2	=	[	$axdeth2,	player_die_ax3	] {};
void()	player_die_ax3	=	[	$axdeth3,	player_die_ax4	] {};
void()	player_die_ax4	=	[	$axdeth4,	player_die_ax5	] {};
void()	player_die_ax5	=	[	$axdeth5,	player_die_ax6	] {};
void()	player_die_ax6	=	[	$axdeth6,	player_die_ax7	] {};
void()	player_die_ax7	=	[	$axdeth7,	player_die_ax8	] {};
void()	player_die_ax8	=	[	$axdeth8,	player_die_ax9	] {};
void()	player_die_ax9	=	[	$axdeth9,	player_die_ax9	] {PlayerDead();};
*/
