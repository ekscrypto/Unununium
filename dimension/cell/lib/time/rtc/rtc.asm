;; $Header: /cvsroot/uuu/dimension/cell/lib/time/rtc/rtc.asm,v 1.9 2003/01/26 07:53:56 lukas2000 Exp $
;; 
;; Luke's Time library		Copyright (C) 2003 Lukas Demetz
;; Unununium OE			Distributed under the BSD license
;;
;; Note: Needs to be tested in non-standard situations (february 29, year 1999
;; 	 and so on)
;;
;; Status: Implemented functions work, even if sometimes strange things may
;;	   occur. Wish you a great time ;)
;;	   

[bits 32]

;                                           -----------------------------------
;                                                                       defines
;==============================================================================

;%define _DEBUG_
%define _FAST_YEAR_		; Use fast leap year calculation


;                                           -----------------------------------
;                                                                        strucs
;==============================================================================


section .c_info
	db 0,1,6,"a"
	dd str_title
	dd str_author
	dd str_copyrights

	str_title:
	db "Time Library",0

	str_author:
	db "Lukas Demetz <luke@hotel-interski.com>",0

	str_copyrights:
	db "BSD Licensed",0




;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init
global _start
_start:
init:
  pushad
  call rtc.get_current_time
  lprint "Actual UUU Time: %x:%x", DEBUG, edx, eax
  call _uuutime_to_fulldate
  lprint "                 %d-%d-%d   %d:%d:%d", DEBUG, ecx, ebx, eax, edx, esi, edi
        %ifdef _DEBUG_	
  	
  	call time.uuu_to_unix
  	lprint "Actual Unix time is: %d", DEBUG, eax
  	call time.unix_to_uuu
  	lprint "Computed back UUU-time is: %x:%x", DEBUG, EDX, EAX
  	call time.get_date_from_time
  	lprint "get_date_from_time: Computed back year %d and %d days", DEBUG, eax, ebx
  	call time.get_time_from_date
  	lprint "get_time_from_date: Returned %x:%x", DEBUG, edx, eax
  	popad
  	pushad
  	mov eax, 0ffffffeeh
  	mov edx, 00ffffffh
  	lprint "TESTING: Maximal value %x:%x", DEBUG, edx, eax
  	call _uuutime_to_fulldate
  	
	lprint "End UUU TIme will be: %d-%d-%d", DEBUG, ecx, ebx, eax
	lprint "             at time %d:%d:%d", DEBUG, edx, esi, edi

  	%endif
  clc
  popad
  retn




;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text



;                                           -----------------------------------
;                                                         rtc.get_current_time
;==============================================================================
globalfunc rtc.get_current_time
;> Returns
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; edx:eax = 64bit Uuu-Time
;; errors as usual
;<
  push ebx
  xor	eax, eax
  xor	edx, edx
  ; Step 1: Get year and subtract 2000 (the initial UUU epoch)
  mov 	al, 09h
  out	70h, al				
  jmp	$+2				; Little wait [ToFIX]
  in	al, 71h				; AL = current year, 2digits
  call _bcd_to_bin
  push ebx
  push ax
  call _rtc_get_century			; Hope it is at least 20 :P
  cmp eax, 20
  jnl .okcentury
  	mov eax, 20			; Wanna be in 20th century ;)
  .okcentury:
  
  push edx
  xor edx, edx
  mov ebx, 100				; Century * 100
  mul ebx
  ; EAX Years (like 2000)
  pop edx
  xor ebx, ebx
  pop bx
  
  add eax, ebx				; Add Years to ccentury
  pop ebx
  ;-------------------------------------;
  ; EAX = Year, 4digit, binary
  ;-------------------------------------;
  
  ; Parse the years starting from 00h 
  ; don't forget that actual year has NOT to be considered
  push eax
  	%ifdef _FAST_YEAR_
  call _years_to_days
  dbg lprint "GetTime: NEW! Returned days %d:%d", DEBUG, edx, eax
  mov edx, eax				; Get days into EDX
  	%else
.year_l: cmp eax, 2000
  	je .year_done
  	jna .year_done
  	call _get_days_of_year
  	dec eax
  	jmp .year_l
  
.year_done:
  	%endif
  pop eax
  
  dbg lprint "Days of all years: %d", DEBUG, edx
  dbg lprint "Current year: %d", DEBUG, eax
  ;-------------------------------------;
  ; EDX = days till actual year
  ; EAX = Actual year, 4digit
  ;-----------------------------------
  					;
  ; Step 2: Do the same with the Months	; > MONTH <
  push 	eax				;
  xor 	eax, eax			;
  mov 	al, 08h				;
  out	70h, al				;
  jmp	$+2				; Little wait [ToFIX]
  in	al, 71h				; AL = current month
  call _bcd_to_bin
  					;
  call _get_days_of_months		; Adds directly to edx
  dbg lprint "get_days_month returned EDX: %d", DEBUG, edx
  pop 	eax				;
  push 	edx				;
  call _get_days_of_year		;
  pop   edx				;
  jnc  .month_done			; Leap Year ?
  	cmp eax, 02h			; March or bigger or not?
  	jb .month_done			;
  	cmp eax, 02h
  	jne .monthgogo
  			; Check for day 29 !!!!!!
  			xor 	eax, eax		
  			mov 	al, 07h                
  			out	70h, al               
  			jmp	$+2
  			in	al, 71h
  			call _bcd_to_bin
  			cmp eax, 29
  			jne .month_done
  .monthgogo:
  	inc 	edx			;
					;
.month_done:				;
  ;-------------------------------------;
  ; EDX = days till actual month 
  ; EAX = Actual year, 4digit   / Will trash it
  ;-----------------------------------
  					; > DAY OF MONTH <
  ; Step 3: Days of Month ... :P	;
  xor 	eax, eax			;
  mov 	al, 07h				;                   
  out	70h, al				;                   
  jmp	$+2				; Little wait [ToFIX
  in	al, 71h				; AL = current day of month
  call _bcd_to_bin
  dec 	eax				; take away current day
  add 	edx, eax			; Add it to the other days
  ;-------------------------------------;
  ; EDX = days till actual day 
  ;-----------------------------------
  
  mov 	eax, edx		
  xor	edx, edx			; Prepare to get seconds up to now
  mov   ebx, 15180h			; 86400 seconds / day
  mul 	ebx				; Go!
  ;-------------------------------------;
  ; EDX:EAX = seconds for the days, missing hours and actual secs 
  ; EBX = free to use
  ;-----------------------------------
  
  push eax
  push edx
  ; Step 4: Get hours till now
  xor 	eax, eax			;
  mov 	al, 04h				;                   
  out	70h, al				;                   
  jmp	$+2				; Little wait [ToFIX
  in	al, 71h				; AL = current hour
  call _bcd_to_bin
  
  mov	bl, 60				; mul by 60 to get minutes
  xor 	edx, edx
  mul 	bl				; Go!
  mov	edx, eax
  ;-------------------------------------;
  ; EDX = minutes till actual hour 
  ; EBX = free to use
  ; stack+0= EDX of secs
  ; stack+4= EAX of secs
  ;-----------------------------------
  
  ; Step 5: Get minutes till now
  
  xor 	eax, eax			;
  mov 	al, 02h				;                   
  out	70h, al				;                   
  jmp	$+2				; Little wait [ToFIX
  in	al, 71h				; AL = current minute
  call _bcd_to_bin
  					;
  add 	edx, eax			; EDX = total minutes
  
  mov	ebx, 60
  mov   eax, edx
  xor   edx, edx 
  mul	ebx				; MUL by 60 to get seconds in EAX:EDX
  ;-------------------------------------;
  ; EDX:EAX = seconds hour-minute 
  ; EBX = free to use
  ; stack+0= EDX of secs
  ; stack+4= EAX of secs
  ;-----------------------------------
  
  ; Step 6: Get actual seconds
  push  eax
  xor 	eax, eax			;
  mov 	al, 00h				;                   
  out	70h, al				;                   
  jmp	$+2				; Little wait [ToFIX
  in	al, 71h				; AL = current seconds
  call _bcd_to_bin
  mov	ebx, eax
  pop	eax
  
  add	eax, ebx
  xor	ebx, ebx
  adc	edx, ebx			; added actual seconds to the others
  
  pop	ecx
  pop	ebx
  add	eax, ebx
  adc	edx, ecx
  dbg lprint "!!Calculated seconds: %d", DEBUG, eax
  
  ; Step 7: we NEED microseconds (1sec= 1000000microsecs)
  mov	ebx, 1000000
  mul	ebx
  pop	ebx
  ; Done
  ; EDX:EAX = UUU-Microsecond-time
  dbg lprint "UUU-time (EAX): %x", DEBUG, eax
  dbg lprint "UUU-time (EDX): %x", DEBUG, edx
  clc
  retn
  
;                                           -----------------------------------
;                                                         rtc.set_current_time
;==============================================================================
globalfunc rtc.set_current_time
;> Returns
;; parameters:
;; -----------
;; eax = year (signed) (-9999 to 9999)
;; ebx = month (1-12)
;; ecx = day (1-31)
;; edx = hours (0-23)
;; esi = minutes (0-59)
;; edi = seconds (0-59)
;;
;; returned values:
;; ----------------
;; errors as usual
;<
   ; Step 1: Check the values
   dbg lprint "SetRTC called, EAX = %x", DEBUG, eax
   cmp eax, 10000
   jge .year_error
   cmp eax, -10000
   jg .check_done
 .year_error:
   dbg lprint "SetRTC Error!", DEBUG
   stc
   retn
 .check_done:
   pushad
   ; Step 2: Write new values
   
   call _bin_to_4digbcd			; convert to BCD
   
   ; AX = BCDs of year:
   ;------------------------------------;
   ; AH = Century (2 dig)
   ; AL = year (2 dig)
   ;------------------------------------;
   push ax				;
   mov al,09h  				; Year ...
   out 70h,al  				;
   pop ax				; AL <- Year
   jmp $+2     				; a slight delay to settle things
   out  71h,al  			; Year written
   					; -----------------
   mov al,32h  				; Century ...
   out 70h,al  				;
   mov al, ah				; AL <- century
   jmp $+2     				; a slight delay to settle things
   out  71h,al  			; Century written
   	
   ;====================================; ------------------
   mov al, bl				; go with month -> BCD
   call _bin_to_2digbcd			;
   push ax				;
   mov al,08h  				; Month ...
   out 70h,al  				;
   pop ax				; AL <- Month
   jmp $+2     				; a slight delay to settle things
   out  71h,al  			; Month written
   ;====================================; ------------------
   					;
   mov al, cl				; go with day -> BCD
   call _bin_to_2digbcd			;
   push ax				;
   mov al,07h  				; Day ...
   out 70h,al  				;
   pop ax				; AL <- Day
   jmp $+2     				; a slight delay to settle things
   out  71h,al  			; Day written
   ;====================================; ------------------
   					;
   mov al, dl				; go with Hours -> BCD
   call _bin_to_2digbcd			;
   push ax				;
   mov al,04h  				; Hours ...
   out 70h,al  				;
   pop ax				; AL <- Hours
   jmp $+2     				; a slight delay to settle things
   out  71h,al  			; Hours written
   ;====================================; ------------------
   					;
   mov ax, si				; go with Minutes -> BCD
   call _bin_to_2digbcd			;
   push ax				;
   mov al,02h  				; Minutes ...
   out 70h,al  				;
   pop ax				; AL <- Minutes
   jmp $+2     				; a slight delay to settle things
   out  71h,al  			; Minutes written
   ;====================================; ------------------
   					;
   mov ax, di				; go with Seconds -> BCD
   call _bin_to_2digbcd			;
   push ax				;
   mov al,00h  				; Seconds ...
   out 70h,al  				;
   pop ax				; AL <- Seconds
   jmp $+2     				; a slight delay to settle things
   out  71h,al  			; Seconds written
   ;====================================;
   ; Done!
   ;
   ;------------------------------------;
   dbg lprint "SetRTC finished...", DEBUG
   popad				;
   clc					;
   retn					;


; ==================================================
; Our time-check loop
; --------------------------
_20sec_loop:
  pushad
  call time.get_current_time
  mov ebx, 1000000			; Get just the secs
  div ebx
  mov ebx, eax
  ; EBX = Seconds of current time
  call rtc.get_current_time
  mov ecx, 1000000
  div ecx
  
  cmp eax, ebx
  jz	.timeok
  ; Need to adjust system time
  call rtc.get_current_time
  call time.set_current_time
.timeok:
  ; [ToDO] RealTime thread rescheduling
  popad
  retn
  
  
  
;==============================================================================
;								Real TIME lib
;------------------------------------------------------------------------------

;                                           -----------------------------------
;                                                        time.get_current_time
;==============================================================================
globalfunc time.get_current_time
;>
;; returns:
;; --------
;;  edx:eax : current 64bit Uuu-Time
;<
  ;mov eax, dword [hra.data_system_time]
  ;mov edx, dword [hra.data_system_time+4]
  retn

;                                           -----------------------------------
;                                                        time.set_current_time
;==============================================================================
globalfunc time.set_current_time
;>
;; inputs:
;; --------
;;  edx:eax : current 64bit Uuu-Time
;;
;; returns:
;; --------
;;  none
;<
  pushad
  ;externfunc hra.update_system_time
  call _uuutime_to_fulldate
  dbg lprint "Set_time: Going to call RTC with values:", DEBUG
  dbg lprint "Set_time: %d year, %d month, %d day", DEBUG, eax, ebx, ecx
  dbg lprint "Set_time: %d hours, %d minutes, %d seconds", DEBUG, edx, esi, edi
  call rtc.set_current_time
  popad
  
  retn

;                                           -----------------------------------
;                                                      time.get_date_from_time
;==============================================================================
globalfunc time.get_date_from_time
;>
;; inputs:
;; --------
;;  edx:eax : current 64bit Uuu-Time
;;
;; returns:
;; --------
;;  eax = Year, signed
;;  ebx = Days of year (1-366)
;<
  push ecx
  push esi
  push edi
  call _uuutime_to_fulldate
  pop edi
  pop esi
  
  ;-------------------------------------;
  ; EAX = Year
  ; EBX = Month
  ; ECX = Days
  ;-------------------------------------;
  push eax
  mov eax, ebx
  mov edx, ecx
  call _get_days_of_months		; Adds to eax calculated days of month
  pop eax
  mov ebx, edx
  pop ecx
  retn
  
;                                           -----------------------------------
;                                                      time.get_time_from_date
;==============================================================================
globalfunc time.get_time_from_date
;>
;; inputs:
;; --------
;;  eax = Signed year
;;  ebx = day of the year
;;
;; returns:
;; --------
;;  edx:eax : 64bit UUU-time
;<
    push ebx
    mov edx, ebx
    ; EAX: Year
    	%ifdef _FAST_YEAR_
    call _years_to_days
    mov edx, eax
    	%else
    .looop:	
    	cmp eax, 2000
    	je .doneloop
    	call _get_days_of_year
    	dec eax
    	jmp .looop
    .doneloop:
    	%endif
    ; EDX = days
    mov ebx, 86400
    mov eax, edx
    xor edx, edx
    mul ebx
    mov ebx, 1000000
    mul ebx
    pop ebx
    retn

;                                           -----------------------------------
;                                                      time.get_time_from_tod
;==============================================================================
globalfunc time.get_time_from_tod
;>
;; inputs:
;; --------
;;  eax: hours
;;  ebx: minutes
;;  ecx: seconds
;;  edx: miliseconds
;;  esi: microseconds
;;
;; returns:
;; --------
;;  edx:eax : 64bit UUU-time
;<
   push ebx
   push edx
   mov ebx, 60
   xor edx, edx
   mul ebx
   pop edx
   pop ebx
   ; eax : minutes
   add eax, ebx
   push edx
   xor edx, edx
   mov ebx, 60
   mul ebx
   
   ; eax : seconds
   
   add eax, ecx
   mov ebx, 1000
   
   mul ebx
   pop ebx
   ; edx:eax : milliseconds
   add eax, ebx
   adc edx, 00h
   mov ebx, 1000
   mul ebx
   add eax, esi
   adc edx, 00h
   retn
   
;                                           -----------------------------------
;                                                      time.get_tod_from_time
;==============================================================================
globalfunc time.get_tod_from_time
;>
;; inputs:
;; --------
;;  edx:eax : 64bit Uuu-Time
;;
;; returns:
;; --------
;;  eax: hours
;;  ebx: minutes
;;  ecx: seconds
;;  edx: milliseconds
;;  esi: microseconds
;<
   pushad
   push eax
   push edx
   
   
   mov ebx, 1000
   div ebx
   mov esi, edx	; ESI = microseconds
   
   xor edx, edx
   mov ebx, 1000
   div ebx
   		; EDX = milliseconds
   
   
   pop edx
   pop eax
   
   push esi
   push edx
   call _uuutime_to_fulldate
   mov eax, edx			; Hours
   mov ebx, edx			; Minutes
   mov ecx, edi			; Seconds
   pop edx
   pop esi

   popad
   retn
   
;                                           -----------------------------------
;                                                                time.set_date
;==============================================================================
globalfunc time.set_date
;>
;; inputs:
;; --------
;;  eax: year (signed value)
;;  ebx: day of the year (1-366)
;;
;; returns:
;; --------
;;  none
;<
   pushad
   
   push ebx
   push eax
   call time.get_current_time
   call _uuutime_to_fulldate
   ; Need to change the following:
   pop edx			; Get back year				
   pop eax			; Get days
   push edx			; Save year again	
   
			; in: EAX = Days
			;     EDX = Actual Year
   call _get_month_from_days
			; out:EAX = days left
			;     ECX = Current month
   mov ebx, ecx
   mov ecx, eax
   pop eax
   
   call rtc.set_current_time
   popad
   retn
   

;                                           -----------------------------------
;                                                                 time.set_tod
;==============================================================================
globalfunc time.set_tod
;>
;; inputs:
;; --------
;;  eax: hours
;;  ebx: minutes
;;  ecx: seconds
;;  edx: miliseconds
;;  esi: microseconds
;;
;; returns:
;; --------
;;  none
;<
   pushad
   push esi
   push edx
   push ecx
   push ebx
   push eax
   
   call time.get_current_time
   call _uuutime_to_fulldate
   	; EAX = Year
	; EBX = Month
	; ECX = Days
   mov edx, ecx
   push eax
   
   	%ifdef _FAST_YEAR_
   call _years_to_days
   mov edx, eax
   	%else
   .year_l: cmp eax, 2000
  	je .year_done
  	jna .year_done
  	call _get_days_of_year
  	dec eax
  	jmp .year_l
  
.year_done:
	%endif
   pop eax
	; EDX = Days til now
	; EAX = Actual year
	; EBX = actual month
   push eax
   mov eax, ebx
     call _get_days_of_months		; Adds directly to edx
  dbg lprint "get_days_month returned EDX: %d", DEBUG, edx
  pop 	eax				;
  push 	edx				;
  call _get_days_of_year		;
  pop   edx				;
  jnc  .month_done			; Leap Year ?
  	cmp ebx, 02h			; March or bigger or not?
  	jb .month_done			;
  	cmp ebx, 02h
  	jne .monthgogo
  			; Check for day 29 !!!!!!
  			xor 	eax, eax		
  			mov 	al, 07h                
  			out	70h, al               
  			jmp	$+2
  			in	al, 71h
  			call _bcd_to_bin
  			cmp eax, 29
  			jne .month_done
  .monthgogo:
  	inc 	edx			;
					;
.month_done:				;
   add edx, ecx				; Add days till today - 1
   dec edx
   mov eax, edx
   xor edx, edx
   mov ebx, 24
   mul ebx
   ; EAX = Total hours
   pop ebx				; Get back hours
   add eax, ebx
   mov ebx, 60
   mul ebx
   ; EAX = Total minutes
   pop ebx				; Get back minutes
   add eax, ebx
   mov ebx, 60
   mul ebx
   ; EAX = Total Seconds
   pop ebx				; Get back seconds
   add eax, ebx
   mov ebx, 1000
   mul ebx
   ; EDX:EAX = Milliseconds
   pop ebx				; Get back milliseconds
   add eax, ebx
   adc edx, 00h
   mov ebx, 1000
   mul ebx
   ; EDX:EAX = Microseconds UUU-time
   pop ebx				; Get back microseconds
   add eax, ebx
   add edx, 00h
   ; Huhu, set time now
   call time.set_current_time
   popad
   retn
   
;                                           -----------------------------------
;                                                             time.unix_to_uuu
;==============================================================================
globalfunc time.unix_to_uuu
;>
;; inputs:
;; --------
;;  eax : 32bit Unix-time
;;
;; returns:
;; --------
;;  edx:eax : 64bit uuu-time
;<
   push ebx
   sub eax, 386D4380h			; Remove Unix seconds (1970-1999)
   xor edx, edx
   mov ebx, 1000000			; Get back microseconds, yeah
   mul ebx
   pop ebx
   retn
   
;                                           -----------------------------------
;                                                             time.uuu_to_unix
;==============================================================================
globalfunc time.uuu_to_unix
;>
;; inputs:
;; --------
;;  edx:eax : 64bit UUU-time
;;
;; returns:
;; --------
;;  eax : 32bit Unix-time
;<
   push ebx
   mov ebx, 60000000
   div ebx				; Get actual minutes -> EAX
   ; EAX = Minutes
   ; EDX = Microseconds
   ;
   push eax
   mov ebx, 1000000
   mov eax, edx
   xor edx, edx
   div ebx
   ; EAX = seconds
   ; Stack+0 = Minutes
   pop ebx
   push eax
   mov eax, ebx				; Minutes -> eax
   xor edx, edx
   mov ebx, 60
   mul ebx
  
   ; EAX = Seconds
   pop ebx
   add eax, ebx				; EAX = Seconds since 01-01-2000
   	
   add eax, 386D4380h			; Add unix (1970-1999) seconds
   pop ebx
   retn
   

;==============================================================================
;									Tools
;------------------------------------------------------------------------------

_rtc_get_century:
; out: 	EAX = century (!), like '20'
;
	xor 	eax, eax
	mov 	al, 32h
  	out	70h, al				
  	jmp	$+2			; Little wait [ToFIX]
  	in	al, 71h			; AL = current century, 2digits 
  	call _bcd_to_bin
  	; eax = century
  	retn
  	
  	
_uuutime_to_fulldate:
; in:
; EDX:EAX = UUU-time
;
; out:
; EAX = Year
; EBX = Month
; ECX = Days
; EDX = Hours
; ESI = Minutes
; EDI = Seconds
;
;
  mov ebx, 60000000			; Get minutes
  div ebx
  ;-------------------------------------;
  ; EAX = minutes
  ; EBX = free to use
  ; EDX = Rest / microseconds
  ;-------------------------------------;
  push eax
  mov eax, edx				; Microseconds -> eax
  xor edx, edx
  mov ebx, 1000000			; Get Seconds ;P
  div ebx				;
  ;-------------------------------------;
  ; EAX = seconds
  ; EBX = free to use
  ; EDX = Rest / free to use
  ; Stack+0 = Minutes
  ;-------------------------------------;
  pop ebx				; Minutes -> EAX
  push eax				; Seconds -> stack
  mov eax, ebx				;
  ;-------------------------------------;
  ; EAX = minutes
  ; EBX = free to use
  ; EDX = Rest / free to use
  ; Stack+0 = seconds
  ;-------------------------------------;
  xor edx, edx				; Minutes ( igh igh )
  mov ebx, 60				;
  div ebx				;
  push edx				; Minutes -> stack
  ;-------------------------------------;
  ; EAX = hours
  ; EBX = free to use
  ; EDX = Rest / free to use
  ; Stack+4 = seconds
  ; Stack+0 = minutes
  ;-------------------------------------;
  xor edx, edx				; Hours ( igh igh )
  mov ebx, 24				;
  div ebx				;
  push edx				; Hours -> stack
  ;-------------------------------------;
  ; EAX = days
  ; EBX = free to use
  ; EDX = Rest / free to use
  ; Stack+8 = seconds
  ; Stack+4 = minutes
  ; Stack+0 = hours
  ;-------------------------------------;
  					; Year(s), filling from 2000
  mov ecx, 2000				;
 .yearloop:
  	
  	
  	
  	pushad
  	xor edx, edx
  	mov ebx, 365
  	div ebx
  	cmp eax, 01h			; Enough days for a year left?
  	popad
  	jb .years_done
  	push eax
  	mov eax, ecx			; Pass year
  	call _get_days_of_year		;
  	pop eax				; EAX = days
  	jnc .addyear			; Carry = set on leap year
  	dec eax			; Leap year, dec 1 day more
  .addyear:
  	inc ecx				; Increase year
  	sub eax, 365			; Year ;)
  	jmp .yearloop
  	
 .years_done:

  push ecx				;
  ; [ToCHECK]
  add eax, 2				; Seems to cause somewhere a BUG!
  ;-------------------------------------;
  ; EAX = Days remaining
  ; ECX = free to use / year
  ; EBX = free to use
  ; Stack+12 = seconds
  ; Stack+8 = minutes
  ; Stack+4 = hours
  ; Stack+0 = year
  ;-------------------------------------;
  mov edx, ecx				; Year as argument
  call _get_month_from_days		; Month(s) ...
  ; Return values
  ;-------------------------------------;
  mov ebx, ecx				; Month
  mov ecx, eax				; Days
  pop eax				; Year
  pop edx				; Hours
  pop esi				; Minutes
  pop edi				; seconds
  retn
  
_get_days_of_year:
;
; in:
; 	EAX = Year (4 digit)
; 
; out:
;	adds to EDX = amount of days
;	Carry set when year has 366 days
;
	push eax
	push ebx
	push edx
	dbg lprint "get_days_of_year: EAX= %d, starting",DEBUG, eax
	
	; Check 1: Dividable trough 400 ?
	xor edx, edx
	push eax
	mov bx, 400
	div bx
	pop eax
	cmp edx, 00h
	jz	.addjear
	
	; Check 1: Dividable trough 100 ?
	xor edx, edx
	push eax
	mov bx, 100
	div bx
	pop eax
	cmp edx, 00h
	jz	.noaddjear
	; Check 1: Dividable trough 4 ?
	xor edx, edx
	push eax
	mov bx, 4h
	div bx
	pop eax
	cmp edx, 00h
	jz	.addjear
	
  .noaddjear:
  	pop edx
  	add edx, 365
  	pop ebx
  	pop eax
  	retn
  	
  .addjear:
  	pop edx
  	add edx, 366
  	pop ebx
  	pop eax
  	stc
  	retn

_get_days_of_months:
; Gets as input the actual month, and returns the days that passed till now
; eg: in:6 will result in amount of days till 31 may
;   !!!>>> IT DOESN'T CALCULATES WITH LEAP YEAR <<<!!!!!!!
; in: EAX = actual month
;
; out: adds to EDX = days
;
; Note: Quite stupid way of getting the months :P
	
	dec eax
	cmp eax, 12
	jnae .go
	stc
  	retn
.go:
	cmp eax, 00h
	jne .jan
	retn
	
  .jan:	;; FASTER VERSION
  	shl eax, 2			; * by 4
  	sub eax, 4
  	add edx, [_data_month_array+eax]
  	retn 
  	;; ------------- FINISH
  	
  
_get_month_from_days:
; in: EAX = Days
;     EDX = Actual Year
;
; out:EAX = days left
;     ECX = Current month
;
; Note: It checks also for leap year
;	
	dbg lprint "Days->Month: Called with %d days and %d year", DEBUG, eax, edx
	cmp eax, 31
	jnbe .feb
	mov ecx, 1
	retn
  .feb:
  	cmp eax, 59
  	jnbe .feb_leap
  	mov ecx, 2
  	sub eax, 31
  	retn
  .feb_leap:
  	pushad
  	mov eax, edx
  	call _get_days_of_year
  	popad
  	jnc .mar
  		; is leap year, feb has +1 day more
  	cmp eax, 60
  	jnbe .mar_leap
  	mov ecx, 2
  	sub eax, 31
  	retn
  .mar_leap:
  	inc eax				; is leap year!
  .mar:					; Continue
  	cmp eax, 5ah
  	jnbe .apr
  	mov ecx, 3
  	sub eax, 59
  	retn
  .apr:
  	cmp eax, 78h
  	jnbe .may
  	mov ecx, 4
  	sub eax, 5ah
  	retn
  .may:
  	cmp eax, 97h
  	jnbe .jun
  	mov ecx, 5
  	sub eax, 78h
  	retn
  .jun:
  	cmp eax, 0B5h
  	jnbe .jul
  	mov ecx, 6
  	sub eax, 97h
  	retn
  .jul:
  	cmp eax, 0D4h
  	jnbe .aug
  	mov ecx, 7
  	sub eax, 0B5h
  	retn
  .aug:
  	cmp eax, 0F3h
  	jnbe .sep
  	mov ecx, 8
  	sub eax, 0D4h
  	retn
  .sep:
  	cmp eax, 111h
  	jnbe .oct
  	mov ecx, 9
  	sub eax, 0F3h
  	retn
  .oct:
  	cmp eax, 130h
  	jnbe .nov
  	mov ecx, 10
  	sub eax, 111h
  	retn
  .nov:
  	cmp eax, 14Eh
  	jnbe .dec
  	mov ecx, 11
  	sub eax, 130h
  	retn
  .dec:
  	mov ecx, 12
  	sub eax, 14Eh
  	;sub eax, 30
  	retn
	

%ifdef _FAST_YEAR_
_years_to_days:
; in: EAX = Year
; out: EDX:EAX = Days since 2000
;
	push ebx			; Save EBX
	push esi			;
	push edi			;
	xor edx, edx			; Clear EDX
	sub eax, 2000			; Take away till year 2000
	test eax, eax			; is 0?
	jz .done			; Done
					;
	mov ebx, 400			;
	div ebx				;
	;-------------------------------;
	; EAX = Number of 400-years	
	; EDX = Remaining years
	; EBX = free to use
	; ESI = free to use
	; EDI = free to use
	;-------------------------------;
	push edx			; Save remaining on stack
	test eax, eax			; Result == 0?
	jz .test_100			; Skip and go on	
					;
	xor edx, edx			; Clear EDX
	mov ebx, 146097			; Days of 400 years
	mul ebx				; Multiply
	;-------------------------------;
	; EDX:EAX = Days till now
	; Stack+0 = Remaining years to parse
	; EBX = free to use
	;-------------------------------;
  .test_100:				; Parse 100-year-steps
	mov esi, eax			; Save EAX
	mov edi, edx			; Save EDX
	pop eax				; Get remaining years
	xor edx, edx			; Clear EDX
	mov ebx, 100			; Divide through 100
	div ebx				;
	;-------------------------------;
	; EAX = Number of 100-years	
	; EDX = Remaining years
	; EBX = free to use
	; ESI = EAX of days till now
	; EDI = EDX of days till now
	;-------------------------------;
	push edx			; Save remaining years
	test eax, eax			; Result == 0?
	jz .test_4			;
					;
	xor edx, edx			;
	mov ebx, 36524			; Days of 100 years
	mul ebx				; Multiply
	add esi, eax			; Add to actual days
	adc edi, edx			; ...
	;-------------------------------;
	; EDI:ESI = Days till now
	; Stack+0 = Remaining years to parse
	; EBX = free to use
	; EAX = free to use
	; EDX = free to use
	;-------------------------------;
 .test_4:				; --------------------
	pop eax				; Get remaining years
	xor edx, edx			; Clear EDX
	mov ebx, 4			; Divide through 100
	div ebx				;
	;-------------------------------;
	; EAX = Number of 4-years	
	; EDX = Remaining years
	; EBX = free to use
	; ESI = EAX of days till now
	; EDI = EDX of days till now
	;-------------------------------;
	push edx			; Save remaining years
	test eax, eax			; Result == 0?
	jz .addyears			;
					;
	xor edx, edx			;
	mov ebx, 1461			; Days of 4 years
	mul ebx				; Multiply
	add esi, eax			; Add to actual days
	adc edi, edx			; ...
	;-------------------------------;
	; EDI:ESI = Days till now
	; Stack+0 = Remaining years to parse
	; EBX = free to use
	; EAX = free to use
	; EDX = free to use
	;-------------------------------;
.addyears:				;
	pop eax				; Get remaining years
	xor edx, edx			; Clear EDX
	mov ebx, 365			; 365 days / year
	mul ebx				; Multiply
	add eax, esi			; Add to actual days
	adc edx, edi			; ...
	;-------------------------------;
	; EDX:EAX = Total days
	;-------------------------------;
  .done:
  	pop edi
  	pop esi
  	pop ebx
  	retn
  %endif
  
_bin_to_2digbcd:
; in: AL = binary upto 99
; out: AL = BCD
	
	AAM
	AAD 16
	retn
	
_bin_to_4digbcd:
;input:
;   ax = number (0...9999)
;output:
;   ax = bcd equivalent (4 digits)
;
	push ebx
	push edx
	pushfd
	push ecx
	mov dx, ax
	xor cl, cl
	xor bx, bx
	mov ah, 16
	.l1:
	mov al, bl
	add al, al
	daa
	mov bl, al
	mov al, bh
	adc al, al
	daa
	mov bh, al
	adc cl, cl
	rol dx, 1
	adc bl, 0
	dec ah
	jnz .l1
	
	pop ecx
	popfd
	pop edx
	mov ax, bx
	pop ebx
	retn


_bcd_to_bin:
; in: AL = BCD
; out: AL = binary
	push	cx
	push	ax

	mov	cl,10h		; get a divisor in Hex
	div	cl		; compute count of 16's and a remainder
	mov	ch,ah		; copy remainder to CH
	mov	cl,0Ah		; get a multiplicand in decimal
	mul	cl		; convert even 16's to even 10's
	add	al,ch		; add remainder to get final result

	pop	cx
	mov	ah, ch
	pop	cx

	retn


;                                           -----------------------------------
;                                                                          data
;==============================================================================

; hra.data_system_time
section .data
align 4, db 0
_data_month_array:
	dd 00h
	dd 31
	dd 3Bh
	dd 5Ah
	dd 78h
	dd 97h
	dd 0B5h
	dd 0D4h
	dd 0F3h
	dd 111h
	dd 130h
	dd 14Eh
	dd 16Dh

