# $Header: /cvsroot/uuu/dimension/cell/lib/string/fasthash/makefile,v 1.1.1.1 2002/01/17 04:31:33 instinc Exp $

INCS = \
	macros.inc \
	vid/lib.string.inc

libfasthash: fasthash.o
	$(ELF2UBF) $(E2UFLAGS) fasthash.o libfasthash

fasthash.o: fasthash.asm $(INCS) makefile
	$(AS) -f elf fasthash.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libfasthash

$(LIB_INST_DIR)/libfasthash: libfasthash
	cp libfasthash $(LIB_INST_DIR)/libfasthash

clean:
	rm -f fasthash.o libfasthash
