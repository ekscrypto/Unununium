; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier / Niklas Kluegel
; Distributed under the BSD License
[bits 32]
section pci_device_detector

%include "pci_device_database.txt"








str_function_number  : db 0x0A,"Function number: ",1
str_end_of_list		  		: db 0x0A ,  "Search completed.",0
str_this_is_index		   	: db 0x0A,"Index : ",1
str_title				        	: db "PCI Device Detector version 0.35, by Dave Poirier / Niklas Kluegel  ",1
str_thanks : db 0x0A , "Special Thanks to : Matthieu Bonetti for his database script ! " , 1
str_pci_configuration_error : db "Error : Reading PCI-Configurationspace NOT successfull !",0
str_configuration             : db 0x0A , "Configuration : " , 0
str_spacer			        : db "    " , 1
str_spacer_lf                   : db 0x0A , "    " , 1
str_command                 : db "Command   : " , 1
str_status                       : db "Status    : " , 1
str_revision              	   : db 0x0A , "Revision      : " , 1
str_class_base		        : db "Base-class: " , 1	
str_class_subclass	: db       0x0A , "Sub-class     : " , 1
str_class_RLPI              : db   "RLPI , I/F: " , 1
str_clg                     : db 0x0A ,     "Cache-Line-Size (x 32bytes): " , 1 
str_effective_latency	: db 0x0A , "EffectiveLatency+8PCIcycles: " , 1
str_BIST                    : db 0x0A ,   "Built-In-Self-Test         : " , 1
str_max_latency		: db 0x0A , "Maximal Lateny             : " , 1
str_min_latency		: db 0x0A , "MinGNT (Minimal Latency)   : " , 1
str_ressources		: db 0x0A , "Ressources : " , 0
str_IRQ                     : db "Hardware Interrupt  : " , 1
str_INT_Pin			: db  "Interrupt-Pin       : " , 1
str_base_address    : db  "Base I/O address    : " , 1
str_memory_map_address      : db "Memory map address  : " , 1
str_IOR                     : db "IOR   = " , 1
str_MAR                     : db "MAR   = " , 1
str_BM                      : db "BM    = " , 1
str_SC                      : db "SC    = " , 1
str_MWI                     : db "MWI   = " , 1
str_VPS                     : db "VPS   = " , 1
str_PER                     : db "PER   = " , 1
str_WC                      : db "WC    = " , 1
str_SEE                     : db "SEE   = " , 1
str_FBB                     : db "FBB   = " , 1
str_DP                      : db "DP    = " , 1
str_DEVTIM					: db "DEVTIM = " , 1
str_STA                     : db "STA   = " , 1
str_TAB                     : db "TAB   = " , 1
str_MAB                     : db "MAB   = " , 1
str_SER                     : db "SER   = " , 1
str_list_of_found_devices   : db 0x0A , "Found the following devices :", 
str_Vendor               : db 0x0A , "VendorName / ID : " , 1
str_slash                   : db "/ " , 1
str_Device               : db 0x0A ,  "DeviceName / ID : " , 1
str_devisor              : db 0x0A ,  "-------------------------" , 0
var_device_number_function  : dd 0 
var_vendor_string_pointer   : dd 0
var_device_string_pointer   : dd 0
var_vendor_ID               : dd 0 
var_device_ID               : dd 0


global app_pci_device_detector
app_pci_device_detector:


  lea esi, [str_title]
  externfunc __string_out, system_log
   lea esi , [str_thanks]
  externfunc __string_out, system_log
 ; les esi , [str_spacer_lf]  
 ; externfunc __string_out, system_log
  lea esi, [str_list_of_found_devices] 
  externfunc __string_out, system_log
  lea ebp, [pci_database_array]

  ;]--Load Vendor ID
.search_vendor:
  mov eax, [ebp]
  lea ebp, [ebp + 4]
  cmp eax, dword -1
  jz .end_of_list
  
  
  mov [var_vendor_ID] , eax
  mov esi, [ebp]
  mov dword [var_vendor_string_pointer] , esi
  lea ebp, [ebp + 4]
  
  ;]--Load/display Device ID
.check_device:
  push eax
  mov edx, [ebp]
  mov [var_device_ID] , edx 
  mov esi , [ebp + 4]
  mov dword [var_device_string_pointer] , esi
  
  xor esi, esi
.retry_device_id:
  mov ecx, edx
  mov edx, eax
  push ebp
  externfunc __find_pci_device, noclass
  pop ebp
  pop eax
  jnc .found_device

.try_next_device:
  lea ebp, [ebp + 8]
  cmp [ebp], dword -1
  jnz .check_device

.try_next_vendor:
  lea ebp, [ebp + 4]
  cmp [ebp], dword -1
  jnz .search_vendor

.end_of_list:
  lea esi, [str_end_of_list]
  externfunc __string_out, system_log
  externfunc __wait_ack, debug
  retn

.found_device:
  push esi
  lea esi , [str_Vendor]
  externfunc __string_out, system_log
  mov esi , [var_vendor_string_pointer]
  externfunc __string_out, system_log
  lea esi , [str_slash]
  externfunc __string_out, system_log
  mov edx , [var_vendor_ID]  
  externfunc __hex_out, system_log	
  

  lea esi , [str_Device]
  externfunc __string_out, system_log
  mov esi , [var_device_string_pointer]
  externfunc __string_out, system_log
  lea esi , [str_slash]
  externfunc __string_out, system_log
  mov edx , [var_device_ID]  
  externfunc __hex_out, system_log	
  
  
 
  xor edx, edx
  mov [var_device_number_function] , ebx
  lea esi, [str_function_number]
  externfunc __string_out, system_log
  mov dl, bl
  and dl, 0x07
  externfunc __hex_out, system_log
  lea esi, [str_this_is_index]
  externfunc __string_out, system_log
  pop edx
  push edx
  externfunc __hex_out, system_log
  pop esi
  inc esi
 push esi
  mov edx, [ebp]
  push eax
    
.get_configuration_data
	;]-- Read 64-byte PCI device header
	xor edx , edx
	mov ebx , [var_device_number_function]
	
	;]-- PCI-Device Command
	mov edi , 4
	xor ecx , ecx
	externfunc __read_pci_configuration_word, noclass
	jc .configuration_error
	lea esi, [str_configuration]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_command]
    externfunc __string_out, system_log
	mov edx ,  ecx
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 1
	jz .IOR
	mov edx , 1
	.IOR:
  	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_IOR]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 2
	jz .MAR
	mov edx , 1
	.MAR:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_MAR]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 4
	jz .BM
	mov edx , 1
	.BM:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_BM]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
  
  	xor edx  , edx
	test ecx , 8
	jz .SC
	mov edx , 1
	.SC:
  	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_SC]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 16
	jz .MWI
	mov edx , 1
	.MWI:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_MWI]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 32
	jz .VPS
	mov edx , 1
	.VPS:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_VPS]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 64
	jz .PER
	mov edx , 1
	.PER:
  	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_PER]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 128
	jz .WC
	mov edx , 1
	.WC:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_WC]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 256
	jz .SEE
	mov edx , 1
	.SEE:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_SEE]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
  
  	xor edx  , edx
	test ecx , 512
	jz .Command_FBB
	mov edx , 1
	.Command_FBB:
  	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_FBB]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
    
  
	
	;]-- PCI-Device Status
	mov edi , 6
	xor ecx , ecx
	externfunc __read_pci_configuration_word, noclass
	jc .configuration_error
	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_status]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 128
	jz .Stat_FBB
	mov edx , 1
	.Stat_FBB:
  	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_FBB]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 256
	jz .DP
	mov edx , 1
	.DP:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_DP]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 512
	jz .DEVTIM_next_bit
	mov edx , 1
	.DEVTIM_next_bit:
  	test ecx , 1024
	jz .DEVTIM
	add edx , 2
	.DEVTIM:
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_DEVTIM]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 2048
	jz .STA
	mov edx , 1
	.STA:
  	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_STA]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 4096
	jz .TAB
	mov edx , 1
	.TAB:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_TAB]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 8192
	jz .MAB
	mov edx , 1
	.MAB:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_MAB]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	xor edx  , edx
	test ecx , 16384
	jz .SER
	mov edx , 1
	.SER:
  	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_SER]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log

	xor edx  , edx
	test ecx , 32768
	jz .Command_PER
	mov edx , 1
	.Command_PER:
  	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_spacer]
	externfunc __string_out, system_log
  	lea esi, [str_PER]
    externfunc __string_out, system_log
	externfunc __hex_out, system_log
	
	;]-- PCI-Device Revision
	mov edi , 8
	xor ecx , ecx
	externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_revision]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device Classes
	mov edi , 11
	externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_class_base]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	mov edi , 10
	externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_class_subclass]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	mov edi , 9
	externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_class_RLPI]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device Cache-Line-Size (CLG)
	mov edi , 12
	externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_clg]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device Built-In-Self-Test (BIST)
	mov edi , 15
    externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_BIST]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
		
	;]-- PCI-Device effective Latency
	mov edi , 13
    externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_effective_latency]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device maximal Latency
	mov edi , 63
    externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_max_latency]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device minimal Latency
	mov edi , 62
    externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_min_latency]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device Occupied Ressources
	lea esi, [str_ressources]
	externfunc __string_out, system_log
	
	;]-- PCI-Device IRQ
	mov edi , 60
	externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer]
	externfunc __string_out, system_log
	lea esi, [str_IRQ]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device Interrupt-Pin
	mov edi , 61
    externfunc __read_pci_configuration_byte, noclass
	jc .configuration_error
	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_INT_Pin]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device I/O Base Address
	mov edi , 10h
	externfunc __read_pci_configuration_dword, noclass
	jc .configuration_error
	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_base_address]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	
	;]-- PCI-Device Memory Map Address
	mov edi , 14h
	externfunc __read_pci_configuration_dword, noclass
	jc .configuration_error
	lea esi, [str_spacer_lf]
	externfunc __string_out, system_log
	lea esi, [str_memory_map_address]
    externfunc __string_out, system_log
	mov edx , ecx
	externfunc __hex_out, system_log
	lea esi , [str_devisor]
	externfunc __string_out, system_log
pop esi   
 jmp .retry_device_id

	
	

.configuration_error:
lea esi , [str_pci_configuration_error]
externfunc __string_out, system_log
jmp .retry_device_id


