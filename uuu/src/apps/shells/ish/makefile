# $Header: /cvsroot/uuu/uuu/src/apps/shells/ish/makefile,v 1.3 2001/11/02 03:28:55 daboy Exp $

ish: ish.o
	$(ELF2UBF) $(E2UFLAGS) ish.o ish

ish.o: ish.asm macros.inc error_codes.inc
	$(AS) -f elf ish.asm $(ASFLAGS) -p macros.inc -p error_codes.inc

.PHONY: clean install

clean:
	rm -f *.o ish

install: $(APP_INST_DIR)/ish

$(APP_INST_DIR)/ish: ish
	cp ish $(APP_INST_DIR)
