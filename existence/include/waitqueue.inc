; Wait Queues definitions
; Copyright (C) 2002, Dave Poirier
; Distributed under the X11 License

%ifndef __WAITQUEUE_INC__
%define __WAITQUEUE_INC__


struc wait_queue_t
.flags		resd 1
.next		resd 1
.previous	resd 1
.queued_items	resd 1
endstruc

struc wait_queue_head_t
.lock		resd 1	; spinlock_t_size == 1, reserve 4 bytes for alignment
.next		resd 1
.previous	resd 1
endstruc

; note: the WAIT_QUEUE macro defines a wait_queue_head!
;
%define WAIT_QUEUE(x) x: times wait_queue_head_t_size db 0

%endif
