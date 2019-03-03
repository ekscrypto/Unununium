# $Header: /cvsroot/uuu/dimension/app/base/dmesg/makefile,v 1.1.1.1 2002/01/17 04:30:55 instinc Exp $

INCS = \
	vid/sys_log.inc \
	fs/fs.inc \
	process.inc \
	macros.inc

dmesg: dmesg.o
	$(ELF2UBF) $(E2UFLAGS) dmesg.o dmesg

dmesg.o: dmesg.asm $(INCS) makefile
	$(AS) -f elf dmesg.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

clean:
	rm -f *.o dmesg

install: $(APP_INST_DIR)/dmesg

$(APP_INST_DIR)/dmesg: dmesg
	cp dmesg $(APP_INST_DIR)
	chmod a+x $(APP_INST_DIR)/dmesg
