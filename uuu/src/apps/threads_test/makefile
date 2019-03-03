# $Header: /cvsroot/uuu/uuu/src/apps/threads_test/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

threads_test.o: threads_test.asm macros.inc error_codes.inc
	$(AS) -f elf threads_test.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
