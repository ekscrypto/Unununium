section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "libterminal",0
str_author: db "Phil Frost",0
str_copyright: db "Distributed under BSD License",0

;                                           -----------------------------------
;                                                               section .c_init
;==============================================================================
section .c_init
global _start
_start:
  ; We do nothing here
  ; added by Luke
  retn
  
section .text

globalfunc lib.term.cursor_back
;>
;; moves the cursor backward a specified count
;; 
;; parameters:
;; -----------
;; EBX = ptr to file descriptor of terminal to use
;; EBP = ptr to op table of that file
;; EAX = number of spaces to move back
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;<

  test eax, eax
  jz .retn

  push esi
  push ecx

  push dword 0x44005b1b
  mov byte[esp+2], al
  mov esi, esp
  mov ecx, 4
    mov ebp,[ebx+file_descriptor.op_table]
  call [ebp+file_op_table.write]
  pop esi

  pop ecx
  pop esi
.retn:
  retn

globalfunc lib.term.cursor_forward
;>
;; moves the cursor forward a specified count
;; 
;; parameters:
;; -----------
;; EBX = ptr to file descriptor of terminal to use
;; EBP = ptr to op table of that file
;; EAX = number of spaces to move forward
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;<

  test eax, eax
  jz .retn

  push esi
  push ecx

  push dword 0x43005b1b
  mov byte[esp+2], al
  mov esi, esp
  mov ecx, 4
    mov ebp,[ebx+file_descriptor.op_table]

  call [ebp+file_op_table.write]
  pop esi

  pop ecx
  pop esi
.retn:
  retn
