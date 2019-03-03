;====---------------------------------------------------------------------====
; Mini-Archiver cell for Unununium OE                  (c)2001 Richard Fillion
; Driver for easy NVRAM access                   Distributed under BSD Licens
;====---------------------------------------------------------------------====

[bits 32]


section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Mini-Archiver NVRAM cell",0
str_author: db "Richard Fillion (Raptor-32)",0
str_copyright: db "(c) 2001 Richard Fillion",0

;====-------[ INITIALIZATION ]-------=====
section .c_init
;every computer has to have NVRAM, so its not a problem of detecting it,
;we must detect how big it is though, either 64bytes or 128bytes.
 pushad

;register with devfs
 mov ebx, _open
 mov esi, nvram_device
 externfunc devfs.register
 
 mov al, 15  ;we read 15th byte
 mov edx, 0x70  ;port for nvram
 out dx, al
 in al, 0x71
 mov bl, al   ;save byte 15
 mov al, 15 + 64
 mov edx, 0x70
 out dx, al
 in al, 0x71
 cmp al, bl  ;compare byte 15 to (64+15), if they are different, the additional
             ;64bytes is present otherwise it wraps around
 jne .nvram_128bytes
 mov al, 15
 mov edx, 0x70
 out dx, al
 mov al, bl
 inc al
 mov edx, 0x71
 out dx, al
 mov edx, 0x70
 mov al, 64+15
 out dx, al
 in al, 0x71
 dec al
 mov bh, al
;return byte 15 to its original position now
 mov al, 15
 mov edx, 0x70
 out dx, al
 mov al, bl
 mov edx, 0x71
 out dx, al   ;byte 15 returned to original position
 cmp bh, bl  ;check if byte 15 (edited) has changed byte 64+15 if so, wehave 64byte nvram
 je .nvram_64bytes

.nvram_128bytes:
 mov byte [nvram_size], 127  ;we dont want those first 14bytes (RTC ownz them)
 mov esi, str_128bytes
 externfunc sys_log.print_string
 popad
 jmp end
.nvram_64bytes:
 mov byte [nvram_size], 63
 mov esi, str_64bytes
 externfunc sys_log.print_string
 popad
 jmp end

str_64bytes: db "NVRAM detected at 64bytes.",0
str_128bytes: db "NVRAM detected at 128bytes.",0

end:

;====--------[POST INIT]---------=====
section .text

;====--------[ OPEN FILE ]-------====
_open:
  push edx
  mov ecx, local_file_descriptor_size
  externfunc mem.alloc
  mov dword[edi+file_descriptor.op_table], our_op_table
  pop dword[edi+file_descriptor.fs_descriptor]
  xor edx, edx
  mov [edi+local_file_descriptor.pos], edx
  mov ebx, edi
  retn

;====--------[ CLOSE FILE ]-------====
__close:
  mov eax, ebx
  externfunc mem.dealloc
  retn


;====--------[ READ FILE ]-------====
__read:
;ECX = number of bytes to read
;EDI = pointer to buffer to put data in
;EBX = pointer to file descriptor
;returned values
;EDI = unmodified
;errors as usual

 push eax
 push edx
 push edi
 push esi
 xor eax, eax
 movzx esi, word [nvram_size]
.write_byte:
 mov al, byte [ebx + local_file_descriptor.pos]	 ;we know its less then 256
 mov edx, 0x70
 out dx, al
 in al, 0x71
 mov byte [edi], al
 inc edi
 cmp [ebx + local_file_descriptor], esi
 je .done_nvram
 inc byte [ebx + local_file_descriptor.pos]		;add 1 to his position
 loop .write_byte
 pop esi
 pop edi
 pop edx
 pop eax
 retn

.done_nvram:
 mov byte [edi], 0x04			;EOF
 pop esi
 pop edi
 pop edx
 pop eax 
 retn
;====--------[ WRITE FILE ]------====
__write:
;parameters
;ECX = number of bytes to write
;ESI = pointer to buffer to read data from
;EBX = pointer to file descriptor
;returned values
;errors as usual

 push eax
 push edx
 push edi
 push esi
 xor eax, eax
 movzx edi, word [nvram_size]
.write_byte:
 mov al, byte [ebx + local_file_descriptor.pos]	 ;we know its less then 256
 mov edx, 0x70
 out dx, al
 mov al, byte [esi]
 mov edx, 0x71
 out dx, al
 inc esi
 cmp [ebx + local_file_descriptor], edi
 je .done_nvram
 inc byte [ebx + local_file_descriptor.pos]		;add 1 to his position
 loop .write_byte
 pop esi
 pop edi
 pop edx
 pop eax
 retn

.done_nvram:
 pop esi
 pop edi
 pop edx
 pop eax 
 retn




;====--------[ SEEK CURSOR ]-----====
__seek_cur:
; parameters
; EDX:EAX = distance to seek, signed
; EBX = pointer to file handle
  
 push ecx
 test edx, edx ; is it further than 4gigs?
 jnz  .error_too_far
 cmp eax, [nvram_size]
 jae .error_too_far   		;they cant seek right to the end, or begining either.
 mov ecx, [ebx + local_file_descriptor.pos]
 test edx, 0x80000000  ;check sign bit
 jz  .forward
.reverse:
 cmp ecx, eax
 jb .error_too_far
 sub ecx, eax
 jmp .mark_it
.forward:
 add ecx, eax
 cmp ecx, [nvram_size]
 ja .error_too_far
.mark_it:
 mov dword [ebx + local_file_descriptor.pos], ecx
 pop ecx
 clc
 popad
 retn
.error_too_far:
 stc
 pop ecx
 mov eax, __ERROR_INVALID_PARAMETERS__
 retn



;====--------[ SEEK START ]------====
__seek_start:
; parameters
; EDX:EAX = distance to seek, unsigned
; EBX = pointer to file handle
  
 test edx, edx ; is it further than 4gigs?
 jnz  .error_too_far
 cmp eax, [nvram_size]
 ja .error_too_far
 mov dword [ebx + local_file_descriptor.pos], eax
 clc
 retn
.error_too_far:
 stc
 mov eax, __ERROR_INVALID_PARAMETERS__
 retn

;====--------[ SEEK END ]-------====
__seek_end:
; parameters
; EDX:EAX = distance to seek, unsigned
; EBX = pointer to file handle
  
 test edx, edx ; is it further than 4gigs?
 jnz  .error_too_far
 cmp eax, [nvram_size]
 ja .error_too_far
 mov edx, [nvram_size]
 sub edx,eax 
 mov dword [ebx + local_file_descriptor.pos], edx
 xor edx, edx			;return this guy to normal
 clc
 retn
.error_too_far:
 stc
 mov eax, __ERROR_INVALID_PARAMETERS__
 retn


;====-------[ ERROR ]-------====
__error:
 mov eax, __ERROR_OPERATION_NOT_SUPPORTED__
 stc
 retn




;====------[VARIABLES]------======
section .data
align 4
nvram_size: dd 0
nvram_device: db "/nvram",0
seek_cursor: dd 0  ;max is 128bytes, so we only need a byte for that. :)


 
;====-----[STRUCTURES]------=====

struc local_file_descriptor
  .global:      resb file_descriptor_size
  .pos:         resd 1
endstruc

our_file_descriptor: 
istruc local_file_descriptor
   at local_file_descriptor.global
      istruc file_descriptor
        at file_descriptor.op_table,      dd our_op_table
      iend
   at local_file_descriptor.pos, dd 0            ; position in the file
iend

our_op_table: istruc file_op_table
at file_op_table.close,         dd __close
at file_op_table.read,          dd __read
at file_op_table.write,         dd __write
at file_op_table.raw_read,      dd __error
at file_op_table.raw_write,     dd __error
at file_op_table.seek_cur,      dd __seek_cur
at file_op_table.seek_start,    dd __seek_start
at file_op_table.seek_end,      dd __seek_end
at file_op_table.read_fork,     dd __error
at file_op_table.write_fork,    dd __error
at file_op_table.link,          dd __error
at file_op_table.unlink,        dd __error
at file_op_table.create,        dd __error
at file_op_table.rename,        dd __error
at file_op_table.copy,          dd __error
at file_op_table.truncate,      dd __error
at file_op_table.attrib,        dd __error
;at file_op_table.list,          dd __error
iend




;====------[ INCLUDES ]-----====

