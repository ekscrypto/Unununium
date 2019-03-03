# $Header: /cvsroot/uuu/dimension/cell/lib/time/rtc/makefile,v 1.1 2003/01/11 16:07:30 lukas2000 Exp $

INCS = \
	macros.inc \
	errors.inc \
	fs/fs.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/time.inc \
	vid/int.inc \
	vid/debug.diable.inc \
	sys_log.inc

rtc: rtc.o
	$(ELF2UBF) $(E2UFLAGS) rtc.o rtc

rtc.o: rtc.asm $(INCS) makefile
	$(AS) -f elf rtc.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/rtc

$(CELL_INST_DIR)/rtc: rtc
	cp rtc $(CELL_INST_DIR)/rtc

clean:
	rm -f rtc.o rtc
