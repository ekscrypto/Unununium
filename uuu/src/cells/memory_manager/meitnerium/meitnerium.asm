;; $Header: /cvsroot/uuu/uuu/src/cells/memory_manager/meitnerium/meitnerium.asm,v 1.9 2001/12/07 01:46:30 daboy Exp $
;;
;; Meitnerium memory manager cell
;; Copyright (c) 2001 Phil Frost
;; Distributed under the BSD license, see file 'license' for details.
;;
;; when to use this cell:
;; ----------------------
;; Use this cell when you want to allocate lotts of fairly small, fixed size
;; memory chunks. This has 2 advantages; it doesn't fragment memory, it's MUCH
;; faster, and less memory is wasted for overhead. Dealloc is somewhat
;; not-hyper-fast (but it's probally just as deallocing with oxygen); this was
;; a tradeoff for less memory overhead.
;;
;; short description of how this works:
;; ------------------------------------
;; linked list'o'rama! Memory is requested from oxygen in "chunks" which
;; contain any power of 2 blocks of a user-specified size. The first chunk
;; allocated has a 12 byte header "root_chunk", and a normal chunk procedes
;; right after that.
;;
;; The chunks are linked together in 2 ways. There is a linked list of all the
;; chunks just so we can dealloc them, and there is a linked list of the chunks
;; with free blocks so we can alloc quickly. The root chunk is oviously the
;; first chunk in the first list, but the first chunk in the chunks with free
;; blocks list is stored in root_chunk.first_free.
;;
;; Inside each chunk is a counter of the availible blocks. This is used to
;; determine when the chunk is full, and when it was full and one block was
;; dealloced (in this case it needs to be added to the free chunks list)
;;
;; In each chunk is also a linked list of the free blocks. The first free block
;; is in chunk.next_free_block. If the free blocks count is zero this value is
;; ignored. Then, inside each free block is a pointer to the next free block;
;; once again the last one need not have a null because the free block count is
;; used.

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_

;                                           -----------------------------------
;                                                                      includes
;==============================================================================

%include "vid/mem.inc"
%include "vid/mem.fixed.inc"

;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc root_chunk
  .block_size:	resd 1	; size of the fixed size blocks
  .block_count:	resd 1	; number of blocks / chunk as power of 2
  .first_free:	resd 1	; ptr to first chunk in the free chunk chain
endstruc

struc chunk
  .next:		resd 1	; ptr to next chunk in the chain; 0 for none
  .next_free:		resd 1	; ptr to next chunk in the free chunk chain
  .next_free_block:	resd 1	; ptr to next free block in this chunk
  .free_blocks:		resd 1	; number of free blocks in this chunk
endstruc

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                         mem.fixed.alloc_space
;==============================================================================

globalfunc mem.fixed.alloc_space
;>
;; This function initializes space for a group of fixed size blocks. It must be
;; called once before allocating fixed size blocks. ECX, the number of blocks
;; to reserve at a time, determines how many of the smaller fixed size blocks
;; are in each larger block. So, if ECX = 32 and ECX = 4, memory will be
;; allocated in 32*2^4 byte blocks (plus any overhead). Smaller values mean less
;; wasted memory due to reserved, but not used memory; larger values mean less
;; wasted memory due to the overhead of Meitnerium and Oxygen.
;;
;; This function needs to be called only once to set up the space; it will be
;; expanded as needed by Meitnerium.
;;
;; parameters:
;; -----------
;; EDX = size of blocks to be allocated, must be at least 4 bytes
;; ECX = number of blocks to reserve at a time as a power of two, so a value of
;;       4 would allocate room for 16 blocks at a time (must be != 0)
;;
;; returned values:
;; ----------------
;; EDI = pointer to root block; use this in calls to other Meitnerium functions
;; errors as usual
;; registers saved as usual
;<

  pushad
  shl edx, cl
  lea ecx, [edx + root_chunk_size + chunk_size]
  dbg_print "allocating 0x",1
  dbg_print_hex ecx
  dbg_print " bytes of RAM for root chunk",0
  externfunc mem.alloc
  mov edx, [esp+20]
  mov ecx, [esp+24]
  jc .end

  xor eax, eax
  mov [edi+root_chunk.block_size], edx
  lea esi, [edi+root_chunk_size]
  mov [edi+root_chunk.block_count], ecx
  mov [edi+root_chunk.first_free], esi
  
  mov [edi+root_chunk_size+chunk.next], eax
  mov [edi+root_chunk_size+chunk.next_free], eax
  add esi, byte chunk_size
  mov [edi+root_chunk_size+chunk.next_free_block], esi
  inc eax
  shl eax, cl
  mov [edi+root_chunk_size+chunk.free_blocks], eax

  lea ebp, [esi+edx]
.loop:
  mov [esi], ebp
  add esi, edx
  add ebp, edx
  dec eax
  jnz .loop

.end:
  dbg_print "allocated root chunk at 0x",1
  dbg_print_hex edi
  dbg_term_log
  mov esi, [esp+4]
  mov ebp, [esp+8]
  mov ebx, [esp+16]
  add esp, byte 32
  retn

;                                           -----------------------------------
;                                                               mem.fixed.alloc
;==============================================================================

globalfunc mem.fixed.alloc
;>
;; Allocates a fixed size memory block from a previously allocated
;; fixed_size_block_space
;;
;; parameters:
;; -----------
;; EDI = pointer to fixed size block space
;;
;; returned values:
;; ----------------
;; EDI = pointer to allocated block
;; errors as usual
;; registers saved as usual
;<

  push ebp
  push esi
  mov esi, edi
  
  mov ebp, [esi+root_chunk.first_free]	; EBP= ptr to first chunk w/ free blocks
  test ebp, ebp				;   unless it's 0, then there is none
  jz .make_new_chunk

  mov edi, [ebp+chunk.next_free_block]
  mov eax, [edi]
  mov [ebp+chunk.next_free_block], eax
  dec dword[ebp+chunk.free_blocks]
  jz .filled_chunk

  clc
  pop esi
  pop ebp
  retn

.filled_chunk:
  mov eax, [ebp+chunk.next_free]
  mov [esi+root_chunk.first_free], eax
  dbg_print "allocated block at 0x",1
  dbg_print_hex edi
  dbg_term_log
  clc
  pop ebp
  pop esi
  retn

.make_new_chunk:	; we have run out of free chunks, so make a new one
  dbg_print "making a new chunk",0
  pushad
  mov edx, [esi+root_chunk.block_size]
  mov ecx, [esi+root_chunk.block_count]
  push edx
  shl edx, cl
  push ecx
  lea ecx, [edx + chunk_size]
  externfunc mem.alloc
  pop ecx
  pop edx
  jc .end
  
  mov [esi+root_chunk.first_free], edi
  
  mov eax, [esi+root_chunk_size+chunk.next]
  mov [edi+chunk.next], eax
  mov [esi+root_chunk_size+chunk.next], edi
  xor eax, eax
  mov [edi+chunk.next_free], eax
  inc eax
  shl eax, cl				; EAX = number of blocks
  dec eax				; we have already allocated one

  mov [edi+chunk.free_blocks], eax

  lea esi, [edi+chunk_size+edx]		; ESI = ptr to 2nd block
  lea ebp, [esi+edx]
  mov [edi+chunk.next_free_block], esi

.loop:
  mov [esi], ebp
  add esi, edx
  add ebp, edx
  dec eax
  jnz .loop

  add edi, byte chunk_size		; move pointer past the header
.end:
  mov [esp], edi
  popad
  pop esi
  pop ebp
  clc
  retn

;                                           -----------------------------------
;                                                       mem.fixed.dealloc_space
;==============================================================================

globalfunc mem.fixed.dealloc_space
;>
;; deallocates a previously allocated fixed block space and all of the blocks
;; in it.
;; 
;; parameters:
;; -----------
;; ESI = pointer to fixed size block space
;;
;; returned values:
;; ----------------
;; errors as usual
;; registers ARE destroyed
;<

  mov ebp, [esi+root_chunk_size+chunk.next]
  mov eax, esi
  dbg_print "deallocing chunk at 0x",1
  dbg_print_hex eax
  dbg_term_log
  externfunc mem.dealloc
  jc .end

  test ebp, ebp
  jz .done

.loop:
  mov eax, ebp
  mov ebp, [ebp+chunk.next]
  dbg_print "deallocing chunk at 0x",1
  dbg_print_hex eax
  dbg_term_log
  externfunc mem.dealloc
  jc .end
  test ebp, ebp
  jnz .loop
.done:
  clc
.end:
  retn

;                                           -----------------------------------
;                                                             mem.fixed.dealloc
;==============================================================================

globalfunc mem.fixed.dealloc
;>
;; deallocates one fixed size block
;;
;; parameters:
;; -----------
;; EAX = pointer to fixed size block space
;; EDI = pointer to fixed size block to deallocate
;;
;; returned values:
;; ----------------
;; errors as usual
;; registers saved as usual
;<

  pushad
  mov edx, eax

  mov eax, [edi+root_chunk.block_size]
  mov ecx, [edi+root_chunk.block_count]
  shl eax, cl
  add eax, byte chunk_size	; EAX = total chunk size
  lea ebp, [edi+root_chunk_size]; EBP = ptr to chunk to test

  jmp short .loop_enter

.loop:
  mov ebp, [ebp+chunk.next]	; load ptr to next chunk
  test ebp, ebp			; if we hit a zero pointer we are hosed
  jz .could_not_find_chunk
  
.loop_enter:
  push edx
  sub edx, ebp			; sub the base address of the chunk from edx
  cmp edx, eax			; see if edx falls within the chunk
  pop edx
  jnbe .loop

  ;; EDX = ptr to block to dealloc
  ;; EBP = ptr to chunk block is in
  ;; EDI = ptr to root chunk
  ;; ECX = number of blocks as power of 2

  mov eax, [ebp+chunk.next_free_block]	;
  mov [edx], eax			; put old next in [edx]
  mov [ebp+chunk.next_free_block], edx	; and edx in the new one

  mov edx, [ebp+chunk.free_blocks]
  test edx, edx
  jnz .was_not_full

  ; if the chunk was previously full, add it to the free chunk chain
  mov eax, [edi+root_chunk.first_free]
  mov [edi+root_chunk.first_free], ebp
  mov [ebp+chunk.next_free], eax

.was_not_full:
  inc edx				; just dealloced one, one less free
  xor eax, eax
  inc eax
  shl eax, cl
  cmp edx, eax
  jae .dealloc_whole_block
  mov [ebp+chunk.free_blocks], edx
  popad
  clc
  retn

.could_not_find_chunk:
  mov eax, __ERROR_INVALID_PARAMETERS__
  popad
  stc
  retn

.dealloc_whole_block:
  ; XXX should make some intelegent decision on how to dealloc here, but for
  ; now just leave it in; future block allocs will still use this chunk.
  popad
  clc
  retn

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================

section .c_info
db 0, 1, 0, 'a'
dd str_cellname
dd str_author
dd str_copyrights
str_cellname:	dd "Meitnerium - fixed size memory block manager"
str_author:	dd 'Phil Frost <daboy@xgs.dhs.org>'
str_copyrights:	dd 'Copyright 2001 by Phil Frost; distributed under the BSD license'
