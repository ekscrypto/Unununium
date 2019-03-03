; $Header: /cvsroot/uuu/uuu/include/ozone.inc,v 1.1 2001/09/25 01:09:34 daboy Exp $
; vim: syntax=uuu

;                                           -----------------------------------
;                                                                   file_handle
;==============================================================================

struc file_descriptor
  .op_table:		resd 1	; ptr to opperation table
  .fs_descriptor:	resd 1	; ptr to the file descriptor this file is on
  ; file systems may put additional data here
endstruc

;                                           -----------------------------------
;                                                                     fs_handle
;==============================================================================

struc fs_descriptor
  .open:	resd 1	; ptr to open function for FS
  .list:	resd 1	; ptr to list (as in list directories) function
  .check_perm:	resd 1	; ptr to check perms function
  ; file systems may put additional info here
endstruc

;                                           -----------------------------------
;                                                                     file_info
;==============================================================================

struc file_info
  .created:	resq 1	; uuudate of creation
  .modified:	resq 1	; uuudate of last modification
  .size:	resq 1	; size of file
  ;.type:	resd 1	; type of file, see %defines below
endstruc

;                                           -----------------------------------
;                                                                    file types
;==============================================================================

%define __FILE_TYPE_UNKNOWN__	0
%define __FILE_TYPE_CONSOLE__	1
%define __FILE_TYPE_FILE__	2

;                                           -----------------------------------
;                                                                 file_op_table
;==============================================================================

struc file_op_table
  .close:	resd 1
  .read:	resd 1
  .write:	resd 1
  .raw_read:	resd 1
  .raw_write:	resd 1
  .seek_cur:	resd 1
  .seek_start:	resd 1
  .seek_end:	resd 1
  .read_fork:	resd 1
  .write_fork:	resd 1
  .link:	resd 1
  .unlink:	resd 1
  .create:	resd 1
  .rename:	resd 1
  .copy:	resd 1
  .truncate:	resd 1
  .attrib:	resd 1
endstruc

;                                           -----------------------------------
;                                                                      fs types
;==============================================================================

%define __FS_TYPE_HACKFS__	1
%define __FS_TYPE_DEVFS__	2
%define __FS_TYPE_EXT2__	3
;; To aquire a FS type contact daboy@xgs.dhs.org
