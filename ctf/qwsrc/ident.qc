/*
	ident.qc

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

// Identify the player you are pointed towards
// By Suck (Nat Friedman)
// This code falls under the GNU public license, and cannot be 
// redistributed without my name attached.

// hacked by Zoid for CTF4

// This is called with the player who wants to know whose in front
// of him as "self."  I call it with an impulse in weapons.qc 
entity (float disp)
identify_player =
{
	// e is a temp entity; guy is our current best guess
	// as to at whom the player is pointing
	local entity	e, guy = world;
	// The best "closeness" heuristic so far.
	local float		closeness = -1;
	// Temp vars.
	local float		currclose;
	local vector	diff, point;

	// Walk the list of players...
	e = find (world, classname, "player");
	while (e != world) {
		// Get a vector pointing from the viewer to the current
		// player under consideration
		diff = e.origin - self.origin;

		// Normalize it since we only care where he's pointing,
		// not how far away the guy is.
		diff = normalize (diff);

		// Normalize self.angles so we can do a length-independent
		// consideration
		point = normalize (self.angles);

		// Find the different between the current player's angle
		// and the viewer's vision angle
		diff -= point;

		// The length is going to be our definition of closeness
		currclose = vlen (diff);
		traceline (self.origin, e.origin, FALSE, self);
		if (trace_ent == e) {
			if (closeness == -1) {
				closeness = currclose;
				guy = e;
			} else if (currclose < closeness) {
				closeness = currclose;
				guy = e;
			}
		}
		e = find (e, classname, "player");
	}

	// Now we display.
	if (disp == 0)
		return guy;
	if (guy == world) {
		TeamPlayerUpdate(self, "You're not looking at anyone!");
		return world;
	}

	TeamPlayerUpdate2 (self, "You are looking at ", guy.netname);
	return guy;
};	 

