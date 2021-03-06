;; $Header: /cvsroot/uuu/uuu/src/cells/lib/string/common/common.asm,v 1.14 2001/12/10 00:00:24 instinc Exp $
;; 
;; Common string functions cell -- provides incredibly common string functions
;; Copyright (C) 2001 Phil Frost
;; Distributed under the BSD license; see file "license" for details.
;;
;; The code in this cell comes from many, many authors, I just created it :P


;                                           -----------------------------------
;                                                   lib.string.ascii_hex_to_reg
;==============================================================================

globalfunc lib.string.ascii_hex_to_reg
;>
;; converts an ascii string in hex into a number in a register. Reads until a
;; non-number char is found. This function does not take care of any leading
;; "0x" or trailing "h" or anything of that sort. Valid chars are [0-9A-Fa-f];
;; there is no overflow protection.
;;
;; parameters:
;; -----------
;; ESI = ptr to string
;;
;; returned values:
;; ----------------
;; EDX = number
;; EAX = destroyed
;; ECX = number of bytes read
;; registers as usual
;<

  xor edx, edx
  xor ecx, ecx
  
  movzx eax, byte[esi+ecx]
  
  cmp al, "0"
  jl .retn
  sub eax, byte 0x30
  cmp al, "9"-"0"
  jle .add_char
  
  cmp al, "A"-0x30
  jl .retn
  sub eax, byte 0x7
  cmp al, "F"-0x37
  jle .add_char

  cmp al, "a"-0x37
  jl .retn
  sub eax, byte 0x20
  cmp al, "f"-0x57
  jnle .retn
  
.add_char:
  shl edx, 4
  add edx, eax
  inc ecx
  movzx eax, byte[esi+ecx]

  cmp al, "0"
  jl .retn
  sub eax, byte 0x30
  cmp al, "9"-"0"
  jle .add_char
  
  cmp al, "A"-0x30
  jl .retn
  sub eax, byte 0x7
  cmp al, "F"-0x37
  jle .add_char

  cmp al, "a"-0x37
  jl .retn
  sub eax, byte 0x20
  cmp al, "f"-0x57
  jle .add_char

.retn:
  retn

;                                           -----------------------------------
;                                               lib.string.ascii_decimal_to_reg
;==============================================================================

globalfunc lib.string.ascii_decimal_to_reg
;>
;; converts a string into a number in a register. Reads until a non-number
;; char is found. There is no overflow protection.
;;
;; parameters:
;; -----------
;; ESI = ptr to string
;;
;; returned values:
;; ----------------
;; EDX = number
;; EAX = destroyed
;; ECX = number of bytes read
;; registers as usual
;<

  xor edx, edx
  xor ecx, ecx
  
  movzx eax, byte[esi+ecx]
  cmp al, "0"
  jl .retn
  cmp al, "9"
  ja .retn
.add_char:
  sub eax, byte "0"
  add edx, edx
  lea edx, [edx*5]
  add edx, eax
  inc ecx
  movzx eax, byte[esi+ecx]
  cmp al, "0"
  jl .retn
  cmp al, "9"
  jna .add_char

.retn:
  retn

;                                           -----------------------------------
;                                          lib.string.find_length_dword_aligned
;==============================================================================

globalfunc lib.string.find_length_dword_aligned
;>
;; parameters:
;; -----------
;; ESI = pointer to single null-terminated string
;;
;; returned values:
;; ----------------
;; ECX = string length
;; all other registers = unmodified
;<

  xor ecx, ecx
  push eax
  push esi
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
  pop esi
  pop eax
  retn

;                                           -----------------------------------
;                                                           find_legnth, string
;==============================================================================

globalfunc lib.string.find_length
;>
;; parameters:
;; -----------
;; ESI = pointer to single null-terminated string
;;
;; returned values:
;; ----------------
;; ECX = string length
;; all other registers = unmodified
;<

  push eax
  push ebx
  xor ecx, ecx
.processing:
  mov eax, [esi + ecx]
  mov ebx, [esi + ecx + 4]
  test al, al
  jz short .string_plus_0
  test ah, ah
  jz short .string_plus_1
  test eax, 0x00FF0000
  jz short .string_plus_2
  test eax, 0xFF000000
  jz short .string_plus_3
  test bl, bl
  jz short .string_plus_4
  test bh, bh
  jz short .string_plus_5
  test ebx, 0x00FF0000
  jz short .string_plus_6
  test ebx, 0xFF000000
  jz short .string_plus_7
  add ecx, byte 8
  jmp short .processing
.string_plus_4:
  add ecx, byte 4
  pop ebx
  pop eax
  retn
.string_plus_3:
  add ecx, byte 3
  pop ebx
  pop eax
  retn
.string_plus_2:
  inc ecx
.string_plus_1:
  inc ecx
.string_plus_0:
  pop ebx
  pop eax
  retn
.string_plus_5:
  add ecx, byte 5
  pop ebx
  pop eax
  retn
.string_plus_6:
  add ecx, byte 6
  pop ebx
  pop eax
  retn
.string_plus_7:
  add ecx, byte 7
  pop ebx
  pop eax
  retn

;                                           -----------------------------------
;                                                          lib.string.read_line
;==============================================================================

globalfunc lib.string.read_line
;>
;; Reads a line (terminated with 0xa) from a file into an already allocated
;; buffer. No null is put on the end of the string; the 0xa is also put into
;; the buffer.
;;
;; This particular read_line flavor checks for backspaces and backs up in the
;; buffer if it finds one.
;;
;; parameters:
;; -----------
;; EBX = file to read from
;; ECX = max buffer size; if this many bytes are read with no 0xa found, the
;;         call returns.
;; EDI = ptr to buffer to read to
;;
;; returned values:
;; ----------------
;; ECX = number of bytes read
;; registers and errors as usual
;<

  push ebp
  push edx
  push esi
  push edi
  
  mov ebp, [ebx+file_descriptor.op_table]
  mov edx, ecx
  xor ecx, ecx
  xor esi, esi	; esi will track how many bytes we have read
  inc ecx

  ;; EDX = ECX from call
  ;; ESI = 0
  ;; ECX = 1
  ;; EBX = file pointer
  ;; EBP = op table

.get_char:
  
  call [ebp+file_op_table.read]
  jc .retn
  mov al, [edi]

  cmp al, 0x8
  je .bs

  call lib.string.print_char	; echo to display

  inc edi
  inc esi
 
  cmp esi, edx
  je .retn

  cmp al, 0xa
  jne .get_char

.retn:
  mov ecx, esi

  pop edi
  pop esi
  pop edx
  pop ebp
  retn

.bs:
  test esi, esi
  jz .get_char		; don't backspace further than the beginning of the buf
  dec esi
  dec edi
  call lib.string.print_char
  jmp short .get_char

;                                           -----------------------------------
;                                                           lib.string.get_char
;==============================================================================

globalfunc lib.string.get_char
;>
;; reads a single byte from a file. Note that it's much more efficient to read
;; multiple bytes at a time, if possible.
;;
;; parameters:
;; -----------
;; EBX = ptr to file descriptor of file to print to
;; EBP = ptr to op table of that file
;;
;; returned values:
;; ----------------
;; AL = byte read
;; errors and registers as usual
;<

  push edi
  push ecx
  push byte 0
  xor ecx, ecx
  mov edi, esp
  inc ecx
  call [ebp+file_op_table.read]
  pop eax
  pop ecx
  pop edi
  retn

;                                           -----------------------------------
;                                                         lib.string.print_char
;==============================================================================

globalfunc lib.string.print_char
;>
;; prints a single byte to a file. Note that if you have many bytes to print
;; it's much more efficient to print them at once.
;; 
;; parameters:
;; -----------
;; AL = byte to print
;; EBX = ptr to file descriptor of file to print to
;; EBP = ptr to op table of that file
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;<

  push esi
  push ecx
  push eax
  xor ecx, ecx
  mov esi, esp
  inc ecx
  call [ebp+file_op_table.write]
  pop eax
  pop ecx
  pop esi
  retn

;                                           -----------------------------------
;                                                          lib.string.print_dec
;==============================================================================

globalfunc lib.string.print_dec_no_pad
;>
;; Prints EDX to a file as a decimal number with no leading zeros.
;;
;; parameters:
;; -----------
;; EDX = number to print
;; EBX = file to print to
;; EBP = op table of that file
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;<

  push edi
  push esi
  push ecx
  
  sub esp, byte 10
  mov edi, esp
  call lib.string.dword_to_decimal_no_pad
  mov esi, edi
  call [ebp+file_op_table.write]
  jc .error
  add esp, byte 10

  pop ecx
  pop esi
  pop edi
  retn

.error:
  add esp, byte 10
  pop ecx
  pop esi
  pop edi
  stc
  retn

;                                           -----------------------------------
;                                                          lib.string.print_hex
;==============================================================================

globalfunc lib.string.print_hex
;>
;; prints EDX as an 8 digit number in hex to a file
;;
;; parameters:
;; -----------
;; EDX = number to print
;; EBX = file to print to
;; EBP = op table of that file
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;<

  push edi
  push esi
  push ecx
  
  mov ecx, 8
  sub esp, ecx
  mov edi, esp
  call lib.string.dword_to_hex
  jc .error
  mov esi, edi
  call [ebp+file_op_table.write]
  add esp, ecx

  pop ecx
  pop esi
  pop edi
  retn

.error:
  add esp, ecx
  pop ecx
  pop esi
  pop edi
  stc
  retn

;                                           -----------------------------------
;                                                       lib.string.dword_to_hex
;==============================================================================

globalfunc lib.string.dword_to_hex
;>
;; converts EDX to an ascii string in hex, using uppercase letters, padded to
;; a specified number of digits with zeros. No null is put in the string, just
;; the ascii chars.
;;
;; parameters:
;; -----------
;; EDX = number to convert
;; EDI = ptr to buffer to put string in (ECX bytes needed)
;; ECX = number of chars to convert (2 converts DL, 4 DX, 8 EDX, etc.)
;;
;; returned values:
;; ----------------
;; AL = last digit converted, in ascii
;; registers as usual
;<

  push ecx
  shl ecx, 2
  ror edx, cl
  shr ecx, 2
  add edi, ecx
  neg ecx
.loop:
  rol edx, 4
  mov al, dl
  and al, 0x0f
  cmp al, 0x0a
  sbb al, 0x69
  das
  mov [edi+ecx], al
  inc ecx
  jnz .loop

  pop ecx
  sub edi, ecx
  retn

;                                           -----------------------------------
;                                            lib.string.dword_to_decimal_no_pad
;==============================================================================

globalfunc lib.string.dword_to_decimal_no_pad
;>
;; converts EDX to an ascii string supressing leading zeros.
;;
;; based on example code in the AMD Athlon optimization manual
;;
;; parameters:
;; -----------
;; EDX = number to convert
;; EDI = ptr to buffer (max of 10 bytes needed)
;;
;; returned values:
;; ----------------
;; ECX = number of bytes used
;; registers as usual
;<

  pushad
  
  mov eax, edx
  mov ecx, edx
  mov edx, 0x89705f41
  mul edx
  add eax, eax
  adc edx, byte 0
  shr edx, 29
  mov eax, edx
  mov ebx, edx
  imul eax, 1000000000
  sub ecx, eax
  or dl, '0'
  mov [edi], dl
  cmp ebx, byte 1
  sbb edi, byte -1
  mov eax, ecx
  mov edx, 0xabcc7712
  mul edx
  shr eax, 30
  lea edx, [eax+4*edx+1]
  mov eax, edx
  shr eax, 28
  and edx, 0xfffffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  lea edx, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 27
  and edx, 0x7ffffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  lea edx, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 26
  and edx, 0x3ffffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  lea edx, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 25
  and edx, 0x1ffffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  lea edx, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 24
  and edx, 0xffffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  lea edx, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 23
  and edx, 0x7fffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  lea edx, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 22
  and edx, 0x3fffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  lea edx, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 21
  and edx, 0x1fffff
  or ebx, eax
  or eax, '0'
  mov [edi], al
  lea eax, [edx*5]
  cmp ebx, byte 1
  sbb edi, byte -1
  shr eax, 20
  or eax, '0'
  mov [edi], al

  sub edi, [esp]
  inc edi
  mov [esp+24], edi
  popad
  mov esi, edi
  retn

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================

section .c_info
db 0, 0, 1, 'a'
dd str_cellname
dd str_author
dd str_copyrights
str_cellname:	dd "common string functions"
str_author:	dd 'various authors'
str_copyrights:	dd 'Copyright 2001 by Phil Frost; distributed under the BSD license'
