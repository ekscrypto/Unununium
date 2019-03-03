;---------------------------------------------------------------------------==|
; Iode cell                                Copyright (c) 2000-2001 Dave Poirer
; Primary IDE driver                         Distributed under the BSD License
;---------------------------------------------------------------------------==|

[bits 32]

; too lazy to make a const.def
__IODE_ADD_DEVICE_ERR__   equ 1


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc local_file_descriptor
  .global:	resb file_descriptor_size
  .drive:	resb 1				; 1 for slave, 0 for primary
endstruc

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
;| informatin:
;| - EAX        Options
;|              bit 0, 1=reloading, 0=clean boot
;| - ECX        Size in bytes of the free memory block reserved for our use
;| - EDI        Pointer to start of free memory block
;| - ESI        Pointer to CORE header
;|
;| Those information must be kept intact and passed as is to the next cell
;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

section .c_init

  jmp short init

init_complete_str:	db "[iode] Initialization completed ($Revision: 1.18 $)",0
add_device_err_str:	db "[iode] add device error", 0
primary_dev:		db "/hd/0",0
secondary_dev:		db "/hd/1",0

add_device_err:
  mov esi, add_device_err_str
  externfunc sys_log.print_string
  pop esi
  mov eax, __IODE_ADD_DEVICE_ERR__
  stc
  jmp short init.end

init:
  pushad

  ; register primary ide drive
  mov esi, primary_dev
  mov ebx, _open
  xor ebp, ebp
  externfunc devfs.register
  jc add_device_err
    
  ; register secondary ide drive
  mov esi, secondary_dev
  inc ebp
  externfunc devfs.register
  jc add_device_err
    
.end:
  popad

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

  push edi
  mov bl, [ebx+local_file_descriptor.drive]
  test edx, edx
  jnz short .sector_above_supported_address

.continue:
  test eax, 0xF0000000
  jnz short .sector_above_supported_address
  cmp bl, 1
  ja short .invalid_drive
.reading_next_sector:
  push ecx
  push eax
  push ebx
  mov dl, bl
  call _read_sector
  pop ebx
  pop eax
  pop ecx
  jc short .error_while_reading
  inc eax
  dec ecx
  jnz short .reading_next_sector
  pop edi
  clc
  retn
  
.error_while_reading:
  mov edi, eax
  xor eax, eax
  dec eax	; TODO: define an error code yet again..
  xor edx, edx
  pop edi
  stc
  retn

.invalid_drive:
  xor eax, eax	; TODO: define specific error code for invalid drive
  dec eax
  pop edi
  stc
  retn

.sector_above_supported_address:
  xor eax, eax
  dec eax   ; TODO: define an error code for this error
  pop edi
  stc
  retn

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
;; EBP = same value as EBP we used when we registered: drive number
;; EDX = ptr to fs descriptor
;;
;; returned values:
;; ----------------
;; EBX = ptr to file handle
;; errors as usual
;<

  mov ecx, local_file_descriptor_size
  push ebp
  push edx
  externfunc mem.alloc

  mov ebx, edi
  mov dword[edi+file_descriptor.op_table], our_op_table
  pop dword[edi+file_descriptor.fs_descriptor]
  pop ecx
  mov [edi+local_file_descriptor.drive], cl

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
