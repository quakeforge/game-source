#include "common.qh"

#include "qw/protocol.qh"
#include "effect.qh"

#include "misc.qh"

void() effect_muzzleflash = {
	WriteByte(MSG_MULTICAST, SVC_MUZZLEFLASH);
	WriteEntity(MSG_MULTICAST, self);
	multicast(self.origin, MULTICAST_PVS);
};

void(entity e) effect_smallkick = {
	if (!is_cl(e))
		return;

	msg_entity = e;
	WriteByte(MSG_ONE, SVC_SMALLKICK);
};

void(vector org, vector dir, float d) effect_blood = {
	d = d / 5;
	if (d < 3) d = 3;
	if (d > 255) d = 255;

	WriteByte(MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte(MSG_MULTICAST, TE_BLOOD);
	WriteByte(MSG_MULTICAST, d);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast(org, MULTICAST_PVS);
};

void(vector org, vector vel, float d) effect_gun_spark = {
	WriteByte(MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte(MSG_MULTICAST, TE_GUNSHOT);
	WriteByte(MSG_MULTICAST, d);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast(org, MULTICAST_PVS);
};

void(vector org, vector vel) effect_nail_spark = {
	WriteByte(MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte(MSG_MULTICAST, TE_SPIKE);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast(org, MULTICAST_PHS);
};

void(vector org) effect_explosion = {
	WriteByte(MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte(MSG_MULTICAST, TE_EXPLOSION);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast(org, MULTICAST_PHS);
};

void(vector org) effect_teleport_fog = {
	local float r;
	local string snd;

	r = random() * 5;
	if (r < 1)	snd = "misc/r_tele1.wav";
	else if (r < 2)	snd = "misc/r_tele2.wav";
	else if (r < 3)	snd = "misc/r_tele3.wav";
	else if (r < 4)	snd = "misc/r_tele4.wav";
	else		snd = "misc/r_tele5.wav";

	WriteByte(MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte(MSG_MULTICAST, TE_TELEPORT);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast(org, MULTICAST_PHS);

	sound_vector(org, snd, 1, ATTN_NORM);
};

void(entity from, vector p1, vector p2) effect_lightning2 = {
	WriteByte(MSG_MULTICAST, SVC_TEMPENTITY);
	WriteByte(MSG_MULTICAST, TE_LIGHTNING2);
	WriteEntity(MSG_MULTICAST, from);
	WriteCoord(MSG_MULTICAST, p1_x);
	WriteCoord(MSG_MULTICAST, p1_y);
	WriteCoord(MSG_MULTICAST, p1_z);
	WriteCoord(MSG_MULTICAST, p2_x);
	WriteCoord(MSG_MULTICAST, p2_y);
	WriteCoord(MSG_MULTICAST, p2_z);
	multicast(p1, MULTICAST_PHS);
};
