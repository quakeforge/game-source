all: qwprogs.dat
qwprogs.dat: progs.src *.qc
	qfcc --advanced -Cno-promote-float,vector-components,const-initializers -Werror -Wall -g
clean:
	rm -f core *.dat *.sym progdefs.h *.p *.i1 *.i2
