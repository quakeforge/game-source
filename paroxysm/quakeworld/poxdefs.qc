// POX - bunch of new variable declarations and prototypes for POXworld

//New stuff for timing second triggers and other weapon stuff
.float prime_tshot;		//this is set when tShot is primed for a triple barrel fire
.float st_tshotload;	//used to time out the tSot's trigger during reload

.float st_sshotgun;		//next attack for ComboGun
.float st_pball;		//next attack for Impact grenade
.float which_ammo;		//used to clean up ammo switching for ComboGun

.float st_mplasma;		//next attack for MegaPlasma Burst
.float st_plasma;		//next attack for PlasmaGun
.float LorR;			//sets which barrel to use for next PlasmaGun shot

.float st_mine;			//next attack for PhaseMine
.float st_grenade;		//next attack for Grenades
.float no_obj;			//fixes a problem with 'hanging' mines on breakable objects destroyed be something else
.entity spawnmaster;
.entity lastowner;

.float st_nailgun;		//next attack for Nailgun
.float st_shrapnel;		//next attack for ShrapnelBomb
.float shrap_detonate;	//decide whether to launch or detonate a ShrapnelBomb
.float shrap_time;		//holds the bombs time out (2 minutes then boom) - just in case owner died

.float reload_rocket;	//keeps count of rockets fired
.float st_rocketload;	//used to time out the rhino's trigger during reload

.float missfire_finished;	//used to seperate attacks and missfires (POXnote : DO I STILL NEED THIS?)

.float nobleed;			//set to TRUE for triggers, breakable objects, buttons, etc...

// Footsteps
.float spawnsilent;
.vector old_velocity;

//POX v1.2 REMOVED EARTHQUAKE! (not suitable for DM)
void() func_earthquake = {remove(self);};

//Water Movement
.float uwmuffle;		//underwater muffle sound timeout
.float onwsound;		//on water sound timeout
.float outwsound;		//head out of water sound flag
.float inwsound;		//head in water sound flag

//New DM option constants
float DM_PREDATOR = 2;
float DM_DARK = 4;
float DM_LMS = 8;
float DM_FFA = 16;
float DM_GIB = 32;
float DM_AUTOSWITCH = 128;

float fraglimit_LMS;		// stores the fraglimit at worldspawn so it can't be changed during a game
float lms_plrcount;		// Keeps track of the number of players in an LMS game
float lms_gameover;			// Lets CheckRules know when one or zero players are left
.float LMS_registered;		// prevents players from being counted more than once
.float LMS_observer;		// Bump think to Observer code if TRUE (1 = late, 2 = killed)
.float LMS_observer_fov;	// Stores observer's current fov
.float LMS_zoom;			// 1 = zoom in, 2 = zoom out, 0 = stop
.float LMS_observer_time;	// times the display of observer instructions

//Dark Mode stuff...
.float flash_flag;	// flashlight toggle (no user toggle)
.entity flash;		// flash entity

// Moved here for use in weapons.qc
float	intermission_running;

.float gl_fix;	//a hack for toggling gl_flashblend

//Used by Target ID impulse
.float target_id_finished;
.float target_id_toggle;
.float target_id_same;
.entity last_target_id;
void(entity client, string s1, string s2, string s3, string s4) centerprint4 = #73;

//POX v1.2 - improved reseting of colour_light
.float cshift_finished;
.float cshift_off;

//POX 1.2 - allows idtarget state to be saved across levelchanges
.float target_id_temp;
