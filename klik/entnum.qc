#include "common.qh"
#include "server.qh"
#include "entnum.qh"

/* This is a horrible hack. */

float(entity e) entnum = {
	local entity walk, walk2;
	local float en, tot;

	if (!e)
		return 0;

	en = 1;
	walk = nextent(world);

	for (tot = 1; tot <= max_clients; tot++) {
		if (e == walk)
			return tot;
	
		walk = walk.chain = nextent(walk);
	}

	while (walk) {
		tot++;
		walk = walk.chain = nextent(walk);
	}

	walk = nextent(world);
	spawn("__ENTNUM_TEMP__");
	for (en = 1; en < tot; en++) {
		if (e == walk) {
			foreach(classname, "__ENTNUM_TEMP__", remove);
			return en;
		}

		walk2 = nextent(walk);

		if (walk.chain != walk2) {
			spawn("__ENTNUM_TEMP__");

			walk2.chain = walk.chain;
			walk.chain = walk2;
			tot++;
		}

		walk = walk2;
		if (!walk)
			break;
	}

	error("entnum: Invalid entity\n");
};

entity(float num) entfornum = {
	local entity walk, walk2;
	local float tot;
	local float debugnum;

	debugnum = num;

	tot = 0;
	for (walk = world; tot < max_clients; walk = nextent(walk)) {
		if (!num)
			return walk;
		num--;
		tot++;
	}

	if (!num)
		return walk;

	tot = 0;
	for (walk2 = walk; walk2; walk2 = walk2.chain = nextent(walk2))
		tot++;

	spawn("__ENTNUM_TEMP__");

	for (0; tot; tot--) {
		walk2 = nextent(walk);
		if (walk.chain != walk2) {
			spawn("__ENTNUM_TEMP__");

			walk2.chain = walk.chain;
			walk.chain = walk2;
			tot++;
		}

		walk = walk2;
		num--;

		if (!num) {
			foreach(classname, "__ENTNUM_TEMP__", remove);
			return walk;
		}
	}

	error("entfornum: Invalid entity number: ", ftos(debugnum), "\n");
};

string(entity e) etos = {
	return ftos(entnum(e));
};
