/* 
	builtins.r

	Master builtins list

	Copyright (C) 2002 Jeff Teunissen <deek@d2dc.net>

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation; either version 2.1 of the License, or (at
	your option) any later version.

	This program is distributed in the hope that it will be useful,	but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

	$Id$
*/

#include "config.rh"

/****************************************************************************
 *								MATH FUNCTIONS								*
 ****************************************************************************/

/*
	ceil

	Returns v, rounded up to the next higher integer
*/
float (float v) ceil = #38;

/*
	fabs

	Returns the absolute value of v
*/
float (float v) fabs = #43;

/*
	floor

	Returns v, rounded down to the next lower integer
*/
float (float v) floor = #37;

/*
	makevectors

	Sets v_forward, v_up, v_right global vectors from the vector ang
*/
void (vector ang) makevectors = #1;

/*
	normalize

	Transform vector v into a unit vector (a vector with a length of 1)
*/
vector (vector v) normalize = #9;

/*
	random

	Generate a random number such that 0 <= num <= 1
*/
float () random = #7;

/*
	rint

	Returns v, rounded to the closest integer. x.5 rounds up.
*/
float (float v) rint = #36;

/*
	vectoangles

	Returns a vector 'pitch yaw 0' corresponding to vector v.
*/
vector (vector v) vectoangles = #51;

/*
	vectoyaw

	Returns the yaw angle ("bearing"), in degrees, associated with vector v.
*/
float (vector v) vectoyaw = #13;
/*
	vlen

	Return the length of vector v
*/
float (vector v) vlen = #12;

/****************************************************************************
 *								ENTITY FUNCTIONS							*
 ****************************************************************************/

/*
	makestatic

	Make entity e static (part of the world).
	Static entities do not interact with the game.
*/
void (entity e) makestatic = #69;

/*
	remove

	Remove entity e.
*/
void (entity e) remove = #15;

/*
	setmodel

	Sets the model name for entity e to string m.
	Set the entity's move type and solid type before calling.
*/
void (entity e, string m) setmodel = #3;

/*
	setorigin

	Sets origin for entity e to vector o.
*/
void (entity e, vector o) setorigin = #2;

/*
	setsize

	Set the size of entity e to a cube with the bounds ( x1 y1 z1 ) ( x2 y2 z2 )
*/
void (entity e, vector min, vector max) setsize = #4;

/*
	spawn

	Creates a new entity and returns it.
*/
entity () spawn = #14;

// -------------------------------------------------------------------------

/****************************************************************************
 *							DEBUGGING FUNCTIONS								*
 ****************************************************************************/

/*
	abort (in QuakeC, this was break)

	Tell the engine to abort (stop) code processing.
*/
void () abort = #6;

/*
	coredump

	Tell the engine to print all edicts (entities)
*/
void () coredump = #28;

/*
	traceon

	Enable instruction trace in the interpreter
*/
void () traceon = #29;

/*
	traceoff

	Disable instruction trace in the interpreter
*/
void () traceoff = #30;

/*
	eprint

	Print all information on an entity to the server console
*/
void (entity e) eprint = #31;

/****************************************************************************
 *							CLIENT/SERVER FUNCTIONS							*
 ****************************************************************************/

/*
	cvar

	Get the value of one of the server's configuration variables.
	Doesn't really supply anything useful for string or vector Cvars.
*/
float (string s) cvar = #45;

/*
	cvar_set

	Set the value of one of the server's configuration variables.
*/
void (string var, string val) cvar_set = #72;

/*
	infokey

	Get an info key for an entity. Using an entity of zero (world) reads the
	serverinfo/localinfo.
*/
#ifdef QUAKEWORLD
string (entity e, string key) infokey = #80;

/*
	setinfokey (QuakeForge-only)

	Set an info key for an entity. Using an entity of zero (world) sets a key
	in the server's localinfo. Does nothing if the entity is not a player.
*/
# ifndef __VERSION6__
void (entity e, string key, string value) setinfokey = #102;
# endif
#endif

#if 0
	PR_AddBuiltin (pr, "vectoyaw", PF_vectoyaw, 13);	// float (vector v) vectoyaw
	PR_AddBuiltin (pr, "find", PF_Find, 18);	// entity (entity start, .(...) fld, ... match) find
	PR_AddBuiltin (pr, "dprint", PF_dprint, 25);  // void (string s) dprint
#endif
