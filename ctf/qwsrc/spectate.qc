/*
	spectate.qc

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

// Spectator functions
// Added Aug11'97 by Zoid <zoid@idsoftware.com>
//
// These functions are called from the server if they exist.
// Note that Spectators only have one think since they movement code doesn't
// track them much.  Impulse commands work as usual, but don't call
// the regular ImpulseCommand handler in weapons.qc since Spectators don't
// have any weapons and things can explode.
//
//   --- Zoid.

/*
===========
SpectatorConnect

called when a spectator connects to a server
============
*/
void ()
SpectatorConnect =
{
	bprint (PRINT_MEDIUM, "Spectator ");
	bprint (PRINT_MEDIUM, self.netname);
	bprint (PRINT_MEDIUM, " entered the game\n");

	self.goalentity = world; // used for impulse 1 below
	self.motd_count = 1;
	self.classname = "spectator";
};

/*
===========
SpectatorDisconnect

called when a spectator disconnects from a server
============
*/
void ()
SpectatorDisconnect =
{
	bprint (PRINT_MEDIUM, "Spectator ");
	bprint (PRINT_MEDIUM, self.netname);
	bprint (PRINT_MEDIUM, " left the game\n");
	self.statstate = 0;
};

/*
================
SpectatorImpulseCommand

Called by SpectatorThink if the spectator entered an impulse
================
*/
void ()
SpectatorImpulseCommand =
{
	switch (self.impulse) {
	case 1:
		// teleport the spectator to the next spawn point
		// note that if the spectator is tracking, this doesn't do  much
		self.goalentity = find(self.goalentity, classname,
							   "info_player_deathmatch");
		if (self.goalentity == world)
			self.goalentity = find (self.goalentity, classname,
									"info_player_deathmatch");
		else {
			setorigin(self, self.goalentity.origin);
			self.angles = self.goalentity.angles;
			self.fixangle = TRUE;           // turn this way immediately
		}
		break;
	case 23:
		TeamFlagStatusReport ();
		break;
	case 25:
		TeamPrintSettings ();
		break;
	case 70:
		if (self.statstate < 0) {
			self.statstate = 0;
			sprint (self, PRINT_HIGH, "Status bar on (impulse 71 to 81 to "
					"set size)\n");
		} else {
			self.statstate = -1;
			sprint(self, PRINT_HIGH, "Status bar off.\n");
		}
		break;
	default:
		if (self.impulse >= 71 && self.impulse <= 81) {
			self.statstate = self.impulse - 71;
			sprint (self, PRINT_HIGH, "Status bar set\n");
		}
		break;
	}
	self.impulse = 0;
};

/*
================
SpectatorThink

Called every frame after physics are run
================
*/
void ()
SpectatorThink =
{
	// self.origin, etc contains spectator position, so you could
	// do some neat stuff here

	TeamCapturePlayerUpdate ();

	if (self.impulse)
		SpectatorImpulseCommand ();
};
