;; $header
;; fRoZen cell
;; Copyright (C) 2001 by Lukas Demetz
;; This software may be distributed under the terms of the BSD license.
;;
;; status:
;; -------
;; some functions already done
;; [~] Test on as many different CPUs as we can
;; [X] Add Vendor String test
;; [D] Use extended cpuid
;; [ ] Add feature tests
;; [X] Add MMX test
;; [D] Add 3Dnow! test
;; [X] Add SSE test
;; [X] Add SSE2 test
;; coding ;)

%define _DEBUG_ 2	; debug level, bigger numbers == more debugging stuff
                        ; 2 = Precise output with strings to system log
                        ; 3 = 3Dnow! debug values


section .c_init
;;-----------------------------------------------------------------------------
;; When we receive control in this part the registers contain this:
;;
;; - EAX        Options (currently unused)
;; - ECX        Size in bytes of the free memory block reserved for our use
;; - EDI        Pointer to start of free memory block
;; - ESI        Pointer to CORE header
;;
;; These must be left as they are found.
;;------------------------------------------------------------------------------

  jmp start
init_done: db "[FroZen] Initialization completed (0.3.27)",0

no_fpu:	db "No FPU found!",0
fpu: db "FPU found!",0
str_mmx: db "MMX detected",0
str_sse: db "SSE detected",0
str_sse2: db "SSE2 detected",0

str_3dnow_s: db "3Dnow detected",0
str_3dnow_e: db "3Dnow+ (extended) detected",0

str_scan1: db "       CPU:  checking ...",0
str_scan2: db "================================",0
vendor: db "Vendor is ", 1
cpustr: db "Your CPU ID/Family is ", 1
str_stepping: db "* Stepping ", 1
str_model: db " Model ", 1
str_brand: db "* Brand ", 1
str_type: db " Type ", 1


;------------- Vendor stringies
%if _DEBUG_ > 1
str_intel: db "Intel",0
str_amd: db "AMD",0
str_via: db "IDT/VIA",0
str_crusoe: db "Transmeta",0
str_cyrix: db "Cyrix",0
str_umc: db "UMC",0
str_rise: db "Rise Technologies",0
str_nexgen: db "NexGen",0
str_other: db "other",0
str_na: db "N/A - CPUID not supported",0

  %endif
;------------------

wrapit: db 0
start:
  pushad
  mov esi, init_done
  externfunc sys_log.print_string
  %ifdef _DEBUG_
  
  mov esi, str_scan1
  externfunc sys_log.print_string
  mov esi, str_scan2
  externfunc sys_log.print_string
  mov esi, cpustr
  externfunc sys_log.print_string
  call	cpu.get_id_string
  mov	edx, eax
    
  externfunc	sys_log.print_decimal
  
  mov esi, wrapit
  externfunc sys_log.print_string
    
  call	cpu.get_id_string
  jnc	.fpu
  ;no fpu
  mov esi, no_fpu
  externfunc sys_log.print_string
  jmp .donne
  .fpu:
  ;found fpu
  mov esi, fpu
  externfunc sys_log.print_string
  
  .donne:
;  mov esi, wrapit
;  externfunc sys_log.print_string
  
  ; vendor
  mov esi, vendor
  externfunc sys_log.print_string
  
  
  call	cpu.detect_vendor
  mov	edx, eax
  
  %if _DEBUG_ > 1
  		; BANG KABOOM. Print Vendor string (haha) :P
  	cmp edx, __DEF_CPUID_VENDOR_INTEL__
  	jne .not_intel
  	mov esi, str_intel
  	jmp .dbg_print_vendor
  	
       .not_intel:
        cmp edx, __DEF_CPUID_VENDOR_AMD__
  	jne .not_amd
  	mov esi, str_amd
  	jmp .dbg_print_vendor
  	
       .not_amd:
        cmp edx, __DEF_CPUID_VENDOR_VIA__
  	jne .not_via
  	mov esi, str_via
  	jmp .dbg_print_vendor
  	
       .not_via:
        cmp edx, __DEF_CPUID_VENDOR_CYRIX__
  	jne .not_cyrix
  	mov esi, str_cyrix
  	jmp .dbg_print_vendor
  	
       .not_cyrix:
        cmp edx, __DEF_CPUID_VENDOR_RISE__
  	jne .not_rise
  	mov esi, str_rise
  	jmp .dbg_print_vendor
  	
       .not_rise:
        cmp edx, __DEF_CPUID_VENDOR_NEXGEN__
  	jne .not_nexgen
  	mov esi, str_nexgen
  	jmp .dbg_print_vendor
  	
       .not_nexgen:
        cmp edx, __DEF_CPUID_VENDOR_UMC__
  	jne .not_umc
  	mov esi, str_umc
  	jmp .dbg_print_vendor
  	
       .not_umc:
        cmp edx, __DEF_CPUID_VENDOR_CRUSOE__
  	jne .not_crusoe
  	mov esi, str_crusoe
  	jmp .dbg_print_vendor
  	
       .not_crusoe:
        cmp edx, __DEF_CPUID_VENDOR_OTHER__
  	jne .not_other
  	mov esi, str_other
  	jmp .dbg_print_vendor
  	
       .not_other:
        mov	esi, str_na
  	jmp .dbg_print_vendor
  	
     .dbg_print_vendor:
     externfunc sys_log.print_string
    %else
  externfunc	sys_log.print_decimal
  
  mov esi, wrapit
  externfunc sys_log.print_string
  
  %endif
  
  ;------------- GIMME MORE! ================ #
  ;;
  call	cpu.get_id_string
  	; STepping
  	mov esi, str_stepping
  	externfunc sys_log.print_string
  	xor	edx, edx
  	mov	dl, bh
  	externfunc	sys_log.print_decimal
  	call	cpu.get_id_string
  	; Model
  	mov esi, str_model
  	externfunc sys_log.print_string
  	xor	edx, edx
  	mov	dl, cl
  	externfunc	sys_log.print_decimal
  	
  	mov esi, wrapit
  	externfunc sys_log.print_string
  	call	cpu.get_id_string
  ; Brand
  	mov esi, str_brand
  	externfunc sys_log.print_string
  	xor	edx, edx
  	mov	dl, bl
  	externfunc	sys_log.print_decimal
  	call	cpu.get_id_string
  	; Type
  	mov esi, str_type
  	externfunc sys_log.print_string
  	xor	edx, edx
  	mov	dl, ch
  	externfunc	sys_log.print_decimal
  	
  	mov esi, wrapit
  	externfunc sys_log.print_string
  
  
  
  ;--- Allright, test for some features
  ; MMX
  call	cpu.detect_mmx
  jc	.no_mmx
  	mov esi, str_mmx
  	externfunc sys_log.print_string
  .no_mmx:
  
  ; SSE
   call	cpu.detect_isse
  jc	.no_isse
  	mov esi, str_sse
  	externfunc sys_log.print_string
  .no_isse:
  
  ; SSE2
   call	cpu.detect_isse2
  jc	.no_isse2
  	mov esi, str_sse2
  	externfunc sys_log.print_string
  .no_isse2:
  
  ; 3Dnow!
   call	cpu.detect_3dnow
   jmp .no_3dnow		; for now :P
  jc	.no_3dnow
  cmp	eax, 01h
  je	.extended_3dnow
  	mov esi, str_3dnow_s
  	externfunc sys_log.print_string
  	jmp	.no_3dnow
  	
  .extended_3dnow:
  	mov esi, str_3dnow_e
  	externfunc sys_log.print_string
  .no_3dnow:
  
;jmp $			; <------- Only UNCOMMENT if no log browser there
  %endif
  popad

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text


Temp:       	DW  0FFFFH
FEnv:      	DW  0,0,0,0,0,0,0
  
  
globalfunc	cpu.get_id_string
;>
;; Get the cpu identification string
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;; EAX = identifier of CPU ; errorcode on error
;;	CH  = Type ID
;;	CL  = Model ID
;;	BL  = Brand ID
;;	BH  = Stepping ID
;;	cf	set on error
;;
;; status: To test
;<
	   
	
		
	push	edx
	push	esp
	pushfd
       
       ; Step 1: Test for CPUID at all
       pushfd
	pop eax
	mov ebx, eax
	xor eax, 00200000h
	push eax
	popfd
	pushfd
	pop eax
	cmp eax, ebx
	jz .no_cpuid
	
       ; Step 2: Test for extended CPUID
       mov eax, 80000000h
	CPUID
	cmp eax, 80000000h
	ja near .e_cpuid
       jmp .cpuid
       
   .no_cpuid:
        	; we start with 386, coz... ehehe
        
        INC     AX
        MOV     EBX,ESP
        AND     ESP,0FFFCH
        PUSHFD
        POP     EDX
        MOV     ECX,EDX
        XOR     EDX,000040000H
        PUSH    EDX
        POPFD
        PUSHFD
        POP     EDX
        PUSH    ECX
        POPFD
        XOR     EDX,ECX
        AND     EDX,000040000H          ;Test Alignment Check Bit
        MOV     ESP,EBX
        JNZ      .no_386                    
        mov	eax, __DEF_CPUID_386__		;80386
        jmp	.found
        
        .no_386:
        ;.486
        INC     AX
        PUSHFD
        POP     EDX
        MOV     ECX,EDX
        XOR     EDX,000200000H
        PUSH    EDX
        POPFD
        PUSHFD
        POP     EDX
        PUSH    ECX
        POPFD
        XOR     EDX,ECX                 ;Test ID Bit
        JNZ      .no_486                    
        mov	eax, __DEF_CPUID_486__		;80486
        jmp	.found
        
        .no_486:
        
       .cpuid:
        ; Step CPUID: Use CPUID to get all the requiered infos ( :)
        MOV     EAX,1
        ;.586 or higher, CPUID returns Cpu Generation Number in AX Bits 8-11
        CPUID
        mov	ecx, eax
        AND     AH,0FH
        SHR     AX,8
		; allright, here we get ALOT of infos ;)
	cmp	ax, 5
	je	.cpu_586
	cmp	ax, 6
	je	.cpu_686
	cmp	ax, 7
	je	.cpu_786
	jmp	.other
	
	
	; ---
	.cpu_586: mov	eax, __DEF_CPUID_586__
			jmp	.get_more
	.cpu_686: mov	eax, __DEF_CPUID_686__
			jmp	.get_more
	.cpu_786: mov	eax, __DEF_CPUID_786__
			jmp	.get_more
	.other:	  mov	eax, __DEF_CPUID_dunn0__
			jmp	.get_more
		
    .get_more:
    	; Step 4a: Get 	type/family/model/stepping/brand
	
		; Type, bit 13-12 of EAX (aka ECX)
	and	ch, 0xCF
	shr	ch, 12
		; CH = CPU type
		
		; Model, bits 7-4 of CL
	mov	bh, cl
	and	cl, 0Fh
	shr	cl, 4
	  		; substep: If CL = F && Vendor = Intel, then check extended valuez
	  		cmp cl, 0Fh
	  		jne .done_model
	  		call cpu.detect_vendor
	  		jc .done_model
	  			; Check extended info (bit 27-20 of ECX)
	  		push	ebx
	  		mov	ebx, ecx
	  		and	ebx, 0xF00FFFFF
	  		shr	ebx, 20
	  		mov	cl, bl
	  		pop	ebx
	  			; ok, done
   .done_model:
   		; Model ID = CL
   		
   		; Stepping ID, bit 3-0 of bh
   	
   	and	bh, 0xF0
   			; BH  = Stepping ID
   			
   		; Brand ID, bl
   			
   			; BL  = Brand ID
			
	jmp	.found
    	
.e_cpuid:	
	; Step xtended CPUID: Use extended CPUID
	mov	eax, 80000001h
	cpuid
	mov	ecx, eax
	; Step 4b: Get 	type/family/model/stepping/brand
  		; Family: bits 11..8
  	AND     AH,0FH
        SHR     AX,8
        cmp	ax, 5
        je	.e_cpu_586
        cmp	ax, 5
        je	.e_cpu_686
        cmp	ax, 5
        je	.e_cpu_786
        jmp	.e_other
        
  	.e_cpu_586: mov	eax, __DEF_CPUID_586__
			jmp	.e_get_more
	.e_cpu_686: mov	eax, __DEF_CPUID_686__
			jmp	.e_get_more
	.e_cpu_786: mov	eax, __DEF_CPUID_786__
			jmp	.e_get_more
	.e_other:	  mov	eax, __DEF_CPUID_dunn0__
			jmp	.e_get_more
			
	.e_get_more:
		
		;; Model ID: Bit 7-4 of eax, aka ecx
	mov	bh, cl
	and	cl, 0Fh
	shr	cl, 4
  		; Model ID = CL
   		
   		; Stepping ID, bit 3-0 of bh
   	
   	and	bh, 0xF0
   			; BH  = Stepping ID
   			
   		; Brand ID, bl
   	xor	bl, bl	
   			; BL  = Brand ID
  .found:
  	
	popfd
	pop	esp
	pop	edx
	
	
	retn
	
globalfunc	cpu.detect_fpu
;>
;; Detect the presence of a floating point unit
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;; 	cf unset if fpu found ;)
;<
;;	status: working

	FNSTENV [FEnv]
        FNINIT
        FNSTSW  [Temp]
        CMP     BYTE  [Temp],0
        JNE     .nofpu
        FNSTCW  [Temp]
        CMP     BYTE [Temp+1],3
        JNE     .nofpu
.found:
	clc
	retn
.nofpu:
	stc
	retn

globalfunc	cpu.detect_vendor, 91
;>
;; Get Vendor ID
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;;  	EAX = Vendor ID
;;	cf	on error
;<
;; 	status: to test
;

	; Step 1: Check if CPU supports CPUID; if not, return UNKNOWN_VENDOR
	call	cpu.get_id_string
	cmp	eax, __DEF_CPUID_586__
	jge	.knows_cpuid
	mov	eax, __DEF_CPUID_VENDOR_NA__
	clc
	retn
	
	; Step 2: Run CPUID and see what happens
  .knows_cpuid:
  	push	ebx
  	push	ecx
  	push	edx
  	
  	mov	eax, 0
  	cpuid
  		; allright, now the id strings are in ebx:edx:ecx
  	
	; Step 3: Loop & compare
		;Intel	'GenuineIntel'
	cmp	ebx, 'Genu'
	jne	.not_intel
	cmp	edx, 'ineI'
	jne	.not_intel
	cmp	ecx, 'ntel'
	jne	.not_intel
	
	.found_intel:
	mov	eax, __DEF_CPUID_VENDOR_INTEL__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_intel:
		;AMD	'AuthenticAMD'; some time ago also 'AMD ISBETTER'
	cmp	ebx, 'Auth'
	jne	.not_amd
	cmp	edx, 'enti'
	jne	.not_amd
	cmp	ecx, 'cAMD'
	jne	.not_amd
	
	.found_amd:
	mov	eax, __DEF_CPUID_VENDOR_AMD__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_amd:
		;Cyrix	'CyrixInstead', very insecure detection :/
	cmp	ebx, 'Cyri'
	jne	.not_cyrix
	cmp	edx, 'xIns'
	jne	.not_cyrix
	cmp	ecx, 'tead'
	jne	.not_cyrix
	
	.found_cyrix:
	mov	eax, __DEF_CPUID_VENDOR_CYRIX__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_cyrix:
		;Rise	'RiseRiseRise'
	cmp	ebx, 'Rise'
	jne	.not_rise
	cmp	edx, 'Rise'
	jne	.not_rise
	cmp	ecx, 'Rise'
	jne	.not_rise
	
	.found_rise:
	mov	eax, __DEF_CPUID_VENDOR_RISE__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_rise:
		;NexGen	'NexGenDriven'	, prolly we'll never see if this works
	cmp	ebx, 'NexG'
	jne	.not_nexgen
	cmp	edx, 'enDr'
	jne	.not_nexgen
	cmp	ecx, 'iven'
	jne	.not_nexgen
	
	.found_nexgen:
	mov	eax, __DEF_CPUID_VENDOR_NEXGEN__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_nexgen:
		;UMC	'UMC UMC UMC '
	cmp	ebx, 'UMC '
	jne	.not_umc
	cmp	edx, 'UMC '
	jne	.not_umc
	cmp	ecx, 'UMC '
	jne	.not_umc
	
	.found_umc:
	mov	eax, __DEF_CPUID_VENDOR_UMC__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_umc:
		;Crusoe	'GenuineTMx86'
	cmp	ebx, 'Genu'
	jne	.not_crusoe
	cmp	edx, 'ineT'
	jne	.not_crusoe
	cmp	ecx, 'Mx86'
	jne	.not_crusoe
	
	.found_crusoe:
	mov	eax, __DEF_CPUID_VENDOR_CRUSOE__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_crusoe:
		;IDT/VIA	'CentaurHauls', but settable by user...
	cmp	ebx, 'Cent'
	jne	.not_idt
	cmp	edx, 'aurH'
	jne	.not_idt
	cmp	ecx, 'auls'
	jne	.not_idt
	
	.found_idt:
	mov	eax, __DEF_CPUID_VENDOR_VIA__
	pop	edx
	pop	ecx
	pop	ebx
	jmp	.done
	
	.not_idt:
	mov	eax, __DEF_CPUID_VENDOR_OTHER__
	pop	edx
	pop	ecx
	pop	ebx
  .done:
	; Step 4: Cleanup
	retn

;globalfunc	cpu.detect_features


globalfunc	cpu.detect_mmx, 900002
;>
;; Detect the presence of MMX extension
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;;	cf	set if MMX *not* supported
;<
;; status: To debug
;
	pushad
	; Step 1: CHeck if CPU 586 or greater
	call	cpu.get_id_string
	cmp	eax, __DEF_CPUID_586__
	jl	.nope
	
	; Step 2: Check if MMX is supported at all
	mov  eax,1           
        cpuid
        test edx,00800000h   ;/  = bit 24
        
        jz   .nope

	; Step 3: Cleanup
	clc
	jmp	.ende
	.nope:
	stc
	.ende:
	popad
	retn

globalfunc	cpu.detect_3dnow, 900003
;>
;; Detect the presence of 3DNow! extension
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;;	cf	set if 3Dnow! *not* supported
;;	eax	setto 01h if extended 3Dnow! supported
;<
;; status: To debug
;
	push ebx
	push ecx
	push edx

	; Step 1: CHeck if CPU 586 or greater
	call	cpu.get_id_string
	cmp	eax, __DEF_CPUID_586__
	jl	.nope
	
	; Step 2: Check if 3Dnow! is supported at all
	mov	eax, 80000000h
	cpuid
	
	%if _DEBUG_ > 2
		mov	edx, eax
		externfunc	sys_log.print_hex
	%endif
	
	cmp	eax, 80000000h
        jbe   .nope
        jl 	.nope
        ja	.ok
        jg	.ok
        stc
        jmp	.nope
        
        .ok:
        
        mov	eax, 80000001h
        cpuid
        	%if _DEBUG_ > 2
		mov	edx, eax
		externfunc	sys_log.print_decimal
		%endif
		
        test	edx, 80000000h	; bit 31 = 3dNow! supported
        jz	.nope
        clc
	test	edx, 40000000h	; bit 30 = extended3dNow! supported
        jz	.ende
	; Step 3: Cleanup
	mov	eax, 01h
	jmp	.ende
	
	.nope:
	stc
	xor eax, eax
	.ende:
	pop edx
	pop ecx
	pop ebx
	retn
	
globalfunc	cpu.detect_isse, 9000004
;>
;; Detect the presence of SSE extension
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;;	cf	set if SSE *not* supported
;<
;; status: To debug
;
	pushad
	; Step 1: CHeck if CPU 586 or greater
	call	cpu.get_id_string
	cmp	eax, __DEF_CPUID_586__
	jl	.nope
	
	; Step 2: Check if SSE is supported at all
	mov  eax,1           
        cpuid
        test edx,02000000h   ;/ cpuid.xmm = bit 25
        jz   .nope

	; Step 3: Cleanup
	clc
	jmp	.ende
	.nope:
	stc
	.ende:
	popad
	retn
	
globalfunc	cpu.detect_isse2, 910000
;>
;; Detect the presence of SSE2 extension
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;;	cf	set if SSE2 *not* supported
;<
;; status: To debug
;
	pushad
	; Step 1: CHeck if CPU 586 or greater
	call	cpu.get_id_string
	cmp	eax, __DEF_CPUID_586__
	jl	.nope
	
	; Step 2: Check if SSE2 is supported at all
	mov  eax,1           
        cpuid
        test edx,04000000h   ;/  = bit 26
        
        jz   .nope

	; Step 3: Cleanup
	clc
	jmp	.ende
	.nope:
	stc
	.ende:
	popad
	retn
	
globalfunc	cpu.detect_sernum, 910001
;>
;; TO BE RENAMED: cpu.get_serial_number
;;
;; Params:
;;--------
;; none
;;
;; Returns:
;;---------
;; cf	set if Serial Number *not* supported
;;	EDX:EAX = 64bit serial number
;<
;; status: To debug, To update, To fix.. to do ;)
;
	pushad
	; Step 1: CHeck if CPU 586 or greater
	call	cpu.get_id_string
	cmp	eax, __DEF_CPUID_586__
	jl	.nope
	
	; Step 2: Check if SN is supported at all
	mov  eax,1           
        cpuid
        test edx,00040000h   ;/  = bit 18
        
        jz   .nope

	; Step 3: Cleanup
	clc
	jmp	.ende
	.nope:
	stc
	.ende:
	popad
	
