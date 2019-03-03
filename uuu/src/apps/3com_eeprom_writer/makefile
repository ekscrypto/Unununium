# $Header: /cvsroot/uuu/uuu/src/apps/3com_eeprom_writer/makefile,v 1.2 2001/09/26 20:44:18 daboy Exp $

3com_eeprom_writer.o: 3com_eeprom_writer.asm macros.inc error_codes.inc
	$(AS) -f elf 3com_eeprom_writer.asm -p macros.inc -p error_codes.inc $(ASFLAGS)

.PHONY: clean

clean:
	rm -f *.o
