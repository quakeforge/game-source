// POX - v1.1 target identifier ala Quake3 - displays the name of players who cross your sight
// by Frank Condello (POX) - http://www.planetquake.com/paroxysm/ - pox@planetquake.com
// requires visible float return from ai.qc

// Short and sweet....
void() ID_CheckTarget =
{	
	local vector org;
	local entity spot;
	
	//Lost target, or target died
	if (self.target_id_same < time || self.last_target_id.health < 1 || !visible(self.last_target_id))
		self.last_target_id = world;
	
	traceline (self.origin , (self.origin+(v_forward * 800)) , FALSE , self);

	org = trace_endpos;
	
	spot = findradius(org, 200);

	while (spot)
	{
		if ((spot.classname == "player" || spot.classname == "bot") && spot.takedamage)
		{
			//Same target as last time
			if (self.target_id_same > time && spot == self.last_target_id)
			{
				self.target_id_finished = time + 1.3;
				self.target_id_same = time + 3;
				return;
			}
			else if (spot != self && visible (spot) )//Found new Target
			{
				self.last_target_id = spot;
				self.target_id_finished = time + 1.5;
				self.target_id_same = time + 3;
				centerprint (self, self.last_target_id.netname);
				return;
			}
		}
		
		spot = spot.chain;
		
	}

};
