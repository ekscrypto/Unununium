;; $Header: /cvsroot/uuu/dimension/cell/memory/oxygen/oxygen.asm,v 1.2 2002/01/17 15:13:09 instinc Exp $
;;
;; Wave ]|[ Oxygen
;;  .: by EKS :.
;;
;; Distributed under the BSD License see uuu/license for more details
;;
[bits 32]
section .text

;; TODO:
;; memory statistics are a little off; the ammount should be alright as long
;;   as the mem.(de)?alloc_forced_range functions don't fail.

;; _CONSISTENCY_CHECK_
;;
;; If defined, the various trinary tree manipulation routine will do extra
;; checks to make sure the various nodes they are working on are valid memory
;; locations.  This prevent eternal node travelling, linking over non null node
;; and various other errors that may be seen.
;;
%define _CONSISTENCY_CHECK_

;; _EXTERNAL_PARANOIA_
;;
;; When defined, all the parameters passed as argument will be checked, we
;; basically give the minimum trust to the caller.  A defined level also
;; include all the lower one.  So if you select 2, all instructions of
;; 0, 1 and 2 are performed.
;;
;; 0	Absolute trust in external callers, they always provide good values
;; 1	Addresses are good, sizes may require alignment
;; 2	Addresses should be good, check if alignment is ok, if so trust it
;; 3	Double check the address given when deallocating, just to make sure
;;      we aren't screwing something up
;; 4	Blocks of memory forced free should be checked for their address/size
;;      alignment
;; 5	Blocks freed should be checked against all memory registered to make
;;      sure they don't overlap in any way possible
;;
%define _EXTERNAL_PARANOIA_	5


;; _ABSOLUTE_DEBUGGING_
;;
;; If defined, will cause a tons of information to be sent on screen to allow
;; complete monitoring of the memory manager behaviour.
;;
;%define _ABSOLUTE_DEBUGGING_


;; _BLOCK_ALIGNMENT_
;;
;; This value defined the minimum block alignment size.  Note that this value
;; must not be set below the current fmm structure size, otherwise memory
;; corruption is for sure to happen.
;;
%define _BLOCK_ALIGNMENT_ 64


;; _KEEP_RM_IDT_
;;
;; If you plan on using the realmode portal (calcium or another) uncomment
;; this variable to make sure to not mark the realmode interrupt table as 
;; free to allocate ram
;;
%define _KEEP_RM_IDT_


;; _ASSUME_MEMORY_
;;
;; Defineing this causes oxygen to skip the normal memory detection routines
;; and assume a fixed ammount of ram. Some emulators <cough>vmware</cough>
;; seem to have a problem with the bios calls oxygen uses, but it seems to
;; work on all real computers and in bochs.
%ifdef __VMWARE__	; vmware BIOS is br0ken and can't deal with this
%define _ASSUME_MEMORY_	4 MB ; (megabytes)
%endif



;;-------- END OF USER SELECTABLE OPTIONS -----------

%ifidn _EXTERNAL_PARANOIA_, 5
  %define _PARANOIA_5_
  %define _EXTERNAL_PARANOIA_ 4
%endif
%ifidn _EXTERNAL_PARANOIA_, 4
  %define _PARANOIA_4_
  %define _EXTERNAL_PARANOIA_ 3
%endif
%ifidn _EXTERNAL_PARANOIA_, 3
  %define _PARANOIA_3_
  %define _EXTERNAL_PARANOIA_ 2
%endif
%ifidn _EXTERNAL_PARANOIA_, 2
  %define _PARANOIA_2_
  %define _EXTERNAL_PARANOIA_ 1
%endif
%ifidn _EXTERNAL_PARANOIA_, 1
  %define _PARANOIA_1_
%endif
%undef _EXTERNAL_PARANOIA_



section .c_info

    db 3,1,0,"b"
    dd str_title
    dd str_author
    dd str_copyrights

    str_title:
    db "Oxygen $Revision: 1.2 $",0

    str_author:
    db "eks",0

    str_copyrights:
    db "BSD Licensed",0




%if 0
section .c_init
global _start

_start:

%ifndef _ASSUME_MEMORY_
setup_portal:
  mov [core_range.start], esi
  add esi, [esi + hdr_core.core_size]
  mov [core_range.end], esi

  mov esi, portal_code_start
  mov edi, __realmode_portal
  mov ecx, (portal_code_end - portal_code_start) >> 2
  repz movsd

  sgdt [gdtr]
  movzx edx, word [gdtr]
  mov edi, [gdtr + 2]
  inc edx
  mov [edi + edx], dword 0x0000FFFF
  mov [edi + edx + 4], dword 0x00009B00
  mov [edi + edx + 8], dword 0x0000FFFF
  mov [edi + edx + 12], dword 0x00009300
  add edx, byte 15
  mov [gdtr], dx
  lgdt [gdtr]

acquire_memory_details:

  push byte 0
  push byte 0x15
  mov edi, 0x00007A00
.acquiring_smap:
  mov eax, 0x0000E820		; GET SYSTEM MEMORY MAP
  mov edx, 'SMAP'
  mov ecx, 0x20
  xor ebx, ebx
  call __realmode_portal
  jc short .smap_failed
  cmp eax, 'SMAP'
  jnz short .smap_failed
  or byte [acquisition_status], byte 0x02
  add edi, byte 0x20
  or ebx, ebx
  jnz short .acquiring_smap

.smap_acquired:
  add esp, byte 8
  pop eax
dmej 0xFF880803	; INCOMPLETE DEV, waiting to find some computer that at least
		; support this call so as to be able to test it..

.smap_failed:
  test byte [acquisition_status], byte 0x02
  jnz short .smap_acquired
  mov eax, [esp + 8]

.acquire_large_mem_size:
  mov eax, 0x0000E881		; GET MEM SIZE FOR >64M CONFIGURATIONS (32bit)
  call __realmode_portal
  jc short .large32_mem_failed
  cmp eax, 0x3C00
  jb short .large_mem_conversion

.large32_mem_failed:
  mov eax, 0x0000E801		; GET MEM SIZE FOR >64M CONFIGURATIONS (16bit)
  call __realmode_portal
  jc short .large16_mem_failed
  movzx eax, ax
  cmp eax, 0x3C00
  ja short .large16_mem_failed
  movzx eax, ax		; extended mem between 1MB and 16MB in 1KB block
  movzx ebx, bx		; extended mem above 16MB in 64KB block
  movzx ecx, cx		; configured mem between 1MB and 16MB in 1KB block
  movzx edx, dx		; configured mem above 16MB in 64KB block
.large_mem_conversion:
  add esp, byte 8
  inc edx
  shl ecx, 10		; 1KB block, 10bit shift on left
  shl edx, 16		; 64KB block, 16bit shift on left
  cmp ecx, 0x00F00000
  mov eax, 0x00100000
  jnz short .register_separately
  lea ecx, [byte edx + ecx]
  call _dealloc_range
  jmp short .no_large_mem
.register_separately:
  or ecx, ecx
  jz short .no_large_mem
  push edx
  call _dealloc_range
  pop ecx
  or ecx, ecx
  jz short .no_large_mem
  inc ecx
  mov eax, 0x01000000
  call _dealloc_range
.no_large_mem:
  jmp short .acquire_realmode_memory

.large16_mem_failed:
  mov ah, 0x8A			; GET BIG MEMORY SIZE
  call __realmode_portal
  jc short .big_memory_size_failed
  add esp, byte 8
dmej 0xFF880A39

.big_memory_size_failed:
  mov ah, 0x88			; GET EXTENDED MEMORY SIZE (286+)
  call __realmode_portal
  jc short .extended_mem_failed
  add esp, byte 8
  movzx ecx, ax
  shl ecx, 10
  mov eax, 0x00100000
  call _dealloc_range
  jmp short .acquire_realmode_memory

.extended_mem_failed:
  ; That starts making me wonder if your computer support any kind of memory
  ; size routine.. You know, it might be time for you to consider a new PC ;)
  dmej 0xFF880808

.acquire_realmode_memory:
  push byte 0
  push dword 0xFFFF0012
  call __realmode_portal
  add esp, byte 8
  movzx ecx, ax
  inc ecx
  shl ecx, 10
  %ifdef _KEEP_RM_IDT_
   mov eax, 0x00000500	; 000-400h IVT, 400h-500h Bios Data Area
   sub ecx, eax
  %else
   xor eax, eax
  %endif
  call _dealloc_range
  mov esi, [esp + 4]

  ; register memory used by the cells
  mov dword[mem.used_ram], dword 0
  movzx ecx, word [esi + hdr_core.cell_count]
  add esi, byte hdr_core_size
.registering_cell_memory:
  pushad
  mov eax, [esi]
  mov ecx, [esi + 4]
  or ecx, ecx
  jz short .bypass_registration
  call mem.alloc_forced_range
.bypass_registration:
  popad
  jc near remove_2_descriptors
  add esi, byte hdr_cell_size
  loop .registering_cell_memory
  jmp remove_2_descriptors

internal_failure:
  dmej 0xFF880004

reloading:
  dmej 0xFF880303


__realmode_portal equ 0x6000
align 4, db 0
portal_code_start:
incbin "portal.bin"
align 4, db 0
portal_code_end:

gdtr: dd 0,0
acquisition_status: dd 0


core_range:
.start: dd 0
.end: dd 0
_dealloc_range:
  pushad
  ; eax = base memory address
  ; ecx = size of the block
  lea ebx, [eax + ecx]
  cmp eax, dword [core_range.start]
  jb short .check_sb_ea
  cmp eax, dword [core_range.end]
  jae short .register_mem
  cmp ebx, dword [core_range.end]
  jbe short .quit
  mov eax, [core_range.end]
  sub ebx, eax
  mov ecx, ebx
  jmp short .register_mem
.check_sb_ea:
  cmp ebx, dword [core_range.start]
  jbe short .register_mem
  cmp ebx, dword [core_range.end]
  jbe short .cut_high_part_and_reg
  push eax
  mov eax, [core_range.end]
  sub ebx, eax
  mov ecx, ebx
  call mem.dealloc_forced_range
  pop eax
.cut_high_part_and_reg:
  mov ecx, [core_range.start]
  sub ecx, eax
.register_mem:
  call mem.dealloc_forced_range
.quit:
  popad
  retn


remove_2_descriptors:
  sub word [gdtr], byte 16
  lgdt [gdtr]

init_end:
  popad

%else ; _ASSUME_MEMORY_

pushad
mov eax, 0x500
mov ecx, 0xA0000-0x500
call mem.dealloc_forced_range
mov eax, 2 MB
mov ecx, (_ASSUME_MEMORY_) - (2 MB)
call mem.dealloc_forced_range
mov dword[mem.used_ram], dword 0
popad

%endif ; else _ASSUME_MEMORY_

retn
%endif






section .text


;; ___________
;;< mem.alloc >
;; -----------
;;         o   ^__^
;;          o  (oo)\_______
;;             (__)\       )\/\
;;                 ||----w |
;;                 ||     ||
;;-----------------------------------------------------------------------------
globalfunc mem.alloc
;>
;; This function allocate memory with some minimal guarantees:
;;
;;  * physical address of the allocated block equal to its linear address
;;  * at least 64bytes aligned, both in size and location
;;  * will not be swapped at any given time
;;
;; Parameters:
;;------------
;; ecx          amount of memory requested
;;
;; Returned values:
;;-----------------
;; cf = 0, successful
;;   eax = original amount of memory requested
;;   ecx = size of the memory block allocated
;;   edi = pointer to allocated memory block
;;
;; cf = 1, failed
;;   eax = error code
;;
;; note: unspecified registers are left unmodified
;<
;;-----------------------------------------------------------------------------
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE3			; Enable Tracing code  |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  mov eax, ecx				; set to original value requested
  pushad				; backup all registers
					;
					; 64 bytes align requested size
					;------------------------------
  add ecx, byte 0x3F			; +63 to size requested
  and ecx, byte -0x40			; mask lowest 6 bits of size requested
  mov eax, __ERROR_INVALID_PARAMETERS__	; set error code
  jz short .return_with_error		; if result is 0, return with error
					;
  mov [esp + 24], ecx			;
					; Search fmm for a matching node
					;-------------------------------
  mov edi, root.fmms			; set super root pointer
.start_sized_node_search:		;
  mov edx, null_tnode			; set null pointer
  mov esi, [edi]			; load root node
  mov ebx, edx				; set best matching node to null
					;
					; Check for end of branch
.find_sized_node:			;------------------------
  cmp esi, edx				; have we reached a null node?
  jz short .allocate_tnode		; yes, allocate best match identified
					;
					; Check for a match
					;------------------
  cmp ecx, [esi + tnode_size]		; compare req'd size with node size
  jz short .perfect_size_match		; in case of a perfect match
					;
					; Decide where to go based on the size
					;-------------------------------------
  sbb ebp, ebp				; calculate offset to next node pointer
  mov eax, esi				; prepare best match pointer in case
  mov esi, [ebp*4 + esi + 4]		; load next node
  jnb short .find_sized_node		; node was insufficient size, go above
  mov ebx, eax				; sufficient size found, mark as best
  jmp short .find_sized_node		; continue searching
					;
					; Verify that we check both node pools
.check_for_below_1mb_alloc:		;-------------------------------------
  mov ebx, root.fmmsl			; set pointer to alternate super root
  cmp edi, ebx				; was super root already pointing there?
  mov edi, ebx				; set it there just in case
  jnz short .start_sized_node_search	; if not, browse the nodes below 1MB
					;
					; Error identified, return with it
.return_with_error:			;---------------------------------
  mov [esp + 28], eax			; set error code in returned values
  popad					; restore all registers
  stc					; set error flag
					;
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE2			; Disable Tracing code |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  retn					; return to caller
					;
					; Search completed, check for a match
.allocate_tnode:			;------------------------------------
  cmp ebx, edx				; is best match = null?
  mov eax, __ERROR_INSUFFICIENT_MEMORY__; set error code in case
  jz short .check_for_below_1mb_alloc	; yes, see if another node pool exists
					;
  mov esi, ebx				;
					;
					; Verify if node has a equal node
.perfect_size_match:			;--------------------------------
  cmp [esi + tnode.equal], edx		;
  jz short .complex_tnode_unlink	;
					;
  mov eax, [esi + tnode.low]		;
  mov ebx, [esi + tnode.high]		;
  mov ebp, [esi + tnode.equal]		;
  mov edi, [esi + tnode.parent]		;
  mov [eax + tnode.parent], ebp		;
  mov [ebx + tnode.parent], ebp		;
  mov [edi], ebp			;
  mov [ebp + tnode.low], eax		;
  mov [ebp + tnode.high], eax		;
  mov [ebp + tnode.parent], edi		;
  mov [edx + tnode.parent], edx		;
					;
.common_tnode_unlink:			;
  sub ecx, [esi + tnode_size]		;
  jz short .unlink_from_fmm		;
  neg ecx				;
					;
  ;-------------------------------------;
  ; curren situation: node to allocate is unlinked from fmms/fmmsl, it is still
  ; linked in the fmm, which is alright, we have to update the size left in the
  ; node and relink it in the fmms/fmmsl.
  ;-------------------------------------;
					; Link node in fmms/fmmsl
					;------------------------
  mov eax, esi				; set eax as node pointer
  call .link_fmms			; link it
					;
					; Compute address of allocated mem block
					;---------------------------------------
  lea eax, [eax + ecx - bnode_size]	; add size after alloc to block addr
					;
					; Link node in umm
.register_in_umm:			;-----------------
  mov [esp], eax			; set computed address as returned value
  mov ecx, [esp + 24]			; reload allocated block size
  sub [mem.free_ram], ecx		; update memory stats
  call mem.alloc_forced_range		; link it
					;
					; Allocation and linking completed
					;---------------------------------
  popad					; restore all registers
  clc					; clear error flag
					;
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE2			; Disable Tracing code |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  retn					; return to caller
					;
					; Complex tnode unlinking
.complex_tnode_unlink:			;------------------------
					; assuming:
					; esi = pointer to node to unlink
					; edx = null node
					; edi = pointer to super root
					; ecx = block size requested
					;------------------------
  mov eax, [esi + tnode.low]		;
  mov ebx, [esi + tnode.high]		;
  mov ebp, [esi + tnode.parent]		;
  cmp ebx, edx				;
  jz short .no_high_tnode		;
					;
  cmp eax, edx				;
  jz short .no_low_tnode		;
					;
  push eax				;
.complex_search_tnode:			;
  mov edi, eax				;
  mov eax, [eax + tnode.high]		;
  cmp eax, edx				;
  jnz short .complex_search_tnode	;
					;
  add edi, byte tnode.high		;
  pop eax				;
  mov [edi], ebx			;
  mov [ebx + tnode.parent], edi		;
					;
  mov [ebp], eax			;
  mov [eax + tnode.parent], ebp		;
					;
  jmp short .common_tnode_unlink	;
					;
.no_high_tnode:				;
  mov [eax + tnode.parent], ebp		;
  mov [ebp], eax			;
  mov [edx + tnode.parent], edx		;
  jmp short .common_tnode_unlink	;
					;
.no_low_tnode:				;
  mov [ebx + tnode.parent], ebp		;
  mov [ebp], ebx			;
  mov [edx + tnode.parent], edx		;
  jmp short .common_tnode_unlink	;
					;
					; Link node in fmms/fmmsl
.link_fmms:				;------------------------
					; assuming:
					; eax = pointer to node to link
					; ecx = size of the memory block
					; edx = pointer to null node
					;------------------------
  pushad				; backup all registers
  jmp near mem.dealloc_forced_range.t_link_node
					;
					; Unlink node from fmm
.unlink_from_fmm:			;---------------------
  mov edi, root.fmm			; set super root pointer
  lea eax, [esi - bnode_size]		;
  mov esi, [edi]			; load root node
					;
.browse_fmm_nodes:			;
  cmp esi, edx				; is the node null?
  jz short .fmm_node_not_found		; yes, block couldn't be found
					;
  cmp eax, esi				; compare base addresses
  jz short .fmm_node_found		; match identified!
					;
  sbb ebp, ebp				; compute offset to next node
  mov esi, [ebp*4 + esi + 4]		; load pointer to next node
  jmp short .browse_fmm_nodes		; go process it
					;
					; Block indicated couldn't be found
.fmm_node_not_found:			;----------------------------------
  popad					; restore all registers
  stc					; set error flag
  mov eax, __ERROR_INTERNAL_FAILURE__	; set error code
  retn					; return to caller
					;
					; Node located
.fmm_node_found:			;-------------
  push eax				; backup base address
  mov eax, [esi + bnode.low]		; get lower node pointer
  mov ebx, [esi + bnode.high]		; get higher node pointer
  cmp eax, edx				; is there a low node?
  mov ebp, [esi + bnode.parent]		; get parent node pointer
  jz short .no_low_fmm_bnode		; no low node, proceed to quick unlink
					;
  cmp ebx, edx				; is there a high node?
  jz short .no_high_fmm_bnode		; no high node, proceed to quick unlink
					;
					; Unlink when both high and low present
					;--------------------------------------
  push eax				; backup low node base address
.fmm_complex_search:			;
  mov edi, eax				; remember current node address
  mov eax, [eax + bnode.high]		; load next node
  cmp eax, edx				; is this new node null?
  jnz short .fmm_complex_search		; no, continue searching null node
					;
  add edi, byte bnode.high		; compute offset to link point
  pop eax				; restore low node base address
  mov [edi], ebx			; link high node to highest low child
  mov [ebx + bnode.parent], edi		; set parent back to highest low child
					;
  mov [ebp], eax			; set ptr in orig parent to low node
  mov [eax + bnode.parent], ebp		; set ptr back to parent
					;
  jmp short .common_fmm_unlink		; common unlink tasks
					;
					; Quick unlink for low node
.no_high_fmm_bnode:			;--------------------------
  mov [eax + bnode.parent], ebp		; set low node parent's
  mov [ebp], eax			; set parent to point to low node
  mov [edx + bnode.parent], edx		; clean back null node in case low node
					;  was null
  jmp short .common_fmm_unlink		; common unlink tasks
					;
					; Quick unlink for high node
.no_low_fmm_bnode:			;---------------------------
  mov [ebx + bnode.parent], ebp		; set high node parent's
  mov [ebp], ebx			; set parent to point to high node
  mov [edx + bnode.parent], edx		;
					;
					; Go register block as allocated
.common_fmm_unlink:			;---------------------------------
  pop eax				; restore block base address
  jmp near .register_in_umm		;
;;-----------------------------------------------------------------------------


;; ________________________
;;< mem.alloc_forced_range >
;; ------------------------
;;         o   ^__^
;;          o  (oo)\_______
;;             (__)\       )\/\
;;                 ||----w |
;;                 ||     ||
;;-----------------------------------------------------------------------------
globalfunc mem.alloc_forced_range
;>
;; This function is used mostly by the memory manager initializer. It is used
;; to mark (yet unmanaged physical memory) as allocated. After the memory
;; block is allocated, it will then be managed by the memory manager the same
;; way as any other allocated memory block. Standard mem.dealloc function can
;; be used to free it later.
;;
;; parameters:
;;------------
;; eax = base address of the block to mark as allocated
;; ecx = size of the block to mark as allocated
;;
;; returns:
;;---------
;; errors and registers as usual
;<
;;-----------------------------------------------------------------------------
  add [mem.used_ram], ecx		; update memory statistics
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE3			; Enable Tracing code  |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  pushad				; backup all registers
					;
					; Allocate UMM entry
					;-------------------
  mov edi, root.umm			; set pointer to super root
  mov ebx, [edi + 4]			; load free umm root pointer
  mov edx, null_lnode			; set null pointer
  mov esi, [ebx + lnode.next]		; get next free node pointer
  cmp ebx, edx				; check if acquired umm entry is null
  mov [edi + 4], esi			; set next entry as root pointer
  mov [esi + lnode.previous], edx	; set previous pointer of next node as
  					;  null
  jz short .allocate_umm_table		; if allocated umm entry is nul...
					;
.umm_entry_allocated:			;
  					; Fill UMM info
					;--------------
  mov [ebx + bnode.low], edx		; set lower node pointer as null
  mov [ebx + bnode.high], edx		; set higher node pointer as null
  mov [ebx + umm.base_address], eax	; set base address as passed
  mov [ebx + umm.size], ecx		; set block size as passed
					;
  					; Link UMM entry in UMM binary-tree
					;----------------------------------
  mov esi, [edi]			; load root node pointer
  mov ecx, edi				;
					;
.browse_bnodes:				;
  cmp esi, edx				; check if node we are browsing is null
  jz .link_point_identified		; if end of chain found, go and link
					;
					; Browse tree to find place to link
					;----------------------------------
  cmp eax, [esi + umm.base_address]	; compare base addresses
  jz short .node_already_present	; node already in the tree!
					;
  sbb ebp, ebp				; compute offset to higher/lower ptr
  lea edi, [ebp*4 + esi + 4]		; get pointer to higher/lower node ptr
  mov esi, [edi]			; load higher/lower node pointer
  jmp short .browse_bnodes		; continue to browse
					;
.node_already_present:			;
  popad					; restore all registers
  mov eax, __ERROR_INVALID_PARAMETERS__	; set error code
  stc					; set error flag
  					;
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE2			; Disable Tracing code |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  retn					; return to caller
					;
					; Link node
.link_point_identified:			;----------
  mov [edi], ebx			; link node to parent
  mov [ebx + bnode.parent], edi		; set parent pointer
					;
					; Return to caller successfully
.recursive:				;------------------------------
  popad					; restore all registers
  clc					; clear error flag
					;
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE2			; Disable Tracing code |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  retn					; return to caller
					;
					; Allocate extra umm table
.allocate_umm_table:			;-------------------------
					; We do a little magic here, we use a
					; redirector to deal with the recursive
					; memory allocation.
					;
					; Jump to non/ recursive handler
					;-------------------------------
  mov esi, recursive_alloc		; set pointer to jump indicator
  jmp [esi]				; jump to it
					;
					; Allocate memory for extra umm table
.non_recursive:				;------------------------------------
  push eax				; backup base address
  push ecx				; backup block size
  mov dword [esi], .recursive		; set jump point to recursive
  mov ecx, umm_table_size		; size of memory block requested
  call mem.alloc			; allocate memory
  mov dword [esi], .non_recursive	;
					;
  ;--------------------------------------
  ; Here's a little bit of clarification, at this point, we have:
  ; eax = memory block size requested (umm_table_size)
  ; ecx = block size allocated, most likely = eax
  ; edx = null_lnode/bnode/tnode
  ; ebx = null_lnode/bnode/tnode
  ; esi = recursive_alloc
  ; edi = allocated memory block
  ; ebp = unknown
  ;
  ; We still got the following left to do:
  ; - link newly allocated umm table
  ; - format the umm table entries and link them up
  ; - allocate one umm entry
  ; - return with the allocated umm entry to the start of this routine
  ;--------------------------------------
					; Link UMM table
					;---------------
  mov eax, [root.umm_table]		; current root.umm_table head table
  mov [edi + lnode.previous], edx	; mark new node as root node
  mov [edi + lnode.next], eax		; set original head as next node
  mov [eax + lnode.previous], edi	; link back original head to our table
  mov [edx + lnode.previous], edx	; in case original head was null
					;
					; Format UMM table and entries
					;-----------------------------
  mov ecx, umm_entries_per_table - 1	; set number of entries to process
  mov ebx, umm_size			; number of bytes per entry
  add edi, byte umm_table.entries	; compute pointer to first entry
  mov eax, edx				; set starting previous node as null
  mov [root.umm_free], edi		; set root pointer to first entry
					;
.linking_umm_entries:			;
  lea esi, [edi + ebx]			; compute pointer to next entry
  mov [edi + lnode.previous], eax	; set pointer to previous entry
  mov [edi + lnode.next], esi		; set pointer to next entry
  dec ecx				; decrement entry count
  mov eax, edi				; move previous pointer to current node
  mov edi, esi				; move current node to next node
  jnz short .linking_umm_entries	; if any entry left, link them
					;
  mov [eax + lnode.next], edx		; terminate linked list with null
  mov ebx, edi				; select last unlinked entry
  pop ecx				; restore block size
  pop eax				; restore base address
  jmp near .umm_entry_allocated		;
;;-----------------------------------------------------------------------------


;; _________________________
;;< mem.alloc_20bit_address >
;; -------------------------
;;         o   ^__^
;;          o  (oo)\_______
;;             (__)\       )\/\
;;                 ||----w |
;;                 ||     ||
;;-----------------------------------------------------------------------------
globalfunc mem.alloc_20bit_address
;>
;;  This function allows allocation based on the same restriction as mem.alloc
;;  but also add a restriction:
;;
;;  *  allocated memory must be in a 20bit addressing range
;;
;;  This extra restriction garantee that memory blocks allocated with this
;;  function will be located in the realmode addressing range, which can also
;;  be used as DMA transfer buffers
;;
;; parameters:
;;------------
;; ecx          amount of memory requested
;;
;; returns:
;;---------
;; cf = 0, successful
;;   eax = original amount of memory requested
;;   ecx = size of memory block allocated
;;   edi = pointer to memory block allocated
;;
;; cf = 1, failed
;;   eax = error code
;<
;;-----------------------------------------------------------------------------
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE3			; Enable Tracing code  |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  mov eax, ecx				; set to original value requested
  pushad				; backup all registers
					;
					; 64 bytes align requested size
					;------------------------------
  add ecx, byte 0x3F			; +63 to size requested
  and ecx, byte -0x40			; mask lowest 6 bits of size requested
  mov eax, __ERROR_INVALID_PARAMETERS__	; set error code
  jz near mem.alloc.return_with_error	; if result is 0, return with error
					;
  mov [esp + 24], ecx			;
					; Search fmm for a matching node
					;-------------------------------
  mov edi, root.fmmsl			; set super root pointer
  jmp near mem.alloc.start_sized_node_search
;;-----------------------------------------------------------------------------


;; _____________
;;< mem.dealloc >
;; -------------
;;          o   ^__^
;;           o  (oo)\_______
;;              (__)\       )\/\
;;                  ||----w |
;;                  ||     ||
;;-----------------------------------------------------------------------------
globalfunc mem.dealloc
clc
retn
;>
;; This function allows one to deallocate a block of memory allocated with
;; any of the following functions:
;;
;;    * mem.alloc
;;    * mem.alloc_20bit_address
;;    * mem.alloc_forced_range
;;    * mem.alloc_swappable
;;
;; The block of memory freed using this function will become available in the
;; memry manager database of available memory blocks.
;;		
;; parameters:
;;------------
;; eax = base address of memory block to free
;;
;; returns:
;;---------
;; errors and registers as usual
;<
;;-----------------------------------------------------------------------------
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE3			; Enable Tracing code  |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  pushad				; backup all registers
					;
					; Search entry in UMM
					;--------------------
  mov edi, root.umm			; set super root pointer
  mov edx, null_lnode			; set null node pointer
  mov esi, [edi]			; load root node
					;
.browse_nodes:				;
  cmp esi, edx				; is the node null?
  jz short .node_not_found		; yes, block couldn't be found
					;
  cmp eax, [esi + umm.base_address]	; compare base addresses
  jz short .node_found			; match identified!
					;
  sbb ebp, ebp				; compute offset to next node
  mov esi, [ebp*4 + esi + 4]		; load pointer to next node
  jmp short .browse_nodes		; go process it
					;
					; Block indicated couldn't be found
.node_not_found:			;----------------------------------
  popad					; restore all registers
  stc					; set error flag
  mov eax, __ERROR_INVALID_PARAMETERS__	; set error code
  retn					; return to caller
					;
					; Node located
.node_found:				;-------------
  push eax				; backup base address
  mov eax, [esi + bnode.low]		; get lower node pointer
  mov ebx, [esi + bnode.high]		; get higher node pointer
  cmp eax, edx				; is there a low node?
  mov ebp, [esi + bnode.parent]		; get parent node pointer
  jz short .no_low_bnode		; no low node, proceed to quick unlink
					;
  cmp ebx, edx				; is there a high node?
  jz short .no_high_bnode		; no high node, proceed to quick unlink
					;
					; Unlink when both high and low present
					;--------------------------------------
  push eax				; backup low node base address
.complex_search:			;
  mov edi, eax				; remember current node address
  mov eax, [eax + bnode.high]		; load next node
  cmp eax, edx				; is this new node null?
  jnz short .complex_search		; no, continue searching null node
					;
  add edi, byte bnode.high		; compute offset to link point
  pop eax				; restore low node base address
  mov [edi], ebx			; link high node to highest low child
  mov [ebx + bnode.parent], edi		; set parent back to highest low child
					;
  mov [ebp], eax			; set ptr in orig parent to low node
  mov [eax + bnode.parent], ebp		; set ptr back to parent
					;
  jmp short .common_unlink		; common unlink tasks
					;
					; Quick unlink for low node
.no_high_bnode:				;--------------------------
  mov [eax + bnode.parent], ebp		; set low node parent's
  mov [ebp], eax			; set parent to point to low node
  mov [edx + bnode.parent], edx		; clean back null node in case low node
					;  was null
  jmp short .common_unlink		; common unlink tasks
					;
					; Quick unlink for high node
.no_low_bnode:				;---------------------------
  mov [ebx + bnode.parent], ebp		; set high node parent's
  mov [ebp], ebx			; set parent to point to high node
  mov [edx + bnode.parent], edx		;
					;
					; Deallocate memory (mark as free)
.common_unlink:				;---------------------------------
  pop eax				; restore original base address
  mov ecx, [esi + umm.size]		; acquire block size
  sub [mem.used_ram], ecx		; update memory statistics
  call mem.dealloc_forced_range		; deallocate associated memory
					;
					; Return to caller
					;-----------------
  popad					; restore all registers
  clc					; set error flag
  retn					; return to caller
;;-----------------------------------------------------------------------------




;; __________________________
;;< mem.dealloc_forced_range >
;; --------------------------
;;          o   ^__^
;;           o  (oo)\_______
;;              (__)\       )\/\
;;                  ||----w |
;;                  ||     ||
;;-----------------------------------------------------------------------------
globalfunc mem.dealloc_forced_range
;>
;; This function is used mostly by the memory manager initializer. It is used
;; to mark (as yet unmanaged physical memory) as available. The block of
;; memory thus marked will then be available for the various memory allocation
;; functions to use.
;;
;; Both parameters and returned values are identical to function
;; mem.alloc_forced_range
;;
;; Warning:
;;
;;   calling this function with a block of memory already marked as free might
;;   make any/all other memory block(s) unavailable until a hard reset
;;
;; parameters:
;;------------
;; eax          base address of memory block to free
;; ecx          size of the block to free
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  add [mem.free_ram], ecx		; update memory stats
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE3			; Enable Tracing code  |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  pushad				; backup all registers
					;
					; 64-bytes align base address
					;----------------------------
  mov edx, 0xFFFFFFC0			; mask for all but lowest 6 bits
  lea ebx, [byte eax + 63]		; add 63 to base address
  and ebx, edx				; mask off the lowest 6 bits
  sub ebx, eax				; compute any difference
  sub ecx, ebx				; re-adjust block size for difference
  jbe short .zero_size_block		; make sure we don't get negative size
					;
					; 64-bytes align block size
  and ecx, edx				;--------------------------
  mov edi, root.fmm			; set super root pointer
  mov edx, null_bnode			; set our null pointer
  jz short .zero_size_block		; if final size is 0, discard block
					;
					; Initialize FMM node
					;--------------------
  mov [eax + bnode.low], edx		; set lower pointer as null
  mov [eax + bnode.high], edx		; set higher pointer as null
					;
					; Link node in FMM binary-tree
					;-----------------------------
  mov esi, [edi]			; load root node pointer
  mov ebx, edi				;
					;
.browse_bnodes:				;
  cmp esi, edx				; check if it is null
  jz short .b_link_point_identified	; if end of chain found, go and link
					;
					; Browse tree to find place to link
					;------------------------------------
  cmp eax, esi				; compare base addresses
  jz short .node_already_present	; node already in the tree
					;
  sbb ebp, ebp				; compute offset to higher/lower ptr
  lea edi, [ebp*4 + esi + 4]		; get pointer to higher/lower node ptr
  mov esi, [edi]			; load higher/lower node pointer
  jmp short .browse_bnodes		; continue to browse
					;
					; Zero sized or already present block
.zero_size_block:			;------------------------------------
.node_already_present:			;
  popad					; restore all registers
  mov eax, __ERROR_INVALID_PARAMETERS__	; error code
  stc					; set error flag
					;
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE2			; Disable Tracing code |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  retn					; return to caller
					;
					; Link node
.b_link_point_identified:		;----------
  mov [edi], eax			; link node to parent
  mov [eax + bnode.parent], edi		; set parent pointer
					;
					; Initialize FMM-Size node
					;-------------------------
  add eax, bnode_size			; compute address to tnode struc
.t_link_node:				;
  mov edi, root.fmms			; set super root pointer
  cmp eax, 1 MB				; check if we have the right super root
  mov [eax + tnode.low], edx		; set lower pointer as null
  sbb ebp, ebp				; compute super root adjustment
  mov [eax + tnode.high], edx		; set higher pointer as null
  mov [eax + tnode.equal], edx		; set equal pointer as null
  lea edi, [ebp*4 + edi]		; calculate final super root pointer
  mov [eax + tnode_size], ecx		; set block size
					;
					; Link node in FMM-Size tinary-tree
					;----------------------------------
  					;
  mov esi, [edi]			; load root node pointer
  mov ebx, edi				; backup pointer to super root
					;
.browse_tnodes:				;
  cmp esi, edx				; check if node is null
  jz short .t_link_point_identified	; if end of chain found, go and link
					;
					; Browse tree to find place to link
					;----------------------------------
  cmp ecx, [esi + tnode_size]		; compare block sizes
  jz short .equal_size_node		;
					;
  sbb ebp, ebp				; compute offset to bigger/smaller ptr
  lea edi, [ebp*4 + esi + 4]		; get pointer to bigger/smaller node ptr
  mov esi, [edi]			; load bigger/smaller node pointer
  jmp short .browse_tnodes		; continue to browse
					;
					; Equal block size
.equal_size_node:			;-----------------
  lea edi, [esi + tnode.equal]		; get pointer to equal node pointer
  mov ebx, [edi]			; get current equal node pointer
  mov [eax + tnode.parent], edi		; set parent pointer in new node
  mov [edi], eax			; set equal node pointer to new node
  add eax, byte tnode.equal		; get pointer to new equal node pointer
  mov [edx + tnode.equal], edx		; restore destroyed equal node
  mov [eax], ebx			; set original current equal node ptr
  mov [ebx + tnode.parent], eax		; set back pointer to new node
  mov [edx + tnode.parent], edx		; restore destroyed parent
					;
					; Linking successful, return
					;---------------------------
  popad					; restore all registers
					;
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE2			; Disable Tracing code |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  clc					; clear error flag
  retn					; return to caller
					;
					; Link node
.t_link_point_identified:		;----------
  mov [edi], eax			; make parent pointer point to new node
  mov [eax + tnode.parent], edi		; point back to parent node
					;
					; Link successful, return
					;------------------------
  popad					; restore all registers
					;
%ifdef _ABSOLUTE_DEBUGGING_		;-----------------------
  pushad				; backup all registers |
  mov dx, 0x8A00			; I/O Debug address    |
  mov ax, 0x8AE2			; Disable Tracing code |
  out dx, ax				; send it              |
  popad					; restore all registers|
%endif					;-----------------------
					;
  clc					; clear error flag
  retn					; return to caller
;------------------------------------------------------------------------------



globalfunc mem.realloc
;---------------------
;>
;; Resizes a block of memory.
;;
;; Important note:
;;
;;    If the block of memory cannot be simply resized, another block of memory
;;    of the requested size will be allocated, the data within the block moved
;;    and the original block of memory will be freed.
;;
;;    If any pointer needs to be recalculated within the moved data block, it
;;    is the responsability of the caller to modify them accordingly.
;;
;; parameters:
;; -----------
;; EAX = base address of block to resize
;; ECX = new size
;;
;; returned values:
;; ----------------
;; EAX = size of block requested (ecx from call)
;; ECX = actuall size of memory allocated
;; EDI = new memory location
;; registers and errors as usual
;<
;------------------------------------------------------------------------------
  push esi				; backup non-destroyed esi
  push ecx				; backup requested block size
  push eax				; backup original memory location
					;
					; Allocate new memory block
					;--------------------------
  push eax				; original mem location for move
  call mem.alloc			; allocate new memory block
  jc .error				; in case of any error
  pop esi				; get original mem location
  push ecx				; backup allocated new block size
  push edi				; backup new mem block location
					;
					; Move data from original to new block
					;-------------------------------------
  shr ecx, 2				; moving one dword at a time
  rep movsd				; move the data
					;
					; Prepare some returned values
					;-----------------------------
  pop edi				; restore new block location
  pop ecx				; restore allocated block size
  pop eax				; restore original location
					;
					; Deallocate original memory block
					;---------------------------------
  call mem.dealloc			; deallocate it
					;
					; Finish preparing return values
					;-------------------------------
  pop eax				; restore requested block size
  pop esi				; restore non-destroyed esi
					;
					; Return to caller
					;-----------------
  retn					; return!
					;
					; Could not allocate new mem block
					;---------------------------------
.error:					;
  add esp, byte 12			;
  pop esi				;
  mov eax, __ERROR_INSUFFICIENT_MEMORY__; set error code
  stc					; set error flag
  retn					; return to caller
;------------------------------------------------------------------------------



section .data

root:
;----
.fmm:
;;-----------------------------------------------------------------------------
;; Root of the Free Memory Map (binary-tree), sorted by base address
;;-----------------------------------------------------------------------------
;;
dd null_bnode

;------
.fmmsl:
;;-----------------------------------------------------------------------------
;; Root of the Free Memory Map (trinary-tree), sorted by block size below 1MB
;;
;; Note: it is of major importance that fmmsl only takes a dword, and that the
;;       next dword defined be the root.fmms
;;-----------------------------------------------------------------------------
dd null_tnode

;-----
.fmms:
;;-----------------------------------------------------------------------------
;; Root of the Free Memory Map (trinary-tree), sorted by block size, above 1MB
;;
;; Note: it is of major importance that fmms is located exactly 1 dword away
;;       after root.fmmsl
;;-----------------------------------------------------------------------------
dd null_tnode

;----
.umm:
;;-----------------------------------------------------------------------------
;; Root of the Used Memory Map (binary-tree), sorted by base address
;;
;; Note: it is of major importance that .umm only takes a dword, and that the
;;       next dword defined be the root.umm_free
;;-----------------------------------------------------------------------------
dd null_bnode

;---------
.umm_free:
;;-----------------------------------------------------------------------------
;; Root of Linked List of free UMM entries
;;
;; Note: it is of major importance that .umm_free is located exactly 1 dword
;;       away after root.umm
;;-----------------------------------------------------------------------------
dd null_lnode

;----------
.umm_table:
;;-----------------------------------------------------------------------------
;; Root of Linked List of allocated Table of UMM entries
;;-----------------------------------------------------------------------------
dd null_lnode

;---------------
recursive_alloc:
;;-----------------------------------------------------------------------------
;; Redirector used in mem.alloc_forced_area when allocating umm tables
;;-----------------------------------------------------------------------------
dd mem.alloc_forced_range.non_recursive

;----------
null_tnode:
null_bnode:
null_lnode:
;;-----------------------------------------------------------------------------
;; We allow ourself to use the null_tnode struc to hold the bnode and lnode
;; too since they can all fit perfectly within tnode
;;-----------------------------------------------------------------------------
istruc tnode
at tnode.low, dd null_tnode
at tnode.high, dd null_tnode
at tnode.equal, dd null_tnode
at tnode.parent, dd null_tnode
iend





;                 ------------------------------------------
;                 Globally available memory usage statistics
;                 ------------------------------------------
;

globalfunc mem.free_ram
;>
;; 32bits (dword) variable, directly accessible, indicating how many bytes of
;; free physical memory are still available.
;;
;; Use as read-only. Writing over this variable might have unpredictable
;; effects.
;<
dd 0

globalfunc mem.used_ram
;>
;; 32bits (dword) variable, directly accessible, indicating the number of
;; blocks the mem.used_ram is split up into. This could be used together with
;; mem.used_ram to compute the average requested memory block size.
;;
;; Use as read-only. Writing over this variable might have unpredictable
;; effects.
;<
dd 0

; note: lets make both variable point to the same location since they are
; and will stay 0
;
globalfunc mem.used_swap
;>
;; 32bits (dword) variable, directly accessible, indicating how many bytes of
;; the secondary storage medium is currently used to hold swapped memory.
;;
;; Use as read-only. Writing over this variable might have unpredictable
;; effects.
;<
globalfunc mem.free_swap
;>
;; 32bits (dword) variable, directly accessible, indicating how many bytes of
;; free secondary storage are still available.
;;
;; Use as read-only. Writing over this variable might have unpredictable
;; effects.
;<
dd 0
