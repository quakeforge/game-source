#include "common.qh"

#include "qw/protocol.qh"
#include "effect.qh"

#include "misc.qh"

void ()
effect_muzzleflash =
{
	WriteByte (MSG_MULTICAST, SVC_MUZZLEFLASH);
	WriteEntity (MSG_MULTICAST, self);
	multicast (self.origin, MULTICAST_PVS);
};

void (entity e)
effect_smallkick =
{
	if (!is_cl(e))
		return;

	msg_entity = e;
	WriteByte (MSG_ONE, SVC_SMALLKICK);
};

void (vector org, vector dir, float d)
effect_blood =
{
	d = d / 5;
	if (d < 3)
		d = 3;
	if (d > 255)
		d = 255;

	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_BLOOD, d);
	WriteCoordV (MSG_MULTICAST, org);
	multicast (org, MULTICAST_PVS);
};

void (vector org, vector vel, float d)
effect_gun_spark =
{
	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_GUNSHOT, d);
	WriteCoordV (MSG_MULTICAST, org);
	multicast (org, MULTICAST_PVS);
};

void (vector org, vector vel)
effect_nail_spark =
{
	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_SPIKE);
	WriteCoordV (MSG_MULTICAST, org);
	multicast (org, MULTICAST_PHS);
};

void (vector org)
effect_explosion =
{
	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_EXPLOSION);
	WriteCoordV (MSG_MULTICAST, org);
	multicast (org, MULTICAST_PHS);
};

void (vector org)
effect_teleport_fog =
{
	local float r;
	local string snd;

	r = random () * 5;
	if (r < 1)
		snd = "misc/r_tele1.wav";
	else if (r < 2)
		snd = "misc/r_tele2.wav";
	else if (r < 3)
		snd = "misc/r_tele3.wav";
	else if (r < 4)
		snd = "misc/r_tele4.wav";
	else
		snd = "misc/r_tele5.wav";

	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_TELEPORT);
	WriteCoordV (MSG_MULTICAST, org);
	multicast (org, MULTICAST_PHS);

	sound_vector (org, snd, 1, ATTN_NORM);
};

void (entity from, vector p1, vector p2)
effect_lightning2 =
{
	WriteBytes (MSG_MULTICAST, SVC_TEMPENTITY, TE_LIGHTNING2);
	WriteEntity (MSG_MULTICAST, from);
	WriteCoordV (MSG_MULTICAST, p1);
	WriteCoordV (MSG_MULTICAST, p2);
	multicast (p1, MULTICAST_PHS);
};
