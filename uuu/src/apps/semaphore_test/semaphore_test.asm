; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License
;
; This is a little application to test the semaphore mechanism of the thread
; engine.  It will create 4 threads, that all try to acquire a lock on a 
; created semaphore.
[bits 32]


section s_app_semaphore_test

global app_semaphore_test
app_semaphore_test:

  ;]-- creating semaphore
  xor eax, eax
  externfunc __create_semaphore, noclass
  mov [semaphore_A], eax
  xor eax, eax
  externfunc __create_semaphore, noclass
  mov [semaphore_B], eax

  push dword 0
  push dword 0
  push dword 1
  push dword th_1
  externfunc __create_thread, noclass
  mov [th_1.id], eax
  pop eax
  push dword th_2
  externfunc __create_thread, noclass
  mov [th_2.id], eax
  pop eax
  push dword th_3
  externfunc __create_thread, noclass
  mov [th_3.id], eax
  pop eax
  push dword th_4
  externfunc __create_thread, noclass
  mov [th_4.id], eax
  add esp, byte 16

  mov ecx, 10000000
  loop $

  mov [th_1.requests], byte 0
  mov [th_2.requests], byte 0
  mov [th_3.requests], byte 0
  mov [th_4.requests], byte 0
  retn



semaphore_A: dd 0
semaphore_B: dd 0
hooked_a: db "semaphore A hooked",0
hooked_b: db "semaphore B hooked",0
clear_it: db "                  ",0


;----
th_1:
;----

  .retry_sequence:
  mov eax, [semaphore_A]
  externfunc __lock_semaphore, write_nofail
  lea esi, [hooked_a]
  mov edi, 0xB8000
  externfunc __showstr, debug
  mov eax, [semaphore_B]
  externfunc __lock_semaphore, write_fail
  jc short .failed

  lea esi, [hooked_b]
  mov edi, 0xB8050
  externfunc __showstr, debug_ack

  ; releasing semaphores
  mov eax, [semaphore_B]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB8050
  externfunc __showstr, debug

  .failed:
  mov eax, [semaphore_A]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB8000
  externfunc __showstr, debug
  externfunc __yield_thread, self
  jmp short .retry_sequence
.requests: equ $-1
  mov eax, [.id]
  externfunc __kill_thread, self

align 4, db 0
.id: dd 0



;----
th_2:
;----

  .retry_sequence:
  mov eax, [semaphore_A]
  externfunc __lock_semaphore, write_nofail
  lea esi, [hooked_a]
  mov edi, 0xB80A0
  externfunc __showstr, debug
  mov eax, [semaphore_B]
  externfunc __lock_semaphore, write_fail
  jc short .failed

  lea esi, [hooked_b]
  mov edi, 0xB80F0
  externfunc __showstr, debug_ack

  ; releasing semaphores
  mov eax, [semaphore_B]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB80F0
  externfunc __showstr, debug

  .failed:
  mov eax, [semaphore_A]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB80A0
  externfunc __showstr, debug
  externfunc __yield_thread, self
  jmp short .retry_sequence
.requests: equ $-1
  mov eax, [.id]
  externfunc __kill_thread, self

align 4, db 0
.id: dd 0

;----
th_3:
;----

  .retry_sequence:
  mov eax, [semaphore_A]
  externfunc __lock_semaphore, write_nofail
  lea esi, [hooked_a]
  mov edi, 0xB8140
  externfunc __showstr, debug
  mov eax, [semaphore_B]
  externfunc __lock_semaphore, write_fail
  jc short .failed

  lea esi, [hooked_b]
  mov edi, 0xB8190
  externfunc __showstr, debug_ack

  ; releasing semaphores
  mov eax, [semaphore_B]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB8190
  externfunc __showstr, debug

  .failed:
  mov eax, [semaphore_A]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB8140
  externfunc __showstr, debug
  externfunc __yield_thread, self
  jmp short .retry_sequence
.requests: equ $-1
  mov eax, [.id]
  externfunc __kill_thread, self

align 4, db 0
.id: dd 0


;----
th_4:
;----

  .retry_sequence:
  mov eax, [semaphore_A]
  externfunc __lock_semaphore, write_nofail
  lea esi, [hooked_a]
  mov edi, 0xB81E0
  externfunc __showstr, debug
  mov eax, [semaphore_B]
  externfunc __lock_semaphore, write_fail
  jc short .failed

  lea esi, [hooked_b]
  mov edi, 0xB8230
  externfunc __showstr, debug_ack

  ; releasing semaphores
  mov eax, [semaphore_B]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB8230
  externfunc __showstr, debug

  .failed:
  mov eax, [semaphore_A]
  externfunc __unlock_semaphore, write
  lea esi, [clear_it]
  mov edi, 0xB81E0
  externfunc __showstr, debug
  externfunc __yield_thread, self
  jmp short .retry_sequence
.requests: equ $-1
  mov eax, [.id]
  externfunc __kill_thread, self

align 4, db 0
.id: dd 0
