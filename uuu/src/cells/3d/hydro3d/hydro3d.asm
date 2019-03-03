;; Hydro3d
;; $Header: /cvsroot/uuu/uuu/src/cells/3d/hydro3d/hydro3d.asm,v 1.28 2001/11/26 18:16:19 instinc Exp $
;; copyright (c) 2001 Phil Frost

;                                           -----------------------------------
;                                                                       options
;==============================================================================

;%define _DEBUG_

;                                           -----------------------------------
;                                                                     constants
;==============================================================================

%define XRES		320	; resloution
%define YRES		400
%define F_HALF_XRES	160.0	; half of the res. as a float
%define F_HALF_YRES	200.0

;                                           -----------------------------------
;                                                                  vid includes
;==============================================================================

%include "vid/hydro3d.inc"
%include "vid/mem.inc"
%include "vid/sys_log.inc"
%include "vid/ics.inc"
%include "hydro3d.inc"

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init

init:
  jmp .start
  .init_done: db "[Hydro3d] Initialization completed ($Revision: 1.28 $)",0
.start:
  pushad
  mov esi, .init_done
  externfunc sys_log.print_string
  popad

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

%ifdef _DEBUG_
strings:
  .mesh_created: db "[Hydro3d] mesh created at 0x",1
  .object_created: db "[Hydro3d] object created at 0x",1
  .camera_created: db "[Hydro3d] camera created at 0x",1
  .vectors_created: db "[Hydro3d] translated vectors created at 0x",1
  .scene_created: db "[Hydro3d] scene created at 0x",1
  .added_object: db "[Hydro3d] object added: 0x",1
  .calc_points: db "[Hydro3d] calculating points with matrix:",1
  .done: db 0
%endif

;                                           -----------------------------------
;                                                          hydro3d.create_scene
;==============================================================================

globalfunc hydro3d.create_scene
;>
;; This function creates a new, empty, useless scene. It's not initialized
;; in any way, and if you try to use without adding stuff to it you will
;; probally have problems.
;;
;; parameters:
;; -----------
;; ESI = pointer to camera
;;
;; returns:
;; --------
;; EDI = pointer to scene
;<

  push esi				; the camera
  
  mov ecx, scene_size			;
  xor edx,edx				;
  externfunc mem.alloc		; get the memory
					;
  push edi				; the pointer to the memory
					;
  mov ecx, scene_size/4			;
  xor eax, eax				;
  rep stosd				; zero it out
  					;
  externfunc ics.create_channel		; create a channel for objects
  ; edi = pointer to channel		;
  push edi

  xor edx, edx
  mov ecx, XRES*YRES			; XXX use the real resloution here.
  externfunc mem.alloc
  
  mov eax, edi
  pop ebx
  pop edi
  pop esi
  mov [edi+scene.objects], ebx		; put the pointer in the scene
  mov [edi+scene.buffer], eax
  mov [edi+scene.camera], esi

  dbg_print "scene created at 0x",1
  dbg_print_hex edi
  dbg_term_log

  retn					;

;                                           -----------------------------------
;                                                         hydro3d.create_object
;==============================================================================

globalfunc hydro3d.create_object
;>
;;------------------------------------------------------------------------------
;; This creates a new object. However, the new object is not added to anything
;; yet...it must be linked to an object list
;;
;; parameters:
;; -----------
;; ESI = pointer to mesh to use
;;
;; returned values:
;; ----------------
;; EDI = pointer to object
;<

;; because we are using ICS channels to keep track of the objects we need 8
;; bytes before the object. Remember to sub 8 when deallocing this memory :)

  push esi
  
  mov ecx, object_size+8		; ATM we need 8 bytes before the
  xor edx, edx				; object because of the ICS channels.
  externfunc mem.alloc		; In the future I will add ICS
  add edi, byte 8			; functions that don't require this

  push edi
  %if object_size % 4
  %error "object_size was assumed to be a multiple of 4 and it wasn't"
  %endif
  mov ecx, object_size / 4
  xor eax, eax
  rep stosd
  pop edi

  ;initialize the omatrix to identity
  mov eax, 0x3f800000			; 1.0
  mov [edi+object.omatrix+matrix44.xx], eax
  mov [edi+object.omatrix+matrix44.yy], eax
  mov [edi+object.omatrix+matrix44.zz], eax
  mov [edi+object.omatrix+matrix44.tw], eax

  pop esi			; pointer to mesh
  mov [edi+object.mesh], esi

  ; allocating memory for translated vectors
  mov ecx, [esi+mesh.vert_count]; ecx = number of verts
  %if vect4_size <> 16
  %error "vect4_size was assumed to be 8 and it wasn't"
  %endif
  shl ecx, 4			; now we mul by 16; ecx = vertcount*vect4_size
  xor edx, edx
  
  push edi
  externfunc mem.alloc
  mov esi, edi
  dbg_print "vectors created at 0x",1
  dbg_print_hex edi
  dbg_term_log
  pop edi
  mov [edi+object.points], esi

  dbg_print "object created at 0x",1
  dbg_print_hex edi
  dbg_term_log

  retn

;                                           -----------------------------------
;                                                           hydro3d.create_mesh
;==============================================================================

globalfunc hydro3d.create_mesh
;>
;; Creates a new mesh.
;; 
;; parameters:
;; -----------
;; EAX = pointer to verts
;; EBX = pointer to faces
;; ECX = number of verts
;; EDX = number of faces
;;
;; returned values:
;; ----------------
;; EDI = pointer to mesh
;<

  push eax	;i know this is bad... when i finalize the data structures
  push ebx	;the program would set these itself.
  push ecx
  push edx
  mov ecx, mesh_size
  xor edx, edx
  externfunc mem.alloc
  pop edx
  pop ecx
  pop ebx
  pop eax

  mov [edi+mesh.vert_count], ecx
  mov [edi+mesh.face_count], edx
  mov [edi+mesh.verts], eax
  mov [edi+mesh.faces], ebx

  ;; ESI = pointer to verts
  ;; EDI = pointer to faces
  ;; ECX = number of faces
  pushad
  mov esi, eax
  mov edi, ebx
  mov ecx, edx
  call _calc_normals
  popad
  
  dbg_print "mesh created at 0x",1
  dbg_print_hex edi
  dbg_term_log
  
  retn

;                                           -----------------------------------
;                                                   hydro3d.add_object_to_scene
;==============================================================================

globalfunc hydro3d.add_object_to_scene
;>
;; This adds the object pointed to by ESI to the scene pointed to by EDI. It's
;; the program's responsibility to make sure objects are not added twice.
;;
;; parameters:
;; -----------
;; EDI = pointer to scene
;; ESI = pointer to object
;;
;; returned values:
;; ----------------
;; none
;<

  %ifdef _DEBUG_
    dbg_print "added object: 0x",1
    dbg_print_hex esi
    dbg_print " to scene 0x",1
    dbg_print_hex edi
    dbg_term_log
  %endif

  mov edi, [edi+scene.objects]	; put the pointer to the channel in edi
  externfunc ics.add_client

  retn

;                                           -----------------------------------
;                                                         hydro3d.create_camera
;==============================================================================

globalfunc hydro3d.create_camera
;>
;; Creates a new camera, imagine that! The camera matrix is initialized to
;; identity, but the program must initialise the projection to something sane,
;; possibly with create_camera_matrix.
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EDI = pointer to camera
;<

  mov ecx, camera_size
  xor edx, edx
  externfunc mem.alloc
 
  ; zero out the memory
  push edi
  shr ecx, 2
  xor eax, eax
  rep stosd
  pop edi

  %if camera.cmatrix <> 0
  %error "camera.cmatrix was assumed to be 0 and it wasn't"
  %endif
  ;initialize cmatrix to identity
  mov eax, 0x3f800000			; 1.0
  mov [edi+camera.cmatrix+matrix44.xx], eax
  mov [edi+camera.cmatrix+matrix44.yy], eax
  mov [edi+camera.cmatrix+matrix44.zz], eax
  mov [edi+camera.cmatrix+matrix44.tw], eax

  dbg_print "camera created at 0x",1
  dbg_print_hex edi
  dbg_term_log

  retn

;                                           -----------------------------------
;                                                  hydro3d.create_camera_matrix
;==============================================================================

globalfunc hydro3d.create_camera_matrix
;>
;; This is a function usefull for creating a camera projection matrix from usual
;; human parameters like FOV and near/far clipping planes. This function only
;; makes the matrix, one must still create a camera if he is to make much use of
;; it :)
;;
;; The parameters on the stack will be popped off.
;;
;; parameters:
;; -----------
;; +12 = far clipping plane (float)
;;  +8 = near clipping plane (float)
;;  +4 = field of view (radians, float)
;; tos = 1/aspect ratio: height/width (3/4 for std monitor, float)
;; EDI = destination for matrix
;;
;; status:
;; -------
;; working
;<

  xor eax, eax
  mov [edi+matrix44.yx], eax
  mov [edi+matrix44.zx], eax
  mov [edi+matrix44.tx], eax
  mov [edi+matrix44.xy], eax
  mov [edi+matrix44.zy], eax
  mov [edi+matrix44.ty], eax
  mov [edi+matrix44.xz], eax
  mov [edi+matrix44.yz], eax
  mov [edi+matrix44.xw], eax
  mov [edi+matrix44.yw], eax
  mov [edi+matrix44.tw], eax
  
  mov dword[edi+matrix44.zw], 0xBF800000	; -1.0
  
  ;; stack contains:
  ;; +16 = f
  ;; +12 = n
  ;;  +8 = fov
  ;;  +4 = w/h
  ;; tos = return point

  fld dword[.negone]		; -1
  fld dword[esp+8]		; fov	-1
  fscale			; fov/2	-1
  fst dword[esp-4]
  push edx
  mov edx, [esp-4]
  pop edx
  fsincos			; cos(fov/2)	sin(fov/2)	-1
  fdivrp st1			; tan(fov/2)	-1
  fdivrp st1			; -1/tan(fov/2)
  fst dword[edi+matrix44.xx]	;
  fmul dword[esp+4]
  fstp dword[edi+matrix44.yy]	; (empty)
  fld dword[esp+16]		; f
  fld dword[esp+12]		; n	f
  fchs				; -n	f
  fld st1			; f	-n	f
  fadd st1			; f-n	-n	f
  fdivp st2			; -n	f/(f-n)
  fmul st1			; -fn/(f-n)	f/(f-n)
  fstp dword[edi+matrix44.tz]	;
  fstp dword[edi+matrix44.zz]	;

  %ifdef _DEBUG_
  push esi
  dbg_print "camera matrix created:",1
  mov esi, edi
  call sys_log.print_matrix
  pop esi
  %endif
  
  retn 16

[section .data]
.negone: dd -1.0
__SECT__

;                                           -----------------------------------
;                                                            hydro3d.draw_scene
;==============================================================================

globalfunc hydro3d.draw_scene
;>
;; Draws a scene
;;
;; parameters:
;; -----------
;; EDI = pointer to scene to draw
;;
;; returned values:
;; ----------------
;; none
;;
;; Here we have 2 loops. One loops over each object, the other loops over the
;; faces of each object until we have a seperate function to do that.
;;
;; Throughout the function the camera distance sits on the fpu stack and is
;; popped off at the end. EAX is also used to store the resloution, and it
;; sits on the stack durring the face drawing. The resloution is divided by
;; 2 so it can be added to the points as they are calculated to bring them
;; to the center of the screen.
;<

; get a list of the objects ---===---

  mov ebx, edi			; save this --------------------.
  mov edi, [edi+scene.objects]	; get pointer to object channel |
  externfunc ics.get_clients	;				|
  ; stack now has the objects on it, ECX has the number of them |
  mov edi, ebx			; restore pointer to scene    <-'

; load the camera distance and put the resloution in EAX ---===---

  mov edx, [edi+scene.camera]	; EDX = pointer to camera
  mov eax, 0x00c80140		; XXX: use the real resloution
  ;mov eax, [edi+scene.res_x]
  ;fld dword[edx+camera.dis]	; load this for __calc_points
  shr eax, 1			; this is for __calc_points too

; clear the buffer ---===---

  push ecx
  push edi

  mov edi, [edi+scene.buffer]
  
  fldz			; load 0
  mov ecx, XRES*YRES-0x80
.clearing_buffer:
  fst qword[edi+ecx]
  fst qword[edi+ecx+0x8]
  fst qword[edi+ecx+0x10]
  fst qword[edi+ecx+0x18]
  fst qword[edi+ecx+0x20]
  fst qword[edi+ecx+0x28]
  fst qword[edi+ecx+0x30]
  fst qword[edi+ecx+0x38]
  fst qword[edi+ecx+0x40]
  fst qword[edi+ecx+0x48]
  fst qword[edi+ecx+0x50]
  fst qword[edi+ecx+0x58]
  fst qword[edi+ecx+0x60]
  fst qword[edi+ecx+0x68]
  fst qword[edi+ecx+0x70]
  fst qword[edi+ecx+0x78]
  add ecx, byte -128
  jns .clearing_buffer

  fstp st0

  pop edi
  pop ecx



; check to see if we have any objects. Return if we don't. ---===---

  test ecx, ecx
  jz near .done			; if we have no objects

.object:

;; Ok, we have now set up all the stuff that dosn't change between objects.
;; Here starts the object-level loop. First we calculate all the points, then
;; we draw the faces.
;;
;; Calculating the points involves calculating the matrix for the object,
;; taking into account the camera and parrent objects. Right now we just fake
;; it by copying the object's matrix and moving it back 10 units.
  
; get an object off the stack ---===---
  
  pop esi			; pop pointer to object

  push ecx			; save number of objects

;; ESI = pointer to current object
;; ECX = number of objects left to draw (including current one)
;; EAX = resloutions
;; EDI = pointer to scene


; calculate the ematrix ---===---

  pushad
  
  ; step 1: calculate [cmatrix] * [pmatrix] = [tmatrix] for the camera
  
  %if camera.cmatrix <> 0
  %error "camera.cmatrix was assumed to be 0 and it wasn't"
  %endif
  mov edi, [edi+scene.camera]
  lea ebx, [edi+camera.pmatrix]
  lea edx, [edi+camera.tmatrix]
  call hydro3d.mul_matrix	; calculate the total matrix for the camera

  ; step 2: calculate [camera.tmatrix] * [object.omatrix] = [object.ematrix]
  
  mov ebx, edx
  %if object.omatrix <> 0
  %error "object.omatrix was assumed to be 0 and it wasn't"
  %endif
  mov edi, esi
  lea edx, [esi+object.ematrix]
  call hydro3d.mul_matrix	; calculate the ematrix for the object

  popad
  
  push edi		;still pointer to scene (hopefully)
  call _calc_points
  pop edi

  ;; ESI EAX = unchanged --
  ;; ESI = pointer to object
  ;; EAX = resloutions, we need to save this
  ;; EDI = pointer to scene

  push eax			; save those resloutions
  push edi			; save the pointer to the scene

  mov ecx, [esi+object.mesh]
  mov edi, [edi+scene.buffer]
  mov ebp, [esi+object.points]
  mov edx, [ecx+mesh.faces]
  mov ecx, [ecx+mesh.face_count]

  ;; EDX = pointer to faces
  ;; ECX = number of faces
  ;; EBP = pointer to points
  ;; EDI = pointer to buffer
  ;; ESI = pointer to object still

;;XXX: use the real resloution in here. This code assumes mode 13h.
;;
;; Ok, we are now ready to draw the faces. Right now we just draw the first
;; vert of each one, and this works fine for meshes generated by blender.

.face:

; translate the normal vector from object to world cordinates ---===---

  fld dword[esi+object.omatrix+matrix44.xz]	; XXX really a dot product
  fmul dword[edx+face.norX]			; should be done here
  fld dword[esi+object.omatrix+matrix44.yz]	;
  fmul dword[edx+face.norY]			;
  fld dword[esi+object.omatrix+matrix44.zz]	;
  fmul dword[edx+face.norZ]			; Z Y X
  fxch						;
  faddp st2					;
  faddp st1					;
  fchs
  
  push edx
  fst dword[esp]			; this is poped of in .skip
  cmp dword[esp], byte 0
  pop eax
  jns near .skip			;and skip the face if norZ is negitive
  
pushad
  movzx eax, word[edx+face.vert1]	; EAX = index to first point
  call _get_vert

  cmp ebx, YRES			; XXX the real res. should be used here
  jae near .out0
  cmp eax, XRES
  jae near .out0

  push eax
  push ebx

  movzx eax, word[edx+face.vert2]	; EAX = index to 2nd point
  call _get_vert

  cmp ebx, YRES			; XXX the real res. should be used here
  jae near .out8
  cmp eax, XRES
  jae near .out8

  push eax
  push ebx

  movzx eax, word[edx+face.vert3]	; EAX = index to 2nd point
  call _get_vert

  cmp ebx, YRES			; XXX the real res. should be used here
  jae .out16
  cmp eax, XRES
  jae .out16

  push eax
  push ebx

  fmul dword[.num_colors]
  push eax
  fist dword[esp]
  pop edx

;; stack:
;; y2		+0
;; x2		+4
;; y1		+8
;; x1		+12
;; y0		+16
;; x1		+20
;;
;; EAX = x2
;; EBX = y2

  mov esi, [esp+8]
  mov ecx, [esp+12]
  call _draw_line
  
  mov esi, [esp+8]
  mov ecx, [esp+12]
  mov ebx, [esp]
  mov eax, [esp+4]
  mov edi, [esp+24]
  call _draw_line
  
  mov esi, [esp+16]
  mov ecx, [esp+20]
  mov ebx, [esp]
  mov eax, [esp+4]
  mov edi, [esp+24]
  call _draw_line
  
  add esp, byte 24

popad

; advance the pointers ---===---
.skip:
  add edx, byte face_size
  fstp st0
  dec ecx
  jnz .face

;; Ok, we have drawn all the faces of that object. Here's the end of the object
;; loop:

  pop edi		; pointer to scene
  pop eax		; the resloutions
  pop ecx		; the number of objects.
  dec ecx
  jnz .object

.done:
  retn

.out16:
  add esp, byte 8
.out8:
  add esp, byte 8
.out0:
  popad
  jmp short .skip

[section .data]
.num_colors: dd 255.0		; XXX this isn't thread safe
resx: dd F_HALF_XRES
resy: dd F_HALF_YRES
__SECT__

;                                           -----------------------------------
;                                                                     _get_vert
;==============================================================================

_get_vert:
;>
;; returns the screen cords of a vertex
;;
;; parameters:
;; -----------
;; ECX = index of vert to get
;; EBP = ptr to verts
;;
;; returned values:
;; ----------------
;; EAX = x
;; EBX = y
;; all other registers unmodified
;<

  %if vect4_size <> 16
  %error "vect4_size was assumed to be 16 and it wasn't"
  %endif
  shl eax, 4
  add eax, ebp			; EAX = offset to first vector of the triangle
  
  fld dword[eax+vect4.x]	; x
  fld dword[eax+vect4.y]	; y x
  fld dword[eax+vect4.w]	; w y x
  fdiv to st2			; w y x/w
  fdivp st1			; y/w x/w

  ;; we now have our point in the range [-1,1]. This makes it easy to map to
  ;; screen cordinates and do clipping and such and stuff.

  fmul dword[resy]		; XXX CHEAT!!!
  push edx
  fistp dword[esp]
  pop eax
  fmul dword[resx]
  push edx
  fistp dword[esp]
  pop ebx

  add eax, XRES/2
  add ebx, YRES/2
  
  dec eax
  dec ebx

  retn

;                                           -----------------------------------
;                                                                    _draw_line
;==============================================================================

_draw_line:
;>
;; draws (x0, y0)------(x1, y1); no clipping performed
;; 
;; parameters:
;; -----------
;; EAX = x0
;; EBX = y0
;; ECX = x1
;; ESI = y1
;; DL = color
;;
;; returned values:
;; ----------------
;; all registers except EDX destroyed
;;
;;
;; 
;; About the Bresenham implementation:
;; -----------------------------------
;; there are 8 possible cases for a line. We first arrange the points by
;; possibly swapping them so that the point with the lower Y value is always
;; first; this reduces the cases to 4:
;;
;;     dx > 0           dx < 0
;;  line goes ->      line goes <-
;; .--------------------------------.
;; |1)        ... |3) ...           |
;; |       ...    |      ...        |        dx > dy       |
;; |    ...       |         ...     | one pixel per column |
;; | ...          |            ...  |                      |
;; |*             |               * |
;; |--------------+-----------------|
;; |2)     .      |4)    .          |
;; |       .      |      .          |
;; |      .       |       .         |        dx < dy
;; |      .       |       .         | one pixel per row  -----
;; |     .        |        .        |
;; |     .        |        .        |
;; |    .         |         .       |
;; |    *         |         *       |
;; `--------------------------------'
;;
;; This routine does not have any special cases for horizontal, vertical, or
;; diagonal lines. I haven't done any tests yet, but I have a hunch that there
;; may be some very slight speed gain by doing that, so I'll save it for
;; another day.
;; 
;; Most Bresenham implementations I have seen make use of some variables to
;; keep track of which direction X and Y are going (to dec, or to inc). It all
;; looks good in C, but then you realise that there arn't that many registers
;; on an ia32 box when you do it in ASM, so the inner-most loop of your 3d
;; engine is shelling variables to memory and replacing "inc eax" with "add
;; eax, [esp+4]" which is a mere 4 times slower on an athlon. Consider that
;; 75% of hydro3d's time is spent in this loop, and suddenly you realise that
;; using that variable from memory has a 20% framerate hit. Gee, I should have
;; thought of that...
;;
;; Anyway, this implementation has 4 seperate cases, where most have only 2
;; (they group 1&3 and 2&4, using that variable in memory to change the
;; direction of the line). I think it's pretty fast, but I have not checked
;; it with any other hardcore gfx programers; this was derived wholey from my
;; own two frontal lobes using a mathamatical description of the algorithm.
;;
;;
;;
;; About the planar VGA memory implementation:
;; -------------------------------------------
;; Currently I'm playing with tweaked VGA modes, which have the funny property
;; of being a royal pain in the ass. Right now I use a resloution of 320x400,
;; which is basicly 13h without the doubled scanlines. In this mode the memory
;; is planar. There are 4 planes. Using the notation plane:byte_in_plane, the
;; pixels across the screen go like this:
;;
;; 0:0  1:0  2:0  3:0  0:1  1:1  2:1  3:1  0:2  1:2  3:2  4:2 ...
;;  ^                   ^                   ^
;; 
;; If I was to just write 3 bytes to 0xa0000 they would show up at the '^'
;; above.
;;
;; As you can imagine, it's quite a nightmare if I draw the scene to a
;; buffer in a linear manner and then want to copy it do display memory. So, I
;; draw to the buffer in a linear manner. By grouping all the pixels that will
;; go in each plane (in other words every 4th pixel) together I can avoid all
;; the messy unpacking and make use of rep movsd to copy rather than do it byte
;; per byte.
;;
;; If i grouped all of the bytes for each plane together and then copied all of
;; plane 0, then all of plane 1, etc. to the screen, I would get funny stripes
;; at the top of the display due to the scan. By the time the sweep comes back
;; to the top of the screen I may be 3/4 done with my copy, but that means I
;; have drawn planes 0, 1, and 2, but not 3. If you look at the figure above
;; you can see that every 4th pixel would not be drawn, and things would look
;; very, very bad.
;;
;; So, I only group the planes together for each scanline. Then I can easily
;; copy an entire scanline with only 4 plane changes, 4 rep movsd, and no
;; unpacking. The x-res is 320 and we have 4 planes, so one scanline in one
;; plane is 320/4 bytes; 80 bytes. Thus, in my buffer, the first 80 bytes go to
;; plane 0, the next 80 to plane 1, etc.
;;
;; To make this fast I use a macro to 'increment' the X cord when drawing. Just
;; INC alone would generate the sequence {0, 1, 2, 3, 4 ... 319} but because of my
;; planar layout I need {0, 80, 160, 240, 1, 81, 161, 241...79, 159, 239, 319}.
;; The macro inc_x does that. There is also a dec_x, which does the same sort
;; of thing but decrements.
;;
;; Lastly, the parameters are provided in a linear domain, not my planar one,
;; so I need to convert. If I am given 2 as a parameter, I need to convert that
;; to 160. The macro x_to_planar does this.
;<

;<vulture> I dunno about bresenham's, but when I draw lines I have a dy and a dx
;<vulture> and if dy>dx then draw along y
;<vulture> if dx>=dy then draw along x
;<vulture> and you do this....
;<vulture> edi = start memory offset
;<vulture> ebx = dy/dx
;<vulture> (.32 fixed point)
;<vulture> edx = start total
;<vulture> al = color
;<vulture> ecx = dx
;<vulture> then it'd look like:
;<vulture> drawline:
;<vulture>  mov [edi],al
;<vulture>  add edx,ebx
;<vulture>  sbb ebp,ebp
;<vulture>  and ebp,XRES
;<vulture>  add edi,ebp
;<vulture>  inc edi
;<vulture>  dec ecx
;<vulture>  jnz drawline

%macro inc_x 0		; effectivly increments X, except for a planar memory
  add eax, byte 80	; model so that all the plane 0 pixels are the first 80
  cmp eax, XRES		; bytes in the buffer, plane 1 is the next 80, etc.
  jb %%no_wrap
  sub eax, XRES - 1	; we went past the scanline, so correct it
%%no_wrap:
%endmacro

%macro dec_x 0		; same as before, but decrement instead
  sub eax, byte 80
  jns %%no_wrap
  add eax, XRES - 1
%%no_wrap:
%endmacro

  dbg_print "drawing line (",1
  dbg_print_hex eax
  dbg_print ", ",1
  dbg_print_hex ebx
  dbg_print ")---(",1
  dbg_print_hex ecx
  dbg_print ", ",1
  dbg_print_hex esi
  dbg_print ")",0

  ; possibly swap points so that y0 =< y1; therefore dy =< 0
  cmp ebx, esi		; cmp y0, y1
  je near .possible_not_line
  jb .no_swap
  dbg_print "swapping points",0
  xchg eax, ecx		; flip the points
  xchg ebx, esi
.no_swap:
  
  sub ecx, eax		; ECX = dx
  sub esi, ebx		; EDX = dy ( always =< 0 )
  
  dbg_print "dx = ",1
  dbg_print_hex ecx
  dbg_print "; dy = ",1
  dbg_print_hex esi
  dbg_term_log

  ;; now convert the linear X to the planar sort we need
  ;; the equation to do this is: newx = x / 4 + (x % 4) * 80
  ;; (x % 4) is the same as (x and 3)
  mov ebp, eax
  and eax, 3
  lea eax, [eax*5]	;
  shr ebp, 2
  shl eax, 4		; eax * 80
  add eax, ebp

  ;; and convert the Y to a memory offset to the scanline we want
  lea ebx, [ebx*5]
  shl ebx, 6
  add edi, ebx


  test ecx, ecx		; decide: case 1/2 or 3/4?
  js .case_3or4

  dbg_print "case 1 or 2",0
  ; case is 1 or 2
  ; dy => 0, so we know the line goes to the left and we will be incrementing x

  ;; at this point:
  ;; EAX = x
  ;; EBX = y
  ;; ECX = dx \ both positive
  ;; EDX = dy /

  cmp ecx, esi	 ; decide: case 1 or 2?
  jb .case2

.case1:
  dbg_print "case 1",0
  add esi, esi		; ESI = 2dy
  mov ebx, ecx
  mov ebp, esi
  sub ebp, ecx		; EBP = 2dy-dx, our decision variable (d)
  add ebx, ecx		; EDX = 2dx
.draw1:
  mov [edi+eax], dl
  test ebp, ebp
  js .no_step1		; skip if d < 0

  sub ebp, ebx		; d -= 2dx
  add edi, XRES
.no_step1:
  add ebp, esi		; d -= 2dy
  inc_x

  dec ecx
  jnz .draw1

  retn

.case2:
  dbg_print "case 2",0
  add ecx, ecx
  mov ebx, esi
  mov ebp, ecx
  sub ebp, esi
  add ebx, esi
.draw2:
  mov [edi+eax], dl
  test ebp, ebp
  js .no_step2		; skip if d < 0

  sub ebp, ebx		; d -= 2dx
  inc_x
.no_step2:
  add ebp, ecx		; d -= 2dy
  add edi, XRES

  dec esi
  jnz .draw2

  retn



.case_3or4:
  dbg_print "case 3 or 4",0

  neg ecx
  cmp ecx, esi	 ; decide: case 3 or 4?
  jb .case4

.case3:
  dbg_print "case 3",0
  add esi, esi		; ESI = 2dy
  mov ebx, ecx
  mov ebp, esi
  sub ebp, ecx		; EBP = 2dy-dx, our decision variable (d)
  add ebx, ecx
.draw3:
  mov [edi+eax], dl
  test ebp, ebp
  js .no_step3		; skip if d < 0

  sub ebp, ebx		; d -= 2dx
  add edi, XRES
.no_step3:
  add ebp, esi		; d -= 2dy
  dec_x

  dec ecx
  jnz .draw3

  retn

.case4:
  dbg_print "case 4",0
  add ecx, ecx		; EDX = 2dx
  mov ebx, esi
  mov ebp, ecx
  sub ebp, esi		; EBP = 2dx-dy, our decision variable (d)
  add ebx, esi
.draw4:
  mov [edi+eax], dl
  test ebp, ebp
  js .no_step4		; skip if d < 0

  sub ebp, ebx		; d -= 2dx
  dec_x
.no_step4:
  add ebp, ecx		; d -= 2dy
  add edi, XRES

  dec esi
  jnz .draw4

  retn

.possible_not_line:
  cmp eax, ecx
  jne .no_swap
  retn

;                                           -----------------------------------
;                                                                  _calc_points
;==============================================================================

_calc_points:
;>
;; Runs through an object and generates coresponding 2dpoints.
;;
;; parameters:
;; -----------
;; ESI = pointer to object
;;
;; returned values:
;; ----------------
;; ESI = unchanged
;<

  %ifdef _DEBUG_
    dbg_print "calculating points using matrix:",1
    add esi, object.ematrix
    call sys_log.print_matrix
    sub esi, object.ematrix
  %endif
  
  mov edx, [esi+object.mesh]
  mov edi, [esi+object.points]
  mov ecx, [edx+mesh.vert_count]
  mov edx, [edx+mesh.verts]

  ;; esi = pointer to object
  ;; edx = pointer to verts
  ;; ecx = number of verts
  ;; edi = pointer to points
.point:
  fld dword[edx+vect3.x]
  fld dword[edx+vect3.y]
  fld dword[edx+vect3.z]	; z y x

  fld dword[esi+object.ematrix+matrix44.xx]	; xx z y x
  fmul st3					; x*xx z y x
  fld dword[esi+object.ematrix+matrix44.yx]	; yx x*xx z y x
  fmul st3					; y*yx x*xx z y x
  fld dword[esi+object.ematrix+matrix44.zx]	; ...
  fmul st3					; ...
  fld dword[esi+object.ematrix+matrix44.tx]	; tx z*zx y*yx x*xx z y x
  faddp st3					; z*zx y*yx x*xx+tx z y x
  faddp st2					; y*yx x*xx+tx+z*zx z y x
  faddp st1					; x*xx+tx+z*zx+y*yx z y x
  fstp dword[edi+vect4.x]

  fld dword[esi+object.ematrix+matrix44.xy]
  fmul st3
  fld dword[esi+object.ematrix+matrix44.yy]
  fmul st3
  fld dword[esi+object.ematrix+matrix44.zy]
  fmul st3
  fld dword[esi+object.ematrix+matrix44.ty]
  faddp st3
  faddp st2
  faddp st1
  fstp dword[edi+vect4.y]
  
  fld dword[esi+object.ematrix+matrix44.xz]
  fmul st3
  fld dword[esi+object.ematrix+matrix44.yz]
  fmul st3
  fld dword[esi+object.ematrix+matrix44.zz]
  fmul st3
  fld dword[esi+object.ematrix+matrix44.tz]
  faddp st3
  faddp st2
  faddp st1
  fstp dword[edi+vect4.z]
						; z y x
  fld dword[esi+object.ematrix+matrix44.xw]	; z y x*xw
  fmulp st3
  fld dword[esi+object.ematrix+matrix44.yw]
  fmulp st2					; z y*yw x*xw
  fld dword[esi+object.ematrix+matrix44.zw]
  fmulp st1					; z*zw y*yw x*xw
  fld dword[esi+object.ematrix+matrix44.tw]
  faddp st3
  faddp st2
  faddp st1
  fstp dword[edi+vect4.w]

  add edx, byte vect3_size	;move the pointers to the next cords
  add edi, byte vect4_size	;
  dec ecx			;
  jnz .point			;

  retn

; here's a 3dnow thing I started but never finished; I don't know if it works
; but someday I'll get around to testing it.
;
;  pushad
;
;  lea eax, [esi+object.ematrix]
;  mov ebx, edi
;
;  femms
;  align 16
;
;  .xform:
;  add ebx, 16
;  movq mm0, [edx]
;  movq mm1, [edx+8]
;  add edx, 16
;  movq mm2, mm0
;  movq mm3, [eax+matrix44.xx]
;  punpckldq mm0, mm0
;  movq mm4, [eax+matrix44.yx]
;  pfmul mm3, mm0
;  punpckhdq mm2, mm2
;  pfmul mm4, mm2
;  movq mm5, [eax+matrix44.xz]
;  movq mm7, [eax+matrix44.yz]
;  movq mm6, mm1
;  pfmul mm5, mm0
;  movq mm0, [eax+matrix44.zx]
;  punpckldq mm1, mm1
;  pfmul mm7, mm2
;  movq mm2, [eax+matrix44.zz]
;  pfmul mm0, mm1
;  pfadd mm3, mm4
;
;  movq mm4, [eax+matrix44.tx]
;  pfmul mm2, mm1
;  pfadd mm5, mm7
;
;  movq mm1, [eax+matrix44.tz]
;  punpckhdq mm6, mm6
;  pfadd mm3, mm4
;
;  pfmul mm4, mm6
;  pfmul mm1, mm6
;  pfadd mm5, mm2
;
;  pfadd mm3, mm4
;
;  movq [ebx-16], mm3
;  pfadd mm5, mm1
;
;  movq [ebx-8], mm5
;  dec ecx
;  jnz .xform
;
;  femms
;  
;  popad
;  retn

;                                           -----------------------------------
;                                                              matrix rotations
;==============================================================================

globalfunc hydro3d.rotate_matrix
;>
;; These functions modify the matrix to rotate the object. These are all in
;; radians, not degrees. There are 2pi radians in a circle, so to convert degree
;; to radians, multiply degrees by pi/180. These rotations are relitive to the
;; current orientaion of the object. If you need absloute rotations, you can set
;; the matrix to identiy first:
;;   dd 1.0, 0.0, 0.0
;;   dd 0.0, 1.0, 0.0
;;   dd 0.0, 0.0, 1.0
;;
;; (*) HOW TO SET THE EDX AND EBX REGISTERS
;; All the rotations are essentially the same code, only opperate on a diffrent
;; part of the matrix. By using these two pointers, I can combine 110
;; instructions down to about 20, with a speed loss of about 5 clocks per
;; rotation. The EDX and EBX registers should be a pointer to the matrix, then
;; a value must be added to them according to the following table:
;;
;;    X         Y         Z
;; --------  --------  --------
;; EDX: yx   EDX: zx   EDX: xx
;; EBX: zx   EBX: xx   EBX: yx
;;
;; Parameters:
;;------------
;; EDX EBX = pointers to matrix (^ see note)
;; ST0 = amount to rotate
;;
;; Returned values:
;;-----------------
;; All registers except EDX and EBX unchanged, fpu stack is clear.
;<

  fsincos			; [c] [sY]
				;
  fld     dword[edx]		;                 [12] [c] [s]
  fld     dword[ebx]		;            [24] [12] [c] [s]
  fld     st2			;        [c] [24] [12] [c] [s]
  fmul    st0,    st2		;      [c12] [24] [12] [c] [s]
  fld     st4			;  [s] [c12] [24] [12] [c] [s]
  fmul    st0,    st2		;[s24] [c12] [24] [12] [c] [s]
  fsubp   st1,    st0		;  [c12-s24] [24] [12] [c] [s]
  fstp    dword[edx]		;            [24] [12] [c] [s]
  fmul    st0,    st2		;           [c24] [12] [c] [s]
  fld     st3			;       [s] [c24] [12] [c] [s]
  fmulp   st2,    st0		;          [c24] [s12] [c] [s]
  faddp   st1,    st0		;            [s12+c24] [c] [s]
  fstp    dword[ebx]		;                      [c] [s]
				;
  add edx, byte 4		;
  add ebx, byte 4		;
				;
  fld     dword[edx]		; this is the same code
  fld     dword[ebx]		;
  fld     st2			;
  fmul    st0,    st2		;
  fld     st4			;
  fmul    st0,    st2		;
  fsubp   st1,    st0		;
  fstp    dword[edx]		;
  fmul    st0,    st2		;
  fld     st3			;
  fmulp   st2,    st0		;
  faddp   st1,    st0		;
  fstp    dword[ebx]		;
				;
  add edx, byte 4		;
  add ebx, byte 4		;
				;
  fld     dword[edx]		; this is the same except it clears the stack
  fld     dword[ebx]		;
  fld     st2			;
  fmul    st0,    st2		;
  fld     st4			;
  fmul    st0,    st2		;
  fsubp   st1,    st0		;
  fstp    dword[edx]		;
  fmulp   st2,    st0		;[Zy] [Zz*cY] [sY]
  fmulp   st2,    st0		;  [Zz*cY] [sY*Zy]
  faddp   st1,    st0		;
  fstp    dword[ebx]		;
				;
  retn				;

;                                           -----------------------------------
;                                                                 _calc_normals
;==============================================================================

_calc_normals:
;>
;; Runs through the faces and generates the normal vectors needed for lighting.
;;
;; Parameters:
;;------------
;; ESI = pointer to verts
;; EDI = pointer to faces
;; ECX = number of faces
;<

%define x1 dword[eax+vect3.x]
%define x2 dword[ebx+vect3.x]
%define x3 dword[edx+vect3.x]
%define y1 dword[eax+vect3.y]
%define y2 dword[ebx+vect3.y]
%define y3 dword[edx+vect3.y]
%define z1 dword[eax+vect3.z]
%define z2 dword[ebx+vect3.z]
%define z3 dword[edx+vect3.z]

.face:
;;normalX = y1 ( z2 - z3 ) + y2 ( z3 - z1 ) + y3 ( z1 - z2 )
;;normalY = z1 ( x2 - x3 ) + z2 ( x3 - x1 ) + z3 ( x1 - x2 )
;;normalZ = x1 ( y2 - y3 ) + x2 ( y3 - y1 ) + x3 ( y1 - y2 )

  movzx     eax,word[edi+face.vert1]		;
  movzx     ebx,word[edi+face.vert2]		;
  movzx     edx,word[edi+face.vert3]		;
  lea eax, [eax*3]
  lea ebx, [ebx*3]
  lea edx, [edx*3]
  lea eax, [esi+eax*4]
  lea ebx, [esi+ebx*4]
  lea edx, [esi+edx*4]


  fld z2			;z2
  fld z3			;z3     z2
  fsubp st1,st0			;z2-z3
  fld y1			;y1     z2-z3
  fmulp st1,st0			;y1(z2-z3)
  fld z3			;z3     y1(z2-z3)
  fld z1			;z1     z3      y1(z2-z3)
  fsubp st1,st0			;z3-z1  y1(z2-z3)
  fld y2			;y2     z3-z1   y1(z2-z3)
  fmulp st1,st0			;y2(z3-z1)      y1(z2-z3)
  fld z1			;z1     y2(z3-z1)       y1(z2-z3)
  fld z2			;z2     z1      y2(z3-z1)       y1(z2-z3)
  fsubp st1,st0			;z1-z2  y2(z3-z1)       y1(z2-z3)
  fld y3			;y3     z1-z2   y2(z3-z1)       y1(z2-z3)
  fmulp st1,st0			;y3(z1-z2)      y2(z3-z1)       y1(z2-z3)
  faddp st1,st0			;y3(z1-z2)+y2(z3-z1)    y1(z2-z3)
  faddp st1,st0			;y3(z1-z2)+y2(z3-z1)+y1(z2-z3)
  fstp dword[edi+face.norX]	;
				;
  fld x2			;z2
  fld x3			;z3     z2
  fsubp st1,st0			;z2-z3
  fld z1			;y1     z2-z3
  fmulp st1,st0			;y1(z2-z3)
  fld x3			;z3     y1(z2-z3)
  fld x1			;z1     z3      y1(z2-z3)
  fsubp st1,st0			;z3-z1  y1(z2-z3)
  fld z2			;y2     z3-z1   y1(z2-z3)
  fmulp st1,st0			;y2(z3-z1)      y1(z2-z3)
  fld x1			;z1     y2(z3-z1)       y1(z2-z3)
  fld x2			;z2     z1      y2(z3-z1)       y1(z2-z3)
  fsubp st1,st0			;z1-z2  y2(z3-z1)       y1(z2-z3)
  fld z3			;y3     z1-z2   y2(z3-z1)       y1(z2-z3)
  fmulp st1,st0			;y3(z1-z2)      y2(z3-z1)       y1(z2-z3)
  faddp st1,st0			;y3(z1-z2)+y2(z3-z1)    y1(z2-z3)
  faddp st1,st0			;y3(z1-z2)+y2(z3-z1)+y1(z2-z3)
  fstp dword[edi+face.norY]	;
				;
  fld y2			;z2
  fld y3			;z3     z2
  fsubp st1,st0			;z2-z3
  fld x1			;y1     z2-z3
  fmulp st1,st0			;y1(z2-z3)
  fld y3			;z3     y1(z2-z3)
  fld y1			;z1     z3      y1(z2-z3)
  fsubp st1,st0			;z3-z1  y1(z2-z3)
  fld x2			;y2     z3-z1   y1(z2-z3)
  fmulp st1,st0			;y2(z3-z1)      y1(z2-z3)
  fld y1			;z1     y2(z3-z1)       y1(z2-z3)
  fld y2			;z2     z1      y2(z3-z1)       y1(z2-z3)
  fsubp st1,st0			;z1-z2  y2(z3-z1)       y1(z2-z3)
  fld x3			;y3     z1-z2   y2(z3-z1)       y1(z2-z3)
  fmulp st1,st0			;y3(z1-z2)      y2(z3-z1)       y1(z2-z3)
  faddp st1,st0			;y3(z1-z2)+y2(z3-z1)    y1(z2-z3)
  faddp st1,st0			;y3(z1-z2)+y2(z3-z1)+y1(z2-z3)
  fstp dword[edi+face.norZ]	;

;we now have the vector, but it's not normalised.
  fld dword[edi+face.norZ]
  fld dword[edi+face.norY]
  fld dword[edi+face.norX]
			;x      z       y
  fld st0		;x      x       z       y
  fmul st0,st0		;x^2    x       z       y
  fld st2		;z      x^2     x       z       y
  fmul st0,st0		;z^2    x^2     x       z       y
  faddp st1,st0		;z^2+x^2        x       z       y
  fld st3		;y      z^2+x^2 x       z       y
  fmul st0,st0		;y^2    z^2+x^2 x       z       y
  faddp st1,st0		;y^2+z^2+x^2    x       z       y
  fsqrt			;legnth x       z       y
  fdiv st1,st0		;legnth X       z       y
  fdiv st2,st0		;legnth X       Z       y
  fdivp st3,st0		;X      Z       Y

  fstp    dword[edi+face.norX]
  fstp    dword[edi+face.norY]
  fstp    dword[edi+face.norZ]

  add edi, byte face_size

  dec ecx
  jnz near .face

  retn

;                                           -----------------------------------
;                                                            hydro3d.mul_matrix
;==============================================================================

globalfunc hydro3d.mul_matrix
;>
;; calculates 4x4 matrix multiplications
;; 
;; parameters:
;; -----------
;; EBX = ptr to first multiplicand
;; EDI = ptr to seccond multiplicand
;; EDX = ptr to place to put result matrix
;;
;; returned values:
;; ----------------
;; all regs except ECX = unmodified
;;
;; status:
;; -------
;; hellishly unoptimised, but working
;<

; [EBX] * [EDI] = [EDX]


  ;; we want to have 2 indicies, one for the X and one for the Y in the matrix.
  ;; The X index will go 0,16,32,48 and the Y index will go 0,4,8,12. To make
  ;; the counters easier to deal with we will go in reverse order so we can use
  ;; a js after the sub from the index rather than a sub + cmp.

  pushad

  mov eax, 12	; Y index
.outer_loop:
  mov esi, 48	; X index
.inner_loop:
  ; load row
  fld dword[ebx+eax+0]
  fld dword[ebx+eax+16]
  fld dword[ebx+eax+32]
  fld dword[ebx+eax+48]

  ; load col
  fld dword[edi+esi+0]
  fld dword[edi+esi+4]
  fld dword[edi+esi+8]
  fld dword[edi+esi+12]	; 12 8 4 0 48 32 16 0

  fmulp st4
  fmulp st4
  fmulp st4
  fmulp st4

  faddp st3
  faddp st2
  faddp st1

  lea ebp, [edx+eax]
  fstp dword[ebp+esi]

  sub esi, byte 16
  jns .inner_loop

  sub eax, byte 4
  jns .outer_loop

  popad
  retn

;                                           -----------------------------------
;                                                          sys_log.print_matrix
;==============================================================================

globalfunc sys_log.print_matrix
;>
;; Dumps a 4x4 matrix to the system log, imagine that!
;;
;; parameters:
;; -----------
;; ESI = pointer to matrix
;;
;; returned values:
;; ----------------
;; all registers and flags unchanged.
;;
;; requires:
;; ---------
;; one fpu register
;;
;; status:
;; -------
;; working
;<

  pushad
  pushfd

  mov ebx, esi
  mov ecx, 4

  mov esi, .lf_str
  externfunc sys_log.print_string

.loop:
  fld dword[ebx+matrix44.xx]
  externfunc sys_log.print_float
  fstp st0
  mov esi, .space_str
  externfunc sys_log.print_string
  
  fld dword[ebx+matrix44.yx]
  externfunc sys_log.print_float
  fstp st0
  mov esi, .space_str
  externfunc sys_log.print_string

  fld dword[ebx+matrix44.zx]
  externfunc sys_log.print_float
  fstp st0
  mov esi, .space_str
  externfunc sys_log.print_string

  fld dword[ebx+matrix44.tx]
  externfunc sys_log.print_float
  fstp st0
  mov esi, .lf_str
  externfunc sys_log.print_string

  add ebx, matrix44.xy
  dec ecx
  jnz .loop

  externfunc sys_log.terminate

  popfd
  popad
  retn

[section .data]
.space_str: db " ",1
.lf_str: db 0x0a,1
__SECT__

;                                           -----------------------------------
;                                                               section .c_info
;==============================================================================

section .c_info
    db 0,1,26,"a"
    dd str_title
    dd str_author
    dd str_copyrights

    str_title:
    db "Hydro3D $Revision: 1.28 $",0

    str_author:
    db 'Phil "indigo" Frost <daboy@xgs.dhs.org>',0

    str_copyrights:
    db "BSD licensed",0
