# $Header: /cvsroot/uuu/uuu/src/cells/lib/app/common/makefile,v 1.2 2001/12/09 21:06:14 instinc Exp $

INCS = \
	macros.inc \
	error_codes.inc \
	vid/lib.string.inc \
	vid/lib.app.inc \
	vid/sys_log.inc

libapp: common.o
	$(ELF2UBF) $(E2UFLAGS) common.o libapp

common.o: common.asm $(INCS) makefile
	$(AS) -f elf common.asm $(ASFLAGS) $(addprefix -p,$(INCS))

.PHONY: clean install

install: $(LIB_INST_DIR)/libapp

$(LIB_INST_DIR)/libapp: libapp
	cp libapp $(LIB_INST_DIR)/libapp

clean:
	rm -f *.o
