;; $Header: /cvsroot/uuu/existence/cells/process/avalon/avalon.asm,v 1.18 2009/05/22 03:27:01 instinc Exp $
;;
;; Avalon Hard Realtime Thread Engine
;; Copyright (C) 2002-2003, Dave Poirier
;; Distributed under the BSD License


%ifdef _RTDB_
  global threads
  global hra.realtime_queue
  global hra.schedule
  global hra.unschedule
  global ps.priority_queue
  global tsa.data_alloc_bitmap
%endif




; Implementation Specifics
;-------------------------
;
; > Thread ID
;
; Thread ID are pointers to stack base.  Thread headers are stored at the top
; of the stack.  One can locate the thread headers by adding the stack size
; to the thread ID then substracting the size of the thread headers.
;
; > Realtime Scheduler
;
; The scheduler is hard realtime. This implies that if two threads try to
; schedule for the same time slot, one of them will fail.  Soft realtime
; is possible by specifying an allowable tolerance.
;
; Using this tolerance, the thread will be scheduled at the specified time
; or _LATER_, up to X microseconds as specified in the tolerance.
;



; note: these comments were taken from the Linux kernel:
;>-->
; * Semaphores are implemented using a two-way counter:
; * The "count" variable is decremented for each process
; * that tries to acquire the semaphore, while the "sleeping"
; * variable is a count of such acquires.
; *
; * Notably, the inline "up()" and "down()" functions can
; * efficiently test if they need to do any extra work (up
; * needs to do something only if count was negative before
; * the increment operation.
; *
; * "sleeping" and the contention routine ordering is
; * protected by the semaphore spinlock.
; *
; * Note that these functions are only called when there is
; * contention on the lock, and as such all this is the
; * "non-critical" part of the whole semaphore business. The
; * critical part is the inline stuff in <asm/semaphore.h>
; * where we want to avoid any extra jumps and calls.
;
; * Logic:
; *  - only on a boundary condition do we need to care. When we go
; *    from a negative count to a non-negative, we wake people up.
; *  - when we go from a non-negative count to a negative do we
; *    (a) synchronize with the "sleeper" count and (b) make sure
; *    that we're on the wakeup list before we synchronize so that
; *    we cannot lose wakeup events.
;<--<
;
; A mutex is implemented as a semaphore with an initial value of 1.
;
;

section .c_info

  db 3,0,0,0
  dd str_title
  dd str_author
  dd str_copyright

  str_title:
  db "Avalon - Hard Realtime Thread Engine",0
  str_author:
  db "eks",0
  str_copyright:
  db "Copyright (C) 2002-2003, Dave Poirier",0x0A
  db "Distributed under the BSD license",0x00

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------

%define EXTRA_CHECKS



;------------------------------------------------------------------------------
; Default stack size in bytes.  Note, the thread headers are stored at the
; stack top, so if ESP == Thread ID the stack is empty.
;
; If ESP == thread ID - (_DEFAULT_STACK_SIZE - _thread_t_size) the stack is
; full.
;
%assign _LOG_STACK_SIZE_	11
%assign _STACK_SIZE_	    (1<<_LOG_STACK_SIZE_)
;------------------------------------------------------------------------------



; Number of 32 threads block to allow
;------------------------------------------------------------------------------
%assign _THREAD_BLOCKS_	 2
;------------------------------------------------------------------------------



; Highest priority allowed and default priority set
;------------------------------------------------------------------------------
%assign _DEFAULT_PRIORITY_	10
%assign _PRIORITY_CEILING_      25
;------------------------------------------------------------------------------


; Default time resolution (in microseconds)
;------------------------------------------------------------------------------
%assign _DEFAULT_RESOLUTION_	100
;------------------------------------------------------------------------------


; initial eflags register state when creating threads
;------------------------------------------------------------------------------
; 
; bit   description
; ---   -----------
;   0   CF, Carry flag
;   1   1
;   2   PF, Parity flag
;   3   0
;   4   AF, Adjust flag
;   5   0
;   6   ZF, Zero flag
;   7   SF, Sign flag
;   8   TF, Trap flag
;   9   IF, Interrupt flag
;  10   DF, Direction flag
;  11   OF, Overflow flag
; 12-13 IOPL, I/O Privilege level
;  14   NT, Nested flag
;  15   0
;  16   RF, Resume flag
;  17   VM, Virtual mode
;  18   AC, Alignment check     
;  19   VIF, Virtual Interrupt flag
;  20   VIP, Virtual Interrupt pending
;  21   ID, Identification flag
; 22-31 0
%define _THREAD_INITIAL_EFLAGS_ 0x00000202
;------------------------------------------------------------------------------


; Initial code segment to use by default
;------------------------------------------------------------------------------
%define _THREAD_INITIAL_CS_     0x0008
;------------------------------------------------------------------------------


; PIT Adjustment value
;------------------------------------------------------------------------------
%assign _PIT_ADJ_DIV_		   1799795308
%assign _PIT_ADJ_DIV_PRECISION_		31
%assign _PIT_ADJ_MULT_		  2562336687
%assign _PIT_ADJ_MULT_PRECISION_	31
;
; How to compute this value... The 8254 PIT has a frequency of 1.193181MHz
; and we want a resolution in microsecond.  Programmation of the pic is
; pretty simple, you give it the number of "tick" to do, and it decrement
; this value at each clock cycle (1.193...).  When the value reach 0, an
; interrupt is fired.
;
; Thus, if we give 1 to the PIT, it will take 0.838095 micro-seconds to
; fire an interrupt.  To have a proper 1 to 1 matching, we need to
; multiply the number of microsecond to wait by 1.193181.
;
; Using fixed point arithmetic 1.31, we take this multiplier and shift
; it by 31 bits, equivalent to multiplying it by 2^31. This gives us
; a value of 2562336687 without losing any precision.
;
; Now if we multiply this 1.31 bits with a 31.1 value, we obtain a 32.32
; fixed point result, which should be easy to extract from EDX:EAX.
;
; The operation will then consist of the following sequence:
; o Load number of microseconds to wait: EAX = microseconds
; o adjust the value for 31.1, insert a 0 on the right: EAX < 1
; o multiply the 31.1 value with the 1.31 value: EAX * 2562336687
; o get result in high part of 32.32: EDX = result
;
; For more information on fixed point arithmetic, please visit:
; http://www.accu.org/acornsig/public/caugers/volume2/issue6/fixedpoint.html
;
%if _PIT_ADJ_DIV_PRECISION_ <> _PIT_ADJ_MULT_PRECISION_
  %error "Precision adjustments unmatching for mult/div in PIT conversion"
%endif
%assign _PIT_ADJ_SHIFT_REQUIRED_	(32 - _PIT_ADJ_MULT_PRECISION_)
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; Macro introducing a small I/O delay, gives some time for the chips to handle
; the request we just sent.
;
%define io_delay	out 0x80, al
;%define io_delay       ;-no-delay-
;------------------------------------------------------------------------------


;----------------------------------------------------------[ DevBench support ]
%macro syscall 1.nolist
  mov eax, %{1}
  int 0x80
%endmacro

%macro log 1.nolist
%ifdef _DEBUG_
[section .data]
%define STDERR	2	; file descriptor
%define SYS_WRITE 4	; syscall #
%%str: db %{1}, 0x0A
%%str_end:
__SECT__
  pushad
  mov ebx, STDERR
  mov ecx, %%str
  mov edx, %%str_end - %%str
  syscall SYS_WRITE
  popad
%endif
%endmacro
;----------------------------------------------------------[/DevBench support ]




;-----------------------------------------------------------------[ CELL INIT ]
%ifdef _RTDB_
  section .text
  global __c_init
  __c_init:
%else
  section .c_init
  global _start
  _start:
%endif

						;- allocate a temporary thread
  xor  edx, edx					; set process id = 0
  call tsa.acquire_thread			; attempt to acquire a thread
  jc near .exit				; catch a failure
  mov  [tsa.data_current_thread], eax		; set it as "active"
  mov  ebx, _STACK_SIZE_ - _thread_t_size	;
  mov  dword [THRD(eax,ebx,timer_handler)], __irq_timer.ps_logic
  mov  dword [THRD(eax,ebx,runlength)], dword 1	;
  mov  ebx, eax					; save ID for thread release
						;
  call tsa.acquire_thread			;- allocate init thread
  jc short .exit				; catch any alloc failure
						;
  mov  esi, esp					; current Top-Of-Stack
  mov  ecx, __INIT_STACK__			; Stack upper limit
  push eax					; thread ID
  push dword .re_entry				; initial EIP
  call tsa.set_initial_values			; set thread values
  call ps.schedule				; schedule it priority based
						;
  cli						; disable interrupts
  mov  eax, 0x20				; IRQ 0 = INT 20
  mov  ebx, __irq_timer				; set pointer to our handler
  externfunc int.set_handler			; hook int directly
						;
  mov eax, _DEFAULT_RESOLUTION_			; set delay between interrupts
  call __set_timer				; program interval timer
						;
  in  al, 0x21					; get current ISR mask
  and al, 0xFE					; set bit 0 (IRQ 0) to 0
  out 0x21, al					; update ISR mask
						;
  sti						; enable interrupt
  jmp short $					; wait for init thread
						;
  .re_entry:
  ; init thread entry point
  ; registers:
  ;  eax = init thread id
  ;  ebx = temporary thread id
  ;  ecx = __INIT_STACK__
  ;  edx = 0
  ;  esi = esp as received for cell initialization
  ;  edi = undefined
  ;  ebp = undefined
  ;  esp = TOS
  ;
  mov  eax, ebx					; set id = temporary thread id
  call tsa.release_thread			; release temporary thread
						;
  .copying_stack:				;- copy init stack content
  sub ecx, byte 4				; proceed to next dword
  push dword [ecx]				; move it to init stack
  cmp ecx, esi					; check if everything was moved
  jnz short .copying_stack			; if not, repeat
						;
  clc						; indicate no error
.exit:						;
  retn						; complete initialisation
;-----------------------------------------------------------------[/CELL INIT ]




__set_timer:
;--------------------------------------------------------------[ set timer ]--
;>
;; Reprogram the PIT and sets the number of full timer expirations for a given
;; microsecond delay.
;;
;; parameters
;; ----------
;; eax = number of microseconds before allowing interruption
;;
;; returns
;; -------
;; eax = destroyed
;; edx = destroyed
;; pit_ticks = number of full expiration to let go
;<
;-----------------------------------------------------------------------------
  shl  eax, _PIT_ADJ_SHIFT_REQUIRED_		; adjust microseconds for multiply
  mov  edx, _PIT_ADJ_MULT_			; magic multiplier
  mul  edx					; magic multiply, get ticks count
  mov  al, 0x36					; select channel 0
  out  0x43, al					; send selection to command port
  xchg eax, edx					; copy the whole part of the result
  and  ah, 0x7F					; keep only the lowest 15bits
  out  0x40, al					; send the low 8bits of tick count
  mov  al, ah					; get high 7bits of tick count
  out  0x40, al					; send it
  retn						; return to caller
;-----------------------------------------------------------------------------
;     8253 Mode Control Register, data format: 
;
;        |7|6|5|4|3|2|1|0|  Mode Control Register
;         | | | | | | | ----- 0=16 binary counter, 1=4 decade BCD counter
;         | | | | ---------- counter mode bits
;         | | ------------- read/write/latch format bits
;         ---------------- counter select bits (also 8254 read back command)
;
;        Bits
;         76 Counter Select Bits
;         00  select counter 0
;         01  select counter 1
;         10  select counter 2
;         11  read back command (8254 only, illegal on 8253, see below)
;
;        Bits
;         54  Read/Write/Latch Format Bits
;         00  latch present counter value
;         01  read/write of MSB only
;         10  read/write of LSB only
;         11  read/write LSB, followed by write of MSB
;
;        Bits
;        321  Counter Mode Bits
;        000  mode 0, interrupt on terminal count;  countdown, interrupt,
;             then wait for a new mode or count; loading a new count in the
;             middle of a count stops the countdown
;        001  mode 1, programmable one-shot; countdown with optional
;             restart; reloading the counter will not affect the countdown
;             until after the following trigger
;        010  mode 2, rate generator; generate one pulse after 'count' CLK
;             cycles; output remains high until after the new countdown has
;             begun; reloading the count mid-period does not take affect
;             until after the period
;        011  mode 3, square wave rate generator; generate one pulse after
;             'count' CLK cycles; output remains high until 1/2 of the next
;             countdown; it does this by decrementing by 2 until zero, at
;             which time it lowers the output signal, reloads the counter
;             and counts down again until interrupting at 0; reloading the
;             count mid-period does not take affect until after the period
;        100  mode 4, software triggered strobe; countdown with output high
;             until counter zero;  at zero output goes low for one CLK
;             period;  countdown is triggered by loading counter;  reloading
;             counter takes effect on next CLK pulse
;        101  mode 5, hardware triggered strobe; countdown after triggering
;             with output high until counter zero; at zero output goes low
;             for one CLK period
; 
;-----------------------------------------------------------------------------



section .text









;------------------------------------------------------[ public: hra.schedule ]
hra.schedule:
;>
;; Used to schedule a thread at a specified time.
;;
;; parameters:
;;------------
;;  eax: thread to act upon
;;  esi:ecx: earliest start time
;;  edx: expected run time
;;  ebx: allowable tolerance
;;
;; returned values:
;;-----------------
;;  eax: scheduled time of execution
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  pushad					; backup all registers
  mov ebp, _STACK_SIZE_ - _thread_t_size	; compute offset to _thread_t
  ENTER_CRITICAL_SECTION			; disable preemption
						;
						;*** Verify It Isn't Linked yet
  cmp  dword [THRD(ebp,eax,next)], byte 0	; already scheduled?
  jnz  short .unable_to_schedule		; if so, return failure
						;
						;*** Initialize Thread Info
  push eax					; save thread ID
  mov  eax, [hra.data_resolution]		; load system time resolution
  mul  edx					; compute runlength in us
  pop  edx					; restore thread ID
  mov  [THRD(ebp,edx,runlength)], eax		; set maximum runlength (in us)
  mov  [THRD(ebp,edx,timer_handler)], dword __irq_timer.rt_logic; as Realtime
						;
						;*** Startline must be future
  sub  ecx, [hra.data_system_time]		; check startline low
  sbb  esi, [hra.data_system_time+4]		; check startline high
  jns  short .restore_original_startline	; > current time? validated
  add  ecx, ebx					; try to dig in tolerance
  mov  ebx, ecx					; set tolerance = left over
  adc  esi, byte 0				; check if it was enough
  mov  ecx, esi					; attempt set ecx = 0
  js   short .unable_to_schedule		; < current time? fail it
  inc  ecx					; set ecx = 1
  add  ecx, [hra.data_system_time]		; current time + 1 (low)
  adc  esi, [hra.data_system_time+4]		; current time + 1 (high)
  jmp  short .startline_validated		; validated
						;
.unable_to_schedule_clear_stack:		;
  add  esp, byte 12				; << eax, esi, ecx
.unable_to_schedule:				;*** Failed Scheduling
  LEAVE_CRITICAL_SECTION			; restore preemption state
  popad						; restore all registers
  set_err eax, FAILED_SCHEDULING		; set error code
  stc						; set error indicator
  retn						; return to caller
						;
.restore_original_startline:			;*** Startline Validated
  mov  ecx, [esp + 4 + 24]			; reload startline (low)
  mov  esi, [esp + 4 + 4]			; reload startline (high)
.startline_validated:				;
						;*** Prepare to Iterate
  mov  edi, [hra.realtime_queue]		; load current queue head
  push ecx					; save startline (low)
  push esi					; save startline (high)
  push eax					; save runlength on TOS
  mov  eax, edx					; set queue head = new thread
  test edi, edi					; check for empty queue
  mov  [THRD(ebp,eax,next)], eax		; pre-link new.next
  mov  [THRD(ebp,eax,previous)], eax		; pre-link new.previous
  jz   short .exit				; if empty, we are done
						;
.evaluate_insertion:				;*** 64bit compare startlines
  sub  ecx, [THRD(ebp,edi,startline)]		; new's < edi's ? (low)
  sbb  esi, [THRD(ebp,edi,startline+4)]		; new's < edi's ? (high)
  jns  short .past_this_node			; if not, goes after edi
						;
						;*** verify runlength can fit
  add  ecx, [esp]				; add runlength
  adc  esi, byte 0				; carry over
  jns  short .past_this_node_recover		; not < edi's? hop after it
						;
.insert_node:					;*** Inserting before EDI
  mov  esi, [THRD(ebp,edi,previous)]		; load 'prev' node
  mov  [THRD(ebp,eax,next)], edi		; set edi as new.next
  mov  [THRD(ebp,eax,previous)], esi		; set 'prev' as new.previous
  mov  [THRD(ebp,esi,next)], eax		; update prev.next to new
  mov  [THRD(ebp,edi,previous)], eax		; update edi.prev to new
						;
.exit:						;*** Complete Scheduling
  mov  [hra.realtime_queue], edx		; update queue head
  pop  edx					; clear runlength from TOS
  pop  dword [THRD(ebp,eax,startline+4)]	; set final startline (high)
  pop  dword [THRD(ebp,eax,startline)]		; set final startline (low)
  LEAVE_CRITICAL_SECTION			; restore preemption state
  popad						; restore all registers
  clc						; indicate proper completion
  retn						; return without error
						;
.past_this_node_recover:			;*** Overlaps, Attempt Next
  sub  ecx, [esp]				; remove runlength
  sbb  esi, byte 0				; propagate borrow
.past_this_node:				;*** Check Queue Head
  cmp  edx, eax					; queue head == new node?
  jnz  short .queue_head_set			; if not, leave root node alone
  mov  edx, edi					; restore orig queue head
.queue_head_set:				;*** Attempt to go to next node
  sub  ecx, [THRD(ebp,edi,runlength)]		; runlength of scheduled thrd
  sbb  esi, byte 0				; propagate borrow
  jns  .to_next_node				; > 0? keep startline/tolerance
  add  ecx, ebx					; dig in tolerance
  adc  esi, byte 0				; carry over
  mov  ebx, ecx					; tolerance = left over
  js   near .unable_to_schedule_clear_stack	; tolerance !sufficient? fail
  mov  ecx, [THRD(ebp,edi,startline)]		; load edi's startline (low)
  mov  esi, [THRD(ebp,edi,startline+4)]		; load edi's startline (high)
  add  ecx, [THRD(ebp,edi,runlength)]		; add edi's runlength
  adc  esi, byte 0				; carry over
  mov  [esp + 4], esi				; update saved startline (high)
  mov  [esp + 8], ecx				; update saved startline (low)
  jmp  short .to_next_node_startline_set	;
.to_next_node:					;*** Restore startline
  mov  esi, [esp + 4]				; load startline (high)
  mov  ecx, [esp + 8]				; load startline (low)
.to_next_node_startline_set:			;*** Move to next node
  mov  edi, [THRD(ebp,edi,next)]		; load next node pointer
  cmp  edi, [hra.realtime_queue]		; end of queue?
  jnz  near .evaluate_insertion			;
  jmp  short .insert_node			;
;------------------------------------------------------------[ /hra.schedule ]





;----------------------------------------[ public: hra.set_schedule_callback ]
hra.set_schedule_callback:
;>
;; Indicate to the HRA the function to call after the thread is done execution
;;
;; parameters:
;;------------
;;  eax: thread to act upon
;;  ecx: callback function
;;
;; returned values:
;;-----------------
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "hra.set_schedule_callback called"
  mov [eax + (_STACK_SIZE_-_thread_t_size) + _thread_t.schedule_callback], ecx
  retn
;-----------------------------------------------[ /hra.set_schedule_callback ]






;---------------------------------------------------[ public: hra.unschedule ]
hra.unschedule:
;>
;; Unschedule a thread, this thread will not be given control at its set time.
;;
;; parameters:
;;------------
;;  eax: thread to act upon
;;
;; returned values:
;;-----------------
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "hra.unschedule called"
  pushad
  mov ebp, _STACK_SIZE_ - _thread_t_size
  ENTER_CRITICAL_SECTION
  mov ebx, [THRD(ebp,eax,next)]
  test ebx, ebx
  jz short .skip_root_modify
  mov edx, [THRD(ebp,eax,previous)]
  mov [THRD(ebp,edx,next)], ebx
  mov [THRD(ebp,ebx,previous)], edx
  cmp ebx, eax
  jnz short .skip_root_modify

  cmp [hra.realtime_queue], eax
  jnz short .skip_root_modify

  mov [hra.realtime_queue], dword 0

.skip_root_modify:
  cmp [tsa.data_current_thread], eax
  jz short .yield_control
  LEAVE_CRITICAL_SECTION
.exit:
  popad
  retn

.yield_control:
  push cs
  push dword .exit
  pushad
  mov  [THRD(ebp,eax,stack_top)], esp
  mov  ecx, HRA_CC_UNSCHEDULED
  call [THRD(ebp,eax,schedule_callback)]
  mov  ebx, ebp
  mov  edi, [hra.data_resolution]
  jmp  near __irq_timer.rt_yield
;----------------------------------------------------------[ /hra.unschedule ]




;------------------------------------------------------[ public: ps.schedule ]
ps.schedule:
;>
;; Add a thread to the priority scheduled queue.
;;
;; parameters:
;;------------
;;  eax: thread to act upon
;;
;; returned values:
;;-----------------
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "ps.schedule called"
  pushad
  mov  ebx, _STACK_SIZE_ - _thread_t_size
  mov  [THRD(eax,ebx,timer_handler)], dword __irq_timer.ps_logic
  mov  [THRD(eax,ebx,schedule_callback)], dword 0
  clc
  ENTER_CRITICAL_SECTION
  mov  edx, [ps.priority_queue]
  test edx, edx
  jz   short .init_queue
  mov  esi, [THRD(edx,ebx,previous)]
  mov  [THRD(edx,ebx,previous)], eax
  mov  [THRD(eax,ebx,next)], edx
  mov  [THRD(eax,ebx,previous)], esi
  mov  [THRD(esi,ebx,next)], eax
  mov  [ps.priority_queue], eax
  LEAVE_CRITICAL_SECTION
  popad
  retn

.init_queue:
  mov  [THRD(eax,ebx,next)], eax
  mov  [THRD(eax,ebx,previous)], eax
  mov  [ps.priority_queue], eax
  LEAVE_CRITICAL_SECTION
  popad
  retn
;-------------------------------------------------------------[ /ps.schedule ]





;--------------------------------------------------[ public: ps.set_priority ]
ps.set_priority:
;>
;; Modify the priority associated with a thread
;;
;; parameters:
;;------------
;;  eax: thread to act upon
;;  ecx: new priority level
;;
;; returned values:
;;-----------------
;;  eax: priority assigned
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "ps.set_priority called"
  push ebx
  push edx
  push ecx
  cmp  ecx, dword _PRIORITY_CEILING_
ps.data_priority_ceiling EQU $-4
  lea  ebx, [eax + (_STACK_SIZE_-_thread_t_size)]
  jbe  short .priority_set
  mov  ecx, _PRIORITY_CEILING_
.priority_set:
  mov  eax, dword [hra.data_resolution]
  mul  ecx
  mov  [ebx + _thread_t.priority], eax
  pop  ecx
  pop  edx
  pop  ebx
  clc
  retn
;---------------------------------------------------------[ /ps.set_priority ]



;----------------------------------------------------[ public: ps.unschedule ]
ps.unschedule:
;>
;; Remove a thread from the priority scheduled queue.
;;
;; parameters:
;;------------
;;  eax: thread to act upon
;;
;; returned values:
;;-----------------
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "ps.unschedule called"			;
  pushad					; backup original registers
  xor  esi, esi					; create a NULL register
  ENTER_CRITICAL_SECTION			; disable preemption
  mov  ebx, _STACK_SIZE_ - _thread_t_size	; compute _thread_t offset
						;
						;*** check thread status
  cmp  dword [eax + ebx + _thread_t.next], esi  ; is thread scheduled?
  jz   short .exit				; if not, bypass unscheduling
						;
						;*** unschedule thread
  mov  ecx, [THRD(eax,ebx,next)]		; load 'next' pointer
  mov  edx, [THRD(eax,ebx,previous)]		; load 'previous' pointer
  mov  [THRD(edx,ebx,next)], ecx		; link 'previous' to 'next'
  mov  [THRD(ecx,ebx,previous)], edx		; link 'next' to 'previous'
  mov  [THRD(eax,ebx,next)],  esi		; set to 'next' to NULL
  mov  [THRD(eax,ebx,previous)], esi		; set to 'previous' to NULL
  cmp  ecx, eax					; thread was last of queue?
  jnz  short .check_queue			; -> no: keep 'next' pointer
  mov  ecx, esi					; set 'next' as NULL pointer
.check_queue:					;
  cmp  [ps.priority_queue], eax			; unscheduled was queue head?
  jnz  short .exit				; no, leave queue head alone
  mov  [ps.priority_queue], ecx			; update queue head
.exit:						;
  cmp  [tsa.data_current_thread], eax		; unscheduling running thread?
  jz   short .yield				; -> yes: yield control
  LEAVE_CRITICAL_SECTION			; restore preemption state
  popad						; restore original registers
  retn						; return to caller
						;
.yield:						;*** yield control
						; ENTER_CRITICAL_SECTION pushed EFLAGS
  push cs					; >> cs, eflags
  mov  [THRD(eax,ebx,runlength)], dword 1	;
  call __soft_irq_timer				; >> eip, cs, eflags
  popad						; restore original registers
  retn						; return to caller
;-----------------------------------------------------------[ /ps.unschedule ]







;-----------------------------------------------[ public: tsa.acquire_thread ]
tsa.acquire_thread:
;>
;; Acquire a free thread entry, this thread can be scheduled as either 
;; realtime or priority based.
;;
;; parameters:
;;------------
;;  edx: resource pool
;;
;; returned values:
;;-----------------
;;  eax: thread ID
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "tsa.acquire_thread called"
  push  esi					; >> esi
  push  ecx					; >> ecx, esi
%if _THREAD_BLOCKS_ > 255
  %error "_THREAD_BLOCKS_ valid range is 0-255"
%endif
  mov   eax, _THREAD_BLOCKS_			; set number of thread blocks
  mov   esi, tsa.data_alloc_bitmap		; ptr to thread alloc bitmap
.scan_block:					;
  ENTER_CRITICAL_SECTION			; disable preemption
  bsf   ecx, dword [esi]			; scan for a free thread (1)
  jz    short .try_next_block			; if none found (all 0)
						;
  mov   al, 1					; set eax = 1
  shl   eax, cl					; select thread identity bit
  xor   [esi], eax				; invert it (set to 0)
  LEAVE_CRITICAL_SECTION			; restore preemption state
  sub   esi, tsa.data_alloc_bitmap		; get block id*4
  lea   eax, [esi*8 + ecx]			; compute thread number
  shl   eax, _LOG_STACK_SIZE_			; find its offset
  pop   ecx					; << ecx, esi
  add   eax, threads				; compute thread ID
  pop   esi					; << esi
  ;; TODO: add thread to resource pool
  clc						; indicate success
  retn						; -done- EAX: Thread ID
						;
.try_next_block:				;
  LEAVE_CRITICAL_SECTION			; restore preemption state
  add   esi, byte 4				; point to next block bitmap
  dec   eax					; check for another block
  jnz   short .scan_block			; yes, valid block, proceed
  stc						; indicate error
  set_err eax, OUT_OF_THREADS			; set error code
  pop   ecx					; << ecx, esi
  pop   esi					; << esi
  retn						; -done- ERR: OUT OF THREADS
;------------------------------------------------------[ /tsa.acquire_thread ]




__kill_self:
;-----------------------------------------------------------------------------
  mov eax, [tsa.data_current_thread]
;  jmp tsa.release_thread
;-----------------------------------------------------------------------------
;-----------------------------------------------[ public: tsa.release_thread ]
tsa.release_thread:
;>
;; Unschedule and release a thread.  Calling this function for the thread
;; currently executing will cause it to be killed and control will NOT be
;; returned.
;;
;; parameters:
;;------------
;;  eax: thread to act upon
;;
;; returned values:
;;-----------------
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "tsa.release_thread called"
  push esi					; >> esi
  push ecx					; >> ecx, esi
  push eax					; >> eax, ecx, esi
  sub eax, threads				;
  mov esi, 1					;
  mov ecx, eax					;
  shr eax, 8					; get alloc bitmap
  shr ecx, _LOG_STACK_SIZE_			; get thread id
  add eax, tsa.data_alloc_bitmap		;
  and ecx, byte 0x1F				; range 0-31
  shl esi, cl					; select associated thread bit
  pop ecx					; << eax, ecx, esi
						; ecx = thread acted upon
  ENTER_CRITICAL_SECTION			; prevent pre-emption
  or [eax], esi					; set thread bit to 1
						;
  mov eax, ecx					; eax = thread acted upon
  mov edx, hra.unschedule			; preference for realtime
  cmp dword [ecx + (_STACK_SIZE_-_thread_t_size) + _thread_t.schedule_callback], byte 0; PS or HRA?
  jnz short .hra				; callback != 0 => HRA
						;
  mov edx, ps.unschedule			; priority based it is
						;
.hra:						;
  call edx					; unschedule
  LEAVE_CRITICAL_SECTION			; release cpu lock
  pop ecx					; << ecx, esi
  pop esi					; << esi
  retn						;
;------------------------------------------------------[ /tsa.release_thread ]





;------------------------------------------[ public: tsa.set_initial_values ]
tsa.set_initial_values:
;>
;; Set the initial registers values and initial EIP address of the given
;; thread.  Note the thread must _NOT_ be scheduled when calling this
;; function.
;;
;; parameters:
;;------------
;;  eax, ecx, edx, ebx, esi, edi, ebp: values to set
;;  stack +0: EIP to use.
;;  stack +4: thread to act upon
;;
;; returned values:
;;-----------------
;;  errors and registers as usual
;<
;-----------------------------------------------------------------------------
  log "tsa.set_starting_value called"
  pushad		;
  pushad		; >> edi, esi, ebp, esp, ebx, edx, ecx, eax
  mov	eax, [esp + 64 +  8]			; retrieve thread to act upon
  xor   esi, esi				; set NULL pointer
  mov	ebx, _STACK_SIZE_ - _thread_t_size	; disp to _thread_t structure
  mov   ecx, [esp + 64 +  4]			; retrieve initial EIP
  mov   edx, [hra.data_resolution]		; load time resolution
  mov   [THRD(eax,ebx,next)], esi		; loop back queue next ptr
  mov	[THRD(eax,ebx,previous)], esi		; loop back queue previous ptr
  mov   [THRD(eax,ebx,priority)], edx		; priority level 1
  lea	edx, [byte eax + ebx - 48]		; compute top of stack address
  mov	[THRD(eax,ebx,stack_top)], edx		; set top of stack
  pop	dword [edx]				; initial edi
  pop	dword [byte edx + 4]			; initial esi
  pop	dword [byte edx + 8]			; initial ebp
  pop   esi					; clear out initial esp
  pop	dword [byte edx + 16]			; initial ebx
  pop	dword [byte edx + 20]			; initial edx
  pop	dword [byte edx + 24]			; initial ecx
  pop	dword [byte edx + 28]			; initial eax
  mov	[byte edx + 32], ecx			; set initial EIP
  mov	[byte edx + 36], cs			; set initial CS
  mov	[byte edx + 40], dword _THREAD_INITIAL_EFLAGS_
  mov   [byte edx + 44], dword __kill_self	;
  popad						;
  retn						;
;-------------------------------------------------[ /tsa.set_starting_values ]




;--------------------------------------------------------[ public: tsa.yield ]
tsa.yield:
;>
;; Yield the control to the next scheduled thread.
;;
;; parameters:
;;------------
;;  none
;;
;; returned values:
;;-----------------
;;  eax destroyed, no return values.
;<
;-----------------------------------------------------------------------------
  log "tsa.yield called"
  mov  eax, [tsa.data_current_thread]
  mov  [eax + (_STACK_SIZE_-_thread_t_size) + _thread_t.runlength], dword 1
  pushfd
  push cs
  call __soft_irq_timer
  retn
;---------------------------------------------------------------[ /tsa.yield ]




sem.acquire_lock:
;---------------------------------------------------------[ sem.acquire_lock ]
;>
;; Fallback function for the SEM_ACQUIRE_LOCK() macro.
;;
;; WARNING: DO NOT CALL THIS FUNCTION DIRECTLY, USE THE MACROS PROVIDED IN
;;          'include/thread.inc'.
;;
;; parameters:
;;------------
;; eax = pointer to semaphore to act upon
;;
;; returns:
;;---------
;; errors and registers as usual
;<
;-----------------------------------------------------------------------------
  ENTER_CRITICAL_SECTION			; disable preemption
  cmp  dword [eax + semaphore_t.count], byte 0	; 
  jge   short .acquired				;
						;
.failed:					;
  pushad					; save registers value
  mov  ebx, [tsa.data_current_thread]		; load current thread ID
  mov  ebp, _STACK_SIZE_ - _thread_t_size	; compute offset to _thread_t
  mov  esi, [THRD(ebx,ebp,next)]		;
  mov  edi, [THRD(ebx,ebp,previous)]		;
						;
  test esi, esi					; Locking in realtime?
  jz   short .realtime				; if so, don't allow it
  mov  [THRD(edi,ebp,next)], esi		; link 'next' to 'previous'
  mov  [THRD(esi,ebp,previous)], edi		; link 'previous' to 'next'
						;
  mov  ecx, [eax + semaphore_t.wait_queue]	; load queue head
  test ecx, ecx					; queue initialized?
  jz   short .init_wait_queue			; if not, initialize it
						;
  mov  edx, [THRD(ecx,ebp,previous)]		;*** Add To Queue
  mov  [THRD(ebx,ebp,next)], ecx		; set 'head' as next
  mov  [THRD(ebx,ebp,previous)], edx		; set 'tail' as previous
  mov  [THRD(edx,ebp,next)], ebx		; set next of 'tail'
  mov  [THRD(ecx,ebp,previous)], ebx		; set previous of 'head'
						;
.sleep:						;*** Unschedule Thread
  xor  eax, eax					; set NULL pointer
  cmp  esi, ebx					; 'next' == current thread?
  jnz  short .set_priority_queue		; if not, don't worry
  mov  esi, eax					; set queue head to NULL
.set_priority_queue:				;
  mov  [ps.priority_queue], esi			; update priority queue
						;
						;*** Go To Sleep
  pushfd					; flags for iretd
  push cs					; code segment for iretd
  mov  [THRD(ebx,ebp,runlength)], eax		; set runlength to 0
  call __soft_irq_timer				; yield control and wait
  popad						; restore registers value
						;
.acquired:					;*** Lock Acquired
  LEAVE_CRITICAL_SECTION			; restore preemption state
  clc						; indicate completion
  retn						;
						;
.realtime:					;*** Realtime lock failed
  inc  dword [eax + semaphore_t.count]		; undo SEM_DOWN()
  popad						; restore registers
  LEAVE_CRITICAL_SECTION			; restore preemption state
  set_err eax, LOCK_FAILED			; set error code
  stc						; set error flag
  retn						; return to realtime thread
						;
.init_wait_queue:				;*** Initialize Wait Queue
  mov [THRD(ebx,ebp,next)], ebx			; loop back 'next'
  mov [THRD(ebx,ebp,previous)], ebx		; loop back 'previous'
  mov [eax + semaphore_t.wait_queue], ebx	; set queue head
  jmp short .sleep				; wait until a lock release
;----------------------------------------------------------------[ /sem.lock ]






sem.release_lock:
;---------------------------------------------------------[ sem.release_lock ]
;>
;; Fallback for the SEM_RELEASE_LOCK() macro.
;;
;; WARNING: DO NOT CALL THIS FUNCTION DIRECTLY, USE THE MACROS DEFINED IN
;;          'include/thread.inc'.
;;
;; parameters:
;;------------
;; eax = pointer to semaphore to act upon
;;
;; returns:
;;---------
;; errors and registers as usual
;<
;-----------------------------------------------------------------------------
  ENTER_CRITICAL_SECTION
  pushad
  mov  ebx, eax
  mov  eax, [ebx + semaphore_t.wait_queue]
  test eax, eax
  jz short .exit
  
  mov  ebp, _STACK_SIZE_ - _thread_t_size
  xor  edx, edx
  mov  esi, [THRD(eax,ebp,next)]
  mov  edi, [THRD(eax,ebp,previous)]
  mov  [THRD(edi,ebp,next)], esi
  mov  [THRD(esi,ebp,previous)], edi
  mov  [THRD(eax,ebp,next)], edx
  mov  [THRD(eax,ebp,previous)], edx
  cmp  esi, eax
  jnz  short .update_queue_head
  mov  esi, edx
.update_queue_head:
  mov  [ebx + semaphore_t.wait_queue], esi
  call ps.schedule

.exit:
  popad
  LEAVE_CRITICAL_SECTION
  retn
;---------------------------------------------------------[ /sem.release_lock ]



sem.try_acquire_lock:
;------------------------------------------------------[ sem.try_acquire_lock ]
;>
;; Fallback for the SEM_TRY_ACQUIRE_LOCK() macro.
;;
;; WARNING: DO NOT CALL THIS FUNCTION DIRECTLY, USE THE MACROS DEFINED IN
;;          'include/thread.inc'
;;
;; parameters:
;;------------
;; eax = pointer to semaphore to act upon
;;
;; returns:
;;---------
;; errors and registers as usual
;<
;------------------------------------------------------------------------------
  ENTER_CRITICAL_SECTION
  inc dword [eax + semaphore_t.count]
  jg short .acquired
  LEAVE_CRITICAL_SECTION
  stc
  retn
.acquired:
  dec dword [eax + semaphore_t.count]
  LEAVE_CRITICAL_SECTION
  clc
  retn
;-----------------------------------------------------[ /sem.try_acquire_lock ]




;__latch_timer:
;;------------------------------------------------------------[ latch timer ]--
;;>
;;; Returns the number of microseconds before the currently set timer expires
;;;
;;; parameters
;;; ----------
;;; none
;;;
;;; returns
;;; -------
;;; edx:eax - number of microseconds until interruption
;;<
;;-----------------------------------------------------------------------------
;   xor  eax, eax				; set eax to 0
;   out  0x43, al				; send 'latch' command for channel 0
;   io_delay					; give it some time
;   io_delay					;
;   in   al, 0x40				; latch 'LSB'
;   mov  ah, al					; back it up in ah
;   io_delay					; give it some time to update itself
;   in   al, 0x40				; latch 'MSB'
;   mov  edx, _PIT_ADJ_DIV_			; magic value as detailed above
;   xchg ah, al					; swap 'MSB' and 'LSB' in their place
;   shl  eax, _PIT_ADJ_SHIFT_REQUIRED_		; adjust value for some magic
;   mul  edx					; compute microseconds equivalent
;   retn					; return to caller
;;-----------------------------------------------------------------------------



;-----------------------------------------------------------------------------
__soft_irq_timer:				;
  pushad					; backup all register values
  cli						; disable preemption
  mov edi, [hra.data_resolution]		;
  jmp short __irq_timer.soft_irq		; bypass time and irq code
;-----------------------------------------------------------------------------
__irq_timer:
;-----------------------------------------------------------------------------
  pushad					; backup all register values
  mov edi, _DEFAULT_RESOLUTION_			; (SMC): timer resolution
hra.data_resolution EQU $-4			;-(SMC): embedded variable
						;*** Update System Time
  add  dword [hra.data_system_time], edi	; add timer resolution
  adc  dword [hra.data_system_time+4], byte 0	; carry over
						;
						;*** Acknowledge IRQ
  mov  al, 0x60					; Specific EOI IRQ 0
  out  0x20, al					; send it to master PIC
						;
.soft_irq:					;*** Check Current Thread State
  mov  eax, 0					; (SMC) load current thread
tsa.data_current_thread EQU $-4			;-(SMC): embedded variable
  mov  ebx, _STACK_SIZE_ - _thread_t_size	; compute _thread_t offset
  mov  [THRD(eax,ebx,stack_top)], esp		; save stack top (ESP)
						;
  sub  [THRD(eax,ebx,runlength)], edi		; countdown runlength
  jmp  [eax + ebx + _thread_t.timer_handler]	; jump to specific handler
						;
.ps_logic:					;*** Priority Based Logic
  pushfd					; save expire check result
						;
						; check for RT schedule
  mov  eax, [hra.realtime_queue]		; load RT queue head
  test eax, eax					; check if queue is empty
  jz   short .no_rt				; if empty, priority based
						;
  mov  ecx, [hra.data_system_time]		; current system time (low)
  mov  edx, [hra.data_system_time+4]		; current system time (high)
  sub  ecx, [THRD(eax,ebx,startline)]		; check thread start line (low)
  sbb  edx, [THRD(eax,ebx,startline+4)]		; check thread start line (high)
  jns  short .ps_fallin				; current >= start: RT ready
						;
.no_rt:						; no RT to schedule
  popfd						; retrieve expire check result
  ja  short .exit				; if not expired: let it be
						;
.rt_fallback:					;*** Priority Thread selected
  mov  eax, 0					; (SMC) load priority queue head
ps.priority_queue EQU $-4			;-(SMC): embedded variable
  test eax, eax					; queue is empty?
  jz  short .set_idle				; if empty, idle for one cycle
						;
  mov  ecx, [THRD(eax,ebx,priority)]		; load thread priority
  mov  edx, [THRD(eax,ebx,next)]		; load 'next' priority thread
  mov  [THRD(eax,ebx,runlength)], ecx		; set runlength = priority
  mov  [ps.priority_queue], edx			; update priority queue head
  jmp  short .load_thread			; activate the new thread
						;
.rt_logic:					;*** Check RT thread expiration
  ja short .exit				; if not expired, let it be
						;
						;*** thread expired, notify CB
  mov  ecx, HRA_CC_EXPIRED			; set Completion Code
  call [THRD(eax,ebx,schedule_callback)]	; call schedule callback
						;
.rt_yield:					;
						;*** Check for ready RT thread
  mov  eax, 0					; (SMC) load queue head
hra.realtime_queue EQU $-4			;-(SMC): embedded variable
  test eax, eax					; check for empty queue
  jz   short .rt_fallback			; empty? priority scheduling
  						;
  mov  ecx, [hra.data_system_time]		; current system time (low)
  mov  edx, [hra.data_system_time+4]		; current system time (high)
  sub  ecx, [THRD(eax,ebx,startline)]		; check thread start line (low)
  sbb  edx, [THRD(eax,ebx,startline+4)]		; check thread start line (high)
  jb   short .rt_fallback			; current < start: not ready
						;
.ps_fallin:					;*** Realtime Thread selected
  mov  ecx, [THRD(eax,ebx,next)]		; load 'next' pointer
  mov  edx, [THRD(eax,ebx,previous)]		; load 'previous' pointer
  xor  esi, esi					; create NULL pointer
  mov  [THRD(edx,ebx,next)], ecx		; link 'previous' to 'next'
  mov  [THRD(ecx,ebx,previous)], edx		; link 'next' to 'previous'
  mov  [THRD(eax,ebx,next)], esi		; unlink 'next' pointer
  mov  [THRD(eax,ebx,previous)], esi		; unlink 'previous' pointer
  mov  [hra.realtime_queue], ecx		; update RT queue head
  sub  ecx, eax					; was last in queue?
  jnz  short .load_thread			; if not, just load new thread
  mov  [hra.realtime_queue], ecx		; set queue to NULL
						;
.load_thread:					;*** Load Selected Thread
  mov  esp, [THRD(eax,ebx,stack_top)]		; load stack top pointer (ESP)
  mov  [tsa.data_current_thread], eax		; set as current thread
						;
.exit:						;*** (Re)Activate Thread
  popad						; restore all registers
  iretd						; transfer full control
						;
.set_idle:					;*** Idle Thread selected
  mov eax, idle_thread				; get idle thread pointer
  lea ecx, [eax + ebx]				; compute _thread_t base
  mov [tsa.data_current_thread], eax		; set current thread as 'idle'
  mov [ecx + _thread_t.runlength], dword edi	; 1 cycle run then re-schedule
  mov [ecx + _thread_t.timer_handler], dword .ps_logic
  mov esp, ecx					; select idle thread stack
						;
						; TODO: some idle time counter
.idling:					;
  sti						; enable interrupts
  hlt						; wait until some interrupts
  jmp short .idling				; continue idling
;-----------------------------------------------------------------------------





  
  
;------------------------------------------------------------------[ DATA ]---


; RT-Engine Private Data
;-----------------------
section .bss
threads: times 32 * _THREAD_BLOCKS_ resb _STACK_SIZE_
idle_thread: resb _STACK_SIZE_

; HRA Public Data
;----------------
section .bss
res64   hra.data_system_time

; HRA Public Data
;----------------
; res32 hra.realtime_queue, now embedded in code, see __irq_timer function


; PS Public Data
;---------------
;section .bss
;res32 ps.data_priority_ceiling, now embedded in code, see ps.set_priority

; PS Private DAta
;----------------
; res32 ps.priority_queue, now embedded in code, see __irq_timer function
section .data
tsa.data_alloc_bitmap:	  times   _THREAD_BLOCKS_ dd 0xFFFFFFFF


; TSA Public Data
;----------------
section .bss
res32   tsa.data_acquired_threads
;res32 tsa.data_current_thread, now embedded in code, see __irq_timer function
res32   tsa.data_stack_size
section .data
tsa.data_total_threads:	 dd      _THREAD_BLOCKS_ * 32
;-----------------------------------------------------------------[ /DATA ]---





;--------------------------------------------------------[ Symbol Exportation ]
;
; Components of the 'System' are:
;--------------------------------
; o Hard Realtime Allocator (HRA)
; o Priority Scheduler (PS)
; o Task Switcher Agent (TSA)
;
;
; Public Function / Data Summary
;-------------------------------
;
; HRA Functions:
; --------------
vglobal hra.schedule
vglobal hra.set_schedule_callback
vglobal hra.unschedule
;
; HRA Public Data:
; ----------------
vglobal hra.data_resolution
vglobal hra.data_system_time
;
; PS Functions:
; -------------
vglobal ps.schedule
vglobal ps.set_priority
vglobal ps.unschedule
;
; PS Public Data:
; ---------------
vglobal ps.data_priority_ceiling
;
; TSA Functions:
; --------------
vglobal tsa.acquire_thread
vglobal tsa.release_thread
vglobal tsa.set_initial_values
vglobal tsa.yield
;
; TSA Public Data:
; ----------------
vglobal tsa.data_total_threads
vglobal tsa.data_acquired_threads
vglobal tsa.data_current_thread
vglobal tsa.data_stack_size
; SEM Functions:
; --------------
vglobal sem.acquire_lock
vglobal sem.release_lock
vglobal sem.try_acquire_lock
