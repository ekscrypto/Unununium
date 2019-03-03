;; Unununium Operating Engine
;; Copyright(C) 2001, Dave Poirier
;; Distributed under the X11 License
;;
;; * provided functions *
;;
;; 111 pci.list_vendor_devices
;; 112 pci.list_class_code_devices 
;; 113 pci.generate_special_cycle <-- TODO
;; 114 pci.get_interrupt_routing_options <-- TODO
;; 115 pci.read_configuration_byte
;; 116 pci.read_configuration_word
;; 117 pci.read_configuration_dword
;; 118 pci.write_configuration_byte
;; 119 pci.write_configuration_word
;; 120 pci.write_configuration_dword
;;
;; Known supported pci-chipsets:
;; device vendor name
;; 1541   10b9   ALI M1541
;; 0596   1106   VT82C596
;; 0686   1106   VT82C686
;; 3099   1106   VT8366
;; 7100   8086   82439TX 430TX
;; 7190   8086   82443BX/ZX 440BX/ZX
;;
;; to know if your chipset is supported, you can download
;; http://onee-san.net/uuu_pci.bin.bz2 , uncompress and raw write it to a
;; floppy, then use it to boot your computer.  If all works properly, you will
;; have hexadecimal numbers displayed on 3 columns on screen.  If you find
;; a supported controller that we do not have listed here, please notify us so
;; we can add it to the list of supported hardware.


;%define _DEBUG_

section .c_info
  db 1,0,0,0
  dd str_cellname
  dd str_author
  dd str_copyright

  str_cellname:
  db "Erode PCI Bus Driver",0
  str_author:
  db "eks",0
  str_copyright:
  db "Copyright (C) 2002, Dave Poirier",0x0A
  db "Distributed under the X11 License",0


section .text

;------------------------------------------------------------------------------
globalfunc pci.list_vendor_devices
;------------------------------------------------------------------------------
;>
;; This functions sends the location of PCI devices that have a specific
;; Device ID and Vender ID as parameters to a specified function.
;;
;; parameters:
;;------------
;; EBX =
;;  bit	15-0:	Vendor ID (0xFFFF for any) first level match
;;  bit 31-16:	Device ID (0xFFFF for any) second level match
;; ECX = pointer to child function to call with the details
;; EBP = passed as is to the child function
;;
;; returned:
;;----------
;; EAX = number of devices listed
;;
;; child function parameters:
;;---------------------------
;; EAX =
;;  bit  7- 0: 0
;;  bit 10- 8: Function Number
;;  bit 15-11: Device Number
;;  bit 23-16: Bus Number
;;  bit 31-24: 0
;; EBX =
;;  bit  7- 0: Revision
;;  bit 31- 8: Class Code
;; ECX = pointer to child function
;; EDX =
;;  bit 15- 0: Vendor ID
;;  bit 31-16: Device ID
;; EBP = as received.
;<
;------------------------------------------------------------------------------
  xor  eax, eax			; set initial number of matches to 0
  pushad			; backup all passed registers
  mov  esi, ebx			;
  shr  ebx, byte 16		; ebx = Device ID to match (0xFFFF = any)
  and  esi, dword 0x0000FFFF	; esi = Vendor ID to match (0xFFFF = any)
  ;xor  eax, eax		; set pointer to first device (already 0)
.processing_list:		;
  push eax			; save bus/device/function #
  call pci.read_configuration_dword
  cmp  eax, byte -1		; valid device?
  jnz  short .check		; yes, check for filters
  pop  eax			; restore bus/device/function #
  test eax, dword 0x00000700	; did it failed on function != 0?
  jnz  short .next_device	;
  test eax, dword 0x0000F800	; failed on device #0 ?
  jz   short .end		; if so, last bus was scanned.
.next_device:			;
  and  eax, dword 0x00FFF800	; reset function to 0
  add  eax, dword 0x00000800	; inc device # (will overflow in bus #)
  jmp  short .processing_list	;
.check:				;
  mov  edx, eax			;
  mov  edi, eax			;
  and  edx, dword 0x0000FFFF	; edx = Vendor ID of device
  shr  edi, byte 16		; edi = Device ID of device
  cmp  esi, dword 0x0000FFFF	; check for 'any' Vendor ID to match
  jz   short .vendor_matched	;
  cmp  esi, edx			; check for a Vendor ID match
  jnz  short .next		;
.vendor_matched:		;
  cmp  ebx, dword 0x0000FFFF	; check for 'any' Device ID to match
  jz   short .device_matched	;
  cmp  ebx, edi			; check for a Device ID match
  jnz  short .next		;
.device_matched:		;
  mov  edx, eax			; remember device/vendor ID
  mov  eax, [esp]		; restore bus/device/function #
  or   eax, byte 0x08		; select register 8 (class/revision)
  call pci.read_configuration_dword
  push esi			; save Vendor ID to match
  push ebx			; save Device ID to match
  mov  ebx, eax			; ebx = class/revision
  mov  eax, [esp+8]		; eax = bus/device/function
				; edx = device/vendoer ID
  call ecx			; send to child function
  pop  ebx			; restore Device ID to match
  pop  esi			; restore Vendor ID to match
  inc  dword [esp + 32]		; increment number of matches found
.next:				;
  mov  eax, [esp]		; restore bus/device/function #
  and  ah, 0xF8			;
  or   eax, byte 0x0E		; select register 0xE (header type)
  call pci.read_configuration_dword
  test eax, 0x00800000		; check if device supports multiple functions
  pop  eax			; restore bus/device/function #
  jz   short .next_device	; if not, go to next device #
  add  eax, 0x00000100		; go to next function number
  jmp  near .processing_list	;
.end:				;
  popad				; restore all registers + number of matches
  retn				; all done
;------------------------------------------------------------------------------
  
  
  
  


;------------------------------------------------------------------------------
globalfunc pci.list_class_code_devices
;------------------------------------------------------------------------------
;>
;; This functions sends the location of PCI devices that have a specific
;; Class Code to a specified function.
;;
;; parameters:
;;------------
;; EBX = 
;;  bit  7-0: reserved, must be 0
;;  bit 31-8: Class code to match
;; ECX = pointer to function to call with the details
;;
;; returned values:
;;-----------------
;; EAX = number of devices listed
;;
;; child function parameters:
;;---------------------------
;; EAX =
;;  bit  7- 0:   0
;;  bit 10- 8:  Function Number
;;  bit 15-11: Device ID
;;  bit 23-16: Bus Number
;;  bit 31-24: 0
;; EBX =
;;  bit  7- 0: Revision
;;  bit 31- 8: Class Code
;; ECX = pointer to child function
;; EDX =
;;  bit 15- 0: Vendor ID
;;  bit 31-16: Device ID
;; EBP = as received.
;<
;------------------------------------------------------------------------------
  xor eax, eax				; set number of matched devices to 0
  pushad				; backup all registers
  mov ebp, esp				; mark entry TOS
  mov ebx, dword 0xFFFFFFFF		; set DeviceID/VendorID to 'all'
  mov ecx, .callback			; set pointer to our child function
  call pci.list_vendor_devices		; list all the devices
  popad					; restore all registers
  retn					; return with eax = number of matches
					;
.callback:				;
  push ecx				; backup pointer to our .callback
  push ebx				; backup given class/revision
  mov bl, 0				; mask out revision
  cmp [ebp + 16], ebx			; compare the class codes
  pop ebx				; restore given class/revision
  jnz short .unmatched			; if class codes doesn't match
  push ebp				; backup our marked entry TOS
  mov ecx, [ebp + 24]			; load child function ptr of caller
  mov ebp, [ebp + 8]			; load its provided EBP
  call ecx				; call it
  mov eax, ebp				; backup its returned EBP
  pop ebp				; restore our marked entry TOS
  mov [ebp + 24], ecx			; save returned function ptr of caller
  mov [ebp + 8], eax			; save child function returned EBP val
  inc dword [ebp + 28]			; increment number of matches
.unmatched:				;
  pop ecx				; restore pointer to our .callback
  retn					;
;------------------------------------------------------------------------------





;------------------------------------------------------------------------------
globalfunc pci.generate_special_cycle
;------------------------------------------------------------------------------
;>
;; This function allows generation of PCI special cycles.  The generated special
;; cycle will be broadcast on a specific PCI bus in the system.
;;
;; Parameters:
;;------------
;; BH = Bus number
;; EDX = Special cycle data
;;
;; Returned values:
;;-----------------
;; if cf = 0, successful
;;    AH = 0
;;
;; if cf = 1, failed
;;    AH = FUNC_NOT_SUPPORTED = 0x81
;<



  struc irq_routing_table_entry
.pci_bus_number		resb 1	; PCI Bus Number
.pci_device_number	resb 1	; PCI Device Number
.link_for_inta		resb 1	; Link value for INTA#
.irq_bitmap_for_inta	resw 1	; IRQ bit-map for INTA#
.link_for_intb		resb 1	; Link value for INTB#
.irq_bitmap_for_intb	resw 1	; IRQ bit-map for INTB#
.link_for_intc		resb 1	; Link value for INTC#
.irq_bitmap_for_intc	resw 1	; IRQ bit-map for INTC#
.link_for_intd		resb 1	; Link value for INTD#
.irq_bitmap_for_intd	resw 1	; IRQ bit-map for INTD#
.slot_number		resb 1	; PCI Slot Number
.reserved		resb 1	; reserved for expansion
  endstruc


;------------------------------------------------------------------------------
globalfunc pci.get_interrupt_routing_options
;------------------------------------------------------------------------------
;>
;; This routine returns the PCI interrupt routing options available on the
;; system motherboard and also the current state of what interrupts are
;; currently exclusively assigned to PCI.  Routing information is returned in
;; a data buffer that contains an IRQ Routing for each PCI device or slot. The
;; format of an entry in the IRQ routing table is show in the struc above.
;;
;; Two values are provided for each PCI interrupt pin in every slot.  One of
;; these values is a bit-map that shows which of the standard AT IRQs this PCI
;; interrupt can be routed to.  This provides the routing options for one
;; particular PCI interrupt pin.  In this bit-map, bit 0 correspond to IRQ0, bit
;; 1 to IRQ1 etc.  A '1' bit in this bit-map indicates a routing is possible;
;; a '0' indicates no routing is possible.  The second value is a 'link' value
;; that provides a way of specifying which PCI interrupt pins are wire-OR'ed
;; together on the motherboard.  Interrupt pins that are wired together must
;; have the same 'link' value in their table entries.  Values for the 'link'
;; field are arbitrary except that the value zero indicates that the PCI
;; interrupt pin has no connection to the interrupt controller.
;;
;; The Slot Number value at the end of the structure is used to communicate
;; whether the table entry is for a motherboard device or an add-in slot.  For
;; motheboard devices, Slot Number should be set to zero.  For add-in slots,
;; Slot Number should be set to a value that corresponds with the physical
;; placement of the slot on the motherboard.  this provides a way to correlate
;; physical slots with PCI Device numbers.  Values (with the exception of  00h)
;; are OEM specific.  For end user ease-of-use, slots in the system should be
;; clearly labeled.
;;
;; This routine requires one parameter, 'RouteBuffer', that is a far pointer to
;; the data structure shown below:
;;
;;         struc IRQRoutingOptionsBuffer
;;    .buffer_size		resw 1
;;    .buffer_offset		resd 1
;;    .buffer_segment		resw 1
;;         endstruc
;;
;; Where '.buffer_size' is filled before the call by the caller, if the buffer
;;  was too small for the PCI Bios to place all the information, it will return
;;  a BUFFER_TOO_SMALL error code (0x89), and this field will be updated with
;;  the required size.  To indicate that the running PCI system does not have
;;  any PCI devices, this function will update the BufferSize field to zero.
;;  On successful completion, this field is updated with the size in bytes of
;;  the data returned.
;;
;;  '.data_offset' + '.data_segment' form a far pointer to the buffer containing
;;  PCI interrupt routing information or to be filled with information for all
;;  motherboard devices and slots.
;;
;; This routine also returns information about which IRQs are currently
;; dedicated for PCI usage.  this information is returned as a bit-map where a
;; set bit indicates that the IRQ is dedicated to PCI and not available for use
;; by devices on other buses.  Note that if an IRQ is routed such that it can
;; be used by PCI devices and other devices the corresponding bit in the bit-map
;; should not be set.  The function returns this informatino in the BX register
;; where bit 0 corresponds to IRQ0, bit 1 IRQ1...., the caller must initialize
;; BX to zero before calling the bios function, but this code takes care of it
;;
;; parameters:
;;------------
;; EDI = pointer to the struc IRQRoutingOptionsBuffer
;;
;; returned values:
;;-----------------
;; EAX is destroyed
;<
         struc IRQRoutingOptionsBuffer
    .buffer_size		resw 1
    .buffer_offset		resd 1
    .buffer_segment		resw 1
         endstruc



;------------------------------------------------------------------------------
globalfunc pci.read_configuration_byte
;------------------------------------------------------------------------------
;>
;; This function allows reading individual bytes from the configuration space of
;; a specific device
;;
;; parameters:
;;------------
;; EAX =
;;  bit	7-0:	register number
;;	10-8:	function number
;;	15-11:	device number
;;	23-16:	bus number
;;	31-24:	reserved, must be 0
;;	
;; returned values:
;;-----------------
;; EAX =
;;  bit  7- 0: configuration byte
;;  bit 31- 8: 0
;<
;------------------------------------------------------------------------------
  push edx				; save original edx value
  push eax				; save low 2bits of register #
  or   eax, dword 0x80000000		; enable configuration space
  and  eax, byte -4			; dword align register #
  mov  edx, dword 0x00000CF8		; port to send the request to
  out  dx, eax				; send bus/device/function/register #
  or   dl, byte 0x04			; select config data port
  in   eax, dx				; read in register dword
  pop  edx				; restore low 2bits of register #
  test dl, byte 0x02			; test low/high 16bit
  jz   short .low16_part		; bit 1 = 1 means high 16bit part
  shr  eax, byte 16			; get high 16 bit in the low part
.low16_part:				;
  test dl, byte 0x01			; test low/high 8bit
  jz   short .low8_part			; bit 0 = 1 means high 8bit part
  shr  eax, byte 8			; get high 8 bit in the low part
.low8_part:				;
  and  eax, dword 0x000000FF		; mask everything else
  pop  edx				; restore original edx value
  retn					;
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
globalfunc pci.read_configuration_word
;------------------------------------------------------------------------------
;>
;; similar to __read_pci_configuration_byte, except it reads a word
;;
;; parameters:
;;------------
;; EAX =
;;  bit	0:	register number lowest bit, must be 0
;;	7-1:	register number
;;	10-8:	function number
;;	15-11:	device number
;;	23-16:	bus number
;;	31-24:	reserved, must be 0
;;
;; returned values:
;;-----------------
;; EAX =
;;  bit 15- 0: configuration word
;;  bit 31-16: 0
;<
;------------------------------------------------------------------------------
  push edx				; save original edx value
  push eax				; save low 2bits of register #
  or   eax, dword 0x80000000		; enable configuration space
  and  eax, byte -4			; dword align register #
  mov  edx, 0x00000CF8			; configuration address port
  out  dx,  eax				; send bus/device/function/register #
  or   dl,  byte 0x04			; select config data port
  in   eax, dx				; read in register dword
  pop  edx				; restore low 2bits of register #
  test dl,  byte 0x02			; test low/high 16bit part
  jz   short .low16_part		; bit 1 = 1 means high 16bit
  shr  eax, byte 16			; get high 16 bit in the low part
.low16_part:				;
  and  eax, dword 0x0000FFFF		; mask everything else
  pop  edx				; restore original edx value
  retn					;
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
globalfunc pci.read_configuration_dword
;------------------------------------------------------------------------------
;>
;; similar to __read_pci_configuration_byte, except it reads a dword
;;
;; parameters:
;;------------
;; EAX =
;;  bit	0-1:	register number lower 2bits, must be 0
;;	7-2:	register number
;;	10-8:	function number
;;	15-11:	device number
;;	23-16:	bus number
;;	31-24:	reserved, must be 0
;;
;; returned values:
;;-----------------
;; EAX = configuration dword
;<
;------------------------------------------------------------------------------
  push edx				; save original edx value
  or   eax, dword 0x80000000		; enable configuration space
  and  eax, byte -4			; dword align register #
  mov  edx, 0x00000CF8			; select configuration address port
  out  dx,  eax				; send bus/device/function/register #
  or   dl,  byte 0x04			; select config data port
  in   eax, dx				; read in register dword
  pop  edx				; restore original edx value
  retn					;
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
globalfunc pci.write_configuration_byte
;------------------------------------------------------------------------------
;>
;; This function allows writing individual bytes from the configuration space of
;; a specific device
;;
;; parameters:
;;------------
;; EAX =
;;  bit	7-0:	register number
;;	10-8:	function number
;;	15-11:	device number
;;	23-16:	bus number
;;	31-24:	reserved, must 0
;; EBX =
;;  bit 7-0:	byte to send
;;  	31-8:	ignored
;;
;; returned values:
;;-----------------
;; EAX is destroyed
;<
;------------------------------------------------------------------------------
  push ecx				; save original ecx value
  push edx				; save original edx value
  push ebx				; save original ebx value
  or   eax, dword 0x80000000		; enable configuration space
  mov  ecx, dword 0x000000FF		; mask to use
  test al,  byte 0x02			; test low/high 16bit part
  jz   short .low16_part		; bit 1 = 1 means high 16bit
  shl  ecx, byte 16			; shift low part into high 16bit
  shl  ebx, byte 16			;
.low16_part:				;
  test al,  byte 0x01			; test low/high 8bit part
  jz   short .low8_part			; bit 0 = 1 means high 8bit
  shl  ecx, byte 8			; shift low part into high 8 bit
  shl  ebx, byte 8			;
.low8_part:				;
  and  eax, byte -4			; dword align register #
  mov  edx, dword 0x00000CF8		; select configuration address port
  out  dx, eax				; send bus/device/function/register #
  or   dl,  byte 0x04			; select config data port
  in   eax, dx				; read current register dword value
  and  ebx, ecx				; mask all ingored bits
  not  ecx				; invert the mask
  and  eax, ecx				; zeroize the byte we want to write
  or   eax, ebx				; write our byte value
  out  dx,  eax				; send the new dword register value
  pop  ebx				; restore original ebx value
  pop  edx				; restore original edx value
  pop  ecx				; restore original ecx value
  retn					;
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
globalfunc pci.write_configuration_word
;------------------------------------------------------------------------------
;>
;; similar to __write_pci_configuration_byte, except it writes a word
;;
;; parameters:
;;------------
;; EAX =
;;  bit	0:	register number lowest bit, must be 0
;;	7-1:	register number
;;	10-8:	function number
;;	15-11:	device number
;;	23-16:	bus number
;;	30-24:	reserved, always 0
;;	31:	configuration space enable (0 = disable, 1 = enable)
;; EBX =
;;  bit 15-0:	word to send
;;  	31-16:	ignored
;;
;; returned values:
;;-----------------
;; EAX is destroyed
;<
;------------------------------------------------------------------------------
  push ecx				; save original ecx value
  push edx				; save original edx value
  push ebx				; save original ebx value
  or   eax, dword 0x80000000		; enable configuration space
  mov  ecx, dword 0x0000FFFF		; mask to use 16bit
  test al,  byte 0x02			; test for low/high 16bit
  jz short .low16_part			; bit 1 = 1 means high 16bit
  shl  ecx, byte 16			; shift low part into high 16bit
  shl  ebx, byte 16			;
.low16_part:				;
  and  eax, byte -4			; dword align register #
  mov  edx, dword 0x00000CF8		; select configuration address port
  out  dx,  eax				; send bus/device/function/register #
  or   dl,  byte 0x04			; select configuration data port
  in   eax, dx				; read in current dword register value
  and  ebx, ecx				; mask all ingored bits
  not  ecx				; invert the mask
  and  eax, ecx				; zeroize the word we want to write
  or   eax, ebx				; write our word value
  out  dx,  eax				; send the new dword register value
  pop  ebx				; restore original ebx value
  pop  edx				; restore original edx value
  pop  ecx				; restore original ecx value
  retn					;
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
globalfunc pci.write_configuration_dword
;------------------------------------------------------------------------------
;>
;; similar to __read_pci_configuration_byte, except it writes a dword
;;
;; parameters:
;;------------
;; EAX =
;;  bit	0-1:	register number lower 2bits, must be 0
;;	7-2:	register number
;;	10-8:	function number
;;	15-11:	device number
;;	23-16:	bus number
;;	30-24:	reserved, always 0
;;	31:	configuration space enable (0 = disable, 1 = enable)
;; EBX =
;;  bit 31-0:	dword to send
;;
;<
;------------------------------------------------------------------------------
  push edx				; save original edx value
  or   eax, dword 0x80000000		; enable configuration space
  and  eax, byte -4			; dword align register #
  mov  edx, dword 0x00000CF8		; select configuration address port
  out  dx,  eax				; send bus/device/function/register #
  or   dl,  byte 0x04			; select configuration data port
  out  dx,  eax				; send out dword register value
  pop  edx				; restore original edx value
  retn					;
;------------------------------------------------------------------------------
