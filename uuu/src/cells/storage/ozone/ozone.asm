;; $Header: /cvsroot/uuu/uuu/src/cells/storage/ozone/ozone.asm,v 1.29 2001/12/10 16:50:10 instinc Exp $
;; 
;; Ozone VFS cell
;; Copyright (C) 2001 by Phil Frost.
;; This software may be distributed under the terms of the BSD license.
;; See file 'licence' for details.
;;
;; status:
;; -------
;; Mostly working, although fancy things like unmouting are not yet supported.
;;
;; XXX the process.get|set_wd functions should not be here

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_
%define _TABLE_SIZE_	4	; log 2 number of entries in the hash table
%define HASH_SEED	0xdeadbeef	; seed used for fasthash calls


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc mountpoint_node	; a ttree
  .length:	resd 1	; length of string
  .next:	resd 1
  .down:	resd 1
  .fs_descriptor:	resd 1
  .name:	; string goes here
endstruc

struc fs_type_node	; a btree
  .left:	resd 1
  .right:	resd 1
  .type:	resd 1	; type of fs
  .mount:	resd 1	; ptr to mount function
endstruc

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init
;;-----------------------------------------------------------------------------
;; When we receive control in this part the registers contain this:
;;
;; - EAX        Options (currently unused)
;; - ECX        Size in bytes of the free memory block reserved for our use
;; - EDI        Pointer to start of free memory block
;; - ESI        Pointer to CORE header
;;
;; These must be left as they are found.
;;------------------------------------------------------------------------------

  jmp short start
init_done: db "[Ozone] Initialization completed ($Revision: 1.29 $)",0
start:
  pushad
  jmp short .start

.blagh:
  dmej 0x07023000

.start:
  ; XXX init the working directory
  mov ecx, 4
  externfunc mem.alloc
  jc .blagh
  mov dword[edi], '/'
  mov [cur_dir], edi

  mov edx, fs_type_node_size
  mov ecx, 4		; allocate in 16 block chunks
  externfunc mem.fixed.alloc_space
  jc .blagh
  mov [fs_type_space], edi

  mov ecx, (1 << _TABLE_SIZE_) * 4
  externfunc mem.alloc
  jc .blagh
  dbg_print "allocated root hash table at 0x",1
  dbg_print_hex edi
  dbg_term_log
  mov [root_hash_table], edi
  xor eax, eax
  shr ecx, 2
  rep stosd

  lprint {"ozone vfs: version $Revision: 1.29 $ loaded",0xa}, LOADINFO
  
  popad

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                       vfs.register_mountpoint
;==============================================================================

globalfunc vfs.register_mountpoint
;>
;; Mounts a node. Unlike unix, the node to mount under should NOT exist.
;; 
;; parameters:
;; -----------
;; ESI = ptr to string of node to mount under
;; EDX = ptr to fs_descriptor to use for the new node
;;
;; returned values:
;; ----------------
;; errors as usual
;<
  
  dbg_print "registering mountpoint: 0x",1
  %ifdef _DEBUG_
  externfunc sys_log.print_hex
  dbg_print " under ",1
  externfunc sys_log.print_string
  %endif

  pushad

  cmp byte[esi+1], 0
  je .mount_root

  mov ebx, edx

  call _get_node
  mov eax, [root_hash_table]
  jmp short .enter
  
.mount_root:
  dbg_print "mouting root FS",0
  mov [root_file_descriptor], edx
  popad
  clc
  retn

.down:
  dbg_print "getting down node",0
  add esi, ecx
  call _get_node
  jc near .found_it

  mov eax, [edi+mountpoint_node.down]
.enter:
  ; ESI = ptr to new node
  ; ECX = length of that node

  test eax, eax
  jz near .create_new_hashtable

  mov edx, HASH_SEED
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
  ;; ECX = length of that string
  
  push ecx
  push ebx
  push eax
  push edx
  add ecx, byte mountpoint_node_size + 1
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
  mov dword[edi+mountpoint_node.fs_descriptor], ecx
  mov dword[edi+mountpoint_node.down], ecx
  
  pop ebx
  
  dbg_print "inserting into ",1
  dbg_print_hex eax
  dbg_term_log
  mov ecx, [eax+edx*4]
  mov [eax+edx*4], edi
  mov [edi+mountpoint_node.next], ecx

  pop ecx

  mov [edi+mountpoint_node.length], ecx
  test ecx, ecx
  jz .no_copy
  push edi
  add edi, byte mountpoint_node.name
  rep movsb
  mov byte [edi], 0
  pop edi
.no_copy:

  call _get_node
  jc .done_allocating
  ; ESI = new node
  ; ECX = new length

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
  mov [edx+mountpoint_node.down], edi
  push edi
  xor eax, eax
  shr ecx, 2
  rep stosd
  pop eax
  pop ecx
  pop edx
  
  mov edx, HASH_SEED
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value
  dbg_print "generated hash ",1
  dbg_print_hex edx
  dbg_term_log
  ; EDX = string hash

  jmp .insert_into_hashtable

.done_allocating:
  mov [edi+mountpoint_node.fs_descriptor], ebx
  popad
  clc
  retn
  
.found_it:
  ; EDI = ptr to node
  dbg_print "found existing node",0
  cmp dword[edi+mountpoint_node.fs_descriptor], byte 0	; see if this file exists
  jne .exists
  mov [edi+mountpoint_node.fs_descriptor], ebx
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
;; parameters:
;; -----------
;; EDX = hash of string to look for
;; ESI = ptr to that string
;; ECX = length of that string
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

  dbg_print "seeking in 0x",1
  dbg_print_hex eax
  dbg_print " for hash 0x",1
  dbg_print_hex edx
  dbg_print " length 0x",1
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
  ; check 1: compare length
  dbg_print "checking length...",1
  cmp ecx, [edi+mountpoint_node.length]
  jne .try_next
  
  ; check 2: compare the string
  dbg_print "checking string...",1
  test ecx, ecx
  jz .pass_2		; automaticly pass if length = 0
  push edi
  push esi
  push ecx
  add edi, mountpoint_node.name
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
  mov edi, [edi+mountpoint_node.next]
  test edi, edi
  jnz .find_node

.could_not_find:
  dbg_print "could not find node",0
  stc
  retn

;                                           -----------------------------------
;                                                                     _get_node
;==============================================================================

_get_node:
;;
;; this function takes a string such as '/fu/bar/bleh' and breaks it up into
;; 'fu' 'bar' and 'bleh' and also returns the length of these substrings. It
;; doesn't accually modify or create the strings, it just scans the existing
;; one.
;;
;; Wherever ESI points, the next node will be pointed to by ESI on return. So,
;; givin the string '/fu/bar/bleh' ESI will point to the 'fu', then the 'bar',
;; then 'bleh', each time returning in ECX the length: 2, then 3, then 4.
;;
;; parameters:
;; -----------
;; ESI = string
;;
;; returned values:
;; ----------------
;; CF = 0:
;;   ESI = new node
;;   
;; CF = 1: there are no more nodes
;;   ESI = 
;; 
;; in both cases:
;;   all other registers except AL, unmodified
;; 

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
;                                                        vfs.register_fs_driver
;==============================================================================

globalfunc vfs.register_fs_driver
;>
;; This function is used to register a FS type (like "ext2") with ozone. This
;; type is used when something is mounted so that ozone can call the correct
;; FS.
;;
;; parameters:
;; -----------
;; EDX = FS type
;; EAX = pointer to mount function
;;
;; returned values:
;; ----------------
;; errors as usual
;<

  dbg_print "registering FS type",0

  mov ebx, [fs_types]
  test ebx, ebx
  jz .make_first_node
  
  call _seek_to_fs_type_node
  jnc .exists

.make_node:
  push edx
  push eax
  mov ecx, fs_type_node_size
  xor edx, edx
  mov edi, [fs_type_space]
  externfunc mem.fixed.alloc
  pop eax
  pop edx
  jc .error
  ; ebp is unmodified

  mov [ebp], edi	; link the new node up in the tree

  mov [edi+fs_type_node.mount], eax
  xor eax, eax
  mov [edi+fs_type_node.type], edx
  mov [edi+fs_type_node.right], eax
  mov [edi+fs_type_node.left], eax

  clc
.error:
  retn

.make_first_node:
  mov ebp, fs_types
  jmp short .make_node
  
.exists:
  mov eax, __ERROR_FS_TYPE_ALREADY_REGISTERED__
  stc
  retn

;                                           -----------------------------------
;                                                         _seek_to_fs_type_node
;==============================================================================

_seek_to_fs_type_node:
;;
;; a simple btree seek function with a really long name
;;
;; parameters:
;; -----------
;; EDX = value to seek to
;; EBX = node to start with
;;
;; returned values:
;; ----------------
;; All registers except EBP and EBX = unchanged
;; 
;; CF = 0: node was found
;;   EBX = ptr to mountpoint node
;; CF = 1: node was not found
;;   EBP = ptr to dword that should contain a pointer to the new nodes
;;

.cmp_node:
  cmp edx, [ebx+fs_type_node.type]
  ja .right
  jb .left

  ; they are equal
  clc
  retn

.right:
  lea ebp, [ebx+fs_type_node.right]
  mov ebx, [ebx+fs_type_node.right]
  jmp short .next_node

.left:
  lea ebp, [ebx+fs_type_node.left]
  mov ebx, [ebx+fs_type_node.left]

.next_node:
  test ebx, ebx
  jnz .cmp_node

  ; darn...hit a dead end
  stc
  retn

;                                           -----------------------------------
;                                                                     vfs.mount
;==============================================================================

globalfunc vfs.mount
;>
;; This function mounts a filesystem; not to be confused with
;; vfs.register_mountpoint which only is part of the mounting process.
;;
;; parameters:
;; -----------
;; ESI = pointer to null-terminated string of where to mount under
;; EDX = fs type to use (must have been registered with ozone already)
;; EAX = what to mount. This is a parameter passed on to the FS, so it could
;;       be a pointer to a string ("/dev/hda", "//host/share"), or just a
;;       dword.
;; ECX, EDI, EBP = passed on to the fs; can be used for additional fs-specific
;;                 options.
;;
;; returned values:
;; ----------------
;; errors as usual
;;
;; This function first looks up the FS type specified by the caller in ozone's
;; tables. It then calls that function with EAX, ECX, EDI, ESI, and EBP passed
;; on. That function must then construct a fs_descriptor and call
;; __register,mountpoint.
;<

  dbg_print "mounting filesystem",0

  push ebp
  mov ebx, [fs_types]
  test ebx, ebx
  jz .error_no_such_fs

  call _seek_to_fs_type_node
  jc .error_no_such_fs

  ; ebx = ptr to fs_type_node
  pop ebp
  ; all registers except EBX, EDX should be the same as when called
  call [ebx+fs_type_node.mount]
  retn

.error_no_such_fs:
  add esp, byte 4
  mov eax, __ERROR_UNKNOWN_FS_TYPE__
  stc
  retn

;                                           -----------------------------------
;                                                                vfs.check_perm
;==============================================================================

globalfunc vfs.check_perm
;>
;; Opens files...
;;
;; parameters:
;; -----------
;; ESI = ptr to null-terminated string of file to open
;;
;; returned values:
;; ----------------
;; errors as usual
;<

dbg_print "checking perms of file: ",1
%ifdef _DEBUG_
  externfunc sys_log.print_string
%endif

  mov eax, fs_descriptor.check_perm
  jmp short _fs_action
  
;                                           -----------------------------------
;                                                                      vfs.list
;==============================================================================

globalfunc vfs.list
;>
;; Opens files...
;;
;; parameters:
;; -----------
;; ESI = ptr to null-terminated string of file/dir to list
;;
;; returned values:
;; ----------------
;; errors as usual
;<

dbg_print "listing file: ",1
%ifdef _DEBUG_
  externfunc sys_log.print_string
%endif

  mov eax, fs_descriptor.list
  jmp short _fs_action

  
;                                           -----------------------------------
;                                                                      vfs.open
;==============================================================================

globalfunc vfs.open
;>
;; Opens files...
;;
;; parameters:
;; -----------
;; ESI = ptr to null-terminated string of file to open
;;
;; returned values:
;; ----------------
;; EBX = file descriptor
;; errors as usual
;<

dbg_print "opening file: ",1
%ifdef _DEBUG_
  externfunc sys_log.print_string
%endif

  mov eax, fs_descriptor.open
  ; spill over into _fs_action

;                                           -----------------------------------
;                                                                    _fs_action
;==============================================================================

_fs_action:
;>
;; calls one of the actions in the fs descriptor (open, list, etc)
;;
;; parameters:
;; -----------
;; EAX = offset within fs_descriptor to the action to call
;; ESI = ptr to null-terminated string of file
;; EDI = passed on to fs action
;;
;; returned values:
;; ----------------
;; dependant on action called
;<

dbg_print "{Ozone} opening node: ",1
%ifdef _DEBUG_
externfunc sys_log.print_string
%endif

  push eax
  push eax
  push edi

  call lib.string.filter_path
  mov esi, edi
  mov [esp+8], edi

  mov ebp, esi		; ebp will point to the sub-string for the fs
  mov ebx, [root_file_descriptor]	; ebx will hold the last found fs descriptor

  call _get_node
  mov edx, HASH_SEED
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value
  
  mov eax, [root_hash_table]
.loop:
  call _seek_hashtable
  jc .partial_match	; if we didn't find the node, that's bad

  add esi, ecx
  call _get_node
  jc .found_it

  cmp dword[edi+mountpoint_node.fs_descriptor], byte 0
  jz .no_new_fs

  ; we found a node with a new FS in it; update EBX
  dbg_print "found new fs",0
  mov ebx, [edi+mountpoint_node.fs_descriptor]
  lea ebp, [esi-1]

.no_new_fs:
  mov edx, HASH_SEED
  externfunc lib.string.fasthash
  and edx, (1 << _TABLE_SIZE_) - 1	; convert to a 4 bit hash value

  mov eax, [edi+mountpoint_node.down]	; go down one level
  test eax, eax				; if it's null, we can't find the file
  jnz .loop

.partial_match:
  test ebx, ebx
  jz .file_not_found
  dbg_print "{Ozone} found partial match; opening ",1
  mov esi, ebp
  pop edi
  pop eax
  mov edx, ebx
  call [ebx+eax]
  jc .error
  
  xchg [esp], eax
  externfunc mem.dealloc
  pop eax
  retn

.found_it:
  dbg_print "{Ozone} found complete match; opening root",0
  cmp dword[edi+mountpoint_node.fs_descriptor], byte 0
  jz .partial_match	; if this node doesn't contain a new FS, it's really
  mov esi, .root_str	; a partial match. If not, we are opening the root
  mov ebx, [edi+mountpoint_node.fs_descriptor]	; of the FS, so set the
  pop edi		; fs descriptor (EBX) and string (ESI) accordingly.
  pop eax
  mov edx, ebx
  call [ebx+eax]
  jc .error
  
  xchg [esp], eax
  externfunc mem.dealloc
  pop eax
  retn

.file_not_found:
  mov eax, __ERROR_FILE_NOT_FOUND__
  add esp, byte 12
  retn

.error:
  xchg [esp], eax
  externfunc mem.dealloc
  pop eax
  stc
  retn

align 4, db 0
.root_str: dstring '/'

;                                           -----------------------------------
;                                                                process.get_wd
;==============================================================================
; XXX this function is only here tempoarily until strontium is working

globalfunc process.get_wd
;>
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; ESI = ptr to dword-aligned string of current working directory; do not
;;         change this string directly.
;; registers and errors as usual
;<

  mov esi, [cur_dir]
  clc
  retn

;                                           -----------------------------------
;                                                                process.set_wd
;==============================================================================
; XXX this function is only here tempoarily until strontium is working

globalfunc process.set_wd
;>
;; parameters:
;; -----------
;; ESI = ptr to dword-aligned string of new working directory. This string will
;;         be deallocated by ozone when it's no longer being used; do not change
;;         the string directly.
;;
;; returned values:
;; ----------------
;; errors and registers as usual
;<

  push edi

  call lib.string.filter_path
  jc .error

  mov eax, esi
;  externfunc mem.dealloc

  mov [cur_dir], edi
  
.error:
  pop edi
  retn

;                                           -----------------------------------
;                                                        lib.string.filter_path
;==============================================================================

globalfunc lib.string.filter_path
;>
;; This filters a path string in the following ways:
;; 
;; * if the string is not an absloute path, it is made absloute by prepending
;;   the current working directory
;; * any . or .. are filtered out
;; * any trailing or double '/' are removed
;;
;; example:
;; "hey/./mom//../" => "/cwd/hey"
;;
;; The string in ESI will never be modified; a new string is always created
;; which should be deallocated with mem.dealloc after use.
;;
;; parameters:
;; -----------
;; ESI = ptr to byte aligned single null terminated string to filter
;;
;; returned values:
;; ----------------
;; EDI = filtered string, dword aligned and null terminated
;; registers and errors as usual
;; original sting in ESI will not be modified
;<

  pushad
  
  ; first, make a copy of the string and possibly prepend the CWD
  
  externfunc lib.string.find_length	; ECX = length of string
  cmp byte[esi], '/'
  je .absloute
  
  ; gotta prepend the CWD...
  push esi			; push ptr to supplied dir
  mov edx, ecx			; EDX = length of supplied dir
  call process.get_wd		; ESI = ptr to cwd
  externfunc lib.string.find_length_dword_aligned	; ECX = length of cwd
  mov ebx, ecx			; EBX = length of cwd
  lea ecx, [ecx+edx+5]		; ECX = length of both dirs, a '/' between them, and 4 nulls
  externfunc mem.alloc
  jc near .pop1error

  mov ecx, ebx			; ECX = length of cwd
  rep movsb
  mov byte [edi], '/'		; put a '/' between the CWD and file
  inc edi
  pop esi			; restore ptr to supplied dir
  mov ecx, edx			; ECX = length of supplied dir
  rep movsb
  mov byte[edi], 0		; dword termination will be put on later
  sub edi, edx
  sub edi, ebx
  dec edi			; EDI = ptr to full path (same as after mem.alloc)
  jmp short .filter_dots

.absloute:
  add ecx, byte 4		; make room for null
  externfunc mem.alloc
  jc near .pop1error

  lea ecx, [eax-4]
  rep movsb
  mov byte[edi], 0		; dword termination will be put on later
  lea ecx, [eax-4]
  sub edi, ecx			; EDI = ptr to full path

.filter_dots:
dbg_print "filtering dots",0
  ;; EDI = ptr to string to filter

  mov [esp], edi	; put our EDI into the EDI to be returned
  mov esi, edi		; ESI = ptr to path to filter

.filter_letter:
  ;; ESI = ptr to source char
  ;; EDI = ptr to dest. char
dbg_print "filtering letter",0
  mov al, [esi]
  cmp al, '/'
  je .found_slash
.write_letter:
  mov [edi], al
  inc esi
  inc edi
  cmp byte[esi], 0
  jnz .filter_letter

.wrap_it_up:
dbg_print "wrapping up",0
  cmp byte[edi-1], '/'		; check if the last char is '/'
  jne .wrap_already
  dec edi			; if so, dec edi so we put 0 over it instead
  cmp edi, [esp]		; but first, check if '/' is the only char
  jne .wrap_already
  inc edi			; if so, leave the '/' there
.wrap_already:
  mov dword[edi], 0		; terminate the string
  popad				; we put the value to return in EDI in already
  clc
  retn

.found_slash:
  cmp byte[esi+1], '/'
  je .double_slash
  
  cmp byte[esi+1], '.'
  je .possible_dot

  jmp short .write_letter

.double_slash:
dbg_print "double slash",0
  inc esi
  jmp short .found_slash

.possible_dot:
  cmp byte[esi+2], '.'
  je .possible_dot_dot
  cmp byte[esi+2], '/'
  je .slash_dot
  cmp byte[esi+2], 0
  jne .write_letter
.slash_dot:
  add esi, byte 2
  jmp short .found_slash

.possible_dot_dot:
dbg_print "possible dot dot",0
  cmp byte[esi+3], '/'
  je .slash_dot_dot
  cmp byte[esi+3], 0
  jne .write_letter
.slash_dot_dot:
dbg_print "slash dot dot",0
  add esi, byte 3
  cmp edi, [esp]
  je .found_slash
.backup:
  dec edi
  cmp byte[edi], '/'
  jne .backup
  jmp short .found_slash
  

.pop1error:
  pop ecx
  mov [esp+28], eax
  popad
  retn

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================

section .c_info
db 0, 0, 1, 'a'
dd str_cellname
dd str_author
dd str_copyrights
str_cellname:	dd "Ozone - VFS"
str_author:	dd 'Phil "Indigo" Frost (daboy@xgs.dhs.org)'
str_copyrights:	dd 'Copyright 2001 by Phil Frost; distributed under the BSD license'

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data

align 4
mountpoints:	dd 0	; ptr to the root node of the mountpoints t-tree
fs_types:	dd 0	; ptr to the root node of the fs types b-tree
cur_dir:	dd 0	; ptr to dword aligned string of cur. working directory
fs_type_space:	dd 0	; ptr to mem.fixed space for fs type nodes

root_hash_table:	dd 0
root_file_descriptor:	dd 0
