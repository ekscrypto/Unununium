;; $Header: /cvsroot/uuu/dimension/cell/lib/buffers/fifo/fifo.asm,v 1.1 2003/01/26 08:32:55 lukas2000 Exp $
;; 
;; Luke's FIFO library		Copyright (C) 2003 Lukas Demetz
;; Unununium OE			Distributed under the BSD license
;;
;; NOTE: Not using (yet) resource pools	  
;;	 Under testing, not sure if it works alright :/ 

[bits 32]

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_



;                                           -----------------------------------
;                                                                        strucs
;==============================================================================
struc fifo_header
	.size:		resd 1	; Size of buffer in bytes
	.used:		resd 1	; Used bytes
	.write_ptr:	resd 1	; Current pointer in buffer relative to .buffer
	.read_ptr:	resd 1	; Current read pointer
	.callb_read:	resd 1	; Read callback
	.callb_write:	resd 1	; Write callback
	.buffer:	resd 0	; Starting of buffer
endstruc
	

section .c_info
	db 0,1,1,"a"
	dd str_title
	dd str_author
	dd str_copyrights

	str_title:
	db "FIFO Library",0

	str_author:
	db "Lukas Demetz <luke@hotel-interski.com>",0

	str_copyrights:
	db "BSD Licensed",0




;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init
global _start
_start:
init:
  %ifdef _DEBUG_
  pushad
  	jmp .huh
   .data:
   	db 1,2,3,4,5,6,7,8,9	
   .buff: db 0,0,0,0,0,0,0,0,0,0,0,0,0
   .callb_read:
    	dbg lprint "Callback read called! EAX:%x ECX:%d EDX:%d", DEBUG, eax, ecx, edx
    	retn
   .callb_write:
    	dbg lprint "Callback write called! EAX:%x ECX:%d EDX:%d", DEBUG, eax, ecx, edx
    	retn
    	
  	.huh:
  	mov eax, 7h
  	mov ecx, 00h
  	call fifo.create
  	dbg lprint "FIFO created, pointer %x", DEBUG, eax
  	lea ecx, [.callb_read]
  	push eax
  	call fifo.set_read_callback
  	pop eax
  	push eax
  	lea ecx, [.callb_write]
  	call fifo.set_write_callback
  	pop eax
  	mov ecx, 3		; 3 bytes
  	lea edx, [.data]	; SOme trash (1,2,3)
  	push eax
  	
  	call fifo.write
  	dbg lprint "FIFO wrote %d bytes", DEBUG, eax
  	pop eax
  	push eax
  	
  	call fifo.get_status
  	dbg lprint "FIFO status: size %d, free %d", DEBUG, ecx, eax
  	pop eax
  	push eax
  	mov ecx, 2
  	lea edx, [.buff]
  	
  	call fifo.read
  	
  	mov ecx, [.buff]
  	dbg lprint "FIFO readen %d bytes: %x",DEBUG, eax, ecx
  	pop eax
  	push eax
  	call fifo.get_status
  	dbg lprint "FIFO status: size %d, free %d", DEBUG, ecx, eax
  	pop eax
  	push eax
  	mov ecx, 6		; 6 bytes (4,5,6,7,8,9)
  	lea edx, [.data+2]	; SOme trash
  	call fifo.write
  	dbg lprint "FIFO wrote %d bytes", DEBUG, eax
  	pop eax
  	push eax
  	call fifo.get_status
  	dbg lprint "FIFO status: size %d, free %d", DEBUG, ecx, eax
  	pop eax
  	
  	mov ecx, 5
  	mov [.buff], dword 00h
  	mov [.buff+4], dword 00h
  	lea edx, [.buff]
  	call fifo.read
  	mov ebx, [.buff]
  	mov ecx, [.buff+3]
  	dbg lprint "FIFO readen %d bytes: %x %x",DEBUG, eax, ebx, ecx
  	clc
 	popad
  	%endif
  
  retn




;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text


;                                           -----------------------------------
;                                                                  fifo.create
;==============================================================================
globalfunc fifo.create
;> Requests the creation of a FIFO structure.
;;
;;  parameters:
;;    eax: size of FIFO buffer
;;    ecx: resource pool
;;
;;  returns:
;;    eax: pointer to FIFO structure
;<
   push ecx
   
   mov ecx, eax
   add ecx, fifo_header_size
   push eax
   dbg lprint "FIFO: Requesting %x bytes of memory", DEBUG, ecx
   externfunc mem.alloc
   pop eax
   jc .err_memalloc
   ; EDI = Base of our block
   dbg lprint "FIFO: Got memory block at %x", DEBUG, edi
   mov [edi+fifo_header.size], dword eax
   mov [edi+fifo_header.used], dword 00h
   mov [edi+fifo_header.write_ptr], dword 00h
   mov [edi+fifo_header.read_ptr], dword 00h
   mov [edi+fifo_header.callb_read], dword 00h
   mov [edi+fifo_header.callb_write], dword 00h
   
   mov eax, edi
   pop ecx
   retn
   
   .err_memalloc:
   stc
   mov eax, __ERROR_INSUFFICIENT_MEMORY__
   dbg lprint "FIFO: Memalloc error!", DEBUG
   pop ecx
   retn
   
;                                           -----------------------------------
;                                                                 fifo.destroy
;==============================================================================
globalfunc fifo.destroy
;> Requests the destruction of a FIFO structure and its associated buffer.
;;
;;  parameters:
;;    eax: pointer to FIFO structure to destroy
;;
;;  returns:
;;    errors and registers as usual
;<
   test eax, eax			; Check FIFO
   jz .err_param			;
   externfunc mem.dealloc		; Dealloc it
   retn					;
   					;
   .err_param:				; -----------------
   stc					;
   mov eax, __ERROR_INVALID_PARAMETERS__;
   retn					;
   					;
;                                           -----------------------------------
;                                                                    fifo.read
;==============================================================================
globalfunc fifo.read
;> Attempt to read a specified number of bytes from FIFO
;;
;;  parameters:
;;    eax: pointer to FIFO structure
;;    ecx: number of bytes to attempt to read
;;    edx: destination buffer
;;
;;  returns:
;;    eax: number of bytes read
;<
   
   
   test eax, eax			; Check given FIFO
   jnz .okk_go				;
   	mov eax, __ERROR_INVALID_PARAMETERS__; Error
   	stc				; Carry <- Error
   	dbg lprint "FIFO-r: Error", DEBUG	;
   	retn				;
   					;
 .okk_go:				; --------------------- 
   push ebx
   mov ebx, dword [eax+fifo_header.size];
   dbg lprint "FIFO structure is %x bytes in size", DEBUG, ebx
   cmp ecx, ebx				; Requested read bigger than buffer !?
   jbe .ok_go				; 
   	mov eax, __ERROR_INVALID_PARAMETERS__; Error
   	pop ebx				; Cleanup
   	stc				; Carry <- Error
   	dbg lprint "FIFO-r: Error, read too big", DEBUG
   	retn				; Adieu
   					;
   .ok_go:				; -----------------
   push esi				;
   push edi				;
   dbg lprint "FIFO-r: First check ok",DEBUG;
   mov ebx, dword [eax+fifo_header.used]; EBX = Bytes in buffer
   mov esi, ebx
   cmp ecx, ebx				; Enough bytes there?
   ja .ok_go2				;
   					;
   mov ebx, ecx				; Go With max. value
   .ok_go2:				;
   sub esi, dword [eax+fifo_header.read_ptr]
   ; ESI = Bytes till buffer end
   xor edi, edi
   dbg lprint "FIFO-r: Round check",DEBUG
   cmp ebx, esi
   
   jb .normal_call
   dbg lprint "FIFO-r: ROund mode on",DEBUG
   mov edi, ebx				; Save total bytes
   sub edi, esi				; Save remaining bytes for round
   mov ebx, esi				; Set bytes to read
   
   .normal_call:
   
   ;------------------------------------;
   ; EAX = Pointer to FIFO
   ; EBX = Amount of bytes to read
   ; EDX = Destination 
   ;------------------------------------;
   push edi
   mov ecx, ebx				; Amount of bytes
   dbg lprint "Gonna read %x bytes", DEBUG, ecx
   mov edi, edx				; Destination
   lea esi, [eax+fifo_header.buffer]	; Source-> FIFO
   add esi, [eax+fifo_header.read_ptr]	; Add read offset
   cld
   rep movsb				; Do the move
   
   pop ecx
   test ecx, ecx			; Need roundbuffer?
   jz .skip_round
   
   add ebx, ecx				; Take from used bytes
   lea esi, [eax+fifo_header.buffer]	; Target-> FIFO
   dbg lprint "RoundRead: %d bytes, starting at EDI:%x, ESI:%x",DEBUG,ecx, edi, esi
   cld
   rep movsb				; Do the roundmove

  .skip_round:
   sub esi, eax
   sub esi, fifo_header.buffer
   mov dword [eax+fifo_header.read_ptr], esi
   mov esi, dword [eax+fifo_header.used]; Update used bytes
   sub esi, ebx				;
   mov dword [eax+fifo_header.used], esi;
  					; -----------------------
   					;
   mov esi, dword [eax+fifo_header.callb_read]
   test esi, esi			; Is there a callback?
   jz .nocall				;	
   pushad				; Prepare for callback call
   mov edx, dword [eax+fifo_header.size];
   mov ecx, edx				;
   sub ecx, dword [eax+fifo_header.used]; Set up passed values
   ;------------------------------------;
   ; EAX = ptr to FIFO
   ; ECX = Free bytes
   ; EDX = Size of FIFO buffer
   ;------------------------------------;
   call esi				; Call!
   popad				; Cleanup
   					;
   .nocall:				; ----------------
   mov eax, ebx				; Readen bytes
   					;
   pop edi				; Cleanup
   pop esi				;
   pop ebx				;
   
   retn
   
;                                           -----------------------------------
;                                                                   fifo.write
;==============================================================================
globalfunc fifo.write
;> Attempt to write a specified number of bytes to a FIFO
;;
;;  parameters:
;;    eax: pointer to FIFO structure
;;    ecx: number of bytes to attempt to write
;;    edx: source buffer
;;
;;  returns:
;;    eax: number of bytes written
;<
   test eax, eax			; Check given FIFO
   jnz .okk_go				;
   	mov eax, __ERROR_INVALID_PARAMETERS__; Error
   	stc				; Carry <- Error
   	dbg lprint "FIFO-w: Error", DEBUG	;
   	retn				;
   					;
 .okk_go:				; ---------------------   
   push ebx				;
   					;
   mov ebx, dword [eax+fifo_header.size];
   dbg lprint "FIFO structure is %x bytes in size", DEBUG, ebx
   cmp ecx, ebx				; Requested write bigger than buffer !?
   jbe .ok_go				; 
   	mov eax, __ERROR_INVALID_PARAMETERS__; Error
   	pop ebx				; Cleanup
   	stc				; Carry <- Error
   	dbg lprint "FIFO-w: Error, write too big", DEBUG
   	retn				; Adieu
   					;
   .ok_go:				; -----------------
   push esi				;
   push edi				;
   dbg lprint "FIFO-w: First check ok",DEBUG;
   sub ebx, dword [eax+fifo_header.used]; EBX = Free space in buffer
   mov esi, ebx				; ESI = Available space
   dbg lprint "FIFO-w: Avail bytes %d, want to write %d",DEBUG, ebx,ecx
   cmp ebx, ecx				; Enough space there?
   jb .ok_go2				;
   					;
   mov ebx, ecx				; Go With max. value
   .ok_go2:				;
   dbg lprint "FIFO-w: 2nd check ok",DEBUG
   sub esi, dword [eax+fifo_header.write_ptr]
   ; ESI = Bytes till buffer end
   xor edi, edi
   dbg lprint "FIFO-w: Round check req.write:%d, till end %d",DEBUG, ebx, esi
   cmp ebx, esi
   
   jb .normal_call
   dbg lprint "FIFO-w: ROund mode on",DEBUG
   mov edi, ebx				; Save total bytes
   sub edi, esi				; Save remaining bytes for
   mov ebx, esi				; Set bytes to write
   
   .normal_call:
   ;------------------------------------;
   ; EAX = Pointer to FIFO
   ; EBX = Amount of bytes to write
   ; EDX = Source 
   ; EDI = Bytes remaining for roundbuffer
   ;------------------------------------;
   push edi
   mov ecx, ebx				; Amount of bytes
   mov esi, edx				; Source
   lea edi, [eax+fifo_header.buffer]	; Target-> FIFO
   add edi, [eax+fifo_header.write_ptr]	; Add write offset
   push edi
   mov edi, [eax+fifo_header.write_ptr]
   dbg lprint "Writepointer is %x", DEBUG, edi
   pop edi
   cld
   rep movsb				; Do the move
   
   
   pop ecx
   test ecx, ecx			; Need roundbuffer?
   jz .skip_round
   
   add ebx, ecx				; Add to used bytes
   lea edi, [eax+fifo_header.buffer]	; Target-> FIFO
   dbg lprint "RoundWrite: %d bytes, starting at EDI:%x, ESI:%x",DEBUG,ecx, edi, esi
   cld
   rep movsb				; Do the roundmove

  .skip_round:
  dbg lprint "FIFO-w: Updating data",DEBUG
   mov esi, dword [eax+fifo_header.used]; Update used bytes
   add esi, ebx				;
   mov dword [eax+fifo_header.used], esi;
   sub edi, eax
   sub edi, fifo_header.buffer
   dbg lprint "Writepointer is %x", DEBUG, edi
   mov dword [eax+fifo_header.write_ptr], edi ; Write pointer
   					;
   mov esi, dword [eax+fifo_header.callb_write]
   dbg lprint "FIFO-w: Next: Callb",DEBUG
   test esi, esi			; Is there a callback?
   jz .nocall				; Nope -> Jump
   					; 
   pushad				; Prepare for callback call
   mov ebx, dword [eax+fifo_header.used]; Set up passed values
   mov ecx, dword [eax+fifo_header.size];
   ;------------------------------------;
   ; EAX = ptr to FIFO
   ; EBX = Available Bytes for read
   ; ECX = Total bytes
   ;------------------------------------;
   dbg lprint "Ready to call write callback at %x", DEBUG, esi
   
   call esi				; Call!
   popad				; Cleanup
   					;
   .nocall:				; ----------------
   mov eax, ebx				; Readen bytes
   					;
   pop edi				; Cleanup
   pop esi				;
   pop ebx				;
   retn					;
   
;                                           -----------------------------------
;                                                              fifo.get_status
;==============================================================================
globalfunc fifo.get_status
;> Get the current usage statistics of a FIFO
;;
;;  parameters:
;;    eax: pointer to FIFO structure
;;
;;  returns:
;;    eax: number of bytes available in the FIFO
;;    ecx: total size in bytes of the FIFO
;<
   test eax, eax			; Check given FIFO
   jnz .ok_go				;
   	mov eax, __ERROR_INVALID_PARAMETERS__; Error
   	stc				; Carry <- Error
   	dbg lprint "FIFO-gs: Error", DEBUG	;
   	retn				;
   					;
 .ok_go:				; ---------------------
   push ebx				; 
   mov ecx, dword [eax+fifo_header.size]; Get size of FIFO
   mov ebx, eax				; Save pointer
   mov eax, ecx				; size -> EAX
   sub eax, dword [ebx+fifo_header.used]; Subtract used bytes from size
   pushad
   mov eax, dword [ebx+fifo_header.write_ptr]
   mov ebx, dword [ebx+fifo_header.read_ptr]
   dbg lprint "WritePTR %x, ReadPTR %x", DEBUG, eax, ebx
   popad
   pop ebx				; Cleanup
   
   retn					;
   					;
;                                           -----------------------------------
;                                                       fifo.set_read_callback
;==============================================================================
globalfunc fifo.set_read_callback
;> Set (or unset) a callback function for incoming data. This function will be 
;; called automatically everytime data is written to the FIFO.
;;
;;  parameters:
;;    eax: pointer to FIFO structure
;;    ecx: pointer to callback function (0 to unset)
;;
;;  returns:
;;    errors and registers as usual
;;
;; The callback function will receive the following information:
;;
;;    eax: pointer to a FIFO structure
;;    ecx: number of bytes available for read in the FIFO
;;    edx: total size in bytes of the FIFO
;; The callback function may destroy all general purpose registers except ESP.
;<
   test eax, eax			; Check given FIFO
   jnz .ok_go				;
   	mov eax, __ERROR_INVALID_PARAMETERS__; Error
   	stc				; Carry <- Error
   	dbg lprint "FIFO-sr: Error", DEBUG	;
   	retn				;
   					;
 .ok_go:				; ---------------------
   mov [eax+fifo_header.callb_write], ecx; Set the callback
   dbg lprint "SetRead callback %x", DEBUG, ecx
   mov edx, dword [eax+fifo_header.size]; Get size of FIFO
   mov ecx, dword [ebx+fifo_header.used]; Get used bytes
   retn					;
					;
;                                           -----------------------------------
;                                                      fifo.set_write_callback
;==============================================================================
globalfunc fifo.set_write_callback
;> Set (or unset) a callback function for outgoing data. This function will be 
;; called automatically everytime data is read from the FIFO.
;;
;;  parameters:
;;    eax: pointer to FIFO structure
;;    ecx: pointer to callback function (0 to unset)
;;
;;  returns:
;;    errors and registers as usual
;; The callback function will receive the following information:
;;
;;    eax: pointer to a FIFO structure
;;    ecx: number of free bytes available for write to the FIFO
;;    edx: total size in bytes of the FIFO
;; The callback function may destroy all general purpose registers except ESP.
;<
   test eax, eax			; Check given FIFO
   jnz .ok_go				;
   	mov eax, __ERROR_INVALID_PARAMETERS__; Error
   	stc				; Carry <- Error
   	dbg lprint "FIFO-sw: Error", DEBUG	;
   	retn				;
   					;
 .ok_go:				; ---------------------
   mov [eax+fifo_header.callb_read], ecx; Set the callback
   dbg lprint "SetWrite callback %x", DEBUG, ecx
   mov edx, dword [eax+fifo_header.size]; Get size of FIFO
   mov ecx, edx				;
   sub ecx, dword [ebx+fifo_header.used]; Get free/available bytes
   retn					;
