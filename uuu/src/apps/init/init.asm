;; $Header: /cvsroot/uuu/uuu/src/apps/init/init.asm,v 1.2 2001/12/15 20:03:01 instinc Exp $
;;
;; by Dave Poirier (instinc@users.sourceforge.net)
;; Distributed under the modified BSD License
;;
[bits 32]


								 ;-------------
								  section .text
;------------------------------------------------------------------------------
global _start				; define our entry point as global
					;
					; system status flags
%define STATUS_8042_FAILED	    0x01; bit 0: 8042 controller error/failure?
%define STATUS_KEYB_RESET_FAILED    0x02; bit 1: keyboard error/failure?
%define STATUS_MEM_TRANSFERED       0x04; bit 2: is mem.alloc transfered?
%define STATUS_FORCED_USER_INPUT    0x08; bit 3: invalid config, input required
;------------------------------------------------------------------------------


									;------
									 _start:
;------------------------------------------------------------------------------
					; Check who gave us control
					;--------------------------
  test ecx, ecx				; if 0, boot record
  jz   short .from_boot_record		; in case it is, act upon it
					;
					; Ran from command-lin
					;---------------------
  jmp  short $				;
					;
					; Clean init
.from_boot_record:			;-----------
  mov  [redirector.malloc], eax		; backup pointer to malloc function
  mov  [redirector.file_open], ebx	; backup pointer to file open function
  mov  [redirector.file_read], edx	; backup pointer to file read function
  mov  [redirector.get_file_size], ebp	; backup pointer to get file size func
					;
					; Display init welcome message
					;-----------------------------
  push byte  __SYSLOG_TYPE_LOADINFO__	;
  push dword strings.title		; welcome message
  call __lprint				; send it to the log
  pop  eax				; clear welcome from stack
  pop  eax				; clear debug type
					;
					; Wait for 8042 to process all commands
.wait_kbd0:				;--------------------------------------
  in   al, 0x64				; read 8042 status port
  test al, 0x02				; test inbuf status
  jnz  short .wait_kbd0			; if not empty, wait again
					;
					; Clear 8042 output buffer
.clear_kbd_outbuf:			;-------------------------
  in   al, 0x64				; read 8042 status port
  test al, 0x01				; test outbuf status
  in   al, 0x60				; read outbuf data in case
  jnz  short .clear_kbd_outbuf		; if it was not empty, check again
					;
					; 8042 Self-test
					;---------------
  mov  al, 0xAA				; self-test command
  out  0x64, al				; send it
					;
  call kbd_inb				; wait for 8042 self-test result
					;
  cmp  al, 0x55				; check if test passed
  jz   short .self_test_8042_passed	; bypass error message if test is OK
					;
					; Display 8042 self-test failed
					;------------------------------
  movzx eax, al				; make error code 32bits
  push eax				; prepare it for display
  push byte  __SYSLOG_TYPE_WARNING__	;
  push dword strings.self_test_8042_failed; error message
  call __lprint				; send it to the log
  add  esp, byte 12			; clear params from stack
  or   byte [system_status], byte STATUS_8042_FAILED
  jmp  short .bypass_kbd_reset		;
					;
.self_test_8042_passed:			;
					; Reset Keyboard Controller
					;--------------------------
  mov  al, 0xFF				; reset command
  call kbd_outb				; send command to keyboard controller
					;
  call kbd_inb				; get keyboard controller answer
  cmp  al, 0xFA				; check if answer is ACK
  jz   short .keyboard_reset_acked	;
					;
  movzx eax, al				; make returned error code 32bit
  push dword strings.keyboard_disabled	; second part of error message
  push eax				; give it as argument to the log
  push byte  __SYSLOG_TYPE_WARNING__	;
  push dword strings.keyboard_reset_failed; error message
  call __lprint				; send all that to the log
  add  esp, byte 16			; clear params on stack
  or   byte [system_status], byte STATUS_KEYB_RESET_FAILED
					;
.keyboard_reset_acked:			;
.bypass_kbd_reset:			;
					; Open configuration file
					;------------------------
  mov	dword esi, files.config		; set our config filename
  push	dword esi			; back it up for log purposes
  call  [redirector.file_open]		; try to open the file
  jnc   short .master_config_open	; check if all went well, if so jump
					;
					; display error in log
					;---------------------
  push	byte  __SYSLOG_TYPE_FATALERR__	; fatal error class of log
  push	dword strings.file_not_found	; set our error message
  call  __lprint			; display log entry
  jmp   short $				; lock the computer
					;
.master_config_open:			; display status in log
					;----------------------
  push	byte  __SYSLOG_TYPE_INFO__	; loading info class of log
  push	dword strings.reading_config	; set our status message
  call	__lprint			; display log entry
  add	dword esp, byte 12		; clear log entry params from stack
					;
					; get file size
					;--------------
					; edx = file handle
					;
  call	[redirector.get_file_size]	; acquire file size (ecx)
					;
					; ecx = file size
					; edx = file handle
					;
					; allocate memory
					;----------------
  inc ecx				; give us space for a null terminator
  call  __malloc			; allocate it
  					;
					; eax = file size+1
					; edx = file handle
					; edi = allocated memory block
					;
					; read file to memory
					;--------------------
  mov	ecx, eax			; restore original file size
  xor   ebp, ebp			; set starting offset to 0
  dec   ecx				; adjust size (without null terminator)
  call  [redirector.file_read]		; read file
  mov   [edi + ecx], byte 0		; null-terminate the file
					;
					; ecx = file size
					; edi = destination buffer
					; ebp = 0
					;
pushad
mov dx, 0x8A00
mov ax, dx
out dx, ax
mov al, 0xE5
out dx, ax
mov al, 0xE3
out dx, ax
popad
					; scan file for preliminary information
					;--------------------------------------
  mov   esi, edi			;
.process_next_token:			;
  inc	ebp				; increment line number
  call  __get_token			; get a token
  jc	short .force_user_input		; in case invalid file detected..
					;
  dec	eax				; blank line? (blank/comment)
  js	short .get_new_line		; if so, go to next line
					;
  cmp	eax, byte 6-1			; make sure it is a system init token
  ja	short .force_user_input		; if not, invalid file
					;
  call  [eax*4 + tokens.handler]	; call the respective token handler
  jc	short .force_user_input		; in case an invalid char was detected
					;
.get_new_line:				;
  lodsb					; load a character
  test al, al				; check for null terminator
  jz short .end_of_config		; in case it is, config parsing done
  cmp al, 0x0A				; check for new line
  jnz short .get_new_line		; if not, read char again
  jmp short .process_next_token		; newline detected, parse for token
					;
.end_of_config:				;
  test  [system_status], byte (STATUS_8042_FAILED + STATUS_KEYB_RESET_FAILED)
  jnz   short .use_defaults		;
  					;
  push	dword [config.delay]		;
  push	byte __SYSLOG_TYPE_INFO__	;
  push	dword strings.press_a_key	;
  call  __lprint			;
  add	esp, byte 8			;
					;
  pop	edx				;
					;
.outer_delay_checker:			;
					;
  mov	ecx, 66291			; 66291*15.085us = 1s
.inner_delay_checker:			;
  in al, 0x61				;
  and al, 0x10				;
  cmp al, ah				;
  jz short .inner_delay_checker		;
  mov ah, al				;
  in al, 0x64				;
  test al, 0x01				;
  jnz short .get_user_input		;
  dec   ecx				;
  jns	short .inner_delay_checker	;
  dec   edx				;
  jle	short .outer_delay_checker	;
					;
.use_defaults:				;
  mov eax, [config.files]		;
  test  eax, eax			;
  jz short .force_user_input		;
					;
  mov	esi, [config.files]		;
  call  __find_matching_config		;
  jnc	short .load_specific_config	;
					;
.force_user_input:			;
  push  dword strings.forcing_user_input;
  push	byte __SYSLOG_TYPE_WARNING__	;
  push	dword strings.invalid_file_format
  call  __lprint			;
  add   esp, byte 12			;
  or	[system_status], byte STATUS_FORCED_USER_INPUT
					;
  test  [system_status], byte (STATUS_8042_FAILED + STATUS_KEYB_RESET_FAILED)
  jz	short .get_user_input		;
					;
  push	byte __SYSLOG_TYPE_FATALERR__	;
  push	dword strings.unable_to_force_user_input
  call	__lprint			;
  jmp	short $				;
					;
.get_user_input:			;
  mov	edi, 0xB8000
  mov	ecx, 2000
  mov	eax, 0x07200720
  rep	stosd
  jmp	short $				;
					;
.load_specific_config:			;
  lea	esi, [edi + config_entry.filename]
  push	esi				;
  push	byte __SYSLOG_TYPE_LOADINFO__	;
  push	dword strings.reading_config	;
  call	__lprint			;
					;
  jmp	short $				;
;------------------------------------------------------------------------------

							;----------------------
							 __find_matching_config:
;------------------------------------------------------------------------------
clc
retn
;------------------------------------------------------------------------------

								   ;-----------
								    __get_token:
;------------------------------------------------------------------------------
; parameters:
;	esi = pointer to memory buffer holding string
; returns:
;   cf = 0, token identified
;	eax = token id
;		0 = no token found, blank line
;		1 = config
;		2 = default
;		3 = delay
;		4 = label
;		5 = ram
;		6 = root
;		7 = load
;		8 = run
;		9 = transfer
;	esi = pointer to first char of token
;   cf = 1, invalid token
;	al  = <destroyed>
;	esi = first non-space character
;	other registers returned unmodified
;------------------------------------------------------------------------------
					; Clear out spaces characters
.clear_leading_spaces:			;----------------------------
  lodsb					; load next character
  cmp al, ' '				; clear out leading spaces
  jz short .clear_leading_spaces	; ..
  cmp al, 0x09				; clear out leading tabs
  jz short .clear_leading_spaces	; ..
					;
					; Test for blank line
					;--------------------
  dec esi				;
  cmp al, 0x0A				; check for new line character
  jz short .blank_line			; if it is a real blank line..
  test al, al				; check if it is a null terminator
  jz short .blank_line			;
  cmp al, '#'				; in case it is a commented line
  jnz short .not_blank			; if it isn't, check for a token id
					;
					; return blank line token
.blank_line:				;------------------------
  xor eax, eax				; set token = 0, CF = 0
  retn					; return
					;
					; Identify token
.not_blank:				;---------------
  pushad				; backup original regs
  push byte 8				; set maximum token length
  pop  ecx				;
  xor  edx, edx				;
  xor  ebx, ebx				;
.parse_token:				;
  lodsb					; load next char
  or   al, 0x20				; lowercase(char)
  cmp  al, 'a'				; check for lower margin
  jb   short .token_end			;
  cmp  al, 'z'				; check for higher margin
  ja   short .token_end			;
					; add char to token name
					;-----------------------
  shld ebx, edx, 8			;
  shl  edx, 8				;
  mov  dl, al				;
  loop .parse_token			; continue parsing if token isn't full
					;
					; make sure token is 8 char or less
					;----------------------------------
  or   al, 0x20				; lowercase(char)
  cmp  al, 'a'				; low-area upper margin
  jb   short .token_end			; if lower, it is valid
  cmp  al, 'z'				; high-area lower margin
  ja   short .token_end			; if higher, it is valid
					;
					; Invalid token detected
.invalid_token:				;-----------------------
  popad					; restore all regs
  stc					; set carry flag
  retn					;
					; End of token identified
.token_end:				;------------------------
  dec esi				; set pointer back to non-token char
  lodsb					;
  cmp al, '='				;
  jnz short .invalid_token		;
					;
  cmp ecx, byte 8			; make sure token is not zero-length
  jz short .invalid_token		; if it is, invalid token dude..
					;
					; Prepare token search regs
					;--------------------------
  push byte TOKEN_COUNT			; number of tokens defined
  pop ecx				; set this number in ecx
  mov edi, tokens			; pointer to tokens definition
					;
.check_next_token:			;
  dec ecx				; check if we got a token to compare to
  js  short .invalid_token		; if none left, invalid one buddy
					;
					; Compare tokens
					;---------------
  cmp [ecx*8 + edi], edx		; compare low part
  jnz short .check_next_token		; if not the same, go to the next token
  cmp [ecx*8 + edi + 4], ebx		; compare high part
  jnz short .check_next_token		; if not the same, go to the next token
					;
					; Token identified
					;-----------------
  inc ecx				; get token id
  mov [esp + 28], ecx			; mark it as returned value
  popad					; restore registers
  clc					; clear error flag
  retn					; return to caller
;------------------------------------------------------------------------------


								  ;------------
								   token_config:
;------------------------------------------------------------------------------
  add esi, byte 7			; go after config= part
					;
					; allocate configuration memory
					;------------------------------
  mov ecx, config_entry_size		; number of bytes required
  call __malloc				; allocate it
					;
  mov eax, edi				; set pointer to our new entry
  xchg eax, [config.files]		; get previous configuration entry
  mov [edi], eax			; link previous entry
  add edi, byte config_entry.filename	; get offset to filename
  push byte 127				;
  pop ecx				;
  mov ebp, validate_filename_char	;
  					;
					;
					; copying name
.copying_name:				;-------------
  lodsb					; get one char
  call ebp				; make sure it is a valid char
  jc short .name_completed		; in case it isn't..
  stosb					; store filename char
  loop .copying_name			;
					;
					; zero-terminate name
.name_completed:			;--------------------
  mov al, 0				; null terminator
  stosb					; store it
					;
  dec esi				; get first invalid char
  clc					; clear error flags
  retn					; return to caller
;------------------------------------------------------------------------------


								 ;-------------
								  token_default:
;------------------------------------------------------------------------------
  add esi, byte 8			; get past default=
  mov edi, config.default		; set destination buffer
  push byte 31				; maximum name length
  pop ecx				; get it in ecx
  mov ebp, validate_name_char		; valid char checker
  jmp short token_config.copying_name	; copy that name down
;------------------------------------------------------------------------------


								   ;-----------
								    token_label:
;------------------------------------------------------------------------------
  add esi, byte 6			; get past label=
					;
  mov edi, [config.files]		; load last config
  test edi, edi				; make sure label= is used with config=
  jz short .invalid			; in case it is not..
					;
  add edi, byte config_entry.label	; get pointer to buffer
  push byte 31				; maximum name length
  pop ecx				; get it in ecx
  mov ebp, validate_name_char		; valid char checker
  jmp token_config.copying_name		; copy that name down
					;
.invalid:				; label used outside of config=
					;------------------------------
  stc					; set error flag
  retn					; return to caller
;------------------------------------------------------------------------------


								    ;----------
								     token_root:
;------------------------------------------------------------------------------
  mov edi, [config.files]
  push byte 31
  pop ecx
  mov ebp, validate_filename_char
  test edi, edi
  lea edi, [edi + config_entry.root]
  jnz short token_config.copying_name
  mov edi, config.root
  jmp short token_config.copying_name
;------------------------------------------------------------------------------


								   ;-----------
								    token_delay:
;------------------------------------------------------------------------------
  add esi, byte 6
  call __get_decimal
  mov [config.delay], ebx
  clc
  retn
;------------------------------------------------------------------------------


								     ;---------
								      token_ram:
;------------------------------------------------------------------------------
  add esi, byte 4
  call __get_decimal
  shl ebx, 20
  mov [config.ram], ebx
  test ebx, ebx
  jnz short .valid
  cmp [esi], dword 'auto'
  jz short .valid
  stc
  retn
.valid:
  clc
  retn
;------------------------------------------------------------------------------


								 ;-------------
								  __get_decimal:
;------------------------------------------------------------------------------
  xor ebx, ebx
.computing:
  lodsb
  sub al, '0'
  js short .done
  cmp al, 9
  ja short .done
  movzx eax, al
  imul ebx, byte 10
  add ebx, eax
  jmp short .computing
.done:
  dec esi
  retn
;------------------------------------------------------------------------------


							;----------------------
							 validate_filename_char:
;------------------------------------------------------------------------------
  cmp al, '/'
  jz short validate_name_char.valid
  cmp al, '-'
  jz short validate_name_char.valid
  cmp al, '.'
  jz short validate_name_char.valid
;------------------------------------------------------------------------------


							    ;------------------
							     validate_name_char:
;------------------------------------------------------------------------------
  cmp al, '0'
  jb short .invalid
  cmp al, '9'
  jbe short .valid
  cmp al, 'A'
  jb short .invalid
  cmp al, 'Z'
  jbe short .valid
  cmp al, '_'
  jz short .valid
  cmp al, 'a'
  jb short .invalid
  cmp al, 'z'
  jbe short .valid
.invalid:
  stc
  retn
.valid:
  clc
  retn
;------------------------------------------------------------------------------


								      ;--------
								       __malloc:
;------------------------------------------------------------------------------
					; Check if memory cell is loaded
					;-------------------------------
  test [system_status], byte STATUS_MEM_TRANSFERED
  jz   short .not_transfered_yet	; in case it isn't, use our code
					;
  jmp  [redirector.malloc]		; use the memory cell
					;
					; Internal memory allocation code
.not_transfered_yet:			;--------------------------------
  mov  edi, 0x00100000			; SMC: base of free memory (extended)
    .extended_base equ $-4		; set pointer to SMC
  push edx				; backup edx, must not be destroyed
  push ecx				; backup original requested size
  mov  edx, -0x40			; value used for alignment
  add  ecx, byte (0x3F + 0x40)		; add link space + alignment
  and  ecx, edx				; align block size
  add  [.extended_base], ecx		; modify the SMC to new base address
  mov  eax, edi				; prepare for linked list update
  xchg eax, [memory.allocated_blocks]	; update allocated block linked list
  mov  [edi], eax			; link previously allocated block
  mov  [edi + 4], ecx			; indicate block size
  sub  edi, edx				; get pointer to allocated block
  add  ecx, edx				; compute allocated block size
  pop  eax				; restore originally requested size
  pop  edx				; restore original edx
  clc					; clear error flag
  retn					; return to caller
;------------------------------------------------------------------------------


								       ;-------
									kbd_inb:
;------------------------------------------------------------------------------
  in al, 0x64				; read in 8042 status
  test al, 0x01				; test status of 8042 output buffer
  jz short kbd_inb			; in case no data is there yet.. retry
  in al, 0x60				; get data from 8042 output buffer
  retn					; return to caller
;------------------------------------------------------------------------------


								      ;--------
								       kbd_outb:
;------------------------------------------------------------------------------
  push eax				;
.waiting_kbd_inbuf_empty:		;
  in al, 0x64				;
  test al, 0x02				;
  jnz short .waiting_kbd_inbuf_empty	;
  pop eax				;
  out 0x60, al				;
					;--------------------------------------
								null_redirector:
;------------------------------------------------------------------------------
  retn					; return to caller
;------------------------------------------------------------------------------


								  ;------------
								   log_transfer:
;------------------------------------------------------------------------------
  ; TODO
  jmp short $
;------------------------------------------------------------------------------

								      ;--------
								       __lprint:
;------------------------------------------------------------------------------
; stack to a printf look-alike string
;------------------------------------------------------------------------------
  pushad				;
  mov ebp, esp				;
  add esp, byte 36			;
					;
  pop esi				; retrieve pointer to message
  pop eax				; retrieve message type
  lea eax, [eax*8 + log_types]		;
  mov edi, log_buffer			;
  mov ebx, [eax]			;
  mov ecx, edi				;
  mov [edi], ebx			;
  mov ebx, [eax + 4]			;
  mov [edi+4], ebx			;
  mov al, 0x20				;
  add edi, byte 8			;
  stosb					;
					;
.parsing_main_string:			;
  lodsb					;
  test al, al				;
  jz short .end				;
  cmp al, '%'				;
  jz short .special_handler		;
  cmp al, '\'				;
  jz near .special_character		;
.unknown_char:				;
  stosb					;
  jmp short .parsing_main_string	;
					;
.end:					;
  stosb					; copy down 0 terminator
  mov esp, ebp				; restore original stack context
					;
					; Allocate space for log entry
					;-----------------------------
  mov esi, ecx				; get original log_buffer pointer
  sub ecx, edi				; get negated log entry length
  neg ecx				; make it positive
  push ecx				; backup original string length
  add ecx, 8				; add space to link log entry + type
  call __malloc				; allocate memory for it
					;
					; Link log entry
					;---------------
  mov eax, [log_linked_list]		; get previous last log entry
  mov [log_linked_list], edi		; mark our as new latest log
  stosd					; link the previous log entry up
  mov eax, [esp + 44]			; get log type
  stosd					; store log type
  mov ebx, edi				; backup pointer to log entry
					;
					; Scroll on-screen display
					;-------------------------
  push esi				; backup pointer to log buffer
  mov esi, 0xB8140			; input data start at line 2
  mov edi, 0xB80A0			; destination data start at line 1
  mov ecx, (80*2*23)/4			; length to move around
  rep movsd				; move it
					;
					; Send log to log entry and display
					;----------------------------------
  pop esi				; restore pointer to log buffer
  pop edx				; restore log buffer length + 4
  mov cl, 80				; set max on-screen length
  mov ah, 0x07				; set log color
.copying_log_entry:			;
  lodsb					; read one char off the log
  stosw					; display char and attrib on screen
  dec ecx				; dec on-screen length allowable
  jz short .finish_log			; if anymore left to do, go do it
  mov [ebx], al				; copy char to log entry
  inc ebx				; move log entry pointer foward
  dec edx				; dec total log entry left to do
  jnz short .copying_log_entry		; if not zero, continue to process
					;
  rep stosw				; zeroize remaining of the screen line
  popad					; restore all registers
  retn					; return to caller
					;
.finish_log:				;
  mov edi, ebx				; set destination pointer
  mov ecx, edx				; set length left to copy
  rep movsb				; copy down the data
  popad					; restore all registers
  retn					; return to caller
					;
.special_handler:
  pop ebx
  lodsb
  cmp al, 's'
  jz short .substring
  cmp al, 'x'
  jz short .hexadecimal
  cmp al, 'd'
  jz short .decimal
  cmp al, 'f'
  jz short .float
  cmp al, 'o'
  jz short .display_octal
  push ebx
  jmp short .unknown_char

.display_octal:
  mov al, 0x08
  jmp short .value_common

.substring:
  xchg esi, ebx
.displaying_substring:
  lodsb
  stosb
  test al, al
  jnz short .displaying_substring
  dec edi
  mov esi, ebx
.go_parse_main_string:
  jmp near .parsing_main_string

.hexadecimal:
  mov al, 0x10
  jmp short .value_common

.decimal:
  mov al, 0x0A
.value_common:
  mov [.start_loc], edi
  movzx eax, al
  xchg eax, ebx
.processing_value:
  xor edx, edx
  div ebx
  xchg eax, edx
  cmp al, 0x0A
  sbb al, 0x69
  das
  stosb
  xchg eax, edx
  test eax, eax
  jnz short .processing_value
  mov ebx, edi
  mov edx, 0
    .start_loc equ $-4
.swap_chars:
  dec ebx
  mov al, [ebx]
  xchg al, [edx]
  mov [ebx], al
  inc edx
  cmp edx, ebx
  jna short .swap_chars
  jmp short .go_parse_main_string

.float:
  stosb
  jmp short .go_parse_main_string

.special_character:
  lodsb
  cmp al, 'n'
  mov bl, 0x0A
  jz short .special_char_write
  cmp al, 't'
  mov bl, 0x08
  jz short .special_char_write
  cmp al, '\'
  mov bl, al
  jz short .special_char_write
  xchg al, bl
  stosb
.special_char_write:
  mov al, bl
  stosb
  jmp short .go_parse_main_string

section .data

			align 8, db 0
tokens:
db "gifnoc"	; config
			align 8, db 0
db "tluafed"	; default
			align 8, db 0
db "yaled"	; delay
			align 8, db 0
db "lebal"	; label
			align 8, db 0
db "mar"	; ram
			align 8, db 0
db "toor"	; root
			align 8, db 0
			TOKEN_COUNT equ ($-tokens)/8
.handler:
dd token_config
dd token_default
dd token_delay
dd token_label
dd token_ram
dd token_root

redirector:
.non_standards:
 .file_open: dd 0
 .file_read: dd 0
 .get_file_size: dd 0
.globals:
 .malloc:
  dd null_redirector
  dd mem.alloc.VID
 .lprint:
  dd __lprint
  dd 5300

log_types:
db "DEBUG   "
db "INFO    "
db "LOADINFO"
db "WARNING "
db "FATALERR"

strings:
.done:
  db "done.\n",0
.failed:
  db "failed.\n",0
.file_not_found:
  db "Could not open file: %s",0
.forcing_user_input:
  db "Forcing user input.",0
.initializing:
  db "Providing organic contact to %s...",0
.invalid_file_format:
  db "Invalid file format detected. %s",0
.keyboard_reset_failed:
  db "Keyboard reset failed with error %x"
  .keyboard_disabled:
  db ", keyboard input disabled.",0
.loading: 
  db "Requesting mitosis of %s...",0
.press_a_key:
  db "Press a key to enter system config, using defaults in %d seconds...",0
.reading_config:
  db "Reading configuration file %s...",0
.self_test_8042_failed:
  db "8042 Self-Test failed with error %x%s",0
.title:
  db "Unununium Distribution Initializer $Revision: 1.2 $ says 'hi!'",0
.unable_to_force_user_input:
  db "User input requested while keyboard or 8042 init failed.",0
.welcome:
  db "Genetically assimilated %s\n",0

files:
.config: db "/conf/init",0

section .bss
log_buffer: times 256 resb 1
log_linked_list: resd 1
system_status: resd 1
memory.allocated_blocks: resd 1
config:
 .default: resb 32
 .delay: resd 1
 .files: resd 1
 .ram: resd 1
 .root: resb 32
