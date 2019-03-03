;====----------------------------------------------------------------------====
; Microsoft Serial Compatible Mouse Driver     (c)2001 Richard Fillion
; MSLogitech Driver Cell		          Distributed under BSD License
;====----------------------------------------------------------------------====

[bits 32]

section .c_info

version: db 0,0,1,'a'
dd str_cellname
dd str_author
dd str_copyrights

str_cellname: db "Microsoft Serial Mouse Driver",0
str_author: db "Richard Fillion (Raptor-32) - rick@rhix.dhs.org",0
str_copyrights: db "Distributed under BSD license.",0


section .c_init
  mov esi, incoming_data
  xor ebx, ebx
  mov bl, 0x60		;baud rate divisor for 1200baud (serial mouse)
  mov bh, 0x00
  xor eax, eax
  mov al, 1		;com1
  mov cl, 1
;;  externfunc com.enable_port TODO: BROKEN! Fix Me! DevFS enabled code!!

section .text

incoming_data:
	;mouse data looks like this:
	; 7  6  5  4  3  2  1  0   bits
	; 0  1  LB RB Y7 Y6 X7 X6
	; 0  0  X5 X4 X3 X2 X1 X0
	; 0  0  Y5 Y4 Y3 Y2 Y1 Y0


;byte is in AL, start by syncing driver with mouse
  movzx ebx, byte [sync]
  or ebx, 0
  jnz .synced
  ;gotta sync it
  mov bl, al
  and bl, 01000000b
  jz near .not_first
  ;we have first byte, sync this puppy
  mov [byte_num], byte 1
  mov [sync], byte 1

  .synced:
  movzx ebx, byte [byte_num]

  cmp ebx, 2
  jb .byte1
  je near .byte2
  .byte3:

   
  ;once 3rd byte is in, thats when you start doing major stuff
  ;al already = bits 0-5 of Y increment
  mov [byte_num], byte 1
  cmp dword [client], -1
  
  je .get_out
  mov bh, [byte_2] ;bh = bits 0-5 of X increment
  mov bl, [byte_1] ;we have buttons already, so all we need to worry about is:
  		;- bits 6,7 for bits 6 and 7 of Y increment
		;- bits 4, 5 for bits 6 and 7 of X increment

	;mouse data looks like this:
	; 7  6  5  4  3  2  1  0   bits
	; 0  1  LB RB Y7 Y6 X7 X6   bl
	; 0  0  X5 X4 X3 X2 X1 X0   bh
	; 0  0  Y5 Y4 Y3 Y2 Y1 Y0   al
   ;we will use ah for X and bl for Y

   mov ah, bl  ;carbon copy of byte 1
	
   and ah, 00000011b
   shl ah, 6
   or  ah, bh
   ; now AH is X
   and bl, 00001100b
   shl bl, 4
   or  bl, al
   ; now BL is Y

  movsx ecx, bl
  movsx ebx, al
  xor edx, edx
  movzx  eax, byte [right_button]
  rol al, 1
  and al, [left_button]
  call [client]
    
    
  .get_out:
  retn



  .byte1:
  mov [byte_1], al
  ;set the buttons so we can ignore that later
  mov bl, al		;check if it really is byte 1
  and bl, 01000000b
  jz .not_synced
  mov bl, al
  mov cl, al
  and bl, 00100000b
  ;shr bl, 5
  rol bl, 3
  mov [left_button], byte bl
  and cl, 00010000b
  shr cl, 4
  mov [right_button], cl
  inc byte [byte_num]

  retn
  .not_synced:
  mov [byte_num], byte 0
  mov [sync], byte 0
  retn

  .byte2:
  mov [byte_2], al
  mov [byte_num], byte 3
  .not_first:
  retn


;===----[VARIABLES]-----===

right_button: db 0
left_button: db 0

byte_num: db 0
sync: db 0

byte_1: db 0
byte_2: db 0
byte_3: db 0

client: dd -1
