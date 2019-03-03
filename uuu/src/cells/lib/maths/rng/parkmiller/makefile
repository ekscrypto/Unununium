# $Header: /cvsroot/uuu/uuu/src/cells/lib/maths/rng/parkmiller/makefile,v 1.3 2001/12/09 23:54:04 instinc Exp $

INCS = \
	macros.inc \
	vid/rng.park_miller_88.inc \
	vid/rng.inc

libparkmiller: parkmiller.o
	$(ELF2UBF) $(E2UFLAGS) parkmiller.o libparkmiller

parkmiller.o: parkmiller.asm $(INCS)
	$(AS) -f elf parkmiller.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libparkmiller

$(LIB_INST_DIR)/libparkmiller: libparkmiller
	cp libparkmiller $(LIB_INST_DIR)/libparkmiller

clean:
	rm -rf parkmiller.o libparkmiller
