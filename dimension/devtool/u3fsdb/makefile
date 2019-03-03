SYSTEMINC = /usr/include/
GUEST = ext2
U3TBASE = $(CURDIR)/../
U3INC = /home/eks/uuu/current/include/
INCLUDE = -I$(SYSTEMINC) -I$(U3TBASE)include/
COMPILERFLAGS = -Wall -O3
CC = gcc
AS = nasm
ASFLAGS = -f elf -w+number-overflow -w+orphan-labels -w+macro-params -w+macro-selfref $(addprefix -i,$(U3INC))
CFLAGS = $(COMPILERFLAGS) $(INCLUDE)

BRIDGE_INC = \
	ext2.inc \
	ozone.inc \
	error_codes.inc \
	macros.inc \
	vid/debug.diable.inc \
	vid/mem.inc \
	vid/sys_log.inc \
	vid/vfs.inc \
	vid/debug.ehex.inc

.PHONY: clean all

all: u3fsdb

u3fsdb.o: u3fsdb.c \
	$(U3TBASE)include/u3common.h \
	$(U3TBASE)u3common/u3common.o \
	$(U3TBASE)include/u3fsdb.h \
	$(U3TBASE)include/u3fsdb_bridge.h

	$(CC) $(CFLAGS) -c -o u3fsdb.o u3fsdb.c

u3fsdb_bridge.o: u3fsdb_bridge.asm
	$(AS) $(ASFLAGS) u3fsdb_bridge.asm $(addprefix -p,$(BRIDGE_INC))

u3fsdb: u3fsdb.o u3fsdb_bridge.o $(CURDIR)/guest/$(GUEST).o
	$(CC) $(CFLAGS) -o u3fsdb u3fsdb.o u3fsdb_bridge.o $(CURDIR)/guest/$(GUEST).o $(U3TBASE)u3common/u3common.o

$(CURDIR)/guest/dummy.o: $(CURDIR)/guest/dummy.asm
	$(AS) $(ASFLAGS) -o guest/dummy.o guest/dummy.asm $(addprefix -p,$(BRIDGE_INC))

clean:
	rm -f u3fsdb.o u3fsdb guest/dummy.o u3fsdb_bridge.o
