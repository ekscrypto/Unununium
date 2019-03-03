;; Irony RamDisk driver		Copyright (C) 2001-2002 Lukas Demetz
;; Ver. 2 - static		Distributed under the BSD license
;;
;; 
;;
;; status:
;; -------
;; testing
;;
;; ToDO:
;; -------
;;	[ ] make dinamic version
;;	[ ] More error-handling
;;
;; Last change: 27-dec-2001 	Lukas
;;

[bits 32]

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_

%define _sector_size_		512	; <-- Size of a sector
%define	_ramd_size_		50	; <-- Amount of sectors

;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc local_file_descriptor
  .global:	resb file_descriptor_size
endstruc

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init

init:
  jmp init.start

  .dev_name:	db "/ramd/0"

.err_mem:
  lprint {"irony ramd: insufficient memory to allocate RamDisk",0xa}, FATALERR
  stc
  jmp short .end	

.start:
  pushad
  ; Alloc memory
  mov	ecx, _sector_size_*_ramd_size_
  externfunc 	mem.alloc
  jc	.err_mem
  mov	[base], edi
  
  ; register with devfs
  mov ebx, _open
  mov esi, .dev_name
  externfunc devfs.register

  lprint {"irony ramd: version $Revision: 1.1 $ loaded",0xa}, LOADINFO
  dbg_print "RamDisk size: ",1
  dbg_print_hex edi
  dbg_print ".",0
  clc
.end:
  popad
  
  ;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

base: 	dd 0
;                                           -----------------------------------
;                                                                   _write_data
;==============================================================================

 

;                                           -----------------------------------
;                                                                    __raw_read
;==============================================================================

__raw_read:
;>
;; parameters:
;; -----------
;; EDX:EAX = 64 bit LBA
;; ECX = number of sectors to read
;; EDI = pointer to buffer to put data in
;; EBX = pointer to file handle
;;
;; returned values:
;; ----------------
;; EDI = unmodified
;; errors as usual
;<

dbg_print "raw reading; LBA: ",1
dbg_print_hex eax
dbg_print "  count: ",1
dbg_print_hex ecx
dbg_term_log

  pushad

  test edx, edx
  jnz .too_big
  test edi, edi
  jnz .too_big
  test ecx, ecx
  jnz .end

  ; Step 1: Check if we fit into the Space
  
  mov	edx, ecx
  add	edx, eax
  cmp	edx, (_ramd_size_ + 1)
  ja	.err_toolarge
  
  ; Step 2: Copy the requested amount of bytes
  mov	esi, dword [base]
  mov	edx, eax
  shl	edx, 9		; * 512
  add	esi, edx	; Esi = Starting address
  
  			; EDI = Destination
  			
  	; Allright, we use movsd (4 bytes at once), so gonna multiply ecx by 7
  shl	ecx, 7
  cld
  dbg_print "raw reading; Starting...",0
  rep	movsd
  dbg_print "raw reading; Done!",0
  ; Step 3: Cleanup
.end:
  
  popad
  clc
  retn
  
.err_toolarge:
.too_big:
  popad
  mov eax, __ERROR_INVALID_PARAMETERS__
  stc
  retn

;                                           -----------------------------------
;                                                                   __raw_write
;==============================================================================

__raw_write:
;>
;; parameters:
;; -----------
;; EDX:EAX = 64 bit LBA
;; ECX = number of sectors to write
;; ESI = pointer to buffer to read data from
;; EBX = file handle
;<

dbg_print "raw writing",0
pushad

  test edx, edx
  jnz .too_big
  test edi, edi
  jnz .too_big
  test ecx, ecx
  jnz .end

  ; Step 1: Check if we fit into the Space
  
  mov	edx, ecx
  add	edx, eax
  cmp	edx, _ramd_size_+1
  ja	.err_toolarge
  
  ; Step 2: Copy the requested amount of bytes
  mov	edi, dword [base]
  mov	edx, eax
  shl	edx, 9		; * 512
  add	edi, edx	; Edi = Starting address
  
  			; ESI = Destination
  			
  	; Allright, we use movsd (4 bytes at once), so gonna multiply ecx by 7
  shl	ecx, 7
  cld
  dbg_print "raw writing; Starting...",0
  rep	movsd
  dbg_print "raw writing; Done!",0
  ; Step 3: Cleanup
.end:
  
  popad
  clc
  retn
  
.err_toolarge:
.too_big:
  popad
  mov eax, __ERROR_INVALID_PARAMETERS__
  stc
  
retn



;                                           -----------------------------------
;                                                                       __close
;==============================================================================

__close:
  ; for now there's really nothing to do
  clc
  retn

;                                           -----------------------------------
;                                                               __not_supported
;==============================================================================

_error:
xor eax, eax
dec eax
stc
retn

__not_supported:
mov eax, __ERROR_OPERATION_NOT_SUPPORTED__
stc
retn


;                                           -----------------------------------
;                                                                         _open
;==============================================================================

_open:
;>
;; parameters:
;; -----------
;; EBP = same value as EBP we used when we registered, but we don't use this
;; EDX = ptr to fs descriptor
;;
;; returned values:
;; ----------------
;; EBX = ptr to file handle
;; errors as usual
;<

  mov ecx, local_file_descriptor_size
  push edx
  externfunc mem.alloc

  mov ebx, edi
  mov dword[edi+file_descriptor.op_table], our_op_table
  pop dword[edi+file_descriptor.fs_descriptor]

  retn

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data
align 4, db 0


our_file_descriptor: istruc local_file_descriptor
  at local_file_descriptor.global
    istruc file_descriptor
      at file_descriptor.op_table,	dd our_op_table
    iend
iend

our_op_table: istruc file_op_table
  at file_op_table.close,	dd __close
  at file_op_table.read,	dd __not_supported
  at file_op_table.write,	dd __not_supported
  at file_op_table.raw_read,	dd __raw_read
  at file_op_table.raw_write,	dd __raw_write
  at file_op_table.seek_cur,	dd __not_supported
  at file_op_table.seek_start,	dd __not_supported
  at file_op_table.seek_end,	dd __not_supported
  at file_op_table.read_fork,	dd __not_supported
  at file_op_table.write_fork,	dd __not_supported
  at file_op_table.link,	dd __not_supported
  at file_op_table.unlink,	dd __not_supported
  at file_op_table.create,	dd __not_supported
  at file_op_table.rename,	dd __not_supported
  at file_op_table.copy,	dd __not_supported
  at file_op_table.truncate,	dd __not_supported
  at file_op_table.attrib,	dd __not_supported
iend


