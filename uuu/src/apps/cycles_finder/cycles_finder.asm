; Unununium Operating Engine
; Copyright (C) 2001, Dave Poirier
; Distributed under the BSD License
;
; This little application allow you to see how many cycles a routine of your
; code take.  Simply place the code to be tested within the defined limits
; and run the application.  The first value on the top is the number of cycles
; required to run your code, while the second value is the actual size taken
; by it.
;
; all values are displayed in hexadecimal.

[bits 32]
section s_app_cycle_finder

start:
  externfunc __enter_critical_section
  
  xor eax, eax
  cpuid
  rdtsc
  push eax
  push edx
  xor eax, eax
  cpuid
  rdtsc
  push eax
  push edx
  rdtsc
  push eax
  push edx
  ; start of code to test
  ;----------------------
  .code_start:

  nop

  .code_end:
  ;--------------------
  ; end of code to test
  xor eax, eax
  cpuid
  rdtsc
  pop ecx
  pop ebx
  sub eax, ebx
  sbb edx, ecx
  pop ecx
  pop ebx
  pop esi
  pop edi
  sub ebx, edi
  sbb ecx, esi
  sub eax, ebx
  sbb edx, ecx
  mov edi, 0xB8000
  externfunc __dword_out, debug
  mov edx, eax
  mov edi, 0xB8010
  externfunc __dword_out, debug
  mov edx, (.code_end - .code_start)
  mov edi, 0xB80A0
  externfunc __dword_out, debug_ack

  externfunc __leave_critical_section
  retn

original_count: dd 0,0
overhead: dd 0,0
