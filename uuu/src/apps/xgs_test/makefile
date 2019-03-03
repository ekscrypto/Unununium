# $Header: /cvsroot/uuu/uuu/src/apps/xgs_test/makefile,v 1.3 2001/09/26 20:44:18 daboy Exp $

xgs_test.o: xgs_test.asm hydro3d.inc blobs.dat numbers.inc macros.inc error_codes.inc
	$(AS) -f elf xgs_test.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
