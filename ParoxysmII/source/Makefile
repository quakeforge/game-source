SRC=	buttons.r builtins.r client.r combat.r defs.r doors.r dynlight.r \
	flash.r items.r misc.r observe.r plats.r player.r poxdefs.r sectrig.r \
	server.r shields.r specfx.r spectate.r subs.r targid.r triggers.r \
	wall.r weapons.r world.r 

HEADERS = client.rh paroxysm.rh config.rh

RFLAGS += -DQUAKEWORLD -Wall -Werror -g
QFCC = qfcc

INSTALLDIR = $(HOME)/.quake/paroxysm/

OBJ = $(addsuffix .o,$(basename $(SRC)))
DEP = $(addprefix .deps/,$(addsuffix .d,$(basename $(SRC))))

%.o: %.r
	@mkdir -p .deps
	@$(QFCC) -M -q $(RFLAGS) -c $< | sed -e 's/\(\.r\)\?\.o\>/.o/' > .deps/`basename $@ .o`.d
	$(QFCC) $(RFLAGS) -q -c -o $@ $<

all: qwprogs.dat

qwprogs.dat: $(OBJ)
	qfcc -o qwprogs.dat $(OBJ)

clean:
	-rm -f *.dat *.sym progdefs.h *.o
	-rm -rf .deps

install: qwprogs.dat
	-cp qwprogs.* $(INSTALLDIR)

.PHONY: clean install

-include $(DEP)
