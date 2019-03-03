[bits 32]

%include "vid/kbd.inc"
%include "vid/gfx.render.13h.inc"
%include "vid/debug.diable.inc"
%include "vid/mem.inc"

NULL          EQU 00000000b
WALL          EQU 00000001b
EMPTY         EQU 00000010b
TARGET        EQU 00000011b
BOX           EQU 00000100b
SET           EQU 00000101b
PLAYER_EMPTY  EQU 00000110b
PLAYER_TARGET EQU 00000111b
UN            EQU 00000000b
UW            EQU 00010000b
UE            EQU 00100000b
UT            EQU 00110000b
UB            EQU 01000000b
US            EQU 01010000b
UP            EQU 01100000b
UG            EQU 01110000b
LN            EQU 00000000b
LW            EQU 00000001b
LE            EQU 00000010b
LT            EQU 00000011b
LB            EQU 00000100b
LS            EQU 00000101b
LP            EQU 00000110b
LG            EQU 00000111b

 global app_boxed_in
 app_boxed_in:
 mov BYTE [QuitGame],0
 
 call SetPalette
 call Set_level_up
 call Unpack_level
 call Draw_level

 mov esi,KeyboardProc
 externfunc kbd.set_unicode_client

MainLoop:
 cmp BYTE [QuitGame],0
 je MainLoop
 retn
  
 %include "control.asm"
 %include "gfx.asm"
 %include "level.asm"



