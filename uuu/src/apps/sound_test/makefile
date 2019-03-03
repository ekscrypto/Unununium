# $Header: /cvsroot/uuu/uuu/src/apps/sound_test/makefile,v 1.3 2001/09/26 20:44:18 daboy Exp $

sound_test.o: sound_test.asm test.wav macros.inc
	$(AS) -f elf sound_test.asm -p macros.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
