;; $Header: /cvsroot/uuu/uuu/src/cells/lib/string/fasthash/fasthash.asm,v 1.10 2002/01/05 23:40:20 raptor-32 Exp $
;;
;; Fasthash - a lib cell providing a fast hash function for hash table lookups
;; Copyright (C) 2001 by Phil Frost.
;; This software may be distributed under the terms of the BSD license.
;; See file 'licence' for details.
;;
;; The hashing function provided in this cell kicks ass :) It was created by
;; Bob Jenkins in 1996. [http://burtleburtle.net/bob/hash/doobs.html] You rock
;; Bob!
;;
;; This is a fast, very good hash function, but it is no good for cryptographic
;; purposes because the hash is easily reversed. Use it in your hash lookup
;; tables and such and be happy :P
;;
;; status:
;; -------
;; i'm 75% sure it is a propper implementation of the hash function. In any
;; case you will get a value, I just don't know if it's the "propper" one yet
;; :P


section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Fasthash - Hasing Functions",0
str_author: db "Phil Frost",0
str_copyright: db "Distributed under BSD License",0


;                                           -----------------------------------
;                                                                        macros
;==============================================================================

%macro mix 0
; mixes eax, ebx, and edx
; todo: optimize?

  sub eax, ebx
  mov ebp, edx
  sub eax, edx
  shr ebp, 13

  sub ebx, edx
  xor eax, ebp
  mov edi, eax
  sub edx, eax
  shl edi, 8
  
  sub edx, eax
  xor ebx, edi
  mov ebp, ebx
  sub edx, ebx
  shr ebp, 13
  
  sub eax, ebx
  xor edx, ebp
  mov edi, edx
  sub eax, edx
  shr edi, 12

  sub ebx, edx
  xor eax, edi
  mov ebp, eax
  sub edx, eax
  shl ebp, 16
  
  sub edx, eax
  xor ebx, ebp
  mov edi, ebx
  sub edx, ebx
  shr edi, 5
  
  sub eax, ebx
  xor edx, edi
  mov ebp, edx
  sub eax, edx
  shr ebp, 3

  sub ebx, edx
  xor eax, ebp
  mov edi, eax
  sub edx, eax
  shl edi, 10
  
  sub edx, eax
  xor ebx, edi
  mov ebp, ebx
  sub edx, ebx
  shr ebp, 15
  xor edx, ebp
%endmacro


;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

globalfunc lib.string.fasthash
;>
;; Computes a fast, very nice hash sutiable for non cryptographic purposes.
;; See the top of this file for credits!
;;
;; parameters:
;; -----------
;; ESI = ptr to key
;; ECX = legnth of key
;; EDX = seed
;;
;; returned values:
;; ----------------
;; EDX = 32 bit hash
;<
  
  pushad
  
  mov eax, 0x9e3779b9	; init to an arbitrary value

  ; first hack away at the string 12 bytes at a time
  cmp ecx, 12
  mov ebx, eax		; init to an arbitrary value
  jb near .last_bytes

.do_12_bytes:
  movzx ebp, byte[esi+1]
  shl ebp, 8
  movzx edi, byte[esi+2]
  shl edi, 16
  add ebp, edi
  movzx edi, byte[esi+3]
  shl edi, 24
  add ebp, edi
  movzx edi, byte[esi]
  add ebp, edi
  add eax, ebp
  
  movzx ebp, byte[esi+5]
  shl ebp, 8
  movzx edi, byte[esi+6]
  shl edi, 16
  add ebp, edi
  movzx edi, byte[esi+7]
  shl edi, 24
  add ebp, edi
  movzx edi, byte[esi+4]
  add ebp, edi
  add ebx, ebp
  
  movzx ebp, byte[esi+9]
  shl ebp, 8
  movzx edi, byte[esi+10]
  shl edi, 16
  add ebp, edi
  movzx edi, byte[esi+11]
  shl edi, 24
  add ebp, edi
  movzx edi, byte[esi+8]
  add ebp, edi
  add edx, ebp

  mix

  add esi, byte 12
  sub ecx, byte 12
  cmp ecx, byte 12
  jae .do_12_bytes

  ; now finish up the last bytes, up to 11 of them
.last_bytes:
  add edx, [esp+24]	; add legnth from call

  jmp [jmp_table+ecx*4]
  
.11:
  movzx ebp, byte[esi+10]
  shl ebp, 24
  add edx, ebp
.10:
  movzx ebp, byte[esi+9]
  shl ebp, 16
  add edx, ebp
.9:
  movzx ebp, byte[esi+8]
  shl ebp, 8
  add edx, ebp
.8:
  movzx ebp, byte[esi+7]
  shl ebp, 24
  add ebx, ebp
.7:
  movzx ebp, byte[esi+6]
  shl ebp, 16
  add ebx, ebp
.6:
  movzx ebp, byte[esi+5]
  shl ebp, 8
  add ebx, ebp
.5:
  movzx ebp, byte[esi+4]
  add ebx, ebp
.4:
  movzx ebp, byte[esi+3]
  shl ebp, 24
  add eax, ebp
.3:
  movzx ebp, byte[esi+2]
  shl ebp, 16
  add eax, ebp
.2:
  movzx ebp, byte[esi+1]
  shl ebp, 8
  add eax, ebp
.1:
  movzx ebp, byte[esi]
  add eax, ebp
.0:

  mix

  mov [esp+20], edx
  popad
  
  retn

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data
jmp_table:
dd lib.string.fasthash.0, lib.string.fasthash.1, lib.string.fasthash.2
dd lib.string.fasthash.3, lib.string.fasthash.4, lib.string.fasthash.5
dd lib.string.fasthash.6, lib.string.fasthash.7, lib.string.fasthash.8
dd lib.string.fasthash.9, lib.string.fasthash.10, lib.string.fasthash.11
