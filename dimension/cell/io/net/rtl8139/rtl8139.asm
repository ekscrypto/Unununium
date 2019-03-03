;;=======================================
;; Unununium Operating Engine
;; Realtek RTL8139 driver
;; Copyright (c) 2002, Niklas Kluegel
;; Distributed under the BSD License
;;=======================================
;; This is a working rtl8139 driver,
;; however it is a quick hack.
;; The skeleton itself is okay and capable
;; of handling mutiple devices, but the
;; functions interfacing to it are not. They
;; are pretty unoptimized. The api itself is
;; just a quick hack and may be changed 
;; soon.
;; Therefore, don't rely on the driver too
;; much.
;;
;; The implemented functions are:
;; - send packet
;; - receive packet
;; - basic stats such as rx packets/bytes
;;   and tx packets/bytes
;; - important data such as the mac address
;;   can be found in the device structure 
;; 
;; NOTE: the reset (_reset) function, 
;; although it seems to be properly implemented, 
;; is responsible for the rtl8139 to stop working.
;;=======================================

section .c_info
  db 1,0,0,0
  dd str_cellname
  dd str_author
  dd str_copyright

  str_cellname:
  db "Realtek RTL8139 Driver",0
  str_author:
  db "lodsb",0
  str_copyright:
  db "Copyright (c) 2002, Niklas Kluegel (lodsb@lodsb.org)",0x0A
  db "Distributed under the BSD License",0x0A
  db "Visit http://www.lodsb.org for further information.",0x0
  
%include "macros.inc"
%include "vid/pci.inc"
%include "../cell/io/net/rtl8139/rtl8139_vcm.inc"


[bits 32]

section .c_init


_detect_and_setup_nic:

mov esi , device_ids
xor edx , edx 
.search_device:
	mov bx 	, [esi+2]
	shl ebx 	, 16
	mov bx 	, [esi] 
	mov ecx, _setup_nic
	externfunc pci.list_vendor_devices
	add edx , eax								;; eax returns the number the devices which have been found 
	add esi 	, 4
	cmp word [esi] , -1
	jne .search_device
   cmp edx , 0								;; if edx = 0 then we did not successfully detect a compatible device
jne .end


lprint {"[Realtek RTL8139 Driver] ERROR: Hardware not found!",0x0A}, FATALERR
retn

.end:
retn

globalfunc rtl8139.setup
;; - - - - - - - - - - - - - - - - - - - - - - -
;; PARAMETERS:
;; esi - pointer to rx callback function
;;       this will be called with
;;       esi - pointer to the received packet
;;       ecx - size of the packet
;; RETURNS :
;; esi - pointer to device structure 
;;       refer to rtl8139_vcm.inc 
;; - - - - - - - - - - - - - - - - - - - - - - -
push ebx 
mov ebx , [current_dev_struct_ptr]
mov [ebx+device_struct.rx_callback] , esi
mov esi , ebx
pop ebx
retn

globalfunc rtl8139.down
;; - - - - - - - - - - - - - - - - - - - - - - -
;; PARAMETERS: -
;; - - - - - - - - - - - - - - - - - - - - - - - 
push ebx
mov ebx , [current_dev_struct_ptr]
mov [ebx+device_struct.rx_callback], dword 0 
mov [ebx+device_struct.rx_packets] , dword 0 
mov [ebx+device_struct.tx_packets] , dword 0 
mov [ebx+device_struct.rx_bytes] 	, dword 0 
mov [ebx+device_struct.tx_bytes] 	, dword 0 
pop ebx
retn

globalfunc rtl8139.send
;; - - - - - - - - - - - - - - - - - - 
;; PARAMETERS:
;; esi - address of the packet to send
;; ecx - size in bytes of the packet
;; - - - - - - - - - - - - - - - - - - 
	mov ebx , [current_dev_struct_ptr]
	mov edi , [ebx+device_struct.tx_buffer_ptr]
	add [ebx+device_struct.tx_bytes], ecx
	push edi
	push ecx
	call _copy_buffer
	pop ecx
	pop esi
	call _xmit
	retn

_receive:
;; Check if the buffer is empty
.check_buffer:
		rxbuf_tailreg_to_tail RxBufTail 	;; returns tail in ebx
		mov dl , RxBufHead
		io_reg_read_word
		cmp ebx, eax 
		jne .check_cmd_buffer
		retn
	.check_cmd_buffer:
		mov dl , ChipCmd
		io_reg_read_byte
		test al , ChipCmdBits.RxBufEmpty
		jz .check_buffer_in_process
		retn
	.check_buffer_in_process:
		mov edx , [current_dev_struct_ptr]
		add ebx , [edx+device_struct.rx_buffer_ptr]
		cmp [ebx+rx_entry.length] , word 0xFFF0
		jne .check_buffer_error_status
		retn
	.check_buffer_error_status:
		sub [ebx+rx_entry.length] , word 4	;; subtract the CRC
		test [ebx+rx_entry.status] , word RxStatusBits.StatusOK
		jnz .check_buffer_error_max_length
		call reset
		retn
	.check_buffer_error_max_length:
		cmp [ebx+rx_entry.length] , word ETHER_II_MAX_SIZE
		jbe .copy_buffer
		call reset
		retn
	.copy_buffer:
		movzx ecx , word [ebx+rx_entry.length]
		push ebx 
		rxbuf_tailreg_to_tail RxBufTail
		add ebx , ecx
		cmp ebx , 0xFFFF
		jb .packet_does_not_wrap
		rxbuf_tailreg_to_tail RxBufTail
		add ebx , 4
		mov eax , 0x10000
		sub eax , ebx
		pop ebx 
		push eax
		push ecx 
		mov ecx , eax 
		lea esi , [ebx+rx_entry.data]
		mov edi , [edx+device_struct.frag_rx_buf_ptr]
		call _copy_buffer
		pop ecx
		pop eax
		push ecx 
		sub eax, ecx
		mov esi , [edx+device_struct.rx_buffer_ptr]
		call _copy_buffer
		mov esi , [edx+device_struct.frag_rx_buf_ptr]
		jmp .calculate_new_tail
		
		.packet_does_not_wrap:
		pop ebx 
		lea esi   , [ebx+rx_entry.data]
		push ecx
	.calculate_new_tail:
		rxbuf_tailreg_to_tail RxBufTail
		pop ecx			;; mov ecx , [esp]
		push ecx
		add ebx , ecx
		add ebx , 8+3
		and ebx , 0xFFFFFFFC  			;; align 4 byte 
		mov eax , 0x10000
		xchg eax , ebx
		xor edx , edx 
		div ebx
		rxbuf_tail_to_tailreg edx
		mov eax , edx	
		mov dl  , RxBufTail
		io_reg_write_word
		mov dl , RxBufHead
		io_reg_read_word
											;; ptr to current dev struct
		pop ecx							;; tx size
											;; esi holds the ptr to packet
		mov edx, [current_dev_struct_ptr]
		add [ebx+device_struct.rx_bytes] , ecx
		inc dword [ebx+device_struct.rx_packets] 
		cmp [edx+device_struct.rx_callback], dword 0
		je .end
		add [edx+device_struct.rx_bytes] , ecx
		inc dword [edx+device_struct.rx_packets]
		call [edx+device_struct.rx_callback]
.end:

retn


_xmit:
;; - - - - - - - - - - - - - - - - - - 
;; PARAMETERS:
;; esi - address of the packet to send
;; ecx - size in bytes of the packet
;; - - - - - - - - - - - - - - - - - - 
cli
pushad 								

	mov eax , [current_dev_struct_ptr]
	;; calculate TSAD 
	movzx edx ,  byte [eax+device_struct.tsad_number]
	shl edx , 2	
	add edx , TxStatus 			
	mov ebx , edx
	
.test_tsad_ready:
	
	io_reg_read_dword
	test eax ,TxStatusBits.HostOwns 
	jnz .set_ptr_to_packet
	mov edx , ebx
	inc ecx 
	mov [0xb8000], dword ecx
	jmp .test_tsad_ready
	
.set_packet_status:
	or eax 	, 0x80000
	mov ecx , [esp+24]
	mov ecx , eax
	or eax 	, ecx
	
.set_ptr_to_packet:
	mov edx , ebx
	add edx , 0x10 
	mov eax , esi
	io_reg_write_dword

	mov edx , ebx
.activate_fifo:
	mov eax , ecx 
	io_reg_write_dword
	inc_tsad_buf_ptr

popad
sti
retn



reset:
pushad
;; Reset the device
	lprint {"[Realtek RTL8139 Driver] Resetting device..."}, FATALERR
	
	xor eax , eax 
	mov dl  , RxBufTail
	io_reg_write_word

	;; Set IMR - diable all interrupts
	mov dl  , IntrMask
	xor eax, eax 
	io_reg_write_word

	xor ecx , ecx
	.reset:
	cmp ecx , 1000000
	je .reset_failed
	mov dl  , ChipCmd
	mov al  , ChipCmdBits.CmdReset
	io_reg_write_byte
	mov dl  , ChipCmd
	mov al  , ChipCmdBits.CmdReset
	io_reg_read_byte
	inc ecx
	test al , ChipCmdBits.CmdReset
	jnz .reset
	lprint {"[Realtek RTL8139 Driver] done"}, FATALERR
	jmp .reset_successfull
	
	.reset_failed:
	lprint {"[Realtek RTL8139 Driver] failed!"}, FATALERR
	popad
	retn
	
	.reset_successfull:
	xor eax, eax
	mov dl , RxBufTail
	io_reg_write_word
	
	;; Set IMR
	mov dl  , IntrMask
	xor eax, eax 
	mov ax , IMR
	io_reg_write_word

	mov ebx , [current_dev_struct_ptr]	

	;; Setup RX buffer
	mov dl , RxBufAddr
	mov eax, [ebx+device_struct.rx_buffer_ptr]
	io_reg_write_dword

	;; Reset RxMissed counter
	mov dl  , RxMissed
	xor eax , eax
	io_reg_write_dword
	
	;; Enable Tx/Rx
	mov dl  , ChipCmd
	mov al  , ChipCmdBits.CmdTxEnb
	or al , ChipCmdBits.CmdRxEnb
	io_reg_write_byte

popad
retn
	
_setup_nic:
	;; EAX =
	;;  bit  7- 0: 0
	;;  bit 10- 8: Function Number
	;;  bit 15-11: Device Number
	;;  bit 23-16: Bus Number
	;;  bit 31-24: 0
	;; EBX =
	;;  bit  7- 0: Revision
	;;  bit 31- 8: Class Code
	push edx 
	push eax 
	push eax
	;;
	;; Allocate memory for device structure
	;;
	mov ecx , device_struct_size
	externfunc mem.alloc
	;;
	;; setup linked list
	;;
	mov esi , linked_list_root
	cmp [esi] , dword 0
	je .search_end_of_linked_list
	mov [linked_list_root] , edi 
	jmp .linked_list_entry_added

	
	.search_end_of_linked_list:
	cmp [esi+device_struct.next_ptr] , dword -1
	je .linked_list_entry
	mov esi , [esi+device_struct.next_ptr]
	jmp .search_end_of_linked_list
	
	.linked_list_entry:
	mov [esi+device_struct.next_ptr] , edi
	
	.linked_list_entry_added:
	mov [edi+device_struct.next_ptr] , dword -1 
	pop eax
	push eax 
	mov al , 0x14
	externfunc pci.read_configuration_dword
	mov [edi+device_struct.dev_mem_addr] , eax
	;;lprint {"[Realtek RTL8139 Driver] MemoryAddress : %x" } , FATALERR,eax

	mov eax , [esp+4]
	mov al , 0x10
	externfunc pci.read_configuration_word
	dec eax 
	mov [edi+device_struct.dev_io_addr] , ax
	;;lprint {"[Realtek RTL8139 Driver] I/O Address : %x" } , FATALERR,eax

	mov [current_dev_io_addr] , ax 

	pop eax
	mov al , 60
	externfunc pci.read_configuration_byte
	mov [edi+device_struct.dev_irq] , al
	;;lprint {"[Realtek RTL8139 Driver] IRQ: %d  "},FATALERR, eax
	
	cli 
	
	mov [current_dev_struct_ptr] , edi 
	mov ebx , edi 

	;; Get RTL81XX`s MAC address
	mov dl , MAC0
	push dx
	mov cl , 3
	movzx ecx , cl
	lea edi , [edi+device_struct.mac_addr]
	.get_mac_address:
	io_reg_read_word
	stosw
	pop dx
	add dx , 2
	push dx
	loop .get_mac_address
	add esp , 2
	
	;; Print the MAC address
	;; pushad
	;; movzx eax , byte [current_dev_struct_ptr+device_struct.mac_addr]
	;; movzx ebx , byte [current_dev_struct_ptr+device_struct.mac_addr+1]
	;; movzx ecx , byte [current_dev_struct_ptr+device_struct.mac_addr+2]
	;; movzx edx , byte [current_dev_struct_ptr+device_struct.mac_addr+3]
	;; movzx esi , byte [current_dev_struct_ptr+device_struct.mac_addr+4]
	;; movzx edi , byte [current_dev_struct_ptr+device_struct.mac_addr+5]
	;; lprint {"[Realtek RTL8139 Driver] MAC-Address:",0x0A,"%x:%x:%x:%x:%x:%x  "},FATALERR, eax, ebx, ecx , edx , esi , edi
	;; popad
	
	;; Reset the device
   lprint {"[Realtek RTL8139 Driver] Resetting device..."}, FATALERR
	xor ecx , ecx
	.reset:
	cmp ecx , 10000
	je .reset_failed
	mov dl  , ChipCmd
	mov al  , ChipCmdBits.CmdReset
	io_reg_write_byte
	
	mov dl  , ChipCmd
	mov al  , ChipCmdBits.CmdReset
	io_reg_read_byte
	inc ecx
	test al , ChipCmdBits.CmdReset
	jnz .reset
	lprint {"[Realtek RTL8139 Driver] done"}, FATALERR
	jmp .allocate_rx
	
	.reset_failed:
	lprint {"[Realtek RTL8139 Driver] failed!"}, FATALERR
	pop eax 
	pop edx 
	retn
	.allocate_rx:
	;; Allocate rx buffer
	mov ecx , 64*1024+16
	externfunc mem.alloc
	mov [ebx+device_struct.rx_buffer_ptr], edi

	mov ecx , 0x800						;;  0x800 block is for the rx buffer for fragmented packets
	externfunc mem.alloc									
	mov [ebx+device_struct.frag_rx_buf_ptr] , edi
	
	;; Enable writing to Cfg9346
	mov dl  , Cfg9346
	mov al  , 0xc
	io_reg_enable_bits_write_byte
	;; Reset Config
	mov dl , Config1
	xor al , al 
	io_reg_write_byte
	
	;; Enable Tx/Rx
	mov dl  , ChipCmd
	mov al  , ChipCmdBits.CmdTxEnb
	or al , ChipCmdBits.CmdRxEnb
	io_reg_write_byte

	;; Set RCR
	mov dl  , RxConfig
	mov eax , RxConfigR
	io_reg_write_dword	

	;; Set TCR
	mov dl  , TxConfig
	mov eax , TCR
	io_reg_write_dword

	;; Turn off wake on lan & enable driver loaded bit
	mov dl , Config1
	io_reg_read_byte
	and al , 0xCF
	or  al , 0x20
	mov dl , Config1
	io_reg_write_byte

	;; Enable FIFO auto-clear
	mov dl , Config4
	io_reg_read_byte
	or  al , 0x80
	io_reg_write_byte

	;; Disable writing to Cfg9346
	mov dl , Cfg9346
	xor al , al 
	io_reg_write_byte
	
	;; Setup RX buffer
	mov dl , RxBufAddr
	mov eax, [ebx+device_struct.rx_buffer_ptr]
	io_reg_write_dword

	;; Reset RxMissed counter
	mov dl  , RxMissed
	xor eax , eax
	io_reg_write_dword

	;; Filter out all multicast packages
	mov dl , MAR0
	xor eax, eax
	io_reg_write_dword
	mov dl , MAR0+4
	xor eax, eax
	io_reg_write_dword

	;; Disable all multi-interrupts
	mov dl , MultiIntr
	xor eax,eax
	io_reg_write_word

	;; Set IMR
	mov dl  , IntrMask
	xor eax, eax 
	mov ax , IMR
	io_reg_write_word
	
	;; Enable Tx/Rx
	mov dl  , ChipCmd
	mov al  , ChipCmdBits.CmdTxEnb
	or al , ChipCmdBits.CmdRxEnb
	io_reg_write_byte


	;; Disable writing to Cfg9346
	mov dl , Cfg9346
	xor al , al 
	io_reg_write_byte
	;; generate IRQ callback function
	;; the irq handler function is being copied
	;; somewhere in the memory 	
	mov ecx , _irq_handler_size+5					;; 5 bytes for the get_ip eax instruction
	externfunc mem.alloc
	mov [ebx+device_struct.irq_handler_ptr] , edi
	mov [_smc_dev_struct_ptr.get_ptr]	, ebx				;; patches the mov eax , 0 to mov eax , current offset
	push edi
	mov esi , _smc_dev_struct_ptr
	mov ecx , 5										;; copy the eax instruction
	call _copy_buffer
	mov esi , _irq_handler
	mov ecx , _irq_handler_size-5
	call _copy_buffer	
	;; Hook IRQ
	mov ebx , current_dev_io_addr
	mov al , [ebx+device_struct.dev_irq]
	pop esi 
	externfunc int.hook_irq
	jnc .hook_ok
	lprint {"[Realtek RTL8139 Driver] ERROR: Unable to hook device-IRQ!"}, FATALERR
	pop eax 
	pop edx 
	retn
	
	.hook_ok:
	
	;;
	;;
	;; devfs : register driver HERE	
	mov [ebx+device_struct.tsad_number], byte 0
	
	mov [ebx+device_struct.rx_callback], dword 0		
	mov ecx , TX_BUFFER_SIZE+4
	call mem.alloc
	and edi , 0xFFFFFFFC				; make 4 byte aligned 	
	mov [ebx+device_struct.tx_buffer_ptr] , dword edi
	sti
	pop eax
	pop edx 
retn

_copy_buffer:
;; _ _ _ _ _ _ _ _ _ _ _ _ _ 
;; internal function
;; 
;; ecx - number of bytes
;; esi - ptr to source
;; edi - ptr to destination
;; _ _ _ _ _ _ _ _ _ _ _ _ _ 
.check_odd:
	test ecx , 1
	jnz .check_even_word
	movsb
.check_even_word:
	test ecx , 2
	jnz .copy_buffer
	movsw
.copy_buffer:
	shr ecx , 2			;; divide by 4
	rep movsd
retn




_irq_handler:
cli
	mov [current_dev_struct_ptr] , eax
	movzx ebx , word [eax+device_struct.dev_io_addr]
	mov [current_dev_io_addr] , bx
	
	mov dl , IntrStatus		
	io_reg_read_word
	;; acknowledge interrupt
	mov dl , IntrStatus	 	
	io_reg_write_word

	test ax ,IntrStatusBits.RxOK
	jnz .irq_rok 	;; recieve ok

	test ax ,IntrStatusBits.RxErr
	jnz .irq_rer	;; recieve error


	test ax ,IntrStatusBits.TxOK
	jnz .irq_tok	;; send ok
	test ax ,IntrStatusBits.TxErr
	jnz .irq_ter	;; send error

	test ax ,IntrStatusBits.RxOverflow
	jnz .irq_rxovw	;; rx buffer overflow

	test ax ,IntrStatusBits.RxUnderrun
	jnz .irq_pun	;; link status changed

	test ax ,IntrStatusBits.RxFIFOOver
	jnz .irq_fovw	;; rx fifo overflow

	test ax ,IntrStatusBitsCableChanged
	jnz .irq_lengchg ;; cable length changed after rx enabled

	test ax ,IntrStatusBitsPCSTimeOut
	jnz .irq_timeout ;; timeout

	test ax ,IntrStatusBits.PCIErr	
	jnz .irq_serr    ;; system error 	
sti
clc
retn
			.irq_rok:
			mov ecx , _receive
			call ecx
			retn
	
			.irq_rer:
			mov ecx , _receive
			call ecx
			retn
	
			.irq_tok:
			mov ebx , [current_dev_struct_ptr]
			inc dword [ebx+device_struct.tx_packets]
			retn

			.irq_ter:
			retn
			
			.irq_rxovw:
			retn

			.irq_fovw:
			retn

			.irq_pun:
			retn

			.irq_lengchg:
			retn

			.irq_timeout:
			retn
			.irq_serr:
			retn
_irq_handler_size : dw $ - _irq_handler
