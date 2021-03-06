; ATTENTION! This include must be generated by some script from u3l.h or by u3l itself
; atm, it is hand-written
;
; anyway, keep it in sync with src/tools/u3l/u3l.h hdr_core struct

; hdr_core for boot.asm and osw.asm
; (for formatting purposes tab = 8)

  struc hdr_core
.signature		resd 1	; 0
.revision		resb 1	; 4
.reserved		resb 1	; 5
.cell_count		resw 1	; 6
.last_mem_used		resd 1	; 8
.core_size		resd 1	; 12
.core_checksum		resd 1	; 16
.mboot_magic		resd 1	; 20
.mboot_flags		resd 1	; 24
.mboot_checksum		resd 1	; 28
.mboot_header_addr	resd 1	; 32
.core_offset		resd 1	; 36
.mboot_load_end_addr	resd 1	; 40
.mboot_bss_end_addr	resd 1	; 44
.mboot_entry		resd 1	; 48
.osw_entry		resd 1	; 52
.code_patchwork		resb 12	; 56
  endstruc			; 68

  struc core_init_hdr
.moves			resd 1	; 0
.onetime_inits		resd 1	; 4
.zeroizes		resd 1	; 8
.inits			resd 1	; 12
  endstruc			; 16

  struc core_op_move
.cell_id		resw 1	; 0
.source			resd 1	; 2
.destination		resd 1	; 6
.dword_count		resd 1	; 10
  endstruc			; 14

  struc core_op_init
.cell_id		resw 1	; 0
.entry_point		resd 1	; 2
.parameter_array	resd 1	; 6
.parameter_count	resb 1	; 10
  endstruc			; 11

  struc core_op_zeroize
.cell_id		resw 1	; 0
.destination		resd 1	; 2
.dword_count		resd 1	; 6
  endstruc			; 10

  struc core_symbol_hdr
.symbol_id		resd 1	; 0
.provider_count		resw 1	; 4
.user_count		resw 1	; 6
  endstruc			; 8

  struc core_cell_info
.version		resd 1	; 0
.name_str		resd 1	; 4
.author_str		resd 1	; 8
.copyright_str		resd 1	; 12
  endstruc			; 16
