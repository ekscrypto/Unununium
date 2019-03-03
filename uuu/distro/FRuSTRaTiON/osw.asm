;; $Header: /cvsroot/uuu/uuu/distro/FRuSTRaTiON/osw.asm,v 1.33 2001/12/18 01:42:11 daboy Exp $
;; 
;; FRuSTRaTiON OS-Wrapper
;;
;; known issues:
;;--------------
;; - If a cell implement a .c_onetime_init section, all the cells' name will
;;   be wrongly assigned after that.  Some more complex mechanism will have to
;;   be designed to allow proper detection of cell name independant on the
;;   presence of .c_onetime_init or .c_init section.  The problem is also
;;   present if a cell doesn't have any .c_init section nor .c_onetime_init.

[bits 32]

section .osw_pre_init	; must be here or nasm will generate a 0 sized .text

;                                           -----------------------------------
;                                                                 configuration
;==============================================================================

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

%include "ozone.inc"
%include "hdr_core.inc"
%include "vid/terminal.inc"
%include "vid/vfs.inc"
%include "vid/int.inc"
%include "vid/void.inc"
%include "vid/debug.diable.inc"
%include "vid/process.inc"
%include "vid/lib.string.inc"
%include "vid/mem.inc"
%include "vid/sys_log.inc"
%include "vid/thread.inc"
%include "sys_log.inc"
%include "process.inc"

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
;                                                                 .osw_pre_init
;==============================================================================

section .osw_pre_init

extern __CORE_HEADER__


  ;- Make screen "BLUE!" >:)
  mov edi, 0xB8000
  mov eax, 0x17201720
  mov ecx, 1000
  repz stosd


  ;- Masking all irq
  mov al, 0xFF	; irq mask
  out 0x21, al	; master pic
  out 0xA1, al	; slave pic


  ;- set up lanthane to use some fake ttyish files we provide
  mov eax, __SYSLOG_TYPE_DEBUG__
  mov ebx, print_fd
  externfunc sys_log.set_echo_file
  mov eax, __SYSLOG_TYPE_INFO__
  externfunc sys_log.set_echo_file
  mov eax, __SYSLOG_TYPE_LOADINFO__
  externfunc sys_log.set_echo_file
  mov eax, __SYSLOG_TYPE_WARNING__
  externfunc sys_log.set_echo_file
  mov eax, __SYSLOG_TYPE_FATALERR__
  externfunc sys_log.set_echo_file

  mov eax, __SYSLOG_TYPE_DEBUG__
  mov ebx, buf_fd
  externfunc sys_log.set_print_file
  mov eax, __SYSLOG_TYPE_INFO__
  externfunc sys_log.set_print_file
  mov eax, __SYSLOG_TYPE_LOADINFO__
  externfunc sys_log.set_print_file
  mov eax, __SYSLOG_TYPE_WARNING__
  externfunc sys_log.set_print_file
  mov eax, __SYSLOG_TYPE_FATALERR__
  externfunc sys_log.set_print_file



  ;- Initialize starting registers
  mov esi, __CORE_HEADER__	; pointer to core header
  xor eax, eax			; all options to zero



%ifdef _REG_TRACING_
%include "../../include/hdr_core.inc"
  mov [cell_header_pointer], dword __CORE_HEADER__ +hdr_core.core_size
  call trace_entering_init

section .osw_inter_init

  call trace_exiting_init
  call trace_query
  call trace_entering_init
%endif	; _REG_TRACING_



;                                           -----------------------------------
;                                                                .osw_post_init
;==============================================================================

section .osw_post_init

;                                           -----------------------------------
;                                                      wrap up register tracing
;==============================================================================

%ifdef _REG_TRACING_
  call trace_exiting_init
  call trace_query
%endif	; _REG_TRACING_

;                                           -----------------------------------
;                  optional section: test registers for corruption durring init
;==============================================================================

%ifdef _REG_CORRUPTION_CHECK_
register_corruption_test:
  cli

  ;; loading up test values
  mov eax, 0x12345678
  mov ebx, 0x9ABCDEF0
  mov ecx, 0xF4F2F3F1
  mov edx, 0xA0A1A2A3
  mov esi, 0xB9B7B5B3
  mov edi, 0x0C2C3C4C
  mov ebp, 459

 .continue_check:
  call set_regs
  mov [.count], dword 10000
  sti
  .checking:
   call check_regs
   jnz near failed_regs
   dec dword [.count]
   inc dword [0xB8140]
  jnz short .checking
  cli
  ;; rotating test values
  push eax
  mov eax, ebx
  mov ebx, ecx
  mov ecx, edx
  mov edx, esi
  mov esi, edi
  mov edi, ebp
  pop ebp
 jmp short .continue_check

align 4, db 0
.count: dd 0

original_regs:
dd 0, 0, 0, 0, 0, 0, 0

set_regs:
  mov [original_regs], eax
  mov [original_regs+4], ebx
  mov [original_regs+8], ecx
  mov [original_regs+12], edx
  mov [original_regs+16], esi
  mov [original_regs+20], edi
  mov [original_regs+24], ebp
  retn

check_regs:
  cmp [original_regs], eax
  jnz short .failed
  cmp [original_regs+4], ebx
  jnz short .failed
  cmp [original_regs+8], ecx
  jnz short .failed
  cmp [original_regs+12], edx
  jnz short .failed
  cmp [original_regs+16], esi
  jnz short .failed
  cmp [original_regs+20], edi
  jnz short .failed
  cmp [original_regs+24], ebp
  jnz short .failed
  .failed:
  retn

failed_regs:
  mov [0xB80A0], byte 'a'
  cmp [original_regs], eax
  jz short .bypass_eax
   mov byte [0xB80A1], 0x04
  .bypass_eax:

  mov [0xB80A2], byte 'b'
  cmp [original_regs+4], ebx
  jz short .bypass_ebx
   mov byte [0xB80A3], 0x04
  .bypass_ebx:

  mov [0xB80A4], byte 'c'
  cmp [original_regs+8], ecx
  jz short .bypass_ecx
   mov byte [0xB80A5], 0x04
  .bypass_ecx:

  mov [0xB80A6], byte 'd'
  cmp [original_regs+12], edx
  jz short .bypass_edx
   mov byte [0xB80A7], 0x04
  .bypass_edx:

  mov [0xb80A8], byte 's'
  cmp [original_regs+16], esi
  jz short .bypass_esi
   mov byte [0xB80A9], 0x04
  .bypass_esi:

  mov [0xb80AA], byte 'd'
  cmp [original_regs+20], edi
  jz short .bypass_edi
   mov byte [0xB80AB], 0x04
  .bypass_edi:

  mov [0xB80AC], byte 'b'
  cmp [original_regs+24], ebp
  jz short .bypass_ebp
   mov byte [0xB80AD], 0x04
  .bypass_ebp:

  jmp short $

%endif	; _REG_CORRUPTION_CHECK_



%ifdef _SHELL_	; =============================================================



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
  mov esi, [__CORE_HEADER__ + hdr_core.dlp_provided]
  xor ecx, ecx

  mov edx, [esi]
  test edx, edx
  jz .done
.register_sym:
  mov edi, [esi+4]
  dbg_print_hex edx
  dbg_term_log
  dbg_print_hex edi
  dbg_term_log
  dbg_term_log
  externfunc void.add_global
  jc .register_error
  inc ecx
  add esi, byte 12
  mov edx, [esi]
  test edx, edx
  jnz .register_sym
  jmp short .done

.register_error:
  push eax
  mov esi, register_err_str
  mov ecx, register_err_len
  call [ebp+file_op_table.write]
  pop edx
  externfunc lib.string.print_dec_no_pad
  jmp reboot
  

.done:
  mov edx, ecx
  externfunc lib.string.print_dec_no_pad
  mov esi, register_done_str
  mov ecx, register_done_len
  call [ebp+file_op_table.write]

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
  mov ebx, [shell_proc_info+process_info.stdout]
  mov ebp, [ebx]
  jnc .app_execed

  push eax
  
  mov esi, unable_to_exec_str
  mov ecx, unable_to_exec_len
  call [ebp+file_op_table.write]

  pop edx
  externfunc lib.string.print_dec_no_pad
  jmp short reboot
	      
.app_execed:
  test eax, eax
  jz reboot

  push eax
  mov esi, returned_error_str
  mov ecx, returned_error_len
  call [ebp+file_op_table.write]
  pop edx
  externfunc lib.string.print_dec_no_pad

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



%endif	; _SHELL_ =============================================================

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
  mov [0xb8000+edi], ax
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
  mov edi, 0xb8000
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
;                                                                          DATA
;==============================================================================

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

init_running_str:	db 'init $Revision: 1.33 $ running. Hello world!',0xa,_DISTRO_INFO_,0xa
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
init_terminating_str:	db 0xa,"init $Revision: 1.33 $ terminating",0xa,"press enter to reboot; have a nice day!"
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
  at print_file.size,		dd 80*25*2*2
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

;                                           -----------------------------------
;                                                    register tracing functions
;==============================================================================

%ifdef _REG_TRACING_
;------------------------------------------------
str_entering_init: db 0x0A,"Entering init of cell ",0
str_space equ $-2
str_regs: db " with registers:",0x0A,"EAX      EBX      ECX      EDX      ESI      EDI      ESP      EBP",0x0A,0
str_init_ended: db 0x0A,"Init ended with registers:",0x0A,0
str_control: db 0x0A,"[c] continue, [s] single step",0

align 4, db 0
entering_regs_value:
.eax: dd 0
.ebx: dd 0
.ecx: dd 0
.edx: dd 0
.esi: dd 0
.edi: dd 0
.esp: dd 0
.ebp: dd 0
cell_serial_number: db 0
cell_header_pointer: dd 0
tty_cursor: dd 0xB8000+(24*0xA0)
leaving_regs_value:
.eax: dd 0
.ebx: dd 0
.ecx: dd 0
.edx: dd 0
.esi: dd 0
.edi: dd 0
.esp: dd 0
.ebp: dd 0


tty_scroll_up:
; params: none
; destroys: eax=0x17201720, ecx=0, esi=0xB8000+(50*0xA0), edi=0xB8000+(50*0xA0)
;----------
mov esi, 0xb80A0
mov edi, 0xB8000
mov ecx, 960
repz movsd
mov eax, 0x17201720
mov cl, 40
repz stosd
retn

tty_out:
; params: esi = pointer to string
;         al = 0=normal, 1=highlighted
;--------
mov edi, [tty_cursor]
mov ah, 0x17
or al, al
jz short .processing
mov ah, 0x1F
.processing:
lodsb
or al, al
 jz short .end
cmp al, 0x0A
 jz short .scroll_up
stosw
cmp edi, 0xB8000+(25*0xA0)
jb short .processing
.scroll_up:
 push esi
 push eax
 call tty_scroll_up
 pop eax
 pop esi
 mov edi, 0xb8000+(24*0xA0)
 jmp short .processing
.end:
mov [tty_cursor], edi
retn

decimal_out:
 ; EDX = value to display
 ; AL = color 0=normal, 1=highlighted
 push eax
 mov eax, edx
 mov ebx, 0x0A
 mov edi, .tmp_buffer+10
 .processing:
 xor edx, edx
 div ebx
 add dl, 0x30
 mov [edi], dl
 dec edi
 or eax, eax
 jnz short .processing
 lea esi, [edi + 1]
 pop eax
 call tty_out
 retn
.tmp_buffer: times 12 db 0

hex_out:
; EDX = value to display
; AL = highlighting, 0=normal, 1=highlighted
push eax
mov ah, 0x0F
mov ecx, 8
mov edi, decimal_out.tmp_buffer+3
mov esi, edi
.processing:
rol edx, 4
mov al, dl
and al, ah
cmp al, 10
sbb al, 0x69
das
stosb
loop .processing
pop eax
call tty_out
retn

trace_entering_init:
  mov [entering_regs_value.eax], eax
  mov [entering_regs_value.ebx], ebx
  mov [entering_regs_value.ecx], ecx
  mov [entering_regs_value.edx], edx
  mov [entering_regs_value.esi], esi
  mov [entering_regs_value.edi], edi
  lea eax, [esp + 4]
  mov [entering_regs_value.esp], eax
  mov [entering_regs_value.ebp], ebp
  mov esi, str_entering_init
  mov al, 0
  call tty_out
  mov ebx, [cell_header_pointer]
  mov esi, [ebx + 8]
  or esi, esi
  jz short .no_c_info_found
  mov esi, [esi+4]
  or esi, esi
  jz short .no_c_info_found
  mov al, 1
  call tty_out
  jmp short .with_regs
  .no_c_info_found:
  movzx edx, byte [cell_serial_number]
  mov al, 1
  call decimal_out
  .with_regs:
  mov al, 0
  mov esi, str_regs
  call tty_out
  mov ebx, entering_regs_value
  call regs_out
  mov eax, [entering_regs_value.eax]
  mov ebx, [entering_regs_value.ebx]
  mov ecx, [entering_regs_value.ecx]
  mov edx, [entering_regs_value.edx]
  mov esi, [entering_regs_value.esi]
  mov edi, [entering_regs_value.edi]
  inc byte [cell_serial_number]
  add [cell_header_pointer], byte 0x0C
  retn

trace_exiting_init:
  mov [leaving_regs_value.eax], eax
  mov [leaving_regs_value.ebx], ebx
  mov [leaving_regs_value.ecx], ecx
  mov [leaving_regs_value.edx], edx
  mov [leaving_regs_value.esi], esi
  mov [leaving_regs_value.edi], edi
  lea eax, [esp + 4]
  mov [leaving_regs_value.esp], eax
  mov [leaving_regs_value.ebp], ebp
  mov al, 0
  mov esi, str_init_ended
  call tty_out
  mov ebx, leaving_regs_value
  call regs_out
  mov eax, [leaving_regs_value.eax]
  mov ebx, [leaving_regs_value.ebx]
  mov ecx, [leaving_regs_value.ecx]
  mov edx, [leaving_regs_value.edx]
  mov esi, [leaving_regs_value.esi]
  mov edi, [leaving_regs_value.edi]
  retn


regs_out:
; EBX = pointer to registers table
  mov ecx, 8
  .displaying_regs:
  mov eax, leaving_regs_value
  mov edx, [ebx]
  cmp ebx, eax
  jb short .no_check
  sub eax, ebx
  neg eax
  cmp edx, [eax + entering_regs_value]
  jz short .no_check
  mov al, 1
  jmp short .display
 .no_check:
  mov al, 0
 .display:
  push ecx
  call hex_out
  mov esi, str_space
  call tty_out
  add ebx, byte 4
  pop ecx
  loop .displaying_regs
  retn

trace_query:
  pushfd
  cmp [.continue_pressed], byte 0
  jnz short .exit
  push eax
  cli
  pushad
  mov esi, str_control
  mov al, 1
  call tty_out
  popad
  .wait_scancode:
  in al, 0x64
  test al, 0x01
  jz short .wait_scancode
  in al, 0x60
  cmp al, 46+0x80
  jz short .continue
  cmp al, 31+0x80
  jnz short .wait_scancode
  pop eax
  .exit:
  popfd
  retn
  .continue:
  mov [.continue_pressed], byte 1
  pop eax
  popfd
  retn
.continue_pressed: db 0

%endif
