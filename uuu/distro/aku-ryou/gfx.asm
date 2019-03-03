; its awful and awkwards but I will optimize and fix it later :)
; enjoy!

%define SCR_WIDTH     320
%define pixmap.width  0
%define pixmap.height 2

; #uuu was here!
;[berkus] monsoon: kinda: 4 byte font identifier (?), base char width, char height, char range low,
;         char range high
;[berkus] then array of (1+char height*(char width byte aligned))*(range high-range low) bytes
;         of char defs
;[berkus] each char as byte - width adjustment (signed byte) then char data
;[berkus] char width byte aligned calculated after width adjustment is made
;[berkus] here's the format
;[berkus] you'll probably need the
;[berkus] "current font" handle
;[berkus] to keep base width and character range plus pointer to the char data (?)
;[berkus] well to simplify
;[berkus] char data could simply follow the header
;[berkus] so we just add sizeof(header) to the base font pointer

struc font_hdr
   .magic   resb 4
   .bwidth  resb 1
   .height  resb 1
   .low     resb 1
   .high    resb 1
endstruc

;------------------------------------------------
; ESI = 0-terminated string address
; EBX = start X
; EDX = start Y
; ECX = font pointer
;------------------------------------------------
draw_text_string:

   retn

;------------------------------------------------
; EBX = X
; EDX = Y
; EBP = color pixmap
; NO CLIPPING IS PERFORMED!!!
;------------------------------------------------
draw_pixmap:
   movzx eax, word [esi + pixmap.width]
   push eax ; save width
   sub eax, SCR_WIDTH
   neg eax
   ; eax has ajustment
   movzx ecx, word [esi + pixmap.height]
   push ecx ; save height

   mov esi, ebp
   add esi, 4 ; point to actual pixmap data

   mov ecx, edx   ; save Y
   shl ecx, 8     ; Y1 *= 256
   shl edx, 6     ; Y2 *= 64
   add ebx, ecx   ; X += Y1
   add ebx, edx   ; X += Y2
   add ebx, 0xa0000
   mov edi, ebx   ; point to the screen mem

   pop edx        ; get height

   mov ebx, eax  ; save advance

.loopy:
   pop ecx        ; get width
   push ecx       ; hook it back

.inner:
   lodsb
   test al, al
   cmovz ax, [edi]
   stosb
   loop .inner

   add edi, ebx    ; advance screen position
   dec edx
   jnz short .loopy

   pop ecx ; youck..waste it out

   retn


;------------------------------------------------
; EBX = X
; EDX = Y
; EBP = color pixmap
; ESI = mask  pixmap
; NO CLIPPING IS PERFORMED!!!
;------------------------------------------------
draw_pixmap_thru_mask:
   movzx eax, word [esi + pixmap.width]
   push eax ; save width
   sub eax, SCR_WIDTH
   neg eax                                       ; eax has ajustment
   movzx ecx, word [esi + pixmap.height]
   push ecx                                      ; save height

   add ebp, 4                                    ; point to actual pixmap data
   add esi, 4                                    ; the mask pixmap is considered of same size as
                                                 ; color pixmap so immediately point to the pixmap
                                                 ; start

   mov ecx, edx                                  ; save Y
   shl ecx, 8                                    ; Y1 *= 256
   shl edx, 6                                    ; Y2 *= 64
   add ebx, ecx                                  ; X += Y1
   add ebx, edx                                  ; X += Y2
   add ebx, 0xa0000
   mov edi, ebx                                  ; point to the screen mem

   pop edx                                       ; get height

   mov ebx, eax                                  ; save advance

.loopy:
   pop ecx                                       ; get width
   push ecx                                      ; hook it back

.inner:
   lodsb                                         ; get mask value, advance mask pixmap
   test   al, al                                 ; zero?
   cmovz  ax, [edi]                              ; yes, load value from video mem (could be SLOW)
   cmovnz ax, [ebp]                              ; no, load value from color pixmap
   stosb                                         ; write to screen
   inc    ebp                                    ; advance color pixmap too
   loop .inner                                   ; finish writing line

   add edi, ebx                                  ; advance screen position
   dec edx
   jnz short .loopy

   pop ecx                                       ; youck..waste it out

   retn

