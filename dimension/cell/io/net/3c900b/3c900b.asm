; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License
;
; This code is currently designed to support only 3C900B-TPO network card, but
; it should be pretty easy to adapt to other model, it might already work with
; other network card too.
;
; UTERLY OUTDATED, needs some major update to work with the new VID/core etc..

[bits 32]

section cell_init

%define __DEBUG__

;; Commands
%define AckInterrupt		0x6800
%define DnStall			0x3002
%define DnUnStall		0x3003
%define RequestInterrupt	0x6000
%define RxDisable		0x1800
%define RxEnable		0x2000
%define RxReset			0x2800
%define SelectRegisterWindow	0x0800
%define SetIndicationEnable	0x7800
%define SetInterruptEnable	0x7000
%define SetRxFilter		0x8000
%define StatisticsDisable	0xB000
%define StatisticsEnable	0xA800
%define TxDisable		0x5000
%define TxEnable		0x4800
%define TxReset			0x5800
%define UpStall			0x3000
%define UpUnStall		0x3001

;; 3C90xB flat register pane
%define offTxPkTld		0x18
%define offTimer		0x1A
%define offTxStatus		0x1B
%define offIntStatus		0x1E
%define offCommand		0x1E
%define offDmaCtrl		0x20
%define offDnListPtr		0x24
%define offDnBurstThresh	0x2A
%define offDnPriorityThresh	0x2C
%define offDnPoll		0x2D
%define offUpPktStatus		0x30
%define offFreeTimer		0x34
%define offCountDown		0x36
%define offUpListPtr		0x38
%define offUpPriorityThresh	0x3C
%define offUpPoll		0x3D
%define offUpBurstThresh	0x3E
%define offRealtimeCnt		0x40
%define offDebugData		0x70
%define offDebugControl		0x74
%define offDnMaxBurst		0x78
%define offUpMaxBurst		0x7A
%define offPowerMgmtCtl		0x7C

;; 3C90xB register window 0
%define win0BiosRomAddr		0x04
%define win0BiosRomData		0x08
%define win0EepromCommand	0x0A
%define win0EepromData		0x0C
%define win0IntStatus		0x0E
%define win0Command		0x0E

;; 3C90xB register window 1
%define win1IntStatus		0x0E
%define win1Command		0x0E

;; 3C90xB register window 2
%define win2StationAddressLo	0x00
%define win2StationAddressMid	0x02
%define win2StationAddressHi	0x04
%define win2StationMaskLo	0x06
%define win2StationMaskMid	0x08
%define win2StationMaskHi	0x0A
%define win2ResetOptions	0x0C
%define win2IntStatus		0x0E
%define win2Command		0x0E

;; 3C90xB register window 3
%define win3InternalConfig	0x00
%define win3MaxPktSize		0x04
%define win3MacControl		0x06
%define win3MediaOptions	0x08
%define win3RxFree		0x0A
%define win3TxFree		0x0C
%define win3IntStatus		0x0E
%define win3Command		0x0E

;; 3C90xB register window 4
%define win4VcoDiagnostic	0x02
%define win4FifoDiagnostic	0x04
%define win4NetworkDiagnostic	0x06
%define win4PhysicalMgmt	0x08
%define win4MediaStatus		0x0A
%define win4BadSSD		0x0C
%define win4UpperBytesOK	0x0D
%define win4IntStatus		0x0E
%define win4Command		0x0E

;; 3C90xB register window 5
%define win5TxStartThresh	0x00
%define win5RxEarlyThresh	0x06
%define win5RxFilter		0x08
%define win5TxReclaimThresh	0x09
%define win5InterruptEnable	0x0A
%define win5IndicationEnable	0x0C
%define win5IntStatus		0x0E
%define win5Command		0x0E

;; 3C90xB register window 6
%define win6CarrierLost		0x00
%define win6SqeErrors		0x01
%define win6MultipleCollisions	0x02
%define win6SingleCollisions	0x03
%define win6LateCollisions	0x04
%define win6RxOverruns		0x05
%define win6FramesXmittedOK	0x06
%define win6FramesRcvdOK	0x07
%define win6FramesDeferred	0x08
%define win6UpperFramesOK	0x09
%define win6BytesRcvdOK		0x0A
%define win6BytesXmittedOK	0x0C
%define win6IntStatus		0x0E
%define win6Command		0x0E

;; 3C90xB register window 7
%define win7VlanMask		0x00
%define win7VlanEtherType	0x04
%define win7PowerMgmtEvent	0x0C
%define win7IntStatus		0x0E
%define win7Command		0x0E



%macro setwindow 1
 mov edx,[iobase]
 add edx, byte 0eh
 mov ax,0800h + %1
 out dx,ax
%endmacro

%macro writeregdword 2
 mov edx,[iobase]
 add edx,%1
 mov eax,%2
 call waitready
 out dx,eax
%endmacro

%macro writereg 2
 mov edx,[iobase]
 add edx,%1
 mov ax,%2
 call waitready
 out dx,ax
%endmacro

%macro writeregbyte 2
 mov edx,[iobase]
 add edx,%1
 mov al,%2
 call waitready
 out dx,al
%endmacro

%macro readreg 2
 mov edx,[iobase]
 add edx,%2
 call waitready
 in ax,dx
 mov %1,ax
%endmacro

%macro readregdword 2
 mov edx,[iobase]
 add edx,%2
 call waitready
 in eax,dx
 mov %1,eax
%endmacro

%macro readregbyte 2
 mov edx,[iobase]
 add edx,%2
 call waitready
 in al,dx
 mov %1,al
%endmacro

 setwindow 0

 mov ecx, 40h
 mov edi, eepromdata

 mov eax, 0x80
reading:
 writereg 0x0A, ax
 push eax
 readreg ax, 0x0C
 xchg al, ah
 stosw
 pop ax
 inc ax
 loop reading

 mov eax, upd0
 writeregdword 0x38, eax

monitor_packets:
 writereg 0x0E, 0x8000+11111b
 writereg 0x0E, 0x2000
 writereg 0x0E, 0x3001
 test dword [upd0+4], 8000h
 jnz dumppacket
 jmp short monitor_packets

dumppacket:
 mov ecx, [upd0+4]
 and ecx, 0x1FFFF
 mov esi, packets
 xor ebp, ebp
 mov edi, 0xb8000
 .show:
 pushad
 test ebp, 0x0F
 jnz .noaddrdisp
 mov edx, ebp
 externfunc __dword_out, debug
 add edi, byte 18
 .noaddrdisp:
 popad
 inc ebp
 pushad
 lodsb
 call hex_out
 test ebp, 0x0F
 jnz .no_new_line
 pushad
 mov ecx, 16
 sub esi, ecx
 add edi, byte 4
 .displaying_chars:
 lodsb
 mov ah, 0x0F
 stosw
 loop .displaying_chars
 popad
 pushad
 lea eax, [edi - 0xB8000]
 mov ebx, 0xA0
 xor edx, edx
 div ebx
 inc eax
 mul ebx
 lea edi, [edi + 0xB8000]
 mov [esp], edi
 popad
 .no_new_line:
 inc esi
 loop .show

 and ebp, 0x0F
 jz .empty_last_line
 push ebp
 neg ebp
 add ebp, 10h
 .skip_spaces:
 mov eax, 0x07200720
 stosd
 stosw
 dec ebp
 jnz .skip_spaces
 add edi, byte 4
 pop ecx
 sub esi, ecx
 mov ah, 0x0F
 .displaying_leftover:
 lodsb
 stosw
 loop .displaying_leftover
 
 .empty_last_line:
 mov dword [upd0+4], 0
 mov eax, upd0
 writeregdword 0x38, eax
 writereg 0x0E, 0x3001
 jmp near monitor_packets
 
 
hex_out:
 rol al, 4
 mov ah, 0x09
 push eax
 and al, 0x0F
 cmp al, 10
 sbb al, 0x69
 das
 stosw
 pop eax
 rol al, 4
 and al, 0x0F
 cmp al, 10
 sbb al, 0x69
 das
 stosw
 add edi, byte 2
 retn

waitready:
 push edx
 push eax
 mov edx, [iobase]
 add edx, 0x0A
 .waiting:
 in ax, dx
 test ah, 0x80
 jnz .waiting
 pop eax
 pop edx
 retn

iobase: dd 0xB000
eepromdata: times 64 db 0

%ifdef __MYASS__


; To help us debug that crap out, let's first set text mode 80x50
 push dword 0x10
 mov eax, 0x00001112
 xor ebx, ebx
 externfunc __procedure_call, realmode
 add esp, byte 4

 ; also clear this garbage on screen ;)
 mov edi, 0xb8000
 mov ecx, 2000
 mov eax, 0x07200720
 repz stosd

detecting_nic_presence:
 ; Try to detect one of the supported Vendor ID/Device ID 
 mov dx, 0x10B7
 mov cx, 0x9004
 xor esi, esi
 externfunc __find_pci_device, noclass
 jc short $
 
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
 push esi
 mov edi, 0x00000010
 push edi
 externfunc __read_pci_configuration_dword, noclass
 jc short $
 pop edi
 dec ecx			; 3com set bit 0 to 1 to indicate port number..
 mov [io_base_address], ecx

 ; Get the Base memory mapped io port address
 add edi, byte 4
 externfunc __read_pci_configuration_dword, noclass
 jc short $
 mov [memory_mapped_io_base_address], ecx
 push ecx

 ; enable device to respond to IO and Memory mapped IO + Bus Master + MW
 mov edi, 0x00000004
 externfunc __read_pci_configuration_word, noclass
 or cl, 0x07
 externfunc __write_pci_configuration_word, noclass

 add edi, byte 0x38
 externfunc __read_pci_configuration_byte, noclass
 mov [interrupt_hooked], cl
 push ecx
 mov al, cl
 mov esi, boomerang_interrupt
 externfunc __hook_irq, noclass
 pop ecx
 cmp cl, 0x08
 jb short .master_pic
 add cl, 0x58
 mov [interrupt_acknowledge_command], cl
 mov [interrupt_acknowledge_port], byte 0xA0
 jmp short .interrupt_found
 .master_pic:
 add cl, 0x60
 mov [interrupt_acknowledge_command], cl
 mov [interrupt_acknowledge_port], byte 0x20
 .interrupt_found:
 pop ecx
 ; ecx = base memory mapped io port address

 ; select register window 0
 mov [ecx + 0x0E], dword 0x0800

 externfunc __enter_critical_section, noclass
 ; read EEPROM data, total of 64 bytes, read one word/step
 mov dl, 0x80
 mov dh, 0x20
 mov edi, eeprom
 
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

initializing_nic:

  ; Reset both transceivers
;  mov [ecx + 0x0E], word TxReset
;  mov [ecx + 0x0E], word RxReset
  mov [ecx + 0x0E], word SelectRegisterWindow+2

  mov ax, [eeprom + 0x14]
  mov [ecx + win2StationAddressLo], word ax
  mov ax, [eeprom + 0x16]
  mov [ecx + win2StationAddressMid], word ax
  mov ax, [eeprom + 0x18]
  mov [ecx + win2StationAddressHi], word ax

  mov [ecx + offUpListPtr], dword upd0
  
  mov [ecx + 0x0E], word 0x8000+1111b
  mov [ecx + 0x0E], word RxEnable
  mov [ecx + 0x0E], word UpUnStall

  externfunc __leave_critical_section, noclass

  
  .monitor_card:
  
  jmp short .monitor_card


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

_debug_display_card_status:
  pushad
  mov ecx, [memory_mapped_io_base_address]
  movzx edx, word [ecx + 0x0E]
  mov edi, 0xb8000
  externfunc __dword_out, debug
  popad
  retn

_dump_card_state:
  mov ecx, [memory_mapped_io_base_address]
  
  movzx edx, byte [ecx + offTxPkTld]
  mov al, byte [ecx + offTimer]
  mov ah, byte [ecx + offTxStatus]
  shl eax, 16
  or edx, eax
  mov edi, 0xb8090 + (0xA0*43)
  externfunc __dword_out, debug
  movzx edx, word [ecx + offIntStatus]
  shl edx, 16
  mov edi, 0xb8090 + (0xA0*42)
  externfunc __dword_out, debug
  mov edx, [ecx + offDmaCtrl]
  mov edi, 0xb8090 + (0xA0*41)
  externfunc __dword_out, debug
  mov edx, [ecx + offDnListPtr]
  mov edi, 0xB8090 + (0xA0*40)
  externfunc __dword_out, debug
  movzx edx, byte [ecx + offDnBurstThresh]
  shl edx, 16
  mov edi, 0xb8090 + (0xa0*39)
  externfunc __dword_out, debug
  xor edx, edx
  mov dl, [ecx + offDnPriorityThresh]
  mov dh, [ecx + offDnPoll]
  mov edi, 0xB8090 + (0xA0*38)
  externfunc __dword_out, debug
  mov edx, [ecx + offUpPktStatus]
  mov edi, 0xB8090 + (0xA0*37)
  externfunc __dword_out, debug
  movzx edx, word [ecx + offCountDown]
  shl edx, 16
  mov dx, [ecx + offFreeTimer]
  mov edi, 0xb8090 + (0xA0*36)
  externfunc __dword_out, debug
  mov edx, [ecx + offUpListPtr]
  mov edi, 0xB8090 + (0xA0*35)
  externfunc __dword_out, debug
  movzx edx, byte [ecx + offUpBurstThresh]
  shl edx, 16
  mov dl, [ecx + offUpPriorityThresh]
  mov dh, [ecx + offUpPoll]
  mov edi, 0xb8090 + (0xA0*34)
  externfunc __dword_out, debug
  mov edx, [ecx + offRealtimeCnt]
  mov edi, 0xb8090 + (0xA0*33)
  externfunc __dword_out, debug

  mov [ecx + 0x0E], word SelectRegisterWindow+0
  mov edx, [ecx + win0BiosRomAddr]
  mov edi, 0xB807E + (0xA0*48)
  externfunc __dword_out, debug
  
  mov [ecx + 0x0E], word SelectRegisterWindow+2
  mov dx, word [win2StationAddressMid]
  shl edx, 16
  mov dx, word [win2StationAddressLo]
  mov edi, 0xB807E+ (0xA0*41)
  externfunc __dword_out, debug
  mov dx, word [win2StationMaskLo]
  shl edx, 16
  mov dx, word [win2StationAddressHi]
  mov edi, 0xB807E+ (0xA0*40)
  externfunc __dword_out, debug
  mov dx, word [win2StationMaskHi]
  shl edx, 16
  mov dx, word [win2StationMaskMid]
  mov edi, 0xb807E+ (0xA0*39)
  externfunc __dword_out, debug
  mov dx, word [win2IntStatus]
  shl edx, 16
  mov dx, word [win2ResetOptions]
  mov edi, 0xb807E+ (0xA0*38)
  externfunc __dword_out, debug
  
  mov [ecx + 0x0E], word SelectRegisterWindow+3
  mov edx, [ecx + win3InternalConfig]
  mov edi, 0xb807E+ (0xA0*37)
  externfunc __dword_out, debug
  mov dx, word [ecx + win3MacControl]
  shl edx, 16
  mov dx, word [ecx + win3MaxPktSize]
  mov edi, 0xb807E+ (0xA0*36)
  externfunc __dword_out, debug
  mov dx, word [ecx + win3RxFree]
  shl edx, 16
  mov dx, word [ecx + win3MediaOptions]
  mov edi, 0xB807E+ (0xA0*35)
  externfunc __dword_out, debug
  mov dx, word [ecx + win3IntStatus]
  shl edx, 16
  mov dx, word [ecx + win3TxFree]
  mov edi, 0xB807E+ (0xA0*34)
  externfunc __dword_out, debug
  
  mov [ecx + 0x0E], word SelectRegisterWindow+4
  mov dx, [ecx + win4VcoDiagnostic]
  shl edx, 16
  mov edi, 0xb807E+ (0xA0*33)
  externfunc __dword_out, debug
  mov dx, word [ecx + win4NetworkDiagnostic]
  shl edx, 16
  mov dx, word [ecx + win4FifoDiagnostic]
  mov edi, 0xb807E+ (0xA0*32)
  externfunc __dword_out, debug
  mov dx, [ecx + win4MediaStatus]
  shl edx, 16
  mov dx, [ecx + win4PhysicalMgmt]
  mov edi, 0xb807E+ (0xA0*31)
  externfunc __dword_out, debug
  mov dx, word [ecx + win4IntStatus]
  shl edx, 16
  mov dl, byte [ecx + win4BadSSD]
  mov dh, byte [ecx + win4UpperBytesOK]
  mov edi, 0xb807E+ (0xa0*30)
  externfunc __dword_out, debug
  
  mov [ecx + 0x0E], word SelectRegisterWindow+5
  movzx edx, word [ecx + win5TxStartThresh]
  mov edi, 0xB807E+ (0xa0*29)
  externfunc __dword_out, debug
  mov dx, word [ecx + win5RxEarlyThresh]
  shl edx, 16
  mov edi, 0xB807E+ (0xA0*28)
  externfunc __dword_out, debug
  mov dx, word [ecx + win5InterruptEnable]
  shl edx, 16
  mov dl, [ecx + win5RxFilter]
  mov dh, [ecx + win5TxReclaimThresh]
  mov edi, 0xb807E+ (0xA0*27)
  externfunc __dword_out, debug
  mov dx, word [ecx + win5IntStatus]
  shl edx, 16
  mov dx, word [ecx + win5IndicationEnable]
  mov edi, 0xb807E+ (0xA0*26)
  externfunc __dword_out, debug

  mov [ecx + 0x0E], word SelectRegisterWindow+6
  mov dl, [ecx + win6MultipleCollisions]
  mov dh, [ecx + win6SingleCollisions]
  shl edx, 16
  mov dl, [ecx + win6CarrierLost]
  mov dh, [ecx + win6SqeErrors]
  mov edi, 0xB807E+ (0xA0*25)
  externfunc __dword_out, debug
  mov dl, [ecx + win6FramesXmittedOK]
  mov dh, [ecx + win6FramesRcvdOK]
  shl edx, 16
  mov dl, [ecx + win6LateCollisions]
  mov dh, [ecx + win6RxOverruns]
  mov edi, 0xB807E+ (0xA0*24)
  externfunc __dword_out, debug
  mov dx, [ecx + win6BytesRcvdOK]
  shl edx, 16
  mov dl, [ecx + win6FramesDeferred]
  mov dh, [ecx + win6UpperFramesOK]
  mov edi, 0xB807E+ (0xA0*23)
  externfunc __dword_out, debug
  mov dx, [ecx + win6IntStatus]
  shl edx, 16
  mov dx, [ecx + win6BytesXmittedOK]
  mov edi, 0xB807E+ (0xA0*22)
  externfunc __dword_out, debug
  retn


 ; Set pointer to UDP
 mov [ecx + 0x38], dword upd0

 ; Send Set RxFilter command for all packets
 mov ax, 0x8008
 mov dl, byte 0x0E
 out dx, ax

 ; Send the UpUnStall command
 mov ax, 0x3001
 out dx, ax
 
 
 ; Send RxEnable command
 mov ax, 0x2000
 out dx, ax

  mov edi, 0xb8000
  mov ecx, 1000
  mov eax, 0x07200720
  repz stosd

_monitor_packets:
  mov esi, packet0
  mov edi, 0xB8000
  mov ecx, 40
  .displaying:
  mov edx, [esi]
  externfunc __dword_out, debug
  add esi, byte 4
  add edi, byte 20
  loop .displaying
  
  mov esi, packet1
  mov ecx, 40
  .displaying1:
  mov edx, [esi]
  externfunc __dword_out, debug
  add esi, byte 4
  add edi, byte 20
  loop .displaying1
  
  mov esi, packet2
  mov ecx, 40
  .displaying2:
  mov edx, [esi]
  externfunc __dword_out, debug
  add esi, byte 4
  add edi, byte 20
  loop .displaying2

  mov esi, packet3
  mov ecx, 40
  .displaying3:
  mov edx, [esi]
  externfunc __dword_out, debug
  add esi, byte 4
  add edi, byte 20
  loop .displaying3
  retn

align 16, db 0x5F

dynamic_s_3c900b:

%define bit(val) 1 << val

%ifdef __DEBUG__
  %macro sys_debug 1.nolist
    push esi
    lea esi, [%{1}]
    externfunc __string_out, system_log
    pop esi
  %endmacro
%else
  %macro sys_debug 1.nolist
  %endmacro
%endif

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

interrupt_acknowledge_port: dw 0
; This value is set at initialization, it points to either the master or slave
; PIC and his used to acknowledge interrupt reception

interrupt_hooked: db 0

interrupt_acknowledge_command: db 0
; This value will be used with the interrupt_acknowedge_port to acknowledge
; servicing of the nic interrupt.

IntStatus:
.IntLatch	equ bit(0)
.HostError	equ bit(1)
.TxComplete	equ bit(2)
.RxComplete	equ bit(4)
.RxEarly	equ bit(5)
.IntRequested	equ bit(6)
.UpdateStats	equ bit(7)
.LinkEvent	equ bit(8)
.DnComplete	equ bit(9)
.UpComplete	equ bit(10)
.CmdInProgress	equ bit(11)
.WindowNumber	equ bit(12)



dd 0,0
boomerang_interrupt:
mov [0xb8000], dword 0x0f300f31
jmp short $
%ifdef __COMPLETE__
  push edx
  xor eax, eax
  mov edx, [memory_mapped_io_base_address]
  mov ax, [edx + offIntStatus]

    sys_debug(str_debug_int_received)

  ;-PCI Shared irq check
  test al, byte IntStatus.IntLatch	; if !IntLatch, get out
  jz short .exit_handler

  ;-PCI HotPlug check
  cmp eax, 0x0000FFFF			; device no longer present?
  jz short .exit_handler		; TODO: unload this cell

    sys_debug(str_debug_entering_int_loop)

  .interrupt_loop:
  test ah, (IntStatus.UpCompleted / 256)
  jz .bypass_up_complete

    ; sending interrupt acknowledgement
    mov eax, AckIntr | UpComplete
    mov [edx + boomerang_regs.Command], ax
    call enable_rx

  .bypass_up_complete:

  ;- Is there 
  test ah, (IntStatus.DnCompleted / 256)
  jz .bypass_dn_complete


  ; download to the card completed

    ;acknowledge interrupt
    mov eax, AckIntr | IntStatus.DnComplete
    mov [edx + boomerang_regs.Command], ax




  .bypass_dn_complete:

  ;-- Check for all uncommon interrupt at cnce
  test eax, IntStatus.HostError | IntStatus.RxEarly | IntStatus.StatsFull | IntStatus.TxComplete | IntStatus.IntReq
  jz .bypass_uncommon_interrupts

    mov edx, 0xFFFF6564	; TODO: create a nice error handler
    mov edi, 0xb8000
    externfunc __dword_out, debug
    jmp short $

  .bypass_uncommon_interrupts:

  ;- Acknowledge the IRQ with the nic
  mov eax, AckIntr | IntStatus.IntReq | IntStatus.IntLatch
  mov [edx + boomerang_regs.Command], ax

  ;- Service the card as long as it still got its IntLatch set
  mov ax, [edx + boomerang_regs.IntStatus]
  test al, IntStatus.IntLatch
  jnz .interrupt_loop

  ;- Interrupt servicing completed, acknowledging PIC
  mov edx, [acknowledge_interrupt_port]
  mov al,  [acknowledge_interrupt_command]
  out dx,  al

.exit_handler:
  pop edx
  stc
  retn

.up_completed:

%ifdef __DEBUG__
str_debug_int_received: db "[3C900B] received system interrupt",0
str_debug_entering_int_loop: db "[3C900B] entering interrupt loop",0
%endif
%endif


%endif

align 16, db 0
upd0:
dd 0
dd 0
dd packet0
dd 8192
dd packet1
dd 8192
dd packet2
dd 8192
dd packet3
dd 8192 + 0x80000000

packets:

packet0: times 8192 db 0
packet1: times 8192 db 0
packet2: times 8192 db 0
packet3: times 8192 db 0
