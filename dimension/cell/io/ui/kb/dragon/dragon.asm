;; Dragon scancode to keycode keyboard cell
;; $Revision: 
;;
;; by EKS - Dave Poirier (instinc@cvs.uuu.sourceforge.net)
;; Distributed under the BSD License
;;
;;
;; This cell provides the ability to get keycodes from the keyboard instead of
;; scancode.  Keycodes are normalized/standardized codes generated identically
;; whatever the type of keyboard you may have.  This create an hardware
;; abstraction layer allowing simpler development of keyboard language cells.
;;
;; The keycode client is called with the following information:
;;
;;    EAX = keycode
;;
;; If the keycode received is a negative value, the key was released, otherwise
;; the key was pressed.  For example, when the Escape key is pressed, a keycode
;; of 1 (0x00000001) will be received, when this key is released, a keycode of
;; -1 (0xFFFFFFFF) will be received.


section .data

keycodes:
.standard:
  db 0x00, 0x01, 0x0F, 0x10, 0x11 ;; (00) (01) (02) (03) (04)
  db 0x12, 0x13, 0x14, 0x15, 0x16 ;; (05) (06) (07) (08) (09)
  db 0x17, 0x18, 0x19, 0x1A, 0x1B ;; (0A) (0B) (0C) (0D) (0E)
  db 0x1C, 0x1D, 0x1E, 0x1F, 0x20 ;; (0F) (10) (11) (12) (13)
  db 0x21, 0x22, 0x23, 0x24, 0x25 ;; (14) (15) (16) (17) (18)
  db 0x26, 0x27, 0x28, 0x36, 0x43 ;; (19) (1A) (1B) (1C) (1D)
  db 0x2B, 0x2C, 0x2D, 0x2E, 0x2F ;; (1E) (1F) (20) (21) (22)
  db 0x30, 0x31, 0x32, 0x33, 0x34 ;; (23) (24) (25) (26) (27)
  db 0x35, 0x0E, 0x37, 0x29, 0x38 ;; (28) (29) (2A) (2B) (2C)
  db 0x39, 0x3A, 0x3B, 0x3C, 0x3D ;; (2D) (2E) (2F) (30) (31)
  db 0x3E, 0x3F, 0x40, 0x41, 0x42 ;; (32) (33) (34) (35) (36)
  db 0x53, 0x45, 0x46, 0x2A, 0x02 ;; (37) (38) (39) (3A) (3B)
  db 0x03, 0x04, 0x05, 0x06, 0x07 ;; (3C) (3D) (3E) (3F) (40)
  db 0x08, 0x09, 0x0A, 0x0B, 0x51 ;; (41) (42) (43) (44) (45)
  db 0x6D, 0x55, 0x56, 0x57, 0x54 ;; (46) (47) (48) (49) (4A)
  db 0x58, 0x59, 0x5A, 0x5B, 0x5C ;; (4B) (4C) (4D) (4E) (4F)
  db 0x5D, 0x5E, 0x5F, 0x60, 0x6F ;; (50) (51) (52) (53) (54)
  db 0x00, 0x4B, 0x0C, 0x0D       ;; (55) (56) (57) (58)
.standard_size equ $ - .standard

.extended:
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (00) (01) (02) (03) (04)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (05) (06) (07) (08) (09)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (0A) (0B) (0C) (0D) (0E)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (0F) (10) (11) (12) (13)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (14) (15) (16) (17) (18)
  db 0x00, 0x00, 0x00, 0x61, 0x4A ;; (19) (1A) (1B) (1C) (1D)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (1E) (1F) (20) (21) (22)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (23) (24) (25) (26) (27)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (28) (29) (2A) (2B) (2C)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (2D) (2E) (2F) (30) (31)
  db 0x00, 0x00, 0x00, 0x52, 0x42 ;; (32) (33) (34) (35) (36)
  db 0x6C, 0x47, 0x00, 0x00, 0x00 ;; (37) (38) (39) (3A) (3B)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (3C) (3D) (3E) (3F) (40)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (41) (42) (43) (44) (45)
  db 0x71, 0x64, 0x68, 0x66, 0x00 ;; (46) (47) (48) (49) (4A)
  db 0x69, 0x00, 0x6B, 0x00, 0x65 ;; (4B) (4C) (4D) (4E) (4F)
  db 0x6A, 0x67, 0x62, 0x63, 0x00 ;; (50) (51) (52) (53) (54)
  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; (55) (56) (57) (58) (59)
  db 0x00, 0x44, 0x48, 0x49       ;; (5A) (5B) (5C) (5D)
.extended_size equ $ - .extended

  db 0x00, 0x00, 0x00, 0x00, 0x00 ;; () () () () ()

strings:
.unknown_scancode: 
db "An unknown scancode was encountered.  Please visit the UUU website to get the   scancode acquisition tool or report the scancode with the brand and model numberof your keyboard to the UUU development team. UNKNOWN SCANCODE: ",0

;; You should not have to edit anything below that line


section .text

%define port_kbd_control	0x64
%define port_kbd_data		0x60
%define kbd_outbuf_full		0x01
%define kbd_inbuf_full		0x02


section .c_info
	db 1,0,0,"a"
	dd str_title
	dd str_author
	dd str_copyrights

	str_title:
	db "Dragon",0

	str_author:
	db "eks",0

	str_copyrights:
	db "BSD Licensed",0


section .c_init
global _start
_start:
  pushad

  mov esi, _irq_1_handler
  mov al, 0x01
  externfunc int.hook_irq

  popad
  retn

section .text

globalfunc kbd.set_keycode_client
;------------------------------------------------------------------------------
;>
;; Set the keyboard keycode client
;;
;; parameters:
;;------------
;; esi = pointer to client (-1 to stop redirection)
;;
;; returned values:
;;-----------------
;; none, always successful
;<
;------------------------------------------------------------------------------
  inc esi				; check if client is -1
  jnz short .set_client			; if not -1, set it and leave
					;
  mov esi, null_client + 1		; our null client
					;
.set_client:				;
  dec esi				; get original client pointer
  mov [kbd.client], esi			; set it
  retn					; return to caller
;------------------------------------------------------------------------------




_analyze_sequence:
;------------------------------------------------------------------------------
  mov	byte  al, [esi]
  cmp	byte  al, 0xE0
  mov	byte  ah, [esi + 1]
  jz	short .extended_key_0
  cmp	byte  al, 0xE1
  movzx	dword esi, al
  jz	short .extended_key_1

  and	dword esi, byte 0x7F
  cmp	dword esi, byte keycodes.standard_size
  ja	short .unknown_scancode
  movzx	dword esi, byte [esi + keycodes.standard]
  test	byte  al,  al
  jns	short .standard_make
  neg	dword esi
.standard_make:
  test	dword esi, esi
  mov	byte  [kbd.buffer_count], byte 0
  mov	dword eax, esi
  retn

.extended_key_0:
  cmp	ebx, byte 2
  movzx esi, ah
  jb	short .waiting_for_extended

  and	dword esi, byte 0x7F
  cmp	dword esi, byte keycodes.extended_size
  ja	short .unknown_scancode

  movzx dword esi, byte [esi + keycodes.extended]
  test	ah, ah
  jns	short .extended_make
  neg	esi
.extended_make:
  test	dword esi, esi
  mov	byte  [kbd.buffer_count], byte 0
  mov	dword eax, esi
  retn

.waiting_for_extended:
  mov	byte [kbd.buffer_count], bl
  cmp	eax, eax
  retn

.extended_key_1:
  cmp	ebx, byte 3
  jb	short .waiting_for_extended

  cmp	ah, 0x9D
  jz	short .pause_release

  cmp	ah, 0x1D
  jnz	short .unknown_scancode

  cmp	byte [kbd.buffer + 2], byte 0x45
  mov	esi, 0x0000006E
  jz	short .extended_make
  xor	esi, esi
  jmp	short .extended_make

.unknown_scancode:
  push	eax
  mov	esi, strings.unknown_scancode
  mov	edi, 0xB8000
  mov	ah, 0x40
.displaying_error:
  lodsb
  stosw
  test	al, al
  jnz	short .displaying_error
  pop	edx
  mov	al, dl
  shr	al, 4
  and	dl, 0x0F
  cmp	al, 0x0A
  sbb	al, 0x69
  das
  stosw
  mov	al, dl
  cmp	al, 0x0A
  sbb	al, 0x69
  das
  stosw
  jmp	short $

.pause_release:
  cmp	byte [kbd.buffer + 2], byte 0xC5
  mov	dword esi, - 0x0000006E
  jz	short .extended_make
  xor	esi, esi
  jmp	short .extended_make
;------------------------------------------------------------------------------
  

ics_client _irq_1_handler
;------------------------------------------------------------------------------
  push	eax
  cmp	dword [lock_count], byte -1
  jnz	short .false_alarm

  in	byte  al, port_kbd_control
  test	byte  al, kbd_outbuf_full
  jz	short .false_alarm

  push	ebx
  in	byte  al, port_kbd_data
  cmp	byte  al, 0xFE
  jz	short .completed
  push	esi
  movzx	ebx, byte [kbd.buffer_count]
  mov	esi, kbd.buffer
  mov	byte  [ebx + esi], al
  inc	ebx
  
  call	_analyze_sequence
  jz	short .not_decoded

  push	ebx
  call	[kbd.client]
  pop	ebx

.not_decoded:
  pop	esi
  cmp	ebx, byte 8
  jb	short .completed

  mov	[kbd.buffer_count], bh

.completed:
  pop	ebx
  pop	eax
  clc
  retn

.false_alarm:
  pop	eax
  stc
null_client:
  retn
;------------------------------------------------------------------------------


globalfunc kbd.lock_io
;------------------------------------------------------------------------------
; TODO: update once the thread engine is ready
;------------------------------------------------------------------------------
;>
;; Lock the keyboard I/O so that another driver may input/output to the keyboard
;; port and establish communication
;;
;; parameters:
;;------------
;; none
;;
;; returns:
;;---------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  inc	dword [lock_count]
  jz	short .lock_acquired

  dec	dword [lock_count]
.waiting:
  cmp	dword [lock_count], byte -1
  jnz	short .waiting

.lock_acquired:
  clc
  retn
;------------------------------------------------------------------------------



globalfunc kbd.unlock_io
;------------------------------------------------------------------------------
; TODO: update once multithread is available
;------------------------------------------------------------------------------
;>
;; Release a lock on the keyboard I/O (call only if you previously acquired a
;; lock otherwise some bad stuff may happen)
;;
;; parameters:
;;------------
;; none
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  dec	dword [lock_count]
  clc
  retn
;------------------------------------------------------------------------------


globalfunc kbd.send_command
;------------------------------------------------------------------------------
;>
;; 8042 Controller access function, send data to port 0x64 (on-board controller)
;;
;; parameters:
;;------------
;;  AH = command code
;;
;; returns:
;;---------
;; AL = keyboard status
;; error and registers as usual
;<
;------------------------------------------------------------------------------
  call	_kbd_wait_inbuf_empty
  jc	short common_retn

  mov	al, ah
  out	0x64, al
  jmp	short _kbd_wait_inbuf_empty
;------------------------------------------------------------------------------


globalfunc kbd.send_data
;------------------------------------------------------------------------------
;>
;; 8042 Controller access function, send data to port 0x60 (keyb controller)
;;
;; parameters:
;;------------
;; AH = value to send
;;
;; returns:
;;---------
;; AL = keyboard status
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  call	_kbd_wait_inbuf_empty
  jc	short common_retn

  mov	al, ah
  out	0x60, al
  jmp	_kbd_wait_inbuf_empty
;------------------------------------------------------------------------------


globalfunc kbd.read_data_aux
;------------------------------------------------------------------------------
;>
;; 8042 Controller access function, get data from port 0x60 (keyb controller)
;; 
;; parameters:
;;------------
;; none
;;
;; returned values:
;;-----------------
;; AL = data read (if successful) / keyboard status (if failed)
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  call	_kbd_wait_outbuf_full_aux	;
  jmp	short kbd.read_data.common	;


globalfunc kbd.read_data
;------------------------------------------------------------------------------
;>
;; 8042 Controller access function, get data from port 0x60 (keyb controller)
;; 
;; parameters:
;;------------
;; none
;;
;; returned values:
;;-----------------
;; AL = data read (if successful) / keyboard status (if failed)
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  call	_kbd_wait_outbuf_full		;
.common:				;
  jc	short .failed			;
					;
  in	al, 0x60			;
					;
.failed:				;
common_retn:				;
  retn					;
;------------------------------------------------------------------------------



_kbd_wait_inbuf_empty:
;------------------------------------------------------------------------------
; TODO: update to use a timer when they are available!
;------------------------------------------------------------------------------
; 8042 Controller access function, waits until input buffer becomes empty or
; until maximum timeout delay
;
; parameters:
;------------
; none
;
; returned values:
;-----------------
; AL = keyboard status
; errors and registers as usual
;
;------------------------------------------------------------------------------
  push	ecx				; we do not destroy ecx
  mov	ecx, 0x0000F000			; maximum count, until we use timers!
					;
.retry:					;
  dec	ecx				; decrement delay counter
  jc	short .delay_error		; if counter is over, end it up
					;
  in	al, 0x64			; read keyboard status
  test	al, 0x02			; is there any data in input buffer?
  jnz	short .retry			; if yes, wait until there is none
					;
  clc					; clear error flag, input buffer ready
.delay_error:				;
  pop	ecx				; restore ecx
  retn					; return to caller
;------------------------------------------------------------------------------


_kbd_wait_outbuf_full:
;------------------------------------------------------------------------------
; TODO: use timer when they are available!
;------------------------------------------------------------------------------
; 8042 Controller access function, waits until data is available in the output
; buffer or until maximum timeout delay
;
; parameters:
;------------
; none
;
; returned values:
;-----------------
; AL = keyboard status
; errors and registers as usual
;
;------------------------------------------------------------------------------
  push	ecx				; we do not want to destroy this one
  mov	ecx, 0x0000F000			; maximum count to wait for
					;
.retry:					;
  dec	ecx				; decrement wait counter
  jc	short .delay_error		; if counter is over, end with error
					;
  in	al, 0x64			; read keyboard status
  test	al, 0x01			; test output buffer status
  jz	short .retry			; if no data there, continue to wait
					;
  clc					; data present, clear error flag
.delay_error:				;
  pop	ecx				; restore ecx
  retn					; return to caller
;------------------------------------------------------------------------------



_kbd_wait_outbuf_full_aux:
;------------------------------------------------------------------------------
; TODO: use timer when they are available!
;------------------------------------------------------------------------------
; 8042 Controller access function, waits until data is available in the output
; buffer of the auxiliary device or until maximum timeout delay
;
; parameters:
;------------
; none
;
; returned values:
;-----------------
; AL = keyboard status
; errors and registers as usual
;
;------------------------------------------------------------------------------
  push	ecx				; we do not want to destroy this one
  mov	ecx, 0x0000F000			; maximum count to wait for
					;
.retry:					;
  dec	ecx				; decrement wait counter
  jc	short .delay_error		; if counter is over, end with error
					;
  in	al, 0x64			; read keyboard status
  test	al, 0x20			; test output buffer status
  jz	short .retry			; if no data there, continue to wait
					;
  clc					; data present, clear error flag
.delay_error:				;
  pop	ecx				; restore ecx
  retn					; return to caller
;------------------------------------------------------------------------------
section .data

kbd.buffer: dd 0,0
kbd.buffer_count: db 0
kbd.client: dd null_client
lock_count: dd -1
