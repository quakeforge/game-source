/* 
	quakeworld.r

	QuakeWorld constant definitions

	Copyright (C) 2002 Dusk to Dawn Computing, Inc.
	Portions Copyright (C) 1996-1997 Id Software, Inc.

	This program is free software you can redistribute it and/or modify it
	under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation either version 2.1 of the License, or (at
	your option) any later version.

	This program is distributed in the hope that it will be useful,	but
	WITHOUT ANY WARRANTY without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this program if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

	$Id$
*/

#define	FALSE				0
#define	TRUE				1

/* Entity flags, for the .flags field (a bit field) */
#define	FL_FLY				1		// Entity is flying
#define	FL_SWIM				2
#define	FL_CLIENT			8		// Set for all client entities
#define	FL_INWATER			16		// Set for entities that are in water
#define	FL_MONSTER			32		// Entity is a monster
#define	FL_GODMODE			64		// Entity has "god mode"
#define	FL_NOTARGET			128		// Entity is not targeted by monsters
#define	FL_ITEM				256		// Extra wide size, for bonus items
#define	FL_ONGROUND			512		// Entity is completely standing on something
#define	FL_PARTIALGROUND	1024	// Not all corners are valid
#define	FL_WATERJUMP		2048	// Entity is a player jumping out of water
#define	FL_JUMPRELEASED		4096	// For jump debouncing (no pogo stick)

/* Valid values for the .movetype field	*/
#define	MOVETYPE_NONE			0	// Does not move
#if 0
# define	MOVETYPE_ANGLENOCLIP	1
# define	MOVETYPE_ANGLECLIP		2
#endif
#define	MOVETYPE_WALK			3	// Only players can have this movement type
#define	MOVETYPE_STEP			4	// Discrete, not real time unless fall
#define	MOVETYPE_FLY			5	// Not affected by gravity
#define	MOVETYPE_TOSS			6	// Use gravity to calculate trajectory
#define	MOVETYPE_PUSH			7	// Not clipped to world, can push and crush players
#define	MOVETYPE_NOCLIP			8	// Not clipped at all
#define	MOVETYPE_FLYMISSILE		9	// Flying with extra size against monsters
#define	MOVETYPE_BOUNCE			10	// Bounces off solid objects, use 
#define	MOVETYPE_BOUNCEMISSILE	11	// Bounces with extra size

/* Valid values for the .solid field */
#define	SOLID_NOT			0		// Does not interact with other objects
#define	SOLID_TRIGGER		1		// .touch called, but don't block movement
#define	SOLID_BBOX			2		// .touch called and block movement
#define	SOLID_SLIDEBOX		3		// .touch on edge, don't block if FL_ONGROUND
#define	SOLID_BSP			4		// BSP clip, .touch on edge, block movement

/* Range values */
#define	RANGE_MELEE			0
#define	RANGE_NEAR			1
#define	RANGE_MID			2
#define	RANGE_FAR			3

/* Valid values for the .deadflag field */
#define	DEAD_NO				0		// Not dead
#define	DEAD_DYING			1		// Dying, will be dead soon
#define	DEAD_DEAD			2		// E's shuffled off his mortal coil
#define	DEAD_RESPAWNABLE	3		// Dead, but can respawn

/* Valid values for the .takedamage field */
#define	DAMAGE_NO			0		// Does not take damage
#define	DAMAGE_YES			1		// Takes all damage
#define	DAMAGE_AIM			2		// Takes only direct damage

/* Item flags */					// Weapons
#define	IT_AXE				4096
#define	IT_SHOTGUN			1
#define	IT_SUPER_SHOTGUN	2
#define	IT_NAILGUN			4
#define	IT_SUPER_NAILGUN	8
#define	IT_GRENADE_LAUNCHER	16
#define	IT_ROCKET_LAUNCHER	32
#define	IT_LIGHTNING		64
#define	IT_EXTRA_WEAPON		128
									// Ammo
#define	IT_SHELLS			256
#define	IT_NAILS			512
#define	IT_ROCKETS			1024
#define	IT_CELLS			2048
									// Armor types
#define	IT_ARMOR1			8192
#define	IT_ARMOR2			16384
#define	IT_ARMOR3			32768
									// Keys
#define	IT_KEY1				131072
#define	IT_KEY2				262144
									// Special items
#define	IT_SUPERHEALTH		65536	// Megahealth
#define	IT_INVISIBILITY		524288	// Ring of shadows
#define	IT_INVULNERABILITY	1048576	// Pentagram of Protection
#define	IT_SUIT				2097152	// Biosuit
#define	IT_QUAD				4194304	// Quad Damage

/* Values returned by pointcontents() */
#define	CONTENT_EMPTY		-1		// Point is in the air somewhere
#define	CONTENT_SOLID		-2		// Point is outside the world
#define	CONTENT_WATER		-3		// Point is in water
#define	CONTENT_SLIME		-4		// Point is in slime
#define	CONTENT_LAVA		-5		// Point is in lava
#define	CONTENT_SKY			-6		// Point is beyond the sky

#define	STATE_TOP			0
#define	STATE_BOTTOM		1
#define	STATE_UP			2
#define	STATE_DOWN			3

#define VEC_ORIGIN			'0 0 0'	// the origin of a 3D object

									// defines the bounding box of a player
#define VEC_HULL_MIN		'-16 -16 -24'
#define VEC_HULL_MAX		'16 16 32'

									// defines the bounding box of some monsters
#define VEC_HULL2_MIN		'-32 -32 -24'
#define VEC_HULL2_MAX		'32 32 64'

// Protocol bytes
#define	SVC_TEMPENTITY		23		// server -> client: create temp entity
#define	SVC_KILLEDMONSTER	27		// server -> client: killed a  monster
#define	SVC_FOUNDSECRET		28		// server -> client: found a secret
#define	SVC_INTERMISSION	30		// server -> client: intermission start
#define	SVC_FINALE			31		// server -> client: game over
#define	SVC_CDTRACK			32		// server -> client: set CD audio track
#define	SVC_SELLSCREEN		33		// server -> client: show "nag" screen
#define	SVC_SMALLKICK		34		// server -> client: 
#define	SVC_BIGKICK			35		// server -> client: 
#define	SVC_MUZZLEFLASH		39		// server -> client: place a glow

// Useful things SVC_TEMPENTITY can create
#define	TE_SPIKE			0		// A nail
#define	TE_SUPERSPIKE		1		// A big nail
#define	TE_GUNSHOT			2		// Gunshot hitting a wall
#define	TE_EXPLOSION		3		// Rocket/grenade explosion
#define	TE_TAREXPLOSION		4		// "tarbaby" explosion
#define	TE_LIGHTNING1		5
#define	TE_LIGHTNING2		6
#define	TE_WIZSPIKE			7		// Yellow trail from the Scragg
#define	TE_KNIGHTSPIKE		8		// The Death Knight's ranged attack
#define	TE_LIGHTNING3		9
#define	TE_LAVASPLASH		10
#define	TE_TELEPORT			11		// Teleportation effect
#define	TE_BLOOD			12		// Blood puff
#define	TE_LIGHTNINGBLOOD	13

/*
	Sound channels

	Channel 0 never willingly overrides anything.
	Other channels (1-7) always override a sound playing on that channel.
*/
#define	CHAN_AUTO			0	// Pick a free channel if available
#define	CHAN_WEAPON			1	// Player's weapon
#define	CHAN_VOICE			2	// Player's voice
#define	CHAN_ITEM			3
#define	CHAN_BODY			4	// Player's body (footsteps, etc)
// special sound flags (OR together with a channel)
#define	CHAN_NO_PHS_ADD		8	// Do not add to the PHS

/* Sound attenuation for distance */
#define	ATTN_NONE			0	// No fadeout (whole world)
#define	ATTN_NORM			1
#define	ATTN_IDLE			2
#define	ATTN_STATIC			3

// update types
#define	UPDATE_GENERAL		0
#define	UPDATE_STATIC		1
#define	UPDATE_BINARY		2
#define	UPDATE_TEMP			3

/* entity effects */
#if 0	// Removed for unknown reasons
# define	EF_BRIGHTFIELD	1
# define	EF_MUZZLEFLASH	2
#endif
#define	EF_BRIGHTLIGHT		4
#define	EF_DIMLIGHT			8
#define	EF_FLAG1			16		// CTF hack, attach flag 1
#define	EF_FLAG2			32		// CTF hack, attach flag 2
// GLQuakeWorld Stuff
#define	EF_BLUE				64		// Blue dlight effect, for Quad
#define	EF_RED				128		// Red dlight effect, for Pentagram

/* Message types */
#define	MSG_BROADCAST		0		// unreliable to all
#define	MSG_ONE				1		// reliable to one (msg_entity)
#define	MSG_ALL				2		// reliable to all
#define	MSG_INIT			3		// write to the init string
#define	MSG_MULTICAST		4		// for multicast() call

/* Message priority levels */
#define	PRINT_LOW			0		// Bonus pickup messages
#define	PRINT_MEDIUM		1		// death messages
#define	PRINT_HIGH			2		// critical messages
#define	PRINT_CHAT			3		// also goes to chat console

// multicast sets
#define	MULTICAST_ALL		0		// every client
#define	MULTICAST_PHS		1		// within hearing
#define	MULTICAST_PVS		2		// within sight
#define	MULTICAST_ALL_R		3		// every client, reliable
#define	MULTICAST_PHS_R		4		// within hearing, reliable
#define	MULTICAST_PVS_R		5		// within sight, reliable
