/***********************************************
*                                              *
*                FrikBot Physics               *
*        The near-perfect emulation of         *
*                Client movement               *
*                                              *
*         Special Thanks to: Asdf, Frog        *
*             Alan "Strider" Kivlin            *
*                                              *
*                                              *
***********************************************/

/*

This program is in the Public Domain. My crack legal
team would like to add:

RYAN "FRIKAC" SMITH IS PROVIDING THIS SOFTWARE "AS IS"
AND MAKES NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE
ACCURACY, CAPABILITY, EFFICIENCY, MERCHANTABILITY, OR
FUNCTIONING OF THIS SOFTWARE AND/OR DOCUMENTATION. IN
NO EVENT WILL RYAN "FRIKAC" SMITH BE LIABLE FOR ANY
GENERAL, CONSEQUENTIAL, INDIRECT, INCIDENTAL,
EXEMPLARY, OR SPECIAL DAMAGES, EVEN IF RYAN "FRIKAC"
SMITH HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES, IRRESPECTIVE OF THE CAUSE OF SUCH DAMAGES. 

You accept this software on the condition that you
indemnify and hold harmless Ryan "FrikaC" Smith from
any and all liability or damages to third parties,
including attorney fees, court costs, and other
related costs and expenses, arising out of your use
of this software irrespective of the cause of said
liability. 

The export from the United States or the subsequent
reexport of this software is subject to compliance
with United States export control and munitions
control restrictions. You agree that in the event you
seek to export this software, you assume full
responsibility for obtaining all necessary export
licenses and approvals and for assuring compliance
with applicable reexport restrictions. 

Any reproduction of this software must contain
this notice in its entirety. 

*/

#include "libfrikbot.h"

float (integer keys, integer key) key_state =
{
	return ((keys & key) != 0) ? 1.0 : 0.0;
};

@implementation Bot (Physics)

-(void)sendMove
{
	local vector movevect = '0 0 0';
	local float anglespeed;
	local vector view;

	if (keys != oldkeys) {
		movevect.y += (350 * key_state (keys, KEY_MOVERIGHT));
		movevect.y -= (350 * key_state (keys, KEY_MOVELEFT));

		movevect.x += (200 * key_state (keys, KEY_MOVEFORWARD));
		movevect.x -= (200 * key_state (keys, KEY_MOVEBACK));

		movevect.z += (200 * key_state (keys, KEY_MOVEUP));
		movevect.z -= (200 * key_state (keys, KEY_MOVEDOWN));

		if (!(b_aiflags & AI_PRECISION))
			movevect *= 2;
	}

	if (b_skill != 2) {
		// use mouse emulation
		anglespeed = 1.5 * real_frametime;
		// 1.5 is the default cl_anglespeedkey & bot always has +speed
		v_angle.y += anglespeed * key_state (keys, KEY_LOOKLEFT) * 140;
		// 140 is default cl_yawspeed
		v_angle.y -= anglespeed * key_state (keys, KEY_LOOKRIGHT) * 140;
		// 140 is default cl_yawspeed
		v_angle.x -= anglespeed * key_state (keys, KEY_LOOKUP) * 150;
		// 150 is default cl_pitchspeed
		v_angle.x += anglespeed * key_state (keys, KEY_LOOKDOWN) * 150;
		// 150 is default cl_pitchspeed
	} else {
		view.x = angcomp (b_angle.x, v_angle.x);
		view.y = angcomp (b_angle.y, v_angle.y);
		view.z = 0;
		if (vlen (view) > 30) {
			mouse_emu += (view * 30);
			if (vlen(mouse_emu) > 180)
				mouse_emu = normalize (mouse_emu) * 180;
		} else
			mouse_emu = view * (1 / real_frametime);
		v_angle += mouse_emu * real_frametime;

		
	}
	oldkeys = keys;
	SV_UserCmd (ent, real_frametime, v_angle, movevect, buttons, impulse);
}
@end

/*
=========================================

Stuff mimicking sv_user.c

=========================================
*/

void() DropPunchAngle =
{
	local float len;

	len = vlen (@self.punchangle);
	@self.punchangle = normalize (@self.punchangle);
	len -= 10 * real_frametime;
	if (len < 0)
		len = 0;
	@self.punchangle *= len;
};
