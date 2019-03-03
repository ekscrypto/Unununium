# $Header: /cvsroot/uuu/dimension/cell/process/strontium/makefile,v 1.1.1.1 2002/01/17 04:31:36 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
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
