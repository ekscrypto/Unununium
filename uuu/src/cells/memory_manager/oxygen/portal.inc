[bits 32]
[org 0x6000]

%macro dme 1.nolist
  pushfd
  pushad
  mov edx, %{1}
  mov edi, 0xB8000
  call dword_out
  popad
  popfd
%endmacro

%macro dmej 1.nolist
  mov edx, %{1}
  mov edi, 0xB80A0
  call dword_out
  jmp short $
%endmacro

__realmode_portal:
;------------------------------------------------------------------------------
  pushfd
  cli
  sidt [.pm_idtr]
  mov [.eax_value], eax
  mov al, [esp + 0x08]
  mov [.interrupt_number], al
  in al, 0x21
  mov [.master_pic_mask], al
  mov ax, [esp + 0x0A]
  out 0x21, al
  in al, 0xA1
  mov [.slave_pic_mask], al
  mov al, ah
  out 0xA1, al
  mov eax, [esp + 0x0C]
  mov [.ds_value], ax
  shr eax, 16
  mov [.es_value], ax
  push ds
  push es
  mov [.pm_stack_esp], esp
  jmp 0x0018:.16bit_pmode
[bits 16]
.16bit_pmode:
  mov ax, 0x0020
  mov ss, ax
  mov ds, ax
  mov es, ax
  mov eax, cr0
  and al, 0xFE
  mov cr0, eax
  jmp 0:.realmode
.realmode:
  lidt [.rm_idtr]
  xor ax, ax
  mov ss, ax
  mov sp, 0x600
  push word 0
   .ds_value equ $-2
  pop ds
  push word 0
   .es_value equ $-2
  pop es
  mov eax, 0
   .eax_value equ $-4
  int 0x00
   .interrupt_number equ $-1
  mov [cs:.returned_eax], eax
  pushfd
  pop dword [cs:.returned_eflags]
  mov eax, cr0
  or al, 0x01
  mov cr0, eax
  jmp dword 0x0008:.pmode_reenabled
[bits 32]
.pmode_reenabled:
  push dword 0x10
  pop ss
  mov esp, 0
   .pm_stack_esp equ $-4
  pop es
  pop ds
  lidt [.pm_idtr]
  mov al, 0xFF
   .master_pic_mask equ $-1
  out 0x21, al
  mov al, 0xFF
   .slave_pic_mask equ $-1
  out 0xA1, al
  pop eax
  mov [.returned_ebx], ebx
  mov ebx, 0
   .returned_eflags equ $-4
  and ebx, 0x00000CD7 ; keep only OF,DF,SF,ZF,AF,PF and CF
  and eax, 0xFFFFF32A ; keep all but OF,DF,SF,ZF,AF,PF and CF
  or eax, ebx
  push eax
  popfd
  mov eax, 0
   .returned_eax equ $-4
  mov ebx, 0
   .returned_ebx equ $-4
  retn
.rm_idtr:
  dw 0x3FF
  dd 0
.pm_idtr:
  dw 0
  dd 0

dword_out:
  mov ecx, 8
  mov ah, 0x0F
.processing:
  rol edx, 4
  mov al, dl
  and al, ah
  cmp al, 0x0A
  sbb al, 0x69
  das
  stosw
  loop .processing
  retn
