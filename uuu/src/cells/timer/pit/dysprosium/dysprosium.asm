; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License

;; * provided functions *
;;
;; __set_client			tick_notification	30	3
;; __set_timer			noclass			200	0
;; __get_timer_resolution	noclass			500	0
;; __free_timer_entry		noclass			502	0

%define visual_activity

; TODO: fix the counter to use 64bits countdown, we will run into problems
; if we run the timer at 5ms ticks for more than 248 days

section cell_init

pit_init:
  externfunc __create_ics_channel, noclass
  mov [_pit_irq_handler.ics_channel], edi

  ;]--Reprogram PIT to 200Hz (channel 0)
  mov al, 0x34
  out 0x43, al
  in al, 0x80	; i/o delay
  in al, 0x80	; i/o delay
  mov al, cl
  out 0x40, al
  mov al, ch
  out 0x40, al
  
  ;]--Hook IRQ 0
  mov esi, _pit_irq_handler
  mov al, 0x20
  externfunc __hook_int, noclass
  mov al, 0x00
  externfunc __unmask_irq, noclass


section pit_timer

  struc timer_entry
.set_count	resd 1
.ptr_to_code	resd 1
.next_timer	resd 1
.prev_timer	resd 1
  endstruc

%define timer_entry_count 511
; ^^- number of timer per timer node

  struc timer_node
.next_node	resd 1
.prev_node	resd 1
.first_timer	resb timer_entry_count * timer_entry_size
  endstruc

timers:
.first_free: dd -1
.first_to_expire: dd -1
.first_to_expire_count: dd -1
.root_node: dd -1


;------------------------------------------------------------------------------
globalfunc __set_client, tick_notification, 30, 3
;------------------------------------------------------------------------------
; parameters:
;------------
; esi = pointer to client, must be ICS compliant
;
; returned values:
;-----------------
; if cf = 0, sucessful
;   eax = (undetermined)
;   ebx = (undetermined)
;   ecx = entry number in the client node
;   edx = pointer to client node holding client entry pointer
;   esi = (unmodified)
;   edi = pointer to channel data
;   esp = (unmodified)
;   ebp = (unmodified)
;
; if cf = 1, failed
;   eax = error code
;   ebx = (undetermined)
;   ecx = (undetermined)
;   edx = (undetermined)
;   esi = (unmodified)
;   edi = (undetermined)
;   esp = (unmodified)
;   ebp = (unmodified)


  mov edi, [_pit_irq_handler.ics_channel]
  externfunc __connect_to_ics_channel, noclass
  retn



;------------------------------------------------------------------------------
globalfunc __set_timer, noclass, 200, 0
;------------------------------------------------------------------------------
; eax = number of nanoseconds to use
; edi = pointer to handler
;--------
; eax = timer id
; ebx = (undetermined)
; ecx = system count the timer will expire at
; edx = TODO
; esi = TODO
; edi = TODO
; esp = (unmodified)
; ebp = (unmodified)
  mov ebx, eax		;] divide by 5 million, resolution of 5ms/1ns
  shr eax, 22		;]
  shr ebx, 25		;]
  sub eax, ebx		;/
  or  eax, eax		; if resoluting count is 0, abort, too fast for us
  jz  .failed

  ;]--Hook the timer up
  pushfd		; TODO: replace those 2 instructions by a start
  cli			;       critical section call to thread engine

  add eax, [_pit_irq_handler.count]
  push edi
  push eax
  call _get_timer_entry
  pop ecx
  pop edi

  ;]--Set timer properties (expiration/handler)
  mov [eax + timer_entry.set_count], ecx
  mov [eax + timer_entry.ptr_to_code], edi

  ;]--Load pointer to first handler
  mov ebx, [timers.first_to_expire]
  
    ;]--Check if timer would be new first to expire
    cmp ecx, [timers.first_to_expire_count]
    jb .new_next_to_expire_timer

    ;]--Travel down the chained list and find timer with highest lower count
    .searching_insertion_point:
    mov edx, [ebx + timer_entry.next_timer]
    cmp edx, dword -1
    jz .append_to_list
    cmp ecx, [edx + timer_entry.set_count]
    jbe .found_insertion_point
    mov ebx, edx
    jmp short .searching_insertion_point

    .found_insertion_point:		; between two existing timers
    mov [eax + timer_entry.prev_timer], ebx
    mov [eax + timer_entry.next_timer], edx
    mov [ebx + timer_entry.next_timer], eax
    mov [edx + timer_entry.prev_timer], eax
    jmp short .completed

    .append_to_list:			; new latest timer set
    mov [ebx + timer_entry.next_timer], eax
    mov [eax + timer_entry.prev_timer], ebx
    mov [eax + timer_entry.next_timer], edx
    jmp short .completed

    .new_next_to_expire_timer:		; new earliest timer set
    mov [timers.first_to_expire_count], ecx
    mov [timers.first_to_expire], eax
    mov [eax + timer_entry.prev_timer], dword -1
    mov [eax + timer_entry.next_timer], ebx
    cmp ebx, dword -1
    jz .completed
    mov [ebx + timer_entry.prev_timer], eax

  .completed:
  popfd			; TODO: replace this by end critical section

  clc
  retn

.failed:
  mov eax, -1		; TODO: def an error code for resolution not supported
  stc
  retn


;------------------------------------------------------------------------------
globalfunc __get_timer_resolution, noclass, 500, 0
;------------------------------------------------------------------------------
; parameters: none
; returned values: eax = number of nanosecond between ticks
  mov eax, 5000000
  retn


;------------------------------------------------------------------------------
globalfunc __free_timer_entry, noclass, 502, 0
;------------------------------------------------------------------------------
; parameters:
;------------
; ebx = pointer to timer entry to free
;
; returned values:
;-----------------
; eax = (undetermined)
; ebx = (undetermined)
; ecx = (unmodified)
; edx = (unmodified)
; esi = (unmodified)
; edi = (unmodified)
; esp = (unmodified)
; ebp = (unmodified)
  pushfd		; TODO: replace those 2 instructions by a start
  cli			;       critical section call to thread engine

  mov eax, [timers.first_free]
  mov [ebx], eax
  mov [timers.first_free], ebx
  mov eax, [ebx + timer_entry.prev_timer]
  cmp eax, dword -1
  jz .set_first_to_expire_count

  mov ebx, [ebx + timer_entry.next_timer]
  mov [eax + timer_entry.next_timer], ebx
  cmp ebx, dword -1
  jz .completed
.completed:

  popfd			; TODO: replace this by end critical section

  retn

.set_first_to_expire_count:
  mov eax, [ebx + timer_entry.next_timer]
  mov [timers.first_to_expire], eax
  cmp eax, dword -1
  jz .no_more_counters

  ;]--marking next timer as new active timer
  mov eax, [eax + timer_entry.set_count]

.no_more_counters:
  mov [timers.first_to_expire_count], eax

  popfd			; TODO: replace this by end critical section

  retn
  

;------------------------------------------------------------------------------
_get_timer_entry:
;------------------------------------------------------------------------------
; parameters: none
; returned values:
; if cf = 0, successful
;   eax = pointer to entry
; if cf = 1, failed
;   eax = error code
  pushfd		; TODO: replace those 2 instructions by a start
  cli			;       critical section call to thread engine

  mov eax, [timers.first_free]
  cmp eax, -1
  jz .expand_timer_node

  mov ebx, [eax]
  mov [timers.first_free], ebx

  popfd			; TODO: replace this by end critical section

  clc
  retn

.expand_timer_node:
  mov ecx, timer_node_size
  xor edx, edx
  externfunc __malloc, noclass
  jc .failed_allocating_memory

  ;]--Linking up new node
  mov esi, [timers.root_node]
  mov [timers.root_node], edi
  mov [edi + timer_node.next_node], esi
  mov [edi + timer_node.prev_node], dword -1
  mov [esi + timer_node.prev_node], edi

  lea esi, [edi + timer_node.first_timer]
  mov [timers.first_free], esi
  mov ecx, timer_entry_count - 2
  
  ;]--Linking up all the entries together
.linking_up:
  lea edi, [esi + timer_entry_size]
  mov [esi], edi
  mov esi, edi
  loop .linking_up

  mov [esi], dword -1
  lea eax, [esi + timer_entry_size]

  popfd			; TODO: replace this by end critical section

  clc
  retn
  
.failed_allocating_memory:
  popfd			; TODO: replace this by end critical section

  stc
  retn
}



;------------------------------------------------------------------------------
_pit_irq_handler:
;------------------------------------------------------------------------------
  push eax
%ifdef visual_activity
  inc dword [0xb8000 + (24*0xA0)+0x9C]
%endif
inc dword [0x800F00F4]
inc dword [0x800F00F4]
inc dword [0x800F00F4]
  push dword [.ics_channel]
  externfunc __send_ics_message, noclass
  pop eax
  mov eax, dword [.count]
  inc eax
  mov [.count], eax
  cmp eax, [timers.first_to_expire_count]
  jz .warn_timer_of_expiration
  .return_from_timer_expiration:
  mov al, 0x60
  out 0x20, al
  pop eax
  iretd

.warn_timer_of_expiration:
  mov eax, [timers.first_to_expire]
  call [eax + timer_entry.ptr_to_code]
  push ebx
  push dword [eax + timer_entry.next_timer]
  mov ebx, eax
  call __free_timer_entry.pit
  pop eax
  mov ebx, [.count]
  cmp [eax + timer_entry.set_count], ebx
  pop ebx
  jnz .return_from_timer_expiration
  cmp eax, dword -1
  jz .return_from_timer_expiration
  jmp short .warn_timer_of_expiration

align 4, db 0
.count: dd 0
.ics_channel: dd -1
