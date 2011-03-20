all: spprogs.dat
spprogs.dat: progs.src *.qc
	qfcc -Cvector-components -Werror -g --advanced
clean:
	rm -f core *.dat *.sym progdefs.h
