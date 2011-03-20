all: qwprogs.dat
qwprogs.dat: progs.src *.qc
	qfcc -Cvector-components -Werror -Wall -g --advanced
clean:
	rm -f core *.dat *.sym progdefs.h
