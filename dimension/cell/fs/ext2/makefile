# $Header: /cvsroot/uuu/dimension/cell/fs/ext2/makefile,v 1.1.1.1 2002/01/17 04:31:11 instinc Exp $

INCS = \
       fs/ext2.inc \
       fs/fs.inc \
       macros.inc \
       errors.inc \
       vid/debug.diable.inc \
       vid/mem.inc \
       vid/sys_log.inc \
       vid/vfs.inc \
       vid/debug.ehex.inc

ext2: ext2.o
	$(ELF2UBF) $(E2UFLAGS) ext2.o ext2

ext2.o: ext2.asm link.inc strings.inc $(INCS) makefile
	$(AS) -f elf ext2.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(CELL_INST_DIR)/ext2

$(CELL_INST_DIR)/ext2: ext2
	cp ext2 $(CELL_INST_DIR)/ext2

clean:
	rm -rf ext2.o ext2
