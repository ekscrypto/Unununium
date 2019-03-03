%define ORIGIN 0x7C00
org ORIGIN
__eks_os__:

%define LOG_TEMP_BLOCK			0x00080000	; -0x83FFF

%define VOID_MEMBLOCK_ID_FREE		0x00000000
%define VOID_MEMBLOCK_ID_ALLOCATED	0x00000001

	struc void_mem_block
.id			resd 1
.base_addr		resd 1
.size			resd 1
.marker_extra_info	resd 1
	endstruc

	struc mem_block
.void			resb void_mem_block_size
.previous		resd 1
.next			resd 1
	endstruc

; START OF BOOT RECORD
;------------------------------------------------------------------------------
  jmp short __boot_record

__fs:
.signature:	db "l33t"
.kernel_size:	db ((__eks_os_end__ - __eks_os__) / 512) - 1
.kernel_start:
.head:		db 0
.sector: 	db 2
.cylinder: 	db 0

__boot_record:
[bits 16]
  mov [.drive_used], dl	; Save disk drive ID we used to boot from
  cli			; Disable interrupts, we are doing sensitive stuff
  o32 lgdt [cs:__gdt]	; Make GDTR point to our own GDT
  mov eax, cr0		; Get current control flags
  or al, 0x01		; Set pmode bit
  mov cr0, eax		; Activate new control flag
  jmp dword 0x0008:.pmode_entered	; Enter protected mode, CS = 4GB r/x

[bits 32]
.pmode_entered:

 ;= Setting up system segments
  mov eax, 0x10		; All system data segments are set 4GB r/w
  mov ds, eax
  mov es, eax
  mov fs, eax
  mov gs, eax
  mov ss, eax
 
 ;= Set temporary stack
  mov esp, $$

 ;= Enabling A20
  mov al, 0x02		; MCA - system A20 is controlled via port 0x92, bit 1
  out 0x92, al
  mov al, 0xD1		; ISA - system A20 is enabled via keyboard controller
  out 0x64, al

 ;= getting disk geometry
  mov dl, 0
   .drive_used equ $-1
 push edx
 mov ah, 0x08
 xor edi, edi
 push byte 0
 push byte 0x13
 call __realmode_portal
 add esp, byte 8
 and cl, byte 0x3F
 mov [.maximum_sector_count], cl
 mov [.maximum_head_count], dh
 pop edx

 ;= Read the remaining of the kernel
  xor esi, esi
  movzx edi, byte [__fs.kernel_size]
  mov ecx, [__fs.sector]
  mov dh, [__fs.head]
  mov bx, 0x7E00
.reading_kernel:
  pushad
  push dword 0
  push dword 0x13
  mov ax, 0x0201
  call __realmode_portal
  add esp, byte 8
  popad
  jnc short .next_kernel_sector
  pushad
  mov ah, 0
  call __realmode_portal
  popad
  jc short .failed
  inc esi
  cmp esi, byte 0x10	; maximum retry count == 16
  jb short .reading_kernel
.failed:
  mov [0xB8000], dword 0x04210446
  jmp short $

.next_kernel_sector:
  xor esi, esi
  dec edi
  jz near __init_phase_2
  mov eax, ecx
  shr cl, 6
  ror cx, 8
  and eax, byte 0x3F
  inc eax
  cmp eax, byte 0x3F
   .maximum_sector_count equ $-1
  jbe short .encode_chs
  mov al, 1
  inc dh
  cmp dh, byte 2
   .maximum_head_count equ $-1
  jb short .encode_chs
  mov dh, 0
  inc ecx  
.encode_chs:
  rol cx, 8
  shl cl, 6
  or cl, al
  add bh, 2
  jmp short .reading_kernel

__realmode_portal:
;------------------------------------------------------------------------------
  pushfd
  cli
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
  lidt [.rm_idt]
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
  lidt [__idtr]
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

.rm_idt:
  dw 0x3FF
  dd 0

__idtr:
  dw (0x30 * 8) -1
  dd 0x600

align 4, db 0
__gdt:
.gdt_start:
dw (.gdt_end - .gdt_start) - 1,
dd __gdt
dw 0
dd 0x0000FFFF, 0x00CF9B00
dd 0x0000FFFF, 0x00CF9300
dd 0x0000FFFF, 0x00009B00
dd 0x0000FFFF, 0x00009300
.gdt_end:

times 510-($-$$) db '_'
db 0x55, 0xAA
;------------------------------------------------------------------------------
; END OF BOOT RECORD
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; BOOT SYSTEM EXTENDER
;------------------------------------------------------------------------------
__init_phase_2:

  ; Mask interrupts (all except timer and keyboard)
  cli
  mov al, 11111100b
  out 0x21, al
  mov al, 11111111b
  out 0xA1, al

  ; Install the timer and keyboard int handlers
  lidt [__idtr]
  mov edi, [__idtr + 2]
  mov [edi + (0x08 * 8) + 0], dword ((__timer_handler-$$+ORIGIN) & 0x0000FFFF) + 0x00080000
  mov [edi + (0x08 * 8) + 4], dword ((__timer_handler-$$+ORIGIN) & 0xFFFF0000) + 0x00008E00
  mov [edi + (0x09 * 8) + 0], dword ((__keyboard_handler-$$+ORIGIN) & 0x0000FFFF) + 0x00080000
  mov [edi + (0x09 * 8) + 4], dword ((__keyboard_handler-$$+ORIGIN) & 0xFFFF0000) + 0x00008E00
  sti

  ; format taskbar
  mov edi, 0xB8000
  mov eax, 0x07200720
  mov ecx, 960
  repz stosd
  mov eax, 0x1F201F20
  mov cl, 40
  push edi
  repz stosd

  ; display taskbar's string
  mov esi, strings.taskbar
  pop edi
  call __put_string.c_alternated

  mov ebp, strings.initializing
  call _extender
  call __close_log_entry.c_noclass

  mov ebp, strings.acquiring_mem_map
  call _extender
  push eax
  push byte 0
  push byte 0x15
  mov edi, 0x00007A00
  .acquiring_smap:
  mov eax, 0x0000E820
  mov edx, 'SMAP'
  mov ecx, 0x20
  xor ebx, ebx
  call __realmode_portal
  jc short .smap_failed
  cmp eax, 'SMAP'
  jnz short .smap_failed
  or byte [shell_options], byte 0x02
  add edi, byte 0x20
  or ebx, ebx
  jnz short .acquiring_smap

  .smap_acquired:
  add esp, byte 8
  pop eax
  call _success
  ; INCOMPLETE, WAITING FOR SOME COMPUTER WITH THIS FUNCTION WORKING ..
  jmp short $

  .smap_failed:
  test byte [shell_options], byte 0x02
  jnz short .smap_acquired
  mov eax, [esp + 8]
  call _failed

_acquire_large_mem_size:
  mov ebp, strings.acquiring_large32_memory_size
  call _extender
  mov [esp + 8], eax
    mov eax, 0x0000E881
    call __realmode_portal
    jc short .large32_mem_failed
    cmp eax, 0x3C00
    ja short .large32_mem_failed
  pushad
  mov eax, [esp + 32 + 8]
  call _success
  popad
  jmp short .large_mem_conversion

.large32_mem_failed:
  mov eax, [esp + 8]
  call _failed

  mov ebp, strings.acquiring_large16_memory_size
  call _extender
  mov [esp + 8], eax
    mov eax, 0x0000E801
    call __realmode_portal
    jc .large16_mem_failed
    movzx eax, ax
    cmp eax, 0x3C00
    ja near .large16_mem_failed
  pushad
  mov eax, [esp + 32 + 8]
  call _success
  popad
  movzx eax, ax
  movzx ebx, bx
  movzx ecx, cx
  movzx edx, dx
  .large_mem_conversion:
  ; TO BE COMPLETED (TODO)
  ;-----------------------
  ; EAX = extended memory between 1M and 16M, in K (max 3C00h = 15MB)
  ; EBX = extended memory above 16M, in 64K blocks
  ; ECX = configured memory 1M to 16M, in K
  ; EDX = configured memory above 16M, in 64K blocks
  add esp, byte 12
  pushad
  mov ebp, strings.generating_memory_map
  call _extender
  mov [esp], eax
  popad
  push edi
  xor esi, esi
  or ecx, ecx
  jz short .large_test_high_mem
  ; TODO: add 1MB<x<16MB mem to fmm
    mov edi, 0x00100000
    mov [edi + void_mem_block.id], dword VOID_MEMBLOCK_ID_FREE
    mov [edi + void_mem_block.base_addr], edi
    mov [edi + void_mem_block.size], ecx
    mov [edi + void_mem_block.marker_extra_info], esi
    dec esi
    mov [edi + mem_block.previous], esi
    mov [edi + mem_block.next], esi
    mov [memory_manager_data.root_free_memory_block], edi
    inc esi
  .large_test_high_mem:
  or edx, edx
  jz near _test_low_mem
  ; TODO: add 16MB+ memory to fmm
    mov edi, 0x01000000
    mov [edi + void_mem_block.id], dword VOID_MEMBLOCK_ID_FREE
    mov [edi + void_mem_block.base_addr], edi
    mov [edi + void_mem_block.size], edx
    mov [edi + void_mem_block.marker_extra_info], esi
    dec esi
    mov [edi + mem_block.previous], esi
    cmp dword [memory_manager_data.root_free_memory_block], byte -1
    jz short .large_link_as_root
    mov esi, [memory_manager_data.root_free_memory_block]
    mov [edi + mem_block.next], esi
    mov [esi + mem_block.previous], edi
    mov [memory_manager_data.root_free_memory_block], edi
    jmp short _test_low_mem
    .large_link_as_root:
    mov [edi + mem_block.next], esi
    mov [memory_manager_data.root_free_memory_block], edi
    jmp short _test_low_mem

.large16_mem_failed:
  mov eax, [esp + 8]
  call _failed

  mov ebp, strings.acquiring_big_memory_size
  call _extender
  mov [esp + 8], eax
    mov ah, 0x8A
    call __realmode_portal
    jc short .big_memory_size_failed
  jmp short $

.big_memory_size_failed:
  mov eax, [esp + 8]
  call _failed

  mov ebp, strings.acquiring_extended_memory_size
  call _extender
  mov [esp + 8], eax
    mov ah, 0x88
    call __realmode_portal
    jc short .extended_mem_failed
    add esp, byte 8
    mov ebp, eax
  pop eax
  call _success
  jmp short $

.extended_mem_failed:
  call _failed
  jmp short $

_test_low_mem:
  pop eax
  mov esi, strings.completed
  call __add_to_log_entry.c_string
  call __close_log_entry.c_noclass
  jmp short $

_success:
  mov esi, strings.successful
  call __add_to_log_entry.c_string
  call __close_log_entry.c_noclass
  retn

_failed:
  mov esi, strings.failed
  call __add_to_log_entry.c_string
  call __close_log_entry.c_noclass
  retn

_extender:
  mov esi, strings.extender
  call __create_log_entry.c_noclass
  mov esi, ebp
  call __add_to_log_entry.c_string
  retn
  

__timer_handler:
  push eax
  inc dword [system_count]
  mov al, 0x20
  out 0x20, al
  pop eax
  iretd

__keyboard_handler:
  push eax
  in al, 0x60
  mov [keyboard_last_scancode], al
  mov al, 0x20
  out 0x20, al
  pop eax
  iretd

__put_string:
  ; ESI = pointer to source string in UTF-8
  ; EDI = pointer to destination buffer
.c_alternated:
  lodsb
  or al, al
  jz short .end
  stosb
  inc edi
  jmp short .c_alternated
  .end:
  retn
.c_alternated_colored:
  ; AH = color
  lodsb
  or al, al
  jz short .end
  stosw
  jmp short .c_alternated_colored
.c_noclass:
  lodsb
  or al, al
  jz short .end
  stosb
  jmp short .c_noclass

__add_to_log_entry:
.c_string:
  ; ESI = pointer to string
  ; EAX = log entry ID
  call .get_end_of_log_entry
  push eax
  .process_string:
  lodsb
  stosb
  or al, al
  jnz short .process_string
  pop eax
  retn
.c_dword:
  ; EDX = value to add to log
  ; EAX = log entry ID
  call .get_end_of_log_entry
  push eax
  call __dword_out.c_noclass
  mov [edi], byte 0
  pop eax
  retn
.get_end_of_log_entry:
  ; EAX = log entry ID
  ; returns EDI = pointer to end of log entry
  lea edi, [eax + 4]
  .search_end_of_string:
  cmp [edi], byte 0
  jz short .end_of_string_found
  inc edi
  jmp short .search_end_of_string
  .end_of_string_found:
  retn

__close_log_entry:
.c_noclass:
  mov ebx, eax
  mov esi, 0xb80A0
  mov edi, 0xB8000
  mov ecx, 23*80/2
  repz movsd
  mov ah, 0x07
  mov cl, 80
  lea esi, [ebx + 4]
  .displaying_log_entry:
  lodsb
  or al, al
  jz short .erase_remaining
  stosw
  loop .displaying_log_entry
  retn
  .erase_remaining:
  mov al, ' '
  repz stosw
  retn

__create_log_entry:
  ; ESI = pointer to log creator
  ; 
.c_noclass:
  cli
  mov eax, [log_buffer.next_free_entry]
  push eax
  lea ebx, [eax + 256]
  mov [log_buffer.next_free_entry], ebx
  sti
  mov [eax], ebx
  mov [ebx], dword -1
  lea edi, [eax + 4]
  mov al, '['
  .processing_log_owner:
  stosb
  lodsb
  or al, al
  jnz short .processing_log_owner
  mov eax, '] '
  stosd
  pop eax
  retn


__dword_out:
  ; EDX = dword to output
  ; EDI = destination buffer
.c_alternated:
  mov ecx, 8
  .processing_alternated:
  rol edx, 4
  mov al, dl
  and al, 0x0F
  cmp al, 0x0A
  sbb al, 0x69
  das
  stosb
  inc edi
  loop .processing_alternated
  retn
.c_noclass:
  mov ecx, 8
  .processing_noclass:
  rol edx, 4
  mov al, dl
  and al, 0x0F
  cmp al, 0x0A
  sbb al, 0x69
  das
  stosb
  loop .processing_noclass
  retn


;------------------------------------------------------------------------------
; END OF BOOT SYSTEM EXTENDER
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; START OF DATA AREA
;------------------------------------------------------------------------------
align 4, db 0
shell_options: dd 0x01
system_count: dd 0

memory_manager_data:
.root_free_memory_block: dd -1
.root_umm: dd -1

log_buffer:
.start: dd LOG_TEMP_BLOCK
.next_free_entry: dd LOG_TEMP_BLOCK
.size: dd 4096

keyboard_last_scancode: db 0

strings:
.acquiring_big_memory_size: db "Acquiring BIOS big memory size..",0
.acquiring_extended_memory_size: db "Acquiring BIOS extended memory size..",0
.acquiring_large16_memory_size: db "Acquiring BIOS large memory configuration (16bits)..",0
.acquiring_large32_memory_size: db "Acquiring BIOS large memory configuration (32bits)..",0
.acquiring_mem_map: db "Acquiring BIOS system memory map..",0
.completed: db "Completed",0
.extender: db "EXTENDER",0
.failed: db "Failed",0
.generating_memory_map: db "Generating internal memory map..",0
.initializing: db "Initializing..",0
.successful: db "Successful",0
.taskbar: db "[UnderWorld] SYSTEM EXTENDER - V0iD COMPLIANT TESTER",0


align 512, db 0
__eks_os_end__:

incbin "fs.bin"
