;; $Header: /cvsroot/uuu/dimension/cell/comm/helium/helium.asm,v 1.2 2002/01/23 01:40:16 jmony Exp $
;;
;; Helium - ICS (InterCommunication System)
;; Copyright (C) 2001 - Phil Frost
;; Distributed under the BSD License; see file "license" for details

[bits 32]

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

%define _DEBUG_


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

struc ics_client_data         ; for client-level data
  .reserved	resb 3
  .index	resb 1          ; this is the Xth client in the table
  .table	resd 1          ; pointer to table client is in
endstruc

struc ics_channel_data
  .first_node	resd 1          ; pointer to first node the of the chain
  .empty	resd 1          ; pointer to last node in chain
  .changes	resb 1          ; the number of disconnects, used for cleanup
  .reserved	resb 3
endstruc

struc ics_client_node
  .next_node	resd 1  ;-pointer to next node of the same channel
  .clientA	resd 1  ;]
  .clientB	resd 1  ;]
  .clientC	resd 1  ;]
  .clientD	resd 1  ;]-pointer to connect ics clients
  .clientE	resd 1  ;]
  .clientF	resd 1  ;]
  .count	resb 1  ;-number of connected clients
  .reserved	resb 3
endstruc

;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init
global _start
_start:
init:
  mov edx, ics_client_node_size
  mov ecx, 3		; allocate in 8 block chunks
  externfunc mem.fixed.alloc_space
  jc .quit
  mov [ics_client_node_space], edi

  mov edx, ics_channel_data_size
  ; ecx still set
  externfunc mem.fixed.alloc_space
  jc .quit
  mov [ics_channel_data_space], edi
.quit:
  retn
;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                             ics.remove_client
;==============================================================================

globalfunc ics.remove_client
;>
;; WARNING: Currently always returns error
;;
;; Allow to remove an ICS client from an ICS channel
;;
;; Parameters:
;;------------
;; ESI = pointer to ICS client
;;
;; Returns:
;;---------
;; Errors and registers as usual
;<
  xor eax, eax
  dec eax
  stc
  retn

;                                           -----------------------------------
;                                                            ics.create_channel
;==============================================================================

globalfunc ics.create_channel
;>
;; Register a new ICS channel
;;
;; This is a very simple process, this function allocates one struc
;; ics_channel_data and returns a pointer to it.
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EDI = pointer to ics channel data
;; ESI, EBP = unmodified
;; errors as usual
;<

  push esi
  mov edi, [ics_channel_data_space]
  externfunc mem.fixed.alloc	; memory allocate function
  jc $
  pop esi
  jc .failed				; in case it fails..

  push edi				; keep pointer to memory block
  call _create_new_ics_node		; create a new node
  pop edx				; restore pointer to memory block
  jc .failed_free_up			; in case new node failed

  ;edi = 1st node
  ;edx = channel struc

  ;]--Filling out the node data
  mov [edx], edi				; the first node in the chain
  mov [edx + ics_channel_data.empty], edi	; last node in the chain
  mov [edx + ics_channel_data.changes], byte -1	; cleanup count
  
  mov edi, edx				; return pointer to channel data
  clc					; no error found
  retn					; get back to caller!

.failed_free_up:	; node creation failed, release channel data

  mov edi, [ics_channel_data_space]
  mov eax, edx
  externfunc mem.fixed.dealloc
  stc

.failed:
  retn

;                                           -----------------------------------
;                                                                ics.add_client
;==============================================================================

globalfunc ics.add_client
;>
;; Connects to an ics channel
;;
;; parameters:
;; -----------
;; EDI = pointer to channel data
;; ESI = pointer to function to connect.
;;
;;       **NOTE** this function must return the stack and registers as it
;;       received them (besides eip).  It must also have a 8 bytes empty client
;;       hook area before the pointer.
;;
;;       i.e.:  dd 0,0
;;              _client:
;;
;; returned values:
;; ----------------
;; ECX = entry number in client node
;; EDX = pointer to client node holding client entry pointer
;; ESI, EDI, EBP = unmodified
;; errors as usual
;<

  mov edx, [edi + ics_channel_data.empty]
  jmp short .start

.next_node:
  mov edx, eax		; save current node, so if we have to expand the
  			; list to include another node, we have a pointer to
			; the previous
.start:
  xor ecx, ecx
  mov cl, byte [edx + ics_client_node.count]
  cmp ecx, byte 6	; max client count reached?
  jl short .add_entry	; nope, add to this node

  ; if we get here, table is full, so we go to the next node
  mov eax, [edx]	; load pointer to next node
  cmp eax, dword -1	; is there another node?
  jnz short .next_node	; yip, go to it

  ;well,there is no more node, let's add one
  push edi
  push edx
  call _create_new_ics_node
  mov edx, edi
  pop eax
  pop edi
  jc .failed
  
  mov [eax], edx
  xor ecx, ecx

  ; we know there is room in this newly created node, just go to add_entry

.add_entry:
  inc ecx
  mov [ecx*4 + edx], esi
  mov [esi -8 +ics_client_data.table], edx
  mov [edx + ics_client_node.count], cl
  mov [esi -8 +ics_client_data.index], cl
  clc
  retn

.failed:
  mov eax, -1
  retn

;                                           -----------------------------------
;                                                              ics.send_message
;==============================================================================

globalfunc ics.send_message
;>
;; Send a message out on a channel
;;
;; parameters:
;; -----------
;; top of stack = pointer to channel data (from __create_ics_channel)
;; registers = passed exactly as they are to all the clients
;;
;; returned values:
;; ----------------
;; all registers unmodified
;;
;; Note: the value on the stack is NOT removed.
;<

  push ebp
  push ecx
  push esi
  mov ebp, esp

  ;stack is now
  ;    esi ecx eip (channel)
  ;ebp-^   +4  +8  +12

  mov esi, [ss:esp + 16]	; retrieve pointer to channel data
  mov esi, [esi]		; retrieve pointer to first node of channel

  ;]--push return address point
  push dword .return_point

  ;]-- pushing location of clients on stack
.looping:
  xor ecx, ecx
  mov cl, byte [esi + ics_client_node.count]
  test ecx, ecx			; make sure there's at least one valid client
  jz .next_node			; nope, check next node
.pushing:
  push dword [ecx*4 + esi]	; push client's address
  dec ecx			; dec count left in this node
  jnz .pushing			; do other clients
.next_node:

  ;]--handling next table, if any
  mov esi, [ esi ]		; load .next_node pointer
  cmp esi, dword -1		; is this a NULL terminator?
  jnz .looping			; nope, load next node

  ;]--restoring registers
  mov esi, [ss:ebp]		; restore caller's esi value
  mov ecx, [ss:ebp+4]		; restore caller's ecx value

  retn				; start chained message pass

.return_point:
  ; when we get here, we are at the same point as before pushing the
  ; return_point address.
  add esp, byte 8		; effectively pop twice
  pop ebp
  retn				; return to caller

;                                           -----------------------------------
;                                                               ics.get_clients
;==============================================================================

globalfunc ics.get_clients
;>
;; Pushes all the clients on the stack and returns to caller.
;;
;; parameters:
;; -----------
;; EDI = pointer to channel data (from __create_ics_channel)
;;
;; returned values:
;; ----------------
;; EBX = unmodified
;; ECX = number of clients
;;
;; Note: the value on the stack is NOT removed.
;<

  mov esi, [edi]		; retrieve pointer to first node of channel
  pop edi			; get the place to return to
  xor ecx, ecx			; reset counter

  ;]-- pushing location of clients on stack
.looping:
  xor eax, eax
  mov al, byte [esi + ics_client_node.count]
  test eax, eax			; make sure there's at least one valid client
  jz .next_node			; nope, check next node
.pushing:
  push dword [eax*4 + esi]	; push client's address
  inc ecx			; count one
  dec eax			; dec count left in this node
  jnz .pushing			; do other clients
.next_node:

  ;]--handling next table, if any
  mov esi, [ esi ]		; load .next_node pointer
  cmp esi, dword -1		; is this a NULL terminator?
  jnz .looping			; nope, load next node

  jmp edi			; return to caller

;                                           -----------------------------------
;                                                    ics.send_confirmed_message
;==============================================================================

globalfunc ics.send_confirmed_message
;>
;; Send an ICS message thru the channel, this variation check the carry flag
;; between each client.  If CF = 1 after a client, the message is sent to the
;; next client until none is left.  If CF = 0 after a client, the message is
;; assumed to have been handled and no other client will receive it.
;;
;; parameters:
;; -----------
;; top of stack = pointer to channel data (from __create_ics_channel)
;; registers = passed exactly as they are to all the clients
;; 
;; returned values:
;; ----------------
;; all registers unmodified
;; CF = set iff message was not handled
;;
;; Note: the value on the stack is NOT removed.
;<

  push esi
  push ecx

  ;stack now contains:
  ;  ecx esi (caller EIP) (channel)
  ;  +0  +4  +8           +12

  mov esi, [ss:esp + 12]
  mov esi, [esi]

.check_for_clients:
  xor ecx, ecx
  mov cl, byte [esi + ics_client_node.count]

  test ecx, ecx
  jz .check_for_linked_node

.check_next_client:
  ; At least one client is in this node, process it/them
  push ecx		; push client count
  push esi		; push client list pointer
  push dword .return_point
  push dword [ecx*4 + esi]
  mov ecx, [esp + 16]
  mov esi, [esp + 20]
  retn

.return_point:
  pop esi
  pop ecx
  jnc .confirmed

  ; CF = 1, check next client
  dec ecx
  jnz .check_next_client

.check_for_linked_node:
  mov esi, [esi + ics_client_node.next_node]
  cmp esi, dword -1
  jnz .check_for_clients

  ;nobody took the call
  pop ecx
  pop esi
  stc
  retn

.confirmed:
  pop ecx
  pop esi
  clc
  retn

;                                           -----------------------------------
;                                                          _create_new_ics_node
;==============================================================================

_create_new_ics_node:
;>
;; this creates a new node, returns the pointer to it
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EBP, ESI = unmodified
;; EDI = pointer to newly created node
;; errors as usual
;<

  push esi
  push ebp
  mov edi, [ics_client_node_space]
  externfunc mem.fixed.alloc
  jc .failed

  mov [edi], dword -1
  mov [edi + ics_client_node.count], byte 0
.failed:
  pop ebp
  pop esi
  retn

;                                           -----------------------------------
;                                                                 section .data
;==============================================================================

section .data
  ics_client_node_space:	dd 0
  ics_channel_data_space:	dd 0

;                                           -----------------------------------
;                                                                     cell info
;==============================================================================

section .c_info

  db 0,1,3,'a'
  dd str_name
  dd str_author
  dd str_copyright

  str_name: db "Helium - ICS",0
  str_author: db 'Phil "indigo" Frost <daboy@xgs.dhs.org>',0
  str_copyright: db "Copyright (C) 2001 Phil Frost",0x0A
                 db "Distributed under the BSD License",0
