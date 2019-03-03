; Unununium Operating Engine
; Copyright (c) 2000-2001, Dave Poirier
; Distributed under the BSD License.
;
;			[= SDK.EHEX Hexadecimal Editor =]
;			      System Core compliant
;
; More information available on our website at http://uuu.wox.org/ or by email
; at core_dev@uuu.wox.org
;
; note for visual consulation, tabulations are adjusted for 8 characters and
; the source was adjusted for a screen width of 80 characters.


[bits 32]
section .c_info
  db 0,0,1,'a'
  dd str_name
  dd str_author
  dd str_copyrights

  str_name : db "EHEX Hexadecimal Editor",0
  str_author : db "Dave Poirier (eks@onee-san.net)",0
  str_copyrights : db "Distributed under BSD License",0

section .c_init
global _start
_start:
  retn




section .text


 %define _VERSION_HIGH_          2
 %define _VERSION_LOW_           0
 %define _VERSION_SPECIFIER_     0
 %define _COMPATIBILITY_         1
 %define _LICENSE_TYPE_          1

 %define _ASC_FIELD_X_			11
 %define _ASC_FIELD_Y_			2
 %define _COLOR_ACTIVE_			0x0F
 %define _COLOR_INACTIVE_		0x07
 %define _DEFAULT_EDIT_ENABLE_		0
 %define _DEFAULT_DECODER_ENABLE_	1
 %define _DEFAULT_FULL_ASCII_		1
 %define _DEFAULT_ALTERNATE_TYPE_	0
 %define _HEX_FIELD_X_			29
 %define _HEX_FIELD_Y_			_ASC_FIELD_Y_
 %define _KEY_ARROW_DOWN_		0x50
 %define _KEY_ARROW_LEFT_		0x4B
 %define _KEY_ARROW_RIGHT_		0x4D
 %define _KEY_ARROW_UP_			0x48
 %define _KEY_ESCAPE_			0x81
 %define _KEY_F01_			0x3B
 %define _KEY_F02_			0x3C
 %define _KEY_F03_			0x3D
 %define _KEY_F04_			0x3E
 %define _KEY_F05_			0x3F
 %define _KEY_F06_			0x40
 %define _KEY_F07_			0x41
 %define _KEY_F08_			0x42
 %define _KEY_F09_			0x43
 %define _KEY_F10_			0x44
 %define _KEY_PAGEUP_			0x49
 %define _KEY_PAGEDOWN_			0x51
 %define _OFFSET_ALTERNATE_TYPE_	(0xA0*1)+(2*57)
 %define _OFFSET_CURRENT_OFFSET_	(0xA0*1)+(2*17)
 %define _OFFSET_DECODER_ENABLE_	(0xA0*1)+(2*28)
 %define _OFFSET_EDIT_ENABLE_		(0xA0*1)+(2*32)
 %define _OFFSET_FULL_ASCII_		(0xA0*1)+(2*36)

ehex_copyrights:
db "Unununium SDK.EHEX hexadecimal editor version "
db '0'+_VERSION_HIGH_,'.','0'+_VERSION_LOW_,'.','0'+_VERSION_SPECIFIER_,10
db "Copyright (c) 2000-2001, Dave Poirier",10
db "Distributed under the BSD License",0

ehex_screen: dd 0x000B8000
ehex_marker0: dd -1
ehex_marker1: dd -1
ehex_marker2: dd -1
ehex_marker3: dd -1
ehex_marker4: dd -1
ehex_marker5: dd -1
ehex_marker6: dd -1
ehex_marker7: dd -1
ehex_marker8: dd -1
ehex_marker9: dd -1

globalfunc debug.ehex.edit_mem
;------------------------------------------------------------------------------
;>
;; Allow user to view/modify memory directly then return to the caller without
;; affecting any register or flag of the caller's code
;;
;; Parameters:
;;------------
;; ESI = address where to start memory edition
;;
;; Returned values:
;;-----------------
;; EAX = (unmodified)
;; EBX = (unmodified)
;; ECX = (unmodified)
;; EDX = (unmodified)
;; EDI = (unmodified)
;; ESI = (unmodified)
;; ESP = (unmodified)
;; EBP = (unmodified)
;; Flags = (unmodified)
;;
;; Development status: completed (but dependant routines still under dev)
;<
  pushfd
  pushad
  in al, 0x21
  push eax
  or al, 0x02
  out 0x21, al

  mov edx, (_DEFAULT_ALTERNATE_TYPE_*16)+(_DEFAULT_DECODER_ENABLE_*4)+(_DEFAULT_EDIT_ENABLE_*2)+(_DEFAULT_FULL_ASCII_*1)
.start:
  mov eax, esi
  mov ebx, esi
  mov al, 0
  mov bh, bl
  and bl, 0x0F
  shl bl, 1
  shr bh, 4
  
  push ebx	;<-- prepare current_x_pos * 256 + current_y_pos
  push eax	;<-- prepare starting_offset
  push esi	;<-- prepare current_offset
  push eax	;<-- prepare data_source

.back_to_the_editor:
  push edx	;<-- prepare status
	; bit 0		Full Ascii view
	; bit 1		Edit enabled
	; bit 2		Decoder enabled
	; bit 3		reserved
	; bit 7-4	type of alternate output value
	; bit 31-8	reserved

  call _IEHEX_the_editor
    ; EAX = exit code
    ; EBX = offset desired (if eax = 5)
    ; stack(0) = ehex status (keep it!)
  pop edx
  mov esi, ebx
  add esp, byte 16
  test eax, 0xFFFFFF00
  jnz .back_to_the_editor
  cmp al, 0	; Escape pressed
  jz .end
  cmp al, 1	; PageUp
  jz .page_up
  cmp al, 2	; PageDown
  jz .page_down
  cmp al, 5
  jnz short .back_to_the_editor
  jmp short .start

.end:
  pop eax
  out 0x21, al
  popad
  popfd
  retn

.page_up:
  lea esi, [esi - 0x100]
  jmp short .start

.page_down:
  lea esi, [esi + 0x100]
  jmp short .start



_IEHEX_clear_display:
;------------------------------------------------------------------------------
;
; Clear the output display
;
; Parameters:
;------------
; none
;
; Returned values:
;-----------------
; EAX = 0x07200720
; EBX = (unmodified)
; ECX = 0x00000000
; EDX = (unmodified)
; EDI = ehex_screen + 4000
; ESI = (unmodified)
;
; Development status: completed
;
  mov eax, 0x07200720
  mov edi, [ehex_screen]
    .drp000 equ $-4
  mov ecx, 1000
  repz stosd
  retn




_IEHEX_display_hex_byte:
;------------------------------------------------------------------------------
;
; Display the hexadecimal value of AL on the output
;
; Parameters:
;------------
; AL  = byte to display
; EDI = offset where to print out the hex value (note spacing for color char)
;
; Returned values:
;-----------------
; EAX = (undetermined)
; EBX = (unmodified)
; ECX = (unmodified)
; EDX = (unmodified)
; EDI = input value + 4
; ESI = (unmodified)
;
; Development status: completed
;

  push eax
  shr al, 4
  add al, 0x90
  daa
  adc al, 0x40
  daa
  mov [edi], al
  pop eax
  lea edi, [edi + 2]
  and al, 0x0F
  add al, 0x90
  daa
  adc al, 0x40
  daa
  mov [edi], al
  lea edi, [edi + 2]
  retn




_IEHEX_display_hex_dword:
;------------------------------------------------------------------------------
;
; Displays the value of EDX on the output at specified address
;
; Parameters:
;------------
; EDX = dword to display
; EDI = offset to use to output the hex representation (note the spacing for
;       color bytes)
;
; Returned values:
;-----------------
; EAX = (undetermined)
; EBX = (unmodified)
; ECX = (unmodified),CL
;  CL = 0
; EDX = (unmodified)
; EDI = input value + 16
; ESI = (unmodified)
;
; Development status: completed
;

  mov cl, 8
.displaying:
  rol edx, 4
  mov al, dl
  and al, 0x0F
  cmp al, 0x0A
  sbb al, 0x69
  das
  mov [edi], al
  add edi, byte 2
  dec cl
  jnz .displaying
  retn




_IEHEX_display_screen:
;------------------------------------------------------------------------------
;
; Take as input a specially formatted kindof ansi screen and displays it on the
; selected output display.  It can also output simple strings using the label
; _IEHEX_display_screen.direct instead of _IEHEX_display_screen
;
; Parameters:
;------------
; ESI = Pointer to screen to display
; EDI = Pointer to offset to use to print out (when displaying using .direct)
; AH  = Default selected color
;
; Returned values:
;-----------------
; EAX = (undetermined),AX
;  AL  = 0
;  AH  = active color when 0 was reached
; EBX = (undetermined)
; ECX = 0 if repeated char was used, otherwise (unmodified)
; EDX = (undetermined)
; EDI = Offset where the next character would have been displayed
; ESI = Offset to first character after the 0 (NULL) end character
;
; Special notes:
;---------------
; - The 00h character (NULL) is used to terminate the screen
; - The 0Ah character is a linefeed, the equivalent of both CRLF under DOS
; - The 01h character is used to change the current active color.  The first
;   byte after after the marker will be used for the color directly without
;   check or modification
; - The 02h charachter is used to indicate coordinates to use.  This will
;   modify the location on the display where the next characters will be sent.
;   The first byte after the marker is the 'x' coordinate, then comes the 'y'.
; - The 03h character is used for long repeated chain of the same character.
;   The first byte value after the marker is taken as the number of repetition
;   and the second character is used as the actual ascii value.
;
; Development status: to be tested
;
  mov edi, [ehex_screen]
    .drp000 equ $-4

.direct:

.displaying:
  mov al, [esi]
  test al, al
  jz short .end
  inc esi
  cmp al, 0x0A
  jz short .new_line
  cmp al, 0x03
  jbe short .special_char
  mov [edi], ax
  lea edi, [edi + 2]
  jmp short .displaying

.end:
  retn

.special_char:
  cmp al, 0x01
  jz short .change_color
  cmp al, 0x02
  jz short .change_coordinates

  ; the only other possibility is 0x03=repeated char
  xor ecx, ecx
  mov al, [esi + 1]
  mov cl, [esi]
  add esi, byte 2
  repz stosw
  jmp short .displaying

.change_color:
  mov ah, [esi]
  inc esi
  jmp short .displaying

.new_line:
  push eax
  mov eax, edi
  sub eax, [ehex_screen]
    .drp001 equ $-4
  mov ebx, 0xA0
  xor edx, edx
  div ebx
  inc eax
  mul ebx
  mov edi, eax
  add edi, [ehex_screen]
    .drp002 equ $-4
  pop eax
  jmp short .displaying

.change_coordinates:
  push eax
  mov ah, 0xA0
  mov al, [esi + 1]
  xor ebx, ebx
  mul ah
  mov bl, [esi]
  cwde
  add esi, byte 2
  lea edi, [ebx * 2 + eax]
  add edi, [ehex_screen]
    .drp003 equ $-4
  pop eax
  jmp short .displaying



_IEHEX_handler_arrow_down:
;------------------------------------------------------------------------------
;
  mov eax, [ss:esp + 24]
  cmp ah, 0x0F
  stc
  jz .end
  call _IEHEX_xy_pos_compute
  mov eax, esi
  mov ebx, edi
  call _IEHEX_xy_pos_deactivate
  add [ss:esp + 16], dword 0x00000010
  inc byte [ss:esp + 25]
  clc
.end:
  retn

_IEHEX_handler_arrow_left:
;------------------------------------------------------------------------------
;
  mov eax, [ss:esp + 24]
  test al, al
  stc
  jz .end
  push eax
  call _IEHEX_xy_pos_compute
  mov eax, esi
  mov ebx, edi
  call _IEHEX_xy_pos_deactivate
  pop eax
  dec eax
  mov [ss:esp + 24], al
  test al, byte 0x01
  jz .end_clear_cary
  dec dword [ss:esp + 16]
.end_clear_cary:
  clc
.end:
  retn


_IEHEX_handler_arrow_right:
;------------------------------------------------------------------------------
;
  mov eax, [ss:esp + 24]
  cmp al, 0x1F
  stc
  jz .end
  push eax
  call _IEHEX_xy_pos_compute
  mov eax, esi
  mov ebx, edi
  call _IEHEX_xy_pos_deactivate
  pop eax
  inc eax
  mov [ss:esp + 24], al
  test al, byte 0x01
  jnz .end_clear_cary
  inc dword [ss:esp + 16]
.end_clear_cary:
  clc
.end:
  retn

_IEHEX_handler_arrow_up:
;------------------------------------------------------------------------------
;
  mov eax, [ss:esp + 24]
  test ah, ah
  stc
  jz .end
  call _IEHEX_xy_pos_compute
  mov eax, esi
  mov ebx, edi
  call _IEHEX_xy_pos_deactivate
  sub [ss:esp + 16], dword 0x00000010
  dec byte [ss:esp + 25]
  clc
.end:
  retn

_IEHEX_handler_change_alternate_type:
;------------------------------------------------------------------------------
;
  add [ss:esp + 8], byte 0x10
  clc
  retn



_IEHEX_handler_help:
;------------------------------------------------------------------------------
;
  call _IEHEX_clear_display
  lea esi, [ehex_scr_help]
    .drp000 equ $-4
  call _IEHEX_display_screen
.waiting_escape_break:
  call _IEHEX_wait_keypress
  cmp al, 0x81
  jnz .waiting_escape_break
  pop eax
  jmp _IEHEX_the_editor



_IEHEX_handler_jump:
;------------------------------------------------------------------------------
; Jump to specified offset (F5)

  xor edx, edx
.get_next_key:
  mov edi, 0xB8000
  pushad
  call _IEHEX_display_hex_dword
  popad
  call _IEHEX_wait_keypress
  or al, al
  js short .get_next_key
  cmp al, 0x01		; Escape
  jz short .abort
  cmp al, 0x02		; 1
  jb short .get_next_key
  cmp al, 0x0A		; 9
  jbe short .digit
  mov ah, 0
  cmp al, 0x0B		; 0
  jz short .use_ah
  cmp al, 0x1C		; Enter
  jz short .completed
  mov ah, 0x0A
  cmp al, 0x1E		; A
  jz short .use_ah
  inc ah
  cmp al, 0x30		; B
  jz short .use_ah
  inc ah
  cmp al, 0x2E		; C
  jz short .use_ah
  inc ah
  cmp al, 0x20		; D
  jz short .use_ah
  inc ah
  cmp al, 0x12		; E
  jz short .use_ah
  inc ah
  cmp al, 0x21		; F
  jz short .use_ah
  cmp al, 0x0E
  jnz short .get_next_key
  shr edx, 4
  jmp short .get_next_key
.digit:
  dec al
  mov ah, al
.use_ah:
  shl edx, 4
  or dl, ah
  jmp short .get_next_key

.completed:
  mov eax, 5
  mov ebx, edx
  cmp eax, 6	; so that ZF = 0
  stc
  retn
.abort:
  cmp eax, eax
  stc
  retn



_IEHEX_handler_jump_to_marker:
;------------------------------------------------------------------------------
;
;  push dword 0x9802580
;  call __IEDEBUG_step
;  clc
;  retn



_IEHEX_handler_set_marker:
;------------------------------------------------------------------------------
;
;  push dword 0xAB803C45
;  call __IEDEBUG_step
;  clc
;  retn



_IEHEX_handler_toggle_ascii_view:
;------------------------------------------------------------------------------
;
  xor [ss:esp + 8], byte 0x01
  clc
  retn



_IEHEX_handler_toggle_decoder_enable:
;------------------------------------------------------------------------------
;
  xor [ss:esp + 8], byte 0x04
  clc
  retn



_IEHEX_handler_toggle_edit_enable:
;------------------------------------------------------------------------------
;
  xor [ss:esp + 8], byte 0x02
  clc
  retn



_IEHEX_refresh_edition_display:
;------------------------------------------------------------------------------
;
; Update the various byte, offset etc on screen
;
; Parameters:
;------------
; _the_editor.starting_offset
;
; Returned values:
;-----------------
; EAX = (undetermined)
; EBX = (undetermined)
; ECX = (undetermined)
; EDX = (undetermined)
; EDI = (undetermined)
; ESI = (undetermined)
;
; Development status: under development
;

  mov edi, [ehex_screen]
    .drp000 equ $-4
  mov eax, (0xA0*2) + 2
  mov esi, [ss:esp + 20 + 8]	; starting_offset
  push dword [ss:esp + 12 + 8]	; data_source
  lea edi, [edi + eax]
  mov ch, 16

  ;]--Displaying HEX/ASCII fields
.displaying:
  mov edx, esi
  pop esi
  push edx
  call _IEHEX_display_hex_dword
  mov cl, 16
  lea ebx, [edi + 4]
  lea edi, [edi + 4+32+4]
.displaying_ascii_field:
  mov al, [esi]
  mov [ebx], al
  inc esi
  lea ebx, [ebx + 2]
  call _IEHEX_display_hex_byte
  lea edi, [edi + 2]
  dec cl
  jnz .displaying_ascii_field
  lea edi, [edi + 8]
  mov edx, esi
  pop esi
  push edx
  lea esi, [esi + 0x10]
  dec ch
  jnz .displaying
  pop esi

  ;]--Displaying various flags (D:, E:, F:, ...)
  mov ebx, [ehex_screen]
    .drp003 equ $-4
  mov edx, [ss:esp + 8 + 8]

    ;]--Displaying Full ascii view
    mov al, '0'
    push eax
    test dl, 1
    jz .display_full_ascii_view
    inc eax
.display_full_ascii_view:
    mov [ebx + _OFFSET_FULL_ASCII_], al
    pop eax

    ;]--Displaying Edit enabled
    push eax
    test dl, 2
    jz .display_edit_enable
    inc eax
.display_edit_enable:
    mov [ebx + _OFFSET_EDIT_ENABLE_], al
    pop eax

    ;]--Display Decoder enabled
    test dl, 4
    jz .display_decoder_enable
    inc eax
.display_decoder_enable:
    mov [ebx + _OFFSET_DECODER_ENABLE_], al

  ;]--Display current offset
  mov edx, [ss:esp + 16 + 8]
  lea edi, [ebx + _OFFSET_CURRENT_OFFSET_]
  call _IEHEX_display_hex_dword

  ;]--Display alternate type's type :P
  mov al, [ss:esp + 8 + 8]
  shr al, 4
  add al, 0x90
  daa
  adc al, 0x40
  daa
  mov [ebx + _OFFSET_ALTERNATE_TYPE_], al

  retn




_IEHEX_the_editor:
;------------------------------------------------------------------------------
;
; Main edition window & control subroutine.  This routine doesn't manage window
; change; it will return control with an exit code to the caller, which is
; responsible for setting up the new edition window and calling back this
; routine.
;
; Parameters:
;------------
; stack(0) = status
; stack(1) = data_source
; stack(2) = current_offset
; stack(3) = starting_offset
; stack(4) = current_x_pos * 256 + current_y_pos
;
; Returned values:
;-----------------
; EAX = exit code
;   0	= Escape pressed
;   1	= PageUp pressed
;   2	= PageDown pressed
;   3	= Save requested
;   4	= Reload requested
;   5	= Specific offset requested, offset in EBX
; EBX = ???
; ECX = ???
; EDX = ???
; EDI = ???
; ESI = ???
;
; Development status: under development
;

  call _IEHEX_clear_display
  lea esi, [ehex_scr_edition]
    .drp000 equ $-4
  call _IEHEX_display_screen

.editing:
  mov eax, [ss:esp + 20]
  call _IEHEX_xy_pos_compute
  push edi
  push esi
  call _IEHEX_refresh_edition_display
  pop eax
  pop ebx
  call _IEHEX_xy_pos_activate
.wrong_keys:
  call _IEHEX_wait_keypress
  xor ebx, ebx
  cmp al, _KEY_ESCAPE_	;<-- End edition
  jz short .exit_with_code
  inc ebx
  cmp al, _KEY_PAGEUP_	;<-- Go one window before
  jz short .exit_with_code
  inc ebx
  cmp al, _KEY_PAGEDOWN_;<-- Go one window further
  jz short .exit_with_code
  inc ebx
  cmp al, _KEY_F10_	;<-- Save requested
  jz short .exit_with_code
  inc ebx
  cmp al, _KEY_F09_	;<-- Reload requested
  jz short .exit_with_code
  xor ebx, ebx
  call .check_functions
  jnc short .editing
  jz short .wrong_keys
 retn

.exit_with_code:
  mov eax, ebx
  mov ebx, [esp + 8 + 4]
  retn

.check_functions:
  xor ebx, ebx
  lea esi, [.functions_keys]
    .drp001 equ $-4
.checking_functions:
  mov ah, [esi]
  test ah, ah
  jz .failed_finding_function
  cmp al, ah
  jz .call_function
  inc ebx
  inc esi
  jmp short .checking_functions

.failed_finding_function:
  stc
  cmp eax, eax
  retn

.call_function:
  jmp [ebx*4 + .functions_handlers]
    .drp002 equ $-4
  


.functions_keys:
db _KEY_F05_	; (code: 0) Jump to specified offset
db _KEY_F08_	; (code: 1) Change alternate type for value display
db _KEY_F02_	; (code: 2) Toggle Full Ascii View
db _KEY_F04_	; (code: 3) Toggle Edit enable
db _KEY_F03_	; (code: 4) Toggle Decoder enable
db _KEY_F01_	; (code: 5) Help
db _KEY_F06_	; (code: 6) Set Marker
db _KEY_F07_	; (code: 7) Jump to marker
db _KEY_ARROW_UP_	; (code: 8) Move up within current window
db _KEY_ARROW_DOWN_	; (code: 9) Move down within current window
db _KEY_ARROW_LEFT_	; (code: 10) Move left within current window
db _KEY_ARROW_RIGHT_	; (code: 11) Move right within current window
db 0

align 4, db 0
.functions_handlers:
.drp003: dd _IEHEX_handler_jump
.drp004: dd _IEHEX_handler_change_alternate_type
.drp005: dd _IEHEX_handler_toggle_ascii_view
.drp006: dd _IEHEX_handler_toggle_edit_enable
.drp007: dd _IEHEX_handler_toggle_decoder_enable
.drp008: dd _IEHEX_handler_help
.drp009: dd _IEHEX_handler_set_marker
.drp00A: dd _IEHEX_handler_jump_to_marker
.drp00B: dd _IEHEX_handler_arrow_up
.drp00C: dd _IEHEX_handler_arrow_down
.drp00D: dd _IEHEX_handler_arrow_left
.drp00E: dd _IEHEX_handler_arrow_right



;.current_offset: dd 0	; current offset relative to start of object
;.data_source: dd 0	; location in memory where data for current window is
;.starting_offset: dd 0	; offset of current window relative to start of object
;.current_x_pos: db 0	; current X position in the edition window
;.current_y_pos: db 0	; current Y position in the edition window




_IEHEX_wait_keypress:
;------------------------------------------------------------------------------
;
; Waits until a character comes in
;
; Parameters:
;------------
; none
;
; Returned values:
;-----------------
; EAX = AL = scancode
; EBX = (unmodified)
; ECX = (unmodified)
; EDX = (unmodified)
; EDI = (unmodified)
; ESI = (unmodified)
;
; Development status: temporary makeup while waiting for real keyboard handler
;

.wait_input:
  in al, 0x64
  test al, 0x01
  jz .wait_input
  in al, 0x60
  retn




_IEHEX_xy_pos_activate:
;------------------------------------------------------------------------------
;
; Change the color of the character at location x,y on the output screen to the
; _COLOR_ACTIVE_
;
; Parameters:
;------------
; EAX = Pointer to the character in the hex field which have been activated
; EBX = Pointer to the character in the ascii field which have been activated
;
; Returned values:
;-----------------
; EAX = (unmodified)
; EBX = (unmodified)
; ECX = (unmodified)
; EDX = (unmodified)
; EDI = (unmodified)
; ESI = (unmodified)
;
; Development status: to be tested
;

  mov [ebx + 1], byte _COLOR_ACTIVE_
  mov [eax + 1], byte _COLOR_ACTIVE_
  retn




_IEHEX_xy_pos_compute:
;------------------------------------------------------------------------------
;
; Compute the compute physical offset to the current activated character
;
; Parameters:
;------------
; eax = current_x_pos * 256 + current_y_pos
;
; Returned values:
;-----------------
; EAX = (undetermined)
; EBX = (undetermined)
; ECX = (unmodified)
; EDX = (unmodified)
; EDI = Pointer to the active character in the HEX field
; ESI = Pointer to the active character in the ASC field
;
; Development status: to be tested
;

  xor ebx, ebx
  mov bl, ah
  mov bh, al
  xor eax, eax
  mov al, bh
  push eax
  mov esi, [ehex_screen]
    .drp000 equ $-4
  and al, 0xFE
  mov edi, esi
  lea esi, [esi + eax + (_ASC_FIELD_X_ * 2) + (_ASC_FIELD_Y_ * 0xA0)]
  lea edi, [eax * 2 + edi + (_HEX_FIELD_X_ * 2) + (_HEX_FIELD_Y_ * 0xA0)]
  mov bh, 0xA0
  lea edi, [edi + eax]
  mov al, bl
  mul bh
  lea edi, [edi + eax]
  lea esi, [esi + eax]
  pop eax
  test al, 0x01
  jz .end
  lea edi, [edi + 2]
.end:
  retn




_IEHEX_xy_pos_deactivate:
;------------------------------------------------------------------------------
;
; Change the color of the character at location x,y on the output screen to the
; _COLOR_INACTIVE_
;
; Parameters:
;------------
; EAX = Pointer to the previously active character in the HEX field
; EBX = Pointer to the previously active character in the ASC field
;
; Returned values:
;-----------------
; EAX = (unmodified)
; EBX = (unmodified)
; ECX = (unmodified)
; EDX = (unmodified)
; EDI = (unmodified)
; ESI = (unmodified)
;
; Development status: under development
;

  mov [ebx + 1], byte _COLOR_INACTIVE_
  mov [eax + 1], byte _COLOR_INACTIVE_
  retn

ehex_scr_edition:
%include "scr/edition.scr"

ehex_scr_help:
%include "scr/help.scr"
