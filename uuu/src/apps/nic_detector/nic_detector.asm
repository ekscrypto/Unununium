; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License
;
; Please see the pci_detector application, which is based on this one but
; much more complete.
;
section nic_detector

nic_database:

dd 0x0082, str_3COM
  dd 0xFFFF, str_3C905
  dd -1

dd 0x008D, str_3COM
  dd 0xFFFF, str_3C905
  dd -1


dd 0x1011, str_DEC
  dd 0x0002, str_DECCHIP21040
  dd 0x0009, str_DECCHIP21140
  dd 0x0014, str_DECCHIP21041
  dd 0x0019, str_DECCHIP21142
  dd 0x500B, str_DE500
  dd -1

dd 0x1014, str_DEC
  dd 0x0001, str_ETHERJET
  dd -1

dd 0x1014, str_XIRCOM
  dd 0x0181, str_ETHERJET
  dd 0x0182, str_ETHERJET
  dd 0x0183, str_ETHERJET
  dd 0x1182, str_ETHERJET
  dd -1

dd 0x1025, str_DEC
  dd 0x0315, str_ALN315
  dd -1

dd 0x1028, str_3COM
  dd 0x0080, str_3C905B
  dd 0x0081, str_3C905B
  dd 0x0082, str_3C905B
  dd 0x0083, str_3C905B
  dd 0x0084, str_3C905B
  dd 0x0085, str_3C905B
  dd 0x0086, str_3C905B
  dd 0x0087, str_3C905B
  dd 0x0088, str_3C905B
  dd 0x0089, str_3C905B
  dd 0x0090, str_3C905B
  dd 0x0091, str_3C905B
  dd 0x0092, str_3C905B
  dd 0x0093, str_3C905B
  dd 0x0094, str_3C905B
  dd 0x0095, str_3C905B
  dd 0x0096, str_3C905B
  dd 0x0097, str_3C905B
  dd 0x0098, str_3C905B
  dd 0x0099, str_3C905B
  dd -1

dd 0x108D, str_DEC
  dd 0x0016, str_RAPIDFIRE2327
  dd -1

dd 0x10B7, str_3COM
  dd 0x5900, str_3C590
  dd 0x5920, str_3C592
  dd 0x5950, str_3C595_TX
  dd 0x5951, str_3C595_T4
  dd 0x5952, str_3C595_MII
  dd 0x9000, str_3C900_TPO
  dd 0x9001, str_3C900_COMBO
  dd 0x9004, str_3C900B_TPO
  dd 0x9005, str_3C900B_COMBO
  dd 0x9006, str_3C900B_TPC
  dd 0x900A, str_3C900B_FL
  dd 0x9050, str_3C905_TX
  dd 0x9051, str_3C905_T4
  dd 0x9055, str_3C905B
  dd 0x9056, str_3C905B_T4
  dd 0x9058, str_3C905B_COMBO
  dd 0x905A, str_3C905B_FX
  dd -1

dd 0x10B8, str_DEC
  dd 0x2001, str_SMC9332BDT
  dd 0x2002, str_SMC9332BVT
  dd 0x2003, str_SMC9334BDT
  dd 0x2005, str_SMC8032DT
  dd -1

dd 0x10EF, str_DEC
  dd 0x8169, str_CARDBUS
  dd -1

dd 0x1109, str_DEC
  dd 0x2400, str_ANA6944ATX
  dd 0x2A00, str_ANA6911ATX
  dd 0x2B00, str_ANA6911ATXC
  dd 0x3000, str_ANA6922TX
  dd -1

dd 0x1112, str_DEC
  dd 0x2300, str_RNS2300
  dd 0x2320, str_RNS2320
  dd 0x2340, str_RNS2340
  dd -1

dd 0x1113, str_DEC
  dd 0x1207, str_EN1207TX
  dd 0x2220, str_CARDBUS
  dd -1

dd 0x115D, str_DEC
  dd 0x0002, str_CARDBUS10_100
  dd -1

dd 0x115D, str_XIRCOM
  dd 0x0003, str_CARDBUS
  dd 0x0005, str_CARDBUS
  dd 0x0007, str_CARDBUS
  dd 0x000B, str_CARDBUS
  dd 0x000F, str_CARDBUS
  dd 0x0101, str_CARDBUS
  dd 0x0103, str_CARDBUS
  dd 0x0181, str_CARDBUS
  dd 0x1181, str_CARDBUS
  dd 0x0182, str_ETHERJET
  dd 0x1182, str_ETHERJET
  dd 0x0183, str_ETHERJET
  dd -1

dd 0x1179, str_DEC
  dd 0x0203, str_FASTETHERNET
  dd 0x0204, str_CARDBUS
  dd -1

dd 0x1186, str_DEC
  dd 0x0100, str_DE530PLUS
  dd 0x1100, str_DFE500TX
  dd 0x1101, str_DFE500TX
  dd 0x1102, str_DFE500TX
  dd -1

dd 0x1266, str_DEC
  dd 0x0004, str_EAGLE_ETHERMAX
  dd -1

dd 0x1282, str_DEC
  dd 0x9100, str_AEF380TXD
  dd -1

dd 0x12AF, str_DEC
  dd 0x0019, str_NETFLYER_CARDBUS
  dd -1

dd 0x1395, str_DEC
  dd 0x0001, str_CARDBUS10_100
  dd -1

dd 0x2646, str_DEC
  dd 0x0001, str_KNE100TX
  dd -1

dd 0x8086, str_DEC
  dd 0x0001, str_ETHEREXPRESSPRO100
  dd -1

dd -1

str_3COM:		db "3COM Corporation",0
str_3C590: 		db "3C590 PCI Ethernet Adapter 10bT",0
str_3C592: 		db "3C592 EISA 10mbps Demon/Vortex",0
str_3C595_TX: 		db "3C595 PCI Ethernet Adapter 100bTX",0
str_3C595_T4: 		db "3C595 PCI Ethernet Adapter 100bT4",0
str_3C595_MII: 		db "3C595 PCI Ethernet Adapater 100b-MII",0
str_3C900_TPO: 		db "3C900-TPO Fast Ethernet",0
str_3C900_COMBO: 	db "3C900-COMBO Fast Etherlink",0
str_3C900B_TPO: 	db "3C900B-TPO Etherlink XL TPO 10Mb",0
str_3C900B_COMBO: 	db "3C900B-COMBO Etherlink XL Combo",0
str_3C900B_TPC: 	db "3C900B-TPC Etherlink XL TPC",0
str_3C900B_FL:		db "3C900B-FL Etherlink XL FL",0
str_3C905:		db "3C905 Fast Etherlink 10/100",0
str_3C905_TX: 		db "3C905-TX Fast Etherlink 10/100",0
str_3C905_T4: 		db "3C905-T4 Fast Etherlink XL 10/100",0
str_3C905B: 		db "3C905B Fast Etherlink XL 10/100",0
str_3C905B_T4:		db "3C905B-T4 Fast Etherlink XL 10/100",0
str_3C905B_COMBO:	db "3C905B-COMBO Deluxe Etherlink 10/100",0
str_3C905B_FX:		db "3C905B-FX Fast Etherlink FX",0
str_AEF380TXD:		db "AEF-380TXD Fast Ethernet",0
str_ALN315:		db "ALN315 Fast Ethernet Adapter",0
str_ANA6911ATX:		db "ANA-6911A/TX Fast Ethernet Adapter",0
str_ANA6911ATXC:	db "ANA-6911A/TXC Fast Ethernet Adapter",0
str_ANA6922TX:		db "ANA-6922/TX Fast Ethernet Adapter",0
str_ANA6944ATX:		db "ANA-6944A/TX Fast Ethernet",0
str_CARDBUS:		db "Cardbus Fast Ethernet Adapter",0
str_CARDBUS10_100:	db "Cardbus Ethernet 10/100 Adapter",0
str_DE500:		db "DE500 Fast Ethernet Adapter",0
str_DE530PLUS:		db "DE-530+ Ethernet Adapter",0
str_DEC:		db "Digital Equipment Corporation (DEC)",0
str_DECCHIP21040:	db "DecChip 21040 'Tulip' Ethernet Adapter",0
str_DECCHIP21041:	db "DecChip 21041 'Tulip Plus' Ethernet Adapter",0
str_DECCHIP21140:	db "DecChip 21140 Fast Ethernet Adapter",0
str_DECCHIP21142:	db "DecChip 21142/3 10/100 Ethernet Adapter",0
str_DFE500TX:		db "DFE-500TX Fast Ethernet",0
str_EAGLE_ETHERMAX:	db "Eagle Fast EtherMAX",0
str_EN1207TX:		db "EN-1207-TX Fast Ethernet or Cheetah Fast Ethernet Adapter",0
str_ETHEREXPRESSPRO100: db "EtherExpress PRO/100 Mobile CardBus 32 Adapter",0
str_ETHERJET:		db "10/100 EtherJet Cardbus Adapter",0
str_FASTETHERNET:	db "Fast Ethernet Adapter",0
str_KNE100TX:		db "KNE100TX Fast Ethernet",0
str_NETFLYER_CARDBUS:	db "NetFlyer Cardbus Fast Ethernet Adapter",0
str_RAPIDFIRE2327:	db "Rapidfire 2327 10/100 Ethernet Adapter",0
str_RNS2300:		db "RNS2300 Fast Ethernet",0
str_RNS2320:		db "RNS2320 Fast Ethernet",0
str_RNS2340:		db "RNS2340 Fast Ethernet",0
str_SMC8032DT:		db "SMC8032DT Extreme Ethernet 10/100 Adapte",0
str_SMC9332BDT:		db "SMC9332BDT EtherPower 10/100",0
str_SMC9332BVT:		db "SMC9332BVT EtherPower T4 10/100",0
str_SMC9334BDT:		db "SMC9334BDT EtherPower 10/100 (1-port)",0
str_XIRCOM:		db "Xircom",0
str_and_function_number: db " and function number: ",1
str_end_of_list:	db "Search completed.",0
str_found_device_on_bus: db "Found device on bus: ",1
str_of_this_type:	db " of this DeviceID/VendorID",0
str_searching_Device:   db "Searching for DeviceID: ",1
str_searching_Vendor:	db "Searching with VendorID: ",1
str_separator:		db " - ",1
str_this_is_index:	db ". This is index ",1
str_title:		db "Network Interface Card Detector version 0.2, by Dave Poirier",0
str_using_device_number: db ", using device number: ",1


global app_nic_detector

app_nic_detector:
  lea esi, [str_title]
  externfunc __string_out, system_log

  lea ebp, [nic_database]

  ;]--Load Vendor ID
.search_vendor:
  mov eax, [ebp]
  lea ebp, [ebp + 4]
  cmp eax, dword -1
  jz .end_of_list

  lea esi, [str_searching_Vendor]
  externfunc __string_out, system_log
  mov edx, eax
  externfunc __hex_out, system_log
  lea esi, [str_separator]
  externfunc __string_out, system_log
  mov esi, [ebp]
  lea ebp, [ebp + 4]
  externfunc __string_out, system_log

  ;]--Load/display Device ID
.check_device:
  push eax
  lea esi, [str_searching_Device]
  externfunc __string_out, system_log
  mov edx, [ebp]
  externfunc __hex_out, system_log
  lea esi, [str_separator]
  externfunc __string_out, system_log
  mov esi, [ebp + 4]
  externfunc __string_out, system_log

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

  retn

.found_device:
  push esi
  lea esi, [str_found_device_on_bus]
  externfunc __string_out, system_log
  xor edx, edx
  mov dl, bh
  externfunc __hex_out, system_log
  lea esi, [str_using_device_number]
  externfunc __string_out, system_log
  mov dl, bl
  shr dl, 3
  externfunc __hex_out, system_log
  lea esi, [str_and_function_number]
  externfunc __string_out, system_log
  mov dl, bl
  and dl, 0x07
  externfunc __hex_out, system_log
  lea esi, [str_this_is_index]
  externfunc __string_out, system_log
  pop edx
  push edx
  externfunc __hex_out, system_log
  lea esi, [str_of_this_type]
  externfunc __string_out, system_log
  pop esi
  inc esi
  mov edx, [ebp]
  push eax
  jmp near .retry_device_id
