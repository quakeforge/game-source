//Paroxysm DM Setup Menu - by Frank Condello (pox@planetquake.com)

//Called when on the start map - basically takes control of the player and only allows menu specific impulses



//This allows multiple strings variables to be centre printed

void(entity client, string s1) menucenterprint1 = #73;

void(entity client, string s1, string s2) menucenterprint2 = #73;

void(entity client, string s1, string s2, string s3) menucenterprint3 = #73;

void(entity client, string s1, string s2, string s3, string s4) menucenterprint4 = #73;

void(entity client, string s1, string s2, string s3, string s4, string s5) menucenterprint5 = #73;

void(entity client, string s1, string s2, string s3, string s4, string s5, string s6) menucenterprint6 = #73;

void(entity client, string s1, string s2, string s3, string s4, string s5, string s6, string s7) menucenterprint7 = #73;



float dm_selected;

float button_off;

void() DisplayRules;



void() CalcDM_Value =

{

local string setdm;

local float holddm;



	holddm = cvar("deathmatch");



	if (dm_selected == 1)

	{

		if (holddm & DM_PREDATOR)

			holddm = holddm - DM_PREDATOR;

		else

			holddm = holddm + DM_PREDATOR;

	}

	

	if (dm_selected == 2)

	{

		if (holddm & DM_DARK)

			holddm = holddm - DM_DARK;

		else

			holddm = holddm + DM_DARK;

	}

	

	if (dm_selected == 3)

	{

		if (holddm & DM_LMS)

			holddm = holddm - DM_LMS;

		else

			holddm = holddm + DM_LMS;

	}



	

	if (dm_selected == 4)

	{

		if (holddm & DM_FFA)

			holddm = holddm - DM_FFA;

		else

			holddm = holddm + DM_FFA;

	}

	

	if (dm_selected == 5)

	{

		if (holddm & DM_GIB)

			holddm = holddm - DM_GIB;

		else

			holddm = holddm + DM_GIB;

	}

	

	if (dm_selected == 6)

	{

		if (holddm & DM_AUTOSWITCH)

			holddm = holddm - DM_AUTOSWITCH;

		else

			holddm = holddm + DM_AUTOSWITCH;

	}

	

	if (dm_selected == 7)

	{

		if (holddm & DM_NOBOTS)

			holddm = holddm - DM_NOBOTS;

		else

			holddm = holddm + DM_NOBOTS;

	}



	setdm = ftos(holddm);

	cvar_set ("deathmatch", setdm);



};



//Check for key presses

void()	MenuImpulses =

{

	if (self.impulse == 10) //Cycle forward

	{

		sound (self, CHAN_AUTO, "misc/menu1.wav", 1, ATTN_NONE);

		dm_selected = dm_selected + 1;

		if (dm_selected == 8)

			dm_selected = 1;

	}

	

	if (self.impulse == 12) //Cycle Backward

	{

		sound (self, CHAN_AUTO, "misc/menu1.wav", 1, ATTN_NONE);

		dm_selected = dm_selected - 1;

		if (dm_selected == 0)

			dm_selected = 7;

	}

	

	//POX - 1.01b - Display Server Rules Impulse

	if (self.impulse == 253)

		DisplayRules();

	

	//button_off negates 'auto-fire' problems

	if ((self.button0 || self.button2) && button_off == TRUE)

	{

		sound (self, CHAN_AUTO, "misc/menu2.wav", 1, ATTN_NONE);

		CalcDM_Value();

		button_off = FALSE;

		return; 

	}

	

	if (!self.button0 && !self.button2)

		button_off = TRUE;

	

};





//Called at PlayerPostThink, updates the printed display

void()	MenuThink =

{	

local string pred, dark, lms, ffa, gib, autos, nobots;

	

	if (self.classname == "player")

	{

		centerprint (self, "Please Wait.\nThe server is being configured");

		return;

	}

	

	if (cvar("deathmatch") & DM_PREDATOR)

	{

		if (dm_selected == 1)

			pred = "Óåòöåò Òõìåó\n\n>on  | Predator Mode	\n";

		else

			pred = "Óåòöåò Òõìåó\n\n on  | Predator Mode	\n";

	}

	else

	{

		if (dm_selected == 1)

			pred = "Óåòöåò Òõìåó\n\n>ÏÆÆ | Predator Mode	\n";

		else

			pred = "Óåòöåò Òõìåó\n\n ÏÆÆ | Predator Mode	\n";

	}

	

	if (cvar("deathmatch") & DM_DARK)

	{

		if (dm_selected == 2)

			dark = ">on  | Dark Mode	\n";

		else

			dark = " on  | Dark Mode	\n";

	}

	else

	{

		if (dm_selected == 2)

			dark = ">ÏÆÆ | Dark Mode	\n";

		else

			dark = " ÏÆÆ | Dark Mode	\n";

	}



	if (cvar("deathmatch") & DM_LMS)

	{

		if (dm_selected == 3)

			lms = ">on  | Last Man Standing\n";

		else

			lms = " on  | Last Man Standing\n";

	}

	else

	{

		if (dm_selected == 3)

			lms = ">ÏÆÆ | Last Man Standing\n";

		else

			lms = " ÏÆÆ | Last Man Standing\n";

	}



	if (cvar("deathmatch") & DM_FFA)

	{

		if (dm_selected == 4)

			ffa = ">on  | Free For All     \n";

		else

			ffa = " on  | Free For All     \n";

	}

	else

	{

		if (dm_selected == 4)

			ffa = ">ÏÆÆ | Free For All     \n";

		else

			ffa = " ÏÆÆ | Free For All     \n";

	}

	

	if (cvar("deathmatch") & DM_GIB)

	{

		if (dm_selected == 5)

			gib = ">on  | Gib	       \n";

		else

			gib = " on  | Gib	       \n";

	}

	else

	{

		if (dm_selected == 5)

			gib = ">ÏÆÆ | Gib	       \n";

		else

			gib = " ÏÆÆ | Gib	       \n";

	}

	

	if (cvar("deathmatch") & DM_AUTOSWITCH)

	{

		if (dm_selected == 6)

			autos = ">on  | Weapon Autoswitch\n";

		else

			autos = " on  | Weapon Autoswitch\n";

	}

	else

	{

		if (dm_selected == 6)

			autos = ">ÏÆÆ | Weapon Autoswitch\n";

		else

			autos = " ÏÆÆ | Weapon Autoswitch\n";

	}

		

	if (cvar("deathmatch") & DM_NOBOTS)

	{

		if (dm_selected == 7)

			nobots = ">ÏÆÆ | Bots		  \n\n\n\nUse Weapon Cycle keys to select,\nPress Fire or Jump to toggle.";

		else

			nobots = " ÏÆÆ | Bots		  \n\n\n\nUse Weapon Cycle keys to select,\nPress Fire or Jump to toggle.";

	}

	else

	{

		if (dm_selected == 7)

			nobots = ">on  | Bots		  \n\n\n\nUse Weapon Cycle keys to select,\nPress Fire or Jump to toggle.";

		else

			nobots = " on  | Bots		  \n\n\n\nUse Weapon Cycle keys to select,\nPress Fire or Jump to toggle.";

	}



	menucenterprint7 (self, pred, dark, lms, ffa, gib, autos, nobots);

	

	MenuImpulses();

	self.impulse = 0;

	

};





//Null out the player

void()	InitMenu =

{

local entity other;

 

	setmodel (self, "");

	self.weaponmodel = "";

	setsize (self, '0 0 0', '0 0 0');

	self.velocity = '0 0 0';

	self.view_ofs = '0 0 0';

	self.movetype = MOVETYPE_NONE;

	self.solid = SOLID_NOT;

	self.takedamage = DAMAGE_NO;

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

	self.attack_state = FALSE;

 

	other = find (world, classname, "dmmenu");

 

	if (other != world)

		self.classname = "player";

	else

	{	

		self.classname = "dmmenu";

		dm_selected = 1;

	}



};

