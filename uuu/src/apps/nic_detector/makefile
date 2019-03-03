# $Header: /cvsroot/uuu/uuu/src/apps/nic_detector/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

nic_detector.o: nic_detector.asm macros.inc error_codes.inc
	$(AS) -f elf nic_detector.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
