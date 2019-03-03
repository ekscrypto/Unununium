; $Header: /cvsroot/uuu/uuu/src/apps/games/ttt/ttt.asm,v 1.2 2001/11/26 18:21:56 instinc Exp $
;
; FIRST ! WHY DO I NEVER COMMENT MY CODE!!! 
; Well, it is me, Hellman that has written this little application. It works
; I don't know what the BSD License is, but I am sure this code is developed
; under that license :D

%include "pcx/sizes.inc"
%include "vid/mem.inc"

%define PLAYER_BLUE	2
%define PLAYER_RED	1

	
%define PIECESIZEQUAD	PIECESIZE*PIECESIZE
%define RECTSIZEQUAD	RECTSIZE*RECTSIZE
%define BORDERSIZEQUAD	BORDERSIZE*BORDERSIZE

%define WINSSIZEQUAD	WINSSIZEX*WINSSIZEY
%define REDSIZEQUAD	REDSIZEX*REDSIZEY
%define BLUESIZEQUAD	BLUESIZEX*BLUESIZEY
%define DRAWSIZEQUAD	DRAWSIZEX*DRAWSIZEY
%define RESTARTSIZEQUAD	RESTARTSIZEX*RESTARTSIZEY

%define TURNSIZEQUAD	TURNSIZEX*TURNSIZEY

; The keys
%define UPARW		1
%define DOWNARW		2
%define RIGHTARW	4
%define LEFTARW		8
%define QKEY		16
%define ENTERKEY	32
%define SPACEKEY	64

; The skin-settings
%define	UPLEFT		0
%define	UP		4
%define	UPRIGHT		8
%define	LEFT		12
%define	BOARD		16
%define RIGHT		20
%define DOWNLEFT	24
%define DOWN		28
%define DOWNRIGHT	32
%define REDPIECE	36
%define BLUEPIECE	40
%define CURSOR		44
%define WINS		48
%define RED		52
%define BLUE            56
%define RESTART		60
%define BLUETURN	64
%define REDTURN		68
%define DRAW		72

; The skin of the board
%define	BG		0
%define EMPTYRECT	4

; This is a super tic-tac-toe game for UUU
global app_ttt

app_ttt:

	xor	edx,edx
	mov	ecx,64000
	externfunc mem.alloc			; Allocate screen buffer
	jc	.end_error
	mov	[vidbuffer], edi
	
	call	init_gfx
	jmp	.draw
	
.game_loop:
	call	get_keyboard_input

;	externfunc showregs, debug
	
	push	dword .keyboard_read
	cmp	bx,UPARW
	jz	near ctrl.move_up
	cmp	bx,DOWNARW
	jz	near ctrl.move_down
	cmp	bx,LEFTARW
	jz	near ctrl.move_left	
	cmp	bx,RIGHTARW
	jz	near ctrl.move_right
	cmp	bx,QKEY
	jz	.end
	cmp	bx,ENTERKEY
	jz	ctrl.place_piece
	cmp	bx,SPACEKEY
	jz	near ctrl.restart
	retn			; Jump to .keyboard_read

.keyboard_read:
	test	bx, bx
	jz	.game_loop
	
.draw:
	call	draw_board
	call	gfxfunc.flip

	call	check_state
		
	jmp 	.game_loop
	retn
.end_error:
.end:
	pop	eax      ; pop .keyboard_read
	; Deallocate
	call	deinit_gfx
	
	mov	eax,[vidbuffer]
	externfunc mem.dealloc			; DeAllocate screen buffer
	
	retn

	
ctrl:
.place_piece:
	push	bx
    	movzx	ax, byte [cursor_pos]
	ror	ax,2
	shr	ah,4
	or	al,ah
	movzx	ecx,al
	add	ecx, board
	mov	ah, [ecx]
	test	ah,ah
	jnz	.not_free
	mov	ah, [player]
	xor	[player], byte 1
	inc	ah
	mov	[ecx], ah
.not_free:
	pop	bx
	retn	
	
.move_up:
	push	bx
	mov	bl, [cursor_pos]	; The less. sign. two bits of cursor_pos is used for the Y-position (0-3)
	mov	al, bl
	and	al, 0xC
	dec	bl
	and	bl, 3
	or	al,bl
	mov	[cursor_pos], al
	pop	bx
	retn
	
.move_down:
	push	bx
	mov	bl, [cursor_pos]	
	mov	al, bl
	and	al, 0xC
	inc	bl
	and	bl, 3
	or	al,bl
	mov	[cursor_pos], al
	pop	bx
        retn

.move_right:
	push	bx
	mov	bl, [cursor_pos]	
	mov	al, bl
	shr	al, 2
	inc	al
	shl	al, 2
	and	bl, 3
	and	al, 0xC
	or	al,bl
	mov	[cursor_pos], al
	pop	bx
        retn

.move_left:
	push	bx
	mov	bl, [cursor_pos]	
	mov	al, bl
	shr	al, 2
	dec	al
	shl	al, 2
	and	bl, 3
	and	al, 0xC
	or	al,bl
	mov	[cursor_pos], al
	pop	bx
	retn

.restart:
	pop	eax
	push	dword app_ttt.draw	; Go to app_ttt
	mov	edi, board
	mov	eax, 0
	mov	ecx, 4
	rep	stosd
	mov	[cursor_pos], byte 0
	
	mov	eax,0
	mov	edi, [vidbuffer]
	mov	ecx, 16000
	rep	stosd

	mov	al, [last_player]
	xor	al, 1
	mov	[player], al
	mov	[last_player], al
	
	retn

check_state:
	; Check if there is a vertical line
	mov	edx, 0
.vert_new_col_beg:	
	mov	ecx, 0
	mov	bl, [board+edx+ecx*4]
.vert_new_row_beg:
	cmp	edx, 4
	jz	.vert_no_full_col
	cmp	ecx, 4
	jz	.vert_full_col
	lea	eax, [board+edx+ecx*4]
	mov	al, [eax]
	cmp	al, 0
	jz	.vert_new_col
	cmp	al, bl
	jz	.vert_new_row
.vert_new_col:
	inc	edx
	jmp	.vert_new_col_beg
.vert_new_row:
	mov	bl, [board+edx+ecx*4]
	inc	ecx
	jmp	.vert_new_row_beg
.vert_full_col:
	call	win	
.vert_no_full_col:
	
	mov	ecx, 0
.hori_new_row_beg:	
	mov	edx, 0
	mov	bl, [board+edx+ecx*4]
.hori_new_col_beg:
	cmp	ecx, 4
	jz	.hori_no_full_row
	cmp	edx, 4
	jz	.hori_full_row
	lea	eax, [board+edx+ecx*4]
	mov	al, [eax]
	cmp	al, 0
	jz	.hori_new_row
	cmp	al, bl
	jz	.hori_new_col
.hori_new_row:
	inc	ecx
	jmp	.hori_new_row_beg
.hori_new_col:
	mov	bl, [board+edx+ecx*4]
	inc	edx
	jmp	.hori_new_col_beg
.hori_full_row:
	call	win	
.hori_no_full_row:

	mov	bh, 1
	mov	ecx, 0
.diag:
	mov	edx, 0
	mov	bl, [board+edx+ecx*4]
.diag_continue:
	cmp	edx,4
	jz	.diag_full_row
	mov	al,[board+edx+ecx*4]
	cmp	al, 0
	jz	.diag_no_full_row
	cmp	al, bl
	jz	.diag_next_row
	jnz	.diag_no_full_row
.diag_next_row:
	mov	bl, [board+edx+ecx*4]
	inc	edx
	add	cl,bh
	jmp	.diag_continue
.diag_no_full_row:
	cmp	bh, -1
	jz	.diag_end
	mov	ecx, 3
	mov	bh, -1
	jmp	.diag
.diag_full_row:
	call	win	
.diag_end:

.corners:
	mov	al, [board]
	mov	bl, al
	cmp	al, 0
	jz	.corners_end
	mov	al, [board+3]
	cmp	al, bl
	jnz	.corners_end
	mov	al, [board+4*4-1]
	cmp	al, bl
	jnz	.corners_end
	mov	al, [board+3*4]
	cmp	al, bl
	jnz	.corners_end

	call	win	
.corners_end:

.box:
	mov	ecx, 0	; limit 0-2
	mov	edx, 0	; limit 0-2
.box_continue:
	cmp	edx, 3
	jz	.box_new_row
	mov	ax, [board+edx+ecx*4]
	mov	bx, [board+edx+ecx*4+4]
	and 	al,ah
	and	bl,bh
	and	al,bl
	test	al,al
	jnz	.box_found
	inc	edx
	jmp	.box_continue
.box_new_row:
	inc	ecx
	cmp	ecx,3
	mov	edx,0
	jz	.box_none_found
	jmp	.box_continue
.box_found:
	call	win	
.box_none_found:

.full_board:
	mov	al, 0
	mov	edi, board
	mov	ecx, 16
	repnz	scasb
	jz	.not_a_full_board
	call	draw
.not_a_full_board:
	retn
	
; Stolen code from xgs_test

get_keyboard_input:
  mov bx, 0				;
  in al, 0x60			;
  cmp al, [.old_code]
  jz .done
  mov [.old_code], al

.up_released:			;
  cmp al, 0x48			;up arrow released
  jne .down_released		;
  mov bx, UPARW			;
  retn
			;
.down_released:			;
  cmp al, 0x50			;
  jne .left_released		;
  mov bx,DOWNARW
  retn		;
				;
.left_released:			;
  cmp al, 0x4b			;
  jne .right_released		;
  mov bx,LEFTARW		;
  retn

.right_released:		;
  cmp al, 0x4d			;
  jne .q_released		;
  mov bx,RIGHTARW		;
  retn

.q_released:				;
  cmp al, 0x90				;
  jne .enter_released			;
  mov bx,QKEY
  retn

.enter_released:				;
  cmp al, 0x1c					;
  jne .space_pressed
  mov bx,ENTERKEY

.space_pressed:
  cmp al, 57
  jne .done
  mov bx,SPACEKEY

.done:
  retn

.old_code:
	db 0

draw:
	; Calculate where to draw the pic
	mov	ebx,320/2-(DRAWSIZEX/2)
	mov	eax,200/2-(DRAWSIZEY/2)
	mov	edx,DRAWSIZEX
	mov	ecx,DRAWSIZEY
	mov	esi,[gfx.skin+DRAW]
	mov	esi,[esi]
	
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop	eax
	
	mov	ebx,320/2-(RESTARTSIZEX/2)
	add	eax, DRAWSIZEY
	mov	edx, RESTARTSIZEX
	mov	ecx, RESTARTSIZEY
	mov	esi,[gfx.skin+RESTART]
	mov	esi,[esi]
	call	gfxfunc.draw
	
	call	gfxfunc.flip
	
.again:
	call	get_keyboard_input
	cmp	bx,SPACEKEY
	jnz	.again
	
	call	ctrl.restart
	retn
		
win:
	; al = winning player
	cmp	al, PLAYER_BLUE
	jz	.blue_won
	
	; Calculate where to draw the pic
	; x = 320/2-(REDSIZEX/2-WINSSIZEX/2)
	; y = 200/2-(REDSIZEY/2-WINSSIZEY/2)
	mov	ebx,320/2-(REDSIZEX/2+WINSSIZEX/2)
	mov	eax,200/2-(REDSIZEY/2)
	mov	edx,REDSIZEX
	mov	ecx,REDSIZEY
	mov	esi,[gfx.skin+RED]
	mov	esi,[esi]
	
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop	eax
	
	add	ebx, REDSIZEX

	jmp	.draw_wins
	
.blue_won:
	; Calculate where to draw the pic
	; x = 320/2-(BLUESIZEX/2-WINSSIZEX/2)
	; y = 200/2-(BLUESIZEY/2-WINSSIZEY/2)
	mov	ebx,320/2-(BLUESIZEX/2+WINSSIZEX/2)
	mov	eax,200/2-(BLUESIZEY/2)
	mov	edx,BLUESIZEX
	mov	ecx,BLUESIZEY
	mov	esi,[gfx.skin+BLUE]
	mov	esi,[esi]
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop	eax
	
	add	ebx, BLUESIZEX
.draw_wins:
	mov	edx, WINSSIZEX
	mov	ecx, WINSSIZEY
	mov	esi,[gfx.skin+WINS]
	mov	esi,[esi]
	
	push	eax
	call	gfxfunc.draw
	pop	eax
	
	mov	ebx,320/2-(RESTARTSIZEX/2)
	add	eax, WINSSIZEY
	mov	edx, RESTARTSIZEX
	mov	ecx, RESTARTSIZEY
	mov	esi,[gfx.skin+RESTART]
	mov	esi,[esi]
	call	gfxfunc.draw
	
	call	gfxfunc.flip
	
.again:
	call	get_keyboard_input
	cmp	bx,SPACEKEY
	jnz	.again
	
	call	ctrl.restart
	retn
	
draw_board:
	; Draw the turn-pic
	
	mov	eax, 200/2-(TURNSIZEY/2)
	mov	ebx, 0
	mov	edx, TURNSIZEX
	mov	ecx, TURNSIZEY
	cmp	[player], byte 1
	jnz	.red_player
	mov	esi, [gfx.skin+BLUETURN]
	jz	.draw_player
.red_player:
	mov	esi, [gfx.skin+REDTURN]
.draw_player:
	mov	esi, [esi]
	call	gfxfunc.draw
	
	; Calculate where to put the board (in the middle)
	
	; Start to draw the UPLEFT border
	mov	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ebx,320/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+UPLEFT]
	mov	esi,[esi]
	call	gfxfunc.draw
	
	mov	ecx,1	
.up:	
	cmp	ecx,4
	ja	.upright
	push	ecx
	mov	eax,BORDERSIZE
	mul	ecx
	add	eax,320/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ebx,eax
	mov	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+UP]
	mov	esi,[esi]
	call	gfxfunc.draw
	pop	ecx
	inc	ecx
	jmp	.up
	
.upright:
	mov	eax,BORDERSIZE
	mul	ecx
	add	eax,320/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ebx,eax
	mov	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+UPRIGHT]
	mov	esi,[esi]
	call	gfxfunc.draw

; NEW ROW
	mov	ecx,1
.main:
	cmp	ecx,5
	jz	near .downleft
	push	ecx
	mov	eax,BORDERSIZE
	mul	ecx
	add	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ebx,320/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+LEFT]
	mov	esi,[esi]
	
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop	eax

	mov	edx,0
.board:
	cmp	edx,4
	je	near .endrow
	push	edx
	add	ebx,BORDERSIZE
	mov	ecx,RECTSIZE
	mov	edx,RECTSIZE
	mov	esi,[gfx.skin+BOARD]
	mov	esi,[esi]
	
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop     eax

; If there is a piece on that tile, draw it
	pop	edx
	pop	ecx	
	push	ecx
	push	edx
	push	ax
	push	dx
	push	cx
	mov	eax,4		; Code to get the right position of the board
	dec	cx
	mul	cx
	pop	cx
	pop	dx
	add	edx,eax
	pop	ax

	push	edx  ;<--------------------------EDX!!!
	
	add	edx,board
	
	cmp	[edx], byte 0  ; NONE
	jz	.none
	cmp	[edx], byte 1	; RED
	jz	.redpiece
	mov	esi,[gfx.skin+BLUEPIECE]
	jmp	.drawpiece
.redpiece:
	mov	esi,[gfx.skin+REDPIECE]
.drawpiece:
	mov	esi,[esi]
	mov	ecx,PIECESIZE
	mov	edx,PIECESIZE
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop	eax
.none:
	pop	edx ;<-----------------------------------EDX!!!
    	
	push	ax
	push	bx
	
    	movzx	ax, byte [cursor_pos]
	ror	ax,2
	shr	ah,4
	or	al,ah
	movzx	ecx,al

	pop	bx
	pop	ax
	
	cmp	ecx, edx
	jnz	.dont_draw_cursor	
	
	mov	esi, [gfx.skin+CURSOR]
	mov	esi, [esi]
	
	mov	ecx,RECTSIZE
	mov	edx,RECTSIZE
	
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop	eax	
	
.dont_draw_cursor:
	pop	edx
	inc	edx
	jmp	.board

.endrow:
; The right border is left to draw

	pop	ecx
	push	ecx	
	mov	eax,BORDERSIZE
	mul	ecx
	add	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2
	add	ebx,RECTSIZE
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+RIGHT]
	mov	esi,[esi]
	
	push	eax
	push	ebx
	call	gfxfunc.draw
	pop	ebx
	pop	eax
	
	pop	ecx
	inc	ecx
	jmp	.main

.downleft:
	; Draw the DOWNLEFT border
	mov	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2+RECTSIZE*4+BORDERSIZE
	mov	ebx,320/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+DOWNLEFT]
	mov	esi,[esi]
	call	gfxfunc.draw
	
	mov	ecx,1	
.down:	
	cmp	ecx,4
	ja	.downright
	push	ecx
	mov	eax,BORDERSIZE
	mul	ecx
	add	eax,320/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ebx,eax
	mov	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2+RECTSIZE*4+BORDERSIZE
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+DOWN]
	mov	esi,[esi]
	call	gfxfunc.draw
	pop	ecx
	inc	ecx
	jmp	.down
	
.downright:
	mov	eax,BORDERSIZE
	mul	ecx
	add	eax,320/2-(RECTSIZE*4+BORDERSIZE*2)/2
	mov	ebx,eax
	mov	eax,200/2-(RECTSIZE*4+BORDERSIZE*2)/2+RECTSIZE*4+BORDERSIZE
	mov	ecx,BORDERSIZE
	mov	edx,BORDERSIZE
	mov	esi,[gfx.skin+DOWNRIGHT]
	mov	esi,[esi]
	call	gfxfunc.draw

	retn
init_gfx:
	
	xor	edx,edx
	mov	ecx,PIECESIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.redpiece], edi
;	mov	edi, [gfx.redpiece]
	
	mov	esi, redpiecepcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,PIECESIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.bluepiece], edi
;	mov	edi, [gfx.bluepiece]
	
	mov	esi, bluepiecepcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,RECTSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.cursor], edi
;	mov	edi, [gfx.cursor]
	
	mov	esi, cursorpcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,RECTSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.empty_rect], edi
;	mov	edi, [gfx.empty_rect]
	
	mov	esi, empty_rectpcx
		
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.upleft], edi
;	mov	edi, [gfx.upleft]

	mov	esi,  upleftpcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.up], edi
;	mov	edi, [gfx.up]
	
	mov	esi,  uppcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.upright], edi
;	mov	edi, [gfx.upright]

	mov	esi,  uprightpcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.left], edi
;	mov	edi, [gfx.left]

	mov	esi,  leftpcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.right], edi
;	mov	edi, [gfx.right]
	
	mov	esi,  rightpcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.downleft], edi
;	mov	edi, [gfx.downleft]

	mov	esi,  downleftpcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.down], edi
;	mov	edi, [gfx.down]
	
	mov	esi,  downpcx
	
	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BORDERSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.downright], edi
;	mov	edi, [gfx.downright]
	
	mov	esi, downrightpcx

	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,WINSSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.wins], edi
;	mov	edi, [gfx.downright]
	
	mov	esi, winspcx

	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,REDSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.red], edi
	
	mov	esi, redpcx

	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,BLUESIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.blue], edi
	
	mov	esi, bluepcx

	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,RESTARTSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.restart], edi
	
	mov	esi, restartpcx

	call	PCXDecoder

; ---

	xor	edx,edx
	mov	ecx,TURNSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.blueturn], edi
	
	mov	esi, blueturnpcx

	call	PCXDecoder
	
; ---

	xor	edx,edx
	mov	ecx,TURNSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.redturn], edi
	
	mov	esi, redturnpcx

	call	PCXDecoder
	
; ---

	xor	edx,edx
	mov	ecx,DRAWSIZEQUAD
	externfunc mem.alloc
	
	mov	[gfx.draw], edi
	
	mov	esi, drawpcx

	call	PCXDecoder
	
	retn
		
deinit_gfx:
	
	mov	eax, [gfx.redpiece]
	externfunc mem.dealloc

; ---

	mov	eax, [gfx.bluepiece]
	externfunc mem.dealloc
	
; ---

	mov	eax, [gfx.cursor]
	externfunc mem.dealloc
	
; ---

	mov	eax, [gfx.empty_rect]
	externfunc mem.dealloc
	
; ---
	
	mov	eax, [gfx.upleft]
	externfunc mem.dealloc
	
; ---

	mov	eax, [gfx.up]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.upright]
	externfunc mem.dealloc

; ---

	mov	eax, [gfx.left]
	externfunc mem.dealloc

; ---

	mov	eax, [gfx.right]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.downleft]
	externfunc mem.dealloc
	
; ---

	mov	eax, [gfx.down]
	externfunc mem.dealloc

; ---

	mov	eax, [gfx.downright]
	externfunc mem.dealloc

; ---

	mov	eax, [gfx.downright]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.red]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.blue]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.restart]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.blueturn]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.redturn]
	externfunc mem.dealloc

; ---
	
	mov	eax, [gfx.draw]
	externfunc mem.dealloc

	retn	

		
gfxfunc:
.flip:
	mov dx, 0x3da	
.wait:		
	in al, dx	
	and al, 0x8	
	jnz .wait	
.waitmore:	
	in al, dx	
	and al, 0x8	
	jz .waitmore	

	mov	esi, [vidbuffer]
	mov	edi, 0xA0000
	mov	ecx, 64000/4
	rep	movsd
	retn

	
.draw:
; (e)ax = y cord
; (e)bx = x cord
; (e)cx = y size
; (e)dx = x size
; esi = image to draw

	push	dx
	mov	edi, [vidbuffer]
	mov	dx,320
	mul	dx
	add	edi,eax
	pop	dx
	add	edi,ebx
.drawnewline:
	cmp	ecx,0
	jbe	.end
	dec	ecx
	push	ecx
	mov	ecx,edx
.write:
	cld
	lodsb
	cmp	al,0
	jz	.transparent
	stosb
	loop	.write
	jmp	.done
.transparent:
	inc	edi
	loop	.write
.done:		
	pop	ecx
	add	edi,320
	sub	edi,edx
	jmp	.drawnewline	
.end:	
	retn
.fill:
; al = color to fill with
	retn

gfx:
.redpiece:	dd 0

.bluepiece:	dd 0

.cursor:	dd 0

.empty_rect:	dd 0

.upleft:	dd 0
.up:		dd 0
.upright:	dd 0
.left:		dd 0
.right:		dd 0
.downleft:	dd 0
.down:		dd 0
.downright:	dd 0
.wins:		dd 0
.red:		dd 0
.blue:		dd 0
.restart:	dd 0
.blueturn	dd 0
.redturn	dd 0
.draw		dd 0

.skin:
dd .upleft, .up, .upright
dd .left, .empty_rect, .right
dd .downleft, .down, .downright
dd .redpiece, .bluepiece, .cursor
dd .wins, .red, .blue, .restart
dd .blueturn, .redturn, .draw

redpiecepcx:
	incbin "pcx/redpc.pcx"
.end:

bluepiecepcx:
	incbin "pcx/bluepc.pcx"
.end:

cursorpcx:
	incbin "pcx/cursor.pcx"
.end:

empty_rectpcx:
	incbin "pcx/rect.pcx"
.end:

upleftpcx:
	incbin "pcx/upleft.pcx"
.end:
		
uppcx:
	incbin "pcx/up.pcx"
.end:
	
uprightpcx:
	incbin "pcx/upright.pcx"
.end:
	
leftpcx:
	incbin "pcx/left.pcx"
.end:
	
rightpcx:
	incbin "pcx/right.pcx"
.end:
	
downleftpcx:
	incbin "pcx/downleft.pcx"
.end:
	
downpcx:
	incbin "pcx/down.pcx"
.end:
	
downrightpcx:
	incbin "pcx/downright.pcx"
.end:

winspcx:
	incbin "pcx/wins.pcx"
.end:

redpcx:
	incbin "pcx/red.pcx"
.end:

bluepcx:
	incbin "pcx/blue.pcx"
.end:

restartpcx:
	incbin "pcx/restart.pcx"
.end:

blueturnpcx:
	incbin "pcx/blueturn.pcx"
.end:

redturnpcx:
	incbin "pcx/redturn.pcx"
.end:

drawpcx:
	incbin "pcx/draw.pcx"
.end:

player:
	db 0	; 0 = red, 1 = blue
last_player:
	db 0
	
cursor_pos:
	db 0   ; 2 less sign. bits = y, 2 more sign. bitrs = x
board:
db 0, 0, 0, 0
db 0, 0, 0, 0
db 0, 0, 0, 0
db 0, 0, 0, 0

vidbuffer: dd 0

;real_vidbuffer:
;	times 64000 db 0

%define XSIZE	8
%define YSIZE	10
%define DATA	128

PCXDecoder:
;	esi = PCX Image
;	edi = Raw Image

	add	esi,8
	mov	dx,[esi]
	inc	dx
	add	esi,2
	mov	cx,[esi]
	inc	cx
	add	esi,128-8-2
	push	cx
	push	dx
	
.newline:
	pop	dx
	pop	cx
	cmp	cx,0
	jz	.end
	dec	cx
	push	cx
	push	dx
.continue:
	lodsb
	cmp	al,0xC0
	jb	.single
	and	al,63
	movzx	ecx,al
	sub	dx,cx
	lodsb
	rep	stosb
	cmp	dx,0
	jz	.newline
	jmp	.continue
.single:
	stosb
	dec	dx
	cmp	dx,0
	jz	.newline
	jmp	.continue
.end:
	retn
