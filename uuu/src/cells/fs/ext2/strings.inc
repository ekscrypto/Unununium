__strlen:
.c_dword_aligned_null_terminated:
; parameter:
;-----------
;   ESI = pointer to string
;
; returned values:
;-----------------
;   ECX = string length
;
; destroyed:
;-----------
;   EAX, AF, CF, OF, PF, SF, ZF
;
  xor ecx, ecx
.searching_null_terminator:
  mov eax, [esi]
  add eax, dword 0xFEFEFEFF
  jnc short .zero_detected
  mov eax, [byte esi + 4]
  add ecx, byte 4
  add eax, dword 0xFEFEFEFF
  jnc short .zero_detected
  mov eax, [byte esi + 8]
  add ecx, byte 4
  add eax, dword 0xFEFEFEFF
  jnc short .zero_detected
  mov eax, [byte esi + 12]
  add ecx, byte 4
  add eax, dword 0xFEFEFEFF
  jnc short .zero_detected
  add ecx, byte 4
  add esi, byte 16
  jmp short .searching_null_terminator
.zero_detected:
  sub eax, 0xFEFEFEFF
  jz short .length_found
  inc ecx
  or ah, ah
  jz short .length_found
  shr eax, 16
  inc ecx
  or al, al
  jz short .length_found
  inc ecx
.length_found:
  retn
