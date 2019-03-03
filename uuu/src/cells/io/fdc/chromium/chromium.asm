;; $Header: /cvsroot/uuu/uuu/src/cells/io/fdc/chromium/chromium.asm,v 1.30 2002/01/04 18:44:35 lukas2000 Exp $
;; 
;; Chromium FDC driver		Copyright (C) 2001 Phil Frost
;; Designed to last :)		Distributed under the BSD license
;;
;; Hopefully this driver will be somewhat good and will stay around for some
;; time. It makes no use of any sissy bios and might even do caching some day :)
;; Right now it's quite stupid though...it assumes a standard floppy format
;; and DMA 2 and IRQ 6 and will only deal with the primary FDC on the standard
;; base port of 0x3f0. Fortinutely, that's not a problem for 99% of us :)
;;
;; status:
;; -------
;; Young, green, but thought to be working (by the brave anyway).
;;

[bits 32]

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_
%define _CALIBRATE_RETRY_	3
%define _READ_RETRY_		3

; error codes from the floppy returned by _read_result
%define _ERR_UNKNOWN_		-1
%define _ERR_INVALID_COMMAND_	1


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc local_file_descriptor
  .global:	resb file_descriptor_size
endstruc


section .c_info
	db 1,0,0,"a"
	dd str_title
	dd str_author
	dd str_copyrights

	str_title:
	db "Chromium",0

	str_author:
	db "indigo",0

	str_copyrights:
	db "BSD Licensed",0




;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init

init:
  jmp init.start

  .dev_name:	db "/fd/0",0

.could_not_calibrate:
  lprint {"chromium fdc: could not calibrate drive",0xa}, FATALERR
  stc
  jmp short .end

.not_enough_ram:
  lprint {"chromium fdc: insufficient memory to allocate disk buffers",0xa}, FATALERR
  stc
  jmp short .end

.start:
  pushad

  ; allocate a buffer for one track
  mov ecx, 0x2400 * 2	; XXX don't need this much but it's needed for alignment
  xor edx, edx
  externfunc mem.alloc_20bit_address
  jc .not_enough_ram
  mov edx, edi
  mov esi, edi
  add edx, 0x2400 - 1	; add the amount of memory we need
  xor esi, edx		; and see if that changes the high bits
  test esi, 0xFFF70000	; if it does, it spans 2 pages
  jz .aligned

  add edi, 0x2400
.aligned:

  mov [track_buffer], edi

  ; hook irq 6
  mov esi, irq_client
  mov al, 6
  externfunc int.hook_irq

  ; reset the FDC and spin up the motor for now. More intelegence later...
  ;mov edx, 0x3f2	; DOR
  ;xor al, al
  ;out dx, al		; reset the controler

  mov edx, 0x3f2
  mov al, 00011100b	; drive A on, dma enabled, controler ready
  out dx, al

  call _calibrate
  jc .could_not_calibrate

  ; register with devfs
  mov ebx, _open
  mov esi, .dev_name
  externfunc devfs.register

  lprint {"chromium fdc: version $Revision: 1.30 $ loaded",0xa}, LOADINFO

  clc
.end:
  popad

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                   _write_data
;==============================================================================

_write_data:
;;
;; waits for the FDC to become ready, then writes a byte to the data register
;;
;; parameters:
;; -----------
;; AH = byte to write
;;
;; returned values:
;; ----------------
;; DX = 0x3f5
;;

  push ecx
.try_again:
  mov ecx, 0x30000
  mov dx, 0x3f4
.wait:
  in al, dx
  dec ecx
  jz .read_extra
  and al, 0xC0
  cmp al, 0x80
  jne .wait

  inc edx
  mov al, ah
  out dx, al

  pop ecx
  retn

.read_extra:
  dbg_print "*** _write_data: something didn't read enough results; reading them",0
  call _read_data
  jmp .try_again
  

;                                           -----------------------------------
;                                                                    _read_data
;==============================================================================

_read_data:
;;
;; waits for the FDC to be ready, then reads a byte from the data register
;; 
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EDX = 0x3F5
;; AL = byte read
;; 

  push ecx
  mov ecx, 0x30000
  mov edx, 0x3F4	; main status register
.wait:
  in al, dx
  dec ecx
  jz .puke
  and al, 0xC0
  cmp al, 0xC0
  jne .wait

  inc edx
  in al, dx

  pop ecx

  retn

.puke:
  lprint {"chromium fdc: _read_data has been waiting some time now; MSR: %2x",0xa}, DEBUG, eax
  jmp short $

;                                           -----------------------------------
;                                                                   _lba_to_chs
;==============================================================================

_lba_to_chs:
;; converts 16 bit LBA to CHS
;;
;; parameters:
;; -----------
;; AX = LBA
;; [sct_per_trk] = sectors per track
;;
;; returned values:
;; ----------------
;; BH = cyl
;; AH = sector
;; BL = head
;; everything else = unchanged
;;
;; This function is really stupid, it will work for standard floppies only

  div byte[sct_per_trk]	; divides AX; answer is in al, remainder in ah
  ;; AL = cyl
  ;; AH = will be sector

  inc ah		; because LBA starts at 0 but we don't
  xor bl, bl		; bl will be the head
  cmp ah, 18		; ah will be the sector
  jna .head0

  ; it's on head 1, subtract 18 and make head 1
  sub ah, 18
  inc bl

.head0:
  mov bh, al
  retn

;                                           -----------------------------------
;                                                                   _seek_heads
;==============================================================================

_seek_heads:
;; seeks the heads...gee
;;
;; parameters:
;; -----------
;; AH = cyl to seek to
;; BH = drive
;;
;; returned values:
;; ----------------
;; DX = 0x3f5
;; everything else = unchanged

  %ifdef _DEBUG_
  dbg_print "seeking heads to cyl ",1
  push edx
  movzx edx, ah
  externfunc sys_log.print_hex
  externfunc sys_log.terminate
  pop edx
  %endif
  
  push eax
  mov ah, 0xf
  call _write_data
  mov ah, bh
  call _write_data
  pop eax
  call _write_data

  call _wait_for_int
  call _ack_int
  
;  pushad
;  mov ah, 01001010b
;  call _write_data
;  xor eax, eax
;  call _write_data
;  call _wait_for_int
;
;  call _read_data
;  dbg_print "  pos after seek: st0: ",1
;  movzx edx, al
;  externfunc sys_log.print_hex
;
;  call _read_data
;  dbg_print "  st1: ",1
;  movzx edx, al
;  externfunc sys_log.print_hex
;
;  call _read_data
;  dbg_print "  st2: ",1
;  movzx edx, al
;  externfunc sys_log.print_hex
;  externfunc sys_log.terminate
;
;  call _read_data
;  dbg_print "  cyl: ",1
;  movzx edx, al
;  externfunc sys_log.print_hex
;
;  call _read_data
;  dbg_print "  head: ",1
;  movzx edx, al
;  externfunc sys_log.print_hex
;
;  call _read_data
;  dbg_print "  sect: ",1
;  movzx edx, al
;  externfunc sys_log.print_hex
;
;  call _read_data
;  dbg_print "  size: ",1
;  movzx edx, al
;  externfunc sys_log.print_hex
;  externfunc sys_log.terminate
;
;  popad

  retn

;                                           -----------------------------------
;                                                                    _calibrate
;==============================================================================

_calibrate:
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; CF set iff error
;; 

  dbg_print "calibrating heads",0
  mov ecx, _CALIBRATE_RETRY_+1
.retry:
  mov ah, 0x07
  call _write_data
  xor ah, ah
  call _write_data

  call _wait_for_int
  call _ack_int

  dec ecx
  jz .give_up

  and ah, 11100000b
  cmp ah, 00100000b
  jne .retry
  
  clc
  retn

.give_up:
  dbg_print "wasn't able to calibrate drive, blagh",0
  stc
  retn

;                                           -----------------------------------
;                                                                  _program_dma           
;==============================================================================

_program_dma:
;; programs the DMA controller for a transfer. Assumes channel 2.
;;
;; parameters:
;; -----------
;; DL = mode ( add the channel too so: 0x46 for io -> mem; 0x4a for mem -> io )
;; CX = legnth - 1
;; EBX = src / dest ( must be below 16M and not cross page )
;; 
;; returned values:
;; ----------------
;; EAX = destroyed
;; everything else = unchanged

  dbg_print "programing DMA to transfer ",1
  dbg_print_hex ecx
  dbg_print "+1 bytes",0

  mov al, 6
  out 0xa, al		; set mask on channel 2

  xor al, al
  out 0xc, al		; clear DMA pointers

  mov al, dl
  out 0xb, al

  mov al, cl
  out 5, al
  mov al, ch
  out 5, al		; set legnth to cx

  mov eax, ebx
  rol eax, 16
  out 0x81, al		; set page
  rol eax, 16
  out 4, al		; send low byte of offset
  mov al, ah
  out 4, al		; high byte

  mov al, 2
  out 0xa, al		; clear mask bit, ready to rock

  retn

;                                           -----------------------------------
;                                                               _send_sector_id
;==============================================================================

_send_sector_id:
;;
;; sends the sector, cyl, head, and all that good stuff to the FDC. Call this
;; after a read/write sector/track command
;; 
;; parameters:
;; -----------
;; AH = sector
;; BL = head
;; BH = cyl
;;
;; returned values:
;; ----------------
;; all registers except AL = unchanged
;; 

%ifdef _DEBUG_
  push edx
  dbg_print "sending sector ID: sect: ",1
  movzx edx, ah
  externfunc sys_log.print_hex
  dbg_print "  cyl: ",1
  movzx edx, bh
  externfunc sys_log.print_hex
  dbg_print "  head: ",1
  movzx edx, bl
  externfunc sys_log.print_hex
  dbg_term_log
  pop edx
%endif

cmp bh, 79
jna .cyl_oki

dbg_print "cyl was over 79; luckily chromium is cool enough to catch this :P",0
jmp short $

.cyl_oki:

  push eax

  mov ah, bl
  shl ah, 2
  call _write_data

  mov ah, bh
  call _write_data

  mov ah, bl
  call _write_data

  pop eax
  call _write_data

  mov ah, 2
  call _write_data

  mov ah, 18
  call _write_data

  mov ah, 27
  call _write_data

  mov ah, -1
  call _write_data

  retn

;                                           -----------------------------------
;                                                                  _read_result
;==============================================================================

_read_result:
;;
;; reads the result from commands (read track, read sector, write sector...)
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EBP = error code; 0 for none (note CF is undeterimed)
;; BH = cyl
;; AH = sector
;; BL = head
;; 

  dbg_print "reading result",0

  xor ebp, ebp
  call _read_data	; st0
  test al, 0xC0
  jnz .analyze_error
  
  call _read_data	; st1
  call _read_data	; st2

.got_error:
  call _read_data	; cyl
  mov bh, al
  call _read_data	; head
  mov bl, al
  call _read_data	; sector
  mov ah, al
  call _read_data	; sector size

  %ifdef _DEBUG_
  push edx
  dbg_print "_read_result: next sector: ",1
  movzx edx, ah
  externfunc sys_log.print_hex
  dbg_print "  cyl: ",1
  movzx edx, bh
  externfunc sys_log.print_hex
  dbg_print "  head: ",1
  movzx edx, bl
  externfunc sys_log.print_hex
  externfunc sys_log.terminate
  pop edx
  %endif
  
  retn

.analyze_error:
  %ifdef _DEBUG_
  dbg_print "Floppy returned error; st0: ",1
  push edx
  movzx edx, al
  externfunc sys_log.print_hex
  pop edx
  %endif
  
  call _read_data	; st1
  
  %ifdef _DEBUG_
  dbg_print "  st1: ",1
  push edx
  movzx edx, al
  externfunc sys_log.print_hex
  externfunc sys_log.terminate
  pop edx
  %endif
  
  call _read_data	; st2
  
  %ifdef _DEBUG_
  dbg_print "  st2: ",1
  push edx
  movzx edx, al
  externfunc sys_log.print_hex
  externfunc sys_log.terminate
  pop edx
  %endif
  
  xor ebp, ebp
  dec ebp
  jmp .got_error

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
;; EDI = unmodified
;; errors as usual
;<

dbg_print "raw reading; LBA: ",1
dbg_print_hex eax
dbg_print "  count: ",1
dbg_print_hex ecx
dbg_term_log

  pushad

  test edx, edx
  jnz .too_big
  test eax, 0xFFFF0000
  jnz .too_big

  call _lba_to_chs
;; BH = cyl
;; AH = sector
;; BL = head

  push eax
  push ebx
  mov ah, bh
  mov bh, 0
  call _seek_heads

  mov dl, 0x46
  mov cx, 512*2-1
  mov ebx, [track_buffer]
  call _program_dma
  pop ebx

  mov ah, 0xE6
  call _write_data
  pop eax

  call _send_sector_id

  call _wait_for_int
  call _read_result

  mov esi, [track_buffer]
  mov ecx, 512*2/4
  rep movsd
  
  popad
  clc
  retn
  
.too_big:
  popad
  mov eax, __ERROR_INVALID_PARAMETERS__
  stc
  retn

;                                           -----------------------------------
;                                                                   __raw_write
;==============================================================================

__raw_write:
;>
;; parameters:
;; -----------
;; EDX:EAX = 64 bit LBA
;; ECX = number of sectors to write
;; ESI = pointer to buffer to read data from
;; EBX = file handle
;<

dbg_print "raw writing",0

.write:
  mov edi, eax
  
  call _lba_to_chs
  mov bh, al

;; BH = cyl
;; AH = sector
;; BL = head

  mov dl, 19
  sub dl, bh	; DL = number of sectors we can write
  movzx edx, dl

  cmp edx, ecx
  jng .gogogo
  
  mov edx, ecx

.gogogo:
  sub ecx, edx
  add edi, edx
  push edi

  push ecx
  mov edi, [track_buffer]
  mov ecx, edx
  shl ecx, 7
  rep movsd
  pop ecx

  push ecx
  push eax
  push ebx
  mov ecx, edx
  mov dl, 0x4A
  shl ecx, 9
  dec ecx
  mov ebx, [track_buffer]
  call _program_dma
  pop ebx
  pop eax
  pop ecx
  ; dma is ready to rock

  push eax
  mov ah, 0xE6
  call _write_data
  pop eax

  call _send_sector_id

  call _wait_for_int
  
  call _read_data
  call _read_data
  call _read_data
  call _read_data
  call _read_data
  call _read_data
  call _read_data

  call _ack_int

  pop eax
  test ecx, ecx
  jnz .write

  clc
  retn

;                                           -----------------------------------
;                                                                 _wait_for_int
;==============================================================================

_wait_for_int:
dbg_print "waiting for int...",1
.wait:
  cmp byte[fd_ready], 0
  jz .wait
  mov byte[fd_ready], 0
  retn

;                                           -----------------------------------
;                                                                      _ack_int
;==============================================================================

_ack_int:
;; this acks the int to the FDC; it should be called after a command has
;; completed it's result phase
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; AL = current cyl
;; AH = st0
;; EDX = destroyed
;; all other registers = unmodified

  mov ah, 0x08		; check int status command
  call _write_data

  call _read_data
  test al, 0x80
  jnz .fake_int
  mov ah, al
  call _read_data

  retn

.fake_int:
  lprint {"chromium fdc: got fake interupt",0xa}, WARNING
  retn

[section .data]
.fake_int_str: db "[Chromium] Acked int but there was no int to ack",0
__SECT__

;                                           -----------------------------------
;                                                                       __close
;==============================================================================

__close:
  ; for now there's really nothing to do
  clc
  retn

;                                           -----------------------------------
;                                                               __not_supported
;==============================================================================

_error:
xor eax, eax
dec eax
stc
retn

__not_supported:
mov eax, __ERROR_OPERATION_NOT_SUPPORTED__
stc
retn

;                                           -----------------------------------
;                                                                    irq_client
;==============================================================================

dd 0,0	; space for ics channel

irq_client:
pushad

dbg_print "got int",0

;.. now acked by the irq redirector [eks]
;mov al, 0x66
;out 0x20, al		; ack PIC

mov byte[fd_ready], 1	; this is polled when something needs to wait for IRQ

popad
clc
retn

;                                           -----------------------------------
;                                                                         _open
;==============================================================================

_open:
;>
;; parameters:
;; -----------
;; EBP = same value as EBP we used when we registered, but we don't use this
;; EDX = ptr to fs descriptor
;;
;; returned values:
;; ----------------
;; EBX = ptr to file handle
;; errors as usual
;<

  mov ecx, local_file_descriptor_size
  push edx
  externfunc mem.alloc

  mov ebx, edi
  mov dword[edi+file_descriptor.op_table], our_op_table
  pop dword[edi+file_descriptor.fs_descriptor]

  retn

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data
align 4, db 0

track_buffer:	dd 0	; ptr to a buffer for one full track

our_file_descriptor: istruc local_file_descriptor
  at local_file_descriptor.global
    istruc file_descriptor
      at file_descriptor.op_table,	dd our_op_table
    iend
iend

our_op_table: istruc file_op_table
  at file_op_table.close,	dd __close
  at file_op_table.read,	dd __not_supported
  at file_op_table.write,	dd __not_supported
  at file_op_table.raw_read,	dd __raw_read
  at file_op_table.raw_write,	dd __raw_write
  at file_op_table.seek_cur,	dd __not_supported
  at file_op_table.seek_start,	dd __not_supported
  at file_op_table.seek_end,	dd __not_supported
  at file_op_table.read_fork,	dd __not_supported
  at file_op_table.write_fork,	dd __not_supported
  at file_op_table.link,	dd __not_supported
  at file_op_table.unlink,	dd __not_supported
  at file_op_table.create,	dd __not_supported
  at file_op_table.rename,	dd __not_supported
  at file_op_table.copy,	dd __not_supported
  at file_op_table.truncate,	dd __not_supported
  at file_op_table.attrib,	dd __not_supported
iend

fd_ready:	db 0
sct_per_trk:	db 36
