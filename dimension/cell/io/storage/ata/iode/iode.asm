;---------------------------------------------------------------------------==|
; Iode cell                                Copyright (c) 2000-2001 Dave Poirer
; Primary IDE driver                         Distributed under the BSD License
;---------------------------------------------------------------------------==|


[bits 32]

section .c_info
	db 1,0,0,"a"
	dd str_title
	dd str_author
	dd str_copyrights

	str_title:
	db "IODE - IDE driver",0

	str_author:
	db "Dave Poirer, Hubert Eichner",0

	str_copyrights:
	db "BSD Licensed",0


; too lazy to make a const.def
__IODE_ADD_DEVICE_ERR__   equ 1
%define _DEBUG_

;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc local_file_descriptor
  .global:	resb file_descriptor_size	; should be 8
  .device:	resd 1				; device number (which drive?)
  .lba_start:	resd 2				; 64bit start LBA
  .lba_end:	resd 2				; 64bit end LBA
endstruc

%define LOCAL_FILE_DESCRIPTOR_SIZE 28
;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
;| information:
;| - EAX        Options
;|              bit 0, 1=reloading, 0=clean boot
;| - ECX        Size in bytes of the free memory block reserved for our use
;| - EDI        Pointer to start of free memory block
;| - ESI        Pointer to CORE header
;|
;| Those information must be kept intact and passed as is to the next cell
;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

section .c_init
global _start
_start:

init:
; detect drives and allocate mem for structures
; scans only the primary bus atm
;-----------------------------------------------;
pushad						;
mov ebp, drives.pm				; first drive
mov ecx, 512					; sector:512b
externfunc mem.alloc				; 
call _wait_not_busy	  			; wait
mov edx, dword 0x01F6				;
in al, dx					; get device/head register
and al, 11101111b				; select first drive (bit 4=0)
;-----------------------------------------------;  
.probe:						; test for drives
push ax						; __wait... destroys eax, edx
push dx						;
call _wait_not_busy    				; wait
pop dx						;
pop ax						;
out dx, al					; write dev/hd register
call _wait_not_busy				; wait until drive is ready
mov dl, 0xF7					; write to the command register
mov al, 0xEC					; the IDENTIFY command
out dx, al					; 
call _wait_not_busy				; wait
mov dl, 0xF0					; from data port
mov ecx, 256					; read 256 words
repz insw					; into buffer
sub edi, 512					; set edi to start of buffer
mov ax, word [edi+2*49]				; read capabilities field
test ax, 0000001000000000b			; lba bit set?
jz .no_lba_drive_found				; either no drv or no lba
;-----------------------------------------------;
mov esi, edi					; save buffer
mov ecx, 8					; alloc 2dws for drive_geometry
externfunc mem.alloc				; 
mov dword [ebp], edi				; store pointer in drives.XX
xchg esi, edi					; restore edi
xor eax, eax					; clear eax
mov ax, word [edi+56*2]				; get current lg. sectors/track
mov dword [esi+drive_geometry.sectors_per_track], eax	; store it
mov ax, word [edi+55*2]				; get logical heads/cylinder
mov dword [esi+drive_geometry.heads_per_cylinder],eax	; store
;-----------------------------------------------;
mov eax, dword [ebp]				; load the registers with the
mov ebx, _open					; right values for the
xor ecx, ecx					; part.scan function.
mov esi, primary_dev				;
cmp ebp, drives.pm				; did we process the first drv?
jz .firstdrive					;
inc ecx						; second drive
add esi, 5					; esi := ptr to secondary dev.
.firstdrive:					;
externfunc part.initialize			; find partitions
;-----------------------------------------------;
.no_lba_drive_found:				;
cmp ebp, drives.pm				; check if finished
jnz .finished					;
add ebp, 4					; ebp now points to drive.ps
mov ecx, 256					; initialize some values
call _wait_not_busy				;
mov dl, 0xF6					;
in al, dx					;
or ax, 0000000000010000b			; select second drive (slave)  
jmp .probe					; probe slave
;-----------------------------------------------;
  						;
.finished:					;
						;
.end:						;
  popad						; end of init section.
  retn						;
;-----------------------------------------------;



;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                    __raw_read
;==============================================================================

__raw_read:
;>
;; parameters:
;; -----------
;; EDX:EAX = 64 bit LBA
;; ECX = number of sectors to read
;; EDI = pointer to buffer to put data in
;; EBX = pointer to file handle
;;
;; returned values:
;; ----------------
;; errors as usual
;<
;-----------------------------------------------;
						;
  push edi					;
  clc						; clear carry
  add eax, dword [ebx+local_file_descriptor.lba_start]
  adc edx, dword [ebx+local_file_descriptor.lba_start+4]
  mov ebx, [ebx+local_file_descriptor.device]	;
  test edx, edx					; lba addreess out of range?
  jnz short .sector_above_supported_address	;
;-----------------------------------------------;
.continue:					;
  test eax, 0xF0000000				;
  jnz short .sector_above_supported_address	;
  cmp bl, 1					; drive one or zero?
  ja short .invalid_drive			;	
.reading_next_sector:				;
  push ecx					;
  push eax					;
  push ebx					;
  mov dl, bl					;
  call _read_sector				;
  pop ebx					;
  pop eax					;
  pop ecx					;
  jc short .error_while_reading			;
  inc eax					;
  dec ecx					;
  jnz short .reading_next_sector		;
  pop edi					;
  clc						;
  retn						;
;-----------------------------------------------;  
.error_while_reading:				;
  dbg lprint "IODE: error while reading", LOADINFO
  mov edi, eax					;
  xor eax, eax					;
  dec eax					; TODO: define an error code
  xor edx, edx					;		
  pop edi					;
  stc						;
  retn						;
;-----------------------------------------------;
.invalid_drive:					;
  dbg lprint "IODE: invalid drive", LOADINFO	;
  xor eax, eax	; TODO: define specific error code for invalid drive
  dec eax					;
  pop edi					;
  stc						;
  retn						;
;-----------------------------------------------;
.sector_above_supported_address:		;
  dbg lprint "IODE: sector above supported address", LOADINFO
  xor eax, eax					;
  dec eax   					; TODO: define an error code
  pop edi					;
  stc						;
  retn						;
;-----------------------------------------------;


		
;                                           -----------------------------------
;                                                                  _read_sector
;==============================================================================

_read_sector:
; parameters:
;------------
; eax = lba
; edi = location where to put the data (512 bytes)
; dl  = drive, 0 = master, 1 = slave

  test eax, 0xF0000000	; test for bits 28-31
  jnz short .return_error
  test dl, 0xFE		; test for invalid device ids
  jnz short .return_error
  push edx
  push eax
  call _wait_not_busy

  mov dl, 0xF2		; port 0x1F2 (sector count register)
  mov al, 0x01		; read one sector at any given time
  out dx, al		;

  inc edx		; port 0x1F3 (sector number register)
  pop ecx		; set ecx = lba
  mov al, cl		; al = lba bits 0-7
  out dx, al		;

  inc edx		; port 0x1F4 (cylinder low register)
  mov al, ch		; al = lba bits 8-15
  out dx, al		;

  inc edx		; port 0x1F5 (cylinder high register)
  ror ecx, 16		;
  mov al, cl		; set al = lba bits 16-23
  out dx, al		;

  pop eax		; restore drive id
  inc edx		; port 0x1F6 (device/head register)
  and ch, 0x0F		; set ch = lba bits 24-27
  shl al, 4		; switch device id selection to bit 4
  or al, 0xE0		; set bit 7 and 5 to 1, with lba = 1
  or al, ch		; add in lba bits 24-27
  out dx, al		;

  call _wait_drdy	; wait for DRDY = 1 (Device ReaDY)
  test al, 0x10		; check DSC bit (Drive Seek Complete)
  jz short .return_error

  mov al, 0x20		; set al = read sector(s) (with retries)
  out dx, al		; edx = 0x1F7 == command/status register

  ; TODO: ask for thread yield, giving time for hdd to read data
  jmp short $+2
  jmp short $+2

  call _wait_not_busy.waiting	; bypass the "mov edx, 0x1F7"
  test al, 0x01     ; check for errors
  jnz short .return_error

  mov dl, 0xF0		; set dx = 0x1F0 (data register)
  mov ecx, 256		; 256 words (512 bytes)
  repz insw		; read the sector to memory
  clc			; set completion flag to successful
  retn			;

.return_error:
  dbg lprint "IODE: error in read_sector!", DEBUG
  mov dl, 0xF1		; error status register 0x1F1
  in al, dx		; read error code
  stc			; set completion flag to failed
  retn			;



_wait_drdy:
; Parameters: none
; returns:
;   al = status register value
;   edx = 0x1F7
;
; TODO: add check in case DRDY is 0 too long
;
  mov edx, 0x00001F7		; set edx = status register
.waiting:
  in al, dx			; read status
  test al, 0x40			; check DRDY bit state
  jz .waiting			; if DRDY = 0, wait
  retn



;                                           -----------------------------------
;                                                                _wait_not_busy
;==============================================================================

_wait_not_busy:
; parameters: none
; destroys: edx = 0x1F7
; returns: al = status
; TODO: add error check if drive is busy too long
  mov edx, 0x000001F7
.waiting:
  in al, dx
  test al, 0x80
  jnz .waiting
  retn

;                                           -----------------------------------
;                                                                       __error
;==============================================================================

__error:
  xor eax, eax
  dec eax
  stc
  retn

;                                           -----------------------------------
;                                                                         _open
;==============================================================================

_open:
;>
;; parameters:
;; -----------
;; EBX:EAX = LBA start
;; ESI:ECX = LBA end
;; EDX = pointer to fs descriptor
;; EDI = device number
;;
;; returned values:
;; ----------------
;; EBX = ptr to file handle
;; errors as usual
;<


  push ecx
  push edi
  push eax
  push edx
  mov ecx, LOCAL_FILE_DESCRIPTOR_SIZE
  externfunc mem.alloc
  jnc .go_on
  dbg lprint "IODE: Could not alloc mem for _open function!", DEBUG
  add esp, 16 
  stc
  retn
  
  .go_on:
  pop edx
  pop eax
  mov dword[edi+file_descriptor.op_table], our_op_table
  mov dword[edi+file_descriptor.fs_descriptor], edx
  pop dword[edi+local_file_descriptor.device]
  mov dword[edi+local_file_descriptor.lba_start], eax
  mov dword[edi+local_file_descriptor.lba_start+4], ebx
  pop dword[edi+local_file_descriptor.lba_end]
  mov dword[edi+local_file_descriptor.lba_end+4], esi
  mov eax, __raw_read
  mov ebx, edi


  .end:
  retn





;                                           -----------------------------------
;                                                                 section .data
;==============================================================================

section .data

our_op_table: istruc file_op_table
at file_op_table.close,		dd __error
at file_op_table.read,		dd __error
at file_op_table.write,		dd __error
at file_op_table.raw_read,	dd __raw_read
at file_op_table.raw_write,	dd __error
at file_op_table.seek_cur,	dd __error
at file_op_table.seek_start,	dd __error
at file_op_table.seek_end,	dd __error
at file_op_table.read_fork,	dd __error
at file_op_table.write_fork,	dd __error
at file_op_table.link,		dd __error
at file_op_table.unlink,	dd __error
at file_op_table.create,	dd __error
at file_op_table.rename,	dd __error
at file_op_table.copy,		dd __error
at file_op_table.truncate,	dd __error
at file_op_table.attrib,	dd __error
iend

primary_dev:		db "hd/0",0
secondary_dev:		db "hd/1",0


; This shows to the drive's geometry structure
drives:
	.pm:		dd 0
	.ps: 		dd 0

struc drive_geometry
	.sectors_per_track:	resd 1
	.heads_per_cylinder:	resd 1
endstruc


