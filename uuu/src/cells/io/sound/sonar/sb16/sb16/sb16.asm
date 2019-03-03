;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;sonar sound system 				         (c) 2002, Niklas Klügel
;soundblaster driver (development-version)         Distributed under BSD-License
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; SECOND EDITION
; 
; USE: 
; - highly non-optimized soundblaster cell.
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
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;;
;;*****************
;;     header     *
;;*****************

%include "vid/timer.inc"
%include "vid/sound.inc"

[bits 32]

section .c_info

db 0,0,1,'a'
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "sonar sound system - soundblaster (compatible)",0
str_author: db "Niklas Klügel",0		
str_copyright: db "BSD-License",0		

;;
;;*****************
;; initialisation *
;;*****************

section .c_init
lprint {"[sonar sound system]: SB16 driver version $Revision: 1.2 $.",0xa}, FATALERR

;;
;; detect sounblaster card
;; 
detect_sb:
	xor edx , edx
	mov dx  , [sb.base_io]

	.search_base_io:
        	;lprint {"base io: %x",0x0A} , FATALERR , edx 	
                cmp dx  , 0x280
		je .failure
		add edx , byte 0x16
		mov al , byte 1
		out dx , al

		call _debug_wait

		xor eax , eax
		out dx  , al

		call _debug_wait

		add edx , byte 8 
		mov ecx , 3
		.retry:
		in al , dx	 
		test al , al
		js .data_ready
		call _debug_wait
		loop .retry		
		lprint{"Error: PortI/O timed out!"}, FATALERR		

		.data_ready:	
		sub edx , byte 4 			
		in al , dx
		sub edx , 0xA			
		cmp al , 0xAA	
		je .found
                jmp .search_base_io
	
	.failure:				
	lprint {"[sonar sound system] SoundBlaster or compatible card not found!", 0x0A}, FATALERR		
	jmp short $
	

	.found:					
	lprint {"[sonar sound system] Soundblaster or compatible card detected :"}, FATALERR, edx
	mov [sb.base_io] , dx
		.get_dsp_version:	
			mov al , 0xe1 
			call _dsp.write
			xor eax , eax
			xor edx , edx
			call _dsp.read
			mov [sb.dsp_vers_hi] , al			
			call _dsp.read
			mov [sb.dsp_vers_lo] , al
			mov dl , [sb.dsp_vers_hi]
			lprint {"       	DSP-Version: %d.%d"}, FATALERR, edx , eax
			cmp ah , 4
			jae .sb16
			lprint {"        => not SB16 compatible, using given configuration :"} , FATALERR 
			jmp .sb_other

.sb16:
	.get_irq:
	add dx , 04h 				; mixer register port
	mov ax, 80h
	out dx , ax 				; IRQ select
		
	call _debug_wait

	add dx , 01h				
	in ax, dx 				
		test dl , 1			
		jnz .test_irq_5			
		mov [sb.irq] , byte 2		
		jmp .get_dma			
		.test_irq_5:			
		test dl , 2			
		jnz .test_irq_7			
		mov [sb.irq] , byte 5		
		jmp .get_dma			
		.test_irq_7:			
		test dl , 4			
		jnz .test_irq_10		
		mov [sb.irq] , byte 7		
		jmp .get_dma			
		.test_irq_10:			
		mov [sb.irq] , byte 10		
						
	.get_dma:				
	mov dx , [sb.base_io]			
	add dx , 04h 				; mixer register port
	mov ax, 81h				
	out dx , ax 				; DMA select
				
	call _debug_wait

	add dx , 01h				
	in ax  , dx 				
	mov bl  , 0				
	mov ecx , 4				
						
	.8_bit_dma:				
		test dl , bl			
		je .8_bit_dma_found		
		inc bl				
		loop .8_bit_dma			
	.8_bit_dma_found:			
		mov [sb.dma8] , bl 		
		mov ecx , 4			
						
	.16_bit_dma:				
		test dl , bl			
		je .sb_other				
		inc bl				
		loop .16_bit_dma		
		mov [sb.dma16] , bl			
.sb_other:
	xor edx , edx
	mov dx , [sb.base_io]
	lprint {"        BaseI/O: %x"} , FATALERR , edx
	xor edx , edx
	mov dl , [sb.irq]
	lprint {"        IRQ : %d"}, FATALERR, edx
	mov dl , [sb.dma8]			
	lprint {"        8-Bit DMA : %d"}, FATALERR, edx
	mov dl , [sb.dma16]			
	lprint {"        16-Bit DMA : %d"}, FATALERR, edx



;;
;; set environment up
;; 
setup_environment:				
						;  allocate 64kbyte below 16Mbyte barrier
	mov ecx , 131072			;  as DMA buffer; problem: the block has
	xor edx , edx				;  to be aligned with page addressing.
	externfunc mem.alloc_20bit_address	
	cmp eax , ecx				
	je .mem_allocated			
		lprint {"[sonar sound system]: insufficient memory"}, FATALERR
		jmp short $
						
	
	.mem_allocated:				
	lea eax , [edi+0xFFFF]			
	and eax , 0xFFFF0000			
	lprint{"memblock-align: %x"} , FATALERR , eax 
	mov [sb.dma_buffer], eax		
	shr eax , 16				
	mov [sb.page_no],al			

        


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
	mov [sb.dma16_reg],dl			;
						;
						; Calc 8bitDMA-channel register (taken 
						;  from "DMA Tutorial by Tom Marshall)
 	mov     dx,2137h                	; *Magic DMA page reg convert
        mov     cl,[sb.dma8]            	;  for DMA 0..3
        shl     cl,2                    	;  	DMA0 => 87h
        shr     dx,cl                   	;  	DMA1 => 83h
        and     dx,0000Fh               	;  	DMA2 => 81h
        add     dx,00080h               	;  	DMA3 => 82h
	mov [sb.dma8_reg],dl			;
						;
						; Hook the irq
	mov 	al, [sb.irq]			;	- AL  = irq number 
	mov	esi, _irq_handler 		; 	- ESI = pointer to client to hook
	externfunc int.hook_irq			
	jnc	.hook_ok			
		lprint {"[sonar sound system]: IRQ not allocated",0xa}, FATALERR
		jmp short $			
						
  .hook_ok:					
	lprint {"[sonar sound system]: Soundblaster (compatible) ready.",0xa}, DEBUG	
  			

;; Uncomment this lines to play a sound "TEST.WAV" for debugging reasons
;; jmp playtest_sound
;; jmp short $

retn



;;
;;*********************
;; internal funcitons *
;;*********************
;;
_dsp:
	.write:
	push edx
	push eax
	mov dx , [sb.base_io]
	add dx  , 0x0C
	.write_busy:
	in al , dx
	test al , 80h
	jnz .write_busy
	pop eax
	out dx , al
	pop edx 
	retn

	.read:
	push edx 
	mov dx , [sb.base_io]
	add dx , 0xe
	.read_busy:
	in al , dx
	test al , 80h
	jz .read_busy
	sub dx , 4
	in al , dx
	pop edx 
	retn	









section .text					
;##############################################################################
;##############################################################################
;; DEBUG
playtest_sound:
xor eax , eax
mov al , [sb.irq]
cmp al , 15
jne .uhuh
retn ;jmp short $
.uhuh:
mov esi , _irq_handler
externfunc int.hook_irq
lprint{"irq : %d"} , FATALERR , eax
xor ebx , ebx
mov bx , 22050
call sound.set_sample_rate
mov eax ,  moo_sound
mov ebx ,  soundlength
sub ebx ,  eax
mov [soundlength] , ebx
call sound.enable_speaker
mov esi , moo_sound
mov ecx , [soundlength]

lprint{"playing sample using stream-function"}, FATALERR
mov edx , dignity 
call sound.play_stream_8bit
jmp short $

;; DEBUG 
;##############################################################################
;##############################################################################


dignity:
mov ecx , [soundlength]
mov esi , moo_sound
retn







globalfunc sound.play_shot_8bit , 721300
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
out 0xa , al					;
						;
xor al,al                   			;Reset byte F/F
out 0Ch,al					;
						;
mov al,0x48                   			;Set mode
add al , [sb.dma8]
out 0Bh,al					;
						;
xor edx , edx		
mov al , [sb.page_no]				;
mov dl , [sb.dma8_reg]				;
out dx , al					;
						;
						;set offset in page		
						; port = channel*2
mov dl, [sb.dma8]				;
shl dl , 1					;
push ax
xor ax, ax
out dx ,al
out dx ,al					;
pop ax
						;	
						; set block length
						; port = channel*2+1
inc dx						;
dec ebx 					;
shr ebx , 1					; now the sb card will play only
mov al, bl					; the half of the buffer and then 
out dx , al					; fire an irq , so we will fill
mov al , bh					; the buffer while playing
out dx , al					;	
						; enable channel		
mov al , [sb.dma8]				;
and al,3					;
out 0xA,al					;
						;
mov byte [sb.dma_mode] , 8				;
						;
mov al , 0x14					; dma dac 8bit command		
call _dsp.write					;
mov al , bl					;
call _dsp.write					;
mov al , bh					;
call _dsp.write					;

retn						;
						;
						;
globalfunc sound.play_stream_8bit , 721301			; 
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
; ecx - size (BYTES) , HAS to be always the same,
;	unless you want funny things happening.
; NOTE:
; When the callback is called a last time the
; CF must be 1 !
;-----------------------------------------------;

mov [callback], edx				;
call edx
mov ebx , ecx					;
mov [sb.block_len] , ecx

mov edi , [sb.dma_buffer]			;
repz movsb					;
mov [sb.stream_ptr], dword 0
						;
mov al,[sb.dma8]				;
and al,3					;
out 0xa , al					;
						;
xor al,al                   			;Reset byte F/F
out 0Ch,al					;
						;
mov al,0x58                   			;Set mode
add al , [sb.dma8]
out 0Bh,al					;
						;
xor edx , edx						;set page	
mov al , [sb.page_no]				;
mov dl , [sb.dma8_reg]				;
out dx , al					;
						;
						;set offset in page		
						; port = channel*2
mov dl, [sb.dma8]				;
shl dl , 1					;
push ax
xor ax, ax
out dx ,al
out dx ,al					;
pop ax
						;	
						; set block length
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
mov al , 0x1c					; dma dac 8bit command		
call _dsp.write					;
mov al , bl					;
call _dsp.write					;
mov al , bh					;
call _dsp.write					;

retn						;




globalfunc sound.enable_speaker , 721310
mov al , 0xd1
call _dsp.write
retn


; pause functions
;
globalfunc sound.halt_8bit , 721303
mov al , 0xd0
call _dsp.write
retn

globalfunc sound.continue_8bit_shot , 721304
mov al , 0xd4
call _dsp.write
retn

globalfunc sound.continue_8bit_stream , 721305
mov al , 0x45
call _dsp.write
retn
;
;


globalfunc sound_exit_8bit_stream , 721306
call sound.disable_speaker
call sound.halt_8bit
mov al , 0xd9
call _dsp.write
call sound.halt_8bit
retn




globalfunc sound.disable_speaker , 721307
mov al , 0xd3
call _dsp.write
retn


globalfunc sound.set_sample_rate , 721308
; bx - samplerate in Hz
push eax 
push edx
cmp [sb.dsp_vers_hi] , byte  4				; 
jae .set_sb16
mov al , 0x40
call _dsp.write
xor eax , eax
xor edx , edx
mov al ,  [sb.sample_chans]
mul ebx
mov ebx , 1000000
xchg ebx , eax
div ebx
neg al
call _dsp.write
pop edx
pop eax
retn

.set_sb16:
mov al , 0x41
call _dsp.write
mov al , bh
call _dsp.write
mov al , bl
call _dsp.write
pop edx
pop eax
retn		


globalfunc sound.reset_dsp , 721309
; usual errorcode

mov  dx  , [sb.base_io]
add edx , byte 0x6
mov al , byte 1
out dx , al

call _debug_wait

xor eax , eax
out dx  , al

call _debug_wait

add edx , byte 8 
.retry:
in al , dx	 
test al , al
js .data_ready
call _debug_wait
jmp .retry		

.data_ready:	
sub edx , byte 4 			
in al , dx
sub edx , 0xA			
cmp al , 0xAA	
je .exit
retn
clc
.exit: 
stc
retn


ics_client _irq_handler 						; for ICS channel
   
cmp dword [callback] , 0 			;if !0 , then it is pointing to a callbackfunction				;
je .single_transfer				
cmp byte [sb.dma_mode] , 8			
jne .16bit_stream			
cmp  [sb.stream_ptr] , 0
jne .first_half_8bit_irq

.second_half_8bit_irq:
lprint{"1"} , FATALERR
call [callback]
mov [sb.block_len] , ecx
jc .last_block
shr ecx , 1
mov edi , [sb.dma_buffer]
repz movsb
mov [sb.stream_ptr] , esi
jmp .confirm_8bit_irq

.last_block
mov [sb.stream_ptr] , esi
mov [sb.status] , byte 1 
jmp .confirm_8bit_irq
retn

.first_half__8bit_irq:
lprint{"2"} , FATALERR
cmp [sb.status] , byte 1
mov ecx , [sb.block_len]
je .end_block
shr ecx , 1
mov esi , [sb.stream_ptr]
mov edi , [sb.dma_buffer]
add edi , ecx
repz movsb
xor [sb.stream_ptr] , [sb.stream_ptr]
.confirm_8bit_irq:
mov dx , [sb.base_io]
add dx , 0xE
in al  , dx
clc
retn

.end_block:
mov [sb.status] , byte 0 
mov dx , [sb.base_io]
add dx , 0xE
in al , dx
mov ecx , [block_len]
mov edi , [sb.dma_buffer]
call sound.play_shot_8bit
clc 
retn
			
.16bit_stream:					
mov dx , [sb.base_io]
add dx , 0xF
in al , dx
call [callback]					
mov edi , [sb.dma_buffer]			
repz movsw					
clc
retn						
						
.single_transfer:				
cmp byte [sb.dma_mode] , 8			




jne .16_bit_dma_transfer			
mov dx , [sb.base_io]				
add dx , 0Eh ; IRQ_ack-port			
in  al , dx
clc
retn	
.16_bit_dma_transfer:				
mov dx , [sb.base_io]				
add dx , 0Fh ; IRQ_ack-port			
in  al , dx
clc
retn					


_debug_wait:
pushad 
mov ecx , 0xFF
.overblah2:

mov ebx , 0xFFFF
.blah2:
dec ebx
cmp ebx , 0
jne .blah2
loop .overblah2

mov eax , 30000 ; = 3000ns = 3ms                                                                                                                                                                
mov edx , pseudo_callback        				 
externfunc timer.set
popad
retn

pseudo_callback:
retn

section .data
moo_sound:
incbin "TEST.WAV"

soundlength : dd 0

callback: dd 0
sb:
  .base_io:	dw 0x200
  .dsp_vers_hi: db 0	
  .dsp_vers_lo: db 0
  .dma8:	db 1		
  .dma16:	db 5		
  .irq:		db 5
  .dma_buffer:  dd 0
  .dma16_reg :  db 0
  .dma8_reg  :  db 0
  .page_no   :  db 0
  .dma_mode  :  db 8
  .status    :  db 0
  .stream_ptr:  dd 0
  .block_len :  dd 0 
  .sample_chans:db 1
