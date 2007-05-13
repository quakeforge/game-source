all: progs.dat
progs.dat: progs.src *.qc
	qfcc -Wcow --traditional -Werror -g
clean:
	rm -f core *.dat *.sym progdefs.h
