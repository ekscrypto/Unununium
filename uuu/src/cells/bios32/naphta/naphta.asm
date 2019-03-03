;; Unununium Operating Engine
;; Copyright (C) 2001, Dave Poirier
;; Distributed under the BSD License
;;
;; Bios32 Service Directory access
;;
;; Additional Contributors:
;;-------------------------
;; Moutaz Haq, aka Cefarix - Addition of log output

[bits 32]

section .text
%include "vid/bios32.inc"
%include "vid/sys_log.inc"
%include "vid/debug.diable.inc"

section .c_init

  struc bsd_header
.signature	resd 1
.entry_point	resd 1
.hdr_version	resb 1
.hdr_lenght	resb 1
.checksum	resb 1
.reserved	resb 5
  endstruc

bios32_init:

  pushad

  ;]--Searching for Bios32 Service Directory
  ; The signature '_32_' should be located on a page boundary between
  ; 000E0000 and 00100000
  mov eax, '_32_'
  mov esi, 0x000E0000
  mov edi, 0x00100000
  mov ebx, 0x00000010
.scanning:
  cmp [esi], eax
  jz .bios32_sd_found
  lea esi, [esi + ebx]
  cmp esi, edi
  jb .scanning

  ; bios 32 service directory not found :/
  mov esi, str_notfound
  externfunc sys_log.print_string
  jmp short .completed

.bios32_sd_found:
  mov [system_code_seg], cs
  mov [bios32_sd], esi
  mov eax, [esi + bsd_header.entry_point]
  mov [bios32_sd_entry_point], eax

  ;]--Validating bios32 global services
  mov [unlock], word 0xC089	; mov eax, eax
  mov esi, str_found
  externfunc sys_log.print_string

.completed:
  popad

;==============================================================================
section .text

bios32_sd: dd 0
bios32_sd_entry_point: dd 0
system_code_seg: dd 0
str_found: db '[BIOS32] Service Directory found',0
str_notfound db '[BIOS32] Service Directory NOT found',0


;------------------------------------------------------------------------------
globalfunc bios32.get_entry_point
;------------------------------------------------------------------------------
;>
;; Finds the entry point for a Bios32 extension
;;
;; parameters:
;;------------
;; EAX = 4 character code service identifier
;; EBX = Service Index
;;
;; returned values:
;;-----------------
;; if cf = 0
;; AL = return code
;;      00 = Service corresponding to Service Identifier is present
;;      80 = Service corresponding to Service Identifier is not present
;;      81 = Unimplemented function for Bios Service Directory
;; EBX = Physical address of the base of the Bios Service
;; ECX = Length of BIOS service
;; EDX = Entry point into BIOS service.  This is an offset from base provided
;;       in EBX
;;
;; if cf = 1, failed
;;   Bios32 Service Directory not yet installed/detected.
;<
unlock:
  jmp short .invalid
  xor ebx, ebx
  call far [bios32_sd_entry_point]
  clc
  retn

.invalid:
  mov eax, -1
  stc
  retn
