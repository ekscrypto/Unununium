

mkdir: mkdir.o
	$(ELF2UBF) $(E2UFLAGS) mkdir.o mkdir

mkdir.o: mkdir.asm macros.inc
	$(AS) -f elf mkdir.asm $(ASFLAGS) -p macros.inc

.PHONY: clean install

clean:
	rm -f *.o *.ubf

install: $(APP_INST_DIR)/mkdir

$(APP_INST_DIR)/mkdir: mkdir
	cp mkdir $(APP_INST_DIR)
