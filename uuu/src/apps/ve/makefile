# $Header: /cvsroot/uuu/uuu/src/apps/ve/makefile,v 1.1 2001/11/03 20:08:36 instinc Exp $

ve: ve.o
	$(ELF2UBF) $(E2UFLAGS) ve.o ve

ve.o: ve.asm
	$(AS) -f elf ve.asm $(ASFLAGS)

.PHONY: clean install

clean:
	rm -f *.o *.ubf

install: $(APP_INST_DIR)/ve

$(APP_INST_DIR)/ve: ve
	cp ve $(APP_INST_DIR)
