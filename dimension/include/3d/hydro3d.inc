; $Header: /cvsroot/uuu/dimension/include/3d/hydro3d.inc,v 1.1.1.1 2002/01/17 04:31:40 instinc Exp $

; vim: syntax=uuu

;; A note on the matricies:
;;
;; | xx yx zx | tx |
;; | xy yy zy | ty |
;; | xz yz zz | tz |
;; -----------------
;; | xw yw zw | tw |
;;
;; x? y? and z? are the x, y, and z unit vectors respectivly.
;; t? is the translation. tw is almost always 1,
;; xw, xy and xz are almost always 0.
;;
;; Keep in mind that the matrix is not stored left-right top-bottom in memory
;; but is stored top-bottom left-right much like as in opengl. This is done
;; because it allows easy isolation of the unit vectors and is easier to load
;; into SIMD registers.
;;
;; Everything uses a full 4x4 matrix even though some values might be assumed.
;; This makes things more flexible and the extra memory usage is negligible.

struc matrix44			; 4 by 4 matrix, full homogenous
  .xx:	resd 1	; 0
  .xy:	resd 1	; 4
  .xz:	resd 1	; 8
  .xw:	resd 1	; 12

  .yx:	resd 1	; 16
  .yy:	resd 1	; 20
  .yz:	resd 1	; 24
  .yw:	resd 1	; 28

  .zx:	resd 1	; 32
  .zy:	resd 1	; 36
  .zz:	resd 1	; 40
  .zw:	resd 1	; 44

  .tx:	resd 1	; 48
  .ty:	resd 1	; 52
  .tz:	resd 1	; 56
  .tw:	resd 1	; 60
endstruc

struc vect3			; 3 dimentional vector
  .x:	resd 1
  .y:	resd 1
  .z:	resd 1
endstruc

struc vect4			; 4 dimentional vector (homogenous)
  .x:	resd 1
  .y:	resd 1
  .z:	resd 1
  .w:	resd 1
endstruc

struc scene
  .objects:	resd 1		;pointer to object list (an ICS channel)
  .camera:	resd 1		;pointer to current camera
  .lights:	resd 1		;pointer to lights
  .res_x:	resw 1          ;X resloution
  .res_y:	resw 1          ;Y resloution
  .buffer:	resd 1		;pointer to output buffer
endstruc

struc camera
  .cmatrix:	resb matrix44_size	;camera matrix; does the orientation
  .pmatrix:	resb matrix44_size	;projection matrix; does the projection
  .tmatrix:	resb matrix44_size	;total matrix, proj*camera
endstruc

struc object
  .omatrix:	resb matrix44_size	;object matrix
  .ematrix:	resb matrix44_size	;eyespace matrix
  .mesh:	resd 1			;pointer to mesh
  .points:	resd 1			;pointer to 2-D points
  .material:	resd 1			;pointer to material (unused)
  .parrent:	resd 1			;pointer to parrent object (unused)
  .children:	resd 1		;pointer to children (an ICS channel) (unused)
endstruc

struc mesh
  .vert_count:	resd 1			;number of verticies
  .face_count:	resd 1			;number of faces (all triangles)
  .verts:	resd 1			;pointer to verts
  .faces:	resd 1			;pointer to faces
endstruc

;struc point		;2-D point
;  .x:		resw 1            ;The 2d cordinates (from __calc_points)
;  .z:		resw 1
;  .yprime:	resd 1          ;the transformed 3d Y cordinate
;endstruc

struc face
  .vert1:	resw 1          ;
  .vert2:	resw 1          ;Must be asigned clockwise
  .vert3:	resw 1          ;
  .norX:	resd 1    ;
  .norY:	resd 1    ;The normal vector (from __calc_normals, in object space)
  .norZ:	resd 1    ;
endstruc					
