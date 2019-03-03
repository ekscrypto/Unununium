# $Header: /cvsroot/uuu/uuu/src/cells/lib/string/md5/makefile,v 1.3 2001/12/10 15:54:48 instinc Exp $

INCS = \
	macros.inc \
	vid/lib.string.inc

libmd5: md5.o
	$(ELF2UBF) $(E2UFLAGS) md5.o libmd5

md5.o: md5.asm $(INCS) makefile
	$(AS) -f elf md5.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libmd5

$(LIB_INST_DIR)/libmd5: libmd5
	cp libmd5 $(LIB_INST_DIR)/libmd5

clean:
	rm -f md5.o libmd5
