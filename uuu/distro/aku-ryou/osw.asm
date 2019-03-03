%include "../../include/macros.inc"

[bits 32]

; aku-ryou OperatingSystem wrapper


section .osw_pre_init

; blindly copied from frustration osw.asm
  mov al, 0xFF
  out 0x21, al
  out 0xA1, al

  mov esi, 0x8000 ; point to core header
  xor eax, eax


section .osw_post_init

; set 320x200x8
 mov ax,0013h
 push DWORD 0
 push DWORD 0xFFFF0010
 externfunc procedure_call, realmode
 add esp,8

; allocate almost 64Kb for decoded PCX image
	mov ecx, 64000
	xor edx, edx
	externfunc malloc, noclass
	jc error
	mov [RawImage], edi	;edi = block address

 ; draw our cool logo screen
call PCX_Decoder.set_up
call PCX_Decoder.draw

error: ; don't draw logo if we failed to obtain memory, but print text anyway :P

; print some shitty text over it
   mov ebp, colorpixmap
   mov esi, maskpixmap
   mov ebx, 28         ; X
   mov edx, 50         ; Y
   call draw_pixmap_thru_mask

   jmp short $

%include "gfx.asm"

colorpixmap:
   dw 4 ; width
   dw 5 ; height

   db 15, 12, 12, 12            ;****
   db 11, 10, 10, 13            ;*  *
   db 11, 13, 15, 10            ;****
   db 05, 10, 10, 15            ;*  *
   db 09, 10, 10, 09            ;*  *

maskpixmap:
   dw 4 ; width
   dw 5 ; height

   db  1,  1,  1,  1            ;****
   db  1,  0,  0,  1            ;*  *
   db  1,  1,  1,  1            ;****
   db  1,  0,  0,  1            ;*  *
   db  1,  0,  0,  1            ;*  *


;#########>> PCX Decoder <<##########

;---------> [variables]

 RawImage     : dd 0              ; pointer to decoded picture
 PCXImage     : incbin "boot.pcx"
 PCXImageEnd  equ $
 x            : db 100
 y            : db 150
;---------> [functions]
PCX_Decoder:
.set_up:
;##### SET PALETTE #####
lea esi , [PCXImageEnd - 768]
xor eax , eax
mov dx  , 0x3c8
mov ecx , 768
out  dx , al
inc dx
.set_palette:
lodsb
shr  al , 2
out dx  , al
loop .set_palette
;##### DECODE PCX  #####
mov edi  , [RawImage]
mov ebp, edi
add ebp, 64000 ; end pointer
lea esi  , [PCXImage + 127]
.decode_pcx:
mov ecx  , 1
lodsb
cmp al , 192
jb .single
and al , 63
mov cl , al
lodsb
.single:
rep stosb
cmp edi , ebp
jbe .decode_pcx
ret

.draw:
mov esi , [RawImage]
mov edi , 0xA0000
mov ecx , 64000
rep movsb
ret

