;; $Header: /cvsroot/uuu/dimension/system/frustration/osw.asm,v 1.4 2009/05/20 00:40:41 instinc Exp $
;; 
;; FRuSTRaTiON OS-Wrapper, for Unununium Core revision 2
;;

[bits 32]
section .bss
resb 1024

section .text

;                                           -----------------------------------
;                                                                 configuration
;==============================================================================

;; amount of memory to use, TODO: if undefined auto-detect
%assign _ASSUME_MEMORY_ 4	; in MiB

;; the shell to start; undefined to run no shell
%define _SHELL_ "/bin/ish"


;; device to mount as root after core init; undef to mount nothing
%define _ROOT_DEVICE_ "/dev/fd/0"


;; how many terminal will be created (only if a shell is being run)

%define _TERMINAL_COUNT_ 4


;; enable debugging (this doesn't do anything, does it? :P )

;%define _DEBUG_


;; enable a utility that will check between each cell init to see if the
;; registers have been corrupted. To use it _SHELL_ should be undefined.

;%define _REG_CORRUPTION_CHECK_


;; trace the contents of the registers between the init of each cell

;%define _REG_TRACING_


;; define the little info splert that is printed at init

%define _DISTRO_INFO_ "FRuSTRaTiON CVS $Name:  $"

;                                           -----------------------------------
;                                                                      includes
;==============================================================================


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc print_file
  .fd:		resb file_descriptor_size
  .width:	resd 1	; width of the display, in bytes
  .size:	resd 1	; size of the console, in bytes
  .cur:		resd 1	; cursor pos, within video memory
endstruc

struc buf_file
  .fd:		resb file_descriptor_size
  .buf:		resd 1	; ptr to current buffer
  .size:	resd 1	; size of current buffer
  .cur:		resd 1	; current location within buffer
endstruc

;                                           -----------------------------------
;                                                               OSW Entry Point
;==============================================================================
global _start
_start:
;  cmp eax, 0x2BADB002	; multiboot loader sets eax=0x2BADB002
;  jz short $

  ;- Blank the screen and set a blue status bar
  mov edi, 0xB8000
  xor eax, eax
  mov ecx, (80*50*2)/4
  repz stosd

  ;- Masking all irq
  mov al, 0xFF	; irq mask
  out 0x21, al	; master pic
  out 0xA1, al	; slave pic


;\/--------------[ NEW INIT SEQUENCE ]-------------\/

 ;- Initialize starting registers
 extern 	__INIT_SEQUENCE_LOCATION__
 mov	esi, 	__INIT_SEQUENCE_LOCATION__
 xor	ebx, 	ebx		; set process header = 0


 push	dword 	[esi + 12]	; number of .c_init calls
 push	dword 	[esi + 8]	; number of zeroize
 push	dword 	[esi + 4]	; number of .c_onetime_init calls
 mov	edx, 	[esi]		; number of moves
 add	esi, 	16		; go past init struc, and hit the move struc
osw_move_cells:			;
 dec	edx			; check if there is an operation to perform
 js	short 	.completed	; in case there isn't, done that part
 push	esi			; backup pointer to start of move operation
 mov	al, 'M'
 call	display_init_status
 mov	ecx, dword [esi + 10]	; get length to move (in dword)
 mov	edi, dword [esi + 6]	; set destination of the block
 mov	esi, dword [esi + 2]	; get block origin
 rep	movsd			; move it
 pop	esi			; restore pointer to start of move operation
 add	esi, byte 14		; advance pointer to next op
 jmp	short	osw_move_cells	;
.completed:			;
				;
				; perform calls phase 1 operations
				;---------------------------------
 pop	ecx			; restore number of .c_onetime_init calls
 jecxz	osw_call1_cells.completed
osw_call1_cells:		;
 pushad				; backup all regs, they will be destroyed
 mov	al, 'O'
 call	display_init_status
 mov	eax, [esi + 2]   	; destination to call
 movzx	ecx, byte [esi + 10]	; number of arguments
 mov	esi, [esi + 6]		; ptr to parameter array
 call	eax			; call cell .c_onetime_init
 popad				; restore all regs, cell doesn't have to do it
 add	esi, byte 11		; move to next entry
 dec	ecx			; optimize for speed, don't use loop :P
 jnz	short osw_call1_cells	;
.completed:			;
				;
				; perform zeroize operations
				;---------------------------
 pop	edx			; restore the number of zeroize op to do
osw_zero_bss:			;
 dec	edx			; check if there's an op to perform
 js	short .completed	; in case not, we are done
 mov	al, 'Z'
 call	display_init_status
 mov	edi, dword [esi + 2]	; offset to start zeroizing
 mov	ecx, dword [esi + 6]	; number of dword to zeroize
 xor	eax, eax		; zeroizer value = 0
 rep	stosd			; zeroize that section
 add	esi, byte 10		; move to next op
 jmp	osw_zero_bss		; continue zeroizing
.completed:			;

  ;- set up lanthane to use some fake ttyish files we provide
  mov eax,	__SYSLOG_TYPE_DEBUG__
  mov ebx,	print_fd
  externfunc	sys_log.set_echo_file
  mov eax,	__SYSLOG_TYPE_INFO__
  externfunc	sys_log.set_echo_file
  mov eax,	__SYSLOG_TYPE_LOADINFO__
  externfunc	sys_log.set_echo_file
  mov eax,	__SYSLOG_TYPE_WARNING__
  externfunc	sys_log.set_echo_file
  mov eax,	__SYSLOG_TYPE_FATALERR__
  externfunc	sys_log.set_echo_file

  mov eax,	__SYSLOG_TYPE_DEBUG__
  mov ebx,	buf_fd
  externfunc	sys_log.set_print_file
  mov eax,	__SYSLOG_TYPE_INFO__
  externfunc	sys_log.set_print_file
  mov eax,	__SYSLOG_TYPE_LOADINFO__
  externfunc	sys_log.set_print_file
  mov eax,	__SYSLOG_TYPE_WARNING__
  externfunc 	sys_log.set_print_file
  mov eax,	__SYSLOG_TYPE_FATALERR__
  externfunc	sys_log.set_print_file

  ; gives some memory to the memory manager
  extern	__END_OF_EXPORT__
  mov	eax,	__END_OF_EXPORT__
  mov	ecx,	(_ASSUME_MEMORY_ * 1024 * 1024)
  sub	ecx,	eax
  externfunc	mem.dealloc_forced_range
  extern	__STACK_LOCATION__
  mov	eax, 	__STACK_LOCATION__
  mov	ecx,	0xA0000
  sub	ecx,	eax
  externfunc	mem.dealloc_forced_range

				; perform .c_init calls
				;----------------------
 pop	ecx			; restore number of .c_init call to perform
 jecxz	osw_call2_cells.completed
osw_call2_cells:		;calls for .c_init of cells
 pushad				; backup all regs, cell don't have to do it
 mov	al, 'I'
 call	display_init_status
 push	esi
 mov	eax, [esi + 2]   	; destination to call
 movzx	ecx, byte [esi + 10]	; number of arguments
 mov	esi, [esi + 6]		; ptr to parameter array
 call	eax			; call .c_init
 pop	esi
 jc	near display_init_failed
 movzx	esi, word [esi]
 extern __INFO_REDIRECTOR_TABLE__
 mov	esi, [esi*4 + __INFO_REDIRECTOR_TABLE__ - 4]
 movzx	eax, byte [esi + 3]
 push	eax
 mov	al, [esi + 2]
 push	eax
 mov	al, [esi + 1]
 push	eax
 mov	al, [esi]
 push	eax
 mov	esi, dword [esi + 4]
 push	esi
 push	byte 1
 push	dword string_initialized
 externfunc	sys_log.print
 add esp, byte 28 - 8
 popad				; restore all regs, cell don't have to do it
 add	esi, byte 11		; move to next op
 dec	ecx			;
 jnz	osw_call2_cells		;
.completed:			;
 call init_completed


;                                           -----------------------------------
;                                          create terminals with silver, if any
;==============================================================================

%if _TERMINAL_COUNT_
create_terminals:
  push byte _TERMINAL_COUNT_
.create_term:
  externfunc terminal.create
  dec dword[esp]
  jnz .create_term

  pop ecx
%else
  %error no terminals are being created in init.
%endif

;                                           -----------------------------------
;                                     open a terminal to serve as stdin/out/err
;==============================================================================

open_terminal:
  mov esi, terminal_str
  externfunc vfs.open
  jnc .terminal_opened

  push eax
  push __SYSLOG_TYPE_FATALERR__
  push unable_to_open_tty
  externfunc sys_log.print
  add esp, byte 4
  push __SYSLOG_TYPE_FATALERR__
  push tty_enter_to_reboot
  externfunc sys_log.print

  jmp reboot.wait

.terminal_opened:
  mov [shell_proc_info+process_info.stdin], ebx
  mov [shell_proc_info+process_info.stdout], ebx
  mov [shell_proc_info+process_info.stderr], ebx
  mov ebp, [ebx]

;                                           -----------------------------------
;                                              set lanthane to use the terminal
;==============================================================================

  mov eax, __SYSLOG_TYPE_DEBUG__
  externfunc sys_log.set_echo_file
  mov eax, __SYSLOG_TYPE_FATALERR__
  externfunc sys_log.set_echo_file

  push ebx
  xor ebx, ebx
  mov eax, __SYSLOG_TYPE_INFO__
  externfunc sys_log.set_echo_file
  mov eax, __SYSLOG_TYPE_LOADINFO__
  externfunc sys_log.set_echo_file
  mov eax, __SYSLOG_TYPE_WARNING__
  externfunc sys_log.set_echo_file
  pop ebx

;                                           -----------------------------------
;                          now that the terminal is open, announce our presence
;==============================================================================

  mov esi, init_running_str
  mov ecx, init_running_len
  call [ebp+file_op_table.write]

;                                           -----------------------------------
;                           register the VOiD symbols in the core with hydrogen
;==============================================================================

register_void_syms:
  mov esi, registering_syms_str
  mov ecx, registering_syms_len
  call [ebp+file_op_table.write]

; register all of the VOiD syms with hydrogen
  extern __SYMBOLS_LINKAGE__
  mov esi, __SYMBOLS_LINKAGE__ + 4
  mov ecx, [esi - 4]

  jecxz .done
.register_sym:
  push	ecx
  mov	edx, [esi]
  movzx	ecx, word [esi + 6]
  push	ecx
  movzx	ecx, word [esi + 4]
  add	esi, byte 8
.registering_global_prov:
  dec	ecx
  js	short .done_providers
  lodsd
  xchg	eax, edi
  externfunc void.add_global
  jmp	short .registering_global_prov
.done_providers:
  pop	ecx
  externfunc void.lookup_global
.registering_global_dep:
  dec	ecx
  js	short .done
  lodsd
  xchg	eax, edi
  externfunc void.add_hook
  jmp short .registering_global_dep
.done:
  pop	ecx
  dec	ecx
  jnz	short .register_sym


;                                           -----------------------------------
;                                                   set up an empty environment
;==============================================================================

set_up_env:
  mov esi, initing_env_str
  mov ecx, initing_env_len
  call [ebp+file_op_table.write]
  ; set up an empty environment
  mov ecx, 4
  externfunc mem.alloc
  jnc .no_error

  push eax
  mov esi, mem_alloc_error_str
  mov ecx, mem_alloc_error_len
  call [ebp+file_op_table.write]
  pop edx
  externfunc lib.string.print_dec_no_pad
  jmp reboot

.no_error:
  mov [edi], dword 0
  mov [shell_proc_info+process_info.env], edi

  mov esi, done_str
  mov ecx, done_len
  call [ebp+file_op_table.write]

;                                           -----------------------------------
;                                                   mount a root device, if any
;==============================================================================

%ifdef _ROOT_DEVICE_
mount_root:
  mov esi, mounting_str
  mov ecx, mounting_len
  call [ebp+file_op_table.write]
  mov esi, root_device_str
  externfunc lib.string.find_length
  call [ebp+file_op_table.write]
  mov esi, mounting_str2
  mov ecx, mounting_len2
  call [ebp+file_op_table.write]

  mov esi, root_dir_str
  mov eax, root_device_str
  mov edx, __FS_TYPE_EXT2__
  externfunc vfs.mount
  mov ebx, [shell_proc_info+process_info.stdout]
  mov ebp, [ebx]
  jnc .mounted

  mov esi, unable_to_mount_str
  mov ecx, unable_to_mount_len
  call [ebp+file_op_table.write]
  mov edx, eax
  externfunc lib.string.print_dec_no_pad
  jmp reboot

.mounted:
  mov esi, done_str
  mov ecx, done_len
  call [ebp+file_op_table.write]
%else
  %error no root device is being mounted in init.
%endif

;                                           -----------------------------------
;                                                             execute the shell
;==============================================================================

execute_shell:
  mov esi, running_shell_str
  mov ecx, running_shell_len
  call [ebp+file_op_table.write]

  mov esi, shell_bin_str
  externfunc lib.string.find_length
  call [ebp+file_op_table.write]
  mov al, 0xa
  externfunc lib.string.print_char
  mov ebx, shell_proc_info
  mov edi, shell_argv
  mov ecx, shell_argc
  xor eax, eax
  externfunc process.create
  externfunc process.kill_self

;                                           -----------------------------------
;                                                             reboot the system
;==============================================================================

reboot:
  mov esi, init_terminating_str
  mov ecx, init_terminating_len
  call [ebp+file_op_table.write]
.wait:
  externfunc debug.diable.wait
; init complete, reboot the system
  mov al, 0xFE
  out 0x64, al
  mov al, 0x01
  out 0x92, al
; should have rebooted, but lock to be sure
  cli
  jmp short $



;                                           -----------------------------------
;                                                                  _print_write
;==============================================================================

_print_write:
; write function for our print pseudo-files
  pushad
  mov ah, 0x07
  mov edi, [ebx+print_file.cur]
.write_char:
  cmp edi, [ebx+print_file.size]
  jae .scroll
.scroll_ret:
  mov al, [esi]
  cmp al, 0xa
  jz .nl
  mov [0xb80A0+edi], ax
  add edi, byte 2
.next_char:
  inc esi
  dec ecx
  jnz .write_char
  mov [ebx+print_file.cur], edi
  popad
  clc
  retn

.scroll:
  push esi
  push ecx
  mov edi, 0xb80A0
  mov ecx, [ebx+print_file.size]
  mov esi, edi
  sub ecx, [ebx+print_file.width]
  add esi, [ebx+print_file.width]
  shr ecx, 2
  repz movsd
  mov ecx, [ebx+print_file.width]
  mov eax, 0x07200720
  shr ecx, 2
  repz stosd
  mov edi, [ebx+print_file.size]
  sub edi, [ebx+print_file.width]
  pop ecx
  pop esi
  jmp short .scroll_ret

.nl:
  mov eax, edi
  xor edx, edx
  div dword[ebx+print_file.width]
  sub edi, edx
  mov ah, 0x7
  add edi, [ebx+print_file.width]
  jmp short .next_char

;                                           -----------------------------------
;                                                                    _buf_write
;==============================================================================

_buf_write:
; fake write function for our fake buffer write files
  pushad
.check_size:
  mov edx, [ebx+buf_file.size]
  sub edx, [ebx+buf_file.cur]
  cmp ecx, edx
  ja .resize
  mov edi, [ebx+buf_file.buf]
  add edi, [ebx+buf_file.cur]
  repz movsb
  sub edi, [ebx+buf_file.buf]
  mov [ebx+buf_file.cur], edi
  popad
  clc
  retn

.resize:
  push ecx
  mov eax, [ebx+buf_file.buf]
  test eax, eax
  jz .create_new
  mov ecx, [ebx+buf_file.size]
  add ecx, 0x1000
  externfunc mem.realloc
  mov [ebx+buf_file.buf], edi
  mov [ebx+buf_file.size], ecx
  pop ecx
  jmp short .check_size

.create_new:
  mov ecx, 0x1000
  externfunc mem.alloc
  mov [ebx+buf_file.buf], edi
  mov [ebx+buf_file.size], ecx
  pop ecx
  jmp short .check_size

;                                           -----------------------------------
;                                                       sys_log.get_log_pointer
;==============================================================================

globalfunc sys_log.get_log_pointer
  mov ebx, buf_fd
  retn



;                                           -----------------------------------
;                                                           display_init_status
;==============================================================================
display_init_failed:
 extern __INFO_REDIRECTOR_TABLE__
 movzx esi, word [esi]
 mov  esi, [esi*4 + __INFO_REDIRECTOR_TABLE__ -4]
 push eax
 push dword [esi + 4]
 push byte __SYSLOG_TYPE_FATALERR__
 push dword string_init_failed
 externfunc sys_log.print
 jmp short $
 
init_completed:
 pushad
 mov	esi, string_export_completed
 mov	al,  '-'
 jmp	short display_init_status.string_set

section .data
string_export_completed:
  db "Export completed.  Proceeding with standard initialization.",0
string_exported:
  db "%s Exported",0x0A,0
string_initialized:
  db "%s version %u.%u.%u.%u Initialized.",0x0A,0
string_init_failed:
  db "%s initialization failed with error code: %x",0
section .text

display_init_status:
  pushad
  movzx ebx, word [esi]
  extern __INFO_REDIRECTOR_TABLE__
  mov	esi, [ebx*4 + __INFO_REDIRECTOR_TABLE__ -4]
  mov   esi, [esi + 4]
.string_set:
  mov	edi, 0xB8000
  cbw
  shl	eax, 16
  or	eax, 0x1F001700+'['
  stosd
  mov	al, ']'
  stosw
  mov	al, ' '
  push	byte 77
  pop	ecx
.display:
  stosw
  lodsb
  dec ecx
  jz short .quit
  test	al, al
  jnz short .display
  rep stosw
.quit:
  popad
  retn



;                                           -----------------------------------
;                                                                          DATA
;==============================================================================
section .data

%ifdef _SHELL_

%ifdef _ROOT_DEVICE_
root_dir_str:		db "/",0
root_device_str:	db _ROOT_DEVICE_,0
unable_to_mount_str:	db "vfs.mount returned error "
unable_to_mount_len:	equ $-unable_to_mount_str
mounting_str:		db 'mounting "'
mounting_len:		equ $-mounting_str
mounting_str2:		db '" as root...'
mounting_len2:		equ $-mounting_str2
%endif	; _ROOT_DEVICE_

shell_argv:		dd shell_bin_str, 0
shell_argc:		equ ($-shell_argv) / 4 - 1
shell_proc_info:	times process_info_size db 0

terminal_str:		db "/dev/tty/0",0
shell_bin_str:		db _SHELL_,0

init_running_str:	db 'init $Revision: 1.4 $ running. Hello world!',0xa,_DISTRO_INFO_,0xa
init_running_len:	equ $-init_running_str
registering_syms_str:	db 'registering VOiD symbols...'
registering_syms_len:	equ $-registering_syms_str
register_done_str:	db ' symbols registered',0xa
register_done_len:	equ $-register_done_str
register_err_str:	db 'void.add_global returned error '
register_err_len:	equ $-register_err_str
unable_to_exec_str:	db 'process.exec returned error '
unable_to_exec_len:	equ $-unable_to_exec_str
returned_error_str:	db 'shell returned error '
returned_error_len:	equ $-returned_error_str
mem_alloc_error_str:	db "mem alloc returned error "
mem_alloc_error_len:	equ $-mem_alloc_error_str
init_terminating_str:	db 0xa,"init $Revision: 1.4 $ terminating",0xa,"press enter to reboot; have a nice day!"
init_terminating_len:	equ $-init_terminating_str
done_str:		db "done",0xa
done_len:		equ $-done_str
initing_env_str:	db "initializing environment..."
initing_env_len:	equ $-initing_env_str
running_shell_str:	db 'executing shell '
running_shell_len:	equ $-running_shell_str

%ifdef _TERMINAL_COUNT_
unable_to_open_tty:	db "unable to open terminal, error %u",0xa,0
tty_enter_to_reboot:	db "press enter to reboot",0
%endif

%endif	; _SHELL_

print_fd: istruc print_file
  at file_descriptor.op_table,	dd print_op_table
  at print_file.width,		dd 80*2
  at print_file.size,		dd 80*24*2*2
  at print_file.cur,		dd 0
iend

print_op_table: istruc file_op_table
  at file_op_table.write,	dd _print_write
iend

buf_fd: istruc buf_file
  at file_descriptor.op_table,	dd buf_op_table
iend

buf_op_table: istruc file_op_table
  at file_op_table.write,	dd _buf_write
iend

