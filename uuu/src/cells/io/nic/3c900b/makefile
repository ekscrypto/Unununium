# $Header: /cvsroot/uuu/uuu/src/cells/io/nic/3c900b/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

3c900b.o: 3c900b.asm macros.inc error_codes.inc
	$(AS) -f elf 3c900b.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
