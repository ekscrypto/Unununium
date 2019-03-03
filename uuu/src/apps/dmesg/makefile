# $Header: /cvsroot/uuu/uuu/src/apps/dmesg/makefile,v 1.1 2001/12/02 08:44:29 daboy Exp $

dmesg: dmesg.o
	$(ELF2UBF) $(E2UFLAGS) dmesg.o dmesg

dmesg.o: dmesg.asm macros.inc
	$(AS) -f elf dmesg.asm $(ASFLAGS) -p macros.inc

.PHONY: clean install

clean:
	rm -f *.o dmesg

install: $(APP_INST_DIR)/dmesg

$(APP_INST_DIR)/dmesg: dmesg
	cp dmesg $(APP_INST_DIR)
