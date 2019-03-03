# $Header: /cvsroot/uuu/uuu/src/apps/games/ttt/makefile,v 1.1 2001/10/26 17:17:39 daboy Exp $

ttt.o: ttt.asm \
	pcx/sizes.inc \
	pcx/redpc.pcx \
	pcx/bluepc.pcx \
	pcx/cursor.pcx \
	pcx/rect.pcx \
	pcx/upleft.pcx \
	pcx/up.pcx \
	pcx/upright.pcx \
	pcx/left.pcx \
	pcx/right.pcx \
	pcx/downleft.pcx \
	pcx/down.pcx \
	pcx/downright.pcx \
	pcx/wins.pcx \
	pcx/red.pcx \
	pcx/blue.pcx \
	pcx/restart.pcx \
	pcx/blueturn.pcx \
	pcx/redturn.pcx \
	pcx/draw.pcx
	
	$(AS) -f elf ttt.asm $(ASFLAGS) -p macros.inc -p error_codes.inc

.PHONY: clean

clean:
	rm -f *.o
