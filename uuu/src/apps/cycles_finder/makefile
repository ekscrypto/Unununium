# $Header: /cvsroot/uuu/uuu/src/apps/cycles_finder/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

cycles_finder.o: cycles_finder.asm macros.inc error_codes.inc
	$(AS) -f elf cycles_finder.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
