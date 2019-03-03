# $Header: /cvsroot/uuu/dimension/cell/lib/buffers/fifo/makefile,v 1.1 2003/01/26 08:32:55 lukas2000 Exp $

INCS = \
	macros.inc \
	errors.inc \
	fs/fs.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/fifo.inc \
	vid/int.inc \
	vid/debug.diable.inc \
	sys_log.inc

fifo: fifo.o
	$(ELF2UBF) $(E2UFLAGS) fifo.o fifo

fifo.o: fifo.asm $(INCS) makefile
	$(AS) -f elf fifo.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/fifo

$(CELL_INST_DIR)/fifo: fifo
	cp fifo $(CELL_INST_DIR)/fifo

clean:
	rm -f fifo.o fifo
