QFCC=qfcc
QCFLAGS=-z -qq -g -Werror
QCPPFLAGS=-DLIBFRIKBOT

libfrikbot_source = \
	bot_ai.qc		\
	bot_fight.qc	\
	bot_misc.qc		\
	bot_move.qc		\
	bot_phys.qc		\
	bot_qw.qc		\
	bot_way.qc		\
	map_dm1.qc		\
	map_dm2.qc		\
	map_dm3.qc		\
	map_dm4.qc		\
	map_dm5.qc		\
	map_dm6.qc

libfrikbot_obj = $(addsuffix .o,$(basename $(libfrikbot_source)))
libfrikbot_dep = $(addprefix .deps/,$(addsuffix .d,$(basename $(libfrikbot_source))))

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

-include $(libfrikbot_dep)