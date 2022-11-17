all: qwprogs.dat
qwprogs.dat: progs.src *.qc
	qfcc --ruamoko -Cno-promote-float,vector-components,const-initializers -Werror -Wall -O
clean:
	rm -f core *.dat *.sym progdefs.h *.p *.i1 *.i2
