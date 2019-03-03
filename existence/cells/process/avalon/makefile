# $Header: /cvsroot/uuu/existence/cells/process/avalon/makefile,v 1.6 2003/01/12 03:20:58 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	vid/int.inc \
	vid/irq.inc \
	vid/hra.inc \
	vid/ps.inc \
	vid/tsa.inc \
	vid/sem.inc \
	thread.inc \
	waitqueue.inc \
	avalon.inc

avalon: avalon.o
	$(ELF2UBF) $(E2UFLAGS) avalon.o avalon

avalon.o: avalon.asm $(INCS) makefile
	$(AS) -f elf avalon.asm -d__INIT_STACK__=$(INIT_STACK) $(ASFLAGS) $(addprefix -p,$(INCS)) -l avalon.lst

.PHONY: clean install

install: $(CELL_INST_DIR)/avalon

$(CELL_INST_DIR)/avalon: avalon
	cp avalon $(CELL_INST_DIR)/avalon

clean:
	rm -f avalon.o avalon avalon.lst
