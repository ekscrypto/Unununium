# $Header: /cvsroot/uuu/uuu/src/cells/fs/ext2/makefile,v 1.8 2001/12/09 17:02:41 instinc Exp $

INCS = \
       ext2.inc \
       ozone.inc \
       macros.inc \
       error_codes.inc \
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
