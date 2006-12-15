all: qwprogs.dat
qwprogs.dat: progs.src *.qc
	qfcc -Werror -Wall -g --advanced
clean:
	rm -f core *.dat *.sym progdefs.h *.p *.i1 *.i2
