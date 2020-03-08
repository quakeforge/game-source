all: qwprogs.dat
qwprogs.dat: progs.src *.qc
	qfcc -Cno-promote-float,vector-components -Werror -g --advanced
clean:
	rm -f core *.dat *.sym progdefs.h
