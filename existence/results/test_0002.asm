RESULTS:
	Adds about 0x01300000 per round

; This cell allow you to perform some tests.
;
; Each section is documented, if you have any question, make sure to consult
; the documentation section of our website at http://uuu.sourceforge.net/
;
; Have fun!

[bits 32]

section .c_info
  ;------------
  ; This section is used to give the version number, the cell name, author and
  ; copyrights information.  Some distros will parse this information and build
  ; up a database of the currently loaded cells in the system while some other
  ; distros will simply read this information and discard it.

  ; version:
db 1,0,0,'a'
  ;---------
  ; The version is a 4 bytes combination.
  ; offset 0:  high version number
  ;        1:  mid version number
  ;        2:  low version number
  ;        3:  revision indicator

  ; ptr to cell's name
dd str_cellname
  ;------------
  ; This is a pointer to the string that gives the name and sometime a very
  ; short description of the cell.  This string is encoded in UTF-8 and should
  ; really be kept as short as possible since it's the string that will be used
  ; when a list of all the cells is requested.

  ; ptr to author's name
dd str_author
  ;----------
  ; This is a pionter to the string that gives the author's name or the group's
  ; name.  This string is encoded in UTF-8.  Some ppl might want to coma
  ; separate a list of authors when many have contributed to the work.

  ; ptr to copyrights
dd str_copyrights
  ;--------------
  ; This is a pointer to the string containing the copyrights information. This
  ; string, like the others, is encoded in UTF-8.  It is possible but not
  ; recommended to use this string to hold the entire copyrights license.  A
  ; much more desirable option would be to give an Internet URI to the license
  ; with the license name.

str_cellname: db "Test cell - for learning purposes",0
  ;---------------------------------------------------
  ; This string gives the name and a very short description of this cell. It is
  ; encoded in UTF-8, which preserve/uses the standard US-ASCII character set.

str_author: db "EKS - Dave Poirier (futur@mad.scientist.com)",0
  ;------------------------------------------------------------
  ; This string is used to hold a list of authors.  If many authors have
  ; collaborated on the work and desire to be included, it is possible to
  ; include more names by coma separating each entry.  This is also encoded
  ; using UTF-8.

str_copyrights: db "Not copyrighted",0
  ;-----------------------------------
  ; This string hold the copyright notice or copyright license's name.  Some 
  ; people might want to include the entire copyrights license here but it is a
  ; unrecommended behaviour. As suggested earlier, an internet URI to the entire
  ; license would be more recommendable.

section .c_onetime_init
  ;--------------------
  ; This section contain specific initialization instructions that will be
  ; executed once and discarded, the cell being saved back, if possible, with
  ; the modified content.
  clc
  retn

section .c_init
  ;------------
  ; This section contain specific initialization instructions that will be
  ; executed once and discarded every time the cell is loaded in memory.
;  xor edx, edx
;  externfunc tsa.acquire_thread
;  push eax
;  push control_function_2
;  externfunc tsa.set_initial_values
;  externfunc ps.schedule
;  pop eax
;  pop eax
  xor edx, edx
  externfunc tsa.acquire_thread
  push eax
  push control_function_1
  externfunc tsa.set_initial_values
  externfunc ps.schedule
  pop eax
  pop eax
  clc
  retn

section .text
  ;----------
  ; This section '.text' is a special section recognized by most tools as being
  ; a section containing executable code and optionally read-only data.
  ;
  ; The U3Linker and the various cells will treat any name not starting with
  ; a dot exactly the same as a '.text' section.  The difference being that
  ; in our system, a '.text' section may contain not only executable code and
  ; read-only data, but also read-write data.

thread1:
  inc dword [0xB81E0]
  jmp thread1

thread2:
  inc dword [0xB8140]
  jmp thread2

align 64, db 0

test_function_1:
  test ecx, 0x0000000F
  jz .failed
  retn 4
.failed:
  pop eax
  pop eax
  jmp [eax]

align 64, db 0

test_function_2:
  test ecx, 0x0000000F
  jz .failed
  mov ebx, 0
  retn
.failed:
  mov ebx, 1
  retn

align 64, db 0

control_function_1:
  cli
  rdtsc
  push edx
  push eax

  mov ecx, 2000000000
.test_loop:
  push dword .alternates
  call test_function_1
  inc dword [0xB8000]
  loop .test_loop
  jmp .results
.failed:
  inc dword [0xB8010]
  loop .test_loop
.results:
  rdtsc

  pop ebx
  pop ecx

  sub eax, ebx
  sbb edx, ecx
	add [cummulative_1], eax
	adc [cummulative_1 + 4], edx
  mov ebx, edx
  mov edi, 0xB8280
  call display_ebx_at_edi
  add edi, 16
  mov [edi], byte ':'
  mov [edi+1], byte 0x07
  add edi, 2
  mov ebx, eax
  call display_ebx_at_edi
	add edi, 18
  mov [edi], byte '1'
  mov [edi+1], byte 0x0B

  mov eax, [cummulative_1]
  mov edx, [cummulative_1 + 4]
  mov ebx, edx
  mov edi, 0xB81E0
  call display_ebx_at_edi
  add edi, 16
  mov [edi], byte ':'
  mov [edi+1], byte 0x07
  add edi, 2
  mov ebx, eax
  call display_ebx_at_edi
  jmp control_function_2

align 4, db 0
.alternates: dd .failed, 0

align 64, db 0
control_function_2:
  rdtsc
	push edx
	push eax

  mov ecx, 2000000000
.test_loop:
  call test_function_2
  test ebx, ebx
  jnz .failed
  inc dword [0xB8000]
  loop .test_loop
  jmp .results
.failed:
  inc dword [0xB8010]
  loop .test_loop
.results:
  rdtsc

  pop ebx
  pop ecx

  sub eax, ebx
  sbb edx, ecx
  add dword [cummulative_2], eax
	adc dword [cummulative_2 + 4], edx
  mov ebx, edx
  mov edi, 0xB8280
  call display_ebx_at_edi
  add edi, 16
  mov [edi], byte ':'
  mov [edi+1], byte 0x07
  add edi, 2
  mov ebx, eax
  call display_ebx_at_edi
	add edi, 18
  mov [edi], byte '2'
  mov [edi+1], byte 0x0B

	mov eax, [cummulative_2]
  mov edx, [cummulative_2 + 4]
  mov ebx, edx
  mov edi, 0xB8210
  call display_ebx_at_edi
  add edi, 16
  mov [edi], byte ':'
  mov [edi+1], byte 0x07
  add edi, 2
  mov ebx, eax
  call display_ebx_at_edi

  mov eax, [cummulative_1]
  mov edx, [cummulative_1 + 4]
  sub eax, [cummulative_2]
  sbb edx, [cummulative_2 + 4]
  mov ebx, edx
  mov edi, 0xB8240
  call display_ebx_at_edi
  add edi, 16
  mov [edi], byte ':'
  mov [edi+1], byte 0x07
  add edi, 2
  mov ebx, eax
  call display_ebx_at_edi
  jmp control_function_1

display_ebx_at_edi:
  pushad
  mov ecx, 4
  mov esi, hex_digits
  xor edx, edx
.display_reg:
  mov ah, 0x07
  mov dl, bl
  and dl, 0x0F
  mov al, [esi + edx]
  shl eax, 16
  mov ah, 0x07
  mov dl, bl
  shr dl, 4
  mov al, [esi + edx]
  shr ebx, 8
  dec ecx
  mov [ecx*4 + edi], eax
  jnz .display_reg
  popad
  retn

hex_digits: db '0123456789ABCDEF'


cummulative_1:
dd 0,0

cummulative_2:
dd 0,0

