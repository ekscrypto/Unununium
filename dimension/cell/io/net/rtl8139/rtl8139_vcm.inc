;;=====================================
;; Unununium Operating Engine
;; Realtek RTL8139 driver, second edition
;; Copyright (c) 2002, Niklas Kluegel
;; Distributed under the BSD License
;;=====================================

%define ETHER_II_HEADER 6+6+2		;; will be replaced by a small cell
%define ETHER_II_MIN_SIZE ETHER_II_HEADER + 46
%define ETHER_II_MAX_SIZE ETHER_II_HEADER + 1500
%define TX_BUFFER_SIZE 0x800

;;	]--- Structures ---[
;;
;;
;;
 
struc rx_entry
	.status 	: resw 1
	.length 	: resw 1
	.data		: resb 1
endstruc

;struc tx_entry
	;.length	: resw 1
	;.data		: resb 1
;endstruc


;; Driver structure for internal and 
;; global handling
struc device_struct
	;; internal structure
	.next_ptr				: resd 1
	.rtl_dev_no 			: resb 1
	.rx_buffer_ptr		: resd 1
	.frag_rx_buf_ptr	: resd 1 
	.rx_callback			: resd 1
	.tsad_number	 		: resb 1
	.tx_buffer_ptr		: resd 1
	.dev_io_addr			: resw 1
	.dev_mem_addr		: resd 1
	.dev_pci_config_fdb	: resd 1
	.dev_irq				: resb 1
	.irq_handler_ptr	: resd 1
	;; global structure
	.dev_class			: resd 1
	.dev_subclass		: resd 1
	.dev_vendor_name  	: resb 24
	.dev_device_name	: resb 32
	.mac_addr				: resb 16
	.rx_packets			: resd 1
	.tx_packets			: resd 1
	.rx_bytes				: resd 1
	.tx_bytes				: resd 1 
;	.mac_address_len	: resb 1
;	.status				: resb 3
	.reserved				: resd 32
endstruc 


struc _irq_handler_struct
	.data_dev_struct_ptr	: resd 1
	.handler				: resb 1
endstruc


;;	]--- Variables ---[
;;
;;
;;

_smc_dev_struct_ptr:
mov eax , 0				;; = B4 00 00 00 00
.get_ptr EQU $-4		;; = pointer to the last 4 bytes


linked_list_root			: dd 0
current_dev_struct_ptr	: dd 0 
current_dev_io_addr		: dd 0 
rtl8139_name				: db "RTL8139",0xA
rtl8139_vend_nam			: db "Realtek Semiconductor Corp.",0xA
rtl8139_rev_id			: db "ABCD",0xA

;; ]--- Device IDs ---[
;; Some RTL8139 compatible cards have 
;; a different vendor and device ID

device_ids:
.rtl8139_vendor	: dw 0x10EC 
.rtl8139_dev		: dw 0x8139
.smc1211_vendor  	: dw 0x1113
.smc1211_dev		: dw 0x1211
.end				: dw -1 


;; ]-- Setup Parameters --[
;;
;;
;;

RxConfigR		EQU 	 	0x00009c1F
TCR				EQU 		0x03000400
IMR				EQU   		0xF
   


;;	]--- Constants ---[
;; Hardware specific registers
;; 
;; 

MAC0 					EQU 0x0			;; Ethernet HW Address
MAR0 					EQU 0x8			;; Multicast Filter

TxStatus 				EQU 0x10			;; Transmit Status (four 32bit regs)
TxAddr0 				EQU 0x20			;; Tx Descriptors (also four 32bit regs)
TxConfig 				EQU 0x40	

RxBufAddr				EQU 0x30
RxEarlyCnt 			EQU 0x34
RxEarlyStatus 		EQU 0x36
RxBufTail 				EQU 0x38
RxBufHead 				EQU 0x3A
RxConfig 				EQU 0x44
RxMissed 				EQU 0x4C			;; 24 bits valid, write clears

ChipCmd 				EQU 0x37
IntrMask 				EQU 0x3C
IntrStatus 			EQU 0x3E

Timer 					EQU 0x48

Cfg9346 				EQU 0x50
Config0 				EQU 0x51
Config1 				EQU 0x52
Config3				EQU 0x59
Config4				EQU 0x5A

FlashReg 				EQU 0x54
GPPinData 				EQU 0x58
GPPinDir 				EQU 0x59

MII_SMI 				EQU 0x5A
MII_BMCR 				EQU 0x62
MII_BMSR 				EQU 0x64

NWayAdvert 			EQU 0x66
NWayLPAR 				EQU 0x68
NWayExpansion 		EQU 0x6A

HltClk 				EQU 0x5B
MultiIntr 				EQU 0x5C
TxSummary 				EQU 0x60

FIFOTMS 				EQU 0x70			;; Fifo Control and test
CSCR					EQU 0x74			;; Chip Status and config reg
PARA78 				EQU 0x78			;; Magic transreceiver parameter reg
PARA7C					EQU 0x7C

;;
;; Chip command bits
;;
ChipCmdBits.CmdReset 	EQU 0x10
ChipCmdBits.CmdRxEnb		EQU 0x08
ChipCmdBits.CmdTxEnb		EQU 0x04
ChipCmdBits.RxBufEmpty	EQU 0x01

;;
;; Interrupt register bits
;;
IntrStatusBits.TxErr			EQU 0x08
IntrStatusBits.TxOK			EQU 0x04
IntrStatusBits.RxErr			EQU 0x02
IntrStatusBits.RxOK			EQU 0x01
IntrStatusBits.PCIErr		EQU 0x8000
IntrStatusBitsPCSTimeOut	EQU 0x4000
IntrStatusBitsCableChanged 	EQU 0x2000
IntrStatusBits.RxFIFOOver	EQU 0x40
IntrStatusBits.RxUnderrun	EQU 0x20
IntrStatusBits.RxOverflow	EQU 0x10

;;
;; Tx Status Bits
;;
TxStatusBits.HostOwns 		EQU 0x2000
TxStatusBits.Underrun		EQU 0x4000
TxStatusBits.StatOk			EQU 0x8000
TxStatusBits.OutOfWindow	EQU 0x20000000
TxStatusBits.Aborted			EQU 0x40000000
TxStatusBits.CarrierLost	EQU 0x80000000

;;
;; Rx Status Bits
;;
RxStatusBits.Multicast		EQU 0x8000
RxStatusBits.Physical		EQU 0x4000
RxStatusBits.Broadcast		EQU 0x2000
RxStatusBits.BadSymbol		EQU 0x0020
RxStatusBits.Runt				EQU 0x0010
RxStatusBits.TooLong			EQU 0x0008
RxStatusBits.CRCErr			EQU 0x0004
RxStatusBits.BadAlign		EQU 0x0002
RxStatusBits.StatusOK		EQU 0x0001

;;	]--- Macros for I/O Access ---[
;;  Parameters : 
;;  read : 	
;;	eax 	- value read from io-port
;;     dl	- 8bit RTL register #
;;  write : 
;;	eax 	- value to write
;;	  dl	- 8bit RTL register #
;;
;;  Bit enable:
;;  eax - bits to enable
;;  dl	- 8bit RTL register #

%macro io_reg_write_byte 0
xor 	dh , dh
add 	dx , [current_dev_io_addr]
out 	dx  , al
%endmacro

%macro io_reg_write_word 0
xor 	dh , dh
add 	dx , [current_dev_io_addr]
out 	dx  , ax
%endmacro

%macro io_reg_write_dword 0
xor 	dh , dh
add 	dx , [current_dev_io_addr]
out 	dx  , eax
%endmacro

%macro io_reg_read_byte 0
xor 	dh , dh
add 	dx , [current_dev_io_addr]
in	 	al , dx
%endmacro

%macro io_reg_read_word 0 
xor 	dh , dh
add 	dx , [current_dev_io_addr]
in	 	ax , dx
%endmacro

%macro io_reg_read_dword 0 
xor 	dh , dh
add 	dx , [current_dev_io_addr]
in	 	eax , dx
%endmacro

%macro io_reg_enable_bits_write_byte 0
push ebx
push dx
push eax
io_reg_read_byte
pop ebx
or eax , ebx
pop dx
io_reg_write_byte
pop ebx 
%endmacro


%macro inc_tsad_buf_ptr 0
push eax 
push edi
mov edi , [current_dev_struct_ptr]
mov al , byte [edi+device_struct.tsad_number]
cmp al , 3
jne %%i_tbp_dont_reset_tx_buffer_ptr
mov [edi+device_struct.tsad_number] , byte 0
jmp %%i_tbp_end
%%i_tbp_dont_reset_tx_buffer_ptr:
inc byte [edi+device_struct.tsad_number] 
%%i_tbp_end:
pop edi
pop eax 
%endmacro

%macro check_tsad_buf_ptr 0
push eax 
mov edi , [current_dev_struct_ptr]
mov al , byte [edi+device_struct.tsad_number]
cmp al , 3
jne %%check_tbp_end
mov [edi+device_struct.tsad_number] , byte 0
%%check_tbp_end:
pop eax 
%endmacro

%macro rxbuf_tailreg_to_tail 1
xor ebx , ebx
mov  dl , %1
io_reg_read_word
push edx
xor edx , edx 
add eax , 16
mov ebx , dword 0x10000		;; modulo
div ebx						;;
mov ebx , edx 				;;
pop edx 						;;
%endmacro

%macro rxbuf_tail_to_tailreg 1
sub %1 ,  16		
%endmacro



