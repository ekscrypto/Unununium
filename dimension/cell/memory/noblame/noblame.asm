;; $Header: /cvsroot/uuu/dimension/cell/memory/noblame/noblame.asm,v 1.2 2002/01/23 01:53:50 jmony Exp $
;;
;; Little simplified memory manager.  It doesn't accept memory deallocations,
;; and uses a simple unique pointer for memory allocations.  Now if things
;; fails while using this memory manager, it is because something else is
;; broken.
;;
;; by EKS, on a desperate day.
;; $Revision: 1.2 $
;;
[bits 32]

%define EXTENDED_RAM	4	; number of MB of RAM on your system
%define CONVENTIONAL_RAM	640	; number of KB of Conventional ram


extern __CORE_HEADER__

section .c_init
global _start:
_start:
_c_init_start:

  push esi
  mov esi, __CORE_HEADER__
  add esi, dword [esi + hdr_core.core_size]
  cmp esi, 0x00100000
  jb short .in_conventional

.in_extended:
  mov [extended_low_limit], esi
  sub esi, 0x00100000
  sub [mem.free_ram], esi
  mov esi, 0x00000500

.in_conventional:
  ; esi = end of core address
  mov [conventional_low_limit], esi
  sub [mem.free_ram], esi

  pop esi

section .text

_text_start:

globalfunc mem.realloc
;---------------------
; resizes a block of memory
;
; parameters:
; -----------
; EAX = base address of block to resize
; ECX = new size
;
; returned values:
; ----------------
; EAX = size of block requested (ecx from call)
; ECX = actuall size of memory allocated
; EDI = new memory location
; registers and errors as usual

  push esi
  push ecx
  
  push eax
  call mem.alloc
  jc .error
  pop esi
  push ecx
  push edi
  
  shr ecx, 2
  rep movsd

  pop edi
  pop ecx
  pop eax
  pop esi

  clc
  retn

.error:
  pop edi
  pop eax
  pop esi
  mov eax, __ERROR_INSUFFICIENT_MEMORY__
  stc
  retn


globalfunc mem.alloc
;-------------------------------
;>
;; param: ecx = mem requested
;; returns: edi = block allocated
;; cf = 1 if error occured, eax = error code
;<

  push ecx
  add ecx, byte 63
  and cl, 0xFF-63
  mov edi, dword [extended_mem_top]
  sub edi, ecx
  cmp edi, dword [extended_low_limit]
  jae short .validated

  pop eax
  mov eax, __ERROR_INSUFFICIENT_MEMORY__
  stc
  retn

.validated:
  mov dword [extended_mem_top], edi
  sub dword [mem.free_ram], ecx
  add dword [mem.used_ram], ecx
  pop eax
  clc
  retn






globalfunc mem.alloc_20bit_address
;---------------------------------
;>
;; params: ecx = mem requested
;; returns: edi = block allocated
;; cf = 1 if error occured, eax = error code
;<

  push edi
  add ecx, byte 63
  and cl, 0xFF-63

  mov edi, dword [conventional_mem_top]
  sub edi, ecx
  cmp edi, dword [conventional_low_limit]
  jae short .successful

  pop edi
  mov eax, __ERROR_INSUFFICIENT_MEMORY__
  stc
  retn

.successful:
  mov dword [conventional_mem_top], edi
  add dword [mem.used_ram], ecx
  add esp, byte 4
  clc
  retn






globalfunc mem.dealloc
;---------------------------------
;>
;; params: eax = pointer to memblock to free
;; returns: cf = 1 if failed, eax = error code
;<

  clc
  retn


section .data

_data_start:

globalfunc mem.used_ram
dd 0

globalfunc mem.used_swap
dd 0

globalfunc mem.free_ram
dd ((EXTENDED_RAM * 0x00100000) - 0x00100000) + (CONVENTIONAL_RAM * 1024)

globalfunc mem.free_swap
dd 0

conventional_low_limit: dd 0
conventional_mem_top: dd CONVENTIONAL_RAM * 1024
extended_low_limit: dd 0x00100000
extended_mem_top: dd EXTENDED_RAM * 0x00100000
