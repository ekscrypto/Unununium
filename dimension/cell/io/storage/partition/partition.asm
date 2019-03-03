;---------------------------------------------------------------------------==|
; partition cell                             copyright (c) 2002 Hubert Eichner
; Partition management driver                Distributed under the BSD License
;---------------------------------------------------------------------------==|

%define _DEBUG_
%define PARTITION_SIZE 24

[bits 32]

section .c_info
	db 0,0,3,0
	dd str_title
	dd str_author
	dd str_copyrights

	str_title:
	db "Partition cell",0

	str_author:
	db "Hubert Eichner",0

	str_copyrights:
	db "BSD Licensed",0


;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
;| information:
;| - EAX        Options
;|              bit 0, 1=reloading, 0=clean boot
;| - ECX        Size in bytes of the free memory block reserved for our use
;| - EDI        Pointer to start of free memory block
;| - ESI        Pointer to CORE header
;|
;| Those information must be kept intact and passed as is to the next cell
;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||


section .c_init
global _start
_start:
retn


;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                         _open
;==============================================================================
_open:
;>
;; parameters:
;; -----------
;; EBP = same value as EBP when we registered: pointer to a partition struc
;; EDX = ptr to fs descriptor
;;
;; returned values:
;; ----------------
;; EBX = ptr to file handle
;; errors as usual
;<

mov eax, [ebp+partition.lba_start]	; load values from our own partition
mov ebx, [ebp+partition.lba_start+4]	; struc into the registers as defined
mov ecx, [ebp+partition.lba_end]	; in the specs.
mov esi, [ebp+partition.lba_end+4]	;
mov edi, [ebp+partition.device]		;
call [ebp+partition.open]		; call the dev. drivers open function
retn					; return to caller, file handle in ebx


;						--------------------------------
;								 part.initialize
;-------------------------------------------------------------------------------
globalfunc part.initialize
;
; parameters:
; EAX = pointer to struc drive_geometry
; EBX = pointer to _open function of this device
; ECX = device number
; ESI = pointer to null-terminated device string like "hd/0",0
;
; returned:
; errors and registers as usual
;---------------------------------------;
pushad					; save regs
mov [current.device], ecx		; save some values in local variables
mov [current.open], ebx			;
mov [current.path], esi			;
push eax				;
mov ecx, -1				;
.get_str_length:			; get length of string without the '\0'
inc ecx					;
cmp byte [esi+ecx], 0			;
jnz .get_str_length			; 
mov dword [current.pathlen], ecx	; save the stringlength
;---------------------------------------;
add ecx, 13 				; "/dev/"+length+'/'+"single"+'\0'
push ecx				;
externfunc mem.alloc			;
pop ecx					; mem.alloc destroys ecx
mov [edi], dword "/dev"			; first add the "/dev/" (needed for
mov [edi+4], byte '/'			; the vfs.open fct later
add edi, 5				; let edi point to the device path 
sub ecx, 13				; get original device path length
rep movsb				; copy the device string
mov ecx, 8				; length of single dev
mov esi, single_dev			;
rep movsb				; append "/single",0
mov esi, edi				; save pointer to device string in esi
sub esi, dword [current.pathlen]	; let esi point to dev string
sub esi, 9				;
;---------------------------------------;
mov ecx, PARTITION_SIZE			;
externfunc mem.alloc			; alloc space for partition struc
mov ecx, dword [current.device]		;
mov [edi+partition.device], ecx		;
mov [edi+partition.open], ebx		;
mov [edi+partition.lba_start], dword 0	; single device starts at 0
mov [edi+partition.lba_start+4], dword 0; 
mov [edi+partition.lba_end], dword -1	; and doesn't end for now
mov [edi+partition.lba_end+4], dword -1	; though I should fix this...
mov ebp, edi				; the partition struc
;---------------------------------------;
mov ebx, _open				; our own open function
externfunc devfs.register		; register the device
jnc .dev_added				; 
lprint "PARTI: Could not register single device!", FATALERR
mov eax, edi				;
externfunc mem.dealloc			; dealloc "single" partition struc
sub esi, 4				; let esi point to the very beginning
mov eax, esi				; of the path (with the "/dev/")
externfunc mem.dealloc			; dealloc device path string
add esp, 4				; undo the "push eax" 
stc					;
popad					;
retn					;
;---------------------------------------;
.dev_added:				; great, the single-device is reg'd!
sub esi, 4				; esi := ptr to path with "/dev/"
externfunc vfs.open			; esi should still contain our dev-path
mov eax, esi				; 
externfunc mem.dealloc			; deallocate memory of device path
mov ecx, 512				; alloc mem for buffer
externfunc mem.alloc			;
xor eax, eax				; LBA start = 0
xor edx, edx				; LBA start = 0
mov ecx, 1				; read one sector
mov ebp, dword [ebx]			; get pointer to file_op_table
call [ebp+file_op_table.raw_read]	; call the raw_read function
;---------------------------------------;
pop ebx					; ebx = ptr to drive_geometry struc
mov dword[current.buffer], edi		; 
mov ebp, 446				; add buffer_start later
xor esi, esi				; delete esi
cmp word [edi+510], 0xAA55		; look for boot signature
jz .bootsig_found			;
dbg lprint "PART: Could not find bootsig!", LOADINFO
mov eax, edi				; dealloc buffer for MBR
externfunc mem.dealloc			; 
clc					; we did our job - there is a "single"
popad					; device now. No partitions found :-(
retn					;
;---------------------------------------;
.bootsig_found:				;
add ebp, dword [current.buffer]		;
cmp dword [ebp+12], 0			; valid entry?
jz .next_entry				;
;---------------------------------------;
mov ecx, PARTITION_SIZE			; alloc mem for new partition struc
externfunc mem.alloc			;
mov ecx, dword [ebp+8]			; get start L-CHS
mov [edi+partition.lba_start], ecx	; store it
mov [edi+partition.lba_start+4], dword 0;
mov [edi+partition.lba_end], dword -1	; and store it
mov [edi+partition.lba_end+4], dword -1	;
mov ecx, [current.device]		; get current device
mov [edi+partition.device], ecx		;
mov ecx, [current.open]			; get device open function
mov [edi+partition.open], ecx		;
call _reg_dev				; register the device
inc esi					; partition_number++
;---------------------------------------;
.next_entry:				; 
add ebp, 16				; go to next entry in table
sub ebp, dword [current.buffer]		; 
cmp ebp, 510				; have we reached the end?
jnz .bootsig_found			;
;---------------------------------------;
mov eax, dword[current.buffer]		;
externfunc mem.dealloc			;
popad					; stack should be clean
clc					; no errors, clear carry flag
retn					; 
;---------------------------------------;



;								----------------
;								    _lchs_to_lba
;===============================================================================
_lchs_to_lba:
;>
;; EAX = 24bit L-CHS address 
;; structure of L-CHS:xxxxxxxxCCCCCCCCCCSSSSSSHHHHHHHH
;; EBX = pointer to drive_geometry struc
;;
;; returns:
;; EDX:EAX = 64bit-LBA
;;
;; destroys ecx, edx
;; the formula is: 
;; ((cylinder*heads_per_cylinder+heads)*sectors_per_track)+sectors-1
;---------------------------------------;
xor edx, edx				;
xor ecx, ecx				;
push eax					;
and eax, 111111111111111111111111b	; delete bits 24-31
shr eax, 14				; ax := cyls
ror ax, 2				;
shr ah, 6				;
mul dword [ebx+drive_geometry.heads_per_cylinder]
mov ecx, dword [esp]			; get former ax
and ecx, 0x000000FF			; cl := heads
add eax, ecx				; add heads
adc edx, 0				; just to add the carry
mul dword [ebx+drive_geometry.sectors_per_track]
pop ecx					; get former ax again
shr cx, 8				; cl=ccssssss
and cl, 00111111b			; cl=00ssssss
dec ecx					; because we add (sectors - 1)
add eax, ecx				; add sectors
adc edx, 0				; add carry of former addition
retn					;
;---------------------------------------;



;								----------------
;									_reg_dev
;===============================================================================
_reg_dev:
;>
;;EDI = pointer to struc partition
;;ESI = device number
;---------------------------------------;
dbg lprint "registering device", DEBUG
pushad					;
mov ebp, edi				;
mov edx, esi				;
mov esi, [current.path]			;
mov ecx, [current.pathlen]		;
add ecx, 13				; 13 digits for '/','/', number and '\0'
push ecx				;
externfunc mem.alloc			; alloc mem for string
pop ecx					;
push edi				; save pointer to beginning of string
sub ecx, 13				; ecx := [current.pathlen]
mov byte[edi], '/'			; prepend '/'
inc edi					;
rep movsb				; copy original path
mov byte [edi], '/'			; attach the '/'
inc edi					; goto next car
externfunc lib.string.dword_to_decimal_no_pad
add edi, ecx				; goto end of string
mov dword [edi], 0			; make the string zero terminated
pop esi					; esi := pointer to device path string
mov eax, dword [ebp+partition.lba_start]
dbg lprint "partition: lba_start: %d", DEBUG, eax
mov ebx, _open				; ebx := pointer to the open function
externfunc devfs.register		; register the device
jc .error
popad					; restore regs
retn	
.error:
dbg lprint "Could not register device!", DEBUG
popad
stc
retn
;
;---------------------------------------;




;                                           -----------------------------------
;                                                                 section .data
;==============================================================================

section .data

current:				; I need these variable because
	.open:		dd 0		; I don't have enough regs...
	.device:	dd 0		; device number
	.path:		dd 0		; ptr to path string of dev file
	.buffer:	dd 0		; ptr to partition buffer
	.pathlen:	dd 0		; length of path string of dev file


single_dev:	db "/single",0

struc partition
	.open:		resd 1		; pointer to open function
	.device:	resd 1		; device number
	.lba_start:	resd 2		; 64bit lba start
	.lba_end:	resd 2		; 64bit lba end
endstruc

struc drive_geometry
    .sectors_per_track:   resd 1
    .heads_per_cylinder:  resd 1
endstruc


