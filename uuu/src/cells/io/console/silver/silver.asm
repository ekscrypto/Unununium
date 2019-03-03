;; Silver single virtual terminal cell
;; Copyright (c) 2001 Phil Frost & Richard Fillion
;; This cell currently provides a psudo-ANSI compliant terminal(s), but will
;; later be extended to support vt-100.
;; 

;                                           -----------------------------------
;                                                                       defines
;============================================================================== 

%define rows 		50		; number of rows on the terminal
%define cols 		80		; number of columns
%define pos(x,y)     	0xb8000 + (x)*2 + (y)*cols*2 
%define mode		3 		;vid mode used
%define driver		1  		;driver used
%define escape_code	0x1B  		;escape code
%define buffer_in_size  128 		;size of buffer for keys to process.
%define initial_attrib  0x07 		;initial attributes for text
%define tab_size	8		;amount of chars per tab
%define beep_freq	880		; a nice A (Hz)
%define beep_length	100		; (ms)

;                                           -----------------------------------
;                                                                        strucs
;============================================================================== 

struc term
  .next:		resd 1
  .prev:		resd 1
  .screen:		resd 1
  .terminal:		resd 1 ; terminal number
  .cursor:		resd 1
  .linestart:		resd 1 ; cursor ptr to last line started
  .color_attrib:	resb 1 ; color/attrib byte for text
  .ansi_cursor: 	resd 1 ; ansi cursor saving place
  .ansi_linestart:	resd 1 ; ansi linestart saving place for save/restore
  .buffer_loc:		resd 1 ; ptr to buffer to put keys in
  .buffer_in:		resd 1 ; where in buffer we last put a key
  .buffer_out:		resd 1 ; where we last read a key
  .buffer_rw:   	resd 1 ; how many bytes currently in the buffer
endstruc

struc local_fd
  .global:      	resb file_descriptor_size
  .terminal:		resd 1 ;ptr to its virtual terminal struc
  .screen:		resd 1 ;ptr to screen's info (for display manager)
endstruc

;                                           -----------------------------------
;                                                                     cell init
;============================================================================== 

section .c_init

init:
  pushad				; set 80x50 textmode
					;-------------------
  mov ax, 0x1112			;
  xor ebx, ebx				;
  push byte 0				;
  push dword 0xFFFF0010			;
  externfunc realmode.proc_call		;
  add esp, byte 8   			;
					; hook keyboard
					;--------------
  mov esi, _kbd_client			;
  externfunc kbd.set_unicode_client	;
					;
  popad					;
  clc					;
.done:					;

;                                           -----------------------------------
;                                                                 section .text
;============================================================================== 
section .text

;                                           -----------------------------------
;                                                               terminal.create
;==============================================================================

terminal.create.retn:
  retn

globalfunc terminal.create
;>
;; Create a terminal /dev/tty/*
;;
;; Parameters:
;;------------
;; none
;;
;; Returns:
;;---------
;; errors and registers as usual
;<

					; allocate memory for term struc
					;-------------------------------
  mov ecx, term_size			;
  externfunc mem.alloc			;
  jc .retn				;
					;
					; add terminal to terminal list
					;------------------------------
  cmp dword [first_terminal], byte -1	;
  jne short .not_first			;
  mov dword [first_terminal], edi	;
  mov dword [last_terminal], edi	;
  mov [edi + term.prev], dword -1	;
  mov [active_terminal], edi		;
  jmp short .done_adjusting		;
.not_first:				;
  mov esi, [last_terminal]		;
  mov [esi+term.next], edi		;
  mov [edi+term.prev], esi		;
  mov [edi + term.next], dword -1	;
  mov [last_terminal], edi		;
.done_adjusting:			;
					;
					; generate name and register with devfs
					;--------------------------------------
  inc dword [last_created]		; get a new vc
  mov dword [dev_name.number], 0	; zero out old settings
  mov dword [dev_name.last_4], 0	;
  mov eax, [last_created]		;
  mov [edi + term.terminal], eax	;
  push edi				; save ptr to this terminal's data
  push eax				; terminal's number (0,1,2...)
  mov edi, dev_name.number		;
  push byte 0				;
  mov ebx, 0x0A				;
.generate:				;
  xor edx, edx				;
  div ebx				;
  add edx, byte 0x30			;
  push edx				;
  test eax, eax				;
  jnz short .generate			;
.print:					;
  pop eax				;
  stosb					;
  test eax, eax				;
  jnz short .print			;
  mov ebx, _open			;
  mov esi, dev_name			;
  pop ebp				; terminal's number (0,1,2...)
  externfunc devfs.register		;
					; create screen
					;--------------
  xor eax, eax				;
  xor ebx, ebx				;
  mov ecx, mode				;
  mov edx, driver			;
  externfunc screen.create		;
					;
  push eax				; start bugfix that clears the terminal
  push edi				;
  push ecx				;
  mov edi, [eax + screen.base_address]	;
  mov ah, initial_attrib		;
  mov al, 0x20				;
  mov ecx, eax				;
  rol eax, 16				;
  mov ax, cx				;
  mov ecx, (cols * rows*2)/4		;
  rep stosd				;
  pop ecx				;
  pop edi				;
  pop eax				; end bugfix that clears the terminal
					;
					; allocate input buffer for terminal
					;-----------------------------------
  pop ebp	  			; terminal's ptr to data
  push esi				;
  xor esi, esi				; ESI = 0
  mov [ebp + term.screen], eax		;
  mov ecx, buffer_in_size		;
  push eax				;
  externfunc mem.alloc			;
  pop eax				;
  mov [ebp + term.buffer_loc], edi	;
  mov [ebp + term.buffer_in], esi	;  
  mov [ebp + term.buffer_rw], esi	;
  mov dword[ebp + term.buffer_out], buffer_in_size
  mov [ebp + term.cursor],  esi		;
  mov [ebp + term.linestart], esi	;
  mov byte[ebp + term.color_attrib], initial_attrib
  push ebp				;
  cmp [active_terminal], ebp		;
  jne .not_active			;
  externfunc screen.set_active		;
.not_active:				;
  pop ebp				;
  pop esi				;
  retn					;
  
;.retn is above the function

;                                           -----------------------------------
;                                                                  _move_cursor
;==============================================================================

 _move_cursor:
;; moves the VGA hardware cursor
;;
;; parameters:
;; -----------
;; EDI = cursor position (if edi = 2, char(2,1) would be cursorized)
;;
;; returned values:
;; ----------------
;; all registers unmodified

  push ecx
  push eax
  push edx

  mov ecx, edi
  shr ecx, 1
  mov dx, 0x03D4
  mov ax, 0x0000E
  mov ah, ch
  out dx, ax
  mov dx, 0x03D4
  mov ax, 0x0000F
  mov ah, cl
  out dx, ax

  pop edx
  pop eax
  pop ecx
  retn 

;                                           -----------------------------------
;                                                                _find_terminal
;==============================================================================

_find_terminal:
;PARAM: ebp = terminal to find
;RETURN: edx = ptr to terminal struc
;CF = 1 if not found
 push edi
 mov edi, [first_terminal]
 ;externfunc sys_log.print_hex
 ;retn
.search:
 cmp [edi + term.terminal], ebp
 je short .found_search
 cmp edi, dword [last_terminal]
 je .done_search 
 mov edi, [edi + term.next]
 jmp short .search
.done_search:
 stc
 pop edi
 retn

.found_search:
 mov edx, edi
 pop edi
 clc
 retn


;                                           -----------------------------------
;                                                                        _error
;============================================================================== 

_error:
  mov eax, __ERROR_OPERATION_NOT_SUPPORTED__
  stc
  retn 

;                                           -----------------------------------
;                                                                         _open
;============================================================================== 

_open:
  push ebp
  push edx
  mov ecx, file_descriptor_size
  externfunc mem.alloc
  jc short .pop2err
  mov dword[edi+file_descriptor.op_table], op_table
  mov dword[edi+file_descriptor.fs_descriptor], edx
  pop dword [edi + file_descriptor.fs_descriptor]
  pop ebp
  call _find_terminal
  jc short .done
  mov dword [edi + local_fd.terminal], edx	;which terminal 
  mov ebp, [edx + term.screen]
  mov dword [edi + local_fd.screen], ebp
  mov ebx, edi
.done:
  retn 

.pop2err:
  add esp, byte 4
  stc
  retn

;                                           -----------------------------------
;                                                                        _write
;==============================================================================
;parameters
;ECX = number of bytes to write
;ESI = pointer to buffer to read data from
;EBX = pointer to file descriptor
;returned values
;errors as usual
_write:
  test ecx, ecx
  jz short .done_write_done
  pushad
  mov edi, [ebx + local_fd.terminal]
  mov ebx, [ebx + local_fd.screen] 
  mov ebx, [ebx + screen.base_address]	; EBX = base of where we will print
  mov ebp, [edi + term.cursor]		;
  mov edx, ebp			;cursor - last line started = distance in line
  sub edx, [edi + term.linestart]	;
  shr edx, 1				;EDX = dist (chars) from start of line
  sub edx, byte 80			;
  neg edx			;NEG(distance - 80)=# of chars in line to go.
.write_byte:				;
  mov al, [esi]				;
  inc esi				;
  test al, 0xE0				;
  jz .control_char			;
  mov ah, [edi + term.color_attrib]	;
  mov word [ebp + ebx], ax		;print at cursor + base addres
  dec edx				;
  jz short .newline			;
  add ebp, byte 2			;
.ignore_char:				;
  dec ecx				;
  jnz short .write_byte			;
.done_write:				;
  mov dword [edi + term.cursor], ebp	;
  cmp edi, [active_terminal]		;
  jne short .not_active			;
					; set cursor position
					;--------------------
  mov edi, ebp				;
  call _move_cursor			;
.not_active:				;
  popad					;
.done_write_done:			;
  retn					;

;                                           -----------------------------------
;                                                                 .control_char
;==============================================================================

.control_char:
  movzx eax, al
  jmp [.control_char_handlers+eax*4]

[section .data]
.control_char_handlers:
  dd .ignore_char	; 0x00 ^@ NUL null
  dd .ignore_char	; 0x01 ^A SOH start heading
  dd .ignore_char	; 0x02 ^B STX start of text
  dd .ignore_char	; 0x03 ^C ETX end of text
  dd .ignore_char	; 0x04 ^D EOT end transmit
  dd .ignore_char	; 0x05 ^E ENQ enquiry
  dd .ignore_char	; 0x06 ^F ACK acknowledge
  dd .beep		; 0x07 ^G BEL beep
  dd .backspace		; 0x08 ^H BS  back space
  dd .tab		; 0x09 ^I HT  horizontal tab
  dd .newline		; 0x0A ^J LF  line feed
  dd .ignore_char	; 0x0B ^K VT  vertical tab
  dd .ignore_char	; 0x0C ^L FF  form feed
  dd .ignore_char	; 0x0D ^M CR  carriage ret.
  dd .ignore_char	; 0x0E ^N SO  shift out
  dd .ignore_char	; 0x0F ^O SI  shift in
  dd .ignore_char	; 0x10 ^P DLE device link esc
  dd .ignore_char	; 0x11 ^Q DC1 dev cont 1 X-ON
  dd .ignore_char	; 0x12 ^R DC2 dev control 2
  dd .ignore_char	; 0x13 ^S DC3 dev cont 3 X-OFF
  dd .ignore_char	; 0x14 ^T DC4 dev control 4
  dd .ignore_char	; 0x15 ^U NAK negative ack
  dd .ignore_char	; 0x16 ^V SYN synchronous idle
  dd .ignore_char	; 0x17 ^W ETB end trans block
  dd .ignore_char	; 0x18 ^X CAN cancel
  dd .ignore_char	; 0x19 ^Y EM  end medium
  dd .ignore_char	; 0x1A ^Z SUB substitute
  dd .ansi_escape	; 0x1B ^[ ESC escape
  dd .ignore_char	; 0x1C ^/ FS  cursor right
  dd .ignore_char	; 0x1D ^] GS  cursor left
  dd .ignore_char	; 0x1E ^^ RS  cursor up
  dd .ignore_char	; 0x1F ^_ US  cursor down
__SECT__

;                                           -----------------------------------
;                                                                      .newline
;==============================================================================

.newline:
  mov edx, cols			;reset manual \n counter.
  mov ebp, [edi + term.linestart]
  add ebp, cols * 2
  cmp ebp, (cols*rows*2)-2
  jb short .no_scroll
  call .scroll
.no_scroll:
  mov [edi + term.linestart], ebp
  dec ecx
  jnz near  .write_byte
  jmp short .done_write

;                                           -----------------------------------
;                                                                       .scroll
;==============================================================================

.scroll:
  pushad
  mov ebp, edi
  lea esi, [ebx + cols * 2]
  mov edi, ebx
  mov ecx, ((rows-1)*(cols*2))/4
  repz movsd
  mov ecx, (cols*2)/4
  push ebx
  mov ah, [ebp + term.color_attrib]
  mov al, " "
  xor ebx, ebx
  mov bx, ax
  rol eax, 16
  mov ax, bx
  pop ebx
  rep stosd
  popad
  mov ebp, [edi + term.linestart]
  retn

;                                           -----------------------------------
;                                                                          .tab
;==============================================================================

.tab:
  push esi
  mov esi, [edi + term.linestart]
  cmp edx, byte 8
  jnb short .no_new_line
;it needs a new line.
  add esi, cols * 2
  mov [edi + term.linestart], esi
  sub edx, byte 8
  neg edx
  mov ebp, esi
  mov edx, cols				;reset manual \n
  dec ecx
  pop esi
  jnz near .write_byte
  jmp near .done_write
.no_new_line:
  pop esi
  add ebp, byte (tab_size * 2) 
  sub edx, byte 8 
  and ebp, 0xFFFFFFF0
  dec ecx
  jnz near .write_byte
  jmp near .done_write

;                                           -----------------------------------
;                                                                    .backspace
;==============================================================================

.backspace:
  mov ah, [edi + term.color_attrib]
  test ebp, ebp
  je short .done_backspace
  sub ebp, byte 2
  mov al, " "
  inc edx
  cmp edx, byte cols
  ja short .backspace_up_a_line
  mov word [ebx + ebp], ax  
.done_backspace:
  dec ecx
  jnz near .write_byte
  jmp near .done_write
.backspace_up_a_line:
  mov edx, 1
  push esi
  mov esi, dword [edi + term.linestart]
  sub esi, cols * 2
  mov dword [edi + term.linestart], esi
  pop esi
  dec ecx
  jnz near .write_byte
  jmp near .done_write

;                                           -----------------------------------
;                                                                         .beep
;==============================================================================

.beep:
  mov al, 10110110b
  out 0x43, al
  in al, 0x61
  or al, 00000011b
  out 0x61, al
  mov ax, 1193180 / beep_freq
  out 0x42, al
  mov al, ah
  out 0x42, al

  push edx
  mov eax, beep_length * 1000000
  mov edx, .beep_callback
  externfunc timer.set
  pop edx
  
  dec ecx
  jnz .write_byte
  jmp .done_write

.beep_callback:
  in al, 0x61			; stop beeping
  and al, 11111100b
  out 0x61, al
  retn

;                                           -----------------------------------
;                                                                  .ansi_escape
;==============================================================================

.ansi_escape:
  mov ah, [edi + term.color_attrib]
  dec ecx  		;check to see if it was last byte.
  jz near .done_write
  mov al, [esi]
  inc esi
  cmp al, "["		;second part of ansi escape code
  je short .real_ansi
  dec esi		;put back to its position then.
  jmp near .write_byte
  
.real_ansi:		;we have a real ANSI escape code, time to analyze
  dec ecx		;take into account the "[" that was read
  jz .done_write
  push eax		;there is no printing to do, so we could use this register.
  ;push edi
  xor eax, eax
  mov ax, [esi]
  cmp al, "s"
  je near .ansi_save_cursor
  cmp al, "u"
  je near .ansi_restor_cursor
  cmp al, "K"
  je near .ansi_erase_line
  cmp ax, "2J"
  je near .ansi_erase_display
  cmp ah, "A"
  je near .ansi_cursor_up
  cmp ah, "B"
  je near .ansi_cursor_down
  cmp ah, "C"
  je near .ansi_cursor_forward
  cmp ah, "D"
  je near .ansi_cursor_backward
  xor eax, eax

  inc ecx
  push esi
  push ecx

;                                           -----------------------------------
;                                                            .find_complex_ansi
;==============================================================================

.find_complex_ansi:
  mov al, [esi]
 ;externfunc debug.diable.print_regs_wait
  inc esi
  dec ecx
  jz .no_ansi_found_sorry
  cmp al, "["
  je .find_complex_ansi
  cmp al, "A"
  jb .find_complex_ansi
  cmp al, "z"
  ja .find_complex_ansi
.complex_ansi_found:
  pop ecx
  pop esi
  dec ecx
  cmp al, "H"
  je near .ansi_set_cursor
  cmp al, "f"
  je near .ansi_set_cursor
  cmp al, "m"
  je short .ansi_attribs
  jmp near .done_ansi
.no_ansi_found_sorry:
  pop ecx
  pop esi
  jmp .done_ansi

;                                           -----------------------------------
;                                                                 .ansi_attribs
;==============================================================================

.ansi_attribs:
 
.find_ansi_attribs:
  xor eax, eax
  mov ax, [esi]
  inc esi
  dec ecx
  jz near .done_write_ansi
  cmp al, ";"
  je .find_ansi_attribs
  cmp al, "m"
  je near .done_ansi
  sub al, 0x30
  cmp ah, ";"
  je .set_ansi_attrib_base  
  cmp ah, "m"
  je .set_ansi_attrib_base
  inc esi
  dec ecx
  jz near .done_write_ansi
  push ebx
  xor ebx, ebx
  mov bl, ah
  and eax, 0xFF
  lea eax, [eax*5]
  add eax, eax
  sub bl, 0x30
  add eax, ebx
  pop ebx
  cmp al, 39
  jb  near .set_ansi_attrib_fg
  ja  near .set_ansi_attrib_bg

.set_ansi_attrib_done:

.set_ansi_attrib_base:
  mov ah, [edi + term.color_attrib]
  cmp al, 1
  je short .set_ansi_attrib_bright
  jb short .set_ansi_attrib_all_off
  cmp al, 2
  je short .set_ansi_attrib_dim
  cmp al, 4
  je short .set_ansi_attrib_underscore
  cmp al, 5
  je short .set_ansi_attrib_blink
  cmp al, 7
  je short .set_ansi_attrib_reverse
  cmp al, 8
  je short .set_ansi_attrib_hidden
  jmp short .find_ansi_attribs

.set_ansi_attrib_all_off:
  and ah, 01110111b
  mov byte [edi + term.color_attrib],ah
  jmp near .find_ansi_attribs
.set_ansi_attrib_bright:
  or ah, 00001000b
  mov byte [edi + term.color_attrib], ah
  jmp near .find_ansi_attribs
    
.set_ansi_attrib_dim:
  and ah, 11110111b
  mov byte [edi + term.color_attrib], ah
  jmp near .find_ansi_attribs

.set_ansi_attrib_underscore:
  mov byte [edi + term.color_attrib], ah
  jmp near .find_ansi_attribs

.set_ansi_attrib_blink:
  xor ah, 10000000b
  mov byte [edi + term.color_attrib], ah
  jmp near .find_ansi_attribs

.set_ansi_attrib_reverse:
  rol ah, 4
  mov byte [edi + term.color_attrib], ah
  jmp near .find_ansi_attribs

.set_ansi_attrib_hidden:
  mov byte [edi + term.color_attrib], ah
  jmp near .find_ansi_attribs

.set_ansi_attrib_fg:
  sub al, byte 30
  mov ah, [edi + term.color_attrib]
  and ah, 11111000b 
  or ah, al
;externfunc debug.diable.print_regs_wait
  mov byte [edi + term.color_attrib], ah
  jmp .find_ansi_attribs
.set_ansi_attrib_bg:
  sub al, byte 40
  shl al, 4
  mov ah, [edi + term.color_attrib]
  and ah, 10001111b
  or ah, al
  mov byte [edi + term.color_attrib], ah
  jmp near .find_ansi_attribs

;                                           -----------------------------------
;                                                             .ansi_save_cursor
;==============================================================================

.ansi_save_cursor:
  inc esi		;fix esi.
  mov dword [edi + term.ansi_cursor], ebp
  dec ecx
  jz near .done_write_ansi
  jmp near .done_ansi
  
;                                           -----------------------------------
;                                                          .ansi_restore_cursor
;==============================================================================

.ansi_restor_cursor:
  inc esi
  mov ebp, dword [edi + term.ansi_cursor]
  dec ecx
  jz near .done_write_ansi
  jmp near .done_ansi
  
;                                           -----------------------------------
;                                                              .ansi_erase_line
;==============================================================================

.ansi_erase_line:
  inc esi
  push ebp
  mov ebp, [edi + term.linestart]
  push ecx
  push edx
  mov ecx, edx
  test ecx, ecx
  jz .ansi_erase_done
  sub edx, cols
  neg edx			;NEG(chars to go-cols) = chars from left
  shl edx, 1
  add ebp, edx
  push eax
  mov ah, [edi + term.color_attrib]
  mov al, 0x20
.ansi_erase_word:
  mov word [ebp + ebx], ax
  add ebp, byte 2
  dec ecx
  jnz near .ansi_erase_word
.ansi_erase_done:
  pop eax
  pop edx
  pop ecx
  pop ebp
  dec ecx
  jz near .done_write_ansi
  jmp near .done_ansi

;                                           -----------------------------------
;                                                           .ansi_erase_display
;==============================================================================

.ansi_erase_display:		;[RESET DISPLAY AND SET CURSOR HOME]
 
  add esi, byte 2		;fix esi
  push edi
  push ecx
  mov ah, [edi + term.color_attrib]
  mov al, 0x20
  mov ecx, eax
  rol eax, 16
  mov ax, cx
  mov edi, ebx
  mov ecx, (cols * rows*2)/4
  rep stosd
  pop ecx
  pop edi
  mov edx, cols			;reset counter for manual \n
  xor ebp, ebp
  mov [edi+term.linestart], ebp
  mov [edi+term.cursor], ebp
;  inc dword [0xb8000]
  sub ecx, byte 2
  jbe near .done_write_ansi
  jmp near .done_ansi

.ansi_cursor_up:
  add esi, byte 2
  push ecx
  xor ecx, ecx
  mov cl, al			;number of lines to go up
.ansi_cursor_up_another:
  cmp ebp, cols * 2
  jb short .ansi_cursor_up_not_ok
  sub ebp, cols * 2
  sub dword [edi + term.linestart], cols *2
  dec ecx
  jnz .ansi_cursor_up_another
.ansi_cursor_up_not_ok:
  pop ecx
  sub ecx, byte 2
  jbe near .done_write_ansi
  jmp near .done_ansi

.ansi_cursor_down:
  add esi, byte 2
  push ecx
  xor ecx, ecx
  mov cl, al			;number of lines to go down
.ansi_cursor_down_another:
  cmp ebp, (cols * rows * 2) - (cols * 2)
  jae near .ansi_cursor_down_not_ok
  add ebp, cols * 2
  add dword [edi + term.linestart], cols *2
  dec ecx
  jnz short .ansi_cursor_down_another
.ansi_cursor_down_not_ok:
  pop ecx
  sub ecx, byte 2
  jbe near .done_write_ansi
  jmp near .done_ansi

;                                           -----------------------------------
;                                                          .ansi_cursor_forward
;==============================================================================

.ansi_cursor_forward:
  add esi, byte 2
  push ecx
  xor ecx, ecx
  mov cl, al
.ansi_cursor_forward_another:
  add ebp, byte 2
  dec edx
  jnz short .ansi_cur_forward_no_newline 
  call .ansi_cursor_forward_newline
.ansi_cur_forward_no_newline:
  dec ecx 
  jnz short .ansi_cursor_forward_another
  pop ecx
  sub ecx, byte 2
  jbe near .done_write_ansi
  jmp near .done_ansi
.ansi_cursor_forward_newline:
  cmp ebp, cols * rows * 2
  jb short .ansi_cur_forward_no_scroll
  call .scroll
  retn
.ansi_cur_forward_no_scroll:
  push esi
  mov esi, dword [edi + term.linestart]
  add esi, cols * 2
  mov dword [edi + term.linestart], esi
  pop esi
  retn

;                                           -----------------------------------
;                                                         .ansi_cursor_backward
;==============================================================================

.ansi_cursor_backward:
  add esi, byte 2
  push ecx
  xor ecx, ecx
  mov cl, al
.ansi_cursor_backward_another:
  inc edx
  cmp edx, byte 80
  ja short .ansi_cursor_backward_backline
  sub ebp, byte 2
  dec ecx
  jnz short .ansi_cursor_backward_another
  pop ecx
  sub ecx, byte 2
  jbe near .done_write_ansi
  jmp near .done_ansi
.ansi_cursor_backward_backline:
  mov edx, 1			;its right at the right most of the line it just backedon
  sub dword [edi + term.linestart], cols *2	;back a line
  sub ebp, byte 2		;reverse cursor position by 1 char
  dec ecx
  jnz short .ansi_cursor_backward_another
  pop ecx
  jmp near .done_ansi

;                                           -----------------------------------
;                                                              .ansi_set_cursor
;==============================================================================

.ansi_set_cursor:
  push eax
  push ecx
  externfunc lib.string.ascii_decimal_to_reg
  add esi, ecx
  mov ebp, ecx
  test edx,edx
  jnz .ansi_set_cursor_found_Y
  mov edx, 1
.ansi_set_cursor_found_Y:
  mov al, [esi]				;go over ";"
  cmp al, ";"
  je .ansi_set_cursor_get_next
  push edx
  mov edx, 1
  inc ebp
  inc esi
  jmp .ansi_set_cursor_done_get
.ansi_set_cursor_get_next:
  inc ebp
  inc esi
  push edx
  externfunc lib.string.ascii_decimal_to_reg
  add esi, ecx
  add ebp, ecx
  test edx, edx
  jnz .ansi_set_cursor_got_last
  mov edx, 1
.ansi_set_cursor_got_last:
  inc esi				;go over letter at end
  inc ebp
.ansi_set_cursor_done_get:
  pop eax
  cmp eax, rows
  ja short .ansi_set_cursor_bad_param
  cmp edx, cols
  ja short .ansi_set_cursor_bad_param
  dec eax			;for some reason when you put 3, it does 4
  dec edx			;same 
  push ebx
  push edx
  mov ebx, cols
  mul ebx
  pop edx
  pop ebx
  add eax, eax
  mov [edi + term.linestart], eax
  mov ecx, ebp
  neg ecx
  add ecx, [esp]
  add esp, 4
  lea ebp, [eax+edx*2]
  mov [edi + term.cursor], ebp
  pop eax
  sub edx, cols
  neg edx			;edx=cols-positions=amount of chars left till \n
  test ecx, ecx
  jz short .done_write_ansi
  jmp short .done_ansi

.ansi_set_cursor_bad_param:
  sub ecx, byte 4
  jbe short .done_write_ansi
  ; spill into .done_ansi

;                                           -----------------------------------
;                                                                    .done_ansi
;==============================================================================

.done_ansi:
  ;pop edi
  pop eax
  jmp near .write_byte

;                                           -----------------------------------
;                                                              .done_write_ansi
;==============================================================================

.done_write_ansi:			;for when you are done writting
  pop eax
  jmp near .done_write

;                                           -----------------------------------
;                                                                         _read
;==============================================================================
; ECX = number of bytes to read
; EDI = pointer to buffer to put data in
; EBX = pointer to file descriptor

_read:
  test ecx, ecx				; do nothing on zero sized reads
  jz short .done_read			;
  pushad				; save registers
  mov edx, [ebx + local_fd.terminal]	; EDX = terminal we are reading from
  mov esi, [edx + term.buffer_loc]	; ESI = buffer base
  mov eax, [edx + term.buffer_out]	; EAX = ptr to first unread char
					;
					; read 1 byte from the buffer
.next_byte:				;----------------------------
  cmp eax, buffer_in_size		; wrap position back to start if end is
  jz short .wrap_around			;   reached
.wrap_done:				;
  cmp dword [edx + term.buffer_rw], byte 0
  jz short .nothing_to_read		; wait til there's enough bytes to read
  mov bl, [esi + eax]			; BL = read byte
  mov [edi], bl				; put byte in dest. buffer
  inc edi				; move to next byte in dest. buffer
  inc eax				; next byte in src. buffer
  dec dword [edx + term.buffer_rw]	; one less byte in src. buffer
  dec ecx				;
  jnz short .next_byte			; loop until done
					;
  mov dword [edx + term.buffer_out], eax; save cur. position
  popad					; restore registers
  retn
  
.done_read:
  lprint {"silver: zero size read",0xa}, WARNING
  retn

.wrap_around:
  xor eax, eax
  jmp short .wrap_done

.nothing_to_read:
  jmp short .next_byte			; now, just loop, later, sleep thread

;                                           -----------------------------------
;                                                               keyboard client
;==============================================================================

_kbd_client:
;; eax = char
;; ebx = modifier, bitwise
;;   mod 0 = left shift
;;   mod 1 = right shift
;;   mod 2 = capslock
;;   mod 3 = left alt
;;   mod 4 = right alt
;;   mod 5 = left ctrl
;;   mod 6 = right ctrl

  pushad				;
  mov edx, [active_terminal]		; EDX = active terminal
  mov edi, [edx + term.buffer_loc]	; EDI = buffer base
  mov esi, [edx + term.buffer_in]	; ESI = current insertion point in buf
  cmp dword [edx + term.buffer_rw], buffer_in_size
  jz  short .buffer_full		; ignore the char if buffer is full
  cmp esi,  buffer_in_size 		; go back to begining of buf when we
  jz short .wrap_around			;   hit the end
.done_wrap:				;
  mov byte [edi + esi], al		;
  inc dword [edx + term.buffer_in]	;
  inc dword [edx + term.buffer_rw]	;
.buffer_full:				;
  popad					;
  retn					;
.wrap_around:				;
  mov dword [edx + term.buffer_in], 0	;
  xor esi, esi				;
  jmp short .done_wrap			;
 
;                                           -----------------------------------
;                                                                     cell info
;==============================================================================
section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Silver - ANSI terminal",0
str_author: db "Richard Fillion (Raptor-32) based on Phil Frost's code.",0
str_copyright: db "Distributed under BSD License",0

;                                           -----------------------------------
;                                                                 section .data
;============================================================================== 

section .data

align 4, db 0

active_terminal: dd -1
first_terminal: dd -1
last_terminal: dd -1
last_created: dd -1

our_file_descriptor: 
istruc local_fd
   at local_fd.global
      istruc file_descriptor
        at file_descriptor.op_table,      dd op_table
      iend
iend

op_table: istruc file_op_table
  at file_op_table.close,	dd _error
  at file_op_table.read,	dd _read
  at file_op_table.write,	dd _write
  at file_op_table.raw_read,	dd _error
  at file_op_table.raw_write,	dd _error
  at file_op_table.seek_cur,	dd _error
  at file_op_table.seek_start,	dd _error
  at file_op_table.seek_end,	dd _error
  at file_op_table.read_fork,	dd _error
  at file_op_table.write_fork,	dd _error
  at file_op_table.link,	dd _error
  at file_op_table.unlink,	dd _error
  at file_op_table.create,	dd _error
  at file_op_table.rename,	dd _error
  at file_op_table.copy,	dd _error
  at file_op_table.truncate,	dd _error
  at file_op_table.attrib,	dd _error
iend

dev_name: db "/tty/"
.number: db 0,0,0,0
.last_4: db 0,0,0,0	;room for 4 billion terminals + 0-termination
