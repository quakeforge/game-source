/*
Frank Condello 09.28.98 - originally for the M.A.H.E.M. MacQuake Mod.
Now used in paroxysm

EMAIL: pox@planetquake.com
WEB: http://www.planetquake.com/paroxysm/
=========================================================================
This is the code for Moving Light Entities (Dynamic Lights)
It's basically identical to the the func_train code with out
stuff like damage and blocked code used for solid objects.
The light follows Targets and waits just like a train.
A new variable (dynlight_style) defines the type of light emitted.
Quake has only three dynamic light styles:
1 - Dimlight
2 - Brightlight
3 - Brightfield (Brightlight with 'shimmering' particles)
Dynamic Light can also be triggered, They currenty only start turned off.
*/
.float dynlight_style;
void() dynlight_next;
void() dynlight_find;

void() start_dynlight =
{
//POX v1.1 - changed this for QW support
//No EF_BLUE or EF_RED in Quake - defaults to EF_DIMLIGHT
	if (self.dynlight_style == 2)
		self.effects |= EF_BRIGHTLIGHT;
	
	else if (self.dynlight_style == 3)
		self.effects |= EF_BRIGHTFIELD;
		
	else
		self.effects |= EF_DIMLIGHT;
		
	dynlight_next();
};

void() dynlight_wait =
{
	if (self.wait)
		self.nextthink = self.ltime + self.wait;
	else
		self.nextthink = self.ltime + 0.1;
	
	self.think = dynlight_next;
};

void() dynlight_next =
{
	local entity	targ;

	targ = find (world, targetname, self.target);
	self.target = targ.target;
	if (!self.target)
		objerror ("dynlight_next: no next target");
	if (targ.wait)
		self.wait = targ.wait;
	else
		self.wait = 0;
	SUB_CalcMove (targ.origin - self.mins, self.speed, dynlight_wait);
};

void() dynlight_find =

{
	local entity	targ;

	targ = find (world, targetname, self.target);
	self.target = targ.target;
	setorigin (self, targ.origin - self.mins);
	if (!self.targetname)
	{	// not triggered, so start immediately
		self.nextthink = self.ltime + 0.1;
		self.think = start_dynlight;
	}
};


void() dynlight_use =
{
	if (self.think != dynlight_find)
		return;		// already activated
	start_dynlight();
};


void() dyn_light =
{	
local float eff;

	precache_model ("progs/null.spr");
	
	if ((self.dynlight_style < 1) || (self.dynlight_style > 3))
		self.dynlight_style = 1;
		
	if (!self.speed)
		self.speed = 100;
	
	if (!self.target)
		objerror ("dyn_light without a target");
	
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_PUSH;
	self.use = dynlight_use;
	self.classname = "dynlight";
	
	setmodel (self, "progs/null.spr");
	setsize (self, '0 0 0', '0 0 0');
	setorigin (self, self.origin);

// start trains on the second frame, to make sure their targets have had
// a chance to spawn
	self.nextthink = self.ltime + 0.1;
	self.think = dynlight_find;
};
