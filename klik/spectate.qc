#include "common.qh"

// Called when a spectator connects
void() SpectatorConnect = {
	bprint(PRINT_MEDIUM, "Spectator ", self.netname, " entered the game.\n");
};

// Called when a spectator disconnects
void() SpectatorDisconnect = {
	bprint(PRINT_MEDIUM, "Spectator ", self.netname, " left the game.\n");
};

// Called around the same time as player thinks?
void() SpectatorThink = {
	self.impulse = 0;
};
