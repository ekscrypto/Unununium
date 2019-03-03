;; $Header: /cvsroot/uuu/uuu/src/cells/storage/seaborgium/seaborgium.asm,v 1.21 2001/12/10 16:58:27 instinc Exp $
;; Seaborgium cell			Copyright 2001 Phil Frost
;; A tempoary ramdisk			Distrubited under the BSD license
;;
;; status:
;; -------
;; highly hacked; currently designed only to give a minimal, one disk, totally
;; worthless FS.

[bits 32]

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_
%define _RAMDISK_SIZE_ 2000000	; 2MB ( base 10 :P )

;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc local_file_descriptor
  .global:	resb file_descriptor_size
  .pos:		resd 1
endstruc

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init

jmp start

s_malloc_error:	db "[Seaborgium] Error allocating memory for ramdisk",0
s_operational:	db "[Seaborgium] Initialization completed ($Revision: 1.21 $)",0
s_device:	db "/rd/0",0

malloc_error:
mov esi, s_malloc_error
externfunc sys_log.print_string
jmp finished

start:
pushad

; allocate memory for disk ---===---
mov ecx, _RAMDISK_SIZE_
xor edx, edx
externfunc mem.alloc
jc malloc_error
mov [p_disk], edi

dbg_print "ramdisk created at 0x",1
%ifdef _DEBUG_
  push edx
  mov edx, edi
  externfunc hex_out, system_log
  pop edx
  externfunc terminate_log, system_log
%endif ; _DEBUG_

; register with devfs ---===---
mov ebx, _open
mov esi, s_device
externfunc devfs.register

mov esi, s_operational
externfunc sys_log.print_string

finished:
popad

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                        __read
;==============================================================================

__read:
;>
;; parameters:
;; -----------
;; ECX = number of bytes
;; EDI = pointer to buffer to put data in
;; EBX = file handle
;;
;; returned values:
;; ----------------
;; EDI = unchanged
;; errors as usual
;<

  dbg_print "reading",0

  mov eax, [ebx+local_file_descriptor.pos]
.engage:		; __raw_read uses this
  mov esi, eax
  add esi, [p_disk]	; set up the source

; check to see if we can read that much
  add eax, ecx
  cmp eax, _RAMDISK_SIZE_
  ja near _too_big

; engage! ---===---
  push edi
  rep movsb	; could probally be better with movsd, but this is a hack...
  pop edi

  clc
  retn

;                                           -----------------------------------
;                                                                       __write
;==============================================================================

__write:
;>
;; parameters:
;; -----------
;; ECX = number of bytes
;; ESI = pointer to buffer to read data from
;; EBX = file handle
;;
;; returned values:
;; ----------------
;; errors as usual
;<

mov eax, [ebx+local_file_descriptor.pos]
.engage:		; __raw_write uses this

; calc the abs. pointer to where we write to ---===---
mov edi, eax
add edi, [p_disk]

; check to see if they write too much ---===---
add eax, ecx
cmp eax, _RAMDISK_SIZE_
ja _too_big

; engage! ---===---
dbg_print "writing to 0x",1
%ifdef _DEBUG_
  push edx
  mov edx, edi
  externfunc hex_out, system_log
  pop edx
  externfunc terminate_log, system_log
%endif	; _DEBUG_

rep movsb

retn

;                                           -----------------------------------
;                                                                    __raw_read
;==============================================================================

__raw_read:
;>
;; reads as if this was a disk with 512b sector size
;;
;; parameters:
;; -----------
;; EDX:EAX = 64 bit LBA
;; ECX = number of sectors to read
;; EDI = pointer to buffer to put data in
;; EBX = pointer to file handle
;;
;; returned values:
;; ----------------
;; EDI = unchanged
;; errors as usual
;<

dbg_print "raw reading",0

  test edx, edx
  jnz _error

  test eax, 0xff800000
  jnz _error

  shl eax, 9	; mul by 512
  shl ecx, 9
  jmp __read.engage

;                                           -----------------------------------
;                                                                   __raw_write
;==============================================================================

__raw_write:
;>
;; writes as if this was a disk with 512b sector size
;;
;; parameters:
;; -----------
;; EDX:EAX = 64 bit LBA
;; ECX = number of sectors to read
;; ESI = pointer to buffer to read data from
;; EBX = file handle
;<

  test edx, edx
  jnz _error

  test eax, 0xff800000
  jnz _error

  shl eax, 9	; mul by 512
  shl ecx, 9

  jmp __write.engage

;                                           -----------------------------------
;                                                                  __seek_start
;==============================================================================
  
__seek_start:
;>
;; moves the position pointer of a file to specified point. This flavor moves
;; to an absloute position relitive to the start of the file.
;;
;; parameters:
;; -----------
;; EDX:EAX = position to seek to, unsigned
;; EBX = file handle
;;
;; returned values:
;; ----------------
;; EBX = unchanged
;; errors as usual
;<

  test edx, edx
  jnz _error	; we can't have more than 4gb of ram...so...eh..no.

  cmp eax, _RAMDISK_SIZE_
  jae _error

  mov [ebx+local_file_descriptor.pos], eax

  clc
  retn
  
;                                           -----------------------------------
;                                                                    __seek_cur
;==============================================================================

__seek_cur:
;>
;; moves the position pointer of a file to specified point. This flavor moves
;; to a position relitive to the current location.
;;
;; parameters:
;; -----------
;; EDX:EAX = amount to seek, signed
;; EBX = file handle
;;
;; returned values:
;; ----------------
;; EBX = unchanged
;; errors as usual
;<

; XXX doesn't check to see if seek goes past file

  test edx, 0x80000000
  jnz .negitive		; jmp is seek is neg

  test edx, edx
  jnz _error		; we can't seek that much
  
  add [ebx+local_file_descriptor.pos], eax

  jmp .done

.negitive:
  not edx
  neg eax
  sbb edx, -1		; neg edx:eax

  test edx, edx
  jnz _error		; we can't seek that much

  sub [ebx+local_file_descriptor.pos], eax
.done:
  clc
  retn

;                                           -----------------------------------
;                                                                    __seek_end
;==============================================================================

__seek_end:
;>
;; moves the position pointer of a file to specified point. This flavor moves
;; to a position relitive to the end of the file. That means that a 0 will get
;; you pointed at a new byte, and 1 will get you pointed at the last byte of
;; the file.
;;
;; parameters:
;; -----------
;; EDX:EAX = amount to seek back from the end, unsigned
;; EBX = file handle
;;
;; returned values:
;; ----------------
;; EBX = unchanged
;; errors as usual
;<

;; XXX doesn't expand the file in the case that it's appended to

  test edx, edx
  jnz _error

  mov edx, _RAMDISK_SIZE_
  sub edx, eax
  js _error
  mov [ebx+local_file_descriptor.pos], edx

  clc
  retn

;                                           -----------------------------------
;                                                                       __error
;==============================================================================

__error:
_error:
_too_big:	; jumped to when there is not enough space on the ramdisk
xor eax, eax
dec eax
stc
retn

;                                           -----------------------------------
;                                                                         _open
;==============================================================================

_open:
  push edx
  mov ecx, local_file_descriptor_size
  externfunc mem.alloc
  mov dword[edi+file_descriptor.op_table], our_op_table
  pop dword[edi+file_descriptor.fs_descriptor]
  xor edx, edx
  mov [edi+local_file_descriptor.pos], edx
  mov ebx, edi
  retn

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================

section .c_info
db 0, 0, 1, 'a'
dd str_cellname
dd str_author
dd str_copyrights
str_cellname:	dd "Seaborgium - simple ramdisk"
str_author:	dd 'Phil "Indigo" Frost (daboy@xgs.dhs.org)'
str_copyrights:	dd 'Copyright 2001 by Phil Frost; distributed under the BSD license'

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data
align 4

global p_disk	; for fs_test
p_disk:	dd 0	; pointer to the disk's RAM chunk

our_file_descriptor: istruc local_file_descriptor
  at local_file_descriptor.global
    istruc file_descriptor
      at file_descriptor.op_table,	dd our_op_table
    iend
  at local_file_descriptor.pos,	dd 0		; position in the file
iend

our_op_table: istruc file_op_table
at file_op_table.close,		dd __error
at file_op_table.read,		dd __read
at file_op_table.write,		dd __write
at file_op_table.raw_read,	dd __raw_read
at file_op_table.raw_write,	dd __raw_write
at file_op_table.seek_cur,	dd __error
at file_op_table.seek_start,	dd __error
at file_op_table.seek_end,	dd __error
at file_op_table.read_fork,	dd __error
at file_op_table.write_fork,	dd __error
at file_op_table.link,		dd __error
at file_op_table.unlink,	dd __error
at file_op_table.create,	dd __error
at file_op_table.rename,	dd __error
at file_op_table.copy,		dd __error
at file_op_table.truncate,	dd __error
at file_op_table.attrib,	dd __error
iend
