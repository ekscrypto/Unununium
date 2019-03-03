;; Keyboard Scancode acquisition tool
;; By EKS - Dave Poirier

org 0x7C00
bits 16

  cli
  jmp short start

start:
  push cs
  pop ax
  mov ds, ax
  mov ss, ax
  mov sp, $$
  push word 0xB800
  pop es

  mov cx, 2000
  mov ax, 0x0720
  xor di, di
  rep stosw

  mov si, strings.instructions
  call string_out
  call new_line

  mov [(0x09*4) + 00], word _kb_handler
  mov [(0x09*4) + 02], cs
  sti
  jmp short $


_kb_handler:
  pusha
  mov al, 0x20
  out 0x20, al
  in al, 0x60
  cmp al, 0x01
  jz short .bypass
  cmp al, 0x81
  jz short .new_sequence
  call hex_out
.bypass:
  popa
  iret
.new_sequence:
  call new_line
  jmp short .bypass

new_line:
  mov di, [tty.old]
  add di, word 0xA0
  cmp di, 0xA0*25
  jb short .oki
  mov di, 0xA0
.oki:
  mov [tty.cur], di
  mov [tty.old], di
  push di
  mov cx, 80
  mov al, ' '
  mov ah, 0x07
  rep stosw
  pop di
  mov si, strings.seq
  call string_out
  retn



string_out:
  mov ah, 0x07
  mov di, [tty.cur]
.processing:
  lodsb
  stosw
  test al, al
  jnz short .processing
  mov [tty.cur], di
  retn

hex_out:
  mov di, [tty.cur]
  mov ah, 0x0F
  mov dl, al
  shr al, 4
  and dl, ah
  cmp al, 0x0A
  sbb al, 0x69
  das
  stosw
  mov al, dl
  cmp al, 0x0A
  sbb al, 0x69
  das
  stosw
  mov al, ' '
  stosw
  mov [tty.cur], di
  retn

tty:
.cur: dd 0
.old: dd 0

strings:
.seq: db "SEQUENCE: ",0
.instructions: 
db "Escape - start new sequence.  Big Red Switch - power down your computer",0

times 510-($-$$) db 0
db 0x55, 0xAA
