;; $Header: /cvsroot/uuu/uuu/src/cells/lib/string/md5/md5.asm,v 1.4 2001/12/10 15:55:30 instinc Exp $
;;
;; md5 - A cell implementing the MD5 secure message-digest algorithm
;; Written by Phil Frost
;; The code in this file and the MD5 algorithm are public domain.
;;
;; todo:
;; -----
;; * globalfuncise _transform so things too big to put in memory can be md5ed
;; * clean hash,md5; i wrote it at 2am and it's really big...i think it sucks

;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc stack	; structure for the stuff on the stack most of the time
  .size:	resd 1	; total size in bytes, ECX from call
  .remaining:	resd 1	; bytes left counter, ECX from call
  .X:		resd 16	; working buffer
  .a:		resd 1	;]
  .b:		resd 1	;]\__ to save the state in _transform
  .c:		resd 1	;]/
  .d:		resd 1	;]
endstruc

;                                           -----------------------------------
;                                                                        macros
;==============================================================================

; ---===--- fundamental MD5 functions ---===---
%macro F 3	; F(X,Y,Z) = XY v not(X) Z
  mov edi, %1
  mov ebp, %1
  and edi, %2
  not ebp
  and ebp, %3
  or edi, ebp
%endmacro

%macro G 3	; G(X,Y,Z) = XZ v Y not(Z)
  mov edi, %3
  mov ebp, %3
  and edi, %1
  not ebp
  and ebp, %2
  or edi, ebp
%endmacro

%macro H 3	; H(X,Y,Z) = X xor Y xor Z
  mov edi, %1
  xor edi, %2
  xor edi, %3
%endmacro

%macro I 3	; I(X,Y,Z) = Y xor (X v not(Z))
  mov edi, %3
  not edi
  or edi, %1
  xor edi, %2
%endmacro

; ---===--- functions for the 4 rounds of transformations ---===---
%macro FF 7	; a = b + ((a + F(b,c,d) + X[k] + T[i]) <<< s). */
  F e%{2}x, e%{3}x, e%{4}x	; result in edi
  add edi, e%{1}x
  add edi, [esp+stack.X+%5*4+4]
  add edi, %7
  rol edi, %6
  lea e%{1}x, [edi+e%{2}x]
%endmacro

%macro GG 7	; a = b + ((a + G(b,c,d) + X[k] + T[i]) <<< s). */
  G e%{2}x, e%{3}x, e%{4}x	; result in edi
  add edi, e%{1}x
  add edi, [esp+stack.X+%5*4+4]
  add edi, %7
  rol edi, %6
  lea e%{1}x, [edi+e%{2}x]
%endmacro

%macro HH 7	; a = b + ((a + H(b,c,d) + X[k] + T[i]) <<< s). */
  H e%{2}x, e%{3}x, e%{4}x	; result in edi
  add edi, e%{1}x
  add edi, [esp+stack.X+%5*4+4]
  add edi, %7
  rol edi, %6
  lea e%{1}x, [edi+e%{2}x]
%endmacro

%macro II 7	; a = b + ((a + I(b,c,d) + X[k] + T[i]) <<< s). */
  I e%{2}x, e%{3}x, e%{4}x	; result in edi
  add edi, e%{1}x
  add edi, [esp+stack.X+%5*4+4]
  add edi, %7
  rol edi, %6
  lea e%{1}x, [edi+e%{2}x]
%endmacro

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text
globalfunc lib.string.md5
;>
;; parameters:
;; -----------
;; ESI = ptr to data
;; ECX = legnth of data in bytes
;;
;; returned values:
;; ----------------
;; EAX:EBX:ECX:EDX = result; This is little endian so start with the low-order
;;   byte of EAX and end with the high-order byte of EDX
;<

  sub esp, byte stack_size
  mov [esp+stack.size], ecx
  mov [esp+stack.remaining], ecx

  mov eax, 0x67452301
  mov ebx, 0xefcdab89
  mov ecx, 0x98badcfe
  mov edx, 0x10325476

  ; first do as much of the transform as we can
.full_block:
  push ecx
  mov ecx, 64
  sub [esp+stack.remaining+4], ecx
  lea edi, [esp+stack.X+4]
  jl .partial
  shr ecx, 2
  rep movsd
  pop ecx

  call _transform
  jmp short .full_block

.partial:
  ; [esp+stack.remaining+4] = accual number of bytes remaining - 16
  mov ecx, [esp+stack.remaining+4]
  add ecx, byte 64
  mov ebp, 64
  test ecx, ecx
  jz .none_left
  sub ebp, ecx	; EBP = bytes we have to pad
  rep movsb	; copy the rest
.none_left:
  mov byte[edi], 0x80	; slap on the zero
  inc edi
  
  sub ebp, byte 9
  jl .not_enough_for_size

.add_size:
  mov ecx, [esp+stack.size+4]
  shl ecx, 3
  mov [edi+ebp], ecx
  mov ecx, [esp+stack.size+4]
  shr ecx, 32-3
  mov [edi+ebp+4], ecx

  test ebp, ebp
  jz .go_and_finish

.zero_loop:
  dec ebp
  mov byte[edi+ebp], 0
  jnz .zero_loop

.go_and_finish:
  pop ecx
  call _transform
  
  add esp, byte stack_size
  retn

.not_enough_for_size:
  ; ebp = number of bytes left to pad - 8 (the 0x80 has already been added)
  add ebp, byte 8
  jz .go_go_go

.zero_loop2:
  dec ebp
  mov byte[edi+ebp], 0
  jnz .zero_loop2
.go_go_go:

  pop ecx
  call _transform
  push ecx
  lea edi, [esp+stack.X+4]
  xor ecx, ecx
  mov ebp, 64-8
  jmp .add_size

;                                           -----------------------------------
;                                                                    _transform
;==============================================================================

_transform:
;>
;; does an md5 transform
;;
;; parameters:
;; -----------
;; X from stack
;; EAX, EBX, ECX, EDX = state
;;
;; returned values:
;; ----------------
;; EAX, EBX, ECX, EDX = new state
;<
  
  mov [esp+stack.a+4], eax
  mov [esp+stack.b+4], ebx
  mov [esp+stack.c+4], ecx
  mov [esp+stack.d+4], edx
  
  FF a, b, c, d,  0,  7, 0xd76aa478
  FF d, a, b, c,  1, 12, 0xe8c7b756
  FF c, d, a, b,  2, 17, 0x242070db
  FF b, c, d, a,  3, 22, 0xc1bdceee
  FF a, b, c, d,  4,  7, 0xf57c0faf
  FF d, a, b, c,  5, 12, 0x4787c62a
  FF c, d, a, b,  6, 17, 0xa8304613
  FF b, c, d, a,  7, 22, 0xfd469501
  FF a, b, c, d,  8,  7, 0x698098d8
  FF d, a, b, c,  9, 12, 0x8b44f7af
  FF c, d, a, b, 10, 17, 0xffff5bb1
  FF b, c, d, a, 11, 22, 0x895cd7be
  FF a, b, c, d, 12,  7, 0x6b901122
  FF d, a, b, c, 13, 12, 0xfd987193
  FF c, d, a, b, 14, 17, 0xa679438e
  FF b, c, d, a, 15, 22, 0x49b40821

  GG a, b, c, d,  1,  5, 0xf61e2562
  GG d, a, b, c,  6,  9, 0xc040b340
  GG c, d, a, b, 11, 14, 0x265e5a51
  GG b, c, d, a,  0, 20, 0xe9b6c7aa
  GG a, b, c, d,  5,  5, 0xd62f105d
  GG d, a, b, c, 10,  9,  0x2441453
  GG c, d, a, b, 15, 14, 0xd8a1e681
  GG b, c, d, a,  4, 20, 0xe7d3fbc8
  GG a, b, c, d,  9,  5, 0x21e1cde6
  GG d, a, b, c, 14,  9, 0xc33707d6
  GG c, d, a, b,  3, 14, 0xf4d50d87
  GG b, c, d, a,  8, 20, 0x455a14ed
  GG a, b, c, d, 13,  5, 0xa9e3e905
  GG d, a, b, c,  2,  9, 0xfcefa3f8
  GG c, d, a, b,  7, 14, 0x676f02d9
  GG b, c, d, a, 12, 20, 0x8d2a4c8a

  HH a, b, c, d,  5,  4, 0xfffa3942
  HH d, a, b, c,  8, 11, 0x8771f681
  HH c, d, a, b, 11, 16, 0x6d9d6122
  HH b, c, d, a, 14, 23, 0xfde5380c
  HH a, b, c, d,  1,  4, 0xa4beea44
  HH d, a, b, c,  4, 11, 0x4bdecfa9
  HH c, d, a, b,  7, 16, 0xf6bb4b60
  HH b, c, d, a, 10, 23, 0xbebfbc70
  HH a, b, c, d, 13,  4, 0x289b7ec6
  HH d, a, b, c,  0, 11, 0xeaa127fa
  HH c, d, a, b,  3, 16, 0xd4ef3085
  HH b, c, d, a,  6, 23,  0x4881d05
  HH a, b, c, d,  9,  4, 0xd9d4d039
  HH d, a, b, c, 12, 11, 0xe6db99e5
  HH c, d, a, b, 15, 16, 0x1fa27cf8
  HH b, c, d, a,  2, 23, 0xc4ac5665

  II a, b, c, d,  0,  6, 0xf4292244
  II d, a, b, c,  7, 10, 0x432aff97
  II c, d, a, b, 14, 15, 0xab9423a7
  II b, c, d, a,  5, 21, 0xfc93a039
  II a, b, c, d, 12,  6, 0x655b59c3
  II d, a, b, c,  3, 10, 0x8f0ccc92
  II c, d, a, b, 10, 15, 0xffeff47d
  II b, c, d, a,  1, 21, 0x85845dd1
  II a, b, c, d,  8,  6, 0x6fa87e4f
  II d, a, b, c, 15, 10, 0xfe2ce6e0
  II c, d, a, b,  6, 15, 0xa3014314
  II b, c, d, a, 13, 21, 0x4e0811a1
  II a, b, c, d,  4,  6, 0xf7537e82
  II d, a, b, c, 11, 10, 0xbd3af235
  II c, d, a, b,  2, 15, 0x2ad7d2bb
  II b, c, d, a,  9, 21, 0xeb86d391

  add eax, [esp+stack.a+4]
  add ebx, [esp+stack.b+4]
  add ecx, [esp+stack.c+4]
  add edx, [esp+stack.d+4]
  
  retn

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================

section .c_info
  ; version:
db 1,0,0,'a'
  ; ptr to cell's name
dd str_cellname
  ; ptr to author's name
dd str_author
  ; ptr to copyrights
dd str_copyrights
str_cellname: db "md5 - a cell implementing the MD5 secure message-digest algorithm",0
str_author: db "Phil Frost <daboy@xgs.dhs.org>",0
str_copyrights: db "public domain",0
