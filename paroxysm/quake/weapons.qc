/*
A note from POX (pox@planetquake.com):

This file has been hacked to death.

Large portions of code have been altered / deleted or commented out,
many of the new weapons are tied into big changes in client.qc and player.qc.

When I first started, I was just hacking around so a lot of code went uncommented, and
unchecked. I cleaned it up as much as possible but it still sucks hard in some places

There is alot of code commented out - stuff like the old Paroxysm PulseGun routines
have been left in 'casue they offer some unique hacks that may be of interest.

You'll see FlameThrower stuff all over the place, it was removed from the mod but it
was easier to just leave it in some functions. (I may enable it some day...)

You've been warned...

BTW - 'Rhino' was the original name for the Anihilator...

*/

//POX v1.1 moved prototypes to sectrig.qc

// called by worldspawn
// POX - LOADS of new mdls and sounds to precache...
void() W_Precache =
{	
	precache_model ("progs/plasma.mdl");
	precache_model ("progs/laser.mdl");
	precache_model ("progs/spark.spr");

	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/nailgun.wav"); // new nailgun sound
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/tink2.wav");
	precache_sound ("weapons/grenade.wav"); // grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/bounce2.wav");		// grenade bounce alt
	precache_sound ("weapons/shotgn2.wav"); // super shotgun
	
	precache_sound ("weapons/mfire1.wav");	// missfire
	precache_sound ("weapons/mfire2.wav");	// megaplasma burst missfire
	precache_sound ("weapons/plasma.wav");		// plasmagun fire
	precache_sound ("weapons/mplasma.wav");		// megaplasmagun fire
	precache_sound ("weapons/mplasex.wav");		// megaplasmagun explosion
	precache_sound ("weapons/ssgrnde.wav"); // super shotgun grenade fire
	precache_sound ("weapons/armed.wav");		// mine armed sound
	precache_sound ("weapons/minedet.wav"); //mine detonate click
	
	precache_sound ("weapons/rhino.wav");	//rhino firing sound
	precache_sound ("weapons/rhinore.wav"); //rhino reload sound
	precache_sound ("weapons/error.wav");	//weapon error sound
	
	precache_sound ("weapons/tsload.wav");	//t-shot load
	precache_sound ("weapons/tsfire.wav");	//t-shot single fire
	precache_sound ("weapons/ts3fire.wav"); //t-shot triple fire

	
	//BoneSaw sounds
	precache_sound ("weapons/sawon.wav");
	precache_sound ("weapons/sawoff.wav");
	precache_sound ("misc/null.wav");		//Used to silence the saw at weapon switch
	precache_sound ("weapons/sawguts.wav");
	precache_sound ("weapons/sawhit.wav");
	precache_sound ("weapons/sawatck.wav");
	precache_sound ("weapons/sawidle.wav");
	
	precache_sound ("weapons/shrapdet.wav"); //ShrapnelBomb detonation-confirmation beep
	//Shrapnel Model
	precache_model("progs/mwrub1.mdl");

	
	
// VisWeap - Player
	precache_model ("progs/bsaw_p.mdl");
	precache_model ("progs/tshot_p.mdl");
	precache_model ("progs/combo_p.mdl");
	precache_model ("progs/plasma_p.mdl");
	precache_model ("progs/nail_p.mdl"); 
	precache_model ("progs/gren_p.mdl");
	precache_model ("progs/rhino_p.mdl");

// VisWeap - Weapon drop
	precache_model ("progs/d_bsaw.mdl");
	precache_model ("progs/d_tshot.mdl");
	precache_model ("progs/d_combo.mdl");
	precache_model ("progs/d_plasma.mdl");
	precache_model ("progs/d_nail.mdl");
	precache_model ("progs/d_gren.mdl");
	precache_model ("progs/d_rhino.mdl");

//No weapon Death Model (weapons are dropped)
	precache_model ("progs/death_p.mdl");

};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local	entity missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();

	missile.avelocity = '3000 1000 2000';
	
// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, org);
};


/* POX - 1.01b2 - made this a little neater
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{	
	local float	blood;
	
	//check for a bleeder
	if (!trace_ent.nobleed)
		blood = 73;
	else
		blood = 6;
	
	particle (org, vel*0.4, blood, damage*3);
};


/* POX - 1.01b2 - made this a little neater
================
spawn_touchblood
================
*/
void(entity who,float damage) spawn_touchblood =
{
	local vector	vel;
	local float		blood;
	
	//check for a bleeder
	if (!other.nobleed)
		blood = 73;
	else
		blood = 6;
	
	vel = wall_velocity () * 0.2;
	
	particle (self.origin, vel*0.4, blood, damage*2);
};


/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
POX - The BoneSaw replaces the Pulsegun from versions .4b2 and below
This code is based on the chainsaw code from Zerstyer, with a re-write
of the sound and animation code to accomodate the new model (see player.qc)
================

W_FireSaw

================

*/

void() W_FireSaw =

{

	local	vector	source;

	local	vector	org;



	makevectors (self.v_angle);


//POX - v1.02b - increased range

	source = self.origin + '0 0 24';

	traceline (source, source + v_forward*64, FALSE, self);

	if (trace_fraction == 1.0)

		return;

	

	org = trace_endpos - v_forward*4;



	if (trace_ent.takedamage)

	{

		trace_ent.axhitme = 2;
		
		//POX v1.1 - nobleed fix
		if (trace_ent.nobleed)
		{
			WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte (MSG_BROADCAST, TE_GUNSHOT);
			WriteCoord (MSG_BROADCAST, org_x);
			WriteCoord (MSG_BROADCAST, org_y);
			WriteCoord (MSG_BROADCAST, org_z);
		}
		else
		{
			SpawnBlood(trace_endpos, '0 0 5', 20);
			SpawnMeatSpray (self.origin + v_forward*16, ((random()*300) - 150) * v_right + (100 * v_forward));
		}


		T_Damage (trace_ent, self, self, 17); //POX 1.01b - reduced damage - POX 1.1 increased damage :)


		trace_ent.velocity = trace_ent.velocity * 0.5;

		sound (self, CHAN_WEAPON, "weapons/sawguts.wav", 1, ATTN_NORM);

		self.punchangle_x = -8;

	}

	else

	{	// hit wall

		sound (self, CHAN_WEAPON, "weapons/sawhit.wav", 1, ATTN_NORM);

		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);

	}

};


//============================================================================


/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity	multi_ent;
float	multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;
	
	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	local	vector	vel, org;
	
	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

//POX - v1.1 - Fixed nobleed not working with shotguns
	if (trace_ent.takedamage && !trace_ent.nobleed)
	{
		SpawnBlood (org, vel*0.2, damage);
		AddMultiDamage (trace_ent, damage);
	}
	else if (trace_ent.takedamage && trace_ent.nobleed)
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
		AddMultiDamage (trace_ent, damage);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/* POX - v1.1
================
FireBullets2

Made a seperate function for the tShot second trigger
- more damage with less bullets
================
*/
void(float shotcount, vector dir, vector spread) FireBullets2 =
{
	local	vector direction;
	local	vector	src;
	
	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (8, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local	vector direction;
	local	vector	src;
	
	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/* POX v1.11 - a cool effect but originally for single player...
================
spawn_spark creates a spark (used by plasma weapons)
================


void() spark_touch =
{
	if (random() < 0.2)
		remove(self);
};

void(float ox) spawn_spark =
{	
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_NOT;
	newmis.classname = "spark";

	makevectors (self.v_angle);

	newmis.velocity = v_forward*60 + v_up * 260 + crandom()*v_right*200 + crandom()*v_up*20;

	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = spark_touch;
	newmis.nextthink = time + random()*2;
	newmis.think = SUB_Remove;
	setmodel (newmis, "progs/spark.spr");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, self.origin + v_forward*36 + v_right*ox);

};

*/

/*
================
W_FireShotgun
================
*/

void() W_FireShotgun =
{
	local vector dir;
	
	sound (self, CHAN_WEAPON, "weapons/tsfire.wav", 1, ATTN_NORM);	

	self.punchangle_x = -2;
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -35;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	dir = aim (self, 100000);
	FireBullets (6, dir, '0.04 0.04 0');
};


/*
================
W_FireSuperShotgun
================
*/
void() W_FireSuperShotgun =
{
	local vector dir;
	local float bullets, used;
	
	bullets = 14;
	used = 2;
	
	//POX v1.1 don't plat tShot sound...
	if (self.currentammo == 1)
	{
		bullets = 6;
		used = 1;
	}
		
	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM); 

	self.punchangle_x = -4;
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -60;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - used;
	dir = aim (self, 100000);
	FireBullets (bullets, dir, '0.14 0.08 0');
};




/*
==============================================================================

ROCKETS

==============================================================================
*/

void() T_MissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner
	
	//POX v1.11
	if (self.voided)
		return;
		
	self.voided = 1;
	
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 20 + random()*10;
	
	if (other.health)
		T_Damage (other, self, self.owner, damg);


	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 90, other);

//	For some reason, ID called explosions sounds from all over the place
//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

/*
================
W_FireRocket
================
*/
void(vector barrel) W_FireRocket =
{
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 0.5;
	
	//if player fired last rocket reset the reload bit
	if (self.ammo_rockets == 0)
		self.reload_rocket = 0;
	else //player has rockets left so ad 1 to reload count
		self.reload_rocket = self.reload_rocket + 1;
	
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "rocket";
		
// set newmis speed	

	makevectors (self.v_angle);

	newmis.velocity = v_forward*1100 + v_up * 220 + v_right* -22;

	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = T_MissileTouch;

	
// set newmis duration
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	
	setmodel (newmis, "progs/grenade.mdl");
		
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, self.origin + v_forward* 8 + v_right* 12 + barrel);
	
};

//=============================================================================
//
// Grenade 
//
//=============================================================================

void() GrenadeExplode =
{
	//POX v1.11
	if (self.voided)
		return;
		
	self.voided = 1;
	
	T_RadiusDamage (self, self.owner, 120, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void() GrenadeTouch =
{
	local	float	r;
	
	r=random();
	
	if (other == self.owner)
		return;		// don't explode on owner
	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode();
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

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	
	self.punchangle_x = -4;
	
	//Added weapon kickback (as long as you're not in mid air)
	if (self.flags & FL_ONGROUND)
		self.velocity = self.velocity + v_forward* -75;

	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "grenade";
		
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
	
	newmis.touch = GrenadeTouch;
	
// set newmis duration
	newmis.nextthink = time + 2.5;
	newmis.think = GrenadeExplode;

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, self.origin);
};


/*
=================================================================================
Start Plasma Gun Fire
=================================================================================
*/

void() plasma_touch =
{
	if (other == self.owner)
		return;
	
	//POX v1.11
	if (self.voided)
		return;
		
	self.voided = 1;

	//if (other.solid == SOLID_TRIGGER)
	//	return; // trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (other, 7);

			
		T_Damage (other, self, self.owner, 7);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};

void(vector org, vector dir) launch_plasma =
{
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = plasma_touch;
	newmis.classname = "plasma";
	
		/*POX v1.11
	if (self.classname == "bot")
	{
		newmis.nextthink = time + 0.05;
		newmis.think = bot_missile_think;
	}
	else
	{*/
		newmis.think = SUB_Remove;
		newmis.nextthink = time + 5;
	//}
	
	setmodel (newmis, "progs/laser.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1400;

};

void(float ox) W_FirePlasma =
{
	local vector	dir;
	
	makevectors (self.v_angle);

	sound (self, CHAN_WEAPON, "weapons/plasma.wav", 1, ATTN_NORM);
	
	self.currentammo = self.ammo_cells = self.ammo_cells - 1;
	
	self.punchangle_x = -1;
	
	dir = aim (self, 1000);
	
	launch_plasma (self.origin + v_forward*12 + '0 0 12' + v_right*ox, dir);
	//POX v1.11
	//spawn_spark(ox);

	
};

/*
=================================================================================
Start nailgun fire
=================================================================================
*/
void() spike_touch =
{

	if (other == self.owner)
		return;

	//POX v1.11
	if (self.voided)
		return;
		
	self.voided = 1;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{	
		spawn_touchblood (other, 9);	
		T_Damage (other, self, self.owner, 9);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};

void() superspike_touch =
{
	if (other == self.owner)
		return;

	//POX v1.11
	if (self.voided)
		return;
		
	self.voided = 1;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{	
		spawn_touchblood (other, 18);

			
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};

void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.voided = 0;
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	
	/*POX v1.11
	if (self.classname == "bot")
	{
		newmis.nextthink = time + 0.05;
		newmis.think = bot_missile_think;
	}
	else
	{*/
		newmis.think = SUB_Remove;
		newmis.nextthink = time + 6;
	//}	
	
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;

};

// New Nailgun fire
void(float ox) W_FireNails =
{
	local vector	dir;
	
	self.weaponmodel = "progs/v_nailgl.mdl"; // light up nailgun barrels
	
	if (!self.aflag) //don't swap models if chasecam is on
		sound (self, CHAN_WEAPON, "weapons/nailgun.wav", 1, ATTN_NORM); // new nailgun sound
	
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16' + v_right*ox, dir);
	newmis.touch = spike_touch;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	self.punchangle_x = -2;
	
};

// Left for spike trap use
void() W_FireSuperSpikes =
{
	local vector	dir;
	
	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	//self.attack_finished = time + 0.15;
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16', dir);
	newmis.touch = superspike_touch;
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	
};

// Obselete?
void(float ox) W_FireSpikes =
{
	local vector	dir;
	
	makevectors (self.v_angle);
	
	/*
	if (self.weapon == IT_SUPER_NAILGUN)
	{
		W_FireNails (ox); // Go to the New Nail attack
		return;
	}
	
	else
	{*/
		sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
		//self.attack_finished = time + 0.2;
		self.currentammo = self.ammo_nails = self.ammo_nails - 1;
		dir = aim (self, 1000);
		launch_spike (self.origin + '0 0 16' + v_right*ox, dir);

		self.punchangle_x = -2;
	//}
};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

void() W_SetCurrentAmmo =
{
	//POX - saw_on is a hack to keep the BoneSaw's animation playing correctly
	if (!self.saw_on)
		player_run ();		// get out of any weapon firing states

	self.items &= ~(IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS);
	
	self.weaponmodel = ""; //Hack for ChaseCam
	
	if (self.weapon == IT_BONESAW)
	{
	
		self.currentammo = 0;
		
	if (self.aflag != TRUE)
		self.weaponmodel = "progs/v_bsaw.mdl";

	}
	else if (self.weapon == IT_TSHOT)
	{
		self.currentammo = self.ammo_shells;
	
	if (self.aflag != TRUE)
		self.weaponmodel = "progs/v_tshot.mdl";
	
		self.weaponframe = 0;
		
		self.items |= IT_SHELLS;
	}
	else if (self.weapon == IT_COMBOGUN)
	{	
	
	if (self.aflag != TRUE)
		self.weaponmodel = "progs/v_combo.mdl";
		
		self.weaponframe = 0;
		
		//POX - ammo depends on last active trigger
		if (self.which_ammo == 1)
		{
			self.currentammo = self.ammo_rockets;
			self.items |= IT_ROCKETS;
		}
		else
		{
			self.currentammo = self.ammo_shells;
			self.items |= IT_SHELLS;
		}
	}
	else if (self.weapon == IT_PLASMAGUN)
	{
		self.currentammo = self.ammo_cells;
	
	if (self.aflag != TRUE)
		self.weaponmodel = "progs/v_plasma.mdl";
	
		self.weaponframe = 0;
		self.items |= IT_CELLS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
	
	if (self.aflag != TRUE)
		self.weaponmodel = "progs/v_nailg.mdl";
	
		self.weaponframe = 0;
		self.items |= IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
	
	if (self.aflag != TRUE)
		self.weaponmodel = "progs/v_gren.mdl";

		self.weaponframe = 0;
		self.items |= IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
	
	if (self.aflag != TRUE)
		self.weaponmodel = "progs/v_rhino.mdl";

		self.weaponframe = 0;
		self.items |= IT_ROCKETS;
	}
	else
	{
		self.currentammo = 0;
		self.weaponmodel = "";
		self.weaponframe = 0;
	}
	
	//Silence the BoneSaw and flag it off
	if (self.weapon != IT_BONESAW)
	{
		sound (self, CHAN_WEAPON, "misc/null.wav", 1, ATTN_NORM);
		self.saw_on = FALSE;
	}
	
	getmodel(self.weapon, self);  // VisWeap MOD: updates the model to take new weapon into account.

};

/* BEST WEAPON MARKER */
float() W_BestWeapon =
{
	local	float	it;
	
	it = self.items;
	
	// A hacky way to keep SuperShot Gun Active when out of rockets
	if ((self.weapon == IT_COMBOGUN) && ( self.ammo_shells >= 2 && (self.ammo_rockets < 1)))
		return IT_COMBOGUN;

	//if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_FLAMETHROWER) )
	//		return IT_FLAMETHROWER;
	if(self.ammo_cells >= 1 && (it & IT_PLASMAGUN) )
		return IT_PLASMAGUN;
	if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;
	if(self.ammo_shells >= 2 && (it & IT_COMBOGUN) )
		return IT_COMBOGUN;
	if(self.ammo_shells >= 1 && (it & IT_TSHOT) )
		return IT_TSHOT;
	return IT_BONESAW;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_BONESAW)
		return TRUE;
	
	self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();
	
// drop the weapon down
	return FALSE;
};
/* BEST WEAPON MARKER */

/*
============
W_Attack

An attack impulse can be triggered now
============
*/

//POX v1.1 moved protypes to sectrig.qc added intermission check
float	intermission_running;

void() W_Attack =
{
	// + POX - from URQW patch...
	// 1999-07-05 Firing during intermission fix by numb - start
    if (intermission_running)
	return;

	if (deathmatch & DM_AUTOSWITCH)
	{
		if (!W_CheckNoAmmo ())
		return;
	}
	
	makevectors	(self.v_angle);			// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up

	
	if (self.weapon == IT_BONESAW)

	{
		
		if (!self.saw_on)
			player_bonesaw1();
		else
			player_bonesaw3();

		self.attack_finished = time + 0.55;

	}
	else if (self.weapon == IT_TSHOT)
	{	
		if (self.ammo_shells < 1)
		{
			sound (self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
			self.attack_finished = time + 0.5;
		}
		else if (self.st_tshotload < time) //prime done so shoot
		{	
			//t-shot is primed so do a triple shot
			//have to double check ammo since switch to ComboGun can mess it up
			if ((self.prime_tshot == TRUE) && (self.ammo_shells > 2))
			{
				player_tshot1 ();
				W_FireTShot ();
				self.attack_finished = time + 0.7;
				self.prime_tshot = FALSE;
			}
			else //normal shot
			{
				player_shot1 ();
				W_FireShotgun ();
				self.attack_finished = time + 0.5;
			//reset prime since switching to ComboGun can use up shells
				self.prime_tshot = FALSE;
			}
		}
	}
	
	else if ((self.weapon == IT_COMBOGUN) && (self.st_sshotgun < time))
	{	
		if (self.ammo_shells < 1)
		{	
			self.currentammo = self.ammo_shells;
			self.items &= ~(IT_ROCKETS);
			self.items |= IT_SHELLS;
			self.which_ammo = 0;
			sound (self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
			self.st_sshotgun = time + 0.7;
		}
		
		else
		{
			self.currentammo = self.ammo_shells;
			self.items &= ~(IT_ROCKETS);
			self.items |= IT_SHELLS;
			self.which_ammo = 0;
			player_shot1 ();
			W_FireSuperShotgun ();
			self.st_sshotgun = time + 0.7;
		}
	}
	else if ((self.weapon == IT_PLASMAGUN) && (self.st_plasma < time) && (self.st_mplasma < time))
	{
		if (self.ammo_cells < 1)
		{
			sound (self, CHAN_AUTO, "weapons/mfire2.wav", 1, ATTN_NORM);
		}
		else if (!self.LorR) // check which barrel fired last
				player_plasma1 ();
			else
				player_plasma2 ();	
	}

	else if ((self.weapon == IT_SUPER_NAILGUN) && (self.st_nailgun < time))
	{		
		if (self.ammo_nails < 1)
			sound (self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
		else
			player_nail1 ();			
	}
	else if ((self.weapon == IT_GRENADE_LAUNCHER) && (self.st_grenade < time))
	{
		if (self.ammo_rockets < 1)
		{
			sound (self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
			self.st_grenade = time + 0.6;
		}
		else
		{
			player_grenade1();
			W_FireGrenade();
			self.st_grenade = time + 0.6;
		}
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		if (self.ammo_rockets < 1) //no rockets so missfire
		{
			sound (self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
			self.attack_finished = time + 0.4;
		}
		else if (self.reload_rocket > 6) //have to reload so missfire
		{
			sound (self, CHAN_AUTO, "weapons/error.wav", 1, ATTN_NORM);
			self.attack_finished = time + 0.42;
		}
		else if (self.st_rocketload > time) // still reloading so do nothing
		{
			SUB_Null ();
		}
		else
		{
			player_rocket1();
			self.attack_finished = time + 0.4;
		}
	}

};

/*
============
W_ChangeWeapon
============
*/
void() W_ChangeWeapon =
{
	local	float	it, am, fl = 0;
	
	it = self.items;
	am = 0;
	self.which_ammo = 0; // Default ammo to shells for SuperShotgun
	
	if (self.impulse == 1)
	{
		fl = IT_BONESAW;
		//self.p_flex = time + 8;
	}
	else if (self.impulse == 2)
	{
		fl = IT_TSHOT;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_COMBOGUN;
		if (self.ammo_shells < 2)
		{
			am = 1;
			//POX v1.1 - fix for dm_autoswitch
			if (self.ammo_rockets > 0 && !(deathmatch & DM_AUTOSWITCH)) // allow player to select SuperShotgun if he has rockets
			{
				self.which_ammo = 1; // tell W_SetCurrentAmmo to use rockets - not shells
				am = 0;
			}
		}
	}		
	else if (self.impulse == 4)
	{
		fl = IT_PLASMAGUN;
		if (self.ammo_cells < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 2)
			am = 1;
	}
	else if (self.impulse == 6)
	{
		fl = IT_GRENADE_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	
	self.impulse = 0;
	
	if (!(self.items & fl))
	{	// don't have the weapon or the ammo
		sprint (self, "no weapon.\n");
		return;
	}
	
	if (am)
	{	// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

//
// set weapon, set ammo
//
	self.weapon = fl;		
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{

	if (deathmatch || coop)
		return;

	self.ammo_rockets = 100;
	self.ammo_nails = 200;
	self.ammo_shells = 100;
	self.ammo_cells = 200;
	self.items |= (IT_BONESAW | IT_TSHOT | IT_COMBOGUN | IT_PLASMAGUN
				   | IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER
				   | IT_ROCKET_LAUNCHER);
		
	self.weapon = IT_COMBOGUN;
	self.impulse = 0;
	W_SetCurrentAmmo ();
};

/* POX v1.1 - got rid of non-existent flamethrower checks
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local	float	it, am;
	
	it = self.items;
	self.impulse = 0;
	
	while (1)
	{
		am = 0;
		self.which_ammo = 0;  // Default ammo to shells for SuperShotgun

		if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_BONESAW;
		}
		else if (self.weapon == IT_BONESAW)
		{
			self.weapon = IT_TSHOT;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_TSHOT)
		{
			self.weapon = IT_COMBOGUN;
			if (self.ammo_shells < 2)
			{
				am = 1;
				//POX v1.1 - fix for dm_autoswitch
				if (self.ammo_rockets > 0 && !(deathmatch & DM_AUTOSWITCH)) // allow player to select SuperShotgun if he has rockets
				{
					self.which_ammo = 1; // tell W_SetCurrentAmmo to use rockets - not shells
					am = 0;
				}
			}
		}		
		else if (self.weapon == IT_COMBOGUN)
		{
			self.weapon = IT_PLASMAGUN;
			if (self.ammo_cells < 1)
				am = 1;
		}
		else if (self.weapon == IT_PLASMAGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
	
		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local	float	it, am;
	
	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;
		self.which_ammo = 0;  // Default ammo to shells for SuperShotgun

		if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_PLASMAGUN;
			if (self.ammo_cells < 1)
				am = 1;
		}
		else if (self.weapon == IT_PLASMAGUN)
		{
			self.weapon = IT_COMBOGUN;
			
			// allow player to select ComboGun if he has rockets
			// BUT NOT IF DM_AUTOSWITCH!!
			if (self.ammo_shells < 2)
			{
				am = 1;
				if (self.ammo_rockets > 0 && !(deathmatch & DM_AUTOSWITCH))
				{
					self.which_ammo = 1; // tell W_SetCurrentAmmo to use rockets - not shells
					am = 0;
				}
			}
		}			
		else if (self.weapon == IT_COMBOGUN)
		{
			self.weapon = IT_TSHOT;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_TSHOT)
		{
			self.weapon = IT_BONESAW;
			//self.p_flex = time + 8;
		}
		else if (self.weapon == IT_BONESAW)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
	
		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
	if (deathmatch || coop)
		return;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items |= IT_QUAD;
	dprint ("quad cheat\n");
};


/*
============
ImpulseCommands

============
*/
//POX - put this in a sperate routine so the same impulse can be used in autocam/setup mode
void() DisplayRules =
{
		sprint (self, "\nÓåòöåò Òõìåó\n----------------------\n	   |\n");
		
		if (deathmatch & DM_PREDATOR)
			sprint (self, "on  | Predator Mode\n");
		else
			sprint (self, "ÏÆÆ | Predator Mode\n");
		
		if (deathmatch & DM_DARK)
			sprint (self, "on  | Dark Mode\n");
		else
			sprint (self, "ÏÆÆ | Dark Mode\n");
			
		if (deathmatch & DM_LMS)
			sprint (self, "on  | Last Man Standing\n");
		else
			sprint (self, "ÏÆÆ | Last Man Standing\n");
		
		if (deathmatch & DM_FFA)
			sprint (self, "on  | Free For All\n");
		else
			sprint (self, "ÏÆÆ | Free For All\n");
		
		if (deathmatch & DM_GIB)
			sprint (self, "on  | Gib\n");
		else
			sprint (self, "ÏÆÆ | Gib\n");
		
		if (deathmatch & DM_AUTOSWITCH)
			sprint (self, "on  | Weapon Autoswitch\n");
		else
			sprint (self, "ÏÆÆ | Weapon Autoswitch\n");
		
		if (deathmatch & DM_NOBOTS)
			sprint (self, "ÏÆÆ | Bots\n");
		else
			sprint (self, "on  | Bots\n    |\n----------------------\n\n");
			
};

.float target_id_temp;//POX 1.2
//POX - stuff added here, bot & camera impulses
void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();
	if (self.impulse == 9)
		CheatCommand ();
	if (self.impulse == 10)
		CycleWeaponCommand ();
	if (self.impulse == 11)
		ServerflagsCommand ();
	if (self.impulse == 12)
		CycleWeaponReverseCommand ();
	if (self.impulse == 255)
		QuadCheat ();

//POX - v1.1 target identifier toggle
	if (self.impulse == 16)
	{
		self.target_id_temp = TRUE;//POX v1.2 - hack to get targid to work accross level changes
		stuffcmd (self, "play misc/talk.wav\n"); //POX v1.2 audio confirmation
		
		if (self.target_id_toggle)
		{
			self.target_id_toggle = FALSE;
			
			//POX v1.12 - don't centerprint if a message is up
			if (self.target_id_finished < time)
				centerprint (self, "Target Identifier OFF\n");
			else
				sprint (self, "Target Identifier OFF\n");
	
		}
		else
		{
			self.target_id_toggle = TRUE;
			
			//POX v1.12 - don't centerprint if a message is up
			if (self.target_id_finished < time)
				centerprint (self, "Target Identifier ON\n");
			else
				sprint (self, "Target Identifier ON\n");

			self.target_id_finished = time + 3;		
		}
	}

//POX - v1.11 GL FlashBlend (hacky fix) - Toggles dynamiclights vs lightglows
	
	if (self.impulse == 17)
	{
		if(!self.gl_fix)
		{
			stuffcmd (self, "gl_flashblend 0\n");
			self.gl_fix = TRUE;
		}
		else
		{
			stuffcmd (self, "gl_flashblend 1\n");
			self.gl_fix = FALSE;
		}
	}

// KasCam ->
    if (self.impulse == 250)
    {	
    //If client hit observer in LMS mode, drop the player count
		if ((deathmatch & DM_LMS) && self.frags > 0)
		{
			lms_plrcount = lms_plrcount - 1;
			self.LMS_registered = FALSE; //Don't display LMS dead message
			self.frags = 0;	       
			CamClientInit ();
		}
		else
		{
			self.frags = 0;	       
			CamClientInit ();
		}
    }
// <- KasCam

//ChaseCam
	if (self.impulse == 254)
		CCam ();
		
	if (self.impulse == 150)
		CCamUp (2);
	if (self.impulse == 151)
		CCamRight (2);
	if (self.impulse == 152)
		CCamForward (2);	
	if (self.impulse == 153)
		CCamUp (-2);
	if (self.impulse == 154)
		CCamRight (-2);
	if (self.impulse == 155)
		CCamForward (-2); 
//ChaseCam

	//Bot impulses - no coop/single player
	
	//Create Enemy bot (FF or Team)
	if (self.impulse == 251 && deathmatch)
		create_bot(1);
	
	//Create TeamBot
	if (self.impulse == 252 && deathmatch && teamplay)
		create_bot(2);
	
	//Display Server Rules Impulse
	if (self.impulse == 253)
		DisplayRules();

	self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/

void() W_WeaponFrame =
{		
	if (time < self.attack_finished)
		return;
		
	// POX - v1.1 target identifier
	if (self.target_id_toggle && (time > self.target_id_finished))
		ID_CheckTarget ();
	
	//POX - Don't swap nailgun skins if player chascam is active!
	if ((self.weapon == IT_SUPER_NAILGUN) && (self.st_nailgun < time) && (!self.aflag))
		self.weaponmodel = "progs/v_nailg.mdl"; // cool off nailgun barrels
	
// + POX - only check these if necessary (thanks to URQW patch)
// 1998-08-14 Constantly checking all impulses fix by Perged
	if (self.impulse == SECOND_TRIGGER)
		W_SecondTrigger ();
	else if (self.impulse)
	    ImpulseCommands ();
// - POX
		
// check for attack
	if (self.button0)
	{
		SuperDamageSound ();
		W_Attack ();
	}
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_AUTO, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
};
