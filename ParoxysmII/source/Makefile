SRC=	buttons.r builtins.r client.r combat.r defs.r doors.r dynlight.r \
	flash.r items.r misc.r observe.r plats.r player.r poxdefs.r sectrig.r \
	server.r shields.r specfx.r spectate.r subs.r targid.r triggers.r \
	wall.r weapons.r world.r 

HEADERS = client.rh paroxysm.rh config.rh

RFLAGS += -Wall -Werror -g

INSTALLDIR = $(HOME)/.quake/paroxysm/

all: qwprogs.dat

qwprogs.dat: $(SRC) $(HEADERS) progs.src Makefile
	qfcc $(RFLAGS)

clean:
	-rm -f *.dat *.sym progdefs.h

install: qwprogs.dat
	-cp qwprogs.* $(INSTALLDIR)

.PHONY: clean install
