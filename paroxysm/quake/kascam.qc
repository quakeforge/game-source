//Kasuha's DeathMatch Camera QC patch version 1.5

/////////////////////////////////////////////////////////////////////////////
// KasCam definitions
/////////////////////////////////////////////////////////////////////////////

// KasCam constants

float CAM_IDLE	    = 0;   // Camera idle, nobody to look at
float CAM_FIXED	    = 1;   // Fixed-position camera
float CAM_FLYBY	    = 2;   // Fly-by camera
float CAM_FOLLOW    = 3;   // Camera following a player
float CAM_HAND	    = 4;   // Hand-targeted camera
float CAM_FREE	    = 5;   // Flying hand-targeted camera
float CAM_NOCLIP    = 6;   // No-clipping flying blabla
float CAM_DEATH	    = 7;   // Death camera (automatic mode only)

// KasCam variables

// how the standard fields are used:
// .enemy ........... targeted entity (player, monster, robot, ...)
// .movetarget ...... previous targeted entity
// .goalentity ...... targeted entity if locked on it
// .attack_state .... TRUE if forced to FOLLOW
// .dest ............ current expected camera position
// .dest1 ........... current expected targeted point
// .dest2 ........... next target for IDLE mode
// .mangle .......... angle speed
// .state ........... camera state
// .pausetime ....... delay measure
// .delay ........... how long to keep current target / idle mode
// .search_time ..... when drop from current mode
// .aflag ........... "take"/"r.i.p." messages on/off
// .lip ............. max distance for flyby mode
// .cnt ............. entity passing counter

/////////////////////////////////////////////////////////////////////////////
// internal KasCam functions
/////////////////////////////////////////////////////////////////////////////

// give me the next possible target please...
// yes, I am testing KasCam with bots. It is easier than with live players :-)

entity(entity ent) CamCycle =
{
 if (ent == world) {
   self.cnt = 0;
 }
 if (self.cnt == 0) {
   ent = find(ent,classname,"player");
   if (ent == world) {
     self.cnt = 1;
   }
 }
 if (self.cnt == 1) {
   ent = find(ent,classname,"bot");
 }
 return ent;
};

// simple now, but there can be differences
// for various target entity classnames

void(entity ent) CamVectors =
{
 if (ent.classname == "player") {
  makevectors(ent.v_angle);
 } else {
  makevectors(ent.angles); // for dmbot
 }
};

// centerprinting prototypes

void(entity client, string s1) camcenterprint1 = #73;
void(entity client, string s1, string s2) camcenterprint2 = #73;
void(entity client, string s1, string s2, string s3) camcenterprint3 = #73;
void(entity client, string s1, string s2, string s3, string s4) camcenterprint4 = #73;
void(entity client, string s1, string s2, string s3, string s4, string s5) camcenterprint5 = #73;
void(entity client, string s1, string s2, string s3, string s4, string s5, string s6) camcenterprint6 = #73;
void(entity client, string s1, string s2, string s3, string s4, string s5, string s6, string s7) camcenterprint7 = #73;

// Now taking / r.i.p report

void(entity ent, string tit) CamReport =
{
 local string s2,s3;
	
 // + POX v1.11 - wait for 'next round' message before printing anything else
 if (self.attack_finished > time)
		return;

 if (ent.frags < 1) {
  s2 = "no";
 } else {
  s2 = ftos(ent.frags);
 }
 if (ent.frags != 1) {
  s3 = " frags";
 } else {
  s3 = " frag";
 }
 camcenterprint6(self,tit,"\n\n\n",ent.netname," - ",s2,s3);
};

// There is NO square root ?!	:-(((

float(float num) CamSqrt =
{
 local float apr;

 if (num < 0.001)
  return 0;

 if (num>1) {
  apr = num;
 } else {
  apr = 1;
 }
 do {
  apr = (num + (apr * apr)) / (2 * apr);
 } while (fabs((apr * apr) - num) > (num * 0.001));
 return apr;
};

// Angle normalization

float(float a) CamReAngle =
{
 while (a>180) a = a - 360;
 while (a<-180) a = a + 360;
 return a;
};

// point visibility test

integer(vector vec) CamVisible =
{
 traceline(self.origin,vec,TRUE,self);
 return ((trace_fraction == 1) && !((trace_inopen && trace_inwater)));
};

// entity visibility test
// suited for players and player size bots; may vary for various classnames

integer(entity ent) CamVisibleEnt =
{
 local vector vec;

// Three points: origin, bottom and eyes
 if (CamVisible(ent.origin)) return TRUE;
 vec = ent.origin;
 vec_z = ent.absmin_z;
 if (CamVisible(vec)) return TRUE;
 vec_z = ent.absmax_z - 8;
 return CamVisible(vec);
};

// find target closest to the screen centre
// returns WORLD if nobody visible

entity() CamShoot =
{
 local entity ent,entx;
 local vector vec;
 local float d1,dx;

 makevectors(self.v_angle);
 entx = world;
 ent = CamCycle(world);
 dx = 0;
 while (ent != world) {
  if (ent.deadflag == DEAD_NO) {
   vec = ent.origin - self.origin;
   vec = normalize(vec);
   d1 = (v_forward_x * vec_x) + (v_forward_y * vec_y) + (v_forward_z * vec_z);
   if (d1 > dx) {
    if (CamVisible(ent.origin)) {
     entx = ent;
     dx = d1;
    }
   }
  }
  ent = CamCycle(ent);
 }
 return entx;
};

// smooth position movement

float(float d, float a) CamHurry =
{
 local float t,tt;

 if (d<0) a = 0 - a;
 t = frametime;
 tt = CamSqrt(d / a);
 if (t > tt) {
  return d;
 } else {
  return (a * t * ((2 * tt) - t));
 }
};

// Watch out! This is probably the most sophisticated routine ;-)
// I spent 5 hours developing the algorithm
// If you understand how it works in 3 minutes you're a guru :-)))

// smooth viewing angle movement
// return value is not a vector - this is a hack to return
// two floats at once :-)
// parameters are: current position, current velocity, acceleration
// returns new position and new velocity

vector(float s, float v, float a) CamSmooth =
{
 local float dt,t1,t2,v2,as,sv2;
 local integer b;
 local vector vec;

 s = CamReAngle(s);
 v2 = v / 2;
 as = a * s;
 sv2 = v2 * v2;
 dt = frametime;
 if (fabs(as) < sv2) {
  b = v > 0;
 } else {
  b = s > 0;
 }
 if (b) {
  t2 = CamSqrt((sv2 + as) / 2) / a;
  a = 0 - a;
 } else {
  t2 = CamSqrt((sv2 - as) / 2) / a;
 }
 t1 = t2 - (v2 / a);
 if (t1 > dt) {
  s = (a * dt + v) * dt + s;
  v = a * dt * 2 + v;
 } else {
  s = (a * t1 + v) * t1 + s;
  v = a * t1 * 2 + v;
  t1 = dt - t1;
  if (t1 < t2) {
   s = (v - (a * t1)) * t1 + s;
   v = v - (a * t1 * 2);
  } else {
   s = 0;
   v = 0;
  }
 }
 vec_x = s;
 vec_y = v;
 return vec;
};

// Check a flyby vector if it is usable
// returns vector length
// 1111 is a sentinel - flyby vectors are taken
// only if shorter than 1000
// vector is passed from player's eyes
// may vary for various classnames

float(vector vec) TryFlybyVector =
{
 local vector orig,vec1;
 local float vl;

 vec1 = normalize(vec);
 vec = 700 * vec1;
 vec1 = 5 * vec1;
 orig = self.enemy.origin;
 orig_z = self.enemy.absmax_z - 8; // .................. eye level
 traceline(orig,orig+vec,FALSE,self.enemy);
 if (trace_ent != world) return 1111;
 if (trace_inopen && trace_inwater) return 1111;
 trace_endpos = trace_endpos - vec1;
 if (pointcontents(trace_endpos) == CONTENT_SOLID) return 1111;
 vl = vlen(self.enemy.origin - trace_endpos);
 if (vl<50) return 1111;
 return fabs(333 - vl);
};

// Move camera towards ideal position (or just skip there)
// parameters are position and angle speed factor
// 0 means to skip

void(float speedv, float speeda) CamUpdatePos =
{
 local vector vec, v1;
 local float vl;

// Check destination visibility
// if invisible, just skip there
 traceline(self.origin,self.dest,TRUE,self);
 if (trace_fraction != 1) {
  speedv = 0;
  speeda = 0;
 }
// first do camera movement
 if (speedv == 0) {
  setorigin(self,self.dest);
 } else {
  vec = self.dest - self.origin;
  vl = vlen(vec);
  vec = normalize(vec);
  vl = CamHurry(vl,speedv);
  vec = vl * vec;
  setorigin(self,self.origin + vec);
 }
// then view angle
 self.fixangle = TRUE;
 self.movetype = MOVETYPE_NONE;
// in death mode look exactly at the target even if camera moves
// in other modes look like camera is in its ideal position
 if (self.state != CAM_DEATH) {
  vec = vectoangles(self.dest1 - self.dest);
 } else {
  vec = vectoangles(self.dest1 - self.origin);
 }
 vec_z = 0;
 vec_x = CamReAngle(360 - vec_x);
 vec_y = CamReAngle(vec_y);
 if (vec_x > 70) {
  vec_x = 70;
 } else {
  if (vec_x < -70) vec_x = -70;
 }
 if (speeda == 0) {
  self.angles = vec;
  self.mangle = '0 0 0';
 } else {
  v1 = CamSmooth(self.angles_x - vec_x,self.mangle_x,speeda);
  self.mangle_x = v1_y;
  self.angles_x = vec_x + v1_x;
  v1 = CamSmooth(self.angles_y - vec_y,self.mangle_y,speeda);
  self.mangle_y = v1_y;
  self.angles_y = vec_y + v1_x;
  self.angles_x = CamReAngle(self.angles_x);
  self.angles_y = CamReAngle(self.angles_y);
 }
 self.v_angle = self.angles;
};

// make camera look forward ;-)
// used when target disappeared etc.

void() CamSetAuto =
{
 self.dest = self.origin;
 makevectors(self.v_angle);
 self.dest1 = self.origin+v_forward;
 CamUpdatePos(0,0);
};

// go to idle state

void() CamGoIdle =
{
 CamSetAuto();
 self.state = CAM_IDLE;
 self.pausetime = time + 2;
 self.search_time = time;
 self.dest2 = self.dest1;
 self.enemy = self;
};

// go to death mode

void() CamGoDeath =
{
 if (self.aflag) CamReport(self.enemy,"R.I.P."); // Report death
 self.mangle = '0 0 0';
 self.dest = self.origin;
 self.state = CAM_DEATH;
 self.pausetime = time + 1;
 self.movetarget = world;
 self.search_time = time + 5; // max. 5 seconds DEATH mode
};

// Get target point for flyby

vector(entity ent) CamFlybyTarget =
{
 local vector vec;
 vec = ent.origin;
 vec_z = ent.absmax_z - 8;
 return vec;
};

// FlyBy mode initialization
// Targeted player is in self.enemy

void(entity newtarg) CamInitFlybyMode =
{
 local float f, max;
 local vector vec;

// Keep camera at this point for some time...
 self.pausetime = time + 0.4;

// Report selected player
 if (self.enemy != newtarg) {
  self.enemy = newtarg;
  if (self.movetarget != self.enemy) {
   if (self.aflag) {
    CamReport(self.enemy,"Now taking");
   }
   self.movetarget = newtarg;
  }
 }
 vec = self.enemy.angles;
 vec_x = 0;
 vec_y = 0;
 makevectors (vec);
 v_forward = 3 * v_forward;
 max = 1000;
 f = TryFlybyVector(v_up + v_forward + v_right);
 if (f<max) {
  max = f;
  vec = trace_endpos;
 }
 f = TryFlybyVector(v_up - v_forward + v_right);
 if (f<max) {
  max = f;
  vec = trace_endpos;
 }
 f = TryFlybyVector(v_up + v_forward - v_right);
 if (f<max) {
  max = f;
  vec = trace_endpos;
 }
 f = TryFlybyVector(v_up - v_forward - v_right);
 if (f<max) {
  max = f;
  vec = trace_endpos;
 }
 if (max >= 1000) {
  f = TryFlybyVector(v_up + v_forward);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector(v_up - v_forward);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector(v_up + v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector(v_up - v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
 }
 if (max>=1000) {
  f = TryFlybyVector(v_forward + v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector(v_forward - v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_forward + v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_forward - v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
 }
 if (max>=1000) {
  f = TryFlybyVector(v_forward);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector(v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_forward);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
 }
 if (max>=1000) {
  f = TryFlybyVector('0 0 0' - v_up + v_forward + v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_up - v_forward + v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_up + v_forward - v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_up - v_forward - v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
 }
 if (max>=1000) {
  f = TryFlybyVector('0 0 0' - v_up + v_forward);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_up + v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_up - v_forward);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
  f = TryFlybyVector('0 0 0' - v_up - v_right);
  if (f<max) {
   max = f;
   vec = trace_endpos;
  }
 }
 if (max >= 1000) {
  CamGoIdle();
  self.pausetime = time + 2;
  return;
 }
 self.dest1 = CamFlybyTarget(self.enemy);
 self.dest = vec;
 self.state = CAM_FLYBY;
 self.lip = 1.5 * vlen(self.dest - self.dest1);
 if (self.lip < 500) self.lip = 500;
 CamUpdatePos(0,0);
};

// get FOLLOW mode position

vector() GetFollowCam =
{
 local vector vec, vec2;

 CamVectors(self.enemy);
 vec = self.enemy.origin + (self.enemy.maxs_z + 4) * v_up;
 traceline(self.enemy.origin,vec,FALSE,self);
 vec = trace_endpos - normalize(vec);
 vec2 = -100 * v_forward;
 traceline(vec,vec+vec2,TRUE,self);
 vec2 = trace_endpos - normalize(vec2);
 if (CamVisible(vec2)) {
  return vec2;
 } else {
  return vec;
 }
};

// get FOLLOW mode targetting point

vector() GetFollowTrg =
{
 local vector vec;

 if (self.enemy.deadflag == DEAD_NO) {
  CamVectors(self.enemy);
  vec = self.enemy.origin + 2048 * v_forward;
 } else {
  vec = self.enemy.origin;
 }
 return vec;
};

// Move the camera to the point it is looking at

void() CamHandJump =
{
 makevectors(self.v_angle);
 traceline(self.origin,self.origin+2000*v_forward,TRUE,self);
 self.dest=trace_endpos - (5 * normalize(trace_endpos-self.origin));
 self.dest1 = self.origin;
 CamUpdatePos(0,0);
};

// find n-th saved position

entity(float n) CamGetPos =
{
 local entity ent;

 ent = find(world,classname,"CamSavedPos");
 while((n>0) && (ent!=world)) {
  ent = find(ent,classname,"CamSavedPos");
  n = n - 1;
 }
 return ent;
};

// save actual position and angles

void(float n) CamSavePos =
{
 local entity ent;

 ent = CamGetPos(n);
 if (ent!=world) {
  ent.angles = self.angles;
  ent.v_angle = self.v_angle;
  setorigin(ent,self.origin);
 }
};

// go to saved position

void(float n) CamLoadPos =
{
 local entity ent;

 if ((self.state == CAM_HAND) || (self.state == CAM_FREE) || (self.state == CAM_NOCLIP)) {
  ent = CamGetPos(n);
  if (ent!=world) {
   self.fixangle = TRUE;
   self.angles = ent.angles;
   self.v_angle = ent.v_angle;
   setorigin(self,ent.origin);
  }
 }
};

// Impulse handling

void() DisplayRules; //POX - predeclare

void() CamImpulses =
{
 local float c;
 local entity ent;

//POX - Added so server rules are accessable in autocam mode
	if (self.impulse == 253)
		DisplayRules();

// Choose target automatically
 if (self.impulse == 100) {
  self.goalentity = world;
  CamGoIdle();
// Choose target manually
 } else if ((self.impulse > 100) && (self.impulse <150)) {
  self.goalentity = world;
  c = self.impulse - 100;
  ent = world;
  do {
   ent = CamCycle(ent);
   c = c - 1;
  } while ((c>0) && (ent != world));
  if (ent != world) {
   if (ent.deadflag == DEAD_NO) {
    CamInitFlybyMode(ent);
    self.delay = time + 10;
    self.search_time = time + 60;  // keep target max. 60 seconds
   }
  }
// Save position
 } else if((self.impulse>=180) && (self.impulse<=189)) {
  c = self.impulse - 180;
  CamSavePos (c);
// Load position
 } else if((self.impulse>=190) && (self.impulse<=199)) {
  c = self.impulse - 190;
  CamLoadPos (c);
// Force FLYBY
 } else if (self.impulse == 200) {
  if (self.enemy != self) {
   CamInitFlybyMode(self.enemy);
  } else {
   ent = CamShoot();
   if (ent != world) {
    CamInitFlybyMode(ent);
    self.delay = time + 10;
    self.search_time = time + 60; // keep target max. 60 seconds
   }
  }
// Force FOLLOW
 } else if (self.impulse == 201) {
  if (self.enemy != self) {
   self.state = CAM_FOLLOW;
  } else {
   ent = CamShoot();
   if (ent != world) {
    self.movetarget = self.enemy = ent;
    if (self.aflag) {
     CamReport(self.enemy,"Now Taking");
    }
    self.state = CAM_FOLLOW;
    self.search_time = time + 60;  // keep target max. 60 seconds
    self.mangle = '0 0 0';
   }
  }
// Force HAND
 } else if (self.impulse == 202) {
  if ((self.state != CAM_FLYBY) && (self.state != CAM_FIXED)) CamHandJump();
  self.state = CAM_HAND;
  self.movetype = MOVETYPE_NONE;
  self.enemy = self;
  self.movetarget = world;
// Force FREE (FLY)
 } else if (self.impulse == 203) {
  self.state = CAM_FREE;
  self.movetype = MOVETYPE_FLY;
  self.enemy = self;
  self.movetarget = world;
// Force NOCLIP
 } else if (self.button2) {//(self.impulse == 204) { //POX v1.2 - JumpButton Forces NOCLIP
  self.state = CAM_NOCLIP;
  self.enemy = self;
  self.movetarget = world;
  self.movetype = MOVETYPE_NOCLIP;
// Force FIXED
 } else if (self.impulse == 205) {
  if ((self.state == CAM_FLYBY) || (self.state == CAM_HAND)) {
   CamSetAuto();
   self.state = CAM_FIXED;
   self.enemy = self;
   self.movetarget = world;
   self.search_time = time + 100000;
   self.pausetime = time + 3;
  }
// Messages ON/OFF
 } else if (self.impulse == 210) {
  self.aflag = (float)!self.aflag;	//FIXME qfcc issue
// Report position
 } else if (self.impulse == 211) {
  bprint("Current camera position: ");
  bprint(vtos(self.origin));
  bprint("\n");
// Messages ON
 } else if (self.impulse == 212) {
  self.aflag = TRUE;
// Messages OFF
 } else if (self.impulse == 213) {
  self.aflag = FALSE;
// FOLLOW always forced
 } else if (self.impulse == 214) {
  self.attack_state = TRUE;
// FOLLOW force normal
 } else if (self.impulse == 215) {
  self.attack_state = FALSE;
// Lock on current target
 } else if (self.impulse == 216) {
  if (self.enemy != self) {
   self.goalentity = self.enemy;
  }
// Switch to next target
 } else if (self.button0) {//(self.impulse == 217) { //POX v1.2 - FireButton Switches Player
  if (self.enemy != self) {
   ent=CamCycle(world);
   while ((ent != world) && (ent != self.enemy)) {
    ent = CamCycle(ent);
   }
   if (ent != world) {
    c = TRUE;
    while (c) {
     ent = CamCycle(ent);
     if (ent == world) {
      ent = CamCycle(ent);
     }
     if (ent == world) {
      c = FALSE;
     } else {
      if (ent.deadflag == DEAD_NO) {
       if (self.goalentity != world) {
	self.goalentity = ent;
       }
       CamInitFlybyMode(ent);
       self.delay = time + 10;
       self.search_time = time + 60;  // keep target max. 60 seconds
       c = FALSE;
      }
     }
    }
   }
  }
 }
 self.impulse = 0;
 self.button0 = 0;//POX v1.2 - clear button hits
 self.button2 = 0;//POX v1.2 - clear button hits
};

// Update camera state according to current target

void() CamUpdValues =
{
 local float it;

 if ((self.enemy != self) && (self.enemy.classname != "bodyque") && (self.enemy.health > 0)) {
// Mask out items which change view color
  it = IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD;
  self.items = (self.enemy.items | it) - it;
  self.health = self.enemy.health;
  self.armorvalue = self.enemy.armorvalue;
  self.ammo_shells = self.enemy.ammo_shells;
  self.ammo_nails = self.enemy.ammo_nails;
  self.ammo_rockets = self.enemy.ammo_rockets;
  self.ammo_cells = self.enemy.ammo_cells;
  self.weapon = self.enemy.weapon;
  self.currentammo = self.enemy.currentammo;
 } else {
  self.items = 0;
  self.health = 111;
  self.armorvalue = 111;
  self.ammo_shells = 111;
  self.ammo_nails = 111;
  self.ammo_rockets = 111;
  self.ammo_cells = 111;
  self.weapon = IT_BONESAW;
  self.currentammo = 111;
 }
};

// Overall health

float(entity ent) CamHealthVal =
{
 local float alldmg;

// First evaluate max damage if infinite armor
 alldmg = ent.health/(1-ent.armortype);
// Test for less armor
 if (alldmg>(ent.health+ent.armorvalue)) {
  alldmg = ent.health+ent.armorvalue;
 }
// And return maximum damage entity can bear
 return alldmg;
};

// IDLE mode think routine

void() CamIdleThink =
{
 local entity ent,ent2;
 local vector vec,vec2;
 local float p1,p2;
 local float pa,pb;

// Prepare a sentinel
 ent2 = self;
 if (self.movetarget != world) {
  if (self.movetarget.deadflag == DEAD_NO) {
   ent2 = self.movetarget;
  }
 }
// try to find some interesting target
 p2 = -1;
 p1 = 5 * random();
 if (self.goalentity != world) {
  if (self.goalentity.deadflag == DEAD_NO) {
   ent2 = self.goalentity;
  } else {
   ent2 = self;
  }
 } else if (p1 < 1) {
  ent = CamCycle(world);
  while (ent != world) {
   if ((ent != self.movetarget) && (ent.deadflag == DEAD_NO)) {
    p1 = CamHealthVal(ent);
    if (p2<p1) {
     ent2 = ent;
     p2 = p1;
    }
   }
   ent = CamCycle(ent);
  }
 } else if (p1 < 2) {
  ent = CamCycle(world);
  while (ent != world) {
// Dead or dying are not interesting at this point
   if ((ent != self.movetarget) && (ent.deadflag == DEAD_NO)) {
    p1 = ent.frags;
    if (p1 < 0) p1 = 0;
    if (p2<p1) {
     ent2 = ent;
     p2 = p1;
    }
   }
   ent = CamCycle(ent);
  }
 } else {
  p2 = 0;
  ent = CamCycle(world);
  while (ent != world) {
   if ((ent != self.movetarget) && (ent.deadflag == DEAD_NO)) {
    p2 = p2 + 1;
   }
   ent = CamCycle(ent);
  }
  if (p2 > 0) {
   p2 = p2 * random();
   ent = world;
   do {
    do {
     ent = CamCycle(ent);
    } while ((ent == self.movetarget) || (ent.deadflag != DEAD_NO));
    p2 = p2 - 1;
   } while (p2 > 0);
   if (ent != world) ent2 = ent;
  }
 }
// If an interesting object found
 if (ent2 != self) {
// Go to FlyBy mode
  CamInitFlybyMode (ent2);
  self.delay = time + 10;
  self.search_time = time + 60;
 } else {
// Idle moves
  self.enemy = self;
  traceline(self.dest, self.dest1, TRUE, self);
  self.dest1 = trace_endpos;
  vec_x = 40 * random () - 20;
  vec_y = 360 * random ();
  vec_z = 0;
  pa = vec_y;
  if (self.origin != self.dest) {
   vec2 = self.origin - self.dest;
   vec2 = vectoangles(vec2);
   pb = vec2_y;
  } else {
   pb = 0;
  }
  pa = CamReAngle(pa);
  makevectors(vec);
  vec = 2000 * v_forward;
  p2 = vlen(self.dest2 - self.dest);
  if (fabs(CamReAngle(pa - pb)) > 60) {
   vec2 = self.dest + vec;
   traceline(self.dest, vec2, TRUE, self);
   vec2 = trace_endpos;
   p1 = vlen(vec2 - self.dest);
   if (p1 > p2) {
    self.dest2 = vec2;
    p2 = p1;
   }
  }
  pa = pa + 180;
  pa = CamReAngle(pa);
  if (fabs(CamReAngle(pa - pb)) > 60) {
   vec2 = self.dest - vec;
   traceline(self.dest, vec2, TRUE, self);
   vec2 = trace_endpos;
   p1 = vlen(vec2 - self.dest);
   if (p1 > p2) {
    self.dest2 = vec2;
    p2 = p1;
   }
  }
  if (self.pausetime < time) {
   self.pausetime = time + 3 + (2 * random());
   self.dest1 = self.dest2;
  }
  if (self.search_time < time) {
   vec = self.dest - self.dest1;
   vec = (5 + (50 * random())) * normalize(vec);
   vec = self.dest1 + vec;
   traceline(self.origin,vec, TRUE, self);
   if (trace_fraction == 1) {
    self.dest = vec;
    self.dest2 = self.dest1;
    self.search_time = time + 8 + (5 * random());
   } else {
    self.dest2 = self.dest;
    self.search_time = time + 1 + random();
   }
  }
 }
};

// FLYBY mode thinking routine

void() CamFlyByThink =
{
 local float p0,p1,grad,p;
 local vector vec;
 local entity ent;

// self.dest1 is set to player
// Check if the player is not dead
 if (self.enemy.deadflag != DEAD_NO) {
   if (time < 31) {
     CamGoIdle();
     return;
   }
   CamGoDeath();
   return;
 }
// All other restrictions apply after some time
// Test player visibility
// If player not visible place another camera
 p1 = vlen(self.dest - self.enemy.origin);
 if ((CamVisibleEnt(self.enemy) && (self.lip > p1)) || (self.pausetime > time)) {
  self.dest1 = CamFlybyTarget(self.enemy);
 } else {
  CamInitFlybyMode (self.enemy);
 }
// Check for FOLLOW mode change
// Player has to be near
// And looking away
// And the destination point must be visible
 if (self.attack_state) {
  self.state = CAM_FOLLOW;
  return;
 } else {
  p1 = vlen(self.enemy.origin - self.origin);
  if (p1 < 170) {
// Player is near enough
// Now if it points away
   grad = fabs(self.enemy.angles_y - self.angles_y);
   if (grad > 180) grad = 360 - grad;
   if (grad < 30) {
// Calculate following point
    vec = GetFollowCam();
    if (CamVisible(vec)) {
     self.state = CAM_FOLLOW;
     return;
    }
   }
  }
 }
// check for FIXED mode change
 if (self.goalentity == world) {
  p0 = 0;
  p1 = 0;
  if (self.delay < time) {
   ent = CamCycle(world);
   while (ent != world) {
    p0 = p0 + 1;
    if (ent.deadflag == DEAD_NO) {
     p = vlen(ent.origin - self.origin);
     if (p < 1500) {
      if (CamVisible(ent.origin)) {
       p1 = p1 + 1;
      }
     }
    }
    ent = CamCycle(ent);
   }
  }
  if (p0<4) {
   p0 = 2;
  } else if (p0<8) {
   p0 = 3;
  } else {
   p0 = 4;
  }
  if (p1 > p0) {
   self.enemy = self;
   self.movetarget = world;
   self.state = CAM_FIXED;
   self.search_time = time + 15;
   self.pausetime = time + 3;
   return;
  }
 }
 if (self.search_time < time) {
  CamGoIdle();
 }
};

// FOLLOW mode thinking routine

void() CamFollowThink =
{
// Check player death
 if (self.enemy.deadflag != DEAD_NO) {
   if (time < 31) {
     CamGoIdle();
     return;
   }
  CamGoDeath();
  return;
 } else {
  if (CamVisibleEnt(self.enemy)) {
   self.dest = GetFollowCam();
   self.dest1 = GetFollowTrg();
   if (pointcontents(self.dest) == CONTENT_SOLID) CamInitFlybyMode(self.enemy);
  } else {
   CamInitFlybyMode(self.enemy);
  }
 }
 if (self.search_time < time) {
  CamGoIdle();
 }
};

// FIXED mode thinking routine

void() CamFixedThink =
{
 local vector vec;
 local entity ent;
 local float cang;
 local float a;
 local float cscr; // count of targets on screen
 local float maxscr; // minimum angle on screen
 local float minscr; // maximum angle on screen
 local float maxlo; // maximum angle of lowers
 local float minhi; // minimum angle of highers
 local vector scrv; // onscreen origin sum
 local vector hiv = '0 0 0'; // lower optimum
 local vector lov = '0 0 0'; // higher optimum
 local float c;

 cang = self.v_angle_y;
 cscr = 0;
 maxscr = -45;
 minscr = 45;
 maxlo = -181;
 minhi = 181;
 scrv = '0 0 0';
 c = 0;
 ent = CamCycle(world);
 while (ent != world) {
  if (ent.deadflag == DEAD_NO) {
   a = vlen(ent.origin - self.origin);
   if (a < 1500) {
    if (CamVisible(ent.origin)) {
// Possible target is visible
// Look if it is "on screen"
     c = c + 1;
     vec = vectoangles(ent.origin - self.origin);
     a = vec_y - cang;
     while (a > 180) a = a - 360;
     while (a < -180) a = a + 360;
     if (fabs(a)<45) {
// entity is "on screen"
      cscr = cscr + 1;
      scrv = scrv + ent.origin;
      if (a < minscr) minscr = a;
      if (a > maxscr) maxscr = a;
     } else {
      if (a > 0) {
       if (a < minhi) {
	minhi = a;
	hiv = ent.origin;
       }
      } else {
       if (a > maxlo) {
	maxlo = a;
	lov = ent.origin;
       }
      }
     }
    }
   }
  }
  ent = CamCycle(ent);
 }
 if (c > 0) {
  if (c > 1) self.pausetime = time + 3;
  if (cscr < c) {
   if ((cscr == 0) || ((maxscr - maxlo) <= 90) || ((minhi - minscr) <= 90)) {
    cscr = cscr + 1;
    if ((maxscr - maxlo) > (minhi - minscr)) {
     scrv = scrv + hiv;
    } else {
     scrv = scrv + lov;
    }
   }
  }
  scrv_x = scrv_x / cscr;
  scrv_y = scrv_y / cscr;
  scrv_z = scrv_z / cscr;
  self.dest1 = scrv;
 }
 self.dest = self.origin;
 if ((self.pausetime < time) || (self.search_time < time)) {
  CamGoIdle();
 }
};

// DEATH mode think
void() CamDeathThink =
{
 local float f;

 if (self.search_time < time) {
  CamGoIdle();
  return;
 }
 if (self.enemy != self) {
  f = vlen(self.origin - self.dest);
  if ((f>1) || (self.mangle != '0 0 0')) {
   f = time + 0.5;
   if (self.pausetime < f) {
    self.pausetime = f;
   }
  }
 }
 if (time > self.pausetime) {
  CamGoIdle();
 } else {
  if (self.enemy != self) {
   self.dest1 = self.enemy.origin;
  }
 }
 if (self.enemy != self) {
  traceline(self.origin,self.dest1,TRUE,self);
  if (trace_fraction != 1){
   if (self.enemy.velocity == '0 0 0') {
    CamGoIdle();
   } else {
    CamInitFlybyMode(self.enemy);
    self.state = CAM_DEATH;
    self.pausetime = time + 2;
   }
  }
  if (self.enemy.velocity != '0 0 0') {
   self.pausetime = time + 2;
  }
 }
 if (vlen(self.dest - self.dest1)>60) {
  self.dest = self.dest - self.dest1;
  self.dest = normalize(self.dest);
  self.dest = 59 * self.dest + self.dest1;
 }
};

/////////////////////////////////////////////////////////////////////////////
// interface functions begin here
/////////////////////////////////////////////////////////////////////////////

// Main camera thinking routine
// Called every frame

void() CamThink =
{
// Update visible values (health, armor, ...)
 CamUpdValues();
 self.velocity = '0 0 0';
 self.avelocity = '0 0 0';
// Status depending handlings
 if (self.state == CAM_IDLE) {
  CamIdleThink();
  CamUpdatePos(1,80);
 } else if (self.state == CAM_FLYBY) {
  CamFlyByThink();
  CamUpdatePos(0,500);
 } else if (self.state == CAM_FOLLOW) {
  CamFollowThink();
  CamUpdatePos(800,1000);
 } else if (self.state == CAM_FIXED) {
  CamFixedThink();
  CamUpdatePos(0,80);
 } else if (self.state == CAM_DEATH) {
  CamDeathThink();
  CamUpdatePos(100,150);
// } else if (self.state == CAM_HAND) { -- nothing to do
// } else if (self.state == CAM_FREE) { -- nothing to do
// } else if (self.state == CAM_NOCLIP) { -- nothing to do
// } else if (self.state == ...
 }
// Impulse handling (standard is not active)
 CamImpulses();
};

// camera initialization

void() CamClientInit =
{
 self.classname = "KasCam";
 setmodel (self, string_null);
 self.weaponmodel = string_null;
 setsize (self, '0 0 0', '0 0 0');
 self.velocity = '0 0 0';
 self.view_ofs = '0 0 0';
 self.movetype = MOVETYPE_NONE;
 self.solid = SOLID_NOT;
 self.takedamage = DAMAGE_NO;
 self.fixangle = TRUE;
 self.nextthink = -1;
 self.colormap = 0;
 self.effects = 0;
 self.rad_time = 1;
 self.radsuit_finished = 0;
 self.invincible_time = 0;
 self.invincible_finished = 0;
 self.invisible_time = 0;
 self.invisible_finished = 0;
 self.super_time = 0;
 self.super_damage_finished = 0;
 self.dest = self.origin;
 makevectors(self.v_angle);
 self.dest1 = self.dest + 100 * v_forward;
 self.enemy = self;
 self.movetarget = world;
 self.goalentity = world;
 self.aflag = TRUE;
 self.mangle = '0 0 0';
 self.pausetime = time;
 self.delay = time;
 self.attack_state = FALSE;
 
 // + POX v1.11 - Late LMS joiner...
 if (self.LMS_late)
 {
	centerprint (self, "Last Man Standing Game in progress...\nObserving until next round.");
	self.attack_finished = time + 10;//Pause the KasCam report function
	stuffcmd (self, "wait;+lookup;wait;+lookdown\n");
 }
 else if (self.LMS_registered)
 {
	centerprint (self, "You have been Eliminated!\nObserving until next round.");
	self.attack_finished = time + 10;//Pause the KasCam report function
	stuffcmd (self, "wait;+lookup;wait;+lookdown\n");
 }
 // - POX v1.11

 CamGoIdle();
 //bprint("Camera running\n");
};

// Main initialization

void() CamSpawn =
{
 local float i;
 local entity ent;
 local entity start;

// find startpoint
 start=find(world,classname,"info_player_start");
// init saved positions
 i=10;
 while (i>0) {
  ent = spawn();
  ent.classname = "CamSavedPos";
  ent.angles = start.angles;
  ent.v_angle = start.v_angle;

//POX - 101b - defaults to player model?
  setmodel (ent, string_null);
  setorigin(ent, start.origin);
  i = i - 1;
 }
};

// Player is disconnecting

float() CamDisconnect =
{
 local entity cam,oself;

 if (self.classname == "KasCam") {
  bprint("Camera deactivated\n");
  return FALSE;
 } else {
  cam = find(world,classname,"KasCam");
  while (cam) {
   if (cam.enemy == self) {
    oself = self;
    self = cam;
    CamGoIdle();
    self = oself;
   }
   if (cam.movetarget == self) {
    cam.movetarget = world;
   }
   cam=find(cam,classname,"KasCam");
  }
  return TRUE;
 }
};

void(entity ent,entity que) CamCopyBody =
{
 local entity oself,cam;

 cam=find(world,classname,"KasCam");
 while (cam) {
  if (ent == cam.enemy) {
// target moved to body queue
   if (cam.state != CAM_DEATH) {
    oself = self;
    self = cam;
    CamGoDeath();
    self = oself;
   }
   cam.enemy = que;
  } else if (que == cam.enemy) {
// queue target used elsewhere
   cam.enemy = cam;
  }
  cam=find(cam,classname,"KasCam");
 }
};

