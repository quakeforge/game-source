QFCC=qfcc
QCFLAGS=-qq -g -Werror
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

libfrikbot_obj = $(addsuffix .qfo,$(basename $(libfrikbot_source)))
libfrikbot_dep = $(addprefix .deps/,$(addsuffix .d,$(basename $(libfrikbot_source))))

%.qfo: %.r
	@mkdir -p .deps
	@$(QFCC) -M -q $(QCPPFLAGS) -c $< | sed -e 's/\(\.r\)\?\.o\>/.qfo/' > .deps/`basename $@ .qfo`.d
	$(QFCC) $(QCFLAGS) $(QCPPFLAGS) -c -o $@ $<

%.qfo: %.qc
	$(QFCC) $(QCFLAGS) $(QCPPFLAGS) -c -o $@ $<

all: libfrikbot.a

libfrikbot.a: $(libfrikbot_obj)
	pak -cf $@ $^

clean:
	rm -f *.qfo *.a *.d
	rm -rf .deps

-include $(libfrikbot_dep)
