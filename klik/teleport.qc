#include "common.qh"
#include "mapents_util.qh"
#include "damage.qh"
#include "effect.qh"
#include "misc.qh"
#include "teleport.qh"

.float (vector org) th_teleport;

void ()
_deathmsg_teleport =
{
	local string att_nname, def_nname;

	def_nname = name (self);
	att_nname = name (self.dmg_attacker);

	if (self.dmg_inflictor.owner == self)
		bprint (PRINT_DEATH, "Satan's power deflects ", att_nname,
				"'s telefrag.\n");
	else
		bprint (PRINT_DEATH, def_nname, " was telefragged by ", att_nname,
				".\n");
};

void ()
_teleport_death_touch =
{
	if (self.owner == other)
		return;

	ghost_inflictor.classname = "TELEPORT_DEATH";

	ghost_inflictor.dmg = DAMAGE_SHOULDDIE;
	ghost_inflictor.mass = 800;

	ghost_inflictor.velocity = '0 0 0';
	ghost_inflictor.lip = 64;
	ghost_inflictor.speed = 1000;
	ghost_inflictor.owner = self.owner;

	damage (other, self.owner, ghost_inflictor, DAMAGE_SHOULDDIE,
			_deathmsg_teleport);
};

void (vector org, entity death_owner)
_teleport_death_spawn =
{
	local entity death;
	
	death = spawn ("TELEDEATH");
	death.owner = death_owner;
	death.solid = SOLID_TRIGGER;
	setsize (death, death_owner.mins - '1 1 1', death_owner.maxs + '1 1 1');
	setorigin (death, org);

	death.touch = _teleport_death_touch;

	death.think = SUB_remove;
	death.nextthink = time + 0.1;

	force_retouch = 2;
};

void (entity e, entity spot)
teleport =
{
	local float spd;

	if (e.th_teleport) {
		local entity oldself, oldother;
		local float do_teleport;

		oldself = self;
		oldother = other;

		self = e;
		other = spot;

		do_teleport = self.th_teleport (other.origin);

		self = oldself;
		other = oldother;
		
		if (!do_teleport)
			return;
	}

	spd = vlen (e.velocity);
	if (spd < 200)
		spd = 200;

	setorigin (e, spot.origin);
	e.angles = spot.angles;
	e.fixangle = TRUE;
	e.teleport_time = 0.1;

	makevectors (e.angles);
	e.velocity = v_forward*spd;

	if (is_living (e))
		_teleport_death_spawn (spot.origin, e);

	effect_teleport_fog (spot.origin);
};
