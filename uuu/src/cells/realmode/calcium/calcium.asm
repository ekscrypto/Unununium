; Unununium Operating Engine
; Copyrights (C) 2001, Dave Poirier
; Distributed under the BSD License
;
; http://uuu.sourceforge.net/

[bits 32]


section .c_info

  db 3,0,0,'b'
  dd str_name
  dd str_author
  dd str_copyrights

  str_name: db "Calcium Realmode Portal",0
  str_author: db "EKS - Dave Poirier (futur@mad.scientist.com)",0
  str_copyrights: db "Copyright (C) 2001, Dave Poirier",0x0A
                  db "Distributed under the BSD License",0

section .c_init

init_realmode_portal:

  pushad


  ;=- allocating rm_transfer_area
  mov ecx, 16*1024
  externfunc mem.alloc_20bit_address
  jnc short .rm_transfer_area_allocated

    mov edx, 1			; in case it failed.. error code: 0000001
    mov edi, 0xB8000
    externfunc debug.diable.dword_out
    jmp short $

  .rm_transfer_area_allocated:
  shl edi, 12
  mov [rm_transfer_area], edi

  ;=- allocating rm_stack
  mov ecx, 1024
  externfunc mem.alloc_20bit_address
  jnc short .rm_stack_allocated

    mov edx, 2			; in case it failed.. error code: 0000002
    mov edi, 0xB8000
    externfunc debug.diable.dword_out
    jmp short $

  .rm_stack_allocated:
  shl edi, 12
  or edi, ecx
  mov [rm_stack], edi

  ;=- allocating cell space
  mov ecx, cell_end - cell_start
  externfunc mem.alloc_20bit_address
  jnc short .cell_space_allocated

    mov edx, 3
    mov edi, 0xB8000
    externfunc debug.diable.dword_out
    jmp short $

  .cell_space_allocated:
  push edi
  mov [exported_code], edi
  push edi
  shr edi, 4
  mov [cell_start.code_segment], di
  mov eax, edi

  ;]--Install irq redirectors
  shl eax, 16
  mov esi, irq_redirectors
  mov edi, 8*4
  mov cl, 8
  .master_pic:
  lodsw
  stosd
  dec cl
  jnz short .master_pic
  mov edi, 0x70*4
  mov cl, 8
  .slave_pic:
  lodsw
  stosd
  dec cl
  jnz short .slave_pic

  ;]--Create 16bits data descriptor
  pop esi
  mov ecx, 0x0FFFF
  mov dh, 0x92
  mov dl, 0
  externfunc gdt.create_descriptor
  mov [cell_start.fixme_ds16], esi
  inc esi
  jnz short .data_desc_created

    mov edx, 4
    mov edi, 0xb8000
    externfunc debug.diable.dword_out
    jmp short $

  .data_desc_created:

  ;]--Create 16bits code descriptor
  pop esi
  push esi
  mov ecx, 0x0000FFFF
  mov dh, 0x9A
  mov dl, 0
  externfunc gdt.create_descriptor
  mov [cell_start.fixme_cs16], esi
  inc esi
  jnz short .code_desc_created

    mov edx, 5
    mov edi, 0xB8000
    externfunc debug.diable.dword_out
    jmp short $

  .code_desc_created:

  ;=- recalculating local data access points -=
  pop edi
  mov esi, fixme_points
.fixing_points:
  lodsd
  test eax, eax
  jz short .done_fixing
  add [eax], edi
  jmp short .fixing_points
.done_fixing:

  ;=- moving cell into it's allocated realmode space -=
  mov esi, cell_start
  mov ecx, (cell_end - cell_start) / 4
  rep movsd

  jmp near completed


fixme_points:
dd cell_start.fixme000, cell_start.fixme001
dd cell_start.fixme002, cell_start.fixme003
dd cell_start.fixme004, cell_start.fixme005
dd cell_start.fixme006, cell_start.fixme007
dd cell_start.fixme008, cell_start.fixme009
dd cell_start.fixme010, cell_start.fixme011
dd 0



cell_start:

;globalfunc realmode.proc_call, 40

  pushfd
  cli
  ;]--Save EAX entrance value to be restored prior to INT
  mov [.eax_value - cell_start], eax
  .fixme000 equ $-4

  ;]--Use self-modifying code to fix up interrupt number for the INT
  mov al, [ss:esp + 8]
  mov [.interrupt_number - cell_start], al
  .fixme001 equ $-4
  in al, 0x21
  mov [.master_pic_mask - cell_start], al
  .fixme002 equ $-4
  mov al, [ss:esp + 10]
  out 0x21, al
  in al, 0xA1
  mov [.slave_pic_mask - cell_start], al
  .fixme003 equ $-4
  mov al, [ss:esp + 11]
  out 0xA1, al

  ;]--fix the values to use for real mode DS and ES
  mov eax, [ss:esp + 12]
  mov [.ds_value - cell_start], ax
  .fixme004 equ $-4
  shr eax, 16
  mov [.es_value - cell_start], ax
  .fixme005 equ $-4

  ;]--Save the pmode values of DS and ES on stack
  push ds
  push es

  ;]--Save current protected mode stack
  mov [.pm_stack_esp - cell_start], esp
  .fixme006 equ $-4
  mov word [.pm_stack_ss - cell_start], ss
  .fixme007 equ $-4

  ;]--Save pointer to protected mode Interrupt Descriptor Table
  sidt [pm_idt - cell_start]
  .fixme008 equ $-4

  jmp 0x0000:(.16bit_code-cell_start)
.fixme_cs16 equ $-2
  dw 0

[bits 16]
.16bit_code:

  ;]--Fixing stack size to 16bits
  mov eax, 0
.fixme_ds16 equ $-4
  mov ss, eax
  mov esp, 0x400
  mov ds, eax
  mov es, eax

  ;]--disabling protected mode
  mov eax, cr0
  and al, 0xFE
  mov cr0, eax

  ;]--Hard encoded far jump to real mode code
  db 0xEA
  dw .pmode_disabled-cell_start
.code_segment:  dw 0

[bits 16]
.pmode_disabled:

  ;]--Load real mode Interrupt Vector Table
  lidt [cs:rm_idt-cell_start]

  ;]--Load real mode stack
  mov ss, [cs:rm_stack+2-cell_start]
  mov sp, [cs:rm_stack-cell_start]

  ;]--Set DS and ES to selected values
  mov ax, 0
.ds_value equ $-2
  mov ds, ax
  mov ax, 0
.es_value equ $-2
  mov es, ax

  ;]--Set back EAX to what it was when __interrupt was first called
  mov eax, 0
.eax_value equ $-4


  ;]--Executing requested interrupt
  int 0xFF
  .interrupt_number equ $-1

  ;]--Saving the EAX register, that will be used to restore pmode
  mov [cs:.eax_returned-cell_start], eax

  ;]--Save the returned flags for further restore
  pushfd
  pop dword [cs:.flags_returned-cell_start]

  ;]--re-enabling protected mode
  mov eax, cr0
  or al, 0x01
  mov cr0, eax

  ;]--Hard encoded far jump instruction to pmode re-entry point
  ;o32 jmp 0x0008:(.pmode_reenabled - cell_start)
  db 0x66, 0xEA
.fixme009:
  dd .pmode_reenabled - cell_start
  dw 0x0008

[bits 32]
.pmode_reenabled:

  ;]--Restore pmode stack
  mov eax, 0
.pm_stack_ss equ $-4
  mov ss, eax
  mov esp, 0
.pm_stack_esp equ $-4

  ;]--Restore pmode DS and ES values
  pop es
  pop ds

  ;]--Restore pmode Interrupt Descriptor Table
  lidt [pm_idt - cell_start]
  .fixme010 equ $-4

  mov al, 0xFF
.master_pic_mask equ $-1
  out 0x21, al
  mov al, 0xFF
.slave_pic_mask equ $-1
  out 0xA1, al

  ;]--Update the flags to return with the flags returned by the INT routine
  pop eax		;<-- retrieve original EFLAGS
  mov [.ebx_returned - cell_start], ebx
  .fixme011 equ $-4
  mov ebx, 0		;<-- SMC fixed with EFLAGS returned
.flags_returned equ $-4
  and ebx, 0x00000CD7 ; keep only OF,DF,SF,ZF,AF,PF and CF
  and eax, 0xFFFFF32A ; keep all but OF,DF,SF,ZF,AF,PF and CF
  or eax, ebx

  ;]--Restore new modified EFLAGS
  push eax		;<-- Save newly modified EFLAGS
  popfd			;<-- Retrieve modified EFLAGS

  ;]--Restore returned EAX value
  mov eax, 0
.eax_returned equ $-4

  ;]--Restore returned EBX value
  mov ebx, 0
.ebx_returned equ $-4

  ;]--Return control
  retn

rm_stack:
  dw 0,0
pm_idt:
  dw 0
  dd 0
rm_idt:	
  dw 0x3FF
  dd 0

[bits 16]

irq0_redirector:
jmp far [0x8 * 4]

irq1_redirector:
jmp far [0x9 * 4]

irq2_redirector:
jmp far [0xA * 4]

irq3_redirector:
jmp far [0xB * 4]

irq4_redirector:
jmp far [0xC * 4]

irq5_redirector:
jmp far [0xD * 4]

irq6_redirector:
jmp far [0xE * 4]

irq7_redirector:
jmp far [0xF * 4]

irq8_redirector:
jmp far [0x70 * 4]

irq9_redirector:
jmp far [0x71 * 4]

irqA_redirector:
jmp far [0x72 * 4]

irqB_redirector:
jmp far [0x73 * 4]

irqC_redirector:
jmp far [0x74 * 4]

irqD_redirector:
jmp far [0x75 * 4]

irqE_redirector:
jmp far [0x76 * 4]

irqF_redirector:
jmp far [0x77 * 4]

align 4, db 0
cell_end:

[bits 32]

irq_redirectors:
dw irq0_redirector-cell_start
dw irq1_redirector-cell_start
dw irq2_redirector-cell_start
dw irq3_redirector-cell_start
dw irq4_redirector-cell_start
dw irq5_redirector-cell_start
dw irq6_redirector-cell_start
dw irq7_redirector-cell_start
dw irq8_redirector-cell_start
dw irq9_redirector-cell_start
dw irqA_redirector-cell_start
dw irqB_redirector-cell_start
dw irqC_redirector-cell_start
dw irqD_redirector-cell_start
dw irqE_redirector-cell_start
dw irqF_redirector-cell_start

completed:
  popad



section .text

globalfunc realmode.proc_call
;>
;; Allow to execute a real mode interrupt from protected mode.
;;
;; Parameters:
;;------------
;; stack + 0 = interrupt number to call
;; stack + 1 = 0
;; stack + 2 = master pic mask (bit 7 = irq 7, bit 0 = irq 0)
;; stack + 3 = slave pic mask (bit 7 = irq 15, bit 0 = irq 8)
;; stack + 4 (16bit) = DS value
;; stack + 6 (16bit) = ES value
;;
;; Returned values:
;;-----------------
;; note: the stack is NOT cleared from the value pushed.
;; ALL: EAX, EBX, ECX, EDX, ESI, EDI, Flags
;;
;; Destroys:
;;----------
;; none
;<
  jmp [exported_code]

globalfunc realmode.get_transfer_area
;>
;; Get a Pointer to the realmode transfer area (safe memory area to use when
;; exchanging data with the bios in realmode)
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;; EDI = pointer to memory area
;<
  mov edi, [rm_transfer_area]
  retn

exported_code: dd 0
rm_transfer_area: dd 0
