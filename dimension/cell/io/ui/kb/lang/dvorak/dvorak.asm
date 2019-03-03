;; $Header:
;;
;; Keycode->UTF-8 english keyboard cell
;; By EKS - Dave Poirier (instinc@users.sourceforge.net)
;; Distributed under the BSD License
;;
;; This cell provides a kbd.set_unicode_client function and uses originally the
;; 'dragon' cell's kbd.set_keycode_client function to receives notification of
;; keycodes coming in.
;;
;; The unicode client hooked to this cell will be called with the following
;; paramters:
;;
;;   AL = UTF-8 byte
;;   EBX = modifiers
;;         bit 0: left shift
;;	   bit 1: right shift
;;	   bit 2: capslock
;;	   bit 3: left alt
;;	   bit 4: right alt
;;	   bit 5: left ctrl
;;	   bit 6: right ctrl
;;	   bit 7: numlock
;;
;; If a unicode value longer than 1 character needs to be sent, successive
;; calls will be made to the client will be made.
;;
;; Initialization specifics:
;;--------------------------
;; Make sure that the 'dragon' cell or a compatible cell is loaded in memory
;; prior to loading this cell.

section .c_info
  db 1,0,0,'b'
  dd str_title
  dd str_author
  dd str_copyright

  str_title: db "Dragon-Language/Dvorak",0
  str_author: db "indigo",0
  str_copyright: db "BSD Licensed",0

section .text


%define mod_lshift	0x01
%define mod_rshift	0x02
%define mod_lalt	0x04
%define mod_ralt	0x08
%define mod_lctrl	0x10
%define mod_rctrl	0x20
%define mod_capslock	0x40
%define mod_numlock	0x80

section .c_init
global _start
_start:
  mov esi, _keycode_client
  externfunc kbd.set_keycode_client
  retn

section .data

keyboard:
.selector: dd .keycodes
.modifiers: dd 0
.client: dd null_client

.keycodes:
 db 0		; keycode 00: nil
 db 0x1B	; keycode 01: escape
 db 0x80	; keycode 02: F1  [escape sequence: ^[[11~ ]
 db 0x81	; keycode 03: F2  [escape sequence: ^[[12~ ]
 db 0x82	; keycode 04: F3  [escape sequence: ^[[13~ ]
 db 0x83	; keycode 05: F4  [escape sequence: ^[[14~ ]
 db 0x84	; keycode 06: F5  [escape sequence: ^[[15~ ]
 db 0x85	; keycode 07: F6  [escape sequence: ^[[17~ ]
 db 0x86	; keycode 08: F7  [escape sequence: ^[[18~ ]
 db 0x87	; keycode 09: F8  [escape sequence: ^[[19~ ]
 db 0x88	; keycode 0A: F9  [escape sequence: ^[[20~ ]
 db 0x89	; keycode 0B: F10 [escape sequence: ^[[21~ ]
 db 0x8A	; keycode 0C: F11 [escape sequence: ^[[23~ ]
 db 0x8B	; keycode 0D: F12 [escape sequence: ^[[24~ ]
 db 0x60	; keycode 0E: `
 db 0x31	; keycode 0F: 1
 db 0x32	; keycode 10: 2
 db 0x33	; keycode 11: 3
 db 0x34	; keycode 12: 4
 db 0x35	; keycode 13: 5
 db 0x36	; keycode 14: 6
 db 0x37	; keycode 15: 7
 db 0x38	; keycode 16: 8
 db 0x39	; keycode 17: 9
 db 0x30	; keycode 18: 0
 db '['		; keycode 19: -
 db ']'		; keycode 1A: =
 db 0x08	; keycode 1B: BackSpace
 db 0x09	; keycode 1C: HorizontalTab
 db "'"		; keycode 1D: q
 db ','		; keycode 1E: w
 db '.'		; keycode 1F: e
 db 'p'		; keycode 20: r
 db 'y'		; keycode 21: t
 db 'f'		; keycode 22: y
 db 'g'		; keycode 23: u
 db 'c'		; keycode 24: i
 db 'r'		; keycode 25: o
 db 'l'		; keycode 26: p
 db '/'		; keycode 27: [
 db '='		; keycode 28: ]
 db 0x5C	; keycode 29: \
 db 0xE6	; keycode 2A: CapsLock [modifier]
 db 'a'		; keycode 2B: a
 db 'o'		; keycode 2C: s
 db 'e'		; keycode 2D: d
 db 'u'		; keycode 2E: f
 db 'i'		; keycode 2F: g
 db 'd'		; keycode 30: h
 db 'h'		; keycode 31: j
 db 't'		; keycode 32: k
 db 'n'		; keycode 33: l
 db 's'		; keycode 34: ;
 db '-'		; keycode 35: '
 db 0x0A	; keycode 36: Enter (LineFeed)
 db 0xE0	; keycode 37: LeftShift [modifier]
 db ';'		; keycode 38: z
 db 'q'		; keycode 39: x
 db 'j'		; keycode 3A: c
 db 'k'		; keycode 3B: v
 db 'x'		; keycode 3C: b
 db 'b'		; keycode 3D: n
 db 'm'		; keycode 3E: m
 db 'w'		; keycode 3F: ,
 db 'v'		; keycode 40: .
 db 'z'		; keycode 41: /
 db 0xE1	; keycode 42: RightShift [modifier]
 db 0xE4	; keycode 43: LeftCTRL [modifier]
 db 0x8C	; keycode 44: Left 'System' key [escape sequence: ^[[3S ]
 db 0xE2	; keycode 45: LeftALT [modifier]
 db 0x20	; keycode 46: Space
 db 0xE3	; keycode 47: RightALT [modifier]
 db 0x8D	; keycode 48: 'Menu' key [escape sequence: ^[[4S ]
 db 0x8E	; keycode 49: Right 'System' key [escape sequence: ^[[5S ]
 db 0xE5	; keycode 4A: RightCTRL [modifier]
 db 0		; keycode 4B: unassigned
 db 0		; keycode 4C: unassigned
 db 0		; keycode 4D: unassigned
 db 0		; keycode 4E: unassigned
 db 0		; keycode 4F: unassigned
 db 0		; keycode 50: unassigned
 db 0xE7	; keycode 51: NumLock [modifier]
 db 0xD5	; keycode 52: Keypad / :: ^[Oo
 db 0xD0	; keycode 53: keypad * :: ^[Oj
 db 0xD3	; keycode 54: keypad - :: ^[Om
 db 0xDD	; keycode 55: keypad 7 :: ^[Ow
 db 0xDE	; keycode 56: keypad 8 :: ^[Ox
 db 0xDF	; keycode 57: keypad 9 :: ^[Oy
 db 0xDA	; keycode 58: keypad 4 :: ^[Ot
 db 0xDB	; keycode 59: keypad 5 :: ^[Ou
 db 0xDC	; keycode 5A: keypad 6 :: ^[Ov
 db 0xD1	; keycode 5B: keypad + :: ^[Ok
 db 0xD7	; keycode 5C: keypad 1 :: ^[Oq
 db 0xD8	; keycode 5D: keypad 2 :: ^[Or
 db 0xD9	; keycode 5E: keypad 3 :: ^[Os
 db 0xD6	; keycode 5F: keypad 0 :: ^[Op
 db 0xD4	; keycode 60: keypad . :: ^[On
 db 0xD2	; keycode 61: keypad Enter :: ^[OM
 db 0x8F	; keycode 62: Insert      [escape sequence: ^[[2~ ]
 db 0x90	; keycode 63: Delete      [escape sequence: ^[[3~ ]
 db 0x91	; keycode 64: Home        [escape sequence: ^[[4~ ]
 db 0x92	; keycode 65: End         [escape sequence: ^[[5~ ]
 db 0x93	; keycode 66: PageUp      [escape sequence: ^[[6~ ]
 db 0x94	; keycode 67: PageDn      [escape sequence: ^[[7~ ]
 db 0x95	; keycode 68: UpArrow     [escape sequence: ^[[A  ]
 db 0x96	; keycode 69: LeftArrow   [escape sequence: ^[[D  ]
 db 0x97	; keycode 6A: DownArrow   [escape sequence: ^[[B  ]
 db 0x98	; keycode 6B: RightArrow  [escape sequence: ^[[C  ]
 db 0x99	; keycode 6C: PrintScreen [escape sequence: ^[[0S ]
 db 0x9A	; keycode 6D: ScrollLock  [escape sequence: ^[[1S ]
 db 0x9B	; keycode 6E: Pause       [escape sequence: ^[[2S ]
.keycode_size equ $- .keycodes

.shift:
 db 0		; keycode 00: nil
 db 0x1B	; keycode 01: escape
 db 0x8A	; keycode 02: F11  [escape sequence: ^[[23~ ]
 db 0x8B	; keycode 03: F12  [escape sequence: ^[[24~ ]
 db 0x9C	; keycode 04: F13  [escape sequence: ^[[25~ ]
 db 0x9D	; keycode 05: F14  [escape sequence: ^[[26~ ]
 db 0x9E	; keycode 06: F15  [escape sequence: ^[[28~ ]
 db 0x9F	; keycode 07: F16  [escape sequence: ^[[29~ ]
 db 0xA0	; keycode 08: F17  [escape sequence: ^[[31~ ]
 db 0xA1	; keycode 09: F18  [escape sequence: ^[[32~ ]
 db 0xA2	; keycode 0A: F19  [escape sequence: ^[[33~ ]
 db 0xA3	; keycode 0B: F20  [escape sequence: ^[[34~ ]
 db 0xA4	; keycode 0C: F21  [escape sequence: ^[[23$ ]
 db 0xA5	; keycode 0D: F22  [escape sequence: ^[[24$ ]
 db 0x7E	; keycode 0E: ~
 db 0x21	; keycode 0F: !
 db 0x40	; keycode 10: @
 db 0x23	; keycode 11: #
 db 0x24	; keycode 12: $
 db 0x25	; keycode 13: %
 db 0x5E	; keycode 14: ^
 db 0x26	; keycode 15: &
 db 0x2A	; keycode 16: *
 db 0x28	; keycode 17: (
 db 0x29	; keycode 18: )
 db '{'		; keycode 19: _
 db '}'		; keycode 1A: +
 db 0x08	; keycode 1B: BackSpace
 db 0x09	; keycode 1C: HorizontalTab
 db '"'		; keycode 1D: Q
 db '<'		; keycode 1E: W
 db '>'		; keycode 1F: E
 db 'P'		; keycode 20: R
 db 'Y'		; keycode 21: T
 db 'F'		; keycode 22: Y
 db 'G'		; keycode 23: U
 db 'C'		; keycode 24: I
 db 'R'		; keycode 25: O
 db 'L'		; keycode 26: P
 db '?'		; keycode 27: {
 db '+'		; keycode 28: }
 db 0x7C	; keycode 29: |
 db 0xE6	; keycode 2A: CapsLock [modifier]
 db 'A'		; keycode 2B: A
 db 'O'		; keycode 2C: S
 db 'E'		; keycode 2D: D
 db 'U'		; keycode 2E: F
 db 'I'		; keycode 2F: G
 db 'D'		; keycode 30: H
 db 'H'		; keycode 31: J
 db 'T'		; keycode 32: K
 db 'N'		; keycode 33: L
 db 'S'		; keycode 34: :
 db '_'		; keycode 35: "
 db 0x0A	; keycode 36: Enter (LineFeed)
 db 0xE0	; keycode 37: LeftShift [modifier]
 db ':'		; keycode 38: Z
 db 'Q'		; keycode 39: X
 db 'J'		; keycode 3A: C
 db 'K'		; keycode 3B: V
 db 'X'		; keycode 3C: B
 db 'B'		; keycode 3D: N
 db 'M'		; keycode 3E: M
 db 'W'		; keycode 3F: <
 db 'V'		; keycode 40: >
 db 'Z'		; keycode 41: ?
 db 0xE1	; keycode 42: RightShift [modifier]
 db 0xE4	; keycode 43: LeftCTRL [modifier]
 db 0x8C	; keycode 44: Left 'System' key [escape sequence: ^[[3S ]
 db 0xE2	; keycode 45: LeftALT [modifier]
 db 0x20	; keycode 46: Space
 db 0xE3	; keycode 47: RightALT [modifier]
 db 0x8D	; keycode 48: 'Menu' key [escape sequence: ^[[4S ]
 db 0x8E	; keycode 49: Right 'System' key [escape sequence: ^[[5S ]
 db 0xE5	; keycode 4A: RightCTRL [modifier]
 db 0		; keycode 4B: unassigned
 db 0		; keycode 4C: unassigned
 db 0		; keycode 4D: unassigned
 db 0		; keycode 4E: unassigned
 db 0		; keycode 4F: unassigned
 db 0		; keycode 50: unassigned
 db 0xE7	; keycode 51: NumLock [modifier]
 db 0xD5	; keycode 52: Keypad / :: ^[Oo
 db 0xD0	; keycode 53: keypad * :: ^[Oj
 db 0xD3	; keycode 54: keypad - :: ^[Om
 db 0xDD	; keycode 55: keypad 7 :: ^[Ow
 db 0xDE	; keycode 56: keypad 8 :: ^[Ox
 db 0xDF	; keycode 57: keypad 9 :: ^[Oy
 db 0xDA	; keycode 58: keypad 4 :: ^[Ot
 db 0xDB	; keycode 59: keypad 5 :: ^[Ou
 db 0xDC	; keycode 5A: keypad 6 :: ^[Ov
 db 0xD1	; keycode 5B: keypad + :: ^[Ok
 db 0xD7	; keycode 5C: keypad 1 :: ^[Oq
 db 0xD8	; keycode 5D: keypad 2 :: ^[Or
 db 0xD9	; keycode 5E: keypad 3 :: ^[Os
 db 0xD6	; keycode 5F: keypad 0 :: ^[Op
 db 0xD4	; keycode 60: keypad . :: ^[On
 db 0xD2	; keycode 61: keypad Enter :: ^[OM
 db 0xA6	; keycode 62: Insert      [escape sequence: ^[[2$ ]
 db 0xA7	; keycode 63: Delete      [escape sequence: ^[[3$ ]
 db 0xA8	; keycode 64: Home        [escape sequence: ^[[7$ ]
 db 0xA9	; keycode 65: End         [escape sequence: ^[[8$ ]
 db 0xAA	; keycode 66: PageUp      [escape sequence: ^[[5$ ]
 db 0xAB	; keycode 67: PageDn      [escape sequence: ^[[6$ ]
 db 0xAC	; keycode 68: UpArrow     [escape sequence: ^[[a  ]
 db 0xAD	; keycode 69: LeftArrow   [escape sequence: ^[[d  ]
 db 0xAE	; keycode 6A: DownArrow   [escape sequence: ^[[b  ]
 db 0xAF	; keycode 6B: RightArrow  [escape sequence: ^[[c  ]
 db 0x99	; keycode 6C: PrintScreen [escape sequence: ^[[0S ]
 db 0x9A	; keycode 6D: ScrollLock  [escape sequence: ^[[1S ]
 db 0x9B	; keycode 6E: Pause       [escape sequence: ^[[2S ]
;----

.numlock_off_keys:
 db 0xB0	; * -> ^[Oj
 db 0xB1	; + -> ^[Ok
 db 0xBF	; Enter -> ^[OM
 db 0xB2	; - -> ^[Om
 db 0xB3	; . -> ^[On
 db 0xB4	; / -> ^[Oo
 db 0xB5	; 0 -> ^[Op
 db 0xB6	; 1 -> ^[Oq
 db 0xB7	; 2 -> ^[Or
 db 0xB8	; 3 -> ^[Os
 db 0xB9	; 4 -> ^[Ot
 db 0xBA	; 5 -> ^[Ou
 db 0xBB	; 6 -> ^[Ov
 db 0xBC	; 7 -> ^[Ow
 db 0xBD	; 8 -> ^[Ox
 db 0xBE	; 9 -> ^[Oy

align 4, db 0

.escape_sequences:
dd 0x31315B1B,0x0000007E	; 80: ^[[11~
dd 0x32315B1B,0x0000007E	; 81: ^[[12~
dd 0x33315B1B,0x0000007E	; 82: ^[[13~
dd 0x34315B1B,0x0000007E	; 83: ^[[14~
dd 0x35315B1B,0x0000007E	; 84: ^[[15~
dd 0x37315B1B,0x0000007E	; 85: ^[[17~
dd 0x38315B1B,0x0000007E	; 86: ^[[18~
dd 0x39315B1B,0x0000007E	; 87: ^[[19~
dd 0x30325B1B,0x0000007E	; 88: ^[[20~
dd 0x31325B1B,0x0000007E	; 89: ^[[21~
dd 0x33325B1B,0x0000007E	; 8A: ^[[23~
dd 0x34325B1B,0x0000007E	; 8B: ^[[24~
dd 0x33305B1B,0x00000053	; 8C: ^[[03S
dd 0x34305B1B,0x00000053	; 8D: ^[[04S
dd 0x35305B1B,0x00000053	; 8E: ^[[05S
dd 0x7E325B1B,0x00000000	; 8F: ^[[2~
dd 0x7E335B1B,0x00000000	; 90: ^[[3~
dd 0x7E345B1B,0x00000000	; 91: ^[[4~
dd 0x7E355B1B,0x00000000	; 92: ^[[5~
dd 0x7E365B1B,0x00000000	; 93: ^[[6~
dd 0x7E375B1B,0x00000000	; 94: ^[[7~
dd 0x00415B1B,0x00000000	; 95: ^[[A
dd 0x00445B1B,0x00000000	; 96: ^[[D
dd 0x00425B1B,0x00000000	; 97: ^[[B
dd 0x00435B1B,0x00000000	; 98: ^[[C
dd 0x30305B1B,0x00000053	; 99: ^[[00S
dd 0x31305B1B,0x00000053	; 9A: ^[[01S
dd 0x32305B1B,0x00000053	; 9B: ^[[02S
dd 0x35325B1B,0x0000007E	; 9C: ^[[25~
dd 0x36325B1B,0x0000007E	; 9D: ^[[26~
dd 0x38325B1B,0x0000007E	; 9E: ^[[28~
dd 0x39325B1B,0x0000007E	; 9F: ^[[29~
dd 0x31335B1B,0x0000007E	; A0: ^[[31~
dd 0x32335B1B,0x0000007E	; A1: ^[[32~
dd 0x33335B1B,0x0000007E	; A2: ^[[33~
dd 0x34335B1B,0x0000007E	; A3: ^[[34~
dd 0x33325B1B,0x00000024	; A4: ^[[23$
dd 0x34325B1B,0x00000024	; A5: ^[[24$
dd 0x24325B1B,0x00000000	; A6: ^[[2$
dd 0x24335B1B,0x00000000	; A7: ^[[3$
dd 0x24375B1B,0x00000000	; A8: ^[[7$
dd 0x24385B1B,0x00000000	; A9: ^[[8$
dd 0x24355B1B,0x00000000	; AA: ^[[5$
dd 0x24365B1B,0x00000000	; AB: ^[[6$
dd 0x00615B1B,0x00000000	; AC: ^[[a
dd 0x00645B1B,0x00000000	; AD: ^[[d
dd 0x00625B1B,0x00000000	; AE: ^[[b
dd 0x00635B1B,0x00000000	; AF: ^[[c
dd 0x006A4F1B,0x00000000	; B0: ^[Oj
dd 0x006B4F1B,0x00000000	; B1: ^[Ok
dd 0x006D4F1B,0x00000000	; B2: ^[Om
dd 0x006E4F1B,0x00000000	; B3: ^[On
dd 0x006F4F1B,0x00000000	; B4: ^[Oo
dd 0x00704F1B,0x00000000	; B5: ^[Op
dd 0x00714F1B,0x00000000	; B6: ^[Oq
dd 0x00724F1B,0x00000000	; B7: ^[Or
dd 0x00734F1B,0x00000000	; B8: ^[Os
dd 0x00744F1B,0x00000000	; B9: ^[Ot
dd 0x00754F1B,0x00000000	; BA: ^[Ou
dd 0x00764F1B,0x00000000	; BB: ^[Ov
dd 0x00774F1B,0x00000000	; BC: ^[Ow
dd 0x00784F1B,0x00000000	; BD: ^[Ox
dd 0x00794F1B,0x00000000	; BE: ^[Oy
dd 0x004D4F1B,0x00000000	; BF: ^[OM


section .text
release_keycode:
  neg eax
  cmp eax, byte keyboard.keycode_size
  mov ebx, [keyboard.selector]
  jnb short .exit

  mov al, byte [eax + ebx]
  sub al, 0xE0
  jb short .exit

  push ecx
  mov cl, al
  mov eax, 0xFFFFFFFE
  rol eax, cl
  cmp cl, 6
  pop ecx
  jnb short .exit
  mov ebx, [keyboard.modifiers]
  and ebx, eax
  mov eax, ebx
  jmp near _keycode_client.select_keymap

.exit:
  retn

_keycode_client:
  test eax, eax
  js short release_keycode

  cmp eax, byte keyboard.keycode_size
  mov ebx, [keyboard.selector]
  jnb short release_keycode.exit

  mov al, byte [eax + ebx]

.analyze_key:
  test al, al
  js short .special_make_code

  mov ebx, [keyboard.modifiers]
  test bl, byte mod_lalt + mod_ralt
  jz short .send_single_unicode

  ; prefix with ^[
  push eax
  mov al, 0x1B
  push ebx
  call [keyboard.client]
  pop ebx
  pop eax

.send_single_unicode:
  test bl, mod_lctrl + mod_rctrl
  jz short .send_to_client
  call convert_control
.send_to_client:
  jmp [keyboard.client]


.special_make_code:

  cmp al, 0xD0
  jb short .escape_sequence

  sub al, 0xE0
  jb near .keypad_keys

  ; modifiers
  push ecx
  mov cl, al
  mov eax, 1
  rol eax, cl
  cmp cl, 6
  pop ecx
  jnb short .locked_modifiers
  or eax, [keyboard.modifiers]
.select_keymap:
  mov ebx, keyboard.shift
  test al, mod_rshift + mod_lshift
  jz short .unshifted_map_test
  test al, mod_capslock
  jz short .map_selected
.unshifted_map:
  mov ebx, keyboard.keycodes
  jmp short .map_selected
.unshifted_map_test:
  test al, mod_capslock
  jz short .unshifted_map
.map_selected:
  mov [keyboard.selector], ebx
.modifiers_update:
  mov [keyboard.modifiers], eax
.exit2:
  retn

.locked_modifiers:
  xor eax, [keyboard.modifiers]
  jmp short .modifiers_update

.escape_sequence:
  test [keyboard.modifiers], byte mod_lalt + mod_ralt
  jz short .send_escape_sequence

  ; prefix with ^[
  push eax
  mov ebx, [keyboard.modifiers]
  mov al, 0x1B
  call [keyboard.client]
  pop eax

.send_escape_sequence:
  sub al, 0x80
  movzx eax, al
  lea ebx, [keyboard.escape_sequences + eax*8]
.processing_escape_sequence:
  mov al, [ebx]
  test al, al
  jz short .exit2
  push ebx
  mov ebx, [keyboard.modifiers]
  test bl, mod_lctrl + mod_rctrl
  jz short .send_sequence_char
  cmp al, '$'
  jnz short .test_for_tilt
  mov al, '@'
  jmp short .send_sequence_char
.test_for_tilt:
  cmp al, '~'
  jnz short .send_sequence_char
  mov al, '$'
.send_sequence_char:
  call [keyboard.client]
  pop ebx
  inc ebx
  jmp short .processing_escape_sequence

.keypad_keys:
  test byte [keyboard.modifiers], byte mod_numlock
  jz short .numlock_off

  test byte [keyboard.modifiers], byte mod_lshift+mod_rshift
  jnz short .keypad_forced_off
.keypad_forced_on:
  add al, 0xE0-(0xD6-0x30)
  jmp near .analyze_key

.numlock_off:
  test byte [keyboard.modifiers], byte mod_lshift+mod_rshift
  jnz short .keypad_forced_on
.keypad_forced_off:
  add al, 0x10
  movzx eax, al
  mov al, [keyboard.numlock_off_keys + eax]
  jmp near .analyze_key

convert_control:
  cmp al, '@'
  jb short .converted
  cmp al, '_'
  jbe short .convert_it
  cmp al, 'z'
  ja short .converted
  sub al, 0x20
.convert_it:
  sub al, 0x40
.converted:
null_client:
  retn








globalfunc kbd.set_unicode_client
;------------------------------------------------------------------------------
;>
;; Allows to set the keyboard unicode (UTF-8) client
;;
;; parameters:
;;------------
;; esi = client's address (-1 to disconnect)
;;
;; returned value:
;;----------------
;; none, always successful
;<
;------------------------------------------------------------------------------
  inc esi
  jnz short .set_client

  mov esi, null_client + 1

.set_client:
  dec esi
  mov [keyboard.client], esi
  retn
;------------------------------------------------------------------------------

