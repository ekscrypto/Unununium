; UTF-8 and UCS-4 String Routines
; Copyright (C) 2002, Dave Poirier & Davison Avery
; Distributed under the X11 License
;
; UTF-8 and UCS-4 string routines

section .c_init
global _start
_start:
    ;; no initialisation required
    ;; do nothing
retn

section .c_info
db 0,0,1,'a'
dd str_cellname
dd str_author
dd str_copyrights
str_cellname:	dd "common UCS4 & UFT8 string functions"
str_author:	dd 'Dave Poirier',0x0A,'Davison Avery'
str_copyrights:	dd 'Copyright 2002 by Dave Poirier & Davison Avery; distributed under the X11 license'



section .text
globalfunc utf8.strlen
;utf8.strlen:
;-----------------------------------------------------------------------------
; Return number of characters in UTF-8 string, excluding terminating Nil. 
; The routine will raise the carry flag if the string is not a valid UTF-8 
; string.
;
; This routine is dependant on utf8.decode_ucs4.from_utf8
;
; parameters:
;------------
; 	ESI = pointer to UTF-8 string
; 
; returns:
;---------
;	EAX = string length (including 0 length) 
;		CF = 0, valid UTF-8 string
;	EAX = 0
;		CF = 0, string is 0 length
;	EAX = destroyed
;		CF = 1, invalid UTF-8 (sub)string

  push esi 				; save register that will be modified
  push ecx
  mov ecx, -1 				; initialize counter

.stringcount:
  inc ecx
  call utf8.decode_ucs4.from_utf8
  jc .done				; carry flag has been set
  test eax, eax 			; have we reached Nil? 
  jnz .stringcount
  
.done:
  mov eax, ecx
  pop ecx
  pop esi
  retn

;-----------------------------------------------------------------------------



globalfunc utf8.strsize 
;utf8.strsize:
;-----------------------------------------------------------------------------
; Returns size in bytes of UTF-8 encoded string up until terminating Nil 
; character. 
; 
; parameters:
;------------
;	ESI = pointer to UTF-8 encoded string
;
; returns:
;---------
;	EAX = size of string in bytes
;

  push esi		; save registers to be modified
  push ecx		

  xor ecx, ecx		; zero byte counter

.stringsize:
  mov al, [esi]
  inc ecx		; increment character counter
  inc esi		; move to next char to compare 
  test al, al		; test for Nil terminator
  jnz .stringsize

.done:
  lea eax, [ecx - 1]	; move result into eax
  pop ecx		; restore ecx
  pop esi		; restore esi
  retn

;-----------------------------------------------------------------------------



globalfunc utf8.strncmp
;utf8.strncmp:
;-----------------------------------------------------------------------------
; Compares two UTF-8 encoded strings for first n characters, or up until
; the Nil terminaters - whichever is reached first 
;
; parameters:
;------------
;	ESI = UTF-8 encoded string1 
; 	EDI = UTF-8 encoded string2
; 	ECX = number of characters to compare from beginning of two strings
;
; returns:
;---------
; 	EAX = 0, CF = 0, strings are equal
; 	EAX = 1, CF = 0, strings are not equal
;	CF = 1, one or more strings are invalid

  pushad			; save registers

.strcmp:
  xor eax, eax			; clear eax 
  dec ecx			; decrement character counter
  jz .finished			;
  call utf8.decode_ucs4.from_utf8
  jc .invalid
  mov ebx, eax			; save string1 UCS4 char
  mov ebp, esi			; save incremented esi pointer for string1
  mov esi, edi			; setup utf8.decode_ucs4.from_utf8 for string2
  call utf8.decode_ucs4.from_utf8
  jc .invalid
  cmp eax, ebx			; are the two chars equal?
  jnz .finished			; no not equal - zero flag set
  mov edi, esi			; setup incremented string2 pointer to edi
  mov esi, ebp			; setup incremented string1 pointer to esi
  test eax, ebx			; have we reached terminating Nils before count is up?
  jnz .strcmp 

.finished:
  clc				; clear the carry flag
.invalid:			; carry flag already raised	
  mov [esp + 28], eax
  popad 
  retn

;-----------------------------------------------------------------------------



globalfunc utf8.strcmp
;utf8.strcmp:
;-----------------------------------------------------------------------------
; Determines if two UTF-8 encoded strings are equivalent.
; 
; parameters:
;------------
;	ESI = UTF-8 encoded string1 
; 	EDI = UTF-8 encoded string2
;
; returns:
;---------
; 	EAX = 0, CF = 0, strings are equal
; 	EAX = 1, CF = 0, strings are not equal
;	CF = 1, one or more strings are invalid
;
;;; use strncmp with exc=7fffffff

  mov ecx, 0x7fffffff
  call utf8.strncmp
  retn

;-----------------------------------------------------------------------------



globalfunc utf8.strstr
;utf8.strstr:
;-----------------------------------------------------------------------------
; Locate first occurance of a substring in a UTF-8 encoded string.
; 
; ** Still needs to be coded **

;-----------------------------------------------------------------------------
; Universal Multiple-Octet Coded Character Set (UCS) Routines
; Copyright (C) 2002, Dave Poirier
; Distributed under the X11 License
;
; Compliant with ISO/IEC 2022, 4873 and 10646
; See http://www.cl.cam.ac.uk/~mgk25/ucs/ISO-10646-UTF-8.html
;
; If you have any comment/question about this code, feel free to write to
; me at instinc@users.sf.net 



globalfunc utf8.decode_ucs4.from_utf8
;utf8.decode_ucs4.from_utf8:
;-----------------------------------------------------------------------------
; Retrieve a UCS-4 character from a UTF-8 encoded string and move the string
; pointer fowards accordingly.
;
; UCS-4 encoded in UTF-8 can be from 1 to 6 bytes in length. The first byte
; indicates how many bytes are required in order to reconstruct the entire
; character.
;
; This function also checks for the validity of the UTF-8 data being retrieved.
; In the event that the string would be out of sync or simply invalid, it would
; raise the Carry Flag and return ESI identical to when it was received.  When
; the character is decoded from a valid UTF-8 string, the Carry Flag is cleared,
; the UCS-4 placed in EAX and ESI moved foward past the end of the now decoded
; character.
;
; parameters:
;------------
;   esi: pointer to utf8 string
;
; returns:
;---------
;   CF = 0, valid character found
;      EAX = UCS
;   CF = 1, invalid character detected
;      EAX = destroyed
;      note: ESI is left unmodified
;
; Determine The Encoding Length
;---------------------------------------------
  mov eax, [esi]		; tentatively load 4 bytes
  test al, byte 0x80		; bit 7 of 1st byte = 0?
  jz short .case_1byte		; 0xxxxxxx ->> range 00-7F
  test al, byte 0x40		; bit 6 of 1st byte = 0?
  jz short .case_invalid	; 10xxxxxx .. out of sync!
  push ebx			; backup EBX, it will be used
  test al, byte 0x20		; bit 5 of 1st byte = 0?
  jz short .case_2bytes		; 110xxxxx ->> range 80-7FF
  push ecx			; backup ECX, it will be used
  test al, byte 0x10		; bit 4 of 1st byte = 0?
  jz short .case_3bytes		; 1110xxxx ->> range 800-FFFF
  push edx			; backup EDX, it will be used
  test al, byte 0x08		; bit 3 of 1st byte = 0?
  jz near .case_4bytes		; 11110xxx ->> range 10000-1FFFFF
  test al, byte 0x04		; bit 2 of 1st byte = 0?
  jz near .case_5bytes		; 111110xx ->> range 200000-3FFFFFF
  test al, byte 0x02		; bit 1 of 1st byte = 0?
  jz near .case_6bytes		; 1111110x ->> range 4000000-7FFFFFFF
				;
				; 1111111x invalid..
				;
.case_invalid_pop3:		;
  pop edx			; restore EDX
.case_invalid_pop2:		;
  pop ecx			; restore ECX
.case_invalid_pop1:		;
  pop ebx			; restore EBX
				;
.case_invalid:			;
  stc				; set CF = 1 to indicate invalid input
  retn				; return to caler with error
				;
				;
.case_1byte:			; Encoded In a Single Byte
				;---------------------------------------------
  and eax, byte 0x7F		; set CF to 0, zeroize extra bytes read
  inc esi			; doesn't affect CF
  retn				; return 00-7F range UCS-4
				;
.case_2bytes:			; Encoded In 2 Bytes
				;---------------------------------------------
  mov ebx, eax			; move 1st byte in bl
  mov al, ah			; move 2nd byte in al
  and ah, byte 0xC0		; keep highest 2bits of 2nd byte
  cmp ah, byte 0x80		; check to make sure they are 10
  jnz short .case_invalid_pop1	;
  shl ebx, byte 6		; shift 1st byte by 6bit at the right position
  and eax, byte 0x3F		; keep only the meaningful bit of 2nd byte
  inc esi			; move string pointer foward once (1st byte)
  or eax, ebx			; or 2nd and 1st byte
  inc esi			; move string pointer foward once (2nd byte)
  and eax, dword 0x7FF		; set CF to 0, zeroize extra bytes read
  pop ebx			; restore EBX
  retn				; return 80-7FF range UCS-4
				;
.case_3bytes:			; Encoded In 3 Bytes
				;---------------------------------------------
  mov ebx, eax			; move 3rd byte in EBX(23:16)
  and eax, dword 0x00C0C000	; keep 2highest bits of 2nd and 3rd byte
  mov ecx, ebx			; move 2nd byte in ECX(15:8)
  cmp eax, dword 0x00808000	; make sure they are 10xxxxxx
  mov eax, ecx			; move 1st byte in EAX(7:0)
  jnz short .case_invalid_pop2	;
  shr ebx, byte 16		; shift 3rd byte in final position
  and eax, byte 0x0F		; keep low 4bits of 1st byte
  shr ecx, byte 2		; shift 2nd byte in final position
  and ebx, byte  0x0000003F	; keep low 6bits of 3rd byte
  shl eax, 12			; shift 1st byte in final position
  and ecx, dword 0x00000FC0	; keep low 6bits of 2nd byte
  or eax, ebx			; merge 1st and 3rd bytes
  inc esi			; move string pointer foward once (1st byte)
  or eax, ecx			; merge in 2nd byte, clear CF
  inc esi			; move string pointer foward once (2nd byte)
  pop ecx			; restore ECX
  inc esi			; move string pointer foward once (3rd byte)
  pop ebx			; restore EBX
  retn				; return 800-FFFF range UCS-4
				;
.case_4bytes:			; Encoded In 4 Bytes
				;---------------------------------------------
  mov ebx, eax			; move 4th byte in EBX(31:24)
  and eax, dword 0xC0C0C000	; keep highest 2bits of 2nd,3rd and 4th bytes
  mov ecx, ebx			; move 3rd byte in ECX(23:16)
  cmp eax, dword 0x80808000	; make sure the pairs of bits are all 10
  mov edx, ebx			; move 2nd byte in EDX(15:8)
  jnz short .case_invalid_pop3	;
  xor edx, eax			; keep lowest 6bits of 4th byte
  shr ecx, byte 10		; shift 3rd byte into position
  mov eax, ebx			; move 1st byte in EAX(7:0)
  shr edx, byte 24		; shift 4th byte into position
  and eax, byte 0x07		; keep lowest 3bits of 1st byte
  shl ebx, byte 4		; shift 2nd byte into position
  and ecx, dword 0x00000FC0	; keep lowest 6bits of 3rd byte
  shl eax, byte 18		; shift 1st byte into position
  and ebx, dword 0x0003F000	; keep lowest 6bits of 2nd byte
  or ecx, edx			; merge in 3rd and 4th bytes
  or eax, ebx			; merge in 1st and 2nd bytes
  add esi, byte 4		; move string pointer foward 4 bytes
  or eax, ecx			; merge in all 4bytes
  pop edx			; restore EDX
  pop ecx			; restore ECX
  pop ebx			; restore EBX
  retn				; return 10000-1FFFFF range UCS-4
				;
.case_5bytes:			; Encoded In 5 Bytes
				;---------------------------------------------
  mov ebx, eax			; move 4th byte in EBX(31:24)
  and eax, dword 0xC0C0C000	; keep highest 2bits of 2nd,3rd and 4th bytes
  mov ecx, ebx			; move 3rd byte in ECX(23:16)
  cmp eax, dword 0x80808000	; make sure the pairs of bits are all 10
  mov edx, ebx			; move 2nd byte in EDX(15:8)
.case_invalid_relay3:		;
  jnz near .case_invalid_pop3	;
  xor edx, eax			; keep lowest 6bits of 4th byte
  shr ecx, byte 10		; shift 3rd byte into temporary position
  mov eax, ebx			; move 1st byte in EAX(7:0)
  shr edx, byte 24		; shift 4th byte into temporary position
  and eax, byte 0x03		; keep lowest 2bits of 1st byte
  shl ebx, byte 4		; shift 2nd byte into temporary position
  and ecx, dword 0x00000FC0	; keep lowest 6bits of 3rd byte
  shl eax, byte 18		; shift 1st byte into temporary position
  and ebx, dword 0x0003F000	; keep lowest 6bits of 2nd byte
  or ecx, edx			; merge in 3rd and 4th bytes
  or eax, ebx			; merge in 1st and 2nd bytes
  mov dl, byte [esi + 4]	; read in the 5th byte
  or ecx, eax			; merge in all first 4 bytes
  mov al, dl			; copy 5th byte for validity check
  and al, 0xC0			; keep highest 2 bits of 5th byte
  cmp al, 0x80			; make sure they are 10
  jnz short .case_invalid_relay3;
  xor dl, al			; keep lowest 6bits of 5th byte
  shl ecx, byte 6		; shift byte 1-4 into final position
  mov eax, edx			; move 5th byte into final position
  add esi, byte 5		; move string pointer foward 5 bytes
  or eax, ecx			; merge in bytes 1-4 with 5th byte
  pop edx			; restore EDX
  pop ecx			; restore ECX
  pop ebx			; restore EBX
  retn				; return 200000-3FFFFFF range UCS-4
				;
.case_6bytes:			; Encoded In 6 Bytes
				;---------------------------------------------
  mov ebx, eax			; move 4th byte in EBX(31:24)
  and eax, dword 0xC0C0C000	; keep highest 2bits of 2nd,3rd and 4th bytes
  mov ecx, ebx			; move 3rd byte in ECX(23:16)
  cmp eax, dword 0x80808000	; make sure the pairs of bits are all 10
  mov edx, ebx			; move 2nd byte in EDX(15:8)
.case_invalid_relay3_2:
  jnz short .case_invalid_relay3;
  xor edx, eax			; keep lowest 6bits of 4th byte
  shr ecx, byte 10		; shift 3rd byte into temporary position
  mov eax, ebx			; move 1st byte in EAX(7:0)
  shr edx, byte 24		; shift 4th byte into temporary position
  and eax, byte 0x01		; keep lowest bit of 1st byte
  shl ebx, byte 4		; shift 2nd byte into temporary position
  and ecx, dword 0x00000FC0	; keep lowest 6bits of 3rd byte
  shl eax, byte 18		; shift 1st byte into temporary position
  and ebx, dword 0x0003F000	; keep lowest 6bits of 2nd byte
  or ecx, edx			; merge in 3rd and 4th bytes
  or eax, ebx			; merge in 1st and 2nd bytes
  mov edx, dword [esi + 4]	; read in the 5th and 6th bytes
  or ecx, eax			; merge in all first 4 bytes
  mov eax, edx			; copy bytes 5-6 for validity check
  and eax, dword 0x0000C0C0	; keep highest 2 bits of bytes 5-6
  xor edx, eax			; keep lowest 6bits of 5th byte
  cmp eax, dword 0x00008080	; make sure they are 10
  mov al, dh			; move 6th byte into EAX(7:0)
  jnz short .case_invalid_relay3_2;
  and edx, byte 0x3F		; keep lowest 6bits of 6th byte
  shl ecx, byte 12		; shift byte 1-4 into final position
  shl edx, byte 6		; shift 5th byte into final position
  and eax, byte 0x3F		; make sure only the 6th byte is present in EBX
  or  ecx, edx			; merge 5th byte with bytes 1-4
  add esi, byte 6		; move string pointer foward 6 bytes
  or eax, ecx			; merge in bytes 1-5 with 6th byte
  pop edx			; restore EDX
  pop ecx			; restore ECX
  pop ebx			; restore EBX
  retn				; return 4000000-7FFFFFFF range UCS-4
;----------------------------------------------------------------------------- 


globalfunc utf8.encode_ucs4.to_utf8
;utf8.encode_ucs4.to_utf8:
;-----------------------------------------------------------------------------
; Encodes a UCS-4 character into a valid UTF-8 string.  Since an encoded
; UCS-4 can take from 1 to 6 bytes, it is required to at least have 6 bytes
; free in the destination string buffer.
;
; UCS-4 with bit 31 set will be flagged as invalid, causing the routine to
; return with the Carry Flag set.  When completed successfully, this routine
; return with the Carry Flag cleared.
;
; parameters:
;------------
; EAX = UCS-4
; EDI = pointer to UTF-8 buffer (must have at least 6 bytes free)
;
; returns:
;---------
; CF = 0, encoded properly
;    EAX = destroyed
; CF = 1, invalid UCS-4 (bit 31 is not 0)
;    EAX = unmodified
;
; Determine The Encoding Length
;---------------------------------------------
  cmp eax, byte 0x7F		; range 00-7F ?
  jbe .case_1byte		; if so, use 1 byte
  push ebx			; backup original EBX
  cmp eax, dword 0x000007FF	; range 80-7FF ?
  mov ebx, eax			; load EBX with UCS-4 to encode
  jbe .case_2bytes		; if within range, use 2 bytes
  push ecx			; backup original ECX
  cmp eax, dword 0x0000FFFF	; range 800-FFFF ?
  mov ecx, eax			; load ECX with UCS-4 to encode
  jbe .case_3bytes		; if within range, use 3 bytes
  push edx			; backup original EDX
  cmp eax, dword 0x001FFFFF	; range 10000-1FFFFF ?
  mov edx, eax			; load EDX with UCS-4 to encode
  jbe .case_4bytes		; if within range, use 4 bytes
  cmp eax, dword 0x03FFFFFF	; range 200000-3FFFFFF ?
  jbe near .case_5bytes		; if so, use 5 bytes
  cmp eax, dword 0x7FFFFFFF	; range 4000000-7FFFFFFF ?
  jbe near .case_6bytes		; if so, use 6 bytes
				;
				; bit 31 is set, unable to encode in UTF-8
  pop edx			; restore original EDX
  pop ecx			; restore original ECX
  pop ebx			; restore original EBX
				;
.invalid:			;
  stc				; set the Carry Flag
  retn				; return to the caller
				;
.case_1byte:			; Encoded In 1 Byte
				;---------------------------------------------
  mov [edi], byte al		; store the value
  clc				; clear the carry flag
  inc edi			; move the string pointer foward (1 byte)
  retn				; return range 00 - 7F
				;
.case_2bytes:			; Encoded In 2 Bytes
				;---------------------------------------------
  shl ebx, 8			; Byte2: Move UCS-4(5:0) into EBX(13:8)
  shr eax, 6			; Byte1: Move UCS-4(10:6) into EAX(4:0)
  and ebx, dword 0x00003F00	; Byte2: mask all bits except UCS-4(5:0)
  and eax, byte 0x1F		; Byte1: mask all bits except UCS-4(10:6)
  lea ebx, [eax + ebx + 0x000080C0]; merge bytes 1 and 2, set encoding bits
  mov [edi], ebx		; store the encoded bytes
  add edi, byte 2		; move string pointer forward 2 bytes, clear CF
  pop ebx			; restore original EBX
  retn				; return range C2 80 - CF BF
				;
.case_3bytes:			; Encoded In 3 Bytes
				;---------------------------------------------
  shr eax, 12			; Byte1: Move UCS-4(15:12) into EAX(3:0)
  shl ebx, 2			; Byte2: Move UCS-4(11:6) into EBX(13:8)
  shl ecx, 16			; Byte3: Move UCS-4(5:0) into ECX(21:16)
  and eax, byte 0x0F		; Byte1: mask all bits except UCS-4(15:12)
  and ebx, dword 0x00003F00	; Byte2: mask all bits except UCS-4(11:6)
  and ecx, dword 0x003F0000	; Byte3: mask all bits except UCS-4(5:0)
  lea eax, [eax + ebx + 0x008080E0]; merge bytes 1-2, set the encoding bits
  or  eax, ecx			; merge byte 3 with bytes 1-2
  mov [edi], eax		; store the encoded bytes
  add edi, byte 3		; move string pointer foward 3 bytes, clear CF
  pop ecx			; restore original ECX
  pop ebx			; restore original EBX
  retn				; return range E0 A0 80 - EF BF BF
				;
.case_4bytes:			; Encoded In 4 Bytes
				;---------------------------------------------
  shr eax, 18			; Byte1: Move UCS-4(20:18) into EAX(2:0)
  shr ebx, 4			; Byte2: Move UCS-4(17:12) into EBX(13:8)
  shl ecx, 10			; Byte3: Move UCS-4(11:6) into ECX(21:16)
  shl edx, 24			; Byte4: Move UCS-4(5:0) into EDX(29:24)
  and eax, byte 0x07		; Byte1: mask all bits except UCS-4(20:18)
  and edx, dword 0x3F000000	; byte4: mask all bits except UCS-4(5:0)
  and ecx, dword 0x003F0000	; Byte3: mask all bits except UCS-4(11:6)
  lea eax, [edx + eax + 0x808080F0]; merge bytes 1 and 4, set encoding bits
  and ebx, dword 0x00003F00	; Byte2: mask all bits except UCS-4(17:12)
  or  eax, ecx			; merge byte 3 with 1 and 4
  pop edx			; restore original EDX
  or  eax, ebx			; merge in byte 2 in final encoding
  pop ecx			; restore original ECX
  mov [edi], dword eax		; store the encoded bytes
  pop ebx			; restore original EBX
  add edi, byte 4		; move string pointer forward, clear CF
  retn				; return range F0 90 80 80 - F7 BF BF BF
				;
.case_5bytes:			; Encoded In 5 Bytes
				;---------------------------------------------
  push eax			; backup UCS-4(5:0)
  shr eax, 24			; Byte1: Move UCS-4(25:24) into EAX(1:0)
  shr ebx, 10			; Byte2: Move UCS-4(23:18) into EBX(13:8)
  shl ecx, 4			; Byte3: Move UCS-4(17:12) into ECX(21:16)
  shl edx, 18			; Byte4: Move UCS-4(11:6) into EDX(29:24)
  and eax, byte 0x03		; Byte1: mask all bits except UCS-4(25:24)
  and ebx, dword 0x00003F00	; Byte2: mask all bits except UCS-4(23:18)
  and ecx, dword 0x003F0000	; Byte3: mask all bits except UCS-4(17:12)
  lea eax, [eax + ebx + 0x808080F8]; merge bytes 1-2, set encoding bits
  and edx, dword 0x3F000000	; Byte4: mask all bits except UCS-4(11:6)
  or  ecx, eax			; merge byte 1-2 with byte 3
  pop eax			; restore UCS-4(5:0) bits
  or  ecx, edx			; merge byte 4 with bytes 1-3
  mov [edi], ecx		; store encoded bytes 1-4
  and eax, byte 0x3F		; Byte5: mask all bits except UCS-4(5:0)
  or  al, byte 0x80		; set encoding bits
  mov [edi+4], byte al		; store encoded byte 5
  pop edx			; restore original EDX
  pop ecx  			; restore original ECX
  add edi, byte 5		; move string pointer forward, clear CF
  pop ebx			; restore original EBX
  retn				; return range F8 88 80 80 80 - FB BF BF BF BF
				;
.case_6bytes:			; Encoded In 6 Bytes
				;---------------------------------------------
  push eax			; backup UCS-4(11:0)
  shr eax, 30			; Byte1: Move UCS-4(30:30) into EAX(0:0)
  shr ebx, 16			; Byte2: Move UCS-4(29:24) into EBX(13:8)
  shr ecx, 2			; Byte3: Move UCS-4(23:18) into ECX(21:16)
  shl edx, 12			; Byte4: Move UCS-4(17:12) into EDX(29:24)
  and eax, byte 0x01		; Byte1: mask all bits except UCS-4(30:30)
  and ebx, dword 0x00003F00	; Byte2: mask all bits except UCS-4(29:24)
  and ecx, dword 0x003F0000	; Byte3: mask all bits except UCS-4(23:18)
  lea eax, [eax + ebx + 0x808080FC]; merge bytes 1 and 2, set encoding bits
  and edx, dword 0x3F000000	; Byte4: mask all bits except UCS-4(17:12)
  or  ecx, eax			; merge byte 1-2 with byte 3
  pop eax			; restore UCS-4(11:0)
  or  ecx, edx			; merge byte 4 with bytes 1-3
  mov ebx, eax			; copy UCS-4(11:0)
  mov [edi], ecx		; store encoded bytes 1-4
  shr ebx, byte 6		; Byte5: Move UCS-4(11:6) into EBX(5:0)
  pop edx			; restore original EDX
  and ebx, byte 0x3F		; Byte5: mask all bits except UCS-4(5:0)
  and eax, byte 0x3F		; Byte6: mask all bits except UCS
  or  bl, byte 0x80		; Byte5: set encoding bits
  or  al, byte 0x80		; Byte6: set encoding bits
  mov [edi+4], byte bl		; store encoded byte 5
  mov [edi+5], byte al		; store encoded byte 6
  pop ecx			; restore original ECX
  add edi, byte 6		; move string pointer forward, clear CF
  pop ebx			; restore original EBX
  retn				; return range FC84808080-FDBFBFBFBFBF
;-----------------------------------------------------------------------------


globalfunc utf8.match_to_utf8_pattern
;utf8.match_to_utf8_pattern:
;-----------------------------------------------------------------------------
; Compare if a given string matches the given pattern.  The pattern may contain
; the following wildcards:
;   *   match any number of chars
;   ?   match any single character
;
; This routine is dependant on utf8.decode_ucs4.from_utf8
;
; parameters:
;------------
; EDI = pointer to UTF-8 string to match
; EDX = pointer to UTF-8 pattern
;
; returns:
;---------
; ECX = 0, pattern matched
; ECX = 1, pattern not matched / invalid UTF-8 string/pattern
;
;-----------------------------------------------------------------------------   
  xor ecx, ecx			; set return code to failed by default
  pushad			; backup all regs
  mov ebp, esp			; mark entry TOS
;
.matching:			; check for wildcard '*'
  mov esi, edx			;-----------------------
  call utf8.decode_ucs4.from_utf8	; get a single UCS-4 character
  jc short .fail		; in case of an invalid UTF-8 pattern
  cmp eax, byte '*'		; check if UCS-4 == '*'
  mov ebx, eax			; move UCS-4 from pattern into EBX
  jnz short .single_comp	; if not '*', match a single UCS-4
				;
				; catch multiple successive '*'
.catch_wc:			;------------------------------
  call utf8.decode_ucs4.from_utf8	; retrieve another UCS-4
  jc short .fail		; in case of an invalid UTF-8 pattern
  cmp eax, byte '*'		; check if UCS-4 == '*'
  jz short .catch_wc		; yes, save new pattern ptr
  mov edx, esi			; save pattern pointer
				;
				; check if pattern end with '*'
				;------------------------------
  test eax, eax			; UCS-4 == 0 ?
  mov esi, edi			; load UTF-8 string pointer in ESI
  jz short .success		; yip, we got a match
				;
				; find first matching char after '*'
				;-----------------------------------
  mov ebx, eax			; move UCS-4 from pattern into EBX
.match_wc_all:			;
  call utf8.decode_ucs4.from_utf8	; get a UCS-4 from UTF-8 string
  jc short .fail		; check for invalid UTF-8 string
  test eax, eax			; end of string to match? (UCS-4==0)
  jz short .fail		; if so we fail
				;
  cmp ebx, byte '?'		; check for '?' right after '*'
  jz short .wc_all_matched	; if so, match without checking
  cmp ebx, eax			; UCS-4 of pattern == UCS-4 of string?
  jnz .match_wc_all		; if not, continue searching
				;
.wc_all_matched:		;
  mov edi, esi			; save UTF-8 string pointer
  push esi			; register UTF-8 string ptr of last '*'
  push edx			; register UTF-8 pattern ptr
  push ebx			; register pattern UCS-4
  jmp short .matching		; continue matching
				;
				; Single UCS-4 to UCS-4 match
.single_comp:			;----------------------------
  mov edx, esi			; save pattern pointer
  mov esi, edi			; load UTF-8 string pointer
  call utf8.decode_ucs4.from_utf8	; get UCS-4 of string to match
  jc short .fail		; in case of an invalid UTF-8 string
  mov edi, esi			; save string pointer
				;
  test eax, eax			; string UCS-4 == 0 ?
  jz short .test_end_of_pattern	; if so, check if pattern is also ended
				;
  cmp ebx, byte '?'		; pattern is wildcard '?' ?
  jz short .matching		; if so, automatically match
  cmp ebx, eax			; make sure pattern UCS-4 match
  jz short .matching		; if so, continue checking
				;
				; Wildcard Fallback
				;------------------
  cmp ebp, esp			; any '*' wildcard registered on stack?
  jz short .fail		; if not, match failed
				;
				; get back to previous '*' found
  pop ebx			; restore pattern UCS-4
  pop edx			; restore UTF-8 pattern pointer
  pop esi			; restore UTF-8 string pointer
  jmp short .match_wc_all	; continue wildcard match
				;
				; Test End Of Pattern
.test_end_of_pattern:		;--------------------
  test ebx, ebx			; is pattern UCS-4 == 0 ?
  jnz short .fail		; if not, fail
				;
				; Success, make ECX = 1
.success:			;----------------------
  inc byte [ebp + 24]		; increment ECX on stack
				;
				; Failure or Success: common ending
.fail:				;----------------------------------
  mov esp, ebp			; restore original stack pointer
  popad				; restore all registers
  retn				; return result in ECX
;-----------------------------------------------------------------------------
