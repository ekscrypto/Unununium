;; Existence OS-Wrapper - ununium core revision 2 -
;; Copyright (C) 2002, Dave Poirier
;; Distributed under the X11 License

[bits 32]
section .text

%assign _ASSUME_MEMORY_		4
%define _DISTRO_INFO_		"Existence CVS $Name:  $"

;							  -----------------
;--------------------------------------------------------[ osw entry point ]--
;							  -----------------
global _start				;
_start:					;
					; Blank the screen
					;-----------------
  mov  edi, dword 0xB8000		; set pointer to VGA text memory
  xor  eax, eax				; pattern(char,col,char,col) to use
  mov  ecx, dword (80*50*2)/4		; number of times pattern is repeated
  rep  stosd				; write it
					;
					; Mask all IRQs
					;--------------
  mov  al, byte 0xFF			; irq mask (all disabled)
  out  0x21, al				; write it to the master pic
  out  0xA1, al				; write it to the slave pic
					;
;							 ------------------
;-------------------------------------------------------[ core exportation ]--
;							 ------------------
					;
  					; set initial register values
					;----------------------------
  extern __INIT_SEQUENCE_LOCATION__	; import U3L provided value
  mov  esi, dword __INIT_SEQUENCE_LOCATION__
  xor  ebx, ebx				; set process ID = 0 (system)
					;
					; Determine number of operations
					;-------------------------------
  push dword [esi + core_init_hdr.inits]	; # of .c_init calls
  push dword [esi + core_init_hdr.zeroizes]	; # of zeroize operations
  push dword [esi + core_init_hdr.onetime_inits]; # of .c_onetime_init calls
  mov  edx, dword [esi + core_init_hdr.moves]	; number of moves
  add  esi, byte core_init_hdr_size	; go past init structure header
					;
					; Export in-core data areas
move_cells:				;--------------------------
  dec  edx				; 'move operations' --
  js   short .completed			; no more moves left!
  push esi				; save operation description pointer
  mov  al, byte 'M'			; set operation code
  call display_init_status		; show current operation details
  mov  ecx, dword [esi + core_op_move.dword_count]; get length of move
  mov  edi, dword [esi + core_op_move.destination]; get move destination address
  mov  esi, dword [esi + core_op_move.source]	  ; get move source address
  rep  movsd				; move it (export)
  pop  esi				; restore operation description pointer
  add  esi, byte core_op_move_size	; go to the next operation
  jmp  short move_cells			;
.completed:				;
					;
					; Perform .c_onetime_init calls
					;------------------------------
  pop  ecx				; get number of .c_onetime_init calls
  jecxz onetime_calls.completed		; check for no .c_onetime_init to do
onetime_calls:				;
  pushad				; backup all regs
  mov  al, byte 'O'			; set operation code
  call display_init_status		; show current operation details
  mov  eax, dword [esi + core_op_init.entry_point]    ; destination to call
  movzx ecx, byte [esi + core_op_init.parameter_count]; number of arguments
  mov  esi, dword [esi + core_op_init.parameter_array]; ptr to parameter array
  call eax				; call the .c_onetime_init function
  jc   near display_init_failed		; lock if an error occured
  popad					; restore all regs
  add  esi, byte core_op_init_size	; move to next entry
  dec  ecx				; 'onetime call operations' --
  jnz  short onetime_calls		; if any left, continue
.completed:				;
					;
					; Perform zeroize operations
					;----------------------------
  pop  edx				; get number of zeroize operations
zeroize:				;
  dec  edx				; 'number of zeroize' --
  js   short .completed			; if none to do, we are done
  mov  al, byte 'Z'			; set operation code
  call display_init_status		; show current operation details
  mov  edi, dword [esi + core_op_zeroize.destination]; set destination
  mov  ecx, dword [esi + core_op_zeroize.dword_count]; get size to zeroize
  xor  eax, eax				; our ZERO register
  rep  stosd				; zeroize it!
  add  esi, byte core_op_zeroize_size	; move to next operation
  jmp  short zeroize			;
.completed:				;
					;
;						      ---------------------
;----------------------------------------------------[ cell initialization ]--
;						      ---------------------
					;
  pop  ecx				; get number of .c_init operations
  jecxz inits.completed			; check for a 0 operation count
inits:					;
  pushad				; back all regs, .c_init may be nasty
  mov  al, byte 'I'			; set operation code
  call display_init_status		; show current operation details
  mov  eax, dword [esi + core_op_init.entry_point]    ; destination to call
  movzx ecx, byte [esi + core_op_init.parameter_count]; number of arguments
  mov  esi, dword [esi + core_op_init.parameter_array]; ptr to parameter array
  call eax				; initialize this cell
  jc   short display_init_failed	; lock if an error occurred
  popad					; restore all regs
  add  esi, byte core_op_init_size	; move to next init descriptor
  dec  ecx				; number of inits --
  jnz short inits			; if > 0, continue
.completed:				;

					;
;							    ------------
;----------------------------------------------------------[ list cells ]--
;							    ------------
					;
  extern __INFO_REDIRECTOR_TABLE__	;
  mov esi, __INFO_REDIRECTOR_TABLE__	;
  extern __CORE_HEADER__		;
  movzx ecx, word [ __CORE_HEADER__ + hdr_core.cell_count ]
					;
listing_cells:				;
  mov  eax, dword [esi + core_cell_info.name_str];
  test eax, eax				; check if cell name is provided
  jnz .name_set				;
  mov eax, unknown_cell_name		; cell name not provided
.name_set:				;
  push eax				; indicate cell name ptr
  push dword [esi + core_cell_info.version]; indicate cell version
;  push byte __SYSLOG_TYPE_INFO__	; type of log entry
;  push dword str__cell_initialized	; pattern
;  externfunc sys_log.print		; display str and clear 2 top params
  add esp, byte 16 - 8			; clear left over params
  add esi, core_cell_info_size		; move to next entry
  dec ecx				; .cell_count--
  jnz short listing_cells		; continue if any cell info left
					;
;						------------------------
;----------------------------------------------[ setup user environment ]--
;						------------------------
					;
;  push byte __SYSLOG_TYPE_INFO__	;
;  push dword str__core_export_completed	;
;  externfunc sys_log.print		;
  retn
  mov eax, 0xEEEE1111
  jmp  short $				;



display_init_failed:
  mov esi, str__init_failed
  mov edi, 0xB80A0
  mov ah, 0x40
.display_msg:
  lodsb
  stosw
  test al, al
  jnz short .display_msg
  jmp short $


display_init_status:
  pushad
  movzx ebx, word [esi]
  extern __INFO_REDIRECTOR_TABLE__
  mov esi, [ebx * 4 + __INFO_REDIRECTOR_TABLE__ - 4]
  mov esi, [esi + 4]
.string_set:
  mov edi, 0xB8000
  cbw
  shl eax, 16
  or eax, 0x1F001700 + '['
  stosd
  mov al, ']'
  stosw
  mov al, ' '
  push byte 77
  pop ecx
.display:
  stosw
  lodsb
  dec ecx
  jz short .quit
  test al, al
  jnz short .display
  rep stosw
.quit:
  popad
  retn


section .data
str__cell_initialized:
  db "exported version %v of %s",0
str__core_export_completed:
  db "core exportation completed.",0
str__init_failed:
  db "INITIALIZATION FAILED",0
unknown_cell_name:
  db "unidentified cell",0

