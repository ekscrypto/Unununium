;
; mony editor (med) for Unununium OE
;
; by Jacques Mony (jmony) - jmony@jmony.com, 2002
;
; Revision 0.1.0 - Restarted
; Todo: Add the code for the key handling, load/save and clipboard. In fact, do
; the editor. :P
;
; Was restarted... better architecture ;)


;                                           -----------------------------------
;                                                                      includes
;==============================================================================

; I don't know yet which really needs to be there, but it works for now :)

%include "vid/kbd.inc"
%include "vid/lib.string.inc"
%include "vid/mem.inc"
%include "vid/process.inc"
%include "vid/void.inc"
%include "vid/vfs.inc"
%include "vid/lib.term.inc"
%include "vid/lib.env.inc"
%include "process.inc"
%include "ozone.inc"

;                                           -----------------------------------
;                                                                        _start
;==============================================================================

global _start
_start:

	mov [proc_info], ebx			;Just grab some informations... stdio ;)
	mov eax, [ebx+process_info.stdout]
	mov edx, [ebx+process_info.stdin]
	mov esi, [ebx+process_info.stderr]
	mov ecx, [ebx+process_info.env]
	mov [stdout], eax
	mov [stdin], edx
	mov [stderr], esi
	mov [env], ecx


	mov ecx, 64000
	externfunc mem.alloc
	jc _error
	mov [b_start], edi
	mov [b_pointer],edi

	call _clear_memory
	jmp _med_main

_clear_memory:						;; THIS CLEARS THE BUFFER
	mov eax,0
	.clear_loop:
	;mov dword[eax+b_start], 0
	add eax, 4
	cmp eax, 64000
	jl .clear_loop
	retn

_exit:								;; THIS EXITS
	mov esi, clear
	call _print
	clc
	xor eax,eax
	retn

_error:								;; THIS EXITS WITH ERROR
	mov esi, clear
	call _print
	stc
	mov eax, __ERROR_INSUFFICIENT_MEMORY__
	retn

_med_main:							;; MAIN PROGRAM
	mov esi, clear
	call _print

	mov esi, howto
	call _print

	call _read
	mov esi, clear
	call _print

	.main_loop:						;; MAIN LOOP

		call _read
		cmp al, 0x1b
		je .escape_key

		;;Want to check for other keys? do it here:

		
		;;Backspace
		cmp al, 0x08
		jne .cont1
		call .BACKSPACE
		jmp .main_loop

		;;Enter
		.cont1:
		cmp al, 0x0a
		jne .cont2
		call .ENTER
		jmp .main_loop

		;;Tab
		.cont2:
		cmp al, 0x09
		jne .contX
		call .TAB
		jmp .main_loop

		;;Normal Key
		.contX:
		mov [cur_char], al
		mov esi, cur_char
		call _print

		jmp .main_loop

	.escape_key:
		call _read
		cmp al, '['	
		jne .get3
		call _read

		cmp al, 'A'
		je near .UP
		cmp al, 'D'
		je near .LEFT
		cmp al, 'B'
		je near .DOWN
		cmp al, 'C'
		je near .RIGHT
		



		cmp al, '1'
		jne .get2
		call _read
		jne .get1
		push eax
		call _read
		pop eax
		cmp al, '1'
		je near .new
		cmp al, '2'
		je near .load
		cmp al, '3'
		je near .save
		cmp al, '4'
		je near .clipboard_functions
		cmp al, '5'
		je near _exit

		jmp near .main_loop
		.get3:
		call _read
		.get2:

		cmp al, '2'
		je near .check_other
		cmp al, '3'
		je near .check_other
		cmp al, '4'
		je near .check_other
		cmp al, '5'
		je near .check_other
		cmp al, '6'
		je near .check_other
		cmp al, '7'
		je near .check_other

		call _read
		.get1:
		call _read
		jmp near .main_loop

.ENTER:
.BACKSPACE:
.TAB:
	retn

.check_other:
	push eax
	call _read
	cmp al, '~'
	pop eax
	jne .main_loop

	;;We probably got one of home, insert, del, end or pgUP/DN
jmp .main_loop
		cmp al, '2'
		je near .INSERT
		cmp al, '3'
		je near .DELETE
		cmp al, '4'
		je near .HOME
		cmp al, '5'
		je near .END
		cmp al, '6'
		je near .PGUP
		cmp al, '7'
		je near .PGDN

jmp .main_loop


.new:			;;Just make a dealloc/malloc and clear the screen ;)
			;;And clean the new content...			TODO
	call _clear_memory
.load:
.save:
.clipboard_functions:
	jmp .main_loop

.UP:
.LEFT:
.DOWN:
.RIGHT:
	jmp .main_loop

.INSERT:
.DELETE:
.HOME:
.END:
.PGUP:
.PGDN:
jmp .main_loop


_read:
	mov ebx,[stdin]
	mov ebp,[ebx]
	externfunc lib.string.get_char
	mov [cur_char],al
retn

_print:
	;ESI is the string ptr
	pushad
	externfunc lib.string.find_length
	mov ebx,[stdout]
	mov ebp,[ebx]
	call [ebp+file_op_table.write]
	popad
retn


;-----------------------------------------------------------
section .bss

align 4, db 0
stdout:		resd 1
stdin: 		resd 1
stderr: 	resd 1
env: 		resd 1
proc_info: 	resd 1

;-----------------------------------------------------------
section .data

align 4, db 0
cur_char: 	db 0, 0

max_col: 	dd 80	;;Some vars used to know where we are on screen...
max_lin: 	dd 50	;;And what to do depending on what happens
lin: 		dd 1 
col: 		dd 1
 
b_start: 	dd 0
b_pointer: 	dd 0
quit: 		db 0
clear:  db 0x1b,"[2J",0
howto:  db "med, small editor for uuu.",0x0a
	db "Press F1 to create a new file",0x0a
	db "      F2 to open an existing file",0x0a
	db "      F3 to save the file",0x0a
	db "      F4 for clipboard...",0x0a
	db "      F5 to exit",0x0a
	db "Press ANY KEY to start using med.",0
