/*
	#FILENAME#

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


void() respawn;
entity() SelectSpawnPoint;
void() CheckAdminCmd;

void(entity player,entity door) ObserverDoor =
{
  local entity d,d_master;
  local vector dmin,dmax;
    local float is_x,is_y,is_z,set;
    local vector dir,or; dir = '0 0 0';
  
  d_master = d = door.owner;
  if (d_master) {
    dmin = d_master.absmin;
    dmax = d_master.absmax;
  } else { 
    dmin = dmax = '0 0 0'; 
  }
  if (dmin != dmax) {
    // regular doors
    if (d_master.state != STATE_BOTTOM) return;
    do {
      // dprint (vtos(d.absmin)); dprint (" "); dprint (vtos(d.absmax)); dprint ("\n");
      if (d.absmin_x < dmin_x) { dmin_x = d.absmin_x; }
      if (d.absmax_x > dmax_x) { dmax_x = d.absmax_x; }
      if (d.absmin_y < dmin_y) { dmin_y = d.absmin_y; }
      if (d.absmax_y > dmax_y) { dmax_y = d.absmax_y; }
      if (d.absmin_z < dmin_z) { dmin_z = d.absmin_z; }
      if (d.absmax_z > dmax_z) { dmax_z = d.absmax_z; }
      d = d.enemy; // next linked door;
    } while ((d != d_master) && (d != world));
  }
  else {
    // secret doors
    // we ignore these currently
    return;
  }
  
    set = is_x = is_y = is_z = FALSE;
    or = player.origin;
    if (dmin_x + 15 < player.absmin_x && player.absmax_x < dmax_x - 15) is_x = TRUE;
    if (dmin_y + 15 < player.absmin_y && player.absmax_y < dmax_y - 15) is_y = TRUE;
    if (dmin_z + 15 < player.absmin_z && player.absmax_z < dmax_z - 15) is_z = TRUE;
    // dprint("doors:  "); dprint (vtos(dmin)); dprint (" "); dprint (vtos(dmax)); dprint ("\n");
    // dprint("player: "); dprint (vtos(player.absmin)); dprint (" "); dprint (vtos(player.absmax)); dprint ("\n");
    if (is_x && is_y) {
      // dprint("door is in xy plane\n");
      if      (or_z < dmin_z) { dir = '0 0  1'; or_z = dmax_z + 25; }
      else if (or_z > dmax_z) { dir = '0 0 -1'; or_z = dmin_z - 25; }
      set = TRUE;
    }
    else if (is_x && is_z) {
      // dprint("door is in xz plane\n");
      if      (or_y < dmin_y) { dir = '0  1 0'; or_y = dmax_y + 25; }
      else if (or_y > dmax_y) { dir = '0 -1 0'; or_y = dmin_y - 25; }
      set = TRUE;
    }
    else if (is_y && is_z) {
      // dprint("door is in yz plane\n");
      if      (or_x < dmin_x) { dir = ' 1 0 0'; or_x = dmax_x + 25; }
      else if (or_x > dmax_x) { dir = '-1 0 0'; or_x = dmin_x - 25; }
      set = TRUE;
    }
      if (set) { 
		local vector v;
		v =  normalize(player.velocity);
		if (dir * v < 0.5) return;
		player.origin = or;
		setorigin (player, player.origin);
      }
};

void(entity player,entity tele) ObserverTeleporter =
{
  local entity targ;
  local vector v1,v2;
  
  v1 = ((tele.absmax + tele.absmin) * 0.5) - player.origin; normalize(v1);
  v2 = player.velocity; normalize(v2);
  if (v1 * v2 <= 0.1) return;
  
  targ = find (world, targetname, tele.target);
  if (!targ) {
    dprint("ObserverTeleportThroughTeleporter: couldn't find teleporter target\n");
    return;
  }
  makevectors (targ.mangle);
  setorigin (player, targ.origin);
  player.angles = targ.mangle;
  player.fixangle = TRUE; // turn this way immediately
  player.teleport_time = time + 0.7;
  player.velocity = v_forward * 300;
  // player.flags &= ~FL_ONGROUND;
};

float() DoObserverImpulse =
{
	if (self.impulse == 1 || self.impulse == 2 || /* self.impulse == 3 ||  */
		self.button2) {

		self.observer = 0;
		SetChangeParms ();
		self.killed = 0;

		if (self.impulse == 1)
			self.team = self.lastteam = TEAM_COLOR1;
		else if (self.impulse == 2)
			self.team = self.lastteam = TEAM_COLOR2;
		else {
			self.lastteam = -50;
			TeamCheckTeam();
		}

		if (self.lastteam == TEAM_COLOR1)  {
			bprint(self.netname);
			bprint(" joined ред team!\n"); // red
		} else if (self.lastteam == TEAM_COLOR2) {
			bprint(self.netname);
			bprint(" joined блуе team!\n"); // blue
		}

		self.impulse = 0;

		self.player_flag |= TEAM_STUFF_COLOR;
		if (teamplay & TEAM_CAPTURE_CUSTOM) {
			if (self.lastteam == TEAM_COLOR1)
				self.skin = 1;
			else
				self.skin = 3;
			if (random() < 0.5)
				self.skin = self.skin + 1; // visor dude
			self.player_flag &= ~65280;
			self.player_flag |= (self.skin * 256);  
		}

		self.weapon = W_BestWeapon();
		respawn();
		W_SetCurrentAmmo();
		return TRUE;
	}
	return FALSE;
};

void () ObserverThink =
{
    local entity e;

	self.weaponmodel = "";
	self.weaponframe = 0;
	self.flags |= FL_ONGROUND;

  { 
    local float invcos,nvp,nvpmax,sp,svz;
    local vector f,vp,vs;
    
    svz = self.velocity_z * 0.75;
    self.velocity_z = 0;
    
    // v_forward is already normalized
    f_x = v_forward_x; 
    f_y = v_forward_y; 
    f_z = 0;
    invcos = vlen(f); if (invcos) invcos= 1/invcos; else invcos=0;
    f = f*invcos; // normalize f
    
    sp = f * self.velocity;
    vp = sp*f;
    nvp = vlen(vp); if (sp<0) nvp = nvp*(-1);
    vs = self.velocity - vp;
    
    vp = v_forward * (nvp * invcos);
    vp_z = vp_z + svz;
    nvp = vlen(vp);
    nvpmax = (320 - 100*(v_forward * '0 0 1'));
    if (nvp > nvpmax) { vp = vp * (nvpmax/nvp); }
    
    self.velocity = vp + vs;
  }
  
	// look for doors, etc.
    e = findradius(self.origin,75);
    while (e != world) {
		if (e.classname == "door") {
			ObserverDoor(self, e);
			e = world;
		}
    	if (e.classname == "trigger_teleport") {
			ObserverTeleporter(self,e);
			e = world;
        }
        e = e.chain;
		if (!e) e = world;
    }

	if (self.impulse && self.accessparm) { // admin functions
		CheckAdminCmd();
		self.impulse = 0;
	} else if (DoObserverImpulse()) {
		return;
	} else if (self.impulse) {
		CheckAdminCmd();
		self.impulse = 0;
	}
};

void(entity player) BecomeObserver =
{
	player.health           = 999;
	player.takedamage       = DAMAGE_NO;
	player.solid            = SOLID_NOT;
	player.movetype         = MOVETYPE_FLY;
	player.deadflag         = DEAD_NO;

	setmodel (player, string_null);

	player.weaponmodel      = "";
	player.weaponframe      = 0;
	player.weapon           = 0;

	setsize(player, '-12 -12 -12', '12 12 12');
	player.view_ofs = '0 0 10';

	player.observer = 1;
	player.do_observer = 0;
};

