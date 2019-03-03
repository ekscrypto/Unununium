;; $Header: /cvsroot/uuu/dimension/app/shell/ish/ish.asm,v 1.3 2002/01/21 06:17:25 instinc Exp $
;;
;; Ish shell
;; Copyright (c) 2001 Phil Frost
;; Ish is distributed under the BSD license, see file "license" for details
;;
;; Features:
;; ---------
;; fast command lookup
;; command editing
;; no un-features
;; supports escape chars in prompt to display usefull stuff (prompt -h)
;; command history
;;
;; Features-to-be:
;; ---------------
;; alias support

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_
%define history_max 32		; max number of commands in history
%define hash_seed 0x00009A00	; seed used for fasthash
%define command_buff_size 0x100	; size of command buffer

;                                           -----------------------------------
;                                                                      includes
;==============================================================================


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc command_entry
  .prev:	resd 1
  .next:	resd 1
  .length:	resd 1
  ; string follows, no null
endstruc

struc hash_node
  .next:	resd 1	; ptr to next hash node, or -1 for none
  .length:	resd 1	; length of command
  .function:	resd 1	; function to call
  ; string follows, no null
endstruc

;                                           -----------------------------------
;                                                     and now the real stuff!!!
;==============================================================================

beam_me_out:
  xor eax, eax
  retn

;                                           -----------------------------------
;                                                                        _start
;==============================================================================

global _start
_start:
  mov eax, [edi]
  mov [shell_name], eax

  mov [proc_info], ebx
  mov eax, [ebx+process_info.stdout]
  mov edx, [ebx+process_info.stdin]
  mov esi, [ebx+process_info.stderr]
  mov ecx, [ebx+process_info.env]
  mov [stdout], eax
  mov [stdin], edx
  mov [stderr], esi
  mov [env], ecx

  externfunc thread.get_self
  mov [thread_self], eax

read_line:
  cmp byte[quit], 0
  jne beam_me_out

  call _print_prompt

  mov ebx, [stdin]
  mov ecx, command_buff_size
  mov edi, command_buf
  call _read_input_line
  dec ecx			; overwrite the 0xa with a 0
  mov word[edi+ecx], 0		;
  mov esi, edi

  ;; ESI = ptr to command string (single null terminated)
  ;; ECX = length of that string

  dbg lprint {"executing command",0xa}, DEBUG
  test ecx, ecx
  jz near .done		; if they just hit enter without typing, ignore

  ;--------------------------------------------------
  ; add the command to the command history

;  push ecx			; push string length
;  add ecx, byte 3 + command_entry_size
;  and ecx, byte -4		; round length up to nearest dword
;  externfunc mem.alloc		; allocate memory for entry in command history
;  jc near .alloc_error
;
;  lea ecx, [eax - command_entry_size]
;  push edi
;  shr ecx, 2
;  add edi, byte command_entry_size
;  rep movsd			; copy the string to the command history node
;  pop edi
;
;  ;; ESI = ptr to command string
;  ;; EDI = ptr to history node
;  ;; TOS = string length
;  
;  mov eax, dword[root_command]
;  cmp eax, byte -1
;  jnz .already_have_root
;
;  mov [root_command], edi
;
;  mov dword[eax+command_entry.next], edi
;.already_have_root:
;  mov dword[edi+command_entry.prev], eax
;  mov dword[edi+command_entry.next], root_command
;  mov [root_command], edi
;  mov dword[cur_command], root_command
;  pop dword[edi+command_entry.length]	; pop the string legnth
;
;  cmp dword[last_command], byte -1
;  jnz .already_have_last
;  mov [last_command], edi
;
;.already_have_last:
;  dec byte[history_avail]
;  jnz .history_done
;
;  mov eax, [last_command]
;  mov ebx, [eax+command_entry.next]
;  mov dword[ebx+command_entry.prev], -1
;  mov [last_command], ebx
;  externfunc mem.dealloc
;  jc near .dealloc_error
;  inc byte[history_avail]
;
;.history_done:

;---------------------------------
;  create structure for process header

.create_process_struc:
  push eax
  push edi			        
  push ecx
  push esi				;ptr to args
  mov ecx, process_info_size
  externfunc mem.alloc
  mov esi, dword [proc_info]		;esi = ptr to ish's process info structure
  mov ecx, process_info_size/4   ;moving the whole struc in dwords
  mov ebx, edi
  rep movsd				;copy ish's struc to the new struct
  pop esi
  pop ecx
  pop edi
  pop eax


  ;--------------------------------------------------
  ; now parse the command

  dbg lprint {"parsing command",0xa}, DEBUG



  ;; ESI = ptr to command string

  xor ebp, ebp		; EBP will hold the arg count;
  			; we will push ptrs to the args on the stack
  call _get_token
  jc near .done		; if we can't find at least 1 token we are done
.get_args:
  inc ebp		; found first arg
  push esi		; put the args on the stack for now
  add esi, ecx		; advance ESI to end of token
  mov byte[esi], 0	; terminate token with a null
  inc esi		; advance esi to next token
  call _get_token	; get the next token
  jnc .get_args		; loop until there are none left

  ;; ESI = ptr to command string
  ;; EBP = number of args
  ;; TOS = last token found
  ;;  +4 = token before that
  ;;    ...

.got_args:
  lea ecx, [ebp*4+4]	; room for EBP pointers, and a null ptr on the end
  externfunc mem.alloc	; allocate memory for argv array
  mov dword[edi+ebp*4], 0	; put null ptr on end of argv

  mov ecx, ebp		; ECX = number of args
  lea edi, [edi+ebp*4]	; EDI = ptr to end of argv
.pop_argv:
  sub edi, byte 4
  pop dword[edi]	; pop arg into argv
  dec ecx
  jnz .pop_argv

  dbg lprint {"argv created at 0x%x",0xa}, DEBUG, edi
  push ebx		; save process info struc
  push edi		; save ptr to argv to dealloc later
  push byte -1		; in case we need to prepend /bin, push a ptr to the
  			;   memory to dealloc later, or -1

  ;; EDI = ptr to argv
  ;; EBP = argc
  ;; TOS = ptr to memory used for tempory string with '/bin' prepended, or -1
  ;;         if no memory needs to be deallocated
  ;;  +4 = ptr to argv (dealloc this after command returns)
  ;;  +8 = ptr to process info structure

  ;--------------------------------------------------
  ; check for built-in
  
  dbg lprint {"checking for built-in",0xa}, DEBUG
  
  mov esi, [edi]	; ESI = ptr to first token, the command to run
  externfunc lib.string.find_length	; ECX = length of command to run
  
.hash:
  mov edx, hash_seed
  externfunc lib.string.fasthash
  and edx, 0xf			; EDX = hash of command to run
  mov eax, [command_hash+edx*4]	; EAX = ptr to hash node of command, or -1
  cmp eax, byte -1
  je .not_builtin

.test:
  cmp ecx, [eax+hash_node.length]	; compare legnths
  jne .try_next

  lea edi, [eax+hash_node_size]	; EDI = ptr to string in hash node
  push ecx		; save command length
  rep cmpsb
  pop ecx
  jne .try_next

  ; ---=== command is a built-in, execute it and we are done ===---

  dbg lprint {"command is a built-in, executing",0xa}, DEBUG
  
  mov ecx, ebp		; ECX = argc
  mov edi, [esp+4]
; mov ebx, [proc_info]				;that was done already up there
  call [eax+hash_node.function]	; call it

  jmp .app_cleanup

.try_next:		; found a hash node but string compare failed
  mov eax, [eax+hash_node.next]	; EAX = ptr to next hash node, or -1
  cmp eax, byte -1
  jne .test

  ;--------------------------------------------------
  ; not a built-in, execute the command

  ;; EBP = argc
  ;; ECX = length of command
  ;; TOS = ptr to memory used for tempory string with '/bin' prepended, or -1
  ;;         if no memory needs to be deallocated
  ;;  +4 = ptr to argv (dealloc this after command returns)
  ;;  +8 = ptr to process info structure

.not_builtin:

  dbg lprint {"command is not built-in",0xa}, DEBUG

  mov edi, [esp+4]	; EDI = ptr to argv
  mov esi, [edi]	; ESI = ptr to command, single null terminated

  ; prepend a '/bin/' to the command if it doesn't start with '/'
  cmp byte[esi], '/'
  je .exec_command

  dbg lprint {"prepending /bin/",0xa}, DEBUG
  inc ecx	; length now includes the null
  push ecx
  add ecx, [prepend_length]
  externfunc mem.alloc
  mov [esp+4], edi
  
  push esi
  mov ecx, [prepend_length]
  mov esi, [prepend_str]
  rep movsb		; copy the prepend string
  
  pop esi
  pop ecx
  rep movsb	; there is a null because we inced ecx above

  mov esi, [esp]	; ESI = ptr to tempoary command string, single null
  mov edi, [esp+4]	; EDI = ptr to argv
 
  
.exec_command:
  
  ;; ESI = ptr to command, single null terminated
  ;; EDI = ptr to argv
  ;; EBP = argc
  ;; TOS = ptr to memory used for tempory string with '/bin' prepended, or -1
  ;;         if no memory needs to be deallocated
  ;;  +4 = ptr to argv (to be dealloced)
  ;;  +8 = ptr to process info structure

  mov ecx, ebp	; ECX = argc
  mov ebx, [esp + 8]
  mov eax, _child_proc_callback
  externfunc process.create
  jnc .app_return

  ;; TOS = ptr to tempoary command string, or -1
  ;;  +4 = ptr to argv
  
  push eax	; save error from process.create
  mov esi, could_not_exec
  call _print_dalign

  mov esi, [esp+8]
  mov esi, [esi]	; ESI = ptr to command used to run program
  call _print
  
  mov esi, error_str
  call _print_dalign
  
  pop edx		; restore process.create error code
  call _print_dec
  call _nl
  
  jmp short .app_cleanup

.app_return:
  externfunc thread.sleep_self

.app_cleanup:
  ;; TOS = ptr to tempoary command string, or -1
  ;;  +4 = ptr to argv
  ;;  +8 = ptr to process info struc
  pop eax
  cmp eax, byte -1
  jz .no_temp_string
  externfunc mem.dealloc	; dealloc the temporary string with '/bin' prepended
.no_temp_string:
  pop eax			;
  externfunc mem.dealloc	; dealloc argv

.app_cleanup_process_info_struc:
  pop edx					;pop ptr to process info
  mov eax, dword [proc_info]			;eax = ish's process info
  mov ebx, [edx + process_info.stdout]		;ebx = app stdout
  cmp ebx, [eax + process_info.stdout]		;if ebx != ish stdout close file
  jne short .app_cleanup_stdin
  mov ebp, [ebx]				;ebp = file op table
  call [ebp + file_op_table.close]		;close file
.app_cleanup_stdin:
  mov ebx, [edx + process_info.stdin]		;ebx = app stdin
  cmp ebx, [eax + process_info.stdin]		;if ebx != ish stdin close file
  jne short .app_cleanup_stderr
  mov ebp, [ebx]				;ebp = file op table
  call [ebp + file_op_table.close]		;close file
.app_cleanup_stderr:
  mov ebx, [edx + process_info.stderr]		;ebx = app stderr
  cmp ebx, [eax + process_info.stderr]		;if ebx != ish stderr close file
  jne short .app_cleanup_process
  mov ebp, [ebx]				;ebp = file op table
  call [ebp + file_op_table.close]		;close file
.app_cleanup_process:
  mov eax, edx					;eax = app process info struc
  externfunc mem.dealloc			;deallocate struc

  ;; stack is now clear
  ;; nothing usefull in the registers

.done:

  jmp read_line

;.alloc_error:
;  push eax
;  mov esi, alloc_err_str
;  call _print_dalign
;  pop edx
;  call _print_dec
;  call _nl
;  jmp short .done
;
;.dealloc_error:
;  push eax
;  mov esi, dealloc_err_str
;  call _print_dalign
;  pop edx
;  call _print_dec
;  call _nl
;  jmp short .done

;                                           -----------------------------------
;                                                                    _get_token
;==============================================================================

_get_token:
;; scans a string for the next token.
;;
;; parameters:
;; -----------
;; ESI = ptr to string
;;
;; returned values:
;; ----------------
;; registers saved as usual
;;
;; CF = 0: token found
;;   ESI = ptr to token found
;;   ECX = legnth of token
;;
;; CF = 1: no more tokens
;;   ESI = ptr to the null on the string
;;   ECX = 0

  xor ecx, ecx
  
  dec esi
.eat_whitespace:
  inc esi
  cmp byte[esi], ' '
  je .eat_whitespace

  ; ESI = ptr to first char of token
  cmp byte[esi], 0
  je .no_more_tokens
  
  cmp byte[esi], ">"
  je .redirection_stdout
  
  dec ecx
.find_end:
  inc ecx
  cmp byte[esi+ecx], ' '
  je .found_end
  cmp byte[esi+ecx], ">"
  je .redirection_stdout
  cmp byte[esi+ecx], 0
  jne .find_end

.found_end:
dbg lprint {"found token",0xa}, DEBUG
clc
  ; CF already clear from above
  retn

.no_more_tokens:
dbg lprint {"no more tokens",0xa}, DEBUG
  stc
  retn

.redirection_stdout:
  inc esi
  cmp [esi], byte ' '
  jz short .redirection_stdout
  pushad
  externfunc vfs.open
  mov [esp + 24], ebx
  popad
  jnc short .set_process_info_stdout
  lprint {"Couldn't open redirection for filename: %s.",0x0A}, WARNING, esi
  jmp short .redirection_stdout_fix_esi
.set_process_info_stdout:
  mov dword [ebx + process_info.stdout], ecx
  dec esi
.redirection_stdout_fix_esi:
  inc esi
  cmp byte [esi], 0
  jne .redirection_stdout_fix_esi
  xor ecx, ecx
  stc
  retn

;                                           -----------------------------------
;                                                            _print and friends
;==============================================================================

_print:
  ; ESI = ptr to string
  pushad
  externfunc lib.string.find_length
  mov ebx, [stdout]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  popad
  retn

_print_dalign:
  ; ESI = ptr to dword-aligned string
  pushad
  externfunc lib.string.find_length_dword_aligned
  mov ebx, [stdout]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  popad
  retn

_print_length:
  ; ESI = ptr to string
  ; ECX = length
  push ebx
  push ebp
  mov ebx, [stdout]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  pop ebp
  pop ebx
  retn

_print_char:	; prints al
  pushad
  lea esi, [esp+28]
  xor ecx, ecx
  mov ebx, [stdout]
  mov ebp, [ebx]
  inc ecx
  call [ebp+file_op_table.write]
  popad
  retn

_print_dec:
  pushad
  
  add esp, byte 10
  mov edi, esp
  externfunc lib.string.dword_to_decimal_no_pad
  mov esi, edi
  call _print_length
  sub esp, byte 10

  popad
  retn

_print_hex:	; prints EDX, destroys nothing
  pushad
  
  mov ecx, 8
  add esp, byte 10
  lea edi, [esp+2]
  mov word[esp], "0x"
  externfunc lib.string.dword_to_hex
  sub edi, byte 2
  add ecx, byte 2
  mov esi, edi
  call _print_length
  sub esp, ecx

  popad

  retn

;                                           -----------------------------------
;                                                                 _print_prompt
;==============================================================================

_print_prompt:
  pushad
  mov ebx, [stdout]
  mov ebp, [ebx]
  mov esi, [prompt_str]
.do_segment:
  xor ecx, ecx
.find_length:
  mov al, [esi+ecx]
  test al, al
  jz near .done
  cmp al, '\'
  je .escaped
  inc ecx
  jmp .find_length

.escaped:
  call _print_length
  lea esi, [esi+ecx+1]
  
  ; esi = ptr to escaped letter
  push esi
  mov al, [esi]
  cmp al, 'h'
  je .hostname
  cmp al, 's'
  je .shell_name
  cmp al, 't'
  je .time
  cmp al, 'v'
  je .version
  cmp al, 'w'
  je .pwd
  cmp al, '\'
  je .backslash

.esc_done:
  pop esi
  inc esi
  jmp short .do_segment

.hostname:
  mov esi, hostname
  externfunc lib.string.find_length_dword_aligned
  call [ebp+file_op_table.write]
  jmp short .esc_done

.shell_name:
  mov esi, [shell_name]
  externfunc lib.string.find_length
  call [ebp+file_op_table.write]
  jmp short .esc_done

.time:
  call _print_time
  jmp short .esc_done

.version:
  mov esi, version_str
  externfunc lib.string.find_length_dword_aligned
  call [ebp+file_op_table.write]
  jmp short .esc_done

.pwd:
  externfunc process.get_wd
  externfunc lib.string.find_length_dword_aligned
  call [ebp+file_op_table.write]
  jmp short .esc_done

.backslash:
  mov al, '\'
  externfunc lib.string.print_char
  jmp short .esc_done

.done:
  test ecx, ecx
  jz .zero
  call [ebp+file_op_table.write]
.zero:
  call _save_cursor
  popad
  retn

;                                           -----------------------------------
;                                                                   _print_date
;==============================================================================

_print_date:
;; parameters:
;; -----------
;; EBX = file to print to
;; EBP = op table of file
;;
;; returned values:
;; ----------------
;; EAX = destroyed
;; all other registers = unmodified

  mov al, '2'
  externfunc lib.string.print_char
  mov al, '0'
  externfunc lib.string.print_char

  mov al,09h
  out 70h,al
  xor eax, eax
  in al,71h

  ror eax, 4
  or al, '0'
  externfunc lib.string.print_char
  shr eax, 28
  or al, '0'
  externfunc lib.string.print_char

  mov al, '-'
  externfunc lib.string.print_char
  
  mov al,08h
  out 70h,al
  xor eax, eax
  in al,71h

  ror eax, 4
  or al, '0'
  externfunc lib.string.print_char
  shr eax, 28
  or al, '0'
  externfunc lib.string.print_char
  
  mov al, '-'
  externfunc lib.string.print_char
  
  mov al,07h
  out 70h,al
  xor eax, eax
  in al,71h

  ror eax, 4
  or al, '0'
  externfunc lib.string.print_char
  shr eax, 28
  or al, '0'
  externfunc lib.string.print_char

  retn

;                                           -----------------------------------
;                                                                   _print_time
;==============================================================================

_print_time:
;; parameters:
;; -----------
;; EBX = file to print to
;; EBP = op table of file
;;
;; returned values:
;; ----------------
;; EAX = destroyed
;; all other registers = unmodified

  mov al, 0x04 
  out 0x70, al
  xor eax, eax
  in al, 0x71

  ror eax, 4
  or al, '0'
  externfunc lib.string.print_char
  shr eax, 28
  or al, '0'
  externfunc lib.string.print_char
  
  mov al, ':'
  externfunc lib.string.print_char

  mov al, 0x02
  out 0x70, al
  xor eax, eax
  in al, 0x71

  ror eax, 4
  or al, '0'
  externfunc lib.string.print_char
  shr eax, 28
  or al, '0'
  externfunc lib.string.print_char
  
  mov al, ':'
  externfunc lib.string.print_char

  xor eax, eax
  out 0x70, al
  xor eax, eax
  in al, 0x71

  ror eax, 4
  or al, '0'
  externfunc lib.string.print_char
  shr eax, 28
  or al, '0'
  externfunc lib.string.print_char

  retn

;                                           -----------------------------------
;                                                                           _nl
;==============================================================================

_nl:	; prints a newline
  pushad
  mov esi, nl_str
  mov ecx, nl_len
  mov ebx, [stdout]
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  popad
  retn

;                                           -----------------------------------
;                                                                   _clear_line
;==============================================================================

_clear_line:	; clears the current input line; destroys no registers
  pushad
  call _restore_cursor
  mov esi, line_clear_str
  mov ecx, line_clear_len
  call _print_length
  popad
  retn

;                                           -----------------------------------
;                                                           save/restore cursor
;==============================================================================

_save_cursor:
  push esi
  push ecx
  mov esi, save_cur_str
  mov ecx, save_cur_len
  call _print_length
  pop ecx
  pop esi
  retn

_restore_cursor:
  push esi
  push ecx
  mov esi, res_cur_str
  mov ecx, res_cur_len
  call _print_length
  pop ecx
  pop esi
  retn

;                                           -----------------------------------
;                                                             internal commands
;==============================================================================


; --- cd ---
_cd:
  cmp ecx, byte 2
  jne .print_help

  mov esi, [edi+4]
  externfunc process.set_wd
  jc .retn
  xor eax, eax
.retn:
  retn

.print_help:
  xor eax, eax
  dec eax
  retn


; --- help ---
_help:
  mov esi, help_msg
  call _print_dalign
  xor eax, eax
  retn


; --- clear ---
_clear:
  mov ebx, [stdout]
  mov ebp, [ebx]
  mov esi, term_clear_str
  mov ecx, term_clear_len
  call [ebp+file_op_table.write]
  xor eax, eax
  retn


; --- logout ---
_logout:
  inc byte[quit]
  xor eax, eax
  retn


; --- about ---
_about:
  mov esi, about_msg
  call _print
  xor eax, eax
  retn


; --- fasthash ---
_fasthash:
  dec ecx
  jnz .hash

  mov esi, fasthash_help_str
  call _print
  xor eax, eax
  dec eax
  retn

.hash:
  add edi, byte 4
  mov esi, [edi]
  push edi
  push esi
  call _print
  mov esi, fasthash_delimeter
  call _print
  pop esi
  
  push ecx
  externfunc lib.string.find_length
 
  mov edx, hash_seed
  externfunc lib.string.fasthash
  call _print_hex
  pop ecx
  call _nl
  dec ecx
  pop edi
  jnz .hash

  xor eax, eax
  retn

[section .data]
fasthash_delimeter: db ": ",0
fasthash_help_str:
db "Usage: fasthash [STRING]...",0xa
db "Compute the fasthash of STRING(s)",0xa,0
__SECT__


; --- echo ---
_echo:
  dbg lprint {"argv found at 0x%x",0xa}, DEBUG, edi
  dec ecx
  jz .done
  jmp short .print_arg

.next_arg:
  mov esi, echo_delimiter
  push ecx
  mov ecx, 1
  call _print_length
  pop ecx
  jmp short .print_arg

.print_arg:
  add edi, byte 4
  mov esi, [edi]
  call _print
  dec ecx
  jnz .next_arg

.done:
  call _nl
  xor eax, eax
  retn

[section .data]
echo_delimiter: db ' '
__SECT__


; --- export ---
_export:
  mov edx, [env]
  cmp ecx, byte 1
  ja .set

  mov ebx, [stdout]
  mov ebp, [ebx]

  mov esi, [edx]
  test esi, esi
  jz .no_err_retn
.print:
  externfunc lib.string.find_length
  call [ebp+file_op_table.write]

  mov esi, nl_str
  mov ecx, nl_len
  call [ebp+file_op_table.write]
  
  add edx, byte 4
  mov esi, [edx]
  test esi, esi
  jnz .print

.no_err_retn:
  xor eax, eax
.retn:
  retn

.set:
  cmp ecx, byte 2
  ja .show_usage
  mov esi, [edi+4]
  cmp byte[esi], '-'
  jz .show_usage
  ; make a copy because the string won't be there for long
  externfunc lib.string.find_length
  externfunc mem.alloc
  mov ecx, eax
  rep movsb
  sub edi, eax

  ; now set it
  mov esi, edi
  externfunc lib.env.set
  jc .retn
  mov [env], edx
  xor eax, eax
  retn

.show_usage:
  mov ebx, [stderr]
  mov ecx, .usage_len
  mov esi, .usage_str
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  mov eax, __ERROR_INVALID_PARAMETERS__
  retn

[section .data]
.usage_str:
db 'Usage: export [VAR=[VALUE]]',0xa
db 'Set the value of the environment variable VAR to VALUE, or display the',0xa
db 'environment with no args.',0xa
.usage_len: equ $-.usage_str
__SECT__


; --- pwd ---
_pwd:
  externfunc process.get_wd
  call _print
  call _nl
  xor eax, eax
  retn


; --- info ---
_info:
  mov esi, version_info
  call _print_dalign
  call _nl
  xor eax, eax
  retn


; --- date ---
_date:
  mov ebx, [stdout]
  mov ebp, [ebx]
  call _print_date
  mov al, ' '
  externfunc lib.string.print_char
  call _print_time
  call _nl
  xor eax, eax
  retn


; --- prompt ---
_prompt:
  mov eax, [prompt_str]
  cmp eax, default_prompt
  je .no_dealloc

  dbg lprint {"deallocing old prompt",0xa}, DEBUG
  externfunc mem.dealloc	; free up old prompt
  jc .dealloc_error
.no_dealloc:
  dec ecx
  jz .restore_default
  dec ecx
  jnz .show_help
  mov esi, [edi+4]
  cmp word[esi], '-h'
  je .show_help
  externfunc lib.string.find_length
  push ecx
  add ecx, byte 2
  externfunc mem.alloc
  pop ecx
  jc .alloc_error
  mov [prompt_str], edi
  rep movsb
  mov word[edi], 0x0020
  xor eax, eax
  retn

.restore_default:
  mov dword[prompt_str], default_prompt
  xor eax, eax
  retn

.dealloc_error:
  push eax
  mov esi, dealloc_err_str
  call _print_dalign
  mov edx, [esp]
  call _print_dec
  call _nl
  pop eax
  retn

.alloc_error:
  push eax
  mov esi, alloc_err_str
  call _print_dalign
  mov edx, [eax]
  call _print_dec
  call _nl
  pop eax
  retn

.show_help:
  mov esi, prompt_help_str
  call _print
  xor eax, eax
  dec eax
  retn

[section .data]
prompt_help_str:
db "Usage: prompt STRING",0xa
db "Set the ish prompt string to STRING.",0xa
db 0xa
db "The following escaped charecters may be used:",0xa
db "  \h  the hostname up to the first '.' (just 'uuu' for now)",0xa
db "  \s  name of the shell (always 'ish' for now)",0xa
db "  \t  time in 24 hour HH:MM:SS format",0xa
db "  \v  the version of ish (e.g., 1.9)",0xa
db "  \w  current working directory",0xa
db "  \\  a backslash",0xa,0
__SECT__


; --- show ---
_show:
  cmp ecx, byte 2
  jnz .error
  mov edx, [env]
  mov esi, [edi+4]
  cmp byte[esi], '-'
  jz .error
  externfunc lib.string.find_length
  externfunc lib.env.get
  jc .retn
  mov esi, [edx+eax]	; ESI now points to "var=value",0 string
  lea esi, [esi+ecx+1]	; ESI now points to "value",0
  call _print
  call _nl
  xor eax, eax
.retn:
  retn

.error:
  mov ebx, [stderr]
  mov ecx, .usage_len
  mov esi, .usage_str
  mov ebp, [ebx]
  call [ebp+file_op_table.write]
  mov eax, __ERROR_INVALID_PARAMETERS__
  retn

[section .data]
.usage_str:
db 'Usage: show VAR',0xa
db 'Print the value of the environment variable VAR to stdout.',0xa
.usage_len: equ $-.usage_str
__SECT__

;                                           -----------------------------------
;                                                          _child_proc_callback
;==============================================================================

_child_proc_callback:
;; called when a child process completes
;; EAX = return status of process
;; EBX = process ID of child process (now terminated)
  test eax, eax		; check return value of app
  jz .done

  push eax
  mov esi, app_error_str
  call _print_dalign
  pop edx
  call _print_dec
  call _nl
  
.done:
  mov eax, [thread_self]
  externfunc thread.wake	; good morning swetie
  retn

;                                           -----------------------------------
;                                                              _read_input_line
;==============================================================================

_read_input_line:
;; Reads a line (terminated with 0xa) from a file into an already allocated
;; buffer. No null is put on the end of the string; the 0xa is also put into
;; the buffer.
;;
;; This particular read_line flavor checks for backspaces and backs up in the
;; buffer if it finds one.
;;
;; parameters:
;; -----------
;; EBX = file to read from
;; ECX = max buffer size; if this many bytes are read with no 0xa found, the
;;         call returns.
;; EDI = ptr to buffer to read to
;;
;; returned values:
;; ----------------
;; ECX = number of bytes read
;; registers and errors as usual

  pushad
  push byte 0	; number of chars after cursor
  
  mov ebp, [ebx+file_descriptor.op_table]
  mov edx, ecx
  xor ecx, ecx
  xor esi, esi	; esi will track how many bytes we have read
  inc ecx

  ;; EDX = ECX from call
  ;; ESI = 0
  ;; ECX = 1
  ;; EBX = file pointer
  ;; EBP = op table

.get_char:
  externfunc lib.string.get_char
  jc .retn

  test al, 0xE0
  jz .control_char

.echo_char:
  call .print_char	; echo to display
  push esi
  mov esi, edi
  mov ecx, [esp+4]
  test ecx, ecx
  jz .no_trailing_chars
  call _print_length
  push eax
  mov eax, ecx
  externfunc lib.term.cursor_back
.shift_buffer:
  mov al, [esi+ecx-1]
  mov [esi+ecx], al
  dec ecx
  jnz .shift_buffer
  pop eax
.no_trailing_chars:
  inc ecx	; set ecx back to 1
  pop esi
  mov [edi], al

  inc edi
  inc esi

  cmp esi, edx
  je .retn

  cmp al, 0xa
  jne .get_char

.retn:
  mov [esp+28], esi	; put esi in ecx on return

.quick_retn:
  pop eax
  popad
  retn

.control_char:
  movzx eax, al
  jmp [.control_char_handlers+eax*4]

[section .data]
.control_char_handlers:
  dd .get_char	; 0x00    NUL null
  dd .get_char	; 0x01 ^A SOH start heading
  dd .get_char	; 0x02 ^B STX start of text
  dd .get_char	; 0x03 ^C ETX end of text
  dd .eot	; 0x04 ^D EOT end transmit
  dd .get_char	; 0x05 ^E ENQ enquiry
  dd .get_char	; 0x06 ^F ACK acknowledge
  dd .bel	; 0x07 ^G BEL beep
  dd .bs	; 0x08 ^H BS  back space
  dd .ht	; 0x09 ^I HT  horizontal tab
  dd .lf	; 0x0A ^J LF  line feed
  dd .get_char	; 0x0B ^K VT  vertical tab
  dd .ff	; 0x0C ^L FF  form feed
  dd .cr	; 0x0D ^M CR  carriage ret.
  dd .get_char	; 0x0E ^N SO  shift out
  dd .get_char	; 0x0F ^O SI  shift in
  dd .get_char	; 0x10 ^P DLE device link esc
  dd .get_char	; 0x11 ^Q DC1 dev cont 1 X-ON
  dd .get_char	; 0x12 ^R DC2 dev control 2
  dd .get_char	; 0x13 ^S DC3 dev cont 3 X-OFF
  dd .get_char	; 0x14 ^T DC4 dev control 4
  dd .nak	; 0x15 ^U NAK negative ack
  dd .get_char	; 0x16 ^V SYN synchronous idle
  dd .get_char	; 0x17 ^W ETB end trans block
  dd .get_char	; 0x18 ^X CAN cancel
  dd .get_char	; 0x19 ^Y EM  end medium
  dd .get_char	; 0x1A ^Z SUB substitute
  dd .esc	; 0x1B ^[ ESC escape
  dd .right	; 0x1C ^/ FS  cursor right
  dd .left	; 0x1D ^] GS  cursor left
  dd .get_char;.up	; 0x1E ^^ RS  cursor up
  dd .get_char;.down	; 0x1F ^_ US  cursor down
__SECT__

.cr:
.lf:
  add edi, [esp]
  mov dword[esp], 0
  mov al, 0xa
  jmp short .echo_char

.ff:
  pushad
  call _clear
  call _print_prompt
  popad
  jmp short .get_char

.bel:
.ht:
  mov al, 0x7
  call .print_char
  jmp .get_char

.eot:
  test esi, esi
  jnz .get_char

  ; type exit for the user
  mov dword[edi], "exit"
  mov byte[edi+4], 0xa
  
  mov esi, edi
  mov ecx, 5
  call [ebp+file_op_table.write]
  mov [esp+28], ecx
  jmp short .quick_retn

.esc:
  externfunc lib.string.get_char
  cmp al, '['
  jne .get_char
  externfunc lib.string.get_char
;  cmp al, 'A'
;  je near .up
;  cmp al, 'B'
;  je near .down
  cmp al, 'D'
  je near .left
  cmp al, 'C'
  je near .right
  cmp al, '4'
  je near .possible_home
  jmp .get_char

.bs:
  cmp esi, [esp]
  jz .get_char		; don't backspace further than the beginning of the buf

  call .print_char
  
  mov ecx, [esp]
  test ecx, ecx
  jz .bs_no_trailing_chars
  
  push esi
  push edi
  mov esi, edi

  ; print the trailing chars
  call _print_length

  ; print a space over where the last char was
  mov al, ' '
  push ecx
  xor ecx, ecx
  inc ecx
  call .print_char
  pop ecx

  ; move the cursor back
  lea eax, [ecx+1]
  externfunc lib.term.cursor_back
  
  ; shift the buffer back
  dec edi
  rep movsb

  pop edi
  pop esi
.bs_no_trailing_chars:
  inc ecx	; set ecx back to 1

  dec esi
  dec edi
  jmp .get_char

.nak:
  call _clear_line
  sub edi, esi
  xor esi, esi
  mov [esp], esi
  jmp .get_char

;.up:
;  mov eax, [cur_command]
;  mov eax, [eax+command_entry.prev]
;  
;  cmp eax, byte -1
;  je .get_char	; do nothing if there is no previous command
;
;  call _clear_line
;  
;  sub edi, esi	; move edi back to begining of buffer
;  
;  jmp short .command_to_buffer
;  
;.down:
;  mov eax, [cur_command]
;  mov eax, [eax+command_entry.next]
;
;  call _clear_line
;  sub edi, esi
;  
;  cmp eax, byte -1
;  je .get_char

.left:
  cmp dword[esp], esi
  je .get_char
  inc dword[esp]
  dec edi
  push esi
  push ecx
  mov esi, cur_left_str
  mov ecx, cur_left_len
  call _print_length
  pop ecx
  pop esi
  jmp .get_char

.right:
  cmp dword[esp], byte 0
  jz .get_char
  dec dword[esp]
  inc edi
  push esi
  push ecx
  mov esi, cur_right_str
  mov ecx, cur_right_len
  call _print_length
  pop ecx
  pop esi
  jmp .get_char

;.command_to_buffer:
;  mov [cur_command], eax
;  mov ecx, [eax+command_entry.length]
;  lea esi, [eax+command_entry_size]
;  call _print_length	; echo the command
;  rep movsb
;  inc ecx	; set ecx back to 1
;  mov esi, [eax+command_entry.length]
;  jmp .get_char

.possible_home:
  externfunc lib.string.get_char
  cmp al, '~'
  jne .get_char
  call _restore_cursor
  sub edi, esi
  add edi, [esp]
  mov [esp], esi
  jmp .get_char

.print_char:	; prints al
  push esi
  push eax
  mov esi, esp
  call [ebp+file_op_table.write]
  pop eax
  pop esi
  retn

;                                           -----------------------------------
;                                                                  section .bss
;==============================================================================

section .bss

align 4, db 0
stdout:		resd 1
stdin:		resd 1
stderr:		resd 1
env:		resd 1		; ptr to our environment
exec_me:	resd 1
proc_info:	resd 1
cur_dir:	resd 1		; ptr to string of current dir
shell_name:	resd 1		; ptr to string of name shell was invoked as
thread_self:	resd 1		; own thread ID

command_buf:	resb command_buff_size+4	; leave 4 nulls on the end

quit:		resb 1		; inced when it's time to quit
proc_returned:	resb 1		; inced when a child process completes

;                                           -----------------------------------
;                                                                 section .data
;==============================================================================

section .data
align 4, db 0

; dword aligned strings

hostname:	dstring 0x1b,'[31;1m','uuu',0x1b,'[37;0m'
could_not_exec:	dstring "ish: could not execute: "
error_str:	dstring " -- error "
version_info:	dstring '$Id: ish.asm,v 1.3 2002/01/21 06:17:25 instinc Exp $'
version_str:	dstring "$Revision: 1.3 $"
dealloc_err_str:dstring "ish: mem.dealloc returned error: "
alloc_err_str:	dstring "ish: mem.alloc returned error: "
app_error_str:	dstring "ish: app returned error: "

help_msg:
db "built-in commands:",0x0a
db "  about    read a little blurb on the Uuu project",0x0a
db "  clear    clear the screen",0x0a
db "  date     prints date/time information as YYYY-MM-DD HH:MM:SS",0x0a
db "  echo     prints it's args",0x0a
db "  exit     exits the shell; same as logout",0x0a
db "  export   sets environment variables",0x0a
db "  fasthash calculate the fasthash of a string",0x0a
db "  help     this message",0x0a
db "  info     display an info blob about the shell",0xa
db "  logout   exit the shell",0xa
db "  prompt   change the prompt",0xa
db "  pwd      prints the current working directory",0x0a
db "  show     show the value of environment variables",0x0a
db 0xa
db "if a command that is not a built-in command is entered ish will attempt to run",0xa
db "the program of that name in the /bin directory.",0xa,0
align 4, db 0

about_msg:
db 0xa
db "  Uuu homepage: http://uuu.sf.net/",0xa
db 0xa
db "  Coders:",0xa
db "    Dave Poirier",0xa
db "    Phil Frost <daboy@xgs.dhs.org>",0xa
db "    Rick Fillion <rick@rhix.dhs.org>",0xa
db 0xa
db "Uuu is distributed under the BSD license. If you don't know what that is,",0xa
db "you are lame. Or you could read the file 'license' that came with Uuu :P",0xa
db 0xa
db 'For help with the shell, see "help".',0xa,0
align 4, db 0

; misc. dword data
prompt_str:	dd default_prompt
prepend_str:	dd prepend_str_str	; string to prepend to non-absloute commands
prepend_length:	dd 5			; length of prepend_str

cur_command:	dd root_command
last_command:	dd -1			; last command in the history chain
root_command:	dd -1
		dd -1
		dd 0

; built-in command hashtable

command_hash:	dd .prompt	; 0
		dd -1		; 1
		dd .help	; 2	.pwd
		dd .clear	; 3	.exit
		dd .cd		; 4
		dd -1		; 5
		dd .export	; 6
		dd .echo	; 7
		dd .info	; 8
		dd -1		; 9
		dd -1		; A
		dd .logout	; B	.about
		dd .fasthash	; C
		dd -1		; D
		dd .date	; E
		dd .show	; F

;.command	dd next_in_chain, length_of_command, function_to_call
;		db 'command'

align 4, db 0
.show:		dd -1, 4, _show
		db 'show'
align 4, db 0
.export:	dd -1, 6, _export
		db 'export'
align 4, db 0
.cd:		dd -1, 2, _cd
		db 'cd'
align 4, db 0
.prompt:	dd -1, 6, _prompt
		db 'prompt'
align 4, db 0
.date:		dd -1, 4, _date
		db 'date'
align 4, db 0
.info:		dd -1, 4, _info
		db 'info'
align 4, db 0
.pwd:		dd -1, 3, _pwd
		db 'pwd'
align 4, db 0
.exit:		dd -1, 4, _logout
		db 'exit'
align 4, db 0
.echo:		dd -1, 4, _echo
		db 'echo'
align 4, db 0
.help:		dd .pwd, 4, _help
		db 'help'
align 4, db 0
.clear:		dd .exit, 5, _clear
		db 'clear'
align 4, db 0
.logout:	dd .about, 6, _logout
		db 'logout'
align 4, db 0
.about:		dd -1, 5, _about
		db 'about'
align 4, db 0
.fasthash:	dd -1, 8, _fasthash
		db 'fasthash'

; unaligned strings

term_clear_str:	db 0x1b, '[2J'
term_clear_len:	equ $-term_clear_str
nl_str:		db 0xa
nl_len:		equ $-nl_str
line_clear_str:	db 0x1b, '[K'
line_clear_len:	equ $-line_clear_str
cur_left_str:	db 0x1b, '[',1,'D'
cur_left_len:	equ $-cur_left_str
cur_right_str:	db 0x1b, '[',1,'C'
cur_right_len:	equ $-cur_right_str
save_cur_str:	db 0x1b, '[s'
save_cur_len:	equ $-save_cur_str
res_cur_str:	db 0x1b, '[u'
res_cur_len:	equ $-res_cur_str
default_prompt:	db '\h:\w$ ',0	;   see prepend_length above
prepend_str_str:db '/bin/'

; misc. byte data

history_avail:	db history_max+1; number of items availible
