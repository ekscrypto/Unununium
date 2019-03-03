# $Header: /cvsroot/uuu/uuu/src/apps/games/boxed_in/makefile,v 1.3 2001/09/26 20:44:18 daboy Exp $

boxed_in.o: boxed_in.asm level.asm gfx.asm control.asm levels.inc macros.inc
	$(AS) -f elf boxed_in.asm -p macros.inc $(ASFLAGS)

.PHONY: clean
	 
clean:
	rm -f *.o
	 
