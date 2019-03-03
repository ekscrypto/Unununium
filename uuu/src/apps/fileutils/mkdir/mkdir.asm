;; UUU fileutils
;; * mkdir		by Lukas Demetz
;;
;; Creates directories
;; Last change: 02-nov-2001

%include "vid/vfs.inc"
%define ish.print.VID 5100
%define ish.scroll.VID 5101

section .text
global _start

_start:
	; Step 1: Check the args
	cmp ecx, byte 1
  	jl .no_args		; nothing passed...
  	mov esi, [edi+4]
  	cmp word[esi], '-h'	; args there
  	je	.print_help
  	
  	cmp word [esi], '-V'
  	je	.be_verbose
  	cmp word [esi], '-v'
  	je	.print_version
  	cmp byte [esi], '-'
  	je	.wrong_arg

	jmp	.continue
	; Step 2: Do the right thing for every arg
	.print_help:
	mov esi, str_help
  	externfunc ish.print
  	xor eax, eax
  	jmp	.exit
  	
	.no_args:
	mov esi, str_noargs
  	externfunc ish.print
  	xor eax, eax
  	jmp	.exit
  	
	.print_version:
	mov esi, str_version
  	externfunc ish.print
  	xor eax, eax
  	jmp	.exit
  	
	.wrong_arg:
	mov esi, str_wrongarg
  	externfunc ish.print
  	xor eax, eax
  	jmp	.exit
  	
	.be_verbose:
	mov esi, str_verbose
  	externfunc ish.print
  	xor eax, eax
  	jmp	.exit
	
	.continue:
		; Get the real dir name
	add	esi, byte 2
	cmp	word[esi], 00h
	je	.no_args
	
	add	edi, byte 4
		; is starting of that supposed string
	
	; Step 3: create the dir in the actual dir OR global dir (/whatever)
	cmp	byte [edi], '/'
	je	.root_is
		; Create in actual dir
		
	.root_is:
	
	; Step 4: Handle errors
	; Step 5: Give feedback
	; Step 6: die
	
	.exit:
	xor	eax, eax
	
	retn












;; ----------------------------------------------- [ Help string ] ---

str_help:
db "Usage: mkdir [OPTION] DIRECTORY...",0xa
db "Create the DIRECTORY(ies), if they do not already exist.",0xa
db 0xa
db "  -V     print a message for each created directory",0xa
db "  -h     display this help and exit",0xa
db "  -v     output version information and exit",0xa,0


str_noargs:
db "mkdir: too few arguments",0xa
db "Try `mkdir -h' for more information.",0xa,0

str_wrongarg:
db "mkdir: wrong arguments",0xa
db "Try `mkdir -h' for more information.",0xa,0

str_version:
db "mkdir version 0.1.1 alpha",0xa
db "      by Lukas Demetz",0xa,0

str_verbose:
db "mkdir: Entering verbose mode...",0xa,0