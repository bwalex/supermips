#
#	Adjust for your system!
#
#	Common options for generic UNIX and Microsoft C (under DOS)
#	are listed here.  You can change them by switching the order,
#	placing the ones you want last.  Pay particular attention to
#	the HZ parameter, which may or may not be listed in some
#	header file on your system, such as <sys/param.h> or <limits.h>
#	(as CLK_TCK).  Even if it is listed, it may be incorrect.
#	Also, some operating systems (notably some (all?) versions
#	of Microport UNIX) lie about the time.  Sanity check with a
#	stopwatch.
#
#	For Microsoft C under DOS, you need a real make, not MSC make,
#	to run this Makefile.  The public domain "ndmake" will suffice.
#
GCC=		mips-sde-elf-gcc


GCCOPTIM=       -O2 -fomit-frame-pointer

GCCFLAGS= $(GCCOPTIM) -g -T simple.ld -mno-float

#
#		You shouldn't need to touch the rest
#
SRC=		dhry_1.c dhry_2.c helper.c startup.s
HDR=		dhry.h supermips.h


all:	$(SRC) $(HDR)
	$(GCC) $(GCCFLAGS) $(SRC) -o dhry.elf

clean:
	-rm -f *.o *.obj dhry.elf
