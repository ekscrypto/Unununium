[org 0x7C00]
[bits 16]



; little useful debugging macro
%macro dme 1.nolist
  mov edx, %{1}
  jmp __dword_out
%endmacro


struc mboot
   .magic		resd 1
   .flags		resd 1
   .checksum		resd 1
   .header_addr		resd 1
   .load_addr		resd 1
   .load_end_addr	resd 1
   .bss_end_addr	resd 1
   .entry_addr		resd 1
endstruc



boot_record_entry_point:

  ; note, bios transfer control with DL = drive number, but since we are
  ; elite we won't need to touch it before we actually read the damned disk

  cli				; these two instructions are required for some
  jmp short stupid_bios		; stupid bioses that check even the validity
  				; of the first 2 instructions, god I hate those
wait_kbd_command:
  in AL, 64h
  test al, 0x01
  jc wait_kbd_command
  retn

stupid_bios:			; from here should be OUR code..

  xor ax, ax			; clear out ax
  mov ds, ax			; set ds = 0000
  mov es, ax			; set es = 0000
  mov ss, ax			; set ss = 0000
  mov sp, 0x7C00		; set stack to 0000:07C00

  mov al, 0x02			; enable A20 bit of PS/2 control register
  out 0x92, al			; flag the bit, should enable the A20 gate
  call wait_kbd_command		; wait for 8042 to be ready
  mov al, 0xD1			; equivalent for older systems
  out 0x64, al			; this time send it to the keyboard controller
  call wait_kbd_command		; wait for 8042 to be ready
  mov al, 0x03			; A20 enabled, reset line high
  out 0x60, al			; send to keyboard controller
  mov al, 10111110b		; set irq mask, only irq 6 and 0 enabled
  out 0x21, al			; send it to master pic
  mov al, 11111111b		; set irq mask, all disabled
  out 0xA1, al			; send it to slave pic

  ; in case you wonder, some guy at IBM I believe though it was a good idea to
  ; actually use the keyboard controller to control the A20 gate.  There is
  ; a hard wired line on your little mobo that goes from it to memory bus

  ; remember that DL = drive ? well, we use it here ;)
  push dx			; backup drive id, we will need it later
  mov ah, 0x08			; get drive geometry bios call
  xor di, di			; es:di must equal 0, some dumb bios bug
  int 0x13			; call bios disk service
  and cl, byte 0x3F		; mask 2 high cylinder bits
  mov ch, dh			; do one mov instruction instead of 2..
  mov [sector_count], cx	; we overflow, but the data is unitialized
  pop dx			; restore the drive id
  mov [drive_id], dl		; keep it also for later use

  ; read next sector, stage 2 of boot loader + ext2 super block
  push byte 0
  pop es
.retrying:
  push dx
  mov cx, 0x0002		; starting on sector 2
  mov dh, 0			; starting on head 0
  mov ax, 0x0203		; read, 3 sectors (1 stage2, 2 super block)
  mov bx, 0x7E00		; offset to place data at, just after us
  int 0x13			; read it
  pop dx
  jnc short .stage2_read	; successful, nice

  mov ah, 0x00			; reset drive controller function
  push dx
  int 0x13			; do it
  pop dx
  jmp short .retrying		; retry

.stage2_read:
  cli
  o32 lgdt [__gdt]		; load GDTR with a pointer/size of our GDT
  mov eax, cr0			; read control register 0
  inc ax			; set pmode enable bit to 1
  mov cr0, eax			; enable pmode
  jmp dword 0x0008:.pmode_entry	; clear prefetch queue


[bits 32]
.pmode_entry:
  push byte 0x10
  pop eax
  mov ds, eax			; set ds = index 2
  mov es, eax			; set es = index 2
  mov edi, 0x8000		; set pointer to super block in memory
  
  ; we save a call by doing this directly :)
  ; EDI = pointer to superblock buffer
  ;---
  ; first, make sure we got ext2fs signature
  cmp [edi + ext2_super_block.s_magic], word 0xEF53
  jz short .proceed_ext2_calc

  ; display "fs" on the lower right hand side of the screen
  mov [0xB8000 + (0xA0*25) - 4], dword 0x04730466
  jmp short $

.proceed_ext2_calc:
  ; computing fragment size
  mov ecx, [edi + ext2_super_block.s_log_frag_size]
  mov edx, 1024			; fragment size are 1024<<log or 1024>>log
  mov ebx, edx			;  depending on ecx being negative or positive
  or ecx, ecx			; check ecx sign
  js short .switch_frag_size_right	; if signed, go do 1024>>log
  shl edx, cl			; shift left 1024<<cl
  jmp short .store_frag_size	; frag size computed, go store it
.switch_frag_size_right:	; gotta do 1024>>cl
  neg ecx			; first, make it back to positive value
  shr edx, cl			; shift it right 1024>>cl
  neg ecx			; set ecx back to its value
.store_frag_size:

  mov [super_block.s_frag_size], edx	; here we store final frag size
  mov eax, ecx			; copy log2fragsize into eax

  ; computing block size
  mov ecx, [edi + ext2_super_block.s_log_block_size]	; load log2blocksize
  shl ebx, cl			; shift 1024<<cl
  push ebx
  shr ebx, 9
  mov [super_block.s_sectors_per_block], ebx
  pop ebx
  
  ; computing number of fragments per block
  sub ecx, eax			; make sure fragments are smaller than blocks
  mov edx, 1			; now find how many frags fill a block
  shl edx, cl			; compute our little value
  mov [super_block.s_frags_per_block], edx	; and store it there
  
  ; determining inodes per block
  cmp dword [edi + ext2_super_block.s_rev_level], byte EXT2_GOOD_OLD_REV
  mov ecx, EXT2_GOOD_OLD_INODE_SIZE
  jz short .compute_inodes_per_block
  mov ecx, [edi + ext2_super_block.s_inode_size]
.compute_inodes_per_block:
  mov eax, ebx			; set eax = block size
  xor edx, edx			; clear out edx
  div ecx			; blocksize / inodesize
    
.store_inodes_per_block:
  mov [super_block.s_inodes_per_block], eax	; inodes/block, store it
  mov [super_block.s_inode_size], ecx		; also store inode size

  ; compute value of s_desc_per_block
  xchg eax, ebx					; switch those, will be easier
  mov ecx, eax					; set ecx= blocksize
  shr eax, 5		; divide block_size by ext2_group_desc_size
  mov [super_block.s_desc_per_block], eax	; save the result
  lea eax, [eax*8]				; eax = blocksize>>2
  bsr eax, eax					; find log2 of eax
  bsr ecx, ecx					; find log2 of ecx
  mov [super_block.s_desc_per_block_bits], eax	; store results..
  mov [super_block.s_addr_per_block_bits], ecx

  ; copy inodes|frags|blocks per group values
  mov eax, [edi + ext2_super_block.s_blocks_per_group]
  mov ecx, [edi + ext2_super_block.s_frags_per_group]
  mov [super_block.s_blocks_per_group], eax
  mov [super_block.s_frags_per_group], ecx
  mov eax, [edi + ext2_super_block.s_inodes_per_group]
  mov [super_block.s_inodes_per_group], eax
  
  ; compute number of inode table blocks per group
  ; EAX = inodes_per_group, EDX = 0 (should be)
  div ebx			; inodes_per_group/inodes_per_block
  mov [super_block.s_itb_per_group], eax

  ; compute s_groups_count
  ;
  ; s_group_count = ( block_count - first_data_block + blocks_per_group - 1)
  ;                 --------------------------------------------------------
  ;                                    blocks_per_group
  ;
  mov eax, dword [edi + ext2_super_block.s_blocks_count]
  sub eax, dword [edi + ext2_super_block.s_first_data_block]
  dec eax
  mov ebx, dword [super_block.s_blocks_per_group]
  add eax, ebx
  div ebx
  mov [super_block.s_groups_count], eax

  ; compute gdb_count
  ; gdb_count =   groups_count + desc_per_block - 1
  ;               ---------------------------------
  ;                      desc_per_block
  ;
  mov ecx, dword [super_block.s_desc_per_block]
  lea eax, [byte eax + ecx - 1]
  xor edx, edx
  div ecx
  mov [super_block.s_gdb_count], eax

  mov [super_block.s_sbh], edi		; store pointer to fs superblock

  ; Read group descriptors to memory
  mul dword [super_block.s_sectors_per_block]	; * sectors per block
  ; eax = number of sectors to read
  push byte 0x04			; value to set in edx, lba to read
  pop edx				; set edx = 4
  mov edi, 0x8200			; set destination location
  push edi				; back it up for later reference
  call __read_sectors			; read the sectors
  pop esi				; restore pointer to loaded sectors
  mov [inode_table], edi		; use returned pointer for inodes
  
  mov eax, [esi + ext2_group_desc.bg_inode_table]
  mov ebx, [super_block.s_sectors_per_block]
  push ebx				; backup sectors_per_block
  mul ebx				; compute lba of inode table
  mov edx, eax				; set edx = lba of inode table
  push edx
  mov eax, ebx				; set eax = number of sectors to read
  mul dword [super_block.s_itb_per_group]
  pop edx
  push edi				; backup ptr for later reference
  call __read_sectors			; read the sectors
  pop esi				; restore pointer to loaded sectors
  mov [root_dir_entry], edi		; use returned pointer for root dir

  ; Locate root directory entry and prepare for directory blocks transfer
  add esi, ((EXT2_ROOT_INO-1)*ext2_inode_size)

  ; make sure entry is really the root dir, simple confirmation
  mov cl, [esi + 1]			; load high part of file mode
  and cl, 0xF0				; mask unimportant bits
  cmp cl, 0x40				; make sure it is a directory entry
  jnz short .invalid_root_node

  mov ecx, [esi + ext2_inode.i_blocks]	; set ecx = number of blocks to load
  pop eax				; set eax = sectors_per_block
  push dword __shell_query		; set return address
  jmp short __read_n_blocks		; go to routine

.invalid_root_node:
  mov [0xB8000+(0xA0*25)-4], dword 0x844E8452	; displays RN in red, top left
  jmp short $				; stop execution



align 4, db 0
; A bit of explanation for what you'll find below.  The GDT actually require
; to have a NULL descriptor.  Intel also says that this null descriptor in
; the GDT can contain any kind of data, since it will never be read/checked.
; We are taking advantage of that to actually fit some bytes in it
;
__gdt:
  dw (.end - .start) + 7		; part of GDTR, size of the GDT
  dd __gdt.start - 8			; part of GDTR, pointer to GDT
.start:
  dd 0x0000FFFF, 0x00CF9B00		; pmode CS, 4GB r/x, linear=physical
  dd 0x0000FFFF, 0x00CF9300		; pmode DS, 4GB r/w, linear=physical
  dd 0x0000FFFF, 0x00009B00		; rmode CS, 64KB r/w, linear=physical
  dd 0x0000FFFF, 0x00009300		; rmode DS, 64KB r/w, linear=physical
.end:


  times 510-($-$$) db '_'		; padding, if we are real elite, this
  					; should be 0 ;)

  db 0x55, 0xAA				; boot signature




;------------------------------------------------------------------------------
; /\ stage 1                                                         stage 2 \/
;------------------------------------------------------------------------------




__read_n_blocks:
  ; esi = pointer to inode entry
  ; eax = sectors_per_block
  ; ecx = number of blocks to load
  ; edi = destination to use
  mov ebx, 12
  mov [file_inode], esi
  add esi, byte ext2_inode.i_block
  xor ebp, ebp
  mov [indx_block], ebp
  mov [bindx_block], ebp
.loading_blocks:
  cmp dword [esi], byte 0
  jz short .abort
  push ebx
  push ecx
  push eax
  push eax
  mul dword [esi]
  mov edx, eax
  pop eax
  push esi
  push edi
  mov edi, 0x800
  push edi
  push eax
  call __read_sectors
  pop ecx
  pop esi
  pop edi
  shl ecx, 7
  rep movsd
  pop esi
  pop eax
  pop ecx
  pop ebx
  add esi, byte 4
  loop .check_indirects
.abort:
  retn
.check_indirects:
  dec ebx
  jnz short .loading_blocks
  mov ebp, [indx_block]
  or ebp, ebp
  jnz short .bindx_blocks
    pushad
    push eax
    mul dword [esi]
    mov edx, eax
    pop eax
    mov edi, [last_offset]
    mov [esp + 4], edi
    push eax
    call __read_sectors
    pop eax
    shl eax, 7
    mov [esp + 16], eax
    popad
    jmp short .loading_blocks
.bindx_blocks:
  mov [0xB8000 + (0xA0*25)-4], dword 0x84008400 + ('+'<<16) + '+'
  jmp short $



__read_sectors:
  ; EAX = number of sectors to load
  ; EDX = LBA of first sector
  ; EDI = pointer to destination address
.read_next:
  push eax
  push edx
  mov eax, edx
  xor edx, edx
  movzx ebx, byte [sector_count]
  div ebx
  inc edx
  mov [.sector_value], dl
  xor edx, edx
  movzx ebx, byte [head_count]
  inc ebx
  div ebx
  mov [.head_value], dl
  mov [.cyl_value], al
  ; note, if the two high bits of cylinder number are set, we are screwed
  push edi
  shr edi, 4
  jmp 0x0018:.pmode16

[bits 16]
.pmode16:
  mov ax, 0x20
  mov ds, ax
  mov es, ax
  mov eax, cr0
  dec eax
  mov cr0, eax
  jmp 0:.realmode

.realmode:
  mov es, di
  xor di, di
.retrying:
  mov ax, 0x0201		; always read 1 sector at a time
  xor bx, bx
  mov cx, 0x0001
    .sector_value equ $-2
    .cyl_value equ $-1
  mov dh, 0x00
    .head_value equ $-1
  mov dl, [drive_id]
  push dx
  push di
  int 0x13
  pop di
  pop dx
  jnc .sector_read

  inc di
  cmp di, byte 10
  jb short .reset_drive

    push word 0xB800
    pop es
    xor di, di
    mov word [di], 0x8430
    jmp short $

.reset_drive:
  mov ah, 0x00
  push di
  int 0x13
  pop di
  jmp short .retrying

.sector_read:
  mov eax, cr0
  inc ax
  mov cr0, eax
  jmp dword 0x0008:.pmode_reentry

[bits 32]
.pmode_reentry:
  push byte 0x10
  pop eax
  mov ds, eax
  mov es, eax
  pop edi
  pop edx
  pop eax
  add edi, 0x200
  inc edx
  dec eax
  jnz near .read_next
  retn


__shell_query:
  mov [last_offset], edi
  ; alright, eventually we could really prompt for filename here, we "could"

__search_filename:
  mov edi, [root_dir_entry]
  mov esi, filename
  push byte filename.size
  pop ecx
.compare_filename:
  cmp [edi + ext2_dir_entry.name_len], cl
  jnz short .compare_next_file

  push edi
  push esi
  push ecx
  add edi, byte ext2_dir_entry.name
  repz cmpsb
  jz short .file_found
  pop ecx
  pop esi
  pop edi

.compare_next_file:
  movzx eax, word [edi + ext2_dir_entry.rec_len]
  add edi, eax
  cmp dword [edi], byte 0
  jnz .compare_filename

    mov [0xB8000+(0xA0*25)-4], dword 0x84468442
    jmp short $

.file_found:
  pop ecx
  pop esi
  pop edi
  cmp byte [edi + ext2_dir_entry.file_type], byte EXT2_FT_REG_FILE
  jz short .load_regular_file

.wrong_file_type:
    mov [0xB8000], dword 0x84748446
    jmp short $

.load_regular_file:
  mov eax, [edi]	; inode number
  mov ebx, ext2_inode_size
  dec eax
  mul ebx
  mov esi, [inode_table]
  add esi, eax
  mov cl, [esi+1]
  and cl, 0xF0
  cmp cl, 0x80
  jnz short .wrong_file_type
  mov ecx, [esi + ext2_inode.i_blocks]
  mov edi, 0x100000
  mov eax, [super_block.s_sectors_per_block]
  call __read_n_blocks
  
; Search for multiboot header
  mov esi, 0x00100000
  mov eax, 0x1badb002
  xor ecx, ecx
.searching_mboot_header:
  cmp [ecx*4+esi], eax
  jz short .header_found
  inc ecx
  cmp ecx, 1024
  jb short .searching_mboot_header

.mboot_failed:
    mov [0xB8000+(0xA0*25)-4], dword 0x8442844D
    jmp short $

.header_found:
  add eax, dword [ecx*4+esi+mboot.flags]
  add eax, dword [ecx*4+esi+mboot.checksum]
  jnz short .mboot_failed

  ; multiboot header checksum confirmed
  ; let's just for now pass on control directly
  push ds
  pop ss
  jmp [ecx*4+esi+mboot.entry_addr]

filename: db "u3core.bin"
.size equ $-filename

  times 1024-($-$$) db '_'


[absolute 0x600]

; note, due to some space/instruction optimization, I strongly suggest you
; keep those 2 vars together ;)
sector_count: resb 1		; sectors per head count
head_count: resb 1		; numbers of head
drive_id: resb 1
resb 1

inode_table: resd 1
root_dir_entry: resd 1
file_inode: resd 1
indx_block: resd 1
bindx_block: resd 1
last_offset: resd 1


; Define some useful macro, will help for clarity
;------------------------------------------------
  %macro ldb 1.nolist
    .%{1}: resb 1
  %endmacro

  %macro ldw 1.nolist
    .%{1}: resw 1
  %endmacro

  %macro ldd 1.nolist
    .%{1}: resd 1
  %endmacro

  %macro ldd 2.nolist
    .%{1}: resd %{2}
  %endmacro



; Ext2FS Information block, computed by our code (see _calc_sb_info)
;-------------------------------------------------------------------
super_block:
  ldd s_frag_size		; size of fragment in bytes
  ldd s_sectors_per_block	; number of 512 bytes sectors in a block
  ldd s_frags_per_block		; number of fragments per block
  ldd s_inodes_per_block	; number of inodes per block
  ldd s_frags_per_group		; number of fragments in a group
  ldd s_blocks_per_group	; number of blocks in a group
  ldd s_inodes_per_group	; number of inodes per group
  ldd s_itb_per_group		; number of inode table blocks per group
  ldd s_gdb_count		; number of group descriptor blocks
  ldd s_desc_per_block		; number of group descriptors per block
  ldd s_groups_count		; number of groups in the fs
  ldd s_sbh			; pointer to buffer holding superblock
;  ldd s_group_desc		; pointer to buffer holding group descriptors
  ldb s_mount_state		; status of mounted file system
  ldb padding
;  ldb s_loaded_inode_bitmaps	; number of inode bitmaps loaded
;  ldb s_loaded_block_bitmaps	; number of block bitmaps loaded
;  
;  ; inode bitmap numbers of inode bitmaps in buf
;  ldd s_inode_bitmap_number, EXT2_MAX_GROUP_LOADED
;  
;  ; pointer to buffer holding inode bitmap
;  ldd s_inode_bitmap, EXT2_MAX_GROUP_LOADED
;  
;  ; block bitmap numbers of block bitmaps in buf
;  ldd s_block_bitmap_number, EXT2_MAX_GROUP_LOADED
;  
;  ; pointer to buffer holding block bitmap
;  ldd s_block_bitmap, EXT2_MAX_GROUP_LOADED
;  
  ldd s_mount_opt		; mount options
  ldd s_resuid			; user id of reserved block
  ldd s_resgid			; group id of reserved block
  ldd s_addr_per_block_bits	; log2(block_size)
  ldd s_desc_per_block_bits	; log2(block_size/ext2_block_descriptor_size)
  ldd s_inode_size		; size of inode structure
  ldd s_first_ino		; block number of first inode
.size equ $-super_block
