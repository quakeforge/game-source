// POX - v1.1 target identifier ala Quake3 - displays the name of players who cross your sight
// by Frank Condello (POX) - http://www.planetquake.com/paroxysm/ - pox@planetquake.com
/* POX - from original Quake ai.qc
=============
visible
returns 1 if the entity is visible to self, even if not infront ()
=============
*/
float (entity targ) visible =
{
	local vector	spot1, spot2;
	
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;
	traceline (spot1, spot2, TRUE, self);	// see through other monsters
	
	if (trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents
	if (trace_fraction == 1)
		return TRUE;
	
	return FALSE;
};
// Short and sweet....
void() ID_CheckTarget =
{	
	local vector org;
	local entity spot;
	local string idfrags; //POX v1.12
	
	//Lost target, or target died
	if (self.target_id_same < time || self.last_target_id.health < 1 || !visible(self.last_target_id))
		self.last_target_id = world;
	
	traceline (self.origin , (self.origin+(v_forward * 800)) , FALSE , self);
	org = trace_endpos;
	
	spot = findradius(org, 200);
	while (spot)
	{
		if ((spot.classname == "player") && spot.takedamage)
		{
			//Same target as last time
			if (self.target_id_same > time && spot == self.last_target_id)
			{
				self.target_id_finished = time + 1.5;
				self.target_id_same = time + 3;
				return;
			}
			else if (spot != self && visible (spot) )//Found new Target
			{
				self.last_target_id = spot;
				self.target_id_finished = time + 1.5;
				self.target_id_same = time + 3;
				
				//POX v1.12 print the target's frags is observing
				if (self.classname == "LMSobserver")
				{
					idfrags = ftos (self.last_target_id.frags);
					centerprint4 (self, self.last_target_id.netname, "\n\n", idfrags, " frags remaining");
				}
				else
					centerprint (self, self.last_target_id.netname);
				
				return;
			}
		}
		
		spot = spot.chain;
		
	}
};