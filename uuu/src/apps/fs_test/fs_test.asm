;; $Header: /cvsroot/uuu/uuu/src/apps/fs_test/fs_test.asm,v 1.9 2001/09/15 03:38:29 daboy Exp $
;; A tempoary program to test the FS

;                                           -----------------------------------
;                                                                      includes
;==============================================================================

%include "../../cells/storage/ozone/strucs.inc"

;                                           -----------------------------------
;                                                                        macros
;==============================================================================

%macro print 1+
[section .data]
%%str: db "(FS test) ",%1,1
__SECT__

  push esi
  mov esi, %%str
  externfunc string_out, system_log
  pop esi
%endmacro

;                                           -----------------------------------
;                                                                       app on!
;==============================================================================

global app_fs_test
app_fs_test:

;                                           -----------------------------------
;                                                    write the data to the disk
;==============================================================================

print "Writing the disk image to the disk",0

mov ecx, test_image.end - test_image
mov esi, test_image
extern p_disk
mov edi, [p_disk]
add edi, 512		; start writing at the seccond sector
rep movsb

;                                           -----------------------------------
;                                                                   do the test
;==============================================================================

print "opening file: ",0
mov esi, strings.filename
externfunc string_out, system_log
externfunc open, file
jc .didnt_work

mov edi, strings.buffer
mov ecx, test_image.end_files - test_image.files
mov ebp, [ebx]
call [ebp+file_op_table.read]

mov esi, strings.buffer
externfunc string_out, system_log

retn

.didnt_work:
; it didn't work :/
print "it didn't work",0
retn

;                                           -----------------------------------
;                                                                    disk image
;==============================================================================

; this data gets copied to the disk starting at the seccond sector, right after
; the boot sector, or on byte 512, or however else you want to think of it.
align 512
test_image:

db 1		; number of elements in file list
times 31 db 0	; fake a file list header

dd 2			; sector file starts on
dd .end_files - .files	; size of file in bytes
db "test"		; filename
times 24-4 db 0		; pad to 24 bytes

align 512, db 0

.files:
db "This string has been sucessfully read from disk; cool eh?",0
.end_files:

.end:

;                                           -----------------------------------
;                                                                          data
;==============================================================================

strings:
  .filename:	db "/test",0	; filename of file to try to open
  .buffer:	times test_image.end_files - test_image.files db 0

p_file_handle:	dd 0	; FH of the file we open
p_file_op_table:dd 0	; op table of the file
