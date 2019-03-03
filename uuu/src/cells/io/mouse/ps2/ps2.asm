;; $Header:
;;
;; PS/2 Mouse Driver cell
;; Copyright (C) 2001, Dave Poirier
;; Distributed under the BSD License
;;
;; see http://void-core.2y.net/~eks/ps2.html for details about the ps2 mouse
;; packet format.

section .text


%define PD0
;%define PD1

section .c_info

  db 0,1,1,'a'
  dd str_name
  dd str_author
  dd str_copyright

  str_name: db "PS/2 Mouse",0
  str_author: db "eks",0
  str_copyright: db "BSD Licensed",0

section .c_init
;------------------------------------------------------------------------------
  pushad				; backup all registers
					;
ps2_mouse_init:				;
					; Hook PS/2 IRQ Handler (0x0C)
					;-----------------------------
  mov esi, _ps2_handler			; our irq handler
  mov al, 12				; irq to hook
  externfunc int.hook_irq		; hook it
  jc near .failed			; check for any error
					;
					; Acquire Lock on I/O to keyboard
					;--------------------------------
  externfunc kbd.lock_io		; try to acquire a lock
  jc near .failed			; check for any error
					;
  push byte 0				; our check value for error handling
					;
					; Read Command Register Mask
					;---------------------------
  mov ah, 0x20				; command: read command register byte
  externfunc kbd.send_command		; send command
  jc short .failed_unlock_io		; check for any error
					;
  externfunc kbd.read_data		; read command byte
  jc short .failed_unlock_io		; check for any error
  					;
					; Enabling Auxiliary Clock and Ints
					;----------------------------------
					; assuming AL = command register mask
					;
  and al, 0xDF				; clear 'Disable Mouse Set' bit
  or al, 0x01				; set 'Mouse Full Interrupt' bit
  mov ah, 0x60				; command: write byte to command reg
  push eax				; back the command register mask
  externfunc kbd.send_command		; send the write command
  pop eax				; restore command register mask
  jc short .failed_unlock_io		; check if there was any error
  mov ah, al				; mask is the data to send
  externfunc kbd.send_data		; write command register mask
  jc short .failed_unlock_io		; check if there was any error
					;
					; Send Mouse Enable command to aux
					;---------------------------------
  mov ah, 0xD4				; command: write to auxiliary command
  externfunc kbd.send_command		; send the command to 8042 controller
  jc short .failed_unlock_io		; check for any error
					;
  mov ah, 0xF4				; aux command: Enable Mouse
  externfunc kbd.send_data		; send command to auxiliary device
  jc short .failed_unlock_io		; check for any error
					;
					; Wait for ACK from mouse
.waiting:				;------------------------
					; TODO: introduce some max delay here
					;------------------------------------
  mov al, [expected_data]		; load data in case it changed
  test al, al				; check if still 0
  jz short .waiting			; if so, continue to wait
					;
  pop ebx				; destroy error handling code
  push eax				; save mouse returned value
  					;
.failed_unlock_io:			; Release Lock on keyboard I/O
					;-----------------------------
  externfunc kbd.unlock_io		; release it
					;
					; Verify mouse initialization
					;----------------------------
  pop eax				; get mouse return code
  cmp al, 0xFA				; compare against ACK code
  mov esi, .success_msg			; set successful message in case
  clc					; clear any error flag in case
  jz short .exit			; if it's a match, exit
					;
					; UnHook the PS/2 handler
					;------------------------
  mov esi, _ps2_handler			; our set client
  mov al, 12				; original irq hooked
  externfunc int.unhook_irq		; unhook it
					;
  jmp short .failed			; jump to error handling
					;
					; Initialization Message section
					;-------------------------------
.failed_msg: db "[PS2] Failed Initializing Driver",0
.success_msg: db "[PS2] Mouse Driver Successfully Initialized",0
					;
.failed:				; Error occured
					;--------------
  mov esi, .failed_msg			; display failure message
  stc					; set error flag
					;
.exit:					; Common Exit Point
					;------------------
  pushfd				; keep current error flag
  externfunc sys_log.print_string	; display message
  popfd					; restore error flag
  popad					; restore all regs
;------------------------------------------------------------------------------

section .data

client: dd -1
packet: db 0,0,0
indicator: db 0
expected_data: db 0

section .text

ics_client _ps2_handler
;------------------------------------------------------------------------------
; IRQ handler, assuming potassium ack the PIC for us
;
  pushad
  cmp byte [expected_data], byte 0
  jz short .expecting_mouse_answer

  externfunc kbd.read_data
  jc short .sync_problem

  movzx ecx, byte [indicator]
  mov [ecx + packet], al
  cmp cl, 2
  jz short .analyze
  test ecx, ecx
  jz short .test_packet_sync
.packet_synced:
  inc byte [indicator]
  popad
  clc
  retn

.expecting_mouse_answer:
  externfunc kbd.read_data
  mov [expected_data], al
  popad
  clc
  retn

.test_packet_sync:
  ; make sure that the first byte of a packet got bit 3 set
  test al, byte 0x08
  jnz short .packet_synced
  clc

.sync_problem:
  popad
  retn


  .analyze:
  mov [indicator], byte 0
  mov eax, [packet]
  mov ebx, eax
  mov ecx, eax
  mov edx, 0x000000FF
  and eax, 0x07
  shr ebx, 8
  shr ecx, 16
  and ebx, edx
  and ecx, edx
  mov dl, [packet]
  .x_not_overflow:
  test dl, 0x10
  jz short .x_not_signed
  movsx ebx, bl
  .x_not_signed:
  test dl, 0x20
  jz short .y_not_signed
  movsx ecx, cl
  .y_not_signed:
  xor edx, edx
  call [client]
  clc
  popad
  retn
;------------------------------------------------------------------------------

  

%ifdef PD1
  globalfunc pd1.set_client
  ;>
  ;; see pd0.set_client
  ;;
  ;<
%elifdef PD0
  globalfunc pd1.set_client
%endif
__set_client:
;------------------------------------------------------------------------------
;>
;; hook up a mouse client
;;
;; The client called will receive the following parameters:
;;   EAX = button status (bit0 = button 0, bit1 = button 1, etc)
;;   EBX = X mouse displacement (signed)
;;   ECX = Y mouse displacement (signed)
;;   EDX = Z mouse displacement (signed)
;;
;;
;; parameters:
;;------------
;; esi = pointer to client to call
;;
;; returned values:
;;-----------------
;; eax = unmodified
;; ebx = unmodified
;; ecx = unmodified
;; edx = unmodified
;; esi = unmodified
;; edi = unmodified
;; esp = unmodified
;; ebp = unmodified
;<
  inc esi
  jnz short .set_client

  mov esi, null_client + 1

.set_client:
  dec esi
  mov [client], esi
  retn


%ifdef PD1
  globalfunc pd1.get_client
  ;>
  ;; see pd0.get_client
  ;;
  ;<
%elifdef PD0
  globalfunc pd1.get_client
%endif
__get_client:
;------------------------------------------------------------------------------
;> get the current mouse client
;;
;; parameters:
;;------------
;; none
;;
;; returned values:
;;-----------------
;; eax = unmodified
;; ebx = unmodified
;; ecx = unmodified
;; edx = unmodified
;; esi = pointer to client function
;; edi = unmodified
;; esp = unmodified
;; ebp = unmodified
;<
  mov esi, [client]
  cmp esi, null_client
  jnz short .exit
  mov esi, -1
.exit:
null_client:
  retn
