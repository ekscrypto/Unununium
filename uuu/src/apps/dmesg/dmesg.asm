%include "vid/sys_log.inc"
%include "ozone.inc"
%include "process.inc"

struc buf_file
  .fd:		resb file_descriptor_size
  .buf:		resd 1	; ptr to current buffer
  .size:	resd 1	; size of current buffer
  .cur:		resd 1	; current location within buffer
endstruc

global _start
_start:

  mov edx, [ebx+process_info.stdout]

  externfunc sys_log.get_log_pointer
  ; EBX = ptr to buffer file descriptor

  xchg edx, ebx
  mov ecx, [edx+buf_file.cur]
  test ecx, ecx
  jz .retn
  mov esi, [edx+buf_file.buf]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  jc .error
.retn:
  xor eax, eax
.error:
  retn
