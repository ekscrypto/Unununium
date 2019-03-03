; MOUNT tool 0.0.1 - Hubert Eichner, February 2003
;						;
;						;
section .text					;
;===============================================;
						;
global _start					;
_start:						;
;-----------------------------------------------;
	mov ebx, [ebx+process_info.stdout]	; Save stdout array in ebx
						; edi points to stdin array
	cmp ecx, 3				; check argcount
	jne .failure_usage			; wrong number of args?
						;
	mov eax, dword [edi+4]			;
	mov esi, dword [edi+8]			;
	mov edx, __FS_TYPE_EXT2__		;
	push ebx				;
	externfunc vfs.mount			;
	jc .failure_vfs				;
	add esp, 4				;
	xor eax, eax				;
	retn					;
;-----------------------------------------------;
	.failure_usage:				;
	mov ebp, dword[ebx]			; get op_table
	mov esi, usage_string 			;
	mov ecx, usage_string_len  		;
	call [ebp+file_op_table.write]		;
	mov eax, 1				;
	retn					;
;-----------------------------------------------;
	.failure_vfs:				;
	pop ebx					;
	mov ebp, dword[ebx]			; get op_table
	mov esi, vfs_error 			;
	mov ecx, vfs_error_len  		;
	call [ebp+file_op_table.write]		;
	retn					;
;===============================================;
section .data					;
usage_string:	db "Usage: mount <devicepath> <mountpoint>",0xA,0
usage_string_len:	equ $-usage_string	;
vfs_error: db "vfs.mount returned error; ",0	;
vfs_error_len:	equ $-vfs_error			;
;===============================================;
