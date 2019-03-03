; U-Burn boot loader
; Copyright (C) 2002, Dave Poirier
; Distributed under the X11 License
;
; Note: Unless otherwise specified all values in the comments are assumed to
;       be hexadecimal.
;
; originally developped for the Unununium Operating Engine, http://uuu.sf.net/

org 0x7C00
bits 16

; Let's define some generic constants...
%assign BIOSVIDEO			0x10
%assign BIOSDISK			0x13
%assign BIOSDISK_RESET			0x00
%assign BIOSDISK_READ_SECTORS		0x02
%assign BIOSDISK_GET_DRIVE_PARAM	0x08
%assign CGA_TEXT_SEGMENT		0xB800
%assign VRAM_SEGMENT			0xA000

; some more definitions for MultiBoot support
%assign MBOOT_SIGNATURE	0x1BADB002
%assign MBOOT_LOADED	0x2BADB002

struc mboot
.magic               resd 1
.flags               resd 1
.checksum            resd 1
.header_addr         resd 1
.load_addr           resd 1
.load_end_addr       resd 1
.bss_end_addr        resd 1
.entry_addr          resd 1
endstruc

; and yet more for ELF support
%assign SHT_PROGBITS	1
%assign SHT_NOBITS	8
%assign ELF32_SIGNATURE	0x464C457F

struc elf_header
.e_signature:	resd 1
.e_class:	resb 1
.e_data:	resb 1
.e_hdrversion:	resb 1
.e_ident:	resb 9
.e_type:	resw 1
.e_machine:	resw 1
.e_version:	resd 1
.e_entry:	resd 1
.e_phoff:	resd 1
.e_shoff:	resd 1
.e_flags:	resd 1
.e_ehsize:	resw 1
.e_phentisze:	resw 1
.e_phnum:	resw 1
.e_shentsize:	resw 1
.e_shnum:	resw 1
.e_shstrndx:	resw 1
endstruc

struc elf_section
.sh_name:	resd 1
.sh_type:	resd 1
.sh_flags:	resd 1
.sh_addr:	resd 1
.sh_offset:	resd 1
.sh_size:	resd 1
.sh_link:	resd 1
.sh_info:	resd 1
.sh_addralign:	resd 1
.sh_entsize:	resd 1
endstruc



;------------------------------------------------------------------------------
_start:
  jmp short _entry		; some bioses requires a jump at the start
  nop				; and they also check the third byte..
;------------------------------------------------------------------------------
; Insert here any file system specific information you might require.
; I.e.: FAT Header


;------------------------------------------------------------------------------
error:
;  push ax			; backup the error code
;  mov ax, 0x0003		; function: set video mode, mode: 80x25 color
;  int BIOSVIDEO			; set text video mode
;  push word CGA_TEXT_SEGMENT	;
;  pop ds			; load ds with text video segment
;  pop ax			; restore the error code
;  aam 0x10			; split the two digits apart
;  cwde				; give us some room in eax
;  cmp al, 0x0A			; convert first digit into ascii
;  sbb al, 0x69			;
;  das				;
;  shl eax, 8			;
;  aad 0x01			;
;  cmp al, 0x0A			; convert second digit into ascii
;  sbb al, 0x69			;
;  das				;
;  or [0], eax			; display them
  				; note: we use 'or' instead of 'mov' so that we
				; dont' have to fill in the color codes for the
				; 2 digits string.
				;
  jmp short $			; lock it up.
				;
_entry:				; setup data and stack segments
				;------------------------------
  xor di, di			; prepare di for get_drive_param (bios bug)
  mov ds, di			; set data segment to	0000
;  mov es, di			; prepare es for get_drive_param (bios bug)
  mov ss, di			; set stack segment to	0000
  mov sp, 0x1000		; set top of stack to	1000
  sti				; enable interrupts
				;
				; set video mode to 320x200
				;--------------------------
  mov al, 0x13			; 13h = 320x200x4bpp
  int BIOSVIDEO			; request servicing
				;
				; get disk geometry
				;------------------
  mov ah, BIOSDISK_GET_DRIVE_PARAM
  mov [drive], dl		; backup drive id
  int BIOSDISK			; request servicing
  mov al, ah			; store error code in case
  test ah, ah			; check if completed with success
  jnz short error		; if not, display error and lock
				;
  and cl, 0x3F			; extract max sector number
  mov [spt], cl			; store spt
  mov [head], dh		; store head
				;
				; read loadmap table
				;-------------------
  xor dx, dx			; set sector id:  00000001
  mov al, 1			;                 -DX--AX-
  mov cx, ax			; sector count:   CX = 1
  xor bx, bx			;
  push word 0x07E0		;
  pop es			; ES:BX = address to load the sectors
  call load_sectors		; load them
  mov si, 0x7E00		;
  lodsw				; ah=sectors per block, al=blocks to load
  mov cl, ah			; cx=sectors per block
  cbw				; ax=blocks to load
  xchg ax, di			; di=blocks to load
  lodsw				; move si forward 2 bytes
  xor bp, bp			; set progress bar start = 0
loading_object:			;
  lodsw				; load low 16-bit of LBA
  xchg ax, dx			; temporarily store it in dx
  lodsw				; load high 16-bit of LBA
  xchg ax, dx			; ax: low 16, dx: high 16
  inc bp			; increase progress mark
  pusha				; backup registers (si,bx,cx,bp,di)
  call load_sectors		; load (blocks to load) from LBA
  ;---------------------------------------------------------------------------
  ; display some cute gfx progress bar on the right side, bottom to top
  ;
  ; bp = number of sectors to load total
  ; di = number of sectors left to load
  ; si = pointer to next sector id to load
  ; ax, dx and cx are free to use
  ; bx = offset to load the sectors, must be 0 when leaving
  ; cx = 0
  ; es = segment to load the sectors, must be kept intact
  ; ds = 0000
  ; cs = 0000
  mov ax, 200			; 320 x 200
  mul bp			; compute progress bar percentage
  div di			;
  push es			; backup load segment address
  push word VRAM_SEGMENT	;
  pop es			; set es = gfx video segment
  mov di, 320*200		; warp to bottom right corner
  xchg ax, dx			; dx = progress / 200
  mov al, 0x09			; al = color
.drawing_bar:			;
  dec di			; get place for 1 pixel
  dec di			; get place for a 2nd pixel
  stosb				; draw both pixels with color of AL
  stosb				;
  sub di, 320			; move up one line
  jz short .done_drawing	; if we reached the top we're done.
  dec dx			; progress bar color swap check
  jnz short .drawing_bar	; haven't reached that point yet
  dec ax			; al = color 09->08
  jmp short .drawing_bar	; continue drawing up to the top
.done_drawing:			;
  pop es			; restore the load segment address
  popa				; restore registers (si,bx,cx,bp,di)
  cmp bp, di			; loaded all sectors?
  jnz loading_object		; if not, continue loading them
				;
  mov ax, 0x0003		; all loaded, set video mode back to 80x25
  int 0x10			; do it!
				;
  cli				; disable interrutps, sensitive stuff coming
				;
				; Enable A20
				;-----------
  mov al, 0x02                  ; enable A20 bit of PS/2 control register
  out 0x92, al                  ; flag the bit, should enable the A20 gate
  call wait_kbd_command         ; wait for 8042 to be ready
  mov al, 0xD1                  ; equivalent for older systems
  out 0x64, al                  ; this time send it to the keyboard controller
  call wait_kbd_command         ; wait for 8042 to be ready
  mov al, 0x03                  ; A20 enabled, reset line high
  out 0x60, al                  ; send to keyboard controller
				;
				; turn off FDC motor
				;-------------------
  mov dx, 0x3F2			; fdc reg
  mov al, 0x0C			; motor bit off
  out dx, al			; done
				;
				; Setup Protected Mode
				;---------------------
  lgdt [__gdt]			; load GDTR
  mov ecx, cr0			; ecx = CR0
  inc ecx			; set pmode bit to 1
  mov cr0, ecx			; update CR0
  jmp 0x0008:pmode		; clear prefetch (activate change)
;-----------------------------------------------------------------------------


load_sectors:
;-----------------------------------------------------------------------------
; DX:AX = sector ID of the first sector to load
; CX    = number of sectors to load (ch must be 0)
; ES:BX = offset in memory where to load them
;------------------------------------------------------------------------------
  pusha				; save starting values
  push cx			; save number of sectors to load
  mov cl, 0			; <- Self-modifying code, 0 replaced by
spt equ $-1			;    sector-per-track value
  div cx			; extract sector number
  mov si, dx			; si = sector number
  mov cl, 0			; <- Self-modifying code, 0 replaced by
head equ $-1			;    number of heads
  inc cx			; head is 0 based, get it up a notch
  inc si			; sector number should be 1 based, adapt it
  xor dx, dx			; prepare for another division
  div cx			; extract head number
  mov dh, dl			; dh = head number
  mov dl, 0			; <- Self-modifying code, 0 replaced by
drive equ $-1			;    drive ID
  xchg al, ah			; compute cylinder/sector value
  shl al, 6			; move high 2 bits of cylinder number
  or ax, si			; merge in sector value
  xchg ax, cx			; cx = cylinder/sector
  pop ax			; restore number of sectors to load
  mov ah, BIOSDISK_READ_SECTORS	; set function number
.retry:				;
  pusha				; save all regs in case of an error
  int BIOSDISK			; read those babies!
  test ah, ah			; error occured?
  jz short .next_sector		; if not, this one is done
				;
  mov ah, 0			; reset drive
  mov dl, [drive]		; load up the drive ID
  int BIOSDISK			; do it!
  popa				; restore the regs and retry
  jmp short .retry		;
				;
.next_sector:			;
  popa				; clear the regs for the bios call
  popa				; restore the original passed values
  push es			;
  pop ax			; ax=load segment address
  shl cx, 5			;
  add ax, cx			; move load segment address forward
  mov es, ax			; update es
  xor cx, cx			; make sure ch = 0
  retn				; done loading
;-----------------------------------------------------------------------------



wait_kbd_command:
;-----------------------------------------------------------------------------
  in AL, 64h			; read 8042 status port
  test al, 0x01			; wait until port 0x60 is ready
  jc wait_kbd_command		;
  retn				;
;-----------------------------------------------------------------------------





pmode:
;-----------------------------------------------------------------------------
[bits 32]
;-----------------------------------------------------------------------------
  cwde				; zeroize high part of eax
  mov al, 0x10			; set eax = 0x00000010 (data selector)
  mov ds, eax			;
  mov es, eax			;
;  mov fs, eax			;
;  mov gs, eax			;
  mov ss, eax			;
  mov esi, 0x8000		; set esi to header of loaded file
  cmp [esi], dword ELF32_SIGNATURE;
  jz short .elf			; if .ELF found, it's an ELF file!
  mov edi, esi			; prepare to search for multiboot header
  mov eax, MBOOT_SIGNATURE	; value to search for
  mov ecx, esi			; search for maximum 0x8000 cases
  repnz scasd			; search for it
;  jz short .mboot		; if any match found, process multiboot file
  jnz short $
				;
;  mov [0xB8000], dword 0x04460449; display error code, 'IF' Invalid Format
;  jmp short $			; lock it up
				;
				; MultiBoot file
.mboot:				;---------------
  mov ecx, [edi + mboot.load_end_addr - 4]
  mov ebp, [edi + mboot.bss_end_addr - 4]
  mov edx, [edi + mboot.entry_addr - 4]
  mov edi, [edi + mboot.load_addr - 4]
  sub ecx, edi			; find number of bytes to move
  shr ecx, 2			; make them dwords
  rep movsd			; move them over
  xor eax, eax			; set eax = 0 for zeroize operation
  mov ecx, ebp			;
  sub ecx, edi			; find number of bytes to zeroize
  jz short .none		; in case there are none
  shr ecx, 2			; make those bytes dwords
  rep stosd			; zeroize them
.none:				;
  mov eax, MBOOT_LOADED		; set eax to multiboot loaded
  jmp edx			; jump to entry point
				;
				; ELF file
.elf:				;---------
  mov ebp, esi			; set ebp = pointer to header
  xor eax, eax			; prepare eax for zeroize operations
  mov edx, [ebp + elf_header.e_shoff]
  add edx, ebp			; compute offset to section header in memory
.process_section:		;
  mov esi, [edx + elf_section.sh_offset]; load section offset 'in file'
  add esi, ebp			; compute section offset in memory
  mov edi, [edx + elf_section.sh_addr]; load destination address
  mov ecx, [edx + elf_section.sh_size]; number of dword to move
  cmp [edx + elf_section.sh_type], byte SHT_PROGBITS; data provided?
  jz short .move		; yes, move it over
  cmp [edx + elf_section.sh_type], byte SHT_NOBITS; .bss?
  jnz short .skip		; nope, unknown, skip it
  rep stosb			; zeroize destination for said lenght
  jmp short .skip		;
.move:				;
  rep movsb			; move provided data
.skip:				;
  add edx, byte elf_section_size; move forward to next section description
  dec byte [ebp + elf_header.e_shnum]; another section to process?
  jnz short .process_section	; if so, go do it
  jmp [ebp + elf_header.e_entry]; if not, jump to entry point
;------------------------------------------------------------------------------




__gdt: ; Global Descriptor Table
;------------------------------------------------------------------------------
  dw (.end - .start) + 7                ; part of GDTR, size of the GDT
  dd __gdt.start - 8                    ; part of GDTR, pointer to GDT
.start:
  dd 0x0000FFFF, 0x00CF9B00             ; pmode CS, 4GB r/x, linear=physical
  dd 0x0000FFFF, 0x00CF9300             ; pmode DS, 4GB r/w, linear=physical
.end:
;------------------------------------------------------------------------------




; BIOS signature
;------------------------------------------------------------------------------
times 510 - ($-$$) db 0		; pad so that signature is the last 2 bytes
db 0x55, 0xAA			; of the sector.
;------------------------------------------------------------------------------

