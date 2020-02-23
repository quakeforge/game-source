all: spprogs.dat
spprogs.dat: progs.src *.qc
	qfcc --advanced -Cvector-components,const-initializers -Werror -Wall -g
clean:
	rm -f core *.dat *.sym progdefs.h
