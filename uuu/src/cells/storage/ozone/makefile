# $Header: /cvsroot/uuu/uuu/src/cells/storage/ozone/makefile,v 1.5 2001/12/10 16:49:32 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	ozone.inc \
	vid/vfs.inc \
	vid/sys_log.inc \
	sys_log.inc \
	vid/mem.inc \
	vid/mem.fixed.inc \
	vid/process.inc \
	vid/lib.string.inc \
	vid/debug.diable.inc \
	vid/debug.ehex.inc

ozone: ozone.o
	$(ELF2UBF) $(E2UFLAGS) ozone.o ozone

ozone.o: ozone.asm $(INCS) makefile
	$(AS) -f elf ozone.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/ozone

$(CELL_INST_DIR)/ozone: ozone
	cp ozone $(CELL_INST_DIR)/ozone

clean:
	rm -f ozone.o ozone
