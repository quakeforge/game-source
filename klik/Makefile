###############################################

GAME=qw
DEBUG=0

###############################################

CPP=cpp
CPPFLAGS=-I. -Iweapons -Imdl -Iact -Imapents

QFCC=qfcc
QFCCFLAGS=-q --warn all --code v6only $(CPPFLAGS)

###############################################

QW_SOURCES=	$(addprefix qw/,								\
			sys_defs.qc	builtins.qc	sz_watch.qc	effect.qc	\
		)

WEAPONS_SOURCES=weapon.qc	weapon_g.qc	\
		w_void.qc	w_axe.qc	w_shotgun.qc	w_nailgun.qc		\
		w_grenade_launcher.qc	w_rocket_launcher.qc	w_lightning_gun.qc

ACT_SOURCES=	act.qc		act_player.qc	act_dead.qc

MDL_SOURCES=	mdl.qc		mdl_void.qc	mdl_player.qc	mdl_eyes.qc

MAPENTS_SOURCES=mapents_util.qc	\
		\
		mapents.qc		items.qc		\
		mapents_triggers.qc	mapents_movewall.qc	mapents_traps.qc	\
		id_compat.qc		mapents_items.qc	mapents_powerup.qc

COMMON_SOURCES=system.qc	\
	\
	equip.qc	\
	equipid.qc	\
	server.qc	worldspawn.qc	\
	client.qc	spectate.qc	\
	math.qc		\
	misc.qc		\
	teleport.qc	delays.qc	\
	bodyque.qc	damage.qc	\
	menu.qc		menus.qc	\
	override.qc	\
	\
	$(addprefix weapons/,	$(WEAPONS_SOURCES))	\
	$(addprefix act/,		$(ACT_SOURCES))		\
	$(addprefix mdl/,		$(MDL_SOURCES))		\
	$(addprefix mapents/,	$(MAPENTS_SOURCES))

DEBUG_SOURCES=	debug.qc	entnum.qc

ifeq ($(GAME),qw)
PROGS=../qwprogs.dat
CPPFLAGS+=-I qw
SOURCES=$(QW_SOURCES) $(COMMON_SOURCES)
else
PROGS=../progs.dat
CPPFLAGS+=-I nq
SOURCES=$(NQ_SOURCES) $(COMMON_SOURCES)
endif

ifeq ($(DEBUG),1)
CPPFLAGS+=-DDEBUG=1
SOURCES+=$(DEBUG_SOURCES)
endif

OBJECTS=$(addsuffix .o,$(basename $(SOURCES)))
DEPENDS=$(addprefix .deps/,$(addsuffix .d,$(basename $(SOURCES))))

GENERATED_SOURCES = equipid.qh equipid.qc weapons/weapon_g.qc

all: $(PROGS)

##########################

$(PROGS): $(OBJECTS)
	$(QFCC) $(QFCCFLAGS) -o $@ $^

WEAPON_G_SOURCES=$(filter weapons/w_%.qc,$(SOURCES))
weapons/weapon_g.qc: weapons/weapon_gen.sh $(WEAPON_G_SOURCES)
	bash weapons/weapon_gen.sh $(WEAPON_G_SOURCES) > $@

EQUIPID_SOURCES=$(filter-out $(GENERATED_SOURCES),$(SOURCES))
equipid.qh equipid.qc: equipid_gen.pl Makefile $(EQUIPID_SOURCES)
	cat $(EQUIPID_SOURCES) | perl equipid_gen.pl > equipid.qh

clean:
	rm -f $(OBJECTS) $(GENERATED_SOURCES)
	rm -rf .deps

#########################


%.o: %.r
	@mkdir -p .deps
	@$(QFCC) -M -q $(QFCCFLAGS) -c $< | sed -e 's/\(\.r\)\?\.o\>/.o/' > .deps/`basename $@ .o`.d
	$(QFCC) $(QFCCFLAGS) -c -o $@ $<

%.o: %.qc
	@mkdir -p .deps
	@$(QFCC) -M -q $(QFCCFLAGS) -c $< | sed -e 's/\(\.qc\)\?\.o\>/.o/' > .deps/`basename $@ .o`.d
	$(QFCC) $(QCFLAGS) $(QFCCFLAGS) -c -o $@ $<


#########################

unused:
	@echo $(filter-out $(SOURCES),$(wildcard *.qc))

$(shell find . -name '*.qc' | xargs grep -l equip.qh | sed -e 's/\.qc/.o/'): equipid.qh

#########################

.PHONY: unused

#########################

#progs.src: Makefile
#	echo $(PROGS) > $@
#	for i in $(SOURCES); do echo "$$i" >> $@; done
#
#$(PROGS): progs.src $(SOURCES)
#	$(QFCC) $(QFCCFLAGS)


-include $(DEPENDS)
