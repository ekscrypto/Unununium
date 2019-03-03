; Graphic Rendered Support functions
; Copyright (c) 2001, Dave Poirier
; Distributed under the X11 license
;
; todo:
; o Add a couple of extra UCS-32 font characters in font.inc
; o Add register dump, dword_out, etc..
;------------------------------------------------------------------------------
section .c_info
  db 1,0,0,'a'
  dd str_title
  dd str_author
  dd str_copyright

  str_title:
  db "Yttrium - Debugging4GFX",0
  str_author:
  db "eks",0
  str_copyright:
  db "Distributed under the X11 License",0

section .text

; Include font characters definition
[section .data]
%include "font.inc"
__SECT__



					      globalfunc debug.gfx.print_string
;------------------------------------------------------------------------------
;>
;; Prints a UTF-8 string in any 8bpp lfb gfx mode. The font is 8x14 and every
;; character row is separated by 2 transparent line. The function is really
;; stupid; if your string doesn't fit across the screen it will not autowrap
;; nicely, it will instead overwrap but one pixel lower than the previous
;; line, overwriting most of it.
;;
;; Special chars supported:
;; ------------------------
;; 0x0A (linefeed): will wrap the text to the next line, under whene it started
;; 0x07 followed by fg then bg color: change the color
;; Supports UTF-8 strings (only UCS-32 0-127 will be displayed)
;;
;; parameters:
;; -----------
;; ESI = ptr to null terminated ascii string
;; EDI = offset to print to lfb where to start printing
;; EBX = pitch to next line (how many bytes until the next gfx line)
;; AL = fg color to use
;; AH = bg color to use
;;
;; returned values:
;; ----------------
;; total chaos!
;;
;; status:
;; -------
;; to test
;<
;------------------------------------------------------------------------------
  pushad		; backup all regs
.start:			;
  push edi		; initial lfb pointer
			;
.letter:		;
  xor ebp, ebp		; reset UCS-32 char
.utf8_byte:		;
  movzx ecx, byte [esi]	; load one UTF-8 byte
  inc esi		; move pointer foward
  shl ebp, 7		; 7 UCS-32 bits per UTF-8 char
  mov edx, ecx		; backup original utf-8 byte read
  and cl, byte 0x7F	; keep only the 7 UCS-32 bits of UTF-8 char
  add ebp, ecx		; add the 7 UCS-32 bits
  test dl, byte 0x80	; compound char ended?
  jnz short .utf8_byte	; if bit7=1, load next byte of compound char
			;
  cmp ebp, 0x0a		; UCS-32 = linefeed?
  jz .lf		;
			;
  cmp ebp, 0x07		; UCS-32 = change color code?
  jz .color_change	;
			;
			; Check if we have the char defined in our font
			;----------------------------------------------
  cmp ebp, _LAST_UCS32_FONT_DEFINED_
  jb short .supported_char
			;
  xor ebp, ebp		; unsupported, select null character
			;
			; Compute font char location
.supported_char:	;---------------------------
  lea edx, [ebp+ebp]	;
  shl ebp, 4		;
  sub ebp, edx		; mul ebp by 14
  add edx, font		; EDX = offset to letter to print
			;
			; Display font char
			;------------------
  mov ch, 14		; character height
  push edi		; backup lfb pointer
			;
.row:			;
  xor ebp, ebp		;
  mov cl, [edx]		; CL = font row to print
			;
.pixel:			;
  mov [edi+ebp], ah	; reset pixel to bg
  test cl, 0x80		; check if we draw the pixel or leave it bg
  jz .no_draw		; if 0, leave it bg
  mov [edi+ebp], al	; draw the pixel
.no_draw:		;
  rol cl, 1		; select next bit of font row
  inc ebp		; select next pixel location
  cmp ebp, byte 8	; all pixels of the row drawn?
  jb short .pixel	; in case not, process next pixel
			;
  lea edi, [ebx+edi- 8]	; go to next lfb row
  inc edx		; go to the font next row
  dec ch		; decrement font row left to process
  jnz .row		; if some left, go process it
			;
  pop edi		; restore ptr to first pixel of first row
  add edi, byte 8	; move 8 pixels right
  jmp .letter		; process next char of string
			;
			; Return to caller
.done:			;-----------------
  pop edi		; clear off our row ptr
  popad			; restore all regs
  retn			; return
			;
			; LineFeed character detected
.lf:			;----------------------------
  pop edi		; get initial lfb pointer
  mov ebp, ebx		; ebp=pitch
  shl ebp, 4		; compute offset of 16 lines
  add edi, ebp		; adjust initial lfb pointer to it
  jmp .start		;
			;
			; Change Colors
.color_change:		;--------------
  lodsw			; load fg and bg colors
  jmp .letter		;
;------------------------------------------------------------------------------
