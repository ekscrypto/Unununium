section .c_info

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Environment Lib",0
str_author: db "Phil Frost",0
str_copyright: db "Distributed under BSD License",0

section .text
;                                           -----------------------------------
;                                                                   lib.env.set
;==============================================================================

globalfunc lib.env.set
;>
;; Sets an environment variable. If the var exists, it will be updated, if not,
;; it will be added. The value to set (in ESI) should be allocated with
;; mem.alloc. If the string changes, so will the environment; this function
;; simply inserts a pointer to what you specify in ESI in the environment.
;;
;; parameters:
;; -----------
;; EDX = ptr to environment array
;; ESI = ptr to "var=value" string; single null terminated
;;
;; returned values:
;; ----------------
;; EDX = ptr to environment array (may change because memory needs to be
;;   resized)
;; registers and errors as usual
;<

  push ecx

  xor ecx, ecx
  dec ecx
.find_length:
  inc ecx
  cmp byte[esi+ecx], 0
  jz .bad_form
  cmp byte[esi+ecx], '='
  jnz .find_length

  call lib.env.get
  jnc .exists

  dbg_print "variable does not yet exist; adding",0
  push eax
  push edi
  lea ecx, [eax+8]	; ECX = size of env array + 4
  mov eax, edx
  externfunc mem.realloc
  mov edx, edi
  pop edi
  pop eax
  mov [edx+eax], esi
  mov dword[edx+eax+4], 0

  pop ecx
  clc
  retn

.exists:
  dbg_print "variable already exists; replacing",0
  ; the varible already exists; replace the old value
  xchg [edx+eax], esi
  mov eax, esi
  externfunc mem.dealloc	; dealloc the old one
  pop ecx
  clc
  retn

.bad_form:
  mov eax, __ERROR_INVALID_PARAMETERS__
  pop edi
  pop ecx
  stc
  retn

;                                           -----------------------------------
;                                                                   lib.env.get
;==============================================================================

globalfunc lib.env.get
;>
;; Gets an environment variable. The value returned in EDX is a pointer
;; to the pointer that points to the value. So, it's possible to simply
;; get the value by doing "mov edx, [edx]" after the call has returned, or
;; the value can be changed "mov [edx], ptr_to_new_value".
;;
;; parameters:
;; -----------
;; ESI = ptr to string of value to get; no termination required. There should
;;         be no "...=value" in the string.
;; ECX = length of that string
;; EDX = ptr to environment
;;
;; returned values:
;; ----------------
;; CF = set iff variable is not found
;;
;; EAX = offset within the environment array to the ptr to ptr to "var=value"
;;   string, or ptr to the null pointer on the end if the variable is not
;;   found. In other words, do this:
;;   
;;     externfunc lib.env.get
;;     mov esi, [edx+eax]	; ESI now points to "var=value",0 string
;;     lea esi, [esi+ecx+1]	; ESI now points to "value",0
;;     
;; registers as usual
;<

  xor eax, eax
  push edi
  push esi
  push ecx
  sub eax, byte 4

.search:
  add eax, byte 4
  mov edi, [edx+eax]
  test edi, edi
  jz .not_found
  
  %ifdef _DEBUG_
  dbg_print_hex ecx
  dbg_print " comparing:",0
  push esi
  externfunc sys_log.print_string
  mov esi, edi
  externfunc sys_log.print_string
  pop esi
  %endif

  repz cmpsb
  mov esi, [esp+4]	; restore ESI and ECX
  mov ecx, [esp]
  jne .search

  ; might have found a match; check that we are at the end
  cmp byte[edi], '='
  jne .search

  ; found it
  ; CF clear from cmp above
  pop ecx
  pop esi
  pop edi
  clc
  retn

.not_found:
  dbg_print "varible not found",0
  pop ecx
  pop esi
  pop edi
  stc
  retn
