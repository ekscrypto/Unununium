;; $Header: /cvsroot/uuu/uuu/src/cells/debug/lanthane/lanthane.asm,v 1.8 2002/01/06 17:17:18 daboy Exp $
;; lanthane system log cell
;; Copyright 2001 Phil Frost

;                                           -----------------------------------
;                                                                      includes
;==============================================================================

%include "vid/lib.string.inc"
%include "vid/sys_log.inc"
%include "ozone.inc"

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================
section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Lanthane - Debuging help",0
str_author: db "Phil Frost",0
str_copyright: db "Distributed under BSD License",0

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                 sys_log.print
;==============================================================================

globalfunc sys_log.print
;>
;; This makes an entry in the system log. A lprint macro is defined in
;; macros.inc that makes calling this fun and so easy the whole family can do
;; it!
;;
;; This takes a printf()-like string to print:
;;
;; %x	dword in hex (uppercase letters)
;; %u	unsigned dword in decimal
;; %s	ptr to a string, single null-terminated
;; %d	signed dword in decimal
;; %%	literal %
;; %#x	# digits of a hex number; must be in the range 1 to 8
;;
;; note that with the exception of %x, none of the printf() style padding
;; stuffs are valid. The reasoning was that there's not much of a reason to
;; have them and the simplicity makes things a lot faster.
;;
;; parameters:
;; -----------
;; TOS = ptr to string to print, single null-terminated
;;  +4 = type, see sys_log.inc
;;  +8 = arg 1
;; +12 = arg 2
;;       ...
;;
;; returned values:
;; ----------------
;; All registers unmodified (even eax on non-error)
;; errors as usual
;<

  pushad
  mov esi, [esp+0x24]		; ESI = ptr to string to print
  mov ebx, [esp+0x28]		; EBX = type
  lea ebp, [esp+0x2c]		; EBP = ptr to 1st arg, if any

; here we scan for the next % or 0 so we can print all those chars at once

.do_span:
  xor ecx, ecx			; ECX = length of span

.find_length:
  mov al, [esi+ecx]
  test al, al
  jz .done
  cmp al, '%'
  jz .escaped
  inc ecx
  jmp short .find_length

.escaped:			; found a %
  call _print
  lea esi, [esi+ecx+2]		; ESI = ptr to char after the %?
  pushad
  mov al, [esi-1]		; ESI = the char after the %
  mov [esp+4], esi		; return our modified ESI
  cmp al, 'x'
  jz .hex
  cmp al, 'u'
  jz .unsigned_dword
  cmp al, 's'
  jz .string
  cmp al, 'd'
  jz .signed_dword
  cmp al, '%'
  jz near .percent

  ; humm...wasn't any of those, maybe it was a %#x
  
  dec esi			; ESI = ptr to char after %
  externfunc lib.string.ascii_decimal_to_reg	; get the number
  cmp byte [esi+ecx], 'x'	; now, was it a %#x?
  jz .hex_with_number
  ; if not, spill over into .esc_done

.esc_done:
  mov [esp+8], ebp		; return our modified EBP
  popad
  jmp .do_span			; and do the next span

.done:
  test ecx, ecx			; if there's a span left to print
  jz .zero
  call _print			; print it
.zero:
  popad
  retn 8

.hex:
  mov ecx, 8
  ; spill over into .hex_doit

.hex_doit:
  mov edx, [ebp]
  sub esp, byte 8
  mov edi, esp
  externfunc lib.string.dword_to_hex
  mov esi, edi
  call _print
  add esp, byte 8
  add ebp, byte 4
  jmp short .esc_done

.signed_dword:
  cmp dword[ebp], byte 0
  jns .unsigned_dword
  xor ecx, ecx
  mov esi, neg_str
  inc ecx
  call _print
  neg dword[ebp]
  ; spill into .unsigned_dword

.unsigned_dword:
  mov edx, [ebp]
  sub esp, byte 12
  mov edi, esp
  externfunc lib.string.dword_to_decimal_no_pad
  mov esi, edi
  call _print
  add esp, byte 12
  add ebp, byte 4
  jmp short .esc_done

.string:
  mov esi, [ebp]
  externfunc lib.string.find_length
  call _print
  add ebp, byte 4
  jmp short .esc_done

.hex_with_number:
  add [esp+4], ecx
  mov ecx, edx
  jmp short .hex_doit

.percent:
  xor ecx, ecx
  mov esi, percent_str
  inc ecx
  call _print
  jmp .esc_done

;                                           -----------------------------------
;                                                            sys_log.set_*_file
;==============================================================================

globalfunc sys_log.set_echo_file
;>
;; sets the echo file for a log type
;;
;; parameters:
;; -----------
;; EAX = type
;; EBX = ptr to file descriptor, 0 to disable
;;
;; returned values:
;; ----------------
;; all registers unmodified
;<

  mov [types+eax*8], ebx
  retn


globalfunc sys_log.set_print_file
;>
;; sets the echo file for a log type
;;
;; parameters:
;; -----------
;; EAX = type
;; EBX = ptr to file descriptor, 0 to disable
;;
;; returned values:
;; ----------------
;; all registers unmodified
;<

  mov [types+eax*8+4], ebx
  retn

;                                           -----------------------------------
;                                                                        _print
;==============================================================================

_print:
;; parameters:
;; -----------
;; EBX = type
;; ESI = ptr to string
;; ECX = length of that string
;; 
;; returns:
;; --------
;; EBP = unmodified
;; EBX = unmodified

  push ebp
  push ebx
  mov ebx, [types+ebx*8]
  test ebx, ebx
  jz .no_echo
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
.no_echo:
  mov ebx, [esp]
  mov ebx, [types+ebx*8+4]
  test ebx, ebx
  jz .done
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
.done:
  pop ebx
  pop ebp
  retn

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data
align 4, db 0

types:
.debug:		dd 0
		dd 0
.info:		dd 0
		dd 0
.loadinfo:	dd 0
		dd 0
.warning:	dd 0
		dd 0
.fatalerr:	dd 0
		dd 0

percent_str:	db '%'
neg_str:	db '-'
