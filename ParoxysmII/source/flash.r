#include "config.rh"

#include "paroxysm.rh"

/*
POX - Flashlight code from the Flashlight Tutorial at the Inside3D website <http://www.inside3d.com>
Created by ShockMan eMail: shockman@brutality.com
Added an entity attribute to the spawn function for bot support (since @self is only the bot at respwan)
*/
void() flash_update =
{
	// The Player is dead so turn the Flashlight off
	if (@self.owner.deadflag != DEAD_NO)
		@self.effects = 0;
	// The Player is alive so turn On the Flashlight
	else				    
		@self.effects = EF_DIMLIGHT;  
	// Find out which direction player facing
	makevectors (@self.owner.v_angle);
	// Check if there is any things infront of the flashlight
	traceline (@self.owner.origin , (@self.owner.origin+(v_forward * 500)) , FALSE , @self);
	// Set the Flashlight's position
	setorigin (@self, trace_endpos+(v_forward * -5));
	// Repeat it in 0.02 seconds...
	@self.nextthink = time + 0.02;
};
void(entity me) flash_on =
{
	// Make a new entity to hold the Flashlight
	local entity myflash;
	// spawn flash
	myflash = spawn ();
	myflash.movetype = MOVETYPE_NONE;
	myflash.solid = SOLID_NOT;
	// this uses the s_bubble.spr, if you want it to be completly
	// invisible you need to create a one pixel trancparent spirit
	// and use it here...
	
	//POX - changed it to a null sprite
	setmodel (myflash, "progs/null.spr"); 
	setsize (myflash, '0 0 0', '0 0 0');
	// Wire Player And Flashlight Together
	myflash.owner = me;
	me.flash = myflash;
	
	// give the flash a Name And Make It Glow
	myflash.classname = "flash";
	myflash.effects = EF_DIMLIGHT;
	
	// Set Start Position
	makevectors (@self.v_angle);
	traceline (@self.origin , (@self.origin+(v_forward * 500)) , FALSE , @self);
	setorigin (myflash, trace_endpos);
	// Start Flashlight Update
	myflash.think = flash_update;
	myflash.nextthink = time + 0.02;
};
//POX - the user toggle is not implemented (auto light for Darkmode only)
/*

void () flash_toggle =
{
	// If Off, Turn On
	if (@self.flash_flag == FALSE)
	{	
		@self.flash_flag = TRUE;
		flash_on();
	}
	// If On, Turn Off
	else
	{
		@self.flash_flag = FALSE;
		W_SetCurrentAmmo ();
		@self.flash.think = SUB_Remove;
		@self.flash.nextthink = time + 0.1;
	}
};

*/
