#include "common.qh"

#include "server.qh"
#include "protocol.qh"
#include "misc.qh"

float sv_spawning;

/*
	All this crap is to make sure we don't overflow the signon
	buffer or message buffer, since Quake doesn't bother to
	just split the messages for us.

	And since, at best, it will crash with an error if the buffer
	gets overflowed.
*/

// ========================================================================
// Don't change these unless you know what you're doing.

#define	SV_SIGNON_BUFFERS	8
#define	SV_SIGNON_BUFFER_SWAP	512

// QF == 1, twilight/stock == 0
#define	SV_FLUSHSIGNON_BREAKS	1

#define	SV_MAX_DATAGRAM		1450
#define	SV_FRAME_OVERHEAD	725	/* Wild guess. */

#define	SIZEOF_BASELINE		22
#define	SIZEOF_AMBIENTSOUND	16
#define	SIZEOF_MAKESTATIC	20

// ========================================================================

float sv_signon_buf_remaining;
float sv_signon_remaining;
float sv_frame_remaining;

// =================

float(float space) SZ_GetSpace_frame = {
	if (sv_frame_remaining < space)
		return FALSE;

	sv_frame_remaining -= space;
	return TRUE;
};

entity SZ_self;
float(float space) SZ_GetSpace_signon = {
	if (sv_spawning || !SV_FLUSHSIGNON_BREAKS) {
		if (self != SZ_self) {
			SZ_self = self;

			if (sv_signon_remaining < (SV_MAX_DATAGRAM - 512)) {
				if (--sv_signon_buf_remaining <= 0)
					return FALSE;

				sv_signon_remaining = SV_MAX_DATAGRAM;
			}
		}
	}

	if (sv_signon_remaining < space)
		return FALSE;

	sv_signon_remaining -= space;

	return TRUE;
};

// =================

void() SZ_init = {
	sv_signon_buf_remaining = SV_SIGNON_BUFFERS;
	sv_signon_remaining = SV_MAX_DATAGRAM;

	while ((self = nextent(self)))
		SZ_GetSpace_signon(SIZEOF_BASELINE);
	self = world;
};

void() SZ_frame = {
	sv_frame_remaining = SV_MAX_DATAGRAM - SV_FRAME_OVERHEAD;
};

// =================

void(entity e) makestatic = {
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_NONE;
	e.velocity = '0 0 0';
	e.avelocity = '0 0 0';
	e.nextthink = -1;

	/* No more space?  Just let it be... */
	if (!SZ_GetSpace_signon(SIZEOF_MAKESTATIC))
		return;

	if (!sv_spawning) {
		if (!SZ_GetSpace_frame(SIZEOF_MAKESTATIC)) {
			self.think = SUB_makestatic;
			self.nextthink = time + sv_mintic;
			return;
		}

		WriteByte(MSG_ALL, SVC_MAKESTATIC);

		WriteByte(MSG_ALL, e.modelindex);

		WriteByte(MSG_ALL, e.frame);
		WriteByte(MSG_ALL, e.colormap);
		WriteByte(MSG_ALL, e.skin);
		
		WriteCoord(MSG_ALL, e.origin_x);
		WriteCoord(MSG_ALL, e.origin_y);
		WriteCoord(MSG_ALL, e.origin_z);

		WriteAngle(MSG_ALL, e.angles_x);
		WriteAngle(MSG_ALL, e.angles_y);
		WriteAngle(MSG_ALL, e.angles_z);
	}

	BUILTIN_makestatic(e);
};

void(vector pos, string samp, float vol, float atten) ambientsound = {
	if (!sv_spawning)
		error("ambientsound after spawn functions\n");

	SZ_GetSpace_signon(SIZEOF_AMBIENTSOUND);

	/* Do it anyway */
	BUILTIN_ambientsound(pos, samp, vol, atten);
};

