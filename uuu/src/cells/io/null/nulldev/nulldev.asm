;====---------------------------------------------------------------------====
; NULL cell for Unununium OE                  	(c)2001 Lukas Demetz
; Driver for easy NULL device                   Distributed under BSD License
;====---------------------------------------------------------------------====

[bits 32]


section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Null-DEV cell",0
str_author: db "Lukas Demetz (luke)",0
str_copyright: db "(c) 2001 Lukas Demetz",0

;====-------[ INITIALIZATION ]-------=====
section .c_init

 pushad

;register with devfs
 mov ebx, _open
 mov esi, null_device
 externfunc devfs.register
 

 mov esi, str_loaded
 externfunc sys_log.print_string
 popad
 jmp end

str_loaded: db "Null-DEV loaded.",0


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

.write_byte:

 mov byte [edi], 00h
 inc edi
 
 inc byte [ebx + local_file_descriptor.pos]		;add 1 to his position
 loop .write_byte
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

  xor	eax, eax
  clc
  
 retn




;====--------[ SEEK CURSOR ]-----====
__seek_cur:
; parameters
; EDX:EAX = distance to seek, signed
; EBX = pointer to file handle
  

  xor	eax, eax
  clc
  
 
 retn



;====--------[ SEEK START ]------====
__seek_start:
; parameters
; EDX:EAX = distance to seek, unsigned
; EBX = pointer to file handle

  xor	eax, eax
  clc
    
 
 retn

;====--------[ SEEK END ]-------====
__seek_end:
; parameters
; EDX:EAX = distance to seek, unsigned
; EBX = pointer to file handle

  xor	eax, eax
  clc
 
 
 retn


;====-------[ ERROR ]-------====
__error:
 mov eax, __ERROR_OPERATION_NOT_SUPPORTED__
 stc
 retn




;====------[VARIABLES]------======
section .data
align 4

null_device: db "/null",0
seek_cursor: dd 0  


 
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

