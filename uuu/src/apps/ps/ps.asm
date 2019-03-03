%include "process.inc"
%include "ozone.inc"
%include "vid/lib.string.inc"
%include "vid/process.inc"

global _start
_start:

  mov ebx, [ebx+process_info.stdout]
  mov [stdout], ebx
  mov ebp, [ebx]

  mov esi, header_str
  mov ecx, header_len
  call [ebp+file_op_table.write]

  mov eax, _callback
  externfunc process.list

  xor eax, eax
  retn

_callback:
  test edx, edx
  jz .done

  mov ebx, [stdout]
  mov ebp, [ebx]

  push esi

  mov esi, zerox_str
  mov ecx, zerox_len
  call [ebp+file_op_table.write]

  externfunc lib.string.print_hex

  mov esi, tab_str
  mov ecx, tab_len
  call [ebp+file_op_table.write]

  pop esi

  test esi, esi
  jz .next

  mov esi, [esi+process_info.argv]
  test esi, esi
  jz .next

  mov esi, [esi]
  externfunc lib.string.find_length
  call [ebp+file_op_table.write]

.next:
  mov esi, nl_str
  mov ecx, nl_len
  call [ebp+file_op_table.write]

.done:
  retn

;                                           -----------------------------------
;                                                                              
;==============================================================================

section .data
align 4, db 0

stdout:		dd 0
zerox_str:	db '0x'
zerox_len:	equ $-zerox_str
tab_str:	db "  "
tab_len:	equ $-tab_str
nl_str:		db 0x0A
nl_len:		equ $-nl_str
header_str:	db '    PID',"     ",'CMD',0xa
header_len:	equ $-header_str
