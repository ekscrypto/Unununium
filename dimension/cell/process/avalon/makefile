# $Header: /cvsroot/uuu/dimension/cell/process/avalon/makefile,v 1.2 2002/10/04 01:47:13 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	sys_log.inc \
	vid/sys_log.inc  \
	vid/int.inc \
	sem.inc \
	process.inc \
	waitqueue.inc \
	avalon.inc

avalon: avalon.o
	$(ELF2UBF) $(E2UFLAGS) avalon.o avalon

avalon.o: avalon.asm $(INCS) makefile
	$(AS) -f elf avalon.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/avalon

$(CELL_INST_DIR)/avalon: avalon
	cp avalon $(CELL_INST_DIR)/avalon

clean:
	rm -f avalon.o avalon
