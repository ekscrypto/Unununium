;; $Header: /cvsroot/uuu/uuu/src/cells/lib/app/common/common.asm,v 1.4 2002/01/05 23:45:05 raptor-32 Exp $
;;
;; Common app lib cell
;; Written by Phil Frost
;;
;; Copyright (c) 2001 by Phil Frost
;; This software is distributed under the BSD license;
;; see file 'license' for details.

section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Common Application Functions",0
str_author: db "Phil Frost",0
str_copyright: db "Distributed under BSD License",0

section .text

;%define _DEBUG_

struc stack
  .ret:		resd 1	; return address
endstruc


globalfunc lib.app.getopts
;>
;; This function takes the usual argv and argc from when an app is called,
;; processes the args based on a string given as a parameter, and then returns
;; the nev argv and argc with the options removed.
;;
;; parameters:
;; -----------
;; EBX = ptr to option description string
;; ECX = number of arguements
;; EDI = ptr to standard argv array
;; EDX = ptr to result area
;;
;; returned values:
;; ----------------
;; ECX, EDI = new values with the options removed
;;
;; option parsing:
;; ---------------
;; There are 2 types of options this function will parse, long ones, which
;; consist of more than one letter and begin with '--', and short ones, which
;; are only one letter long and begin with a single '-'.
;;
;; Long options are not yet really parsed, and you will get an error if you
;; ask this function to parse them.
;;
;; More than one hort option may be put after a single '-', thus '-a -b' is
;; the same as '-ab'. Options that take a string arguement, such as
;; "-f somefile" will be supported later.
;;
;; option string:
;; --------------
;; This string is used to describe the valid options and what actions should
;; be taken upon finding them. Currently only short options which do not take
;; a string arguement are supported, so it's quite simple :P
;;
;; The string consists of 3 parts, each terminated by a null as such:
;;
;;   [short with no args], 0, [short with args], 0, [long], 0
;;
;; * short with no args:
;;
;; This section describes short (single letter) options that don't take any
;; additional string args. The format is simply a list of all the valid
;; options. So, if -a and -b are valid options, this section would be "ab".
;; 
;; * short with args
;; * long
;;
;; the [short with args] and [long] are not supported yet, so there should be
;; 3 nulls on the end of the string.
;;
;; * example
;;
;; db "ab",0,0,0
;; -a and -b are valid options which take no extra args
;;
;; result area:
;; ------------
;; the results of the parsing are returned via a result area in memory. A
;; pointer to this area is passed in EDX on calling this function.
;;
;; In the above example ("ab") the first byte at EDX will hold the number of
;; times the -a option was found, and the seccond is for -b. It might look
;; something like this:
;;
;;   section .bss
;;   options:
;;     .a:	resb 1
;;     .b:	resb 1
;<

  %ifdef _DEBUG_
  dbg_print "using arg string: ",1
  push esi
  mov esi, ebx
  externfunc sys_log.print_string
  pop esi
  %endif

  pushad
  push ebp
  push ecx
  
.next_arg:
  add edi, byte 4	; the first arg is the program name, which we don't
.check_arg:
  dec dword[esp]		;   care about
  jz .args_checked
  
  mov esi, [edi]
  cmp byte[esi], '-'
  jne .next_arg
  
  cmp byte[esi+1], '-'	; now see if it's a long arg...
  je .long_arg
  cmp byte[esi+1], 0	; if it was just a '-' then it's not an option
  je .next_arg

  externfunc lib.string.find_length
  dec ecx		; take into account the leading '-'

.next_single_arg:
  inc esi
  xor ebp, ebp
.check_single_arg:
  mov al, [esi]
  dbg_print_hex eax
  dbg_term_log
  cmp al, [ebx+ebp]
  je .found_single_arg

  inc ebp
  cmp byte[ebx+ebp], 0
  jnz .check_single_arg

.invalid_option:
  ; found an invalid option
  dbg_print "found invalid option",0
  add esp, byte 8
  popad
  mov eax, __ERROR_UNSUPPORTED_OPTION__
  stc
  retn

.found_single_arg:
  inc byte[edx+ebp]
  dec ecx
  jnz .next_single_arg

  call _shift_argv
  jmp short .check_arg

.long_arg:
  add esi, byte 2
  cmp byte[esi], 0	; see if it was '--' alone
  je .stop_parsing
  
  jmp short .invalid_option	; long options not supported yet

.args_checked:
  add esp, byte 8
  popad
  clc
  retn

.stop_parsing:
  dbg_print "stopping parsing",0
  call _shift_argv
  jmp short .args_checked



_shift_argv:
  ; shifts argv to the left at EDI, removing the arg pointed to by EDI
  dbg_print "shifting argv",0
  dec dword[esp+36]	; dec the argc on the stack
  mov ecx, [esp+4]
  push edi
.shift_arg:
  mov eax, [edi+4]
  mov [edi], eax
  add edi, byte 4
  dec ecx
  jnz .shift_arg

  pop edi
  retn
