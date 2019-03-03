[bits 32]

%include "vid/debug.diable.inc"
%include "vid/video.inc"
%include "screen.inc"
%include "stdmodes.inc"

;%define _DEBUG_

;==============================================================================
                                                                  section .text
;                                        --------------------------------------

;==============================================================================
                                                       globalfunc screen.create
;                                        --------------------------------------
;>
;; Creates a screen the size of the video mode, as defined in the
;; driver.  If the CF is set, then the display manager will attempt to create
;; the screen directly on the video card.  When returning, EAX is the screen
;; number to be used as reference for when activating the screen.  EDI
;; holds the base address of the screen created.  If CF is set, an error has 
;; occured, EAX holds the error number, ECX may have more info about the
;; error.
;; 
;; parameters:
;; -----------
;;        EAX =   (undetermined)
;;        EBX =   Video Mode Options (driver dependant)
;;        ECX =   Video Mode
;;        EDX =   Video Driver
;;
;; returned values:
;; ----------------
;;        if CF = 0, successful
;;            EAX = Screen ID
;;            EBX = (undetermined)
;;            ECX = (undetermined)
;;            EDX = (undetermined)
;;            ESI = (undetermined)
;;            EDI = Base address of screen
;;            ESP = (undetermined)
;;            EBP = (undetermined)
;;
;;        if CF = 1, error occured
;;            EAX = error code
;;            EBX = (undetermined)
;;            ECX = (undetermined)
;;            EDX = (undetermined)
;;            ESI = (undetermined)
;;            EDI = (undetermined)
;;            ESP = (undetermined)
;;            EBP = (undetermined)
;<

;Step ONE, find out how much RAM this puppy needs

  push ebx	  ;push the options 

;if edx is 0, we are using the STDMODES (bios, real mode)
;for some strange reason using TEST didn't seem to give an accurate
;result, going back to cmp. :(

  cmp edx, 0
  je .using_stdmodes

;this is where the driver stuff goes
;for the moment, till we know how to use drivers, lets just push them

  push ecx        ;push the video mode
  push edx        ;push the driver CID

  mov eax, ecx
  vextern video.get_mode_info
  call video.get_mode_info
  push edi	;push active point  

  jmp .call_get_mem

.using_stdmodes:
  push ecx        ;push the video mode
  push edx        ;push the driver CID
  mov  eax, [silicium_videomodes + ecx*8]  ;ram needed
   
  mov edx, [silicium_videomodes + ecx*8 + 4]  ;active point
                                             
  push edx

;In theory, we should have the amount of RAM needed in eax
  mov  ecx, eax

;---STACK CONTENT---
;0 - Active point
;4 - Driver
;8 - Video Mode
;12 - Options

.call_get_mem:
  xor edx,edx
  externfunc  mem.alloc
;check to see if there was an error
  jc near .error_mem
;no error, continue
;store size of screen
  
  push ecx			;dont forget to pop it before the others 

;lets put that memory location aside for now, cause we still need to make the
;chain link
  mov ebp, edi			;abit of safe keeping
   
;that was easy

;Now, we sorta take for granted that there will be enough space for the
;link in the linked list, all we need is like 40bytes or so.
;]----[LINKED LIST DATA]-----[
;.previous_link:        Address to previous link
;.next_link:            Address to next link
;.driver:               Corresponding Driver to screen
;.videomode:            Video mode for screen
;.size_of_screen:       Total size of screen (in bytes)
;.entrance_point:       Address to starting point of the screen
;.verify_point:         Signature of Display Manager (0x0E0E0E0E) used to make 
;                       sure ppl dont screw up system via display manager

  mov ecx, screen_size
  xor     edx, edx
  externfunc  mem.alloc

;Check for an error coming from the memory manager
;testing eax didn't seem to work, cmp works
  jc near .error_mem

;OK, we got the memory, should be clear sailing from here so lets make sure
;we know that we DO have a screen
.test_scr:

  mov ebx, [silicium_is_no_screen]
   
  test ebx, ebx
  jnz .not_first_screen

;This is the first link in our chain of screens:
  mov [silicium_first_link], edi
   
  mov [edi + screen.next_link], dword 0x00000000 ;LAST screen.
;Make sure that it never gets identified as first screen again
  inc ebx
  mov [silicium_is_no_screen], ebx
   
  jmp .start_filling_struc

.not_first_screen:
;if it's not the first, then it's the last one on the chain.
;first step, update the original last link to include this as next
  mov esi, [silicium_last_link]
   
  mov [esi + screen.next_link], edi
  mov [silicium_last_link], edi
   
;Now just tell the last link that the previous link was the original

  mov [edi + screen.previous_link], esi

;Wow, that was crazy eh.  I'll try to optimize it later, cause thats some
;slow code there, waiting after the same registers all the time.

.start_filling_struc:
;All the alignment is done, lets start filling that struc.
  mov esi, ebp			;safe keeping back
  pop ebp			;temp ecx is back 
  mov [edi + screen.base_address], esi
  pop edx
  mov [edi + screen.active_point], edx
  pop edx
  pop ecx
  mov [edi + screen.driver], edx
  pop eax
  mov [edi + screen.videomode], ecx
  mov [edi + screen.video_options], eax
  mov edx, ebp

 ; mov ebp, [edi + screen.active_point]

  mov [edi + screen.size_of_screen], edx
  mov dword [edi + screen.verify_point], 0x0E0E0E0E  ;our signature

;Struc should be full (hopefully)

;for our own good, lets add a screen to the count. ;)
  mov eax, [silicium_number_of_screens]
   
  inc eax
  mov [silicium_number_of_screens], eax

;put screen number in eax, BEFORE we destroy edi
  mov eax, edi

;Put size of buffer in edx
;oops, it's already done ;)

;Put starting location of buffer in edi
  mov edi, esi
;New screen created successfully!
  retn

;---ERRORS---IF THE CPU EVER SEES THIS SOMETHING WENT WRONG.
;Error 1 (Memory)
.error_mem:
  stc
  mov ecx, eax  ;move exactly what went wrong to ecx
  xor eax, eax
  mov eax, 1    ;1=error in memory, code 1.
  mov edx, ecx
  retn

;==============================================================================
                                                       globalfunc screen.delete
;                                        --------------------------------------
;>
;; parameters:
;; -----------
;;        EAX =   Screen ID
;;
;; returned values:
;; ----------------
;;    if CF = 0, successful
;;        EAX = (undetermined)
;;        EBX = (undetermined)
;;        ECX = (undetermined)
;;        EDX = (undetermined)
;;        ESI = (undetermined)
;;        EDI = (undetermined)
;;        ESP = (undetermined)
;;        EBP = (undetermined)
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

;1st off, check to see if this is even a screen
  mov edx, [eax+screen.verify_point]
  xor edx, 0x0E0E0E0E
  jnz near .no_screen
;check if its active
  push eax          ;keep that screen reference handy
  cmp eax, [silicium_active_screen]
  jne .not_active
  mov [silicium_active_screen], dword 0
  jmp .active
.not_active:
;so we have a screen, deallocate it's actual SCREEN
  mov eax, [edx+screen.base_address]
  externfunc  mem.dealloc
.active:
  pop edx

  mov edi, [edx+screen.next_link]
  mov esi, [edx+screen.previous_link]
;now ESI, is the link before, EDI is the link after


;check to see if this is the last on the chain
  cmp edx, [silicium_last_link]
  jne .isanext
;if we are here, that means that we are taking out the last link

          cmp edx, [silicium_first_link]
          jne .isnotalast_and_first
         ;if we are here, we are taking out the last link and first link
        ;so ajusts the first&last links
          mov [silicium_first_link], dword 0x00000000
          mov [silicium_last_link], dword 0x00000000
        ;now just get rid of this damn chain link
          jmp .finish


        .isnotalast_and_first:
        ;that means that it's only the last link, so feel free to adjust the
        ;link before it. And update our last variable
          mov [esi+screen.next_link], dword 0x00000000
          mov [silicium_last_link], esi
          jmp .finish
.isanext:
          cmp edx, [silicium_first_link]
          jne .isaprevious
        ;if we are here that means we are taking out the first link
        ;so adjust the next links previous pointer
        ;and adjust our first link pointer
          mov [edi+screen.previous_link], dword 0x00000000
          mov [silicium_first_link], edi
          jmp .finish

        .isaprevious:
        ;AHA! so we are removing a link thats in the middle!
          mov ecx, [esi+screen.next_link]
          mov ebx, [edi+screen.previous_link]
          mov [edi+screen.previous_link], ecx
          mov [esi+screen.next_link], ebx
        ;no need to adjust our vars. :)

.finish:
  mov eax, edx
  xor edx,edx
  externfunc  mem.dealloc
  jc .error_mem
;for our own good, lets dec a screen to the count. ;)
  mov eax, [silicium_number_of_screens]
   
  dec eax
  mov [silicium_number_of_screens], eax


  retn

;WOOHOO!! WE TOOK OUT A SCREEN!

;------[ERRORS]------------
.error_mem:
  stc
  mov ecx, eax
  mov eax, 0x00000001
.no_screen:
  stc
  mov eax, 2
.done:  
retn

;==============================================================================
                                                       globalfunc screen.resize
;                                        --------------------------------------

retn

;==============================================================================
                                                   globalfunc screen.set_active
;                                        --------------------------------------
;>
;; parameters:
;; -----------
;; EAX = Screen ID
;; 
;; returned values:
;; ----------------
;; EDI = New base address of screen
;<

;first thing to do, figure out if there is already an active screen
 
  push eax

  mov esi, [silicium_active_screen]
  cmp esi, 0x00000000
  je .done_taking_out_old_screen
  push esi
 
;so now we have some old screen to get rid of. Luckily, its ID is in ESI
  mov     ecx, [esi + screen.size_of_screen]
  xor     edx,edx
  externfunc    mem.alloc
  jc      .error_mem
  mov edx, [ebp]   ;replaces those two lines^^
  mov esi, [edx + screen.active_point]
;ecx already contains the amount of bytes
  shr   ecx, 2  ;and now it's the number of dwords, and shr wonderful? :)
;edi is already the starting location of the mem allocated
  push edi  ;we need you in a few cycles

  .copy_old_screen:
  rep movsd

; hmm, that seemed too short, but hey.  Screen should be copied, change it's
; entrance point
  pop   edi
  pop   esi
  mov   [edx + screen.base_address], edi
.done_taking_out_old_screen:

.step1:
  pop edx ;screen ID of the WANNABE screen
;set the mode with the driver.
.step2:
  mov ebx, [edx + screen.driver]
;  test ebx, ebx ;if it's 0, we are using BIOS modes

  cmp ebx, 0x00000000
  je .using_bios_mode

.using_real_driver:
;set things up for calling the real driver
  mov eax, [edx + screen.videomode]
;externfunc debug.diable.print_regs_wait
  vextern video.set_mode
  call video.set_mode

  jmp .copy_new_screen

.using_bios_mode:
;set things up for the RM portal
  push dword 0x10  ;we need a int 10h
  mov eax, [edx + screen.videomode]
  ;thats it ladies and gents, lets do it. :)
  externfunc realmode.proc_call
  ;get rid of that last stack push
  pop edi

.copy_new_screen:
;now that old screen should be taken care of, lets mov our WANNABE 
;active scr
  mov edi, [edx + screen.active_point]
  mov ecx, [edx + screen.size_of_screen]
  shr ecx, 2
  mov esi, [edx + screen.base_address]
  mov eax, edi ;prolly faster this way
;now, EDI is where the screen WILL be, ESI is where it is
;and ECX is how many dwords to mov.
  rep movsd
;done moved. adjust what needs to be adjusted.
  mov [edx + screen.base_address], eax
;hrmm, that was easy.


.finish_off:
  mov edi, eax
  mov eax, edx
  mov [silicium_active_screen], eax
  clc
  retn

.error_mem:
  pop     esi
  pop     ebx
  mov     ecx, eax
  mov   eax, 0x00000001
  retn


%ifdef _DEBUG_
;==============================================================================
                                            globalfunc screen.create_test, 3001
;                                        --------------------------------------
;-----------[ITS TESTING TIME!!!]----------------------
;note this is MY test, you should not be looking to use
;this to test the display manager on a regular basis.
;this test is VERY slow, uses little to no optimization
;and is FAR from being properly commented.  if you want 
;to use this to test the display manager, go ahead, but 
;i warn you, its SLOW, and creates 2 screens without 
;getting rid of them.

  mov ebx, 0
  mov ecx, 0x13
  xor edx, edx
  call screen.create
  push eax
%ifdef _DEBUG_
  pushad
%endif
  ;mov ebx, silicium_done_create_str
  mov esi, silicium_done_create_str
   
  externfunc sys_log.print_string
  popad
  pushad
  mov edx, eax
  mov edi, 0xB8050
  externfunc sys_log.print_hex
  popad
  pushad
  mov edx, edi
  mov edi, 0xB8050+26
  externfunc sys_log.print_hex
  popad
  pushad
  mov edi, 0xB8050+50
  call _dev_display_hex
  popad
  pushad
  mov edx, [eax+silicium_screen_link.verify_point]
  cmp edx, 0x0E0E0E0E
  jne .error_exit
  mov esi, silicium_verify_point_yes
   
  externfunc sys_log.print_string
  popad
  pushad

  cmp edx, 64000
  jne .error_exit
  mov esi, silicium_screen_size_correct
   
  externfunc sys_log.print_string

  popad

  mov ebx, [eax+silicium_screen_link.entrance_point]
  cmp ebx, edi
  jne .error_exit
  mov esi, silicium_points_match
   
  externfunc sys_log.print_string

.done:
  mov esi, silicium_screen_verified
   
  externfunc sys_log.print_string
  retn

.error_exit:
  mov esi, siilcium_error_exiting
   
  externfunc sys_log.print_string

  mov esi, silicium_screen_verified
   
  externfunc sys_log.print_string
  mov ecx, 320
  add edi, 32000
;we are now at halfway point
  mov al, 0x9  ;nice blue so daboy says
  .color_loop:
  stosb
  loop .color_loop

  pop eax

  call screen.set_active

  mov ebx, 0
  mov ecx, 0x03
  xor edx, edx
  call screen.create
 
  call screen.set_active

  retn

%endif ; %ifdef _DEBUG_

;==============================================================================
                                                                  section .data
;                                        --------------------------------------

%ifdef _DEBUG_
silicium_done_create_str: db "Done Creating Screen, Verifying...",0
silicium_verify_point_yes: db "Point Verified, Checking Size...",0
silicium_error_exiting: db "An error occured while testing screen, exiting",0
silicium_screen_size_correct: db "Size Correct, Checking Entry Point...",0
silicium_points_match: db "Link Entry & EDI match.Screen working.",0
silicium_screen_verified: db "Screen verified.",0
silicium_screen_active: db "Screen Activated.",0
%endif

silicium_number_of_screens: dd 0
silicium_active_screen: dd 0
silicium_is_no_screen: db 0
silicium_first_link: dd 0
silicium_last_link: dd 0

;==============================================================================
                                                                section .c_info
;                                        --------------------------------------

  db 0,0,1,'a'
  dd str_name
  dd str_author
  dd str_copyright

  str_name: db "Silicium Display Manager",0
  str_author: db "Richard Fillion <rick@rhix.dhs.org>",0
  str_copyright: db "Distributed under the BSD License",0
