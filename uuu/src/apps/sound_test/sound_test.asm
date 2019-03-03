[bits 32]
 

section sound_test

%macro showmsg 1+	; prints a message to the system log, be sure to
[section .data]		; include a 1 or 0 terminator on the string.
%%msg: db %1
__SECT__
push esi
mov esi, %%msg
externfunc string_out, system_log
pop esi
%endmacro

struc riff_head
  .id:			resb 4	; 'RIFF'
  .size:		resd 1	; number of bytes in file, not including this header?
  .type_id:		resd 1	; just guessing, but i know this must be 'WAVE' for wave files
endstruc

struc format_chunk
  .id:			resb 4	; 'fmt ' <-- note the space
  .size:		resd 1	; not including this header?
  .tag:			resw 1	; 1 for uncompressed
  .channels:		resw 1
  .sample_rate:		resd 1
  .bytes_per_sec:	resd 1
  .align:		resw 1	; size of sample frame
  .bits_per_sample:	resw 1
  ;; may be more
endstruc

struc data_chunk
  .id:			resb 4	; 'data'
  .size:		resd 1	; not including this header and any end pad bytes
endstruc
 
global app_sound_test

app_sound_test:

  externfunc install_check, sb
  jc exit

  mov esi, stream_start
  cmp dword[esi], 'RIFF'
  jne exit.riff

  cmp dword[esi+riff_head.type_id], 'WAVE'
  jne exit.wave

  add esi, riff_head_size	; esi now points to first chunk
  cmp dword[esi+format_chunk.id], 'fmt '
  jne exit.stupid

  mov ebx, [esi+format_chunk.sample_rate]
  push esi
  externfunc set_sample_rate, noclass
  pop esi

  cmp word[esi+format_chunk.channels], 1
  jne exit.stupid

  cmp word[esi+format_chunk.bits_per_sample], 8
  jne exit.stupid

  add esi, [esi+format_chunk.size]
  add esi, byte 8		; esi now points to next chunk

  cmp dword[esi], 'data'
  jne exit.stupid

  mov ecx, [esi+data_chunk.size]

  add esi, byte data_chunk_size	; don't play the header
  mov [stream.current_position], esi
  mov [stream.bytes_remaining], ecx

  ; copy the sound to someplace DMA can get to it
  mov edi, 0x60000
  rep movsd

  showmsg "playing sound",0xa,0

  externfunc set_speaker, enable
  mov edx, callback_function
  externfunc play_sound, stream
  
  showmsg "press enter to continue",0xa,0

  externfunc wait_ack, debug

  externfunc set_speaker, disable
  
exit:  
  retn

.riff:
  showmsg "File does not appear to be RIFF, exiting",0xa,0
  jmp exit
  
.wave:
  showmsg "File does not appear to be in wave format, exiting",0xa,0
  jmp exit

.stupid:
  showmsg "This program is too stupid to deal with this fancy wav file, exiting",0xa,0
  jmp exit

.tobig:
  jmp exit



callback_function:
  ;; ecx = number of bytes to copy
  ;; edi = buffer to put bytes in
  ;;
  ;; returns:
  ;; ebx = number of bytes copied

  cmp [stream.bytes_remaining], ecx
  jge .copy_full_amount

  ; if we get here we have less left to play than the callback wants

  mov ecx, [stream.bytes_remaining]

.copy_full_amount:

  mov ebx, ecx

  mov esi, [stream.current_position]
  shr ecx, 2				; convert bytes to dwords
  rep movsd

  add [stream.current_position], ebx
  sub [stream.bytes_remaining], ebx

  retn




section .data

stream_start:
incbin "test.wav"
stream_end:

stream:
  .current_position:	dd 0	; offset to current place in file
  .bytes_remaining:	dd 0


