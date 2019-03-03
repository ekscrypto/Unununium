;; Hacked-Bochs function cell, which basically allows to set memory ranges as
;; protected, and get the various access done to this memory area sent to
;; stderr.
;;
;; developed by EKS - Dave Poirier
;; see http://void-core.2y.net/~eks/bochs_hacked_mem.tgz for bochs sources
;; with the hacked memory


section .c_init
global _start
_start:
  push eax
  mov dx, 0x8A00
  mov eax, edx
  out dx, ax
  pop eax

section .text


globalfunc debug.bochs.unset_all_memory_protections
;>
;; Ask the I/O Debug cell to remove all currently set memory protections
;;
;; Parameters:
;;------------
;;  none
;;
;; Returned values:
;;-----------------
;; none, flags and registers all kept intact
;<
  push eax
  push edx
  pushfd
  mov dx, 0x8A00
  mov eax, edx
  mov al, 0xFF
  out dx, ax
  popfd
  pop edx
  pop eax
  retn


globalfunc debug.bochs.set_protection_on_address_range
;>
;; Indicate to the I/O Debug cell to set memory protection/monitoring on for
;; a specific memory range
;;
;; Parameters:
;;------------
;; eax = lower address where protection should start
;; edx = highest address+1 where protection should end
;;
;; Returns:
;;---------
;; none, flags and registers are all kept intact
;<
 pushad
 pushfd
 mov ebx, edx
 mov dx, 0x8A00
 push eax
 mov eax, edx
 mov al, 0x01
 out dx, ax	; select register 0
 pop eax
 ror eax, 16
 inc edx
 out dx, ax	; send highest 16bits of start addr
 shr eax, 16
 out dx, ax	; send lowest 16bits of start addr
 mov eax, edx
 dec edx
 inc eax
 out dx, ax	; select register 1
 inc edx
 mov eax, ebx
 ror eax, 16
 out dx, ax	; send highest 16 bits of end addr
 shr eax, 16
 out dx, ax	; send lowest 16 bits of end addr
 dec edx
 mov eax, edx
 mov al, 0x80
 out dx, ax	; send register memory range command
 popfd
 popad
 retn


%define _TERMINATE_ON_ONE_
globalfunc debug.bochs.print_string
;>
;; Print a string to bochs log output
;;
;; Parameters:
;;------------
;; esi = pointer to string to print
;;
;; Returns:
;;---------
;; none, flags and registers are all kept intact
;<
  push eax
  push edx
  push esi
  pushfd
  cli
  mov dx, 0xFFF0
  xor ax, ax
  jmp short .init
.sending_log:
  out dx, al
  mov ah, al
.init:
  lodsb

  %ifdef _TERMINATE_ON_ONE_
   cmp al, 0x01
   jz short .end
  %endif
  or al, al
  jnz short .sending_log
  mov al, 0x0A
  cmp ah, al
  jz short .end
  out dx, al
.end:
  popfd
  pop esi
  pop edx
  pop eax
  retn


