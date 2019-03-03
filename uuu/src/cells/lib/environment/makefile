# $Header: /cvsroot/uuu/uuu/src/cells/lib/environment/makefile,v 1.2 2001/12/09 22:51:44 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	ozone.inc \
	vid/vfs.inc \
	vid/mem.inc \
	vid/lib.env.inc \
	vid/sys_log.inc \
	vid/debug.diable.inc \
	vid/debug.ehex.inc

libenv: environment.o
	$(ELF2UBF) $(E2UFLAGS) environment.o libenv

environment.o: environment.asm $(INCS) makefile
	$(AS) -f elf environment.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libenv

$(LIB_INST_DIR)/libenv: libenv
	cp libenv $(LIB_INST_DIR)/libenv

clean:
	rm -f environment.o libenv
