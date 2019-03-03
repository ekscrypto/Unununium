;; Indigas - a mostly nasm-compatible assembler in it's own syntax
;; $Header: /cvsroot/uuu/uuu/src/apps/indigas/indigas.asm,v 1.1 2001/09/08 17:41:42 daboy Exp $
;;
;; status:
;; -------
;; completely useless. Many things need to be done before this is usefull,
;; such as the file system and JIT, but it's aronud anyway as something to
;; do when working on the FS gets slow.

%define _DEBUG_

%macro debug_msg 1
  %ifdef _DEBUG_
    push esi
    mov esi, debug.%1
    externfunc string_out, system_log
    pop esi
  %endif
%endmacro

global app_indigas
app_indigas:
call _lex
retn

found_stc:	db "[indigas] found stc token",0
_stc:	; gets called when we find an stc token
  mov esi, found_stc
  externfunc string_out, system_log
  retn

found_sti:	db "[indigas] found sti token",0
_sti:
  mov esi, found_sti
  externfunc string_out, system_log
  retn

found_failure:	db "[indigas] failed to find a token",0
_failure:	; called when no token is found
  mov esi, found_failure
  externfunc string_out, system_log
  retn

_get_char:
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; al = next char from input, high bits of EAX are zeroed
;; all other registers = unchanged
;; 

  push esi
  mov esi, [input_pos]
  movzx eax, byte[esi]
  inc esi
  mov [input_pos], esi
  pop esi

  retn

_unget_char:
;;
;; parameters:
;; -----------
;; al = char to unget
;;
;; returned_values:
;; ----------------
;; all registers = unchanged
;;

  push edi
  mov edi, [input_pos]
  dec edi
  mov [edi], al
  mov [input_pos], edi
  pop edi

  retn

%include "lexer.inc"
%include "parser.inc"

input_pos:	dd input

input: db "bound",0x0A,0x04
str_buffer: times 255 db 0

%ifdef _DEBUG_
debug:
  .test_node:	db "[indigas] testing node...",0
  .try_next:	db "[indigas] matched, trying next",0
  .try_or:	db "[indigas] not matched, trying or",0
  .token_found:	db "[indigas] found token 0x",1
%endif
