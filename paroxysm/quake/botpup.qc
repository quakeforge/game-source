/*
================
BotCheckPowerups

Modified Player CheckPowerup for use with POXbots.
This just checks if powerups are active - see botgrab.qc for the actuall pickup routines
================
*/

.float	bot_health_rot; //POX - Seperate time out for Bot's Mega Health rot since bot think times vary
.float	skinsave;		//POX - Saves skin value when playing predator mode (for head gibs)

.float	armor_rot;		//POX - Holds the armor rot time out (also used for real clients)

void(entity bot) BotCheckPowerups =
{
	if (bot.health <= 0)
		return;

//POX - 1.01b
//================
// Armour Rot
//================


	if (bot.armorvalue > 150 && bot.armor_rot < time)
	{
		bot.armorvalue = bot.armorvalue - 1;
		bot.armor_rot = time + 1;
		
	//POX v1.1 - change armour to Yellow
	if (bot.armorvalue == 150)
		bot.items &= ~(IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3);
		bot.items |= IT_ARMOR2;
	}


//================
// Megahealth Rot
//================

	if (bot.health > bot.max_health && bot.bot_health_rot < time)
	{
		bot.health = bot.health - 1;
		bot.bot_health_rot = time + 1;
	}


//================
// invisibility
//================

// invisibility
	if (bot.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (bot.invisible_sound < time)
		{
			sound (bot, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			bot.invisible_sound = time + ((random() * 3) + 1);
		}


		if (bot.invisible_finished < time + 3)
		{
			if (bot.invisible_time == 1)
			{
				sound (bot, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				bot.invisible_time = time + 1;
			}
			
			if (bot.invisible_time < time)
				bot.invisible_time = time + 1;
		}

		if (bot.invisible_finished < time)
		{	// just stopped
			bot.items = bot.items - IT_INVISIBILITY;
			bot.invisible_finished = 0;
			bot.invisible_time = 0;
		}
		
	// use the eyes
		bot.frame = 0;
		bot.modelindex = modelindex_eyes;
		bot.skin = 0; // for proper eye skin
	}
	else
	{
		getmodel(bot.weapon, bot);
		bot.skin = bot.skinsave;
	}

//================
// invincibility
//================

	if (bot.invincible_finished)
	{
// sound and screen flash when items starts to run out
		if (bot.invincible_finished < time + 3)
		{
			if (bot.invincible_time == 1)
			{
				//sprint (bot, "Protection is almost burned out\n");
				//stuffcmd (bot, "bf\n");
				sound (bot, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				bot.invincible_time = time + 1;
			}
			
			if (bot.invincible_time < time)
			{
				bot.invincible_time = time + 1;
				//stuffcmd (bot, "bf\n");
			}
		}
		
		if (bot.invincible_finished < time)
		{	// just stopped
			bot.items = bot.items - IT_INVULNERABILITY;
			bot.invincible_time = 0;
			bot.invincible_finished = 0;
		}
		
		if (!(deathmatch & DM_DARK))
		{
			if (bot.invincible_finished > time)
				bot.effects |= EF_DIMLIGHT;
			else
				bot.effects &= ~EF_DIMLIGHT;
		}
	}

//================
// super damage
//================

	if (bot.super_damage_finished)
	{

// sound and screen flash when items starts to run out

		if (bot.super_damage_finished < time + 3)
		{
			if (bot.super_time == 1)
			{
				//sprint (bot, "Quad Damage is wearing off\n");
				//stuffcmd (bot, "bf\n");
				sound (bot, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				bot.super_time = time + 1;
			}	  
			
			if (bot.super_time < time)
			{
				bot.super_time = time + 1;
				//stuffcmd (bot, "bf\n");
			}
		}

		if (bot.super_damage_finished < time)
		{	// just stopped
			bot.items = bot.items - IT_QUAD;
			bot.super_damage_finished = 0;
			bot.super_time = 0;
		}
		
		
		if (!(deathmatch & DM_DARK))
		{
			if (bot.super_damage_finished > time)
				bot.effects |= EF_DIMLIGHT;
			else
				bot.effects &= ~EF_DIMLIGHT;
		}
	}	

//================
// suit
//================

	if (bot.radsuit_finished)
	{
		bot.air_finished = time + 12;		// don't drown

// sound and screen flash when items starts to run out
		if (bot.radsuit_finished < time + 3)
		{
			if (bot.rad_time == 1)
			{
				//sprint (bot, "Air supply in Biosuit expiring\n");
				//stuffcmd (bot, "bf\n");
				sound (bot, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				bot.rad_time = time + 1;
			}
			
			if (bot.rad_time < time)
			{
				bot.rad_time = time + 1;
				//stuffcmd (bot, "bf\n");
			}
		}

		if (bot.radsuit_finished < time)
		{	// just stopped
			bot.items = bot.items - IT_SUIT;
			bot.rad_time = 0;
			bot.radsuit_finished = 0;
		}
	}	

};
