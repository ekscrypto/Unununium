;; Fastasia sound cell
;; Copyright 2001 Phil Frost
;; Distributed under the BSD license

;; * provided functions *
;;
;; __play_sound		single_shot	5500	1
;; __play_sound		stream		5500	2
;; __install_check	sb		5570	1
;; __set_sample_rate	noclass		5571	0
;; __set_speaker	enable		5560	1
;; __set_speaker	disable		5560	2
;; __dsp_reset		noclass		5550	0

[bits 32]

%macro showmsg 1+	; prints a message to the system log, be sure to
push esi
mov esi, %%msg
externfunc string_out, system_log
pop esi
[section .data]		; include a 1 or 0 terminator on the string.
%%msg: db %1
__SECT__
%endmacro

;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------
;; INIT
;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------

section .c_init

pushad

test_for_sb:
; try to reset
  call __dsp_reset.c_noclass
  jnc .sucess

; reset failed :(
  showmsg "[Fastasia] Reset of SB failed, aborting;",0xa,"The base IO address is probally wrong.",0xa,0
  jmp end_init

.sucess:
  inc byte[sb_installed]			; set to 1
  showmsg "[Fastasia] SoundBlaster ready",0xa,0


hook_sb_irq:
  mov al, [sb.irq]
  mov esi, sb_irq_handler
  externfunc hook_irq, noclass

allocate_dma_buffer:
  ; XXX should allocate with memory manager
  mov dword[dma.buffer0], 0x60000
  mov dword[dma.buffer1], 0x68000
  mov dword[dma.buffer_size], 0x8000

setup_irq_ack:
  mov al, [sb.irq]
  cmp al, 7
  jg .slave_pic

  mov byte[..@irq_ack_port], 0x20
  jmp .fix_number
  
.slave_pic:
  mov byte[..@irq_ack_port], 0xA0
  sub al, 8

.fix_number:
  add al, 0x60
  mov [..@irq_ack_number], al
  
end_init:
popad
  

;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------
;; DATA
;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------

section .data

align 4

sb:
  .base_io:	dw 0x220	; base io: 0x210 to 0x280, powers of 0x10
  .dma8:	db 1		; almost always 1, but also can be 0, or 3
  .dma16:	db 5		; can be 5, 6, or 7
  .irq:		db 5		; most common 5 or 7, can also be 2, 3, or 10

sb_installed:	db 0		; set if a SB is detected

dma:
  .buffer0:	dd 0
  .buffer1:	dd 0
  .buffer_size:	dd 0

extra_bytes:	dd 0

callback_function:	dd 0	; pointer to streaming callback function, 0
				;   for none

current_buffer:	db 0		; 0 or 1



;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------
;; GLOBAL FUNCTIONS
;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------

section .text

globalfunc play_sound, single_shot, 5500, 1
;>
;; plays a single sound. The sound must all be loaded in memory and fit in
;; only one page below 16MB.
;;
;; parameters:
;; -----------
;; esi = pointer to sound
;; ecx = number of bytes in sound (must be non-zero)
;;
;; returned values:
;; ----------------
;; none
;<


  mov al, 100b
  or al, [sb.dma8]
  out 0xa, al		; mask off channel to program it

  out 0xc, al		; clear byte ptr, can be any value

  mov al, 0x48		; single mode read
  or al, [sb.dma8]
  out 0xb, al		; set mode

  mov eax, esi

  rol eax, 16
  out 0x83, al		; set page XXX only for channel 1

  rol eax, 16
  out 0x02, al		; XXX this assumes channel 1
  ror eax, 8
  out 0x02, al		; set offset to 0

  dec ecx
  mov al, cl
  out 0x03, al
  mov al, ch
  out 0x03, al		; set legnth

  mov al, [sb.dma8]
  out 0xa, al		; disable mask, channel is enabled and ready to rock.

  mov al, 0x14		; DMA DAC, 8 bit command
  call _dsp_write

  mov al, cl		; ecx has already been DECed
  call _dsp_write	; low byte of legnth--
  mov al, ch
  call _dsp_write	; high byte, LAUNCH!
  
  retn			; that was fun; return to base.



globalfunc play_sound, stream, 5500, 2
;>
;; **INCOMPLETE**
;; 
;; plays a stream by using a callback function
;;
;; parameters:
;; -----------
;; edx = pointer to callback function; see below
;;
;; returned values:
;; ----------------
;; none yet
;;
;; callback function:
;; ------------------
;; When the buffer needs refilling the function specified in edx is called with
;; these parameters:
;;
;;   parameters:
;;   -----------
;;   edi = pointer to buffer to fill
;;   ecx = nuber of bytes to fill
;;
;;   returned values:
;;   ----------------
;;   ebx = number of bytes accually copied into the buffer. If this is equal to
;;        ecx when the callback is called, streaming continues. If it is less,
;;        that many bytes are played and then the stream is stopped. If it is
;;        zero, the stream is stopped immediately, if it is larger than ecx
;;        funny things happen, so don't do that :)
;<


; program DMA ---===---

  mov ecx, [dma.buffer_size]
  dec ecx
  mov al, 0x48		; set block size command
  call _dsp_write
  mov al, cl
  call _dsp_write
  mov al, ch
  call _dsp_write	; set SB transfer size for half of the buffer

  add ecx, ecx		; double it; dma plays the whole thing, SB plays half
  mov edi, [dma.buffer0]
  inc ecx		; we subtracted one, then doubled, so we are missing one

  mov al, 100b
  or al, [sb.dma8]
  out 0xa, al		; mask off channel to program it

  out 0xc, al		; clear byte ptr, any value can be written

  mov al, 0x58		; single mode read auto-initialize
  or al, [sb.dma8]
  out 0xb, al		; set mode

  mov eax, edi

  rol eax, 16
  out 0x83, al		; set page; XXX assumes channel 1

  rol eax, 16
  out 0x02, al		; XXX this assumes channel 1
  ror eax, 8
  out 0x02, al		; set offset to 0

  mov al, cl
  out 0x03, al
  mov al, ch
  out 0x03, al		; set legnth

  mov al, [sb.dma8]
  out 0xa, al		; disable mask, channel is enabled and ready to rock.


; call callback to fill buffer ---===---

  mov [callback_function], edx

  inc ecx		; this is already set for the whole buffer - 1
  ; edi is still set

  push ecx
  call edx
  pop ecx

; see if they filled the whole buffer; if they did not, call single_shot to
; play the sound ---===---
  
  ;ebx = number of bytes filled
  ;ecx = size of both buffers
  cmp ebx, ecx
  jl .single_shot
  

; set up some info for the IRQ handler ---===---
  mov byte[current_buffer], 0

; launch SB ---===---

  mov al, 0x1c		; auto-init DMA DAC 8 bit command
  jmp _dsp_write	; that was fun; return to base.


; if all of both buffers was not filled we just call one_shot

.single_shot:
  showmsg "sound was too small, doing one shot, not stream",0xa,0
  ; ebx = number of bytes to play
  mov esi, [dma.buffer0]
  mov ecx, ebx
  jmp __play_sound.c_single_shot



globalfunc install_check, sb, 5570, 1
;>
;; checks if a SB is installed.
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; cf = clear if sb is installed
;<

  mov al, [sb_installed]
  stc
  test al, al
  jz .nope

  clc
.nope:
  retn



globalfunc set_sample_rate, noclass, 5571, 0
;>
;; sets the sample rate
;;
;; parameters:
;; -----------
;; ebx = sample rate (if playback is stereo, double it)
;;
;; returned values:
;; ----------------
;; none
;;
;; todo:
;; -----
;; the sample rate may not have to be doubled for stero on non sbPro
;<

  mov al, 0x40		; set time constant command
  call _dsp_write

; the time constant is 256 - 1000000 / sampleChannels / sampleRate
; but the sampleChannels is taken care of by the caller, so we don't.

  mov eax, 1000000
  xor edx, edx
  div ebx

  xor edx, edx
  sub edx, eax

  mov eax, edx

  call _dsp_write

  retn


globalfunc set_speaker, enable, 5560, 1
;>
;; turns on the speakers
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; none
;<

  mov al, 0xd1
  call _dsp_write
  retn


globalfunc set_speaker, disable, 5560, 2
;>
;; turns off the speakers
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; none
;<

  mov al, 0xd3
  call _dsp_write
  retn


globalfunc dsp_reset, noclass, 5550, 0
;>
;; Performs a complete DSP reset, killing all pending opperations.
;; 
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; cf = clear if sucessfull
;<

; send 1 to reset port
  mov dx, [sb.base_io]
  mov al, 1
  add edx, byte 6
  out dx, al

; now we wait 3.3 ms
  mov ecx, 219
  externfunc timed_delay, low_resolution

; write 0 to reset port
  xor al, al
  out dx, al

; wait for data to become ready
  mov ecx, 0x10000000		; maximum possible tries, about 100ms
  add edx, byte 8		; is now data ready port 0xe

.wait:
  in al, dx
  test al, al
  js .data_ready
  loop .wait

; data never became ready, die
  jmp .failure

.data_ready:
  sub edx, byte 4		; dsp data port 0x0a
  in al, dx
  cmp al, 0xaa			; should be 0xaa if reset was sucessfull
  jne .failure

.exit:
  clc
  retn

.failure:
  stc
  retn


;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------
;; NON GLOBAL FUNCTIONS
;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------

_dsp_write:
;;-----------------------------------------------------------------------------
;; writes AL to the data port, waiting for the data_ready signal like all good
;; programs :P
;; 
;; parameters:
;; -----------
;; AL = Data byte
;;
;; returned values:
;; ----------------
;; all registers unchanged
;;
;; todo:
;; -----
;; make a maximum wait of 100ms so that this won't loop forever.

  push edx
  push eax
  mov dx,[sb.base_io]
  add edx, byte 0x0c	; select write data port
.busy:
  in al,dx		; get write status
  test al,80h		; ready to write ?
  jnz .busy		; no check status again
  pop eax 
  out dx,al		; write data byte
  pop edx
  retn




_dsp_read:
;;-----------------------------------------------------------------------------
;; reads a byte from the data port, waiting, like a good boy.
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; al = byte read
;;
;; todo:
;; -----
;; make a maximum wait of 100ms so that this won't loop forever.

  push	edx
  mov	dx,[sb.base_io]
  add	dx,0eh              	; select data ready status port
.busy:
  in	al,dx               	; get status
  test	al,80h
  jz 	.busy
  sub 	dx,4                	; select data read port
  in   	al,dx               	; read byte
  pop  	edx
  retn     	            	; return to caller



;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------
;; IRQ HANDLER
;;-----------------------------------------------------------------------------
;;-----------------------------------------------------------------------------


dd 0,0			; for ICS channel
sb_irq_handler:
;;-----------------------------------------------------------------------------
  pushad
  
  mov dx, [sb.base_io]
  add dx, byte 0xe
  in al, dx		; ACK IRQ to SB

  mov al, 0x65
..@irq_ack_number: equ $-1
  out 0x20, al		; ACK PIC; this is SMC set up by cell_init
..@irq_ack_port: equ $-1

  showmsg "SB IRQ fired",0xa,0


; check if we are streaming ---===---

  mov eax, [callback_function]
  test eax, eax
  jz .done		; if there isn't a callback we are not streaming


; we are streaming, set up the next buffer ---===---

  ; figure out which buffer to fill
  xor byte [current_buffer], 1	; toggle the current buffer
  mov ecx, [dma.buffer_size]
  jz .buffer1

  ; setup to fill buffer 0
  showmsg "filling buffer 0",0xa,0
  mov edi, [dma.buffer0]
  push dword .buffer_filled
  jmp eax			; like CALL but retn to .buffer1

.buffer1:
  ; setup to fill buffer 1
  showmsg "filling buffer 1",0xa,0
  mov edi, [dma.buffer1]
  call eax

.buffer_filled:

; check to see if they filled all of the buffer ---===---
  ; ebx = number of bytes the callback put into the buffer
  cmp ebx, [dma.buffer_size]
  jl .stop_play			; if they didn't, jump
  
.done:
  popad

  clc			; we handled the IRQ, thankya
  retn



;; if the callback didn't fill the whole buffer we stop playing by programing
;; the soundblaster for a single cycle DMA ---===---

.stop_play:

  mov dword[extra_bytes], ebx

  mov dword[callback_function], _halt_autoinit_dma	; the next int will stop playback

  ; ebx = number of remaining bytes to play

  popad
  clc
  retn



_halt_autoinit_dma:
;; used as the callback when the stream needs to be halted.

  mov dword[callback_function], 0	; done streaming, no more callback

  mov al, 0x14
  call _dsp_write
  mov eax, [extra_bytes]
  dec eax
  call _dsp_write
  mov al, ah		; now the next time around SB will play
  call _dsp_write	; ebx bytes and stop

  pop eax		; dump return point
  popad
  clc
  retn			; return from interupt
