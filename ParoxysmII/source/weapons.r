#include "paroxysm.rh"

/*
*/


// called by worldspawn - POX - added lots'o'junk here...
void() W_Precache =
{
	precache_model ("progs/plasma.mdl");
	precache_model ("progs/laser.mdl");

	precache_sound ("weapons/r_exp3.wav");		// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/ric1.wav");		// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");		// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");		// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");		// super spikes
	precache_sound ("weapons/hog.wav"); 		// new nailgun sound
	precache_sound ("weapons/tink1.wav");		// spikes tink (used in c code)
	precache_sound ("weapons/tink2.wav");
	precache_sound ("weapons/gren.wav"); 		// grenade launcher
	precache_sound ("weapons/gren2.wav"); 		// second trigger grenades
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/bounce2.wav");		// grenade bounce alt
	precache_sound ("weapons/shotgn2.wav"); 	// super shotgun
	
	precache_sound ("weapons/mfire1.wav");		// misfire
	precache_sound ("weapons/mfire2.wav");		// megaplasma burst misfire
	precache_sound ("weapons/plasma.wav");		// plasmagun fire
	precache_sound ("weapons/mplasma.wav");		// megaplasmagun fire
	precache_sound ("weapons/mplasex.wav");		// megaplasmagun explosion
	precache_sound ("weapons/gren.wav"); 		// super shotgun grenade fire
	precache_sound ("weapons/armed.wav");		// mine armed sound
	precache_sound ("weapons/minedet.wav"); 	//mine detonate click
	
	precache_sound ("weapons/rhino.wav");		//rhino firing sound
	precache_sound ("weapons/rhinore.wav"); 	//rhino reload sound
	precache_sound ("weapons/error.wav");		//weapon error sound
	
	precache_sound ("weapons/tsload.wav");		//t-shot load
	precache_sound ("weapons/tsfire.wav");		//t-shot single fire
	precache_sound ("weapons/ts3fire.wav"); 	//t-shot triple fire

	
	precache_sound ("weapons/shrapdet.wav");	//ShrapnelBomb detonation-confirmation beep

	/*
		Precached models
	*/
	precache_model ("progs/mwrub1.mdl"); 		//Shrapnel Model

/*
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

	// No weapon Death Model (weapons are dropped)
	precache_model ("progs/death_p.mdl");
*/
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	local	vector	source;
	local	vector	org;

	makevectors (@self.v_angle);
	source = @self.origin + '0 0 16';
	traceline (source, source + v_forward*64, FALSE, @self);
	if (trace_fraction == 1.0)
		return;
	
	org = trace_endpos - v_forward*4;

	if (trace_ent.takedamage) {
		trace_ent.axhitme = 1;
		SpawnBlood (org, 20);
		//if (deathmatch > 3)
		//	T_Damage (trace_ent, @self, @self, 75);
		//else
			T_Damage (trace_ent, @self, @self, 20);
	} else {	// hit wall
		sound (@self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);

		WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
		WriteByte (MSG_MULTICAST, TE_GUNSHOT);
		WriteByte (MSG_MULTICAST, 3);
		WriteCoord (MSG_MULTICAST, org_x);
		WriteCoord (MSG_MULTICAST, org_y);
		WriteCoord (MSG_MULTICAST, org_z);
		multicast (org, MULTICAST_PVS);
	}
};


//============================================================================

/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local entity	missile;

	missile = spawn ();
	missile.owner = @self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (@self.angles);

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

/*
================
SpawnBlood
================
*/
void(vector org, float damage) SpawnBlood =
{
	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);

	if (trace_ent.nobleed) {
		WriteByte (MSG_MULTICAST, TE_GUNSHOT);
		WriteByte (MSG_MULTICAST, 5);
	} else {
		WriteByte (MSG_MULTICAST, TE_BLOOD);
		WriteByte (MSG_MULTICAST, 1);
	}
	WriteCoord (MSG_MULTICAST, org_x);
	WriteCoord (MSG_MULTICAST, org_y);
	WriteCoord (MSG_MULTICAST, org_z);
	multicast (org, MULTICAST_PVS);
};


/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	
	SpawnBlood (@self.origin + vel*0.01, damage);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity	multi_ent;
float	multi_damage;

vector	blood_org;
float	blood_count;

vector	puff_org;
float	puff_count;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
	blood_count = 0;
	puff_count = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, @self, @self, multi_damage);
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

void() Multi_Finish =
{
	if (puff_count)
	{
		WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
		WriteByte (MSG_MULTICAST, TE_GUNSHOT);
		WriteByte (MSG_MULTICAST, puff_count);
		WriteCoord (MSG_MULTICAST, puff_org_x);
		WriteCoord (MSG_MULTICAST, puff_org_y);
		WriteCoord (MSG_MULTICAST, puff_org_z);
		multicast (puff_org, MULTICAST_PVS);
	}

	if (blood_count)
	{
		WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
		WriteByte (MSG_MULTICAST, TE_BLOOD);
		WriteByte (MSG_MULTICAST, blood_count);
		WriteCoord (MSG_MULTICAST, blood_org_x);
		WriteCoord (MSG_MULTICAST, blood_org_y);
		WriteCoord (MSG_MULTICAST, blood_org_z);
		multicast (puff_org, MULTICAST_PVS);
	}
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
	
	// + POX - added nobleed check
	if (trace_ent.takedamage && !trace_ent.nobleed)
	{
		blood_count = blood_count + 1;
		blood_org = org;
		AddMultiDamage (trace_ent, damage);
	}
	
	else if (trace_ent.takedamage && trace_ent.nobleed)
	{
		puff_count = puff_count + 1;
		puff_org = org;
		AddMultiDamage (trace_ent, damage);
	}
	// - POX
	
	else
	{
		puff_count = puff_count + 1;
	}
};

/* POX - for the tShot second trigger, half the bullets twice the damage
================
FireBullets2

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets2 =
{
	local	vector direction;
	local	vector	src;
	
	makevectors(@self.v_angle);

	src = @self.origin + v_forward*10;
	src_z = @self.absmin_z + @self.size_z * 0.7;

	ClearMultiDamage ();

	traceline (src, src + dir*2048, FALSE, @self);
	puff_org = trace_endpos - dir*4;

	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;
		traceline (src, src + direction*2048, FALSE, @self);
		if (trace_fraction != 1.0)
			TraceAttack (8, direction); //POX 4*2

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
	Multi_Finish ();
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
	
	makevectors(@self.v_angle);

	src = @self.origin + v_forward*10;
	src_z = @self.absmin_z + @self.size_z * 0.7;

	ClearMultiDamage ();

	traceline (src, src + dir*2048, FALSE, @self);
	puff_org = trace_endpos - dir*4;

	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;
		traceline (src, src + direction*2048, FALSE, @self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
	Multi_Finish ();
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	local vector dir;

	sound (@self, CHAN_WEAPON, "weapons/tsfire.wav", 1, ATTN_NORM);

	msg_entity = @self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
	
	//POX - May not need this (SVC_SMALLKICK?)
	if (@self.flags & FL_ONGROUND)
		@self.velocity = @self.velocity + v_forward* -35;

	@self.currentammo = @self.ammo_shells = @self.ammo_shells - 1;

	dir = aim (@self, 100000);
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
	if (@self.currentammo == 1)
	{
		bullets = 6;
		used = 1;
	}
		
	sound (@self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM); 

	msg_entity = @self;
	WriteByte (MSG_ONE, SVC_BIGKICK);
	
	if (@self.flags & FL_ONGROUND)
		@self.velocity = @self.velocity + v_forward* -60;
	
	//if (deathmatch != 4)
	@self.currentammo = @self.ammo_shells = @self.ammo_shells - used;
	
	dir = aim (@self, 100000);
	FireBullets (14, dir, '0.14 0.08 0');
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void() T_MissileTouch =
{
	local float	damg;

	if (other == @self.owner)
		return;		// don't explode on owner

	if (@self.voided) {
		return;
	}
	@self.voided = 1;

	if (pointcontents(@self.origin) == CONTENT_SKY)
	{
		remove(@self);
		return;
	}

	damg = 20 + random()*10;
	
	if (other.health)
	{
		other.deathtype = "rocket";
		T_Damage (other, @self, @self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact


	T_RadiusDamage (@self, @self.owner, 90, other, "rocket");

//  sound (@self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	@self.origin = @self.origin - 8 * normalize(@self.velocity);

	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte (MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord (MSG_MULTICAST, @self.origin_x);
	WriteCoord (MSG_MULTICAST, @self.origin_y);
	WriteCoord (MSG_MULTICAST, @self.origin_z);
	multicast (@self.origin, MULTICAST_PHS);

	remove(@self);
};



/*
================
W_FireRocket
================
*/
void(vector barrel) W_FireRocket =
{
	@self.currentammo = @self.ammo_rockets = @self.ammo_rockets - 0.5;
	
	//if player fired last rocket reset the reload bit
	if (@self.ammo_rockets == 0)
		@self.reload_rocket = 0;
	else //player has rockets left so ad 1 to reload count
		@self.reload_rocket = @self.reload_rocket + 1;
	
	newmis = spawn ();
	newmis.owner = @self;
	newmis.movetype = MOVETYPE_TOSS;
	newmis.solid = SOLID_BBOX;
		
// set newmis speed	

	makevectors (@self.v_angle);
	
	newmis.velocity = v_forward*1100 + v_up * 220 + v_right* -22;

	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = T_MissileTouch;
	
	newmis.voided = 0;
	
// set newmis duration
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	newmis.classname = "rocket";

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, @self.origin + v_forward* 8 + v_right* 12 + barrel);
};

//=============================================================================


void() GrenadeExplode =
{
	if (@self.voided) {
		return;
	}
	@self.voided = 1;

	T_RadiusDamage (@self, @self.owner, 120, world, "grenade");

	WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte (MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord (MSG_MULTICAST, @self.origin_x);
	WriteCoord (MSG_MULTICAST, @self.origin_y);
	WriteCoord (MSG_MULTICAST, @self.origin_z);
	multicast (@self.origin, MULTICAST_PHS);

	remove (@self);
};

void() GrenadeTouch =
{
	local	float	r;
	
	r=random();
	
	if (other == @self.owner)
		return;		// don't explode on owner
	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode();
		return;
	}
	
	//pick a bounce sound
	if (r < 0.75)
		sound (@self, CHAN_VOICE, "weapons/bounce.wav", 1, ATTN_NORM);
	else
		sound (@self, CHAN_VOICE, "weapons/bounce2.wav", 1, ATTN_NORM);
		
	if (@self.velocity == '0 0 0')
		@self.avelocity = '0 0 0';
};

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{	
	@self.currentammo = @self.ammo_rockets = @self.ammo_rockets - 1;
	
	sound (@self, CHAN_WEAPON, "weapons/gren.wav", 1, ATTN_NORM);

	msg_entity = @self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
	
	if (@self.flags & FL_ONGROUND)
		@self.velocity = @self.velocity + v_forward* -75;

	newmis = spawn ();
	newmis.voided=0;
	newmis.owner = @self;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "grenade";
		
// set newmis speed	

	makevectors (@self.v_angle);

	if (@self.v_angle_x)
		newmis.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		newmis.velocity = aim(@self, 10000);
		newmis.velocity = newmis.velocity * 600;
		newmis.velocity_z = 200;
	}

	newmis.avelocity = '300 300 300';

	newmis.angles = vectoangles(newmis.velocity);
	
	newmis.touch = GrenadeTouch;
	

	newmis.nextthink = time + 2.5;

	newmis.think = GrenadeExplode;

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, @self.origin);
};


//=============================================================================
// + POX - Plasma

void() plasma_touch =
{
	if (other == @self.owner)
		return;

	if (@self.voided) {
		return;
	}
	@self.voided = 1;

	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing

	if (pointcontents(@self.origin) == CONTENT_SKY)
	{
		remove(@self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (7);
		other.deathtype = "plasma";
		T_Damage (other, @self, @self.owner, 7);
	}
	else
	{
		WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
		WriteByte (MSG_MULTICAST, TE_SPIKE);
		WriteCoord (MSG_MULTICAST, @self.origin_x);
		WriteCoord (MSG_MULTICAST, @self.origin_y);
		WriteCoord (MSG_MULTICAST, @self.origin_z);
		multicast (@self.origin, MULTICAST_PHS);
	}

	remove(@self);

};

void(vector org, vector dir) launch_plasma =
{
	newmis = spawn ();
	newmis.voided=0;
	newmis.owner = @self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = plasma_touch;
	newmis.classname = "plasma";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 5;
	setmodel (newmis, "progs/laser.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1400;
};

void(float ox) W_FirePlasma =
{
	local vector	dir;
	
	makevectors (@self.v_angle);
	
	sound (@self, CHAN_WEAPON, "weapons/plasma.wav", 1, ATTN_NORM);
	
	@self.currentammo = @self.ammo_cells = @self.ammo_cells - 1;

	dir = aim (@self, 1000);
	
	launch_plasma (@self.origin + v_forward*12 + '0 0 12' + v_right*ox, dir);

	msg_entity = @self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
};

// - POX - Plasma
//===========================================================================

void() spike_touch =
{
	if (@self.voided) {
		return;
	}
	@self.voided = 1;

	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing

	if (pointcontents (@self.origin) == CONTENT_SKY) {
		remove (@self);
		return;
	}
	
	// hit something that bleeds
	if (other.takedamage) {
		spawn_touchblood (9);
		other.deathtype = "nail";
		T_Damage (other, @self, @self.owner, 9);
	} else {
		WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
		WriteByte (MSG_MULTICAST, TE_SPIKE);
		WriteCoord (MSG_MULTICAST, @self.origin_x);
		WriteCoord (MSG_MULTICAST, @self.origin_y);
		WriteCoord (MSG_MULTICAST, @self.origin_z);
		multicast (@self.origin, MULTICAST_PHS);
	}

	remove (@self);
};

void() superspike_touch =
{
	if (@self.voided) {
		return;
	}
	@self.voided = 1;

	if (other.solid == SOLID_TRIGGER)
		return; // trigger field, do nothing

	if (pointcontents (@self.origin) == CONTENT_SKY) {
		remove (@self);
		return;
	}
	
	// hit something that bleeds
	if (other.takedamage) {
		spawn_touchblood (18);
		other.deathtype = "supernail";
		T_Damage (other, @self, @self.owner, 18);
	} else {
		WriteByte (MSG_MULTICAST, SVC_TEMPENTITY);
		WriteByte (MSG_MULTICAST, TE_SUPERSPIKE);
		WriteCoord (MSG_MULTICAST, @self.origin_x);
		WriteCoord (MSG_MULTICAST, @self.origin_y);
		WriteCoord (MSG_MULTICAST, @self.origin_z);
		multicast (@self.origin, MULTICAST_PHS);
	}

	remove (@self);
};



/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.voided=0;
	newmis.owner = @self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

void(float ox) W_FireNails =
{
	local vector	dir;
	
	makevectors (@self.v_angle);
	
	@self.weaponmodel = "progs/v_nailgl.mdl"; // light up nailgun barrels
	
	sound (@self, CHAN_WEAPON, "weapons/hog.wav", 0.8, ATTN_NORM);
	
	@self.currentammo = @self.ammo_nails = @self.ammo_nails - 1;
	
	dir = aim (@self, 1000);
	launch_spike (@self.origin + '0 0 16' + v_right*ox, dir);

	msg_entity = @self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
};

// POX - not used by players...but maybe traps (?)
void() W_FireSuperSpikes =
{
	local vector	dir;
	
	sound (@self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	@self.attack_finished = time + 0.2;
	//if (deathmatch != 4) 
		@self.currentammo = @self.ammo_nails = @self.ammo_nails - 2;
	dir = aim (@self, 1000);
	launch_spike (@self.origin + '0 0 16', dir);
	newmis.touch = superspike_touch;
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	msg_entity = @self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
};

void(float ox) W_FireSpikes =
{
	local vector	dir;
	
	makevectors (@self.v_angle);
	
	if (@self.ammo_nails >= 2 && @self.weapon == IT_SUPER_NAILGUN) {
		W_FireSuperSpikes ();
		return;
	}

	if (@self.ammo_nails < 1) {
		@self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	sound (@self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	@self.attack_finished = time + 0.2;

	@self.currentammo = --@self.ammo_nails;

	dir = aim (@self, 1000);
	launch_spike (@self.origin + '0 0 16' + v_right * ox, dir);

	msg_entity = @self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
};


// - POX ?
//.float hit_z;

/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/
// + POX - changed weapon models, added ammo check for ComboGun
void() W_SetCurrentAmmo =
{
	player_run ();		// get out of any weapon firing states

	@self.items &= ~(IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS);
	@self.weaponframe = 0;

	switch (@self.weapon) {
		case IT_AXE:
			@self.weaponmodel = "progs/v_axe.mdl";
			@self.currentammo = 0;
			break;
		case IT_TSHOT:
			@self.weaponmodel = "progs/v_tshot.mdl";
			@self.currentammo = @self.ammo_shells;
			@self.items |= IT_SHELLS;
			break;
		case IT_COMBOGUN:
			@self.weaponmodel = "progs/v_combo.mdl";
			// ammo depends on last active trigger
			if (@self.which_ammo == 1 && @self.ammo_rockets > 0) {
				@self.currentammo = @self.ammo_rockets;
				@self.items |= IT_ROCKETS;
			} else {
				@self.which_ammo = 0;
				@self.currentammo = @self.ammo_shells;
				@self.items |= IT_SHELLS;
			}
			break;
		case IT_PLASMAGUN:
			@self.weaponmodel = "progs/v_plasma.mdl";
			@self.currentammo = @self.ammo_cells;
			@self.items |= IT_CELLS;
			break;
		case IT_SUPER_NAILGUN:
			@self.weaponmodel = "progs/v_nailg.mdl";
			@self.currentammo = @self.ammo_nails;
			@self.items |= IT_NAILS;
			break;
		case IT_GRENADE_LAUNCHER:
			@self.weaponmodel = "progs/v_gren.mdl";
			@self.currentammo = @self.ammo_rockets;
			@self.items |= IT_ROCKETS;
			break;
		case IT_ROCKET_LAUNCHER:
			@self.weaponmodel = "progs/v_rhino.mdl";
			@self.currentammo = @self.ammo_rockets;
			@self.items |= IT_ROCKETS;
			break;
		default:
			@self.weaponmodel = "";
			@self.currentammo = 0;
	}
};

float() W_BestWeapon =
{
	local float		it = @self.items;

	// A hacky way to keep Super Shotgun active when out of rockets
	if ((@self.weapon == IT_COMBOGUN) && (@self.ammo_shells >= 2 && (@self.ammo_rockets < 1)))
		return IT_COMBOGUN;

	if (@self.ammo_rockets > 0 && (it & IT_ROCKET_LAUNCHER))
		return IT_ROCKET_LAUNCHER;

	if (@self.ammo_cells > 0 && (it & IT_PLASMAGUN))
		return IT_PLASMAGUN;

	if (@self.ammo_nails > 0 && (it & IT_SUPER_NAILGUN))
		return IT_SUPER_NAILGUN;

	if (@self.ammo_shells > 1 && (it & IT_COMBOGUN))
		return IT_COMBOGUN;

	if (@self.ammo_shells > 0 && (it & IT_TSHOT))
		return IT_TSHOT;

	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (@self.currentammo > 0)
		return TRUE;

	if (@self.weapon == IT_AXE)
		return TRUE;
	
	@self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();
	
	// drop the weapon down
	return FALSE;
};

/* POX - in sync with Paroxysm v1.1
============
W_Attack

An attack impulse can be triggered now
============
*/

void() W_Attack =
{
	local float		r;
	
	if (intermission_running)
		return;
	
	if (deathmatch & DM_AUTOSWITCH) {
		if (!W_CheckNoAmmo ())
			return;
	}

	makevectors	(@self.v_angle);		// calculate forward angle for velocity
	@self.show_hostile = time + 1;	// wake monsters up

	switch (@self.weapon) {
		case IT_AXE:
			@self.attack_finished = time + 0.5;
			sound (@self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);

			r = random ();
			if (r < 0.25)
				player_axe1 ();
			else if (r < 0.5)
				player_axeb1 ();
			else if (r < 0.75)
				player_axec1 ();
			else
				player_axed1 ();
			return;

		case IT_TSHOT:
			if (@self.ammo_shells < 1) {
				sound (@self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
				@self.attack_finished = time + 0.5;
				return;
			}

			if (@self.st_tshotload > time)	// T-Shot still priming
				return;

			if ((@self.prime_tshot) && (@self.ammo_shells > 2)) {	// OK for triple
				player_tshot1 ();
				W_FireTShot ();
				@self.attack_finished = time + 0.7;
			} else {	// Normal shot
				player_shot1 ();
				W_FireShotgun ();
				@self.attack_finished = time + 0.5;
			}

			// reset prime
			@self.prime_tshot = FALSE;
			return;

		case IT_COMBOGUN:
			if (@self.st_sshotgun > time)
				return;

			@self.items &= ~IT_ROCKETS;
			@self.items |= IT_SHELLS;

			@self.currentammo = @self.ammo_shells;
			@self.which_ammo = 0;

			if (@self.ammo_shells < 1) {	// misfire
				sound (@self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
				@self.st_sshotgun = time + 0.7;
				return;
			}

			player_shot1 ();
			W_FireSuperShotgun ();
			@self.st_sshotgun = time + 0.7;
			return;

		case IT_PLASMAGUN:
			if ((@self.st_plasma > time) || (@self.st_mplasma > time))
				return;
			
			if (@self.ammo_cells < 1) {
				sound (@self, CHAN_AUTO, "weapons/mfire2.wav", 1, ATTN_NORM);
				return;
			}

			if (!@self.LorR)	// which barrel is supposed to fire?
				player_plasma1 ();
			else
				player_plasma2 ();

			return;

		case IT_SUPER_NAILGUN:
			if (@self.st_nailgun > time)
				return;

			if (@self.ammo_nails < 1) {
				sound (@self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
				return;
			}
			
			player_nail1 ();
			return;

		case IT_GRENADE_LAUNCHER:
			if (@self.st_grenade > time)
				return;
			
			if (@self.ammo_rockets < 1) {
				sound (@self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
				@self.st_grenade = time + 0.6;
				return;
			}

			player_grenade1 ();
			W_FireGrenade ();
			@self.st_grenade = time + 0.6;
			return;

		case IT_ROCKET_LAUNCHER:
			if (@self.st_rocketload > time) // still reloading
				return;

			if (@self.ammo_rockets < 1) {	// no ammo
				sound (@self, CHAN_AUTO, "weapons/mfire1.wav", 1, ATTN_NORM);
				@self.attack_finished = time + 0.4;
				return;
			}

			if (@self.reload_rocket > 6) {
				sound (@self, CHAN_AUTO, "weapons/error.wav", 1, ATTN_NORM);
				@self.attack_finished = time + 0.42;
				return;
			}

			player_rocket1 ();
			@self.attack_finished = time + 0.4;
			return;
	}
};

/* POX - in sync with Paroxysm v1.1
============
W_ChangeWeapon
============
*/
void() W_ChangeWeapon =
{
	local float	no_ammo = 0;
	local float selected = NIL;

	@self.which_ammo = 0; // Default ammo to shells for SuperShotgun

	switch (@self.impulse) {
		case 1:
			selected = IT_AXE;
			break;
		case 2:
			selected = IT_TSHOT;
			if (@self.ammo_shells < 1)
				no_ammo = 1;
			break;
		case 3:
			selected = IT_COMBOGUN;
			if (@self.ammo_shells < 2) {
				no_ammo = 1;
				// allow player to still select SuperShotgun if he has rockets
				if (@self.ammo_rockets > 0 && (!(deathmatch & DM_AUTOSWITCH))) {
					@self.which_ammo = 1;	// tell W_SetCurrentAmmo to use rockets, not shells
					no_ammo = 0;
				}
			}
			break;
		case 4:
			selected = IT_PLASMAGUN;
			if (@self.ammo_cells < 1)
				no_ammo = 1;
			break;
		case 5:
			selected = IT_SUPER_NAILGUN;
			if (@self.ammo_nails < 2)
				no_ammo = 1;
			break;
		case 6:
			selected = IT_GRENADE_LAUNCHER;
			if (@self.ammo_rockets < 1)
				no_ammo = 1;
			break;
		case 7:
			selected = IT_ROCKET_LAUNCHER;
			if (@self.ammo_rockets < 1)
				no_ammo = 1;
			break;
	}

	@self.impulse = 0;

	if (!(@self.items & selected)) {	// don't have the weapon or the ammo
		sprint (@self, PRINT_HIGH, "no weapon.\n");
		return;
	}

	if (no_ammo) {	// don't have the ammo
		sprint (@self, PRINT_HIGH, "not enough ammo.\n");
		return;
	}

//
// set weapon, set ammo
//
	@self.weapon = selected;		
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
//	if (deathmatch || coop)
		return;
};

/* + POX - in sync with Paroxysm v1.1 - changed BONESAW back to AXE
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void () CycleWeaponCommand =
{
	local float		am;
	
	@self.impulse = 0;
	
	while (1) {
		am = 0;
		@self.which_ammo = 0;  // Default ammo to shells for SuperShotgun

		switch (@self.weapon) {
			case IT_ROCKET_LAUNCHER:
				@self.weapon = IT_AXE;
				break;
			case IT_AXE:
				@self.weapon = IT_TSHOT;
				if (@self.ammo_shells < 1)
					am = 1;
				break;
			case IT_TSHOT:
				@self.weapon = IT_COMBOGUN;
				if (@self.ammo_shells < 2) {
					am = 1;
					// allow player to select SuperShotgun if he has rockets
					if (@self.ammo_rockets > 0 && (!(deathmatch & DM_AUTOSWITCH))) {
						@self.which_ammo = 1;	// tell W_SetCurrentAmmo to use rockets, not shells
						am = 0;
					}
				}
				break;
			case IT_COMBOGUN:
				@self.weapon = IT_PLASMAGUN;
				if (@self.ammo_cells < 1)
					am = 1;
				break;
			case IT_PLASMAGUN:
				@self.weapon = IT_SUPER_NAILGUN;
				if (@self.ammo_nails < 2)
					am = 1;
				break;
			case IT_SUPER_NAILGUN:
				@self.weapon = IT_GRENADE_LAUNCHER;
				if (@self.ammo_rockets < 1)
					am = 1;
				break;
			case IT_GRENADE_LAUNCHER:
				@self.weapon = IT_ROCKET_LAUNCHER;
				if (@self.ammo_rockets < 1)
					am = 1;
				break;
		}

		if ((@self.items & @self.weapon) && am == 0) {
			W_SetCurrentAmmo ();
			return;
		}
	}
};


/* + POX - in sync with Paroxysm v1.1 - *went back to AXE for QW
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local	float	am;
	
	@self.impulse = 0;

	while (1) {
		am = 0;
		@self.which_ammo = 0;  // Default ammo to shells for SuperShotgun

		if (@self.weapon == IT_ROCKET_LAUNCHER) {
			@self.weapon = IT_GRENADE_LAUNCHER;
			if (@self.ammo_rockets < 1)
				am = 1;
		} else if (@self.weapon == IT_GRENADE_LAUNCHER) {
			@self.weapon = IT_SUPER_NAILGUN;
			if (@self.ammo_nails < 2)
				am = 1;
		} else if (@self.weapon == IT_SUPER_NAILGUN) {
			@self.weapon = IT_PLASMAGUN;
			if (@self.ammo_cells < 1)
				am = 1;
		} else if (@self.weapon == IT_PLASMAGUN) {
			@self.weapon = IT_COMBOGUN;
			
			// allow player to select ComboGun if he has rockets
			// BUT NOT IF DM_AUTOSWITCH!!
			if (@self.ammo_shells < 2) {
				am = 1;
				if (@self.ammo_rockets > 0 && !(deathmatch & DM_AUTOSWITCH)) {
					@self.which_ammo = 1; // tell W_SetCurrentAmmo to use rockets - not shells
					am = 0;
				}
			}
		} else if (@self.weapon == IT_COMBOGUN) {
			@self.weapon = IT_TSHOT;
			if (@self.ammo_shells < 1)
				am = 1;
		} else if (@self.weapon == IT_TSHOT) {
			@self.weapon = IT_AXE;
		} else if (@self.weapon == IT_AXE) {
			@self.weapon = IT_ROCKET_LAUNCHER;
			if (@self.ammo_rockets < 1)
				am = 1;
		}
	
		if ((@self.items & @self.weapon) && am == 0) {
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

// + POX - Displays the server rules
void() DisplayRules =
{
	sprint (@self, PRINT_HIGH, "\nÓåòöåò Òõìåó\n----------------------\n    |\n");
		
		if (deathmatch & DM_PREDATOR)
			sprint (@self, PRINT_HIGH, "on  | Predator Mode\n");
		else
			sprint (@self, PRINT_HIGH, "ÏÆÆ | Predator Mode\n");
		
		if (deathmatch & DM_DARK)
			sprint (@self, PRINT_HIGH, "on  | Dark Mode\n");
		else
			sprint (@self, PRINT_HIGH, "ÏÆÆ | Dark Mode\n");
			
		if (deathmatch & DM_LMS)
			sprint (@self, PRINT_HIGH, "on  | Last Man Standing\n");
		else
			sprint (@self, PRINT_HIGH, "ÏÆÆ | Last Man Standing\n");
		
		if (deathmatch & DM_FFA)
			sprint (@self, PRINT_HIGH, "on  | Free For All\n");
		else
			sprint (@self, PRINT_HIGH, "ÏÆÆ | Free For All\n");
		
		if (deathmatch & DM_GIB)
			sprint (@self, PRINT_HIGH, "on  | Gib\n");
		else
			sprint (@self, PRINT_HIGH, "ÏÆÆ | Gib\n");
		
		if (deathmatch & DM_AUTOSWITCH)
			sprint (@self, PRINT_HIGH, "on  | Weapon Autoswitch\n	|\n----------------------\n\n");
		else
			sprint (@self, PRINT_HIGH, "ÏÆÆ | Weapon Autoswitch\n	|\n----------------------\n\n");

};



/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	switch (@self.impulse) {
		case 1:
		case 2:
		case 3:
		case 4:
		case 5:
		case 6:
		case 7:
		case 8:
			W_ChangeWeapon ();
			break;
		case 9:
			CheatCommand ();
			break;
		case 10:
			CycleWeaponCommand ();
			break;
		case 11:
			ServerflagsCommand ();
			break;
		case 12:
			CycleWeaponReverseCommand ();
			break;
		case 16:	// target identifier
			@self.target_id_temp = TRUE;	// Make it work across level change
			stuffcmd (@self, "play misc/talk.wav\n"); // audio confirmation
		
			if (@self.target_id_toggle) {
				@self.target_id_toggle = FALSE;
			
				// don't centerprint if a message is up
				if (@self.target_id_finished < time)
					centerprint (@self, "Target Identifier OFF\n");
				else
					sprint (@self, PRINT_HIGH, "Target Identifier OFF\n");
			} else {
				@self.target_id_toggle = TRUE;

				// don't centerprint if a message is up
				if (@self.target_id_finished < time)
					centerprint (@self, "Target Identifier ON\n");
				else
					sprint (@self, PRINT_HIGH, "Target Identifier ON\n");

				@self.target_id_finished = time + 3;		
			}
			break;
		case 17:	// FIXME - Toggle dlights vs lightglows
			if(@self.gl_fix) {
				stuffcmd (@self, "gl_flashblend 1\n");
				@self.gl_fix = FALSE;
			} else {
				stuffcmd (@self, "gl_flashblend 0\n");
				@self.gl_fix = TRUE;
			}
			break;

		case 253:	// Display Server Game Modes
			DisplayRules ();
			break;
	}

	@self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
	if (time < @self.attack_finished)
		return;
	
	//POX - v1.1 target identifier
	if (@self.target_id_toggle && (time > @self.target_id_finished))
		ID_CheckTarget ();
	
	//POX - Don't swap nailgun skins if player is invisible or chascam is active!
	if (@self.weapon == IT_SUPER_NAILGUN && @self.st_nailgun < time)
		@self.weaponmodel = "progs/v_nailg.mdl"; // cool off nailgun barrels

// + POX - only check these if necessary (thanks to URQW patch)
// 1998-08-14 Constantly checking all impulses fix by Perged
	if (@self.impulse == SECOND_TRIGGER)
		W_SecondTrigger ();
	else if (@self.impulse)
	    ImpulseCommands ();
// - POX	
	
// check for attack
	if (@self.button0)
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
	if (@self.super_damage_finished > time)
	{
		if (@self.super_sound < time)
		{
			@self.super_sound = time + 1;
			sound (@self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
};


