QFCC=qfcc
#QCFLAGS=-z -qq -g -Werror
QCFLAGS=-qq -g -Werror -Wall
QCPPFLAGS=
libdir=$(shell pkg-config qfcc --variable=libdir)
includedir=$(shell pkg-config qfcc --variable=includedir)

libfrikbot_source = \
	bot_ai.qc		\
	bot_fight.qc	\
	bot_misc.qc		\
	bot_move.qc		\
	bot_qw.qc		\
	bot_way.qc		\
	map_dm1.qc		\
	map_dm2.qc		\
	map_dm3.qc		\
	map_dm4.qc		\
	map_dm5.qc		\
	map_dm6.qc		\
	chat.r			\
	editor.r		\
	impulse_menu.r	\
	target.r		\
	waypoint.r

libfrikbot_obj = $(addsuffix .o,$(basename $(libfrikbot_source)))
libfrikbot_dep = $(addprefix .deps/,$(addsuffix .d,$(basename $(libfrikbot_source))))

map_%.o: map_%.qc
	@mkdir -p .deps
	@$(QFCC) -M -q $(QCPPFLAGS) -c $< | sed -e 's/\(\.qc\)\?\.o\>/.o/' > .deps/`basename $@ .o`.d
	$(QFCC) $(QCFLAGS) -Cvector-calls $(QCPPFLAGS) -c -o $@ $<

%.o: %.r
	@mkdir -p .deps
	@$(QFCC) -M -q $(QCPPFLAGS) -c $< | sed -e 's/\(\.r\)\?\.o\>/.o/' > .deps/`basename $@ .o`.d
	$(QFCC) $(QCFLAGS) $(QCPPFLAGS) -c -o $@ $<

%.o: %.qc
	@mkdir -p .deps
	@$(QFCC) -M -q $(QCPPFLAGS) -c $< | sed -e 's/\(\.qc\)\?\.o\>/.o/' > .deps/`basename $@ .o`.d
	$(QFCC) $(QCFLAGS) $(QCPPFLAGS) -c -o $@ $<

all: libfrikbot.a

libfrikbot.a: $(libfrikbot_obj)
	pak -cf $@ $^

clean:
	rm -f *.o *.qfo *.a *.d
	rm -rf .deps

install: libfrikbot.a
	cp frikbot.h $(DESTDIR)$(includedir)
	cp libfrikbot.a $(DESTDIR)$(libdir)

-include $(libfrikbot_dep)
