/*
	#FILENAME#

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

	$Id$
*/


void(entity targ, entity attacker, string what) LogPlayerDMDeath =
{
	// note embedded tabs in the next string
	dprint("LOG:	DEATH	");
	dprint(targ.netname);
	dprint("/");
	dprint(ftos(targ.frags));
	dprint("	");
	dprint(attacker.netname);
	dprint("/");
	dprint(ftos(attacker.frags));
	dprint("	");
	dprint(what);
	dprint("\n");
};

void (entity targ, string what) LogPlayerDeath =
{
	dprint("LOG:	DEATH	");
	dprint(targ.netname);
	dprint("/");
	dprint(ftos(targ.frags));
	dprint("	");
	dprint(what);
	dprint("\n");
};

void (entity who, string what) LogMsg =
{
	dprint("LOG:	");
	dprint(what);
	dprint("	");
	dprint(who.netname);
	dprint("\n");
};
