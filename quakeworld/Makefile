all: qwprogs.dat
qwprogs.dat: progs.src *.qc
	qfcc -Werror -g
clean:
	rm -f core *.dat *.sym progdefs.h
