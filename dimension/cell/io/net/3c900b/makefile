# $Header: /cvsroot/uuu/dimension/cell/io/net/3c900b/makefile,v 1.1.1.1 2002/01/17 04:31:18 instinc Exp $

3c900b.o: 3c900b.asm macros.inc error_codes.inc
	$(AS) -f elf 3c900b.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
