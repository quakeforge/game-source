
void() NOTHING_function = {};

// ========================================================================== //
// ========================================================================== //

/* Fields in maps */

// not used by the gamecode, but some utils leave it.
.float          light_lev;
.float          style;

// worldspawn
.string		wad;
.string		map;
.float		worldtype;	// 0=medieval 1=metal 2=base

// various triggers
.string		killtarget;
.float		wait;		// time from firing to restarting
.float		delay;		// time from activation to firing
.float		count;		// for counting triggers

// plats, doors, trains, etc
.float		speed;
.float		dmg;			// damage done by door when hit
.float		lip;
.float		state;
.float		height;

// secret doors
.float          t_length, t_width;

// various
.vector		mangle;			// angle at start


/* Custom klik stuff, to be used in maps */

// for sounds
.float		volume, attenuation;
.string		noise4;

.string noise5, noise6;		// can't activate, can activate.
.string noise7;			// for items, respawn

// ========================================================================== //
// ========================================================================== //

#if 0
// used by QSG engines
.float		alpha, scale;
.float		glow_size, glow_color;
.vector		colormod;
#endif

// plats, doors, trains, etc
.vector		pos1, pos2;
.void()		think1;

// Per-player modifiers
.float		gravity;		// Gravity Multiplier (0 to 1.0)
.float		maxspeed;		// Used to set Maxspeed on a player

// ========================================================================== //
// ========================================================================== //

.float mass;			// for projectile collisions

.float currency;

.float max_armor;

.float max_ammo_shells;
.float max_ammo_nails;
.float max_ammo_rockets;
.float max_ammo_cells;

.float air_finished;	// Air left in lungs
.float water_finished;	// swim sound
.float pain_finished;	// pain sound

// ========================================================================== //
// ========================================================================== //
