SetPalette:
 xor eax,eax
 mov esi,palette
SelectIndex:
 push eax
 mov dx,3C8h     
 out dx,al
 inc dx 
 mov al,[esi]                                      
 out dx,al
 mov al,[esi + 1]                                   
 out dx,al
 mov al,[esi + 2]                                  
 out dx,al
 pop eax
 add esi,3
 inc eax
 cmp eax,256
 jne SelectIndex
 ret

palette:
incbin "boxed_in.pal"
 
square_gfx:
incbin "theme_a.raw"
