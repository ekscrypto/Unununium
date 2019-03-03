;; $Header: /cvsroot/uuu/dimension/cell/fs/devfs/devfs.asm,v 1.2 2002/01/23 01:44:59 jmony Exp $
;;
;; DevFS; a filesystem for device nodes
;; Copyright (C) 2001 by Phil Frost
;; Distributed under the BSD license, see "license" for details
;;
;; status:
;; -------
;; young, but stable, and terribly simple.
;;
;; todo:
;; -----
;; much of this code is cut and pasted from ozone, those functions should be
;; made global and shared.

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_
%define _TABLE_SIZE_	4	; log 2 number of entries in the hash table

;                                           -----------------------------------
;                                                                      includes
;==============================================================================


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc device_node	; a hash table node
  .legnth:		resd 1	; legnth of the string
  .next:		resd 1	; ptr to next node in chain
  .down:		resd 1	; ptr to hash table of files one level down
  .open_function:	resd 1	; ptr to open function
  .momento:		resd 1	; dword passed on to device's open function
  .name:		; the string follows... (no null!)
endstruc


section .c_info
	db 1,0,0,"a"	; not sure which revision this is - ask indigo ;)
	dd str_title
	dd str_author
	dd str_copyrights

	str_title:
	db "DevFS",0

	str_author:
	db "indigo",0

	str_copyrights:
	db "BSD Licensed",0



;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init
global _start
_start:
;;-----------------------------------------------------------------------------
;; When we receive control in this part the registers contain:
;;
;; - EAX        Options (currently unused)
;; - ECX        Size in bytes of the free memory block reserved for our use
;; - EDI        Pointer to start of free memory block
;; - ESI        Pointer to CORE header
;;
;; These must be left as they are found.
;;------------------------------------------------------------------------------

init:
  mov ecx, (1 << _TABLE_SIZE_) * 4
  externfunc mem.alloc
  jc .mem.alloc_failed
  dbg_print "allocated root hash table at 0x",1
  dbg_print_hex edi
  dbg_term_log
  mov [root_hash_table], edi
  xor eax, eax
  shr ecx, 2
  rep stosd
  
  mov edx, __FS_TYPE_DEVFS__
  mov eax, _mount
  externfunc vfs.register_fs_driver
  
  mov esi, .mount_point
  mov edx, __FS_TYPE_DEVFS__
  externfunc vfs.mount

  clc
  retn

.mem.alloc_failed:
  lprint {"devfs: unable to allocate memory",0xa}, FATALERR
  stc
  retn

.mount_point: db "/dev",0


;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                devfs.register
;==============================================================================

globalfunc devfs.register
;>
;; This registers a device and creates a node for it in the FS.
;;
;; parameters:
;; -----------
;; EBX = pointer to open function of device. Read below for details
;; EBP = passed on to the open function when later called; use this to determine
;;   what is being opened. It could be a pointer to a data strucure, just a
;;   dword, whatever.
;; ESI = pointer to name of device. This would be '/hda1' or something along
;; those lines.
;;
;; returned values:
;; ----------------
;; all registers except EAX = unmodified
;; errors as usual
;;
;; the open function:
;; ------------------
;; Each time some app opens a device, this function gets called. The specs are:
;;   
;;   parameters:
;;   -----------
;;   EBP = the same value that was in EBP when the device was registered
;;   EDX = ptr to FS descriptor
;;
;;   returned values:
;;   ----------------
;;   EBX = ptr to file handle
;;   errors as usual
;;   registers need not be preserved (devfs saves them)
;;
;; Because more than one app may open a device at a time, a new file handle
;; should be allocated on each call. DevFS does not fill out any part of the
;; file descriptor; that's up to you.
;<

  dbg_print "{DevFS} registering device: ",1
  %ifdef _DEBUG_
  externfunc sys_log.print_string
  %endif
  
  pushad

  call _get_node
  mov eax, [root_hash_table]
  jmp short .enter
  
.down:
  dbg_print "getting down node",0
  add esi, ecx
  call _get_node
  jc near .found_it

  mov eax, [edi+device_node.down]
.enter:
  ; ESI = ptr to new node
  ; ECX = legnth of that node

  test eax, eax
  jz .create_new_hashtable

  mov edx, 0xdeadbeef
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value
  dbg_print "generated hash ",1
  dbg_print_hex edx
  dbg_term_log
  ; EDX = string hash

  call _seek_hashtable	; look for the node
  ; EDI = ptr to node or 0
  jnc .down

.insert_into_hashtable:
  ;; EAX = ptr to table to insert into
  ;; ESI = ptr to string to insert
  ;; EDX = hash of that string
  ;; ECX = legnth of that string
  
  push ecx
  push ebx
  push eax
  push edx
  add ecx, byte device_node_size + 1
  externfunc mem.alloc
  dbg_print "created node at 0x",1
  dbg_print_hex edi
  dbg_print " for: ",1
  %ifdef _DEBUG_
  externfunc sys_log.print_string
  %endif
  pop edx
  pop eax
  
  xor ecx, ecx
  mov dword[edi+device_node.open_function], ecx
  mov dword[edi+device_node.down], ecx
  
  pop ebx
  
  dbg_print "inserting into ",1
  dbg_print_hex eax
  dbg_term_log
  mov ecx, [eax+edx*4]
  mov [eax+edx*4], edi
  mov [edi+device_node.next], ecx

  pop ecx

  mov [edi+device_node.legnth], ecx
  test ecx, ecx
  jz .no_copy
  push edi
  add edi, byte device_node.name
  rep movsb
  mov byte [edi], 0
  pop edi
.no_copy:

  call _get_node
  jc .done_allocating
  ; ESI = new node
  ; ECX = new legnth

  ; there are more nodes; make a hash table to hold them

.create_new_hashtable:
  dbg_print "created new hashtable at 0x",1
  ; EDI = ptr to node to create child hash table to
  push edx
  push ecx
  push edi
  mov ecx, (1 << _TABLE_SIZE_) * 4
  externfunc mem.alloc
  dbg_print_hex edi
  dbg_term_log
  pop edx
  mov [edx+device_node.down], edi
  push edi
  xor eax, eax
  shr ecx, 2
  rep stosd
  pop eax
  pop ecx
  pop edx
  
  mov edx, 0xdeadbeef
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value
  dbg_print "generated hash ",1
  dbg_print_hex edx
  dbg_term_log
  ; EDX = string hash

  jmp .insert_into_hashtable

.done_allocating:
  mov [edi+device_node.open_function], ebx
  mov [edi+device_node.momento], ebp
  popad
  clc
  retn
  
.found_it:
  ; EDI = ptr to node
  dbg_print "found existing node",0
  cmp dword[edi+device_node.open_function], 0	; see if this file exists
  jne .exists
  mov [edi+device_node.open_function], ebx
  mov [edi+device_node.momento], ebp
  popad
  clc
  retn

.exists:
  ; the node they are tring to register has already been registered :/
  dbg_print "device already exists",0
  mov eax, __ERROR_FILE_EXISTS__
  stc
  popad
  retn
;                                           -----------------------------------
;                                                               _seek_hashtable
;==============================================================================

_seek_hashtable:
;>
;; parameters:
;; -----------
;; EDX = hash of string to look for
;; ESI = ptr to that string
;; ECX = legnth of that string
;; EAX = ptr to hash table to look in
;;
;; returned values:
;; ----------------
;; CF = 0: node was found
;;   EDI = node of string
;; CF = 1: node was not found
;;   EDI = 0
;;
;; all other registers unmodified
;<

  dbg_print "seeking in 0x",1
  dbg_print_hex eax
  dbg_print " for hash 0x",1
  dbg_print_hex edx
  dbg_print " legnth 0x",1
  dbg_print_hex ecx
  dbg_print ": ",1
  %ifdef _DEBUG_
  externfunc sys_log.print_string
  %endif
  mov edi, [eax+edx*4]		; EAX = ptr to possible node
  test edi, edi
  jz .could_not_find

.find_node:
  ; now we make sure it is really the one
  ; check 1: compare legnth
  dbg_print "checking legnth...",1
  cmp ecx, [edi+device_node.legnth]
  jne .try_next
  
  ; check 2: compare the string
  dbg_print "checking string...",1
  test ecx, ecx
  jz .pass_2		; automaticly pass if legnth = 0
  push edi
  push esi
  push ecx
  add edi, device_node.name
  rep cmpsb
  pop ecx
  pop esi
  pop edi
  jne .try_next
.pass_2:
  dbg_print "found the node",0
  ; found the node, return
  clc
  retn

.try_next:
  dbg_print "failed; tring next node",0
  mov edi, [edi+device_node.next]
  test edi, edi
  jnz .find_node

.could_not_find:
  dbg_print "could not find node",0
  stc
  retn

;                                           -----------------------------------
;                                                                        __open
;==============================================================================

__open:
;>
;; parameters:
;; -----------
;; ESI = ptr to string to open
;;
;; returned values:
;; ----------------
;; EBX = file descriptor of opened node
;; errors as usual
;; registers not saved
;<

dbg_print "{DevFS} opening node: ",1
%ifdef _DEBUG_
externfunc sys_log.print_string
%endif

  push edx

  call _get_node
  mov edx, 0xdeadbeef
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value
  
  mov eax, [root_hash_table]
.loop:
  call _seek_hashtable
  jc .file_not_found	; if we didn't find the node, that's bad

  add esi, ecx
  call _get_node
  jc .found_it
  mov edx, 0xdeadbeef
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value

  mov eax, [edi+device_node.down]	; go down one level
  test eax, eax				; if it's null, we can't find the file
  jnz .loop

  dbg_print "{DevFS} hit a dead end center node",0
.file_not_found:
  pop edx
  mov eax, __ERROR_FILE_NOT_FOUND__
  stc
  retn

.found_it:
  dbg_print "{DevFS} found complete match",0
  cmp dword[edi+device_node.open_function], 0
  je .file_not_found
  mov ebp, [edi+device_node.momento]
  pop edx		; restore ptr to fs_descriptor
  call [edi+device_node.open_function]
  retn

;                                           -----------------------------------
;                                                                        __list
;==============================================================================

__list:
;>
;; parameters:
;; -----------
;;  ESI = pointer to string of the directory name to list
;;  EDI = pointer to callback function that will receive each entry of the
;;        directory listing
;;  EDX = pointer to fs descriptor
;;        (provided by ozone, not user acquired)
;;
;; returned values:
;; ----------------
;; registers and errors as usual
;;
;; callback:
;; ---------
;;   parameters:
;;   -----------
;;   ESI = pointer to filename (valid only until the callback returns)
;;       = NULL to indicate end of directory listing
;;   EDX:EAX = file size in bytes
;;   EBX = type of file
;;         0 = standard file
;;         1 = directory
;;         2 = symbolic link
;;         3 = special device
;;
;;   returned values:
;;   ----------------
;;   CF = 0: continue directory listing
;;   CF = 1: abort directory listing
;<

dbg_print "{DevFS} listing node: ",1
%ifdef _DEBUG_
externfunc sys_log.print_string
%endif

  push edi		; save ptr to callback

  call _get_node
  test ecx, ecx		; if ecx = 0 we are opening root '/'
  jz .list_root
  mov edx, 0xdeadbeef
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value
  
  mov eax, [root_hash_table]
.loop:
  call _seek_hashtable
  jc .file_not_found	; if we didn't find the node, that's bad

  add esi, ecx
  call _get_node
  jc .found_it
  mov edx, 0xdeadbeef
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value

  mov eax, [edi+device_node.down]	; go down one level
  test eax, eax				; if it's null, we can't find the file
  jnz .loop

  dbg_print "{DevFS} hit a dead end center node",0
.file_not_found:
  pop edi
  mov eax, __ERROR_FILE_NOT_FOUND__
  stc
  retn

.list_root:
  mov ebx, [root_hash_table]
  test ebx, ebx
  pop edi
  jz .end_list
  jmp short .start_listing

.found_it:
  dbg_print "{DevFS} found complete match",0
  ;; EDI = ptr to node

  mov ebx, [edi+device_node.down]
  pop edi
  test ebx, ebx
  jz .end_list

.start_listing:
  mov ecx, 1 << _TABLE_SIZE_
.list_hash_table:
  mov esi, [ebx+ecx*4-4]
  test esi, esi
  jz .next_entry
.list_hash_entry:
  pushad
  
  xor ebx, ebx
  cmp dword[esi+device_node.down], byte 0
  jnz .is_directory
  add ebx, byte 2
.is_directory:
  inc ebx
  
  add esi, byte device_node.name
  xor edx, edx
  xor eax, eax
  call edi
  popad
  jc .done

  mov esi, [esi+device_node.next]
  test esi, esi
  jnz .list_hash_entry
.next_entry:
  dec ecx
  jnz .list_hash_table

.end_list:
  dbg_print "ending list",0
  xor esi, esi
  call edi
.done:
  clc
  retn

;                                           -----------------------------------
;                                                                     _get_node
;==============================================================================

_get_node:
;>
;; this function takes a string such as '/fu/bar/bleh' and breaks it up into
;; 'fu' 'bar' and 'bleh' and also returns the legnth of these substrings. It
;; doesn't accually modify or create the strings, it just scans the existing
;; one.
;;
;; Wherever ESI points, the next node will be pointed to by ESI on return. So,
;; givin the string '/fu/bar/bleh' ESI will point to the 'fu', then the 'bar',
;; then 'bleh', each time returning in ECX the legnth: 2, then 3, then 4.
;;
;; parameters:
;; -----------
;; ESI = string
;;
;; returned values:
;; ----------------
;; CF = 0:
;;   ESI = new node
;;   ECX = legnth of node
;;   
;; CF = 1: there are no more nodes
;;   ESI = ptr to the null terminator of the string
;;   ECX = unmodified
;; 
;; in both cases:
;;   all other registers = unmodified
;< 

  ; eat up the first char; should be a /. If it's a 0 we have reached the end.
  cmp byte[esi], 0
  je .no_more_nodes

  ; scan for the next '/' or 0
  xor ecx, ecx
  inc esi
  jmp short .scan_enter

.scan:
  inc ecx
  inc esi
.scan_enter:
  cmp byte[esi], '/'
  je .done
  cmp byte[esi], 0
  jne .scan

.done:
  test ecx, ecx
  jz .no_more_nodes
  sub esi, ecx		; put esi back
  clc
  retn

.no_more_nodes:
  stc
  retn

;                                           -----------------------------------
;                                                                       __error
;==============================================================================

__error:
dbg_print "{DevFS} shit happened.",0
xor eax, eax
dec eax
stc
retn


_mount:
;; at this point:
;; ESI = pointer to null-terminated string of what we are mounting under
;; EAX = what to mount (ignored, devfs doesn't mount anything)
;;
;; We have to make a fs_descriptor and call __register,mountpoint to complete the
;; process.

  mov edx, our_fs_descriptor
  externfunc vfs.register_mountpoint
  retn

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data

our_fs_descriptor: istruc fs_descriptor
  at fs_descriptor.open,	dd __open
  at fs_descriptor.list,	dd __list
  at fs_descriptor.check_perm,	dd __error
iend

devices:	dd 0	; ptr to devices tree
root_hash_table:dd 0	; ptr to root hash table
