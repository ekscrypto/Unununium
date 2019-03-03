;; $Header: /cvsroot/uuu/dimension/cell/process/avalon/avalon.asm,v 1.2 2002/10/04 01:48:28 instinc Exp $
;;
;; avalon thread engine
;; Copyright (C) 2002, Dave Poirier
;; Distributed under the BSD License


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
  db "Avalon - RT Thread Engine",0
  str_author:
  db "eks",0
  str_copyright:
  db "Copyright (C) 2002, Dave Poirier",0x0A
  db "Distributed under the BSD license",0x00

;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------

%define EXTRA_CHECKS

; Base Time Slice which will be used as the number of microseconds between each
; thread switch of the lowest priority.  When no real-time timers are pending.
%assign _BASE_TIME_SLICE_	625

; Default stack size in bytes
%assign _DEFAULT_STACK_SIZE_	2048

; This will display thread statistics on the top right corner
%define _SHOW_THREAD_STATS_

; DO NOT MODIFY
%define _SHORTLIFE_THREADS_	32

; Highest priority allowed.  Anything above that will be refused.
%assign _HIGHEST_PRIORITY_	7

; set to the same value as --stack-location on the U3L command line
%assign _INIT_STACK_LOCATION_	0x1000

; initial eflags register state when creating threads
; bit	description
; ---	-----------
;   0	CF, Carry flag
;   1	1
;   2	PF, Parity flag
;   3	0
;   4	AF, Adjust flag
;   5   0
;   6   ZF, Zero flag
;   7	SF, Sign flag
;   8	TF, Trap flag
;   9	IF, Interrupt flag
;  10	DF, Direction flag
;  11	OF, Overflow flag
; 12-13	IOPL, I/O Privilege level
;  14	NT, Nested flag
;  15	0
;  16	RF, Resume flag
;  17	VM, Virtual mode
;  18	AC, Alignment check
;  19	VIF, Virtual Interrupt flag
;  20	VIP, Virtual Interrupt pending
;  21	ID, Identification flag
; 22-31	0
%define _THREAD_INITIAL_EFLAGS_ 0x00000602


; Initial code segment to use by default
%define _THREAD_INITIAL_CS_	0x0008


; PIT Adjustment value
; --------------------
%assign _PIT_ADJ_DIV_			1799795308
%assign _PIT_ADJ_DIV_PRECISION_		31
%assign _PIT_ADJ_MULT_		  	2562336687
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


; Macro to compute the 'idle' thread location
%define idle_thread	(short_life_threads + (_SHORTLIFE_THREADS_ * _thread_t_padded_size))

; Macro introducing a small I/O delay, gives some time for the chips to handle
; the request we just sent.
%define io_delay	out 0x80, al


; Verify assumed data structure lengths
%if _thread_t_padded_size <> 64
  %error "_thread_t structure is not 64 bytes big!"
%endif
%if _process_t_padded_size <> 64
  %error "_process_t structure is not 64 bytes big!"
%endif



;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
section .c_init
global _start



								    _bochsStop:
;------------------------------------------------------------------------------
; code for the Bochs Emulator with IO-Debug support, used to stop the emulation
; in order to do some hand checking on register values, etc.
;------
  pushad				; backup edx/eax
  mov dx, 0x8A00			; IO-Debug port
  mov eax, edx				; IO-Debug Enable command
  out dx, ax				; enable IO-Debug
  mov al, 0xE0				; IO-Debug RtCP command
  out dx, ax				; return to bochs command prompt
  popad					; restore eax/edx
  retn					; -all done-
;------------------------------------------------------------------------------
%define bochsStop call _bochsStop	; nifty macro keeps code clean
;------------------------------------------------------------------------------



									_start:
;------------------------------------------------------------------------------
  mov [_start], esp			; backup the entry stack pointer
					;
					; setup short-life threads' stack
					;--------------------------------
  mov ecx, _SHORTLIFE_THREADS_		; number of short life threads to setup
  mov ebx, short_life_stacks		; pointer to first allocated stack
  mov edx, _DEFAULT_STACK_SIZE_		; stack size to use
  mov eax, short_life_threads - _thread_t_padded_size; pointer before first  _thread_t
					;
.setting_up_shortlife_threads:		;
  add ebx, edx				; get "Top of Stack" from base of it
  add eax, byte _thread_t_padded_size	; get to next _thread_t
  dec ecx				; number of threads to init - 1
  mov [eax + _thread_t.stack_top], ebx	; set pointer to top of stack
  mov [eax + _thread_t.stack_size], edx	; set stack size (_DEFAULT_STACK_SIZE_)
  jns short .setting_up_shortlife_threads; continue until 'idle' thread is done
					;
					; setup idle thread
					;------------------
  mov [active_thread.running], eax	; set initial active thread as 'idle'
  mov [active_thread.selector], eax	; set initial thead selector
  mov [eax + _thread_t.priority], ecx	; set idle thread priority to -1
					;
					; create initialization thread
					;-----------------------------
  xor edx, edx				; set owner = system
  mov ebx, .restore_original_stack	; set entry point
  call thread.create_shortlife		; create it as short-life
					;
					; Hook IRQ0 - Unchanneled
					;------------------------
  mov al, 0x20				; irq0 -> int 0x20
  mov esi, __timer_handler		; irq handler
  externfunc int.hook			; hook it up
  mov al, 0x00				; irq 0
  externfunc int.unmask_irq		; enable it
					;
					;
  jmp near _idler			; go idle some
					;
					;
.restore_original_stack:		; Resume initialization
					;----------------------
  bochsStop
  mov esi, [_start]
  mov ebx, _INIT_STACK_LOCATION_
.restoring_stack:
  sub ebx, byte 4
  push dword [ebx]
  cmp ebx, esi
  ja short .restoring_stack

; TODO:
; o hook up the timer irq
; o modify the various lock/unlock mutexes SMC

  retn
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------




section .text


__latch_timer:
;------------------------------------------------------------[ latch timer ]--
;>
;; Returns the number of microseconds before the currently set timer expires
;;
;; parameters
;; ----------
;; none
;;
;; returns
;; -------
;; edx:eax - number of microseconds until interruption
;<
;-----------------------------------------------------------------------------
   xor eax, eax				; set eax to 0
   out 0x43, al				; send 'latch' command for channel 0
   io_delay				; give it some time
   io_delay				;
   in al, 0x40				; latch 'LSB'
   mov ah, al				; back it up in ah
   io_delay				; give it some time to update itself
   in al, 0x40				; latch 'MSB'
   mov edx, _PIT_ADJ_DIV_		; magic value as detailed above
   xchg ah, al				; swap 'MSB' and 'LSB' in their place
   shl eax, _PIT_ADJ_SHIFT_REQUIRED_	; adjust value for some magic
   mul edx				; compute microseconds equivalent
   retn					; return to caller
;-----------------------------------------------------------------------------



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
  shl eax, _PIT_ADJ_SHIFT_REQUIRED_	; adjust microseconds for multiply
  mov edx, _PIT_ADJ_MULT_		; magic multiplier
  mul edx				; magic multiply, get ticks count
  mov al, 0x30				; select channel 0
  out 0x43, al				; send selection to command port
  xchg eax, edx				; copy the whole part of the result
  and ah, 0x7F				; keep only the lowest 15bits
  out 0x40, al				; send the low 8bits of tick count
  mov al, ah				; get high 7bits of tick count
  out 0x40, al				; send it
  retn					; return to caller
;-----------------------------------------------------------------------------



thread.create_shortlife:
;------------------------------------------------[ create shortlife thread ]--
;>
;; Creates a thread which is expected to have a very short life
;;
;; parameters
;; ----------
;; o edx = process id (0 = system)
;; o ebx = starting address
;; o edi = value of the edi register of the thread created (param for thread)
;;
;; returns
;; -------
;; o eax = thread id
;; errors as usual
;<
;-----------------------------------------------------------------------------
  pushfd				; backup the flags
  cli					; disable thread switch
					;
					; find a free short-life thread
					;------------------------------
  pushad				; use ecx as scratch pad
  bsf	ecx, dword [free_shortlife_threads]; set ecx=free _thread_t number
  jz	short .allocate_thread_header	; in case none was found
					;
					; mark _thread_t as 'busy'
					;-------------------------
  mov	eax, 1				; bit mask
  shl	eax, cl				; shift mask to proper _thread_t
  xor	[short_life_threads], eax	; invert the bit 1->0
					;
					; compute _thread_t location
			;------------------------------------------------------
  shl	ecx, 6		; warning: adjusted for _thread_t_size = 64
			;------------------------------------------------------
  add	ecx, short_life_threads		;
					;
					; check for system process request (0)
					;-------------------------------------
  test	edx, edx			; process = 0?
  jnz	short .owner_set		; if not, keep set process id
  mov	edx, system_process		; set process id
.owner_set:				;
					; fill thread's process information
					;---------------------------
  mov	[ecx + _thread_t.owner_proc], edx
  mov	esi, [edx + _process_t.threads]	;
  mov	[edx + _process_t.threads], ecx	;
  movzx eax, byte [edx + _process_t.priority]
  xor	edx, edx			; make ourself a nil register
  mov	[ecx + _thread_t.next_proc], esi;
  mov	[ecx + _thread_t.prev_proc], edx;
  test	esi, esi			;
  jz	short .unique_thread		;
  mov	[esi + _thread_t.prev_proc], ecx;
.unique_thread:				;
					; prepare thread information
					;---------------------------
  push	edi				; set thread parameter
  xchg	ecx, ebx			; swap entry point and _thread_t ptr
  ;xor	edx, edx (already 0)		; set startline high 32bits to nil
  mov	ebp, edx			; set startline low 32bits to nil
  mov	edi, edx			; set deadline high 32bits to nil
  mov	esi, edx			; set deadline low 32bits to nil
  push	edx				; set timer re-trigger interval to nil
  push	edx				; set result callback to nil
					;
  call	init_thread_rt			; initialize thread values
  call	_schedule_thread		; schedule it
					;
					; return with success
					;--------------------
  mov [esp + 28], ebx			; set eax = thread id
  popad					; restore the registers
  popfd					; restore previous interruptability
  clc					; indicate success
  retn					; return to caller
					;
.allocate_thread_header:		;
  ; TODO: allocate memory
bochsStop
  mov eax, -1
  jmp short $
;-----------------------------------------------------------------------------




init_thread_rt:
;---------------------------------------------------[ init realtime thread ]--
;>
;; parameters
;; ----------
;; eax	   priority
;; ebx     ptr to _thread_t struc
;; ecx     initial entry point
;; edx:ebp startline
;; edi:esi deadline
;; TOS+00  result callback
;; TOS+04  timer re-trigger interval
;; TOS+08  thread parameter
;;
;; returns
;; -------
;; TOS = TOS+12
;; edx:ebp destroyed
;<
;-----------------------------------------------------------------------------
						; set realtime constraints
						;-------------------------
  mov ah, al					; set_priority = priority
  mov [ebx + _thread_t.priority], eax		; initialize:
 						;  o priority
						;  o set priority
						;  o status
						;  o flags
  mov [ebx + _thread_t.startline + 0], ebp	; startline low 32bits
  mov [ebx + _thread_t.startline + 4], edx	; startline high 32bits
   pop ebp					; ebp = retn's destination
  mov [ebx + _thread_t.deadline  + 0], esi	; deadline low 32bits
  mov [ebx + _thread_t.deadline  + 4], edi	; deadline high 32bits
   pop dword [ebx + _thread_t.result_callback]	; set result callback
  mov edx, [ebx + _thread_t.stack_addr]		; get stack base address
  add edx, [ebx + _thread_t.stack_size]		; find the top of the stack
   pop dword [edx + _thread_t.interval]		; set re-trigger interval
  mov [byte edx - 4], dword thread.kill_self	; thread retn handler
  mov [edx - 8], dword _THREAD_INITIAL_EFLAGS_	; initial cpu flags to use
  mov [edx - 12], dword _THREAD_INITIAL_CS_	; default code segment to use
  sub edx, byte 16				; compute TOS after popad
  mov [edx], ecx				; set thread entry point
  mov [edx - 20], edx				; set popad esp value
  sub edx, byte 28				; compute TOS before popad
   pop dword [edx]				; set thread edi parameter
  mov [ebx + _thread_t.stack_top], edx		; set TOS before popad
   jmp ebp					; pseudo-retn
;------------------------------------------------------------------------------



thread.kill_self:
;-------------------------------------------------------[ thread.kill_self ]--
bochsStop
  mov eax, -2
  jmp short $
;-----------------------------------------------------------------------------





_schedule_thread:
;--------------------------------------------------------[ schedule thread ]--
;>
;; Schedule a thread in the proper queue
;;
;; parameters
;; ----------
;; o ebx = pointer to _thread_t to schedule
;;
;; returns
;; -------
;; o eax, edx, esi, ebp = destroyed
;<
;-----------------------------------------------------------------------------
  xor eax, eax					; nil comparator
						;
						; Determine the queue to use
						;---------------------------
  mov	edx, queues.idle_eaters			; tentatively set idle-eaters
  mov	byte [ebx + _thread_t.status], _THRDS_IDLE_;
  test	byte [ebx + _thread_t.flags], _THRDF_IDLE_; set as idle?
  jnz	short .link_idle			; if so, assumption was good
						;
  mov	edx, queues.pending			; tentatively set pending
						;
						; check for realtime startline
						;-----------------------------
  cmp	[ebx + _thread_t.startline+0], eax	; check startline low 32bits
  jnz	short .sched_as_pending			;
  cmp	[ebx + _thread_t.startline+4], eax	; check startline high 32bits
  jnz	short .sched_as_pending			;
						;
						; place in 'scheduled' queue
						;---------------------------
  mov	edx, queues.scheduled			; pointer to queue pointer
  mov	byte [ebx + _thread_t.status], _THRDS_SCHEDULED_; set thread status
						;
						;
.link_idle:					; link using queue pointer
						;-------------------------
  mov	eax, [edx]				; load queue pointer
  test	eax, eax				; check to see if it's empty
  jnz	short .append				; not empty? add at the end
						;
.emptyring:					; initialize ring queue
						;----------------------
  mov	[edx], ebx				; queue pointer = _thread_t
  mov	[ebx + _thread_t.next_queue], ebx	; wrap back to us
  mov	[ebx + _thread_t.prev_queue], ebx	; wrap back to us
						;
						; update active thread selector
						;------------------------------
  cmp	[active_thread.selector], dword idle_thread
  jnz	short .done				;
  mov	[active_thread.selector], ebx		;
  call	__latch_timer				; get us time until interrupt
  sub	eax, byte 1				; 1us delay for sched kickback
  sbb	edx, byte 0				;
  sub	[system_time.set_interruption+0], eax	; adjust set interruption time
  sbb	[system_time.set_interruption+4], edx	;
  mov	eax, 1					; set 1us delay for interruption
  call	__set_timer				;
  retn						; return to caller
						;
.sched_as_pending:				; pending a specified time
						;--------------------------
  mov	byte [ebx + _thread_t.status], _THRDS_PENDING_; set status
  mov	eax, [edx]				; get pending queue pointer
  test	eax, eax				; check if it's empty
  jz	short .emptyring			; empty? initialize the ring
						;
						; find ordered insertion point
						;-----------------------------
  mov	esi, [ebx + _thread_t.startline + 0]	; low 32bits of startline
  mov	ebp, [ebx + _thread_t.startline + 4]	; high 32bits of startline
.sched_pending:					;
  cmp	ebp, [eax + _thread_t.startline + 4]	; compare high 32bits
  ja	short .next				; >? go to next ring entry
  jb	short .insert				; <? insert here.
  cmp	esi, [eax + _thread_t.startline + 0]	; compare low 32bits
  ja	short .next				; >? go to next ring entry
						;
.insert:					; insert @ found location
						;------------------------
  mov	esi, [eax + _thread_t.prev_queue]	; previous to insertion point
  mov	[eax + _thread_t.prev_queue], ebx	; link with ins. point
  mov	[esi + _thread_t.next_queue], ebx	; link with prev to ins. point
  mov	[ebx + _thread_t.prev_queue], esi	; link prev to ins. point
  mov	[ebx + _thread_t.next_queue], eax	; link ins. point
  cmp	eax, [edx]				; queue pointer need update?
  jnz	short .done				; nope, we are done
  mov	[edx], ebx				; update queue pointer
  retn						; return to caller
						;
.next:						; next node of ring list
						;-----------------------
  mov	eax, [eax + _thread_t.next_queue]	; load next ring entry
  cmp	eax, [edx]				; check for ring wrap
  jnz	short .sched_pending			; unchecked entry? test it
						;
.append:					; add as last entry of ring
						;--------------------------
  mov	esi, [eax + _thread_t.prev_queue]	; load prev to start (last)
  mov	[eax + _thread_t.prev_queue], ebx	; link before start
  mov	[esi + _thread_t.next_queue], ebx	; link after 'last'
  mov	[ebx + _thread_t.prev_queue], esi	; link 'last' as previous
  mov	[ebx + _thread_t.next_queue], eax	; link start as next
.done:						;
  retn						; return to caller
;------------------------------------------------------------------------------


_idler:
;-----------------------------------------------------------[ idler thread ]--
;>
;; Idle thread, given control once at setup and when there's nothing scheduled.
;<
;-----------------------------------------------------------------------------
%ifdef _SHOW_THREAD_STATS_		;
  inc dword [0xB813C]			;
%endif					;
  hlt					;
  jmp short _idler			;
;-----------------------------------------------------------------------------


__timer_handler:
;----------------------------------------------------------[ timer handler ]--
;>
;; Timer IRQ (0) Handler
;;
;; parameters
;; ----------
;; none
;;
;; returns
;; -------
;; none
;<
;------------------------------------------------------------------------------
					; save running thread state
					;--------------------------
  pushad				; backup the registers
  mov esi, [active_thread.running]	; get ptr to running _thread_t
  mov [esi + _thread_t.stack_top], esp	; backup TOS
					;
					; acknowledge interrupt
					;----------------------
  mov al, 0x60				; 'Specific EOI' for IRQ 0
  out 0x20, al				; send to Master PIC
					;
					; update system time
					;-------------------
  mov edi, system_time			;
  mov eax, [edi + ((system_time.set_interruption+0) - system_time)]
  mov edx, [edi + ((system_time.set_interruption+4) - system_time)]
  mov ebx, eax
  mov ecx, edx
  sub eax, [edi + ((system_time.time_at_schedule+0) - system_time)]
  sbb edx, [edi + ((system_time.time_at_schedule+4) - system_time)]
  add [edi + ((system_time.official+0) - system_time)], eax
  adc [edi + ((system_time.official+4) - system_time)], edx
					;
					; compute next time slice
					;------------------------
  mov esi, [esi + _thread_t.next_queue]	;
  mov edx, _BASE_TIME_SLICE_		;
  movzx eax, byte [esi + _thread_t.priority];
  mul edx				;
  mov [edi + ((system_time.time_at_schedule+0) - system_time)], ebx
  mov [edi + ((system_time.time_at_schedule+4) - system_time)], ecx
  add ebx, eax				;
  adc ecx, edx				;
  ; TODO: check pending queue for expired startline
  mov [edi + ((system_time.set_interruption+0) - system_time)], ebx
  mov [edi + ((system_time.set_interruption+4) - system_time)], ecx
  call __set_timer			;

  mov esp, [esi + _thread_t.stack_top]
  popad
  iretd
;------------------------------------------------------------------------------



add_wait_queue:
;---------------------------------------------------------[ add_wait_queue ]--
; ebx = pointer to wait_queue_head_t
; esi = pointer to wait_queue_t entry to add
;-----------------------------------------------------------------------------
%ifdef EXTRA_CHECKS				;
  cmp dword [esi + wait_queue_t.next], byte 0	; check for NULL .next ptr
  jnz short .error				; if NULL, ain't ok
  cmp dword [esi + wait_queue_t.previous], byte 0; check for NULL .prev ptr
  jnz short .ok					; if not NULL, both are ok
.error:						;
  push esi					; indicate queue entry ptr
  push byte __SYSLOG_TYPE_FATALERR__		; error type, damn real
  push dword xchecks_queuing_queued		; error message
  externfunc sys_log.print			; display it
  jmp short $					; lock it up
.ok:						;
%endif						;
						;
  LOCK_SPINLOCK ebx				; acquire lock on queue
  mov eax, [ebx + wait_queue_head_t.next]	; get ptr to remove
  mov [esi + wait_queue_t.next], eax		; set .next ptr
  mov [esi + wait_queue_t.previous], ebx	; set .prev ptr
  mov [ebx + wait_queue_head_t.next], eax	; link back .next ptr
  mov [eax + wait_queue_t.previous], esi	; link back .prev ptr
  UNLOCK_SPINLOCK ebx				; release queue lock
  retn						;
;-----------------------------------------------------------------------------

  


remove_wait_queue:
;------------------------------------------------------[ remove_wait_queue ]--
; ebx = pointer to semaphore
; esi = pointer to wait_queue_t entry
;-----------------------------------------------------------------------------
%ifdef EXTRA_CHECKS				;
  cmp dword [esi + wait_queue_t.previous], byte 0; previous ptr == NULL?
  jz short .error				; if so, fix your bugs dude
  cmp dword [esi + wait_queue_t.next], byte 0	; next ptr == NULL?
  jnz short .ok					; no, both pointers valid!
.error:						; one/both pointer(s) == NULL
  push esi					; display semaphore ptr
  push byte __SYSLOG_TYPE_FATALERR__		; set log type
  push dword xchecks_unqueuing_unqueued		; our lovely message
  externfunc sys_log.print			; screw the programmer
  jmp short $					; lock the machine
.ok:						;
%endif						;
  push ecx					; back up ecx
  LOCK_SPINLOCK ebx				; acquire lock on queue
  mov eax, [esi + wait_queue_t.previous]	; load .prev ptr
  mov ecx, [esi + wait_queue_t.next]		; load .next ptr
  mov [ecx + wait_queue_t.previous], eax	; link .prev to .next
  mov [eax + wait_queue_t.next], ecx		; link .next to .prev
  UNLOCK_SPINLOCK ebx				; release lock on queue
  pop ecx					; restore destroyed ecx
%ifdef EXTRA_CHECKS				;
  mov [esi + wait_queue_t.previous], dword 0	; set .prev to NULL
  mov [esi + wait_queue_t.next], dword 0	; set .next to NULL
%endif						;
  retn						;
;-----------------------------------------------------------------------------



wake_up:
;----------------------------------------------------------------[ wake up ]--
; ebx = pointer to wait_queue_head_t
;-----------------------------------------------------------------------------
  push esi					; back up esi
  LOCK_SPINLOCK ebx				; Acquire lock on queue
  push ebx					; save ptr to wait_queue_head_t
  mov esi, [ebx + wait_queue_head_t.next]	; load ptr to next entry
.processing:					;
  cmp esi, ebx					; reached end of list?
  jz short .done				; esi == wait_queue_head_t..
  push dword [esi + wait_queue_t.next]		; remember position of next
%ifdef EXTRA_CHECKS				;
  mov [esi + wait_queue_t.next], dword 0	; set .next ptr to NULL
  mov [esi + wait_queue_t.previous], dword 0	; set .prev ptr to NULL
%endif						;
  mov edx, [esi + wait_queue_t.queued_item]	; get task ptr
  call _schedule_thread				; schedule thread
  pop esi					; get position of next entry
  jmp short .processing				; continue processing queue
.done:						;
  mov [ebx + wait_queue_head_t.next], ebx	; NULLize .next ptr of queue
  mov [ebx + wait_queue_head_t.previous], ebx	; NULLize .prev ptr of queue
  UNLOCK_SPINLOCK ebx				; release queue lock
  pop esi					; restore esi
  retn						;
;-----------------------------------------------------------------------------
  
  

lock_semaphore:
;---------------------------------------------------------[ lock semaphore ]--
; parameters:
; EBX = pointer to semaphore
;-----------------------------------------------------------------------------
  lock						; atomic operation..
  dec  dword [ebx + semaphore_t.count]		; -1 for every lock acquired
  js   short .wait_for_unlock			; if count wasn't positive..
  retn						; otherwise, lock acquired.
						;
.wait_for_unlock:				; wait for an unlock operation
						;-----------------------------
  mov  edx, [active_thread.running]		; load current task pointer
  sub  esp, byte wait_queue_t_size		; create wait_queue_t space
  mov  esi, esp					; set pointer to it
  mov  [esi + wait_queue_t.queued_item], edx	; queued_item = ptr to task
%ifdef EXTRA_CHECKS				;
  mov  [esi + wait_queue_t.previous], dword 0	; set starting values
  mov  [esi + wait_queue_t.next], dword 0	; set starting values
%endif						;
  or  [edx + _thread_t.flags], byte _THRDF_UNINTERRUPTIBLE_
  lock						; atomic operation..
  inc  dword [ebx + semaphore_t.count]		; set count back
  add  ebx, byte semaphore_t.wait_queue		; set ptr to wait_queue_head_t
  call add_wait_queue				; add it to the queue
  sub  ebx, byte semaphore_t.wait_queue		; get back semaphore ptr
;TODO  call wait_for_wakeup			; wait for semaphore.unlock
  and [edx + _thread_t.flags], byte 0xFF-_THRDF_UNINTERRUPTIBLE_
  add  esp, byte wait_queue_t_size		; free wait_queue_t space
  jmp  short lock_semaphore			; retry acquiring
;-----------------------------------------------------------------------------


unlock_semaphore:
;--------------------------------------------------------[ unlock semaphore]--
; parameters:
; EBX = pointer to semaphore
;-----------------------------------------------------------------------------
  lock						; atomic operation
  inc  dword [ebx + semaphore_t.count]		; increment count
  jle  short .done				; signed or zero?, done
						;
						; went positive, wake ppl up
  add  ebx, byte semaphore_t.wait_queue		; set ptr to wait_queue_head_t
  call wake_up					; wake 'em up
  sub  ebx, byte semaphore_t.wait_queue		; restore semaphore pointer
.done:						;
  retn						; done
;-----------------------------------------------------------------------------



section .data
free_shortlife_threads: dd 0xFFFFFFFF

%ifdef EXTRA_CHECKS
xchecks_queuing_queued:
  db "Trying to queue an already queued task: %x",0
xchecks_unqueuing_unqueued:
  db "Trying to unqueue an unqueued task: %x",0
%endif



section .bss

; Tick/Time variables
; -------------------
system_time:
.official:		resd 2
.set_interruption:	resd 2
.time_at_schedule:	resd 2

; Scheduling information
; ----------------------
active_thread:
.running:		resd 1
.selector:		resd 1

queues:
.pending:		resd 1
.scheduled:		resd 1
.idle_eaters:		resd 1

; Pre-Allocated structures
; ------------------------
short_life_threads:	resb (_SHORTLIFE_THREADS_+1) * _thread_t_padded_size
short_life_stacks:	resb (_SHORTLIFE_THREADS_+1) * _DEFAULT_STACK_SIZE_
system_process:		resb _process_t_padded_size
