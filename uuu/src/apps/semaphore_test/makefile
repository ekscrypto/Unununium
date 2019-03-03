# $Header: /cvsroot/uuu/uuu/src/apps/semaphore_test/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

semaphore_test.o: semaphore_test.asm macros.inc error_codes.inc
	$(AS) -f elf semaphore_test.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
