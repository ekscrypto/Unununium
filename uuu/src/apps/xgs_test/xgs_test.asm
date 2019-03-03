; $Header: /cvsroot/uuu/uuu/src/apps/xgs_test/xgs_test.asm,v 1.11 2001/10/26 21:39:22 daboy Exp $

[bits 32]

;                                           -----------------------------------
;                                                                       options
;==============================================================================

;%define _DEBUG_
;%define _RDTSC_		; will display the number of clocks each frame takes

;                                           -----------------------------------
;                                                                      includes
;==============================================================================

%include "vid/hydro3d.inc"
%include "vid/kbd.inc"
%include "vid/sys_log.inc"
%include "hydro3d.inc"

;                                           -----------------------------------
;                                                                     constants
;==============================================================================

%define SC_INDEX	0x3c4
%define MEMORY_MODE	4
%define GRAPHICS_MODE	5
%define MISCELLANEOUS	6
%define MAP_MASK	2
%define CRTC_INDEX	0x3d4
%define MAX_SCAN_LINE	9
%define UNDERLINE	0x14
%define MODE_CONTROL	0x17
%define XRES		320
%define YRES		400

;                                           -----------------------------------
;                                                                   render data
;==============================================================================

section .data
  %include "blobs.dat"

;                                           -----------------------------------
;                                                          real fun starts now
;==============================================================================

section .text
global app_xgs_test
app_xgs_test:

start:
;;------------------------------------------------------------------------------
;; And now our feature presentation...
;;------------------------------------------------------------------------------

set_320_400:
  ; already in 13h
  mov dx, SC_INDEX
  mov al, MEMORY_MODE
  out dx, al
  inc dx
  in al, dx
  and al, 0xf7
  or al, 0x04
  out dx, al
  mov dx, SC_INDEX
  mov al, GRAPHICS_MODE
  out dx, al
  inc dx
  in al, dx
  and al, 0xef
  out dx, al
  dec dx
  mov al, MISCELLANEOUS
  out dx, al
  inc dx
  in al, dx
  and al, 0xfd
  out dx, al

  ; now clear the screen before switching modes because 13h only clears half
  mov dx, SC_INDEX
  mov ax, 0xf00 + MAP_MASK
  out dx, ax

  xor eax, eax
  mov ecx, 0x4000
  cld
  rep stosd

  ; now tweak 13h not not scan each line twice
  mov dx, CRTC_INDEX
  mov al, MAX_SCAN_LINE
  out dx, al
  inc dx
  in al, dx
  and al, 0xe0
  out dx, al
  dec dx

  mov al, UNDERLINE
  out dx, al
  inc dx
  in al, dx
  and al, 0xbf
  out dx, al
  dec dx
  mov al, MODE_CONTROL
  out dx, al
  inc dx
  in al, dx
  or al, 0x40

  out dx, al

  

hook_keyboard:
;-------------------------------------------------------------------------------
  mov esi, _keyboard_client
  externfunc kbd.set_scancode_client



create_mesh:
;-------------------------------------------------------------------------------
  mov ecx, vertcount
  mov edx, facecount
  mov eax, test_verts
  mov ebx, test_faces
  externfunc hydro3d.create_mesh
  ; edi = pointer to mesh



create_objects:
;-------------------------------------------------------------------------------
  mov esi, edi					;
  ;push edi
  externfunc hydro3d.create_object	;
  mov [data.object1], edi			;

  ;fld dword[edi+object.omatrix+matrix44.tx]
  ;fsub dword[data.object_back]
  ;fstp dword[edi+object.omatrix+matrix44.tx]
  
;  mov esi, [esp]
;  externfunc hydro3d.create_object	;
;  mov [data.object2], edi			;
;
;;  call _scale_matrix
;
;  pop esi
;  externfunc hydro3d.create_object	;
;  mov [data.object3], edi			;
;
;  call _scale_matrix
;
;  fld dword[edi+object.omatrix+matrix44.tx]
;  fadd dword[data.object_dis]
;  fstp dword[edi+object.omatrix+matrix44.tx]
  



create_camera:
;-------------------------------------------------------------------------------
  externfunc hydro3d.create_camera	;
  ; edi = pointer to camera			;

  mov dword[edi+camera.cmatrix+matrix44.tz], 0xC1200000	; -10.0
  
  push dword [data.far_clip]		; far clip plane
  push dword [data.near_clip]		; near clip plane
  push dword [data.fov]			; FOV
  push dword [data.aspect_ratio]	; aspect ratio
  add edi, byte camera.pmatrix
  externfunc hydro3d.create_camera_matrix
  sub edi, byte camera.pmatrix
  



create_scene:
;-------------------------------------------------------------------------------
  mov esi, edi					;
  externfunc hydro3d.create_scene	;
  ; edi = pointer to scene			;
  mov [data.scene], edi			;



add_objects_to_scene:
;-------------------------------------------------------------------------------
  ; edi = pointer to scene			;
  ;push edi
  mov esi, [data.object1]			;
  externfunc hydro3d.add_object_to_scene

  ;mov edi, [esp]
  ;mov esi, [data.object2]			;
  ;externfunc hydro3d.add_object_to_scene

  ;pop edi
  ;mov esi, [data.object3]			;
  ;externfunc hydro3d.add_object_to_scene




set_palette:	; makes a bluescale palette from 1 to 255
;-------------------------------------------------------------------------------
  mov ecx, 255	;
  xor ebx, ebx	;
  inc ebx	;
.loop:  	;
  mov dx, 0x3c8	;
  mov eax, ebx	;
  out dx, al	;
 		;
  inc edx	; 0x3c9 now
  mov eax, ecx	;
  shr eax, 3	;
  out dx, al	;red
  out dx, al	;green
  		;
  mov eax, ecx	;
  shr eax, 2	;
  out dx, al	;blue
		;
  inc ebx	;
  dec ecx	;
  jnl .loop	;


set_sane_floating_precision:
;-------------------------------------------------------------------------------
  fstcw [esp-2]
  and word[esp-2], 0xfcff	; clear bits 8 and 9 for single precision
  fldcw [esp-2]


;; Ok, init stuff is done. We have the whole scene set up and a pointer to it
;; in [data.scene]. This should be all we need to draw it.



;                                           -----------------------------------
;                                                               frame loop here
;==============================================================================

frame:



%ifdef _RDTSC_
  xor eax, eax
  cpuid			; serialize
  rdtsc
  push eax
%endif

draw_scene_to_buffer:
;-------------------------------------------------------------------------------
  mov edi, [data.scene]
  externfunc hydro3d.draw_scene

%ifdef _RDTSC_
  xor eax, eax
  cpuid			; serialize
  rdtsc
  pop edx
  sub eax, edx
  push eax
%endif



wait_for_retrace:
;-------------------------------------------------------------------------------
  mov dx, 0x3da	;
.wait:		;
  in al, dx	;
  and al, 0x8	;
  jnz .wait	;
.waitmore:	;
  in al, dx	;
  and al, 0x8	;
  jz .waitmore	;



%ifdef _RDTSC_
display_tsc:
;-------------------------------------------------------------------------------
  mov edi, [data.scene]	;
  mov edi, [edi+scene.buffer]	;
  pop edx			;
  call _display_hex		;
%endif


draw_buffer:
;-------------------------------------------------------------------------------
  mov esi, [data.scene]	;
  mov edi, 0xa0000		;
  mov esi, [esi+scene.buffer]	;
  mov dx, SC_INDEX
  xor ecx, ecx
  mov al, 0x02

  mov ebx, YRES
.copy_scanline:
  
  mov ah, 0x01
  add ecx, byte 80/4
  out dx, ax		; select write to plane 0
  rep movsd

  mov ah, 0x02
  sub edi, byte 80
  add ecx, byte 80/4
  out dx, ax		; select write to plane 1
  rep movsd

  mov ah, 0x04
  sub edi, byte 80
  add ecx, byte 80/4
  out dx, ax		; select write to plane 2
  rep movsd

  mov ah, 0x08
  sub edi, byte 80
  add ecx, byte 80/4
  out dx, ax		; select write to plane 3
  rep movsd

  dec ebx
  jnz .copy_scanline


  cmp byte[data.fade_count], 0
  jne exit


rotate_n_translate:
  mov bx, [data.keys]			;
.slowdown:				;
  fld dword[data.Xrot_amount]	;
  fld dword[data.Yrot_amount]	;
  fld dword[data.Zrot_amount]	;
  fld dword[data.rot_decel]		;
  fmul st3, st0				;
  fmul st2, st0				;
  fmulp st1, st0			;
  fstp dword[data.Zrot_amount]	;
  fstp dword[data.Yrot_amount]	;
  fstp dword[data.Xrot_amount]	;
  					;
.up:					;
  test bx, 1b				;up arrow pressed?
  jz .down				;
  fld dword[data.Xrot_amount]	;
  fld dword[data.rot_accel]		;
  fchs					;
  faddp st1, st0			;
  fstp dword[data.Xrot_amount]	;
					;
.down:					;
  test bx, 10b				;
  jz .left				;
  fld dword[data.Xrot_amount]	;
  fld dword[data.rot_accel]		;
  faddp st1, st0			;
  fstp dword[data.Xrot_amount]	;
					;
.left:					;
  test bx, 100b				;
  jz .right				;
  fld dword[data.Yrot_amount]	;
  fld dword[data.rot_accel]		;
  faddp st1, st0			;
  fstp dword[data.Yrot_amount]	;
					;
.right:					;
  test bx, 1000b			;
  ;zooming disabled temp.		;
  ;jz .plus				;
  jz .done				;
  fld dword[data.Yrot_amount]	;
  fld dword[data.rot_accel]		;
  fchs					;
  faddp st1, st0			;
  fstp dword[data.Yrot_amount]	;
					;
;.plus:					;
;  mov ecx, [data.state_ptr]	;
;  test bx, 10000b			;
;  jz .minus				;
;  fld dword[ecx+client_state.cam_dis]	;
;  fld dword[data.zoom_speed]	;
;  faddp st1,st0			;
;  fstp dword[ecx+client_state.cam_dis]	;
;					;
;.minus:				;
;  test bx, 100000b			;
;  jz .done				;
;  fld dword[ecx+client_state.cam_dis]	;
;  fld dword[data.zoom_speed]	;
;  fsubp st1,st0			;
;  fstp dword[ecx+client_state.cam_dis]	;
.done:					;


rotate:
  mov eax, [data.object1]			;
  call _rotate_object
						;
  mov eax, [data.object2]			;
  call _rotate_object
						;
  mov eax, [data.object3]			;
  call _rotate_object



  jmp frame	; go do another frame

;                                           -----------------------------------
;                                                                          exit
;==============================================================================

exit:
  xor eax, eax			; TODO: dealloc memory, etc...for now we just
  mov [data.Xrot_amount], eax	; stop rotation so it looks like we cleaned up
  mov [data.Yrot_amount], eax	;
  mov [data.Zrot_amount], eax	;

  mov [data.fade_count], al

  mov esi, eax
  dec esi
  externfunc kbd.set_scancode_client

  retn				; return to base

;                                           -----------------------------------
;                                                              _keyboard_client
;==============================================================================

_keyboard_client:
				;
  push ebx
  mov bx, [data.keys]
				;
  cmp al, 0x48			;up arrow
  je .up_pressed		;
  cmp al, 0xc8			;up arrow released
  je .up_released		;
  cmp al, 0x50			;
  je .down_pressed		;
  cmp al, 0xd0			;
  je .down_released		;
  cmp al, 0x4b			;
  je .left_pressed		;
  cmp al, 0xcb			;
  je .left_released		;
  cmp al, 0x4d			;
  je .right_pressed		;
  cmp al, 0xcd			;
  je .right_released		;
  cmp al, 0x0d			;
  je .plus_pressed		;
  cmp al, 0x8d			;
  je .plus_released		;
  cmp al, 0x0c			;
  je .minus_pressed		;
  cmp al, 0x8c			;
  je .minus_released		;
  cmp al, 0x10			;
  je .q_pressed			;
  cmp al, 0x1c			;
  je .enter_pressed		;
  cmp al, 0x9c			;
  je .enter_released		;
  
  pop ebx
  stc
  retn

.up_pressed:			;
  or bx, 1b			;
  jmp short .done
				;
.up_released:			;
  and bx, 0xfffe		;
  jmp short .done
				;
.down_pressed:			;
  or bx, 10b			;
  jmp short .done
				;
.down_released:			;
  and bx, 0xfffd		;
  jmp short .done
				;
.left_pressed:			;
  or bx, 100b			;
  jmp short .done
				;
.left_released:			;
  and bx, 0xfffb		;
  jmp short .done
				;
.right_pressed:			;
  or bx, 1000b			;
  jmp short .done
				;
.right_released:		;
  and bx, 0xfff7		;
  jmp short .done
				;
.plus_pressed:			;
  or bx, 10000b			;
  jmp short .done
				;
.plus_released:			;
  and bx, 0xffef		;
  jmp short .done
				;
.minus_pressed:			;
  or bx, 100000b		;
  jmp short .done
				;
.minus_released:		;
  and bx, 0xffdf		;
  jmp short .done
				;________
.q_pressed:				;
  ;save this for later, when we add fading again.
  mov byte[data.fade_count], 255	;
  jmp short .done
					;________
.enter_pressed:					;
  mov dword[data.rot_decel], 0x3f733333	;0.95
  jmp short .done
						;
.enter_released:				;
  mov dword[data.rot_decel], 0x3f7fbe77	;0.999
  jmp short .done
						;
.done:						;
  mov [data.keys], bx
  pop ebx
  clc
  retn


;                                           -----------------------------------
;                                                                 _scale_matrix
;==============================================================================

_scale_matrix:
; scales the matrix pointed to by edx by [data.object_scale]

; ** temp. disabled **
;  mov ecx, matrix33_size / 4 - 1
;
;.loop:
;  fld dword[edi+ecx*4]
;  fmul dword[data.object_scale]
;  fstp dword[edi+ecx*4]
;
;  dec ecx
;  jns .loop
  
  retn

;                                           -----------------------------------
;                                                                _rotate_object               
;==============================================================================

_rotate_object:
;; rotates the object pointed to by eax by the Xrot_ammount and Yrot...
  mov edx, eax
  mov ebx, eax
  add edx, byte object.omatrix+matrix44.yx
  add ebx, byte object.omatrix+matrix44.zx
  fld dword[data.Yrot_amount]
  externfunc hydro3d.rotate_matrix

  mov edx, eax
  mov ebx, eax
  add edx, byte object.omatrix+matrix44.zx
  fld dword[data.Xrot_amount]
  externfunc hydro3d.rotate_matrix
  retn

;                                           -----------------------------------
;                                                                  _display_hex
;==============================================================================

%ifdef _RDTSC_
_display_hex:
;; parameters:
;; -----------
;; EDI = Pointer to buffer location where to start printing, a total of 64x8
;;       pixels will be required.
;; EDX = value to print out in hex
;;
;; returned values:
;; ----------------
;; EAX = (undefined)
;; EBX = (undefined)
;; ECX = 0
;; EDX = (unmodified)
;; ESI = (undefined)
;; EDI = EDI + 64
;; ESP = (unmodified)
;; EBP = (unmodified)

  lea ebx, [hex_conv]
  mov ecx, 8
.displaying:
  xor eax, eax
  rol edx, 4
  mov al, dl
  and al, 0x0F
  lea esi, [eax*8 + ebx]  
  push eax
  push ebx
  push edx
  call _display_char
  pop edx
  pop ebx
  pop eax
  loop .displaying
  retn

_display_char:
  push ecx
  push edi
  mov ch, 8
  mov ebx, 320-8
.displaying_next8:
  mov dh, [esi]
  mov cl, 8
.displaying:
  xor eax, eax
  rcl dh, 1
  jnc .got_zero
  mov al, 0x3F
.got_zero:
  mov [edi], al
  inc edi
  dec cl
  jnz .displaying
  inc esi
  lea edi, [edi + ebx]
  dec ch
  jnz .displaying_next8
  pop edi
  lea edi, [edi + 8]
  pop ecx
  retn

hex_conv:
%include "numbers.inc"

%endif		; _RDTSC_

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data

; misc. data ---===---

data:
  .scene:	dd 0		; pointer to scene
  .object1:	dd 0
  .object2:	dd 0
  .object3:	dd 0
  .object_dis:	dd 3.0		; space between each "U"
  .object_back:	dd 10.0		; how far back the Us are
  .Xrot_amount:	dd 0
  .Yrot_amount:	dd 0
  .Zrot_amount:	dd 0
  .rot_accel:	dd 0.0008
  .rot_decel:	dd 0.999
  .keys:	dw 0		; flags of what keys are currently pressed
  .far_clip:	dd 10.0		; far clip plane
  .near_clip:	dd 1.0		; near clip plane
  .fov:		dd 0.6		; FOV, in radians
  .aspect_ratio:dd 0.47		; aspect ratio - my calculations are somehow
  .fade_count:	db 0		;   screwed, so this was made by trial & error
