;; $Header: /cvsroot/uuu/uuu/src/cells/video/console/rubidium/rubidium.asm,v 1.3 2001/12/10 18:18:34 instinc Exp $
;;
;; Rubidium console manager
;;
;; Copyright (C) 2001 by Phil Frost
;;
;; todo: later this cell should create new consoles as needed, but for now it
;; creates a fixed number at init
;;
;; todo: some of these functions are not thread safe

%define _NUM_CONSOLES_ 32	; number of consoles to be created (non-zero)


struc console
  .next:	resd 1	; ptr to next console, 0 for none
  .prev:	resd 1	; ptr to prev. console, 0 for none
  .release:	resd 1	; ptr to release function, 0 if console is not hooked
  .activate:	resd 1	; ptr to activate function
  .remember_me:	resd 1	; given when registered; restored for release, activate
endstruc

;                                           -----------------------------------
;                                                                          init
;==============================================================================

section .c_init

init:
  pushad

  ; make mem.fixed space for our console strucs
  mov edx, console_size
  mov ecx, 3		; 8 consoles per block
  externfunc mem.fixed.alloc_space
  mov [console_space], edi
  
  ; create the consoles
  mov edx, _NUM_CONSOLES_
  xor ebp, ebp
  
  mov [num_consoles], edx
  mov edi, [console_space]
  externfunc mem.fixed.alloc
  mov [root_console], edi
  mov [edi+console.prev], ebp
  mov [edi+console.release], ebp
  mov ebx, edi
  dec edx
  jz .done_making

.make_console:
  mov edi, [console_space]
  externfunc mem.fixed.alloc
  mov [edi+console.prev], ebx
  mov [ebx+console.next], edi
  mov [edi+console.release], ebp
  mov ebx, edi
  dec edx
  jnz .make_console
  
.done_making:
  mov [edi+console.next], ebp

  popad

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                  console.hook
;==============================================================================

globalfunc console.hook
;>
;; hooks a console for use. All consoles when hooked should be assumed to be
;; inactive; their activate function will be called when they are activated
;; (possibly before this function returns)
;;
;; parameters:
;; -----------
;; EDX = console to hook, 0 for next availible (only 0 is supported ATM)
;; ESI = ptr to activate function
;; EDI = ptr to release function
;; EBX = remember me value
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;;
;; The caller may provide a "remember me" value that will be restored when the
;; activate and release functions are called. This allows one function to fill
;; the role of activate/release function for many consoles.
;;
;; release function:
;; -----------------
;; The release function is called when the app should suspend use of the
;; display and keyboard.
;; 
;;   parameters:
;;   -----------
;;   EBX = remember me value
;;
;;   returned values:
;;   ----------------
;;   all registers except EBX = unmodified
;;   errors as usual
;;
;; activate function:
;; ------------------
;; The activate function is called when the app's console has been made active;
;; it can then hook the keyboard and resume using the display.
;;
;;   parameters:
;;   -----------
;;   EBX = remember me value
;;
;;   returned values:
;;   ----------------
;;   all registers except EBX = unmodified
;;   errors as usual
;<

  test edx, edx
  jnz .error
  mov eax, [root_console]

.try_console:
  cmp dword[eax+console.release], byte 0	; is it free?
  jz .found_free
  mov eax, [eax+console.next]
  test eax, eax
  jnz .try_console

.error:
  ; no free consoles, sucks to be you
  xor eax, eax
  dec eax
  stc
  retn

.found_free:
  mov [eax+console.release], edi
  mov [eax+console.activate], esi
  mov [eax+console.remember_me], ebx

  ; EDX = 0
  cmp [active_console], edx
  jz .set_active
  
  clc
  retn

.set_active:
; there was no active console, so activate this one
  pushad
  call esi
  popad
  jc .retn
  mov [active_console], eax
  clc
.retn:
  retn

;                                           -----------------------------------
;                                                            console.set_active
;==============================================================================

globalfunc console.set_active
;>
;; sets a specified console as active
;;
;; parameters:
;; -----------
;; EDX = console to set as active
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;<

  push edx
  push ebx
  
  cmp edx, [num_consoles]
  ja .no_such_console		; this will catch EDX = 0 (now -1) also

  mov eax, [root_console]
  dec edx
  jz .console_found
  js .no_such_console
.next_console:
  mov eax, [eax+console.next]
  test eax, eax
  jz .no_such_console
  dec edx
  jnz .next_console

.console_found:
  cmp dword[eax+console.release], byte 0
  jz .no_such_console
  push eax
  mov edx, [active_console]
  mov ebx, [edx+console.remember_me]
  call [edx+console.release]
  pop edx
  jc .retn
  
  mov ebx, [edx+console.remember_me]
  call [edx+console.activate]

.retn:
  pop ebx
  pop edx
  retn

.no_such_console:
  mov eax, __ERROR_NO_SUCH_CONSOLE__
.err_retn:
  pop ebx
  pop edx
  stc
  retn

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data

console_space:	dd 0	; mem.fixed space for console strucs
root_console:	dd 0	; ptr to root node of console chain
num_consoles:	dd 0	; number of existing consoles
active_console:	dd 0	; currently active console
