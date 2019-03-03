;; $Header: /cvsroot/uuu/dimension/cell/fs/ext2/ext2.asm,v 1.3 2002/01/23 01:45:25 jmony Exp $
;;
;; Second Extended File System
;; by EKS - Dave Poirier
;;
;; TODO:
;; - save modified inode back in the itb before discarding them, in case they
;;   were modified
;; - save modified itb back on disk before discarding them
;; - complete the no cached itb code
;; - complete the no cached inodes code
;; - complete the no cached blocks code
;; - complete write access to files (which include block/inodes allocations)
;; - write fsck algo
;; - once proper strlen (normal 0 termination) is available, use it instead of
;;   our own defined strlen
;;-----------------------------------------------------------------------------

section .text

;;--------------------
;; MONITORING CONTROLS
;;-----------------------------------------------------------------------------
;%define _EXT2_MONITORING_
;%define _MONITOR_INODE_LOCKS_
;;-----------------------------------------------------------------------------






;       .---.
;      /     \
;      | - - |   < section: .c_info >
;     (| ' ' |)
;      | (_) |   o
;      `//=\\' o
;      (((()))
;       )))((
;       (())))
;        ))((
;        (()
;    jgs  ))
;         (
section .c_info

;;--------------------
;; VERSION INFORMATION
;;-----------------------------------------------------------------------------
  db 0,2,1,"c"
  dd str_title
  dd str_author
  dd str_copyrights

str_title: db "Ext2 File System",0
str_author: db "eks",0
str_copyrights: db "BSD Licensed",0
;;-----------------------------------------------------------------------------



;       .---.
;      /     \
;      | - - |   < section: .text >
;     (| ' ' |)
;      | (_) |   o
;      `//=\\' o
;      (((()))
;       )))((
;       (())))
;        ))((
;        (()
;    jgs  ))
;         (
section .text

;;------------------------------
;; CACHING CONTROLS - Be careful
;;-----------------------------------------------------------------------------
;;
;; Maximum number of entry allowable in cache, minimum is 2
%define PERFORMANCE_INODES_CACHED	5
;;
;; Maximum number of blocks allowable in cache, minimum is 1
%define PERFORMANCE_BLOCKS_CACHED	1
;;
;; Maximum number of inode table blocks allowable in cache, minimum is 1
%define PERFORMANCE_ITB_CACHED		1
;;-----------------------------------------------------------------------------

;;-----------------------------------------------
;; PARANOIA CONTROLS - optional additional checks
;;-----------------------------------------------------------------------------
;;
;; Make sure we don't use null pointers, that we are accessing the right type
;; of data with the right pointers, etc.
%define _PARANOIA_SELF_
;;
;; Do not trust blindly Ext2 signature, perform checks to prevent cpu exception
;; on data until mount operation is completed.
%define _PARANOIA_MOUNT_
;;-----------------------------------------------------------------------------

;;-----------------------------
;; EXTENDED ERROR CODES SUPPORT
;;-----------------------------------------------------------------------------
%define _EXTENDED_ERROR_CODE_
	%define _EXT_E_OPEN_DEV_FAILED		1
	%define _EXT_E_SB_BUFFER_ALLOC		2
        %define _EXT_E_READ_DEV_FAILED_SB	3
	%define _EXT_E_INVALID_SB_MAGIC		4
        %define _EXT_E_FRAG_SIZE_OVERFLOW	5
        %define _EXT_E_FRAG_SIZE_UNDERFLOW	6
        %define _EXT_E_BLOCK_SIZE_OVERFLOW	7
	%define _EXT_E_FRAG_LARGER_THAN_BLOCK	8
	%define _EXT_E_INODES_PER_BLOCK		9
        %define _EXT_E_INODES_PER_GROUP		10
        %define _EXT_E_GDB_BUFFER_ALLOC		11
        %define _EXT_E_GDB_READ_FAILED		12
        %define _EXT_E_ITB_ALLOC		13
	%define _EXT_E_INVALID_FILENAME		14
        %define _EXT_E_DIR_ENTRY_NOT_FOUND	15
        %define _EXT_E_TIND_LIMIT_EXCEEDED	16
	%define _EXT_E_BLOCK_READ_FAILED	17
	%define _EXT_E_BLOCK_ALLOC		18
;;-----------------------------------------------------------------------------



;;-------------------------------
;; INTERNAL STRUCTURES DEFINITION
;;-----------------------------------------------------------------------------
	struc cached_itb	;
.first_inode	resd 1		; first inode described in this itb
.buffer_ptr	resd 1		; pointer to inode table block buffer
.last_access	resd 1		; last time this block was accessed
.locks		resd 1		; locks count for this particular itb
	endstruc		;
				;
	struc cached_block	;
.block_number	resd 1		; block id
.buffer_ptr	resd 1		; pointer to block buffer
.last_access	resd 1		; last time this block was accessed
.locks		resd 1		; locks count for this particular block
	endstruc		;
				;
	struc cached_inode	;
.inode_number	resd 1		; inode id
.buffer_ptr	resd 1		; pointer to inode buffer
.last_access	resd 1		; last time this inode was accessed
.locks		resd 1		; locks count for this particular inode
	endstruc		;
				;
	struc ext2_file_descriptor
.global		resb file_descriptor_size
.inode		resb ext2_inode_size
.inode_number	resd 1		;
.current_offset	resd 1		;
.access_rights	resd 1		;
.prev_open_file	resd 1		;
.next_open_file	resd 1		;
	endstruc		;
;;-----------------------------------------------------------------------------



;;------------------
;; MACRO DEFINITIONS
;;-----------------------------------------------------------------------------
%macro ldb 1.nolist			;
__%{1} equ $-exported_fs_data_start	;
.%{1}: db 0				;
%endmacro				;
					;
%macro ldw 1.nolist			;
__%{1} equ $-exported_fs_data_start	;
.%{1}: dw 0				;
%endmacro				;
					;
%macro ldd 1.nolist			;
__%{1} equ $-exported_fs_data_start	;
.%{1}: dd 0				;
%endmacro				;
					;
%macro ldd 2.nolist			;
__%{1} equ $-exported_fs_data_start	;
.%{1}: times %{2} dd 0			;
%endmacro				;
					;
%macro ldd 3.nolist			;
__%{1} equ $-exported_fs_data_start	;
.%{1}: times %{2} dd %{3}		;
%endmacro				;
;;-----------------------------------------------------------------------------


;;----------------------------------
;; _DEBUG_MOVSD_ and "mem_mov" macro
;;
;; Allows to monitor block of memory relocations/copies.  Information displayed
;; is in the following format:
;;
;; 10012002		code to identify memory block reloc/copy
;; XXXXXXXX		source address
;; YYYYYYYY		destination address
;; ZZZZZZZZ		amount of dword to move
;; ident		string identifying the action done
;;
;;-----------------------------------------------------------------------------
;; Uncomment the next line to enable
;%define _DEBUG_MOVSD_
;;--------------------
%macro mem_mov 1.nolist
 %ifdef _DEBUG_MOVSD_
[section .data]
%%str: db %{1},0
__SECT__
   pushad
   mov edx, edi
   mov edi, 0xB8140
   externfunc debug.diable.dword_out
   mov edx, esi
   mov edi, 0xB80A0
   externfunc debug.diable.dword_out
   mov edx, 0x10012002
   mov edi, 0xB8000
   externfunc debug.diable.dword_out
   mov esi, %%str
   mov edi, 0xB81E0+0xA0
%%display_str:
   lodsb
   stosb
   inc edi
   or al, al
   jnz short %%display_str
   lea edx, [ecx*4]
   mov edi, 0xB81E0
   externfunc debug.diable.dword_out_wait
   mov edi, 0xB8000
   mov eax, 0x17201720
   mov ecx, 1000
   rep stosd
   popad
 %endif
   rep movsd
%endmacro
   
%macro mem_movb 1.nolist
 %ifdef _DEBUG_MOVSD_
[section .data]
%%str: db %{1},0
__SECT__
   pushad
   mov edx, edi
   mov edi, 0xB8140
   externfunc debug.diable.dword_out
   mov edx, esi
   mov edi, 0xB80A0
   externfunc debug.diable.dword_out
   mov edx, 0x10012002
   mov edi, 0xB8000
   externfunc debug.diable.dword_out
   mov esi, %%str
   mov edi, 0xB81E0+0xA0
%%display_str:
   lodsb
   stosb
   inc edi
   or al, al
   jnz short %%display_str
   mov edx, ecx
   mov edi, 0xB81E0
   externfunc debug.diable.dword_out_wait
   mov edi, 0xB8000
   mov eax, 0x17201720
   mov ecx, 1000
   rep stosd
   popad
 %endif
   rep movsb
%endmacro
;;-----------------------------------------------------------------------------   


;;----------------------------------
;; _DEBUG_ALLOCS_ and "malloc" macro
;;
;; Allows precise memory allocation tracing, the following information is
;; displayed:
;;
;; 000A110C		code to indentify memory allocation
;; XXXXXXXX		amount of memory requested
;; YYYYYYYY		location of allocated memory area
;; ZZZZZZZZ		amount of memory allocated
;; ident		unique function call identifier, allow to find from
;;                      where this mem call was performed.
;;
;; to continue execution, press enter.  Note the video text mode memory will
;; be cleared to gray chars on blue background
;;
;;-----------------------------------------------------------------------------
;; to use this debugging facility, uncomment the next line
;%define _DEBUG_ALLOCS_
;;---------------------
%macro malloc 1.nolist
 %ifndef _DEBUG_ALLOCS_
  externfunc mem.alloc
 %else
[section .data]
%%str: db %{1},0
__SECT__
  pushad
  mov esi, %%str
  mov edi, 0xB81E0+0xA0
%%display_str:
  lodsb
  stosb
  inc edi
  or al, al
  jnz short %%display_str
  mov edi, 0xB8000
  mov edx, 0xA110C
  externfunc debug.diable.dword_out
  add edi, 0xA0
  mov edx, ecx
  externfunc debug.diable.dword_out
  popad
  externfunc mem.alloc
  pushfd
  pushad
  mov edx, edi
  mov edi, 0xB8140
  externfunc debug.diable.dword_out
  mov edx, ecx
  mov edi, 0xB81E0
  externfunc debug.diable.dword_out_wait
  mov edi, 0xB8000
  mov eax, 0x17201720
  mov ecx, 1000
  repz stosd
  popad
  popfd
 %endif
%endmacro
;;-----------------------------------------------------------------------------




;=----------------------------------------------------------------------------=
_mount:
;=----------------------------------------------------------------------------=
;; This function is called whenever the file system is mounted somewhere
;;
;; parameters:
;;------------
;; ESI = pointer to null-terminated string of what we are mounting under
;; EAX = device to use for storage, i.e. "ram0"

  push eax
  push esi				; save pointer to mountpoint

  mov esi, eax				; load pointer to device to use
  externfunc vfs.open			; open device
  jnc short .device_opened

    %ifdef _EXTENDED_ERROR_CODE_
     mov [ext2fs.extended_error_code], dword _EXT_E_OPEN_DEV_FAILED
    %endif

  pop esi
  pop eax
  stc
  retn

.device_opened:
  mov [device_file_handle], ebx		; save it

  ;=- allocate buffer
  mov ecx, ext2_super_block_size
  push ebx
  malloc "ext2_super_block"		; allocate it
  pop ebx
  jnc short .buffer_allocated

    %ifdef _EXTENDED_ERROR_CODE_
      mov [ext2fs.extended_error_code], dword _EXT_E_SB_BUFFER_ALLOC
    %endif

  ; cannot allocate buffer but the device is open, so first close the device
  ; and then return with an error code.
  mov ebp, [ebx]
  call [ebp + file_op_table.close]
  mov eax, __ERROR_INSUFFICIENT_MEMORY__
  stc
  retn 8

.buffer_allocated:
  push edi				; save pointer to buffer

    ;=- Read device superblock
    mov eax, 2				; Superblock is always @ 1024 bytes
    xor edx, edx
    mov ecx, (ext2_super_block_size / 512)
    mov ebp, [ebx]
    mov [disk_op_table], ebp
    call [ebp + file_op_table.raw_read]
      %ifdef _EXTENDED_ERROR_CODE_
        mov [ext2fs.extended_error_code], dword _EXT_E_READ_DEV_FAILED_SB
      %endif
    jc short .mount_failure

    ; Check superblock magic signature
    movzx eax, word [edi + ext2_super_block.s_magic]
    cmp eax, EXT2_SUPER_MAGIC
    mov eax, __ERROR_INVALID_FILESYSTEM__
      %ifdef _EXTENDED_ERROR_CODE_
        mov [ext2fs.extended_error_code], dword _EXT_E_INVALID_SB_MAGIC
      %endif
    jnz short .mount_failure

    ; Check file system state
    movzx eax, word [edi + ext2_super_block.s_state]
    cmp eax, byte EXT2_VALID_FS
    jz short .cleanly_unmounted

    call _fsck
    jc short .mount_failure

.cleanly_unmounted:
    mov word [edi + ext2_super_block.s_state], word EXT2_ERROR_FS
    mov [super_block.s_mount_state], al

;TODO: once _fsck is completed, re-enable check for mount count
;    movzx eax, word [edi + ext2_super_block.s_mnt_count]
;    movzx ebx, word [edi + ext2_super_block.s_max_mnt_count]
;    inc eax
;    cmp eax, ebx
;    jb .mount_count_checked
;
;    ; mount count exceeded, should run fsck

.mount_count_checked:
    
    call _calc_sb_info
    jc short .mount_failure

  ;=- Initialize performance enhancement options
  call _init_enhancements
  jc short .mount_failure

  mov ecx, (exported_fs_data_end-exported_fs_data_start)
  malloc "exported_fs_data"
  jc short .mount_failure

  ;=- Export file system data
  mov esi, exported_fs_data_start
  mov ecx, (exported_fs_data_end-exported_fs_data_start) / 4
  push edi
  mem_mov "exporting file system data"
  pop edi

%ifdef _EXT2_MONITORING_
 mov [lastmount_fs_data], edi
%endif

  pop esi
  pop esi
  pop eax
  mov edx, edi				; point to our functions calltable
  externfunc vfs.register_mountpoint	; register the mountpoint
  clc
  retn
  
    
.mount_failure:
  pop edi
  add esp, byte 8
  push eax				; restore pointer to buffer
  mov eax, edi
  externfunc mem.dealloc		; deallocate it

  mov ebx, [device_file_handle]
  mov ebp, [ebx]
  call [ebp + file_op_table.close]

  pop eax
  stc
  retn 					; clear both eax and esi from stack




_calc_sb_info:
;------------------------------------------------------------------------------
; parameters:
;------------
; EDI = pointer to superblock buffer
;
; returns:
;---------
; cf = 0, successful
;  eax = s_gdb_count
;
; cf = 1, failed (currently locking up rather than returning)
; TODO: ^^^^^^^^^^^^^
				;
				; computing fragment size
				;------------------------
  mov ecx, [edi + ext2_super_block.s_log_frag_size]
  mov edx, 1024			; fragment size are 1024<<log or 1024>>log
  mov ebx, edx			;  depending on ecx being negative or positive
  or ecx, ecx			; check ecx sign
  js short .switch_frag_size_right	; if signed, go do 1024>>log
  				;
    %ifdef _PARANOIA_MOUNT_	;
    cmp ecx, byte 21		; just make sure this value is valid
      %ifdef _EXTENDED_ERROR_CODE_
        mov [ext2fs.extended_error_code], dword _EXT_E_FRAG_SIZE_OVERFLOW
      %endif			;
    jae near .invalid_sb	; 1024<< for more than 21 bits overflow..
    %endif			;
    				;
  shl edx, cl			; shift left 1024<<cl
  jmp short .store_frag_size	; frag size computed, go store it
.switch_frag_size_right:	; gotta do 1024>>cl
  neg ecx			; first, make it back to positive value
  				;
    %ifdef _PARANOIA_MOUNT_	;
    cmp ecx, byte 10		; make sure we don't reduce it to 0
      %ifdef _EXTENDED_ERROR_CODE_
        mov [ext2fs.extended_error_code], dword _EXT_E_FRAG_SIZE_UNDERFLOW
      %endif			;
    jae near .invalid_sb	; seems like it did, wrong fs pal
    %endif			;
 				;
  shr edx, cl			; shift it right 1024>>cl
  neg ecx			; set ecx back to its value
.store_frag_size:		;
				;
  mov [super_block.s_frag_size], edx	; here we store final frag size
  mov eax, ecx			; copy log2fragsize into eax
				;
				; computing block size
				;---------------------
  mov ecx, [edi + ext2_super_block.s_log_block_size]	; load log2blocksize
				;
    %ifdef _PARANOIA_MOUNT_	;
    cmp ecx, byte 21		; make sure log2block size won't overflow 32bit
      %ifdef _EXTENDED_ERROR_CODE
        mov [ext2fs.extended_error_code], dword _EXT_E_BLOCK_SIZE_OVERFLOW
      %endif			;
    jae short .invalid_sb	; well, it would, screw it
    %endif			;
				;
  shl ebx, cl			; shift 1024<<cl
  push ebx			;
  shr ebx, 9			;
  mov [super_block.s_sectors_per_block], ebx
  pop ebx			;
  mov [super_block.s_block_size], ebx
				;
  pushad			; compute ind/bind/tind limits
				;-----------------------------
  shr ebx, 2			; (block_size / 4)
  mov [super_block.s_ind_limit], ebx
  mov eax, ebx			;
  imul eax, ebx			;
  mov [super_block.s_bind_limit], eax
  imul eax, ebx			;
  mov [super_block.s_tind_limit], eax
  popad				;
  				;
				; computing number of fragments per block
				;----------------------------------------
  sub ecx, eax			; make sure fragments are smaller than blocks
				;
   %ifdef _PARANOIA_MOUNT_	;
    %ifdef _EXTENDED_ERROR_CODE_;
      mov [ext2fs.extended_error_code], dword _EXT_E_FRAG_LARGER_THAN_BLOCK
    %endif			;
    js short .invalid_sb	; seem like it wasn't, doh!
   %endif			;
				;
  mov edx, 1			; now find how many frags fill a block
  shl edx, cl			; compute our little value
  mov [super_block.s_frags_per_block], edx	; and store it there
  				;
				; determining inodes per block
				;-----------------------------
  cmp dword [edi + ext2_super_block.s_rev_level], byte EXT2_GOOD_OLD_REV
  mov ecx, EXT2_GOOD_OLD_INODE_SIZE
  jz short .compute_inodes_per_block
  mov ecx, [edi + ext2_super_block.s_inode_size]
.compute_inodes_per_block:	;
  mov eax, ebx			; set eax = block size
  xor edx, edx			; clear out edx
  div ecx			; blocksize / inodesize
  				;
%ifdef _PARANOIA_MOUNT_		;
    or edx, edx			; make sure all that fits perfectly
    jz short .store_inodes_per_block	; hrm..it is, cool!
				;
    %ifdef _EXTENDED_ERROR_CODE_;
      mov [ext2fs.extended_error_code], dword _EXT_E_INODES_PER_BLOCK
    %endif			;
 				;
.invalid_sb:			;
  stc				;
  retn				;
%endif				;
				;
.store_inodes_per_block:	;
  mov [super_block.s_inodes_per_block], eax	; inodes/block, store it
  mov [super_block.s_inode_size], ecx		; also store inode size
				;
				; compute value of s_desc_per_block
				;----------------------------------
  xchg eax, ebx			; switch those, will be easier
  mov ecx, eax			; set ecx= blocksize
  shr eax, 5			; divide block_size by ext2_group_desc_size
  mov [super_block.s_desc_per_block], eax	; save the result
  lea eax, [eax*8]		; eax = blocksize>>2
  bsr eax, eax			; find log2 of eax
  bsr ecx, ecx			; find log2 of ecx
  mov [super_block.s_desc_per_block_bits], eax	; store results..
  mov [super_block.s_addr_per_block_bits], ecx
				;
				; copy inodes|frags|blocks per group values
				;------------------------------------------
  mov eax, [edi + ext2_super_block.s_blocks_per_group]
  mov ecx, [edi + ext2_super_block.s_frags_per_group]
  mov [super_block.s_blocks_per_group], eax
  mov [super_block.s_frags_per_group], ecx
  mov eax, [edi + ext2_super_block.s_inodes_per_group]
  mov [super_block.s_inodes_per_group], eax
				;
				; compute number of itb per group
				;--------------------------------
				; EAX = inodes_per_group, EDX = 0 (should be)
  div ebx			; inodes_per_group/inodes_per_block
				;
    %ifdef _PARANOIA_MOUNT_	;
    or edx, edx			; make sure it perfectly fits
      %ifdef _EXTENDED_ERROR_CODE_
        mov [ext2fs.extended_error_code], dword _EXT_E_INODES_PER_GROUP
      %endif			;
    jnz short .invalid_sb	; hrm.. lucky guy, went up to here, catched ya!
    %endif			;
				;
  mov [super_block.s_itb_per_group], eax
  ;
  ; compute s_groups_count
  ;
  ; s_group_count = ( block_count - first_data_block + blocks_per_group - 1)
  ;                 --------------------------------------------------------
  ;                                    blocks_per_group
  ;
  mov eax, dword [edi + ext2_super_block.s_blocks_count]
  sub eax, dword [edi + ext2_super_block.s_first_data_block]
  dec eax
  mov ebx, dword [super_block.s_blocks_per_group]
  add eax, ebx
  div ebx
  mov [super_block.s_groups_count], eax
  ;
  ; compute gdb_count
  ;------------------
  ; gdb_count =   groups_count + desc_per_block - 1
  ;               ---------------------------------
  ;                      desc_per_block
  ;
  mov ecx, dword [super_block.s_desc_per_block]
  lea eax, [byte eax + ecx - 1]		;
  xor edx, edx				;
  div ecx				;
  mov [super_block.s_gdb_count], eax	;
					;
  mov [super_block.s_sbh], edi		; store pointer to fs superblock  
					;
  clc					;
  retn					;
;------------------------------------------------------------------------------


_init_enhancements:
;------------------------------------------------------------------------------
; parameters:
;------------
;  eax = s_gdb_count
;
; returns:
;---------
; cf = 0, successful
;  eax = (undetermined)
;  ebx = (undetermined)
;  ecx = (undetermined)
;  edx = (undetermined)
;  esi = (undetermined)
;  edi = (undetermined)
;  esp = (unmodified)
;  ebp = (unmodified)
;
; cf = 1, failed
;  eax = error code
;  ebx = (undetermined)
;  ecx = (undetermined)
;  edx = (undetermined)
;  esi = (undetermined)
;  edi = (undetermined)
;  esp = (unmodified)
;  ebp = (unmodified)
;
  xor ebx, ebx				;
  dec ebx				;
  					; Make sure all ITB cache entries
					; are cleared
					;--------------------------------
					; EBX = -1
%ifndef PERFORMANCE_ITB_CACHE_DISABLE	;
  mov ecx, PERFORMANCE_ITB_CACHED	;
  mov edi, itb_cached			;
.formating_itb_cache:			;
  mov [edi], dword ebx			;
  add edi, byte cached_itb_size		;
  loop .formating_itb_cache		;
%else					;
  pushad				;
  mov ecx, [super_block.s_block_size]	;
  malloc "itb entry, cache disabled"	;
  mov [esp], edi			;
  popad					;
  jnc .itb_cache_allocated		;
  mov eax, __ERROR_INSUFFICIENT_MEMORY__;
    %ifdef _EXTENDED_ERROR_CODE_	;
      mov [ext2fs.extended_error_code], dword _EXT_E_ITB_ALLOC
    %endif				;
					; CF = 1 already
  retn					;
					;
.itb_cache_allocated:			;
  mov [itb_cache], edi			;
%endif					;
					; Make sure all INODES cache entries
					; are cleared
					;-----------------------------------
					; assuming EBX = -1
%ifndef PERFORMANCE_INODES_CACHE_DISABLE;
  mov ecx, PERFORMANCE_INODES_CACHED	;
  mov edi, inodes_cached		;
.formating_inodes_cache:		;
  mov [edi], dword ebx			;
  add edi, byte cached_inode_size	;
  loop .formating_inodes_cache		;
%else					;
  pushad				;
  mov ecx, ext2_inode_size		;
  malloc "inode entry, cache disabled"	;
  mov [esp], edi			;
  popad					;
  jnc short .inode_cache_allocated	;
  mov eax, [itb_cache]			;
  externfunc mem.dealloc		;
  mov eax, __ERROR_INSUFFICIENT_MEMORY__;
    %ifdef _EXTENDED_ERROR_CODE_	;
      mov [ext2fs.extended_error_code], dword _EXT_E_INODE_ALLOC
    %endif				;
  ;stc					; CF = 1 already
  retn					;
					;
.inode_cache_allocated:			;
  mov [inode_cache], edi		;
%endif					;
					;
					; Make sure all BLOCKS cache entries
					; are cleared
					;-----------------------------------
					; assuming EBX = -1
%ifndef PERFORMANCE_BLOCKS_CACHE_DISABLE;
  mov ecx, PERFORMANCE_BLOCKS_CACHED	;
  mov edi, blocks_cached		;
.formating_blocks_cache:		;
  mov [edi], dword ebx			;
  add edi, byte cached_block_size	;
  loop .formating_blocks_cache		;
%else					;
  pushad				;
  mov ecx, [super_block.s_block_size]	;
  malloc "block entry, cache disabled"	;
  mov [esp], esi			;
  popad					;
  jnc short .block_cache_allocated	;
    mov eax, [itb_cache]		;
    externfunc mem.dealloc		;
    mov eax, [inode_cache]		;
    externfunc mem.dealloc		;
    %ifdef _EXTENDED_ERROR_CODE_	;
      mov [ext2fs.extended_error_code], dword _EXT_E_BLOCK_ALLOC
    %endif				;
  mov eax, __ERROR_INSUFFICIENT_MEMORY__;
  stc					;
  retn					;
					;
.block_cache_allocated:			;
  mov [block_cache], edi		;
%endif					;
					;
					; assuming EAX = s_gdb_count
  push eax				;
  mul dword [super_block.s_sectors_per_block]
  mov ecx, eax				;
  shl ecx, byte 9			;
  malloc "group descriptor blocks"	;
  pop ecx				;
    %ifdef _EXTENDED_ERROR_CODE_	;
     mov [ext2fs.extended_error_code], dword _EXT_E_GDB_BUFFER_ALLOC
   %endif     				;
  jc near .failed			;
					; 
					;
  mov [super_block.s_group_desc], edi	; save the pointer to the group
					; descriptor block buffer
					;
					; assuming...
					; edi = pointer to allocated block
					; ecx = number of blocks to read
  mov eax, 1				;
  cmp dword [super_block.s_sectors_per_block], byte 2
  jnz short .gd_adjusted		;
  inc eax				;
.gd_adjusted:				;
  mov ebx, exported_fs_data_start	;
  push esi				;
  push ecx				;
  imul ecx, [super_block.s_block_size]	;
  xor esi, esi				;
  call _read_blocks			;
  pop ecx				;
  pop esi				;
    %ifdef _EXTENDED_ERROR_CODE_	;
     mov [ext2fs.extended_error_code], dword _EXT_E_GDB_READ_FAILED
    %endif				;
  jc short .failed_free_gdb		;
					;
					; load root inode
					;----------------
  mov eax, EXT2_ROOT_INO		; inode number to load
  call _load_inode_in_cache		;
  retn					;
					;
.failed_free_gdb_pop1:			;
  pop ebx				;
.failed_free_gdb:			;
  mov eax, [super_block.s_group_desc]	;
  externfunc mem.dealloc		;
    %ifdef _PARANOIA_SELF_			;
      jc short .self_check_failed	;
    %endif				;
  stc					;
.failed:				;
  retn					;
					;
%ifdef _PARANOIA_SELF_			;
.self_check_failed:			;
  mov eax, __ERROR_INTERNAL_FAILURE__	;
  stc					;
  retn					;
%endif ; _PARANOIA_SELF_			;
;------------------------------------------------------------------------------




_fsck:
;------------------------------------------------------------------------------
; Time for file system check, either mount count reached its limit or fs
; uncleanly unmounted.
  stc
  retn
;------------------------------------------------------------------------------





_i_cache_unlock:
;------------------------------------------------------------------------------
;
; Unlock an Inode cache entry
;
; Parameters:
;------------
;   ebx = file system descriptor
;   stack(0) = pointer to inode buffer of related cache entry to free
;
; Returns:
;---------
;   none, flags and registers kept intact
;
;------------------------------------------------------------------------------
  pushfd
  push eax
  push ecx
  push ebx

  lea   dword eax, [ebx + __inodes_cached]
  mov	dword ecx, PERFORMANCE_INODES_CACHED
  mov   dword ebx, [esp + 20]
.searching_inode:
  cmp	[eax + cached_inode.buffer_ptr], ebx
  jz	short .inode_found
  add	dword eax, byte cached_inode_size
  dec	dword ecx
  jnz	short .searching_inode

%ifdef _MONITOR_INODE_LOCKS_
pushad
mov edx, [esp + 52]
mov esi, str_dbg.i_cache_unlock_failed
externfunc sys_log.print_string
externfunc sys_log.print_hex
externfunc sys_log.terminate
externfunc debug.diable.wait
popad
%endif
  pop ebx
  pop ecx
  pop eax
  popfd
  retn 4

.inode_found:
  mov	dword ecx, [cache_operations_counter]	; load cache counter
  inc	dword [cache_operations_counter]	; tick once cache op counter
  mov	dword [eax + 8], ecx			; mark last access time
  dec	dword [eax + 12]			; remove one lock from cache

%ifdef _MONITOR_INODE_LOCKS_
pushad
mov edx, [esp + 52]
mov esi, str_dbg.i_cache_unlock_success
externfunc sys_log.print_string
externfunc sys_log.print_hex
externfunc sys_log.terminate
popad
%endif

  pop ebx
  pop ecx
  pop eax
  popfd
  retn 4					; get back to caller
;------------------------------------------------------------------------------



_load_inode_in_cache:
;------------------------------------------------------------------------------
;
; note: same as with the other caching function, this one will fetch the inode
; if required and lock it.  Once you are done with the data, make sure to
; call the cache_unlock function.
;
; parameters:
;------------
; EBX = pointer to fs descriptor
; EAX = inode number to load in cache
;
; returns:
;---------
; cf = 0, successful
;   eax = (unmodified)
;   ebx = (unmodified)
;   ecx = (unmodified)
;   edx = (unmodified)
;   esi = (unmodified)
;   edi = pointer to inode data
;   esp = (unmodified)
;   ebp = (unmodified)
;
; cf = 1, failed
;   eax = error code
;   ebx = (unmodified)
;   ecx = (unmodified)
;   edx = (unmodified)
;   esi = (unmodified)
;   edi = (unmodified)
;   esp = (unmodified)
;   ebp = (unmodified)
;

  pushad

  dec eax

  mov ecx, PERFORMANCE_INODES_CACHED
  lea esi, [ebx + __inodes_cached]
  xor edi, edi
  dec edi
.check_cached_inodes:
  mov edx, [esi]
  cmp edx, byte -1
  jz short .free_entry
  cmp edx, eax
  jnz short .next_inode_entry

.found_inode:
  mov edi, [esi + cached_inode.buffer_ptr]
  inc dword [esi + cached_inode.locks]
  mov [esp], edi
  popad

%ifdef _MONITOR_INODE_LOCKS_
pushad
mov edx, eax
mov esi, str_dbg.locked_inode
externfunc sys_log.print_string
externfunc sys_log.print_hex
mov esi, str_dbg.buffer
mov edx, edi
externfunc sys_log.print_string
externfunc sys_log.print_hex
externfunc sys_log.terminate
externfunc debug.diable.wait
popad
%endif

  clc
  retn

.free_entry:
  mov edi, esi

.next_inode_entry:
  add esi, byte cached_inode_size
  dec ecx
  jnz short .check_cached_inodes
  
  ; no matching cached inode
  ; check if we have encountered a free cache entry while searching
  cmp edi, byte -1
  jz short .search_oldest_cached_entry	; nope, then use an old cache entry

  ; try allocating a new inode buffer
  push edi
  push eax
  push ebx
  mov ecx, ext2_inode_size
  malloc "new inode buffer, cache enabled"
  pop ebx
  pop eax
  pop esi
  jc short .search_oldest_cached_entry

  mov [esi + cached_inode.buffer_ptr], edi
  mov [esi + cached_inode.locks], dword 0
  jmp short .read_inode_data

.search_oldest_cached_entry:
  lea edi, [ebx + __inodes_cached]
  mov ecx, PERFORMANCE_INODES_CACHED
  xor esi, esi
  dec esi
.update_oldest_cache_entry:
  cmp [edi], byte -1
  jz short .bypass_free_cache
  cmp [edi + cached_inode.locks], byte 0
  jnz short .bypass_locked_cache
  mov esi, edi
  mov edx, [edi + cached_inode.last_access]
.bypass_free_cache:
.bypass_locked_cache:
.check_for_oldest:
  add edi, byte cached_inode_size
  dec ecx
  jz short .check_validity_of_inode

  cmp [edi + cached_inode.last_access], edx
  jb short .update_oldest_cache_entry
  jmp short .check_for_oldest

.check_validity_of_inode:
  cmp esi, byte -1
  jnz short .read_inode_data

  popad
  mov eax, -1; XXX TODO: select a different error code ;)
  stc
  retn

.read_inode_data:
  ; esi = pointer to inode cache entry to use
  ; eax = inode number
  ; ebx = fs descriptor
  mov [esi + cached_inode.inode_number], eax
  inc dword [esi + cached_inode.locks]

  mov ecx, esi
  call _load_itb_in_cache
  jc near .dealloc_cache_entry

  ; esi = pointer to itb buffer
  xor edx, edx
  div dword [ebx + __s_inodes_per_block]
  
  imul eax, edx, ext2_inode_size
  mov edi, [ecx + cached_inode.buffer_ptr]
  add esi, eax
  mov ecx, ext2_inode_size/4
  mov [esp], edi
  mem_mov "copying inode to cache entry"
  popad

%ifdef _MONITOR_INODE_LOCKS_
pushad
mov edx, eax
mov esi, str_dbg.locked_inode
externfunc sys_log.print_string
externfunc sys_log.print_hex
mov esi, str_dbg.buffer
mov edx, edi
externfunc sys_log.print_string
externfunc sys_log.print_hex
externfunc sys_log.terminate
externfunc debug.diable.wait
popad
%endif

  clc
  retn

.dealloc_cache_entry:
  mov [esp+28], eax		; pass on error code
  mov eax, edi
  mov [ecx], dword -1
  externfunc mem.dealloc
  popad
  stc
  retn
;------------------------------------------------------------------------------
  



_load_itb_in_cache:
;------------------------------------------------------------------------------
; Loads a block of the Inode Table in cache
;
; parameters:
;------------
; EBX = pointer to fs descriptor
; EAX = inode number for which associated ITB should be loaded
;
; returns:
;---------
; cf = 0, successful
;   eax = (unmodified)
;   ebx = (unmodified)
;   ecx = (unmodified)
;   edx = (unmodified)
;   esi = pointer to itb buffer
;   edi = (unmodified)
;   esp = (unmodified)
;   ebp = (unmodified)
;
; cf = 1, failed
;   eax = error code
;   ebx = (unmodified)
;   ecx = (unmodified)
;   edx = (unmodified)
;   esi = (unmodified)
;   edi = (unmodified)
;   esp = (unmodified)
;   ebp = (unmodified)
;

  pushad
    inc dword [cache_operations_counter]

    ; compute inodes block boundaries associated with requested inode
    mov ecx, eax
    xor edx, edx
    div dword [ebx + __s_inodes_per_block]
    sub ecx, edx
    mov eax, ecx
    dec ecx
    add ecx, [ebx + __s_inodes_per_block]
    ; EAX = first inode of the block

    mov edx, ecx
    xor edi, edi
    mov ecx, PERFORMANCE_ITB_CACHED
    dec edi
    lea esi, [ebx + __itb_cached]
.check_cached_itb:
    cmp eax, [esi + cached_itb.first_inode]
    jz near .itb_found

.check_next_cached_itb:
    cmp [esi + cached_itb.first_inode], byte -1	; cache entry empty?
    jnz short .not_free_entry			; looks like it wasn't..
    mov edi, esi				; set edi = free entry
  .not_free_entry:
    add esi, byte cached_itb_size
    dec ecx
    jnz short .check_cached_itb

    ; ITB not found, identifying if a free ITB cache entry is available, if so
    ; allocate memory and use it, otherwise, discard an old cached itb entry
    cmp edi, byte -1
    jz short .itb_cache_full
    ; edi = pointer to last empty ITB cache entry found

    ; try to allocate extra itb buffer, if it fails we might still have a
    ; chance to recover by using the oldest buffer available.
    mov esi, edi
    push eax
    mov ecx, [ebx + __s_sectors_per_block]
    shl ecx, 9
    malloc "new itb buffer, cache enabled"
    pop eax
    jc short .itb_cache_full
    
    mov [esi + cached_itb.buffer_ptr], edi
    jmp short .read_itb_from_disk

.itb_cache_full:
    ; Let's search for the oldest ITB entry..
    lea edi, [ebx + __itb_cached]
    mov ecx, PERFORMANCE_ITB_CACHED
  .update_access_check_next_itb:
    mov esi, edi
    mov edx, [edi + cached_itb.last_access]
  .check_next_itb:
    add edi, byte cached_itb_size
    dec ecx
    jz short .set_edi_and_read_itb_from_disk

  .compare_itb_last_access:
    cmp [edi + cached_itb.last_access], edx
    jae .check_next_itb
    jmp short .update_access_check_next_itb
    

.itb_found:
  mov eax, [cache_operations_counter]
  mov [esi + cached_itb.last_access], eax
  mov esi, [esi + cached_itb.buffer_ptr]
  mov [esp + 4], esi
  popad
  clc
  retn

.set_edi_and_read_itb_from_disk:
    mov edi, [esi + cached_itb.buffer_ptr]

.read_itb_from_disk:
    ; esi = itb cache entry
    ; edi = destination buffer
    ; eax = first inode
    ; first, update cache entry
    mov [esi + cached_itb.first_inode], eax
    mov ecx, [cache_operations_counter]
    mov [esi + cached_itb.last_access], ecx

    ; eax = first inode of the block to read
    ; first compute its offset in the group descriptor table
    xor edx, edx
    div dword [ebx + __s_inodes_per_group]
    mov ecx, eax
    mov eax, edx
    xor edx, edx
    div dword [ebx + __s_inodes_per_block]
    ; ecx = group id
    ; eax = block offset from start of itb

    imul ecx, byte ext2_group_desc_size
    add ecx, [ebx + __s_group_desc]
    add eax, [ecx + ext2_group_desc.bg_inode_table]

    mov ecx, [ebx + __s_block_size]
    xor esi, esi
	;pushad
	;mov edx, edi
	;mov edi, 0xB80A0
	;externfunc debug.diable.dword_out
	;mov edx, ecx
	;mov edi, 0xB8140
	;externfunc debug.diable.dword_out
	;mov edx, esi
	;mov edi, 0xB81E0
	;externfunc debug.diable.dword_out
	;mov edx, eax
	;mov edi, 0xB8280
	;externfunc debug.diable.dword_out
	;mov edx, 0x11111111
	;mov edi, 0xB8000
	;externfunc debug.diable.dword_out_wait
	;mov eax, 0x17201720
	;mov ecx, 1000
	;rep stosd
	;popad
    call _read_blocks
    jc short .failed_read_itb

    mov [esp + 4], edi
    popad
    clc
    retn


.failed_read_itb:
  mov [esp+28], eax
  mov eax, edi
  mov [esi], dword -1		; mark cache entry as empty
  externfunc mem.dealloc		; deallocate itb allocated buffer
  popad
  stc
  retn
;------------------------------------------------------------------------------



_read_blocks:
;------------------------------------------------------------------------------
;
; parameters:
;------------
; EAX = block id
; EBX = fs handler
; ECX = number of bytes to read
; ESI = offset from inside the first block to start reading from
; EDI = location where to put the block
;
; returned values:
;-----------------
; cf = 0, successful
;  eax = last block read + 1
;  ebx = (unmodified)
;  ecx = 0
;  edx = (unmodified)
;  esi = 0
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
; cf = 1, failed
;  eax = error code
;  ebx = (unmodified)
;  ecx = numbers of bytes left to read
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
  push edi				;
  push esi				;
  add ecx, esi				;
.reading_blocks:			;
  pushad				;
					;
  inc dword [cache_operations_counter]	;
  mov ecx, PERFORMANCE_BLOCKS_CACHED	;
  lea esi, [ebx + __blocks_cached]	;
  xor edx, edx				;
  dec edx				;
.search_block_cache:			;
  cmp [esi], eax			;
  jz near .block_hit			;
  cmp dword [esi], byte -1		;
  jnz short .not_empty			;
  mov edx, esi				;
.not_empty:				;
  add esi, byte cached_block_size	;
  loop .search_block_cache		;
					;
  cmp edx, byte -1			;
  jz short .search_oldest_cache_entry	;
					;
  push edi				;
  push eax				;
  push ebx				;
  push edx				;
  mov ecx, [ebx + __s_block_size]	;
  malloc "new block entry, cache enabled"
  pop esi				;
  mov [esi + cached_block.buffer_ptr], edi
  pop ebx				;
  pop eax				;
  pop edi				;
  jnc short .read_block_from_disk	;
					;
.search_oldest_cache_entry:		;
  mov ecx, PERFORMANCE_BLOCKS_CACHED	;
  lea edi, [ebx + __blocks_cached]	;
  xor esi, esi				;
  dec esi				;
  mov edx, esi				;
.searching_oldest:			;
  cmp dword [edi], byte -1		;
  jz short .bypass_entry		;
  cmp [edi + cached_block.last_access], edx
  ja short .bypass_entry		;
  mov esi, edi				;
  mov edx, [edi + cached_block.last_access]
.bypass_entry:				;
  add edi, byte cached_block_size	;
  loop .searching_oldest		;
					;
  cmp edx, byte -1			;
  jz near .failed_allocating		;
					;
.read_block_from_disk:			;
  mov [esi + cached_block.block_number], eax
  mov ecx, [cache_operations_counter]	;
  mov [esi + cached_block.last_access], ecx
  mov ecx, [ebx + __s_sectors_per_block];
  mul ecx				;
  push ebx				;
  mov ebx, [ebx + __device_file_handle]	;
  mov ebp, [ebx]			;
  push esi				;
  mov edi, [esi + cached_block.buffer_ptr]
	;pushad
	;mov edi, 0xB80A0
	;externfunc debug.diable.dword_out
	;mov edx, eax
	;mov edi, 0xB8140
	;externfunc debug.diable.dword_out
	;mov edx, ecx
	;mov edi, 0xB81E0
	;externfunc debug.diable.dword_out
	;mov edx, 0x22222222
	;mov edi, 0xb8000
	;externfunc debug.diable.dword_out_wait
	;mov eax, 0x17201720
	;mov ecx, 1000
	;rep stosd
	;popad
  call [ebp + file_op_table.raw_read]	;
  pop esi				;
  pop ebx				;
  jc near .failed_read			;
  mov edi, [esp]			;
					;
.block_hit:				;
  mov ecx, [cache_operations_counter]	;
  mov [esi + cached_block.last_access], ecx
  mov esi, [esi + cached_block.buffer_ptr]
					;
  mov ecx, [ebx + __s_block_size]	;
  sub [esp + 24], ecx			;
  jbe short .last_block			;
  mov eax, [esp + 4]			;
  sub ecx, eax				;
  add esi, eax				;
  sub [esp + 4], eax			;
  					;
  mem_movb "moving complete/partial block from cache to dest"
  mov [esp], edi			;
  popad					;
  xor esi, esi				;
  inc eax				;
  jmp near .reading_blocks		;
					;
.last_block:				;
  add ecx, dword [esp + 24]		;
  mov eax, [esp + 4]			;
  add esi, eax				;
  sub ecx, eax				;
  mem_movb "moving last block, from cache to destination"
  popad					;
  pop esi				;
  xor esi, esi				;
  xor ecx, ecx				;
  pop edi				;
  clc					;
  retn					;
					;
.failed_read:				;
  mov [esp + 28], eax			; pass on error code
  popad					;
  pop esi				;
  pop edi				;
    %ifdef _EXTENDED_ERROR_CODE_	;
      mov [ext2fs.extended_error_code], dword _EXT_E_BLOCK_READ_FAILED
    %endif				;
  stc					;
  retn					;
					;
.failed_allocating:			;
  popad					;
  pop esi				;
  mov eax, __ERROR_INSUFFICIENT_MEMORY__;
    %ifdef _EXTENDED_ERROR_CODE_	;
      mov [ext2fs.extended_error_code], dword _EXT_E_BLOCK_ALLOC
    %endif				;
  stc					;
  retn					;
;------------------------------------------------------------------------------



_find_dir_entry:
;------------------------------------------------------------------------------
;
; parameters:
;------------
; EBX = pointer to fs descriptor
; EDI = pointer to inode entry of the directory to search
; ESI = pointer to filename to search
;
; returned values:
;-----------------
; cf = 0, successful
;  eax = (unmodified)
;  ebx = (unmodified)
;  ecx = (unmodified)
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = pointer to the directory entry
;  esp = (unmodified)
;  ebp = (unmodified)
;
; cf = 1, failed
;  eax = error code
;  ebx = (unmodified)
;  ecx = (unmodified)
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
; internals
; -
; eax = current offset in directory entry block
; ebx = pointer to fs descriptor
; ecx = string length
; edx = pointer to inode entry
; esi = pointer to filename we are searching for
;
  pushad				; save all regs
  mov edx, edi				; set edx = inode pointer
					;
					; esi = pointer to string
  call _str_len				; get filename length (ecx)
  test ecx, 0xFFFFFF00			; if above 255, fail
  jnz short .entry_not_found		; it is,.. let's fail
					;
					; assuming ecx = lengh of file/dir name
  mov eax, 1				;
.lock_dir_entry:			;
  xchg [ebx + __dir_entry_cache.LOCK], eax
  test eax, eax				;
  jnz short .lock_dir_entry		;
					;
  ;xor eax, eax				; assume eax = 0 = start of directory
					;
.searching_directory:			;
  cmp eax, [edx + ext2_inode.i_size]	; eax past the end of the directory?
  jae short .entry_not_found		; yes, file not found
					;
  call .cache_directory_entry		; read directory entry
  jc short .entry_not_found		; couldn't read directory entry :(
					;
  cmp cl, [edi + ext2_dir_entry.name_len]	; compare filenames length
  jz short .check_inode_number		; length are the same, analyze further
					;
.check_next_entry:			;
  movzx edi, word [edi + ext2_dir_entry.rec_len]	; read record length
  add eax, edi				; add record length to current pointer
  jmp short .searching_directory	; search next entry
					;
.check_inode_number:			;
  cmp dword [edi + ext2_dir_entry.inode], byte 0	; 0=emtpy entry
  jz short .check_next_entry		; inode is 0, empty entry
					;
  push edi				; save pointer to dir entry
  push esi				; save pointer to filename
  push ecx				; save filename length
  add edi, byte ext2_dir_entry.name	; select dir entry filename
  repz cmpsb				; compare the 2 strings
  pop ecx				; restore filename length
  pop esi				; restore pointer to filename
  pop edi				; restore pointer to dir entry
  jnz short .check_next_entry		; filenames are different
					;
					; filename match!
					;
  mov [esp], edi			; set pointer to directory entry
  popad					; restore original regs
  clc					; indicate success
  retn					; return
					;
.entry_not_found:			;
    %ifdef _EXTENDED_ERROR_CODE_	;
      mov [ext2fs.extended_error_code], dword _EXT_E_DIR_ENTRY_NOT_FOUND
    %endif				;
  mov [ebx + __dir_entry_cache.LOCK], dword 0
  popad					; restore all regs
  mov eax, __ERROR_FILE_NOT_FOUND__	; set error code
  stc					; set error flag
  retn					; return
					;
					;
.cache_directory_entry:			;
  pushad				; backup all regs
  lea edi, [ebx + __dir_entry_cache]	; point to dir entry buffer
  mov ecx, ext2_dir_entry_size		; set the size of the read
  call _read_file_sub_section		; read the entry
  mov [esp], edi			; set pointer to entry
  popad					; restore all regs
  retn					; return with caller's error code
;------------------------------------------------------------------------------



_read_file_sub_section:
;------------------------------------------------------------------------------
;
; parameters:
;------------
; eax = offset to start reading from
; ebx = fs descriptor
; ecx = size in bytes to read
; edx = inode
; edi = destination buffer
;
; returns:
;---------
; cf = 0, successful
;  eax = last read sequential block + 1
;  ebx = (unmodified)
;  ecx = 0
;  edx = (unmodified)
;  esi = 0
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
; cf = 1, failed
;  eax = error code
;  ebx =
;  ecx = 
;  edx = 
;  esi = 
;  edi = 
;  esp = 
;  ebp = 
;
  push edi
  ; compute starting block id
  ; and starting offset
  mov esi, [ebx + __s_block_size]
  push edx
  xor edx, edx
  div esi
  mov esi, edx
  pop edx
  ; eax = block sequential number
  ; ebx = fs descriptor
  ; ecx = size in bytes to read
  ; edx = inode
  ; esi = offset to start reading from
  ; edi = destination buffer
.get_next_block:
  push eax
  call _get_block_id
  jc short .failed

  ; eax = block id
  ;-
  push edx			; backup inode ptr
  push ecx
  mov edx, [ebx + __s_block_size]
  sub edx, esi			; get virtual block size after start of offset
  sub edx, ecx			;
  jnb short .read_it

  add ecx, edx

.read_it:
  pop edx
  sub edx, ecx
  push edx
  push ecx
	;pushad
	;mov edx, edi
	;mov edi, 0xB80A0
	;externfunc debug.diable.dword_out
	;mov edx, 0xB100D000
	;mov edi, 0xB8000
	;externfunc debug.diable.dword_out
	;mov edx, eax
	;mov edi, 0xB8140
	;externfunc debug.diable.dword_out
	;mov edx, ecx
	;mov edi, 0xB81E0
	;externfunc debug.diable.dword_out
	;mov edx, esi
	;mov edi, 0xB81E0+0xA0
	;externfunc debug.diable.dword_out_wait
	;popad
  call _read_blocks
	;vm edi
  xor esi, esi
  pop ecx
  add edi, ecx
  pop ecx
  pop edx
  pop eax
  inc eax
  or ecx, ecx
  jnz short .get_next_block
  pop edi
  clc
  retn

.failed:
  add esp, byte 4
  pop edi
  retn

_get_block_id:
;------------------------------------------------------------------------------
;
; parameters:
;------------
; eax = block sequential number
; ebx = fs descriptor
; edx = pointer to inode
;
; returned values:
;-----------------
; cf = 0, successful
;  eax = block id
;  ebx = (unmodified)
;  ecx = (unmodified)
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
; cf = 1, failed
;  eax = error code
;  ebx = (unmodified)
;  ecx = (unmodified)
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;

  cmp eax, byte 12
  jae short .indirect_block_id

  mov eax, [eax*4 + edx + ext2_inode.i_block]
  clc
  retn

.indirect_block_id:
  sub eax, byte 12
  cmp eax, [ebx + __s_ind_limit]
  jb short .ind_redirection
  cmp eax, [ebx + __s_bind_limit]
  jb short .bind_redirection
  cmp eax, [ebx + __s_tind_limit]
  jb short .tind_redirection

    %ifdef _EXTENDED_ERROR_CODE_
      mov [ext2fs.extended_error_code], dword _EXT_E_TIND_LIMIT_EXCEEDED
    %endif

  mov eax, __ERROR_INTERNAL_FAILURE__
  stc
  retn

.tind_redirection:
.bind_redirection:
.ind_redirection:
  dmej 0xE2F05453


_str_len:
;------------------------------------------------------------------------------
;
; parameters:
;------------
; esi = pointer to string
;
; returns:
;---------
; eax = (unmodified)
; ebx = (unmodified)
; ecx = string length
; edx = (unmodified)
; esi = (unmodified)
; edi = (unmodified)
; esp = (unmodified)
; ebp = (unmodified)
;

  xor ecx, ecx			; 
  dec ecx			; set starting size to -1
.finding_length:
  inc ecx			; increase filename length
  cmp [esi+ecx], byte 0		; check for end of filename marker
  jnz short .finding_length	; end of filename reached? nope, continue

  retn				; return with filename length





__open:
;------------------------------------------------------------------------------
;
; parameters:
;------------
; esi = filename (utf-8)
; edx = file system descriptor
;
; returned values:
;-----------------
; cf = 0, successful
;  eax = (unmodified)
;  ebx = file handle
;  ecx = file size
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
; cf = 1, failed
;  eax = error code
;  ebx = (unmodified)
;  ecx = (unmodified)
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
  pushad				; backup all register
					;
					; make sure filename starts with a /
    %ifdef _EXTENDED_ERROR_CODE_	;-----------------------------------
      mov [ext2fs.extended_error_code], dword _EXT_E_INVALID_FILENAME
    %endif				;
  cmp [esi], byte '/'			;
  jnz short .failed			;
					; load root inode
  mov ebx, edx				;----------------
  mov eax, EXT2_ROOT_INO		;
  call _load_inode_in_cache		; returns EDI = pointer to inode entry
  jc short .failed			;
					;
					; Following path to filename
					;---------------------------
					; assuming...
					; edi = pointer to inode entry
					; esi = pointer to path+filename to open
					; ebx = file descriptor
.one_level_further:			;
  lea edx, [esi + 1]			; discaring /
					; now find the file/directory name
.searching_end:				;
  inc esi				; go to next char in filename
  movzx eax, byte [esi]			; zero extend it to unicode
  cmp eax, byte '/'			; is it a directory separator?
  jz .end_located			; yah, end found
  ; TODO: insert invalid character checks
  or eax, eax				; is it zero? (null terminator)
  jnz short .searching_end		; nah, continue processing name
  					;
.end_located:				; file/dir name selected
  mov [esi], byte 0			; null-terminate it
  push eax				; backup original name separator
  push esi				; backup end of file/dir name
  mov esi, edx				; get pointer to start of file/dir name
  push edi				; backup pointer to inode buffer
  call _find_dir_entry			; find entry in current dir
  call _i_cache_unlock			; release lock on directory inode
  pop edx				; get pointer to end of file/dir name
  jc short .failed_pop1			; check for error
					;
					; match found, loading file info
					;-------------------------------
					; assuming...
					; edi = pointer to directory entry
  mov eax, [edi]			; load inode of dir entry
  mov [ebx + __dir_entry_cache.LOCK], dword 0
  call _load_inode_in_cache		;
  jc .failed_pop1			;
					;
  pop eax				; restore original name separator
  mov [edx], al				;
  test eax, eax				; was it a null termination?
  jnz short .check_not_a_file		; no, verify that match is a dir
					;
					; verify that we have a file
					;---------------------------
  mov al, [edi + 1]			; load file type
  and al, EXT2_S_IFMT>>8		; mask off uninteresting bits
  cmp al, EXT2_S_IFREG>>8		; is it a regular file?
  jz short .open_regular_file		; yes, open it
  cmp al, EXT2_S_IFLNK>>8		; did we just get a symlink?
  jz short .symlink_encountered		; yes, go process symlink
  					;
  					; nor a file nor a symlink..
					;
  push edi				;
  call _i_cache_unlock			;
					;
  jmp short .failed			;
					;
.failed_pop1:				; Failure handler, returning
  pop eax				;---------------------------
.failed:				;
  mov eax, __ERROR_FILE_NOT_FOUND__	;
.failed_use_already_provided_error:	;
  mov [esp + 28], eax			;
  popad					;
  stc					;
  retn					;
					;
.check_not_a_file:			;
  ; right now, we test only for directory attributes, but this could also
  ; be symlinks or other types.
  mov al, [edi + 1]
  and al, EXT2_S_IFMT>>8
  cmp al, EXT2_S_IFDIR>>8
  jz short .directory_identified

  cmp al, EXT2_S_IFLNK>>8	; symbolic link
  jnz short .failed
  
.symlink_encountered:
  dmej 0xE2F05111

.directory_identified:
  ; edi = directory inode
  ; edx = pointer to "/" separating current directory name of the remaining
  ;       of the filename to get

  ; TODO: check access rights

  mov esi, edx
  jmp near .one_level_further

.open_regular_file:
  ; TODO: check access rights
  mov ecx, ext2_file_descriptor_size
  push edi
  push ebx
  malloc "file descriptor"
  pop ebx
  pop esi
  jc short .failed_use_already_provided_error
  
  mov dword [edi + file_descriptor.op_table], __op_table
  mov dword [edi + file_descriptor.fs_descriptor], ebx
  mov ecx, ext2_inode_size /4
  push edi
  push esi
  add edi, byte ext2_file_descriptor.inode
  repz movsd
  call _i_cache_unlock
  pop ebx
  mov dword [ebx + ext2_file_descriptor.current_offset], 0
  mov eax, [opened_files]
  mov [ebx + ext2_file_descriptor.next_open_file], eax
  cmp eax, byte -1
  jz short .null_next_link
  mov [eax + ext2_file_descriptor.prev_open_file], ebx
.null_next_link:
  mov [ebx + ext2_file_descriptor.prev_open_file], dword -1
  mov [opened_files], ebx
  mov [esp + 16], ebx
  popad
  clc
  retn



__list:
;;
;; params:
;;--------
;;  ESI = pointer to string of the directory name to list
;;  EDI = pointer to callback function that will receive each entry of the
;;        directory listing
;;  EDX = pointer to fs descriptor
;;        (provided by ozone, not user acquired)
;;
;; returns:
;;---------
;; registers and errors as usual
;;
;; callback receives the following:
;;---------------------------------
;;  ESI = pointer to filename (valid only until the callback returns)
;;        = NULL to indicate end of directory listing
;;  EDX:EAX = file size in bytes
;;  EBX = type of file
;;        0 = standard file
;;        1 = directory
;;        2 = symbolic link
;;        3 = special device
;;
;; callback may returns:
;;----------------------
;;  CF = 0 to continue directory listing
;;  CF = 1 to abort directory listing
;;

  pushad				; backup all registers
					;
					; Extended error code if supported
%ifdef _EXTENDED_ERROR_CODE_		;---------------------------------
  mov [ext2fs.extended_error_code], dword _EXT_E_INVALID_FILENAME
%endif					;
					;
					; Make sure dir/file starts with /
					;---------------------------------
  cmp [esi], byte '/'			; check it
  jnz near .failed			; if not, fail; XXX
					;
					; Load root directory inode
					;--------------------------
  mov ebx, edx				; set ebx = fs descriptor
  mov eax, EXT2_ROOT_INO		; set inode number
  call _load_inode_in_cache		; load it in cache
  jc short .failed			; if it failed..
					;
					; Check for end of path/file name
					;--------------------------------
  cmp byte [esi + 1], byte 0		; is it null terminated?
  jz short .list_directory		; yes, list root directory
					;
					; In depth directory searching
					;-----------------------------
					; assuming:
					; edi: ptr to inode entry
					; esi: ptr to path+filename to list
					; ebx: fs descriptor
.one_level_further:			;-----------------------------
  lea edx, [esi + 1]			; start of current dir/file name
					;
					; Search end of current dir/file name
.searching_end:				;------------------------------------
  inc esi				; move to next character
  movzx eax, byte [esi]			; load char in eax
  cmp eax, byte '/'			; is it a directory separator?
  jz .end_located			; yes, end of dir/file located
					;
					; TODO: we could check for invalid char
					;
  or eax, eax				; check for null termination
  jnz short .searching_end		; if not null, continue searching end
					;
					; Search dir for current dir/file name
.end_located:				;-------------------------------------
					; assuming:
					; ESI: end of dir/file name
					; EAX: termination character
					; EDX: start of dir/file name
					; EBX: fs descriptor
					; EDI: inode of parent dir entry
					;-------------------------------------
  mov [esi], byte 0			; null terminate dir/file name
  push eax				; backup original termination
  push esi				; backup end of dir/file name
  mov esi, edx				; set esi = dir/file name
  push edx				; backup start of dir/file name
  push edi				; backup dir inode ptr
  call _find_dir_entry			; find our dir/file name
  call _i_cache_unlock			; unlock cache entry
  pop esi				; restore start of dir/file name
  pop edx				; restore end of dir/file name
  jc short .failed_pop1			; if dir/file name not found...
					;
					; Load inode of dir/file entry
					;-----------------------------
					; assuming:
					; EDI = directory entry
					; EBX = fs descriptor
					;-----------------------------
  mov eax, [edi]			; get inode number
  mov [ebx + __dir_entry_cache.LOCK], dword 0	; unlock directory entry
  call _load_inode_in_cache		; load it
  jc .failed_pop1			; in case it couldn't....
					;
					; Restore file/dir name termination
					;----------------------------------
					; assuming:
					; EDX = ptr to end of dir/file name
					;----------------------------------
  pop eax				; restore it in eax
  mov [edx], al				; set it back in dir/file name
					;
					; Test inode attributes
					;----------------------------------
  mov cl, [edi + 1]			; load inode type
  and cl, EXT2_S_IFMT>>8		; mask non-related bits
  cmp cl, EXT2_S_IFDIR>>8		; is it a dir?
  jz short .directory_identified	; yes, directory identified
					;
  cmp cl, EXT2_S_IFREG>>8		; is it a regular file?
  jz near .list_single_file		; yes, regular file identified
					;
  cmp cl, EXT2_S_IFLNK>>8		; symbolic link?
  jnz short .failed			; if not, well, we don't support it
					;
					; Follow symlink
.symlink_encountered:			;---------------
  dmej 0xE2F05111			; TODO
					;
					; Error handling
.failed_pop1:				;---------------
  pop eax				;
.failed:				;
  popad					;
  mov eax, __ERROR_FILE_NOT_FOUND__	;
  stc					;
  retn					;
					;
					; Determine if we list or continue
.directory_identified:			;---------------------------------
					; assuming:
					; EDX: pointer to end of dir name
					; EAX: termination character
					;
					; TODO: check access rights
					;
  mov esi, edx				; next dir/file name start after this 1
  test eax, eax				; was null terminated?
  jnz short .one_level_further		; no, so go one level further
					;
					; List Directory
.list_directory:			;---------------
					; assuming:
					; EDI: pointer to directory inode
					; EBX: fs descriptor
					;---------------
  pop ebp				; get pointer to callback function
  push ebp				; push it back on stack
  mov edx, edi				; set edx as pointer to dir inode data
  xor esi, esi				; set start of directory
					;
.listing_directory:			;
  cmp esi, [edx	+ ext2_inode.i_size]	; past the end of the directory?
  jae short .exit			; yes, listing completed
					;
					; Read Directory Entry
					;---------------------
					; assuming:
					; ESI: offset from start of dir file
					;      to read from
					; EBX: fs descriptor
					; EDX: inode of directory
					;---------------------
  mov eax, esi				; set the starting address to read from
  call .cache_directory_entry		; read directory entry
  jc short .exit			; couldn't read directory entry :(
					;
					; Prepare file information for listing
					;-------------------------------------
  pushad				; first backup all registers
					;
  lea esi, [edi + ext2_dir_entry.name]	; get pointer to filename
  movzx ecx, byte [edi + ext2_dir_entry.name_len]	; get filename length
  mov al, [esi + ecx]			; backup char located after dir entry
  mov [esi + ecx], byte 0		; null terminate dir/file name
  mov [esp + 28], al			; backup termination character
					;
					; Convert Ext2 file type->UUU file type
					;--------------------------------------
  mov al, [edi + ext2_dir_entry.file_type]	; get Ext2 file type
  xor ebx, ebx				; type: regular file
  cmp al, EXT2_FT_REG_FILE		; 
  jz  short .file_type_set		;
					;
  inc ebx				; type: directory file
  cmp al, EXT2_FT_DIR			;
  jz short .file_type_set		;
					;
  inc ebx				; type: symbolic link file
  cmp al, EXT2_FT_SYMLINK		;
  jz short .file_type_set		;
					;
  inc ebx				; type: device file
  cmp al, EXT2_FT_CHRDEV		;
  jz short .file_type_set		;
  cmp al, EXT2_FT_BLKDEV		;
  jz short .file_type_set		;
					;
  mov ebx, 0xFFFFFFFF			; type: unknown
					;
.file_type_set:				;
					; Acquiring dir/file size
					;------------------------
  mov eax, [edi + ext2_dir_entry.inode]	; get associated inode id
  push eax				; backup inode id for quick ref
  push ebx				; backup file type
  mov ebx, [esp + 24]			; get fs descriptor
  call _load_inode_in_cache		; load associated inode in cache
  mov eax, [edi + ext2_inode.i_size]	; get file size
  push edi				;
  call _i_cache_unlock			; unlock it (release inode lock)
  xor edx, edx				; make file size 64bits
					;
					; Call callback function to list entry
					;-------------------------------------
  pop ebx				; restore set file type
  pop edi				; restore inode id for quick ref
  call ebp				; proceed to callback function
					;
					; Terminate dir/file name as before
					;----------------------------------
  popad					; restore all registers
  movzx ecx, byte [edi + ext2_dir_entry.name_len] ; get dir/file name length
  mov [edi + ecx + ext2_dir_entry.name], al ; restore dir/file name termination
					;
					; Proceed to next directory entry
.check_next_entry:			;--------------------------------
  movzx edi, word [edi + ext2_dir_entry.rec_len]; read dir record length
  add esi, edi				; add record length to current pointer
  jmp short .listing_directory		; proceed to next entry
					;
					; Listing completed, send null file
.exit:					;----------------------------------
  push edx				; directory inode buffer
  call _i_cache_unlock			; free directory inode lock
					;
  xor esi, esi				; null filename
  xor ebx, ebx				; null file type (make 0 then -1)
  xor edx, edx				; null size
  xor eax, eax				; ..
  dec ebx				; make file type -1
  call ebp				; call callback function
					;
					; Listing terminated, returning
					;------------------------------
  popad					; restore original regs
  clc					; indicate success
  retn					; return
					;
					; Load directory entry in cache
.cache_directory_entry:			;------------------------------
  pushad				; backup all regs
  lea edi, [ebx + __dir_entry_cache]	; point to dir entry buffer
  mov ecx, ext2_dir_entry_size		; set the size of the read
  call _read_file_sub_section		; read the entry
  mov [esp], edi			; set pointer to entry
  popad					; restore all regs
  retn					; return with caller's error code
					;
					; Listing requested on a single file
.list_single_file:			;-----------------------------------
  pop ebp				; acquire pointer to callback function
  push ebp				; set back original edi
					;
  					; assuming esi points to filename
  mov eax, [edi + ext2_inode.i_size]	; read file size
  push edi				;
  call _i_cache_unlock			; unlock it
  xor edx, edx				; set upper file size to 0
  xor ebx, ebx				; set file type to regular file
  push edi				; backup pointer to inode entry
  push ebp				; backup caller's callback function
  call ebp				; caller's callback function
  pop ebp				; restore pointer to caller
  xor esi, esi				; end of listing indication
  xor ebx, ebx				;
  xor eax, eax				;
  xor edx, edx				;
  dec ebx				;
  call ebp				; caller's callback function
  					;
					; Unlock cache entry
					;-------------------
  pop esi				; pointer to cache entry to unlock
  pop ebx				; fs descriptor
					;
					; Return to caller
					;-----------------
  popad					; restore all registers
  clc					; clear any error flag
  retn					;
;------------------------------------------------------------------------------




__check_permissions:
  dmej 0xE2F000F3



__close:
;------------------------------------------------------------------------------
;
; parameters:
;------------
; ebx = file descriptor
;
; returns:
;---------
; cf = 0, successful
;  eax = (unmodified)
;  ebx = (unmodified)
;  ecx = (unmodified)
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
; cf = 1, failed
;  eax = error code
;  ebx = (unmodified)
;  ecx = (unmodified)
;  edx = (unmodified)
;  esi = (unmodified)
;  edi = (unmodified)
;  esp = (unmodified)
;  ebp = (unmodified)
;
 
  pushad
  mov eax, [ebx + ext2_file_descriptor.prev_open_file]
  mov ecx, [ebx + ext2_file_descriptor.next_open_file]
  cmp eax, byte -1
  jz short .update_root

  mov [eax + ext2_file_descriptor.next_open_file], ecx
  jmp short .update_next_file

.update_root:
  mov [opened_files], ecx
  
.update_next_file:
  cmp ecx, byte -1
  jz short .null_link

  mov [ecx + ext2_file_descriptor.prev_open_file], eax

.null_link:
  ; TODO: check if any write access is pending
  mov eax, ebx
  externfunc mem.dealloc
  jc short .internal_failure
  popad
  retn

.internal_failure:
  popad
  mov eax, __ERROR_INTERNAL_FAILURE__
  stc
  retn






__read:
;------------------------------------------------------------------------------
;
; note, if EAX <> ECX on return, and CF = 0, EndOfFile reached
;
; parameters:
;------------
; ebx = file descriptor
; ecx = number of bytes to read
; edi = destination
;
; returns:
;---------
; cf = 0, successful
;   eax = number of bytes read
;   ebx = (unmodified)
;   ecx = (unmodified)
;   edx = (unmodified)
;   esi = (unmodified)
;   edi = (unmodified)
;   esp = (unmodified)
;   ebp = (unmodified)
;
; cf = 1, failed
;   eax = error code
;   ebx = (unmodified)
;   ecx = (unmodified)
;   edx = (unmodified)
;   esi = (unmodified)
;   edi = (unmodified)
;   esp = (unmodified)
;   ebp = (unmodified)
; 
  pushad
  mov eax, [ebx + ext2_file_descriptor.current_offset]
  lea edx, [ebx + ext2_file_descriptor.inode]

  ; make sure we don't read past the end of file
  mov esi, [edx + ext2_inode.i_size]
  cmp eax, esi
  jae short .eof

  ; check requested read size, make sure we won't read past end of file
  add ecx, eax
  sub ecx, esi
  jbe short .partial_read

  ; read will past EOF, adjust it
  sub ecx, eax

.partial_read:
  add ecx, esi
 
  sub ecx, eax
  mov ebx, [ebx + file_descriptor.fs_descriptor]
  push ecx
  call _read_file_sub_section
  pop ecx
  jc short .failed

  mov [esp + 28], ecx
  popad
  add [ebx + ext2_file_descriptor.current_offset], eax
  clc
  retn

.failed:
  mov [esp+28], eax
  popad
  retn

.eof:
  popad
  mov eax, __ERROR_FS_END_OF_FILE_REACHED__
  stc
  retn



__write:
  dmej 0xE2F000F6

__raw_read:
  dmej 0xE2F000F7

__raw_write:
  dmej 0xE2F000F8

__seek_cur:
;; parameters:
;;------------
;; EDX:EAX = distance to seek, signed
;; EBX = pointer to file handle
;;
;; returns:
;; CF = 0, successful
;;   EDX:EAX = new offset from start of file
;; errors as usual
  test edx, edx
  jz short .limit_check0_passed
  inc edx
  jz short .limit_check0_passed

.below_file_start:
.above_max_file_limit:
.write_access_not_available:
  mov eax, __ERROR_FS_ACCESS_DENIED__
  stc
  retn

.limit_check0_passed:

  ;; add offset 
  ;;
  add eax, [ebx + ext2_file_descriptor.current_offset]
  jo short .above_max_file_limit	; above 4GB?
  jc short .below_file_start		; below 0?

.seek_common:
  ;; EAX = new offset

  ;; check if seek is past current end of file
  ;;
  cmp eax, [ebx + ext2_file_descriptor.inode + ext2_inode.i_size]
;;  jb short .completed

  ;; TODO: when write access is completed, this part should extend the file
  ;; to fit the requested size
  jae short .write_access_not_available

.completed:
  ;; save new offset in file descriptor and exit without error
  ;;
  mov [ebx + ext2_file_descriptor.current_offset], eax
  xor edx, edx
  clc
  retn


__seek_start:
  test edx, edx
  jnz short __seek_cur.above_max_file_limit

  jmp short __seek_cur.seek_common


__seek_end:
  or  edx, edx
  jz short .limit0_checked
  inc edx
  jnz short __seek_cur.above_max_file_limit

  ; displacement is negative, make sure it isn't larger than file size
  sub eax, dword [ebx + ext2_file_descriptor.inode + ext2_inode.i_size]
  jnbe short __seek_cur.below_file_start

  neg eax
  jmp short __seek_cur.completed

.limit0_checked:
  add eax, dword [ebx + ext2_file_descriptor.inode + ext2_inode.i_size]
  jo short __seek_cur.above_max_file_limit
  
  jmp short __seek_cur.seek_common

  

__link:
  dmej 0xE2F000FC

__unlink:
  dmej 0xE2F000FD

__create:
  dmej 0xE2F000FE

__rename:
  dmej 0xE2F000FF

__copy:
  dmej 0xE2F00F10

__truncate:
  dmej 0xE2F00F11

__attrib:
  dmej 0xE2F00F12

__error:
  mov eax, -1
  stc
  retn





%ifdef _EXT2_MONITORING_
globalfunc ext2_dev.display_lock_status, 5000
  pushad
  mov esi, [lastmount_fs_data]
  test esi, esi
  jnz short .proceed
  popad
  retn

.proceed:
  ; displaying inode cache
  lea ebx, [esi + __inodes_cached]
  mov ecx, PERFORMANCE_INODES_CACHED
  mov esi, str_dbg.listing_inodes
  externfunc sys_log.print_string
.displaying_inodes:
  mov esi, str_dbg.inode
  mov edx, ebx
  externfunc sys_log.print_string
  externfunc sys_log.print_hex
  mov esi, str_dbg.inode_id
  mov edx, [ebx]
  externfunc sys_log.print_string
  externfunc sys_log.print_hex
  mov esi, str_dbg.lock_count
  mov edx, [ebx + cached_inode.locks]
  externfunc sys_log.print_string
  externfunc sys_log.print_hex
  mov esi, str_dbg.last_access
  mov edx, [ebx + cached_inode.last_access]
  externfunc sys_log.print_string
  externfunc sys_log.print_hex
  mov edx, [ebx + cached_inode.buffer_ptr]
  mov esi, str_dbg.buffer
  externfunc sys_log.print_string
  externfunc sys_log.print_hex
  externfunc sys_log.terminate
  add ebx, byte cached_inode_size
  loop .displaying_inodes
.bypass_inodes:
  ; inodes displayed

  ; returning
popad
  retn
%endif



section .data

%ifdef _EXT2_MONITORING_
lastmount_fs_data: dd 0

str_dbg:
.buffer: db " B: ",1
.i_cache_unlock: db "[EXT2] Cache UnLock applied on: ",1
.i_cache_unlock_failed: db "[EXT2] Cache UnLock Failed for: ",1
.i_cache_unlock_success: db "[EXT2] Cache UnLock Succeeded for: ",1
.inode: db "[EXT2] (",1
.inode_id: db ") I: ",1
.last_access: db " LA: ",1
.listing_inodes: db "[EXT2] DEBUG: Listing Inodes..",0
.lock_count: db " LC: ",1
.locked_inode: db "[EXT2] Locked inode: ",1
align 4, db 0
%endif

exported_fs_data_start:

ext2fs_descriptor: istruc fs_descriptor
  at fs_descriptor.open,	dd __open
  at fs_descriptor.list,	dd __list
  at fs_descriptor.check_perm,	dd __check_permissions
  iend

super_block:
  ldd s_frag_size		; size of fragment in bytes
  ldd s_block_size		; size of block in bytes
  ldd s_frags_per_block		; number of fragments per block
  ldd s_inodes_per_block	; number of inodes per block
  ldd s_sectors_per_block	; number of sectors per block
  ldd s_frags_per_group		; number of fragments in a group
  ldd s_blocks_per_group	; number of blocks in a group
  ldd s_inodes_per_group	; number of inodes per group
  ldd s_itb_per_group		; number of inode table blocks per group
  ldd s_gdb_count		; number of group descriptor blocks
  ldd s_desc_per_block		; number of group descriptors per block
  ldd s_groups_count		; number of groups in the fs
  ldd s_sbh			; pointer to buffer holding superblock
  ldd s_group_desc		; pointer to buffer holding group descriptors
  ldd s_mount_state		; status of mounted file system
  ldd s_mount_opt		; mount options
  ldd s_resuid			; user id of reserved block
  ldd s_resgid			; group id of reserved block
  ldd s_addr_per_block_bits	; log2(block_size)
  ldd s_desc_per_block_bits	; log2(block_size/ext2_block_descriptor_size)
  ldd s_inode_size		; size of inode structure
  ldd s_first_ino		; block number of first inode
  ldd s_ind_limit		; block_size / 4
  ldd s_bind_limit		; (block_size / 4) * s_ind_limit
  ldd s_tind_limit		; (block_size / 4) * s_bind_limit
.size equ $-super_block

__device_file_handle equ $-exported_fs_data_start
device_file_handle: dd -1

__disk_op_table equ $-exported_fs_data_start
disk_op_table: dd -1

itb_cached:
__itb_cached equ $-exported_fs_data_start
times PERFORMANCE_ITB_CACHED*cached_itb_size db 0

blocks_cached:
__blocks_cached equ $-exported_fs_data_start
times PERFORMANCE_BLOCKS_CACHED*cached_block_size db 0

inodes_cached:
__inodes_cached equ $-exported_fs_data_start
times PERFORMANCE_INODES_CACHED*cached_inode_size db 0

dir_entry_cache:
__dir_entry_cache equ $-exported_fs_data_start
times ext2_dir_entry_size db 0
__dir_entry_cache.LOCK equ $-exported_fs_data_start
dir_entry_cache.LOCK: dd 0


align 4, db 0
exported_fs_data_end:


;=----------------------------------------------------------------------------=
;=----------------------------------------------------------------------------=
section .c_init
global _start
_start:
;=----------------------------------------------------------------------------=
;=----------------------------------------------------------------------------=

  mov edx, __FS_TYPE_EXT2__		; our fs type, as register with ozone
  mov eax, _mount			; pointer to our mount function
  externfunc vfs.register_fs_driver	; register our fs type
  retn








;=----------------------------------------------------------------------------=
;=----------------------------------------------------------------------------=
section .data
;=----------------------------------------------------------------------------=
;=----------------------------------------------------------------------------=
cache_operations_counter: dd 0

opened_files: dd -1

__op_table:	istruc file_op_table
at file_op_table.close,		dd __close
at file_op_table.read,		dd __read
at file_op_table.write,		dd __write
at file_op_table.raw_read,	dd __raw_read
at file_op_table.raw_write,	dd __raw_write
at file_op_table.seek_cur,	dd __seek_cur
at file_op_table.seek_start,	dd __seek_start
at file_op_table.seek_end,	dd __seek_end
at file_op_table.read_fork,	dd __error
at file_op_table.write_fork,	dd __error
at file_op_table.link,		dd __link
at file_op_table.unlink,	dd __unlink
at file_op_table.create,	dd __create
at file_op_table.rename,	dd __rename
at file_op_table.copy,		dd __copy
at file_op_table.truncate,	dd __truncate
		iend


%ifdef _EXTENDED_ERROR_CODE_
 %define ext2fs.extended_error_code.VID 1000
 globalfunc ext2fs.extended_error_code
 dd 0
%endif
