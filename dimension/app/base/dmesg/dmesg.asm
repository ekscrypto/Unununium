;; $Header: /cvsroot/uuu/dimension/app/base/dmesg/dmesg.asm,v 1.3 2002/08/11 07:42:45 lukas2000 Exp $
;; Dmesg App
;; Copyright (C) 2001 - Phil Frost (indigo)
;; Distributed under BSD License
;; 

;                                           -----------------------------------
                                                                  section .text
;==============================================================================

global _start				; app start
_start:
					; EBX = pointer to process header
  mov edx, [ebx+process_info.stdout]	; set EDX to stdout file descriptor
					;
  externfunc sys_log.get_log_pointer	; EBX = ptr to log info
					;
  xchg edx, ebx				; set EDX = log info, EBX = stdout fd
  mov ecx, [edx+buf_file.cur]		; get log length (based on current ptr)
  test ecx, ecx				; make sure we got something to print
  jz .retn				; if zero, then exit
  mov esi, [edx+buf_file.buf]		; ESI contains pointer to current buffer
  mov ebp, [ebx]			; EBX = stdout, EBP= file_op_table
  call [ebp+file_op_table.write]	; Write to stdout
  jc .error				; CF is set, when error occurs
.retn:					;
  xor eax, eax				; Clear EAX
.error:					;
  retn					; Exit

;                                           -----------------------------------
;                                                                  section .bss
;==============================================================================

struc buf_file
  .fd:		resb file_descriptor_size
  .buf:		resd 1			; ptr to current buffer
  .size:	resd 1			; size of current buffer
  .cur:		resd 1			; current location within buffer
endstruc

