;--------------------------------------------------------------------------==|
; VESA (VBE3) Video Driver                Copyright (c) 2002 Hubert Eichner  ;
; using BIOS                              Distributed under the BSD License  ;
;--------------------------------------------------------------------------==|
; 						;
; IMPORTANT!!! README!!!			;
; This cell supports LFB ONLY, and no bank   	;
; switching! Don't attempt to call bitblit	;
; or other functions when the cell_init gives	;
; back an error					;
; You must also heck if your box has enough mem	;
; for the user framebuffer. This may take over  ;
; 5 megs. Atm, more than 1024x768x16 is too 	;
; much because the amount of RAM is set in	;
; osw.asm; setting another amount there makes	;
; the VESA driver act strange (it allocs the mem;
; but has a problem writing/reading to it)	;
; Use this cell on your own risk! If your box	;
; crashes, you loose data or whatever bad may	;
; happen because of the use of this driver, I'm	;
; not responsible for it!			;
;						;
; Have phun!					;
;		myselph (myselph@users.sf.net)	;
;-----------------------------------------------;
%define _DEBUG_					; Use this to get debugging output
						;
						;
[bits 32]					;
%define MODES_SIZE 5*4				; size of one mode in mode structure
						;
section .c_info					;
						;
  db 0,0,5,'a'					; version
  dd str_name					; name of cell
  dd str_author					; author of cell
  dd str_copyrights				; copyright stuff
						;
  str_name: db "VESA Driver via bios",0		; cell name
  str_author: db "Hubert Eichner (myselph@users.sf.net)",0 ; my name :-)
  str_copyrights: db "Distributed under BSD License",0
						;
;-------------------------[ CELL INIT ]------------------------------
section .c_init					;
global _start					;
_start:						;
	pushad					;
	call _detectcard			; Detect card
	jc .cinit_error				; no vesa card found? well...
						;					
	;TODO: Registration with DevFS;		;
	;not done yet because			;
	;new devfs isn't coded yet		;
						;
						;
	clc					; return to caller w/o error
	popad					; restore registers
	retn					;
						;
    .cinit_error:				; no card found
	lprint "VESA: No VESA-LFB compatible card found...", FATALERR
	stc					;
	popad					;
	retn					;	
						;
						;	
;-----------------------------------------------;
;----------- [ GLOBAL FUNCTIONS ] --------------;
;-----------------------------------------------;
section .text					;
						;
function_call_table:				; function calltable for devfs
.get_card_info:	dd get_card_info		;
.set_mode:	dd set_mode			;
.get_mode:	dd get_mode			;
.list_modes:	dd list_modes			;
.bitblit:	dd bitblit			;
.update:	dd update			;
						;
						;	
						;
;-----------------------------------------------;
;-----------------------------------------------;
;Function:	get_card_info			;
; Parameters:					;
; 	none					;
; Returned:					;
; 	eax	-	Maximum X resolution	;
; 	ebx	-	Maximum Y resolution	;
; 	ecx	-	video memory in KB	;
; 	esi	-	pointer to Video Card description string;
; 	ebp	-	Max. color depth in bpp	;
; 						;
; ----------------------------------------------;
get_card_info:					;
						;
	mov ecx, (_modelist.end_of_modelist - _modelist)/MODES_SIZE ; get number of modes to try
	mov esi, _modelist.end_of_modelist - MODES_SIZE	; get source of where to start with modes
	push edx				;
	.try_modes:				;
	mov edx, dword [esi+mode.mode]		; get modenumber
	mov ebx, dword 0x00000001		; don't store values when calling getmodeinfo
	call _get_mode_info			; call the modeinfo-function
	jnc .mode_found				; if carry flag isn't set, mode exists
	.next_mode:				;
	sub esi, MODES_SIZE			;
	loop .try_modes				;
						;
;-----------------------------------------------;
						;
	pop edx					; no mode found?
	mov eax, 0				;
	mov ebx, 0				;
	mov ecx, dword [MemoryAvail]		;
	mov esi, dword [vesainfo]		;
	mov esi, [esi+VbeInfoBlock.OemProductNamePtr]
	mov ebp, 0				;
	stc					;
	retn					;
						;
;-----------------------------------------------;
						;
	.mode_found:				;
	mov eax, dword [esi+mode.resx]		; save xres, yres
	mov ebx, dword [esi+mode.resy]		;
	mov ebp, dword [esi+mode.depth]		; convert colors to color depth
	mov ecx, dword [MemoryAvail]		;
	mov esi, dword [vesainfo]		; 
	mov esi, [esi+VbeInfoBlock.OemProductNamePtr]
	pop edx					;
	retn					;
						;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
; Function:	update				;
; Parameters:					;
;	none					;
; Returned:					;
; 	errors and registers as usual		;
; 						;
; ----------------------------------------------;
update:						;
						;
	pushad					;
	mov esi, dword [UFB_base]		;
	mov edi, dword [LFB_base]		;
	mov eax, dword [resx]			;
	shr eax, 2				; divide by 4 because of lodsd
	mul dword [resy]			;
	mul dword [bpp]				; ebx = bits/pixel
	shr eax, 3				; -> bytes/pixel
	mov ecx, eax				;
	rep movsd				;
	popad					;
	clc					;
	retn					;
						;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
; Function:	set_mode			;
; Parameters:					;
; 	eax	-	X res			;
; 	ebx	-	Y res			;
; 	ecx	-	Depth in bits		;
; 	edx	-	Pitch (xres*bpp/8)	; number of bytes per scanline
; Returned:					;
;	edi	-	LFB to which you are to write which will be displayed. 
; 	errors and registers as usual		;
; 						;
; ----------------------------------------------;
set_mode:					;				
	pushad					;
	mov	edx, 1				; we don't need edx (yet)
	shl	edx, cl				; 2 exp depth = colors
	mov	ecx, edx			; because modes struc uses cols, nod coldepth
						;
	call _findvesamode			; Does the requested mode exist in our table?
	jnc .mode_found				; umm... nope :-(
	lprint "VESA: Mode not supported!", LOADINFO
	stc					;
	popad					;
	retn					;
						;
;-----------------------------------------------;
						;
	.mode_found:				;
	mov edx, dword [edx+mode.mode]		; move mode number into edx (e. g. 101, ...)
  	push dx					; mem.alloc destroys edx
	xor ebx, ebx				; clear ebx : store values!
	call _get_mode_info			; get more infos about the mode
	cmp byte [LFB_available], 1		; is LFB available in this mode?
	jz .setup_UFB				; no, so call mode with bank switching enabled
	lprint "VESA: No LFB available!", FATALERR
	popad					;
	stc					;
	retn					;
						;
;-----------------------------------------------;
						;
  .setup_UFB:					; only setup when LFB available
  	mov eax, dword [resx]			;
	mul dword [resy]			;
	mul dword [bpp]				;
	shr eax, 3				; coz bpp is in bits/pixel
	mov ecx, eax				;
	dbg lprint "Requesting %d bytes for UFB", LOADINFO, ecx
	externfunc mem.alloc			;
	jnc .uselfb				;
						;
  	lprint "VESA: Not enough mem for UFB", FATALERR
	popad					; not implemented (this could take some time...)
	stc					; set the carry flag for error
	retn					; no bank switching support yet
						;
;-----------------------------------------------;
						;
  .uselfb:					; in case the mode (the card) supports LFB
	mov [UFB_base], edi			;
	mov eax, 0x00000000			; clear UFB
	shr ecx, 2				; we write dwords, not bytes
	rep stosd				; write zeros into UFB
						;
	dbg lprint "VESA: UFB_base at %d", LOADINFO, edi
	pop bx					; first 8 bits of mode number
	or bh, 01000001b			; cl. vidram, use cur. def. refresh rate, lfb,
						; set bit 8 of mode number
;-----------------------------------------------;
						;
  .switch:					; 
  	mov eax, 0x00004F02			; func 02 - set video mode
 	push dword 0x00000010			; int 10h
 	externfunc realmode.proc_call		; exec realmode interrupt
	add	esp,4				; Clean stack
	cmp	al,04fh				; succesful?
	je	.intok				; fail, if not switched
	popad					;
	lprint "VESA: Couldn't switch to mode!", FATALERR
	stc					;
	retn					;
						;
;-----------------------------------------------;
						;
  .intok:					; Return to caller
	dbg lprint "VESA: Successfully switched to mode %x", LOADINFO, edx
	cmp dword [bpp], 8			; if bpp is 8, set_palette
	jnz .set_mode_finished			; if not, finish
						;
;-----------------------------------------------; set the palette
						;
	mov dx, 0x03C8				; tell vga that we set all colors
	xor ax, ax				;
	out dx, al				;
	mov dx, 0x03C9				; now the color values come...	
	mov esi, pal_8bpp.r_array		;
	.next_r:				;
	mov edi, pal_8bpp.g_array		;
	.next_g:				;
	mov ebp, pal_8bpp.b_array		;
	.next_b:				;
	mov al, byte [esi]			;
	out dx, al				;
	mov al, byte [edi]			;
	out dx, al				;
	mov al, byte [ebp]			;
	out dx, al				;
	inc ebp					;
	cmp ebp, pal_8bpp.b_array + 8		;
	jne short .next_b			;
	inc edi					;
	cmp edi, pal_8bpp.g_array + 4		;
	jne short .next_g			;
	inc esi					;
	cmp esi, pal_8bpp.r_array + 8		;
	jne short .next_r			;
						;
;-----------------------------------------------;
						;
	.set_mode_finished:			;
	clc					;
	popad					;
	mov edi, dword [UFB_base]		; return User Frame Buffer
	retn					;
  						;
  						;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
; Function: 	get_mode			;
; Parameters:					;
; 	none					;
; Returned:					;
; 	eax	-	X res			;
; 	ebx	-	Y res			;
; 	ecx	-	Depth			;
; 	edx	-	Pitch 			;
;	edi	-	UFB base address	;
;-----------------------------------------------:
						;
get_mode:					;
						;
	mov eax, dword [resx]			; easy, just fill regs with our mode infos
	mov ebx, dword [resy]			;
	mov ecx, dword [bpp]			;
	mov edx, dword [pitch]			;
	mov edi, dword [UFB_base]		;
	retn					;
						;
						;
						;
;-----------------------------------------------;
; ----------------------------------------------;
; Function: 	video.list_modes		;
; Parameters:					;
;  eax	-  Depth to filter (0xFFFFFFFF for no filter)
;  ecx	-  32bit Pointer to child		; 
;	   function to call			;
;  ebp	-  Passed to child function as is	;
; Returned:					;
;  errors and registers as usual		;
; 						;
; ----------------------------------------------;
;						;
; Child Function Parameters:			;
;  eax	-  X res				;
;  ebx	-  Y res				;
;  ecx	-  Depth				;
;  ebp	-  same as that passed to function video.list_modes
; Child function returned values:		;
;  cf	-  1 = cancel listing, 0 = continue	;
;  ecx	-  32bit Pointer to child function to call next
;  ebp	-  Passed to next child function called	;
;-----------------------------------------------;
						;
list_modes:					;
						;
	cmp eax, dword 0xFFFFFFFF		; doesn't do anything right now
	jz short .no_filter			;
  						;
	.no_filter:				;
	pushad					; save regs
	push ecx				; save pointer to child function
	mov edi, (_modelist.end_of_modelist - _modelist)/MODES_SIZE ; get number of modes to try
	mov esi, _modelist			; get source of where to start with modes
	.try_modes:				;
	mov edx, dword [esi+mode.mode]		; get modenumber
	mov ebx, dword 0x00000001		; don't store values when calling getmodeinfo
	call _get_mode_info			; call the modeinfo-function
	jc .next_mode				; if carry flag set, mode doesn't exist
	mov eax, dword [esi+mode.resx]		; save xres, yres
	mov ebx, dword [esi+mode.resy]		;
	mov ecx, dword [esi+mode.depth]		; convert colors to color depth
	pop edx					;
	call edx				;
	jc .end_of_try_modes			;
	push ecx				;
	.next_mode:				;
	add esi, MODES_SIZE			;
	dec edi					;
	jnz .try_modes				;
	.end_of_try_modes:			;
	clc					; 
	retn					;
						;
						;
						;
;-----------------------------------------------;
;-----------------------------------------------;
; Function:	bitblit				;
; Parameters:					;
;  eax	-  Width of source			;
;  ebx	-  Height of source			;
;  ecx	-  Horizontal offset of where to blit to;
;  edx	-  Vertical offset of where to blit to	;
;  edi 	-  Pitch of source			;
;  esi 	-  32bit Pointer to start of source	; 
; Returned: 					;
;  ecx 	-  0 if blitted without clipping needed ;
; 						;
; ----------------------------------------------;
;						;
; bitblit overtakes a 32bit-image. Other color	;
; depths aren't and won't become supported,	;
; because we intend to set 32bit as a standard.	;
; This picture is then converted to the screen	;
; color depth, either 8bit, 16bit or 24bit	;
; (don't expect me to support 4 or 15 bit :-)	;
; and written to the UFB (User Frame Buffer).	;
; In order to copy the UFB to videomemory, you	;
; must use the update function!			;
;------------------------------------------------------
						;
bitblit:					;
						;
						;
						;
	pushad					;
	dbg lprint "VESA: bpp is %d bit",LOADINFO,dword [bpp]
						;
	cmp dword [bpp], dword 8		; 8 bit?
	jz .bitblit_8bit			;
	cmp dword [bpp], dword 16		;
	jz .bitblit_16bit			; jump to the 16bit-function
	cmp dword [bpp], dword 32		;
	jnz .bitblit_init_error			; 24bit without alpha-channel isn't
	call .bitblit_24bit			; too far away for jump -> call
	popad					; return to caller
	clc					;
	retn					;
						;
	.bitblit_init_error:			;
	lprint "VESA: bitblit init error!", FATALERR
	popad					;
	stc					;
	retn					;
						;
;-----------------------------------------------;
						;
	.bitblit_8bit:				;
	; 8bit-pic				;
	; 8bit-pitch				;
	;---------------------------------------;
	mov edi, dword [UFB_base]		; calculate mem-offset:
						; prepare edx (voffset)
	imul edx, dword [pitch]			; edx = edx*xres*bpp/8
	add edi, edx				; update edi with new mem-offset
	add edi, ecx				;
	add edi, eax				; also add width; blit-func will sub it l8er
	sub edi, dword [pitch]			; and decrease mem by one line (blit will add it l8er)
						;
	.bitblit_8bit_vertical:			; the bitblit routine for LFB
	sub edi, eax				; 
	add edi, dword [pitch]			;
						;
	mov ecx, eax				; put width into ecx
	push eax				; and draw word [esi] to [edi] ecx times
	.convert_to_8bit_loop:			;
	lodsd					;
	xor edx, edx				;
	and eax, 00000000111000001100000011100000b
	or dl, al				; dl=rrr00000
	shr eax, 3				; ah=000gg000
	or dl, ah				; dl=rrrgg000
	shr eax, 10				; ah=00000bbb
	or dl, ah				; dl=rrrggbbb
	mov al, dl				;
	stosb					;
	loop .convert_to_8bit_loop		;
	rep movsb				;
	pop eax					;
	dec ebx					;
	jnz .bitblit_8bit_vertical		;
						;
	popad					;
	clc					;
	retn					;
						;
;-----------------------------------------------;
						;
	.bitblit_16bit:				;
	; 16bit-pic				;
	; 16bit-pitch				;
	;---------------------------------------;
	mov edi, dword [UFB_base]		; calculate mem-offset:
						; prepare edx (voffset)
	imul edx, dword [pitch]			; edx = edx*xres*bpp/8
						; same for ecx (hoffset)
	shl ecx, 1				; 16bpp for now
	shl eax, 1				; and same for width
	add edi, edx				; update edi with new mem-offset
	add edi, ecx				;
	add edi, eax				; also add width; blit-func will sub it l8er
	shr eax, 1				; restore eax
	sub edi, dword [pitch]			; and decrease mem by one line (blit will add it l8er)
						;
						;
	.bitblit_16bit_vertical:		; the bitblit routine for LFB
	shl eax, 1				; go back to start of line
	sub edi, eax				; and add pitch so that
	shr eax, 1				; newpos=start_of_next_line
	add edi, dword [pitch]			;
	mov ecx, eax				; put width into ecx
	push eax				; and draw word [esi] to [edi] ecx times
						;
	.convert_to_16bit_loop:			; the loop for horizontal drawing
	lodsd					; format in mem is ABGR (<-)
	xor edx, edx				;
	and eax, 00000000111110001111110011111000b
	or dl, al				; copy Red channel
	shl dx, 5				; prepare for Green channel
	or dl, ah				; copy Green channel
	shl dx, 3				; prepare for Blue channel
	shr eax, 11				;
	or dl, ah				; copy blue channel
	mov ax, dx				; save to ax again
	stosw					; and write to video memory
	loop .convert_to_16bit_loop		; loop xres times
						;
	pop eax					;
	dec ebx					;
	jnz .bitblit_16bit_vertical		;
						;
	popad					;
	clc					;
	retn					;
						;
;-----------------------------------------------;
						;
	.bitblit_24bit:				;
	; WARNING! Supports only dword-aligned  ;
	; 24bit-videomem (with alphachannel!!!)	;
	;---------------------------------------;
	mov edi, dword [UFB_base]		; calculate mem-offset:
						; prepare edx (voffset)
	imul edx, dword [pitch]			; edx = edx*xres*bpp/8
						; same for ecx (hoffset)
	shl ecx, 2				; 32bpp now
	shl eax, 2				; and same for width
	add edi, edx				; update edi with new mem-offset
	add edi, ecx				;
	add edi, eax				; also add width; blit-func will sub it l8er
	shr eax, 2				; restore eax
	sub edi, dword [pitch]			; and decrease mem by one line (blit will add it l8er)
						;
						;
	.bitblit_24bit_vertical:		; the bitblit routine for LFB
	shl eax, 2				; go back to start of line
	sub edi, eax				; and add pitch so that
	shr eax, 2				; newpos=start_of_next_line
	add edi, dword [pitch]			;
	mov ecx, eax				; put width into ecx
	push eax				; and draw dword [esi] to [edi] ecx times
						;
	.convert_to_24bit_loop_32bpp:		;
	lodsd					; 
	xor edx, edx				; see explanation for 16bit-function
	mov dh, al				;
	mov dl, ah				; 
	shl edx, 8				; 
	shr eax, 8				; 
	mov dl, ah				;
	mov eax, edx				;
	stosd 					;
	loop .convert_to_24bit_loop_32bpp	;
						;
	pop eax					;
	dec ebx					;
	jnz .bitblit_24bit_vertical		;
						;
	popad					;
	clc					;
	retn					;
						;
						;
;-----------------------------------------------;
;-----------[ Internal FUNCTIONS ]--------------;
;-----------------------------------------------;


;-----------------------------------------------;
; _detectcard - checks if VESA card is installed;
;-----------------------------------------------;
						;
_detectcard:					;
	pushad					;
	xor edx,edx				; allocate some bytes for int 10 callback 
						; tables in realmode address space
	mov ecx,256*2 				; 256 bytes * 2 Tables
	dbg lprint "VESA: Allocating memory under 1MB",LOADINFO
	externfunc mem.alloc_20bit_address	;
	jc .fail_alloc				;
	cmp ecx,256*2				;
	jl .fail_alloc				;
	jmp .h_ahead				;
  .fail_alloc:					;
  	lprint "VESA: Allocating memory under 1MB failed!",FATALERR
  	popad					;
  	stc					;
  	retn					;
  .h_ahead:					; Went Ok, go ahead
	mov [vesainfo], edi			; store pointers to allocated space
	add edi, 256				;
	mov [modeinfo], edi			;
	sub edi, 256				;
						;
	mov dword [edi], '2EBV'			; fill [edi] with signature
	mov eax, edi				; convert edi to realmode address (segmented)
	shl eax,12				;
	shr ax,12				;
	movzx edi,ax				;
	and eax,0xFFFF0000			;
	push eax				; seg in ES: DS=0
 	push DWORD 0x00000010			;
 	mov eax,4f00h				; func 00, Return VESA Information
 	externfunc realmode.proc_call		; execute int 10h
	add esp,8				; Clean stack
	cmp al,04fh				; call successful?
	je .initok				; fail, if VBExtentions not available
	popad					;
	lprint "VESA: Vesa not available at all!", FATALERR
	stc					;
	retn					;
						;
;-----------------------------------------------;
						;
.initok:					;
  	mov edi, [vesainfo]			; vesainfo contains pointer to VbeInfoBlock
  	movzx eax,word  [edi+VbeInfoBlock.TotalMemory]
	shl eax,6				; Total memory is in 64kb mem blocks, so getting in KB
	mov [MemoryAvail], eax			;
	dbg lprint "VESA: available memory on card %u bytes.", LOADINFO, eax
						;
	mov eax, dword [edi+VbeInfoBlock.VbeSignature]	
	cmp dword eax,'VESA'			; VESA signature? if yes, oki!
	jz .check_next				;
						;
	lprint "VESA: Vesa not available! Signature not VESA :(", FATALERR
	popad					;
	stc					;
	retn					;
						;
;-----------------------------------------------;
						;
.check_next:					;
	cmp byte [edi+VbeInfoBlock.VbeVersion+1], 02h	;check BCD version numver of 2.x
	je .okidoki				; VBE Version 2?
	cmp byte [edi+VbeInfoBlock.VbeVersion+1], 03h	;check BCD version numver of 3.x
	je .okidoki				; ...or VBE Version 3?
	popad					;
	lprint "VESA: VBA2 or VBA3 not available!", FATALERR
	stc					;
	ret					;
						;
	.okidoki:				;
	push ebx				;
	xor ebx, ebx				;
	mov bx, word [edi+VbeInfoBlock.VbeVersion]
	dbg lprint "VESA: version %x available", LOADINFO, ebx
	pop ebx					;
	clc					;
	popad					;
	retn					;
						;
						;	
;-----------------------------------------------;
; _get_mode_info				;
; parameters: edx = VESA mode number		;
; 	      ebx = 1: just try mode but don't	;
;	               save the values		;
;-----------------------------------------------;
						;
						;
_get_mode_info:					;
	pushad					;
	mov edi, [modeinfo]			;
	mov eax, edi				; Flat -> seg:off
	shl eax, 12				;
	shr ax, 12				;
	movzx edi,ax				; offset
	and eax,0ffff0000h			;
	push eax				; seg in ES: DS=0
 	push DWORD 0x00000010			; Int 10h
 	mov eax,4f01h				; func 01, Return VBE mode information
 	mov ecx,edx				; check desired mode
	externfunc realmode.proc_call		;
	add esp,8				;
	cmp al,04fh				; call successful?
	jz .initlfb				; fail, if VBExtentions not available
	lprint "VESA: Mode not supported", FATALERR
	popad					;
	stc					;
	retn					;
						;
;-----------------------------------------------;
						;
	.initlfb:				; check for LFB
	mov edi, [modeinfo]			;
	mov eax, dword [edi+ModeInfoBlock.ModeAttributes]		;get mode attribute WORD
	test ax, 0x80				; LFB-bit set?
	jnz .LFB				; no, don't store 1 in [LFB_available]
						;
	lprint "mode doesn't support LFB!", FATALERR
	mov [LFB_available], byte 0		;
	popad					;
	stc					;
	retn					;
						;
	.LFB:					; Assume now we have LFB
	mov [LFB_available], byte 1		; store it
	cmp ebx, 1				; should we store the values in [resx] etc.?
	jnz .store_values			;
	popad					; no, so return to (probably) list_modes function
	clc					;
	retn					;
						;
;-----------------------------------------------;
						;
	.store_values:				;
	xor esi, esi				; save xres
	mov si, word [edi+ModeInfoBlock.XResolution]
	mov dword [resx], esi			;
	dbg lprint "VESA: resx: %u", LOADINFO, [resx]
						;
	xor	esi, esi			; save yres
	mov	si, word [edi+ModeInfoBlock.YResolution]
	mov	dword [resy], esi		; 
	dbg lprint "VESA: resy: %u", LOADINFO, [resy]
						;
	xor ebx, ebx				;
	mov bl, byte [edi+ModeInfoBlock.BitsPerPixel]
	mov dword [bpp], ebx			; save colordepth
	dbg lprint "VESA: bpp: %u", LOADINFO, [bpp]
						;
	xor esi, esi				; save bytes per scanline (bpp/8*xres)
	mov si, word [edi+ModeInfoBlock.BytesPerScanLine]
	mov dword [pitch], esi			;
	dbg lprint "VESA: pitch: %u", LOADINFO, [pitch]
						;
	mov	esi, dword [edi+ModeInfoBlock.PhysBasePtr]
	mov	dword [LFB_base], esi		; get the LFB base address
	dbg lprint "VESA: LFB-Base-Address: %x", LOADINFO, esi
						;
						;
	xor eax, eax				;
	mov al, byte [edi+ModeInfoBlock.MemoryModel]
	dbg lprint "VESA: memory model, %x", LOADINFO, eax
						;
						;
						;
	popad					;
	clc					;
	retn					; return to caller function
						;
;-----------------------------------------------;
; _findvesamode: check if a specified mode is	;
; available and give back a pointer to the mode	;
;-----------------------------------------------;
_findvesamode:					; function to find the desired mode in the mode struc
; IN:	eax	-	X res			;
;	ebx	-	Y res			;
;	ecx	-	Colors			;
; OUT:	edx	- 	Pointer to entry	;
;	cf set if nothing found			;
;-----------------------------------------------;
						;
	lea edx, [_modelist]			;
	sub edx, MODES_SIZE			;
.resx_loop:					; First we scan for a correspondent X-Resolution ...
	add edx, MODES_SIZE			;
	cmp [edx], dword 00h			; end of mode struc is marked with a dword 00
	jz .notfound				;
	cmp [edx+mode.resx], dword eax		;
	jnz .resx_loop				;
						; okay, xres found, what about the yres?
	cmp [edx+mode.resy] dword ebx		;
	jnz .resx_loop				;
						; Found xres and yres, now check color...
	cmp [edx+mode.colors], dword ecx	;
	jnz .resx_loop				; nothing found? Okay, search on
						; Yahoo, found it, yep!
						; EDX = Already the pointer to the mode :)
	clc					;
	retn					;
						;
.notfound:					;
	stc					;
	retn					;
						;
						;
						;
						;
;--------------------------- [ DATA ] ----------------------------------
section .data					;
						;
%include "struc.inc"				; the Vesa callback table structures
%include "modes.inc"				;
						;
; Card related.					;
						;
vesainfo: dd 0					;
modeinfo: dd 0					;
						;
MemoryAvail:	dd 0				;
UFB_base:	dd 0				; User frame buffer base address
						;
LFB_available:	db 0				; LFB availability byte
LFB_base:	dd 0				; Linear Frame Buffer base address
resx:		dd 0				;
resy:		dd 0				;
bpp:		dd 0				;
pitch:		dd 0				;
						;
pal_8bpp:					; values for VGA colors in 8bit modes
.r_array: db 0,9,18,27,36,45,54,63		;
.g_array: db 0,21,42,63				;
.b_array: db 0,9,18,27,36,45,54,63		;

