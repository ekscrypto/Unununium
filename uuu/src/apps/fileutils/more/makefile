

more: more.o
	$(ELF2UBF) $(E2UFLAGS) more.o more

more.o: more.asm macros.inc
	$(AS) -f elf more.asm $(ASFLAGS) -p macros.inc

.PHONY: clean install

clean:
	rm -f *.o *.ubf

install: $(APP_INST_DIR)/more

$(APP_INST_DIR)/more: more
	cp more $(APP_INST_DIR)
