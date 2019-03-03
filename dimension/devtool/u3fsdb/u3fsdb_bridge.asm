;; Unununium File System Development Bench Bridge
;; Copyright (C) 2001-2002, Dave Poirier
;; Distributed under the modified BSD License
;;
;; System bridge between the guest fs cell and the dev bench
;;
;; note: all the uuu specific includes such as the vid/*.inc are pre-included
;;       by the makefile.


section .text

;; Bridging to dev bench
global u3fsdb_bridge_init_guest		;; int . (void)
global u3fsdb_bridge_mount		;; void . (char *, char *)
;; Bridging from dev bench
extern u3fsdb_fclose			;; uint . (char *)
extern u3fsdb_fopen			;; uint . (char *)
extern u3fsdb_fread			;; uint . (void *, size_t, size_t)
extern u3fsdb_free			;; uint . (void *)
extern u3fsdb_fwrite			;; uint . (void *, size_t, size_t)
extern u3fsdb_malloc			;; void* . (size_t)
extern u3fsdb_mountpoint_registration	;; uint . (char *)
extern u3fsdb_report			;; void . (char *, uint, char *)
extern u3fsdb_urgent_exit		;; void . (void)
extern u3fsdb_call_trace		;; void . (uint 8 times, char *)
extern u3fsdb_call_ltrace		;; void . (uint 9 times)

;; Bridging from guest fs
extern __init_entry_point
;; Bridging to guest fs is done via globalfunc


%macro trace_in 1.nolist
  push dword %1
  pushad
  call u3fsdb_call_trace
  popad
  add esp, byte 4
%endmacro

%macro trace_out 1.nolist
  push byte %1
  pushad
  call u3fsdb_call_ltrace
  popad
  add esp, byte 4
%endmacro


u3fsdb_bridge_init_guest:
;;=============================================================================
  push ebp				; backup frame pointer
  call __init_entry_point		;
  pop ebp				; restore frame pointer
  jnc short .successful			;
					;
					;>-failed!
  xor eax, eax				; set return value to 0
  retn					; return to fsdb
					;
.successful:				;>-succeeded!
  mov eax, [fs_type]			; set return value to fs id
  retn					; return to fsdb
;;-----------------------------------------------------------------------------




u3fsdb_bridge_mount:
;;=============================================================================
  cmp dword [fs_mount_function], byte 0	; make sure the mount point is reg'd
  jz short .early_exit			;
					;
  push ebp				; backup frame pointer
					;
  mov esi, [esp + 12]			;
  mov eax, [esp + 8]			;
  call [fs_mount_function]		;
  push byte 0				;
  jnc short .mount_success		;
					;
  push eax				;
  push dword failed_mount		;
.common_exit:				;
  call u3fsdb_report			;
  add esp, byte 12			;
					;
  pop ebp				;
.early_exit:				;
  retn					;
					;
.mount_success:				;
  push byte 0				;
  push dword success_mount		;
  jmp short .common_exit		;
;;-----------------------------------------------------------------------------




globalfunc vfs.register_fs_driver
;;=============================================================================
  trace_in func_vfs_register_fs_driver	;
					; check if fs is already registered
					;----------------------------------
  cmp dword [fs_type], byte 0		; if fs_type is set, it is..
  jnz short .fs_driver_already_registered; ehehe, at least we catched it ;)
					;
					; register the file system with fsdb
					;-----------------------------------
  pushad				; backing up all regs, C is nasty..
  push byte 0				; char *extra_info=NULL
  push edx				; unsigned int supplement_code
  push dword success_fs_registered	; char *msg
  call u3fsdb_report			; fsdb fs registered notification
  add esp, byte 12			; destroy C params
  popad					; restore all regs
					;
					; register file system locally
					;-----------------------------
  mov [fs_type], edx			; set file system type
  mov [fs_mount_function], eax		; backup pointer to function
  trace_out 0				;
  clc					; clear error flag
  retn					; return to guest fs
					;
					; fs already registered
.fs_driver_already_registered:		;----------------------
					;
					; report error to fsdb
					;---------------------
  pushad				; backup all regs, C is nasty!
  push byte 0				; char *extra_info=NULL
  push eax				; unsigned int supplement_code=fs_type
  push dword error_fs_registration_failed; char *msg
  call u3fsdb_report			; report it to fsdb
  add esp, byte 12			; clear C params from stack
  popad					; restore all regs
  					;
  mov eax, __ERROR_FS_TYPE_ALREADY_REGISTERED__; error code to return to fs
  trace_out 1				;
  stc					; set error flag
  retn					; return to guest fs
;;-----------------------------------------------------------------------------



globalfunc mem.alloc
;;=============================================================================
  trace_in func_mem_alloc			;
						; request memory from fsdb
						;-------------------------
  pushad					; backup all regs, C is nasty!
  push ecx					; size requested
  call u3fsdb_malloc				; get some mem from fsdb
  pop edi					; destroy C param
  mov [esp], eax				; backup returned value
  popad						; restore all regs + value
						;
  mov eax, ecx					; return original size
  add ecx, byte 63				; compute 64bytes aligned value
  and ecx, byte -64				;  ..
  ; edi = allocated block, null if failed,
  ; ecx = allocated size (64 bytes aligned)
  ; eax = requested size
  test edi, edi					; check if alloc failed
  jz short .failed				; edi = 0, it did (=NULL)
						;
  add edi, byte 63				;
  and edi, byte -64				;
						;
						; alloc successful!
						;------------------
  trace_out 0					;
  clc						; clear error flag
  retn						; return
						;
						; fsdb returned null
.failed:					;-------------------
  mov eax, __ERROR_INSUFFICIENT_MEMORY__	; set error code
  trace_out 0					;
  stc						; set error flag
  retn						; return to guest fs
;------------------------------------------------------------------------------




globalfunc mem.dealloc
;;=============================================================================
  trace_in func_mem_dealloc			;
						; free up some mem with fsdb
						;---------------------------
  pushad					; backup all regs, C is nasty!
  push eax					; void *buffer
  call u3fsdb_free				; call fsdb and see how it goes
  pop ecx					; destroy the C param
  test eax, eax					; test the returned value
  popad						; restore all registers
						;
						; dealloc successful!
						;--------------------
  trace_out 0					;
  clc						; clear any erro flag
  retn						; return to guest fs
						;
						; fsdb said block is invalid
.failed:					;---------------------------
  mov eax, __ERROR_INVALID_PARAMETERS__		; set error code
  trace_out 1					;
  stc						; set error flag
  retn						; return to guest fs
;;-----------------------------------------------------------------------------




globalfunc vfs.open
;;=============================================================================
  trace_in func_vfs_open			;
						; send open request to fsdb
						;--------------------------
  pushad					; backup all regs, nasty C!
  push esi					; char *filename
  call u3fsdb_fopen				; defer to fsdb to give us ok
  pop esi					; clear off C params
  test eax, eax					; test returned value
  popad						; restore all regs
  jnz short .failed				;
						;
						; fsdb said it was all fine!
						;---------------------------
  mov ebx, device_access_file_desc		; set file_descriptor
  trace_out 0					;
  clc						; clear error flag
  retn						; return to guest fs
						;
						; fsdb said invalid file!
.failed:					;------------------------
  mov eax, __ERROR_FS_INVALID_FILENAME__	; set error code
  trace_out 1					;
  stc						; set error flag
globalfunc debug.diable.dword_out		;
  retn						; return to guest fs
;;-----------------------------------------------------------------------------





globalfunc vfs.register_mountpoint
;;=============================================================================
  trace_in func_vfs_register_mountpoint	;
  push edx				; backup fs descriptor
					;
					; Query fsdb for mountpoint validity
					;-----------------------------------
  push esi				; char *mountpoint
  call u3fsdb_mountpoint_registration	; validate mountpoint
  pop esi				; destroy C param
					;
  pop edx				; restore fs descriptor pointer
					;
  test eax, eax				; check returned code, 0=ok, 1=failed
  jnz short .registration_failed	; if it's 1... return an error
					;
  mov [guest_fs_descriptor], edx	; set the fs descriptor
  trace_out 0				;
  clc					; clear any error flag
  retn					; return
					;
					; dev bench said to return an error!
.registration_failed:			;-----------------------------------
  mov eax, __ERROR_FILE_EXISTS__	; set error code
  mov [guest_fs_descriptor], dword 0	;
  trace_out 1				;
  stc					; set error flag
  retn					; return to guest fs
;;-----------------------------------------------------------------------------




close_device:
;;=============================================================================
  trace_in func_close				;
						; ask fsdb to close device
						;-------------------------
  pushad					; backup all regs, nasty C!
  call u3fsdb_fclose				; ask fsdb for closing device
  test eax, eax					; check returned value
  popad						; restore all regs
  jnz short .failed				; if not 0, file was closed
						;
						; file now closed!
						;-----------------
  trace_out 0					;
  clc						; clear error flag
  retn						; return to guest fs
						;
						; fsdb said file was close
.failed:					;-------------------------
  mov eax, __ERROR_FILE_NOT_FOUND__		; set error code
  trace_out 1					;
  stc						; set error flag
  retn						; return to guest fs
;;-----------------------------------------------------------------------------




raw_read_device:
;;=============================================================================
  trace_in func_raw_read			;
						;
  cmp ebx, device_access_file_desc		;
  jz short .proceed				;
						;
  mov eax, __ERROR_FILE_NOT_FOUND__		;
  trace_out 1					;
  stc						;
  retn						;
						;
.proceed:					;
  test edx, edx					;
  jnz short .failed				;
						;
  pushad					;
  push ecx					;
  push eax					;
  push edi					;
  call u3fsdb_fread				;
  add esp, byte 12				;
  test eax, eax					;
  popad						;
  jnz short .failed				;
						;
  trace_out 0					;
  clc						;
  retn						;
						;
.failed:					;
  mov eax, __ERROR_FS_DAMAGED_FILE__		;
  trace_out 1					;
  stc						;
  retn						;
;;-----------------------------------------------------------------------------




raw_write_device:
;;=============================================================================
  trace_in func_raw_read			;
						;
  cmp ebx, device_access_file_desc		;
  jz short .proceed				;
						;
  mov eax, __ERROR_FILE_NOT_FOUND__		;
  trace_out 1					;
  stc						;
  retn						;
						;
.proceed:					;
  test edx, edx					;
  jnz short .failed				;
						;
  pushad					;
  push ecx					;
  push eax					;
  push esi					;
  call u3fsdb_fwrite				;
  add esp, byte 12				;
  test eax, eax					;
  popad						;
  jnz short .failed				;
						;
  trace_out 0					;
  clc						;
  retn						;
						;
.failed:					;
  mov eax, __ERROR_FS_DAMAGED_FILE__		;
  trace_out 1					;
  stc						;
  retn						;
;;-----------------------------------------------------------------------------
  trace_in func_raw_write
  trace_out 1
  stc
  retn
;;-----------------------------------------------------------------------------





unsupported_yet:
illegal_operation:
  call u3fsdb_urgent_exit
  jmp short $



section .data

fs_type: dd 0
fs_mount_function: dd 0
guest_fs_descriptor: dd 0

device_access_file_desc:
  istruc file_descriptor
  at file_descriptor.op_table, dd device_access_op_table
  at file_descriptor.fs_descriptor, dd device_access_fs_desc
  iend

device_access_op_table:
  istruc file_op_table
  at file_op_table.close, dd close_device
  at file_op_table.read, dd illegal_operation
  at file_op_table.write, dd illegal_operation
  at file_op_table.raw_read, dd raw_read_device
  at file_op_table.raw_write, dd raw_write_device
  at file_op_table.seek_cur, dd illegal_operation
  at file_op_table.seek_start, dd illegal_operation
  at file_op_table.seek_end, dd illegal_operation
  at file_op_table.read_fork, dd illegal_operation
  at file_op_table.write_fork, dd illegal_operation
  at file_op_table.link, dd illegal_operation
  at file_op_table.unlink, dd illegal_operation
  at file_op_table.create, dd illegal_operation
  at file_op_table.rename, dd illegal_operation
  at file_op_table.copy, dd illegal_operation
  at file_op_table.truncate, dd illegal_operation
  at file_op_table.attrib, dd illegal_operation
  iend

device_access_fs_desc:
  istruc fs_descriptor
  at fs_descriptor.open, dd illegal_operation
  at fs_descriptor.list, dd illegal_operation
  at fs_descriptor.check_perm, dd illegal_operation
  iend

error_fs_registration_failed:
  db "error: fs registration failed.",0
failed_mount:
  db "error: fs mount function returned failure with error code",0
success_fs_registered:
  db "successfully registered fs",0
success_mount:
  db "fs mount function returned success",0

func_vfs_register_fs_driver:
  db "vfs.register_fs_driver",0
func_vfs_register_mountpoint:
  db "vfs.register_mountpoint",0
func_vfs_open:
  db "vfs.open",0
func_raw_read:
  db "file_op_table.raw_read",0
func_raw_write:
  db "file_op_table.raw_write",0
func_close:
  db "file_op_table.close",0
func_mem_alloc:
  db "mem.alloc",0
func_mem_dealloc:
  db "mem.dealloc",0
