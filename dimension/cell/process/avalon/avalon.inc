%if process_info_size <> 32
  %error "process_info is not 32 bytes"
%endif

struc _process_t
.stdhdr			resb process_info_size	; 32bytes, process_info struc
.next			resd 1	; 20-23	; next _process_t struc
.previous		resd 1	; 24-27	; previous _process_t struc
.threads		resd 1	; 28-2B	; linked list of _thread_t struc
.flags			resb 3	; 2C-2E	; various flags
.priority		resb 1	; 2F-2F	; default priority assigned to the threads
.started		resd 2	; 30-37	; uuu-time at which this task was started
.granted		resd 2	; 38-3F	; # of microseconds used by this tasked
endstruc

struc _thread_t
.next_queue		resd 1	; 00-03	; next thread in this queue
.prev_queue		resd 1	; 04-07	; previous thread in this queue
.next_proc		resd 1	; 08-0B	; next thread of the owner process
.prev_proc		resd 1	; 0C-0F	; previous thread of the owner process
.owner_proc		resd 1	; 10-13	; pointer to owner _process_t struc
.stack_top		resd 1	; 14-17	; last ESP value (top of stack)
.stack_size		resd 1	; 18-1B	; allocated stack size
.stack_addr		resd 1	; 1C-1F	; allocated stack base address
.priority		resb 1	; 20-20	; running priority
.set_priority		resb 1	; 21-21	; assigned priority
.status			resb 1	; 22-22	; scheduled status
.flags			resb 1	; 23-23	; control flags
.mutexes		resd 1	; 24-27	; locked mutexes
.startline		resd 2	; 28-2F	; set start of execution (uuu-time)
.deadline		resd 2	; 30-37	; set end of execution (uuu-time)
.result_callback	resd 1	; 38-3B	; function to callback on termination
.interval		resd 1	; 3C-3F	; timer re-trigger interval
endstruc



struc _process_t_padded
.data			resb _process_t_size
.padding		resb 64-_process_t_size
endstruc

struc _thread_t_padded
.data			resb _thread_t_size
.padding		resb 64-_thread_t_size
endstruc




%assign _THRDF_FPU_CONTEXT_	0x80	; thread have a registered fpu context
%assign _THRDF_IND_PRIORITY_	0x40	; priority independant of process
%assign _THRDF_IDLE_		0x20	; thread is using only spare cycles
%assign _THRDF_UNINTERRUPTIBLE_	0x01	; thread is uninterruptible


%assign _THRDS_PAUSED_		0x00	; completed, waiting to be reset
%assign _THRDS_RUNNING_		0x01	; currenting running
%assign _THRDS_WAITING_		0x02	; waiting for mutex lock or signal
%assign _THRDS_SCHEDULED_	0x03	; waiting for scheduled time slice
%assign _THRDS_TIMEDOUT_	0x04	; did not complete before set deadline
%assign _THRDS_PENDING_		0x05	; waiting to be scheduled
%assign _THRDS_IDLE_		0x0F	; special idle thread


struc _specific_val_t
.thread			resd 1		; thread id for this specific
.value			resd 1		; value for this .thread
.next			resd 1		; pointer to next _specific_t
endstruc


struc _mutex_lock_t
.mutex			resd 1		; ptr to _mutex_t struc
.thread			resd 1		; ptr to _thread_t struc
.count			resd 1		; recursive count
.reserved		resd 1		; -
.next_of_thread		resd 1		; next _mutex_lock_t of .thread
.prev_of_thread		resd 1		; previous _mutex_lock_t of .thread
.next_of_mutex		resd 1		; next _mutex_lock_t of .mutex
.prev_of_mutex		resd 1		; previous _mutex_lock_t of .mutex
endstruc


; add a node to a ring list and mark this entry as the entry point.
;
; reg0 = pointer to ring head pointer
; reg1 = pointer to entry to add
; reg2 = scratch register
%macro RingInsert 3.nolist
  mov %3, [%1]
  mov [%1], %2
  test %3, %3
  jz short %%emptyring
  
  mov [%2 + _thread_t.next_queue], %3
  mov %1, [%3 + _thread_t.prev_queue]
  mov [%2 + _thread_t.prev_queue], %1
  mov [%3 + _thread_t.prev_queue], %2
  mov [%1 + thread_t.next_queue], %2
  jmp short %%end

%%emptyring:
  mov [%2 + _thread_t.prev_queue], %2
  mov [%2 + _thread_t.next_queue], %2
%%end:
%endmacro

; add a node to a ring list and mark this entry as the last to be executed
;
; reg0 = pointer to ring head pointer
; reg1 = pointer to entry to add
; reg2 = scratch register
%macro RingAppend 3.nolist
  mov %3, [%1]
  test %3, %3
  jz short %%emptyring
  
  mov [%2 + _thread_t.next_queue], %3
  mov %1, [%3 + _thread_t.prev_queue]
  mov [%2 + _thread_t.prev_queue], %1
  mov [%3 + _thread_t.prev_queue], %2
  mov [%1 + thread_t.next_queue], %2
  jmp short %%end

%%emptyring:
  mov [%1], %2
  mov [%2 + _thread_t.prev_queue], %2
  mov [%2 + _thread_t.next_queue], %2
%%end:
%endmacro
