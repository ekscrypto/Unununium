; Unununium Standard Libs		by Lukas Demetz
; AppWrapper
;
; Description: This code gets linked with any C app that uses stdlib4uuu.
;		The purpose is to bridge the gap between UUU and those
;		apps.
;
; Status: Should work

%include "process.inc"

section .text

global _start
_start:						; Here we get control from UUU
 
  push eax					
  push edi
  push edx
  mov eax, [ebx + process_info.stdin]		; Set up STDIO
  mov edi, [ebx + process_info.stdout]		;
  mov edx, [ebx + process_info.stderr]		;
  mov [stdlib_stdin], eax			;
  mov [stdlib_stdout], edi			;
  mov [stdlib_stderr], edx			;
  mov [stdlib_proc_info], ebx			; Save this for later usage
  pop edx
  pop edi
  pop eax
  
  extern _init_stdio
  call 	_init_stdio				; Call Init code of stdio
  
  push esi					; Here the ARGS
  push ecx					; Number of args
  extern main
  call main
  pop ecx
  pop esi
  
  extern _cleanup_stdio				; Call STDIO's cleanup code
  call	_cleanup_stdio
  						; EAX = Return value of app
 retn
 
section .bss
 ;; Variables
 global stdlib_stdin
 stdlib_stdin:		resd 1			; Save stdin
 global stdlib_stdout
 stdlib_stdout: 	resd 1			; Save stdout
 global stdlib_stderr
 stdlib_stderr: 	resd 1			; Save stderr
 
 global stdlib_proc_info
 stdlib_proc_info:	resd 1			; Save process_info
