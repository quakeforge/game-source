
void() monster_ogre = {remove(self);};
void() monster_demon1 = {remove(self);};
void() monster_shambler = {remove(self);};
void() monster_knight = {remove(self);};
void() monster_army = {remove(self);};
void() monster_wizard = {remove(self);};
void() monster_dog = {remove(self);};
void() monster_zombie = {remove(self);};
void() monster_boss = {remove(self);};
void() monster_tarbaby = {remove(self);};
void() monster_hell_knight = {remove(self);};
void() monster_fish = {remove(self);};
void() monster_shalrath = {remove(self);};
void() monster_enforcer = {remove(self);};
void() monster_oldone = {remove(self);};
void() event_lightning = {remove(self);};
/*
==============================================================================
MOVETARGET CODE
The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which allways heads to the next target.
targetname
must be present.  The name of this movetarget.
target
the next spot to move to.  If not present, stop here for good.
pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow
==============================================================================
*/
/*
=============
t_movetarget
Something has bumped into a movetarget.	 If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void() t_movetarget =
{
local entity	temp;
	if (other.movetarget != self)
		return;
	
	if (other.enemy)
		return;		// fighting, not following a path
	temp = self;
	self = other;
	other = temp;
	if (self.classname == "monster_ogre")
		sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);// play chainsaw drag sound
//dprint ("t_movetarget\n");
	self.goalentity = self.movetarget = find (world, targetname, other.target);
	self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
	if (!self.movetarget)
	{
		self.pausetime = time + 999999;
		self.th_stand ();
		return;
	}
};
void() movetarget_f =
{
	if (!self.targetname)
		objerror ("monster_movetarget: no targetname");
		
	self.solid = SOLID_TRIGGER;
	self.touch = t_movetarget;
	setsize (self, '-8 -8 -8', '8 8 8');
	
};
/*QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
Monsters will continue walking towards the next target corner.
*/
void() path_corner =
{
	movetarget_f ();
};

//============================================================================
