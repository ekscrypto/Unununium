;====---------------------------------------------------------------------====
; Serial Handler Cell                                (c) 2001 Richard Fillion
; Serilium SuperCell			        Distributed under BSD License
;====---------------------------------------------------------------------====

[bits 32]

section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Serilium SuperCell Serial Handler",0
str_author: db "Richard Fillin (Raptor-32)",0
str_copyright: db "(c) 2001 Richard Fillion",0


;====------[ INITIALIZATION ]-------=====
section .c_init
	push eax
	push ecx
	
	mov ax, [0x00000400]
	or ax, 0
	jz .com2
	mov [com1_port], ax
	.com2:
	mov bx, [0x00000402]
	or bx, 0
	jz .com3
	mov [com2_port], bx
	.com3:
	mov cx, [0x00000404]
	or cx, 0
	jz .com4
	mov [com3_port], cx
	.com4:
	mov dx, [0x00000406]
	or dx, 0
	jz .end_detect
	mov [com4_port], dx
	.end_detect:

	pop ecx
	pop eax

	;in al, 0x80
	;xor cx, cx
	;mov cl, al		;no port available signal
	;externfunc showregs, debug_ack
	;mov dx, 0x3F8 + 5
	;in ax, dx
	;externfunc showregs, debug_ack
	;cmp ax, cx
	;je  .check_com2
	;mov [com1_port], word 0x3F8
	;.check_com2:
	;mov dx, 0x2F8 + 5
	;in ax, dx
	;externfunc showregs, debug_ack
	;cmp ax, cx
	;je .check_com3
	;mov [com2_port], word 0x2F8
	;.check_com3:
	;mov dx, 0x3E8 + 5
	;in ax, dx
	;externfunc showregs, debug_ack
	;cmp ax, cx
	;je .check_com4
	;mov [com3_port], word 0x3E8
	;.check_com4:
	;mov dx, 0x2E8 + 5
	;in ax, dx
	;externfunc showregs, debug_ack
	;cmp ax, cx
	;je .done_check
	;mov [com4_port], word 0x2E8
	;.done_check:

;note: the register switching there can save a few cycles on modern CPUs


section .text

found_com1: db "Serial COM1 found at i/o address:",0
found_com2: db "Serial COM2 found at i/o address:",0
found_com3: db "Serial COM3 found at i/o address:",0
found_com4: db "Serial COM4 found at i/o address:",0


globalfunc enable_port, com, 1, 10
;in :
;  eax = com port
;  bl = baud rate divisor high
;  bh = baud rate divisor low
;  cl = data format, (0 = 8data bits, 1 stop bit |1 = 7 data bits, 2 stop bits) 
;  esi = function to call
;
	push eax		;push com port to set irq later
	
  	xor edx, edx
	and eax, 0x0000FFFF
	or eax, eax		;check for 0
	jz .com_too_high
	cmp eax, 4
	ja  .com_too_high
	shl eax, 1 
	sub eax, 2
	mov edi, com_ports
	add edi, eax
	
	mov dx, [edi]
	cmp dx, -1
	je  .no_such_port
	;dx is now location for i/o for port requested
	push dx
	add dx, 3
	mov al, 0x80
	out dx, al
	pop dx
	mov al, bl	;baud rate divisor high should be in bl 
	out dx, al  	;baud rate divisor
	inc dx
	mov al, bh
	out dx, al      ;baud rate divisor low
	add dx, 2
	mov al, cl
	out dx, al	;set stop bits
	xor al, 00000011b
	;data bits
	out dx, al
	dec dx
	mov al, 0xC7
	out dx, al
	add dx, 2
	mov al, 0x0B
	out dx, al
	sub dx, 3
	mov al, 0x01
	out dx, al	;interupt when data in.

	
	;find com again, set irq client, irqsharing.
	pop eax
	cmp al, 2
	jb .use_com1
	je .use_com2
	cmp al, 4
	jb .use_com3
	je .use_com4
	;still here? got an error
	jmp .error_irq
	
	.use_com1:
	xor eax, eax
	mov al, 4	;irq 4
	mov edi, esi
	mov esi, serial_irq4
	cmp [com_clients.com3_client], dword -1
	je .done_set1
	;if com3 has a client, then now we have to share irq4
	mov [irq4share], byte 1
	.done_set1:
	mov [com_clients.com1_client], edi
	externfunc hook_irq, noclass
	retn
	
	.use_com2:
	xor eax, eax
	mov al, 3		;irq3
	mov edi, esi		;save client
	mov esi, serial_irq3
	cmp [com_clients.com4_client], dword -1
	je .done_set2
	;if com4 has a client, we must now share irq3
	mov [irq3share], byte 1
	.done_set2:
	mov [com_clients.com2_client], edi
	externfunc hook_irq, noclass
	retn

	.use_com3:
	mov al, 4		;irq 4
	mov edi, esi		;save client
	mov esi, serial_irq4
	cmp [com_clients.com1_client], dword -1
	je .done_set3
	;if com1 has a client, we must share irq4
	mov [irq4share], byte 1
	.done_set3:
	mov [com_clients.com3_client], dword edi
	externfunc hook_irq, noclass
	retn

	.use_com4:
	mov al, 3		;irq 3
	mov edi, esi		;save client
	mov esi, serial_irq3
	cmp [com_clients.com2_client], dword -1
	je .done_set4
	;if com2 has a client, we must share irq3
	mov [irq3share], byte 1
	.done_set4:
	mov [com_clients.com4_client], dword edi
	externfunc hook_irq, noclass
	retn
	


;====-------[ERRORS]--------=====
	
	.com_too_high:
	pop eax
	stc
	mov eax, dword 2		;error 2, com too high
	retn
	.no_such_port:
	pop eax
	stc
	mov eax, dword 3		;error 3, no such com port
	retn
	.error_irq:
	stc
	mov eax, dword 4		;error 4, couldnt find irq needed
	retn




;=======-------[IRQ SHARERS]-------=======

serial_irq4:			;for coms 1 and 3
  push ebx
  push edx
  push edi
  push ebp
  
  mov al, byte [irq4share]
  or al, 0
  jz .do_com1
  ;ok, we are sharing IRQ4 for com 1 and 3, check status bits to see
  ;which com just got sent data
  ;checking COM3 first
  mov dx, 0x3E8 + 3	;base + 3 = LSR, Line Status Register
  in al, dx
  and al, 00000001b     ;if bit 0 is set, keep it.
  or al, 0
  jz .do_com1		;not com3, check com1
  ;something awaits in com3, lets get it.
  xor ax, ax
  mov dx, 0x3E8
  in al, dx
  mov bx, ax
  mov al, 0x20
  out 0x20, al		;ack the PIC
  mov ax, bx
  mov edx, com_clients.com3_client
  call [edx]
  pop ebp
  pop edi
  pop edx
  pop ebx
  
  retn
  
  .do_com1:
  ;irq was called, either com3 doesnt exist, or nothing was there
  ;so we can just get whatever came in.
  mov dx, 0x3F8
  xor ax, ax
  in al, dx
  push eax
  ;mov bx, ax
  mov al, 0x20
  out 0x20, al			;ack the PIC
  pop eax
  ;mov ax, bx
  call [com_clients.com1_client]
  ;call [edx]
  
  pop ebp
  pop edi
  pop edx
  pop ebx
	  
  retn


 

serial_irq3:			;for coms 2 and 4
    
  push ebx
  push edx
  push edi
  push ebp

  mov al, byte [irq3share]
  or al, 0			;check if sharing irq3
  jz .do_com2
  ;sharing IRQ, check to see if it was com4 
  mov dx, 0x2E8 + 3		;base + 3 = LSR, Line Status Register
  in al, dx
  and al, 00000001b		;only keep bit0 up if it is up.
  or al, 0			;is al 0? if yes it was com2 that got called
  jz .do_com2
  ;it was com4 at this point
  xor ax, ax
  mov dx, 0x2E8
  in al, dx
  mov bx, ax
  mov al, 0x20
  out 0x20, al			;ack the PIC
  mov ax, bx
  mov edx, com_clients.com4_client
  call [edx]
  pop ebp
  pop edi
  pop edx
  pop ebx
	  
  retn
   
  .do_com2:
  ;if it gets here, we either have no com4, or it wasnt com4 that was called
  xor ax, ax
  mov dx, 0x2F8
  in al, dx
  mov bx, ax
  mov al, 0x20
  out 0x20, al			;ack the PIC
  mov edx, com_clients.com2_client
  call [edx]
  pop ebp
  pop edi
  pop edx
  pop ebx
	  
  retn





globalfunc disable_port, com, 2, 10
;in EAX= com port
  
  and eax, 0x0000FFFF   ;make SURE that top 16bits are cleared
  or eax, eax		;check for zero
  jz .no_com
  cmp eax, 4		;check for a com above 4
  ja .no_com
  push eax
  ;we have a POSSIBLE com, find its addres.
  shl eax, 1
  sub eax, 2
  mov edi, com_ports
  add edi, eax
  mov dx, [edi]
  cmp dx, -1
  je .no_com		;if dx = -1, we never detect an address for that com.
  ;base address to com port now in dx.
  ;first, stop the com from interupting the CPU.
  inc dx	;address to out to cancel interupt generation
  mov al, 0x00  
  out dx, al
  ;check to see if you can cancel the IRQ all together.
  pop eax
  cmp eax, 2
  jb .dis_com1
  je .dis_com2
  cmp eax, 4
  jb .dis_com3
  je .dis_com4
  
  .no_com:
  stc
  mov eax, 1			;error 1, no com port found.
  retn
 

  .dis_com1:
  mov [com_clients.com1_client], dword -1
  cmp [com_clients.com3_client], dword -1
  jne .no_unhook1
  ;unhook irq
  mov al, 4
  mov esi, serial_irq4
  ;externfunc unhook_irq, noclass  ;------NOTE!!!!!----------
  				;it was commented cause function not coded yet.
  .no_unhook1:
  clc
  retn

  .dis_com2:
  mov [com_clients.com2_client], dword -1
  cmp [com_clients.com4_client], dword -1
  jne .no_unhook2
  ;unhook irq
  mov al, 3
  mov esi, serial_irq3
  ;externfunc unhook_irq, noclass
  .no_unhook2:
  clc
  retn

  .dis_com3:
  mov [com_clients.com3_client], dword -1
  cmp [com_clients.com1_client], dword -1
  jne .no_unhook3
  ;unhook irq
  mov al, 4
  mov esi, serial_irq4
  ;externfunc unhook_irq, noclass
  .no_unhook3:
  clc
  retn

  .dis_com4:
  mov [com_clients.com4_client], dword -1
  cmp [com_clients.com2_client], dword -1
  jne .no_unhook4
  ;unhook irq
  mov al, 3
  mov esi, serial_irq3
  ;externfunc unhook_irq, noclass
  .no_unhook4:
  clc
  retn


  


;====------[ VARIABLES ]------=====
com_ports:

global com1_port
global com2_port
global com3_port
global com4_port
  
com1_port: dw -1
com2_port: dw -1
com3_port: dw -1
com4_port: dw -1


divisors:
  .2400:  db  0x30
  .4800:  db  0x18
  .9600:  db  0x0C
  .19200: db  0x06
  .38400: db  0x03
  .57600: db  0x02
  .115200: db 0x01

com_clients:
  .com1_client: dd -1
  .com2_client: dd -1
  .com3_client: dd -1
  .com4_client: dd -1

irq3share: db 0		;boolean to see whether we are sharing IRQ3 or not.
irq4share: db 0		;same but for IRQ4.


struc com_buffer	;size is 11bytes
	.com:	resb 1
	.location: resd 1
	.size: resw 1
	.in: resw 1
	.out: resw 1
endstruc



;===-----[ COM BUFFERS ]------===
com1_buffer:
	.location: dd -1
	.size: dw -1
	.in: dw 0
	.out: dw 0

com2_buffer:
	.location: dd -1
	.size: dw -1
	.in: dw 0
	.out: dw 0

com3_buffer:
	.location: dd -1
	.size: dw -1
	.in: dw 0
	.out: dw 0

com4_buffer:
	.location: dd -1
	.size: dw -1
	.in: dw 0
	.out: dw 0
