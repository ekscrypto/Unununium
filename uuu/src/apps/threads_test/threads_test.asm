; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD license
;
; this is a little utility to test the thread engine

[bits 32]

section s_thread_test


global app_threads_test
app_threads_test:

  ; First, clear the screen to have a nice good looking world
  ; TODO: use the console manager / video driver functions to clear that out

  mov edi, 0xb8000
  mov ecx, 1000
  mov eax, 0x07200720
  repz stosd

  ; display keys that we can use
  lea esi, [str_help1]
  mov edi, 0xB8020
  externfunc __showstr, debug
  lea esi, [str_help1b]
  mov edi, 0xB80D4
  externfunc __showstr, debug
  lea esi, [str_help2]
  mov edi, 0xB8160
  externfunc __showstr, debug
  lea esi, [str_help2b]
  mov edi, 0xB8214
  externfunc __showstr, debug
  lea esi, [str_help3]
  mov edi, 0xB82A0
  externfunc __showstr, debug
  lea esi, [str_help3b]
  mov edi, 0xB8354
  externfunc __showstr, debug
  lea esi, [str_help4]
  mov edi, 0xB83E0
  externfunc __showstr, debug
  lea esi, [str_help4b]
  mov edi, 0xB8494
  externfunc __showstr, debug
  lea esi, [str_help5]
  mov edi, 0xB8540+0xA0
  externfunc __showstr, debug

  ; mask off keyboard port
  in al, 0x21
  push eax
  or al, 0x02
  out 0x21, al

  .get_next_key:
  call _get_key

  cmp al, 0x10	; Q
  jz .create_th0

  cmp al, 0x11	; W
  jz .kill_th0

  cmp al, 0x12	; E
  jz .create_th1

  cmp al, 0x13	; R
  jz .kill_th1

  cmp al, 0x16	; U
  jz .create_th2

  cmp al, 0x17	; I
  jz .kill_th2

  cmp al, 0x18	; O
  jz .create_th3

  cmp al, 0x19	; P
  jz .kill_th3

  cmp al, 0x1E	; A
  jz .wake_th0

  cmp al, 0x1F	; S
  jz .sleep_th0

  cmp al, 0x20	; D
  jz .wake_th1

  cmp al, 0x21	; F
  jz .sleep_th1

  cmp al, 0x23	; H
  jz .wake_th2

  cmp al, 0x24	; J
  jz .sleep_th2

  cmp al, 0x25	; K
  jz .wake_th3

  cmp al, 0x26	; L
  jz .sleep_th3

  cmp al, 0x2C	; Z
  jz .self_kill0

  cmp al, 0x2D	; X
  jz .self_sleep0

  cmp al, 0x2E	; C
  jz .self_kill1

  cmp al, 0x2F	; V
  jz .self_sleep1

  cmp al, 0x30	; B
  jz .self_kill2

  cmp al, 0x31	; N
  jz .self_sleep2

  cmp al, 0x32	; M
  jz .self_kill3

  cmp al, 0x33	; ,
  jz .self_sleep3

  cmp al, 0x01
  jnz .get_next_key
  pop eax
  out 0x21, al
  retn

  .create_th0:
  cmp [th_id0], dword 0
  jnz .get_next_key
  xor eax, eax
  push eax
  push eax
  inc eax
  push eax
  push dword th_top_left_side
  mov edi, 0xB8000
  xor edx, edx
  externfunc __create_thread, noclass
  mov [th_id0], eax
  add esp, byte 16
  jmp .get_next_key

  .create_th1:
  cmp [th_id1], dword 0
  jnz .get_next_key
  xor eax, eax
  push eax
  push eax
  inc eax
  push eax
  push dword th_top_right_side
  mov edi, 0xB8090
  xor edx, edx
  externfunc __create_thread, noclass
  mov [th_id1], eax
  add esp, byte 16
  jmp .get_next_key

  .create_th2:
  cmp [th_id2], dword 0
  jnz .get_next_key
  xor eax, eax
  push eax
  push eax
  inc eax
  push eax
  push dword th_bottom_left_side
  mov edi, 0xB8000 + (0xA0*24)
  xor edx, edx
  externfunc __create_thread, noclass
  mov [th_id2], eax
  add esp, byte 16
  jmp .get_next_key
  
  .create_th3:
  cmp [th_id3], dword 0
  jnz .get_next_key
  xor eax, eax
  push eax
  push eax
  inc eax
  push eax
  push dword th_bottom_right_side
  mov edi, 0xB8090 + (0xA0 * 24)
  xor edx, edx
  externfunc __create_thread, noclass
  mov [th_id3], eax
  add esp, byte 16
  jmp .get_next_key
  
  ;----

  .kill_th0:
  cmp [th_id0], dword 0
  jz .get_next_key
  mov eax, [th_id0]
  externfunc __kill_thread, noclass
  mov [th_id0], dword 0
  lea esi, [str_killed]
  mov edi, 0xB8000
  externfunc __showstr, debug
  jmp .get_next_key
  
  .kill_th1:
  cmp [th_id1], dword 0
  jz .get_next_key
  mov eax, [th_id1]
  externfunc __kill_thread, noclass
  mov [th_id1], dword 0
  lea esi, [str_killed]
  mov edi, 0xB8090
  externfunc __showstr, debug
  jmp .get_next_key
  
  .kill_th2:
  cmp [th_id2], dword 0
  jz .get_next_key
  mov eax, [th_id2]
  externfunc __kill_thread, noclass
  mov [th_id2], dword 0
  lea esi, [str_killed]
  mov edi, 0xB8000 + (0xA0*24)
  externfunc __showstr, debug
  jmp .get_next_key
  
  .kill_th3:
  cmp [th_id3], dword 0
  jz .get_next_key
  mov eax, [th_id3]
  externfunc __kill_thread, noclass
  mov [th_id3], dword 0
  lea esi, [str_killed]
  mov edi, 0xB8090 + (0xA0*24)
  externfunc __showstr, debug
  jmp .get_next_key

  ;----

  .wake_th0:
  cmp [th_id0], dword 0
  jz .get_next_key
  and [th_top_left_side.requests], byte 0xFE
  mov eax, [th_id0]
  externfunc __wake_thread, noclass
  jmp .get_next_key

  .wake_th1:
  cmp [th_id1], dword 0
  jz .get_next_key
  and [th_top_right_side.requests], byte 0xFE
  mov eax, [th_id1]
  externfunc __wake_thread, noclass
  jmp .get_next_key

  .wake_th2:
  cmp [th_id2], dword 0
  jz .get_next_key
  and [th_bottom_left_side.requests], byte 0xFE
  mov eax, [th_id2]
  externfunc __wake_thread, noclass
  jmp .get_next_key

  .wake_th3:
  cmp [th_id3], dword 0
  jz .get_next_key
  and [th_bottom_right_side.requests], byte 0xFE
  mov eax, [th_id3]
  externfunc __wake_thread, noclass
  jmp .get_next_key

  ;----

  .sleep_th0:
  cmp [th_id0], dword 0
  jz .get_next_key
  mov eax, [th_id0]
  externfunc __sleep_thread, noclass
  jmp .get_next_key
  
  ;----

  .sleep_th1:
  cmp [th_id1], dword 0
  jz .get_next_key
  mov eax, [th_id1]
  externfunc __sleep_thread, noclass
  jmp .get_next_key
  

  .sleep_th2:
  cmp [th_id2], dword 0
  jz .get_next_key
  mov eax, [th_id2]
  externfunc __sleep_thread, noclass
  jmp .get_next_key
  

  .sleep_th3:
  cmp [th_id3], dword 0
  jz .get_next_key
  mov eax, [th_id3]
  externfunc __sleep_thread, noclass
  jmp .get_next_key
  
  ;----

  .self_kill0:
  or byte [th_top_left_side.requests], byte 0x02
  jmp .get_next_key
  
  .self_kill1:
  or byte [th_top_right_side.requests], byte 0x02
  jmp .get_next_key
  
  .self_kill2:
  or byte [th_bottom_left_side.requests], byte 0x02
  jmp .get_next_key
  
  .self_kill3:
  or byte [th_bottom_right_side.requests], byte 0x02
  jmp .get_next_key

  ;----

  .self_sleep0:
  or byte [th_top_left_side.requests], byte 0x01
  jmp .get_next_key

  .self_sleep1:
  or byte [th_top_right_side.requests], byte 0x01
  jmp .get_next_key

  .self_sleep2:
  or byte [th_bottom_left_side.requests], byte 0x01
  jmp .get_next_key

  .self_sleep3:
  or byte [th_bottom_right_side.requests], byte 0x01
  jmp .get_next_key



_get_key:
  in al, 0x64
  test al, 0x01
  jz _get_key
  in al, 0x60
  or al, al
  js _get_key
  retn

str_help1:  db "thread 1: Q - Create, W - Kill, A - Wake, S - Sleep",0
str_help1b:           db "Z - Self Kill, X - Self Sleep",0
str_help2: db "thread 2: E - Create, R - Kill, D - Wake, F - Sleep",0
str_help2b:           db "C - Self Kill, V - Self Sleep",0
str_help3: db "thread 3: O - Create, P - Kill, K - Wake, L - Sleep",0
str_help3b:           db "M - Self Kill, , - Self Sleep",0
str_help4: db "thread 4: U - Create, I - Kill, H - Wake, J - Sleep",0
str_help4b:           db "B - Self Kill, N - Self Sleep",0
str_help5: db "ESC - Quit",0
str_killed: db "--------",0


th_id0: dd 0
th_id1: dd 0
th_id2: dd 0
th_id3: dd 0


th_top_left_side:
  .continue:
  inc edx
  externfunc __dword_out, debug

  ; check if sleep was requested
  test [.requests], byte 0x01
  jz short .no_sleep

  externfunc __sleep_thread, self
  .no_sleep:

  ; check if self kill was requested
  test [.requests], byte 0x02
  jz short .dont_die

  lea esi, [str_killed]
  externfunc __showstr, debug
  mov [th_id0], dword 0
  externfunc __kill_thread, self
  .dont_die:
  jmp short .continue

.requests: db 0


th_top_right_side:
  mov [.requests], byte 0
  .continue:
  inc edx
  externfunc __dword_out, debug
  
  ; check if sleep was requested
  test [.requests], byte 0x01
  jz short .no_sleep

  externfunc __sleep_thread, self
  .no_sleep:

  ; check if self kill was requested
  test [.requests], byte 0x02
  jz short .dont_die

  lea esi, [str_killed]
  externfunc __showstr, debug
  mov [th_id1], dword 0
  externfunc __kill_thread, self
  .dont_die:
  jmp short .continue

.requests: db 0


th_bottom_left_side:
  mov [.requests], byte 0
  .continue:
  inc edx
  externfunc __dword_out, debug
  
  ; check if sleep was requested
  test [.requests], byte 0x01
  jz short .no_sleep

  externfunc __sleep_thread, self
  .no_sleep:

  ; check if self kill was requested
  test [.requests], byte 0x02
  jz short .dont_die

  lea esi, [str_killed]
  externfunc __showstr, debug
  mov [th_id2], dword 0
  externfunc __kill_thread, self
  .dont_die:
  jmp short .continue

.requests: db 0


th_bottom_right_side:
  mov [.requests], byte 0
  .continue:
  inc edx
  externfunc __dword_out, debug
  
  ; check if sleep was requested
  test [.requests], byte 0x01
  jz short .no_sleep

  externfunc __sleep_thread, self
  .no_sleep:

  ; check if self kill was requested
  test [.requests], byte 0x02
  jz short .dont_die

  lea esi, [str_killed]
  externfunc __showstr, debug
  mov [th_id3], dword 0
  externfunc __kill_thread, self
  .dont_die:
  jmp short .continue

.requests: db 0


