KeyboardProc:
 pushad
 xor ecx,ecx
 xor edx,edx
 mov cl,[PlayerX]
 mov dl,[PlayerY] 
 lea esi,[edx * 9]
 lea esi,[esi + esi + ecx]
 add esi,[pleveldata]
 xor ebx,ebx
 xor ecx,ecx
 cmp al,8
 je Backspace
 cmp al,'r'
 je RestartLevel
 cmp al,'q'
 je near Quit
 cmp al,'9'
 je NextLevel
 cmp al,'3'
 je PrevLevel
 cmp al,'8'
 je near Up
 cmp al,'2'
 je near Down
 cmp al,'6'
 je near Right
 cmp al,'4'
 je near Left
 jmp EndKeyboardProc
Backspace:
 call RestoreLastMove
 call Draw_level
 call DrawMoveNumber
 jmp EndKeyboardProc
RestartLevel:
 call Unpack_level
 call Draw_level
 jmp EndKeyboardProc
NextLevel:
 mov eax,[CurrentLevel]
 cmp eax,NUMBERLEVELS - 1
 je near EndKeyboardProc
 inc DWORD [CurrentLevel]
 call Unpack_level
 call Draw_level
 jmp EndKeyboardProc
PrevLevel:
 mov eax,[CurrentLevel]
 cmp eax,0
 je near EndKeyboardProc
 dec DWORD [CurrentLevel]
 call Unpack_level
 call Draw_level
 jmp EndKeyboardProc
Up:
 lea edi,[esi - 18]
 lea edx,[esi - 36]
 mov ecx,-1
 jmp ProcessMove
Down:
 lea edi,[esi + 18]
 lea edx,[esi + 36]
 mov ecx,1
 jmp ProcessMove
Left:
 lea edi,[esi - 1]
 lea edx,[esi - 2]
 mov ebx,-1
 jmp ProcessMove
Right:
 lea edi,[esi + 1]
 lea edx,[esi + 2]
 mov ebx,1
ProcessMove:
 mov al,[edi]
 cmp al,WALL
 je near EndKeyboardProc
 cmp al,BOX
 je ProcessBox
 cmp al,SET
 je near ProcessSet
 cmp al,TARGET
 je ProcessTarget
ProcessEmpty:
 call SaveMove
 mov BYTE [edi],PLAYER_EMPTY
 and BYTE [esi],11b
 add DWORD [PlayerX],ebx
 add DWORD [PlayerY],ecx
 jmp RedrawLevel
ProcessTarget:
 call SaveMove
 mov BYTE [edi],PLAYER_TARGET
 and BYTE [esi],11b
 add DWORD [PlayerX],ebx
 add DWORD [PlayerY],ecx
 jmp RedrawLevel
ProcessBox:
 mov al,[edx]
 cmp al,WALL
 je near EndKeyboardProc
 cmp al,SET
 je near EndKeyboardProc
 cmp al,BOX
 je near EndKeyboardProc
 cmp al,TARGET
 je ProcessBoxTarget
ProcessBoxEmpty:
 call SaveMove
 mov BYTE [edx],BOX
 mov BYTE [edi],PLAYER_EMPTY
 and BYTE [esi],11b
 add DWORD [PlayerX],ebx
 add DWORD [PlayerY],ecx
 jmp RedrawLevel
ProcessBoxTarget:
 call SaveMove
 mov BYTE [edx],SET
 mov BYTE [edi],PLAYER_EMPTY
 and BYTE [esi],11b
 add DWORD [PlayerX],ebx
 add DWORD [PlayerY],ecx
 jmp RedrawLevel
ProcessSet:
 mov al,[edx]
 cmp al,WALL
 je near EndKeyboardProc
 cmp al, SET
 je near EndKeyboardProc
 cmp al,BOX
 je near EndKeyboardProc
 cmp al,TARGET
 je ProcessSetTarget
ProcessSetEmpty:
 call SaveMove
 mov BYTE [edx],BOX
 mov BYTE [edi],PLAYER_TARGET
 and BYTE [esi],11b
 add DWORD [PlayerX],ebx
 add DWORD [PlayerY],ecx
 jmp RedrawLevel
ProcessSetTarget:
 call SaveMove
 mov BYTE [edx],SET
 mov BYTE [edi],PLAYER_TARGET
 and BYTE [esi],11b
 add DWORD [PlayerX],ebx
 add DWORD [PlayerY],ecx
 jmp RedrawLevel
LevelCompleted:
 call Draw_level 
 mov eax,[CurrentLevel]
 cmp eax,NUMBERLEVELS - 1
 je GameWon
 mov esi,NextLevelBlurb
 mov edi,0xA0000 + (320*93) + 65
 mov al,11
 externfunc gfx.render.13h.string
 externfunc debug.diable.wait
 inc DWORD [CurrentLevel]
 call Unpack_level
 call Draw_level 
 jmp EndKeyboardProc
GameWon:
 mov esi,GameWonBlurb
 mov edi,0xA0000 + (320*93) + 65
 mov al,11
 externfunc gfx.render.13h.string
 externfunc debug.diable.wait
Quit:
 mov BYTE [QuitGame],1
 jmp EndKeyboardProc
RedrawLevel:
 call NumberBoxesSet
 cmp cl,[NumberToSet]
 je LevelCompleted
 call Draw_level
 inc DWORD [NumberMoves]
 call DrawMoveNumber
EndKeyboardProc:
 popad
 ret

NumberMoves:    DD 0 
CurrentLevel:   DD 0 
NumberToSet:    DB 0
PlayerX:        DD 0
PlayerY:        DD 0
QuitGame:       DB 0
NextLevelBlurb: DB 'Press enter to proceed',10,'  to the next level.',0
GameWonBlurb:   DB '      Congratulations!',10,'You have beaten Blocked In!',0
