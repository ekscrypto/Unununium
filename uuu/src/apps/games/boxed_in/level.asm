;IN: esi=pointer to compressed level data 
;  OUT: edi=pointer to decompressed level data
Set_level_up:
 mov ecx,18 * 14
 xor edx,edx
 externfunc mem.alloc 
 mov DWORD [pleveldata],edi
 mov ecx,18 * 14
 xor edx,edx
 externfunc mem.alloc
 mov DWORD [plastmove],edi
 retn 

Unpack_level:
 mov eax,[CurrentLevel]
 mov ebx , ((18*14) / 2)
 mul ebx
 mov esi , level_data
 add esi , eax
 mov edi , dword [pleveldata]
 mov ecx,(18 * 14) / 2
.unpack_byte:
 mov al,[esi]
 shr al,4
 mov [edi + 0],al
 mov al,[esi]
 and al,1111b
 mov [edi + 1],al 
 inc esi
 add edi,2
 loop .unpack_byte
 call NumberBoxesSet
 push ecx
 call NumberTargets
 pop eax
 add eax,ecx
 mov [NumberToSet],al
 mov DWORD [NumberMoves],0
ClearScreen:
 mov edi,0xA0000
 mov eax,0xFFFFFFFF
 mov ecx,(320 * 200) / 4
 rep stosd
DrawTitle:
 mov esi,BoxedIn
 mov edi,0xA0000 + 125
 mov al,11
 externfunc gfx.render.13h.string
ClearLastMove:
 mov esi,[plastmove]
 mov DWORD [esi],0xFFFFFFFF
DrawLevelNumber:
 mov eax,[CurrentLevel]
 inc eax
 aam
 add ax,0x3030
 rol ax,8
 mov [LevelNumber + 7],ax
 mov esi,LevelNumber
 mov edi,0xA0000 + (320 * 186) + 200
 mov al,11
 externfunc gfx.render.13h.string 
 call DrawMoveNumber
 ret

SaveMove:
 pushad
 mov esi,[pleveldata]
 mov edi,[plastmove]
 mov ecx,(18 * 14) / 4
 rep movsd
 popad
 ret

RestoreLastMove:
 mov esi,[plastmove]
 cmp DWORD [esi],0xFFFFFFFF
 je EndRestoreLastMove
 dec DWORD [NumberMoves] 
 mov edi,[pleveldata]
 xor edx,edx
 mov ecx,(18 * 14)
RestoreTile:
 mov al,[esi]
 mov [edi],al
 inc edx
 inc esi
 inc edi
 cmp al,PLAYER_EMPTY
 je CalcNewPlayerPos
 loop RestoreTile
 jmp EndRestoreLastMove
CalcNewPlayerPos:
 call CalculatePlayerPosition
 dec ecx
 jmp RestoreTile
EndRestoreLastMove:
 mov esi,[plastmove]
 mov DWORD [esi],0xFFFFFFFF
 ret

DrawMoveNumber:
 mov esi,BlankString
 mov edi,0xA0000 + (320 * 186) + 20
 mov al,255
 externfunc gfx.render.13h.string
 mov DWORD [MoveNumber + 6],'0000'
 mov eax,[NumberMoves]
 mov ebx,10
 mov edi,MoveNumber + 9
NextDigit:
 xor edx,edx
 div ebx
 add dl,0x30
 mov [edi],dl
 dec edi
 cmp eax,0
 jnz NextDigit
 mov esi,MoveNumber
 mov edi,0xA0000 + (320 * 186) + 20
 mov al,11
 externfunc gfx.render.13h.string
 ret  

NumberBoxesSet:
 mov esi,[pleveldata]
 xor ecx,ecx
 xor edx,edx
TestForSetBox:
 mov al,[esi]
 inc esi
 cmp edx,(18 * 14)
 je EndTestForSetBox
 inc edx
 cmp al,SET
 jne TestForSetBox
 inc ecx
 jmp TestForSetBox
EndTestForSetBox:
 ret 

NumberTargets:
 mov esi,[pleveldata]
 xor ecx,ecx
 xor edx,edx
TestForTarget:
 mov al,[esi]
 inc esi
 cmp edx,(18 * 14)
 je EndTestForTarget
 inc edx
 cmp al,PLAYER_EMPTY
 je PlayerFound
 cmp al,TARGET
 jne TestForTarget
 inc ecx
 jmp TestForTarget
PlayerFound:
 call CalculatePlayerPosition
 jmp TestForTarget
EndTestForTarget:
 ret 

CalculatePlayerPosition:
 pushad
 mov eax,edx
 dec eax
 xor edx,edx
 mov ebx,18
 div ebx
 mov DWORD [PlayerX],edx
 mov DWORD [PlayerY],eax
 popad
 ret

Draw_level:
 mov ebp,[pleveldata]
 mov edi,0xA0000 + (16 * 320) + 52
 mov edx,14
.next_row:
 push edi
 mov ecx,18
.draw_row:
 push edi
 push ecx
.draw_square:
 xor eax,eax
 mov al,[ebp]
 inc ebp
 mov ebx,144
 push edx
 mul ebx
 pop edx
 mov esi,eax
 add esi,square_gfx
 mov ecx,12
.draw_line:
 push ecx
 mov ecx,12
.draw_pixel:
 movsb
 loop .draw_pixel
 add edi,308
 pop ecx
 loop .draw_line
 pop ecx
 pop edi
 add edi,12
 loop .draw_row
 pop edi
 add edi,3840
 dec edx
 jnz .next_row
 ret


;variables
pleveldata : dd 0
plastmove:   DD 0
temp: dd 0
LevelNumber: DB 'Level: 00',0
BlankString: DB 219,219,219,219,219,219,219,219,219,219,0
MoveNumber:  DB 'Move: 0000',0
BoxedIn:     DB 'Boxed In!',0
level_data :
 %include "levels.inc"
