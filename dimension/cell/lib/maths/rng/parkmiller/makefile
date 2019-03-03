# $Header: /cvsroot/uuu/dimension/cell/lib/maths/rng/parkmiller/makefile,v 1.1.1.1 2002/01/17 04:31:31 instinc Exp $

INCS = \
	macros.inc \
	vid/rng.park_miller_88.inc \
	vid/rng.inc

libparkmiller: parkmiller.o
	$(ELF2UBF) $(E2UFLAGS) parkmiller.o libparkmiller

parkmiller.o: parkmiller.asm $(INCS) makefile
	$(AS) -f elf parkmiller.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libparkmiller

$(LIB_INST_DIR)/libparkmiller: libparkmiller
	cp libparkmiller $(LIB_INST_DIR)/libparkmiller

clean:
	rm -rf parkmiller.o libparkmiller
