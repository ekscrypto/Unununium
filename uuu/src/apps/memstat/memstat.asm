;; $Header: /cvsroot/uuu/uuu/src/apps/memstat/memstat.asm,v 1.1 2001/12/19 02:06:58 daboy Exp $
;;
;; memstat: display primitive memory statistics
;;
;; Copyright 2001 Phil Frost
;; This program is distributed under the BSD license;
;; see file 'license' for details

%include "vid/lib.string.inc"
%include "vid/mem.inc"
%include "process.inc"
%include "ozone.inc"

vextern mem.free_ram
vextern mem.free_swap
vextern mem.used_ram
vextern mem.used_swap

global _start
_start:
  mov ebx, [ebx+process_info.stdout]
  mov ebp, [ebx]

  mov esi, mem_str
  mov ecx, mem_len
  call [ebp+file_op_table.write]

  mov edx, [mem.used_ram]
  add edx, [mem.free_ram]
  shr edx, 10
  adc edx, byte 0
  externfunc lib.string.print_dec_no_pad

  mov esi, total_str
  mov ecx, total_len
  call [ebp+file_op_table.write]

  mov edx, [mem.used_ram]
  shr edx, 10
  adc edx, byte 0
  externfunc lib.string.print_dec_no_pad

  mov esi, used_str
  mov ecx, used_len
  call [ebp+file_op_table.write]

  mov edx, [mem.free_ram]
  shr edx, 10
  adc edx, byte 0
  externfunc lib.string.print_dec_no_pad

  mov esi, free_str
  mov ecx, free_len
  call [ebp+file_op_table.write]

  xor eax, eax
  retn

section .data
mem_str:		db "Mem: "
mem_len:		equ $-mem_str
swap_str:		db 0xa,"Swap: "
swap_len:		equ $-swap_str
total_str:		db "K total, "
total_len:		equ $-total_str
used_str:		db "K used, "
used_len:		equ $-used_str
free_str:		db "K free",0xa
free_len:		equ $-free_str
