all: progs.dat
progs.dat: progs.src *.qc
	qfcc -Nwarn -Wall -Werror -g --advanced
clean:
	rm -f core *.dat *.sym progdefs.h
