
struc _thread_t			; ----- ; -------------------------------------
res32	.process_id		; 00-03 ; ID of parent process
res32	.next			; 04-07 ; next thread in queue
res32	.previous		; 08-0B ; previous thread in queue
res32	.stack_top		; 0C-0F ; TOS (ESP)
res0	.priority		; 10-13 ; PS: Priority Assigned
res64	.startline		; 10-13 ; HRA: start time
res32	.runlength		; 18-1B ; HRA: number of microseconds of execution
res32	.schedule_callback	; 1C-1F ; HRA: callback for rescheduling
res32	.timer_handler		; 20-23 ; PS/HRA timer handler
res32	.locked_mutexes		; 24-27 ; List of locked mutexes
res32	.used_resources		; 28-2B ; List of used resources
endstruc			; ----- ; -------------------------------------



%define THRD(x,y,z) byte x + y + _thread_t. %+ z
