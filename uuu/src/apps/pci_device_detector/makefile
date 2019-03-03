# $Header: /cvsroot/uuu/uuu/src/apps/pci_device_detector/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

pci_device_detector.o: pci_device_detector.asm macros.inc error_codes.inc
	$(AS) -f elf pci_device_detector.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
