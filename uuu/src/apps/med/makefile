
med: med.o
	$(ELF2UBF) $(E2UFLAGS) med.o med

med.o: med.asm macros.inc error_codes.inc
	$(AS) -f elf med.asm $(ASFLAGS) -p macros.inc -p error_codes.inc

.PHONY: clean install

clean:
	rm -f *.o med

install: $(APP_INST_DIR)/med

$(APP_INST_DIR)/med: med
	cp med $(APP_INST_DIR)
