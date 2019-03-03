;; Babylon Resource Pools
;; Copyright (C) 2003, Dave Poirier
;; Distributed under the BSD License


section .c_info

  db 0,1,0,'a'
  dd str_title
  dd str_author
  dd str_copyright

  str_title:
  db "Babylon Resource Pools",0
  str_author:
  db "eks",0
  str_copyright:
  db "Copyright(C) 2003, Dave Poirier",0x0A
  db "Distributed under the BSD license",0x00



section .text


struc _resource_t
.deallocator		resd 1
.host_pool		resd 1
.next			resd 1
.previous		resd 1
endstruc



globalfunc rp.empty_pool
;-------------------------------------------------------------[ rp.empty_pool ]
;>
;; Free all resources associated with a pool and mark it as empty.
;;
;; parameters:
;; -----------
;;  eax = pointer to resource pool to empty
;;
;; returns:
;; --------
;;  errors and registers as usual
;<
;------------------------------------------------------------------------------
  pushad
  xor  ebx, ebx
  xchg [eax], ebx
  test ebx, ebx
  mov eax, ebx
  jz short .end
  push eax
.processing:
  push dword [eax + _resource_t.next]
  call [eax]
  pop eax
  cmp eax, [esp]
  jnz short .processing
  pop eax
.end:
  popad
  clc
  retn
;------------------------------------------------------------[ /rp.empty_pool ]


globalfunc rp.free_resource
;----------------------------------------------------------[ rp.free_resource ]
;>
;; Free a resource and remove it from its host resource pool.
;;
;; parameters:
;; -----------
;;  eax = resource to free
;;
;; returns:
;; --------
;;  errors and registers as usual
;<
;------------------------------------------------------------------------------
  pushad					;
  call rp.unlink_resource			;
  call [eax]					;
  popad						;
  clc						;
  retn						;
;---------------------------------------------------------[ /rp.free_resource ]



globalfunc rp.link_resource
;----------------------------------------------------------[ rp.link_resource ]
;>
;; Link a resource to a host resource pool.
;;
;; parameters:
;; -----------
;;  eax = resource to link
;;  ecx = host resource pool
;;
;; returns:
;; --------
;;  errors and registers as usual
;<
;------------------------------------------------------------------------------
  pushad					;
  ENTER_CRITICAL_SECTION			;
  mov  ebx, [ecx]				;
  mov  [eax + _resource_t.host_pool], ecx	;
  mov  [eax + _resource_t.next], eax		;
  mov  [eax + _resource_t.previous], eax	;
  test ebx, ebx					;
  jz short .initialize_resource_pool		;
  mov  edx, [ebx + _resource_t.previous]	;
  mov  [eax + _resource_t.next], ebx		;
  mov  [eax + _resource_t.previous], edx	;
  mov  [edx + _resource_t.next], eax		;
  mov  [ebx + _resource_t.previous], eax	;
.initialize_resource_pool:			;
  mov  [ecx], eax				;
  LEAVE_CRITICAL_SECTION			;
  popad						;
  clc						;
  retn						;
;---------------------------------------------------------[ /rp.link_resource ]


globalfunc rp.unlink_resource
;--------------------------------------------------------[ rp.unlink_resource ]
;>
;; Unlink a resource from a host resource pool without freeing it.
;;
;; parameters:
;; -----------
;;  eax = pointer to resource to unlink
;;
;; returns:
;; --------
;;  errors and registers as usual
;<
;------------------------------------------------------------------------------
  pushad					;
  ENTER_CRITICAL_SECTION			;
  mov ebx, [eax + _resource_t.host_pool]	;
  test ebx, ebx					;
  mov ecx, [eax + _resource_t.next]		;
  mov edx, [eax + _resource_t.previous]		;
  jz short .early_exit				;
  mov [edx + _resource_t.next], ecx		;
  mov [ecx + _resource_t.previous], edx		;
  mov [eax + _resource_t.next], eax		;
  mov [eax + _resource_t.previous], eax		;
  cmp ecx, eax					;
  jz short .update_pool				;
  xor ecx, ecx					;
.update_pool:					;
  mov [ebx], ecx				;
.early_exit:					;
  LEAVE_CRITICAL_SECTION			;
  popad						;
  clc						;
  retn						;
;-------------------------------------------------------[ /rp.unlink_resource ]

