;; $Header:
;;
;; IDT/IRQ Channeler/Helper
;; By EKS - Dave Poirier
;; Distributed under the BSD License
;;
;; known limitations:
;;-------------------
;; - Maximum of 255 clients per IRQ channel
;; - GDT descriptor created are always with privilege level 0
;; - Doesn't remove a client from an IRQ channel due to an incomplete
;;   ics.remove_client implementation
;; - In case the PIC was only partly initialized by a 3rd party, no detection
;;   will be made of that case when writing to the PIC
;; - No check is done to see if GDT is still at the allocated address
;; - Initialization will freeze with an error code on screen if it can't
;;   properly allocate memory to create either GDT or IDT
;;
;; special notable requirement:
;;-----------------------------
;; - A stack must already be setup to at least allow 64 bytes, ss must be set
;;   a priori to use a 4GB r/w segment or one that is at least aligned with
;;   physical addresses.
;;
;; special initialization behaviour:
;;----------------------------------
;; - During initialization, both the IDT and the GDT will be reloaded with the
;;   defaults one.  CS = 0x0008, DS=ES=FS=GS=SS = 0x0010.  Both descriptor will
;;   be base address 0, size = 4GB.  Data segment is r/w, Code segment is r/x
;;


section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Potassium - IRQ Dispatcher",0
str_author: db "eks",0
str_copyright: db "BSD Licensed",0

section .text
;==============================================================================


%define _PROVIDE_NMI_FUNCTIONS_

%define MAX_GDT_SIZE		128
%define FIRST_FREE_GDT_ENTRY	3
%define IDT_ENTRY_COUNT		0x30
%define FIRST_KNOWN_INT_HANDLER	0x20
%define KNOWN_INT_HANDLER_COUNT	0x10
%define PORT_PIC_MASTER_COMMAND	0x20
%define PORT_PIC_SLAVE_COMMAND	0xA0
%define GDTFF_OFF		(FIRST_FREE_GDT_ENTRY*8)
%define IDT_SIZE		(IDT_ENTRY_COUNT*8)
%define SEG_CODE		0x0008
%define SEG_DATA		0x0010

  struc gdt_null_desc
.signature      resb 4
.first_free     resd 1
  endstruc

section .c_init
global _start
_start:
;------------------------------------------------------------------------------
init:
					; Allocate memory for GDT
					;------------------------
  mov ecx, MAX_GDT_SIZE			; Max GDT Size
  externfunc mem.alloc			; allocate memory for it
  mov edx, 0xEE010001			; failure code
  jc short init_failed			; display error if any
					;
					; Initialize GDT manipulation data
					;---------------------------------
  mov [gdt.offset], edi			; save pointer to GDT
  mov [edi], dword 'GDTM'		; mark it as valid GDT
  lea esi, [byte edi + GDTFF_OFF]	; get first free entry pointer
  mov [byte edi + 04], esi		; set first free entry pointer
  					;
					; Initialize Code Segment
					;------------------------
  mov [byte edi + 08], dword 0x0000FFFF	; set base/limit
  mov [byte edi + 12], dword 0x00CF9B00	; set base/limit/type
					;
					; Initialize Data Segment
					;------------------------
  mov [byte edi + 16], dword 0x0000FFFF	; set base/limit
  mov [byte edi + 20], dword 0x00CF9300	; set base/limit/type
  					;
					; Link up free entries
					;---------------------
  mov ecx, ((MAX_GDT_SIZE-GDTFF_OFF)/8)	; number of free entries
  add edi, byte GDTFF_OFF		; move pointer to first free entry
.linking_gdt_entries:			;
  lea esi, [edi + 8]			; get pointer to next free entry
  mov [edi], esi			; set pointer to next free entry
  dec ecx				; decrement free entry count
  mov edi, esi				; move pointer to next free entry
  jnz short .linking_gdt_entries	; continue if any free entry left
					;
  mov [byte edi - 8], dword ecx		; null terminate last entry
  					;
					; Reload Pointer to GDT
					;----------------------
  lgdt [gdt]				; set cpu gdtr
  					;
					; Activate new code segment, part i
					;----------------------------------
  jmp dword SEG_CODE:reload_cs		; far jump to re-entry code
					;
					; Error handler in case of failure
init_failed:				;---------------------------------
  mov eax, edx				;
  stc					;
  retn					;
					;
					; PIC 82C59A Initialization Sequence
pic.sequence.master:			;-----------------------------------
db 0x11, 0x20, 0x04, 0x1D, 0xFB		; Master PIC
					;
pic.sequence.slave:			;
db 0x11, 0x28, 0x02, 0x19, 0xFF		; Slave PIC
					;
send_pic_sequence:			;
  lodsb					; load icw0
  out dx, al				; send icw0 to pic address+0
  inc edx				; select pic address+1
  lodsb					; load icw1
  out dx, al				; send icw1 to pic address+1
  lodsb					; load icw2
  out dx, al				; send icw2 to pic address+1
  lodsb					; load icw3
  out dx, al				; send icw3 to pic address+1
  lodsb					; load irq mask
  out dx, al				; send irq mask to pic address+1
  retn					;
					; Activate new code segment, part ii
					;-----------------------------------
reload_cs:				; reentry point
					;
					; Activate new data segment
					;--------------------------
  push byte SEG_DATA			; segment selector to use
  pop eax				; get it in eax so we can work with it
  mov ds, eax				; initialize ds
  mov es, eax				; initialize es
  mov fs, eax				; initialize fs
  mov gs, eax				; initialize gs
  mov ss, eax				; initialize ss
					;
					; Acquiring memory for IDT
					;-------------------------
  mov ecx, IDT_SIZE			; size of the IDT to initialize
  externfunc mem.alloc			; allocate memory
  mov edx, 0xEE010002			; error code in case of failure
  jc short init_failed			; handle error if any
					;
					; Activate IDT
					;-------------
  dec eax				; decrement size of IDT by 1
  push edi				; save gdt location
  o16 push ax				; save size of IDT-1
  lidt [esp]				; set cpu IDTR
  o16 pop ax				; clear off idt size
  pop dword [idt.offset]		; set internal pointer to idt location
					;
					; Initialize unhandled INTs
					;-------------------------
  push byte FIRST_KNOWN_INT_HANDLER	; number of int to setup
  mov esi, _default_int_handler		; set our default handler
  pop ecx				; set number of unhandled interrupts
  xor eax, eax				; start with interrupt 0
.registering_unhandled_int:		;
  push eax				; back it up, it will be destroyed
  call int.hook				; hook it up
  pop eax				; restore eax
  inc eax				; go to next interrupt
  dec ecx				; decrement interrupt count
  jnz short .registering_unhandled_int	; go process any interrupt left
					;
					; Initialize known IDT entries
					;-----------------------------
					; assuming al = FIRST_KNOWN_INT_HANDLER
					;
  push byte KNOWN_INT_HANDLER_COUNT	; number of int to setup
  mov esi, _irq_0			; pointer to int information
  pop ecx				; set int count in ecx
.registering_idt_entries:		;
  push eax				; backup interrupt number
  push esi				; backup int handler offset
  call int.hook				; interrupt hooking function
  externfunc ics.create_channel		; create associated ICS channel
  pop esi				; restore int handler offset
  pop eax				; restore int handler offset
  mov [esi + 1], edi			; save ICS channel in int handler
  inc eax				; select next idt entry
  add esi, byte 8			; move to the next int handler
  dec ecx				; decrement int handler count
  jnz short .registering_idt_entries	; if any left, process them
					;
					; Send 82C59A Initialization Sequences
					;-------------------------------------
  mov esi, pic.sequence.master		; select initialization sequence
  mov edx, PORT_PIC_MASTER_COMMAND	; select master PIC
  call send_pic_sequence		; send sequence
  mov edx, PORT_PIC_SLAVE_COMMAND	; select slave PIC
  call send_pic_sequence		; send sequence
					;
  sti					;
					;
  clc					;
  retn					; return to caller
;------------------------------------------------------------------------------




section .data
;==============================================================================
gdt:
.size: dw MAX_GDT_SIZE - 1
.offset: dd 0

idt:
.offset: dd 0
.default_handler: dd -1
.fatal_error: db 0

strings:
.unhandled_interrupt: db "Unhandled interrupt caught! Locking up.",0
;==============================================================================



section .text
;==============================================================================

%ifdef _PROVIDE_NMI_FUNCTIONS_

globalfunc int.enable_nmi
;------------------------------------------------------------------------------
;>
;; Enable Non-Maskable Interrupt
;;
;; parameters:
;;------------
;; none
;;
;; returns:
;;---------
;; registers as usual
;; no error check
;<
;------------------------------------------------------------------------------
  in	byte al,   byte 0x70		; Read CMOS RAM Index register
  and	byte al,   byte 0x7F		; Unmask NMI bit
  out	byte 0x70, byte al		; Write modified CMOS RAM Index reg
  retn					;
;------------------------------------------------------------------------------


globalfunc int.disable_nmi
;------------------------------------------------------------------------------
;>
;; Disable Non-Maskable Interrupt
;;
;; parameters:
;;------------
;; none
;;
;; returns:
;;---------
;; registers as usual
;; no error check
;<
;------------------------------------------------------------------------------
  in	byte al,   byte 0x70		; Read CMOS RAM Index register
  or	byte al,   byte 0x80		; Mask NMI bit
  out	byte 0x70, byte al		; Write modified CMOS RAM Index reg
  retn					;
;------------------------------------------------------------------------------

%endif



globalfunc int.hook_irq
;------------------------------------------------------------------------------
;>
;; Hook a client to an irq channel
;;
;; note that the client must be ICS compatible, see the ICS documentation for
;; more detail.
;;
;; parameters:
;;------------
;; al  = irq number (0 to 15)
;; esi = pointer to client to hook
;;
;; returned values:
;;-----------------
;; error and registers as usual
;<
;------------------------------------------------------------------------------
  pushad				; backup all regs
					;
					; Test irq number validity
					;-------------------------
  test al, 0xF0				; make sure requested irq is valid
  stc					; prepare error flag in case
  jnz short .exit			; if invalid, exit
					;
					; Add client to ics irq channel
					;------------------------------
  movzx eax, al				; expand irq number to 32bit
  mov edi, [eax * 8 + _irq_0 + 1]	; get irq channel number
  push eax				; backup requested irq number
  externfunc ics.add_client		; add client to the ics irq channel
  pop eax				; restore requested irq number
  jc short .exit			; in case of any error, exit
					;
					; IRQ mask/unmask control
					;------------------------
  inc byte [eax * 8 + _irq_0 + 7]	; increment client count for this irq
  clc					; clear error in case we leave early
  jnz short .exit			; client already present? don't unmask
					;
  call int.unmask_irq			; unmask irq
					;
					; Exit point
.exit:					;-----------
  popad					; restore all registers
  retn					; return to caller
;------------------------------------------------------------------------------


globalfunc int.unhook_irq
;------------------------------------------------------------------------------
;>
;; Unhook a client from an irq channel
;;
;; Parameters:
;;------------
;; al  = irq number
;; esi = pointer to client
;;
;; Returned values:
;;-----------------
;; error and registers as usual
;<
;------------------------------------------------------------------------------
  pushad				; backing up all registers
					;
					; Test irq number validity
					;-------------------------
  test al, 0xF0				; must be between 0 and 15
  stc					; set error flag in case
  jnz short .exit			; exit if invalid
					;
					; IRQ mask/unmask control
					;------------------------
  movzx eax, al				; expand irq number to 32bit
  dec byte [eax * 8 + _irq_0 + 7]	; decrement client count
  jns short .unhook_client		; if client count is above -1..
  					;    don't mask yet
					;
  call int.mask_irq			; mask irq, no more client left
					;
					; Unhook client from irq channel
.unhook_client:				;-------------------------------
;  externfunc ics.remove_client		; XXX TODO: as soon as it is available
					; uncomment and test!
					;
					; Exit point
.exit:					;-----------
  popad					; restore all registers
  retn					; return to caller
;------------------------------------------------------------------------------




globalfunc int.mask_irq
;------------------------------------------------------------------------------
;>
;; Mask an irq, in either the slave or master pic
;;
;; parameters:
;;------------
;; al = irq number (only the lowest 4 bits are used)
;;
;; returned values:
;;-----------------
;; CL = irq number as provided in AL
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  test al, 0xF0				; test irq number validity
  mov cl, al				; prepare rotating mask count
  stc					; set error flag in case
  mov ah, 0x01				; mask to 'or' with, only 1 bit cleared
  jnz short int.unmask_irq.exit		; if irq number is above range, exit
  rol ah, cl				; rotate mask to fit selected irq
  test al, 0x08         		; determine slave/master based on bit 3
  jnz .slave_pic			; seems it slave, go do it
					;
					; Master PIC irq mask
					;--------------------
  in al, 0x21				; get current master pic irq mask
  or al, ah				; set the irq mask for selected irq
  out 0x21, al				; send new irq mask to master pic
  clc					; clear any error flag
  retn					; return to caller
					;
					; Slave PIC irq mask
.slave_pic:				;-------------------
  in al, 0xA1				; get current slave pic irq mask
  or al, ah				; set the irq mask for selected irq
  out 0xA1, al				; send new irq mask to slave pic
  clc					; clear any error flag
  retn					; get back to caller
;------------------------------------------------------------------------------



globalfunc int.unmask_irq
;------------------------------------------------------------------------------
;>
;; Unmask an irq, in either the slave or master pic
;;
;; parameters:
;;------------
;; al = irq number
;;
;; returned values:
;;-----------------
;; cl = irq number as requested in al
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  test al, 0xF0				; test irq number validity
  mov cl, al				; prepare rotating mask count
  stc					; set error flag in case
  mov ah, 0xFE				; mask to 'and' with, only 1 bit cleared
  jnz short .exit			; if irq number is above range, exit
  rol ah, cl				; rotate mask to fit selected irq
  test al, 0x08				; was it a slave or master pic's irq?
  jnz .slave_pic			; seems it slave, go do it
					;
					; Master PIC irq unmask
					;----------------------
  in al, 0x21				; get current master pic irq mask
  and al, ah				; clear the irq mask for selected irq
  out 0x21, al				; send new irq mask to master pic
  clc					; clear any error flag
  retn					;
					;
					; Exit point, invalid param
.exit:					;--------------------------
  mov eax, __ERROR_INVALID_PARAMETERS__	;
  retn					; get back to caller
					;
					; Slave PIC irq unmask
.slave_pic:				;---------------------
  in al, 0xA1				; get current slave pic irq mask
  and al, ah				; clear the irq mask for selected irq
  out 0xA1, al				; send new irq mask to slave pic
  clc					; clear any error flag
  retn					; get back to caller
;------------------------------------------------------------------------------


globalfunc int.get_irq_mask
;------------------------------------------------------------------------------
;>
;; Get both master and slave pic irq mask
;;
;; parameters:
;;------------
;; none
;;
;; returned values:
;;-----------------
;; al = master pic irq mask
;; ah = slave pic irq mask
;<
; no error returned,
;------------------------------------------------------------------------------
  in al, 0xA1				; get slave pic irq mask
  mov ah, al				; put it up in ah
  in al, 0x21				; get master pic irq mask
  retn					; return to caller
;------------------------------------------------------------------------------



globalfunc int.set_irq_mask
;------------------------------------------------------------------------------
;>
;; Set both master and slave pic irq mask
;;
;; parameters:
;;------------
;; al = master pic irq mask
;; ah = slave pic irq mask
;;
;; returned values:
;;-----------------
;; none, eax destroyed
;<
;------------------------------------------------------------------------------
  out 0x21, al				; send irq mask to master pic
  mov al, ah				; load up irq mask of slave pic
  out 0xA1, al				; send irq mask to slave pic
  retn					; return to caller
;------------------------------------------------------------------------------


globalfunc gdt.create_descriptor
;------------------------------------------------------------------------------
;>
;; Create a GDT descriptor
;;
;; parameters:
;;------------
;; esi = base address of segment to create
;; ecx = size of segment
;; dh  = type of segment
;; dl  = default operation/address size 0=16bits, 1=32bits
;;
;; returned values:
;;-----------------
;;
;;   eax = gdt descriptor bits 0-31
;;   ebx = gdt descriptor bits 32-63
;;   esi = segment selector
;;
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  push edi				; back it up!
					;
					; Get Pointer to first free GDT entry
					;------------------------------------
  mov edi, [gdt.offset]			; get pointer to GDT
  mov ebx, [edi + gdt_null_desc.first_free]
  test ebx, ebx				; verify that next free entry isn't nil
  stc					; set error flag in case
  mov eax, __ERROR_GDT_FULL__		; prepare error code
  jz short .exit			; in case its nil, exit
					;
					; Unlink GDT entry
					;-----------------
  mov eax, [ebx]			; get pointer to next free entry
  push ebx				; save current gdt entry pointer
  mov [edi + gdt_null_desc.first_free], eax ; set pointer to next free entry
					;
					; Create GDT descriptor
					;----------------------
  mov ebx, esi				; load base address
  mov eax, esi				; load base address
  and ebx, 0xFF000000			; keep only highest 8 bites of address
  rol eax, 16				; rotate bits left by 16
					;  the original 16-23 bits will end up
					;  in bits 0-7; original bits 0-15 will
					;  end up in bits 16-31
  test ecx, 0xFFF00000			; check if segment size require BIG bit
  mov bl, al				; load original address bits 16-23
  jz short .small_seg			; if it isn't required.. bypass bit set
  shr ecx, 12				; divide size by 4KB
  or ebx, 0x00800000			; set the BIG bit
.small_seg:				;
  mov ax, cx				; load size 0-15 in descriptor low part
  pop esi				; restore pointer to gdt entry selected
  neg edi				; negate gdt location to compute index
  and ecx, 0x000F0000			; keep only high part of segment size
  test dl, dl				; test default operation size
  mov bh, dh				; set segment type
  jz short .16bits_seg			; if 16 bits, bypass bit set
  or ebx, 0x00400000			; set operation size bit
.16bits_seg:				;
  or ebx, ecx				; include high part of segment size
  mov [esi], eax			; write gdt descriptor low part
  mov [esi + 4], ebx			; write gdt descriptor high part
  add esi, edi				; compute gdt entry index (selector)
  clc					; clear any error flag
.exit:					;
  pop edi				; restore edi
  retn					; return to caller
;------------------------------------------------------------------------------


globalfunc gdt.destroy_descriptor
;------------------------------------------------------------------------------
;>
;; Destroy a GDT Descriptor
;;
;; parameters:
;;------------
;; EAX = Selector of the gdt entry to destroy
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  push edi				; backup edi reg
  cmp eax, [gdt.size]			; parameter sanity check
  mov edi, [gdt.offset]			; load pointer to gdt
  jnb short .above_gdt_limit		; index points above gdt? exit !
					;
  add eax, edi				; point to gdt entry
  push dword [edi + gdt_null_desc.first_free]	; original first free
  mov [edi + gdt_null_desc.first_free], eax	; new first free
  pop dword [eax]			; link to original first free
  clc					; clear any error flag
  pop edi				; restore edi
  retn					; return to caller
					;
.above_gdt_limit:			;
  pop edi				; restore edi
  mov eax, __ERROR_INVALID_PARAMETERS__	; set error code
  stc					; set error flag
  retn					; return to caller
;------------------------------------------------------------------------------


globalfunc int.hook
;------------------------------------------------------------------------------
;>
;; Hook an Interrupt Handler directly in the IDT
;;
;; parameters:
;;------------
;; AL = Interrupt number
;; esi = pointer to interrupt handler
;;
;; returned values:
;;-----------------
;; ebx = original interrupt number requested
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  movzx ebx, al				; expand interrupt number to 32bit
  mov eax, __ERROR_INVALID_PARAMETERS__	; set error in case int > idt limit
  cmp bl, IDT_ENTRY_COUNT		; original idt size created
  jnb short .exit_with_error		; int > idt limit? exit!
					;
					; Acquire pointer to idt entry
					;-----------------------------
  push edi				; back those up..
  push esi				;
  push ebx				;
  					;
  mov edi, [idt.offset]			; get pointer to idt
  lea edi, [ebx * 8 + edi]		; add in displacement to int entry
  					;
  mov eax, esi				; load interrupt handler location
  mov ebx, cs				; get code segment value
  and esi, 0x0000FFFF			; keep only lowest 16 bits
  shl ebx, 16				; switch left 16 bits original cs
  and eax, 0xFFFF0000			; keep only highest 16 bits
  or esi, ebx				; mask in code segment value
  or eax, 0x00008E00			; mask gate as 32bit, present, DPL=0
  mov [edi], esi			; write low part of int descriptor
  mov [edi + 4], eax			; write high part of int descriptor
  pop ebx				; restore backed up registers
  pop esi				;
  pop edi				;
  clc					; clear any error flag
  retn					; return to caller
					;
.exit_with_error:			;
  stc					; set error flag
  retn					; return to caller
;------------------------------------------------------------------------------


globalfunc int.unhook
;------------------------------------------------------------------------------
;>
;; Unhook an interrupt descriptor
;;
;; parameters:
;;------------
;; al = interrupt number
;;
;; returned values:
;;-----------------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  push esi
  mov esi, _default_int_handler
  call int.hook
  pop esi
  retn
;------------------------------------------------------------------------------



globalfunc int.set_default_handler
;------------------------------------------------------------------------------
;>
;; Set the default interrupt handler that will be called if an unhooked int
;; is generated.
;;
;; note: send -1 to restore potassium's default
;;
;; Parameters:
;;------------
;;  esi = pointer to interrupt handler function
;;
;; Returned values:
;;-----------------
;; none, always successful
;<
;------------------------------------------------------------------------------
  mov [idt.default_handler], esi
  retn
;------------------------------------------------------------------------------




_default_int_handler:
;------------------------------------------------------------------------------
  cmp dword [idt.default_handler], byte -1	; check if default handler is
  jz short .no_handler_hooked			; present, if not, deal with it
						;
						; Redirect to default handler
  jmp [idt.default_handler]			;<---------------------------
						;
						; Default handler not present
.no_handler_hooked:				;----------------------------
						;
						; Extra check in case we have
						; a double or tripple fault
						;-----------------------------
  inc byte [idt.fatal_error]			; inc fatal error count
  jnz short $					; if not going from -1 to 0...
						; we have a double fault at
						; the least
						;
						; Disable Non-maskable int
  call int.disable_nmi				;-------------------------
 						;
						; Display unhandled
						;------------------
  mov esi, strings.unhandled_interrupt		; our error message
  mov edi, 0xB8000				; location to print it
  mov ah, 0x40					; color code
.writing_message:				;
  lodsb						; load one char
  stosw						; write char + color
  test al, al					; test for end of string
  jnz short .writing_message			; if char isn't null, continue
  jmp short $					; lock the comp.
;------------------------------------------------------------------------------



_irq_common:
;------------------------------------------------------------------------------
  push eax
  mov al, 0x20
  out 0x20, al
  pop eax
  externfunc ics.send_confirmed_message
  add esp, byte 4
  iretd
;------------------------------------------------------------------------------




;------------------------------------------------------------------------------
  align 8, db 0				; align code on 8 bytes boundary for
  					; faster computations
					; (see int.hook_irq and int.unhook_irq)
					;
_irq_0:					;-----------: IRQ 0 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_1:					;-----------: IRQ 1 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_2:					;-----------: IRQ 2 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_3:					;-----------: IRQ 3 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_4:					;-----------: IRQ 4 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_5:					;-----------: IRQ 5 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_6:					;-----------: IRQ 6 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_7:					;-----------: IRQ 7 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common			; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_8:					;-----------: IRQ 8 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_9:					;-----------: IRQ 9 handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_A:					;-----------: IRQ A handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_B:					;-----------: IRQ B handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_C:					;-----------: IRQ C handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_D:					;-----------: IRQ D handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_E:					;-----------: IRQ E handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
					;
_irq_F:					;-----------: IRQ F handler
  push dword 0				; ICS channel, set at initialization
  jmp short _irq_common_slave		; jump to common irq handling code
.count: db -1				; number of client hooked on this irq
;------------------------------------------------------------------------------



_irq_common_slave:
;------------------------------------------------------------------------------
  push eax
  mov al, 0x20
  out 0x20, al
  out 0xA0, al
  pop eax
  externfunc ics.send_confirmed_message
  add esp, byte 4
  iretd
;------------------------------------------------------------------------------
