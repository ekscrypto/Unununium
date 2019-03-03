;; $Header: /cvsroot/uuu/uuu/src/apps/ls/ls.asm,v 1.9 2001/11/19 12:19:08 daboy Exp $

%include "vid/vfs.inc"
%include "vid/lib.string.inc"
%include "vid/lib.app.inc"
%include "vid/process.inc"
%include "ozone.inc"
%include "process.inc"

section .text

;                                           -----------------------------------
;                                                               _invalid_option
;==============================================================================

_invalid_option:
  push eax
  mov esi, invalid_option_str
  call _print_err
  pop eax
  stc
  retn

;                                           -----------------------------------
;                                                           _show_help_and_quit
;==============================================================================

_show_help_and_quit:
  mov esi, help_str
  call _print
  xor eax, eax
  retn

;                                           -----------------------------------
;                                                                        _start
;==============================================================================

global _start
_start:

  mov eax, [ebx+process_info.stdin]
  mov [stdin], eax
  mov eax, [ebx+process_info.stderr]
  mov [stderr], eax

  mov edx, opt
  mov ebx, opt_str
  externfunc lib.app.getopts
  jc _invalid_option

  cmp byte[opt.help], 0
  jnz _show_help_and_quit

  ; check if used without options
  cmp ecx, byte 2
  jl .list_cwd

.options_parsed:
  mov ebp, edi

  dec ecx
  jnz .more_than_one

.list_cwd:
  externfunc process.get_wd
  mov edi, ls_callback
  externfunc vfs.list
  jc .done
  xor eax, eax
  jmp short .done

.next_dir:
  call _print_nl

.more_than_one:
  add ebp, byte 4
  mov esi, [ebp]
  push esi
  call _print_unaligned
  mov esi, post_dir_str
  call _print
  pop esi
  mov edi, ls_callback
  push ebp
  push ecx
  externfunc vfs.list
  pop ecx
  pop ebp
  jc .done
  dec ecx
  jnz .next_dir
  xor eax, eax
  
.done:
  retn

ls_callback:
  test esi, esi
  jz .done

  cmp byte[esi], '.'
  jnz .not_hidden
  cmp byte[opt.show_all], 0
  jnz .not_hidden
  clc
  retn

.not_hidden:
  push eax
  call _print_unaligned
  cmp ebx, byte max_type_number
  jna .type_ok		; no indicator if we we don't know what kind it is
  xor ebx, ebx		; so assume it's a regular file
.type_ok:
  cmp byte[opt.indicators], 0
  jz .no_indicator
  mov esi, [type_strs+ebx*4]
  call _print
  
.no_indicator:
  pop eax
  cmp byte [opt.long], 0
  jz short .done
  push eax
  mov esi, size_str
  call _print
  pop eax
  call qtoi
  call _print_unaligned
.done:
  call _print_nl
  clc
  retn

qtoi:
;----
; converts EDX:EAX to a string in decimal representation
;
; params:
;--------
;  EDX:EAX
  mov ebx, 0x0A
  mov esi, qtoi_buffer + 19
.processing:
  mov ecx, eax
  mov eax, edx
  xor edx, edx
  div ebx
  push eax
  mov eax, ecx
  div ebx
  add edx, byte 0x30
  mov [esi], dl
  dec esi
  pop edx
  test edx, edx
  jnz short .processing
  test eax, eax
  jnz short .processing
.wtf:
  inc esi
  retn

;                                           -----------------------------------
;                                                            _print and friends
;==============================================================================

_print:
; prints dword aligned string pointed to by ESI
  pushad
  externfunc lib.string.find_length_dword_aligned
  mov ebx, [stdin]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  popad
  retn

_print_unaligned:
; prints string pointed to by ESI (only single null required)
  pushad
  externfunc lib.string.find_length
  mov ebx, [stdin]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  popad
  retn

_print_err:
; same but prints to stderr
  pushad
  externfunc lib.string.find_length
  mov ebx, [stderr]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  popad
  retn

_print_nl:	; prints a newline
  pushad
  xor ecx, ecx
  mov esi, nl
  mov ebx, [stdin]
  inc ecx
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  popad
  retn

;                                           -----------------------------------
;                                                                  section .bss
;==============================================================================

section .bss

stdin:		resd 1
stderr:		resd 1
qtoi_buffer:	resb 21

opt:
.show_all:	resb 1
.long:		resb 1
.indicators:	resb 1
.help:		resb 1

;                                           -----------------------------------
;                                                                              
;==============================================================================

section .data
align 4

invalid_option_str:	dstring "invalid option"

help_str:
db "Usage: ls [OPTION]... [FILE]...",0xa
db "List information about the FILEs (the current directory by default).",0xa
db 0xa
db "  -h     show this help",0xa
db "  -l     long output; include file size",0xa
db "  -p     append indicator (one of /=@|) to entries",0xa,0
align 4, db 0

post_dir_str:	dstring ":",0xa
size_str:	dstring 0x9		; but between filename and size

type_strs:	dd type_0, type_1, type_2
max_type_number: equ ($ - type_strs) / 4 - 1
type_0:		dstring ""
type_1:		dstring '/'
type_2:		dstring '@'

nl:		db 0xa
opt_str:	db 'alph',0,0,0
dir_str:	db "/",0
