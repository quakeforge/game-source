
#include "config.rh"
#include "paroxysm.rh"

void() bubble_bob;
/*
==============================================================================
PLAYER
==============================================================================
*/
$cd /raid/quake/id1/models/player_4
$origin 0 -6 24
$base base		
$skin skin

//
// running
//
$frame axrun1 axrun2 axrun3 axrun4 axrun5 axrun6
$frame rockrun1 rockrun2 rockrun3 rockrun4 rockrun5 rockrun6

//
// standing
//
$frame stand1 stand2 stand3 stand4 stand5

$frame axstnd1 axstnd2 axstnd3 axstnd4 axstnd5 axstnd6
$frame axstnd7 axstnd8 axstnd9 axstnd10 axstnd11 axstnd12

//
// pain
//
$frame axpain1 axpain2 axpain3 axpain4 axpain5 axpain6
$frame pain1 pain2 pain3 pain4 pain5 pain6

//
// death
//
$frame axdeth1 axdeth2 axdeth3 axdeth4 axdeth5 axdeth6
$frame axdeth7 axdeth8 axdeth9

$frame deatha1 deatha2 deatha3 deatha4 deatha5 deatha6 deatha7 deatha8
$frame deatha9 deatha10 deatha11

$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9

$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11 deathc12 deathc13 deathc14 deathc15

$frame deathd1 deathd2 deathd3 deathd4 deathd5 deathd6 deathd7
$frame deathd8 deathd9

$frame deathe1 deathe2 deathe3 deathe4 deathe5 deathe6 deathe7
$frame deathe8 deathe9

//
// attacks
//
$frame nailatt1 nailatt2

$frame light1 light2

$frame rockatt1 rockatt2 rockatt3 rockatt4 rockatt5 rockatt6

$frame shotatt1 shotatt2 shotatt3 shotatt4 shotatt5 shotatt6

$frame axatt1 axatt2 axatt3 axatt4 axatt5 axatt6
$frame axattb1 axattb2 axattb3 axattb4 axattb5 axattb6
$frame axattc1 axattc2 axattc3 axattc4 axattc5 axattc6
$frame axattd1 axattd2 axattd3 axattd4 axattd5 axattd6

/*
==============================================================================
PLAYER
==============================================================================
*/
void() player_run;
void() player_stand1 = [$axstnd1, player_stand1]
{
	self.weaponframe = 0;
	if (self.velocity_x || self.velocity_y) {
		self.walkframe = 0;
		player_run ();
		return;
	}

	if (self.weapon == IT_AXE) {
		if (self.walkframe >= 12)
			self.walkframe = 0;
		self.frame = $axstnd1 + self.walkframe;
	} else {
		if (self.walkframe >= 5)
			self.walkframe = 0;
		self.frame = $stand1 + self.walkframe;
	}
	self.walkframe++;
};

void() player_run = [$rockrun1, player_run]
{
	self.weaponframe = 0;
	if (!self.velocity_x && !self.velocity_y) {
		self.walkframe = 0;
		player_stand1 ();
		return;
	}

	if (self.weapon == IT_AXE) {
		if (self.walkframe == 6)
			self.walkframe = 0;
		self.frame = $axrun1 + self.walkframe;
	} else {
		if (self.walkframe == 6)
			self.walkframe = 0;
		self.frame = self.frame + self.walkframe;
	}

	// footstep sounds	
	self.spawnsilent += vlen (self.origin - self.old_velocity);
	self.old_velocity = self.origin;
      
	if (self.waterlevel < 3 && self.classname == "player") { // no footsteps underwater or for observer
		if (self.spawnsilent > 95) {
			local float	r;

			if (self.spawnsilent > 190)
				self.spawnsilent = 0;
			else
				self.spawnsilent = 0.5 * (self.spawnsilent - 95);

			r = random ();

			if (self.waterlevel) {
				if (r < 0.25)
					sound (self, CHAN_AUTO, "misc/water1.wav", 1, ATTN_NORM);
				else if (r < 0.5)
					sound (self, CHAN_AUTO, "misc/water2.wav", 1, ATTN_NORM);
				else if (r < 0.75)
					sound (self, CHAN_AUTO, "misc/owater2.wav", 0.75, ATTN_NORM);
			} else if (self.flags & FL_ONGROUND) {
				local float speed, vol;

				speed = vlen (self.velocity);
				vol = speed * 0.002; // Scale footstep volume by speed
				if (vol > 1)
					vol = 1;
				if (vol < 0.1)
					return;	// don't make a sound

				if (r < 0.25)
					sound (self, CHAN_AUTO, "misc/foot1.wav", vol, ATTN_NORM);
				else if (r < 0.5)
					sound (self, CHAN_AUTO, "misc/foot2.wav", vol, ATTN_NORM);
				else if (r < 0.75)
					sound (self, CHAN_AUTO, "misc/foot3.wav", vol, ATTN_NORM);
				else
					sound (self, CHAN_AUTO, "misc/foot4.wav", vol, ATTN_NORM);
			}
		}
	}

	self.walkframe++;
};

void () muzzleflash =
{
	WriteByte (MSG_MULTICAST, SVC_MUZZLEFLASH);
	WriteEntity (MSG_MULTICAST, self);
	multicast (self.origin, MULTICAST_PVS);
};

// POX - used for tShot and ComboGun primary triggers
void() player_shot1 = [$shotatt1, player_shot2]
{
	self.weaponframe = 1;
	muzzleflash ();
};

void() player_shot2 = [$shotatt2, player_shot3] {self.weaponframe = 2;};
void() player_shot3 = [$shotatt3, player_shot4] {self.weaponframe = 3;};
void() player_shot4 = [$shotatt4, player_shot5] {self.weaponframe = 4;};
void() player_shot5 = [$shotatt5, player_shot6] {self.weaponframe = 5;};
void() player_shot6 = [$shotatt6, player_run]	{self.weaponframe = 6;};

// POX - New Frame Macro For tShot 3 barrel fire
void() player_tshot1 = [$shotatt1, player_tshot2]	{self.weaponframe = 1; muzzleflash();};
void() player_tshot2 = [$shotatt2, player_tshot3]	{self.weaponframe = 16;}; // triple flare frame
void() player_tshot3 = [$shotatt3, player_tshot4]	{self.weaponframe = 3;};
void() player_tshot4 = [$shotatt4, player_tshot5]	{self.weaponframe = 4;};
void() player_tshot5 = [$shotatt5, player_tshot6]	{self.weaponframe = 5;};
void() player_tshot6 = [$shotatt6, player_run]		{self.weaponframe = 6;};

// POX - New Frame Macro For tShot 3 barrel prime
void() player_reshot1 =	[$shotatt1, player_reshot2]	{self.weaponframe = 7;};
void() player_reshot2 =	[$shotatt3, player_reshot3] {self.weaponframe = 8;};
void() player_reshot3 =	[$shotatt4, player_reshot4] {self.weaponframe = 9;};
void() player_reshot4 =	[$shotatt5, player_reshot5] {self.weaponframe = 10;};
void() player_reshot5 =	[$shotatt6, player_reshot6] {self.weaponframe = 11;};
void() player_reshot6 =	[$shotatt5, player_reshot7] {self.weaponframe = 12;};
void() player_reshot7 =	[$shotatt4, player_reshot8] {self.weaponframe = 13;};
void() player_reshot8 =	[$shotatt3, player_reshot9] {self.weaponframe = 14;};
void() player_reshot9 =	[$shotatt1, player_run]		{self.weaponframe = 15;};

// POX - New Frame Macro For ComboGun Second Trigger (Impact Grenades)
void() player_gshot1 = [$shotatt1, player_gshot2]	{self.weaponframe = 2; muzzleflash();};
void() player_gshot2 = [$shotatt2, player_gshot3]	{self.weaponframe = 3;};
void() player_gshot3 = [$shotatt3, player_gshot4]	{self.weaponframe = 4;};
void() player_gshot4 = [$shotatt4, player_gshot5]	{self.weaponframe = 5;};
void() player_gshot5 = [$shotatt5, player_run]		{self.weaponframe = 6;};

// POX - New Frame Macro For Nailgun Second Trigger (Shrapnel Bomb)
void() player_shrap1 = [$nailatt1, player_shrap2]	{muzzleflash ();};
void() player_shrap2 = [$nailatt2, player_run]		{};

void() player_axe1 = [$axatt1, player_axe2]	{self.weaponframe=1;};
void() player_axe2 = [$axatt2, player_axe3]	{self.weaponframe=2;};
void() player_axe3 = [$axatt3, player_axe4]	{self.weaponframe=3;W_FireAxe();};
void() player_axe4 = [$axatt4, player_run]	{self.weaponframe=4;};

void() player_axeb1 = [$axattb1, player_axeb2]	{self.weaponframe=5;};
void() player_axeb2 = [$axattb2, player_axeb3]	{self.weaponframe=6;};
void() player_axeb3 = [$axattb3, player_axeb4]	{self.weaponframe=7;W_FireAxe();};
void() player_axeb4 = [$axattb4, player_run]	{self.weaponframe=8;};

void() player_axec1 = [$axattc1, player_axec2]	{self.weaponframe=1;};
void() player_axec2 = [$axattc2, player_axec3]	{self.weaponframe=2;};
void() player_axec3 = [$axattc3, player_axec4]	{self.weaponframe=3;W_FireAxe();};
void() player_axec4 = [$axattc4, player_run]	{self.weaponframe=4;};

void() player_axed1 = [$axattd1, player_axed2]	{self.weaponframe=5;};
void() player_axed2 = [$axattd2, player_axed3]	{self.weaponframe=6;};
void() player_axed3 = [$axattd3, player_axed4]	{self.weaponframe=7;W_FireAxe();};
void() player_axed4 = [$axattd4, player_run]	{self.weaponframe=8;};

// NailGun animation
void() player_nail1 = [$nailatt1, player_nail2] 
{	
	if (self.st_nailgun > time)
		return;

	if (self.ammo_nails < 1) {
		sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
		self.st_nailgun = time + 0.4;
		player_run ();
		return;
	}

	muzzleflash ();

	if (!self.button0) {
		player_run ();
		return;
	}

	if (++self.weaponframe == 9)
		self.weaponframe = 1;

	SuperDamageSound ();
	W_FireNails (3);

	if (self.flags & FL_ONGROUND)
		self.velocity += v_forward * -20;
		
	self.st_nailgun = time + 0.1;
};

void() player_nail2 = [$nailatt2, player_nail1]
{
	if (self.st_nailgun > time)
		return;

	if (self.ammo_nails < 1) {	
		sound (self, CHAN_WEAPON, "weapons/mfire1.wav", 1, ATTN_NORM);
		self.st_nailgun = time + 0.4;
		player_run ();
		return;
	}

	muzzleflash ();
	if (!self.button0) {
		player_run ();
		return;
	}

	if (++self.weaponframe == 9)
		self.weaponframe = 1;

	SuperDamageSound();
	W_FireNails (-3);
		
	if (self.flags & FL_ONGROUND)
		self.velocity += v_forward * -20;
		
	self.st_nailgun = time + 0.1;
};

//============================================================================
// POX - PlasmaGun animation - In sync with Paroxysm v1.1
void() player_plasma1	=[$nailatt1, player_plasma2  ]
{	
	if (self.st_plasma > time)
		return;

	if (self.ammo_cells < 1) {	
		sound (self, CHAN_WEAPON, "weapons/mfire2.wav", 1, ATTN_NORM);
		player_run ();
		self.st_plasma = time + 0.4;
		return;
	}

	muzzleflash ();

	if (!self.button0) {
		player_run ();
		return;
	}
		
	self.weaponframe = 1;
	self.LorR = 1;

	SuperDamageSound ();
	W_FirePlasma (6);

	if (self.flags & FL_ONGROUND)
		self.velocity += v_forward * -20;

	self.st_plasma = time + 0.1;
};

void() player_plasma2	=[$nailatt2, player_plasma1  ]
{	
	if (self.st_plasma > time)
		return;

	if (self.ammo_cells < 1) {	
		sound (self, CHAN_WEAPON, "weapons/mfire2.wav", 1, ATTN_NORM);
		player_run ();
		self.st_plasma = time + 0.4;
		return;
	}

	muzzleflash ();

	if (!self.button0) {
		player_run ();
		return;
	}

	self.weaponframe = 2;
	self.LorR = 0;

	SuperDamageSound();
	W_FirePlasma (-7);

	if (self.flags & FL_ONGROUND)
		self.velocity += v_forward * -20;

	self.st_plasma = time + 0.1;
};

//============================================================================
// POX - MegaPlasma Burst
void() player_mplasma1	 =[$rockatt1, player_mplasma2  ] {self.weaponframe=0;};
void() player_mplasma2	 =[$rockatt2, player_mplasma3  ] {};
void() player_mplasma3	 =[$rockatt3, player_run  ] {};

// POX - Grenadelauncher Animation
void() player_grenade1	 =[$rockatt1, player_grenade2  ] {self.weaponframe=1;muzzleflash();};
void() player_grenade2	 =[$rockatt2, player_grenade3  ] {self.weaponframe=2;};
void() player_grenade3	 =[$rockatt3, player_grenade4  ] {self.weaponframe=3;};
void() player_grenade4	 =[$rockatt4, player_grenade5  ] {self.weaponframe=4;};
void() player_grenade5	 =[$rockatt5, player_grenade6  ] {self.weaponframe=5;};
void() player_grenade6	 =[$rockatt6, player_run  ] {self.weaponframe=6;};

// POX - Annihilator firing sequence
void() player_rocket1 = [$rockatt1, player_rocket2]
{

	self.weaponframe = 1;
	W_FireRocket ('0 0 16');

	// sound is timed for double shot (two single shot sounds had inconsistant results)
	sound (self, CHAN_WEAPON, "weapons/rhino.wav", 1, ATTN_NORM);
	
	if (self.flags & FL_ONGROUND)
		self.velocity = v_forward * -25;

	msg_entity = self;

	WriteByte (MSG_ONE, SVC_BIGKICK);

	muzzleflash ();
};

void() player_rocket2 = [$rockatt2, player_rocket3]
{
	self.weaponframe = 2;
	W_FireRocket('0 0 24');
};

void() player_rocket3 = [$rockatt3, player_run ]	{self.weaponframe=3;};

// POX - Annihilator Reload sequence
void() player_rocketload1 = [$rockatt1, player_rocketload2] {self.weaponframe = 4;};
void() player_rocketload2 = [$rockatt3, player_rocketload3] {self.weaponframe = 5;};
void() player_rocketload3 = [$rockatt4, player_rocketload4] {self.weaponframe = 6;};
void() player_rocketload4 = [$rockatt5, player_rocketload5] {self.weaponframe = 7;};
void() player_rocketload5 = [$rockatt6, player_rocketload6] {self.weaponframe = 8;};
void() player_rocketload6 = [$rockatt4, player_run]			{self.weaponframe = 9;};

void (float num_bubbles) DeathBubbles;

void() PainSound =
{
	local float		rs = random ();

	if (self.health < 0)
		return;

	if (damage_attacker.classname == "teledeath") {
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

	// water pain sounds
	if (self.watertype == CONTENT_WATER && self.waterlevel == 3) {
		DeathBubbles (1);

		if (rs > 0.5)
			sound (self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.watertype == CONTENT_SLIME) {	// slime pain sounds
		// FIXME: put in some steam here
		if (rs > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.watertype == CONTENT_LAVA) {
		if (rs > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.pain_finished > time) {
		self.axhitme = 0;
		return;
	}

	self.pain_finished = time + 0.5;

	// don't make multiple pain sounds right after each other

	if (self.axhitme == 1) {	// axe pain sound
		self.axhitme = 0;
		sound (self, CHAN_VOICE, "player/axhit1.wav", 1, ATTN_NORM);
		return;
	}
	
	rs = rint ((random () * 5) + 1);
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

void() player_pain1 = [$pain1, player_pain2]	{PainSound (); self.weaponframe = 0;};
void() player_pain2 = [$pain2, player_pain3]	{};
void() player_pain3 = [$pain3, player_pain4]	{};
void() player_pain4 = [$pain4, player_pain5]	{};
void() player_pain5 = [$pain5, player_pain6]	{};
void() player_pain6 = [$pain6, player_run]		{};

void() player_axpain1 =	[$axpain1, player_axpain2]	{PainSound (); self.weaponframe = 0;};
void() player_axpain2 =	[$axpain2, player_axpain3]	{};
void() player_axpain3 =	[$axpain3, player_axpain4]	{};
void() player_axpain4 =	[$axpain4, player_axpain5]	{};
void() player_axpain5 =	[$axpain5, player_axpain6]	{};
void() player_axpain6 =	[$axpain6, player_run]		{};

void() player_pain =
{
	if (self.weaponframe)
		return;

	if (self.invisible_finished > time)
		return;		// eyes don't have pain frames

	if (self.weapon == IT_AXE)
		player_axpain1 ();
	else
		player_pain1 ();
};

void() player_diea1;
void() player_dieb1;
void() player_diec1;
void() player_died1;
void() player_diee1;
void() player_die_ax1;

void() DeathBubblesSpawn =
{
	local entity	bubble;

	if (self.owner.waterlevel != 3)
		return;

	bubble = spawn ();

	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.owner.origin + '0 0 24');
	setsize (bubble, '-8 -8 -8', '8 8 8');

	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';

	bubble.classname = "bubble";
	bubble.cnt = 0;
	bubble.frame = 0;

	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;

	self.think = DeathBubblesSpawn;
	self.nextthink = time + 0.1;

	if (++self.air_finished >= self.bubble_count)
		remove (self);
};

void (float num_bubbles) DeathBubbles =
{
	local entity	bubble_spawner;
	
	bubble_spawner = spawn ();
	setorigin (bubble_spawner, self.origin);

	bubble_spawner.owner = self;

	bubble_spawner.air_finished = 0;
	bubble_spawner.bubble_count = num_bubbles;
	bubble_spawner.movetype = MOVETYPE_NONE;
	bubble_spawner.solid = SOLID_NOT;

	bubble_spawner.think = DeathBubblesSpawn;
	bubble_spawner.nextthink = time + 0.1;

	return;
};

void() DeathSound =
{
	local float		rs;

	if (self.waterlevel == 3) {	// water death sounds
		DeathBubbles (5);
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
	self.nextthink = -1;	// allow respawn after a certain time
	self.deadflag = DEAD_DEAD;
};

vector(float dm) VelocityForDamage =
{
	local vector	v;

	if (vlen (damage_inflictor.velocity) > 0) {
		v = 0.5 * damage_inflictor.velocity;
		v += 25 * normalize (self.origin - damage_inflictor.origin);
		v_x += 200 * crandom ();
		v_y += 200 * crandom ();
		v_z = 100 + 240 * random();
//		dprint ("Velocity gib\n");
	} else {
		v_x = 100 * crandom();
		v_y = 100 * crandom();
		v_z = 200 + 100 * random();
	}

//	v_x = 100 * crandom();
//	v_y = 100 * crandom();
//	v_z = 200 + 100 * random();

	if (dm > -50) {
//		dprint ("level 1\n");
		v *= 0.7;
	} else if (dm > -200) {
//		dprint ("level 3\n");
		v *= 2;
	} else {
		v *= 10;
	}

	return v;
};


void (string gibname, float dm) ThrowGib =
{
	local entity	new;

	new = spawn ();
	new.origin = self.origin;
	setmodel (new, gibname);
	setsize (new, '0 0 0', '0 0 0');

	// wind tunnels
	new.solid = SOLID_TRIGGER;

	if (self.waterlevel > 0) {	// make gibs float in water
		new.classname = "gib";
		new.movetype = MOVETYPE_FLY;
		new.velocity = '100 3 15';
		new.think = bubble_bob;
		new.nextthink = time + 0.5;
		new.cnt = 0;
	} else {
		new.velocity = VelocityForDamage (dm);
		new.movetype = MOVETYPE_BOUNCE;

		new.avelocity_x = random () * 600;
		new.avelocity_y = random () * 600;
		new.avelocity_z = random () * 600;

		new.think = SUB_Remove;
		new.ltime = time;
		new.nextthink = time + 10 + random () * 10;
		new.flags = 0;
	}

	new.frame = 0;
};


void (string gibname, float dm) ThrowHead =
{
	setmodel (self, gibname);
	self.frame = 0;
	self.takedamage = DAMAGE_NO;

	// wind tunnels
	self.solid = SOLID_TRIGGER;

	if (self.waterlevel > 0) {	// float 'em
		self.movetype = MOVETYPE_FLY;

		self.velocity = '100 3 15';

		self.think = bubble_bob;
		self.nextthink = time + 0.5;
		self.cnt = 0;
	} else {
		self.movetype = MOVETYPE_BOUNCE;

		self.velocity = VelocityForDamage (dm);
		self.avelocity = crandom () * '0 600 0';

		self.nextthink = -1;
	}
	self.view_ofs = '0 0 8';
	setsize (self, '-16 -16 0', '16 16 56');
	self.origin_z -= 24;

	self.flags &= ~FL_ONGROUND;
};

void() GibPlayer =
{
	// make a nice gib in Gib mode
	if (deathmatch & DM_GIB)
		self.health -= 40;

	ThrowHead ("progs/h_player.mdl", self.health);
	ThrowGib ("progs/gib1.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);

	self.deadflag = DEAD_DEAD;

	if (damage_attacker.classname == "teledeath") {
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

	if (damage_attacker.classname == "teledeath2") {
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

	if (random () < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);
};

void() PlayerDie =
{
	local float		i;
	local string	s;

	self.items &= ~IT_INVISIBILITY;

	if (stof (infokey (world, "dq"))) {	// drop quad?
		if (self.super_damage_finished > 0) {
			DropQuad (self.super_damage_finished - time);
			s = self.netname
				+ " lost a Quad with "
				+ ftos (rint (self.super_damage_finished - time))
				+ " seconds remaining!\n";

			BPRINT (PRINT_MEDIUM, s);
		}
	}

	if (stof (infokey (world, "dc"))) {
		if (self.invisible_finished > 0) {
			DropRing (self.invisible_finished - time);
			s = self.netname
				+ " lost a Cloaking Device with "
				+ ftos (rint (self.invisible_finished - time))
				+ " seconds remaining!\n";
			BPRINT (PRINT_LOW, s);
		}
	}

	self.invisible_finished = 0;	// don't die as eyes
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.modelindex = modelindex_player;	// don't use eyes

	// + POX - moved below gib check (no packs when gibbed!)
	//DropBackpack();

	// + POX v1.11 - clear the target print so it doesn't obscure the scoreboard
	if (self.target_id_toggle)
		centerprint (self, "");

	self.weaponmodel = "";
	self.view_ofs = '0 0 -8';
	self.deadflag = DEAD_DYING;
	self.solid = SOLID_NOT;
	self.flags &= ~FL_ONGROUND;
	self.movetype = MOVETYPE_TOSS;

	if (self.velocity_z < 10)
		self.velocity_z = self.velocity_z + random () * 300;
	
	// + POX check for gib mode as well as regular gib
	if (self.health < -40 || (deathmatch & DM_GIB)) {		
		GibPlayer ();
		return;
	}
	
	DropBackpack ();
	
	DeathSound ();
	
	self.angles_x = 0;
	self.angles_z = 0;
	
	if (self.weapon == IT_AXE) {
		player_die_ax1 ();
		return;
	}

	i = 1 + floor (random () * 5);
	switch (i) {
		case 1:
			player_diea1 ();
			break;
		case 2:
			player_dieb1 ();
			break;
		case 3:
			player_diec1 ();
			break;
		case 4:
			player_died1 ();
			break;
		default:
			player_diee1 ();
	}
};

void() set_suicide_frame =
{	// used by kill command and diconnect command
	if (self.model != "progs/player.mdl")
		return; // allready gibbed

	self.frame = $deatha11;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_TOSS;
	self.deadflag = DEAD_DEAD;
	self.nextthink = -1;
};

void() player_diea1	=	[$deatha1, player_diea2]	{};
void() player_diea2	=	[$deatha2, player_diea3]	{};
void() player_diea3	=	[$deatha3, player_diea4]	{};
void() player_diea4	=	[$deatha4, player_diea5]	{};
void() player_diea5	=	[$deatha5, player_diea6]	{};
void() player_diea6	=	[$deatha6, player_diea7]	{};
void() player_diea7	=	[$deatha7, player_diea8]	{};
void() player_diea8	=	[$deatha8, player_diea9]	{};
void() player_diea9	=	[$deatha9, player_diea10]	{};
void() player_diea10 =	[$deatha10, player_diea11]	{};
void() player_diea11 =	[$deatha11, player_diea11]	{PlayerDead ();};

void() player_dieb1	=	[$deathb1, player_dieb2]	{};
void() player_dieb2	=	[$deathb2, player_dieb3]	{};
void() player_dieb3	=	[$deathb3, player_dieb4]	{};
void() player_dieb4	=	[$deathb4, player_dieb5]	{};
void() player_dieb5	=	[$deathb5, player_dieb6]	{};
void() player_dieb6	=	[$deathb6, player_dieb7]	{};
void() player_dieb7	=	[$deathb7, player_dieb8]	{};
void() player_dieb8	=	[$deathb8, player_dieb9]	{};
void() player_dieb9	=	[$deathb9, player_dieb9]	{PlayerDead ();};

void() player_diec1	= [$deathc1, player_diec2]		{};
void() player_diec2	= [$deathc2, player_diec3]		{};
void() player_diec3	= [$deathc3, player_diec4]		{};
void() player_diec4	= [$deathc4, player_diec5]		{};
void() player_diec5	= [$deathc5, player_diec6]		{};
void() player_diec6	= [$deathc6, player_diec7]		{};
void() player_diec7	= [$deathc7, player_diec8]		{};
void() player_diec8	= [$deathc8, player_diec9]		{};
void() player_diec9	= [$deathc9, player_diec10]		{};
void() player_diec10 = [$deathc10, player_diec11]	{};
void() player_diec11 = [$deathc11, player_diec12]	{};
void() player_diec12 = [$deathc12, player_diec13]	{};
void() player_diec13 = [$deathc13, player_diec14]	{};
void() player_diec14 = [$deathc14, player_diec15]	{};
void() player_diec15 = [$deathc15, player_diec15]	{PlayerDead();};

void() player_died1	= [$deathd1, player_died2]	{};
void() player_died2	= [$deathd2, player_died3]	{};
void() player_died3	= [$deathd3, player_died4]	{};
void() player_died4	= [$deathd4, player_died5]	{};
void() player_died5	= [$deathd5, player_died6]	{};
void() player_died6	= [$deathd6, player_died7]	{};
void() player_died7	= [$deathd7, player_died8]	{};
void() player_died8	= [$deathd8, player_died9]	{};
void() player_died9	= [$deathd9, player_died9]	{PlayerDead ();};

void() player_diee1	= [$deathe1, player_diee2]	{};
void() player_diee2	= [$deathe2, player_diee3]	{};
void() player_diee3	= [$deathe3, player_diee4]	{};
void() player_diee4	= [$deathe4, player_diee5]	{};
void() player_diee5	= [$deathe5, player_diee6]	{};
void() player_diee6	= [$deathe6, player_diee7]	{};
void() player_diee7	= [$deathe7, player_diee8]	{};
void() player_diee8	= [$deathe8, player_diee9]	{};
void() player_diee9	= [$deathe9, player_diee9]	{PlayerDead();}; 

void() player_die_ax1 = [$axdeth1, player_die_ax2]	{};
void() player_die_ax2 = [$axdeth2, player_die_ax3]	{};
void() player_die_ax3 = [$axdeth3, player_die_ax4]	{};
void() player_die_ax4 = [$axdeth4, player_die_ax5]	{};
void() player_die_ax5 = [$axdeth5, player_die_ax6]	{};
void() player_die_ax6 = [$axdeth6, player_die_ax7]	{};
void() player_die_ax7 = [$axdeth7, player_die_ax8]	{};
void() player_die_ax8 = [$axdeth8, player_die_ax9]	{};
void() player_die_ax9 = [$axdeth9, player_die_ax9]	{PlayerDead();};
