;; $Header: /cvsroot/uuu/dimension/cell/dyn/executioner/executioner.asm,v 1.3 2002/08/11 07:41:24 lukas2000 Exp $
;;
;; executioner dynamic linker
;; Copyright (C) 2001 Phil Frost
;; Distributed under the BSD license; see file "license" for details
;;
;; status:
;; -------
;; executes apps flawlessly when nothing goes wrong, but some of the error
;; handlers don't dealloc all their memory or close all the files.
;;
;; XXX memory deallocations have been commented out because they are corrupting
;; memory. Fixing this is top-priority

;%define _DEBUG_



;                                           -----------------------------------
;                                                              strucs 'n' stuff
;==============================================================================


struc stack
  .ret:		resd 1	; return adddress
  .header:	resd 1
  .fp:		resd 1	; file descriptor of input
  .sym_table:	resd 1
  .sect_table:	resd 1
  .to_be_freed:	resd 1	; ptr to a table of stuff we must free  prog retns
  .edi:		resd 1
endstruc


;                                           -----------------------------------
;                                                               section .c_init
;==============================================================================
section .c_init
global _start
_start:
  ; We do nothing here
  ; added by Luke
  retn
;                                           -----------------------------------
                                                                  section .text
;==============================================================================

;                                           -----------------------------------
                                                           globalfunc file.link
;==============================================================================

;>
;; parameters:
;; -----------
;; ESI = ptr to string of file to link
;; EDI = argv array
;;
;; returned values:
;; ----------------
;; EAX = cleanup number; use for later call to file.cleanup_link
;; EDX = entry point
;; EDI = new argv array; this may change if the file is a shell script. If this
;;       happens the old argv remains untouched and the new one is deallocated
;;       automaticly when the process is destroyed.
;; errors as usual (no cleanup required on error)
;; all other registers destroyed
;<
  
  dbg lprint 'executioner: executing file "%s"', DEBUG, esi

					; set up space on stack to hold vars
					;-----------------------------------
  mov ebp, esp				;
  sub esp, byte stack_size - 4		;
					;
  dbg lprint 'executioner: executing file "%s"', DEBUG, esi
					;
  mov [ebp-stack.edi], edi		; save argv
					;
  push ebp				;
  externfunc vfs.open			; EBX = input file
  pop ebp				;
  jc short .error_redir0			;
  mov [ebp-stack.fp], ebx		; save input file on stack
					;
					; allocate memory for header
					;---------------------------
  mov ecx, ubf_header_size		;
  externfunc mem.alloc			; EDI = ptr to buf for header
.error_redir0:
  jc short .error_redir1			;
  dbg lprint 'executioner: header in memory at 0x%x', DEBUG, edi
  mov [ebp-stack.header], edi		; save ptr to header on stack
					;
					; read header to memory
					;----------------------
  mov esi, [ebx+file_descriptor.op_table]
  mov ecx, ubf_header_size		; ESI = op table
  call [esi+file_op_table.read]		;
.error_redir1:
  jc short .error_redir2		;
					;
					; check our magic
  cmp dword[edi+ubf_header.magic], ubf_magic
  jne near .not_valid_ubf		;
  dbg lprint "executioner: valid UBF found", DEBUG
					;
					; create the symbol table
					;------------------------
  mov ecx, [edi+ubf_header.num_externs]	;
  add ecx, [edi+ubf_header.num_sections];
  shl ecx, 2				; ECX = size of symbol table
  mov edx, edi				; EDX = ptr to header in memory
  externfunc mem.alloc			; EDI = ptr to buffer for symbol table
.error_redir2:
  jc short .error_redir3			;
  mov [ebp-stack.sym_table], edi	; save ptr to sym table on stack
					;
  cmp [edx+ubf_header.num_externs], byte 0
  jz .sym_table_done			;
					;
  mov eax, [edx+ubf_header.num_sections]; EAX = number of sections
  lea edi, [edi+eax*4]			; EDI = extern part of sect table
					;
  push dword[edx+ubf_header.num_externs]; TOS = number of externs
  mov eax, [edx+ubf_header.extern_table]; EAX = ptr to extern table in file
  dbg lprint "executioner: seeking to 0x%x for extern table", DEBUG, eax
  xor edx, edx				;
  call [esi+file_op_table.seek_start]	;
.error_redir3:				;
  jc short .error_redir4		;
					;
  pop ecx				; ECX = number of externs
  shl ecx, 2				; ECX = size of extern table
  call [esi+file_op_table.read]		; read in extern table
.error_redir4:
  jc short .error_redir5			;
  shr ecx, 2				; ECX = number of externs
					;
.get_value:				;
  mov edx, [edi+ecx*4-4]		; EDX = VID to lookup
  externfunc void.lookup_global		; EAX = VID value
  jc near .unable_to_lookup_global	;
  mov [edi+ecx*4-4], eax		; save value
  dec ecx				;
  jnz .get_value			; loop until done
  
.sym_table_done:			;
  dbg lprint "executioner: done creating symbol table", DEBUG
  
					; read in the section table
					;--------------------------
  mov edi, [ebp-stack.header]		; EDI = ptr to header in mem
  mov ebx, [ebp-stack.fp]		; EBX = file (ESI still op table)

  xor edx, edx
  mov eax, [edi+ubf_header.sect_table]
  dbg lprint "executioner: seeking to 0x%x for section table", DEBUG, eax
  call [esi+file_op_table.seek_start]	; seek to sect table in file
.error_redir5:
  jc short .error_redir6		;
					;
  mov ecx, [edi+ubf_header.num_sections]; ECX = number of sections
  %if ubf_sect_size <> 28
    %error "ubf_sect_size was assumed to be 28, but it wasn't"
  %endif
  dbg lprint "executioner: file has %d sections", DEBUG, ecx
  push ecx				; TOS = number of sections
  imul ecx, byte ubf_sect_size		; ECX = size of section table
  externfunc mem.alloc			;
.error_redir6:
  jc short .error_redir7		;
  mov [ebp-stack.sect_table], edi	; save ptr to sect table on stack
  mov ecx, eax				; ECX = size of sect table
  call [esi+file_op_table.read]		; read from file
.error_redir7:
  jc near .error			;
					; read sections into memory and fill
					; out their entries in the symbol table
					;--------------------------------------
  push ebp				; TOS = ptr to stack frame
  mov ebp, [ebp-stack.sym_table]	;
 
  ;; tos+4 = number of sections
  ;; tos = ptr to stack frame
  ;; EBP = ptr to sym table
  ;; EBX = ptr to file descriptor
  ;; ESI = ptr to file's op_table
  ;; EDI = ptr to section table in memory
  ;; EDX = 0

.read_sect:				;
  mov al, [edi+ubf_sect.type]		; AL = section type
  cmp al, ubf_secttype_prog		; branch to the correct handler
  je .type_prog				;
  cmp al, ubf_secttype_uninit_data	;
  je .type_uninit_data			;
					; unknown section type, die
					;--------------------------
					; XXX bad cleanup here
  lprint "executioner: unknown section type 0x%2x", FATALERR, eax
  					;
  pop ebp				; EBP = stack frame
  mov ebx, [ebp-stack.fp]		; close our file
  mov esi, [ebx]			;
  call [esi+file_op_table.close]	;
  mov esi, ebp				;
  retn					;
					; ubf_secttype_uninit_data
.type_uninit_data:			;-------------------------
  push edi				; save ptr to section table
  mov ecx, [edi+ubf_sect.size]		; ECX = size of section
  externfunc mem.alloc			; get memory for it
  jc near .pop_ebp_err			;
  mov [ebp], edi			; fill out entry in section table
  					;
  xor eax, eax				; EAX = 0
  shr ecx, 2				; ECX = section size / 4
  push esi				;
  rep stosd				; zero out data
  pop esi				;
  pop edi				;
  jmp short .sect_done			;
					; ubf_secttype_prog
.type_prog:				;------------------
  mov eax, [edi+ubf_sect.loc]		; EAX = section location in file
  dbg lprint "executioner: seeking to section at 0x%x", DEBUG, eax
  call [esi+file_op_table.seek_start]	; seek to section
					;
  push edi				;
  mov ecx, [edi+ubf_sect.size]		; ECX = section size
  push ecx				;
  externfunc mem.alloc			; get memory for section
  jc near .pop_ebp_err			;
					;
  pop ecx				;
  call [esi+file_op_table.read]		; read to memory
					;
  mov [ebp], edi			; fill out entry in symbol table
  pop edi				;
					;
					; next section
.sect_done:				;-------------
  add edi, byte ubf_sect_size		; EDI = ptr to next section
  add ebp, byte 4			; EBP = ptr to next entry in sym table
  dec dword[esp+4]			; dec number of sections
  jnz .read_sect			;
					;
  pop ebp				; pop saved stack frame
  pop ecx				; pop off 0, was the # of sections

  ;; EBX = ptr to file descriptor
  ;; ESI = ptr to file op table

  ;--------------------------------------------------
  ; apply relocations

  push ebp				; TOS = ptr to stack frame
  mov eax, [ebp-stack.header]		; EAX = ptr to UBF header
  push dword[eax+ubf_header.num_sections]; TOS = number of sections
  mov eax, [ebp-stack.sym_table]	; EAX = ptr to sym table
  xor edx, edx				; EDX = curent section
  mov ebp, [ebp-stack.sect_table]	; EBP = section table

.relocate_section:

  dbg lprint "executioner: relocating section %d; %d abs and %d rel", DEBUG, edx, [ebp+ubf_sect.abs_num], [ebp+ubf_sect.rel_num]

					; process absolute relocs
					;------------------------
  mov ecx, [ebp+ubf_sect.abs_num]	; ecx = number of relocs to do
  jecxz .abs_done			; bypass if we have none
					;
  push eax				; save ptr to sym table
					;
					; seek to table
					;--------------
  push edx				; backup section id
  mov esi, [ebx]			; esi = file_op_table
  xor edx, edx				; seek addr high 32bits = 0
  mov eax, [ebp+ubf_sect.abs_reloc]	; seek addr low 32bits = reloc address
  dbg lprint "executioner: seeking to 0x%x for abs reloc table", DEBUG, eax
  call [esi+file_op_table.seek_start]	; seek to abs relocation table
  pop edx				; restore section id
  jc short .pop_1_ebp_err_redir0	;
					;
					; allocate memory for relocs
					;---------------------------
  %if ubf_reloc_size <> 8		;
    %error "ubf_reloc_size assumed to be 8 and it's not"
  %endif				;
  shl ecx, 3				; each reloc is 8 bytes
  push ecx				; backup number of relocs * 8
  externfunc mem.alloc			; get memory for reloc table
  pop ecx				; restore number of relocs * 8
.pop_1_ebp_err_redir0:			;
  jc near .pop_1_ebp_err		; 
					;
					; read reloc table
					;-----------------
  call [esi+file_op_table.read]		;
  jc short .pop_1_ebp_err_redir0	;
					;
  pop eax				; restore ptr to sym table
  mov esi, [eax+edx*4]			;
  shr ecx, 3				;
  push edi				;
  push ecx				;
  push ebx				;

  ;; tos = number of sections
  ;; EAX = ptr to sym table
  ;; EBX = available
  ;; ECX = number of relocs
  ;; EDX = section number we are on
  ;; EBP = ptr to cur sect in sect table
  ;; ESI = location of cur sect in mem
  ;; EDI = ptr to reloc table

.do_abs_reloc:				;
  add esi, [edi+ubf_reloc.target]	; ESI = target
  mov ebx, [edi+ubf_reloc.sym]		;
  mov ebx, [eax+ebx*4]			;
  add [esi], ebx			;
  sub esi, [edi+ubf_reloc.target]	; ESI = sect location (as it was)
					;
  add edi, byte ubf_reloc_size		;
  dec ecx				;
  jnz .do_abs_reloc			;
					;
  pop ebx				;
  pop ecx				;
					;
  pop edi				;
  xchg eax, edi				;
  externfunc mem.dealloc		; deallocate reloc table
  xchg eax, edi				;
					;
.abs_done:				;
					; process relative relocs
  					;------------------------
  mov ecx, [ebp+ubf_sect.rel_num]	; load number of relocs
  jecxz .rel_done			; if none to do, skip all this
					;
  push eax				; save ptr to sym table
					;
					; seek to table
					;--------------
  push edx				; backup section id
  mov esi, [ebx]			; esi = file_op_table
  xor edx, edx				; seek addr high 32bits = 0
  mov eax, [ebp+ubf_sect.rel_reloc]	; seek addr low 32bits = off to relocs
  dbg lprint "executioner: seeking to 0x%x for rel reloc table", DEBUG, eax
  call [esi+file_op_table.seek_start]	; seek
  pop edx				; restore section id
  jc short .pop_ebp_err_redir0		;
					;
  %if ubf_reloc_size <> 8		;
    %error "ubf_reloc_size assumed to be 8 and it's not"
  %endif				;
  					; allocate memory for relocs
					;---------------------------
  shl ecx, 3				; each reloc is 8 bytes
  push ecx				; save number of relocs * 8
  externfunc mem.alloc			; alloc it
  pop ecx				; restore number of relocs * 8
  jc short .pop_ebp_err_redir0		;
					;
					; read relocs
					;------------
  call [esi+file_op_table.read]		;
.pop_ebp_err_redir0:			;
  jc near .pop_ebp_err			;
					;
  pop eax				; restore ptr to sym table
  mov esi, [eax+edx*4]			;
  shr ecx, 3				;
  push edi				;
  push ecx				;
  push ebx				;

  ;; tos = number of sections
  ;; EAX = ptr to sym table
  ;; EBX = availible
  ;; ECX = number of relocs
  ;; EDX = section number we are on
  ;; EBP = ptr to cur sect in sect table
  ;; ESI = location of cur sect in mem
  ;; EDI = ptr to reloc table

.do_rel_reloc:
  add esi, [edi+ubf_reloc.target]	; ESI = target
  mov ebx, [edi+ubf_reloc.sym]
  mov ebx, [eax+ebx*4]
  add [esi], ebx
  sub [esi], esi
  sub esi, [edi+ubf_reloc.target]	; ESI = sect location (as it was)

  add edi, byte ubf_reloc_size
  dec ecx
  jnz .do_rel_reloc
  
  pop ebx
  pop ecx
  
  pop edi
  xchg eax, edi
;  externfunc mem.dealloc	; deallocate reloc table
  xchg eax, edi

.rel_done:

  ; done doing section, move to next
  add ebp, byte ubf_sect_size	; move to next section
  inc edx
  dec dword[esp]
  jnz .relocate_section

  pop eax
  pop ebp

  ;--------------------------------------------------
  ; clean up and call the program

  mov esi, [ebx]
  call [esi+file_op_table.close]

  mov eax, [ebp-stack.header]
  mov ebx, [ebp-stack.sym_table]
  movzx edx, byte[eax+ubf_header.entry_sect]
  mov edx, [ebx+edx*4]
  add edx, [eax+ubf_header.entry_offset]	; EDX = entry location in mem
  
;  externfunc mem.dealloc	; free header
  mov eax, ebx
;  externfunc mem.dealloc	; free symbol table
  mov eax, [ebp-stack.sect_table]
;  externfunc mem.dealloc	; free section table

  dbg lprint "executioner: entry point at 0x%x", DEBUG, edx
  mov edi, [ebp-stack.edi]
  mov esp, ebp
  retn

;----------------------------------

.pop_1_ebp_err:
  add esp, byte 4

.pop_ebp_err:
  pop ebp

.error:
  dbg lprint "executioner: got error %d; aborting", DEBUG, eax
  mov esp, ebp
  stc
  retn

.not_valid_ubf:
  lprint "executioner: file is not valid UBF", FATALERR, edx
  mov eax, edi
;  externfunc mem.dealloc
  call [esi+file_op_table.close]
  stc
  jmp short .error

.unable_to_lookup_global:
  lprint "executioner: required vid %u not registered", FATALERR, edx
  mov ebx, [ebp-stack.fp]
  mov esi, [ebx+file_descriptor.op_table]
  call [esi+file_op_table.close]
  mov eax, __ERROR_VID_NOT_FOUND__
  stc
  jmp short .error

;                                           -----------------------------------
;                                                               process.cleanup
;==============================================================================

globalfunc process.cleanup
;>
;; cleans up after execing an app, doing things such as deallocating memory
;; that was allocated by executioner. This should normally be called by the
;; thread engine when it terminates the process.
;;
;; parameters:
;; -----------
;; EDX = ptr to cleanup info, from process info struc
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;<

  ; XXX we don't yet build propper cleanup data

  clc
  retn

;what was used before, after the CALL to the app returned:
;  pop ebp
;  push eax	; save program's return value
;  mov eax, [ebp-stack.prev_stack]
;  mov [last_process_info], eax
;  ; ...do our stuff
;  mov esi, [ebp-stack.to_be_freed]
;  mov ecx, [esi]
;.free_loop:
;  mov eax, [esi+ecx*4]
;  dbg_print "freeing stuff at 0x",1
;  dbg_print_hex eax
;  dbg_term_log
;;  externfunc mem.dealloc	; XXX this block has already been freed
;  dec ecx
;  jnz .free_loop
;
;  mov eax, esi
;;  externfunc mem.dealloc
;
;  pop eax
;  mov esp, ebp
;  clc
;  retn

;                                           -----------------------------------
                                                                section .c_info
;==============================================================================

;version
db 0,0,1,'a'   ;0.0.1 alpha
dd str_cellname
dd str_author
dd str_copyright

str_cellname: db "Executioner - Dynamic Linker",0
str_author: db "Phil Frost",0
str_copyright: db "Distributed under BSD License",0
