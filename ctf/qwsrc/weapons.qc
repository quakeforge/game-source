/*
	weapons.qc

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

	$Id$
*/

void () player_chain1; // prototype from player.qc
void () player_chain3; // prototype from player.qc

void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void (entity bomb, entity attacker, float rad, entity ignore) T_RadiusDamage;
void (vector org, float damage) SpawnBlood;
void () SuperDamageSound;
void () HasteSound;
void () PreviousWeaponCommand;

// called by worldspawn
void()
W_Precache =
{
	precache_sound ("hknight/hit.wav");  // flamethrower
	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");	// player shotgun
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");	// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");	// super shotgun

	// grapple sounds (wedge)
	precache_sound ("weapons/chain1.wav");
	precache_sound ("weapons/chain2.wav");
	precache_sound ("weapons/chain3.wav");
	precache_sound ("weapons/bounce2.wav");
	precache_sound ("blob/land1.wav");

	// ZOID:
	// normally the weapon models are precached in the individual item
	// creation routines.  But since we've added impulse 21 we can drop
	// weapons at any time.  Must precache all weapon models.
	precache_model ("progs/g_shot.mdl");
	precache_model ("progs/g_nail.mdl");
	precache_model ("progs/g_nail2.mdl");
	precache_model ("progs/g_rock.mdl");
	precache_model ("progs/g_rock2.mdl");
	precache_model ("progs/g_light.mdl");
};

float ()
crandom =
{
	return 2 * (random () - 0.5);
};

void()
W_FireAxe =
{
	local vector	org, source;

	makevectors (self.v_angle);
	source = self.origin + '0 0 16';
	traceline (source, source + v_forward * 64, FALSE, self);
	if (trace_fraction == 1.0)
		return;

	org = trace_endpos - v_forward * 4;

	if (trace_ent.takedamage) {
		trace_ent.axhitme = 1;
		SpawnBlood (org, 20);
		T_Damage (trace_ent, self, self, 20);
	} else {	// hit wall
        sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);

		WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_GUNSHOT, 3.0);
		WriteCoordV (MSG_MULTICAST, org);
		multicast (org, MULTICAST_PVS);
	}
};

//============================================================================

vector()
wall_velocity =
{
	local vector	vel;

	vel = normalize (self.velocity);
	vel = normalize (vel + v_up * (random () - 0.5) +
					 v_right * (random () - 0.5));
	vel += 2 * trace_plane_normal;
	vel *= 200;

	return vel;
};

void (vector org, vector vel)
SpawnMeatSpray =
{
	local entity	missile;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50 * random ();

	missile.avelocity = '3000 1000 2000';

	// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, org);
};

void (vector org, float damage)
SpawnBlood =
{
	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_BLOOD, 1.0);
	WriteCoordV (MSG_MULTICAST, org);
	multicast (org, MULTICAST_PVS);
};

void (float damage)
spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel * 0.01, damage);
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

void ()
ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
	blood_count = 0;
	puff_count = 0;
};

void ()
ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage);
};

void (entity hit, float damage)
AddMultiDamage =
{
	if (!hit)
		return;

	if (hit != multi_ent) {
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	} else
		multi_damage = multi_damage + damage;
};

void ()
Multi_Finish =
{
	if (puff_count) {
		WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_GUNSHOT, puff_count);
		WriteCoordV (MSG_MULTICAST, puff_org);
		multicast (puff_org, MULTICAST_PVS);
	}

	if (blood_count) {
		WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_BLOOD, blood_count);
		WriteCoordV (MSG_MULTICAST, blood_org);
		multicast (puff_org, MULTICAST_PVS);
	}
};

// BULLETS ====================================================================

void (float damage, vector dir)
TraceAttack =
{
	local vector	vel, org;

	vel = normalize (dir + v_up * crandom () + v_right * crandom ());
	vel += 2 * trace_plane_normal;
	vel *= 200;

	org = trace_endpos - dir * 4;

	if (trace_ent.takedamage) {
		blood_count++;
		blood_org = org;
		AddMultiDamage (trace_ent, damage);
	} else {
 		puff_count++;
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void (float shotcount, vector dir, vector spread)
FireBullets =
{
	local vector	direction, src;

	makevectors (self.v_angle);

	src = self.origin + v_forward * 10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();

 	traceline (src, src + dir * 2048, FALSE, self);
 	puff_org = trace_endpos - dir * 4;

	while (shotcount > 0) {
 		direction = dir + crandom () * spread_x * v_right +
			crandom () * spread_y * v_up;

		traceline (src, src + direction * 2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
	Multi_Finish ();
};

void ()
W_FireShotgun =
{
	local vector	dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);	

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);

	self.currentammo = --self.ammo_shells;
	dir = aim (self, 100000);
	FireBullets (6, dir, '0.04 0.04 0');
};

void ()
W_FireSuperShotgun =
{
	local vector	dir;

	if (self.currentammo == 1) {
		W_FireShotgun ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_BIGKICK);

	self.currentammo = self.ammo_shells -= 2;
	dir = aim (self, 100000);
	FireBullets (14, dir, '0.14 0.08 0');
};

// ROCKETS ====================================================================

void ()
T_MissileTouch =
{
	local float		damg;

	if (other == self.owner)
		return;		// don't explode on owner
	if (self.cnt)
		return;

	self.cnt = 1;
	if (pointcontents (self.origin) == CONTENT_SKY) {
		remove (self);
		return;
	}

	damg = 100 + 20 * random ();

	if (other.health) {
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 120, other);

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8 * normalize (self.velocity);

	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_EXPLOSION);
	WriteCoordV (MSG_MULTICAST, self.origin);
	multicast (self.origin, MULTICAST_PHS);

	remove (self);
};

void ()
W_FireRocket =
{
	self.currentammo = --self.ammo_rockets;

	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);

	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "missile";
	newmis.cnt = 0;

	// set newmis speed	
	makevectors (self.v_angle);
	newmis.velocity = aim (self, 1000);
	newmis.velocity *= 1000;
	newmis.angles = vectoangles (newmis.velocity);

	newmis.touch = T_MissileTouch;

	// set newmis duration
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;

	setmodel (newmis, "progs/missile.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, self.origin + v_forward * 8 + '0 0 16');
};

// LIGHTNING ==================================================================

void (entity from, float damage)
LightningHit =
{
	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_LIGHTNINGBLOOD);
	WriteCoordV (MSG_MULTICAST, trace_endpos);
	multicast (trace_endpos, MULTICAST_PVS);

	T_Damage (trace_ent, from, from, damage);
};

void (vector p1, vector p2, entity from, float damage)
LightningDamage =
{
	local entity	e1, e2;
	local vector	f;

	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f *= 16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
	if (trace_ent.takedamage) {
		LightningHit (from, damage);
		if (self.classname == "player") {
			if (other.classname == "player")
				trace_ent.velocity_z += 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
	if (trace_ent != e1 && trace_ent.takedamage) {
		LightningHit (from, damage);
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage) {
		LightningHit (from, damage);
	}
};

void ()
W_FireLightning =
{
	local float		cells;
	local vector	org;

	if (self.ammo_cells < 1) {
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	// explode if under water
	if (self.waterlevel > 1) {
		cells = self.ammo_cells;
		self.ammo_cells = 0;
		W_SetCurrentAmmo ();
		T_RadiusDamage (self, self, 35 * cells, world);
		return;
	}

	if (self.t_width < time) {
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);

	self.currentammo = --self.ammo_cells;

	org = self.origin + '0 0 16';

	traceline (org, org + v_forward * 600, TRUE, self);

	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_LIGHTNING2);
	WriteEntity (MSG_MULTICAST, self);
	WriteCoordV (MSG_MULTICAST, org);
	WriteCoordV (MSG_MULTICAST, trace_endpos);
	multicast (org, MULTICAST_PHS);

	LightningDamage (self.origin, trace_endpos + v_forward * 4, self, 30);
};

//=============================================================================

void ()
GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 120, world);

	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_EXPLOSION);
	WriteCoordV (MSG_MULTICAST, self.origin);
	multicast (self.origin, MULTICAST_PHS);

	remove (self);
};

void ()
GrenadeTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner
	if (self.cnt)
		return;

	if (other.takedamage == DAMAGE_AIM) {
		self.cnt = 1;
		GrenadeExplode ();
		return;
	}

	// bounce sound
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

void ()
W_FireGrenade =
{	
	self.currentammo = --self.ammo_rockets;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);

	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.classname = "grenade";
	newmis.cnt = 0;

	// set newmis speed	
	makevectors (self.v_angle);

	if (self.v_angle_x)
		newmis.velocity = v_forward * 600 + v_up * 200 + 10 *
			(v_right * crandom () + v_up * crandom ());
	else {
		newmis.velocity = aim (self, 10000);
		newmis.velocity *= 600;
		newmis.velocity_z = 200;
	}

	newmis.avelocity = '300 300 300';

	newmis.angles = vectoangles (newmis.velocity);

	newmis.touch = GrenadeTouch;

	// set newmis duration
	newmis.nextthink = time + 2.5;
	newmis.think = GrenadeExplode;

	setmodel (newmis, "progs/grenade.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		
	setorigin (newmis, self.origin);
};

//=============================================================================

void() spike_touch;
void() superspike_touch;

/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void (vector org, vector dir)
launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.cnt = 0;

	newmis.angles = vectoangles (dir);
	
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

void ()
W_FireSuperSpikes =
{
	local vector	dir;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_nails = self.ammo_nails - 2;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16', dir);
	newmis.touch = superspike_touch;
	newmis.classname = "spike";
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
};

void (float ox)
W_FireSpikes =
{
	local vector	dir;

	makevectors (self.v_angle);

	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN) {
		W_FireSuperSpikes ();
		return;
	}

	if (self.ammo_nails < 1) {
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = --self.ammo_nails;
	dir = aim (self, 1000);
	launch_spike (self.origin + '0 0 16' + v_right * ox, dir);

	msg_entity = self;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
};

.float hit_z;
void() spike_touch =
{
	if (other == self.owner)
		return;
	if (self.cnt)
		return;
	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	self.cnt = 1;

	if (pointcontents (self.origin) == CONTENT_SKY) {
		remove (self);
		return;
	}

	// hit something that bleeds
	if (other.takedamage) {
		spawn_touchblood (9);
		T_Damage (other, self, self.owner, 9);
	} else {
		local float		foo = TE_SPIKE;

		switch (self.classname) {
		case "wizspike":
			foo = TE_WIZSPIKE;
			break;
		case "knightspike":
			foo = TE_KNIGHTSPIKE;
			break;
		default:
//			foo = TE_SPIKE;
			break;
		}

		WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, foo);
		WriteCoordV (MSG_MULTICAST, self.origin);
		multicast (self.origin, MULTICAST_PHS);
	}

	remove (self);
};

void ()
superspike_touch =
{
	if (other == self.owner)
		return;
	if (self.cnt)
		return;
	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	self.cnt = 1;

	if (pointcontents (self.origin) == CONTENT_SKY) {
		remove (self);
		return;
	}

	// hit something that bleeds
	if (other.takedamage) {
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18);
	} else {
		WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_SUPERSPIKE);
		WriteCoordV (MSG_MULTICAST, self.origin);
		multicast (self.origin, MULTICAST_PHS);
	}

	remove (self);
};

// PLAYER WEAPON USE ==========================================================

void ()
W_SetCurrentAmmo =
{
	player_run ();		// get out of any weapon firing states

	self.items &= ~(IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS);

	switch (self.weapon) {
	case IT_AXE:
		self.currentammo = 0;
		self.weaponmodel = "progs/v_axe.mdl";
		self.weaponframe = 0;
		break;
	case IT_GRAPPLE:
		self.currentammo = 0;
		self.weaponmodel = "progs/v_star.mdl";
		self.weaponframe = 0;
		break;
	case IT_SHOTGUN:
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot.mdl";
		self.weaponframe = 0;
		self.items |= IT_SHELLS;
		break;
	case IT_SUPER_SHOTGUN:
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items |= IT_SHELLS;
		break;
	case IT_NAILGUN:
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.items |= IT_NAILS;
		break;
	case IT_SUPER_NAILGUN:
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.items |= IT_NAILS;
		break;
	case IT_GRENADE_LAUNCHER:
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
		break;
	case IT_ROCKET_LAUNCHER:
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items |= IT_ROCKETS;
		break;
	case IT_LIGHTNING:
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items |= IT_CELLS;
		break;
	default:
		self.currentammo = 0;
		self.weaponmodel = "";
		self.weaponframe = 0;
		break;
	}
};

float ()
W_BestWeapon =
{
	local float		it;

	it = self.items;

	if ((self.waterlevel <= 1) && (self.ammo_cells >= 1)
		&& (it & IT_LIGHTNING))
		return IT_LIGHTNING;
	else if ((self.ammo_nails >= 2) && (it & IT_SUPER_NAILGUN))
		return IT_SUPER_NAILGUN;
	else if ((self.ammo_shells >= 2) && (it & IT_SUPER_SHOTGUN))
		return IT_SUPER_SHOTGUN;
	else if ((self.ammo_nails >= 1) && (it & IT_NAILGUN))
		return IT_NAILGUN;
	else if ((self.ammo_shells >= 1) && (it & IT_SHOTGUN))
		return IT_SHOTGUN;
/*
	if ((self.ammo_rockets >= 1) && (it & IT_ROCKET_LAUNCHER))
		return IT_ROCKET_LAUNCHER;
	else if ((self.ammo_rockets >= 1) && (it & IT_GRENADE_LAUNCHER))
		return IT_GRENADE_LAUNCHER;
*/
	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;
	if (self.weapon == IT_AXE)
		return TRUE;
	if (self.weapon == IT_GRAPPLE)
		return TRUE;

	self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();

	// drop the weapon down
	return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;
void()	player_shot1;
void()	player_nail1;
void()	player_light1;
void()	player_rocket1;

void ()
W_Attack =
{
	local float		r;

	if (!W_CheckNoAmmo ())
		return;

	makevectors	(self.v_angle);			// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up

	switch (self.weapon) {
	case IT_GRAPPLE:
		if (self.hook_out)
			player_chain3 ();
		else
			player_chain1 ();
		self.attack_finished = time + 0.1;
		break;
	case IT_AXE:
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
		r = random ();
		if (r < 0.25)
			player_axe1 ();
		else if (r < 0.5)
			player_axeb1 ();
		else if (r < 0.75)
			player_axec1 ();
		else
			player_axed1 ();
		// RUNE: rune of hell magic
		if (self.player_flag & ITEM_RUNE3_FLAG) {
			self.attack_finished = time + 0.3;
			HasteSound ();
		} else
			self.attack_finished = time + 0.5;
		break;
	case IT_SHOTGUN:
		player_shot1 ();
		W_FireShotgun ();
		// RUNE: rune of hell magic
		if (self.player_flag & ITEM_RUNE3_FLAG) {
			self.attack_finished = time + 0.3;
			HasteSound ();
		} else
			self.attack_finished = time + 0.5;
		break;
	case IT_SUPER_SHOTGUN:
		player_shot1 ();
		W_FireSuperShotgun ();
		// RUNE: rune of hell magic
		if (self.player_flag & ITEM_RUNE3_FLAG) {
			self.attack_finished = time + 0.4;
			HasteSound ();
		} else
			self.attack_finished = time + 0.7;
		break;
	case IT_NAILGUN:
		player_nail1 ();
		break;
	case IT_SUPER_NAILGUN:
		player_nail1 ();
		break;
	case IT_GRENADE_LAUNCHER:
		player_rocket1 ();
		W_FireGrenade ();
		// RUNE: rune of hell magic
 		if (self.player_flag & ITEM_RUNE3_FLAG) {
 			self.attack_finished = time + 0.3;
 			HasteSound ();
 		} else
			self.attack_finished = time + 0.6;
		break;
	case IT_ROCKET_LAUNCHER:
		player_rocket1();
		W_FireRocket();
		// RUNE: rune of hell magic
 		if (self.player_flag & ITEM_RUNE3_FLAG) {
 			self.attack_finished = time + 0.4;
 			HasteSound ();
 		} else
			self.attack_finished = time + 0.8;
		break;
	case IT_LIGHTNING:
		self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
		player_light1 ();
	default:
		break;
	}
};

void ()
W_ChangeWeapon =
{
};

void ()
CheatCommand =
{
/*
	if (deathmatch || coop)
		return;

	self.ammo_shells = 100;
	self.ammo_nails = 200;
	self.ammo_rockets = 100;
	self.ammo_cells = 200;
	self.items |= (IT_AXE | IT_SHOTGUN | IT_SUPER_SHOTGUN | IT_NAILGUN |
				   IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER |
				   IT_ROCKET_LAUNCHER | IT_LIGHTNING | IT_KEY1 | IT_KEY2);

	self.weapon = IT_ROCKET_LAUNCHER;
	self.impulse = 0;
	W_SetCurrentAmmo ();
*/
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void ()
CycleWeaponCommand =
{
	local float		it, am;

	it = self.items;
	self.impulse = 0;

	//McBain: save current weapon
	self.previous_weapon = self.weapon;

	while (1) {
		am = 0;

		switch (self.weapon) {
		case IT_LIGHTNING:
			self.weapon = IT_GRAPPLE;
			break;
		case IT_GRAPPLE:
			self.weapon = IT_AXE;
			break;
		case IT_AXE:
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
			break;
		case IT_SHOTGUN:
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
			break;
		case IT_SUPER_SHOTGUN:
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
			break;
		case IT_NAILGUN:
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
			break;
		case IT_SUPER_NAILGUN:
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
			break;
		case IT_GRENADE_LAUNCHER:
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
			break;
		case IT_ROCKET_LAUNCHER:
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		default:
			break;
		}

		if ((it & self.weapon) && am == 0) {
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
void ()
CycleWeaponReverseCommand =
{
	local float		it, am;

	it = self.items;
	self.impulse = 0;

	//McBain: save current weapon
	self.previous_weapon = self.weapon;

	while (1) {
		am = 0;

		switch (self.weapon) {
		case IT_LIGHTNING:
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
			break;
		case IT_ROCKET_LAUNCHER:
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
			break;
		case IT_GRENADE_LAUNCHER:
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
			break;
		case IT_SUPER_NAILGUN:
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
			break;
		case IT_NAILGUN:
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
			break;
		case IT_SUPER_SHOTGUN:
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
			break;
		case IT_SHOTGUN:
			self.weapon = IT_AXE;
			break;
		case IT_AXE:
			self.weapon = IT_GRAPPLE;
			break;
		case IT_GRAPPLE:
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		default:
			break;
		}

		if ((it & self.weapon) && am == 0) {
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
void ()
ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
	// ZOID:  Bug fix
	serverflags = (serverflags & 15);
};

//ZOID:  Uhm, where am I?
void ()
PrintLocation =
{
	local string	p;

	p = vtos (self.origin);

	sprint (self, PRINT_HIGH, "You are at ");
	sprint (self, PRINT_HIGH, p);
	sprint (self, PRINT_HIGH, "\n");
};

//ZOID: Note, changed it all to an if/else construct.  No need to check
//remaining impulses if we have one already.  Much cleaner and a tad
//more efficient.  Using a non-existant impulse is still the worst case. :(
void ()
ImpulseCommands =
{
	local float		it, am = 0, fl = 0;

	it = self.items;

	switch (self.impulse) {
	case 1:
		if (self.weapon == IT_AXE) {
			fl = IT_GRAPPLE;
			if (self.hook_out)
				Reset_Grapple (self.hook);
		} else if (self.weapon)
			fl = IT_AXE;
		break;
	case 22:
		fl = IT_GRAPPLE;
		if (self.weapon != IT_GRAPPLE) {
			sprint (self, PRINT_HIGH , "Grappling Hook Selected\n");
			if (self.hook_out)
				sound (self, CHAN_WEAPON, "weapons/bounce2.wav", 1, ATTN_NORM);

			self.hook_out = FALSE;
			self.on_hook = FALSE;
		}
		break;
	case 31:
		fl = IT_AXE;
		break;
	case 2:
	case 32:
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
		break;
	case 3:
	case 33:
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 2)
			am = 1;
		break;
	case 4:
	case 34:
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
		break;
	case 5:
	case 35:
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 2)
			am = 1;
		break;
	case 6:
	case 36:
		fl = IT_GRENADE_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
		break;
	case 7:
	case 37:
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
		break;
	case 8:
	case 38:
		fl = IT_LIGHTNING;
		if (self.ammo_cells < 1)
			am = 1;
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
	// McBain: I picked 69 -- seems appropriate!  I hope 69 hasn't been used in
	// other add-ons.  This is my first attempt at Quake C, and I hope I
	// haven't violated any Quake C ettiquette.  :(
	case 69:
		PreviousWeaponCommand ();
		break;
	case 99:
		PrintLocation();
		break;
	case 20:
		if (teamplay & TEAM_DROP_ITEMS)
			TossBackpack ();
		break;
	case 21:
		if (teamplay & TEAM_DROP_ITEMS)
			TossWeapon ();
		break;
	// Impulse 25 prints info about the current teamplay settings.
	case 25:
		TeamPrintSettings ();
		break;
	// *Capture The Flag - Status report by Wonko
	// Impulse 23 prints the current status of your flag and the
	// enemy flag (summarizes the endless messages)
	case 23:
		TeamFlagStatusReport ();
		break;
	case 141:
		identify_player (1);
		break;
	case 70:
		if (self.statstate < 0) {
			self.statstate = 0;
			sprint (self, PRINT_HIGH, "Status bar on (impulse 71 to 81 to "
					"set size)\n");
		} else {
			self.statstate = -1;
			sprint (self, PRINT_HIGH, "Status bar off.\n");
		}
		break;
	case 71:
	case 81:
		self.statstate = self.impulse - 71;
		sprint (self, PRINT_HIGH, "Status bar set\n");
	default:
		break;
	}
  	self.impulse = 0;

	if (fl) {
		if (!(self.items & fl)) {	// don't have the weapon or the ammo
			sprint (self, PRINT_HIGH, "no weapon.\n");
			return;
		}

		if (am) {	// don't have the ammo
			sprint (self, PRINT_HIGH, "not enough ammo.\n");
			return;
		}

		// set weapon, set ammo
		self.previous_weapon = self.weapon;
		self.weapon = fl;
		W_SetCurrentAmmo ();
	}
};

//McBain: Here's the beef...
void ()
PreviousWeaponCommand =
{
	local float		fl, am;

	self.impulse = 0;
	am = 0;

	if (!(self.items & self.previous_weapon)) {	// don't have the weapon or the ammo
		sprint (self, PRINT_HIGH, "no weapon.\n");
		return;
	}

	fl = self.weapon;
	self.weapon = self.previous_weapon;
	self.previous_weapon = fl;

	// this might not be the best method, but I'll be able to play sooner
	switch (self.weapon) {
	case IT_SHOTGUN:
	case IT_SUPER_SHOTGUN:
		if (self.ammo_shells < 1)
			am = 1;
		break;
	case IT_NAILGUN:
	case IT_SUPER_NAILGUN:
		if (self.ammo_nails < 1)
			am = 1;
		break;
	case IT_GRENADE_LAUNCHER:
	case IT_ROCKET_LAUNCHER:
		if (self.ammo_rockets < 1)
			am = 1;
		break;
	case IT_LIGHTNING:
		if (self.ammo_cells < 1)
			am = 1;
	default:
		break;
	}
	// ignore AXE -- no ammo needed

	if (am)
		self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void ()
W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;

	// ZOID: Only call ImpulseCommands() if needed!  This saves a good chunk
	// of cpu.  'profile' in console listed ImpulseCommands() as #1 user of
	// cpu (instructions), adding this one line caused it to not even be in
	// the top ten.
	if (self.impulse)
		ImpulseCommands ();

	// check for attack
	if (self.button0) {
		SuperDamageSound ();
		W_Attack ();
	}
};

/*
========
Resistancesound

Plays sound if needed
========
*/
void (entity who)
ResistanceSound =
{
	// RUNE play resistance sound if player has Earth Magic
	if (who.player_flag & ITEM_RUNE1_FLAG) {
		if (who.invincible_sound < time) {
			who.invincible_sound = time + 1;
			sound (who, CHAN_BODY, "rune/rune1.wav", 1, ATTN_NORM);
		}
	}
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void ()
SuperDamageSound =
{
	// RUNE play super damage sound if player has Black Magic, too
	if ((self.player_flag & ITEM_RUNE2_FLAG) && 
		(self.super_damage_finished > time)) {
		if (self.super_sound < time) {
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "rune/rune22.wav", 1, ATTN_NORM);
		}
	}

	if (self.super_damage_finished > time) {
		if (self.super_sound < time) {
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}

	if (self.player_flag & ITEM_RUNE2_FLAG) {
		if (self.super_sound < time) {
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "rune/rune2.wav", 1, ATTN_NORM);
		}
	}
};

/*
========
RegenerationSound

Plays sound if needed
========
*/
void ()
RegenerationSound =
{
	// RUNE play healing sound if player has Elder Magic
	if (self.player_flag & ITEM_RUNE4_FLAG) {
		if (self.regeneration_sound < time) {
			self.regeneration_sound = time + 1;
			sound(self, CHAN_BODY, "rune/rune4.wav", 1, ATTN_NORM);
		}
	}
};

/*
========
HasteSound

Plays sound if needed
========
*/
void ()
HasteSound =
{
	// RUNE play haste (Chthon's roar) sound if player has Hell Magic
	if (self.player_flag & ITEM_RUNE3_FLAG) {
		if (self.haste_sound < time) {
			self.haste_sound = time + 1;
			sound(self, CHAN_BODY, "rune/rune3.wav", 1, ATTN_NORM);
		}
	}
};
