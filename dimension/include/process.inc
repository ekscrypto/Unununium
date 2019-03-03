; $Header: /cvsroot/uuu/dimension/include/process.inc,v 1.2 2002/02/02 18:37:04 instinc Exp $

struc process_info
  .stdin:	resd 1
  .stdout:	resd 1
  .stderr:	resd 1
  .env:		resd 1	; ptr to the environment
  .argv:	resd 1	; ptr to orig. argv used
  .cleanup:	resd 1	; ptr to cleanup info; used by process.exec
endstruc

struc _mutex_t
.thread		resd 1
.waiters	resd 1
endstruc

struc _cond_t
.mutex		resd 1
.waiters	resd 1
endstruc

%define mutex(x)	x: times _mutex_t_size db 0
%define rmutex(x)	x: resb _mutex_t_size
%define cond(x)		x: times _cond_t_size db 0
%define rcond(x)	x: resb _cond_t_size
