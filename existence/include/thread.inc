
%include "vid/tsa.inc"


%macro ENTER_CRITICAL_SECTION 0.nolist
  pushfd
  cli
%endmacro

%macro LEAVE_CRITICAL_SECTION 0.nolist
  popfd
%endmacro



struc semaphore_t
  .count	resd 1
  .wait_queue	resd 1
endstruc


%define SEM(x)			x: times semaphore_t_size db 0
%define rSEM(x)			x: resb semaphore_t_size
%define SEM_INIT(x,y)		__SEM_INIT x, y
%define SEM_RELEASE_LOCK(x)	__SEM_RELEASE_LOCK x
%define SEM_ACQUIRE_LOCK(x)	__SEM_ACQUIRE_LOCK x
%define SEM_TRY_ACQUIRE_LOCK(x)	__SEM_TRY_ACQUIRE_LOCK x


%macro __SEM_INIT 2.nolist
%ifnidni %1, eax
  mov eax, %{1}
%endif
  mov dword [eax], %{2}
  mov dword [eax + semaphore_t.wait_queue], 0
%endmacro

%macro __SEM_RELEASE_LOCK 1.nolist
%ifnidni %1, eax
  mov eax, %{1}
%endif
  inc dword [eax]
  jg  short %%done
  externfunc sem.release_lock
%%done:
%endmacro


%macro __SEM_ACQUIRE_LOCK 1.nolist
%ifnidni %1, eax
  mov eax, %{1}
%endif
  dec dword [eax]
  jns short %%done
  externfunc sem.acquire_lock
%%done:
%endmacro


%macro __SEM_TRY_ACQUIRE_LOCK 1.nolist
%ifnidni %1, eax
  mov eax, %{1}
%endif
  dec dword [eax]
  clc
  jns short %%done
  externfunc sem.try_acquire_lock
%%done:
%endmacro




struc spinlock_t
.lock	resb 1
endstruc

%define SPIN(x) x: db 0
%define rSPIN(x) x: resb 1

%define SPIN_INIT(x)			__SPIN_INIT x
%define SPIN_INIT_LOCKED(x)		__SPIN_INIT_LOCKED x
%define SPIN_ACQUIRE_LOCK(x)		__SPIN_ACQUIRE_LOCK x
%define SPIN_ACQUIRE_IRQSAFE_LOCK(x)	__SPIN_ACQUIRE_IRQSAFE_LOCK x
%define SPIN_RELEASE_LOCK(x)		__SPIN_RELEASE_LOCK x
%define SPIN_RELEASE_IRQSAFE_LOCK(x)	__SPIN_RELEASE_IRQSAFE_LOCK x


%macro __SPIN_INIT 1.nolist
  mov byte [%1], 1
%endmacro

%macro __SPIN_INIT_LOCKED 1.nolist
  mov byte [%1], 0
%endmacro


%macro __SPIN_ACQUIRE_LOCK 1.nolist
; Locks a SPINLOCK (use only outside of IRQ handlers)
;
; REQUIRES:
;----------
; param 1: register holding pointer to spinlock
;
%%retry:
  dec byte [%1]
  jz short %%done
  inc byte [%1]
  externfunc tsa.yield
  jmp short %%retry
%%done:
  cli
%endmacro


%macro __SPIN_ACQUIRE_IRQSAFE_LOCK 1.nolist
; Locks a SPINLOCK within an IRQ handler
;
; REQUIRES:
;----------
; param 1: register holding pointer to spinlock
;
%%retry:
  dec byte [%1]
  jz short %%done
  inc byte [%1]
  jmp short %%retry
%%done:
%endmacro


%macro __SPIN_RELEASE_LOCK 1.nolist
; Unlocks a SPINLOCK (use only outside of IRQ handlers)
;
; REQUIRES:
;----------
; param 1: register holding pointer to spinlock
;
  inc byte [%1]
  sti
%endmacro


%macro __SPIN_RELEASE_IRQSAFE_LOCK 1.nolist
; Unlocks a SPINLOCK within an IRQ handler
;
; REQUIRES:
;----------
; param 1: register holding pointer to spinlock
;
  inc byte [%1]
%endmacro



HRA_CC_EXPIRED		EQU	0
HRA_CC_YIELD		EQU	1
HRA_CC_UNSCHEDULED	EQU	2


