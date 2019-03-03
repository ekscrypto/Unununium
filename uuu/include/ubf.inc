; $Header: /cvsroot/uuu/uuu/include/ubf.inc,v 1.1 2001/10/31 12:24:49 daboy Exp $

%define ubf_secttype_prog		0
%define ubf_secttype_cinit		1
%define ubf_secttype_onetimeinit	2
%define ubf_secttype_cinfo		3
%define ubf_secttype_uninit_data	4
%define ubf_secttype_trash		-1
%define ubf_magic			0x4642557F

struc ubf_header
  .magic:	resd 1
  .checksum:	resd 1
  .req_features:resd 1
  .sect_table:	resd 1
  .num_externs:	resd 1
  .extern_table:resd 1
  .stack_size:	resd 1
  .entry_offset:resd 1
  .entry_sect:	resb 1
  .ubf_version:	resb 1
  .req_cpu:	resb 1
  .num_sections:resb 1
endstruc

struc ubf_reloc
  .target:	resd 1
  .sym:		resd 1
endstruc

struc ubf_sect
  .loc:		resd 1
  .size:	resd 1
  .abs_num:	resd 1
  .abs_reloc:	resd 1
  .rel_num:	resd 1
  .rel_reloc:	resd 1
  .type:	resb 1
  .reserved:	resb 3
endstruc
