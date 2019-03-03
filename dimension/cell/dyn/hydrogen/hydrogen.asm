;; $Header: /cvsroot/uuu/dimension/cell/dyn/hydrogen/hydrogen.asm,v 1.2 2002/01/23 01:44:33 jmony Exp $
;;
;; Hydrogen - VOiD fixer upper
;; Copyright (C) 2001 - Phil Frost
;; Distributed under the BSD License; see file "license" for details
;;
;; Currently does nothing usefull :P
;; This file should also be moved out of the jit directory cuz that's not what
;; it does and we have decided to replace jit with "dynamic linking"

[bits 32]


;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_

;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc fid_node
  .left:	resd 1
  .right:	resd 1
  .fid:		resd 1
  .value:	resd 1
endstruc

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init
global _start
_start:
  mov edx, fid_node_size
  mov ecx, 6		; allocate in 64 block chunks
  externfunc mem.fixed.alloc_space
  jc $
  mov [fid_node_space], edi
  
  retn

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                   _fid_locate
;==============================================================================

_fid_locate:
;>
;; parameters:
;; -----------
;; EDX = VID to locate
;;
;; returned values:
;; ----------------
;; CF = 0: node was found
;;   EBX = ptr to node
;;   EBP = ptr to parrent node, or -1 if EBX is the anchor node
;; CF = 1: node was not found
;;   ZF = 0: no nodes exist in the tree
;;   ZF = 1: some nodes exist in the tree
;;     EBP = ptr to parent node (use to link, if desired)
;;
;; EAX = undefined
;; registers saved as usual
;<

  dbg_print "searching for VID ",1
  dbg_print_hex edx
  dbg_term_log

  xor ebp, ebp
  mov ebx, [fid_anchor]
  dec ebp
  cmp ebx, byte -1
  jz .no_nodes

.search:
  xor eax, eax
  cmp [ebx+fid_node.fid], edx	; set CF if edx is greater
  je .found_node

  adc eax, eax			; inc eax if carry (meaning edx > cur_node)
  mov ebp, ebx
  mov ebx, [ebx+eax*4]
  
  cmp ebx, byte -1
  jne .search

  stc
  retn

.found_node:  ; CF already clear
  clc
  retn

.no_nodes:
  cmp esp, byte -1	; clear ZF and set CF
  retn

;                                           -----------------------------------
;                                                               void.add_global
;==============================================================================

globalfunc void.add_global
;>
;; used to register dynamic hook with the jit handler.  this class allows to
;; register provider dynamic hook
;;
;; parameters:
;; -----------
;; EDX = VID (VOiD symbol ID)
;; EDI = value
;;
;; returned values:
;; ----------------
;; errors as usual
;; registers saved as usual
;<

  dbg_print "adding VID 0x",1
  dbg_print_hex edx
  dbg_print " = 0x",1
  dbg_print_hex edi
  dbg_term_log

  pushad

  call _fid_locate

  jnc .exists
  dbg_print "using value ",1
  dbg_print_hex edi
  dbg_term_log
  jnz .make_first_node

  mov edi, [fid_node_space]
  externfunc mem.fixed.alloc
  jc .end

  xor ebx, ebx
  mov eax, [esp]
  dec ebx
  mov [edi+fid_node.left], ebx
  mov [edi+fid_node.right], ebx
  mov [edi+fid_node.fid], edx
  mov [edi+fid_node.value], eax
  
  cmp [ebp+fid_node.fid], edx	; CF set if EDX is greater
  adc ebx, byte 1		; EBX = 1 if EDX is greater, else 0
  mov [ebp+ebx*4], edi		; i wanna see a C compiler that can do this :P
  
.clc_end:
  mov edi, [esp]
  mov esi, [esp+4]
  clc
.end:
  mov ebx, [esp+16]
  mov ebp, [esp+8]
  add esp, byte 32
  retn

.make_first_node:
  dbg_print "creating first VID node",0
  mov edi, [fid_node_space]
  externfunc mem.fixed.alloc
  jc .end

  xor ebx, ebx
  mov eax, [esp]
  dec ebx
  mov [edi+fid_node.left], ebx
  mov [edi+fid_node.right], ebx
  mov [edi+fid_node.fid], edx
  mov [edi+fid_node.value], eax

  mov [fid_anchor], edi
  jmp short .clc_end

.exists:
  dbg_print "VID already exists",0
  mov eax, __ERROR_VID_EXISTS__
  mov ebx, [esp+16]
  mov ebp, [esp+8]
  add esp, byte 32
  stc
  retn

;                                           -----------------------------------
;                                                            void.lookup_global
;==============================================================================

globalfunc void.lookup_global
;>
;; looks up the value of a VOiD constant; also used before a call to
;; __register_void_hook
;;
;; parameters:
;; -----------
;; EDX = VID to look up
;;
;; returned values:
;; ----------------
;; EAX = value of VID
;; EBX = ptr to VID node; use this to register a hook if desired
;; errors as usual
;; registers saved as usual
;<

  push ebp
  call _fid_locate
  pop ebp
  jc .could_not_find

  mov eax, [ebx+fid_node.value]
  retn

.could_not_find:
  xor eax, eax
  dec eax	; XXX error code needed
  stc
  retn

;                                           -----------------------------------
;                                                                 void.add_hook
;==============================================================================

globalfunc void.add_hook, 100
;>
;; Adds a point in memory that should be kept up to date with a VOiD constant
;;
;; parameters:
;; -----------
;; EBX = ptr to VID node; probally from void.lookup_global
;;
;; returned values:
;; ----------------
;; errors as usual
;; registers saved as usual
;<

  clc
  retn		; just pretend it worked; we don't have any VOiD stuff yet :P

;                                           -----------------------------------
;                                                                 section .data
;==============================================================================

section .data
  fid_anchor:			dd -1
  id_block_space:		dd 0
  fid_node_space:		dd 0

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================

section .c_info

  db 0,0,1,'a'
  dd str_name
  dd str_author
  dd str_copyright

  str_name: db "Hydrogen - VOiD fixer upper",0
  str_author: db 'Phil "indigo" Frost <daboy@xgs.dhs.org>',0
  str_copyright: db "Copyright (C) 2001 Phil Frost",0x0A
                 db "Distributed under the BSD License",0
