; $Header: /cvsroot/uuu/uuu/distro/XGS/osw.asm,v 1.18 2001/10/26 17:18:04 daboy Exp $

[bits 32]

%include "vid/realmode.inc"
%include "vid/kbd.inc"
%include "vid/gfx.render.13h.inc"

section .osw_pre_init

extern __CORE_HEADER__

os_init:
  ;]--Initialize DS/ES and clear screen
  mov eax, 0x07200720   ;- clear screen
  mov edi, 0x000B8000   ; set pointer to color text area
  mov ecx, 1000         ; set screen length
  repz stosd            ; color text mode completed

  ;mov [byte edi - 6], dword 0x0946075B
  ;mov [byte edi - 2], word 0x075D

  mov al, 0xFF
  out 0x21, al
  out 0xA1, al

  mov esi, __CORE_HEADER__	; point to core header
  xor eax, eax			; clear all init options

;                                           -----------------------------------
;                                                        section .osw_post_init
;==============================================================================

section .osw_post_init

%define _RIGHT_OFFSET_		105	; how far to the right the menu is
%define _DOWN_OFFSET_		76	; how far down the menu is
%define _MAX_MENU_PLACE_	4	; the number of menu items - 1
extern app_xgs_test
extern app_log_browser
extern app_boxed_in
extern app_ttt

set_13h:
  push dword 0xFFFF0010			;
  mov ax, 0x13				;set mode 0x13
  externfunc realmode.proc_call

  pop eax				;pop the 0x10

  xor eax, eax
  mov ecx, 320*200/4
  mov edi, 0xa0000
  rep stosd				; black out the screen

set_keyboard_client:
  mov esi, kbd_client
  externfunc kbd.set_unicode_client

display_xgs:
  mov edi, 0xa0000+320*3+148
  mov esi, strings.xgs
  mov al, 0xf
  externfunc gfx.render.13h.string

display_menu:
  mov edi, 0xa0000+320*_DOWN_OFFSET_+_RIGHT_OFFSET_
  mov esi, strings.menu
  mov al, 4
  externfunc gfx.render.13h.string

display_bullet:
  mov al, 0xf
  call _draw_bullet

wait_for_something_to_happen:
  mov ebp, [call_me]
  test ebp, ebp
  jz wait_for_something_to_happen

  ;yay, something happened!
  xor esi, esi
  dec esi
  externfunc kbd.set_unicode_client
  
  call ebp
  
  xor ebp, ebp
  mov [call_me], ebp

  jmp set_13h


kbd_client:
  pushad

  cmp eax, 0x80000003		; down arrow
  je .down

  cmp eax, 0x80000001		; up arrow
  je .up

  cmp eax, 0xD			; enter
  je .enter

  popad
  retn
  
.down:
  cmp byte[data.bullet_place], _MAX_MENU_PLACE_
  jae .retn
  
  xor eax, eax
  call _draw_bullet		; black out bullet
  inc byte [data.bullet_place]
  mov al, 0xf
  call _draw_bullet		; black out bullet

  popad
  retn

.up:
  cmp byte[data.bullet_place], 0
  jbe .retn
  
  xor eax, eax
  call _draw_bullet		; black out bullet
  dec byte [data.bullet_place]
  mov al, 0xf
  call _draw_bullet		; black out bullet

  popad
  retn

.enter:
  movzx eax, byte[data.bullet_place]
  shl eax, 2
  mov eax, [data.menu_calls+eax]
  mov [call_me], eax
.retn:  
  popad
  retn


_draw_bullet:
; draws the bullet with color in AL
  mov edi, 0xa0000+320*_DOWN_OFFSET_+_RIGHT_OFFSET_-10
  movzx ebp, byte[data.bullet_place]
  lea ebp, [ebp*5]
  shl ebp, 6			; mul ebp by 320
  lea esi, [ebp+ebp]
  shl ebp, 4
  sub ebp, esi			; and now by 14
  add edi, ebp			; and add it to the offset
  mov esi, strings.bullet
  externfunc gfx.render.13h.string
  retn

_log_browser_wrapper:
  push dword 0xFFFF0010			; set mode 3 for it
  mov ax, 3				;
  externfunc realmode.proc_call	;
  pop eax				;
  call app_log_browser
  retn

_reboot:
  mov al,0FEh
  out 64h,al
  mov al,1h
  out 92h,al
; should have rebooted, but lock to be sure
  cli
  jmp short $
  
;==============================================================================
;                                                                          data
;                                        --------------------------------------

str_completed: db "                  [http://uuu.sf.net] -- init completed, yahoo!",0
strings:
  .menu:
    db "Hydro3D demo",0xa
    db "Boxed In",0xa
    db "Super Tic Tac Toe",0xa
    db 7,0x17,"view log messages",0xa
    db "reboot",0
  .bullet:	db 0xf9,0
  .xgs:		db "XGS",0
data:
  .bullet_place: db 0
  .menu_calls:
    dd app_xgs_test
    dd app_boxed_in
    dd app_ttt
    dd _log_browser_wrapper
    dd _reboot
call_me:	dd 0	; polled for a function to call
