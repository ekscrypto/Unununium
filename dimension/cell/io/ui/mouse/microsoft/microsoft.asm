;; $Header: /cvsroot/uuu/dimension/cell/io/ui/mouse/microsoft/microsoft.asm,v 1.3 2002/01/23 01:51:28 jmony Exp $
;; Microsoft Serial Compatible Mouse Driver
;; MSLogitech Driver Cell
;; Copyright (C) 2001 - Richard Fillion
;; Distributed under BSD License
;; 
;; Current todo list:
;;-------------------
;;   * externfunc com.enable_port - todo DevFS enabled code!!
;;     this means this cell isn't working right now (IMHO - amd)

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================
section .c_info

version: db 0,0,1,'a'
dd str_cellname
dd str_author
dd str_copyrights

str_cellname:   db "Microsoft Serial Mouse Driver",0
str_author:     db "Richard Fillion (Raptor-32) - rick@rhix.dhs.org",0
str_copyrights: db "Distributed under BSD license.",0

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================
section .c_init
global _start
_start:
  mov esi, incoming_data        ; 
  xor ebx, ebx                  ; 
  mov bl, 0x60                  ; baud rate divisor for 1200baud (serial mouse)
  mov bh, 0x00                  ; 
  xor eax, eax                  ; 
  mov al, 1                     ; AL = COM no. (COM1)
  mov cl, 1                     ; 
;;  externfunc com.enable_port TODO: BROKEN! Fix Me! DevFS enabled code!!
  retn
;                                           -----------------------------------
;                                                                     cell code
;==============================================================================
section .text

incoming_data:
;------------------------------------------------------------------------------
                                ;mouse data looks like this:
                                ; 7  6  5  4  3  2  1  0   bits
                                ; 0  1  LB RB Y7 Y6 X7 X6
                                ; 0  0  X5 X4 X3 X2 X1 X0
                                ; 0  0  Y5 Y4 Y3 Y2 Y1 Y0
                                ;byte is in AL, start by syncing 
                                ;driver with mouse

  movzx ebx, byte [sync]        ; move [sync] to EBX and pad it with zeros
  or ebx, 0                     ; if is [sync] zero, then sync it
  jnz .synced                   ; gotta sync it

  mov bl, al                    ; move byte to BL, to leave AL unchanged
  and bl, 01000000b             ; bit6 of first byte is always set
  jz near .not_first            ; we have first byte, sync this puppy

  mov [byte_num], byte 1        ; store the byte and take next byte
  mov [sync], byte 1            ; set synced flag

  .synced:                      
  movzx ebx, byte [byte_num]    ; next byte...

  cmp ebx, 2                    ; check if next byte
  jb .byte1                     ; wow, first byte
  je near .byte2                ; yes, it's second
  .byte3:                       ; 
                                ; once 3rd byte is in, thats when 
                                ; you start doing major stuff
                                ; al already = bits 0-5 of Y increment
				;
  mov [byte_num], byte 1	; byte 1 ok
  cmp dword [client], -1        ; check if we have client function
  je .get_out                   ; no! then let's get out
				;
  mov bh, [byte_2]              ;bh = bits 0-5 of X increment
  mov bl, [byte_1]              ;buttons done, so all we need to worry about is:
                                ;- bits 6,7 for bits 6 and 7 of Y increment
                                ;- bits 4, 5 for bits 6 and 7 of X increment
                                ;----------------------------------------------
                                ;mouse data looks like this:
                                ; 7  6  5  4  3  2  1  0   bits
                                ; 0  1  LB RB Y7 Y6 X7 X6   bl
                                ; 0  0  X5 X4 X3 X2 X1 X0   bh
                                ; 0  0  Y5 Y4 Y3 Y2 Y1 Y0   al
                                ;we will use ah for X and bl for Y
  mov ah, bl                    ;carbon copy of byte 1

  and ah, 00000011b             ; decode X coordinate...
  shl ah, 6                     ; multiply by 2^6 (ah = 64*ah)
  or  ah, bh                    ; now AH is X
  and bl, 00001100b             ; decode Y coordinate...
  shl bl, 4                     ; multiply by 2^4 (bl = 16*bl)
  or  bl, al                    ; now BL is Y

  movsx ecx, bl                 ; move X to ECX
  movsx ebx, al                 ; move Y to EBX
  xor edx, edx                  ; set EDX to 0
  movzx eax, byte [right_button] ; move r button value to EAX, actually (AL)
  rol al, 1                     ; move right button bit to left button
  and al, [left_button]         ; and set [left_button]
  call [client]                 ; call client function...
    
  .get_out:                     ; 
  retn                          ; and exit

  .byte1:
  mov [byte_1], al              ; set the byte 1 so we can ignore that later
  mov bl, al                    ; check if it really is byte 1
  and bl, 01000000b             ; check if bit 6 is set
  jz .not_synced                ; bit 6 is always set in first byte

  mov bl, al                    ; BL will contain value for Left Button
  mov cl, al                    ; CL for Right Button
  and bl, 00100000b             ; Set only bit 5 which contains the LB data
  ;shr bl, 5                    ; 
  rol bl, 3                     ; move bit5 to bit0
  mov [left_button], byte bl    ; and finally store it to [left_button]
  and cl, 00010000b             ; Bit4 contains the RB flag
  shr cl, 4                     ; move bit4 to bit0...
  mov [right_button], cl        ; and finally store it to [right_button]
  inc byte [byte_num]           ; go to next byte
  retn

  .not_synced:
  mov [byte_num], byte 0        ; if not synced, start with byte 0
  mov [sync], byte 0            
  retn                          

  .byte2:
  mov [byte_2], al              ; AL contains byte 2 information
  mov [byte_num], byte 3        ; Move to byte 3
  .not_first:                   ;
  retn                                  

;                                           -----------------------------------
;                                                                     cell data
;==============================================================================
section .data

right_button:   db 0		; Contains Information for Right Button
left_button:    db 0		; and for Left Button

byte_num:       db 0		; used to track, which byte is next
sync:           db 0		; flag to see if mouse is synced 

byte_1:         db 0            ; 3 bytes of data from mouse...
byte_2:         db 0            ; ...
byte_3:         db 0            ; ...containing valuable data

client:         dd -1           ; Client function address
