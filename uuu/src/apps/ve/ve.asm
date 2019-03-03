;; Vi-Eks, a ViM-like editor for UUU
;; distributed under the BSD License
;; by EKS - Dave Poirier
;;
bits 32
section .text
global _start

%include "macros.inc"
%include "vid/kbd.inc"
%include "vid/mem.inc"
%include "vid/vfs.inc"
%include "vid/debug.diable.inc"
%define ish.print.VID 5100
%define ish.scroll.VID 5101
%define tty_out externfunc ish.print

%define LF 0x0A


%define _DEBUG_

  struc ve_buffer
.next		resd 1
.prev		resd 1
.buffer		resd 1
.filename	resd 1
.file_handle	resd 1
.start_offset	resd 1
.line_number	resd 1
.total_lines	resd 1
.flags		resd 1
  endstruc

  struc char
.next		resd 1
.prev		resd 1
.char		resd 1
  endstruc

  struc edit_buffer
.starting_offset	resd 1
.line_number		resd 1
.first_free_char	resd 1
.first_used_char	resd 1
.chars		resb 3998*char_size
  endstruc




_start:

; XXX todo: use stdin rather than directly hooking kb
externfunc kbd.get_unicode_client
mov [old_kb], esi
mov esi, our_temporary_keyboard_handler
externfunc kbd.set_unicode_client

  ;; ecx = argument count
  ;; edi = pointer to argument list

.process_arguments:
  ;; go through the arguments specified
  dec	dword ecx
  jz	near  .proceed

  ;; move argument pointer foward
  add	dword edi, byte 4
  mov	dword esi, [edi]

  test	[option_end], byte 1
  jnz	short .filename

  ;; check for command line options
  mov	dword eax, [esi]
  cmp	byte  al, byte '-'
  jnz	short .filename

  ;; option detected, analyze it
  inc	dword esi
  push	dword ecx
  push	dword edi
  call	analyze_option
  pop	dword edi
  pop	dword ecx
  jnc	short .process_arguments

.end_dirty:
; XXX TODO: remove once we use stdin
mov esi, [old_kb]
externfunc kbd.set_unicode_client
  xor	dword eax, eax
  inc	eax
  retn

.filename:
  push	dword edi
  push	dword ecx
  push	dword esi
  mov	dword ecx, ve_buffer_size
  call	malloc
  jc	short .file_malloc_failed
  mov	dword [active_buffer], edi
  mov	dword edx, edi
  mov	dword ecx, edit_buffer_size
  call	malloc
  jc	short .file_malloc_failed
  call  format_edit_buffer
  mov	dword [edx + ve_buffer.buffer], edi
  pop	dword esi
  mov	dword [edx + ve_buffer.filename], esi
  externfunc vfs.open
  mov	dword [edx + ve_buffer.file_handle], ebx
  pop	dword ecx
  pop	dword edi
  jnc	short .process_arguments

.failed_opening_file:
  push	dword esi
  mov	dword esi, strings.unable_to_create_new_file
  tty_out
  pop	dword esi
  tty_out
  mov	dword esi, strings.linefeed
  tty_out
  jmp	short .end_dirty

.file_malloc_failed:
  add esp, byte 12
  jmp short .end_dirty

.proceed:
  

.end_cleanly:
; XXX todo: remove once we use stdin
mov esi, [old_kb]
externfunc kbd.set_unicode_client

  xor	dword eax, eax
  retn
;------------------------------------------------------------------------------


analyze_option:
;------------------------------------------------------------------------------
						;
  mov	dword edi, options			; set pointer to options
.searching_options:				;
  movzx	dword ecx, byte [edi]			; load offset to next option
  test	dword ecx, ecx				; check for end of options
  jz	short .option_not_found			; if 0, option not found
  push	dword edi				; backup option ptr
  push	dword esi				; backup selected option ptr
  push	dword ecx				; backup offset
  sub	dword ecx, byte 5			; adjust option length
  inc	dword edi
  repz	cmpsb					; compare strings
  pop	dword ecx				; restore offset
  pop	dword esi				; restore selected option ptr
  pop	dword edi				; restore option ptr
  jz	short .option_found			; in case we found a match
.wrong_match:					;
  add	dword edi, ecx				; move to next option
  jmp	short .searching_options		; continue searching
.option_found:					;
  mov	byte  al, [esi + ecx - 5]		; load termination char
  cmp	byte  al, '='				; check for valid termination
  jz	short .match_confirmed			; option=.. confirmed.
  test	byte  al, al				; check for valid termination
  jnz	short .wrong_match			; partial match, continue
.match_confirmed:				;
  jmp	near  [edi + ecx - 4]			; transfer control to option
						;
.option_not_found:				;
  push	dword esi				; backup selected option
  mov	dword esi, strings.app_title		; this app's name
  tty_out					; display it
  mov	dword esi, strings.unknown_option	; error msg to display
  tty_out					; display msg
  pop	dword esi				; get ptr to sel option
  tty_out					; display selected option
  mov	dword esi, strings.more_info		; more info msg
  tty_out					; display msg
  stc						; set error code
  retn						; return to caller
;------------------------------------------------------------------------------


format_edit_buffer:
;------------------------------------------------------------------------------
  retn
;------------------------------------------------------------------------------


malloc:
;------------------------------------------------------------------------------
  externfunc mem.alloc
  jnc short .exit

  push	dword esi
  mov	dword esi, strings.out_of_memory
  tty_out
  pop	dword esi
  stc
.exit:
  retn
;------------------------------------------------------------------------------


option_end_of:
;------------------------------------------------------------------------------
  test	byte al, al
  jnz	short analyze_option.option_not_found
  or [option_end], byte 1
  clc
  retn
;------------------------------------------------------------------------------




option_help:
;------------------------------------------------------------------------------
  mov	dword esi, strings.help
  tty_out
  clc
  retn
;------------------------------------------------------------------------------



option_unsupported:
;------------------------------------------------------------------------------
  push	dword esi
  mov	dword esi, strings.unsupported_option
  tty_out
  pop	dword esi
  tty_out
  mov	dword esi, strings.close_quote_linefeed
  tty_out
  clc
  retn
;------------------------------------------------------------------------------



option_version:
;------------------------------------------------------------------------------
  test	byte  al, al
  jnz	short analyze_option.option_not_found
  mov	dword esi, strings.app_title
  tty_out
  clc
  retn
;------------------------------------------------------------------------------


; XXX TODO: remove once we use stdin
our_temporary_keyboard_handler:
  pushad
  mov edi, [.buffer_head]
  mov ecx, edi
  call .advance_pointer
  cmp edi, [.buffer_tail]
  jz  short .buffer_full
  mov [.buffer_head], edi
  mov [ecx], eax
.buffer_full:
  popad
  clc
  retn
.advance_pointer:
  ; edi = pointer
  add edi, byte 4
  cmp edi, .buffer_head
  jb short .pointer_advanced
  mov edi, .buffer
.pointer_advanced:
  retn
.buffer: times 32 dd 0
.buffer_head: dd .buffer
.buffer_tail: dd .buffer

; XXX TODO: update to use the real stdin someday
read_stdin:
  push edi
  mov eax, [our_temporary_keyboard_handler.buffer_tail]
.wait_for_key:
  cmp eax, [our_temporary_keyboard_handler.buffer_head]
  jz short .wait_for_key
  mov edi, eax
  call our_temporary_keyboard_handler.advance_pointer
  mov eax, [eax]
  mov [our_temporary_keyboard_handler.buffer_tail], edi
  pop edi
  clc
  retn

%ifdef _DEBUG_
dbg_disp_string:
  lodsb
  stosw
  test al, al
  jnz dbg_disp_string
  retn
%endif

section .data

buffers:  dd -1
active_buffer: dd -1


%macro bool 2.nolist
.%{1}.BIT equ BOOL_BIT
.%{1}.BYTE equ BOOL_BYTE
%assign BOOL_BIT BOOL_BIT + 1
%ifidn BOOL_BIT, 8
  %assign BOOL_BIT 0
%endif
%endmacro

booleans:
%assign BOOL_BIT 0
%assign BOOL_BYTE 0
%assign BOOL_VAL 0
bool autoindent, 1
bool autoread, 0
bool autowrite, 0
bool autowriteall, 0
bool backup, 0
bool binary, 0
bool bomb, 0
bool foldenable, 1
bool gdefault, 0
bool hidden, 0
bool hkmap, 0
bool hkmapp, 0
bool modeline, 1
bool modifiable, 1
bool more, 1
bool mousefocus, 0
bool mousehide, 1



%macro option 2.nolist
%%opt_start: db %%optlen, %{1}, 0
dd option_%{2}
%%optlen equ $-%%opt_start
%endmacro

options:
option "-version", version
option "-help", help
option "h", help
option "-", end_of
option "R", unsupported
option "r", unsupported
option "L", unsupported
db 0

option_end: db 0	;<-- TODO: make that a boolean value in the future
old_kb: dd 0		;<-- TODO: remove this crap when we use stdin

strings:
.app_title: db "Vi-Eks - A ViM clone by EKS $(Revision:) $(Date:)",LF,0
.close_quote_linefeed: db '"',LF
.help:
  db "usage: ve [arguments] [file ..]          edit specified file(s)",LF
  db "   or: ve [arguments] -                  read text from stdin",LF
  db 0
.more_info: db '"',LF,'More info with: "ve -h"',LF,0
.linefeed equ $-2
.out_of_memory: db "Out of memory",LF,0
.unable_to_create_new_file: db "unable to create new file: ",0
.unknown_option: db 'Unknown option: "-',0
.unsupported_option: db 'Unsupported option: "-',0

%ifdef _DEBUG_
string_dbg:
.analyzing_option: db "analyzing option:",0
%endif
