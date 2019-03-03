; unununium operating engine
; copyright (c) 2001, dave poirier
; distributed under the bsd license

[bits 32]

%define LOG_SIZE 65536

%include "vid/sys_log.inc"
%include "vid/mem.inc"
%include "vid/debug.diable.inc"
%include "vid/gfx.render.13h.inc"
%include "vid/debug.bochs.inc"
%include "vid/lib.string.inc"

;; _BOCHS_LOG_OUTPUT_
;;
;; uncomment if you want all the log output to also be sent to bochs.out via the
;; debug/bochs cell
;;
;%define _BOCHS_LOG_OUTPUT_

;; _TEXTMODE_SCREEN_OUTPUT_
;;
;; uncomment if you want the log output to also be sent to a textmode console at
;; 0xb8000
%define _TEXTMODE_SCREEN_OUTPUT_

%macro print_to_screen_and_bochs 0
  %ifdef _BOCHS_LOG_OUTPUT_
    externfunc debug.bochs.print_string
  %endif
  %ifdef _TEXTMODE_SCREEN_OUTPUT_
    call _tty_to_screen
  %endif
%endmacro

section .c_info

  db 1,1,0,'f'
  dd str_name
  dd str_author
  dd str_copyright

  str_name: db "Yttrium System Log",0
  str_author: db "EKS - Dave Poirier (futur@mad.scientist.com)",0x0A
              db "Daboj - Phil Frost (daboy@xgs.dhs.org)",0
  str_copyright: db "Copyright (C) 2001, Dave Poirier",0x0A
                 db "Distributed under the BSD License",0

section .c_init

initialization:

.start:
  pushad

  mov ecx, LOG_SIZE
  externfunc mem.alloc
  jnc short .proceed

.failed:
  dmej 0xdeadbe2f

.proceed:
  mov [log_start], edi
  mov [edi], word 0
  add edi, byte 2
  mov [log_cursor_start], edi
  mov [log_cursor_end], edi
  lea edi, [edi + ecx - 2]
  mov [log_end], edi

  popad



section .text


;------------------------------------------------------------------------------
globalfunc sys_log.print_string
;;-----------------------------------------------------------------------------
;>
;; Prints the string at ESI to the log. If the string ends in 0, the
;; log entry is terminated. If it ends in 1, the log entry is left open. So, you
;; could print "The number is: ",1 and then call one of the number output funcs,
;; then call terminate to print "The number is: 0xdeadbeef".
;;
;; returned values:
;;-----------------
;;   eax = (unmodified)
;;   ebx = (unmodified)
;;   ecx = (unmodified)
;;   edx = (unmodified)
;;   esi = (unmodified)
;;   edi = (unmodified)
;;   esp = (unmodified)
;;   ebp = (unmodified)
;<

  pushad
  pushfd
  print_to_screen_and_bochs

  mov edi, [log_cursor_end]
  inc edi
  jz .failed

  dec edi
  mov edx, [log_end]
.copying_over:
  mov al, [esi]
  or al, al
  jz short .end
  cmp edi, edx
  jz short .quick_end
  cmp al, 0x01
  jz short .quick_end
  mov [edi], al
  inc esi
  inc edi
  jmp short .copying_over

.end:
  cmp edi, edx
  jz short .quick_end
  mov [edi], al
  inc edi

.quick_end:
  mov [log_cursor_end], edi

.failed:
  popfd
  popad
  retn

;------------------------------------------------------------------------------
globalfunc sys_log.terminate
;------------------------------------------------------------------------------
;>
;;
;; Terminates a log entry (similar to sending a null string)
;;
;<
  pushad
  pushfd
  mov esi, .nl

  print_to_screen_and_bochs
  mov edi, [log_cursor_end]
  cmp edi, [log_end]
  jae .end
  mov [edi], byte 0
  inc edi
  mov [log_cursor_end], edi
.end:
  popfd
  popad
  retn

.nl: db 0

;------------------------------------------------------------------------------
globalfunc sys_log.print_decimal
;------------------------------------------------------------------------------
;>
;; Print the value of EDX in decimal
;;
;; Parameters:
;;------------
;; EDX = value to print
;;
;; Returns:
;;---------
;; flags unmodified
;; registers as usual
;<

  pushad
  pushfd

  mov edi, .tmp_buffer
  externfunc lib.string.dword_to_decimal_no_pad
  mov byte[edi+ecx], 1
  mov esi, edi
  call sys_log.print_string

  popfd
  popad
  retn

.tmp_buffer: times 10+1 db 1

;------------------------------------------------------------------------------
globalfunc sys_log.print_float
;;------------------------------------------------------------------------------
;>
;; prints st0 out in hex such as "+000000FF.80000000" (255.5). Will also print
;; "NaN" or "INF". If the number is too big or small to fit within the 8 digits
;; on either side of the decimal "BIG" or "SMAL" is printed. This is likely to
;; change later.
;<

  pushad
  pushfd

  push eax
  fst dword[esp]
  pop edx

  mov edi, .string

  mov dword[edi], "    "
  mov dword[edi+4], "    "
  mov dword[edi+8], "    "
  mov dword[edi+12], "    "
  mov word[edi+16], "  "

  ; first we check the sign and be done with it

  test edx, 0x80000000
  jz .positive

  mov byte[edi], '-'
  inc edi
  jmp .done_with_sign

.positive:
  mov byte[edi], '+'
  inc edi

.done_with_sign:

  ;; next, we break the float up into it's parts:
  ;; EDX = the float unchanged
  ;; EAX = mantissa, bits 0-22, aligned to the left beacuse it's fractional
  ;; ECX = exponent, bits 23-30

  mov eax, edx
  mov ecx, edx
  and eax, 0x007fffff
  and ecx, 0x7f800000
  shl eax, 9		; EAX = mantissa
  shr ecx, 23		; ECX = exponent

  ; test for some special exponent cases:

  cmp cl, 255
  jne .not_inf_or_nan

  ; an exponent of 255 indicates either infinity or NaN
  test eax, eax
  jz .not_nan

  ; we have 255 exponent and non zero mantissa, it's NaN
  mov dword[edi], "NaN "
  jmp .end

.not_nan:
  ; we have 255 exponent and zero mantissa, it's infinity
  mov dword[edi], "INF "
  jmp .end

.not_inf_or_nan:

  ;; now we check for denomalized numbers and set the implied 1 bit (or implied
  ;; 0 if it's denormalized) in the mantissa.

  xor edx, edx
  inc edx	; assume our number is normal, so set the implied 1 bit
  
  test ecx, ecx
  jnz .normalized

  ; test if it's zero
  test eax, eax
  jnz .not_zero

  mov byte[edi], "0"
  jmp .end

.not_zero:
  dec edx	; whoops...unset that 1 bit
  inc ecx	; exp is -126, not -127

.normalized:

  ;; now our number is in EDX:EAX with the binary point between the registers.
  ;; Now we want to apply the shift in the exponent. Should the number be to
  ;; big or to small to fit in 64 bits we will simply puke out "BIG" or
  ;; "SMALL" and die because all the numbers I will be using will fit :)
  
  sub ecx, byte 127	; remove the bias
  test ecx, ecx
  js .neg_exp

  ; we have a positive exp, that means we shift left.
  test ecx, 0xFFFFFFC0
  jz .shift_left

  ; it's so big there would be nothing but 0.
  mov dword[edi], "BIG "
  jmp .end

.shift_left:
  shld edx, eax, cl
  shl eax, cl
  test ecx, 0x20
  jz .l_shift_done
  mov edx, eax
  xor eax, eax
.l_shift_done:
  jmp .display

.neg_exp:
  ; we have a negitive exp, that means we shift right.
  neg ecx
  test ecx, 0xFFFFFFC0
  jz .shift_right

  ; it's so small there's nothing but 0.
  mov dword[edi], "SMAL"
  jmp .end

.shift_right:
  shrd eax, edx, cl
  shr edx, cl
  test ecx, 0x20
  jz .r_shift_done
  mov eax, edx
  xor edx, edx
.r_shift_done:

  ;; Goody...now our number is either in EDX:EAX or it was too big or small so
  ;; "BIG" or "SMAL" was printed. All that's left is to print it.

.display:
  push eax
  call _make_ascii
  mov byte[edi], '.'
  inc edi
  pop edx
  call _make_ascii
  
.end:
  mov esi, .string
  call sys_log.print_string
  popfd
  popad
  retn

.string: times 19 db 1

_make_ascii:
  mov ecx, 8
.loop:
  rol edx, 4
  mov al, dl
  and al, 0x0f
  cmp al, 0x0a
  sbb al, 0x69
  das
  mov [edi], al
  inc edi
  dec ecx
  jnz .loop

  retn

;------------------------------------------------------------------------------
globalfunc sys_log.print_hex
;;-----------------------------------------------------------------------------
;>
;; Prints the number in EDX as an 8 digit hex number, not terminating the log.
;;
;; Parameters:
;;------------
;; EDX = value to print
;;
;; Returns:
;;---------
;; flags and registers kept intact
;<

  pushad
  pushfd
 
  mov edi, .tmp_buffer
  
  call _make_ascii
 
  lea esi, [edi-8]
  
  call sys_log.print_string

  popfd
  popad
  
  retn
  
.tmp_buffer: times 8+1 db 1


;------------------------------------------------------------------------------
globalfunc sys_log.get_log_pointer
;------------------------------------------------------------------------------
;>
;;
;; parameters: none
;; returned values: esi = pointer to log, ecx = size
;<

  mov esi, [log_cursor_start]
  retn

log_start: dd -1
log_end: dd -1
log_cursor_start: dd -1
log_cursor_end: dd -1


globalfunc sys_log.dump_regs
;;------------------------------------------------------------------------------
;>
;; Prints all the registers to the system log. It makes a complete entry too :P
;; The EIP is the EIP on the stack from the call and EFLAGS are your flags, not
;; mine.
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; all registers and flags unchanged.
;<

  pushad
  pushfd

   mov esi, .eax_str
  call sys_log.print_string
  mov edx, eax
  call sys_log.print_hex

   mov esi, .edx_str
  call sys_log.print_string
  mov edx, [ss:esp+24]
  call sys_log.print_hex

  mov esi, .ecx_str
  call sys_log.print_string
  mov edx, ecx
  call sys_log.print_hex

  mov esi, .ebx_str
  call sys_log.print_string
  mov edx, ebx
  call sys_log.print_hex

  mov esi, .esp_str
  call sys_log.print_string
  mov edx, esp
  add edx, byte 32      ; the esp before pushad
  call sys_log.print_hex

  mov esi, .eflags_str
  call sys_log.print_string
  mov edx, [ss:esp]
  call sys_log.print_hex

  mov esi, .eip_str
  call sys_log.print_string
  mov edx, [ss:esp+36]
  call sys_log.print_hex

  mov esi, .ebp_str
  call sys_log.print_string
  mov edx, ebp
  call sys_log.print_hex

  mov esi, .esi_str
  call sys_log.print_string
  mov edx, [ss:esp+8]
  call sys_log.print_hex

  mov esi, .edi_str
  call sys_log.print_string
  mov edx, edi
  call sys_log.print_hex

  mov esi, .end_str
  call sys_log.print_string

  popfd
  popad
  retn

.eax_str: db "EAX: ",1
.edx_str: db " EDX: ",1
.ecx_str: db " ECX: ",1
.ebx_str: db " EBX: ",1
.esp_str: db " ESP: ",1
.eflags_str: db 0x0a,"EFLAGS: ",1
.eip_str: db " EIP: ",1
.ebp_str: db " EBP: ",1
.esi_str: db " ESI: ",1
.edi_str: db " EDI: ",1
.end_str: db 0x0a, 0


globalfunc sys_log.dump_fpu_regs
;;------------------------------------------------------------------------------
;>
;; Just like sys_log.dump_registers, except it dumps the FPU registers
;<

  push esi

.display:
   mov esi, .st0_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  mov esi, .st1_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  mov esi, .st2_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  mov esi, .st3_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  mov esi, .st4_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  mov esi, .st5_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  mov esi, .st6_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  mov esi, .st7_str
  call sys_log.print_string
  call sys_log.print_float
  fincstp

  call sys_log.terminate

  pop esi
  retn

.st0_str: db "ST0: ",1
.st1_str: db " ST1: ",1
.st2_str: db 0x0a,"   ST2: ",1
.st3_str: db " ST3: ",1
.st4_str: db 0x0a,"   ST4: ",1
.st5_str: db " ST5: ",1
.st6_str: db 0x0a,"   ST6: ",1
.st7_str: db " ST7: ",1


%ifdef _TEXTMODE_SCREEN_OUTPUT_
;------------------------------------------------------------------------------
_tty_to_screen:
;------------------------------------------------------------------------------
; display a copy of the log entry on screen

  ; esi = pointer to string, either 0 or 1 terminated.
  mov edi, [.tty_offset]
  mov ah, 0x07
  push esi
.displaying:
  mov al, [esi]
  inc esi
  cmp al, 0x0A
  jz short .scroll_up
  cmp al, 0x01
  jz short .quick_end
  or al, al
  jz short .scroll_and_quit
  stosw
  jmp short .displaying

.scroll_up:
  call .scroll_it_up
  jmp short .displaying

.scroll_and_quit:
  call .scroll_it_up
.quick_end:
  pop esi
  mov [.tty_offset], edi
  retn

.scroll_it_up:
  push eax
  push esi
  cld
  mov esi, 0xB80A0
  mov edi, 0xB8000
  mov ecx, 960
  repz movsd
  push edi
  mov ecx, 40
  mov eax, 0x07200720
  repz stosd
  pop edi
  pop esi
  pop eax
  retn

.tty_offset: dd 0xB8000 + (0xA0*24)

%endif	; _TEXTMODE_SCREEN_OUTPUT_

globalfunc gfx.render.13h.string
;>
;; Prints an ascii string in beautiful 13h. The font is 8x14; the background
;; is transparent. The function is really stupid; if your string doesn't fit
;; across the screen it will not autowrap.
;;
;; Special chars supported:
;; ------------------------
;; 0x0A (linefeed): will wrap the text to the next line, under whene it started
;; 0x07 followed by color: change the color
;; 
;; parameters:
;; -----------
;; ESI = ptr to null terminated ascii string
;; EDI = offset to print to
;; AL = color to use
;;
;; returned values:
;; ----------------
;; total chaos!
;;
;; status:
;; -------
;; done
;<
.start:
  push edi

.letter:
  movzx ebp, byte[esi]
  test ebp, ebp
  jz .done
  
  cmp ebp, 0x0a
  jne .no_lf

  pop edi
  add edi, 320*14
  inc esi
  jmp .start
.no_lf:

  cmp ebp, 0x07
  jne .no_color_change

  inc esi
  mov al, [esi]
  inc esi
  jmp .letter

.no_color_change:
  lea ebx, [ebp+ebp]	;
  shl ebp, 4		;
  sub ebp, ebx		; mul ebp by 14
  mov edx, .font
  add edx, ebp		; EDX = offset to letter to print

  mov ecx, 14

.row:
  mov ebp, 8
  mov bl, [edx]		; BL = row to print
  
.pixel:
  test bl, 0x80
  jz .no_draw
  mov byte[edi], al
.no_draw:
  rol bl, 1
  add edi, 1
  dec ebp
  jnz .pixel

  add edi, 320-8	; go to next row
  inc edx		; go to next row
  dec ecx
  jnz .row

  sub edi, 320*14-8	; move edi to next char's place
  inc esi		; next letter
  jmp .letter
.done:
  pop edi
  retn

.font:
  %include "font.inc"
