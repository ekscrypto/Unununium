;; $Header: /cvsroot/uuu/uuu/src/cells/lib/maths/rng/parkmiller/parkmiller.asm,v 1.6 2001/12/09 23:54:35 instinc Exp $
;;
;; The generator is the "minimal standard" multiplicative linear congruential
;; generator of Park, S.K. and Miller, K.W., "Random Number Generators: Good
;; Ones are Hard to Find," * CACM 31:10, Oct. 88, pp. 1192-1201.
;;
;; assembly implementation by EKS - Dave Poirier
;;
;; The C equivalent sources are available from the reference site at:
;; http://www-sop.inria.fr/rodeo/personnel/Antoine.Clerget/ns/ns/nam-1.0a7/AllCode__.html
[bits 32]


section .text

%define multiplier	16807

%define N_SEEDS		64


section .data
;;
;; The following predefined seeds are evenly spaced around the 2^31 cycle.
;; Each is approximately 33,000,000 elements apart.
;;
predefined_seeds:
	dd 1973272912,	188312339,	1072664641,	694388766
	dd 2009044369,	934100682,	1972392646,	1936856304
	dd 1598189534,	1822174485,	1871883252,	558746720
	dd 605846893,	1384311643,	2081634991,	1644999263
	dd 773370613,	358485174,	1996632795,	1000004583
	dd 1769370802,	1895218768,	186872697,	1859168769
	dd 349544396,	1996610406,	222735214,	1334983095
	dd 144443207,	720236707,	762772169,	437720306
	dd 939612284,	425414105,	1998078925,	981631283
	dd 1024155645,	822780843,	701857417,	960703545
	dd 2101442385,	2125204119,	2041095833,	89865291
	dd 898723423,	1859531344,	764283187,	1349341884
	dd 678622600,	778794064,	1319566104,	1277478588
	dd 538474442,	683102175,	999157082,	985046914
	dd 722594620,	1695858027,	1700738670,	1995749838
	dd 1147024708,	346983590,	565528207,	513791680

section .text

globalfunc rng.park_miller_88.set_seed, 102
;>
;; see rng.set_seed
;;
;<
globalfunc rng.set_seed, 94
;;-----------------------------------------------------------------------------
;>
;; Sets the next seed to use, either using the local rng pre-calculated seed or
;; by providing a non-0 seed value directly.
;; 
;; parameters:
;;------------
;; eax = seed
;; ebx = type of seed requested
;;	0 = use provided seed as is
;;	other = use pre-defined seed
;;
;; returns:
;;---------
;;  eax = seed to use for rng input
;;  ebx = (unmodified)
;;  ecx = (unmodified)
;;  edx = (unmodified)
;;  esi = (unmodified)
;;  edi = (unmodified)
;;  esp = (unmodified)
;;  ebp = (unmodified)
;<

  or ebx, ebx
  jz .store_seed

  push edx
  push ebx
  xor edx, edx
  mov ebx, N_SEEDS
  div ebx
  mov eax, [edx*4 + predefined_seeds]
  pop ebx
  pop edx

.store_seed:
  retn


globalfunc rng.park_miller_88.get_32bit
;>
;; see rng.get_32bit
;;
;<
globalfunc rng.get_32bit
;;-----------------------------------------------------------------------------
;; The algorithm implemented is: Sn = (a*s) mod m. 
;; The modulus m can be approximately factored as: m = a*q + r, 
;;   where q = m div a and r = m mod a.
;;
;; Then Sn = g(s) + m*d(s)
;; where g(s) = a(s mod q) - r(s div q) 
;;   and d(s) = (s div q) - ((a*s) div m) 
;;
;; Observations:
;; - d(s) is either 0 or 1. 
;; - both terms of g(s) are in 0, 1, 2, . . ., m - 1.
;; - |g(s)| <= m - 1.
;; - if g(s) > 0, d(s) = 0, else d(s) = 1.
;; - s mod q = s - k*q, where k = s div q.
;;
;; Thus Sn = a(s - k*q) - r*k,
;;    if (Sn <= 0), then Sn += m.
;;
;; To test an implementation for A = 16807, M = 2^31-1, you should get the
;; following sequences for the given starting seeds:
;;
;; s0		00000001
;; s1		000041A7
;; s2		10D63AF1
;; s3		60B7ACD9
;; ...
;; s10000	3E345911
;; ...
;; s551246	000003EB
;;
;; It is important to check for s10000 and s551246 with s0=1, to guard against
;; overflow. 
;;
;; parameters:
;;------------
;; eax = last seed returned, or new seed to use
;;
;; returns:
;;---------
;; eax = random number (signed positive value)
;; ebx = (unmodified)
;; ecx = (unmodified)
;; edx = (unmodified)
;; esi = (unmodified)
;; edi = (unmodified)
;; esp = (unmodified)
;; ebp = (unmodified)

 push ecx
 mov ecx, eax				; ecx = seed
 and ecx, dword 0x0000FFFF		; ecx = seed & 0xFFFF
 shr eax, byte 16			; eax = seed >> 16
 imul ecx, dword multiplier		; ecx = (seed * 0xFFFF) * 16807 = L
 imul eax, dword multiplier		; eax = (seed >> 16) * 16807 = H
 push eax
 and eax, 0x7FFF			; eax = (H & 0x7FFF)
 shl eax, 16				; eax = (H & 0x7FFF) << 16
 add eax, ecx				; eax = ((H & 0x7FFF)<< 16) + L = seed
 sub eax, 0x7FFFFFFF			; seed = seed - 0x7FFFFFFFF
 pop ecx				; ecx = H
 shr ecx, byte 15			; ecx = H >> 15
 add eax, ecx				; seed = seed + (H >> 15)
 jg short .return_seed			; if seed > 0, jump
 add eax, dword 0x7FFFFFFF		; seed += 0x7FFFFFFFF
.return_seed:
 pop ecx
 retn
