; Unununium Operating Engine's boot record
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License
;
; version 1.0.3
;
; Featuring:
; - cpu detection, 8088, 80286 and 80386+, will allow only 386+ to go thru
; - enable protected mode
; - set ds, es, fs, gs and ss to 4GB r/w 32bits data segment
; - set cs to 32bits 4GB r/x code segment
; - can read more more than 256 sectors
; - boots from floppy, cdrom, zip, .., and hard disk partitions
; - support for partitions above 8GB (up to 2TB)
; - enable a20 for both standard AT and PS/2 Microchanneled computers
; - disable fdc motor after reading the sectors
; - disable crt hardware cursor (works also for lcd)
; - progress indication while loading sectors
; - support for bios with the disk support extension
;
[org 0x7C00]
[bits 16]

;%define __DEMO__

section .text

  struc DAP
.header_length          resb 1
.reserved               resb 1
.block_count            resw 1
.transfer_buffer        resd 1
.starting_block_number  resd 2
  endstruc

  struc part
.bootflag               resb 1
.start_head             resb 1
.start_cyl              resb 1
.start_sector           resb 1
.type                   resb 1
.ending_head            resb 1
.ending_cyl             resb 1
.ending_sector          resb 1
.starting_lba           resd 1
.sector_count           resd 1
  endstruc

%include "../../include/hdr_core.inc"

_boot_record:

  xor  bx,  bx				; bx = 0, used to set segment selectors
  mov  ss,  bx				; set ss = 0
  mov  sp,  0x4004			; after pushing flag, sp = 4002

  mov si, str_old_cpu
  ;]--Test if bit 14 stay always clear, indicate 80286
  ;   or if bit 12/13 stay always set, indicates 8088
  push sp				; set bit 14
  mov es, bx				; es = 0
  popf					; load flags with it
  mov ds, bx				; ds = 0
  pushf					; save back flags
  pop  ax				; get back final result
  test ah,  0x30			; bit 12-13 set?
 out 0x92, al			; [2]- Enable PS/2 gate A20
  jnz short lock_that_babe		; yip, 8088 detected
  test ah,  0x40			; bit 14 still set?
 mov al, 0xD1			; [2]- Enable A20
  jnz short processor_passed_the_test	; yes, good, we have 80386 or above :)


lock_that_babe:
  mov  ah,  0x0E			; teletype service
  xor  bx,  bx				; select page 0, color 0
.displaying:
  lodsb					; load char
  test al,  al				; 0 terminator?
  jz   short $				; yip, lock that babe!
  int  0x10				; ask for bios video service
  jmp short .displaying			; and go to next char





;                                 ---




processor_passed_the_test:
 out 0x64, al			; [2]-send to keyboard command port value 0xD1
  mov [boot_drive], dl			; save drive id that we booted from
 mov al, 0x03			; [2]-Enable A20


;                                 ---


bios_extensions_test:
  ;]--Test for IBM/MS Int 13 Extensions
  mov  ah,   0x41			; installation check service
  mov  bx,   0x55AA			; req value, should be inversed if valid
 out 0x60, al			; [2]-send to keyboard data port value 0x03
  xor  bp,   bp				; set var used later to diff chs/lba
  int  0x13				; ask for bios disk service
  jc   short .no_extension		; cf=1 mean not installed
  cmp  bx,   0xAA55			; is it inversed?
  jnz  short .no_extension		; no, not installed :(
  test cl, 1				; installed, does it provides 0x42?
  jz   short .lba_extension_enabled	; yes? nice :))

.no_extension:
  mov  ah,   0x08			; get drive parameters service
  xor  di,   di				; es:di = 0, some bios are capricious
  inc  bp				; set var for chs (1)
  int  0x13				; ask for bios disk service
  jc   short read_sectors.disk_error	; error occured, display message
  and  ecx,  byte 0x3F			; keep only sectors, discard cylinders
  mov  [disk_geometry.sectors_per_head], ecx
  mov  cl,   dh				; move number of heads in cl (ecx)
  inc  cx				; increment it, doing modulo later
  mov  [disk_geometry.number_of_heads], ecx

.lba_extension_enabled:

  mov  ah,   0				; reset disk system service
  mov  dl,   [boot_drive]		; select startup drive
  int  0x13				; ask for bios disk service
  jc   short read_sectors.disk_error	; error occured, display message

  xor  eax,  eax			; set starting lba to 0 in case fdd/cdrom
  or   dl,   dl				; verify if start was on a floppy
  js   short get_partition_information	; we are on hdd, get partition info
  jmp  near load_system		; floppy? no partition table!


;                                 ---



read_sectors:
; bp  = chs/lba selector
;       0 = lba (using 13h bios service extensions)
;       1 = chs
; DAP = contain the sectors relative information
  mov  di, 4				; maximum retry count for one sector
.retry:
  or   bp,   bp				; test for disk extension presence
  mov  si,   dap_information		; load pointer to dap just in case
  mov  ah,   0x42			; extended service disk read
  jz   short .extensions_enabled	; disk extension present, use DAP

  mov  edx,   [dap_information.starting_block_number + 4]; high part of block id
  mov  eax,   [dap_information.starting_block_number]	; low part of block id
  div  dword  [disk_geometry.sectors_per_head]	; calculate sector value
  mov  cx,   dx				; load remainder, sector value
  inc  cx				; sectors start at 1, not 0
  mov  dl,   0				; clear remainder
  div  dword  [disk_geometry.number_of_heads]	; get cylinder and head value
  mov  ch,   al				; set low cylinder
  shl  ah,   6				; isolate high cylinder part
  or   cl,   ah				; or high cylinder part with sectors
  mov  dh,   dl				; set head value
  mov  ax,   0x0201			; service 02 (read disk), for 1 sector
  les  bx,   [dap_information.transfer_buffer]

.extensions_enabled:
  mov  dl,   [boot_drive]		; read drive id where we booted from
  int  0x13				; ask for bios disk service
  jnc  short .read_next_sector		; no error, let's go to the next sector
  mov  ah,   0				; reset disk system service
  int  0x13				; ask for bios disk service
  jc   short .disk_error		; error while resetting disk.. ouch
  dec  di				; retry decount..
  jnz  short .retry			; count not up yet, retry!

.disk_error:
  mov  si,   str_disk_error		; point to our cute message
.lock_it:
  jmp  near  lock_that_babe		; and lock that computer

.read_next_sector:
%ifndef __DEMO__			; is demo deactivated?
  call display_progress			; no demo? display progress (dots..)
%else
  call demo				; if demo is active, call one frame
%endif
  add  dword [dap_information.starting_block_number], byte 1
  adc  dword [dap_information.starting_block_number + 4], byte 0
  add  word [dap_information.transfer_buffer + 2], byte 0x0020
  dec  word [dap_information.block_count]
  jnz  short read_sectors
  retn



;                                 ---


get_partition_information:

  call read_sectors			; read partition table/mbr
  lea  si,   [$$ - 0x42]		; Point to it
  mov  cx,   4				; 4 partitions entry to process..

.reading_partition_table:
  cmp  byte  [si + part.type], 0x69	; compare with our own partition type
  jz   short .partition_entry_found	; seems like we found it

  add  si,   byte 16			; point to next partition entry
  loop .reading_partition_table		; go and read next entry if any

  mov  si,   str_no_partition		; set error message
  jmp  short read_sectors.lock_it	; lock that computer.

.partition_entry_found:
  mov  eax,   [si + part.starting_lba]	; get lba address
  dec  eax				; we are already loaded, bypass br


;                                 ---



load_system:
  add  eax,   dword [Wrapper.offset]	; read os wrapper's position on disk
  add  [dap_information.starting_block_number], dword eax
  mov  eax,   [loading_position]	; read linear destination offset
  shr  eax, 4				; convert linear to segmented address
  mov  [dap_information.transfer_buffer + 2], ax

%ifdef __DEMO__
  mov ax, 0x0013			; if demo active, set video to 320x200
  int 0x10				; ask for bios video service
%endif

.read_next_section:
  mov  ax,    0x0008			; number of sector in this section
  sub  [Wrapper.size], ax		; update amount left after this section
  jg  short  .read_section		; complete section of 8 sectors?

  add  ax,    [Wrapper.size]		; fix amount of sectors to read
  cmp  al,    8				; check if end is on a 4K boundary
  jnz   short .read_section		; nope, no problem then
  dec  word   [Wrapper.size]		; yes, make sure we don't crash it

.read_section:
  mov  [dap_information + DAP.block_count], ax
  call read_sectors			; read next section group

  test [Wrapper.size + 1], byte 0x80	; os wrapper entirely loaded?
  jz   short   .read_next_section	; no, continue loading

  mov ax, 0x0003			; if demo active, set back text mode
  int 0x10				; ask for bios video service
  mov ax, 0x1112
  int 0x10

 ;- deactivate fdc motor
 mov dx, 0x3F2			; [2]-disable fdc motor
 mov al, 0x0C			; [2]-fdc command: disable fdc motor

  ;]--Load default starting gdt
  lgdt [GDTR]

 out dx, al			; [2]-send command to fdc, disable motor

  ;]--Restore workable flags
  push word 0x0002		; all flags=0, IF=0 too :)
  popf

 ;- deactivate crt hardware cursor
 dec ax				; [2]-use value 0x0C of fdc routine, dec to 0x0B
 mov dl, 0xD4			; [2]-update dx to port 0x03D4 (dh=0x03,see fdc)
 dec ax				; [2]-select reg 0x0A
 out dx, al			; [2]-send selected reg index to crt
 inc dx				; [2]-select crt data port
 mov al, 0x20			; [2]-cursor disable flag
 out dx, al			; [2]-send it

  ;]--Enable protected mode
  mov eax, cr0				; read control register
  or al, 1				; enable protected mode
  mov cr0, eax				; write back modified value

  ;]--Transfer control to os-wrapper
  jmp dword 0x0008:.reentry		; reload cs
.reentry:
[bits 32]

  xor eax, eax				; prepare eax to hold segment selector
  mov al, 0x10				; selector 0x10, 32bit data seg
  mov ds, eax				; set ds = 0x0010
  mov es, eax				; set es = 0x0010
  mov fs, eax				; set fs = 0x0010
  mov gs, eax				; set gs = 0x0010
  mov ss, eax				; set ss = 0x0010
  mov esp, 0x00008000			; set stack pointer to bottom of oswrap
loading_position equ $-4		; use same var for os wrapper
  jmp near [byte esp + hdr_core.osw_entry]

[bits 16]

;                                 ---


%ifndef __DEMO__			; in case demo isn't active, progress!
display_progress:
  mov ah, 0x0E				; teletype service
  mov al, '.'				; set progress symbol
  xor bx, bx				; select sceen 0, no color
  int 0x10				; ask for bios video service
  retn					; return back to main routine
%endif

%ifdef __DEMO__				; demo activated! woohoo!
demo:
; A little demo >:)
pusha					; save all regs
push ds					; also save data segment
mov ax, 0xA000				; pointer to video memory
mov ds, ax				; make ds point to video memory
demo_loop:
mov cl, 0xC8				; set loop count/calculation value
xor di, di				; start drawing at pixel (0,0)
xor dx, dx				; start with color 0
long_loop:
mov ax, 0x0140				; adjusted values for cuty circles
little_loop:
add dx, cx				; color calculations
add dh, al				; color calculations
mov [di], dh				; put pixel
inc di					; go to next pixel
dec ax					; decrement x count
jnz short little_loop			; get to next pixel on same line
loop long_loop				; process next line
mov dx, 0x03C9				; DAC palette register
mov cl, 0x3F				; 63 colors to update
set_palette1:
push ax					; save current color for blue setting
mov al, 0				; set red and green to 0
out dx, al				; - set red
out dx, al				; - set green
pop ax					; restore shade of blue to use
out dx, al				; - set blue
inc ax					; select next lighter shade
loop set_palette1			; process next color
mov cl, 0x3F				; 63 colors to update
set_palette2:
push ax					; save current color for blue setting
mov al, 0				; set red and green to 0
out dx, al				; - set red
out dx, al				; - set green
pop ax					; restore shade of blue to use
out dx, al				; - set blue
dec al					; select next darker shade of blue
loop set_palette2			; process next color
pop ds					; restore data segment
popa					; make sure we didn't break anything ;)
retn					; go back to caller
%endif


;                                 ---




GDTR:
dw 0x17					; set to size of gdt (with null desc) -1
dd GDT - 8				; point to imaginary null pointer

;  struc DAP
;.header_length		resb 1
;.reserved		resb 1
;.block_count		resw 1
;.transfer_buffer	resd 1
;.starting_block_number	resd 2
;  endstruc

dap_information:			; disk access parameters
.header_length	db 10			;
db 0					;
.block_count	dw 1			;
.transfer_buffer	dd 0x07A00000	; 07A0:0000 -> 0x00007A00
.starting_block_number	dd 0,0


;- our little error messages
str_old_cpu:		db "386+",0
str_disk_error:		db "Disk error",0
str_no_partition:	db "Part?",0


;=------------ some fun out of optimization :P ------------=
db "Uuu"	; should leave absolutely no bytes unused ;)

;=------------ Alignment --------------=
TIMES 0x1E8 - ($-$$) db '_'
;=------------ Alignment --------------=

GDT:
dd 0x0000FFFF, 0x00CF9A00		; Code segment, 32bit, r/x, 4GB
dd 0x0000FFFF, 0x00CF9200		; Data segment, 32bit, r/w, 4GB

Wrapper:
.offset:	dd 1			; offset in partition/disk to os wrapper
.size:		dw (core_end-core_start)/200h

Boot_Record_Signature:
dw 0xAA55				; you need that one, believe me :P


;=------- Undefined Data Space ---------=
	absolute 0x7E00
disk_geometry:
.sectors_per_head	resd 1
.number_of_heads	resd 1

boot_drive		resb 1

section .text

;=------- image to load, ease calculations ;) -------=
align 512
core_start:
incbin "u3core.bin"

align 512
core_end:
