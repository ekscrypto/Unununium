; small, hopefully stable memory manager using linked list
section .text

struc _x_mem_block
.previous resd 1
.next resd 1
.size resd 1
endstruc

section .c_info

  db 1,0,0,0
  dd str_title
  dd str_author
  dd str_copyright

  str_title:
  db "Octane Memory Manager",0
  str_author:
  db "eks",0
  str_copyright:
  db "Copyright (C) 2002, Dave Poirier",0x0A
  db "Distributed under the X11 License",0

section .c_init
global _start
_start:
  ; We do nothing here
  ; added by Luke
  retn

section .text
							 globalfunc mem.realloc
;------------------------------------------------------------------------------
; params:
; o eax = base address of current block
; o ecx = new block size desired
  push ecx
  push eax
  call mem.alloc
  jc .leave
  pop eax
  pushad
  mov esi, eax
  shr ecx, 2
  rep movsd
  call mem.dealloc
  popad
  pop eax
.leave:
  add esp, byte 8
  retn
;------------------------------------------------------------------------------


					     globalfunc mem.alloc_20bit_address
;------------------------------------------------------------------------------
; params:
; o ecx = required size
   mov edi, 0x000FFFFF		; highest address allowed
   jmp mem.alloc.common
;------------------------------------------------------------------------------

							   globalfunc mem.alloc
;------------------------------------------------------------------------------
; params:
; o ecx = size of memory block required
; returns:
; o edi = pointer to memory block allocated
  mov edi, 0xFFFFFFFF		; highest address allowed
.common:
  mov eax, ecx
  pushad

  mov ebp, memory_lock
  call pthread.mutex_lock	; TODO: make that an externfunc

  add ecx, byte 127
  and ecx, byte -64
  mov esi, [free_blocks]
  lea eax, [ecx + 128]

.checking_free_blocks:
  test esi, esi
  jz short .failed
  cmp esi, edi
  ja short .address_too_high
  cmp ecx, [esi + _x_mem_block.size]
  jbe short .found_match
.address_too_high:
  mov esi, [esi + _x_mem_block.next]
  jmp short .checking_free_blocks

.failed:
  call pthread.mutex_unlock	; TODO: make that an externfunc

  popad
  mov eax, __ERROR_INSUFFICIENT_MEMORY__
  stc
  retn

.found_match:
  mov [esp + 24], ecx
  mov edx, [esi + _x_mem_block.size]
  cmp edx, eax
  jbe short .dont_split

  sub edx, ecx
  lea eax, [esi + edx]
  mov [esi + _x_mem_block.size], edx
  jmp short .common_linking

.dont_split:
  mov eax, esi
  mov edi, free_blocks
  call _unlink_block
.common_linking:
  mov edi, used_blocks
  call _link_block
  pop edi
  add eax, 64
  push eax

  call pthread.mutex_unlock	; TODO: make that an externfunc

  popad
  sub ecx, byte 64
  clc
  retn
;------------------------------------------------------------------------------





							 globalfunc mem.dealloc
;------------------------------------------------------------------------------
; params:
; o eax = base address of freed block
  pushad

  mov ebp, memory_lock
  call pthread.mutex_lock	; TODO: make that an externfunc

  mov edi, used_blocks
  mov ebx, [edi]
  sub eax, 64
.search_allocated_blocks:
  test ebx, ebx
  jz short .failed
  cmp ebx, eax
  jz short .found_match
  mov ebx, [ebx + _x_mem_block.next]
  jmp short .search_allocated_blocks

.failed:

  call pthread.mutex_unlock	; TODO: make that an externfunc

  popad
  stc
  retn

.found_match:
  call _unlink_block
  mov edi, free_blocks
  call _link_block

  call pthread.mutex_unlock	; TODO: make that an externfunc

  popad
  clc
  retn
;------------------------------------------------------------------------------





					      globalfunc mem.alloc_forced_range
;------------------------------------------------------------------------------
; params:
; o eax = base address
; o ecx = block size
  clc
  retn
;------------------------------------------------------------------------------


					    globalfunc mem.dealloc_forced_range
;------------------------------------------------------------------------------
; params
; o eax = base address
; o ecx = block size
  pushad

  mov ebp, memory_lock
  call pthread.mutex_lock	; TODO: make that an externfunc
  push ebp
  
  mov [eax + _x_mem_block.size], ecx
  mov edi, [free_blocks]
  xor edx, edx
  mov ebp, edi
.browsing_lower_blocks:
  test edi, edi
  jz short .eolblocks

  mov ebx, [edi + _x_mem_block.size]
  add ebx, edi
  cmp eax, ebx
  jz short .merge_with_lower
  mov edi, [edi + _x_mem_block.next]
  jmp short .browsing_lower_blocks

.merge_with_lower:
  sub ebx, edi
  add ecx, ebx
  mov [edi + _x_mem_block.size], ecx
  mov eax, edi
  inc edx

.eolblocks:
  mov edi, ebp
  add ecx, eax
.browsing_higher_blocks:
  test edi, edi
  jz short .eohblocks
  cmp ecx, edi
  jz short .merge_with_higher
  mov edi, [edi + _x_mem_block.next]
  jmp short .browsing_higher_blocks

.merge_with_higher:
  test edx, edx
  jz short .bypass_higher_unlink
  pushad
  mov eax, edi
  mov edi, free_blocks
  call _unlink_block
  popad
.bypass_higher_unlink:
  sub ecx, eax
  add ecx, [edi + _x_mem_block.size]
  mov [eax + _x_mem_block.size], ecx
.eohblocks:
  test edx, edx
  jnz short .leave
  mov [eax + _x_mem_block.next], ebp
  mov [eax + _x_mem_block.previous], dword 0
  mov [free_blocks], eax
  test ebp, ebp
  jz short .leave
  mov [ebp + _x_mem_block.previous], eax
.leave:

  pop ebp
  call pthread.mutex_unlock	; TODO: make that an externfunc

  popad
  clc
  retn
;------------------------------------------------------------------------------


								 _unlink_block:
;------------------------------------------------------------------------------
; eax = block to unlink
; edi = pointer to root node pointer
  mov ebx, [eax + _x_mem_block.previous]
  mov edx, [eax + _x_mem_block.next]
  test ebx, ebx
  jz short .block_was_root

  mov [ebx + _x_mem_block.next], edx
  jmp short .previous_updated
.block_was_root:
  mov [edi], edx
.previous_updated:
  test edx, edx
  jz short .completed
  mov [edx + _x_mem_block.previous], ebx
.completed:
  retn
;------------------------------------------------------------------------------


								   _link_block:
;------------------------------------------------------------------------------
; eax = block to link
; edi = pointer to root node pointer
  xor edx, edx
  mov [eax + _x_mem_block.previous], edx
  mov esi, [edi]
  mov [edi], eax
  mov [eax + _x_mem_block.next], esi
  retn
;------------------------------------------------------------------------------


; TODO: remove those functions once we can safely use the externfunc ones
pthread.mutex_lock:
pthread.mutex_unlock:
  retn

section .bss
free_blocks:	resd 1
used_blocks:	resd 1
globalfunc mem.used_ram
		resd 1
globalfunc mem.free_ram
		resd 1
globalfunc mem.free_swap
globalfunc mem.used_swap
		resd 1
rmutex(memory_lock)
