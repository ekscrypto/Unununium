; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License
;
;                    =] Binary Tree manipulations [=
;                             version 0.1


%ifndef __MACRO_DRP__
  %error "btree functions included but required 'drp' macro not found"
%endif


%macro flib_btree_link 8.nolist
;=----------------------------------=[ binary tree link ]=----=
;
; link a specified node inside the base address sorted binary tree.
;
; declaration:
;-------------
; param1:  register that will hold the comparison value
; param2:  register that will hold the base address of the node to link
; param3:  offset in data structure to right child pointer entry
; param4:  offset in data structure to left child pointer entry
; param5:  offset in data structure to parent pointer entry
; param6:  offset in data structure to comparison value
; param7:  scratch register
; param8:  offset in memory to location holding pointer to root node
;          |___note: this value may either be a register used as pointer, or
;                    it can be a memory location. In either case, if you
;                    desire to NOT use the DRP macros (in case you have a reg
;                    or a fixed memory location), you may do:
;
;                      %define __FLIB_TTREE_ROOT_NODRP__
;
;                    By defining this constant, no drp entry will be created
;                    for the instructions accessing the root of the tree.
;
; parameters:
;------------
; reg of param1 = value to be sorted on
; reg of param2 = base address to entry to add
;
; returned values:
;-----------------
;
; if cf = 0, succesful
;   reg of param7 = (undetermined)
;   others = (unmodified)
;
; if cf = 1, failed (value already exist)
;   reg of param7 = pointer to node containing the duplicate entry
;   others = (undmofieid)
;
; development status: to be tested

%ifndef __FLIB_BTREE_NODRP__
  drp mov %{7}, dword [%{8}]
%else
  mov %{7}, dword [%{8}]
%endif
  cmp %{7}, -1
  jz short %%insert_node_as_root

%%proceed:
  cmp %{1}, dword [%{7} + %{6}]
  ja short %%browse_left
  jz %%quit

%%browse_right:
  ;=- note -= base address of node to insert is below the base address of the
  ; current node being browsed.  We try to browse right toward higher base
  ; address nodes.  If none exist, we will insert our node as right link.
  
  cmp dword [%{7} + %{3}], -1
  jz short %%insert_as_right_child

  ;=- we browse right, for some optimization later we should 'rotate' the
  ;   right node toward root, so most often used routes gets shorter

  ;=- load right node -=
  mov %{7}, dword [%{7} + %{3}]
  jmp short %%proceed

%%browse_left:
  ;=- note -= base address of node to insert is above the base address of the
  ; current node.  We try to browse left, if not possible then insert node as
  ; the left child.

  cmp dword [%{7} + %{4}], -1
  jz short %%insert_as_left_child

  ;=- we browse left, for some optimization later, we should 'rotate' the
  ;   left node toward root, so most often used routes gets shorter

  ;=- load left node -=
  mov %{7}, [%{7} + %{4}]
  jmp short %%proceed

%%insert_as_right_child:
  mov [%{2} + %{5}], %{7}
  mov [%{7} + %{3}], %{2}
  clc
  retn

%%insert_as_left_child:
  mov [%{2} + %{5}], %{7}
  mov [%{7} + %{4}], %{2}
  clc
  retn

%%insert_node_as_root:
  drp mov [%{8}], %{2}
  clc
  retn

%%quit:
  stc
  retn
%endmacro



%macro flib_btree_unlink 8
;=----------------------------------=[ binary tree unlink ]=----=
;
; unlink a specified node inside the base address sorted binary tree.
;
; declaration:
;-------------
; param1:  register that will hold the base address of the node to link
; param2:  offset in data structure to right child pointer entry
; param3:  offset in data structure to left child pointer entry
; param4:  offset in data structure to parent pointer entry
; param5:  first scratch register
; param6:  second scratch register
; param7:  third scratch register
; param8:  offset in memory to location holding pointer to root node
;          |___note: this value may either be a register used as pointer, or
;                    it can be a memory location. In either case, if you
;                    desire to NOT use the DRP macros (in case you have a reg
;                    or a fixed memory location), you may do:
;
;                      %define __FLIB_TTREE_ROOT_NODRP__
;
;                    By defining this constant, no drp entry will be created
;                    for the instructions accessing the root of the tree.
;
; parameters:
;------------
; reg of param8 = base address to fmm entry
;
; returned values:
;-----------------
; eax = -1
; ebx = (undetermined)
; ecx = (undetermined)
; edx = (unmodified)
; esi = (unmodified)
; edi = (unmodified)
; esp = (unmodified)
; ebp = (unmodified)
;
; development status: to be tested

  mov %{5}, -1

  ;=- test if right child is present on node to unlink -=
  cmp dword [%{1} + %{2}], %{5}
  jz short %%link_left

%%test_left_child:
  ;=- preload right child in case no left child present -=
  mov %{6}, dword [%{1} + %{2}]

  ;=- test if left child is also there with right node -=
  cmp dword [%{1} + %{3}], %{5}
  jz short %%link_right

  ;=- both child are present, now determining if we can rotate -=

    ;=- preload left child -=
    mov %{7}, dword [%{1} + %{3}]
  
    ;=- looking up for right node left's child presence -=
    ;note: right node was just pre-loaded in %{6}
    cmp dword [%{6} + %{3}], %{5}
    jz short %%left_over_right

    ;=- looking up for left node right's child presence -=
    ;note: left node was just pre-loaded in %{7}
    cmp dword [%{7} + %{2}], %{5}
    jnz short %%long_shot

%%right_over_left:
  ;=- right child of unlinked node becomes right child of left node -=
  ;note: both left and right child are pre-loaded in %{7} and %{6} respectively
    ;=- linking right on left -=
    mov dword [%{7} + %{2}], %{6}
    ;=- marking left as parent of right -=
    mov dword [%{6} + %{4}], %{7}
    ;=- terminating unlinked node right's child -=
    mov dword [%{1} + %{2}], %{5}
    jmp short %%link_left

%%test_left_child_only:
  ;=- test if left child would be only one present -=
  cmp dword [%{1} + %{3}], %{5}
  jnz short %%link_left

%%terminate_parent:
  ;=- terminate parent node -=
  mov %{7}, dword [%{1} + %{4}]
  mov %{6}, %{5}
  jmp short %%terminate_parent_common

%%left_over_right:
  ;=- left child of unlinked node becomes left child of right node -=
  ;note: left node was just pre-loaded in %{7}
    ;=- linking left on right -=
    mov dword [%{6} + %{3}], %{7}
    ;=- marking right as parent of left -=
    mov dword [%{7} + %{4}], %{6}
    ;=- terminating unlinked node left's child -=
    mov dword [%{1} + %{3}], %{5}
    jmp short %%link_right

%%link_left:
  ;=- link left node to parent -=
  mov %{6}, dword [%{1} + %{3}]
  mov dword [%{1} + %{3}], %{5}
  jmp short %%link_unique_common

%%link_right:
  ;=- link right node to parent -=
  mov dword [%{1} + %{2}], %{5}

%%link_unique_common:
  mov %{7}, dword [%{1} + %{4}]
  mov dword [%{6} + %{4}], %{7}

%%terminate_parent_common:
    ;=- test if parent is root -=
    cmp %{7}, %{5}
    jz short %%link_right_to_root

    ;=- linking to parent -=
    mov dword [%{1} + %{4}], %{5}

      ;=- determining if we were right or left link -=
      cmp dword [%{7} + %{3}], %{1}
      jz short %%link_right_to_parent_left

      ;=- linking to parent's right -=
      mov dword [%{7} + %{2}], %{6}
      retn

    %%link_right_to_parent_left:
      ;=- linking to parent's left -=
      mov dword [%{7} + %{3}], %{6}
      retn

  %%link_right_to_root:
    ;=- linking as root -=
%ifndef __FLIB_BTREE_NODRP__
    drp mov dword [%{8}], %{6}
%else
    mov dword [%{8}], %{6}
%endif
    retn

%%long_shot:
  ;=- both left and right node are present, and furthermore, both have
  ; right and left child respectively, so a quick replacement is impossible.
  ; this part will place the right child of the left node, as the leftmost
  ; child of the right node.  It will then mark the right node as having 
  ; left node as parent, and place the left node in the position of the
  ; unlinked node. woohoo.. word game :P

  ;=- unlinking node -=
  mov [%{1} + %{3}], %{5}
  mov [%{1} + %{2}], %{5}
  xchg %{5}, [%{1} + %{4}]
  mov [%{7} + %{4}], %{5}

  ;=- from this point, node is fully unlinked, simply link back the other
  ; node like established

  ;=- linking right node on left -=
  mov %{5}, %{6}
  xchg %{5}, [%{7} + %{2}]
    ; %{5} = original right child of left node
  mov [%{6} + %{4}], %{7}

  ;=- finding leftmost of right node
%%leftmost_search:
  cmp [%{6} + %{3}], dword -1
  jz short %%leftmost_found
  mov %{6}, [%{7} + %{3}]
  jmp short %%leftmost_search

%%leftmost_found:
  mov [%{6} + %{3}], %{5}
  mov [%{5} + %{4}], %{6}
  mov %{5}, dword -1
  mov %{6}, %{7}
  mov %{7}, [%{1} + %{4}]
  jmp short %%terminate_parent_common

retn
