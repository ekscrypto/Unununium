;; Unununium Operating Engine
;; Copyright(C) 2001, Dave Poirier
;; Distributed under the BSD License
;;
;; * provided functions *
;;
;; pci.find_device 111
;; pci.find_class_code 112 
;; pci.generate_special_cycle 113
;; pci.get_interrupt_routing_options 114
;; pci.read_configuration_byte 115
;; pci.read_configuration_word 116
;; pci.read_configuration_dword 117
;; pci.write_configuration_byte 118
;; pci.write_configuration_word 119
;; pci.write_configuration_dword 120
;;
;; Additional Contributors:
;;-------------------------
;; Moutaz Haq - Noticed the ebx register issue when searching for the bios

;%define _DEBUG_


section .c_init
global _start
_start:

initialization:
  mov eax, "$PCI"
  xor ebx, ebx
  externfunc bios32.get_entry_point
  cmp al, 0
  stc
  jnz short .quit

  ; EBX = Physical address of the base Bios Service
  ; ECX = Size of the physical block of memory holding the Bios Service
  ; EDX = Entry point into to Bios Service, offset from base in EBX

  add edx,ebx
  mov [bios_entry_point], edx
  mov [code_segment], cs

  xor edx, edx
  mov eax, 0x0000B101
  call far [bios_entry_point]
  cmp edx, 0x20494350
  stc
  jnz short .quit

  ;]--PCI Bios present, saving hardware mechanism indicator
  mov [hardware_mechanism], al
  
  ;]--Save number of the last PCI bus in the system
  mov [last_pci_bus], cl

  mov [interface_level_version], bx
  clc
.quit:
  retn


;==============================================================================
section .data

bios_entry_point: dd 0
code_segment: dw 8
; Used together to make a far pointer to the PCI Bios entry point
; CS must have the same base address and size as DS when calling the bios and
; must encompass the entire given PCI Bios.


hardware_mechanism: db 0
; bit 0 = 1 means hardware config mechanism #1 is supported
; bit 1 = 1 means hardware config mechanism #2 is supported
; bit 2-3 are reserved
; bit 4 = 1 if special cycle supported via config mechanism #1
; bit 5 = 1 if special cycle supported via config mechanism #2
; bit 6-7 are reserved


last_pci_bus: db 0
; PCI buses are numbered starting at zero and returning up to the value
; here, which was specified in CL when calling PCI Bios Present service


interface_level_version:
.minor: db 0
.major: db 0
; Interface Level Major/Minor Version


section .text
;------------------------------------------------------------------------------
globalfunc pci.find_device
;------------------------------------------------------------------------------
;>
;; This functions returns the location of PCI devices that have a specific
;; Device ID and Vender ID.  Given a Vender ID, Device ID and an Index (N),
;; the function returns the Bus Number, Device Number, and Function Number of
;; the Nth Device/Function whose Vender ID and Device ID match the input params.
;;
;; parameters:
;;------------
;; CX = Device ID
;; DX = Vendor ID
;; SI = Index (0...N)
;;
;; returned:
;;----------
;; if cf = 0, successful
;;   AH = 0
;;   BL = Device/Function number
;;        bits 0-2: Function number
;;        bits 3-5: Device Number
;;   BH = Bus Number (0...255)
;; if cf = 1, failed
;;   AH = error code
;<
;
  mov eax, 0x0000B102
  call far [bios_entry_point]
  retn

;------------------------------------------------------------------------------
globalfunc pci.find_class_code
;------------------------------------------------------------------------------
;>
;; This function returns the location of PCI devices that have a specific Class
;; Code.  Given a Class Code and an Index (N), the function returns the Bus
;; Number, Device Number and Function NUmber of the Nth Device/Function whose
;; Class Code matches the input parameters.
;;
;; parameters:
;;------------
;; ECX = Class code (in lowest 3 bytes)
;; SI  = index number
;;
;; returned values:
;;-----------------
;; if cf = 0, successful
;;  AH = 0
;;  BL = Device Number/Function number
;;       bits 0-2: Function number
;;       bits 3-7: Device number
;;  BH = Bus number (0...255)
;;
;; if cf = 1, failed
;;  AH = PCI Error code, most probably DEVICE_NOT_FOUND 0x86
;<
  mov eax, 0x0000B103
  call far [bios_entry_point]
  retn


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

  mov eax, 0x0000B106
  call far [bios_entry_point]
  retn


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
;; if cf = 0, successful
;;   AH = 0
;;   BX = IRQ bit-map of dedicated irq lines to PCI devices
;; if cf = 1, failed
;;   AH = PCI error code
;;        0x89 = BUFFER_TO_SMALL
;;        0x81 = FUNC_NOT_SUPPORTED
;<
         struc IRQRoutingOptionsBuffer
    .buffer_size		resw 1
    .buffer_offset		resd 1
    .buffer_segment		resw 1
         endstruc


  xor ebx,ebx
  mov eax, 0x0000B10E
  call far [bios_entry_point]
  retn


;------------------------------------------------------------------------------
globalfunc pci.read_configuration_byte
;------------------------------------------------------------------------------
;>
;; This function allows reading individual bytes from the configuration space of
;; a specific device
;;
;; parameters:
;;------------
;; BL  = Device number in upper 5 bits
;;       Function number in lower 3 bits
;; BH  = Bus number
;; EDI = Register number (0...255)
;;
;; returned values:
;;-----------------
;; if cf = 0, successful
;;   AH  = 0
;;   CL  = Byte read
;; if cf = 1, failed
;;   AH  = PCI Error returned
;<

  mov eax, 0x0000B108
  call far [bios_entry_point]
  retn

;------------------------------------------------------------------------------
globalfunc pci.read_configuration_word
;------------------------------------------------------------------------------
;>
;; similar to __read_pci_configuration_byte, except it reads a word
;;
;; parameters:
;;------------
;; BL  = Device number in upper 5 bits
;;       Function number in lower 3 bits
;; BH  = Bus number
;; EDI = Register number (0,2,4,6...254)
;;
;; returned values:
;;-----------------
;; if cf = 0, successful
;;   AH  = 0
;;   CX  = Word read
;; if cf = 1, failed
;;   AH  = PCI Error returned
;<

  mov eax, 0x0000B109
  call far [bios_entry_point]
  retn


;------------------------------------------------------------------------------
globalfunc pci.read_configuration_dword
;------------------------------------------------------------------------------
;>
;; similar to __read_pci_configuration_byte, except it reads a dword
;;
;; parameters:
;;------------
;; BL  = Device number in upper 5 bits
;;       Function number in lower 3 bits
;; BH  = Bus number
;; EDI = Register number (0,4,8,...252)
;;
;; returned values:
;;-----------------
;; if cf = 0, successful
;;   AH  = 0
;;   ECX  = Dword read
;; if cf = 1, failed
;;   AH  = PCI Error returned
;<

  mov eax, 0x0000B10A
  call far [bios_entry_point]
  retn



;------------------------------------------------------------------------------
globalfunc pci.write_configuration_byte
;------------------------------------------------------------------------------
;>
;; This function allows writing individual bytes from the configuration space of
;; a specific device
;;
;; parameters:
;;------------
;; BL  = Device number in upper 5 bits
;;       Function number in lower 3 bits
;; BH  = Bus number
;; CL  = Byte value to write
;; EDI = Register number (0...255)
;;
;; returned values:
;;-----------------
;; if cf = 0, successful
;;   AH  = 0
;; if cf = 1, failed
;;   AH  = PCI Error returned
;<

  mov eax, 0x0000B10B
  call far [bios_entry_point]
  retn

;------------------------------------------------------------------------------
globalfunc pci.write_configuration_word
;------------------------------------------------------------------------------
;>
;; similar to __write_pci_configuration_byte, except it writes a word
;;
;; parameters:
;;------------
;; BL  = Device number in upper 5 bits
;;       Function number in lower 3 bits
;; BH  = Bus number
;; CX  = Word value to write
;; EDI = Register number (0,2,4,6...254)
;;
;; returned values:
;;-----------------
;; if cf = 0, successful
;;   AH  = 0
;; if cf = 1, failed
;;   AH  = PCI Error returned
;<

  mov eax, 0x0000B10C
  call far [bios_entry_point]
  retn


;------------------------------------------------------------------------------
globalfunc pci.write_configuration_dword
;------------------------------------------------------------------------------
;>
;; similar to __read_pci_configuration_byte, except it reads a dword
;;
;; parameters:
;;------------
;; BL  = Device number in upper 5 bits
;;       Function number in lower 3 bits
;; BH  = Bus number
;; ECX = Dword value to write
;; EDI = Register number (0,4,8,...252)
;;
;; returned values:
;;-----------------
;; if cf = 0, successful
;;   AH  = 0
;; if cf = 1, failed
;;   AH  = PCI Error returned
;<

  mov eax, 0x0000B10D
  call far [bios_entry_point]
  retn


