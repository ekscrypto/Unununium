;----------------------------------------------------------------------
; Nano-X for Unununium Data Structures                                -
; By: Richard Fillion                   Distributed under BSD License -
;----------------------------------------------------------------------

	struc GR_EVENT_ERROR		; Structure for the Error Event
.GR_EVENT_TYPE 		resd 	1	; Will be GR_EVENT_TYPE_ERROR
.GR_FUNC_NAME		resb 	25	; 25byte area for function name
.GR_ERROR		resd 	1	; Identifies the error type
.GR_ID			resd 	1	; This uniquely identifies a nano-X object.
	endstruc

%macro GR_RECT 1.nolist ; param:  label name
%1: istruc GR_RECT
 iend
%endmacro

%macro GR_RECT 5.nolist ; param:  label, x,y,width,height
%1: istruc GR_RECT
at GR_RECT_t.x, dd %2
at GR_RECT_t.y, dd %3
at GR_RECT_t.width, dd %4
at GR_RECT_t.height, dd %5
iend
%endmacro

