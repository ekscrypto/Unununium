; CAT tool 0.0.1 - Jacques Mony, Jan19 2002
;
; Now commented :-)
;
; You can improve the "end of stdin input" feature, which ends with ESCAPE
; instead of CTRL-C (CTRL-C doesn't seem to kill the process).
;

section .text
;==============================================================================

global _start
_start:
;------------------------------------------------------------------------------
						; Save I/O data
						;------------------------------
	mov eax, [ebx+process_info.stdin]	; Save stdin
	mov [stdin], eax			;
	mov eax, [ebx+process_info.stdout]	; Save stdout
	mov [stdout], eax			;
	mov eax, [ebx+process_info.stderr]	; Save stderr
	mov [stderr], eax			; (Unused at the moment)
						;
						; Check Command Line Parameters
						;------------------------------
	cmp ecx, 2				; How many entries in argv[] ?
	jge .gotfilename			; If there is a file,	
						;  call the appropriate
						;  sub-program.
	call .catitin				; There was not file, 
						;  pure stdin/stdout method
						;
						; Exit without problem
						;------------------------------
	clc 					; Clear carry
	xor eax,eax				; Clear error code
	retn					; return to caller
;------------------------------------------------------------------------------


.gotfilename:							
;------------------------------------------------------------------------------
						; Retrieve filename
						;------------------------------
	add edi,4				; Go to next argument
	mov esi, [edi]				; filename is pointed by edi+4
	cmp esi, 0				; Is it the last file?
	je .exitfil				; If so, exit!
	externfunc vfs.open			; Call vfs.open (open file)
	jnc .cont				; If there is not problem, 
						; continue.
						;
						;
						;
						; Error happened
						;------------------------------
	stc					; huho, there was a problem!
	mov eax, 17				; FILE NOT FOUND ERROR EXIT
	retn					; Return to caller
						;
	.cont:					; Ok, we got the file opened.
	mov [stdin], ebx			; Make it become our stdin
						;
						;
	call .catit				; Now call that method of CAT
						;
	mov ebx,[stdin]				; Take the file handler
	mov ebp,[ebx] 				;	
	call [ebp+file_op_table.close]		; Close the file!
						;
	jmp .gotfilename			; Loop in case we have more 
						;  than one file
.exitfil:					;
	clc					; EXIT WITHOUT PROBLEM
	xor eax, eax				;
	retn					;


.catit:						
;------------------------------------------------------------------------------
						; The method used with  file
	pushad					;
						;
						; Main r/w loop
						;------------------------------
.loop:						; Begin
	xor eax, eax				; Clear and set registers		
	mov edi, buffer				;
	xor ecx, ecx				;
	mov ecx, 1				; Buffer size (TO FIX to allow
	mov ebx, [stdin]			; > 1 !!)
	mov ebp, [ebx]				;
	call [ebp+file_op_table.read]		; Call read with the right
        jc .exit				; parameters. Exit if error.
						;	
	cmp eax, 0				; End of file?
	je .exit				;
						; Display to stdout
						;------------------------------
	mov esi, buffer				;
	mov ecx, eax				; Size read
	mov ebx, [stdout]			;
	mov ebp, [ebx]				;
	call [ebp+file_op_table.write]		; Write the byte to stdout
	jmp .loop				; Go back to loop begin
.exit:						; EXIT
	popad					;
	retn					;
;------------------------------------------------------------------------------
	
.catitin:
;------------------------------------------------------------------------------
						; The method for stdin-->stdout
	pushad					;
						;
						; Loop start
.loop1:						;------------------------------
	xor eax, eax				;
	mov edi, buffer				;
	mov ecx, 1				; One char
	mov ebx, [stdin]			;
	mov ebp, [ebx]				;
	call [ebp+file_op_table.read]		; READ A BYTE
        jc .exit1				;
						;	
	mov al, [buffer]			;; PRESS ESCAPE TO TERMINATE
	cmp al, 0x1b				;; STDIN INPUT
	je .exit1				;
					;; THIS WILL CAUSE A PROBLEM WITH
					;; STDIN PIPES. THIS NEEDS TO BE
					;; FIXED IN THE FUTURE... anyways,
					;; we could kill the process too ;)
						;
	mov esi, buffer				;
	mov ecx, 1				;
	mov ebx, [stdout]			;
	mov ebp, [ebx]				;
	call [ebp+file_op_table.write]		; WRITE THE BYTE
	jmp .loop1				; Go back
						;
.exit1:						;
	popad					;
	retn					;
;------------------------------------------------------------------------------

section .data
;==============================================================================
stdin:  dd 0					; Our I/O handlers
stdout: dd 0					; are saved
stderr: dd 0					; here
;==============================================================================

section .bss
;==============================================================================
buffer: resb 512				; Reserve a buffer for I/O
;==============================================================================