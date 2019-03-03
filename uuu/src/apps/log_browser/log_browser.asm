;; To use this:
;;
;; extern app_log_browser
;; call app_log_browser

[bits 32]

%include "vid/sys_log.inc"

section .text

global _start

_start:
; XXX until strontium is back
;  externfunc enter_critical_section, noclass

  externfunc sys_log.get_log_pointer
.next_part:
  push esi
  lea esi, [.browser_title]
  mov edi, 0xb8000
  push edi
  mov ecx, 1000
  mov eax, 0x07200720
  repz stosd
  pop edi
  mov ah, 0x0F
  call logger_outstr
  pop esi
  push esi
  call logger_out_log
  pop esi
.get_key:
  call logger_getkey
  cmp al, 0x01
  jz .quit
  cmp al, 0x48
  jz .up_one_line
  cmp al, 0x50
  jz .down_one_line
  cmp al, 0x51
  jz .page_down
  cmp al, 0x49
  jz .page_up
  jmp short .get_key

.quit:
; XXX until strontium is back
;  externfunc leave_critical_section, noclass
  xor eax, eax
  retn

.down_one_line:
  call .get_down_one_line
  jmp short .next_part

.up_one_line:
  call .get_up_one_line
  jmp short .next_part

.page_up:
  mov ecx, 15
  .page_up_one_more:
  call .get_up_one_line
  loop .page_up_one_more
  jmp short .next_part

.page_down:
  mov ecx, 15
  .page_down_one_more:
  call .get_down_one_line
  loop .page_down_one_more
  jmp near .next_part


.get_up_one_line:
  cmp [esi - 2], byte 0
  jz .get_up_one_line_end
  dec esi
.search_start_of_previous_line:
  dec esi
  cmp [esi], byte 0
  jnz .search_start_of_previous_line
  inc esi
.get_up_one_line_end:
  retn


.get_down_one_line:
  cmp [esi], byte 0
  jz .get_down_one_line_end
.search_start_of_next_line:
  inc esi
  cmp [esi], byte 0
  jnz .search_start_of_next_line
  inc esi
.get_down_one_line_end:
  retn

  

.browser_title: db "FRuSTRaTiON Log Browser, version 0.1",0

logger_getkey:
  in al, 0x64
  test al, 0x01
  jz logger_getkey
  in al, 0x60
  or al, al
  js logger_getkey
  retn

logger_outstr:
.displaying:
  lodsb
  cmp al, 0x0A
  jz .next_line
  stosw
  or al, al
  jnz .displaying
  call .do_next_line
  retn

.next_line:
  call .do_next_line
  jmp short .displaying

.do_next_line:
  push eax
  lea eax, [edi - 0xb8000]
  xor ebx, ebx
  xor edx, edx
  mov bl, 0xA0
  div ebx
  inc eax
  mul ebx
  lea edi, [eax + 0xB8000]
  pop eax
  retn


logger_out_log:
  mov ah, 0x09
  cmp [esi], byte 0
  jz .end
  cmp edi, 0xb8000 + (25*0xA0)
  jae .end
  push esi
  lea esi, [.line_indicator]
  call logger_outstr
  lea edi, [edi - 0x9A]
  pop esi
  mov ah, 0x07
  call logger_outstr
  jmp short logger_out_log
.end:
  retn

.line_indicator: db "-> ",0
