; vim: syntax=uuu

_lex:
;;
;; parameters:
;; -----------
;; none
;;
;; returned values:
;; ----------------
;; EAX = token
;; EDX = value
;;

  mov ebp, esp		; save esp; we will use the stack for saving our place
  mov esi, lex_table

.next_char:
  call _get_char
.test_node:
  debug_msg test_node
  
  cmp al, [esi+lex_node.char]
  jne .try_or

  ; char is matched. Check to see if it's a full token, then continue.
  mov edx, [esi+lex_node.token]
  test edx, edx
  jz .try_next

  ; it's a token; return it
  jmp [esi+lex_node.call]	; token is in edx

.try_next:
  ; we matched a char but didn't find a token, continue scaning
  ;push esi	; save our place; if this branch doesn't work we can come back
  debug_msg try_next
  
  mov esi, [esi+lex_node.next]
  jmp .next_char

.try_or:
  ; we didn't match the node, try an or
  debug_msg try_or
  
  mov esi, [esi+lex_node.or]
  test esi, esi
  jnz .test_node

  ; we don't have any more ors to try!
  ; we should backtrack here, but for now we just puke and die
  xor edx, edx	; token 0
  jmp _failure
 
_retn:
debug_msg token_found
%ifdef _DEBUG_
  externfunc hex_out, system_log
  externfunc terminate_log, system_log
%endif
retn

%include "opcodes.inc"
%define _T_CMOV_ -1

struc lex_node
  .char:	resb 1
  .next:	resd 1	; ptr to things that could be next
  .or:		resd 1	; ptr to other things that work in this spot
  .token:	resd 1	; token value
  .call:	resd 1	; function to call when this token is found
  ; if the token value is 0 the call may be omitted
endstruc

%macro mn 3	; make node, ( char, next, or )
  db %1
  dd %2
  dd %3
  dd 0
%endmacro

%macro mn 4	; make node, ( char, next, or, token )
  db %1
  dd %2
  dd %3
  dd _T_%4_
  dd _retn
%endmacro

%macro mn 5	; make node, ( char, next, or, token, call )
  db %1
  dd %2
  dd %3
  dd _T_%4_
  dd %5
%endmacro

lex_table:
	;char	next	or	token	call
	mn 'a',	.aa,	.b
.aa:	mn 'a',	.aaa,	.ad
.aaa:	mn 'a',	0,	.aas,	AAA
.aas:	mn 's',	0,	.aam,	AAS
.aam:	mn 'm',	0,	.aad,	AAM
.aad:	mn 'd',	0,	0,	AAD
.ad:	mn 'd',	.adc,	.an
.adc:	mn 'c',	0,	.add,	ADC
.add:	mn 'd',	0,	0,	ADD
.an:	mn 'n',	.and,	.ar
.and:	mn 'd',	0,	0,	AND
.ar:	mn 'r',	.arp,	0
.arp:	mn 'p',	.arpl,	0
.arpl:	mn 'l',	0,	0,	ARPL
.b:	mn 'b',	.bo,	.c
.bo:	mn 'o',	.bou,	.bs
.bou:	mn 'u',	.boun,	0
.boun:	mn 'n',	.bound,	0
.bound:	mn 'd',	0,	0,	BOUND
.bs:	mn 's',	.bsf,	.bt,
.bsf:	mn 'f',	0,	.bsr,	BSF
.bsr:	mn 'r',	0,	.bsw,	BSR
.bsw:	mn 'w',	.bswa,	0
.bswa:	mn 'a',	.bswap,	0
.bswap:	mn 'p',	0,	0,	BSWAP
.bt:	mn 't',	.btc,	0,	BT
.btc:	mn 'c',	0,	.btr,	BTC
.btr:	mn 'r',	0,	.bts,	BTR
.bts:	mn 's',	0,	0,	BTS
.c:	mn 'c',	.ca,	.d
.ca:	mn 'a', .cal,	.cb
.cal:	mn 'l', .call,	0
.call:	mn 'l', 0,	0,	CALL
.cb:	mn 'b',	.cbw,	.cd
.cbw:	mn 'w', 0,	0,	CBW
.cd:	mn 'd',	.cdq,	.cl
.cdq:	mn 'q',	0,	0,	CDQ
.cl:	mn 'l',	.clc,	.cm
.clc:	mn 'c',	0,	.cld,	CLC
.cld:	mn 'd',	0,	.cli,	CLD
.cli:	mn 'i',	0,	.clt,	CLI
.clt:	mn 't',	.clts,	0
.clts:	mn 's',	0,	0,	CLTS
.cm:	mn 'm',	.cmc,	.cp
.cmc:	mn 'c',	0,	.cmo,	CMC
.cmo:	mn 'o',	.cmov,	.cmp
.cmov:	mn 'v',	0,	0,	CMOV
.cmp:	mn 'p',	.cmps,	0
.cmps:	mn 's',	.cmpsb,	.cmpx
.cmpsb:	mn 'b',	0,	.cmpsw,	CMPSB
.cmpsw:	mn 'w',	0,	.cmpsd,	CMPSW
.cmpsd:	mn 'd',	0,	0,	CMPSD
.cmpx:	mn 'x',	.cmpxc,	0
.cmpxc:	mn 'c',	.cmpxch,0

.cmpxch:	mn 'h',	.cmpxchg,	0
.cmpxchg:	mn 'g',	.cmpxchg4,	0,		CMPXCHG
.cmpxchg4:	mn '4',	.cmpxchg48,	.cmpxchg8
.cmpxchg48:	mn '8',	.cmpxchg486,	0
.cmpxchg486:	mn '6',	0,		0,		CMPXCHG486

.d:
.cp:
.cmpxchg8:


times 1024 dd 0
