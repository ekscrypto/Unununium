;; $Header: /cvsroot/uuu/uuu/src/cells/thread/strontium/strontium.asm,v 2.6 2002/01/04 18:44:42 lukas2000 Exp $
;;
;; strontium ][ thread engine
;; Copyright 2001 Phil Frost
;; based on original strontium by Dave Poirier
;;
;; known issues:
;; -------------
;; scheduling is a simple rotation with no reguard to priority
;; yield_self will actually steal some of the next thread's CPU time

;                                           -----------------------------------
;                                                                        config
;==============================================================================

; _VISUAL_ACTIVITY_ is used mainly for test purposes.  It will increase a dword
; on screen which indicate if we are still alive or if interrupts have been
; disabled
;%define _VISUAL_ACTIVITY_

; This is the frequency (Hz) of the context switches
%define FREQ 200

; This value is used to control the default stack size of newly created threads
%define DEF_STACK_SIZE 2 * 1024

; and this is the size of the large stack, specified by a flag in the thread
%define LARGE_STACK_SIZE 8 * 1024

; This will enable a signature in the strucs which will be checked to see if
; a bad pointer has been followed or a struc has been corrupted
%define _MAGIC_CHECKS_

; This will store the EIP of each thread a seccond time, in the thread struc
; as well as on the stack. Good for detecting memory corruption. This probally
; won't work as it was part of a debugging attempt long ago, but if it's needed
; again it's a good place to start :P
;%define _EIP_CHECKS_

; This will create an ICS channel that will be called on each tick. This is
; really slow, but hey...
;%define _TICK_CHANNEL_

; This will display in the upper left corner the number of active threads.
;%define _SHOW_THREAD_COUNT_

; This will enable some useless prattle to the DEBUG log
;%define _DEBUG_

;                                           -----------------------------------
;                                                                        macros
;==============================================================================

%macro mcheck_thread 1	; check the magic of a thread
  %ifdef _MAGIC_CHECKS_
    cmp dword[%1+thread.magic], THREAD_MAGIC
    jnz .magic_error
  %endif
%endmacro

%macro mcheck_proc 1	; check the magic of a process
  %ifdef _MAGIC_CHECKS_
    cmp dword[%1+proc.magic], PROC_MAGIC
    jnz .magic_error
  %endif
%endmacro

%macro mcheck_timer 1	; check the magic of a process
  %ifdef _MAGIC_CHECKS_
    cmp dword[%1+proc.magic], TIMER_MAGIC
    jnz .magic_error
  %endif
%endmacro

;                                           -----------------------------------
;                                                                        strucs
;==============================================================================

;; The .threads pointer must always be valid; a process may not exist without
;; a thread.
;;
;; A process can be created with a parent, by setting .parent to non-zero.
;; If a process has a parent, the parent will recieve notice when the child
;; process is terminated. Also, if PROCESS_F_KILL_WITH_PARENT is set, the
;; child process will be killed when the parent process terminates.

struc proc
%ifdef _MAGIC_CHECKS_
  .magic:	resd 1	; magic number, 'THps'
  %define PROC_MAGIC	'THps'
%endif
  .next:	resd 1	; ptr to next process or 0 for none
  .prev:	resd 1	; prt to prev process or 0 for none
  .threads:	resd 1	; ptr to first child thread (must be at least 1)
  .callback:	resd 1	; to be called on termination, or 0 for none
  .children:	resd 1	; linked list of child processes, 0 for none
  .flags:	resd 1	; process flags, see below
  .info:	resb process_info_size	; the process info we all know and love
  .reserved:	resb process_info_size % 4 ; maintain alignment
endstruc

; kill child process with the parent
%define PROCESS_F_KILL_WITH_PARENT	1



;; The .next and .prev pointers in the thread struc form a loop, not a chain.
;; If there is only one thread, both pointers should point to itself.

struc thread
%ifdef _MAGIC_CHECKS_
  .magic:	resd 1	; magic number, 'THth'
  %define THREAD_MAGIC	'THth'
%endif
%ifdef _EIP_CHECKS_
  .eip:		resd 1	; extra copy to verify EIP
%endif
  .next:	resd 1	; ptr to next thread struc
  .prev:	resd 1	; ptr to previous thread struc
  .proc_next:	resd 1	; ptr to next thread in this process, 0 for none
  .proc_prev:	resd 1	; ptr to previous thread in this process, 0 for none
  .process:	resd 1	; ptr to parrent process struc
  .esp:		resd 1	; saved ESP
  .stack_base:	resd 1	; base address (top, low end) of thread's stack
  .flags:	resd 1	; thread flags; see below.
  .priority:	resb 1	; ignored atm
  .reserved:	resb 3
endstruc

%define THREAD_F_FPU		1	; thread is using FPU
%define THREAD_F_LARGE_STACK	2	; use a large stack (LARGE_STACK_SIZE)
%define THREAD_F_SLEEPING	4	; thread is currently sleeping



struc timer
%ifdef _MAGIC_CHECKS_
  .magic:	resd 1	; magic number, 'THtm'
  %define TIMER_MAGIC 'THtm'
%endif
  .expire:	resq 1	; tick count timer expires on
  .next:	resd 1	; ptr to next timer in chain (sorted by .expire)
  .prev:	resd 1	; ptr to prev timer node
  .callback:	resd 1	; func to call on expire
  .rememberme:	resd 1	; value to be restored when timer expires
endstruc


section .c_info
	db 1,0,0,"a"
	dd str_author
	dd str_copyrights
	dd str_title

	str_title:
	db "Strontium $Revision: 1.00",0

	str_author:
	db "indigo",0

	str_copyrights:
	db "BSD Licensed",0
;                                           -----------------------------------
;                                                                     cell init
;==============================================================================

section .c_init

init:
  jmp short .start

.error:
  dmej 0x7EDE0001

.start:
  pushad				;
					; allocate space for process strucs
					;----------------------------------
  mov edx, proc_size			;
  mov ecx, 4				; 16 blocks at a time
  externfunc mem.fixed.alloc_space	;
  jc .error				;
  mov [proc_memspace], edi		;
					; and more space for thread strucs
					;---------------------------------
  mov edx, thread_size			;
  mov ecx, 5				; 32 blocks at a time
  externfunc mem.fixed.alloc_space	;
  jc .error				;
  mov [thread_memspace], edi		;
					; and more space for timer strucs
					;--------------------------------
  mov edx, timer_size			;
  mov ecx, 5				; 32 blocks at a time
  externfunc mem.fixed.alloc_space	;
  jc .error				;
  mov [timer_memspace], edi		;
					; and some space for linked list nodes
					;-------------------------------------
  mov edx, 8				;
  mov ecx, 5				; 32 blocks at a time
  externfunc mem.fixed.alloc_space	;
  jc .error				;
  mov [ll_memspace], edi		;
					; allocate stack for the idle thread
					;-----------------------------------
  mov ecx, DEF_STACK_SIZE		;
  externfunc mem.alloc			;
  jc .error				;
  mov [idle_thread+thread.stack_base], edi
					; create an init thread
					;-----------------------
  mov edi, [thread_memspace]		;
  externfunc mem.fixed.alloc		; allocate memory for thread
  jc .error				;
  dbg lprint {"init thread created at 0x%x",0xa}, DEBUG, edi
%ifdef _MAGIC_CHECKS_			;
  mov dword[edi+thread.magic], THREAD_MAGIC
%endif					;
  xor eax, eax				;
  mov [edi+thread.next], edi		;
  mov [edi+thread.prev], edi		; form a loop with 1 node in it
  mov [edi+thread.proc_next], eax	;
  mov [edi+thread.proc_prev], eax	;
  ; we don't care about .esp yet	;
  mov [edi+thread.stack_base], eax	; XXX this will be passed in the options
  mov [edi+thread.flags], eax		;
  mov byte[edi+thread.priority], 50	; medium priority
  mov ebx, edi				; EBX = ptr to thread
					;
					; create the init process
					;------------------------
  mov edi, [proc_memspace]		;
  externfunc mem.fixed.alloc		; allocate memory for process
%ifdef _MAGIC_CHECKS_			;
  mov dword[edi+proc.magic], PROC_MAGIC	;
%endif					;
  xor eax, eax				;
  mov [edi+proc.next], eax		; zero out the process list pointers
  mov [edi+proc.prev], eax		;
  mov [processes], edi			; make this root of process list
  mov [edi+proc.threads], ebx		; add thread to process
  mov [edi+proc.callback], eax		; no callback
  mov [edi+proc.children], eax		; no children
  mov [edi+proc.flags], eax		; no flags
  mov dword[edi+proc.info+process_info.argv], init_argv
  mov [ebx+thread.process], edi		; link thread to process
					;
  inc dword[thread_count]		;
  mov [cur_thread], ebx			;
					; reprogram PIT (channel 0)
					;-----------------------------------
  mov al, 0x34				;
  out 0x43, al				;
  mov al, 0x1234DD / FREQ % 0x100	;
  out 0x40, al				;
  mov al, 0x1234DD / FREQ / 0x100	;
  out 0x40, al				;
					; hook IRQ 0
					;-----------
  mov esi, _timer_handler		;
  mov al, 0x20				;
  externfunc int.hook			;
  mov al, 0x00				;
  externfunc int.unmask_irq		;
					;
  popad					;
  sti					; engage!

;                                           -----------------------------------
;                                                                 section .text
;==============================================================================

section .text

;                                           -----------------------------------
;                                                                  thread.sleep
;==============================================================================

globalfunc thread.sleep
;>
;; This function will unschedule the thread specified, making it effectively
;; 'sleep'.  If the thread id is the one currently running, the control will
;; be redirected to thread.sleep_self
;;
;; parameters:
;; -----------
;; eax = thread id
;;
;; returned values:
;; ----------------
;;   eax = (unmodified)
;;   ebx = (unmodified)
;;   ecx = (unmodified)
;;   edx = (unmodified)
;;   esi = (undetermined)
;;   edi = (undetermined)
;;   esp = (unmodified)
;;   ebp = (unmodified)
;<

%ifdef _TICK_CHANNEL_

;                                           -----------------------------------
;                                            timer.set_tick_notification_client
;==============================================================================

globalfunc timer.set_tick_notification_client
;>
;; parameters:
;;------------
;; esi = pointer to client, must be ICS compliant
;;
;; returned values:
;;-----------------
;; if cf = 0, sucessful
;;   eax = (undetermined)
;;   ebx = (undetermined)
;;   ecx = entry number in the client node
;;   edx = pointer to client node holding client entry pointer
;;   esi = (unmodified)
;;   edi = pointer to channel data
;;   esp = (unmodified)
;;   ebp = (unmodified)
;;
;; if cf = 1, failed
;;   eax = error code
;;   ebx = (undetermined)
;;   ecx = (undetermined)
;;   edx = (undetermined)
;;   esi = (unmodified)
;;   edi = (undetermined)
;;   esp = (unmodified)
;;   ebp = (unmodified)
;<

;                                           -----------------------------------
;                                                          timer.get_resolution
;==============================================================================

globalfunc timer.get_resolution
;>
;; parameters: none
;; returned values: eax = number of nanosecond between ticks
;<

%endif	; %ifdef _TICK_CHANNEL_

;                                           -----------------------------------
;                                                                 timer.destroy
;==============================================================================

globalfunc timer.destroy
;>
;; parameters:
;; -----------
;; EBX = pointer to timer entry to free
;;
;; returned values:
;; ----------------
;; all registers unmodified
;; errors as usual
;<

;                                           -----------------------------------
;                                                       thread.create_semaphore
;==============================================================================

globalfunc thread.create_semaphore
;>
;; This function allow to create semaphore, which can be use to control mutual
;; exclusions also called mutex
;;
;; parameters:
;; -----------
;; eax = atomic count starting value, normally 0
;;
;; returned values:
;; ----------------
;; all registers unmodified
;; errors as usual
;<

;                                           -----------------------------------
;                                                      thread.destroy_semaphore
;==============================================================================

globalfunc thread.destroy_semaphore
;>
;; parameters:
;; -----------
;; ebx = pointer to mutex entry to free
;;
;; returned values:
;; ----------------
;; all registers unmodified
;; XXX errors?
;<

;                                           -----------------------------------
;                                          thread.lock_read_semaphore_garanteed
;==============================================================================

globalfunc thread.lock_read_semaphore_garanteed
;>
;; Acquire a read lock on a semaphore. If the semaphore is write locked or have
;; pending write locks, the thread will be appended to the read lock waiting
;; queue.
;;
;; parameters:
;; -----------
;; EAX = semaphore id
;;
;; returned values:
;; ----------------
;; all registers unmodified
;<
  
;                                           -----------------------------------
;                                         thread.lock_write_semaphore_garanteed
;==============================================================================

globalfunc thread.lock_write_semaphore_garanteed
;>
;; Acquire a write lock on a semaphore.  If the semaphore is already locked
;; either by other write lock of by other read lock, the thread will be placed
;; in the waiting queue
;;
;; parameters:
;; -----------
;; EAX = semaphore id
;;
;; returned values:
;; ----------------
;; all registers unmodified
;<

;                                           -----------------------------------
;                                                    thread.lock_read_semaphore
;==============================================================================

globalfunc thread.lock_read_semaphore
;>
;; Try to lock a read semaphore, if the semaphore is currently locked for write
;; or have pending write locks, this routine will fail returning CF=1 otherwise
;; it will lock the semaphore and return CF=0
;;
;; parameters:
;; -----------
;; EAX = semaphore id
;;
;; returned values:
;; ----------------
;; all registers unmodified
;; CF = completion status, 0: semaphore was locked; 1: lock failed
;<

;                                           -----------------------------------
;                                                   thread.lock_write_semaphore
;==============================================================================

globalfunc thread.lock_write_semaphore
;>
;; Try to lock a write semaphore.  Will return CF=1 if the semaphore is in any
;; other state than free
;;
;; parameters:
;; -----------
;; EAX = semaphore id
;;
;; returned values:
;; ----------------
;; all registers unmodified
;; CF = completion status, 0: semaphore was locked; 1: lock failed
;<

;                                           -----------------------------------
;                                                 thread.unlock_write_semaphore
;==============================================================================

globalfunc thread.unlock_write_semaphore
;>
;; Release a write lock on a semaphore
;;
;; parameters:
;; -----------
;; EAX = semaphore id
;;
;; returned values:
;; ----------------
;; all registres unmodified
;<

;                                           -----------------------------------
;                                                  thread.unlock_read_semaphore
;==============================================================================

globalfunc thread.unlock_read_semaphore
;>
;; Release a read lock acquired on a semaphore
;;
;; parameters:
;; -----------
;; EAX = semaphore id
;;
;; returned values:
;; ----------------
;; all registers unmodified
;<

  xor eax, eax
  dec eax
  stc
  retn

;                                           -----------------------------------
;                                                                     timer.set
;==============================================================================

globalfunc timer.set
;>
;; create a new timer. When the timer expires it will be destroyed and the
;; callback will be called.
;;
;; parameters:
;; -----------
;; EAX = number of nanoseconds until timer expires
;; EDX = pointer to callback, must be valid until timer expires or is destroyed
;; EBP = value to be restored when callback is called
;;
;; returned values:
;; ----------------
;; EDX = timer ID
;; registers and errors as usual
;;
;; the callback is called with:
;; ----------------------------
;; EBP = remembered value
;; EDX = timer ID
;; 
;; The callback may destroy all registers. The callback is called within an
;; interupt handler. Listen to your mother. Don't stare at the sun.
;;
;; TODO: make linking search check all 64 bits in case tick counter rolls over.
;; At 200Hz this will take 248.551 days, but Unununium is rock solid and faster
;; frequencies may be used.
;<

  pushad

  %if FREQ <> 200
    %error "frequency was assumed to be 200Hz but it's not"
  %endif
  mov ebx, eax				; divide by 5 mil
  shr ebx, 22				;
  shr eax, 25				;
  sub ebx, eax				; EBX = delay in ticks
  test ebx, ebx				; if count == 0 timer is too fast
  jz near .too_fast			;
					; allocate memory for timer struc
					;---------------------------------
  mov edi, [timer_memspace]		;
  externfunc mem.fixed.alloc		; EDI = ptr to timer struc
  jc .failed
  dbg lprint {"timer created at %x",0xa}, DEBUG, edi
%ifdef _MAGIC_CHECKS_			;
  mov dword[edi+timer.magic], TIMER_MAGIC
%endif					;
  mov [edi+timer.callback], edx		; fill out the callback
  mov [edi+timer.rememberme], ebp	; save rememberme value
					;
					; calculate expiration tick count
					;--------------------------------
  call thread.enter_critical_section	; don't want tick count to roll over
  mov eax, [timer.tick_count+4]		; EAX = MSW of count
  add ebx, [timer.tick_count]		; EBX = LSW of calculated count
  adc eax, byte 0			; inc eax if result rolls over
  mov [edi+timer.expire], ebx		; put expiration time in struc
  mov [edi+timer.expire+4], eax		;
					; link timer node into list
					;--------------------------
  mov ecx, [timers]			; ECX = root timer
  xor esi, esi				; ESI = 0 (will be the prev. timer)
  test ecx, ecx				; if root timer is 0
  jz .found_it				;   we are done
.compare_node:				;
  cmp [ecx+timer.expire], ebx		; compare LSW of expire times
  jae .found_it				; if new timer is less or equal, done
  mov esi, ecx				; ESI = prev. timer
  mov ecx, [ecx+timer.next]		; ECX = next timer
  test ecx, ecx				; if next timer is not null
  jnz .compare_node			;   compare the next one
					;
					; link the timer into the list
.found_it:				;-----------------------------
					; ECX = node to put after new
					; ESI = node to put before new
					; (either may be 0)
  mov [edi+timer.next], ecx		; new -> next
  mov [edi+timer.prev], esi		; new -> prev
  test ecx, ecx				; if next timer is null
  jz .no_next				;   don't try to link it
  mov [ecx+timer.prev], edi		; next -> new
.no_next:				;
  test esi, esi				; if prev timer is null don't try to
  jz .no_prev				;   link it and update root timer
  mov [esi+timer.next], edi		; prev -> new
					;
.done:					;
  call thread.leave_critical_section	;
  mov [esp+20], edi			; return our edi in edx (thread ID)
  popad					;
  clc					;
  retn					;

.no_prev:				; linking new timer and prev. is null
  mov [timers], edi			; update root node
  jmp short .done			;

.too_fast:				; delay is too short for us
  mov eax, __ERROR_INVALID_PARAMETERS__	;
.failed:				;
  call thread.leave_critical_section	;
  mov [esp+28], eax			; return error code
  popad					;
  stc					;
  retn					;

;                                           -----------------------------------
;                                                        process.get_info_struc
;==============================================================================

globalfunc process.get_info_struc
;>
;; Returns a pointer to the process information including stdin/out/err,
;; environment, and possibly more in the future. This is the same thing that's
;; passed to the app in EBX when it's called. See struc process_info in
;; include/proc.inc
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; ESI = ptr to process info
;; all other registers unmodified
;<

  mov esi, [cur_thread]			; ESI = cur thread
  mcheck_thread esi			;
  mov esi, [esi+thread.process]		; ESI = cur process
  mcheck_proc esi			;
  add esi, byte proc.info		; ESI = ptr to process info
  retn					;

%ifdef _MAGIC_CHECKS_
.magic_error:
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE0002
%endif

;                                           -----------------------------------
;                                                            thread.clear_stack
;==============================================================================

globalfunc thread.clear_stack
;>
;; This clears everything off your stack except for the final return address.
;; For when you came from somewhere, and you never want to go back :P
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EAX = destroyed
;; ESP = back to top
;; all other registers unmodified
;<

  mov eax, [cur_thread]			; EAX = cur thread
  mov eax, [eax+thread.stack_base]	; EAX = base of cur stack
  add eax, DEF_STACK_SIZE-4		; EAX = top of stack
  xchg esp, eax				; EAX = old stack
  push dword[eax]			; push return address
  retn					; return

; The fancy return address dancing is done so that the retn pairs with the call
; on an athlon. Also, a ptr to thread.kill_self is left on the stack always,
; hence the DEF_STACK_SIZE-4

;                                           -----------------------------------
;                                                               thread.get_self
;==============================================================================

globalfunc thread.get_self
;>
;; get some!
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EAX = thread ID of calling thread
;; all other registers unmodified
;<

  mov eax, [cur_thread]			;
  retn					;

;                                           -----------------------------------
;                                                              process.get_self
;==============================================================================

globalfunc process.get_self
;>
;; get some more!
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EAX = process ID of calling process
;; all other registers unmodified
;<

  mov eax, [cur_thread]			; EAX = cur thread
  mov eax, [eax+thread.process]		; EAX = cur process
  retn					;

;                                           -----------------------------------
;                                                    thread.kill_others_in_proc
;==============================================================================

globalfunc thread.kill_others_in_proc
;>
;; Kill all the other threads in a proc, except the one that calls this
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; regisers and errors as usual
;<

  dbg lprint {"thread_kill_others_in_proc called",0xa}, DEBUG
  mov eax, [cur_thread]			; EAX = cur thread
					;
					; kill all the previous threads
					;------------------------------
  call thread.enter_critical_section	; so no one creates new threads on us
  mov eax, [eax+thread.proc_prev]	; EAX = 1st prev thread
  test eax, eax				; if EAX = 0 there are no prev.
  jz .prev_killed			;   threads so we are half done
.kill_prev:				;
  call thread.kill			; DIE!
  jc .retn				;
  mov eax, [eax+thread.proc_prev]	; EAX = next prev thread
  test eax, eax				; if it's not zero there are more to
  jnz .kill_prev			;   kill >:}
.prev_killed:				;
					; kill all the next threads
					;--------------------------
  mov eax, [cur_thread]			; EAX = cur thread
  mov eax, [eax+thread.proc_next]	; EAX = ptr to 1st next thread
  test eax, eax				; if EAX = 0 there are no next
  jz .retn				;   threads so we are done
.kill_next:				;
  call thread.kill			; PSCHEWW!
  jc .retn				;
  mov eax, [eax+thread.proc_next]	; EAX = next next thread
  test eax, eax				; kill more until we hit a null ptr
  jnz .kill_next			;
.retn:					;
  call thread.leave_critical_section	;
  retn					;

;                                           -----------------------------------
;                                                 thread.enter_critical_section
;==============================================================================

globalfunc thread.enter_critical_section
;>
;;
;<

  dbg lprint {"thread.enter_critical_section called",0xa}, DEBUG
  cmp dword[crit_sect_depth], byte 0	; if we are already in a crit sect
  jnz .not_1st				;   skip saving the flags
  pushfd				; save our flags so if IF=0 when we
  pop dword [crit_sect_flags]		;   entered it isn't set when we leave
.not_1st:				;
  cli					; leave us alone!
  inc dword[crit_sect_depth]		; a level deeper...
  retn					;

;                                           -----------------------------------
;                                                 thread.leave_critical_section
;==============================================================================

globalfunc thread.leave_critical_section
;>
;;
;<

  dbg lprint {"thread.leave_critical_section called",0xa}, DEBUG
  dec dword[crit_sect_depth]		; if we are more than 1 level deep
  jnz .still_critical			;   don't restore the flags
  push dword[crit_sect_flags]		;
  popfd					; restore flags
.still_critical:			;
  retn					;

;                                           -----------------------------------
;                                                             thread.yield_self
;==============================================================================

globalfunc thread.yield_self
;>
;; Forfit the rest of your CPU time to the next thread. If there is some event
;; like a callback or an interupt (you are not polling something) it is better
;; to use thread.sleep_self and have the interupt or callback wake the thread
;; back up.
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EAX = destroyed
;; everything else = unmodified (including flags)
;<
					; make the stack match iretd
					;---------------------------
  pop eax				; pop EIP
  pushfd				; push flags
  push cs				; push CS
  push eax				; push EIP
  pushad				; push all registers
  mov ebx, [cur_thread]			; EBX = cur thread
  mcheck_thread ebx			;
  cli					; leave us alone please
  mov [ebx+thread.esp], esp		; save esp
%ifdef _EIP_CHECKS_			;
  mov [ebx+thread.eip], eax		; save copy of EIP
%endif					;
  mov ebx, [ebx+thread.next]		; EBX = next thread
  mcheck_thread ebx			;
  mov esp, [ebx+thread.esp]		; ESP = TOS of next thread
  popad					; restore registers
  iretd					; go to it

%ifdef _MAGIC_CHECKS_
.magic_error:
  dmej 0x7EDE0013
%endif

;                                           -----------------------------------
;                                                                 thread.create
;==============================================================================

globalfunc thread.create
;>
;; general use registers = passed on to thread
;; TOS = address where to start execution of new thread (EIP)
;;  +4 = scheduling priority
;;  +8 = flags (just 0 for now, but later will indicate FPU usage)
;;
;; requires at least 128 bytes of additional free stack
;;
;; returned values:
;; ----------------
;; EAX = thread id of newly created thread
;; stack is cleared
;; errors and registers as usual
;<

  dbg lprint {"thread.create called",0xa}, DEBUG
  pushad				; save all registers
					;
					; create new thread
					;------------------
  mov ebp, [esp+36]			; EBP = starting EIP
  call _create_thread			; EBX = new thread
  jc .error				; NOTE: in critical section now
					;
					; add thread to cur. process
					;---------------------------
  mov eax, [cur_thread]			; EAX = curent thread
  mcheck_thread eax			;
  mov eax, [eax+thread.process]		; EAX = curent process
  mcheck_proc eax			;
  mov ecx, [eax+proc.threads]		; ECX = first thread in proc chain
  mcheck_thread ecx			;
  xor esi, esi				; ESI = 0
  mov [ebx+thread.process], eax		; new thread -> process
  mov [eax+proc.threads], ebx		; new thread is new root in thread list
  mov [ebx+thread.proc_next], ecx	; old root is next node
  mov [ecx+thread.proc_prev], ebx	; old root's prev is new node
  mov [ebx+thread.proc_prev], esi	; zero prev pointer of new node
					;
					; make final touches to new thread
					;---------------------------------
  mov eax, [esp+40]			; EAX = priority
  mov ecx, [esp+44]			; ECX = flags
  mov [ebx+thread.priority], al		;
  mov [ebx+thread.flags], ecx		;
					; done
					;-----
  call thread.leave_critical_section	;
  mov [esp+28], ebx			; return our ebx in eax (thread id)
  clc					;
.error:					;
  popad					;
  retn 12				;

%ifdef _MAGIC_CHECKS_
.magic_error:
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE0003
%endif

;                                           -----------------------------------
;                                                                   thread.kill
;==============================================================================

%ifdef _MAGIC_CHECKS_
thread.kill.magic_error:
  dmej 0x7EDE0004
%endif

globalfunc thread.kill
;>
;; Kill a specified thread. If thread specified is the currently running
;; thread, the control will be pased to the thread.kill_self function (of
;; course if that happens this function will never return ;) )
;;
;; parameters:
;; -----------
;; EAX = thread id
;;
;; returned values:
;; ----------------
;; errors and registers as usual
;<

  dbg lprint {"thread.kill called",0xa}, DEBUG
  mcheck_thread eax

  cmp eax, [cur_thread]			; redirect call if killing curent
  jz near thread.kill_self		;   thread
					;
  dec dword[thread_count]		; one down...
  jz near _no_threads			; and hopefully there are some left
					;
  push edx				; save used registers
  push ebx				;
					;
  call thread.enter_critical_section	;
  mov edx, [eax+thread.next]		; EDX = next thread
  mcheck_thread edx			;
  mov ebx, [eax+thread.prev]		; EBX = prev. thread
  mcheck_thread ebx			;
					; remove thread from active loop
					;-------------------------------
  mov [ebx+thread.next], edx		; we can assume there's at least 1
  mov [edx+thread.prev], ebx		; other thread
					;
					; remove thread from process
					;---------------------------
  mov edx, [eax+thread.proc_next]	; EDX = next thread in proc
  mov ebx, [eax+thread.proc_prev]	; EBX = prev thread in proc
  test edx, edx				; skip linking if there is no next
  jz .no_proc_next			;   thread in the proc
  mov [edx+thread.proc_prev], ebx	; next->prev
.no_proc_next:				;
  test ebx, ebx				; skip linking if there is no prev
  jz .no_proc_prev			;   thread in the proc
  mov [ebx+thread.proc_next], edx	; prev -> next
					;
.done_removing:				;
  call thread.leave_critical_section	; we are done messing with active data
					;
  pop ebx				; restore used registers
  pop edx				;
					; clean up thread
					;----------------
  mov eax, [eax+thread.stack_base]	; EAX = base of thread's stack
  test eax, eax				; if it's zero, don't dealloc it
  jz .skip_stack_dealloc		;
  externfunc mem.dealloc		; deallocate stack
  jc .retn				;
.skip_stack_dealloc:			;
  push edi				;
  mov edi, [thread_memspace]		; EDI = ptr to thread memory space
  externfunc mem.fixed.dealloc		; deallocate thread struc
  pop edi				;
					;
.retn:					;
  retn					;

.kill_last_in_proc:			;
  dmej 0x7EDE0006			;

.no_proc_prev:
  test edx, edx				; if there is no next either we are
  jz .kill_last_in_proc			;   killing the last thread in the proc
  mov edx, [eax+thread.process]		; EDX = ptr to process
  mcheck_proc edx			;
  mov [edx+proc.threads], ebx		; make next thread new root
  jmp short .done_removing		;

;                                           -----------------------------------
;                                                              thread.kill_self
;==============================================================================

globalfunc thread.kill_self
;>
;; arakiri!
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; be realistic ;)
;<

  dbg lprint {"thread.kill_self called",0xa}, DEBUG

  dec dword[thread_count]		; one less scumbag in the world
  jz near _no_threads			;
  mov ecx, eax				; save EAX of thread; we may need it if
  cli					;   we have to terminate the process
					;
					; get prev & next & cur threads
					;------------------------------
  mov ebx, [cur_thread]			; EBX = cur thread that we are removing
  mcheck_thread ebx			;
  mov esi, [ebx+thread.process]		; ESI = cur process
  mcheck_proc esi			;
  mov edx, [ebx+thread.prev]		; EDX = prev. thread
  mcheck_thread edx			;
  cmp edx, ebx				; if the prev pointer points back to
  jz .kill_last_thread			;   the cur thread there is only 1
  mov eax, [ebx+thread.next]		; EAX = next thread
  mcheck_thread eax			;
					; remove thread from active loop
					;---------------------------------
  mov [edx+thread.next], eax		;
  mov [eax+thread.prev], edx		;
					; switch to next context
.switch_context:			;-----------------------
  mov [cur_thread], eax			;
  mov esp, [eax+thread.esp]		;
					; clean up thread
					;----------------
  mov eax, [ebx+thread.stack_base]	; EAX = base of cur. stack
  test eax, eax				; if it's zero, skip deallocating it
  jz .skip_stack_dealloc		;
  externfunc mem.dealloc		; deallocate stack
.skip_stack_dealloc:			;
  mov eax, ebx				; EAX = cur thread
  mov edi, [thread_memspace]		; EDI = thread memspace
  externfunc mem.fixed.dealloc		; dealloc thread struc
					;
					; remove thread from process
					;---------------------------
  mov ebp, [ebx+thread.proc_next]	; EBP = next thread in proc
  mov edx, [ebx+thread.proc_prev]	; EDX = prev thread in proc
  test ebp, ebp				;
  jz .no_proc_next			; if there's no next skip linking it
  mov [ebp+thread.proc_prev], edx	; next -> prev
.no_proc_next:				;
  test edx, edx				; if there's no prev, skip linking it
  jz .no_proc_prev			;   and update the process root thread
  mov [edx+thread.proc_next], ebp	; prev -> next

  popad
  iretd					; goodbye cruel world!

%ifdef _MAGIC_CHECKS_
.magic_error:
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE0007
%endif

.kill_last_thread:
  mov eax, idle_thread			; EAX = idle_thread
  mov esp, [idle_thread+thread.stack_base]
  add esp, DEF_STACK_SIZE		; ESP = top of idle stack
  push dword 0x00000202			; push flags
  push cs				; push cs
  push dword _idle			; push eip
  sub esp, byte 32			; pseudo-pushad
  mov [eax+thread.esp], esp		; save esp
%ifdef _EIP_CHECKS_			;
  mov dword[eax+thread.eip], _idle	;
%endif					;
  jmp short .switch_context		;

.no_proc_prev:
  mov esi, [ebx+thread.process]		; ESI = cur process
  mcheck_proc esi			;
  test ebp, ebp				; if ebp (next) is also null, there
  jz .kill_last_in_proc			;   are no other nodes
  mov [esi+proc.threads], ebp		; update root thread
  popad					;
  iretd					; go to next thread

.kill_last_in_proc:
  ; ESI = cur process
  ; ECX = exit status (what was in EAX when this function was called)
  dbg lprint {"strontium: terminating process with status %d",0xa}, DEBUG, ecx

					; take process out of process list
					;---------------------------------
  mov ebx, [esi+proc.prev]		; EBX = prev process
  mov ebp, [esi+proc.next]		; EBP = next process
					;
  test ebp, ebp				;
  jz .no_next				;
  mov [ebp+proc.prev], ebx		; next -> prev
.no_next:				;
  test ebx, ebx				;
  jz .no_prev				;
  mov [ebx+proc.next], ebp		; prev -> next
  jmp short .removed			;
.no_prev:				;
  mov [processes], ebp			; update root thread in process
.removed:				;
					; clean up process
					;-----------------
  mov edi, [proc_memspace]		; EDI = process memspace
  mov eax, esi				; EAX = ptr to process
  externfunc mem.fixed.dealloc		; dealloc process struc
					;
  mov ebp, [esi+proc.callback]		; EBP = callback
  test ebp, ebp				;
  jz .no_callback			; if it's zero, skip it
  					;
  mov ebx, esi				; EBX = process
  mov eax, ecx				; EAX = exit status
  call ebp				;
					;
.no_callback:				;
  popad					;
  dbg lprint {"strontium: process terminated",0xa}, DEBUG
  iretd					;

;                                           -----------------------------------
;                                                                process.create
;==============================================================================

globalfunc process.create
;>
;; parameters:
;; -----------
;; EAX = ptr to callback func to call when process terminates, or 0 for none
;; EBX = ptr to process_info struc (see uuu/include/proc.inc)
;; ECX = number of args
;; EDI = ptr to array of pointers to args
;; ESI = ptr to string of file to execute
;;
;; returned values:
;; ----------------
;; EBX = process ID of created process
;; errors and registers as usual
;;
;; arg[0] is the name the command was invoked as, so if you give no args to
;; a program ECX = 1.
;;
;; The process info is copied, so it must only be valid until this function
;; returns, at which point it can be maimed, mangled, or mutilated, or even
;; deallocated.
;;
;; callback function:
;; ------------------
;; use this to monitor when the created process termitates. The function will
;; be called with these parameters:
;;   EAX = return status of process, this is what's in EAX when the last thread
;;           terminates or one of the threads calls proc.kill_self
;;   EBX = process ID of terminated process
;; the registers may be destroyed on return. The callback must remain valid for
;; the entire life of the calling proc. When the parent process terminates
;; (the one that called this function), the callback will be set to 0.
;<

  dbg lprint {"process.create called",0xa}, DEBUG
  pushad				; save registers
  pushad				; save regs again for _create_thread
					;
  					; allocate memory for process
					;----------------------------
  mov edi, [proc_memspace]		;
  externfunc mem.fixed.alloc		;
  jc near .error			;
%ifdef _MAGIC_CHECKS_			;
  mov dword[edi+proc.magic], PROC_MAGIC	; fill out magic field
%endif					;
  push edi				;
					;
					; link up the file
					;-----------------
  mov edi, [esp+36]			; EDI = edi (argv) from call
  externfunc file.link			;
  jc near .pop1error			;
  mov [esp+4], edi			; put our edi in thread's edi
					;
					; set up process info
					;--------------------
  pop edi				; EDI = ptr to process
  mov [esp+28], edi			; save ptr to process in thread's eax
  mov esi, [esp+32+16]			; ESI = ptr to source process info
  mov ecx, process_info_size / 4	; ECX = dwords in struc process_info
  add edi, byte proc.info		; EDI = ptr to process info of new proc
  mov [esp+16], edi			; put our edi in thread's ebx
  rep movsd				; copy src->dest
  sub edi, byte process_info_size	; EDI = ptr to process info again
  mov ecx, [esp]			; ECX = ptr to argv
  mov [edi+process_info.cleanup], eax	; save cleanup from file.link
  mov [edi+process_info.argv], ecx	; save ptr to argv
					;
					; create new thread and set it up
					;--------------------------------
  mov ebp, edx				; set starting eip from file.link's edx
  call _create_thread			; EBX = ptr to new thread
  jc .error				;
%ifdef _EIP_CHECKS_			;
  mov [ebx+thread.eip], ebp		;
%endif					;
  xor edx, edx				; NOTE: in critical section now
  mov edi, [esp+28]			; EDI = ptr to process
  mov [ebx+thread.proc_next], edx	; zero out the process thread list
  mov [ebx+thread.proc_prev], edx	;   pointers
  mov [ebx+thread.process], edi		; fill process field
  mov [ebx+thread.flags], edx		;
					;
					; put finishing touches on process
					;---------------------------------
  mov eax, [esp+32+28]			; EAX = ptr to callback; eax from call
  mov [edi+proc.threads], ebx		;
  mov [edi+proc.callback], eax		;
  mov [edi+proc.children], edx		;
  mov [edi+proc.flags], edx		;
  mov eax, [processes]			; EAX = root node of process list
  mov [edi+proc.next], eax		; add our node
  mov [edi+proc.prev], edx		;
  test eax, eax				;
  jz .no_processes			;
  mov [eax+proc.prev], edi		;
.no_processes:				;
  mov [processes], edi			;
					; done; clean up and return
					;--------------------------
  call thread.leave_critical_section	; whee!
  add esp, byte 32			;
  popad					; restore registers
  retn					;

.pop1error:
  add esp, byte 4
.error:
  add esp, byte 32
  mov [esp+28], eax
  popad
  stc
  retn

;                                           -----------------------------------
;                                                             process.kill_self
;==============================================================================

globalfunc process.kill_self
;>
;; Kills the current process and all it's threads.
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; NEVER :P
;<

  dbg lprint {"process.kill_self called",0xa}, DEBUG
  push eax				; save exit code
  call thread.kill_others_in_proc	; kill everyone else
  pop eax				; restore exit code
  call thread.kill_self			; NOW we can kill ourself :)

;                                           -----------------------------------
;                                                             thread.sleep_self
;==============================================================================

globalfunc thread.sleep_self
;>
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EAX = destroyed
;; everything else (including flags) unmodified
;<

  dbg lprint {"thread.sleep_self called",0xa}, DEBUG
					; save state of curent thread
					;----------------------------
  pop eax				; pop EIP
  pushfd				; push flags
  push cs				; push cs
  push eax				; push EIP
  pushad				; push all registers
  mov ebx, [cur_thread]			; EBX = cur thread
  mcheck_thread ebx			;
  mov [ebx+thread.esp], esp		; save ESP
%ifdef _EIP_CHECKS_			;
  mov [ebx+thread.eip], eax		; save EIP
%endif					;
					; get next and prev threads
					;--------------------------
  cli					; playing with data strucs, hold on
  mov eax, [ebx+thread.next]		; EAX = next thread
  mcheck_thread eax			;
  cmp eax, ebx				; if the next pointer points back to
  jz .sleep_last			;   the cur thread there is 1 active
  mov edx, [ebx+thread.prev]		; EDX = prev thread
  mcheck_thread edx			;
					;
					; take cur thread out of active loop
					;-----------------------------------
  mov [edx+thread.next], eax		; prev -> next
  mov [eax+thread.prev], edx		; next -> prev
  					;
					; add cur thread to sleeping list
.add_to_sleep_list:			;--------------------------------
  xor edx, edx				; EDX = 0
  mov ecx, [sleeping_threads]		; ECX = root sleeping node
  mov [ebx+thread.prev], edx		; no prev sleeping thread
  mov [ebx+thread.next], ecx		; old root is next sleeping thread
  test ecx, ecx				;
  jz .none_sleeping			; skip linking if there was no old root
  mov [ecx+thread.prev], ebx		; link root -> cur
.none_sleeping:				;
  or dword[ebx+thread.flags], THREAD_F_SLEEPING	; mark as sleeping
  mov [sleeping_threads], ebx		; cur thread is new root sleeping
					;
					; activate next thread
					;---------------------
  mov [cur_thread], eax			; update cur_thread
  mov esp, [eax+thread.esp]		; switch to new stack
					;
%ifdef _DEBUG_				;
  call _dump_threads			;
%endif					;
					;
  popad					; restore registers of new thread
  iretd					; go to it!

%ifdef _MAGIC_CHECKS_
.magic_error:
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE0009
%endif

.sleep_last:				;
  mov eax, idle_thread			; next thread = idle_thread
  mov esp, [idle_thread+thread.stack_base]
  add esp, DEF_STACK_SIZE		; use idle thread's stack
  push dword 0x00000202			; push flags
  push cs				; push CS
  push dword _idle			; push EIP
  sub esp, byte 32			; act like we did pushad
  mov [idle_thread+thread.esp], esp	; save esp
  jmp short .add_to_sleep_list		;

;                                           -----------------------------------
;                                                                   thread.wake
;==============================================================================

globalfunc thread.wake
;>
;; parameters:
;; -----------
;; EAX = thread id
;;
;; returned values:
;; ----------------
;; all registers unmodified
;<

  dbg lprint {"thread.wake called: waking thread at 0x%x",0xa}, DEBUG, eax
  mcheck_thread eax
  test dword[eax+thread.flags], THREAD_F_SLEEPING
  jz .retn				; if it's already awake, cool :P
					;
  push ebx				;
  push ecx				;
  call thread.enter_critical_section	;
					;
  mov ebx, [eax+thread.next]		; EBX = next thread
  mov ecx, [eax+thread.prev]		; ECX = prev thread
					;
					; remove thread from sleeping list
					;---------------------------------
  test ebx, ebx				;
  jz .no_next				; jmp if next pointer is null
  mcheck_thread ebx			;
  mov [ebx+thread.prev], ecx		; link next -> prev
.no_next:				;
  test ecx, ecx				;
  jz .no_prev				; jmp if prev pointer is null
  mcheck_thread ecx			;
  mov [ecx+thread.next], ebx		; link prev -> next
					;
					; add thread to active loop
.add_to_active_loop:			;--------------------------
  mov ecx, [cur_thread]			; ECX = cur thread
  mcheck_thread ecx			;
  mov ebx, [ecx+thread.next]		; EBX = next thread
  mcheck_thread ebx			;
  mov [ecx+thread.next], eax		; cur -> new
  mov [ebx+thread.prev], eax		; next -> new
  mov [eax+thread.next], ebx		; new -> next
  mov [eax+thread.prev], ecx		; new -> cur
					;
  call thread.leave_critical_section	;
  pop ecx				;
  pop ebx				;
					;
.retn:					;
  dbg call _dump_threads		;
  retn					;
					;
.no_prev:				;
  mov [sleeping_threads], ebx		; no prev, so next is new root
  jmp short .add_to_active_loop		;
					; let's hope we never have to use this
					;-------------------------------------
%ifdef _MAGIC_CHECKS_			;
.magic_error:				;
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE000B			;
%endif					;

;                                           -----------------------------------
;                                                                 _dump_threads
;==============================================================================

%ifdef _DEBUG_
_dump_threads:		; dumps the contents of the active and sleeping thread
			; lists to the DEBUG log
  pushad
  pushfd
  cli

  lprint {"ACTIVE LOOP",0xa}, DEBUG
  mov eax, [cur_thread]
  mcheck_thread eax
  mov edx, eax
.loop_active:
  lprint {" %x",0xa}, DEBUG, edx
  mov ebx, [edx+thread.next]
  mcheck_thread ebx
  cmp [ebx+thread.prev], edx
  jnz .bad_prev
  mov edx, ebx
  cmp edx, eax
  jnz .loop_active

  lprint {"SLEEPING LIST",0xa}, DEBUG
  mov eax, [sleeping_threads]
  test eax, eax
  jz .done
.loop_sleep:
  mcheck_thread eax
  lprint {" %x",0xa}, DEBUG, eax
  mov eax, [eax+thread.next]
  test eax, eax
  jnz .loop_sleep

.done:
  popfd
  popad
  retn

.magic_error:
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE0012

.bad_prev:
  lprint {"strontium: bad prev pointer in thread",0xa}, DEBUG
  dmej 0x7EDE0013

%endif

;                                           -----------------------------------
;                                                                         _idle
;==============================================================================

_idle:
  dbg lprint {"strontium: entering idle loop",0xa}, DEBUG
.loop:
  cmp dword[idle_thread+thread.next], idle_thread
  jz .loop				; wait for another thread to be linked
					;
					; remove idle thread from active loop
					;------------------------------------
  cli					;
  mov eax, [idle_thread+thread.next]	; EAX = next thread
  mov ebx, [idle_thread+thread.prev]	; EBX = prev thread
  dbg lprint {"strontium: leaving idle loop; next: %x; prev: %x",0xa}, DEBUG, eax, ebx
  mov [eax+thread.prev], ebx		;
  mov [ebx+thread.next], eax		;
  mov [cur_thread], eax			;
  mov esp, [eax+thread.esp]		;
  mov dword[idle_thread+thread.next], idle_thread ; get ready for next use
  mov dword[idle_thread+thread.prev], idle_thread
  popad					;
  iretd					;

;                                           -----------------------------------
;                                                                  process.list
;==============================================================================

globalfunc process.list
;>
;; Gives a listing of all the existing processes
;;
;; parameters:
;; -----------
;; EAX = ptr to callback function
;;
;; returned values:
;; ----------------
;; registers as usual
;;
;; the callback function is called with:
;; -------------------------------------
;; EDX = process ID, or 0 to terminate listing
;; ESI = ptr to process info struc
;;
;; the callback function may return all registers destroyed.
;<

  call thread.enter_critical_section
  mov edx, [processes]
  lea esi, [edx+proc.info]
  push edx
  push eax
  call eax
  pop eax
  pop edx
  test edx, edx
  jz .done
.next:
  mov edx, [edx+proc.next]
  lea esi, [edx+proc.info]
  push edx
  push eax
  call eax
  pop eax
  pop edx
  test edx, edx
  jnz .next
.done:
  call thread.leave_critical_section
_create_thread.error:
  retn

;                                           -----------------------------------
;                                                                _create_thread
;==============================================================================

_create_thread:
;; parameters:
;; -----------
;; TOS = registers to pass on to thread, pushad style
;; EBP = starting EIP
;;
;; returned values:
;; ----------------
;; EBX = ptr to new thread
;; EBP = unmodified
;; all other registers = destroyed
;; errors as usual
;;
;; this fills in the scheduling and magic info, but the proc_*, process, flags,
;; and priority fields are unfilled.
;;
;; if this function exits with an error, the thread was not created and the
;; critical section is not entered.
;;
;; note: this function enters a critical section when needed; the calling
;; function should call thread.leave_critical_section after it's done.

					; allocate memory for thread struc
					;---------------------------------
  mov edi, [thread_memspace]		; EDI = thread memory space
  externfunc mem.fixed.alloc		; EDI = ptr to new thread
  jc .error				;
					;
%ifdef _MAGIC_CHECKS_			;
  mov dword[edi+thread.magic], THREAD_MAGIC
%endif					;
					; allocate stack for new thread
					;------------------------------
  mov ebx, edi				; EBX = ptr to new thread
  mov ecx, DEF_STACK_SIZE		; ECX = stack size
  externfunc mem.alloc			; EDI = ptr to thread's stack
  jc .error				;
  mov [ebx+thread.stack_base], edi	; save stack base address
  lea edi, [edi+eax-48]			; EDI = ptr to TOS with room for stuff
  mov [ebx+thread.esp], edi		; save ESP
					;
					; fill in starting values on the stack
;-----------------------------------------------------------------------------
; we want this:						|
; TOS edi	+24 ecx					|
;  +4 esi	+28 eax					|
;  +8 ebp	+32 starting eip			|
; +12 ---	+36 cs					|
; +16 ebx	+40 starting eflags (all clear but IF)	|
; +20 edx	+44 return point, thread.kill_self	|
;--------------------------------------------------------
  mov dword[edi+44], thread.kill_self	; if the thread does a retn, kill it
  mov dword[edi+40], 0x00000202		; set start EFLAGS to all 0 except IF
  mov dword[edi+36], 0x00000008		; CS = 8
  mov dword[edi+32], ebp		; starting EIP
  mov eax, [esp+4]			; EAX = starting EDI
  mov ecx, [esp+8]			; ECX = starting ESI
  mov edx, [esp+12]			; EDX = starting EBP
  mov [edi], eax			; edi
  mov [edi+4], ecx			; esi
  mov [edi+8], edx			; ebp
  mov eax, [esp+20]			; EAX = starting EBX
  mov ecx, [esp+24]			; ECX = starting EDX
  mov edx, [esp+28]			; EDX = starting ECX
  mov esi, [esp+32]			; ESI = starting EAX
  mov [edi+16], eax			; ebx
  mov [edi+20], ecx			; edx
  mov [edi+24], edx			; ecx
  mov [edi+28], esi			; eax
					;
					; add thread to active loop
					;--------------------------
  call thread.enter_critical_section	; because we screw the data structures
  mov eax, [cur_thread]			; EAX = ptr to current thread
  mcheck_thread eax			;
  mov edx, [eax+thread.next]		; EDX = ptr to next thread
  mcheck_thread edx			; insert new thread between cur. and next
  mov [ebx+thread.next], edx		; new -> next
  mov [ebx+thread.prev], eax		; new -> cur
  mov [eax+thread.next], ebx		; cur -> new
  mov [edx+thread.prev], ebx		; next -> new
  inc dword[thread_count]		; inc total thread count
  clc					; no error
  dbg lprint {"created thread at 0x%x",0xa}, DEBUG, ebx
  retn					; done

.magic_error:
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE000C

; .error is in the function above this

;                                           -----------------------------------
;                                                                   _no_threads
;==============================================================================

_no_threads:
  lprint {"All threads have been killed; press enter to reboot",0xa}, FATALERR
  externfunc debug.diable.wait
  mov al, 0xFE
  out 0x64, al
  mov al, 0x01
  out 0x92, al
; should have rebooted, but lock to be sure
  cli
  hlt

;                                           -----------------------------------
;                                                                _timer_handler
;==============================================================================

_timer_handler:
; TODO: update timer stuff to handle 32 bit rollover

  pushad				; save registers
%ifdef _VISUAL_ACTIVITY_		;
  inc dword [0xb8000 + 0xA0 - 4]	;
%endif					;
					; increment the tick count
					;-------------------------
  inc dword[timer.tick_count]		; increment the LSW
  jc near .tick_overflow			; if it rolls over, inc the MSW
.tick_done:				;
					; check for timer expirations
					;----------------------------
  mov edx, [timers]			; EDX = ptr to root timer
.check_timer:				;
  test edx, edx				; if timer is zero there are no timers
  jz .timers_done			;   so we are done
  mcheck_timer edx			; (check magic)
  mov eax, [timer.tick_count]		; EAX = tick count
  cmp [edx+timer.expire], eax		; compare expire time with tick count
  jne .timers_done			; if they arn't equal we are done
  mov ebp, [edx+timer.rememberme]	; restore saved value
  push edx				; save curent timer
  call [edx+timer.callback]		; call the callback
  pop eax				; EAX = curent timer (just expired)
  mov edx, [eax+timer.next]		; EDX = next timer
  mov edi, [timer_memspace]		; EDI = timer memspace
  externfunc mem.dealloc		; deallocate the timer struc
  test edx, edx				; if the next node is 0
  jz .timers_done			;   no more timers, take a break
  mov dword[edx+timer.prev], 0		; zero prev ptr of next timer
  jmp short .check_timer		; check next timer for expiration
					;
.timers_done:				;
  mov [timers], edx			; save new root timer
					; switch to next thread
  mov eax, [cur_thread]			; EAX = cur thread
  mcheck_thread eax			; (check magic)
					;
%ifdef _EIP_CHECKS_			;
  mov ebx, [esp+32]			; (save eip)
  mov [eax+thread.eip], ebx		;
%endif					;
					;
%ifdef _SHOW_THREAD_COUNT_		;
  xor ecx, ecx				; ECX = 0
  mov ebx, eax				; EBX = cur thread
.find_num:				;
  inc ecx				; inc count of threads
  mov ebx, [ebx+thread.next]		; EBX = next thread
  cmp ebx, eax				; compare next with first thread
  jnz .find_num				; loop until we find the first thread
  dme ecx				; display the count
%endif	; %ifdef _SHOW_THREAD_COUNT_	;
					;
  mov [eax+thread.esp], esp		; save esp
  mov eax, [eax+thread.next]		; EAX = next thread
  mcheck_thread eax			; (check magic)
  mov esp, [eax+thread.esp]		; switch to new stack
  mov [cur_thread], eax			; cur_thread = eax now
					;
%ifdef _EIP_CHECKS_			;
  mov ebx, [eax+thread.eip]		; EBX = saved eip of thread
  test ebx, ebx				;
  jz .skip_eip_check			; if it's zero skip it with a warning
  cmp ebx, [esp+32]			; compare the eips
  jnz .eip_error			; if they don't match, that's bad
.eip_done:				;
%endif					;
					; done, send EOI
					;---------------
  mov al, 0x60				;
  out 0x20, al				;
  popad					; restore registers
  iretd					;

.tick_overflow:				; used when LSW of timer count overflows
  inc dword[timer.tick_count+4]		; inc MSW
  jmp near .tick_done			;

%ifdef _MAGIC_CHECKS_
.magic_error:
  lprint {"strontium: bad magic",0xa}, FATALERR
  dmej 0x7EDE000D
%endif

%ifdef _EIP_CHECKS_
.eip_error:
  mov ecx, [esp+32]
  lprint {"strontium: eip mismatch: 0x%x in thread struc, 0x%x on stack",0xa}, FATALERR, ebx, ecx
  dmej 0x7EDE000E

.skip_eip_check:
  lprint {"strontium: skiping eip check",0xa}, DEBUG
  jmp short .eip_done
%endif

;                                           -----------------------------------
;                                                                          data
;==============================================================================

section .data
align 4, db 0

timer.tick_count:	dd 0, 0
vglobal timer.tick_count
proc_memspace:		dd 0
thread_memspace:	dd 0
timer_memspace:		dd 0
ll_memspace:		dd 0	; 8 byte linked list mem.fixed space
cur_thread:		dd 0	; ptr to current thread; always valid
sleeping_threads:	dd 0	; ptr to first sleeping thread or 0 for none
crit_sect_depth:	dd 0
crit_sect_flags:	dd 0
thread_count:		dd 0	; number of existant threads, active or not
processes:		dd 0	; ptr to first process in chain
timers:			dd 0	; ptr to root timer (next to expire)

init_argv:		dd init_name, 0

idle_thread: istruc thread
%ifdef _MAGIC_CHECKS_
at thread.magic,	dd THREAD_MAGIC
%endif
at thread.next,		dd idle_thread
at thread.prev,		dd idle_thread
iend

init_name:		db "init",0
