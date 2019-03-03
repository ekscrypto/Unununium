; Unununium Operating Engine
; Distributed under the BSD License

; vim: syntax=uuu


%ifndef __MACROS_INC__
%define __MACROS_INC__

%macro vglobal 2
  %ifnnum %2
    %error "seccond arg to vglobal must be a number"
  %else
    global ..@VOiD%2
    ..@VOiD%2 equ %1
  %endif
%endmacro

%macro vglobal 1
  %ifndef %1.VID
    %error "matching .VID not defined for vglobal:"
    %error %1
  %else
    vglobal {%1}, {%1.VID}
  %endif
%endmacro

%macro vextern 2
  %ifndef vextern%1
    %define vextern%1
    %ifnnum %2
      %error "seccond arg to vextern must be a number"
    %endif
    extern ..@VOiD%2
    %1 equ ..@VOiD%2
  %endif
%endmacro

%macro vextern 1
  %ifndef %1.VID
    %error "matching .VID not defined for vextern:"
    %error %1
  %else
    vextern {%1}, {%1.VID}
  %endif
%endmacro
;;------------------------------------------------------------------------------
;; globalfunc NAME, CLASS [, FID, CID]
;;

%macro globalfunc 1
  %1:
  vglobal %1
%endmacro

%macro globalfunc 2
  %1:
  vglobal %1, %2
%endmacro


;;------------------------------------------------------------------------------
;; externfunc NAME, CLASS
;;
;; Calls an external function. Use it like you would a CALL instruction.

%macro externfunc 1
  %ifndef %1.VID
    %error "matching .VID not defined for vextern:"
    %error %1
  %else
    vextern %1, %1.VID
    call %1
  %endif
%endmacro

%macro externfunc 2
  vextern %1, %2
  call %1
%endmacro

;                                           -----------------------------------
; STRING MACROS.. handy little things to make dword-aligned strings and such
;==============================================================================

;                                           -----------------------------------
;                                                                       dstring
;==============================================================================
;; usage: dstring "hi mom, this is a string"
;;
;; makes a dword aligned string. The nulls are automaticly added.

%macro dstring 1+.nolist
  db %1,0
  align 4, db 0
%endmacro


;                                           -----------------------------------
; ICS RELATED MACROS.. simplify and reduce the chances of error: stupid dd 0,0!
;==============================================================================

%macro ics_client 1.nolist
dd 0,0
%{1}:
%endmacro



;                                           -----------------------------------
;       DEBUGGING MACROS.. I'm now using them all over, better define them here
;==============================================================================

%macro dme 1.nolist	; prints a number to the upper-left corner of screen
  pushfd
  pushad
  mov edx, %{1}
  mov edi, 0xB8000
  externfunc debug.diable.dword_out
  popad
  popfd
%endmacro

%macro dmeh 1.nolist	; prints a number and waits for <enter>
  pushfd
  pushad
  mov edx, %{1}
  mov edi, 0xB80A0
  externfunc debug.diable.dword_out_wait
  popad
  popfd
%endmacro

%macro dmej 1.nolist	; prints a number to the upper-left and locks
  pushfd
  pushad
  mov edx, %{1}
  mov edi, 0xB80A0
  externfunc debug.diable.dword_out
  popad
  popfd
  cli
  jmp short $
%endmacro

%macro vm 1.nolist	; edits a memory location
  pushfd
  pushad
  mov esi, %{1}
  externfunc debug.ehex.edit_mem
  popad
  popfd
%endmacro

;                                           -----------------------------------
;                                 MORE DEBUGGING MACROS that use the system log
;==============================================================================

%macro dbg_print 1+.nolist	; prints a string to the system log;
%ifdef _DEBUG_			; caller includes the 0 or 1 terminator
[section .data]
%%str: db %1
__SECT__

  push esi
  mov esi, %%str
  externfunc sys_log.print_string
  pop esi
%endif
%endmacro

%macro dbg_print_hex 1.nolist	; prints a 32 bit number in hex
%ifdef _DEBUG_
  push edx
  mov edx, %1
  externfunc sys_log.print_hex
  pop edx
%endif
%endmacro

%macro dbg_term_log 0.nolist	; terminates the log
%ifdef _DEBUG_
  externfunc sys_log.terminate
%endif
%endmacro

%macro dbg_wait_ack 0.nolist	; waits for the user to hit <enter>
%ifdef _DEBUG_
  externfunc debug.diable.wait
%endif
%endmacro

;                                           -----------------------------------
;                                        lprint - print stuff to the system log
;==============================================================================
;; parameters:
;; -----------
;; %1 = string to print. If you want a NL on the end you need {} braces so nasm
;;        will pass it in one arg, ex. '{"hi mom!",0xa}'
;; %2 = type of log entry, one of DEBUG, INFO, LOADINFO, WARNING, FATALERR
;; %3 = arg 1
;; %4 = arg 2
;;   ...
;; 
;; returned values:
;; ----------------
;; All registers unmodified (even eax on non-error)
;; errors as usual

%macro lprint 2-*.nolist
  %rep %0-2
    %rotate -1
    push dword %1
  %endrep
  %rotate %0-2

  push byte __SYSLOG_TYPE_%2__
  push dword %%str
  externfunc sys_log.print
  lea esp, [esp + (%0 - 2) * 4 ]

[section .data]
%%str: db %1,0xa,0
__SECT__
%endmacro


%macro dbg 1+.nolist	; a single line %ifdef _DEBUG_ thingie
%ifdef _DEBUG_
  %1
%endif
%endmacro

%endif	;__MACROS_INC__
