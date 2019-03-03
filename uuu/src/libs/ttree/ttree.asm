;; $Header: /cvsroot/uuu/uuu/src/libs/ttree/ttree.asm,v 1.12 2001/10/03 17:46:56 instinc Exp $
;;
;; Trinary tree manipulation macros ($Revision: 1.12 $)
;; Original Author: EKS - Dave Poirier (futur@mad.scientist.com)


%macro lib_unlink_node 10.nolist
;
; Values passed at declaration time to the macros are in the following order:
; param 1:	32bit register to use as pointer to node to unlink (param)
;		suggested: ESI
; param 2:	32bit register to use as pointer to root node variable (param)
;		suggested: EDI
;		special note: may also be a label
; param 3:	32bit register to use as parent node pointer (internally)
;		suggested: EAX
; param 4:	32bit register to use as left node pointer (internally)
;		suggested: EBX
; param 5:	32bit register to use as center node pointer (internally)
;		suggested: ECX
; param 6:	32bit register to use as right node pointer (internally)
;		suggested: EDX
; param 7:	offset from node pointer (param 1) to the parent node pointer
; param 8:	offset from node pointer (param 1) to the left node pointer
; param 9:	offset from node pointer (param 1) to the right node pointer
; param 10:	offset from node pointer (param 1) to the center node pointer
;
; this function also support a 'consistency check' option, to enable it, simply
; define _CONSISTENCY_CHECK_ before using the macro
;
; if consistency check is enabled, the routine will return CF=error code. When
; CF=0, unlinking was successfull and integrity of the nodes modified was
; verified, if CF=1, an inconsistency has been detected and the unlinking
; aborted as early as possible; some pointers may already have been modified.
;
; note, this is a callable macro, should be defined as a function that would
; be called from other part of the code, after completion of the task, this
; macro will execute a retn
;
  ; %{1} = pointer to node to unlink
  mov %{3}, [%{1} + %{7}]
  mov %{4}, [%{1} + %{8}]
   %ifdef _CONSISTENCY_CHECK_
    cmp %{4}, byte -1
    jz short %%dont_check_left
    cmp [%{4} + %{7}], %{1}
    jnz near %%error
    %%dont_check_left:
   %endif
  mov %{5}, [%{1} + %{10}]
   %ifdef _CONSISTENCY_CHECK_
    cmp %{5}, byte -1
    jz short %%dont_check_center
    cmp [%{5} + %{7}], %{1}
    jnz near %%error
    %%dont_check_center:
   %endif
  mov %{6}, [%{1} + %{9}]
   %ifdef _CONSISTENCY_CHECK_
    cmp %{6}, byte -1
    jz short %%dont_check_right
    cmp [%{6} + %{7}], %{1}
    jnz near %%error
    %%dont_check_right:
   %endif
  inc %{5}
  jnz short %%center_node_replacement
  dec %{5}
  inc %{4}
  jz short %%no_left_node
  dec %{4}
  inc %{6}
  jz short %%left_node_replacement
  dec %{6}
  ; right&left=present, center=null
  mov %{5}, [%{6} + %{8}]
  mov [%{6} + %{8}], %{4}
  mov [%{4} + %{7}], %{6}
%%search_leftmost:
  cmp dword [%{4} + %{9}], byte -1
  jz short %%relink_right_node
   %ifdef _CONSISTENCY_CHECK_
    push %{5}
    mov %{5}, [%{6} + %{8}]
    cmp [%{5} + %{7}], %{6}
    pop %{5}
    jnz near %%error
    cmp [%{6} + %{8}], edx
    jz near %%error
   %endif
  mov %{4}, [ebx + %{9}]
  jmp short %%search_leftmost
%%relink_right_node:
  mov [%{4} + %{9}], %{5}
  mov [%{5} + %{7}], %{4}
  mov [%{1} + %{8}], dword -1
  mov [%{1} + %{9}], dword -1
  mov %{5}, %{6}
  jmp short %%parent_node_update
%%left_node_replacement:
  mov [%{4} + %{7}], %{1}
  mov [%{1} + %{8}], %{5}
  mov %{5}, %{4}
  jmp short %%parent_node_update
%%no_left_node:
  inc %{6}
  jz short %%parent_node_update
  dec %{6}
  mov [%{6} + %{7}], %{3}
  mov [%{1} + %{9}], %{5}
  mov %{5}, %{6}
  jmp short %%parent_node_update
%%center_node_replacement:
  dec %{5}
  mov [%{1} + %{10}], dword -1
  mov [%{5} + %{7}], %{3}
   %ifdef _CONSISTENCY_CHECK_
    cmp dword [%{5} + %{8}], byte -1
    jnz short %%error
   %endif
  mov [%{5} + %{8}], %{4}
   %ifdef _CONSISTENCY_CHECK_
    cmp dword [%{5} + %{9}], byte -1
    jnz short %%error
   %endif
  mov [%{5} + %{9}], %{6}
%%parent_node_update:
  ; %{3} = pointer to parent node
  ; %{5} = new node to replace it
  ; %{1} = original node to unlink
  inc %{3}
  mov [%{1} + %{7}], dword %{5}
  jz short %%root_node_replacement
  dec %{3}
  cmp [%{3} + %{8}], %{1}
  jz short %%parent_node_is_left
  cmp [%{3} + %{10}], %{1}
  jz short %%parent_node_is_center
   %ifdef _CONSISTENCY_CHECK_
    cmp [%{3} + %{9}], %{1}
    jnz short %%error
   %endif
  mov [%{3} + %{9}], %{5}
   %ifdef _CONSISTENCY_CHECK_
    clc
   %endif
  retn
%%parent_node_is_center:
  mov [%{3} + %{10}], %{5}
   %ifdef _CONSISTENCY_CHECK_
    clc
   %endif
  retn
%%parent_node_is_left:
  mov [%{3} + %{8}], %{5}
   %ifdef _CONSISTENCY_CHECK_
    clc
   %endif
  retn
%%root_node_replacement:
   %ifdef _CONSISTENCY_CHECK_
    cmp [%{2}], %{1}
    jnz short %%error
   %endif
  mov [%{2}], %{5}
   %ifdef _CONSISTENCY_CHECK_
    clc
   %endif
  retn
   %ifdef _CONSISTENCY_CHECK_
%%error:
    stc
    retn
   %endif
%endmacro

%macro lib_locate_node 9.nolist
;;
;; This function searches in a trinary-tree for a matching entry.  In the case
;; where the entry wouldn't be found, it passes all the required information to
;; be able to easily and quickly link a new node in the tree.
;;
;; A consistency check is available.  In order to use it, define, before you
;; declare the macro, _CONSISTENCY_CHECK.
;;
;; Note: This macro should be declared and later called as a function. Once the
;; search is completeed, a 'retn' instruction is executed.
;;
;; Values passed at declaration time to the macros are in the following order:
;; param 1:	32bit register to use as parameter for the researched value
;;		suggested: EDX
;; param 2:	32bit register to use as pointer to root node variable
;;		suggested: EDI
;;		note: may also be a label or numeric value
;; param 3:	32bit register to use as returned offset in the anchor node in
;;		case value could not be located
;;		suggested: EAX
;; param 4:	32bit register to use as returned pointer to the anchor node in
;;		case the value could not be located
;;		suggested: ESI
;; param 5:	offset from node pointer to the parent node pointer
;: param 6:	offset from node pointer to the left node pointer
;; param 7:	offset from node pointer to the right node pointer
;; param 8:	offset from node pointer to the center node pointer
;; param 9:	offset from node pointer to the reference value
;;
;;
;; parameters at runtime:
;;------------
;; %{1} = 32bit value searched
;; returns: CF = 0, value found, %{4} = pointer to node with matching entry
;;             ZF = 1, single entry found
;;             ZF = 0, multiple matching entries found
;;          CF = 1, value not found, ESI = pointer to node that should be used
;;                  to create the new node in case insertion is wanted
;;             %{3} = offset within the node to link to, where anchor should be
;;
;; possible output values are:
;;----------------------------
;; CF = 0, ZF = 0
;;	Multiple matching entries were found
;; CF = 0, ZF = 1
;;	A single matching entry was found
;; CF = 1, %{3} != -1, %{4} = -1
;;	No matching entry found
;;	Tree currently contain no node, create new node as root
;; CF = 1, %{3} != -1, %{4} != -1
;;	No matching entry was found
;;	Tree isn't empty, ESI points to the node that should be used as anchor
;;	 point and EAX contain offset into that node to where anchor should be
;;	 placed
;; CF = 1, %{3} = -1
;;	Tree inconsistency detected, memory was corrupted or data was wrongly
;;        manipulated (may mean internal failure)
;;	This output will never be returned if _INCONSISTENCY_CHECK_ is disabled
;;
;;
  mov %{4}, [%{2}]
  cmp %{4}, byte -1
  jz short %%not_found
%%browsing:
  cmp %{1}, [%{4} + %{9}]
  ja short %%test_left_node_presence
  jb short %%test_right_node_presence
  mov %{3}, %{8}
  cmp [%{4} + %{8}], byte -1
  clc
  retn
%%right_would_be_link_point:
%%not_found:
  mov %{3}, %{7}
  stc
  retn
%%test_left_node_presence:
  cmp [%{4} + %{6}], byte -1
  jz short %%left_would_be_link_point
   %ifdef _CONSISTENCY_CHECK_
    mov %{3}, [%{4} + %{6}]
    cmp %{3}, %{4}				; make sure we aren't entering
    jz short %%error				;  an eternal loop
    cmp [%{3} + %{5}], %{4}			; make sure parent node ptr is
    jnz short %%error				;  valid
   %endif
  mov %{4}, [%{4} + %{6}]
  jmp short %%browsing
%%test_right_node_presence:
  cmp [%{4} + %{7}], byte -1
  jz short %%right_would_be_link_point
   %ifdef _CONSISTENCY_CHECK_
    mov %{3}, [%{4} + %{7}]
    cmp %{3}, %{4}				; make sure we aren't entering
    jz short %%error				;  an eternal loop
    cmp [%{3} + %{5}], %{4}
    jnz short %%error
   %endif
  mov %{4}, [%{4} + %{7}]
  jmp short %%browsing
%%left_would_be_link_point:
  mov %{3}, %{6}
  stc
  retn
   %ifdef _CONSISTENCY_CHECK_
%%error:
    mov %{3}, -1
    stc
    retn
   %endif
%endmacro

%macro lib_locate_ae_node 9.nolist
;;
;; This function searches in a trinary-tree for a matching entry (above or
;; equal).  In the case where the entry wouldn't be found, it passes all the
;; required information to be able to easily and quickly link a new node in
;; the tree.
;;
;; A consistency check is available.  In order to use it, define, before you
;; declare the macro, _CONSISTENCY_CHECK_.
;;
;; Note: This macro should be declared and later called as a function. Once the
;; search is completeed, a 'retn' instruction is executed.
;;
;; Values passed at declaration time to the macros are in the following order:
;; param 1:	32bit register to use as parameter for the researched value
;;		suggested: EDX
;; param 2:	32bit register to use as pointer to root node variable
;;		suggested: EDI
;;		note: may also be a label or numeric value
;; param 3:	32bit register to use as returned offset in the anchor node in
;;		case value could not be located
;;		suggested: EAX
;; param 4:	32bit register to use as returned pointer to the anchor node in
;;		case the value could not be located
;;		suggested: ESI
;; param 5:	offset from node pointer to the parent node pointer
;: param 6:	offset from node pointer to the left node pointer
;; param 7:	offset from node pointer to the right node pointer
;; param 8:	offset from node pointer to the center node pointer
;; param 9:	offset from node pointer to the reference value
;;
;;
;; parameters at runtime:
;;------------
;; %{1} = 32bit value searched
;; %{2} = pointer to root node pointer
;; returns: CF = 0, value found, %{4} = pointer to node with matching entry
;;             ZF = 1, single entry found
;;             ZF = 0, multiple matching entries found
;;          CF = 1, value not found, ESI = pointer to node that should be used
;;                  to create the new node in case insertion is wanted
;;             %{3} = offset within the node to link to, where anchor should be
;;
;; possible output values are:
;;----------------------------
;; CF = 0, ZF = 0
;;	Multiple matching entries were found
;; CF = 0, ZF = 1
;;	A single matching entry was found
;; CF = 1, %{3} != -1, %{4} = -1
;;	No matching entry found
;;	Tree currently contain no node, create new node as root
;; CF = 1, %{3} != -1, %{4} != -1
;;	No matching entry was found
;;	Tree isn't empty, ESI points to the node that should be used as anchor
;;	 point and EAX contain offset into that node to where anchor should be
;;	 placed
;; CF = 1, %{3} = -1
;;	Tree inconsistency detected, memory was corrupted or data was wrongly
;;        manipulated (may mean internal failure)
;;	This output will never be returned if _INCONSISTENCY_CHECK_ is disabled
;;
;;
  mov %{4}, [%{2}]
  mov %{3}, -1
  cmp %{4}, %{3}
  jz short %%not_found_root_closed
%%browsing:
  cmp %{1}, [%{4} + %{9}]
  ja short %%test_left_node_presence
  jb short %%test_right_node_presence
  mov %{3}, %{8}
  cmp [%{4} + %{8}], byte -1
  clc
  retn
%%left_would_be_link_point:
  cmp %{3}, byte -1
  jnz short %%safe_node_recover
%%not_found_root_closed:		;<-- just to make sure eax != -1
  mov %{3}, %{6}
%%not_found:
  stc
  retn
%%test_left_node_presence:
  cmp [%{4} + %{6}], byte -1
  jz short %%left_would_be_link_point
   %ifdef _CONSISTENCY_CHECK_
    push %{3}
    mov %{3}, [%{4} + %{6}]
    cmp %{3}, %{4}				; make sure we aren't entering
    jz short %%error				;  an eternal loop
    cmp [%{3} + %{5}], %{4}			; make sure parent node ptr is
    jnz short %%error				;  valid
    pop %{3}
   %endif
  mov %{4}, [%{4} + %{6}]
  jmp short %%browsing
%%test_right_node_presence:
  cmp [%{4} + %{7}], byte -1
  jz short %%right_would_be_link_point
   %ifdef _CONSISTENCY_CHECK_
    push %{3}
    mov %{3}, [%{4} + %{7}]
    cmp %{3}, %{4}				; make sure we aren't entering
    jz short %%error				;  an eternal loop
    cmp [%{3} + %{5}], %{4}
    jnz short %%error
    pop %{3}
   %endif
  mov %{3}, %{4}
  mov %{4}, [%{4} + %{7}]
  jmp short %%browsing
   %ifdef _CONSISTENCY_CHECK_
%%error:
    pop %{3}
    mov %{3}, -1
    stc
    retn
   %endif
%%safe_node_recover:
  mov %{4}, %{3}
%%right_would_be_link_point:
  mov %{3}, %{7}
  clc
  retn
%endmacro


%macro lib_link_node 8.nolist
; param 1:	32bit register used as pointer to the root node pointer
;		suggested: EDI
;		note: may also be a label or numerical value
; param 2:	32bit register containing the allocated node as returned by
;		the function of param 6
;		suggested: EBX
; param 3:	32bit register containing pointer to the anchor node
;		note: should be the same as param 4 of lib_locate_node function
;		suggested: ESI
; param 4:	32bit register containing offset within the anchor node to the
; 		anchor point.
;		suggested: EAX
; param 5:	32bit register holding the reference value
;		note: should be the same as param 1 of lib_locate_node function
;		suggested: EDX
; param 6:	function to be called to allocate a node entry
;		note: may be a label or a 32bit register used as pointer
; param 7:	offset within the node to the parent node pointer
; param 8:	offset within the node to the reference value
;
; special note: make sure the function which allocates the node entry doesn't
; destroy param 1, 3 nor 4.  CF must be cleared if allocation was successful,
; otherwise CF must be set and EAX given a value other than -1.
;
; expected to be called with return parameters of lib_find_node function when
; CF = 1.  Nodes to be used in the tree are allocated by a callback function.
;
; parameters:
;------------
; %{1} = (if a register is used), pointer to root node pointer
; %{3} = pointer to node to use as anchor
;       -1 if trinary-tree isn't yet initialized
; %{4} = offset within the anchor node where anchor should be placed
; %{5} = sort value
;
; possible output values:
;------------------------
; CF = 0
;	linking successful
; CF = 1, EAX != -1
;	node allocation failed
; CF = 1, EAX == -1 (only returned if _CONSISTENCY_CHECK_ is enabled)
;	node allocated is invalid or parameters received are invalid
;
  call %{6}
  jc short %%failed
  mov [%{2} + %{8}], %{5}
  ; %{3} = allocated node
  cmp %{3}, byte -1
  jz short %%initialize_tree
   %ifdef _CONSISTENCY_CHECK_
    cmp dword [%{2} + %{7}], byte -1
    jnz short %%error
    cmp dword [%{3} + %{4}], byte -1
    jnz short %%error
   %endif
  mov [%{2} + %{7}], %{3}
  mov [%{3} + %{4}], %{2}
  clc
%%failed:
  retn
%%initialize_tree:
   %ifdef _CONSISTENCY_CHECK_
    cmp dword [%{1}], byte -1
    jnz short %%error
    cmp %{2}, byte -1
    jz short %%error
    cmp dword [%{2} + %{7}], byte -1
    jnz short %%error
   %endif
  mov [%{1}], %{2}
  clc
  retn
   %ifdef _CONSISTENCY_CHECK_
%%error:
  mov eax, -1
  stc
  retn
   %endif
%endmacro
