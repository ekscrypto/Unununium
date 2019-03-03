# $Header: /cvsroot/uuu/uuu/src/boot/ext2_boot/makefile,v 1.3 2001/10/30 04:30:38 daboy Exp $

UUU_TEST_DISK = /dev/fd0

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin -p ../../../include/ext2.inc -p ../../../include/error_codes.inc
	ls -al boot.bin

install: boot.bin
	dd if=boot.bin of=${UUU_TEST_DISK} bs=512 count=2 conv=notrunc

.PHONY: clean

clean:
	rm -f boot.bin
