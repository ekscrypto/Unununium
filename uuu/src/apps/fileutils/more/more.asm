;; UUU fileutils	(c)2001-2002 Lukas Demetz
;; * more		Unununium Operating Engine
;;
;; $Header: /cvsroot/uuu/uuu/src/apps/fileutils/more/more.asm,v 1.2 2001/12/30 08:15:26 lukas2000 Exp $
;;
;; Prints the contents of a file to the screen
;;
;; [Features]
;;	> Shows page-per-page
;;	> piping-compatible
;;
;; [ToDO]
;;	< > Debug the argument-getting part (filename)
;;	< > Clean the output (Only show the file, not the rest)
;;	< > Optimize it a bit
;;	< > Add Piping-COmpatibility
;;
;; Last change: 29-dec-2001
;;
;; [Status]
;; unstable, to work on it

%include "vid/vfs.inc"
%include "ozone.inc"
%include "vid/mem.inc"
%include "error_codes.inc"
%include "vid/lib.string.inc"
%include "vid/lib.app.inc"
%include "vid/process.inc"
%include "process.inc"

section .text
global _start

;-----------------------------------------------;
;---- Defines ----------------------------------;
;
						;
%define	_SCR_LINES_		25		; Assumed lines on a terminal
%define	_SCR_COLS_		80		; Assumed Columns on a terminal
%define	_DEF_BUFFER_	_SCR_LINES_*_SCR_COLS_	; Size for the buffer
						; -
;-----------------------------------------------;
;---- Error handlers ---------------------------;
;
_error:
  .invalidargs:
  	lea esi, [str_wrongarg]
  	call _print.err
  	stc
  	xor	eax, eax
  	retn
  	
  .showhelp:
  	lea esi, [str_help]
  	call _print.unaligned
  	clc
  	xor	eax, eax
  	retn
  	
  .showversion:
  	lea esi, [str_version]
  	call _print.unaligned
  	clc
  	xor	eax, eax
  	retn
  	
  .vfs_error:
  	lea esi, [str_filenotfound]		; Assume file not found
  	call _print.err
  	stc
  	retn
  	
  .memory_error:
   	lea esi, [str_memoryerror]
  	call _print.err
  	stc
  	retn
  	
  .no_filename:
  	jmp	.invalidargs
  	; ToDO:
  	; Here we must try STDIN (piped things)
  
;---------------------------------------------------------------------------------------;
_start:						; 		< STARTS HERE >
  pushad					;	==============================
  mov eax, [ebx + process_info.stdin]		; Set up STDIO
  mov edi, [ebx + process_info.stdout]		;
  mov edx, [ebx + process_info.stderr]		;
  mov [stdin], eax				;
  mov [stdout], edi				;
  mov [stderr], edx				;
  popad

  cmp ecx, byte 2				; Do we have args at all ?
  jl _error.invalidargs				;
  clc
  
  mov edx, opt					; Check arguments 
  mov ebx, opt_str				;	
  externfunc lib.app.getopts			;
  jc _error.invalidargs				;	
  
  cmp byte[opt.help], 0				;	- help?
  jnz _error.showhelp				; 
  cmp byte[opt.version], 0			;	- version?
  jnz _error.showversion			;
  						;
  ;---------------------------------------------;
  ; ECX = number of arguements
  ; EDI = ptr to standard argv array
  ;---------------------------------------------;
  						;
  push	esi					;
  mov	esi, edi				; Now we need to see, if there is a filename
  externfunc lib.string.find_length		;
  
  pop	esi					; Result in ECX (lenght)
  						;
  cmp	ecx, 00h				; Is lenght 0 (if yes, there is no filename)
  jz	_error.no_filename			;
  						; Ok, there is a filename
  mov	esi, edi				; Open it! (EDI=)
  externfunc	vfs.open			;
  jc	_error.vfs_error			;
  						;
  ;---------------------------------------------;
  ; EBX = File descriptor
  ;---------------------------------------------; 
						; Now, we have to create a buffer according to
  mov	ecx, _DEF_BUFFER_			; _DEF_BUFFER_
  call _tools.alloc				;
  mov	[file_buffer], dword ecx		;
  
  pushad					; \
  mov	edi, ecx				;
  mov	ecx, _DEF_BUFFER_			;
  xor	eax, eax				; Clear it completely
  cld						;
  rep a32 stosb					;
  popad						; /
  						;
  mov	edi, ecx				; Load the registers
  mov	ecx, _DEF_BUFFER_			;
  						;
  ;---------------------------------------------;
  ; EBX = File descriptor
  ; ECX = Size of buffer
  ; EDI = Pointer to buffer
  ;---------------------------------------------;
 .read_loop:					; [.read_loop] starts here
  mov ebp, [ebx]				;
  call [ebp+file_op_table.read]			; Then we read a portion of the file into the buffer
						;
  jnc	.read.no_err				; And check for EOF
  cmp 	eax, __ERROR_FS_END_OF_FILE_REACHED__	;
  je	.file_end				;
  						;
 .read.no_err: 					;
  cmp	eax, ecx				; if EAX is NOT equal ECX, partial read and EOF
  jz	.continue_reading			;
						; 
  ;---------------------------------------------;
  ; EBX = File descriptor
  ; EAX = Amount of bytes in buffer
  ; ECX = Size of buffer
  ; EDI = Pointer to buffer
  ;---------------------------------------------;  
  						;
  call _print.frombuffer			; AHA, print to screen and exit 
  mov ebp, [ebx]				;
  call [ebp+file_op_table.close]  		; Close the file
  jmp	.cleanup				;
					
.continue_reading:				; File not ended, print
  call _print.frombuffer			;
  call _tools.waitforenter			; now, wait for a keypress (ENTER)	
						;
  jmp .read_loop				; And now, continue reading
						; [.read_loop] ends here
.file_end:					;
  mov ebp, [ebx]				;
  call [ebp+file_op_table.close]  		; Close the file
  jmp	.cleanup				;
						;
.cleanup:					; [.cleanup]
						;
						; Here we need to:
  lea ecx, [file_buffer]			; 	- Release the buffer
  call _tools.dealloc				;
  lea esi, [str_EOF]				;	- Print a little msg
  call _print.unaligned				;
  						;
  xor eax, eax					;	- Give back Error-Code (0)
  clc						; 
  retn						;	============================			
						; 		< ENDS HERE >
;---------------------------------------------------------------------------------------;



;-----------------------------------------------;
;-------- Tools & functions we could need ------;
;-----------------------------------------------;
_print:						; 	[_print]
  .unaligned:					;
  ; prints string pointed to by ESI 		; Prints to STDOUT
  ; (only single null required)			;
  pushad					;
  externfunc lib.string.find_length		;
  mov ebx, [stdout]				;
  mov ebp, [ebx]				;
  call [ebp+file_op_table.write]		;
  popad						;
  retn						;
						;
  .err:						; Prints to STDERR
  ; same but prints to stderr			;
  pushad					;
  externfunc lib.string.find_length		;
  mov ebx, [stderr]				;
  mov ebp, [ebx]				;
  call [ebp+file_op_table.write]		;
  popad						;
  retn						;
  						;
  .frombuffer:					; Prints from buffer to stdout
  ; Prints EDI-buffer to stdout			;
  ; EAX = Size of buffer			;
  ;						;
  pushad					;
  mov esi, edi					;
  mov ecx, eax					;
  mov ebx, [stdout]				;
  mov ebp, [ebx]				;
  call [ebp+file_op_table.write]		;
  popad						;
  retn						;
  						;
  						;
_tools:						; 	[_tools]
  .waitforenter:				; 
  ; Waits for ENTER to be pressed		;
  pushad					; Save registers completely
 .loop: 					;
  mov ecx, 01h					;
  mov ebx, [stdin]				;
  mov ebp, [ebx]				;
  lea edi, [lil_buffer]				;
  call [ebp+file_op_table.read]			; Read a byte from the STDIN		
  						; 
  cmp [lil_buffer], byte 'q'			; is ENTER ?  (0x0D)
  jne .loop					;  	- No? Sigh, loop
  popad						;	- Yes? ok, return
  retn						;
  				
  
  .alloc:					; Alloc tool
  ; in = ecx	amount of bytes			;
  ; out= ecx	location			;
	push	eax				;
	push 	edi				;
	externfunc mem.alloc			;
	jc	.err__				;
	mov	ecx, edi			;
	pop	edi				;
	pop	eax				;
  retn						;
						;
	.err__:					;
	pop 	edi				;
	pop	edi				; DO not restore EAX (Errorcode)
	jmp _error.memory_error			;
						;
  .dealloc:					; Dealloc tool
  ; in = ecx	location			;
	push	ebx				;
	push	eax				;
	mov	eax, ecx			;
	externfunc mem.dealloc			;
	jc	.err_				;
	pop	eax				;
	pop	ebx				;
  retn						;
						;
	.err_:					;
	pop 	ebx				; DO not restore EAX (Errorcode)
	pop	ebx				;
	jmp _error.memory_error			; -----------------------------------------
;; -------------------------------------------- ; 		[ Help string ] 

str_help:
db "Usage: more [OPTION] FILE...",0xa
db "Prints the contents of the file to screen",0xa
db 0xa
db "  -h     display this help and exit",0xa
db "  -v     output version information and exit",0xa,0


str_noargs:
db "more: too few arguments",0xa
db "Try `more -h' for more information.",0xa,0

str_wrongarg:
db "more: wrong arguments",0xa
db "Try `more -h' for more information.",0xa,0

str_version:
db "more version $Revision: 1.2 $ pre-alpha",0xa
db "     by Lukas Demetz",0xa,0

str_filenotfound:
db "more: File not found",0xa,0

str_EOF:
db "EOF",0xa,0

str_memoryerror:
db "more: Memory alloc/dealloc error.",0xa,0

str_file:
db"/text.txt",0					; --------------------------------------;
;-----------------------------------------------; 		[DATA]			;
;-----------------------------------------------; --------------------------------------;
; Some data					;					;
stdin:	dd 0					; STDIN filehandle			;
stdout:	dd 0					; STDOUT filehandle			;
stderr:	dd 0					; STDERR filehandle			;
						;					;
file_buffer: 	dd 0				; Buffer for Read/Output		;
lil_buffer:	db 0				; Buffer for 1 char			;
						;					;
opt:						; Array for parsed arguments		;
.version:	db 0				; 	- Version (-v)			;
.help:		db 0				;	- Help (-h)			;
						;					;
opt_str:	db "vh",0,0,0			; String for arguments			;
						;	- 'v' for Version (-v)		;
						;	- 'h' for Help (-h)		;
						;					;
						; 	  	  <END>			;
;---------------------------------------------------------------------------------------;