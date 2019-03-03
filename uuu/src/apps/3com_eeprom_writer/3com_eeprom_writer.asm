; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License
;
; This code is currently designed to support only 3C900B-TPO network card, but
; it should be pretty easy to adapt to other model, it might already work with
; other network card too.

[bits 32]

section s_app_3com_eeprom_writer

supported_nic:
dw 0x10B7, 0x9004
dw 0x10B7, 0x9055
dw 0x1082, 0x0082
dw 0x1082, 0x008D
dw -1


_detect_nic_device:
 mov edi, supported_nic
 externfunc __enter_critical_section, noclass
 
 ; Try to detect one of the supported Vendor ID/Device ID 
.try_again:
 mov dx, [edi]
 mov cx, [edi+ 2]
 xor esi, esi
 push edi
 externfunc __find_pci_device, noclass
 pop edi
 jnc short .match_found
 add edi, byte 4
 cmp [edi], word -1
 jnz .try_again
 stc
 jmp short .exit

.match_found:
 ; Device detected, the following registers now contain information:
 ; BL = Device Number/Function Number
 ;      bits 0-2: Function NUmber
 ;      bits 3-7: Device Number
 ; BH = Bus Number (0...255)
 mov [device_number], ebx	; write in one shot the device_number and the
 				; bus_number.  We use ebx because right now the
				; io_base_adress isn't yet filled, so we can
				; allow to overwrite it.  This save using 66
				; prefix generating an extra cpu cycle

 ; Get the Base IO Address
 mov edi, 0x00000010
 push edi
 externfunc __read_pci_configuration_dword, noclass
 jc short .exit
 pop edi
 dec ecx			; 3com set bit 0 to 1 to indicate port number..
 mov [io_base_address], ecx

 ; Get the Base memory mapped io port address
 add edi, byte 4
 externfunc __read_pci_configuration_dword, noclass
 jc short .exit
 mov [memory_mapped_io_base_address], ecx
 push ecx

 ; enable device to respond to IO and Memory mapped IO + Bus Master + MWI
 mov edi, 0x00000004
 externfunc __read_pci_configuration_word, noclass
 or cl, 0x17
 externfunc __write_pci_configuration_word, noclass
 pop ecx
 ; ecx = base memory mapped io port address

 ; select register window 0
 mov [ecx + 0x0E], word 0x0800
 clc
 externfunc __leave_critical_section, noclass
 retn

 .exit:
 externfunc __leave_critical_section, noclass
 stc
 retn


_write_rom:
 externfunc __enter_critical_section, noclass
 ; write new EEPROM data, total of 64 bytes, write one word/step
 mov dl, 0x40
 mov dh, 0x20
 mov esi, eeprom
 mov ecx, [memory_mapped_io_base_address]

 .writing_rom:
   call _delay_162us

   mov [ecx + 0x0A], word 0x0030

   call _delay_162us

   lodsw
   mov [ecx + 0x0C], ax
   push edx
   mov dh, 0
   mov [ecx + 0x0A], dx
   pop edx

   inc dl
   dec dh
   jnz .writing_rom
   externfunc __leave_critical_section, noclass
   retn
 
_read_rom:
 ; read EEPROM data, total of 64 bytes, read one word/step
 externfunc __enter_critical_section, noclass
 mov dl, 0x80
 mov dh, 0x20
 mov edi, eeprom
 mov ecx, [memory_mapped_io_base_address]
 
 call _delay_162us

 .reading_rom:
 
   push edx
   mov dh, 0
   mov [ecx + 0x0A], dx
   pop edx

   call _delay_162us
 
   mov ax, [ecx + 0x0C]
   stosw

   inc edx
   dec dh
   jnz short .reading_rom
   externfunc __leave_critical_section, noclass
   retn
 

global app_3com_eeprom_writer
app_3com_eeprom_writer:

   in al, 0x21
   push eax
   or al, 0x02
   out 0x21, al
   call _clear_screen

   call _detect_nic_device
   jc near .failed

   call _read_rom
   call _prepare_mac_to_edit
   .get_key:
   call _update_highlights
   mov esi, str_3com_mac
   mov edi, 0xb8000
   call _display_str
   mov esi, mac_3com
   call _display_mac
   mov esi, str_oem_mac
   mov edi, 0xb80A0
   call _display_str
   mov esi, mac_oem
   call _display_mac
   call _get_key
   mov edi, [field_under_edition]
   cmp al, 0x1F
   jz near .save
   cmp al, 0x0B
   mov ah, 0x00
   jz near .pressed
   inc ah
   cmp al, 0x02
   jz near .pressed
   inc ah
   cmp al, 0x03
   jz near .pressed
   inc ah
   cmp al, 0x04
   jz near .pressed
   inc ah
   cmp al, 0x05
   jz near .pressed
   inc ah
   cmp al, 0x06
   jz short .pressed
   inc ah
   cmp al, 0x07
   jz short .pressed
   inc ah
   cmp al, 0x08
   jz short .pressed
   inc ah
   cmp al, 0x09
   jz short .pressed
   inc ah
   cmp al, 0x0A
   jz short .pressed
   inc ah
   cmp al, 0x1E
   jz short .pressed
   inc ah
   cmp al, 0x30
   jz short .pressed
   inc ah
   cmp al, 0x2E
   jz short .pressed
   inc ah
   cmp al, 0x20
   jz short .pressed
   inc ah
   cmp al, 0x12
   jz short .pressed
   inc ah
   cmp al, 0x21
   jz short .pressed
   cmp al, 0x0E
   jz short .back_spacing
   cmp al, 0x4B
   jz short .back_spacing
   cmp al, 0x4D
   jz short .next_location
   cmp al, 0x01
   jnz near .get_key

.exit:
   pop eax
   out 0x21, al
   retn

   .failed:
   mov esi, str_no_3com_supported
   mov edi, 0xB8000
   mov ah, 0x4F
   .writing_message:
   lodsb
   stosw
   test al, al
   jnz short .writing_message
   externfunc __wait_ack, debug
   pop eax
   out 0x21, al
   retn

.save:
  call _place_back_edited_mac
  call _write_rom
  jmp short .exit

.pressed:
  mov [edi], ah

.next_location:
  inc edi
  cmp edi, mac_oem + 11
  ja near .get_key
  mov [field_under_edition], edi
  jmp near .get_key

.back_spacing:
  dec edi
  cmp edi, mac_3com
  jb near .get_key
  mov [field_under_edition], edi
  jmp near .get_key


str_no_3com_supported: db "No supported 3Com card detected, exiting",0
str_3com_mac: db "3com: ",0
str_oem_mac: db "oem : ",0

_place_back_edited_mac:
  mov esi, mac_3com
  mov edi, eeprom
  call .convert
  mov esi, mac_oem
  mov edi, eeprom + 0x14
  call .convert
  retn
.convert:
  mov cl, 3
  .converting:
  lodsb
  mov bh, al
  shl bh, 4
  lodsb
  or bh, al
  lodsb
  mov bl, al
  shl bl, 4
  lodsb
  or bl, al
  mov ax, bx
  stosw
  dec cl
  jnz short .converting
  retn


_prepare_mac_to_edit:
  mov edi, mac_3com
  mov esi, eeprom
  call .convert
  mov edi, mac_oem
  mov esi, eeprom + 0x14
  call .convert
  retn
.convert:
  mov cl, 3
  .converting:
  lodsw
  mov bx, ax
  mov al, ah
  shr al, 4
  stosb
  mov al, ah
  and al, 0x0F
  stosb
  mov al, bl
  shr al, 4
  stosb
  mov al, bl
  and al, 0x0F
  stosb
  dec cl
  jnz short .converting
  retn


_clear_screen:
  mov edi, 0xb8000
  mov eax, 0x07200720
  mov ecx, 1000
  repz stosd
  retn

_delay_162us:
   ; wait 162us..
   ; using PB4 of Port 61h, which toggles every 15.085us..
   .redelay0:
   mov bl, 11	; 11*15.085us = 165.935us, which is close enough :)
   .delay0:
   in al, 0x61
   and al, 0x10
   cmp al, ah
   jz short .delay0
   mov ah, al
   dec bl
   jnz short .delay0
   test [ecx + 0x0A], word 0x8000
   jnz short .redelay0
   retn

_get_key:
  in al, 0x64
  test al, 0x01
  jz short _get_key
  in al, 0x60
  or al, al
  js _get_key
  retn

_display_mac:
  ; esi = pointer to mac address
  ; edi = pointer to location to print
  ; note: it won't overwrite current color in the background
  mov cl, 6
  .displaying_mac:
  lodsb
  add al, 0x90
  daa
  adc al, 0x40
  daa
  mov [edi], al
  lodsb
  add al, 0x90
  daa
  adc al, 0x40
  daa
  mov [edi+2], al
  mov [edi+4], byte '-'
  add edi, byte 6
  dec cl
  jnz .displaying_mac
  mov [edi - 2], byte ' '
  retn

_display_str:
  lodsb
  stosb
  inc edi
  test al, al
  jnz short _display_str
  retn

_update_highlights:
  mov edi, 0xB800A
  mov ecx, 12
  mov eax, 0x07200720
  push ecx
  repz stosd
  pop ecx
  mov edi, 0xb80AA
  repz stosd
  mov edi, [field_under_edition]
  cmp edi, mac_oem
  jb short .3com
  mov eax, edi
  sub eax, mac_oem
  mov edi, 0xB80AF
  jmp short .common
.3com:
  mov eax, edi
  sub eax, mac_3com
  mov edi, 0xB800F
  .common:
  test eax, eax
  jz short .highlight_it
  .find_highlight:
  add edi, byte 2
  dec eax
  jz short .highlight_it
  add edi, byte 4
  dec eax
  jnz short .find_highlight
.highlight_it:
  mov [edi], byte 0x09
  retn

align 16, db 0x5F

; This will be to read back the eeprom to confirm it's really loaded
eeprom: times 64 db 0

device_number: db 0
; This number represent the Device Number on the given PCI Bus, it is used to
; access the device via the PCI Bios functions
;
; bits 0-2: Function Number, for the 3C90xB this is always 0
; bits 3-7: Device Number

bus_number: db 0
; This gives the PCI Bus Number where the device is located.  It is used to
; access the device via the PCI Bios functions.


io_base_address: dw 0
; Pointer to the base address, PCI force 32bit i/o to be returned but PC supports
; only 16bits addressing, save only the 16bits.


memory_mapped_io_base_address: dd 0
; Pointer to the location in memory wehe the mapped io ports of the nic are
; located.

field_under_edition: dd mac_3com

mac_3com: times 12 db 0
mac_oem: times 12 db 0
