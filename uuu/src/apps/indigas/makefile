# $Header: /cvsroot/uuu/uuu/src/apps/indigas/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

indigas.o: indigas.asm lexer.inc parser.inc opcodes.inc macros.inc error_codes.inc
	$(AS) -f elf indigas.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
