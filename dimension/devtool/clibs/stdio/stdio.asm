; Unununium Standard Libs		by Lukas Demetz
; STDIO
;
; Description: Provides FS interface to UUU
;
;
; Status: Coding
;
; ToDO:
; --------
;	[ ] Finish the functions
;	[x] Finish buffering
;	[ ] Add all C Defines in stddef.inc 
;
;
;
;

%include "struct.def"
%include "define.inc"
%include "fs/fs.inc"
%include "vid/mem.inc"
%include "vid/vfs.inc"
;
%include "fstdio.inc"
;							----------------
;							Global Functions
;						      --------------------
;		      [Done]
global clearerr		;*		;; void clearerr(FILE *stream) 
global fclose		;*		;; int fclose(FILE *stream)
global feof		;*		;; int feof(FILE *stream)
global ferror		;*		;; int ferror(FILE *stream)
global fflush		;*		;; int fflush(FILE *stream)
global fgetpos		;*		;; int fgetpos(FILE *stream, fpos_t *pos)
global fopen		;*		;; FILE *fopen(const char *filename, const char *mode)
global fread		;*		;; size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream)
global freopen				;; FILE *freopen(const char *filename, const char *mode, FILE *stream)
global fseek		;*		;; int fseek(FILE *stream, long int offset, int whence)
global fsetpos		;*		;; int fsetpos(FILE *stream, const fpos_t *pos)
global ftell		;*		;; long int ftell(FILE *stream)
global fwrite		;*		;; size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream)
global remove				;; int remove(const char *filename)
global rename				;; int rename(const char *old_filename, const char *new_filename)
global rewind		;*		;; void rewind(FILE *stream)
global setbuf		;*		;; void setbuf(FILE *stream, char *buffer)
global setvbuf		;*		;; int setvbuf(FILE *stream, char *buffer, int mode, size_t size)
global tmpfile				;; FILE *tmpfile(void)
global tmpnam				;; char *tmpnam(char *str)


;							----------------
;							  Extern Data
;						      --------------------
extern stdlib_stdin			; Data of the app we#re running
extern stdlib_stdout
extern stdlib_stderr
extern process_info

section .text

;
;--------------------------------------; Allright, we start here
;						GLOBAL FUNCTIONS

clearerr:				;; void clearerr(FILE *stream)
;					-------------------------------
; Clears the end-of-file and error indicators for the given stream. 
; As long as the error indicator is set, all stream operations will return 
; an error until clearerr or rewind is called. 
	
;; Status: Done

	push	ebp
	mov	ebp, esp
	
	; Step 1: Get the param
	push	ebx
	mov 	ebx, [ebp + 8]
	
	call	_tool.parsefilepointer		; Check it
	; Step 2: Reset EOF & Error sign
	mov dword [ebx+l4u_FileDescr.iserror], 00h
	mov dword [ebx+l4u_FileDescr.iseof], 00h
	; Step 3: Return 0
	xor	eax, eax
	pop	ebx
	pop	ebp
	retn
	
fclose:					;; int fclose(FILE *stream)
; 					-------------------------------
; Closes the stream. All buffers are flushed. 
; If successful, it returns zero. On error it returns EOF. 
	
;; Status: Done

	push	ebp			;
	mov	ebp, esp		;
					;   	---
					; Step 1: Get the param
	push	ebx			;
	mov 	ebx, [ebp + 8]		; EBX points to our FileDescr
					; 	---
	call	_tool.parsefilepointer		; Check it				
	call _tool.destruct_l4uFD	; Next Step: Remove our l4u_FileDescr
	
	
					
	pop	ebx			; Cleanup
	pop	ebp			;
	retn				; <done>
 ;--------------------------------------;
	
	
feof:					;; int feof(FILE *stream)
;					-------------------------------
; Tests the end-of-file indicator for the given stream. If the stream
; is at the end-of-file, then it returns a nonzero value. 
; If it is not at the end of the file, then it returns zero. 
	
;; Status: Done

	push	ebp
	mov	ebp, esp
	
	; Step 1: Get the param
	push	ebx
	mov 	ebx, [ebp + 8]
	call	_tool.parsefilepointer		; Check it
	; Step 2: Check EOF
	mov ebx, dword [ebx+l4u_FileDescr.iseof]
	cmp ebx, dword 00h
	je	.neof
	mov	ebx, dword EOF
	
	; Step 3: Return 
	.neof:
	mov 	eax, ebx
	pop	ebx
	pop	ebp
	retn
	
	
	
	
 ferror:				;; int ferror(FILE *stream)
;					-------------------------------
; Tests the error indicator for the given stream. If the 
; error indicator is set, then it returns a nonzero value. 
; If the error indicator is not set, then it returns zero. 
	
;; Status: Done

	push	ebp
	mov	ebp, esp
	
	; Step 1: Get the param
	push	ebx
	mov 	ebx, [ebp + 8]
	call	_tool.parsefilepointer		; Check it
	; Step 2: Check EOF
	mov ebx, dword [ebx+l4u_FileDescr.iserror]
	cmp ebx, dword 00h
	je	.nerr
	; call _tool.parseerror
	mov	ebx, -1			
	
	; Step 3: Return 
	.nerr:
	mov 	eax, ebx
	pop	ebx
	pop	ebp
	retn
	
fflush:					;; int fflush(FILE *stream)
; Returns zero
	xor	eax, eax
	retn

;
fgetpos:				;; int fgetpos(FILE *stream, fpos_t *pos)
;					-------------------------------
; Gets the current file position of the stream and writes it to pos. 
; If successful, it returns zero. 
; On error it returns a nonzero value and stores the error number in the variable. 

; Status: Done
	
			
	call	ftell			; Call ftell (pipe)
	push	ebp			;	-> Returns EAX=position
	mov	ebp, esp		;
					; Result is in eax
	mov	ebp, dword [ebp+12]	;
	cmp	eax, dword -1		;
	jne	.ok			;
					; ---
	call	_tool.seterr		; Error
	pop 	ebp			;
	retn				; 
					; ---
	.ok:				; Ok
	mov	dword [ebp], eax	; Save *pos
	xor	eax, eax		; Return 0
					;
	pop	ebp			;
	retn				; <done>
 ;--------------------------------------;
 	

fseek:				;; int fseek(FILE *stream, long int offset, int whence)
;					---------------------------
; Sets the file position of the stream to the given offset. 
; The argument offset signifies the number of bytes to seek 
; from the given whence position. The argument whence can be: 
;	SEEK_SET Seeks from the beginning of the file. 
;	SEEK_CUR Seeks from the current position. 
;	SEEK_END Seeks from the end of the file. 
; On a text stream, whence should be SEEK_SET and offset should 
; be either zero or a value returned from ftell. 
;
; The end-of-file indicator is reset. The error indicator is NOT reset. 
; On success zero is returned. On error a nonzero value is returned. 
	
; Status: Done

	push	ebp
	mov	ebp, esp
	
	push	ebx
	push	edx
	push	esi
	; Step 1: Get the param
	
	mov 	ebx, [ebp + 8]		; FileHandle
	mov	eax, [ebp + 12]		; Offset
	xor	edx, edx		;
	call	_tool.parsefilepointer	;   - Check it
	
	clc
	call	_tool.eof		; Clear EOF
					; Step 2: Set up our call
	mov	ebx, dword [ebx+l4u_FileDescr.file_descr]
	mov	esi, dword [ebx+file_descriptor.op_table]
					;
	;-------------------------------;
	; ESI = OpTable
	; EBX = FIleHandle (UUU)
	; EDX:EAX = Size to seek
	; Stack+0 = Our FileHandle
	;-------------------------------;
					;
	cmp	[ebp + 16], dword SEEK_END
	jne	.not_end		;
					;
	mov	esi, dword [esi+file_op_table.seek_end]
	jmp	.continue		;
  .not_end:				;
  	cmp	[ebp + 16], dword SEEK_CUR
  	jne	.not_cur		;
  	mov	esi, dword [esi+file_op_table.seek_cur]
	jmp	.continue		;
  .not_cur:				;
  	mov	esi, dword [esi+file_op_table.seek_start]
					;
  .continue:				;
  	call	[esi]			; Call!
  					;
  	jc	.error			;
  	xor	eax, eax		; Return zero
  	jmp .done			;
	.error:				;
	call	_tool.seterror		; Set error
					;
	.done:				; <ends>
	pop	esi			;
	pop	edx			;
	pop	ebx			;
	pop	ebp			;
	retn				;
	
fsetpos:				;; int fsetpos(FILE *stream, const fpos_t *pos)	
;					-------------------------------
; Sets the file position of the given stream to the given position.
; The argument pos is a position given by the function fgetpos. 
; The end-of-file indicator is cleared. 
; On success zero is returned. On error a nonzero value 
; is returned and the variable errno is set. 

	push	ebp
	mov	ebp, esp
	
	push	ebx
	push	edx
	push	esi
	; Step 1: Get the param
	
	mov 	ebx, [ebp + 8]		; FileHandle
	mov	eax, [ebp + 12]		; Offset
	mov	eax, [eax]		;   - Get it
	xor	edx, edx		;
	call	_tool.parsefilepointer	;   - Check it
	
	clc
	call	_tool.eof		; Clear EOF
					; Step 2: Set up our call
	mov	ebx, dword [ebx+l4u_FileDescr.file_descr]
	mov	esi, dword [ebx+file_descriptor.op_table]
	mov	esi, dword [esi+file_op_table.seek_start]
	call	[esi]
	
	jc	.error			;
  	xor	eax, eax		; Return zero
  	jmp .done			;
	.error:				;
	call	_tool.seterror		; Set error
					;
	.done:				; <ends>
	pop	esi			;
	pop	edx			;
	pop	ebx			;
	pop	ebp			;
	retn				;


ftell:					;; long int ftell(FILE *stream)
;				 	;------------------------------
; Returns the current file position of the given stream. 
; If it is a binary stream, then the value is the number of bytes from 
;  the beginning of the file. If it is a text stream, then the value is a 
;  value useable by the fseek function to return the file position to the current position. 
; On success the current file position is returned. 
; On error a value of -1 is returned and errno is set. 
					;
; Status: Done				;
					; <start>
	push	ebp			;
	mov	ebp, esp		;
					;   	---
					; Step 1: Get the param
	push	ebx			;
	mov 	ebx, [ebp + 8]		; EBX points to our FileDescr
	call	_tool.parsefilepointer		; Check it
					; 	---
	push	ebx			; Step 2: Set up our call
	mov	ebx, dword [ebx+l4u_FileDescr.file_descr]
	mov	esi, dword [ebx+file_descriptor.op_table]
	mov	esi, dword [esi+file_op_table.seek_cur]
					;
	mov	eax, dword 00h		;
					;
	;-------------------------------;
	; EAX = Amount to read
	; ESI = seek_cur position
	; EBX = File Descriptor for UUU
	;-------------------------------;
					;	---
	call	[esi]			; Step 3: Call seek_cur
	pop	ebx			;
	jnc	.ok			;
	call	_tool.seterr		; Error? Set errorflag & 
	mov	eax, -1			;	 return -1
	.ok:				;
					;
	pop	ebx			; Cleanup
	pop	ebp			;
	retn				; <done>
 ;--------------------------------------;
	
 fopen:					;; FILE *fopen(const char *filename, const char *mode)
; On success a pointer to the file stream is returned. On failure a null pointer is returned. 
; NOTE: Not using mode at all

; Status: Done

	push	ebp
	mov	ebp, esp
	
	; Step 1: Get the param
	push	ebx
	push	esi
	mov 	ebx, [ebp + 8]
	call _tool.parsefilepointer
	mov	esi, ebx
	mov	esi, dword [esi+l4u_FileDescr.file_descr]
	; Step 2: Try to open the file
	externfunc vfs.open
	jc	.error_vfs
	
	call _tool.create_l4uFD
	
	mov	eax, ebx			; Return value
	pop	esi
	pop	ebx
	pop	ebp
	retn
	
	.error_vfs:
	mov	eax, NULL			; Null-pointer
	pop	esi
	pop	ebx
	pop	ebp
	retn
	

fread:		;; size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream)	
;					--------------------------------
; Reads data from the given stream into the array pointed to by ptr. 
; It reads nmemb number of elements of size size. The total number of 
; bytes read is (size*nmemb). 
; On success the number of elements read is returned. On error or 
; end-of-file the total number of elements successfully read (which may be zero) 
; is returned. 

; Status: Done

	push	ebp			;
	mov	ebp, esp		;
					;   	---
					; Step 1: Get the param
	push	ebx			;
	push	edx
	push	edi
	
	mov 	ebx, [ebp + 20]		; EBX points to our FileDescr
	call	_tool.parsefilepointer		; Check it
	mov	edx, [ebp + 12]
	mov	eax, [ebp + 16]
	mul	edx			; 	< 32 bit only!>
	mov	ecx, eax		; ECX = Number of bytes to read
	mov	edi, [ebp + 8]		; EDI = Destination
					; 	---
	push	ebx			; Step 2: Set up our call
	mov	ebx, dword [ebx+l4u_FileDescr.file_descr]
	mov	esi, dword [ebx+file_descriptor.op_table]
	mov	esi, dword [esi+file_op_table.read]
					;
	
					;
	;-------------------------------;
	; ECX = Amount to read
	; EDI = Destination
	; EBX = File Descriptor for UUU
	;-------------------------------;
					;	---
	call	[esi]			; Step 3: Call read
	pop	ebx			;	(save back our own file_desc)
	
	pop	edi
	pop	edx			;
	pop	ebx			; Cleanup
	
	pop	ebp			;
	retn				; <done>
 ;--------------------------------------;


fwrite:			;; size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream)
;					-------------------------
; Writes data from the array pointed to by ptr to the given 
; stream. It writes nmemb number of elements of size size. The 
; total number of bytes written is (size*nmemb). 
; On success the number of elements writen is returned. On error 
; the total number of elements successfully writen (which may be zero) is returned. 


; Status: Done

	push	ebp			;
	mov	ebp, esp		;
					;   	---
					; Step 1: Get the param
	push	ebx			;
	push	edx
	push	edi
	
	mov 	ebx, [ebp + 20]		; EBX points to our FileDescr
	call	_tool.parsefilepointer		; Check it
	mov	edx, [ebp + 12]
	mov	eax, [ebp + 16]
	mul	edx			; 	< 32 bit only!>
	mov	ecx, eax		; ECX = Number of bytes to read
	mov	esi, [ebp + 8]		; ESI = Source
					; 	---
	push	ebx			; Step 2: Set up our call
	mov	ebx, dword [ebx+l4u_FileDescr.file_descr]
	mov	esi, dword [ebx+file_descriptor.op_table]
	mov	esi, dword [esi+file_op_table.write]
					;
	
					;
	;-------------------------------;
	; ECX = Amount to read
	; ESI = Source
	; EBX = File Descriptor for UUU
	;-------------------------------;
					;	---
	call	[esi]			; Step 3: Call write
	pop	ebx			;	(save back our own file_desc)
	
	pop	edi
	pop	edx			;
	pop	ebx			; Cleanup
	
	pop	ebp			;
	retn				; <done>
 ;--------------------------------------;
 
rewind:					;; void rewind(FILE *stream)
;					--------------------------
; Sets the file position to the beginning of the 
; file of the given stream. The error and end-of-file 
; indicators are reset. 
	push	ebp			;
	mov	ebp, esp		;
	
	push	ebx
	push	edx
	push	esi
	
	mov 	ebx, [ebp + 8]
	xor	edx, edx		;
	call	_tool.parsefilepointer	;   - Check it
	
	clc
	call	_tool.eof		; Clear EOF
	call	_tool.clearerr		; Clear Error
					; Step 2: Set up our call
	mov	ebx, dword [ebx+l4u_FileDescr.file_descr]
	mov	esi, dword [ebx+file_descriptor.op_table]
	mov	esi, dword [esi+file_op_table.seek_start]
	call	[esi]
	
	jc	.error			;
  	xor	eax, eax		; Return zero
  	jmp .done			;
	.error:				;
	call	_tool.seterror		; Set error
					;
	.done:				; <ends>
	pop	esi			;
	pop	edx			;
	pop	ebx			;
	pop	ebp			;
	retn				;
	
setbuf:					;; void setbuf(FILE *stream, char *buffer)
; Return nothing
	retn
	
setvbuf:				;; int setvbuf(FILE *stream, char *buffer, int mode, size_t size)
; Return zero
	xor eax, eax
	retn
						;
;-----------------------------------------------;
; Tools
;-----------------------------------------------;
						;
_tool:
.parseerror:
; EBX = Errorcode
;Returns in EBX new errorcode (c-Compat)

.seterror:
.seterr:
; EBX = OurHandle
; EAX = Errornumber of UUU (optional)
	mov dword [ebx+l4u_FileDescr.iserror], 01h
	retn

.clearerr:
; EBX = Ourhandle
	mov dword [ebx+l4u_FileDescr.iserror], 00h
	retn
	
.eof:
; EBX = OurHandle
; CF -> set, otherwise unset
	jc	.eof_set
	mov dword [ebx+l4u_FileDescr.iseof], 00h
	retn
	
	.eof_set:
	mov dword [ebx+l4u_FileDescr.iseof], 01h
	retn
	
.parsefilepointer:				; Includes check for STDIN/STDOUT/STDERR
; EBX = Value given by C app
; out = Corresponding l4u_FileDescr
; Status: Done

	cmp ebx, STDIN
	jne .next1
	mov	ebx, [stdin]
	jmp .done
	
	.next1:
	cmp ebx, STDOUT
	jne .next2
	mov	ebx, [stdout]
	jmp .done
	
	.next2:
	cmp ebx, STDERR
	jne .next3
	mov	ebx, [stderr]
	jmp .done
	
	.next3:
	cmp ebx, NULL
	jne .other_file
	jmp short $				; <TODO>
	
	.other_file:
	.done:
	retn
	
	
.create_l4uFD:
; EBX = File_Descriptor location		; Creates our own struct
; out EBX = l4u_FileDescr
	
	push	ecx
	mov	ecx, l4u_FileDescr_size
	call _tool.malloc
						; Fill up now
	mov dword [ecx+l4u_FileDescr.lasterror], 00h
	mov dword [ecx+l4u_FileDescr.iserror], 00h
	mov dword [ecx+l4u_FileDescr.iseof], 00h
	mov dword [ecx+l4u_FileDescr.cur_pos], 00h
	mov dword [ecx+l4u_FileDescr.file_descr], ebx
	mov	ebx, ecx
	pop	ecx
	retn
	
.destruct_l4uFD:
; EBX = File_Descriptor location		; Kill our own struct	
; 	(perhaps more to come when buffering is here)
	
	push	ebx
	push	esi
	xor	eax, eax
	
	mov	ebx, dword [ebx+l4u_FileDescr.file_descr]
	mov	esi, dword [ebx+file_descriptor.op_table]
	mov	esi, dword [esi+file_op_table.close]
					;
	call	[esi]			; Call UUU!
	pop	ebx
					;
	jnc	.ok			;
	call	_tool.seterr		; Error? Set errorflag & 
	mov	eax, -1			;	 return -1
	.ok:				;
					;
	;-------------------------------;
	; EBX = Our Handle
	;-------------------------------;
					;
	call	_tool.dealloc		; Dealloc our struct
	pop	esi
	retn
	
.malloc:
; ECX = Size needed
; out ECX = Address
	pushad
	externfunc mem.alloc
	jc .malloc_err
	mov ecx, esi
	popad
	retn
	.malloc_err:
	stc
	popad
	jmp $					; HangMeUp <TODO>
	retn

.dealloc:
; EBX = Address
	pushad
	mov	eax, ebx
	externfunc mem.dealloc
	jc .DEalloc_err
	popad
	retn
	.DEalloc_err:
	stc
	popad
	jmp $					; HangMeUp <TODO>
	retn

						;
;-----------------------------------------------;
; Init
;-----------------------------------------------;
						;
global _init_stdio				;
_init_stdio:					; We need to set up STDIN/STDOUT properly
	push	ebx				; in l4u_FileDescr format.
						;     ---
	mov ebx, dword [stdlib_stdin]		; Set up STDIN
	call _tool.create_l4uFD			;
	mov dword [stdin], ebx			;
						;     ---
	mov ebx, dword [stdlib_stdout]		; Set up STDOUT
	call _tool.create_l4uFD			;
	mov dword [stdout], ebx			;
						;     ---
	mov ebx, dword [stdlib_stderr]		; Set up STDERR
	call _tool.create_l4uFD			;
	mov dword [stderr], ebx			;
						;     ---
	pop	ebx				; Clean the stack
	retn					;    
						;    > DONE <
;-----------------------------------------------;
; Cleanup
;-----------------------------------------------;
						;
global _cleanup_stdio				;
_cleanup_stdio:					; Need to release allocated memory for 
	push eax				; STDIN/STDOUT/STDERR
						;  <ToDO>: 	Buffering cleanup
						;
	mov eax,[stdin]				; Cleanup our STDIN stuff
	externfunc mem.dealloc			;
	mov eax,[stdout]			; Cleanup our STDOUT stuff
	externfunc mem.dealloc			;
	mov eax,[stderr]			; Cleanup our STDERR stuff
	externfunc mem.dealloc			;
						;      ---
	pop eax					; Clean the stack
	retn					;
						;    > DONE <
						;
;-----------------------------------------------; ============== CODE ENDS =================
; DATA
;-----------------------------------------------;	
stdin:	dd 0					; STDIN pointer (our format; l4u_FileDescr)
stdout:	dd 0					; STDOUT pointer (our format; l4u_FileDescr)
stderr:	dd 0					; STDERR pointer (our format; l4u_FileDescr)
						;
						;
						;
					;-------
				;-------
		;---------------
;------------------------------------------------------------------------------
;
; Copyright (c) 2002 	Lukas Demetz
; All Rights reserved!
;
;------------------------------------------------------------------------------