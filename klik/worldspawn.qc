#include "common.qh"

void() worldspawn = {
	/* These are used be the server C code, but not precached. Bad iD. */
	precache_sound("misc/h2ohit1.wav");
	precache_sound("demon/dland2.wav");
	precache_sound("misc/r_tele1.wav");
	precache_sound("misc/r_tele2.wav");
	precache_sound("misc/r_tele3.wav");
	precache_sound("misc/r_tele4.wav");
	precache_sound("misc/r_tele5.wav");

	/* Compatibility :) */
	if (self.model == "maps/e1m8.bsp")
		cvar_set("sv_gravity", "100");

	// Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
	// 0 normal
	lightstyle(0, "m");

	// 1 FLICKER (first variety)
	lightstyle(1, "mmnmmommommnonmmonqnmmo");

	// 2 SLOW STRONG PULSE
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

	// 3 CANDLE (first variety)
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

	// 4 FAST STROBE
	lightstyle(4, "ma");
	
	// 5 GENTLE PULSE 1
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

	// 6 FLICKER (second variety)
	lightstyle(6, "nmonqnmomnmomomno");

	// 7 CANDLE (second variety)
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

	// 8 CANDLE (third variety)
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

	// 9 SLOW STROBE (fourth variety)
	lightstyle(9, "aaaaaaaazzzzzzzz");

	// 10 FLUORESCENT FLICKER
	lightstyle(10, "mmamammmmammamamaaamammma");

	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

	// styles 32-62 are assigned by the light program for switchable lights

	main();
};
