all: qwprogs.dat
qwprogs.dat: progs.src *.qc
	qfcc -Werror -Wall -g
clean:
	rm -f core *.dat *.sym progdefs.h
