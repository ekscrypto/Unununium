;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;sonar sound system 				         (c) 2002, Niklas Klügel
;soundblaster driver (development-version)         Distributed under BSD-License
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; USE: 
; - highly non-optimized soundblaster cell.
; - should work with all OPL3 based adaptors (isa), i.e. SB-clones          
; - 8bit functions may work with OPL2 based cards
;    
; TODO:
; - test, test, test
; - optimize globalfuncs (most is just copy&paste) + dsp_read/write (timing) 
; - functions for various settings
; - DevFS support 
; - finish all play functions , sb10 8bit!// do record functions!
;
; STATUS:
; - instable
; - development-version
%include "vid/timer.inc"
%include "vid/sound.inc"

[bits 32]

section .c_info

db 0,0,1,'a'
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "sonar sound system - soundblaster (compatible)",0
str_author: db "Niklas Klügel",0		;
str_copyright: db "BSD-License",0		;
						;
;-----------------------------------------------;
; *****************				
;  initialisation				
; *****************		
;-----------------------------------------------;
						;		
section .c_init					; [.C_INIT]
starthere:
	pushad
	lprint {"[sonar sound system]: SB16 driver version $Revision: 1.4 $.",0xa}, DEBUG
detect_sb_base_io:				;			
	xor edx , edx				; We detect the sb`s base i/o address by simply 
	mov dx  , [sb.base_io]			; trying to reset the dsp on common base i/o-s.
	.search_base_io:			;
		add edx , byte 6		;
						; send 1 to dsp_reset_port (2X6h)
		mov al  , byte 1		;
		out dx  , al			;
						; since there is a little delay (3 micro-secs) 
		mov ecx, 220			; until the byte is sent, we need to wait;
		call _tools.timed_delay		;
						; send 0 to dsp_reset_port (2X6h)
		xor eax , eax			;
		out dx  , al			;
						; the dsp needs around 100 micro-seconds to reset
		mov ecx , 6600			;
		call _tools.timed_delay		;
		add edx , byte 4 		;(2xAh)		
		in al , dx			;
		cmp al , 0xAA			;
		je .found			;
		sub dx , 0xA			;
		cmp dx , 0x280			;
		je .failure			;
		add dx , 0x10			;
		jmp .search_base_io		;
						;
	.failure:				;
	lprint {"[sonar sound system] SoundBlaster or compatible card not found!", 0x0A}, FATALERR		; Failed :/
	popad					; Adieu
	retn					;
						;
  						;
	.found:					; Found! :)
	 dbg lprint {"[sonar sound system] Soundblaster or compatible card successfully found! Port %d",0xa}, DEBUG, edx
	mov [sb.base_io], dx			;
						;	
						; Let`s get the dsp vers.
		mov al , 0xE1			; request dsp-version
		call _dsp.write			;
		call _dsp.read			;
		mov ah , al 			;
		call _dsp.read			;
		mov [sb.dsp_vers] , ax		;
		mov dx , ax			;
		dbg lprint {0x0A ,"DSP-Version: %d",0xa}, DEBUG, edx
		cmp ah , 4			;
		je .sb16			;
		dbg lprint {0x0A ,"[sonar sound system] Sounddevice seems not to be SoundBlaster16 (or above) compatible. Trying given standard configuration: ",0xa}, DEBUG
		popad
		retn				;
						;
	.sb16:					; - get IRQ / DMA 
	mov dx , [sb.base_io]			;
	add dx , 04h 				; mixer register port
	mov ax, 80h
	out dx , ax 				; IRQ select
	mov edx, 6600				;
	call _tools.timed_delay			;
	add dx , 01h				;
	in ax, dx 				;
		test dl , 1			;
		jnz .test_irq_5			;
		mov [sb.irq] , byte 2		;
		jmp .get_dma			;
		.test_irq_5:			;
		test dl , 2			;
		jnz .test_irq_7			;
		mov [sb.irq] , byte 5		;
		jmp .get_dma			;
		.test_irq_7:			;
		test dl , 4			;
		jnz .test_irq_10		;
		mov [sb.irq] , byte 7		;
		jmp .get_dma			;
		.test_irq_10:			;
		mov [sb.irq] , byte 10		;
						;
	.get_dma:				;
	mov dx , [sb.base_io]			;
	add dx , 04h 				; mixer register port
	mov ax, 81h				;
	out dx , ax 				; DMA select
	mov edx, 6600				;
	call _tools.timed_delay			;
	add dx , 01h				;
	in ax  , dx 				;
	mov bl  , 0				;
	mov ecx , 4				;
						;
	.8_bit_dma:				;
		test dl , bl			;
		je .8_bit_dma_found		;
		inc bl				;
		loop .8_bit_dma			;
	.8_bit_dma_found:			;
		mov [sb.dma8] , bl 		;
		mov ecx , 4			;
						;
	.16_bit_dma:				;
		test dl , bl			;
		je .end				;
		inc bl				;
		loop .16_bit_dma		;
						;
	.end:					;
	mov [sb.dma16] , bl			;
	mov edx , [sb.irq]			;
	dbg lprint {0x0A ,"	IRQ : %d",0xa}, DEBUG, edx
	mov edx , [sb.dma8]			;
	dbg lprint {0x0A ,"8-Bit DMA : %d",0xa}, DEBUG, edx
	mov edx , [sb.dma16]			;
	dbg lprint {0x0A ,"16-Bit DMA : %d",0xa}, DEBUG, edx
						;
	;---------------------------------------;
	; *********************
	;   set environment up
	; *********************
	;---------------------------------------;
						;
setup_environment:				;
						;  allocate 64kbyte below 16Mbyte barrier
	mov ecx , 131072			;  as DMA buffer; problem: the block has
	xor edx , edx				;  to be aligned with page addressing.
	externfunc mem.alloc_20bit_address	;
	cmp eax , ecx				;
	je .mem_allocated			;
		lprint {"[sonar sound system]: insufficient memory",0xa}, FATALERR
		popad
		retn				;
	.mem_allocated:				;
	mov eax , [edi+0xFFFF]			;
	and eax , 0xFFFF0000			;
	mov [sb.dma_buffer], eax		;
	shr eax , 16				;
	mov [sb.page_no],al			;
						; do some calculations,so we`ll save
						; some cycles at runtime:
						; Calc 16bitDMA-channel register (taken 
						;  from "DMA Tutorial by Tom Marshall)
	mov     dx,0A9BFh               	; *Magic DMA page reg convert
        mov     cl,[sb.dma16]           	;  for DMA 4..7
        shl     cl,2                    	;  	DMA4 => 8Fh
        shr     dx,cl                   	;  	DMA5 => 8Bh
        and     dx,0000Fh               	;  	DMA6 => 89h
        add     dx,00080h               	;  	DMA7 => 8Ah
	mov [sb.dma16_reg],dx			;
						;
						; Calc 8bitDMA-channel register (taken 
						;  from "DMA Tutorial by Tom Marshall)
 	mov     dx,2137h                	; *Magic DMA page reg convert
        mov     cl,[sb.dma8]            	;  for DMA 0..3
        shl     cl,2                    	;  	DMA0 => 87h
        shr     dx,cl                   	;  	DMA1 => 83h
        and     dx,0000Fh               	;  	DMA2 => 81h
        add     dx,00080h               	;  	DMA3 => 82h
	mov [sb.dma8_reg],dx			;
						;
						; Hook the irq
	mov 	al, byte [sb.irq]		;	- AL  = irq number 
	lea	esi, [_irq_handler]		; 	- ESI = pointer to client to hook
	externfunc int.hook_irq			;
	jnc	.hook_ok			;
		lprint {"[sonar sound system]: IRQ not allocated",0xa}, FATALERR
		popad
		retn				;
						;
  .hook_ok:					;
	lprint {"[sonar sound system]: SB16 ready.",0xa}, DEBUG	
  popad						;
retn						; / Done INIT
						;
section .text					; [.TEXT]
;-----------------------------------------------;
;   	**************************
;            global functions
; 	**************************
;-----------------------------------------------;
; NOTE:
; -----
; This is how the command-byte, used in all 16bit modes by the dsp 
; looks:
; COMMAND BYTE
; ÉÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍ
; º(7)³(6)³(5)³(4)³ 3 ³ 2 ³ 1 ³[0]
; ÈÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍ
; ³   ³   ³   ³   ³   ³   ³   ÀÄÄÄ Reserved (0)
; ³   ³   ³   ³   ³   ³   ÀÄÄÄÄÄÄÄ FIFO Mode (0 = Disable, 1 = Enable)
; ³   ³   ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄ DMA Mode  (0 = Single, 1 = Auto-Init)
; ³   ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Transfer Mode (0 = DAC, 1 = ADC)
; ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
; ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄ Sampling Resolution
; ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´   1011b = 16-bit, 1100b = 8-bit
; ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
; This is the mode-byte which is a parameter (always al) and written 
; directly to the dsp: 
; MODE BYTE
; ÉÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍ»
; º[7]³[6]³ 5 ³ 4 ³[3]³[2]³[1]³[0]º
; ÈÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍÏÍÑÍ¼
; ³   ³   ³   ³   ³   ³   ³     ÀÄÂÄ Reserved (0)
; ³   ³   ³   ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄ´
; ³   ³   ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄ´
; ³   ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
; ³   ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Sample Mode (0 = Unsigned, 1 = Signed)
; ³   ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Stereo Mode (0 = Monaural, 1 = Stereo)
; ³   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄ Reserved (0)
; ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;-----------------------------------------------;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
						;
globalfunc sound.play_shot_16bit_fifo		;
						;
;-----------------------------------------------
; plays a single sound via 16bit DMA by using FIFO mode,
; suggested for high-speed transfer and large data-transfers
; 
; esi - pointer to soundblock (64kbyte max.)
;       somewhere in memory
; ecx - size (WORDS)
;  al - mode-byte 
;
; Todo : 
; Terminate transfer.
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;             copy&paste
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;-----------------------------------------------;
mov byte [sb.mode_byte], 01011010b		;
call sound.play_shot_16bit			;
retn						;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
						;
globalfunc sound.play_shot_16bit		;
						;
;-----------------------------------------------;
; plays a single sound via 16bit DMA
; 
; esi - pointer to soundblock (64kbyte max.)
;       somewhere in memory
; ecx - size (words)
;  al - mode-byte 
;
; Todo : 
; Terminate transfer.
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;             copy&paste
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;-----------------------------------------------;
mov byte [sb.mode_byte], 01011000b		;
call sound.play_shot_16bit			;
retn						;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
						;
globalfunc sound.stream_16bit			;
						;
;-----------------------------------------------;
; streams via 16bit DMA, using a callback 
; function
; edx - pointer to callbackfunction
;  al - mode-byte 
;
;-----------------------------------------------;
; 
; the callback function:
; is called when the buffer needs to be refilled,
; it has to return these parameters:
; esi - pointer to soundblock (64kbyte max.)
;       somewhere in memory
; ecx - size (WORDS)
;
;-----------------------------------------------;
						;
mov byte [sb.command_byte],01011100b			;
call _sb_stream_16bit				;
retn						;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
						;
globalfunc sound.stream_16bit_fifo		;
						;
;-----------------------------------------------;
; streams via 16bit DMA, using a callback 
; function (FIFO mode,suggested for
; high-speed transfer and large
; data-transfers)
;
; edx - pointer to callbackfunction
;  al - mode-byte 
;
;-----------------------------------------------;
; 
; the callback function:
; is called when the buffer needs to be refilled,
; it has to return these parameters:
; esi - pointer to soundblock (64kbyte max.)
;       somewhere in memory
; ecx - size (WORDS)
;
;-----------------------------------------------;
						;
mov byte [sb.command_byte],01011110b		;
call _sb_stream_16bit				;
retn						;
						;
globalfunc sound.play_shot_8bit_compat		;
;-----------------------------------------------;
; plays a single sound via 8bit DMA (SB and up)
; 
; esi - pointer to soundblock (64kbyte max.)
;       somewhere in memory
; ecx - size (BYTES)
;
;-----------------------------------------------;
mov dword [callback], 00h			;
mov ebx , ecx					;
mov edi , [sb.dma_buffer]			;
repz movsb					;
						;
mov al,[sb.dma8]				;
and al,3					;
or  al,100b					;
out 0xa , al					;
						;
xor al,al                   			;Reset byte F/F
out 0Ch,al					;
						;
mov al,0x48                   			;Set mode
out 0Bh,al					;
						;
						;set page	
mov al , [sb.page_no]				;
mov dx , [sb.dma8_reg]				;
out dx , al					;
						;
						;set offset in page		
						; port = channel*2
mov dl, [sb.dma8]				;
shl dl , 1					;
push ax
xor ax, ax
out dx ,ax					;
pop ax
						;	
						; set block lenght
						; port = channel*2+1
inc dl						;
dec ebx 					;
mov al, bl					;
out dx , al					;
mov al , bh					;
out dx , al					;
						;
						; enable channel		
mov al , [sb.dma8]				;
and al,3					;
out 0xA,al					;
						;
mov byte [sb.dma_mode] , 8				;
						;
mov al , 0x14 					; dma dac 8bit command		
call _dsp.write					;
mov al , bl					;
call _dsp.write					;
mov al , bh					;
call _dsp.write					;
retn						;
						;
						;
						;
						;
globalfunc sound.stream_8bit			; NOT READY!
;-----------------------------------------------;
; streams sound via 8bit DMA (SB and up), using 
; a callback function (FIFO mode,suggested for
; high-speed transfer and large
; data-transfers)
;-----------------------------------------------;
; 
; the callback function:
; is called when the buffer needs to be refilled,
; it has to return these parameters:
; edx - pointer to callbackfunction 
; esi - pointer to soundblock (64kbyte max.)
;       somewhere in memory
; ecx - size (BYTES)
;
;-----------------------------------------------;
mov [callback],edx				;
call _irq_handler				;
						;
mov al,[sb.dma8]				;
and al,3					;
or  al,100b					;
out 0xa , al					;
						;
xor al,al                   			;Reset byte F/F
out 0Ch,al					;
						;
mov al,0x58                   			;Set mode
add al , [sb.dma8]
out 0Bh,al					;
						;
						;set page	
mov al , [sb.page_no]				;
mov dx , [sb.dma8_reg]				;
out dx , al					;
						;
						;set offset in page		
						; port = channel*2
mov dl, [sb.dma8]				;
shl dl , 1					;
push ax
xor ax, ax
out dx , ax					;
pop ax
						;	
						; set block lenght
						; port = channel*2+1
inc dl						;
dec ebx 					;
mov al, bl					;
out dx , al					;
mov al , bh					;
out dx , al					;
						;
						; enable channel		
mov al , [sb.dma8]				;
and al,3					;
out 0xA,al					;
						;
mov byte [sb.dma_mode] , 8				;
						;
mov al , 0x14 					; dma dac 8bit command		
call _dsp.write					;
mov al , bl					;
call _dsp.write					;
mov al , bh					;
call _dsp.write					;
retn						;
						;
						;
						;
;-----------------------------------------------;
;
; IRQ- Handler
;
;-----------------------------------------------;
dd 0,0 						; for ICS channel
_irq_handler:					;
   ; pushad - i am not sure about tha		; Save the registers
    						;
cmp dword [callback] , 0 			;if !0 , then it is pointing to a callbackfunction				;
je .single_transfer				;
cmp byte [sb.dma_mode] , 8				;
jne .16bit_stream				;
call [callback]					;
mov edi , [sb.dma_buffer]			;
repz movsb					;
.16bit_stream:					;
call [callback]					;
mov edi , [sb.dma_buffer]			;
repz movsw					;
retn						;
						;
.single_transfer:				;
cmp byte [sb.dma_mode] , 8			;
jne .16_bit_dma_transfer			;
mov dx , [sb.base_io]				;
add dx , 0Eh ; IRQ_ack-port			;
xchg ax, dx
in ax  , dx					;
xchg ax, dx
retn						;
.16_bit_dma_transfer:				;
mov dx , [sb.base_io]				;
add dx , 0Fh ; IRQ_ack-port			;
xchg ax, dx
in ax  , dx					;
xchg ax, dx
 						;
    						;
    ;popad - i am not sure about that		; Pop the registers
    retn					;
						;
						;
;-----------------------------------------------;
; **************************
;     internal functions
; **************************
;-----------------------------------------------;
						;
						;					_sb_single_shot_16bit:				;
mov byte [sb.mode_byte],al			;
mov dword [callback] , 0			;
mov ebx , ecx					;
mov edi , [sb.dma_buffer]			;
repz movsw					;
						;
;-----------------------------------------------;
; soundblock should be now in our
; piece of memory bellow the 16MByte 
; barrier 
;-----------------------------------------------;
						; -------------------------
						; Add 1... disable dma channel
mov al,[sb.dma16]				;
and al,3					;
or  al,100b				        ;
out 0xD4,al					; -------------------------
						; Add 2... reset byte F/F
xor al,al					;
out 0xd8,al					; -------------------------
						; Add 3... set mode (single read)						;
mov al,0x48					;
add al , [sb.dma16]				;
out 0xd6,al					; -------------------------
						; Add 4... set page
mov al,[sb.page_no]				;
mov dx,[sb.dma16_reg]				;
out dx,al					; -------------------------
						; Add 5... set offset in page
						;  port = channel*4+0xc
mov dl,[sb.dma16]				;
shl dl, 2					;
add dl, 0Ch					;
xor ax, ax					;
out dx, ax   					; 0 because we transfer the whole page
						; -------------------------
						; Add 6... set block length
						;  port = channel*4+0xC+1 
inc dx						;
dec ebx						;
mov al, bl					;
out dx, al					;
mov al, bh					;
out dx, al					;
						; -------------------------
						; Add 7... enable channel
mov al,[sb.dma16]				;
and al,3					;
out 0xA,al					;
mov byte [sb.dma_mode] , 16			; -------------------------
						;Add 8.. enable transfer on SB
mov al , [sb.command_byte] 			;
call _dsp.write					;
mov al , [sb.mode_byte] 			;
call _dsp.write					;
mov al , bl					;
call _dsp.write					;
mov al , bh					;
call _dsp.write					;
retn						;
						;					
;------------------------------------------------
;
;------------------------------------------------
						;
_sb_stream_16bit:				;	
mov [sb.mode_byte],al				;
mov [callback], edx				;
call _irq_handler				;
						;
						; -------------------------
						; Add 1... disable dma channel
mov al,[sb.dma16]				;
and al,3					;
or  al,100b				        ;
out 0xD4,al					;
						;
						;Add 2... reset byte F/F
xor al,al					;
out 0xd8,al					;
						;
						;Add 3... set mode (auto-initialized playback)
mov al,0x58
add al , [sb.dma16]				;
out 0xd6,al					;
						;
						;Add 4... set page
mov al,[sb.page_no]				;
mov dx,[sb.dma16_reg]				;
out dx,al					;
						;
						;Add 5... set offset in page
						; port = channel*4+0xc
mov dl,[sb.dma16]				;
shl dl, 2					;
add dl, 0xC					;
xor ax, ax					;	
out dx, ax					;	
						;	
						;Add 6... set block length
						; port = channel*4+0xC+1 
inc dx						;
dec ebx						;
mov al, bl					;	
out dx, al					;
						;
mov al, bh					;
out dx, al					;
						;
						;Add 7... enable channel
mov al,[sb.dma16]				;
and al,3					;
out 0xA,al					;
mov byte [sb.dma_mode] , 16			;
						;Add 8.. enable transfer on SB
mov al , [sb.command_byte]			;
call _dsp.write					;
mov al , [sb.mode_byte] 			;
call _dsp.write					;
mov al , bl					;
call _dsp.write					;
mov al , bh					;
call _dsp.write					;
retn						;
						;					
;------------------------------------------------
;
;------------------------------------------------
						;
						;
_dsp:						; Functions to access the DSP
  .write:					;
  ;; 
  ;; AL = dsp command
  ;;
  push esi 
  push edx 
  push ecx 
  push ebx
  push eax
  mov dx , [sb.base_io]
  add dx , 0x0C					; dsp write-port
  mov ebx , 100
 .wait_for_dsp_readyw:
						; same 100micro-seconds for dsp to come ready
  mov ecx , 70
  call _tools.timed_delay
  in al , dx
  test al , 80h
  jz .dsp_readyw
  cmp ebx , 0
  dec ebx
  jne .wait_for_dsp_readyw
  stc
  dbg lprint {"[sonar sound system] DSP-Write command timed out!", 0x0A}, DEBUG
  pop eax
  pop ebx
  pop ecx
  pop edx
  pop esi
  retn
  
  .dsp_readyw:
  pop eax
  out dx , al
  pop ebx
  pop ecx
  pop edx
  pop esi
  retn

  .read:
  ;;
  ;; al = byte read from dsp
  ;;
  push edx 
  push ecx
  push ebx
  push esi 
  mov dx,[sb.base_io]
  add dx, 0xE
  mov ebx , 100
  .wait_for_dsp_readyr:
						; same 100micro-seconds for dsp to come ready
  mov ecx , 70
  call _tools.timed_delay
  in al , dx
  test al , 80h
  jz .dsp_readyr
  cmp ebx , 0
  dec ebx
  jne .wait_for_dsp_readyr
  stc
  dbg lprint {"[sonar sound system] DSP-Read command timed out!", 0x0A}, DEBUG
  pop esi
  pop ebx
  pop ecx
  pop edx
  retn
  
 .dsp_readyr:
  sub dx , 4
  in  al , dx
  pop esi
  pop ebx
  pop ecx
  pop edx
  retn

;-----------------------------------------------;
; Nice tools we could need			
;-----------------------------------------------;	
_tools:						;
						; --------------------------
  .timed_delay:					; Waits for given time and returns
  ; in: ECX= Ticks to wait			;
  ;						; Set the timer up
  ;						;
  push	eax					;
  push	edx					;
  
  dbg lprint {"[sonar sound system] timed_delay entered!", 0x0A}, DEBUG
  
  mov	eax, ecx				; 	EAX = number of nanoseconds until timer expires
  lea	edx, [.timer_handler]			; 	EDX = pointer to callback	
  ;externfunc	timer.set			;
  call	_timer_ole				;	<todo> This is a temporary timer
  						;
 .loop: 					;
  cmp	[.timer_done], dword 01h		; Good, now wait until timer is gone ...
  jne	.loop					;	
  						;
  mov	[.timer_done], dword 00h		; Reset the status
  pop	edx					; POP back
  pop	eax					;
  retn						; Done!
  						;
  .timer_handler:				;
      dbg lprint {"[sonar sound system] timer_handler called!", 0x0A}, DEBUG
    mov	[.timer_done], dword 01h		; Aha, timer done, good
    retn					;
  .timer_done: dd 0				; Our timer-status

_timer_ole:
; Debuggin temporary timer
; EAX = ticks to wait
; EDX = callback
	pushad
	shl	eax, 6				; Multiply it a bit
	.loop:					; Looping
	dec	eax
	cmp	eax, 00h
	jne	.loop
	call	[edx]
	popad
retn

section .data

callback: dd 0
sb:
  .base_io:	dw 0x210
  .dsp_vers:    dw 0	
  .dma8:	db 1		
  .dma16:	db 5		
  .irq:		db 5
  .dma_buffer:  dd 0
  .dma16_reg :  dw 0
  .dma8_reg  :  dw 0
  .page_no   :  db 0
  .dma_mode  :  db 0
  .mode_byte :  db 0
  .command_byte:db 0
