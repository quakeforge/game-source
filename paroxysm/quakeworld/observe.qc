/*
POX - Last Man Standing Observer Code
This was written to support Last Man Standing Rules, it is a crude form of Spectate that allows
observes to stay connected as players so they can play the next game.

An LMS observer is counted as a player, so you can still have the max amount of true Spectors connected
*/

entity() SelectSpawnPoint;
void() teleport_touch; //POX v1.12


//POX v1.12 - sets fov for observer (impulses 1 and 2)
/*------------------
SetObserverFOV
-------------------*/
void() SetObserverFOV =
{
	local string ob_fov;
	
	ob_fov = ftos(self.LMS_observer_fov);
	
	stuffcmd (self, "fov ");
	stuffcmd (self, ob_fov);
	stuffcmd (self, "\n");

};

//POX v1.12 - Allows observers to use teleporters
/*------------------
ObserverTeleportTouch
-------------------*/
void(string destination) ObserverTeleportTouch =
{
local entity	t;
	
	if (self.teleport_time > time)
		return;
	
	t = find (world, targetname, destination);
	
	if (!t)
		objerror ("couldn't find target");
		
	setorigin (self, t.origin);
	self.angles = t.mangle;

	self.fixangle = 1;		// turn this way immediately
	self.teleport_time = time + 1.7;//POX v1.2 increased this
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.velocity = v_forward * 300;
	self.flags = self.flags - self.flags & FL_ONGROUND;
};


/*------------------
ObserverImpulses
Handels observer controls
-------------------*/
void() ObserverImpulses =
{

	//Jump to a dm start point (Fire Button)
	if (self.button0)
	{
		self.goalentity = find(self.goalentity, classname, "info_player_deathmatch");
		
		if (self.goalentity == world)
			self.goalentity = find(self.goalentity, classname, "info_player_deathmatch");
		
		if (self.goalentity != world)
		{
			setorigin(self, self.goalentity.origin);
			self.angles = self.goalentity.angles;
			self.fixangle = TRUE;		// turn this way immediately
		}
	}
	
	//Jump into a player's position (Jump Button)
	if (self.button2)
	{
		self.goalentity = find(self.goalentity, classname, "player");
		
		if (self.goalentity == world)
			self.goalentity = find(self.goalentity, classname, "player");
		
		if (self.goalentity != world)
		{
			setorigin(self, self.goalentity.origin + '0 0 1');
			self.angles = self.goalentity.angles;
			self.fixangle = TRUE;		// turn this way immediately
		}
	}
	
	// POX v1.2 - added auto fov increase/decrease and reset impulses
	if (self.impulse == 1)
	{
		if (self.LMS_zoom == 1)
			self.LMS_zoom = FALSE;
		else
			self.LMS_zoom = 1;
	}
	
	if (self.impulse == 2)
	{
		if (self.LMS_zoom == 2)
			self.LMS_zoom = FALSE;
		else
			self.LMS_zoom = 2;
	}
	
	if (self.impulse == 3)
	{
		self.LMS_observer_fov = 90;
		self.LMS_zoom = FALSE;
		SetObserverFOV ();
	}
	
	//Allow TargetId to be turned off
	if (self.impulse == 16)
	{
		if (self.target_id_toggle)
		{
			self.target_id_toggle = FALSE;
			
			//POX v1.12 - don't centerprint if a message is up
			if (self.target_id_finished < time)
				centerprint (self, "Target Identifier OFF\n");
			else
				sprint (self, PRINT_HIGH, "Target Identifier OFF\n");
		}
		else
		{
			self.target_id_toggle = TRUE;

			//POX v1.12 - don't centerprint if a message is up
			if (self.target_id_finished < time)
				centerprint (self, "Target Identifier ON\n");
			else
				sprint (self, PRINT_HIGH, "Target Identifier ON\n");
			
			self.target_id_finished = time + 3;
		}
	}
	
	self.impulse = 0;
	self.button0 = 0;
	self.button1 = 0;

};

/*------------------
ObserverThink
Rerouted from PlayerPostThink
-------------------*/

void() ObserverThink =
{	
	local entity tele; //POX v1.12
	
	// POX v1.12 - display observer control instructions
	if (self.LMS_observer_time > time)
	{
		if (self.LMS_observer == 1)
			centerprint(self, "Last Man Standing game in progress...\n\nObserving till next round.");
		else //was eliminated
			centerprint (self, "You have been eliminated!\n\nObserving till next round.");
		self.target_id_finished = time + 0.1;	
	}
	else if (self.LMS_observer_time + 7 > time)
	{ 
		centerprint(self, "[FIRE] cycles through spawn points\n\n[JUMP] cycles through players\n\n[1] [2] zooms in/out, [3] resets zoom.");
		self.target_id_finished = time + 0.1;
	}
	    
	//POX v1.12 if touching a teleporter, go through it...
	tele = findradius(self.origin, 80);
	
	while(tele)
	{
		if (tele.touch == teleport_touch)
			ObserverTeleportTouch (tele.target);
			
		tele = tele.chain;	
	}
	
	//Update target identifier
	if (self.target_id_toggle && (time > self.target_id_finished))
		ID_CheckTarget ();
	
	//POX v1.2 - Better fov control - first impulse starts to zoom, second stops it
	if (self.LMS_zoom == 1)
	{
		self.LMS_observer_fov = self.LMS_observer_fov - 1;
		
		if (self.LMS_observer_fov < 30)
		{
			self.LMS_zoom = FALSE;
			self.LMS_observer_fov = 30;
		}
		
		SetObserverFOV ();
	}
	else if (self.LMS_zoom == 2)
	{
		self.LMS_observer_fov = self.LMS_observer_fov + 1;
		
		if (self.LMS_observer_fov > 135)
		{
			self.LMS_zoom = FALSE;
			self.LMS_observer_fov = 135;
		}
		
		SetObserverFOV ();
	}
	
	ObserverImpulses ();

};

/*------------------
SpawnObserver
-------------------*/

void() SpawnObserver =
{
	local	entity spot;
	
	self.classname = "LMSobserver";
	self.health = 111;
	
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NOCLIP; //I think this is cheat protected....
	//self.flags = FL_CLIENT;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;

	self.items = 0;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;	
	self.weapon = 0;

	self.armorvalue = 0;
	self.armortype = 0;

	self.deadflag = DEAD_NO;
	spot = SelectSpawnPoint ();

	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately

	setmodel (self, string_null);
	self.weaponmodel = string_null;
	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	self.view_ofs = '0 0 22';
	self.velocity = '0 0 0';
	
	//POX v1.2 - had this as '==' (worked anyway :P)
	self.goalentity = world;
	
	//POX v1.12
	if (self.LMS_registered) //This shouldn't happen but...
	{
		self.LMS_registered = 0;
		lms_plrcount = lms_plrcount - 1;
	}
	
	self.LMS_observer_time = time + 3;
	self.LMS_observer_fov = 100;
	stuffcmd (self, "fov 100\n");
	self.target_id_toggle = TRUE; //POX v1.12 default to on
};






