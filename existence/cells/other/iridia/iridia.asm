; Iridia IRQ channels
; Copyright(C) 2002, Dave Poirier
; Distributed under the BSD License
;
;
; IRQ channels allow multiple clients to receive IRQ notification without
; requiring those clients to keep track of the previous handler.  They simply
; care to connect and disconnect themselves from the channels.
;
;
; IRQ related functions:
;-----------------------
; irq.connect
; irq.disconnect
; irq.relocate_table
;--
;
; GDT related functions:
;-----------------------
; gdt.add_descriptor
; gdt.remove_descriptor
; gdt.relocate_table
;--
;
; CPU Exception/Fault related functions:
;---------------------------------------
; int.set_handler
; int.unset_handler
;--
;
; Note: Some parts of the code use Self-Modifying Code, the instructions being
; modified are identified with a [SMC] at the start of the comments.

; When defined, the original realmode BIOS Interrupt 10h vector will be saved.
%define _BACKUP_RMINT10H_

; Perform additional verifications, slower but safer
%define _EXTRA_CHECKS_

section .c_info
;-------------------------------------------------------[ Cell Information ]--
  db 1,0,0,'a'				; Version
  dd str_cellname			; pointer to cell name
  dd str_author				; pointer to author name
  dd str_copyright			; pointer to copyright info
					;--
  str_cellname:				; cell name
    db 'Iridia IRQ Channels',0		;
  str_author:				; author
    db 'eks',0				;
  str_copyright:			; copyright information
    db 'BSD Licensed.',0		;
;-----------------------------------------------------------------------------


section .c_init
global _start


_start:
;----------------------------------------------------------------[ _start ]--
%ifdef _BACKUP_RMINT10H_		;--
  push dword [0x10 * 4]			; backup pointer to BIOS int 10h
  pop dword [original_int10h]		;
%endif					;--
  mov eax, 0x20	-1			; 32 reserved interrupts by Intel
  mov ebx, _unhandled_interrupt		; get pointer to unhandled handler
.set_unhandled:				;--
  call int.set_handler			; set interrupt handler address
  dec eax				; select previous interrupt number
  jnl .set_unhandled			; loop for all reserved interrupts
					;--
  mov ecx, 0x00000010			; number of IRQ supported by chipset
  mov ebx, _irq_F			; get last IRQ handler's address
.set_irq_handlers:			;--
  lea eax, [ecx + 0x20 - 1]		; get int number associated to IRQ
  call int.set_handler			; set the interrupt handler
  sub ebx, byte 4			; compute address of previous handler
  loop .set_irq_handlers		; process next handler if any left
					;--
  lidt [idtr]				; load IDTR with size/address of IDT
					;--
  lea edx, [ecx + 0x20]			; load edx with 0x00000020
  mov esi, pic.sequence.master		; set initialization sequence
  call send_pic_sequence		; initialize Master PIC
  					; esi now points to pic.sequence.slave
  add edx, byte 0xA0-0x21		; set edx to 0x000000A0
  call send_pic_sequence		; initialize Slave PIC
					;
  SPIN_INIT(spin_irq)			;
  sti					; enable IRQ
  clc					; indicate no error occured
  retn					; end of initialization
;-----------------------------------------------------------------------------
idtr: dw 0x30 * 8 - 1			; 0x30 entries, IDTR.size is 0x17F
      dd 0				; physical address 0
					;
					; PIC 82C59A Initialization Sequence
pic.sequence.master:			;-----------------------------------
db 0x11, 0x20, 0x04, 0x1D, 0xFB		; Master PIC
pic.sequence.slave:			;
db 0x11, 0x28, 0x02, 0x19, 0xFF		; Slave PIC
					;
send_pic_sequence:			;
  lodsb					; load icw0
  out dx, al				; send icw0 to pic address+0
  inc edx				; select pic address+1
  lodsb					; load icw1
  out dx, al				; send icw1 to pic address+1
  lodsb					; load icw2
  out dx, al				; send icw2 to pic address+1
  lodsb					; load icw3
  out dx, al				; send icw3 to pic address+1
  lodsb					; load irq mask
  out dx, al				; send irq mask to pic address+1
  retn					;
;-----------------------------------------------------------------------------


section .text



globalfunc int.set_handler
;-------------------------------------------------[ Interrupt: Set Handler ]--
;>
;; Set the pointer to an interrupt handler routine
;; (note: overwrites whatever handler is currently set)
;;
;; parameters:
;;------------
;; eax = interrupt number
;; ebx = pointer to interrupt handler
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;-----------------------------------------------------------------------------
  cmp eax, byte 0x30			; check for IDT limit
  jb short .set_handler			; if below limit, set the handler
					;--
  set_err eax, INVALID_PARAMETERS	; set error code
  stc					; raise error flag indicator
  retn					; return to caller with error
					;--
.set_handler:				;--
  pushad				; backup all registers
  mov edi, 0				; [SMC] load IDT offset
idt_offset EQU $-4			; set in-SMC variable
  lea edi, [eax*8 + edi]		; compute offset to IDT entry
  					;--
  mov eax, ebx				; copy pointer to interrupt handler
  mov ecx, cs				; get code segment value
  and ebx, 0x0000FFFF			; keep bits 15-0 of handler address
  shl ecx, 16				; shift code selector to bits 23-16
  and eax, 0xFFFF0000			; keep bits 31-16 of handler address
  or  ebx, ecx				; merge in shifted code selector
  or  eax, 0x00008E00			; select present 32bit GATE, DPL=0
  mov [edi], ebx			; write bits 31-0 of descriptor
  mov [edi + 4], eax			; write bits 63-32 of descriptor
  popad					; restore all registers
  					; error flag is low due to 'or' above
  retn					; return to caller without error
;-----------------------------------------------------------------------------



globalfunc int.unset_handler
;----------------------------------------------[ Interrupts: Unset Handler ]--
;>
;; Unset the handler of a specified interrupts.  Next interruptions will
;; trigger an unhandled interrupt panic.
;;
;; parameters:
;;------------
;; eax = interrupt number
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;-----------------------------------------------------------------------------
  push ebx				; backup ebx
  mov ebx, _unhandled_interrupt		; get pointer to unhandled int handler
  call int.set_handler			; set it for selected interrupt
  pop ebx				; restore ebx
  retn					; return to caller
;-----------------------------------------------------------------------------




globalfunc irq.connect
;-----------------------------------------------------------[ IRQ: connect ]--
;>
;; Connects an IRQ client to an IRQ channel.  The client will be called for
;; every IRQ received.
;;
;; parameters:
;;------------
;; eax = irq number
;; ebx = pointer to irq client
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;-----------------------------------------------------------------------------
  cmp eax, byte 0x10			; make sure requested IRQ is valid
  jb short .connect			; if below chipset limit, proceed
					;--
  set_err eax, INVALID_PARAMETERS	; set error code
  stc					; raise error flag
  retn					; return with error
					;--
.connect:				;--
  pushad				; backup all registers
  SPIN_ACQUIRE_LOCK(spin_irq)		; thread-safe operation LOCKED
  lea edi, [eax*4 + _irq_clients]	; compute pointer to IRQ channel header
  push eax				;
  mov eax, [edi]			; load currently set first client
  mov [edi], ebx			; set new client as first to be called
  mov [ebx - 8], dword 0		; set 'previous' ptr of new client
  mov [ebx - 4], eax			; set 'next' ptr of new client
  test eax, eax				; was there already a client?
  jz short .first_client		; if not, no 'next' client to update
					;--
  mov [eax - 8], ebx			; set 'previous' ptr of next client
  pop eax				; clear irq number from stack
  jmp short .irq_enabled		; irq already enabled, skip
					;--
.first_client:				;--
  pop eax				; retrieve irq number from stack
  call _unmask_irq			; unmask the irq
.irq_enabled:				;--
  SPIN_RELEASE_LOCK(spin_irq)		; allowing other threads to go on
  popad					; restore all registers
  					; error flag is low after 'test'
  retn					; return without error
;-----------------------------------------------------------------------------




globalfunc irq.disconnect
;--------------------------------------------------------[ IRQ: disconnect ]--
;>
;; Disconnects a client from an IRQ channel.
;;
;; ** DO NOT CALL FROM THE IRQ HANDLER **
;;
;; parameters:
;;------------
;; eax = irq number
;; ebx = pointer to irq client to disconnect
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;-----------------------------------------------------------------------------
  cmp eax, byte 0x10			; make sure IRQ is within range
  jb short .valid_irq			; if so, proceed
					;--
  set_err eax, INVALID_PARAMETERS	; set error code
  stc					; raise error flag
  retn					; return with error
					;--
.valid_irq:				;--
  pushad				; backup all registers
  SPIN_ACQUIRE_LOCK(spin_irq)		; thread-safe operation LOCKED
  xor esi, esi				; make a NULL pointer
  mov edx, [ebx - 8]			; read 'previous' client
  mov ecx, [ebx - 4]			; read 'next' client
  mov [ebx - 8], esi			; set to NULL 'previous'
  mov [ebx - 4], esi			; set to NULL 'next'
					;--
  test ecx, ecx				; check if there is a 'next' client
  jz short .no_next_client		; if not, skip update
  mov [ecx - 8], edx			; link 'next' to 'previous'
.no_next_client:			;--
  test edx, edx				; check if there is a 'previous' client
  jz short .no_previous_client		; if not, update irq channel head
  mov [edx - 4], ecx			; link 'previous' to 'next'
.exit:					;--
  SPIN_RELEASE_LOCK(spin_irq)		; allow other threads to go on
  popad					; restore all registers
  clc					; clear error flag
  retn					; return without error
					;--
.no_previous_client:			;--
  mov [eax*4 + _irq_clients], ecx	; update client head pointer
  test ecx, ecx				; was last client?
  jnz short .exit			; if not, leave irq unmask
					;--
  call _mask_irq			; mask irq
  jmp short .exit			; exit
;-----------------------------------------------------------------------------


_mask_irq:
;--------------------------------------------------------------[ IRQ: mask ]--
;>
;; Mask an irq, in either the slave or master pic
;;
;; parameters:
;;------------
;; al = irq number (only the lowest 4 bits are used)
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  push ecx				; backup ecx
  test al, 0xF0				; test irq number validity
  mov cl, al				; prepare rotating mask count
  stc					; set error flag in case
  mov ah, 0x01				; mask to 'or' with, only 1 bit cleared
  jnz short _unmask_irq.exit		; if irq number is above range, exit
  rol ah, cl				; rotate mask to fit selected irq
  test al, 0x08         		; determine slave/master based on bit 3
  jnz .slave_pic			; seems it slave, go do it
					;
					; Master PIC irq mask
					;--------------------
  in al, 0x21				; get current master pic irq mask
  or al, ah				; set the irq mask for selected irq
  out 0x21, al				; send new irq mask to master pic
  pop ecx				;
  retn					; return to caller
					;
					; Slave PIC irq mask
.slave_pic:				;-------------------
  in al, 0xA1				; get current slave pic irq mask
  or al, ah				; set the irq mask for selected irq
  out 0xA1, al				; send new irq mask to slave pic
  pop ecx				;
  retn					; get back to caller
;------------------------------------------------------------------------------



_unmask_irq:
;-------------------------------------------------------------[ IRQ: unmask ]--
;>
;; Unmask an irq, in either the slave or master pic
;;
;; parameters:
;;------------
;; al = irq number
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  test al, 0xF0				; test irq number validity
  push ecx				;
  mov cl, al				; prepare rotating mask count
  stc					; set error flag in case
  mov ah, 0xFE				; mask to 'and' with, only 1 bit cleared
  jnz short .exit			; if irq number is above range, exit
  rol ah, cl				; rotate mask to fit selected irq
  test al, 0x08				; was it a slave or master pic's irq?
  jnz .slave_pic			; seems it slave, go do it
					;
					; Master PIC irq unmask
					;----------------------
  in al, 0x21				; get current master pic irq mask
  and al, ah				; clear the irq mask for selected irq
  out 0x21, al				; send new irq mask to master pic
  pop ecx				;
  retn					;
					;
					; Exit point, invalid param
.exit:					;--------------------------
  set_err eax, INVALID_PARAMETERS	;
  pop ecx				;
  retn					; get back to caller
					;
					; Slave PIC irq unmask
.slave_pic:				;---------------------
  in al, 0xA1				; get current slave pic irq mask
  and al, ah				; clear the irq mask for selected irq
  out 0xA1, al				; send new irq mask to slave pic
  pop ecx				;
  retn					; get back to caller
;------------------------------------------------------------------------------






;-----------------------------------------------------------[ IRQ CHANNELS ]--
  align 8, db 0				; align interruption handlers
					;
_irq_0:					;--------: IRQ 0 Handler
 push byte 0x00				;
 jmp short _irq_common			;
_irq_1:					;--------: IRQ 1 Handler
 push byte 0x01				;
 jmp short _irq_common			;
_irq_2:					;--------: IRQ 2 Handler
 push byte 0x02				;
 jmp short _irq_common			;
_irq_3:					;--------: IRQ 3 Handler
 push byte 0x03				;
 jmp short _irq_common			;
_irq_4:					;--------: IRQ 4 Handler
 push byte 0x04				;
 jmp short _irq_common			;
_irq_5:					;--------: IRQ 5 Handler
 push byte 0x05				;
 jmp short _irq_common			;
_irq_6:					;--------: IRQ 6 Handler
 push byte 0x06				;
 jmp short _irq_common			;
_irq_7:					;--------: IRQ 7 Handler
 push byte 0x07				;
 jmp short _irq_common			;
_irq_8:					;--------: IRQ 8 Handler
 push byte 0x08				;
 jmp short _irq_common			;
_irq_9:					;--------: IRQ 9 Handler
 push byte 0x09				;
 jmp short _irq_common			;
_irq_A:					;--------: IRQ A Handler
 push byte 0x0A				;
 jmp short _irq_common			;
_irq_B:					;--------: IRQ B Handler
 push byte 0x0B				;
 jmp short _irq_common			;
_irq_C:					;--------: IRQ C Handler
 push byte 0x0C				;
 jmp short _irq_common			;
_irq_D:					;--------: IRQ D Handler
 push byte 0x0D				;
 jmp short _irq_common			;
_irq_E:					;--------: IRQ E Handler
 push byte 0x0E				;
 jmp short _irq_common			;
_irq_F:					;--------: IRQ F Handler
 push byte 0x0F				;
;------------------------------------------------------[ IRQ Client Router ]--
_irq_common:				;
  SPIN_ACQUIRE_IRQSAFE_LOCK(spin_irq)	; IRQ-Safe SPINLOCK Acquire
  push eax				; backup eax
  mov al, 0x20				; Non-Specific EOI command
  out 0x20, al				; send command to master PIC
  cmp byte [esp + 4], 0x08		; check for slave PIC IRQ
  jb short .master_only			; if not, do not acknowledge slave
  out 0xA0, al				; acknowledge slave PIC
.master_only:				;--
  mov eax, [esp + 4]			; retrieve IRQ number
  mov eax, [eax*4 + _irq_clients]	; retrieve first client's address
  mov [esp + 4], eax			; replace IRQ number with address
  pop eax				; restore eax
.next_client:				;--
  cmp dword [esp], byte 0		; client present? (0 = none)
  jz short .done			; in case none, we are done
  pushad				; backup all registers
  call [esp + 32]			; call the client
  mov eax, [esp + 32]			; load client address
  mov ebx, [eax - 4]			; read "next" pointer at -4 of client
  mov [esp + 32], ebx			; set it as next
  popad					; restore all registers
  jmp short .next_client		; proceed to next client
.done:					;--
  SPIN_RELEASE_IRQSAFE_LOCK(spin_irq)	; IRQ-Safe SPINLOCK Release
  add esp, byte 4			; clear IRQ number
  iretd					; return from interruption
;-----------------------------------------------------------------------------



_unhandled_interrupt:
;-------------------------------------------[ Unhandled Interrupt Handlers ]--
  mov eax, 0xEEEE0006			; set error code, YAY Bochs!
  mov [0xB809C], dword 0x04210421	; display some indication on screen
  jmp short $				; for now just lock
;-----------------------------------------------------------------------------






section .bss
;----------------------------------------------------[ Unitialized Section ]--
%ifdef _BACKUP_RMINT10H_		;
original_int10h: resd 1			; Realmode Interrupt 10h Vector
%endif					;
					;--
_irq_clients: resd 0x10			; 16 IRQ clients head pointer
					;--
rSPIN(spin_irq)				;
;-----------------------------------------------------------------------------
