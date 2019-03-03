# $Header: /cvsroot/uuu/dimension/cell/lib/environment/makefile,v 1.1.1.1 2002/01/17 04:31:31 instinc Exp $

INCS = \
	macros.inc \
	errors.inc \
	fs/fs.inc \
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
