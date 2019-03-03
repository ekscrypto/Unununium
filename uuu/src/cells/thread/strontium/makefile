# $Header: /cvsroot/uuu/uuu/src/cells/thread/strontium/makefile,v 1.4 2001/12/18 02:07:06 daboy Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	sys_log.inc \
	process.inc \
	vid/sys_log.inc  \
	vid/mem.inc \
	vid/mem.fixed.inc \
	vid/process.inc \
	vid/thread.inc \
	vid/timer.inc \
	vid/debug.diable.inc \
	vid/int.inc \
	vid/debug.ehex.inc \
	vid/file.inc

strontium: strontium.o
	$(ELF2UBF) $(E2UFLAGS) strontium.o strontium

strontium.o: strontium.asm $(INCS) makefile
	$(AS) -f elf strontium.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/strontium

$(CELL_INST_DIR)/strontium: strontium
	cp strontium $(CELL_INST_DIR)/strontium

clean:
	rm -f strontium.o strontium
