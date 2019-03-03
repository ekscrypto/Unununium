;--------------------------------------------------------------------------==|
; Mode13h Video Driver                 Copyright (c) 2000-2001 Richard Fillion
;                                            Distributed under the BSD License
;--------------------------------------------------------------------------==|
; File description:
;
;This driver provides the standard drawing routines and video card
;handling routines for most standard VGA modes.
;
;notes:
;this driver should work for any VGA compatible video card, which is almost
;all of them out there from ISA to AGP.  It is not capable of being loaded
;twice for dual video cards, a special version will be made for that.  


[bits 32]

section .c_info

  db 0,0,1,'a'
  dd str_name
  dd str_author
  dd str_copyrights

  str_name: db "VGA Driver via bios",0
  str_author: db "Richard Fillion (rick@rhix.dhs.org)",0
  str_copyrights: db "Distributed under BSD License",0

section .c_init


nop
;initialization:
;  push esi
;  lea esi, [.initstr_completed]
;  externfunc string_out, system_log
;  
;  pop esi
;  jmp short .completed
;
;.initstr_completed: db "VGA video driver loaded", 0x0A, 0
;
;.completed:



section .text


 
;; <indigo> TODO: there needs to be written a sort of unified driver manager
;; thingie to keep track of all these drivers. While the old FID/CID system
;; would have not required this, drivers are the only components that need it
;; so it was decided that this would be part of another cell. Until this
;; manager is written these functions have been given tempoary negitive VIDs.




globalfunc video.get_mode_info
;--------------[GET MODE INFORMATION]-------------
;>
;;DAMNIT!  I had to scrap the idea of only having one mode, 
;;cause afterall what kinda driver would this be if there were only
;;one mode.  ARGH! (Rick)
;;
;;Parameters:
;;---------------
;;        EAX = Mode
;;
;;Returned Values:
;;-----------------
;;    if CF = 0, successful
;;        EAX = Mode
;;        EBX = (untouched)
;;        ECX = Size of screen needed
;;        EDX = (untouched)
;;        ESI = (untouched)
;;        EDI = Base of screen when active
;;        ESP = (untouched)
;;        EBP = (untouched)
;;
;;    if CF = 1, error occured
;;        EAX = error code
;;        EBX = (undetermined)
;;        ECX = (undetermined)
;;        EDX = (undetermined)
;;        ESI = (undetermined)
;;        EDI = (undetermined)
;;        ESP = (undetermined)
;;        EBP = (undetermined)
;<
  
  mov ecx, [VGA_modes + 8 * eax]     ; that gives us the size
  mov edi, [VGA_modes + 8 * eax + 4] ; that gives use destination
  clc 					;almost a waste of a cycle
  retn 


;get_mode_info


globalfunc video.restore_card_state
;----------------[RESTORE CARD STATE]-----------------
;>
;; i'll look into this. :)  XXX <-signal for HACK (rick)
;;
;<

  mov bx, 0x5000
  push dword 0x50000000  ;sets ES to 5
  push dword 0x10	;int 10h
  mov al, 0x1C		;function 0x1C
  mov ah, 02h		;restore state
  externfunc realmode.proc_call

;should be done that, put the stack back to normal

  add esp, byte 8 	;done
  
  xor al, 0x1c		;check if all went well
  jnz .error
  clc
  retn

.error:
  stc
  mov eax, 0x01
  retn




globalfunc video.save_card_state
;------------------[SAVE CARD STATE]------------
;>
;; this one too i guess.  XXX <-signal for HACK (rick)
;;
;<

save_state:
;alright, we will be stealing memory from 0x55000 on

  mov bx, 0x5000
  push dword 0x50000000  ;sets DS to 5
  push dword 0x10	;int 10h
  mov al, 0x1C		;function 0x1C
  mov ah, 01h		;save state
  externfunc realmode.proc_call

;must restore right after (most bios screw the registers)
 
  mov ah, 02h		;restore state
  externfunc realmode.proc_call

;should be done that, put the stack back to normal

  add esp, byte 8 	;done
  
  xor al, 0x1c		;check if all went well
  jnz .error
  clc
  retn

.error:
  stc
  mov eax, 0x01
  retn

globalfunc video.set_mode
;--------------[SET RESOLUTION]------------------
;>
;;Parameters:
;;---------------
;;        EAX = Mode
;;
;;Returned Values:
;;-----------------
;;    if CF = 0, successful
;;        EAX = Mode
;;        EBX = (untouched)
;;        ECX = (untouched)
;;        EDX = (untouched)
;;        ESI = (untouched)
;;        EDI = (untouched)
;;        ESP = (untouched)
;;        EBP = (untouched)
;;
;;    if CF = 1, error occured
;;        EAX = error code
;;        EBX = (undetermined)
;;        ECX = (undetermined)
;;        EDX = (undetermined)
;;        ESI = (undetermined)
;;        EDI = (undetermined)
;;        ESP = (undetermined)
;;        EBP = (undetermined)
;<
  cmp eax, [current_mode]
  je .done			;if desired video mode = current mode, why change?
  push dword 0x10 		;we need a int 10h (bios change res interupt)
  ;mode is already in eax 
  ;thats it ladies and gents, lets do it. :)
  externfunc realmode.proc_call
  add esp, byte 4 		;get rid of that last stack push
  .done:
  clc  				;how can any of this go wrong? :)
  retn

;set_rez
  
globalfunc video.get_mode
;--------------[GET RESOLUTION]------------------
;>
;;Parameters:
;;---------------
;;        None
;;
;;Returned Values:
;;-----------------
;;    if CF = 0, successful
;;        EAX = Mode
;;        EBX = (undetermind)
;;        ECX = (untouched)
;;        EDX = (untouched)
;;        ESI = (untouched)
;;        EDI = (untouched)
;;        ESP = (untouched)
;;        EBP = (untouched)
;;
;;    if CF = 1, error occured
;;        EAX = error code
;;        EBX = (undetermined)
;;        ECX = (undetermined)
;;        EDX = (undetermined)
;;        ESI = (undetermined)
;;        EDI = (undetermined)
;;        ESP = (undetermined)
;;        EBP = (undetermined)
;<
  
  mov eax, dword [current_mode]  
  clc  				;how can any of this go wrong? :)
  retn




;current mode:
current_mode: dd 3  ;3 is default mode when comp starts

;---------------[MODE LISTING]------------------
;here we insert all the modes that are VGA compatible, and abit
;of info about them for the programmers. You may wish to add 
;modes or take some out.


;/--[MODE]-----|----[SIZE]------|---[Base when active]-----\
VGA_modes:
vidmode00:      dd      0       ,       0
vidmode01:      dd      0       ,       0
vidmode02:      dd      0       ,       0
vidmode03:      dd      8000    ,       0xB8000
vidmode04:      dd      0       ,       0
vidmode05:      dd      0       ,       0
vidmode06:      dd      0       ,       0
vidmode07:      dd      0       ,       0
vidmode08:      dd      0       ,       0
vidmode09:      dd      0       ,       0
vidmode0A:      dd      0       ,       0
vidmode0B:      dd      0       ,       0
vidmode0C:      dd      0       ,       0
vidmode0D:      dd      32000   ,       0xA0000
vidmode0E:      dd      64000   ,       0xA0000
vidmode0F:      dd      28000   ,       0xA0000
vidmode10:      dd      0       ,       0
vidmode11:      dd      38400   ,       0xA0000
vidmode12:      dd      153600  ,       0xA0000
vidmode13:      dd      64000   ,       0xA0000
