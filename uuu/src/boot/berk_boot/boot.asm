;----------------------------------------------------------------------------------------
;
; Multiboot-compliant boot loader (mainly for Go! OS and Unununium)
; Copyright (C) 2001, Stanislav Karchebny
; version 1.0.6
;
; Uses i/o code from Unununium Operating Engine's boot record, version 1.0.3
; Copyright (C) 2001, Dave Poirier
;
; Distributed under the BSD License.
;
;----------------------------------------------------------------------------------------
;
; Features:
; - cpu detection, 8088, 80286 and 80386+, will allow only 386+ to go thru
; - enable protected mode
; - can read more more than 256 sectors
; - boots from floppy, cdrom, zip, .., and hard disk partitions
; - support for partitions above 8GB (up to 2TB)
; - disable fdc motor after reading the sectors
; - progress indication while loading sectors
; - support for bios with the disk support extension
;
; Multiboot compliance features:
; - loads image at location specified in image header
;   the bad thing is it doesn't check for loading address to be in safe place so you can
;   easily crash your system if the load address is plain wrong or the image overwrites
;   some of the code.
; - scans first 8Kb of image for multiboot tag (0x1BADB002)
; - scans for all available memory
; - sets CS to 32-bit r/x segment at 0 with limit of 0xFFFFFFFF.
; - sets DS, ES, FS, GS, and SS to 32-bit r/w segments at 0 with limit of 0xFFFFFFFF.
; - enable a20 for both standard AT and PS/2 Microchanneled computers
; - processor interrupt flag IF is 0
; - EAX contains the magic value 0x2BADB002
; - EBX contains the 32-bit physical address of the Multiboot information structure
; - zeroes out BSS when present
;
;----------------------------------------------------------------------------------------

%ifdef UUU
%define PART_CODE 0x69      ; uuu partition code
%else
%define PART_CODE 0xAB      ; go! partition code
%endif

;----------------------------------------------------------------------------------------
;
; Disk Addressing Parameters - extended disk transfer info
;
struc DAP
   .header_length          resb 1
   .reserved               resb 1
   .block_count            resw 1
   .transfer_buffer        resd 1
   .starting_block_number  resd 2
endstruc

;----------------------------------------------------------------------------------------
;
; HDD partition
;
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

;----------------------------------------------------------------------------------------
;
; Multiboot image header
;
struc mboot
   .magic                  resd 1
   .flags                  resd 1
   .checksum               resd 1
   .header_addr            resd 1 ; physical address of multiboot magic (for syncing)
   .load_addr              resd 1 ; physical address of .text
   .load_end_addr          resd 1 ; physical address of .data end
   .bss_end_addr           resd 1 ; physical address of .bss end
   .entry_addr             resd 1 ; physical address of entry point
endstruc


;----------------------------------------------------------------------------------------
;
;  Let's go
;
[org 0x7C00]
[bits 16]

section .text

_boot_record:
   xor    bx,  bx                                          ; bx = 0, used to set segment selectors
   mov    ds,  bx                                          ; ds = 0
   mov    es,  bx                                          ; es = 0
   mov    ss,  bx                                          ; ss = 0
   mov    si,  str_old_cpu

   ; -- Test if bit 14 stay always clear, indicate 80286
   ;     or if bit 12/13 stay always set, indicates 8088

   mov    sp,  0x4004                                      ; after pushing flag, sp = 4002
   push   sp                                               ; set bit 14
   popf                                                    ; load flags with it
   pushf                                                   ; save back flags
   pop    ax                                               ; get back final result
   test   ah,  0x30                                        ; bit 12-13 set?
   out    0x92, al                                         ; [2] Enable PS/2 gate A20 - send 0x04
   jnz    short error_exit                                 ; yip, 8088 detected
   test   ah,  0x40                                        ; bit 14 still set?
   mov    al, 0xD1                                         ; [2] Enable A20
   out    0x64, al                                         ; [2] Send to keyboard command port
   jz     short error_exit
                                                           ; yes, good, we have 80386 or above :)
   mov    al, 0x03                                         ; [2] Enable A20
   out    0x60, al                                         ; [2] Send to keyboard data port


bios_extensions_test:
   mov [boot_drive], dl                                    ; save drive id that we booted from

   ; -- Test for IBM/MS Int 13 Extensions

   mov  ah,   0x41                                         ; installation check service
   mov  bx,   0x55AA                                       ; req value, should be inversed if valid
   xor  bp,   bp                                           ; set var used later to diff chs/lba
   int  0x13                                               ; ask for bios disk service
   jc   short .no_extension                                ; cf=1 mean not installed
   cmp  bx,   0xAA55                                       ; is it inversed?
   jne  short .no_extension                                ; no, not installed :(
   test cl, 1                                              ; installed, does it provides 0x42?
   jz   short .lba_extension_enabled                       ; yes? nice :))

.no_extension:
   mov  ah,   0x08                                         ; get drive parameters service
   xor  di,   di                                           ; es:di = 0, some bios are capricious
   inc  bp                                                 ; set var for chs (1)
   int  0x13                                               ; ask for bios disk service
   jc   short read_sectors.disk_error                      ; error occured, display message
   and  ecx,  byte 0x3F                                    ; keep only sectors, discard cylinders
   mov  [disk_geometry.sectors_per_head], ecx
   mov  cl,   dh                                           ; move number of heads in cl (ecx)
   inc  cx                                                 ; increment it, doing modulo later
   mov  [disk_geometry.number_of_heads], ecx

.lba_extension_enabled:
   mov  ah,   0                                            ; reset disk system service
   mov  dl,   [boot_drive]                                 ; select startup drive
   int  0x13                                               ; ask for bios disk service
   jc   short read_sectors.disk_error                      ; error occured, display message

   xor  eax,  eax                                          ; set starting lba to 0 in case fdd/cdrom
   or   dl,   dl                                           ; verify if start was on a floppy
   js   short get_partition_information                    ; we are on hdd, get partition info
   jmp  near  load_system                                  ; floppy? no partition table!


;----------------------------------------------------------------------------------------
;
; Type message and halt
;
error_exit:
   mov  ah,  0x0E                                          ; teletype service
   xor  bx,  bx                                            ; select page 0, color 0
   mov  cx,  3                                             ; print that much chars
.displaying:
   lodsb                                                   ; load char
   int  0x10                                               ; ask for bios video service
   loop .displaying                                        ; and go to next char
   jmp short $                                             ; lockit!!


;----------------------------------------------------------------------------------------


read_sectors:
; bp  = chs/lba selector
;       0 = lba (using 13h bios service extensions)
;       1 = chs
; DAP = contain the sectors relative information
   mov  di, 4                                              ; maximum retry count for one sector
.retry:
   mov  si,   dap_information                              ; load pointer to dap (just in case)
   mov  ah,   0x42                                         ; extended service disk read (just in case)
   or   bp,   bp                                           ; test for disk extension presence
   jz   short .extensions_enabled                          ; disk extension present, use DAP

.extensions_not_present:
   mov  edx,   [dap_information.starting_block_number + 4] ; high part of block id
   mov  eax,   [dap_information.starting_block_number]     ; low part of block id
   div  dword  [disk_geometry.sectors_per_head]            ; calculate sector value
   mov  cx,   dx                                           ; load remainder, sector value
   inc  cx                                                 ; sectors start at 1, not 0
   mov  dl,   0                                            ; clear remainder
   div  dword  [disk_geometry.number_of_heads]             ; get cylinder and head value
   mov  ch,   al                                           ; set low cylinder
   shl  ah,   6                                            ; isolate high cylinder part
   or   cl,   ah                                           ; or high cylinder part with sectors
   mov  dh,   dl                                           ; set head value
   mov  ax,   0x0201                                       ; service 02 (read disk), for 1 sector
   les  bx,   [dap_information.transfer_buffer]

.extensions_enabled:
   mov  dl,   [boot_drive]                                 ; read drive id where we booted from
   int  0x13                                               ; ask for bios disk service
   jnc  short .read_next_sector                            ; no error, let's go to the next sector
   mov  ah,   0                                            ; reset disk system service
   int  0x13                                               ; ask for bios disk service
   jc   short .disk_error                                  ; error while resetting disk.. ouch
   dec  di                                                 ; retry decount..
   jnz  short .retry                                       ; count not up yet, retry!

.disk_error:
   mov  si,   str_disk_error                               ; point to our cute message
.lock_it:                                                  ; "jump out of range" fixing label
   jmp  short error_exit                                   ; and lock that computer

.read_next_sector:

   ; -- display progress (blocks..)
   mov  ax, 0x0EFE                                         ; 0E = teletype service, FE = 'þ'
   xor  bx, bx                                             ; select screen 0, no color
   int  0x10                                               ; ask for bios video service

   add  dword [dap_information.starting_block_number], byte 1
   adc  dword [dap_information.starting_block_number + 4], byte 0
   add  word [dap_information.transfer_buffer + 2], byte 0x0020
   dec  word [dap_information.block_count]
   jnz  short read_sectors
   retn


;----------------------------------------------------------------------------------------


get_partition_information:
   call read_sectors                                       ; read partition table/mbr to 0x7A00
   lea  si,   [$$ - 0x42]                                  ; Point to it
   mov  cx,   4                                            ; 4 partition entries to process..

.reading_partition_table:
   cmp  byte  [si + part.type], PART_CODE                  ; compare with our own partition type
   jz   short .partition_entry_found                       ; seems like we found it

   add  si,   byte 16                                      ; point to next partition entry
   loop .reading_partition_table                           ; go and read next entry if any

   mov  si,   str_no_partition                             ; set error message
   jmp  short read_sectors.lock_it                         ; lock that computer.

.partition_entry_found:
   mov  eax,   [si + part.starting_lba]                    ; get lba address
   dec  eax                                                ; we are already loaded,
                                                           ; bypass bootrecord


;----------------------------------------------------------------------------------------


load_system:
   add   eax,  byte Wrapper.offset                         ; read os wrapper's position on disk
   add   [dap_information.starting_block_number],  dword eax
   movzx eax,  word [Wrapper.size]
   mov   [dap_information.block_count],  ax
   mov   ax, 0x1000                                        ; get image load segment (64K)
   mov   [dap_information.transfer_buffer + 2], ax         ; keep for loading routine

   call read_sectors                                       ; read image

   ; -- deactivate fdc motor

   mov dx, 0x3F2                                           ; fdc command port
   mov al, 0x0C                                            ; fdc command: disable fdc motor
   out dx, al                                              ; send command to fdc, disable motor


fill_multiboot_header:
	xor eax, eax
	inc ax                                                  ; save a byte, dude!
   mov dword [Multiboot_header.flags], eax                 ; pass memory info
   movzx eax, word [0x413]                                 ; conventional memory size in 0x40:0x13
   mov [Multiboot_header.mem_lower], eax                   ; low memory


;----------------------------------------------------------------------------------------
;
; -- Prepare for and Switch to Protected Mode
;
   lgdt [GDT]                                              ; Load default starting gdt

   push byte 0x02                                          ; Restore workable flags
   popf                                                    ; all flags=0, IF=0 too :)

   ; -- Enable protected mode
   mov eax, cr0                                            ; read control register 0
   or  al,  1                                              ; enable protected mode
   mov cr0, eax                                            ; write back modified value

   ; -- Transfer control to os-wrapper
   jmp dword 0x0008:reentry                                ; reload cs


;----------------------------------------------------------------------------------------
;
;  Now executing in protected mode, CS - r/x segment, other regs undefined atm
;
[bits 32]
reentry:
   ; -- Set up segment registers to "good" values
   mov eax, data - GDT                                     ; 32bit data seg selector
   mov ds, eax
   mov es, eax
   mov fs, eax
   mov gs, eax
   mov ss, eax


;----------------------------------------------------------------------------------------
; Make through memory probe and fill multiboot info mem_upper
;
memory_test:
   mov edi, 0x00100000                                     ; start scanning at 1 meg
   mov ebx, edi                                            ; with 1 meg increments
.processing:
   mov eax, [edi]                                          ; probe memory at edi
   xor [edi], edi                                          ; (destructively)
   cmp [edi], eax
   jz short .end_of_ram                                    ; can't read/write - not present
   add edi, ebx                                            ; advance to next meg
   jmp short .processing
.end_of_ram:                                               ; EDI = physical ram installed in bytes
   sub edi, ebx                                            ; subtract 1 meg for correct mboot
   shr edi, 10                                             ; information and divide by 1024
   mov [Multiboot_header.mem_upper], edi                   ; high memory in kbytes


;----------------------------------------------------------------------------------------
; Prepare multiboot image for booting
;
; -- Scan 8Kb of loaded image for dword aligned multiboot magic number
;
scan_multiboot:
   mov edi, 0x00010000                                     ; get loading position (64K)
   mov cx, 8192/4                                          ; scan first 8K
   mov eax, 0x1BADB002                                     ; for magic
   repne scasd
.wrong_image:
   jne short $                                             ; well, not the best

.found_image:
	sub  edi, byte 4                                        ; adjust edi to point exactly to header
   test byte [edi + mboot.flags + 2], 0x01                 ; bit 16 should be set or boot will fail
   jz   short $                                            ; berkus: could remove this test (?)

; -- Move image to required location
; move image from offset `header - (header_addr - load_addr)` to memory location load_addr

move_image:
   mov eax, [edi + mboot.header_addr]
   mov esi, [edi + mboot.load_addr]
   mov ecx, [edi + mboot.load_end_addr]
   mov ebx, [edi + mboot.bss_end_addr]
   mov edx, edi                                            ; save header pointer
   mov edi, esi                                            ; save target image position to EDI
   sub ebx, ecx                                            ; calculate .bss size
   sub ecx, esi                                            ; calculate .text+.data size for moving
   sub esi, eax                                            ; esi = load_addr - header_addr
   add esi, edx                                            ; esi = header - header_addr + load_addr + 4

   rep movsb                                               ; move image

   mov  ecx, ebx                                           ; zero BSS
   xchg eax, ebx                                           ; save image location to EBX
   or   ecx, ecx                                           ; do not zero if no bss
   jz   short .no_bss
   xor  eax, eax
   rep  stosb

.no_bss:
   mov edi, ebx                                            ; ebx is moved image header location
   mov eax, 0x2BADB002                                     ; multiboot loader magic
   mov ebx, Multiboot_header                               ; physical address of boot information
   jmp near [edi + mboot.entry_addr]                       ; jump off the os wrapper


;----------------------------------------------------------------------------------------


dap_information:                                           ; struc DAP, disk access parameters
   .header_length          db 10
   .reserved               db 0
   .block_count            dw 1                            ; initial value for reading MBR
   .transfer_buffer        dd 0x07A00000                   ; initial value for reading MBR
   .starting_block_number  dd 0,0


;----------------------------------------------------------------------------------------
; -- A baby GDT, with code and data from 0 to 4G.

GDT   dw gdt_limit
      dd GDT
Wrapper.size:
      dw (core_end-core_start)/0x200                       ; size in sectors
;     ^^^ - align is necessary!, we just put something useful in here

code  dd 0x0000FFFF, 0x00CF9800 ; A code segment, 32 bit, r/x, from 0 up to 4G (well, FFFFF000)
data  dd 0x0000FFFF, 0x00CF9200 ; A data segment, 32 bit, r/w, from 0 up to 4G (well, FFFFF000)

gdt_limit equ $-GDT-1


; -- our VERY little error messages
str_old_cpu:         db "386"                              ; Need 386+ CPU
str_disk_error:      db "Dsk"                              ; Disk error
str_no_partition:    db "Prt"                              ; No proper partition found


; -- padding, should leave absolutely no bytes unused ;)

TIMES 0x1FE - ($-$$) db '_'


Boot_Record_Signature:
dw 0xAA55                                                  ; you need that one, believe me :P


;----------------------------------------------------------------------------------------
; -- image to load - include your favourite multiboot core here :P
;
align 512
core_start:

%ifdef UUU
incbin "u3core.bin"
%elifdef MBTEST
incbin "../bin/mbtest"
%else
incbin "../bin/mboot_go"
%endif

align 512
core_end:


Wrapper.offset equ (core_start - $$)/0x200                 ; offset in partition/disk to os wrapper


;--------------------------------------------------------------------------
; Undefined Data Space
;
[absolute 0x7E00]

boot_drive         resb 1

disk_geometry:
.sectors_per_head  resd 1
.number_of_heads   resd 1

Multiboot_header:
.flags             resd 1
.mem_lower         resd 1
.mem_upper         resd 1

