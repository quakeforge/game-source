#include "config.rh"

#include "paroxysm.rh"

/*SERVER
void() monster_death_use;
*/

//============================================================================

/*
	CanDamage

	Returns true if the inflictor can directly damage the target.  Used for
	explosions and melee attacks.
*/
float (entity targ, entity inflictor) CanDamage =
{
	// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH) {
		traceline (inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, @self);

		if (trace_fraction == 1)
			return TRUE;

		if (trace_ent == targ)
			return TRUE;

		return FALSE;
	}
	
	traceline (inflictor.origin, targ.origin, TRUE, @self);

	if (trace_fraction == 1)
		return TRUE;

	traceline (inflictor.origin, targ.origin + '15 15 0', TRUE, @self);
	if (trace_fraction == 1)
		return TRUE;

	traceline (inflictor.origin, targ.origin + '-15 -15 0', TRUE, @self);
	if (trace_fraction == 1)
		return TRUE;

	traceline (inflictor.origin, targ.origin + '-15 15 0', TRUE, @self);
	if (trace_fraction == 1)
		return TRUE;

	traceline (inflictor.origin, targ.origin + '15 -15 0', TRUE, @self);
	if (trace_fraction == 1)
		return TRUE;

	return FALSE;
};

/*
============
Killed
============
*/
void (entity targ, entity attacker) Killed =
{
	local entity	oself = @self;

	@self = targ;
	
	if (@self.health < -99)
		@self.health = -99;		// don't let sbar get funky

	if (@self.movetype == MOVETYPE_PUSH || @self.movetype == MOVETYPE_NONE) {	// doors, triggers, etc
		@self.th_die ();
		@self = oself;
		return;
	}

	@self.enemy = attacker;

	// bump the monster counter
	if (@self.flags & FL_MONSTER) {
		killed_monsters++;
		WriteByte (MSG_ALL, SVC_KILLEDMONSTER);
	}
	ClientObituary (@self, attacker);
	
	@self.takedamage = DAMAGE_NO;
	@self.touch = nil;
	@self.effects = 0;

/*SERVER
	monster_death_use();
*/
	@self.th_die ();
	
	@self = oself;
};


/*
	T_Damage

	The damage is coming from inflictor, but get mad at attacker
	This should be the only function that ever reduces health.
*/
void (entity targ, entity inflictor, entity attacker, float damage) T_Damage =
{
	local vector	dir;
	local entity	oldself;
	local float		save;
	local float		take;
#ifdef QUAKEWORLD
	local string	attackerteam, targteam;
#else
	local float 	attackerteam, targteam;
#endif

	if (!targ.takedamage)
		return;


	if (targ.flags & FL_GODMODE)	// godmode completely unaffected by damage
		return;

	// check for invincibility
	if (targ.invincible_finished >= time && @self.invincible_sound < time) {
		sound (targ, CHAN_ITEM, "items/protect3.wav", 1, ATTN_NORM);
		@self.invincible_sound = time + 2;
		return;
	}

	// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;

	// check for quad damage powerup on the attacker
	if (attacker.super_damage_finished > time && inflictor.classname != "door")
		damage *= 4;

	// save damage based on the target's armor level
	save = ceil (targ.armortype * damage);
	if (save >= targ.armorvalue) {
		save = targ.armorvalue;
		targ.armortype = 0;	// lost all armor
		targ.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
	}

	targ.armorvalue -= save;
	if (targ.armorvalue > 0) {
		targ.armortype = 0.8;	// all armor has same value
		targ.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
	}

	// Change the color using only the value -- no different armor types
	if (targ.armorvalue > 150) {		// red
		targ.items |= IT_ARMOR3;
	} else if (targ.armorvalue > 50) {	// yellow
		targ.items |= IT_ARMOR2;
	} else if (targ.armorvalue > 1) {	// blue
		targ.items |= IT_ARMOR2;
	}
	
	take = ceil (damage - save);

	/*
		Add to the damage total for clients, which will be sent as a single
		message at the end of the frame
	*/
	// FIXME: remove after combining shotgun blasts?
	if (targ.flags & FL_CLIENT) {
		targ.dmg_take += take;
		targ.dmg_save += save;
		targ.dmg_inflictor = inflictor;
	}
	damage_inflictor = inflictor;	     

	// figure momentum add
	if ((inflictor != world) && (targ.movetype == MOVETYPE_WALK)) {
		dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize (dir);

		if ((damage < 60)	// player-player damage (not @self-inflicted)
				&& (attacker.classname == "player")
				&& (targ.classname == "player")
				&& (attacker != targ)) 
			targ.velocity += dir * damage * 11;
		else
			targ.velocity += dir * damage * 8;

		// Rocket Jump modifiers
		if ((rj > 1) && ((attacker.classname == "player") && (targ.classname == "player")) && (attacker == targ)) 
			targ.velocity = targ.velocity + dir * damage * rj;
	}

	// team play damage avoidance
	// ZOID 12-13-96: self.team doesn't work in QW.	Use keys
#ifdef QUAKEWORLD
	attackerteam = infokey (attacker, "team");
	targteam = infokey (targ, "team");
#else
	attackerteam = attacker.team;
	targteam = targ.team;
#endif

	if (((teamplay == 1) || (teamplay == 3))
			&& (attacker.classname == "player")
			&& ((attackerteam) && (targteam == attackerteam) && (targ != attacker))
			&& inflictor.classname != "door")
		return;
		
	// do the damage
	targ.health -= take;
	if (targ.health <= 0) {
		Killed (targ, attacker);
		return;
	}

	// react to the damage
	oldself = @self;
	@self = targ;

#if 0
	if ((@self.flags & FL_MONSTER) && attacker != world) { // get mad unless of the same class (except for soldiers)
		if (@self != attacker && attacker != @self.enemy) {
			if ((@self.classname != attacker.classname)
					|| (@self.classname == "monster_army" )) {
				if (@self.enemy.classname == "player")
					@self.oldenemy = @self.enemy;

				@self.enemy = attacker;
				FoundTarget ();
			}
		}
	}
#endif

	if (@self.th_pain)
		@self.th_pain ();

	@self = oldself;
};

/*
============
T_RadiusDamage
============
*/
void (entity inflictor,
	  entity attacker,
	  float damage,
	  entity ignore,
	  string dtype) T_RadiusDamage =
{
	local float		points;
	local entity	head;
	local vector	org;

	if ((head = findradius (inflictor.origin, damage + 40))) {
		do {
			if (head != ignore && head.takedamage) {
				org = head.origin + (head.mins + head.maxs)*0.5;
				points = 0.5 * vlen (inflictor.origin - org);

				if (points < 0)
					points = 0;

				points = damage - points;
				
				if (head == attacker)
					points *= 0.5;

				if (points > 0) {
					if (CanDamage (head, inflictor)) {
						head.deathtype = dtype;
						T_Damage (head, inflictor, attacker, points);
					}
				}
			}
			head = head.chain;
		} while (head);
	}
};

/*
============
T_BeamDamage
============
*/
void (entity attacker, float damage) T_BeamDamage =
{
	local float		points;
	local entity	head;

	if ((head = findradius (attacker.origin, damage + 40))) {
		do {
			if (head.takedamage) {
				points = 0.5 * vlen (attacker.origin - head.origin);

				if (points < 0)
					points = 0;

				points = damage - points;
				
				if (head == attacker)
					points *= 0.5;

				if (points > 0) {
					if (CanDamage (head, attacker)) {
						T_Damage (head, attacker, attacker, points);
					}
				}
			}
			head = head.chain;
		} while (head);
	}
};
