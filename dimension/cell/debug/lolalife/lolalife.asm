; Lola Life Jacket - In case your ship crash while in ocean.. might be your
; only help!
;
; [Jan2302/jmony] - No comments were added since the cell is mainly
; 			made of error messages.
;


[bits 32]

section .text
;==============================================================================

;; TODO:
;;------
;; - Dump registers
;; - Add GDT + segment backup/reload
;; - Backup original stack and load internal one in case stack was the error
;; and many many many other possibilities..


%define __long_description__

%define _ERROR_NO 0x00
%define _ERROR_ZERO 0x01
%define _ERROR_YES 0x02
%define _TYPE_FAULT 0x80
%define _TYPE_ABORT 0x40
%define _TYPE_TRAP 0x20
%define _TYPE_INT 0x10


section .c_info
;==============================================================================
  db 0,0,1,'a'
  dd str_name
  dd str_author
  dd str_copyright

  str_name: db "Lola Life Jacket - Crash detection/rescue",0
  str_author: db "EKS - Dave Poirier (futur@mad.scientistk.com)",0
  str_copyright: db "Copyright (C) 2001, Dave Poirier", 0x0A
                 db "Distributed under the BSD License",0
;==============================================================================

section .c_init
;==============================================================================
						
global _start
_start:
;------------------------------------------------------------------------------
  mov ecx, int_count				;
  xor eax, eax					;
  .hooking_up:					;
   mov al, [ecx + .int_numbers]			;
   mov esi, [ecx*4 + .int_handlers]		;
   externfunc int.hook				;
  dec ecx					;
  jns short .hooking_up				;
  retn						;
                                                ;
.int_numbers:					;
db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18	;
int_count equ $-.int_numbers			;
align 4, db 0					;
.int_handlers:					;
dd handler_divide_error				;
dd handler_debug				;
dd handler_nmi					;
dd handler_breakpoint				;
dd handler_overflow				;
dd handler_bound				;
dd handler_invalid_opcode			;
dd handler_no_math_coproc			;
dd handler_double_fault				;
dd handler_coproc_seg_overrun			;
dd handler_invalid_tss				;
dd handler_seg_not_present			;
dd handler_stack_fault				;
dd handler_general_protection			;
dd handler_page_fault				;
dd handler_fpu					;
dd handler_alignment_check			;
dd handler_machine_check			;
;==============================================================================

section .text
;==============================================================================
%ifndef __long_description__
 error_packet_de: 		db "Fault:Divide Error",0
 error_packet_db: 		db "Fault/Trap:Debug",0
 error_packet_nmi: 		db "Interrupt:Non-Maskable Interrupt",0
 error_packet_bp: 		db "Trap:Breakpoint",0
 error_packet_of: 		db "Trap:Overflow",0
 error_packet_br: 		db "Fault:BOUND Range Exceeded",0
 error_packet_ud:		db "Fault:Undefined Opcode",0
 error_packet_nm: 		db "Fault:No Math Coprocessor",0
 error_packet_df: 		db "Abort:Double Fault",0
 error_packet_so: 		db "Fault:Coprocessor Segment Overrun",0
 error_packet_ts: 		db "Fault:Invalid TSS",0
 error_packet_np: 		db "Fault:Segment Not Present",0
 error_packet_ss: 		db "Fault:Stack-Segment Fault",0
 error_packet_gp: 		db "Fault:General Protection",0
 error_packet_pf: 		db "Fault:Page Fault",0
 error_packet_mf: 		db "Fault:Floating-Point Error",0
 error_packet_ac: 		db "Fault:Alignment Check",0
 error_packet_mc: 		db "Abort:Machine Check",0
		
%else

 ; NOTE: The various description for the exceptions and interrupts have been
 ;       taken out of the IA-32 Software Developer Manual volume 3, page 5-5
 ;       in table 5-1.

 error_packet_de:
 db 0, "DE"
 db "Divide Error",0
 db _TYPE_FAULT + _ERROR_NO
 db "DIV or IDIV instruction",0

 error_packet_db:
 db 1,"DB"
 db "Debug",0
 db _TYPE_FAULT + _TYPE_TRAP + _ERROR_NO
 db "Any code or data reference or INT 1 instruction",0
 
 error_packet_nmi:
 db 2, "  "
 db "NMI Interrupt",0
 db _TYPE_INT + _ERROR_NO
 db "Nonmaskable external interrupt",0

 error_packet_bp:
 db 3, "BP"
 db "Breakpoint",0
 db _TYPE_TRAP + _ERROR_NO
 db "INT 3 instruction",0

 error_packet_of:
 db 4,"OF"
 db "Overflow",0
 db _TYPE_TRAP + _ERROR_NO
 db "INTO instruction",0

 error_packet_br:
 db 5, "BR"
 db "BOUND Range Exceeded",0
 db _TYPE_FAULT + _ERROR_NO
 db "BOUND instruction",0

 error_packet_ud:
 db 6, "UD"
 db "Invalid Opcode (Undefined Opcode)",0
 db _TYPE_FAULT + _ERROR_NO
 db "UD2 instruction or reserved/invalid opcode",0

 error_packet_nm:
 db 7, "NM"
 db "Device Not Available (No Math Coprocessor)",0
 db _TYPE_FAULT + _ERROR_NO
 db "Floating-point or WAIT/FWAIT instruction",0

 error_packet_df:
 db 8, "DF"
 db "Double Fault",
 db _TYPE_ABORT + _ERROR_ZERO
 db "Any instruction that can generate an exception, an NMI, or an INTR.",0

 error_packet_so:
 db 9, "  "
 db "Coprocessor Segment Overrun",0
 db _TYPE_FAULT + _ERROR_NO
 db "Floating-Point instruction",0

 error_packet_ts:
 db 10, "TS"
 db "Invalid TSS",0
 db _TYPE_FAULT + _ERROR_YES
 db "Task switch or TSS access",0

 error_packet_np:
 db 11, "NP"
 db "Segment Not Present",0
 db _TYPE_FAULT + _ERROR_YES
 db "Loading segment registers or accessing system segments",0

 error_packet_ss:
 db 12, "SS"
 db "Stack Segment Fault",0
 db _TYPE_FAULT +  _ERROR_YES
 db "Stack operations and SS register loads",0

 error_packet_gp:
 db 13, "GP"
 db "General Protection",0
 db _TYPE_FAULT + _ERROR_YES
 db "Any memory reference and other protetion checks",0

 error_packet_pf:
 db 14, "PF"
 db "Page Fault",0
 db _TYPE_FAULT + _ERROR_YES
 db "Any memory reference",0

 error_packet_mf:
 db 16, "MF"
 db "Floating-Point Error (Math Fault)",0
 db _TYPE_FAULT + _ERROR_NO
 db "Floating-Point instruction or WAIT/FWAIT instruction",0
 
 error_packet_ac:
 db 17, "AC"
 db "Alignment Check",0
 db _TYPE_FAULT + _ERROR_ZERO
 db "Any data reference in memory",0

 error_packet_mc:
 db 18, "MC"
 db "Machine Check",0
 db _TYPE_ABORT + _ERROR_NO
 db "Error codes (if any) and source are model dependent",0
 
%endif

handler_divide_error:
  mov [error_packet], dword error_packet_de
  jmp near display_error

handler_debug:
  mov [error_packet], dword error_packet_db
  jmp near display_error

handler_nmi:
  mov [error_packet], dword error_packet_nmi
  jmp near display_error

handler_breakpoint:
  mov [error_packet], dword error_packet_bp
  jmp near display_error

handler_overflow:
  mov [error_packet], dword error_packet_of
  jmp near display_error

handler_bound:
  mov [error_packet], dword error_packet_br
  jmp near display_error

handler_invalid_opcode:
  mov [error_packet], dword error_packet_ud
  jmp near display_error

handler_no_math_coproc:
  mov [error_packet], dword error_packet_nm
  jmp near display_error

handler_double_fault:
  mov [error_packet], dword error_packet_df
  jmp short display_error

handler_coproc_seg_overrun:
  mov [error_packet], dword error_packet_so
  jmp short display_error

handler_invalid_tss:
  mov [error_packet], dword error_packet_ts
  jmp short display_error

handler_seg_not_present:
  mov [error_packet], dword error_packet_np
  jmp short display_error

handler_stack_fault:
  mov [error_packet], dword error_packet_ss
  jmp short display_error

handler_general_protection:
  mov [error_packet], dword error_packet_gp
  jmp short display_error

handler_page_fault:
  mov [error_packet], dword error_packet_pf
  jmp short display_error

handler_fpu:
  mov [error_packet], dword error_packet_mf
  jmp short display_error

handler_alignment_check:
  mov [error_packet], dword error_packet_ac
  jmp short display_error

handler_machine_check:
  mov [error_packet], dword error_packet_mc
  jmp short display_error


display_error:
;------------------------------------------------------------------------------
  mov [registers.eax], eax			;
  mov [registers.ebx], ebx			;
  mov [registers.ecx], ecx			;
  mov [registers.edx], edx			;
  mov [registers.esi], esi			;
  mov [registers.edi], edi			;
  mov [registers.esp], esp			;
  mov [registers.ebp], ebp			;
                                                ;
%ifndef __long_description__			;
						;
  mov edi, 0xb8000				;
  mov esi, [error_packet]			;
  mov ah, 0x84					;
  .displaying:					;
  lodsb						;
  stosw						;
  or al, al					;
  jnz .displaying				;
  jmp short $					;
						;
%else	; %ifndef __long_description__		;
						;
  mov ah, 0x04					;
  mov ebp, [error_packet]			;
  mov esi, str_exception			;
  mov edi, 0xB8000				;
  call func_str_out				;
  mov al, [ebp]					;
  inc ebp					;
  call func_byte_out				;
  mov edi, 0xB80A0				;
  mov esi, str_signal_name			;
  call func_str_out				;
  sub edi, 2					;
  mov al, [ebp]					;
  inc ebp					;
  stosw						;
  mov al, [ebp]					;
  inc ebp					;
  call func_sep					;
  mov esi, ebp					;
  call func_str_out				;
  mov ebp, esi					;
  mov edi, 0xB8140				;
  mov esi, str_type				;
  call func_str_out				;
  mov cl, [ebp]					;
  xor ebx, ebx					;
                                                ;
  test cl, _TYPE_FAULT				;
  mov esi, str_fault				;
  jz short .bypass_fault			;
   call func_str_out				;
   inc ebx					;
  .bypass_fault:				;
                                                ;
  test cl, _TYPE_ABORT				;
  mov esi, str_abort				;
  jz short .bypass_abort			;
   or ebx, ebx					;
   jz short .bypass_sep1			;
    call func_sep				;
   .bypass_sep1:				;
   call func_str_out				;
   inc ebx					;
  .bypass_abort:				;
						;
  test cl, _TYPE_TRAP				;
  mov esi, str_trap				;
  jz short .bypass_trap				;
   or ebx, ebx					;
   jz short .bypass_sep2			;
    call func_sep				;
   .bypass_sep2:				;
   call func_str_out				;
   inc ebx					;
  .bypass_trap:					;
						;
  test cl, _TYPE_INT				;
  mov esi, str_interrupt			;
  jz short .bypass_int				;
   or ebx, ebx					;
   jz short .bypass_sep3			;
    call func_sep				;
   .bypass_sep3:				;
   call func_str_out				;
   inc ebx					;
  .bypass_int:					;
						;
  jmp short $					;
;------------------------------------------------------------------------------

str_exception: db "exception number:",0
str_signal_name: db "signal: #",0
str_type: db "type:",0
str_source: db "source:",0
str_trap: db "TRAP",0
str_fault: db "FAULT",0
str_interrupt: db "INTERRUPT",0
str_abort: db "ABORT",0

func_str_out:
;------------------------------------------------------------------------------
; esi = pointer to string
; edi = destination
 .displaying:					;
 lodsb						;
 stosw						;
 or al, al					;
 jnz short .displaying				;
 retn						;
;------------------------------------------------------------------------------

func_byte_out:
;------------------------------------------------------------------------------
; al = byte to display
; edi = destination
  mov bl, al					;
  shr al, 4					;
  cmp al, 10					;
  sbb al, 0x69					;
  das						;
  stosw						;
  mov al, bl					;
  and al, 0x0F					;
  cmp al, 10					;
  sbb al, 0x69					;
  das						;
  stosw						;
  retn						;
;------------------------------------------------------------------------------

func_sep:
;------------------------------------------------------------------------------
  mov al, ' '					;
  stosw						;
  mov al, '-'					;
  stosw						;
  mov al, ' '					;
  stosw						;
  retn						;
;------------------------------------------------------------------------------

%endif

align 4, db 0

error_packet: dd 0

registers:
.eax: dd 0
.ebx: dd 0
.ecx: dd 0
.edx: dd 0
.esi: dd 0
.edi: dd 0
.ebp: dd 0
.esp: dd 0
