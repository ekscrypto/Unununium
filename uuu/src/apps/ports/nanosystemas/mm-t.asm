;NANOSISTEMAS <http://nsis.ath.cx>
;Vitoria - Brazil
;start: 10.MAY.1997
;
;
VERSAO  EQU     1       ;External functions (No.Update)
;
;
;Main program source code in i80386 Assembly language - MM.COM
;
;
;ABOUT THE SOURCE CODE:
;------------------------------------
;I'll assume that who will be reading this program and trying
;to understand its functioning, knows well the Assembly language,
;and knows at satisfactory level how the computer works.
;(how IT WORKS, not how to work with it).
;All the comments are here for facilitating the understanding
;of each proccess executed by the program, but the objetive is not
;to make it clear for readers who don't have the necessary knowledge.
;It isn't easy, even for experienced programmers, to understand
;a program made by another one, that uses different techniques.
;Fill yourself comfortable to read this program. Just know that in
;any moment were made any kind of optimizations to turn the source
;code clearly.
;
;------------------------------------
;LAST SIGNIFICANT MODIFICATION IN SOURCE CODE: (THU09SEP99,15:52)
;LAST SIGNIFICANT MODIFICATION IN PLANNING:    (FRI22MAY98,20:16)
;
;To work this program needs:
;
;- Intel 80386 or later compatible processor.
;- VESA video card, that supports at least the mode 100h (640x400x256).
;- MS-DOS 3.0 or later compatible operating system.
;- A 64KB block of conventional memory for the load of code by DOS.
;- Interrupt vectors working accordding the IBM-PC standards:
;  INT 21h compatible with MS-DOS 3.0 or later
;  INT 10h with the subfunctions of function 4Fh totaly accessible
;  INT 1Ch being set in the frequency of 18.2 Hz
;  INT 08h System Timer IRQ 0 in 18.2 Hz
;  INT 16h Bios Keyboard with all its functions accessible
;- Other peripherals, like SVGA compatible monitor, PS/2 keyboard
;  with 101 keys, hard drive or something similar, and MS-Mouse.
;
;For a better experience with the program, is recommended:
;
;- A current processor, compatible with the Intel 80386 specifications.
;- VESA video card, with 1MB of memory.
;- MS-DOS 3.0+ operating system working in real mode (without Windows).
;- A free block of 500KB or more of conventional memory, for the load of
;  code and the background image the user choose.
;- SVGA monitor, NI (non-interlaced), with support for 1024x768 or higher.
;- Mouse compatible with MS-MOUSE standard (for direct reading), or
;  any pointing device if the user choose to use Mouse Driver.
;- All the system working in a hard drive, or in a fast disk unit
;  and that allows reading, writing and rewriting.
;
;
;
;The programmer who wishes to make any change or implementation
;in the code, or wishes to interpret or follow the functioning of
;any function contained in this program, will have to assume that
;each function was made (and must be made) according the following
;definitions:
;
;*      X resolution is given by CS:RX, and Y by CS:RY
;*      When changing the video page, is necessary to update
;       the page number. (CS:OFST)
;       To request the next page, use CALL NEXT.
;*      To initiate a LOOP, must be used ;LOOP1
;       and when finishing use ;END1 where 1 is an identification of the loop.
;*      The  nomenclature of labels is given as follows:
;       LOOPS: Lnnx (nn -> ID of routine where Loop is, x -> number of loop)
;       JUMPS: Jnnx (as above)
;       In case of needing, nn may be how many characters are needed
;*      For labels in general (buffers, routines and subroutines) there
;       are no rules.
;*      The limits determined by the perimeter CS:AEX,CS:AEY,CS:AEXX,CS:AEYY
;       must not be used, even if regulated by CS:AIX,CS:AIY,CS:AIXX,CS:AIYY.
;*      Every routine or function must have a header indicating
;       the inputs and outputs of registers and memory.
;*      The maximum size of the code file is of 60KB.
;*      OVERLAY(s) are not allowed in the COM code file
;*      XMS or EMS must not be allocated inside Nanosis, not even to
;       external use. Nanosis must not have to depend of memory larger than
;       64KB (code) and buffers of conventional memory.
;*      Nanosis must not depend of external programs or any driver
;       to work. Not even of operating system, mouse drivers,
;       memory managers or interrupt vectors not pertaining to BIOS,
;       except of INT 21h supplied by DOS.
;*      Every communication port, sound card I/O, modem, network, video,
;       hard disk or any control port to any device who will need
;       modification during  a internal routine of Nanosis, must be
;       restored to the way it was before.
;
;------------------------------------
;Below starts the code loaded by DOS.
;At this point, the program assumes:
;
;- Address of label INIC equal to CS:0100h
;- initial DS contains the segment of PSP (DS:0 contains the address of PSP)
;- PSP follow the defaults adopted by MS-DOS 3.0 or higher.

PROG   SEGMENT USE16 'CODE'
ASSUME CS:PROG
ORG    0100h
.386


;...AND ALL THIS BEGIN WITH A MOV..

INIC:   MOV     AX,0BEBAh       ;ID. to verify the validy of
        MOV     AX,0C0CAh       ;first bytes

        MOV     DSIN,DS         ;Capture initial DS (Segment PSP) - Although
                                ;in the COM file CS:0000 is the PSP address,
                                ;maybe this program becomes too big e turn
                                ;itself into a EXE.

        MOV     AX,0F000h       ;Verify processor 80386 or higher
	PUSH	AX
	POPF
	PUSHF
	POP	AX
	AND	AX,0F000h
        JNZ     CPUOK           ;Afirmative, jump. Processor OK.
        MOV     AH,9            ;Negative, show a message and finish.
        MOV     DX,OFFSET CPUER ;Processor inferior to 80386
	INT	21h
        RETN                    ;Finish. Return to DOS.

        CPUOK:                  ;Processor being OK, continues execution
	JMP     ALOC
INICI:  JMP     BGIN            ;Start the environment preparation

;CONSTANTS
;I.D.          Value     Description:
;----           ---      ----------------------------------------------------
MJAN    EQU     49      ;Max number of windows
FSIZ    EQU     5       ;Size (width X) of the lesser font
FALT    EQU     15      ;Height of each character (next line ADD)
MMWTS   EQU     35      ;Number of maximum characters of the window label
MMWXS   EQU     8       ;Size XYXXYY of each window (8 bytes, 4 words)
MMWCS   EQU     20      ;Size in bytes of the config of each window
ICOTS   EQU     22      ;Max number of chars in the label of icon
ICOBS   EQU     1024    ;Size in bytes to each bitmap of each icon
ICOPS   EQU     72      ;Max number of chars of the path and filename of each icon
ICODS   EQU     72      ;Max number of chars of current directory
ICORS   EQU     10      ;Size of the reserved area of each icon
;------------------------------------
;Checksum
CSID	DB	'=>'	;Identification of the checksum
 init
CSUM	DD	0	;Verification (ADD) CHECKSUM
CCSM	DB	0	;Verify checksum? (0=YES, XX=NO)
;BEGIN: Area not verified by checksum
L17H    DB      0       ;Initial state of flags NUMLOCK,CAPSLOCK e SCROLL LOCK
BMEC	DW	0	;Buffer segment of 13456 bytes for manipulator of critical error
SSIN	DW	0	;Initial SS
SPIN	DW	0	;Initial SP
DSIN    DW      0       ;PSP segment (initial DS)
SYSPATH:DB   79 dup (?)	;Path of MM.COM file (captured in the moment of execution)
;END: Area not verifed by checksum
CHECKST:		;Begin of bytes to be checked (checksum)
;------------------------------------
SAVEBGN:		;Begin of bytes to save in configuration file (MM.CFG)
CCFG	DW	0	;Checksum of CFG
 file
;I/O CONFIGURATION
UART    DW      3F8h    ;UART address (Mouse port)
SRES    DW      103h    ;initial resolution (mode VESA SVGA)
;CONFIGURATION OF VISIBLE ENVIRONMENT
FULL	DB	0	;FULLMOVEMENT? 0=No, 1=Yes
BMPY	DB	1	;Use background BMP if available? (0=No, 1=Yes)
SHCD	DB	1	;Show CD PLAYER if available? 0=No, 1=Yes
BDMC	DB	1	;Right button moves CD PLAYER? 0=No, 1=Yes
BANI	DB	0	;Use animation as background (0=No,1=Yes)
BACV	DB	0	;Without background image (0=No,1=Yes)
CMSE	DB	0	;Mouse control (0=Auto, 1=Mouse Driver, 2=Direct Reading)
JMD1	DB	0	;Window - MOUSE NOT FOUND (1=Don't show again, 0=Always)
MPOR	DB	0	;Mouse port. 1=3F8h,2=2F8h,3=3E8h,4=2E8h,5=custom. 0 = Autodetect
VIRU	DB	1	;Verify possible virus? (0=No, 1=Yes)
BMPN:	DB 'MM.BMP',73 dup (0)	;BMP
 filename
CUSP:	DB '3F8h',0,0,0		;Port defined by user (Direct Reading)
VDOU	DB	3	;doubleclick
 speed
UACE	DB	1	;Use mouse acceleration in direct reading? (1=Yes,0=No)
ACEL	DB	15	;Mouse acceleration in direct reading
SMAX	DB	128d	;Max size of cursor jump in direct reading
CDPX	DW	150d	;X position of CD PLAYER. From 100..RX-230
TLAR    DW      16      ;Height of upper bar
TJBL    DB      01      ;Label of window (00=Normal, 01=Bold)
TBSZ    DW      16      ;Thickness of title bar

CORST:
;COLORS - DESKTOP
TXTC	DB	00	;Foreground color of texts (in general)
TBCR	DB	15	;Background color of message boxes
TCIB	DB	00	;Foreground color of binary icons
TCOR    DB      15      ;Color of top bar
TXCR    DB      00      ;Color of top bar texts
TXBF    DB      15      ;Background color of textboxes
TBCT    DB      00      ;Color of texts in textboxes
BORD    DB      00      ;Color of borders (in general)
BGND    DB      07      ;Background color

;COLORS - WINDOWS
CJSB    DB      07      ;Color of windows scroll bars
CJIS    DB      07      ;Background color - text of selected icons
CJFS    DB      00      ;Foreground color - text of selected icons
CJIN    DB      00      ;Foreground color - text of unselected icons
CJFN    DB      15      ;Background color of window (icons area)
CJFE    DB      15      ;Color of top and bottom bands (title bar)
CJFC    DB      07      ;Color of center band (title bar)
CJFT    DB      00      ;Color of text of title bar
INTC    DB      08      ;Color of band between title bar and window
;Begin of bytes of 16 RGB colors of system
RGBVAL  DB      0,0,0           ;Definition of system defaults
	DB	0,0,42
	DB	0,42,0
	DB	0,42,42
	DB	42,0,0
	DB	42,0,42
	DB	42,42,0
	DB	42,42,42
	DB	0,0,21
	DB	0,0,63		
	DB	0,42,21
	DB	0,42,63
	DB	42,0,21
	DB	42,0,63
	DB	42,42,21
	DB	63,63,63

COREN:

;IMAGE FADE
;GENERAL CONTROL
FADEST:
EXIR    DB      1               ;Show red
EXIG    DB      1               ;Show green
EXIB    DB      1               ;Show blue

;RED CONTROL
RCORI   DB      00              ;Initial color (Initial position)
RCORS   DB      1               ;State (position) of initial color (0=INC,1=DEC)
RINTE   DB      INRM            ;Initial intensity
RINTS   DB      0               ;Intensity state (0=INC,1=DEC)
RINTM   DB      INRM            ;Minimum intensity
RSTEP	DB	1		;Stepsize
RSIZY	DB	3fh		;Size Y (1..63)
RCPLS	DB	2		;Thickness of each line (1=def)

;GREEN CONTROL
GCORI	DB	50		;Initial color (Initial position)
GCORS	DB	0		;State (position) of initial color (0=INC,1=DEC)
GINTE	DB	INGM		;Initial intensity
GINTS	DB	0		;Intensity state (0=INC,1=DEC)
GINTM	DB	INGM		;Minimum intensity
GSTEP	DB	1		;Stepsize
GSIZY	DB	3fh		;Size Y (1..63)
GCPLS	DB	1		;Thickness of each line (1=def)

;BLUE CONTROL
BCORI	DB	90		;Initial color (Initial position)
BCORS	DB	0		;State (position) of initial color (0=INC,1=DEC)
BINTE	DB	INBM		;Initial intensity
BINTS	DB	0		;Intensity state (0=INC,1=DEC)
BINTM	DB	INBM		;Minimum intensity
BSTEP	DB	1		;Stepsize
BSIZY	DB	3fh		;Size Y (1..63)
BCPLS	DB	2		;Thickness of each line (1=def)
FADEFIM:

SAVEEND:		;End of bytes to save in configuration file (MM.CFG)
;----------------------------------------------------------------------------------
;Internal use variables
MOUS	DB	0	;Mouse Control (0=UART,1=MOUSE DRIVER)	
CDOK	DB	0	;is MSCDEX available to play CDs? 0=No, 1=yes
BMPD	DB	0	;is a background BMP available? (0=No,1=yes)
CATE	DW	0	;"A" Counter - (IN)  Input (Current) Be careful	
CATS	DW	0	;"A" counter - (OUT) Output (Max/Dev) 'l's Counters! 
CBTE	DB	0	;"B" counter - (IN)  input (current) being destroyed
CBTS	DB	0	;"B" counter - (OUT) output (Max/dev) all routines
USEF	DB	0	;Use USEF font number (0=big font,1=small font)
WINM	DB	0	;Presentation mode of the window (MACW old routine)
DMAL	DB	0	;Maximize 'AI' to track last window and REWRITE? (0=Yes, XX=No)
EXEP	DB	0	;Run program? 0=No, 1=yes
DCLK	DB	0	;DoubleClick timer
TEMP	DW	0	;Timer (for any routine use) warning!
TMP1	DW	0	;Timer (for any routine use) same as counters,
TMP2	DW	0	;Timer (for any routine use) all routines use this variables!
ALTX	DB	0	;ALT+X enabled? (0=yes, 1=NO)
OL24	DD	0	;Real interrupct INT 24h
OL2F	DD	0	;real interrupt INT 2Fh
OL1C	DD	0	;real interrupt INT 1Ch
OL10	DD	0	;real interrupt INT 10h 
OL06	DD	0	;real interrupt INT 06h - Invalid Opcode
OL00	DD	0	;real interrupt INT 00h - Division by Zero
OL09	DD	0	;real interrupt INT 09h - Keyboard handler
BUFA	DW	0	;Size (in 'paragrafos') of the background BMP buffer 
RSEG	DW	0	;READ segment of video memory
WSEG	DW	0	;SAVING segment of video memory
RJAN	DB	0	;Window for the READ of video memory
WJAN	DB	0	;Window for the SAVING in video memory
OEMS	DW	0	;string segment of the video OEM
OEMO	DW	0	;string Offset of video OEM
VVER	DW	0	;VESA version
TMVD	DW	0	;total of video memory (64kb blocks)
RESB	DW 100h,101h,103h,105h,107h,201h,203h,205h,0FFFFh	;permited graphical resolutions
RESN	DB 'VESA 640x400x256  ',13d ;19x8bytes TXT
	DB 'VESA 640x480x256  ',13d
	DB 'VESA 800x600x256  ',13d
	DB 'VESA 1024x768x256 ',13d
	DB 'VESA 1280x1024x256',13d
BNMR	DW	0	;max number of found resolutions (number of valid words in RESP buffer)
RESP	DW 10 dup (0FFFFh);graphical resolutions by Nanosistemas and 
RESPE:			  ;user video card

;DEFINITIONS OF PERMITED PERIMETER
RAE	DB	0	;exclusion area to be 'respected' (0=YES, 1=NO)
RAI	DB	0	;inclusion area to be respected (0=YES, 1=NO)
AEX	DW	0	;exclusion area, X position
AEY	DW	0	;exclusion area, Y position
AEXX	DW	0	;exclusion area, XX position
AEYY	DW	0	;exclusion area, YY position
AIX	DW	0	;inclusion area, X position
AIY	DW	0	;inclusion area, Y position
AIXX	DW	0	;inclusion area, XX position
AIYY	DW	0	;inclusion area, YY position
;OBS: O tamanho X e Y da tela grafica estao em CS:RX e CS:RY
;     (veja o final do programa)

;START OF INTERNAL FUNCTIONS AND ROUTINES

;-------------------------------------------------------------
;Refresh video pelette
;Nanosistemas. set-up video routine
;			
;Based on the DS:SI buffer, redefine 16 colors palette
;of Nanosistemas as a System Default for IBMPC VESA BIOS.
;the colors are restaured: system powerup 
;			   system powerdown
;			   system colors set up

SYSPLT: PUSHA
	XOR	AL,AL
	MOV	DX,3C8h 	;first color: ZERO (#0)
	OUT	DX,AL

	MOV	DX,3C9h
	MOV	CX,16*3d	;starting redefinition sequence, 16 colors
	REP	OUTSB
	POPA
	RET

;-------------------------------------------------------------
;Interupt 24h (VET.0000:0090h)
;Nanosistemas. critical error manager
;
;Apenas pode ser acessado pelo DOS atraves de INT 24h
;com a pilha na seguinte forma:
;
;FLAGS	:-- 
;CS	:Flags,CS and IP located in a stack pelo INT 21h emitido pelo caller
;IP	:--
;ES	:Abaixo, ES,DS,BP,DI,SI,DX,CX,BX and AX dados a INT 21h pelo caller
;DS
;BP
;DI
;SI
;DX
;CX
;BX
;AX
;FLAGS	:--
;CS	:Flags,CS e IP colocados na pilha pela INT 21h quando chamou INT 24h
;IP	:--
;
;Input: in DOS the call to INT 24h is in this way:
;	(Descrito apenas o que o manipulador do Nanosis considera)
;
;	AH	: Bit 7 : 0=Erro de disco
;			: 1=Erro em outro dispositivo
;		: Bit 1-2 00=Erro ocorreu na area do DOS
;		:	  10=Erro ocorreu na FAT
;		:	  11=Erro ocorreu na area de arquivos
;		: Bit 0 : 0=Erro ocorreu em operacao de leitura
;		:	: 1=Erro ocorreu em operacao de escrita
;	AL	: Codigo da unidade (0=A,1=B..)
;	DI	: Bits 0..7 : Codigo do erro:
;		: 00h	= Disco Protegido
;		: 01h	= Unidade desconhecida
;		: 02h	= Drive nao pronto
;		: 03h	= Comando invalido
;		: 04h	= CRC error
;		: 05h	= Tamanho da estrutura de solicitacao invalida
;		: 06h	= Erro na pesquisa
;		: 07h	= Midia invalida
;		: 08h	= Setor nao encontrado
;		: 09h	= Impressora sem papel
;		: 0Ah	= Falha de escrita
;		: 0Bh	= Falha de leitura
;		: 0Ch	= Falha geral
;
;Retorna: O manipulador de erro interno do Nanosistemas vai apresentar
;	  ao usuario uma janela com duas opcoes:
;	  RETRY ou CANCELA.
;	  Escolhendo RETRY, o manipulador vai apenas colocar AL=1 
;	  e executar um IRET sem mexer na pilha, mandando o DOS
;	  tentar novamente a operacao.
;	  Escolhendo CANCEL, o manipulador vai retornar ao caller
;	  como se estivesse retornando da INT, e vai colocar o flag
;	  de Carrier = 1, avisando que houve erro.
;
;OBS:	Este manipulador de erro critico sempre assume que o usuario
;	esta em modo grafico e com as rotinas do Nanosistemas carregadas
;	na memoria.
;
;

;MAERCR - Interrupcao 24h
;Icones (32x13)
	
MMEC0:	DB	'I/O ERROR',0
MMEC1:	DB	'Error Reading',0
MMEC2:	DB	'Error Recording',0
MMEC4:	DB	'drive X:',0
MMEC5:	DB	'RETRY	   CANCEL',0


MEMEC:	DB	'Disk is Protected',0
	DB	'Invalid Drive',0
	DB	'Drive Not Ready',0
	DB	'Invalid Command',0
	DB	'CRC error',0
	DB	'Bad request header',0
	DB	'Seek Error',0
	DB	'Invalid Midia',0
	DB	'Sector Not Found',0
	DB	'Printer Without Paper',0
	DB	'Write Failure',0
	DB	'Read Failure',0
	DB	'General Failure',0
	DB	'Unknown Error',0

MECT1	DB	0		;Temporario
MECT2	DB	0
MECT3	DW	0
MECT4	DW	0
MECX	DW	0		;Posicao X e Y da janela / X Y Window Position
MECY	DW	0

MECAH	DB	0		;AH inicial
RLIM	DW	0		;Respeitar limites (buffer)

MAERCR: PUSHA			
	PUSH	DS
	PUSH	ES
	
	PUSH	AIX		;Salva os limites do video
	PUSH	AIY
	PUSH	AIXX
	PUSH	AIYY
	
	MOV	MECAH,AH	;Grava AH inicial
	MOV	BYTE PTR CS:[OFFSET MMEC4+6],AL ;Grava letra da unidade
	ADD	BYTE PTR CS:[OFFSET MMEC4+6],65d;onde deu erro
	
	PUSH	AX		;Salva o que for alterar na memoria
	MOV	AL,USEF
	MOV	AH,CBGT
	MOV	MECT1,AL
	MOV	MECT2,AH
	POP	AX
	
	CALL	CHIDE		;Retira cursor do mouse
	
	PUSH	DI
	MOV	DX,073d 	;Grava o que esta por traz da janela
	MOV	CX,184d 	;para restaurar depois

	MOV	CS:NCMSX,CX	;Calcula posicoes onde a janela vai aparecer / Calculate position where the window will show up
	MOV	CS:NCMSY,DX

	MOV	BX,CS:RX	;Prepara registradores
	SHR	BX,1
	MOV	AX,NCMSX
	SHR	AX,1
	SUB	BX,AX
	MOV	AX,CS:RY
	SHR	AX,1
	MOV	DI,NCMSY
	SHR	DI,1
	SUB	AX,DI
		
	MOV	MECX,BX 	;Grava posicoes X e Y da janela / Save X Y Window position
	MOV	MECY,AX
	
	MOV	ES,BMEC 	;Copia video para o buffer		
	XOR	DI,DI
	CALL	CAPMAP
	POP	DI
	
	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	DX,071d 	;Desenha janela / 'Goodbye' Window :)
	MOV	CX,179d
	MOV	AIXX,0
	CALL	NCMS
	CALL	NCMS
	
	ADD	AX,12		;Escreve texto
	ADD	BX,17
	XOR	CH,CH
	MOV	CL,TXTC
	MOV	USEF,1
	MOV	CBGT,0FFh
	PUSH	CS
	POP	DS

	TEST	MECAH,10000000b ;Verifica se foi erro de disco
	JNZ	JMEC2		;Negativo, pula
	PUSH	BX
	PUSH	AX		;Afirmativo, mostra mensagem: ERRO
	TEST	MECAH,1b	;Verifica se foi leitura ou gravacao
	JZ	JMEC3		;Pula se for LEITURA
	MOV	SI,OFFSET MMEC2 ;Gravacao:
	CALL	TEXT
	ADD	BX,14*5
	JMP	JMEC4
	JMEC3:
	MOV	SI,OFFSET MMEC1 ;Leitura:
	CALL	TEXT
	ADD	BX,11*5
	JMEC4:
	MOV	SI,OFFSET MMEC4 ;Mostra mensagem: DRIVE X:
	CALL	TEXT
	POP	AX
	POP	BX
	JMEC2:
	
	PUSH	AX
	MOV	DX,DI
	AND	DX,11111111b	;Calcula mensagem de erro
	CMP	DX,12d		;Verifica se e' erro desconhecido
	JNA	JMEC5		;Negativo, pula
	MOV	DX,13d		;Afirmativo, marca para mostrar msg: ERRO DESCONHECIDO
	JMEC5:
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET MEMEC
	OR	DX,DX
	JZ	JMEC0		
	CLD
	;LOOP1
	LMEC0:
	XOR	AL,AL
	MOV	CX,0FFFFh
	REPNZ	SCASB
	DEC	DX
	JNZ	LMEC0
	;END1
	JMEC0:
	PUSH	ES
	POP	DS
	MOV	SI,DI
	POP	AX
	;Em DS:SI o endereco da string ASCIIZ da mensagem de erro
	ADD	AX,15d
	XOR	CH,CH
	MOV	CL,TXTC
	CALL	TEXT		;Escreve mensagem de erro
	
	MOV	AH,TXTC
	MOV	AL,TBCR
	MOV	DI,AX
	MOV	AX,MECY 	;Escreve RETRY	CANCEL
	MOV	BX,MECX
	ADD	AX,49
	ADD	BX,20
	XOR	CH,CH
	MOV	CL,TXTC
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET MMEC5
	MOV	USEF,0
	CALL	TEXT
	INC	BX
	CALL	TEXT

	CALL	CSHOW		;Recoloca cursor do mouse
	
	POP	AIYY		;Restaura limites
	POP	AIXX
	POP	AIY
	POP	AIX
	
	LMEC1:
	;-----------------

	PUSH	SI
	PUSH	DI
	PUSH	DS
	PUSH	ES	
	PUSHF
	CALL	LM00		;Chama rotina de controle do mouse
	POPF
	POP	ES
	POP	DS
	POP	DI
	POP	SI

	TEST	BX,11b		;Verifica se saiu com click do mouse
	JZ	JTECLA		;Negativo, pula
	MOV	BX,MECX 	;Afirmativo, verifica se clicou em RETRY ou CANCEL
	CMP	CX,BX		;Verifica se o click saiu fora da janela		
	JNA	LMEC1		;Pula sempre que afirmativo	
	ADD	BX,180d
	CMP	CX,BX
	JA	LMEC1
	MOV	BX,MECY
	ADD	BX,49d
	CMP	DX,BX
	JNA	LMEC1
	ADD	BX,22
	CMP	DX,BX
	JA	LMEC1
	MOV	BX,RX		;Verifica se o click foi em RETRY ou CANCEL		
	SHR	BX,1
	CMP	CX,BX
	JA	JABORT		;Cancel
	JMP	JRETRY		;Retry
	;Scancodes (AH):
	;A=30d
	;R=19d
	;ESC=1
	;ENTER=28d
	JTECLA:
	CMP	AH,19d		;Verifica teclas
	JZ	JRETRY
	CMP	AH,30d		
	JZ	JABORT
	CMP	AH,1
	JZ	JABORT
	CMP	AH,28d
	JZ	JRETRY
	JMP	LMEC1
	
	;-----------------
	JRETRY:
	CALL	MECRJ		;Retira janela do video
	POP	ES		;Retry
	POP	DS
	POPA
	MOV	AL,1		;Marca: Retry
	IRET			;Volta controle para o DOS
	
	;-----------------
	JABORT:
	CALL	MECRJ		;Retira janela do video
	POP	ES		;Abort
	POP	DS
	POPA

	POP	AX		;Restaura a pilha
	POP	AX
	POP	AX
	POP	AX
	POP	BX
	POP	CX
	POP	DX
	POP	SI
	POP	DI
	POP	BP
	POP	DS
	POP	ES
	
	POP	MECT3		;Marca o flag CARRIER indicando erro
	POP	MECT4
	POPF
	STC
	PUSHF
	PUSH	MECT4
	PUSH	MECT3

	IRET			;Retorna ao caller

;Subrotina interna: Exclusiva do manipulador de erro critico
;Retira a janela de erro do video
;Entra: NADA
;RetornaL NADA
MECRJ:	PUSHA
	PUSH	DS
	PUSHF
	
	CALL	CHIDE		;Retira cursor do mouse
	
	PUSH	WORD PTR CS:[OFFSET RAE]
	MOV	RAI,1
	MOV	RAE,1
	
	MOV	AX,MECY 	;Restaura o que estava atraz da janela
	MOV	BX,MECX
	MOV	CX,184d
	MOV	DX,073d
	MOV	DS,BMEC
	XOR	SI,SI
	CALL	BITMAP
	
	CALL	CSHOW		;Recoloca cursor do mouse
	
	POP	WORD PTR CS:[OFFSET RAE]
	
	POPF
	POP	DS		;Finaliza e retorna
	POPA
	RET
	
;-------------------------------------------------------------
;NANOSISTEMAS. Dados do sistema.
;
;Preenche um buffer de memoria com dados sobre o sistema.
;
;Entra: AL	: Numero do buffer desejado
;	ES:DI	: Endereco do buffer 
;Retorna:
;	DS:SI	: Endereco do buffer solicitado, na memoria do Nanosistemas.
;	Buffer em ES:DI preenchido com os dados solicitados
;
;Buffer em ES:DI retornara da seguinte forma:
;
;Buffer 00h:	;Informacao VESA
;GRAN	DW	;Granularidade do video
;PSIZ	DW	;Tamanho de cada pagina de video
;SEGA	DW	;Segmento da janela "A" de video
;SEGB	DW	;Segmento da janela "B" de video
;POIN	DD	;Endereco da funcao de troca de pagina de video
;BPSL	DW	;Bytes por linha
;RX	DW	;Resolucao horizontal em pixels
;RY	DW	;Resolucao vertical em pixels
;
;Buffer 01h:	;Cores DESKTOP	
;TXTC	DB	;Cor de frente dos textos (em geral)
;TBCR	DB	;Cor de fundo das caixas de mensagens
;TCIB	DB	;Cor de frente icones binarias
;TCOR	DB	;Cor da barra superior
;TXCR	DB	;Cor dos textos da barra superior
;TXBF	DB	;Cor de fundo das textboxes
;TBCT	DB	;Cor dos textos das textboxes
;BORD	DB	;Cor das bordas (em geral)
;BGND	DB	;Cor do background
;
;Buffer 02h:	;Cores - JANELAS
;CJSB	DB	;Cor da scroll bar das janelas
;CJIS	DB	;Cor de fundo - texto icones selecionadas
;CJFS	DB	;Cor de frente - texto icones selecionadas  
;CJIN	DB	;Cor de frente - texto icones nao selecionadas
;CJFN	DB	;Cor de fundo da janela (area das icones)
;CJFE	DB	;Cor das faixas superior e inferior (barra de titulo)
;CJFC	DB	;Cor da faixa central (barra de titulo)
;CJFT	DB	;Cor do texto da barra de titulo
;INTC	DB	;Cor da listra entre a barra de titulo e a janela
;
;Buffer 03h:	;Lista de modos graficos permitidos (pela placa e pelo sistema)
;MODOS	DW	;10 words contendo os numeros dos modos de video. Word=FFFF termina lista.
;
;Buffer 04h:	;Limites permitidos (Area de Inclusao e Area de Exclusao)
;AEX	DW	;Area de EXCLUSAO, posicao X inicial
;AEY	DW	;Area de EXCLUSAO, posicao Y inicial
;AEXX	DW	;Area de EXCLUSAO, posicao X final
;AEYY	DW	;Area de EXCLUSAO, posicao Y final
;AIX	DW	;Area de INCLUSAO, posicao X inicial
;AIY	DW	;Area de INCLUSAO, posicao Y inicial
;AIXX	DW	;Area de INCLUSAO, posicao X final
;AIYY	DW	;Area de INCLUSAO, posicao Y final
;
;Buffer 05h:	;Diretorio (path) do sistema.
;PATH	DB	;String ASCIIZ de 79 caracteres
;
;
;Tabela:	OFFSET,     TAMANHO
BUFINF: DW	OFFSET GRAN,18d
	DW	OFFSET TXTC,09d
	DW	OFFSET CJSB,09d
	DW	OFFSET RESP,20d
	DW	OFFSET AEX,16d
	DW	OFFSET SYSPATH,79d
	
INFOS:	PUSH	BX
	PUSH	CX
	PUSH	DI
	
	MOVZX	BX,AL	;Copia buffer para a memoria especificada
	SHL	BX,2
	MOV	SI,WORD PTR CS:[OFFSET BUFINF+BX]
	MOV	CX,WORD PTR CS:[OFFSET BUFINF+BX+2]
	PUSH	CS
	POP	DS
	CLD
	PUSH	SI
	REP	MOVSB
	POP	SI
	
	POP	DI
	POP	CX	;Finaliza e retorna
	POP	BX
	RET		

;-------------------------------------------------------------
;NANOSISTEMAS. "Caller" INT 10h
;Acesso aos programas do sistema.
;
;Executa a chamada a INT 10h real.
;
;Entra: Parametros a serem passados a INT 10h
;Retorna: Respostas oriundas da INT 10h
;
;OBS: Chamadas diretas a INT 10h nao serao realizadas.
;
INT10H: PUSHF
	CALL	OL10
	RET
	
;-------------------------------------------------------------
;NANOSISTEMAS. Manipulador INT 09h
;Acesso apenas externo, via INTR-PIC
;

MAIN09: PUSHA		;INT 9 IRQ 1 Interrupcao do Teclado
	PUSHF

	;Le o scan code da porta do teclado
	IN	AL,60h
	;Em AL o SCAN CODE da tecla pressionada
	
	;Processa CONTROL	
	CMP	AL,29d
	JNZ	J9C0
	MOV	CONTR,1
	J9C0:
	CMP	AL,157d
	JNZ	J9C1
	MOV	CONTR,0 
	J9C1:
	
	;Processa ALT
	CMP	AL,56d
	JNZ	J9A0
	MOV	ALT,1
	J9A0:
	CMP	AL,184d
	JNZ	J9A1
	MOV	ALT,0 
	J9A1:
	
	;Processa DEL
	CMP	AL,82d
	JNZ	J9D0
	MOV	DEL,1
	J9D0:
	CMP	AL,170d
	JNZ	J9D1
	MOV	DEL,0 
	J9D1:

	;Verifica se a sequencia CONTROL ALT DEL esta pressionada
	CMP	DWORD PTR CS:[OFFSET CAD],01010101h
	JNZ	J9CAD0		;Pula se negativo
	CMP	ALTX,0		;Verifica se esta no Nanosistemas,
	JNZ	J9CAD1		;sem programas externos. Negativo, pula 
	MOV	AL,20h		;Libera PIC
	OUT	20h,AL
	POPF			;Afirmativo, ignora o C.A.D.
	POPA
	STI
	IRET			;Retorna
	J9CAD1:

	;Ctrl+Alt+Del pressionado e aceito:	 
	POPF			;Restaura registradores no momento
	POPA			;do trap
	LES	DI,CFAR
	MOV	AX,20CDh
	STOSW		;LES DI,CFAR aqui em cima hein!
	POP	AX
	POP	AX
	PUSH	CFAR
	CALL	MAXL		;Restaura desktop 
	CALL	REWRITE
	MOV	AL,20h		;Libera PIC
	OUT	20h,AL
	STI
	IRET			;Retorna para finalizar o programa
	
	;Prossegue normalmente, retorna controle a INT 9 real
	J9CAD0:
	POPF
	POPA
	JMP	DWORD PTR CS:[OFFSET OL09]

;CONTROL ALT DEL STATUS:
;0 = Released, 1 = Pressed	 SCANCODES:			
CAD:				;PRESSED RELEASED
CONTR	DB	0		;#29	 #157
ALT	DB	0		;#56	 #184
DEL	DB	0		;#83	 #170
	DB	1

;-------------------------------------------------------------
;NANOSISTEMAS. Manipulador INT 10h
;Acesso apenas externo.
;
;Impede que a INT 10h seja indevidamente utilizada por programas externos.
;
MAIN10: CMP	AH,0Eh			;Nao permite que INT 10h func 0Eh seja utilizada
	JZ	JMAIN10F
	CMP	AH,13h
	JZ	JMAIN10F
	CMP	AH,09h
	JZ	JMAIN10F
	CMP	AH,0Ah
	JZ	JMAIN10F
	JMP	OL10			;Chama INT 10h real	
	JMAIN10F:
	IRET

;-------------------------------------------------------------
;NANOSISTEMAS. Manipulador INT 06h
;Acesso apenas externo.
;
;Gerencia as excecoes INVALID OPCODE
FM0:	DB	'Division Overflow',0
FM1:	DB	'Invalid Opcode   ',0
EXFN:	DB	'FAULT.BMP',0

FAIL6:	DB	8,0FFh,0FFh,32,18
	DW	1,OFFSET FAILI
	DB	4,3,'NSIS EXCEPTION HANDLER: '
FMSG:	DB	'		  ',13,13,5,5
	DB	'WARNING: Program has crashed.',13
	DB	'CS: ',9
	F6CS	DW	0
	DB	'   IP: ',9
	F6IP	DW	0
	DB	'   SS: ',9
	F6SS	DW	0
	DB	'   SP: ',9
	F6SP	DW	0
	DB	13,'AX: ',9
	F6AX	DW	0
	DB	'   BX: ',9
	F6BX	DW	0
	DB	'   CX: ',9
	F6CX	DW	0
	DB	'   DX: ',9
	F6DX	DW	0
	DB	13,'DS: ',9
	F6DS	DW	0
	DB	'   SI: ',9
	F6SI	DW	0
	DB	'   ES: ',9
	F6ES	DW	0
	DB	'   DI: ',9
	F6DI	DW	0
	DB	13,'BP: ',9
	F6BP	DW	0
	DB	'   FS: ',9
	F6FS	DW	0
	DB	'   GS: ',9
	F6GS	DW	0
	DB	13,13,5,5
	DB	'Bytes at CS:IP (HEXADECIMAL)',13
F6BY	DB	10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' '	
	DB	10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' ',10d,6,' '	
	DB	0
	
FAILI:	DD	00000000000000010000000000000000b
	DD	00000000000000010000000000000000b
	DD	00000000000000111000000000000000b
	DD	00000000000000111000000000000000b
	DD	00000000000001111100000000000000b
	DD	00000000000001110100000000000000b
	DD	00000000000011100110000000000000b
	DD	00000000000011001110000000000000b
	DD	00000000000110001111000000000000b
	DD	00000000000100011111000000000000b
	DD	00000000001000000001100000000000b
	DD	00000000001111100011100000000000b
	DD	00000000011111100111110000000000b
	DD	00000000011111001111110000000000b
	DD	00000000111110011111111000000000b
	DD	00000000111100111111111000000000b
	DD	00000001111101111111111100000000b
	DD	00000001111111111111111100000000b

MAIN06: PUSHA			;Copia mensagem de erro para o buffer
	PUSH	ES
	PUSH	DS
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET FM1
	MOV	DI,OFFSET FMSG
	MOV	CX,17d
	CLD
	REP	MOVSB
	POP	DS
	POP	ES
	POPA
	JMP	EXCEPT

MAIN00: PUSHA			;Copia mensagem de erro para o buffer
	PUSH	ES
	PUSH	DS
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET FM0
	MOV	DI,OFFSET FMSG
	MOV	CX,17d
	CLD
	REP	MOVSB
	POP	DS
	POP	ES
	POPA
	;SEGUE PARA EXCEPT.. (flows)
	
EXCEPT: MOV	F6AX,AX
	MOV	F6BX,BX
	MOV	F6CX,CX
	MOV	F6DX,DX
	MOV	F6SS,SS
	MOV	F6SP,SP
	MOV	F6ES,ES
	MOV	F6DI,DI
	MOV	F6DS,DS
	MOV	F6SI,SI
	MOV	F6BP,BP
	MOV	F6FS,FS
	MOV	F6GS,GS
	;Le CS:IP de onde veio a falha e poe em DS:SI e F6CS:F6IP
	MOV	BX,SP
	MOV	SI,WORD PTR SS:[BX]
	MOV	F6IP,SI
	MOV	DS,WORD PTR SS:[BX+2]
	MOV	F6CS,DS
	
	PUSH	DS
	PUSH	SI
	
	;Copia os bytes em DS:SI (local da falha) para o buffer F6BY,
	;mas neste buffer, deve-se gravar um byte e pular 2, por
	;causa da estrutura de amostragem dos valores HEX.
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET F6BY+1
	MOV	CX,14
	CLI
	;LOOP
	LMAIN060:
	MOVSB
	ADD	DI,2
	LOOP	LMAIN060
	;END
	
	;Mensagem de texto pronta, com os numeros do erro.
	;Prosegue, mostrando a janela de erro
	
	PUSH	CS
	POP	DS
	
	CALL	MAXL			;Maximiza area de inclusao
	MOV	AX,0E07h		;BEEP warning the user
	CALL	INT10H	
	MOV	USEF,1		;Usar fonte normal
	CALL	CHIDE

	MOV	AX,50d
	MOV	BX,AX
	MOV	DX,198
	MOV	CX,300
	CALL	MWIN		;Desenha caixa de mensagem

	ADD	AX,15		;Escreve textos
	ADD	BX,15
	MOV	CH,0h
	MOV	CL,TXTC
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET FAIL6
	CALL	TEXT

	PUSH	CS		;Salva uma tela da falha
	POP	DS
	MOV	DX,OFFSET EXFN
	CALL	SSHOT
	
	CALL	MWINN		;Aguarda OK
	CALL	CSHOW
	CALL	MAXL
	CALL	REWRITE 	;Retira todas as janelas do desktop
	CLD			;Grava um INT 20h no lugar da falha
	POP	DI
	POP	ES
	MOV	AX,20CDh
	STOSW
	IRET			;Retorna
	
	
;-------------------------------------------------------------
;NANOSISTEMAS. Adaptacao da funcao TEXT para acesso externo.
TEXT2:	MOV	USEF,DL
	MOV	CBGT,DH
	CALL	TEXT

	RET
	
;-------------------------------------------------------------
;Nanosistemas. Manipulador para acesso externo as funcoes.
;Acesso apenas atraves de CALL FAR.
;
;
;COMO ACESSAR AS FUNCOES:
;-----------------------------
;De inicio, o seu programa deve conter (em qualquer parte do arquivo)
;a inscricao: NSISCODE0 (9 letras). 
;Quando for executado pelo Nanosistemas, ele vai encontrar essa identificacao
;e vai colocar logo depois o endereco CALL FAR para acessar as funcoes.
;Exemplo:
;
;INIC:	CMP	CFAR,0		;Verifica se o Nanosistemas esta presente
;	JZ	ERRO		;Negativo, pula
;
;	MOV	AX,1		;Prepara registradores
;	PUSH	16h		;para acessar uma funcao
;	(...)
;	CALL	CFAR		;Acessa funcao
;	POP	AX		;Retira da pilha
;	INT	20h		;Finaliza
;
;	DB	'NSISCODE0'	;Identificacao
;CFAR	DD	0		;Endereco do manipulador KERNEL
;	DD	0		;4 bytes reservados para uso futuro. Devem ser 0.	
;
;
;
;Em resumo:
;Ajuste registradores e memoria conforme queira,
;coloque na pilha operacional o numero da funcao (Ex: PUSH 16h),
;execute um CALL FAR para o endereco do manipulador KERNEL do Nanosistemas.
;O numero da funcao sera retirado da pilha.
;
;O sistema sera entregue ao programa da seguinte maneira:
;
;Area de inclusao maximizada e area de exclusao minimizada.
;Desktop apenas com as janelas, fundo (imagem bmp, fade ou cor) e barra
;superior. 
;Todos os bancos zerados.
;
;
;FUNCOES ACESSIVEIS EXTERNAMENTE:
;-----------------------------
;0000: MAXL
;0001: PUSHAE
;0002: POPAE
;0003: PUSHAI
;0004: POPAI
;0005: AUSB
;0006: AUSD
;0007: MOUSE
;0008: LTR1
;0009: CHIDE
;000A: CSHOW
;000B: POINT
;000C: LINEV
;000D: LINEH
;000E: RECT
;000F: RECF
;0010: NCMS
;0011: BITMAP
;0012: BINMAP
;0013: CRSMAP
;0014: CAPMAP
;0015: TEXT
;0016: MOPC
;0017: ROT1
;0018: SCRM
;0019: BROWSE
;001A: INPT
;001B: REWRITE
;001C: CBANK
;001D: ZBANKS
;001E: AJAE
;001F: LEAE
;0020: AJAI
;0021: LEAI
;0022: ABANK
;0023: INT10H
;0024: INFOS
;0025: SPATH
;0026: DOBGN
;

KEROBX	DW	0	;Buffer para BX
KERODI	DW	0	;Buffer para DI
KEREAX	DD	0	;Buffer para EAX
KERFNC	DW	0	;Numero da funcao

;SEEK TABLE para as funcoes
KERSEK	DW	OFFSET	MAXL
	DW	OFFSET	PUSHAEE
	DW	OFFSET	POPAEE
	DW	OFFSET	PUSHAIE
	DW	OFFSET	POPAIE
	DW	OFFSET	AUSB
	DW	OFFSET	AUSD
	DW	OFFSET	MOUSE
	DW	OFFSET	LTR1
	DW	OFFSET	CHIDE
	DW	OFFSET	CSHOW
	DW	OFFSET	POINT
	DW	OFFSET	LINEV
	DW	OFFSET	LINEH
	DW	OFFSET	RECT
	DW	OFFSET	RECF
	DW	OFFSET	NCMS
	DW	OFFSET	BITMAP
	DW	OFFSET	BINMAP
	DW	OFFSET	CRSMAP
	DW	OFFSET	CAPMAP
	DW	OFFSET	TEXT2
	DW	OFFSET	MOPC
	DW	OFFSET	ROT1
	DW	OFFSET	SCRM
	DW	OFFSET	BROWSE
	DW	OFFSET	INPT

	DW	OFFSET	REWRITE
	DW	OFFSET	CBANK
	DW	OFFSET	ZBANKS
	DW	OFFSET	AJAE
	DW	OFFSET	LEAE
	DW	OFFSET	AJAI
	DW	OFFSET	LEAI
	DW	OFFSET	ABANK
	DW	OFFSET	INT10H
	DW	OFFSET	INFOS
	DW	OFFSET	SPATH
	DW	OFFSET	DOBGN
	
;Inicio do manipulador KERNEL
KERNEL: MOV	KEROBX,BX		;Salva DI e BX que serao alterados abaixo
	MOV	KERODI,DI
	
	MOV	DI,SP			;Coloca em KERFNC o endereco da funcao
	MOV	BX,WORD PTR SS:[DI+4]
	SHL	BX,1
	MOV	DI,WORD PTR CS:[OFFSET KERSEK+BX]
	MOV	KERFNC,DI
	
	POP	KEREAX			;Retira numero da funcao da pilha
	POP	BX
	PUSH	KEREAX
	
	MOV	DI,KERODI		;Restaura DI e BX que foram alterados acima
	MOV	BX,KEROBX
	
	CALL	KERFNC			;Acessa a funcao solicitada

	RETF				;Retorna ao caller

;-------------------------------------------------------------
;NANOSISTEMAS. Funcao #1Eh - AJAE
;
;Ajusta area de exclusao.
;
;Entra: AX	: AEY  (Y inicial, 0FFFFh = Nao modifique este)
;	BX	: AEX  (X inicial, 0FFFFh = Nao modifique este)
;	CX	: AEXX (X final, 0FFFFh = Nao modifique este)
;	DX	: AEYY (Y final, 0FFFFh = Nao modifique este)
;Retorna: Nada

AJAE:	CMP	AX,0FFFFh
	JZ	JAJAE0
	MOV	AEY,AX
	JAJAE0:
	
	CMP	BX,0FFFFh
	JZ	JAJAE1
	MOV	AEX,BX
	JAJAE1:
	
	CMP	CX,0FFFFh
	JZ	JAJAE2
	MOV	AEXX,CX
	JAJAE2:
	
	CMP	DX,0FFFFh
	JZ	JAJAE3
	MOV	AEYY,DX
	JAJAE3:
	
	RET

;-------------------------------------------------------------
;NANOSISTEMAS. Funcao #1Fh - LEAE
;
;Le valores da area de exclusao.
;
;Entra:  Nada
;Retorna:AX	: AEY  (Y inicial)
;	 BX	: AEX  (X inicial)
;	 CX	: AEXX (X final)
;	 DX	: AEYY (Y final)

LEAE:	MOV	AX,AEY
	MOV	BX,AEX
	MOV	CX,AEXX
	MOV	DX,AEYY
	RET

;-------------------------------------------------------------
;NANOSISTEMAS. Funcao #20h - AJAI
;
;Ajusta area de inclusao.
;
;Entra: AX	: AIY  (Y inicial, 0FFFFh = Nao modifique este)
;	BX	: AIX  (X inicial, 0FFFFh = Nao modifique este)
;	CX	: AIXX (X final, 0FFFFh = Nao modifique este)
;	DX	: AIYY (Y final, 0FFFFh = Nao modifique este)
;Retorna: Nada

AJAI:	CMP	AX,0FFFFh
	JZ	JAJAI0
	MOV	AIY,AX
	JAJAI0:
	
	CMP	BX,0FFFFh
	JZ	JAJAI1
	MOV	AIX,BX
	JAJAI1:
	
	CMP	CX,0FFFFh
	JZ	JAJAI2
	MOV	AIXX,CX
	JAJAI2:
	
	CMP	DX,0FFFFh
	JZ	JAJAI3
	MOV	AIYY,DX
	JAJAI3:
	
	RET

;-------------------------------------------------------------
;NANOSISTEMAS. Funcao #21h - LEAI
;
;Le valores da area de inclusao.
;
;Entra:  Nada
;Retorna:AX	: AIY  (Y inicial)
;	 BX	: AIX  (X inicial)
;	 CX	: AIXX (X final)
;	 DX	: AIYY (Y final)

LEAI:	MOV	AX,AIY
	MOV	BX,AIX
	MOV	CX,AIXX
	MOV	DX,AIYY
	RET



;-------------------------------------------------------------
;NANOSISTEMAS. Rotina CBANK
;Acesso: CALL CBANK / EXTERNO
;
;Coloca o endereco em DS:DX no banco BL (BL = 1..12d)
;
;Esses bancos devem conter enderecos efetivos de memoria, que apontem
;para rotinas especificas. Por exemplo: Ajustando o banco 1 para um
;determinado endereco e executando a funcao INPT com DL=1, a cada
;tecla pressionada uma rotina especifica sera executada, permitindo
;assim que seja feito ajuste no texto, ou que certos caracteres sejam
;negados, ou demais operacoes.
;
;Todos os bancos sao entregues zerados ao programa executado, assim com
;sao zerados logo que o programa retorna.
;
;Todos os bancos sao executados pelo sistema atraves de um CALL FAR.
;Sendo assim, devem retornar usando um RETF.
;
;Os bancos de 1 a 10 sao para uso geral.
;
;Se o banco 11 estiver diferente de ZERO (conter algum endereco), o
;sistema vai executar um CALL FAR para o endereco contido nele 18.2 vezes
;por segundo. ATENCAO! Se este recurso nao for utilizado, este banco
;devera' conter ZERO. E a rotina que sera' executada 18.2 vezes por segundo
;devera' retornar TODOS os registradores (incluindo flags) sem alteracoes,
;e deve executar seu processo o mais rapido possivel.
;
;O banco 12 contem o endereco do manipulador do ALT+X. Se este banco estiver
;diferente de zero e ALT+X for pressionado, a rotina correspondente ao endereco
;contido neste banco sera executada.
;
BANKS:	DD 10 dup (0)	;10 bancos
BANK1C	DD	0	;Banco 11 - INT 1Ch
BANKAX	DD	0	;Banco 12 - ALT+X
BANK13	DD	0	;Banco 13 - Ready

CBANK:	PUSHA
	
	DEC	BL
	CMP	BL,12d	;Banco invalido, pula e finaliza
	JA	CBANKF
	
	SHL	BL,2	;BL*4
	XOR	BH,BH
	MOV	WORD PTR CS:[OFFSET BANKS+BX],DX
	MOV	WORD PTR CS:[OFFSET BANKS+BX+2],DS
	
	CBANKF:
	POPA
	RET

;Subrotina para uso externo: Zera todos os bancos.
;Entra NADA e retorna NADA
ZBANKS: PUSHA
	PUSH	ES
	
	PUSH	CS	;Grava ZERO em todos os bancos. 	
	POP	ES
	MOV	DI,OFFSET BANKS
	XOR	AL,AL
	MOV	CX,OFFSET CBANK - OFFSET BANKS
	REP	STOSB
	
	POP	ES
	POPA
	RET
	
;Subrotina: Acessa o banco em BX.
;Entra: BL = Numero do banco (1..12)
;Retorna: Nada.
BXMP	DW	0	;BX temp

ABANK:	PUSH	BX
	XOR	BH,BH
	DEC	BL
	CMP	BL,11d
	JA	JABANKF
	SHL	BL,2
	CALL	DWORD PTR CS:[OFFSET BANKS+BX]
	MOV	BXMP,BX ;Preserva o BX retornado pela funcao
	JABANKF:
	POP	BX
	MOV	BX,BXMP 
	RET

;-------------------------------------------------------------
;Nanosistemas. Rotinas ABMC e DBMC 
;Acesso: CALL ABMC
;
;ABMC:
;Aloca um buffer de 13456 bytes na memoria convencional para ser usado
;pelo manipulador de erro critico. Neste buffer o manipulador ira
;gravar o que vai estar atras de sua janela para restaurar apos
;a confirmacao RETRY/ABORT do usuario, e prosseguir com a
;execucao do sistema. 
;Esta funcao so vai alocar o buffer caso BMEC=0.
;OBS: Esta rotina deve ser chamada pelo sistema antes de tentar
;alocar buffer para a imagem de fundo.
;
;DBMC:
;Desaloca o buffer de 13456 bytes da memoria convencional, alocado
;anteriormente por uma chamada bem sucedida da rotina ABMC.
;Atencao que uma vez que este bloco for liberado, o manipulador
;de erro critico do Nanosistemas nao salvara mais o que
;estava por traz no video e nao podera mais restaurar.
;
;
;Entra: NADA
;Retorna: CS:BMEC : Segmento do buffer
;	  CS:BMEC=0 significa que o buffer nao esta alocado

;Aloca o buffer de 13456 bytes
ABMC:	PUSHA
	PUSH	ES
	CMP	BMEC,0		;Verifica se BMEC=0
	JNZ	JALF		;Negativo, nao precisa alocar o buffer
	
	MOV	AH,48h		;Tenta alocar bloco de memoria
	MOV	BX,842d 	;bytes
	INT	21h
	JNC	JAL1		;Conseguindo, pula
	XOR	BX,BX		;Nao conseguindo, grava 0 na variavei
	XOR	AX,AX		;BMEC, indicando que houve erro na alocacao da memoria
	JAL1:
	MOV	BMEC,AX 	;Grava segmento do buffer alocado em BMEC
	
	JALF:
	POP	ES		;Finaliza rotina e retorna
	POPA
	RET
	
;Desaloca o buffer de 13456 bytes	
DBMC:	PUSHA
	PUSH	ES
	
	MOV	AH,49h		;Tenta liberar bloco de memoria
	MOV	ES,BMEC
	INT	21h
	JC	JDL1		;Nao conseguindo, pula
	MOV	BMEC,0		;Conseguindo, zera BMEC 	
	JDL1:

	POP	ES
	POPA
	RET

;-------------------------------------------------------------
;Rotinas de controle do CD PLAYER.
;-------------------------------------------------------------
;-------------------------------------------------------------
;-------------------------------------------------------------
;Nanosistemas. Funcao CD PLAYER (INDEPENDENTE DO SISTEMA)
;Acesso CALL CDPLAY / EXTERNO
;
;Realiza operacoes de PLAY, REWIND, FAST FORWARD, STOP, PAUSE, RESUME, EJECT...
;no drive de CDROM.
;
;Entra: AL	: 0d = Play
;	AL	: 1d = Rewind 
;	AL	: 2d = Fast Forward
;	AL	: 3d = Preview track
;	AL	: 4d = Next track
;	AL	: 5d = Stop
;	AL	: 6d = Pause / Resume
;	AL	: 7d = Open / Close
;
;Retorna:
;	AL	: 0d = Ok
;	AL	: 1d = Erro: Impossivel usar CDROM
;	AL	: 2d = Erro: Disco nao e' de audio ou drive esta ocupado/Sem disco

;------------------------------------------------------------
;22 bytes buffer
BM22:	DB	24 dup (0)	;Buffer 22 bytes

;---------------
;Command buffer (READ)
BCOM:	DB	0,0		;Buffer de controle
FRAM	DB	0		;REDBOOK: Frame #
SEGS	DB	0		;REDBOOK: Segundos
MINU	DB	0		;REDBOOK: Minutos
UNNU	DB	0		;REDBOOK: Inutil
BTCI	DW	0		;Track control information

;---------------
;Entire Disc
BCAA	DB	0Ah
FTRK	DB	0		;Numero da primeira trilha
LTRK	DB	0		;Numero da ultima trilha
FTFN	DB	0		;FRAME NUMBER da primeira trilha
FTSC	DB	0		;SECOND da primeira trilha
FTMN	DB	0		;MINUTE da primeira trilha
FTUN	DB	0		;Inutil
FTOT	DD	0		;Total de frames no disco (HSG)

;---------------
;Command buffer (READ)
CNTR	DB	0		;Comando
STAT	DW	0		;Status
RESV	DW	0		;Reservado

;---------------
;Audio Disc Info (ATUALIZADO POR: CALL ADIN)
BADI	DB	12d
	DB	0
BTRN	DB	0		;Track #
	DB	0

TMIN	DB	0		;Track MINUTES
TSEG	DB	0		;Track SECONDS
TFRM	DB	0		;Track FRAME #
TZER	DB	0		;Zero

DMIN	DB	0		;Disk MINUTES
DSEG	DB	0		;Disk SECONDS
DFRM	DB	0		;Disk FRAME

;---------------
;Dados gerais
CDAL	DB	0		;AL Inicial (Comando do usuario)
CDRE	DB	0		;Resposta (AL de retorno)
CDSS	DW	0		;SS inicial
CDSP	DW	0		;SP inicial

DDHN	DW	0		;Handle do device driver
DRIV	DB	6		;Letra do 1o drive de CDROM
STST	DB	0		;Stop Status: 1=Stopped (recomecar a tocar da 1a musica)
				;	      0=Proceder normalmente
;---------------
;Dados lidos inicialmente pelo MSCDEX
SUNA	DB	0		;SUBUNIT NUMBER do drive A (primeiro drive)
DDNO	DW	0		;Offset para o nome do DEVICE DRIVER (drive A)
DDNS	DW	0		;Segmento para o nome do DEVICE DRIVER (drive A)
BUFB:	DB	50 dup (0)	;Bytes extras

;------------------------------------------------------------
;Inicio da rotina
;-----------------------------------------
CDPLAY: PUSHA
	PUSH	ES
	PUSH	DS
	MOV	CDSS,SS 	;Salva estado da pilha
	MOV	CDSP,SP
	MOV	CDAL,AL 	;Grava AL inicial
	MOV	CDRE,0
	
	;Verifica se MSCDEX esta presente, se e' versao 2.1 ou maior
	;e se existe CD ROM de audio no drive
	;Negativo, pula e finaliza com AL=1
	
	MOV	AX,150Ch	;Pega versao do MSCDEX
	XOR	BX,BX
	INT	2Fh
	CMP	BX,0210h	;Verifica a versao

	JNAE	MSCERR		;Erro, pula
	
	MOV	AX,1500h	;Verifica quantos CDROMS estao presentes
	XOR	BX,BX
	INT	2Fh
	OR	BX,BX		;Nenhum?
	JZ	MSCERR		;Pula. Erro		
	MOV	DRIV,CL 	;Grava letra do 1o drive
	
	MOV	AX,1501h	;Pega o nome do CDROM DEVICE DRIVER
	PUSH	CS
	POP	ES
	MOV	BX,OFFSET SUNA	;Algo tipo "MSCD001"
	INT	2Fh
	
	MOV	AX,3D02h	;Abre arquivo (dispositivo)
	MOV	DS,DDNS
	MOV	DX,DDNO
	ADD	DX,10d		;DDNO+10 contem o nome do DD
	INT	21h
	JC	MSCERR		;Erro, pula
	MOV	BX,AX
	MOV	DDHN,BX 	;O manipulador do Device Driver esta em CS:DDHN

	;Verifica o comando do usuario e executa
	;------------------------------------------
	MOV	AL,CDAL 	;Em AL o comando

	PUSH	AX		;Le status do CDROM
	MOV	AX,4402h
	MOV	BX,DDHN
	MOV	CX,5
	MOV	CNTR,6
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CNTR
	INT	21h
	JC	ERRO
	POP	AX
	
	TEST	STAT,1b 	;Verifica se a porta esta fechada ou aberta
	JNZ	JCDP06		;Se estiver aberta, nao permite acesso a PLAY,PAUSE,STOP... 
	TEST	STAT,10000b	;Verifica se o drive suporta AUDIO PLAY
	JZ	MSCERR		;Negativo, pula e marca ERRO
	
	OR	AL,AL		;PLAY
	JNZ	JCDP00
	CALL	PLAY
	
	JCDP00:
	CMP	STST,1		;Verifica se o CD esta STOPPED
	JZ	JCDPLAYF	;Afirmativo, pula. Nem checa outros comandos
	
	CMP	AL,1		;REWIND
	JNZ	JCDP01
	MOV	AL,1

	CALL	SEEK

	JCDP01:
	CMP	AL,2		;FAST FORWARD
	JNZ	JCDP02
	XOR	AL,AL
	CALL	SEEK
	
	JCDP02:
	CMP	AL,3		;PREWIEW
	JNZ	JCDP03
	CALL	PREVIEW
	
	JCDP03:
	CMP	AL,4		;NEXT
	JNZ	JCDP04
	CALL	CDNEXT
	
	JCDP04:
	CMP	AL,5		;STOP
	JNZ	JCDP05
	CALL	STOP
	
	JCDP05:
	CMP	AL,6		;PAUSE
	JNZ	JCDP06
	CALL	PAUSE
	
	JCDP06:
	CMP	AL,7		;EJECT
	JNZ	JCDP07
	CALL	EJECT	
	JCDP07:

	;Prepara para retornar ao usuario
	JCDPLAYF:
	MOV	AH,3Eh		;Fecha o arquivo
	MOV	BX,DDHN
	INT	21h
	
	POP	DS		;Finaliza rotina principal
	POP	ES
	POPA
	MOV	AL,CDRE 	;Poe em AL a resposta (ERRO ou OK)
	RET
	
;------------------------------------------------------------
;Subrotina interna: SEEK (CALL SEEK)
;Desloca 10 segundos a musica.
;
;Entra: AL = 0 : FORWARD
;	AL = 1 : REWIND
;
SKAL	DB	0		;AL inicial

SEEK:	PUSHA
	PUSH	ES
	PUSH	DS
	
	MOV	SKAL,AL
	CALL	ADIN		;Atualiza buffers
	CALL	ABBC
	CALL	PAUSECD

	;Prepara buffer de 22 bytes
	MOV	BYTE PTR CS:[OFFSET BM22],22d
	MOV	AL,SUNA
	MOV	BYTE PTR CS:[OFFSET BM22+1],AL
	MOV	BYTE PTR CS:[OFFSET BM22+2],84h
	MOV	BYTE PTR CS:[OFFSET BM22+0Dh],0
	
	;Converte DWORD do formato REDBOOK para o formato HSG
	;Esta DWORD contem a posicao atual (OFFSET) do disco
	MOV	CX,4500d
	MOVZX	AX,DMIN
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EBX		;Em EBX: MINU*4500
	
	MOV	CX,75d
	MOVZX	AX,DSEG
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	ECX		
	ADD	EBX,ECX 	;Em EBX: MINU*4500+SEGS*75
	
	MOVZX	ECX,DFRM
	ADD	EBX,ECX 	
	SUB	EBX,150d	;Em EBX: (MINU*4500+SEGS*75+FRAM)-150
	;Em EBX, a DWORD convertida (de REDBOOK para HSG)
	
	CMP	SKAL,0		;REWIND?
	JNZ	JSEK0		;Afirm. Pula
	
	ADD	EBX,750d	;Adianta musica 10 segundo
	CMP	EBX,FTOT	;Ja estando no final do disco,
	JAE	FORWF		;pula e finaliza. Nao adianta mais
	JMP	JSEK1
	
	JSEK0:
	SUB	EBX,750d	;Volta musica 10 segundos
	JNC	JSEK1		;Se nao voltou antes do inicio do CD, pula
	XOR	EBX,EBX 	;Se voltou, manda tocar do inicio do CD
	
	JSEK1:
	;Continua preparando o buffer de 22 bytes
	MOV	DWORD PTR CS:[OFFSET BM22+0Eh],EBX		;Grava DWORD HSG
	MOV	EAX,FTOT
	SUB	EAX,EBX
	MOV	DWORD PTR CS:[OFFSET BM22+12h],EAX		;Grava FRAME COUNT
	
	;Buffer de 22 bytes pronto.
	;Solicita ao MSCDEX executar SEEK conforme instruido
	MOV	AX,1510h
	PUSH	CS
	POP	ES
	MOV	BX,OFFSET BM22	;Buffer BM22 contem instrucoes
	MOVZX	CX,DRIV
	INT	2Fh
	
	TEST	WORD PTR CS:[OFFSET BM22+3],1000000000000000b
	JNZ	ERRO		;Pula se houve erro
	
	FORWF:
	POP	DS
	POP	ES
	POPA
	RET
	
	
;------------------------------------------------------------
;Subrotina interna: NEXT
;Pula para a proxima trilha
;
CDNEXT: PUSHA
	PUSH	ES
	PUSH	DS
	
	CALL	ADIN		;Atualiza Disc Status
	CALL	ABBC		;Atualiza Entire Disc Information
	MOV	DL,BTRN 	;Em DL o numero da trilha atual

	CMP	DL,LTRK 	;Verifica se ja esta na ultima		
	JZ	NEXTF		;Afirmativo, pula. Nao faz nada
	
	INC	DL		;Manda tocar trilha anterior
	PUSH	DX
	CALL	PAUSECD 	;Para CD
	POP	DX
	CALL	PLAYCD		;Toca proxima musica
	
	NEXTF:			;Finaliza subrotina
	POP	DS
	POP	ES
	POPA
	RET
	
;------------------------------------------------------------
;Subrotina interna: PREVIEW
;Pula para a trilha anterior
;
PREVIEW:PUSHA
	PUSH	ES
	PUSH	DS
	
	CALL	ADIN		;Atualiza Disc Status
	CALL	ABBC		;Atualiza Entire Disc Information
	MOV	DL,BTRN 	;Em DL o numero da trilha atual
	
	MOV	AH,TMIN 	;Ordem de PREVIEW TRACK apos os 2 primeiros segundos
	MOV	AL,TSEG 	;da musica devem ser intendidos como  
	CMP	AX,1d		;VOLTAR PARA O COMECO DESTA MUSICA
	JA	JPREV0		;Pula, se for para apenas voltar ao comeco da musica
	
	CMP	DL,FTRK 	;Verifica se esta na primeira trilha		
	JZ	PREVF		;Afirmativo, pula. Nao faz nada
	DEC	DL		;Manda tocar trilha anterior
	JPREV0:
	PUSH	DX
	CALL	PAUSECD 	;Para CD
	POP	DX
	CALL	PLAYCD		;Toca trilha anterior
	
	PREVF:			;Finaliza subrotina
	POP	DS
	POP	ES
	POPA
	RET
	
;------------------------------------------------------------
;Subrotina interna: STATUS (MIN/SEG/TRACK)
;Atualiza Disc Information (Pode ser chamada enquanto estiver tocando)
;
ADIN:	PUSHA
	PUSH	ES
	PUSH	DS
	
	MOV	AX,4402h	;Le Audio Q-Channel Info
	MOV	BX,DDHN
	MOV	BYTE PTR CS:[OFFSET BADI],12d
	MOV	CX,11d
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BADI
	INT	21h
	JC	ERRO
	
	MOVZX	DX,BTRN 	;Converte TRACK NUMBER de BCD para BINARY DECIMAL
	ROR	DX,4
	ROR	DH,4
	;DL contem parte alta do BCD
	;DH contem parte baixa do BCD
	MOV	AL,DL		;AL:=DL*10+DH	
	MOV	CH,10d
	MUL	CH
	ADD	AL,DH		;Em AL o valor convertido para decimal
	MOV	BTRN,AL 	;Grava em BTRN
	
	POP	DS
	POP	ES
	POPA
	RET
	
;------------------------------------------------------------
;Subrotina interna: EJECT (OPEN/CLOSE)
;Abre / Fecha porta do drive

;
EJECT:	PUSHA
	PUSH	ES
	PUSH	DS
	
	;Verifica se a porta esta fechada ou aberta
	MOV	AX,4402h
	MOV	BX,DDHN
	MOV	CX,5
	MOV	CNTR,6
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CNTR
	INT	21h
	JC	ERRO
	
	TEST	STAT,1b 	;Verifica se a porta esta fechada ou aberta
	JZ	OPEN		;Fechada? Entao abre.
	
	;Fecha porta do drive
	MOV	AX,4403h
	MOV	CX,1
	MOV	CNTR,5
	INT	21h
	JC	ERRO
	JMP	EJECTF		;Pula para finalizar subrotina
	
	;Abre porta do drive
	OPEN:
	MOV	AX,4403h
	MOV	CX,1
	MOV	CNTR,0
	INT	21h
	JC	ERRO
	
	EJECTF: 		;Finaliza subrotina
	POP	DS
	POP	ES
	POPA
	RET

;------------------------------------------------------------
;Subrotina interna: STOP
;STOP playing
;
STOP:	PUSHA
	PUSH	ES
	PUSH	DS
	
	CALL	PAUSECD 	;Manda CD parar de tocar
	MOV	STST,1		;Marca: CD STOPPED. Recomecar da 1a musica

	
	POP	DS
	POP	ES
	POPA
	RET
	
;------------------------------------------------------------
;Subrotina interna: PAUSE / RESUME (ACESSO: CALL PAUSE)
;Executa PAUSE / RESUME

;Subrotina da Subrotina (Puts!) - Acesso externo OK
;Verifica se o CD esta PAUSED ou PLAYING.
;Se estiver PAUSED, manda CD continuar a tocar. (Retorna AL=0)
;Se nao estiver PAUSED, nao faz nada, mas retorna AL=1.

;Entra nada e retorna TUDO o que for possivel alterado
;
RESUME: ;Verifica se CDROM esta PAUSED ou PLAYING
	MOV	AX,4402h			 
	MOV	CNTR,15d	;Get Audio Status
	MOV	BX,DDHN
	MOV	CX,11d
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CNTR
	INT	21h
	JC	ERRO
	
	MOV	AL,1
	TEST	STAT,1b 	;Verifica se esta PAUSED
	JZ	RESUMEF 	;Negativo, pula. Retorna AL=1
	
	;Envia RESUME para o drive
	MOV	AX,1510h	
	MOV	BYTE PTR CS:[OFFSET BM22],0Dh	
	MOV	DL,SUNA
	MOV	BYTE PTR CS:[OFFSET BM22+1],DL	;SUBUNIT NUMBER
	MOV	BYTE PTR CS:[OFFSET BM22+2],88h ;Comando: RESUME
	PUSH	CS
	POP	ES
	MOV	BX,OFFSET BM22			;Buffer
	MOVZX	CX,DRIV 			;Letra do drive
	INT	2Fh
	
	TEST	WORD PTR CS:[OFFSET BM22+3],1000000000000000b
	JNZ	ERRO		;Pula se houve erro
	
	MOV	AL,0
	
	;Envia PAUSE para o drive
	RESUMEF:
	RET

;Subrotina da subrotina (Puts! Puts!!) Acesso externo OK
;Incondicionalmente PARA o CD (PAUSE), podendo prosseguir
;de onde parou chamando a subrotina RESUME.
;
PAUSECD:MOV	AX,1510h	
	MOV	BYTE PTR CS:[OFFSET BM22],0Dh	
	MOV	DL,SUNA
	MOV	BYTE PTR CS:[OFFSET BM22+1],DL	;SUBUNIT NUMBER
	MOV	BYTE PTR CS:[OFFSET BM22+2],85h ;Comando: PAUSE
	PUSH	CS
	POP	ES
	MOV	BX,OFFSET BM22			;Buffer
	MOVZX	CX,DRIV 			;Letra do drive
	INT	2Fh

	TEST	WORD PTR CS:[OFFSET BM22+3],1000000000000000b
	JNZ	ERRO		;Pula se houve erro
	
	RET
	
;Subrotina principal
PAUSE:	PUSHA
	PUSH	ES
	PUSH	DS
	
	CMP	STST,1	;Verifica se o CD esta parado (STOPPED)
	JZ	PAUSEF	;Afirmativo, nao atual (pula e finaliza subrotina)
	
	CALL	RESUME	;Verifica se o CD esta PAUSED PLAYING.
	OR	AL,AL
	JZ	PAUSEF	;Se estava PAUSED, agora ja esta PLAYING. Pula e finaliza subrotina
	
	;Se estava PLAYING, envia comando para PAUSAR CD
	CALL	PAUSECD 
		
	PAUSEF: 		;Finaliza subrotina
	POP	DS
	POP	ES
	POPA
	RET

;------------------------------------------------------------
;Subrotina interna: PLAY
;Envia comando para tocar CDROM
;

;Subrotina da Subrotina (Aiaiai.. puts!)
;Atualiza buffer BCAA (Que contem informacoes do disco,
;como TOTAL DE FRAMES NO DISCO, NUMERO DA 1 e ULTIMA MUSICA, etc..)
;Entra: NADA
;Retorna: NADA

ABBC:	PUSHA
	PUSH	ES
	PUSH	DS
	
	;Le do driver na memoria as informacoes do CD
	MOV	AX,4402h
	MOV	CX,7
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BCAA
	MOV	BX,DDHN
	INT	21h
	JC	ERRO
	
	;Converte DWORD do formato REDBOOK para o formato HSG
	;Esta DWORD contem o TAMANHO DO DISCO
	MOV	CX,4500d
	MOVZX	AX,FTMN
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EBX		;Em EBX: MINU*4500
	
	MOV	CX,75
	MOVZX	AX,FTSC
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	ECX		
	ADD	EBX,ECX 	;Em EBX: MINU*4500+SEGS*75
	
	MOVZX	ECX,FTFN
	ADD	EBX,ECX 	
	SUB	EBX,150 	;Em EBX: (MINU*4500+SEGS*75+FRAM)-150
	;Em EBX, a DWORD convertida (de REDBOOK para HSG)
	MOV	FTOT,EBX	;Grava total de frames no disco

	POP	ES
	POP	DS
	POPA
	RET

;Subrotina da Subrotina (puuuuts!) - Acesso externo OK
;Toda a trilha especificada
;Entra: AL : Numero da trilha
;Retorna: TUDO alterado!
;	
PLAYCD: ;Prepara registradores e memoria para mandar MSCDEX tocar o CD
	;Pega informacoes da trilha que deve tocar
	MOV	AX,4402h	;Le dados do MSCDEX para o buffer BCOM
	MOV	BYTE PTR CS:[OFFSET BCOM],0Bh
	MOV	BYTE PTR CS:[OFFSET BCOM+1],DL
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BCOM
	MOV	BX,DDHN
	MOV	CX,8
	INT	21h
	JC	ERRO		;Erro, pula
	
	;Prepara buffer de 22 bytes
	MOV	BYTE PTR CS:[OFFSET BM22],22d
	MOV	AL,SUNA
	MOV	BYTE PTR CS:[OFFSET BM22+1],AL
	MOV	BYTE PTR CS:[OFFSET BM22+2],84h
	MOV	BYTE PTR CS:[OFFSET BM22+0Dh],0
	
	;Converte DWORD do formato REDBOOK para o formato HSG
	MOV	CX,4500d
	MOVZX	AX,MINU
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EBX		;Em EBX: MINU*4500
	
	MOV	CX,75
	MOVZX	AX,SEGS
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	ECX		
	ADD	EBX,ECX 	;Em EBX: MINU*4500+SEGS*75
	
	MOVZX	ECX,FRAM
	ADD	EBX,ECX 	
	SUB	EBX,150 	;Em EBX: (MINU*4500+SEGS*75+FRAM)-150
	;Em EBX, a DWORD convertida (de REDBOOK para HSG)
	
	;Continua preparando o buffer de 22 bytes
	MOV	DWORD PTR CS:[OFFSET BM22+0Eh],EBX		;Grava DWORD HSG
	MOV	EAX,FTOT
	SUB	EAX,EBX
	MOV	DWORD PTR CS:[OFFSET BM22+12h],EAX		;Grava FRAME COUNT
	
	;Buffer de 22 bytes pronto.
	;Solicita ao MSCDEX tocar o CD conforme instruido
	MOV	AX,1510h
	PUSH	CS
	POP	ES
	MOV	BX,OFFSET BM22	;Buffer BM22 contem instrucoes
	MOVZX	CX,DRIV 	
	INT	2Fh

	TEST	WORD PTR CS:[OFFSET BM22+3],1000000000000000b
	JNZ	ERRO		;Pula se houve erro
	
	RET

;Subrotina principal
PLAY:	PUSHA			
	PUSH	ES
	PUSH	DS

	CMP	STST,1		;Verifica se o CDROM estava parado (STOPPED) e
	JZ	STPL		;deve agora recomecar da primeira musica. Afirm, Pula
	
	CALL	RESUME		;Verifica se CDROM esta apenas PAUSED.
	OR	AL,AL		;Afirmativo, pula rotina PLAY, pois a subrotina
	JZ	PLAYF		;RESUME ja mandou o CD continuar o PAUSE.

	STPL:	
	MOV	STST,0		;Marca: CD nao esta mais parado
	
	;MANDA CD TOCAR A PARTIR DA 1a TRILHA
	;--------------------------------------------------------
	CALL	ABBC		;Atualiza buffer BCAA
	MOV	DL,FTRK 	;Manda CD tocar a 1a trilha
	CALL	PLAYCD

	PLAYF:			;Finaliza subrotina
	POP	DS
	POP	ES
	POPA
	RET
	
;------------------------------------------------------------
;Subrotina: Controle de erro nao-fatal
;Retorna AL=2
;
ERRO:	MOV	SS,CDSS
	MOV	SP,CDSP
	MOV	CDRE,2
	JMP	JCDPLAYF

;------------------------------------------------------------
;A execucao vira' pra ca' caso haja erro na inicializacao do MSCDEX
;
MSCERR: POP	DS		;Erro fatal:
	POP	ES
	POPA
	MOV	AL,1		;Marca: IMPOSSIVEL OPERAR CDROM
	RET			;Retorna


;-------------------------------------------------------------
;-------------------------------------------------------------
;-------------------------------------------------------------
;Nanosistemas. Funcao 00h
;Acesso: CALL MAXL / EXTERNO
;
;Maximiza area de inclusao e minimiza area de exclusao
;Entra nada, volta registradores intactos
MAXL:	PUSHA
	MOV	DWORD PTR CS:[OFFSET AIX],0
	MOV	DWORD PTR CS:[OFFSET AEX],0
	MOV	DWORD PTR CS:[OFFSET AEXX],0
	MOV	AX,RY
	MOV	BX,RX
	MOV	AIXX,BX
	MOV	AIYY,AX
	POPA
	RET

;-------------------------------------------------------------
;Nanosistemas. Rotina interna
;Acesso: CALL MCHK / INTERNO
;
;Gera ou verifica a checksum do arquivo de janelas (MMW)
;
;Entra: AL : 0 = Calcular e gravar a checksum
;	AL : 1 = Verificar a checksum
;	BX : Manipulador do arquivo que mantem a janela 
;Retorna:
;	Se chamado com AL=1:
;	AL : 0 = Janela aprovada
;	AL : 1 = Janela rejeitada
;	AH destruido
;	Flags.. nem se fala.
;	
;***	Das duas formas (AL=0 ou 1) a posicao (SEEK OFFSET) 
;	do arquivo serao mudadas.
;
;OBS:	* O buffer CS:RBDT sera usado para leitura do arquivo MMW.
;	* A rotina nao fecha o arquivo

CBSZ	EQU	10000d		;Numero de bytes a ler de cada vez

MCHK:	PUSH	CATS
	PUSH	CATE

	PUSHA
	PUSH	DS
	PUSH	ES
	PUSH	TEMP
	PUSH	TMP1
	
	XOR	AH,AH
	MOV	TEMP,AX 	;Em TEMP o parametro do usuario
	
	MOV	AX,4200h	;Desloca posicao do arquivo para o inicio
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	
	MOV	CATE,0		;CS:CATE ira contar o numero de bytes ja calculados
	MOV	CATS,0		;CS:CATS ira contar o resultado da soma
	
	;---- LOOP1 ----
	LMCH0:
	MOV	AH,3Fh		;Le 10000 bytes do arquivo
	MOV	CX,CBSZ
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET RBDT
	INT	21h
	
	MOV	TMP1,AX 	;Em AX, o numero de bytes realmente lidos
	OR	AX,AX		;Verifica se CX=0
	JZ	JMCH6		;Afirmativo, pula. Ja acabou o arquivo			

	MOV	CX,AX		;CX: Numero de bytes a somar em CS:CATS
	MOV	SI,OFFSET RBDT
	CLD			;Diveizinquando um Clear Direction e' bom..
	;---- LOOP2 ----
	LMCH1:
	INC	CATE		;Incrementa: NUMERO TOTAL DE BYTES JA SOMADOS
	LODSB			;Le um byte
	
	CMP	CATE,(MMWTS+MMWXS+15d)	;Verifica se esta encima dos bytes da checksum
	JZ	JMCH5			;Pula sempre que positivo. Nao calcula checksum
	CMP	CATE,(MMWTS+MMWXS+16d)	;usando estes bytes.	
	JZ	JMCH5
	JMP	JMCH3
	JMCH5:
	DEC	CX
	JNZ	LMCH1			;Nao realiza a soma mas realiza o loop
	JMP	JMCH4			;Pula se tiver acabado
	
	JMCH3:
	XOR	AH,AH
	ADD	CATS,AX 	;Adiciona AL em CS:CATS
	LOOP	LMCH1	
	;---- END2 ----
	JMCH4:
	
	CMP	TMP1,CBSZ	;Verifica se ja acabou de calcular a checksum
	JZ	LMCH0		;Negativo, pula e recomeca o LOOP
	;---- END1 ----
	JMCH6:
	;Neste ponto, em CS:CATS o resultado da checksum
	
	;..and BX goes on..
	MOV	AX,4200h	;Desloca posicao do arquivo para a posicao da checksum
	XOR	CX,CX
	MOV	DX,(MMWTS+MMWXS+14d)
	INT	21h
	
	CMP	TEMP,1		;VERIFICA PARAMETRO DO USUARIO
	JZ	JMCH0		;Verificar a checksum? Pula.
	
	MOV	AH,40h		;Escreve a checksum no arquivo MMW
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CATS
	MOV	CX,2
	INT	21h
	JMP	JMCHF		;Finaliza
	
	JMCH0:			;Verifica a checksum
	MOV	AH,3Fh		;Le checksum do arquivo
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CATE
	MOV	CX,2
	INT	21h
	
	JMCHF:
	POP	TMP1
	POP	TEMP	
	POP	ES		;Restaura registradores
	POP	DS
	POPA
	
	MOV	AX,CATE 	;Verifica se a checksum confere
	CMP	AX,CATS
	SETNZ	AL		;Afirmativo, marca AL=0. Negativo, marca AL=1

	
	JMCH2:
	POP	CATE
	POP	CATS
	RET			;Retorna
	
	
;-------------------------------------------------------------
;Nanosistemas. Rotina interna
;Acesso: CALL CCHK / INTERNO

;
;Gera ou verifica a checksum do arquivo CFG
;
;Entra: AL : 0 = Calcular e gravar a checksum
;	AL : 1 = Verificar a checksum
;	BX : Manipulador do arquivo CFG 
;Retorna:
;	Se chamado com AL=1:
;	AL : 0 = CFG aprovada
;	AL : 1 = CFG rejeitada
;	AH destruido
;	Flags.. nem se fala.
;	
;***	Das duas formas (AL=0 ou 1) a posicao (SEEK OFFSET) 
;	do arquivo serao mudadas.
;
;OBS:	* O buffer CS:RBDT sera usado para leitura do arquivo CFG
;	* A rotina nao fecha o arquivo

CCHK:	PUSH	CATS
	PUSH	CATE

	PUSHA
	PUSH	DS
	PUSH	ES
	PUSH	TEMP
	PUSH	TMP1
	
	XOR	AH,AH
	MOV	TEMP,AX 	;Em TEMP o parametro do usuario
	
	MOV	AX,4200h	;Desloca posicao do arquivo para o inicio
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	
	MOV	CATS,0		;CS:CATS ira contar o resultado da soma
	
	LCCH0:
	MOV	AH,3Fh		;Le 10000 bytes do arquivo
	MOV	CX,CBSZ
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET RBDT
	INT	21h
	
	CLC
	MOV	CX,AX		;CX: Numero de bytes a somar em CS:CATS
	MOV	SI,OFFSET RBDT
	ADD	SI,2
	SUB	CX,2
	CLD			;Clear Direction
	;---- LOOP1 ----
	LCCH1:
	LODSB			;Le um byte
	XOR	AH,AH

	ADD	CATS,AX 	;Adiciona AL em CS:CATS
	LOOP	LCCH1	
	;---- END1 ----
	;Neste ponto, em CS:CATS o resultado da checksum
	
	;..and BX goes on..
	MOV	AX,4200h	;Desloca posicao do arquivo para a posicao da checksum
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	
	CMP	TEMP,1		;VERIFICA PARAMETRO DO USUARIO
	JZ	JCCH0		;Verificar a checksum? Pula.
	
	MOV	AH,40h		;Escreve a checksum no arquivo CFG
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CATS
	MOV	CX,2
	INT	21h
	JMP	JCCHF		;Finaliza
	
	JCCH0:			;Verifica a checksum
	MOV	AH,3Fh		;Le checksum do arquivo
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CATE
	MOV	CX,2
	INT	21h
	
	JCCHF:
	POP	TMP1
	POP	TEMP	
	POP	ES		;Restaura registradores (todos)
	POP	DS		;So deixa CATE e CATS na pilha
	POPA
	
	MOV	AX,CATE 	;Verifica se a checksum confere
	CMP	AX,CATS
	SETNZ	AL		;Afirmativo, marca AL=0. Negativo, marca AL=1
	
	JCCH2:
	POP	CATE		;Finaliza rotina
	POP	CATS
	RET			;Retorna
	
;-------------------------------------------------------------
;Nanosistemas.
;Acesso: CALL PUSHAE / EXTERNO
;
;Salva em um buffer interno (CS:POES) a area de exclusao
;
;Entra: NADA
;Retorna: NADA
POES:	DD	3 dup (0)
POEX:	DD	3 dup (0)

PUSHAE: PUSHF
	PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS
	POP	ES
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET AEX
	MOV	DI,OFFSET POES
	MOVSD
	MOVSD
	
	POP	DS
	POP	ES
	POPA
	POPF
	RET

;Realiza PUSHAE para as rotinas externas
PUSHAEE:PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS
	POP	ES
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET AEX
	MOV	DI,OFFSET POEX
	MOVSD
	MOVSD
	
	POP	DS
	POP	ES
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas.
;Acesso: CALL POPAE / EXTERNO
;
;Restaura a area de exclusao do buffer interno (CS:POES)
;
;Entra: NADA
;Retorna: NADA 
POPAE:	PUSHF
	PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS
	POP	ES
	PUSH	CS
	POP	DS
	MOV	DI,OFFSET AEX
	MOV	SI,OFFSET POES
	MOVSD
	MOVSD
	
	POP	DS
	POP	ES
	POPA
	POPF
	RET

;Realiza POPAE para as rotinas externas
POPAEE: PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS
	POP	ES
	PUSH	CS
	POP	DS
	MOV	DI,OFFSET AEX
	MOV	SI,OFFSET POEX
	MOVSD
	MOVSD
	
	POP	DS
	POP	ES
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas.
;Acesso: CALL PUSHAI / EXTERNO
;
;Salva em um buffer interno (CS:POES) a area de inclusao
;
;Entra: NADA
;Retorna: NADA
PUSHAI: PUSHF
	PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS	;Versoes anteriores a 22JUL98: Aqui estava PUSH SS
	POP	ES
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET AIX
	MOV	DI,OFFSET POES
	MOVSD
	MOVSD
	
	POP	DS
	POP	ES
	POPA
	POPF
	RET

;Realiza PUSHAI para as rotinas externas
PUSHAIE:PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS	
	POP	ES
	PUSH	CS
	POP	DS

	MOV	SI,OFFSET AIX
	MOV	DI,OFFSET POEX

	MOVSD
	MOVSD
	


	POP	DS
	POP	ES
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas.
;Acesso: CALL POPAI / EXTERNO
;
;Restaura a area de inclusao do buffer interno (CS:POES)
;
;Entra: NADA
;Retorna: NADA 
POPAI:	PUSHF
	PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS
	POP	ES
	PUSH	CS
	POP	DS
	MOV	DI,OFFSET AIX
	MOV	SI,OFFSET POES
	MOVSD
	MOVSD
	
	POP	DS
	POP	ES
	POPA
	POPF
	RET

;Realiza POPAI para as rotinas externas
POPAIE: PUSHA
	PUSH	ES
	PUSH	DS
	
	CLD
	PUSH	CS
	POP	ES
	PUSH	CS
	POP	DS
	MOV	DI,OFFSET AIX
	MOV	SI,OFFSET POEX
	MOVSD
	MOVSD
	
	POP	DS
	POP	ES
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao 01h
;Acesso: CALL NEXT / NEXTR
;
;NEXT:	Usada apenas para enderecar quando ha gravacao no video
;NEXTR: Usada apenas para enderecar quando ha leitura no video
;
;Pula para o proximo segmento de video, respeitando a granularidade da placa.
;Entra: nada
;Retrn: registradores intactos

;Rotina No.0 : WRITE
NEXT:	PUSHA
	MOVZX	AX,GRFC
	ADD	CS:OFST,AX
	MOV	DX,CS:OFST
	MOV	AX,4f05h
	XOR	BH,BH
	MOV	BL,WJAN
	CALL	INT10H
	POPA
	RET

;Rotina No.1 : READ
NEXTR:	PUSHA
	MOVZX	AX,GRFC
	ADD	CS:OFST,AX
	MOV	DX,CS:OFST
	MOV	AX,4f05h
	XOR	BH,BH
	MOV	BL,RJAN
	CALL	INT10H
	POPA
	RET

-------------------------------------------------------------
;Aguarda usuario soltar botao do mouse (soltar os dois)
AUSB:	PUSHA
	;---- LOOP1 -----
	LRO4A:
	CALL	LTR1
	TEST	BX,00000011b
	JNZ	LRO4A
	;---- END1 -----
	POPA
	RET
	
-------------------------------------------------------------
;Agurada usuario soltar botao direito
AUSD:	PUSHA
	;---- LOOP1 -----
	JSCTM8: 			
	CALL	LTR1
	TEST	BX,00000001b
	JNZ	JSCTM8
	;---- END1 -----	
	POPA
	RET				
	
-------------------------------------------------------------
;Nanosistemas. Funcao exclusiva autoexecutavel
;Acesso premitido apenas pela funcao INIC : SEEK -> JMP ALOC
;
;Libera memoria dinamica do .COM alocado pelo DOS 
;Entra:
;DS	- Segmento do PSP (DS inicial)
ALOC:	PUSHA
	MOV	AH,4Ah		;Libera memoria convencional dinamica do COM PAI
	PUSH	CS
	POP	ES
	MOV	BX,1001h
	INT	21h
	POPA
	JMP	INICI

-------------------------------------------------------------
;Nanosistemas. Funcao 02h
;Acesso: CALL REFRESH / EXTERNO
;
;Aguarda a placa de video terminar o ultimo refresh
;Chama sem parametros, nao altera nada
REFRESH:PUSH	AX
	PUSH	DX	
	PUSHF
	MOV	DX,3DAh 	;Aguarda refresh de video
	LWRF:
	IN	AL,DX
	TEST	AL,8
	JZ	LWRF
	POPF
	POP	DX
	POP	AX
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao 03h
;Acesso: CALL DOCAL / EXTERNO
;
;Exibe o calendario
;Entra : AX : Pos Y
;	 BX : Pos X
;	 CL : Cor do texto
;	 CH : Cor de fundo 
;
;Retorna: Alteracoes na memoria de video,
;	  Registradores de segmento alterados

CALX	DW	0
CALY	DW	0
CALC	DB	0
CALF	DB	0
DTBF:	db 'XXX xx.XXX.xxxx xx:xx',0
DCKS	DB	0
WEEK:	DB 'SUNMONTUEWEDTHUFRISAT---'
MONT:	DB 'JANFEBMARAPRMAYJUNJULAGOSEPOCTNOVDEC---'

WRIT:	;AL : Byte #, DI : Offset
	PUSHA
	XOR	AH,AH		;Para converter DEC -> ASCII, divide-se o numero
	MOV	CL,10d		;por 10 e considera-se o resto
	DIV	CL		;>>> Primeiro digito

	MOVZX	BX,AH
	MOV	DL,BYTE PTR CS:[BX+OFFSET HEX]
	MOV	BYTE PTR CS:[DI+(OFFSET DTBF-1)],DL


	XOR	AH,AH		;>>> Segundo digito
	MOV	CL,10d
	DIV	CL

	MOVZX	BX,AH
	MOV	DL,BYTE PTR CS:[BX+OFFSET HEX]
	MOV	BYTE PTR CS:[DI+(OFFSET DTBF-1)-1],DL
	POPA
	RET

DOCAL:	PUSHA

	MOV	CALX,BX ;Grava coordenadas 
	MOV	CALY,AX
	MOV	CALC,CL
	MOV	CALF,CH
	
	MOV	AH,2Ah	;Obtem dados do relogio
	INT	21h
	
	CMP	AL,6	;Verifica se obteve um dia da semana valido
	JNA	JDC5	;Afirmativo, pula
	MOV	AL,7	;Afirmativo, AL=7
	
	JDC5:
	PUSH	CX
	PUSH	DX	;Escreve dia da semana
	CLD
	PUSH	CS	;Copia texto  
	POP	DS
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET DTBF
	MOV	SI,OFFSET WEEK
	XOR	AH,AH
	MOV	CX,3
	MUL	CL
	ADD	SI,AX
	REP	MOVSB

	POP	DX	;Escreve mes
	PUSH	DX
	MOV	AL,DH
	
	CMP	AL,12	;Verifica se obteve um mes valido
	JNA	JDC6	;Afirmativo, pula
	MOV	AL,13	;Afirmativo, AL=13
	
	JDC6:
	MOV	DI,(OFFSET DTBF + 7)
	MOV	SI,OFFSET MONT
	XOR	AH,AH
	XOR	CH,CH
	DEC	AL
	MOV	CL,3
	MUL	CL
	ADD	SI,AX
	REP	MOVSB
	
	POP	DX
	MOV	AL,DL	;Dia mes
	MOV	DI,6
	CALL	WRIT

	POP	CX	;Escreve ano
	MOV	AX,CX	;Dois primeiros digitos
	MOV	CL,100
	DIV	CL
	MOV	DI,13
	CALL	WRIT
	MOV	AL,AH	;Dois ultimos digitos
	MOV	DI,15
	CALL	WRIT
	
	MOV	AH,2Ch	;Le horario
	INT	21h
	
	MOV	AL,CH	;Hora
	MOV	DI,18
	CALL	WRIT

	MOV	AL,CL	;Min
	MOV	DI,21
	CALL	WRIT

	JCDM:
	MOV	USEF,1	;Usar fonte pequena
	MOV	AX,CALY
	MOV	BX,CALX

	MOV	CX,120d
	MOV	DL,CALF
	MOV	DH,12d
	LKJ0:	;---- LOOP1 -----
	CALL	LINEH
	INC	AX
	DEC	DH
	JNZ	LKJ0	;END1

	
	MOV	SI,OFFSET DTBF	
	MOV	AX,CALY
	MOV	BX,CALX
	MOV	CH,99h
	MOV	CL,CALC
	CALL	TEXT
	
	JDCF:
	POPA
	RET
	
;Funcao: CALXY (CALL NEAR)
;
;Calcula o offset e a pagina de video do ponto, dadas as coordenadas
;X e Y do pixel. A funcao tambem realiza a troca de pagina de video
;se necessario, e atualiza as variaveis internas do Nanosistemas.
;
;Entra: BX,AX	: Coord. X,Y do pixel
;Retrn: AX	: Offset dentro do semento A000
;	DX	: No. da pagina de video, convertido de acordo com a granularidade
;
;NOTA:	Esta rotina esta usando WRITE WINDOW.
;	Utilize apenas para fazer gravacoes na memoria de video 

CALXY:	MUL	CS:RX		;Calcula a pagina e o offset da pagina
	ADD	AX,BX
	ADC	DX,0

	XCHG	AX,DX		;15NOV98: Consideracao da granularidade
	MUL	GRFC		;de video
	XCHG	AX,DX

	CMP	DX,CS:OFST	;Verifica se sera necessario pular de pagina
	JE	JCXY0		;Caso negativo, ignora a INT 10h
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	PUSH	AX
	XOR	BH,BH
	MOV	BL,WJAN
	CALL	POIN		;Alteracao: 29 de agosto de 1998:
	POP	AX		;Mudanca de pagina via far call.
	JCXY0:
	RET			;Finaliza e retorna
-------------------------------------------------------------
;Nanosistemas. Funcao 04h
;Acesso: CALL POINT / EXTERNO
;
;Plota um ponto na tela de video grafica.
;A rotina respeitara os limites da area de inclusao caso CS:RAI=0, e
;respeitara os limites da area de exclusao caso CS:RAE=0. Sendo CS:RAI ou 
;CS:RAE = 1, a rotina nao ira nem ler as definicoes de limites.
;Os limites sao definidos por:
;AREA DE INCLUSAO: Apenas serao plotados os pontos que estiverem dentro do 
;		   retangulo definido por:
;X,Y
;  --------------	X:  CS:AIX  
; |		 |	Y:  CS:AIY
; |   AREA DE	 |	XX: CS:AIXX
; |   INCLUSAO	 |	YY: CS:AIYY
; |		 |
; |		 |
;  -------------- XX,YY
;
;AREA DE EXCLUSAO: Apenas serao plotados os pontos que nao estiverem dentro
;		   do retangulo definido por:
;X:   CS:AEX
;Y:   CS:AEY

;XX:  CS:AEXX
;YY:  CS:AEYY
;
;Entra:
;AX	  : Pos: Y, 
;BX	  : Pos: X, 

;CL	  : Cor
;Retora:
;Alteracoes na memoria de video

OFST	DW	0	;Byte da pagina
PGNM	DB	0	;Numero da pagina
PNTM:	DD	0	;Variavel de uso geral

POINT:	PUSH	AX
	PUSH	BX
	PUSH	DX
	
	CMP	BX,CS:RX	;Verifica se o ponto esta no limite X da tela
	JAE	PTFM		;Negativo, ignora	
	CMP	AX,CS:RY	;Verifica se o ponto esta no limite Y da tela
	JAE	PTFM		;Negativo, ignora	
	
	;*** Verifica se o ponto estara nos limites da AREA DE INCLUSAO
	CMP	CS:RAI,1	;Verifica se deve considerar AI
	JZ	JPT9
	
	CMP	AX,CS:AIY	;Verifica se o ponto estara na area de
	JB	PTFM		;inclusao.
	CMP	BX,CS:AIX	;Caso negativo, finaliza sem desenhar
	JB	PTFM
	CMP	AX,CS:AIYY
	JA	PTFM
	CMP	BX,CS:AIXX
	JA	PTFM
	;*** Verifica se o ponto estara nos limites da AREA DE EXCLUSAO
	JPT9:
	CMP	CS:RAE,1	;Verifica se deve considerar AE
	JZ	EFDL

	CMP	AX,CS:AEY	;Verifica limites Y
	JB	EFDL
	CMP	AX,CS:AEYY
	JA	EFDL
	CMP	BX,CS:AEXX	;Verifica limites X
	JA	EFDL
	CMP	BX,CS:AEX
	JA	PTFM
	;*** Chegando aqui a linha de execucao, entao o ponto sera riscado

	EFDL:
	CALL	CALXY		;Calcula coordenadas logicas do pixel
	
	MOV	GS,WSEG
	MOV	BX,AX
	MOV	BYTE PTR GS:[BX],CL
	
	PTFM:
	POP	DX
	POP	BX
	POP	AX
	RET	
	
-------------------------------------------------------------
;Nanosistemas. Funcao 05h
;Acesso: CALL DOBGN / EXTERNO
;
;Desenha todo background do desktop, respeitando os limites de inclusao
;e de exclusao, nao importando o estado de CS:RAI ou CS:RAE.
;Entra: NADA
;Retorna: Alteracoes na memoria de video

DOBGN:	PUSHA
	PUSH	DS
	
	;VERIFICA SE O BACKGROUND PODE SER PLOTADO SEM PROBLEMAS
	MOV	AX,AIX		;AIinicial maior que AIfinal, pula.
	CMP	AX,AIXX
	JAE	JDBF		
	MOV	AX,AIY
	CMP	AX,AIYY
	JAE	JDBF		
	
	MOV	AX,RX		;Se esta fora do limite X da tela de video,
	CMP	AIX,AX		;nao traca fundo.
	JAE	JDBF		;Pula e finaliza rotina sem fazer nada

	MOV	AX,RY		;Se esta fora do limite Y da tela de video,
	CMP	AIY,AX		;nao traca fundo.
	JAE	JDBF		;Pula e finaliza rotina sem fazer nada
	
	XOR	AX,AX		
	ADD	AX,TLAR 	;Nao deixa tracar fundo em cima da barra
	CMP	AIY,AX		
	JA	JDB10A
	MOV	AIY,AX
	JDB10A:
	
	;CHEGANDO AQUI, BACKGROUND SERA PLOTADO.
	CMP	BANI,1		;Verifica se deve usar background "demo"
	JNZ	JBD10B		;Negativo, pula
	CALL	PBANI		;Afirmativo, plota background "demo"
	JMP	JDBF		;Finaliza
	JBD10B:
	MOV	XORC,0		;Marca: Se for fazer FADE, zerar a pallete de video
	CMP	BMPD,1		;Verifica se esta disponivel o BMP
	JNZ	JDB1		;Nao, pula.
	CMP	BMPY,1		;Deve usar o BMP?
	JNZ	JDB1		;Nao, pula

	CALL	SBMP		;Preenche background com BMP
	JMP	JDBF		;Finaliza
	
	;------ PREENCHE FUNDO COM BACKGROUND CINZA
	JDB1:			
	MOV	AX,AIY		;Prepara registradores
	MOV	DX,AIYY
	MOV	BX,AIX
	MOV	CX,AIXX
	
	CMP	CX,RX		;Evita ter que tracar um retangulo
	JNAE	JDB1A		;maior que a tela (em X)
	MOV	CX,RX		;Reajusta tamanho X
	JDB1A:
	
	SUB	CX,BX
	MOV	DX,AIYY
	SUB	DX,AX
	MOVZX	SI,BGND
	
	MOV	RFPX,BX 	;Grava valores na memoria
	MOV	RFPY,AX
	MOV	RFSX,CX
	MOV	RFSY,DX
	MOV	RFCR,SI
	MOV	SI,RX
	SUB	SI,CX
	MOV	RFJS,SI
	
	INC	AX
	MUL	CS:RX		;Calcula a pagina e o offset da pagina
	ADD	AX,BX
	JNC	JDB0
	INC	DX
	JDB0:

	XCHG	AX,DX		;15NOV98 **********************
	MUL	GRFC
	XCHG	AX,DX

	CMP	DX,CS:OFST	;Verifica se sera necessario pular de pagina
	JE	NDBD		;Caso negativo, ignora a INT 10h
	
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	PUSH	DX
	PUSH	AX
	MOV	AX,4F05h	;Muda a pagina de video
	XOR	BH,BH
	MOV	BL,WJAN
	INT	10h
	POP	AX
	POP	DX
	
	NDBD:
	;Aponta registradores para a memoria de video
	MOV	ES,WSEG
	MOV	DI,AX
	
	MOV	CX,RFSX
	MOV	DX,RFSY
	MOV	AX,RFCR
	MOV	BX,RFPX
	MOV	SI,RFPY
	CLD
	;Neste ponto:
	;ES:DI	: Seg:Offset do primeiro ponto na memoria de video
	;CX	: Tamanho X
	;DX	: Tamanho Y
	;BX	: Pos X
	;SI	: Pos Y
	;AX	: Cor (AL)
	;-------- LOOP1 ----------
	;-------- LOOP2 ----------
	LDB0:
	CMP	BX,RX		;Verifica LIMITE X DA TELA
	JAE	JDB8
	CMP	BX,AEX		;Verifica AREA DE EXCLUSAO
	JNAE	JDB7		;(Pula se ponto for aceito)
	CMP	BX,AEXX
	JA	JDB7
	CMP	SI,AEY
	JNAE	JDB7
	CMP	SI,AEYY
	JA	JDB7
	JDB8:
	
	INC	DI		;Marca "ponto invisivel"
	JMP	JDB6		;Pula
	JDB7:
	STOSB
	JDB6:

	INC	BX
	OR	DI,DI		;Verifica se deve trocar de pagina
	JNZ	JDB4		;Nao, pula
	CALL	NEXT		;Sim, vai pra proxima pagina
	JDB4:
	
	DEC	CX		;Verifica se terminou uma linha
	JNZ	LDB0		;Negativo, prossegue o LOOP
	;-------- END2 ----------
	INC	SI
	MOV	BX,RFPX
	ADD	DI,RFJS 	;Passa DI para a proxima linha
	JNC	JDB5		;Mudar de pagina: NAO: Pula
	CALL	NEXT		;Muda de pagina
	JDB5:
	MOV	CX,RFSX 	;Recarrega CX
	DEC	DX
	JNZ	LDB0		;Ainda nao terminando, prossegue o loop
	;-------- END1 ----------
	
	JDBF:
	POP	DS
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao PBANI e DOANI
;Acesso: CALL PBANI / INTERNO
;
;PBANI:
;Plota background animado
;
;Entra: Area de inclusao e exclusao
;Retorna: Alteracoes na memoria de video
;
;DOANI:
;Realiza o efeito na palette de cores
;
;Entra: Nada
;Retorna: Nada
;
STEPY	DW	0		;Distancia entre os retangulos
STEPO	DW	0		;Distancia entre os retangulos
STEPC	DB	0		;Numero da cor
XORC	DB	0		;Zerar todas as cores? 0=SIM, 1=NAO

PBANI:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CMP	XORC,1		;Verifica se deve zerar os registradores de cor
	JZ	JPBANI0 	;Negativo, pula
	MOV	XORC,1		;Afirmativo, marca: Ja estao zerados
	MOV	DX,3C8h 	;Envia comando para o Chip And Technologies SVGA
	MOV	AL,10h		;Comando: WRITE CAT'S PEL Enhanced VGA mode
	OUT	DX,AL		;Envia comando
	MOV	CX,720d 	;Zera os 240 ultimos PELs usando EVGAM
	XOR	AL,AL		;Sao 240 defn de 3 valores (RGB) cada.
	MOV	DX,3C9h 	;Comando: WRITE CAT'S PEL RGB bytes EVGAM	
	LPBANI4:
	OUT	DX,AL		;REP OUT DX,AL <- ISSO NAO FUNCIONA
	LOOP	LPBANI4 	;Envia o comando 720 vezes (720=(256-10h)*3)
	JPBANI0:
	
	;Calcula Stepsize
	MOV	AX,RY		;STEPY=RY/240
	MOV	CX,240
	XOR	DX,DX
	DIV	CX
	INC	AX
	MOV	STEPY,AX
	MOV	STEPO,AX

	MOV	CX,AX
	MOV	AX,AIY		;Calcula primeira cor
	INC	AX
	XOR	DX,DX
	DIV	CX
	ADD	AX,TLAR
	MOV	STEPC,AL
	
	SUB	STEPO,DX
	
	;--- LOOP1 ---
	;------ PREENCHE FUNDO COM BACKGROUND CINZA
	JDBA1:			
	MOV	AX,AIY		;Prepara registradores
	MOV	DX,AIYY
	MOV	BX,AIX
	MOV	CX,AIXX
	
	CMP	CX,RX		;Evita ter que tracar um retangulo
	JNAE	JDBA1A		;maior que a tela (em X)
	MOV	CX,RX		;Reajusta tamanho X
	JDBA1A:
	
	SUB	CX,BX
	MOV	DX,AIYY
	SUB	DX,AX
	MOV	SI,07h
	
	MOV	RFPX,BX 	;Grava valores na memoria
	MOV	RFPY,AX
	MOV	RFSX,CX
	MOV	RFSY,DX
	MOV	RFCR,SI
	MOV	SI,RX
	SUB	SI,CX
	MOV	RFJS,SI
	
	INC	AX
	MUL	CS:RX		;Calcula a pagina e o offset da pagina
	ADD	AX,BX
	JNC	JDBA0
	INC	DX
	JDBA0:
		
	XCHG	AX,DX		;15NOV98 **********************
	MUL	GRFC
	XCHG	AX,DX

	CMP	DX,CS:OFST	;Verifica se sera necessario pular de pagina
	JE	NDBAD		 ;Caso negativo, ignora a INT 10h
	
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	PUSH	DX
	PUSH	AX
	MOV	AX,4F05h	;Muda a pagina de video
	XOR	BH,BH
	MOV	BL,WJAN
	INT	10h
	POP	AX
	POP	DX
	
	NDBAD:
	;Aponta registradores para a memoria de video
	MOV	ES,WSEG
	MOV	DI,AX
	
	MOV	CX,RFSX
	MOV	DX,RFSY
	MOV	AX,RFCR
	MOV	BX,RFPX
	MOV	SI,RFPY
	CLD
	;Neste ponto:
	;ES:DI	: Seg:Offset do primeiro ponto na memoria de video
	;CX	: Tamanho X
	;DX	: Tamanho Y
	;BX	: Pos X
	;SI	: Pos Y
	;AX	: Cor (AL)
	;-------- LOOP1 ----------
	;-------- LOOP2 ----------
	LDBA0:
	CMP	BX,RX		;Verifica LIMITE X DA TELA
	JAE	JDBA8
	CMP	BX,AEX		;Verifica AREA DE EXCLUSAO
	JNAE	JDBA7		;(Pula se ponto for aceito)
	CMP	BX,AEXX
	JA	JDBA7
	CMP	SI,AEY
	JNAE	JDBA7
	CMP	SI,AEYY
	JA	JDBA7
	JDBA8:
	
	INC	DI		;Marca "ponto invisivel"
	JMP	JDBA6		;Pula
	JDBA7:
	MOV	AL,STEPC
	STOSB
	JDBA6:
	

	INC	BX
	OR	DI,DI		;Verifica se deve trocar de pagina
	JNZ	JDBA4		;Nao, pula
	CALL	NEXT		;Sim, vai pra proxima pagina
	JDBA4:
	
	DEC	CX		;Verifica se terminou uma linha
	JNZ	LDBA0		;Negativo, prossegue o LOOP
	;-------- END2 ----------
	INC	SI
	
	DEC	STEPO		;Decrementa stepsize
	JNZ	JDBB0		;Trocar de cor. Negativo, pula
	MOV	AX,STEPY
	MOV	STEPO,AX
	INC	STEPC		;Passa para a proxima cor
	JDBB0:

	MOV	BX,RFPX
	ADD	DI,RFJS 	;Passa DI para a proxima linha
	JNC	JDBA5		;Mudar de pagina: NAO: Pula
	CALL	NEXT		;Muda de pagina
	JDBA5:
	MOV	CX,RFSX 	;Recarrega CX
	DEC	DX
	JNZ	LDBA0		;Ainda nao terminando, prossegue o loop
	;-------- END1 ----------
	
	JDBAF:
	;--- END1 ---
	
	POP	ES		;Finaliza
	POP	DS
	POPA
	RET			;Retorna

;INICIO DO MANIPULADOR INT 1Ch
;-----------------------------------------

;Controle/ajuste
OFACT	EQU	090d		;Offset Factor
CORV	DB	0		;Cor para atualizar (0=RED,1=GREEN,2=BLUE)
INRM	EQU	13		;Intensidade minima
INGM	EQU	13		;Intensidade minima
INBM	EQU	0		;Intensidade minima

;Variaveis de controle no campo do CFG

;Variaveis internas
VTMP	DB	0		;RED temp

GTMP	DB	0		;GREEN temp
BTMP	DB	0		;BLUE temp
CPLS	DB	0		;Cores por linha
	
;Autorizacao do sistema ao acesso ao BANCO 11 INT 1CH 
AUTH1C	DB	0		;Permissao para acesso ao banco 11 - INT 1Ch

;Manipulador na INT 1Ch (Endereco do vetor)
MAIN1C:
DOANI:	PUSHFD

	CMP	BANK1C,0			;Verifica se deve executar o banco 11
	JZ	JNOMAN0 			;Negativo, pula
	CMP	AUTH1C,0			;Verifica se ha permissao para acesso a INT 1Ch
	JZ	JNOMAN0 			;Negativo, pula
	CALL	BANK1C				;Executa banco 11
	
	JNOMAN0:
	CMP	BANI,0				;Verifica se deve mostrar animacao
	JZ	JGOTO08 			;Negativo, pula. Nao faz nada
	
	PUSHA
	PUSH	DS
	PUSH	ES
	
	PUSH	CS				;Verifica quais cores (R,G e B)
	POP	DS				;devem ser mostradas e atualizadas

	MOV	SI,OFFSET RCORI 		;RED			
	MOV	CORV,0
	CALL	DOCOR
	
	MOV	SI,OFFSET GCORI 		;GREEN
	MOV	CORV,1
	CALL	DOCOR

	MOV	SI,OFFSET BCORI 		;BLUE
	MOV	CORV,2
	CALL	DOCOR
	
	JMP	JDOANIF 			;Finaliza
	
	;SUBROTINA INTERNA:
	;Processa animacao para a cor em CS:CORV
	;Entra: DS:SI : Request Header 
	;	CORV  : Numero da cor (0=R,1=G,2=B)
	;
	DOCOR:
	MOV	CL,10h				;Primeira cor a ajustar
	MOV	BL,BYTE PTR DS:[SI+4]
	MOV	BYTE PTR DS:[SI+2],BL		;Intensidade inicial
	MOV	BYTE PTR DS:[SI+3],0		;Estado inicial (INC)
	
	;Verifica se ja acabou de incrementar
	CMP	BYTE PTR DS:[SI],10h
	JAE	JDOANI7
	MOV	BYTE PTR DS:[SI],10h
	MOV	BYTE PTR DS:[SI+1],0		;Marca: INC
	JDOANI7:
	
	;Verifica se ja acabou de decrementar
	CMP	BYTE PTR DS:[SI],OFACT
	JNA	JDOANI8
	MOV	BYTE PTR DS:[SI+1],1		;Marca: DEC
	JDOANI8:
	
	;Verifica se esta incrementando ou decrementando
	MOV	BL,BYTE PTR DS:[SI+5]
	
	CMP	BYTE PTR DS:[SI+1],1		;Verifica se DEC ou INC
	JZ	JDOANI9 			;DEC, pula
	ADD	BYTE PTR DS:[SI],BL		;Incrementa
	JMP	JDOANI10
	
	JDOANI9:
	SUB	BYTE PTR DS:[SI],BL		;Decrementa
	JMP	JDOANI10
	
	JDOANI10:
	MOV	BL,BYTE PTR DS:[SI+7]		;Define espessura de cada linha
	MOV	CPLS,BL
	
	MOV	BH,BYTE PTR DS:[SI]
	;CL	: Cor atual
	
	;LOOP1
	;-----------------------------------------------
	LDOANI0:
	INC	CL
	CMP	CL,0FFh 		;Verifica se ja acabou
	JZ	JDOANI6 		;Afirmativo, pula
	;---
	
	;VERIFICA SE AINDA ESTA PREENCHENDO PARTE DE CIMA
	CMP	CL,BH
	JNAE	JDOANI3
	
	;Faz o fade na cor
	CMP	BYTE PTR DS:[SI+3],1		;Verifica se deve decrementar
	JZ	JDOANI2 			;Afirmativo, pula
	
	;INCREMENTAR FADE
	;-----------------------
	MOV	BL,BYTE PTR DS:[SI+6]
	CMP	BYTE PTR DS:[SI+2],BL		;Verifica se a intensidade ja esta no maximo
	JNZ	JDOANI1 			;Negativo, pula
	MOV	BYTE PTR DS:[SI+3],1		;Afirmativo, marca DECREMENTAR
	JMP	JDOANI2 			;Pula para decrementar
	JDOANI1:
	DEC	CPLS				;Verifica espessura de cada linha
	JNZ	JDOANI3
	MOV	BL,BYTE PTR DS:[SI+7]
	MOV	CPLS,BL
	INC	BYTE PTR DS:[SI+2]		;Incrementa cor
	JMP	JDOANI3 			;Pula para ajustar cor
	;-----------------------
	
	;DECREMENTAR FADE
	;-----------------------
	JDOANI2:
	MOV	BL,BYTE PTR DS:[SI+4]	
	CMP	BYTE PTR DS:[SI+2],BL		;Verifica se a intensidade esta no minimo
	JZ	JDOANI3 			;Negativo, pula
	DEC	CPLS				;Verifica espessura de cada linha
	JNZ	JDOANI3
	MOV	BL,BYTE PTR DS:[SI+7]
	MOV	CPLS,BL
	DEC	BYTE PTR DS:[SI+2]		;Decrementa cor
	JMP	JDOANI3 			;Pula para ajustar cor
	;-----------------------
	
	;Ajusta cor em CL para INTE
	JDOANI3:
	MOV	DX,3C7h 			;Le valores RGB
	MOV	AL,CL
	OUT	DX,AL

	MOV	DX,3C9h 			;Le valores e grava em R,G,BTMP
	IN	AL,DX
	CMP	EXIR,1
	JZ	$+4
	XOR	AL,AL
	MOV	VTMP,AL
	IN	AL,DX
	CMP	EXIG,1
	JZ	$+4
	XOR	AL,AL
	MOV	GTMP,AL
	IN	AL,DX
	CMP	EXIB,1
	JZ	$+4
	XOR	AL,AL
	MOV	BTMP,AL
	
	MOV	DX,3C8h 			;Ajusta cor
	MOV	AL,CL
	OUT	DX,AL
	
	CMP	CORV,0				;Verifica qual cor deve ajustar
	JNZ	JCORV0
	CMP	EXIR,1
	JNZ	JCORV0
	MOV	AL,BYTE PTR DS:[SI+2]
	MOV	VTMP,AL
	JCORV0:
	CMP	CORV,1
	JNZ	JCORV1
	CMP	EXIG,1
	JNZ	JCORV1
	MOV	AL,BYTE PTR DS:[SI+2]
	MOV	GTMP,AL
	JCORV1:
	CMP	CORV,2
	JNZ	JCORV2
	CMP	EXIB,1
	JNZ	JCORV2
	MOV	AL,BYTE PTR DS:[SI+2]
	MOV	BTMP,AL
	JCORV2:
	
	MOV	DX,3C9h 			;Envia valores
	MOV	AL,VTMP
	OUT	DX,AL
	MOV	AL,GTMP
	OUT	DX,AL
	MOV	AL,BTMP
	OUT	DX,AL
	JMP	LDOANI0 			;Retorna ao LOOP
	;-----------------------------------------------
	;END1
	
	JDOANI6:
	RET					;Finaliza subrotina
	
	JDOANIF:
	POP	ES				;Finaliza rotina
	POP	DS
	POPA
	JGOTO08:
	POPFD
	JMP	DWORD PTR CS:[OL1C]		;Retorna a INT 8 real

-------------------------------------------------------------
;Nanosistemas. Funcao 06h
;Acesso: CALL XORNT / EXTERNO
;
;Faz um XOR (OR-EXCLUSIVO) em um ponto da tela de video, 
;ignorando areas de limites (AE,AI)
;Entra:
;AX	  : Pos: Y 
;BX	  : Pos: X
;Retorna:
;Alteracoes na memoria de video

XORNT:	PUSH	AX
	PUSH	BX
	PUSH	DX
	
	CMP	AX,CS:RY	;Verifica se sera tracado um XOR fora dos
	JAE	NTOX		;limites da tela, podendo prejudicar a memoria
	CMP	BX,CS:RX	;Se for fora dos limites, nao traca
	JAE	NTOX
	
	MUL	CS:RX		;Calcula a pagina e o offset da pagina
	ADD	AX,BX
	JNC	XNC0
	INC	DX
	XNC0:
	
	XCHG	AX,DX		;15NOV98 **********************
	MUL	GRFC
	XCHG	AX,DX
		
	CMP	DX,CS:OFST	;Verifica se sera necessario pular de pagina
	JE	NXID		;Caso negativo, ignora a INT 10h
	
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	
	PUSH	AX
	MOV	AX,4F05h	;Muda a pagina de video
	XOR	BH,BH
	MOV	BL,WJAN
	INT	10h
	POP	AX
	
	NXID:	

	;"XORza" o byte na memoria de video
	MOV	GS,WSEG
	MOV	BX,AX
	XOR	BYTE PTR GS:[BX],0FFh

	NTOX:
	POP	DX

	POP	BX
	POP	AX
	RET	

-------------------------------------------------------------
;Nanosistemas. Funcao 07h
;Acesso: CALL CURSOR / EXTERNO
;
;Exibe o cursor do mouse
;AX	: Pos: Y
;BX	: Pos: X
CSAM:	DB	00,00,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	DB	00,15,00,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	DB	00,15,15,00,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	DB	00,15,15,15,00,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	DB	00,15,15,15,15,00,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
	DB	00,15,15,15,15,15,00,0ffh,0ffh,0ffh,0ffh,0ffh
	DB	00,15,15,15,15,15,15,00,0ffh,0ffh,0ffh,0ffh
	DB	00,15,15,15,15,15,15,15,00,0ffh,0ffh,0ffh
	DB	00,15,15,15,15,15,15,15,15,00,0ffh,0ffh
	DB	00,15,15,15,15,15,15,15,15,15,00,0ffh
	DB	00,15,15,15,15,15,15,00,00,00,00,00
	DB	00,15,15,00,00,15,15,00,0ffh,0ffh,0ffh,0ffh
	DB	00,15,00,0ffh,00,15,15,00,0ffh,0ffh,0ffh,0ffh
	DB	00,00,0ffh,0ffh,0ffh,00,15,15,00,0ffh,0ffh,0ffh
	DB	00,0ffh,0ffh,0ffh,0ffh,00,15,15,00,0ffh,0ffh,0ffh
	DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00,15,15,00,0ffh,0ffh
	DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00,15,15,00,0ffh,0ffh
	DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00,15,15,00,0ffh
	DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00,15,15,00,0ffh
	DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00,00,0ffh,0ffh

OLDX	DW	0	;Posicoes anteriores X,Y
OLDY	DW	0

CURSOR: PUSHA
	CMP	AX,CS:OLDY	;Verifica se o mouse foi movido
	JNE	CMNS		;So reescreve o cursor caso o mouse
	CMP	BX,CS:OLDX	;tenha sido movido
	JNE	CMNS
	JMP	JCMS
	CMNS:
	
	MOV	CS:RAE,1	;NAO considerar areas de inclusao e exclusao
	MOV	CS:RAI,1
							
	MOV	AX,CS:OLDY	;Restaura background do cursor do mouse
	MOV	BX,CS:OLDX
	MOV	CX,12d
	MOV	DX,21d
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET CTMP
	CALL	BITMAP
	POPA
	PUSHA
	
	MOV	CX,12d		;Captura o novo background
	MOV	DX,21d
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET CTMP
	CALL	CAPMAP
	
	MOV	CS:OLDY,AX	;Atualiza as posicoes "anteriores"
	MOV	CS:OLDX,BX

	JCMS:
	MOV	AX,CS:OLDY	
	MOV	BX,CS:OLDX
	MOV	CX,12d
	MOV	DX,20d
	MOV	SI,OFFSET CSAM	;Plota cursor do mouse
	MOV	CS:RAE,1	;NAO considerar areas de inclusao e exclusao
	MOV	CS:RAI,1
	CALL	CRSMAP
	
	CMFI:
	MOV	CS:RAE,0	;Volte a considerar areas de inclusao e exclusao
	MOV	CS:RAI,0
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao 08h
;Acesso: CALL CSHOW / EXTERNO
;
;Atualiza o buffer de restauracao  ,do cursor do mouse.
CSHOW:	PUSHA
	PUSH	DS
	PUSH	ES
	MOV	RAI,1		;Ignorar area de inclusao e
	MOV	RAE,1		;area de exclusao
	MOV	AX,CS:OLDY
	MOV	BX,CS:OLDX
	MOV	CX,12d		;Captura o novo background
	MOV	DX,21d
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET CTMP
	CALL	CAPMAP
	MOV	RAI,0		;Respeitar area de inclusao e
	MOV	RAE,0		;area de exclusao
	POP	ES
	POP	DS
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao 09h
;Acesso: CALL CHIDE / EXTERNO
;
;Retira o cursor do mouse da tela de video, restaurando a imagem
;que se encontrava por baixo dele.
CHIDE:	PUSHA
	PUSH	DS
	PUSH	ES
	MOV	RAI,1		;Ignorar area de inclusao e
	MOV	RAE,1		;area de exclusao
	MOV	AX,CS:OLDY	;Restaura background do cursor do mouse
	MOV	BX,CS:OLDX
	MOV	CX,12d
	MOV	DX,21d
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET CTMP
	CALL	BITMAP
	MOV	RAI,0		;Respeitar area de inclusao e
	MOV	RAE,0		;area de exclusao
	POP	ES
	POP	DS
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao NEWR
;Acesso: CALL NEWR / EXTERNO
;
;Reinicia totalmente o ambiente
;
;Entra: NADA
;Retorna; NAO RETORNA
NEWR:	MOV	SS,SSIN
	MOV	SP,SPIN
	CALL	DALB	;Desaloca buffer do BMP
	MOV	BSEG,0	;Zera variaveis
	MOV	BUFA,0
	MOV	DX,UART ;Restaura porta do mouse
	CALL	POPP   
	JMP	BGIN
	
-------------------------------------------------------------
;Nanosistemas. Funcao NEWV
;Acesso: CALL NEWV / EXTERNO
;
;Atualiza as informacoes do video (modo atual)
;
;Entra: NADA
;Retorna; NADA

NEWV:	PUSHA
	PUSH	ES
	
	MOV	AX,1017h	;Salva registradores de cores (RGB) atual
	XOR	BX,BX
	MOV	CX,0FFh
	PUSH	CS
	POP	ES
	MOV	DX,OFFSET RBDT
	INT	10h
	
	MOV	AX,4F01h	;Captura informacoes sobre o modo atual
	MOV	CX,CS:SRES
	MOV	DI,OFFSET USLS
	INT	10h
	
	MOV	AX,4F02h	;Muda o modo de video para modo grafico
	MOV	BX,CS:SRES
	INT	10h
				
	MOV	AX,64d		;Calcula GranFactor (GRFC=(64/GRAN)-1)
	XOR	DX,DX
	DIV	CS:GRAN
	MOV	CS:GRFC,AL
	
	MOV	AX,1012h	;Restaura registradores de cores (RGB) 
	XOR	BX,BX
	MOV	CX,0FFh
	MOV	DX,OFFSET RBDT
	INT	10h
	
	CALL	MAXL		;Atualiza desktop
	CALL	REWRITE
	CALL	IRIU		;Reinicializa o mouse
	
	POP	ES
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao exclusiva do sistema
;Acesso: CALL SECR / SYS.rotinas
;
;Verifica se foi pressionado ALT+X. 
;Afirmativo, finaliza execucao imediatamente e retorna 
;ao sistema operacional.
;
;Entra: NADA
;Retorna (quando retorna): NADA
;
;Por lei do sistema, "CALL SECR" deve ser inserido 
;em todo o LOOP que:
;
;	* Executar verificacao ou contagem de strings dadas pelo usuario
;	* Aguardar evendo de hardware
;	* Aguardar novo ciclo da INT 8h 
;	* Depender apenas do mouse, ou outro "pointing device"
;	* Executar divisoes sucessivas aguardando um resultado
;	* Aguardar resposta de um vetor de interrupcao
;
;	..Ou onde se achar necessario
;
;Estando salvas as rotinas que:
;
;	* Necessitam de toda a velocidade do sistema
;	* Ja possuirem sua propria rotina de seguranca
;	* Executar verificacao ou contagem de strings dadas pelo usuario
;	  onde esta string e' copiada para uma area propria de memoria,
;	  sem depender do conteudo da string para o encerramento com
;	  seguranca do LOOP.
;
;	..Ou onde com certeza total nao se achar necessario
;	  
;
SECR:	RET			;(8SET99) .. Rotina desabilitada *****
	PUSHF
	PUSH	AX
	
	MOV	AH,1
	INT	16h
	JZ	JMS0		;Negativo, pula
	XOR	AX,AX		;Afirmativo, le caractere ASCII e codigo de varredura
	INT	16h
	CMP	AH,45		;"ALT+X" abandona
	JNZ	JMS0
	OR	AL,AL		;"ALT+X" = ASCII code = 0 e SCAN CODE = 45h
	JZ	PFIM
	
	JMS0:
	POP	AX
	POPF
	RET


-------------------------------------------------------------
;Nanosistemas. Rotinas MCROTS
;Acesso exclusivo pela funcao MOUSE
;
;Esta rotina sera executada a cada CLICK ou a cada tecla pressionada
;pelo usuario, de toda a funcao que chamar a funcao MOUSE para le-las.
;

;Sempre esta funcao e' chamada com:
;	  AX: AH = Codigo de varredura, AL = caractere ASCII (Se pressionado alguma tecla)
;	  CX: Pos X
;	  DX: Pos Y
;	  BX: Botoes: BIT 0 = Botao Direito
;		      BIT 1 = Botao Esquerdo
;		      BIT 2 = Double click (qualquer dos botoes ou ate teclado)
BMPFD:	DB	'SHOT000.BMP',0
BMPFN:	DB	13 dup (0)

MCROTS: OR	BX,BX		;Verifica se foi botao pressionado
	JNZ	JMCR1		;Afirmativo, pula

	CMP	AX,1900h	;Verifica se e' ALT+P (screen shot)
	JNZ	JMCR1		;Negativo, pula
	
	CLD
	PUSH	CS		;Afirmativo, prepara nome do BMP
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET BMPFD
	MOV	DI,OFFSET BMPFN
	MOV	CX,13
	REP	MOVSB
	MOV	DX,OFFSET BMPFN
	CALL	FILEN
	
	MOV	DX,OFFSET BMPFN ;Captura tela
	CALL	SSHOT
	JMP	JMCR0		;Finaliza
	
	JMCR1:
	TEST	BX,10b		;Verifica se o botao esquerdo foi pressionado
	JZ	JMCR0		;Negativo, pula
	
	;Verificacao do CD PLAYER
	CMP	SHCD,1		;Verifica se CD PLAYER esta no desktop
	JNZ	JMCR0		;Negativo, pula e finaliza
	CMP	DX,TLAR 	;Verifica se esta clicando no CD PLAYER
	JA	JMCR0		;Pula sempre que negativo
	MOV	AX,CDPX
	CMP	CX,AX
	JNA	JMCR0
	ADD	AX,120
	CMP	CX,AX
	JA	JMCR0
	;Chegando aqui, entao houve click no CD PLAYER
	SUB	CX,CDPX
	MOV	AX,CX
	MOV	CL,15d
	DIV	CL		;AL contem o numero da icone clicada (0,1,2..)
	
	;Valor de AL e icone correspondente:
	;
	;AL:	 0   1	 2   3	 4  5	6   7
	;ICONE: [>][<<][>>][|<][>|][˛][||][EJ]
	
	CALL	CDPLAY		;Envia comando para o CDROM
	CALL	AUSB		;Aguarda usuario soltar botao
	
	JMCR0:
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao MOUSE
;Acesso: CALL MOUSE / EXTERNO
;
;Passa o controle ao mouse, so retornando quando for
;pressionado algun botao ou pressionado tecla ESC.
;Entra: NADA
;Retorna: AX: AH = Codigo de varredura, AL = caractere ASCII (Se pressionado alguma tecla)
;	  CX: Pos X
;	  DX: Pos Y
;	  BX: Botoes: BIT 0 = Botao Direito
;		      BIT 1 = Botao Esquerdo
;		      BIT 2 = Double click (qualquer dos botoes ou ate teclado)
;	  MOBX: Ultimo BX na saida (Igual a BX)
;
;OBS:	Para saber se o doubleclick foi acionado pelo botao direito, esquerdo
;	ou pelo teclado, basta verificar os bits 0 e 1. 
;	Se o bit 2 marca doubleclick, e os bits 0 e 1 estao desligados,
;	entao o doubleclick foi acionado pelo teclado.
;	Se o bit 2 marca doubleclick, o bit 0 esta ligado e o 1 esta desligado,
;	entao o doubleclick foi acionado pelo botao direito.

DCTM	DB	0	;Temporario do Doubleclick
MOBX	DW	0	;Ultimo BX na saida da funcao MOUSE

MOUSE:	PUSH	SI
	PUSH	DI
	PUSH	DS
	PUSH	ES	
	PUSHF
	
	MOV	AUTH1C,1	;Autoriza o BANCO 11 INT 1C rodar
	CALL	LM00		;Chama rotina de controle do mouse
	MOV	AUTH1C,0	;BANCO 11 STANDBY..
	AND	BX,11b
	PUSH	AX
	CMP	DCLK,1		;Verifica se o botao ficou segurado
	JNA	JMOUSE0 	;Afirmativo, pula. Ignora o doubleclick
	MOV	AL,VDOU 	;AL contem a velocidade do doubleclick
	CMP	DCLK,AL 	;Verifica se houve um doubleclick
	JA	JMOUSE0 	;Negativo, pula
	OR	BX,100b 	;Afirmativo, marca em BX que houve doubleclick
	JMOUSE0:
	MOV	DCLK,0		;Zera doubleclickcounter (prepara para contar de novo)
	POP	AX		;Restaura AX
	
	PUSHA		;Salva TUDO
	PUSH	ES
	PUSH	DS
	PUSHF
	CALL	MCROTS	;Chama rotinas auto-executaveis pelo click do mouse
	POPF
	POP	DS
	POP	ES
	POPA		;Restaura TUDO
	
	MOV	MOBX,BX 	;Grava ULTIMO BX
	
	POPF
	POP	ES
	POP	DS
	POP	DI
	POP	SI
	RET			;Retorna

	;Inicio da rotina principal, verificacao da BIOS/real time clock, 
	;deslocamento relativo no plano cartesiano, teste de entrada e saida
	;das rotinas em standby, t.e.s. da rotina LTR1 e/ou INT 16h, e
	;temporizacao do doubleclick.
	;---- LOOP1 ------
	LM00:
	CMP	BANK13,0	;Verifica se deve acessar banco 13 - ready
	JZ	JREADYB
	PUSHA
	PUSH	ES
	PUSH	DS
	PUSHF
	CALL	BANK13		;Executa o banco 13 - ready
	POPF
	POP	DS
	POP	ES
	POPA
	JREADYB:
	
	;Atualizacao do relogio/calendario
	;--------------------------------
	MOV	AL,0Ah	;Verifica se o dado esta disponivel (HORA/BIOS)
	OUT	70h,AL
	IN	AL,71h
	TEST	AL,10000000b
	JNZ	JM02
	
	MOV	AL,2	;Verifica se houve alteracoes no calendario
	OUT	70h,AL	;Verifica minutos
	IN	AL,71h
	CMP	AL,DCKS
	JZ	JM02
	MOV	DCKS,AL
	XOR	AX,AX	;Atualiza calendario
	ADD	AX,3
	MOV	BX,RX
	SUB	BX,110d
	MOV	CL,TXCR
	MOV	CH,TCOR
	MOV	DL,RAI	;Nao respeitar area de inclusao
	MOV	RAI,1
	CALL	DOCAL
	CMP	SHCD,0	;Verifica se deve exibir o CD PLAYER
	JZ	JM02	;Negativo, pula
	CALL	ATCD	;Recoloca o CD PLAYER
	MOV	RAI,DL
	JM02:		
	;--------------------------------
	
	;*** CONTAGEM DO DOUBLECLICK
	;--------------------------------
	PUSH	DS
	PUSH	40h	;Verifica se ja se passaram 0.055segs e se deve
	POP	DS	;incrementar CS:DCLK (tempo do doubleclick)
	MOV	AL,BYTE PTR DS:[6Ch]
	CMP	AL,CS:DCTM	;Verifica se deve incrementar CS:DCLK
	JZ	JDC1		;Negativo, pula rotina
	MOV	CS:DCTM,AL	;Positivo, atualiza memoria
	CMP	CS:DCLK,0FEh	;Verifica se CS:DCLK<255
	JAE	JDC1		;Negativo, e' maior, entao pula. Nao incrementa
	INC	DCLK		;Sendo menor que 255, entao incrementa
	JDC1:
	POP	DS
	;--------------------------------
	
	;Verificacao de teclas pressionadas
	;--------------------------------
	MOV	AH,1		;Verifica se ha teclas pressionadas
	INT	16h
	JZ	JM00		;Negativo, pula
	XOR	AX,AX		;Afirmativo, le caractere ASCII e codigo de varredura
	INT	16h
	
	CMP	AX,2D00h	;Verifica ALT+X pressionado
	JNZ	JM01		;Negativo, pula
	CMP	BANKAX,0	;Verifica se deve executar o manipulador ALT+X
	JNZ	JM01A		;Afirmativo, pula
	CMP	ALTX,0		;Verifica se ALT+X esta disponivel
	JZ	PFIM		;Afirmativo, finaliza normalmente o sistema
	JMP	JM00		;Negativo, nao faz nada
	JM01A:
	CALL	BANKAX		;Executa manipulador	
	;--------------------------------
	
	;Movimentacao do mouse	
	;--------------------------------
	JM00:
	CALL	LTR1		;Le posicao do mouse
	
	PUSH	BX
	MOV	AX,DX		;Plota o cursor na tela
	MOV	BX,CX
	CALL	CURSOR
	POP	BX
	
	XOR	AX,AX
	TEST	BX,00000011b	;Verifica se algum botao foi pressionado
	JZ	LM00		;Negativo, pula. Retorna ao loop
	;--------------------------------
	
	JM01:			;Finaliza e retorna
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao 0Ch
;Acesso: CALL MROT / EXTERNO
;
;Passa o controle a rotina que cuida dos clicks nas janelas,
;nas icones, menus, hotkeys.. etc.
;Entra: CX,DX : Posicoes do cursor do mouse
;Retorna:


;Todos os registradores alterados (FLAGS, ACUMULADORES, CONTADORES...)
;Memoria alterada, flags internos, variaveis, video, portas, memoria externa,
;estado da pilha, registradores de segmento.. etc.
;
;DESCRICAO DO PROCESSO:
;Quando acionada, a rotina MROT passa o controle a funcao MOUSE, que
;retornara caso o usuario tenha pressionado alguma tecla ou clicado 
;com o mouse.
;A funcao MOUSE retornara: CODIGO ASCII e SCANCODE da tecla (se houve alguma
;pressionada), a posicao X,Y do cursor do mouse , e os botoes pressionados.
;Apos retornar para a funcao MROT, ela verificara se houve alguma tecla pressionada.
;Logo apos verificado as teclas, verifica se houve algum botao do mouse pressionado.
;Caso afirmativo, pula para a rotina BTNE.
;Esta rotina (BTNE) verifica se foi o botao direito. Afirmativo, chama a rotina
;BNTD que exibe o menu com as janelas presentes do desktop. 
;Se foi o botao esquerdo, verifica se foi clicado no menu Nanosistemas (na barra superior).
;Afirmativo, chama a rotina que exibe menu e, quando retornar da rotina, verifica
;o numero da opcao do menu que foi selecionada, e executa a operacao correspondente.
;Se foi clicado na area das janelas, passa o controle a rotina que identifica
;em qual janela foi clicado, passa esta janela para primeiro plano, e dependendo
;do click, executa rotinas de movimentacao da janela ,troca de tamanho, click
;em icone, scroll, etc..
;OBS: A rotina que gerencia o click na area de janelas, modifica o byte CS:PMAJ
;     de acordo com o click:
;	Se foi clicado: 	
;	NA BARRA DE TITULO DA JANELA, PMAJ=1
;	NA ICONE INFERIOR DIREITA (RESIZE), PMAJ=2
;	NA ICONE DE SCROLL UP, PMAJ=4
;	NA ICONE DE SCROLL DOWN, PMAJ=3
;	NA ICONE SUPERIOR ESQUERDA, PMAJ=5
;	EM QUALQUER OUTRA PARTE DA JANELA, PMAJ=0
;     Desta forma, esta rotina pode se comunicar com as outras rotinas que manipulam
;     as janelas, alem de fornecer para qualquer parte do Nanosistemas este detalhe
;     da operacao atual do Nanosistemas.

;ESTRUTURA DO MENU PRINCIPAL
R1XX	DW	10	;Pos X
	DW	10	;Pos Y				+2
	DB	0FFh	;Cor do menu			+4
	DB	0FFh	;Cor dos textos do menu 	+5
	DD	0	;Reservado
	DB	  ' Help',13d
	DB	  ' New Window',13d			 
	DB	  ' Delete Window',13d
	DB	  ' New Icon',13d
	DB	  ' Run..',13d
	DB	  ' ',2,20,'-',13d
	DB	  ' Screen Resolution	 ',13d
	DB	  ' System Info',13d
	DB	  ' System Setup',13d
	DB	  ' ',2,20,'-',13d

	DB	  ' About Nanosistemas',13d
	DB	  ' Exit',0d,13d
	DB	0FFh,0FFh
;ESTRUTURA DO MENU 'VIDEO'
R1VM:	DW	10	;Pos X
	DW	10	;Pos Y				+2
	DB	0FFh	;Cor do menu			+4
	DB	0FFh	;Cor dos textos do menu 	+5
	DB	0F8h	;Cor do titulo
	DB	3 dup(0);Reservado
	DB	'VIDEO',13d
R1VT:	DB	160d dup (0)
	DB	0d,13d
	DB	0FFh,0FFh

;ESTRUTURA DO MENU 'VIDEO'
R1OP:	DW	10	;Pos X
	DW	10	;Pos Y				+2
	DB	0FFh	;Cor do menu			+4
	DB	0FFh	;Cor dos textos do menu 	+5
	DB	0F8h	;Cor do titulo
	DB	3 dup(0);Reservado
	DB	'SETUP',13d
	DB	'Mouse ',13
	DB	'System Options ',13
	DB	'Image Fade',13
	DB	'Colors'
	DB	0d,13d
	DB	0FFh,0FFh

;INICIO DA ROTINA
MROT:	;----- LOOP1 -------
	CALL	MAXL	;Maximiza limites / abilita desktop

	CALL	SPATH	;Retorna ao path do sistema
	CALL	MOUSE
	MOV	DMAL,1	;Flag
	
	CMP	AX,1700h;ALT+I = Imagem fade (configuracao)
	JNZ	JMR00
	CALL	CINF
	JMP	MROT
	JMR00:
	CMP	AX,1F00h;ALT+S = Sistema
	JNZ	JMR01
	CALL	SINF
	JMP	MROT

	JMR01:
	CMP	AX,2F00h;ALT+V = Video (VESA modes)
	JNZ	JMR02
	MOV	R1CL,7
	JMP	JR14
	JMR02:
	
	CMP	AH,62d	;F4: Adiciona nova janela

	JNZ	JMR0
	CALL	NEWW
	JMR0:
	CMP	AH,82d	;INS: Nova icone

	JNZ	JMR1
	XOR	AL,AL
	CALL	NEWI
	JMR1:
	CMP	AH,18d	;E: Edita icone
	JNZ	JMR11
	MOV	AL,1
	CALL	NEWI
	JMR11:
	CMP	AH,67d	;F9: Exclui janela
	JNZ	JMR2
	CALL	DWIN
	JMR2:
	CMP	AH,83d	;DEL: Exclui janela
	JNZ	JMR3
	CALL	Dico
	JMR3:
	CMP	AH,59d	;F1: Help
	JNZ	JMR4
	CALL	HELPM
	JMR4:
	CMP	AH,23d	;I: Imagem BMP
	JNZ	JMR4A
	CALL	VEIW
	JMR4A:
	
	PUSH	AX
	CMP	AL,49d	;1,2,3... troca a resolucao
	JNAE	JMR5
	CMP	AL,57d
	JA	JMR5
	XOR	AH,AH		;Muda modo de video
	SUB	AL,49d
	SHL	AL,1
	MOV	SI,OFFSET RESP
	ADD	SI,AX
	MOV	AX,WORD PTR CS:[SI]
	CMP	AX,0FFFFh
	JZ	JMR5
	CMP	CS:SRES,AX	;Verifica
	JZ	JMR5
	MOV	CS:SRES,AX
	CALL	NEWV	;Muda a resolucao do sistema
	JMP	MROT
	JMR5:
	POP	AX
	
	PUSH	AX
	CMP	AH,12d	;- ou _ troca resolucao (RESOLUCAO ANTERIOR)
	JZ	JMR6A
	CMP	AH,74d
	JNZ	JMR6
	JMR6A:
	CLD		;Procura resolucao atual no buffer RESP
	PUSH	CS
	POP	ES
	MOV	AX,SRES
	MOV	DI,OFFSET RESP
	MOV	CX,(OFFSET RESPE - OFFSET RESP)
	SHR	CX,1
	REPNZ	SCASW
	SUB	DI,4	;Aponta DI para a resolucao anterior
	CMP	DI,OFFSET RESP	;Verifica se esta no limite do buffer RESP
	JNAE	JMR6		;Negativo, pula
	MOV	AX,WORD PTR ES:[DI]
	MOV	SRES,AX ;Grava a nova resolucao em SRES
	CALL	NEWV	;Muda a resolucao do sistema
	JMP	MROT
	JMR6:
	POP	AX
	
	PUSH	AX
	CMP	AH,13d	;= ou + troca resolucao (PROXIMA RESOLUCAO)
	JZ	JMR7A
	CMP	AH,78d
	JNZ	JMR7
	JMR7A:
	CLD		;Procura resolucao atual no buffer RESP
	PUSH	CS
	POP	ES
	MOV	AX,SRES
	MOV	DI,OFFSET RESP
	MOV	CX,(OFFSET RESPE - OFFSET RESP)
	SHR	CX,1
	REPNZ	SCASW
	CMP	DI,OFFSET RESPE ;Verifica se esta no limite do buffer RESP
	JA	JMR7		;Negativo, pula
	MOV	AX,WORD PTR ES:[DI]
	CMP	AX,0FFFFh	;Verifica se a resolucao e' valida
	JZ	JMR7		;Negativo, pula
	MOV	SRES,AX ;Grava a nova resolucao em SRES
	CALL	NEWV	;Muda a resolucao do sistema
	JMP	MROT
	JMR7:
	POP	AX
	
	CMP	AH,28d	;ENTER: Executa programa
	JNZ	JMR8
	CMP	CS:ICSL,1	;Verifica se ha alguma icone visivelmente selecionada
	JNZ	JMR8		;Negativo, pula
	CALL	MRKI		;Afirmativo, prossegue
	CALL	EXECP
	JMR8:
	CMP	AH,24d	;Opcoes do Sistema
	JNZ	JMR9A
	CALL	MOPCT
	JMR9A:
	CMP	AH,39d	;"*": Auto-destruicao ;55X
	JNZ	JMR9
	;------ ASTER -------------
	CALL	MAIN06
	;CALL	VNIW
	;CALL	DOANI
	;CALL	SCRT
	;CALL	NNEW
	;CALL	TESTIC
	;CALL	OMOUS	;********************
	;CALL	CCSI
	
	;--------------------------
	JMR9:
	CMP	AH,88d	;SHIFT+F5: Full Environment Refresh
	JNZ	JMR10
	CALL	NEWR
	JMR10:
	CMP	AH,63d	;F5: Desktop Refresh
	JNZ	JMR10A
	CALL	MAXL
	CALL	REWRITE
	CALL	MROT
	JMR10A:
	
	CMP	AX,4700h;HOME : Restaura posicoes iniciais da janela
	JNZ	JMR11A
	CMP	INDX,0	;Verifica se existe alguma janela no desktop
	JZ	JMR11A	;Negativo, pula
	MOV	DI,INDX
	CMP	DWORD PTR CS:[WIN1+DI],0014001Eh	;Verifica se a janela ja esta la.
	JZ	JMR11A					;Afirmativo, pula. Nao redesenha a janela
	MOV	AX,WORD PTR CS:[WIN1+DI]	;Le posicoes anteriores (atuais..) da janela 
	MOV	BX,WORD PTR CS:[WIN1+DI+2]
	MOV	CX,WORD PTR CS:[WIN1+DI+4]
	JCXZ	JMR11A	;Nao restaura janela oculta
	MOV	DX,WORD PTR CS:[WIN1+DI+6]
	ADD	CX,2
	ADD	DX,2
	SUB	BX,2
	MOV	AIX,AX		;Define a area de inclusao
	MOV	AIY,BX
	MOV	AIXX,CX
	MOV	AIYY,DX
	MOV	DWORD PTR CS:[WIN1+DI],0014001Eh
	MOV	DWORD PTR CS:[WIN1+DI+4],00C8012Ch
	MOV	AEX,30
	MOV	AEY,20
	MOV	AEXX,300
	MOV	AEYY,199
	MOV	WORD PTR CS:[OFFSET WINM],0	;Zera WINM/DMAL
	CALL	CHIDE
	CALL	REWRITE
	CALL	CSHOW
	JMP	MROT
	JMR11A:

	MOV	DMAL,0	;Flag
	TEST	BX,00000011b
	JZ	MROT		
	;----- END1 -------
	JMP	BTNE
	
;--------- SUBROTINA INTERNA:
;Exibe menu quando pressionado botao direito do mouse.
;Neste menu estarao todos os titulos das janelas presentes no desktop.
;Entra: NADA
;Retorna: Alteracoes na memoria (posicao das janelas)
;	  Registradores alterados (todos, inclsv flags)
BTND:	CALL	DISJ		;Desmarca icone selecionada 
	CALL	MBDP		;Atualiza o buffer
	ADD	DX,2
	ADD	CX,2
	MOV	RBDX,CX 	;Botao direito pressionado
	MOV	RBDY,DX 	;Exibe menu com os nomes das janelas
	MOV	SI,OFFSET RBDX
	MOV	DMAL,1
	MOV	WINM,3
	PUSH	CS
	POP	DS
	CALL	ROT1
	CALL	REWRITE
	CALL	MAXL
	DEC	R1CL
	MOVZX	DI,R1CL
	SHL	DI,3		;DI:=DI*8
	OR	DI,DI		;DI=0...
	JZ	JBTN		;..pula
	CMP	DI,CS:INDX	;Verifica se DI e' maior que o numero de janelas
	JA	JBTN		;Afirmativo, pula
	CALL	CLKWIN		;Seleciona janela
	JBTN:
	JMP	MROT
;--------- FIM DA SUBROTINA INTERNA

;SUBROTINA: Movimenta CD PLAYER pela barra superior enquanto botao direito 
;	    estiver pressionado (Via LTR1)
;Entra: NADA
;Retorna: NADA
BTNDA:	PUSHA
	CMP	SHCD,1		;Verifica se deve mostrar o CD PLAYER
	JNZ	JBTNDAF2	;Negativo, pula
	CMP	BDMC,1		;Verifica se deve mover o CD PLAYER
	JNZ	JBTNDAF2	;Negativo, pula
	CALL	LTR1
	CMP	DX,TLAR 	;Verifica se esta clicando no CD PLAYER
	JAE	JBTNDAF2	;Pula sempre que negativo
	MOV	AX,CDPX
	CMP	CX,AX
	JNA	JBTNDAF2
	ADD	AX,120
	CMP	CX,AX
	JA	JBTNDAF2
	;Chegando aqui, entao esta clicando (com o botao direito) no CD PLAYER
	CALL	CHIDE
	MOV	TEMP,CX
	;--- LOOP1 ---
	LBTNDA0:
	CALL	LTR1		;Le nova posicao do mouse
	TEST	BX,11b		;Verifica se soltou o botao direito
	JZ	JBTNDAF1	;Afirmativo, cancela o LOOP
	CMP	CX,TEMP 	;Verifica se moveu (em X)		
	JZ	LBTNDA0 	;Negativo, checa denovo
	
	CALL	HDCD

	CMP	CX,TEMP 	;Adicionar?
	JA	JBTNDA0 	;Pula
	MOV	BX,TEMP 	;Executa SUBTRACAO
	SUB	BX,CX
	SUB	CDPX,BX
	MOV	TEMP,CX
	CALL	ATCD

	JMP	LBTNDA0 	;Retorna ao LOOP
	
	JBTNDA0:
	MOV	BX,CX		;Executa ADICAO
	SUB	BX,TEMP
	ADD	CDPX,BX
	MOV	TEMP,CX
	CALL	ATCD
	JMP	LBTNDA0
	;--- END1 ---
	JBTNDAF1:
	CALL	CSHOW
	POPA
	JMP	MROT
	
	JBTNDAF2:
	POPA
	JMP	BTND
	
;Subrotina interna:
;Atualiza CD PLAYER de acordo com a variavel CDPX
ATCD:	PUSHA			
	CMP	CDPX,80d	;Verifica se o CD PLAYER esta depois do menu Nanosistemas
	JAE	JATCD0		;Afirmativo, pula
	MOV	CDPX,80d	;Negativo, ajusta posicao do CD PLAYER
	
	JATCD0:
	CMP	CDPX,32000d	;Ajusta, se houve BORROW
	JNA	JATCD1		;Negativo, pula
	MOV	CDPX,80 	;Afirmativo, ajusta
	
	JATCD1:
	MOV	AH,TXCR 	;Desenha o CD PLAYER
	MOV	AL,TCOR
	MOV	DI,AX
	XOR	AX,AX
	ADD	AX,3
	MOV	BX,CDPX
	MOV	CX,64d
	MOV	DX,11d
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET ICB1
	CALL	BINMAP
	ADD	BX,60d
	MOV	SI,OFFSET ICB2
	CALL	BINMAP
	POPA
	RET
	
;Subrotina interna:
;Esconde CD PLAYER de acordo com a variavel CDPX
HDCD:	PUSHA
	MOV	SHCD,0
	CALL	PUSHAI		;*** Esta instrucao causa erro em SCRM/SCTL<=SCML
	CALL	MAXL		;*** CORRIGIDO. Erro era em SCRM 
	MOV	AIY,1
	MOV	AIYY,14
	MOV	AX,CDPX
	MOV	AIX,AX
	ADD	AX,125
	MOV	AIXX,AX
	CALL	BARR
	MOV	SHCD,1
	CALL	MAXL
	POPA
	RET
	
;Subrotina: Gerencia CLICKS do mouse	
BTNE:	TEST	BX,00000010b	;Botao esquerdo pressionado
	JZ	BTNDA		;Pula se for Botao Direito
	
	;Rotina delimitada:
	;Verifica clicks no menu Nanosistemas
	;-------------
	MOV	DMAL,1		;Flag
	CMP	CX,70d		;Clicado no menu Nanosistemas
	JA	BTPG		;Pula sempre que negado
	CMP	DX,TLAR
	JA	BTPG
	
	CALL	DISJ		;Desmarca icone selecionada na janela anterior
	JBTPG1:
	MOV	SI,OFFSET R1XX
	MOV	DMAL,1
	MOV	WINM,3
	PUSH	CS
	POP	DS
	CALL	ROT1		;Exibe o menu
	
	CALL	REWRITE
	CALL	MAXL
	;-------------
	
	CMP	R1CL,1		;HELP
	JNZ	JR10
	CALL	HELPM
	JR10:
	CMP	R1CL,2		;NOVA JANELA
	JNZ	JR11
	CALL	NEWW
	JR11:
	CMP	R1CL,3		;EXCLUIR JANELA
	JNZ	JR12
	CALL	DWIN
	JR12:
	CMP	R1CL,5		;Executar 
	JNZ	JR13
	CALL	JEXECUT
	JMP	MROT		;Retorna ao LOOP
	;----------------------------------
	JEXECUT:
	CALL	MAXL		;Afirmativo, exibe janela de browse
	CALL	AUSB	

	CALL	LTR1
	CALL	CHIDE
	MOV	BX,CX
	MOV	AX,DX
	MOV	DX,222
	MOV	CX,220
	CALL	NCMS
	CALL	CSHOW

	MOV	CX,BX
	MOV	DX,AX
	ADD	CX,30d
	ADD	DX,10d
	
	XOR	AX,AX
	MOV	BH,11h
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET BEXCM 
	CALL	BROWSE
	
	TEST	AL,11110000b	;Cancel, pula
	JNZ	JBRNICB
	
	CALL	REWRITE ;Retira menu do desktop

	PUSH	CS	;Copia nome do programa escolhido
	POP	ES
	CLD
	MOV	DI,OFFSET ICOP
	MOV	CX,79
	PUSH	SI
	REP	MOVSB
	POP	SI
			;Copia diretorio de trabalho
	MOV	DI,OFFSET ICOD
	;LOOP
	LBRNI0B:
	LODSB
	STOSB
	OR	AL,AL
	JNZ	LBRNI0B
	;END
	MOV	AL,'\'
	STD
	MOV	CX,79d
	REPNZ	SCASB
	MOV	BYTE PTR ES:[DI+1],0
	CLD
	
	CALL	EXECP	;Executa programa
	JBRNICB:
	CALL	CHIDE	;Retira menu do desktop
	CALL	REWRITE
	CALL	CSHOW

	CALL	MAXL
	RET

	;----------------------------
	JR13:
	CMP	R1CL,4		;NOVA ICONE
	JNZ	JR14
	XOR	AL,AL
	CALL	NEWI
	
	JR14:
	CMP	R1CL,7		;Novo modo de video
	JNZ	JR15
	CALL	LTR1		;Pega posicoes do mouse
	CMP	DX,TLAR 	;Nao permite menu aparecer na barra superior
	JAE	JJR140
	MOV	DX,TLAR
	JJR140:
	INC	DX
	INC	CX
	INC	CX
	MOV	SI,OFFSET R1VM	;Exibe menu 'VIDEO'
	MOV	WORD PTR CS:[SI],CX	;Ajusta posicoes do menu
	MOV	WORD PTR CS:[SI+2],DX	;para a posicao do mouse
	MOV	DMAL,1
	MOV	WINM,3
	PUSH	CS
	POP	DS
	CALL	ROT1
	CALL	REWRITE
	CALL	MAXL
	MOVZX	BX,R1CL
	OR	BX,BX		;Verifica limites
	JZ	JR15
	SUB	BX,2		;Prepara registradores
	CMP	BX,BNMR 	;Verifica se a resolucao nao existe (click fora do limite YY do menu)
	JAE	JR15
	CMP	BX,10d		;Verifica limites
	JAE	JR15
	SHL	BX,1
	ADD	BX,OFFSET RESP
	CMP	BX,OFFSET RESPE
	JAE	JR15
	MOV	AX,WORD PTR CS:[BX]
	OR	AX,AX		;Verifica se modo e' valido
	JZ	JR15
	CMP	CS:SRES,AX	;Verifica
	JZ	JR15
	MOV	CS:SRES,AX
	CALL	NEWV
	
	JR15:
	CMP	R1CL,8		;Dados do sistema
	JNZ	JR16
	CALL	SINF
	JR16:
	
	CMP	R1CL,9		;Opcoes do sistema
	JNZ	JR17
	CALL	LTR1		;Pega posicoes do mouse
	MOV	SI,OFFSET R1OP	;Exibe menu 'CONFIG'
	MOV	WORD PTR CS:[SI],CX	;Ajusta posicoes do menu
	MOV	WORD PTR CS:[SI+2],DX	;para a posicao do mouse
	MOV	DMAL,1
	MOV	WINM,3
	PUSH	CS
	POP	DS
	CALL	ROT1
	CALL	REWRITE
	CALL	MAXL
	CMP	R1CL,2
	JNZ	$+5
	CALL	OMOUS
	CMP	R1CL,3
	JNZ	$+5
	CALL	MOPCT
	CMP	R1CL,4
	JNZ	$+5
	CALL	CINF
	CMP	R1CL,5
	JNZ	$+5
	CALL	CCSI
	JR17:
	
	CMP	R1CL,11 	;Nanosistemas (VERSAO)
	JNZ	JR19
	CALL	VNIW
	
	JR19:
	CMP	R1CL,12 	;Finaliza
	JZ	PFIM
	JR18:

	BTPG:
	MOV	CLAL,0		;Todas as operacoes permitidas
	JMP	CLICKS
;--------------------------------------------------
;Inicio da rotina que gerencia clicks na area das janelas.
;Entra: CX,DX : Posicoes X,Y do mouse
;Retorna: TUDO ALTERADO!
CLAL	DB	0		;Operacoes permitidas: (Bit = 0 : YES, 1 : NO)
				;Bit 0 = Executar
				;Bit 1 = Movimentar
				;Bit 2 = Resize
				;Bit 3 = Scroll
				;Bit 4 = Close
				;Bit 5 = Marcar/desmarcar icone
				;Bit 6 = Reservado
				;Bit 7 = Reservado
	
	PMAJ	DB	0	;1 - Mova a janela, 0 - Apenas mostre-a
				;2 - Resize	  
				;3 - Scroll Down
				;4 - Scroll Up
				;5 - Fechar janela (esconder)
				;6 - Controlbox
				
CLICKS: MOV	DMAL,0		;Marca: MAXIMIZAR AI PARA TRACAR ULTIMA JANELA EM REWRITE



				;Ajusta registradores para comecar a
	MOV	DI,CS:INDX	;analizar o cadastro de janelas
	ADD	DI,8
	
	LM01:
	SUB	DI,8		;Verifica se o mouse esta dentro da janela
	OR	DI,DI		;Verifica se ja examinou todas as janelas
	JZ	MROT
	
	CMP	CX,WORD PTR CS:[WIN1+DI]	;X
	JNA	LM01
	CMP	DX,WORD PTR CS:[WIN1+DI+2]	;Y
	JNA	LM01
	CMP	CX,WORD PTR CS:[WIN1+DI+4]	;XX
	JA	LM01
	CMP	DX,WORD PTR CS:[WIN1+DI+6]	;YY
	JA	LM01

	MOV	CS:PMAJ,0			;Zera operacao (que sera determinada logo abaixo)
	
	;OBS:	EM CX : Pos. X do mouse
	;	EM DX : Pos. Y do mouse
	;	EM CS:WIN1+DI : Pos. X da janela
	;	EM CS:WIN1+DI+2 : Pos. Y da janela
	;	EM CS:WIN1+DI+4 : Pos. XX da janela
	;	EM CS:WIN1+DI+6 : Pos. YY da janela

	;Verifica se clicou na icone Scroll Up
	;Caso afirmativo, marca o flag para Scroll Up
	MOV	BX,WORD PTR CS:[WIN1+DI+4]	;XX
	MOV	AX,WORD PTR CS:[WIN1+DI+2]	;YY
	SUB	BX,15
	CMP	CX,BX
	JNA	JM06
	ADD	AX,CS:TBSZ
	CMP	DX,AX
	JNA	JM06
	ADD	AX,20
	CMP	DX,AX
	JA	JM06
	MOV	CS:PMAJ,4
	JM06:
	;Verifica se clicou na icone Scroll Down
	;Caso afirmativo, marca o flag para Scroll Down
	MOV	BX,WORD PTR CS:[WIN1+DI+4]	;XX
	MOV	AX,WORD PTR CS:[WIN1+DI+6]	;YY
	SUB	BX,15d
	CMP	CX,BX
	JNA	JM07
	SUB	AX,40d
	CMP	DX,AX
	JNA	JM07
	ADD	AX,20d
	CMP	DX,AX
	JA	JM07
	MOV	CS:PMAJ,3
	JM07:
	;Verifica se clicou na barra de titulo da janela
	;Caso afirmativo ,marca o flag para mover a janela
	MOV	AX,WORD PTR CS:[WIN1+DI+2]	;Y
	ADD	AX,15d
	CMP	DX,AX
	JA	JM08
	MOV	CS:PMAJ,1
	JM08:
	;Verifica se clicou na icone de "resize"
	;Caso afirmativo ,marca o flag para redimensionar a janela
	MOV	AX,WORD PTR CS:[WIN1+DI+4]	;XX
	MOV	BX,WORD PTR CS:[WIN1+DI+6]	;YY
	SUB	BX,20d
	CMP	DX,BX
	JNA	JM09
	SUB	AX,15d
	CMP	CX,AX
	JNA	JM09
	MOV	CS:PMAJ,2
	JM09:
	;Verifica se clicou na icone CLOSE
	;Caso afirmativo, marca o flag para CLOSE
	MOV	BX,WORD PTR CS:[WIN1+DI+0]	;X
	MOV	AX,WORD PTR CS:[WIN1+DI+2]	;Y
	ADD	BX,6
	ADD	AX,2
	CMP	CX,BX
	JNAE	JM10
	CMP	DX,AX
	JNAE	JM10
	ADD	BX,11
	ADD	AX,11
	CMP	CX,BX
	JA	JM10
	CMP	DX,AX
	JA	JM10
	MOV	CS:PMAJ,5
	JM10:
	;Verifica se clicou na icone OPTIONS
	;Caso afirmativo...
	MOV	BX,WORD PTR CS:[WIN1+DI+0]	;X
	MOV	AX,WORD PTR CS:[WIN1+DI+2]	;Y
	ADD	BX,6+14
	ADD	AX,2
	CMP	CX,BX
	JNAE	JM11
	CMP	DX,AX
	JNAE	JM11
	ADD	BX,11
	ADD	AX,11
	CMP	CX,BX
	JA	JM11
	CMP	DX,AX
	JA	JM11
	MOV	PMAJ,6
	JM11:

	;Verifica se foi clicado na janela em 1o plano, para nao redesenha-la sem necessidade 
	CMP	DI,CS:INDX
	JZ	PRI1	

	CALL	CLKWIN		;Move janela selecionada para 1o plano
	
	RMT2:			;SE FOI CLICADO EM ALGUMA ICONE DA JANELA,
	PRI1:			;verifica operacao:
				;CLAL : BYTE : OPERACOES PERMITIDAS (1=NO)
				;Bit 0 = Executar
				;Bit 1 = Movimentar
				;Bit 2 = Resize
				;Bit 3 = Scroll
				;Bit 4 = Close
				;Bit 5 = Marcar/desmarcar icone
				;Bit 6 = Reservado
				;Bit 7 = Reservado
	
	CMP	CS:PMAJ,0	;Apenas mostre a janela

	JNZ	JAEJ
	TEST	CLAL,100000b
	JNZ	JAEJ
	CALL	MKICO		;Marca icone
	JMP	JNE1
	
	JAEJ:
	CMP	CS:PMAJ,3	;Scroll Down
	JNZ	JNE2
	TEST	CLAL,1000b
	JNZ	JNE2
	XOR	AH,AH
	CALL	WSCRL
	
	JNE2:
	CMP	CS:PMAJ,4	;Scroll Up
	JNZ	JNE3
	TEST	CLAL,1000b
	JNZ	JNE3
	MOV	AH,1
	CALL	WSCRL
	
	JNE3:
	CMP	CS:PMAJ,1	;Move
	JNZ	JNE4
	TEST	CLAL,10b
	JNZ	JNE4
	CALL	WMOVE
	
	JNE4:
	CMP	CS:PMAJ,2	;Resize
	JNZ	JNE1
	TEST	CLAL,100b
	JNZ	JNE1
	CALL	WMOVE
	
	JNE1:
	CMP	CS:PMAJ,6	;Controlbox
	JNZ	JNE1A
	CALL	CBOX
	
	JNE1A:
	CMP	CS:PMAJ,5	;Close (esconde)
	JNZ	JNE0
	TEST	CLAL,10000b
	JNZ	JNE0
	MOV	AL,1
	CALL	WHIDE
	
	JNE0:
	MOUSEFIM:
	CMP	EXEP,0		;Verifica se deve executar o programa
	JZ	JNE5		;Negativo, pula rotina
	TEST	CLAL,1b
	JNZ	JNE5
	CALL	EXECP		;Executa programa
	
	JNE5:
	MOV	CS:PMAJ,0	;Zera flags
	MOV	EXEP,0
	JMP	MROT
	
;-------------------------------------------------------------
;NANOSISTEMAS. Show menu in CONTROL BOX
;
;STRUCTURE OF 'VIDEO' MENU
R1CB:	DW	10	;Pos X
	DW	10	;Pos Y				+2
	DB	0FFh	;Menu color			+4
	DB	0FFh	;Color of menu texts        	+5
	DB	0h	;Title color
	DB	3 dup(0);Reserved
	DB	'New Icon',13
	DB	'Edit Icon',13
	DB	'Delete Icon',13
	DB	'New Window',13
	DB	'Delete Window',13
	DB	'Run..'
	DB	0d,13d
	DB	0FFh,0FFh
	
CBOX:	PUSHA
	PUSH	DS
	PUSH	ES
	
	PUSH	ICLC		;Save data of selected icon
	MOV	AL,ICSL
	PUSH	AX
	
	CALL	LTR1
	MOV	WORD PTR CS:[OFFSET R1CB],CX
	MOV	WORD PTR CS:[OFFSET R1CB+2],DX

	PUSH	CS
	POP	DS

	MOV	SI,OFFSET R1CB
	CALL	ROT1
	
	MOV	WINM,3		;Removes menu from desktop
	MOV	DMAL,1
	CALL	REWRITE
	CALL	DISJ
	
	POP	AX		;Restore data of selected icon
	MOV	ICSL,AL
	POP	ICLC

	CMP	R1CL,1		;New icon
	JNZ	JCBOX0
	XOR	AL,AL
	CALL	NEWI
	
	JCBOX0:
	CMP	R1CL,2		;Edit icon
	JNZ	JCBOX1
	MOV	AL,1
	CALL	NEWI
	
	JCBOX1:
	CMP	R1CL,3		;Erase icon
	JNZ	JCBOX2
	CALL	DICO	

	JCBOX2:
	CMP	R1CL,4		;New window
	JNZ	JCBOX3
	CALL	NEWW
	
	JCBOX3:
	CMP	R1CL,5		;Erase window
	JNZ	JCBOX4
	CALL	DWIN
	
	JCBOX4:
	CMP	R1CL,6		;Run
	JNZ	JCBOXF
	CALL	JEXECUT 
	
	JCBOXF: 
	POP	ES		;Finishes and return
	POP	DS
	POPA
	RET

;-------------------------------------------------------------
;Finds window that appears in the given X,Y position.
;
;In:    CX : Pos X
;	DX : Pos Y
;Out:   DI : Number of selected window (in multiple of 8),
;	     as required by routine CLKWIN.
;	DI = 0 : There's no window in the indicated X,Y position
;	
XYWN:	MOV	DI,CS:INDX	;checks the window registry
	ADD	DI,8
	
	LXY1:
	SUB	DI,8		;Verifies if all the windows had been checked
	JZ	JXYF		;Yes, jump
	
	;Check if mouse is inside the window
	CMP	CX,WORD PTR CS:[WIN1+DI]	;X
	JNA	LXY1
	CMP	DX,WORD PTR CS:[WIN1+DI+2]	;Y
	JNA	LXY1
	CMP	CX,WORD PTR CS:[WIN1+DI+4]	;XX
	JA	LXY1
	CMP	DX,WORD PTR CS:[WIN1+DI+6]	;YY
	JA	LXY1
	
	JXYF:
	RET
	
;-------------------------------------------------------------
;Nanosistemas
;Acess: CALL AJPP / EXTERN
;
;Update the icons area of the top window.
;In:  NOTHING
;Out: Screen modifications
;
;ATTENTION: This routine modifies the allowed perimeter.

AJPP:	PUSHA
	MOV	WINM,0		;Redraw window
	MOV	DI,INDX
	MOV	BX,WORD PTR CS:WIN1+DI
	MOV	AX,WORD PTR CS:WIN1+DI+2
	MOV	DX,WORD PTR CS:WIN1+DI+4
	MOV	CX,WORD PTR CS:WIN1+DI+6
	PUSHA
	ADD	AX,TBSZ
	SUB	DX,TBSZ
	MOV	AIX,BX
	MOV	AIY,AX
	MOV	AIXX,DX
	MOV	AIYY,CX
	MOV	AEX,1
	MOV	AEXX,1
	MOV	DMAL,1
	POPA
	SUB	DX,BX
	SUB	CX,AX
	MOV	SI,INDX
	ADD	SI,OFFSET TTLS
	PUSH	CS
	POP	DS
	CALL	CHIDE
	CALL	MACW
	CALL	CSHOW
	POPA
	RET

;-------------------------------------------------------------
;Nanosistemas. Function MOVI
;Acess: CALL MOVI / EXTERN
;
;Move/copy the selected icon to another position in any
;window visible in desktop.
;
;In: NOTHING
;Out: Modifications in buffers ,counters and MMW files
;
;In the system, this routine is called by the function MKICO, who
;takes care of clicks in the icons.
;

MVOX	DW	0
MVOY	DW	0
MVIC	DB	0	;FLAG: 0 = Normal, 1 = Moving icon.

MOVI:	PUSHA
	PUSH	ES
	PUSH	DS

	CMP	EXEP,1			;Checks for a doubleclick
	JZ	JMVF			;Yes, don't move the icon
	
	CMP	CS:ICSL,0		;Checks if there's a selected icon
	JZ	JMVF			;No, finishes the routine with no operation
	
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	
	CALL	MRKI			;Reads informations of the selected icon
	
	MOV	DI,OFFSET ICOC		;Copy informations to the buffer CS:ICOC
	MOV	SI,OFFSET ICOT
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	CLD
	REP	MOVSB
	
	MOV	SI,OFFSET CSAM		;Copy the BMP of mouse cursor together
	MOV	DI,OFFSET ICOB		;with the BMP of icon to be moved
	MOV	CX,240d
	MOV	AH,12d
	;---- LOOP1 -----
	LMV2:
	LODSB
	DEC	AH
	JNZ	JLMV21
	MOV	AH,12
	ADD	DI,20
	JLMV21:
	CMP	AL,0FFh
	JZ	JLMV20
	STOSB
	LOOP	LMV2
	JMP	JLMV2F
	JLMV20:
	INC	DI
	LOOP	LMV2
	;---- END1 -----
	JLMV2F:
	
	CALL	CHIDE			;Removes the mouse cursor
	MOV	DWORD PTR CS:[MVOX],0	;Zeroes previous positions
	
	;---- LOOP1 -----
	LMV0:
	CALL	LTR1
	TEST	BX,00000010b		;Released the button?
	JZ	JMV0			;Ends LOOP
	INC	CX
	INC	DX
	
	CMP	CX,MVOX 		;Checks for a mouse movement
	JNZ	JMV1			;Just passes from label JMV1 if the
	CMP	DX,MVOY 		;positions of mouse where changed.
	JZ	LMV0			;If they're not changed then jump.
	                                ;Return to loop until they're changed.
	JMV1:
	CMP	DWORD PTR CS:[MVOX],0	;Checks for the 1st plotting
	JZ	JMV2			;(Still doesn't have a reset buffer)
	
	PUSHA
	MOV	AX,MVOY
	MOV	BX,MVOX
	MOV	CX,32
	MOV	DX,CX
	MOV	SI,OFFSET MVIB		;Resets what was behind the icon
	CALL	BITMAP
	POPA
	
	JMV2:
	MOV	MVOY,DX 		;Save "previous" positions
	MOV	MVOX,CX
	
	MOV	AX,DX
	MOV	BX,CX
	MOV	CX,32
	MOV	DX,CX
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET MVIB		;Capture what was behind the icon
	CALL	CAPMAP			;to reset before.
	
	MOV	SI,OFFSET ICOB
	PUSH	CS
	POP	DS
	CALL	CRSMAP			;Draw the icon
	JMP	LMV0
	;---- END1 -----
	JMV0:
	CMP	MVOX,0			;Checks for changes in the icon position
	JZ	JMVF			;No changes, ends routine without update file MMW
	PUSHA
	MOV	AX,MVOY
	MOV	BX,MVOX
	MOV	CX,32
	MOV	DX,CX
	MOV	SI,OFFSET MVIB		;Resets what was behind the icon
	CALL	BITMAP
	
	POPA

	MOV	CX,MVOX 		;Resets icon position
	MOV	DX,MVOY 		;(to pass to the function below)
	
	CALL	XYWN			;Checks wich window was chosen
	OR	DI,DI			;None?
	JZ	JMVF			;Jump. Ends execution of routine
	
	;Checks if icon is being moved to the same place
	;If negative, always jump
	CALL	LTR1
	MOV	AX,ICXS
	CMP	CX,AX
	JNAE	JMV01
	ADD	AX,ICSX 
	CMP	CX,AX
	JA	JMV01
	
	MOV	AX,ICYS
	CMP	DX,AX
	JNAE	JMV01
	ADD	AX,ICSY
	CMP	DX,AX
	JA	JMV01
	
	JMP	JMVF			;Moving icon to the same place, ends routine
	
	JMV01:

	;Continues..

	MOV	MVIC,1			;Mark: MOVING ICON
	MOV	AH,2			;Checks if CONTROL is pressed
	INT	16h
	TEST	AL,00000100b
	JNZ	JMV6			;Yes, doesn't erase the icon who was dragged
	
	MOV	AIXX,0
	CMP	DI,CS:INDX		;Checks if it's necessary to update the origin window
	JZ	JMV6A			;(in the case of moving the icon from a window to another)
	MOV	MVIC,0			;If yes, call DICO to erase icon and update window.
	JMV6A:
	CALL	DICO			;Erases the icon that was dragged.
	MOV	MVIC,1			;Mark: MOVING ICON (who can have been temporarily unmarked by the above subroutine)
	CALL	MAXL			;Maximize limits to update the destination window.
	
	JMV6:
	CMP	DI,CS:INDX		;Checks if is the top window
	JZ	JMV02			;Yes, doesn't bring it to foreground
	CALL	CLKWIN			;Move the chosen window to foreground
	JMV02:	
	;Select icon in the position chosen by user

	MOV	CS:WINM,1		;FLAG MARK: Select icon of the window
	MOV	DI,CS:INDX		;Redraws the window
	MOV	BX,WORD PTR CS:[WIN1+DI]
	MOV	AX,WORD PTR CS:[WIN1+DI+2]
	MOV	DX,WORD PTR CS:[WIN1+DI+4]
	MOV	CX,WORD PTR CS:[WIN1+DI+6]
	SUB	CX,AX
	SUB	DX,BX
	MOV	SI,OFFSET TTLS
	ADD	SI,INDX
	CALL	CHIDE
	CALL	MACW			;Call window routine
	CALL	CSHOW			;to select the chosen icon
	MOV	MVIC,0			;Unmark: Moving icon
	
	;*** In CS:ICLC (WORD) is the number of selected icon
	
	MOV	CX,ICLC 		;Finds position of the selected icon
	DEC	CX			;to know when to stop copying the icon
	CMP	ICSL,0			;Checks if there's an icon selected
	JNZ	JMV4			;Yes, jump
	MOV	CX,CATE 		;No, places icon in the last free space
	JMV4:
	MOV	AX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)	
	MUL	CX			;in the loop below.
	PUSH	DX
	PUSH	AX
	POP	EAX
	ADD	EAX,(MMWTS+MMWXS+MMWCS)
	MOV	SLONG,EAX	
	
	MOV	AX,3D02h		;Open file MMW
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MMWBUF
	INT	21h
	JC	JMVF			;Error: Jump
	MOV	MVHN,AX
	
	MOV	AX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	CX,CATE
	;OR	CX,CX			;AUG99
	;JZ	JMV7
	JCXZ	JMV7
	DEC	CX
	JMV7:
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EAX
	ADD	EAX,(MMWTS+MMWXS+MMWCS)
	MOV	TLONG,EAX
	
	;----- LOOP1 -------
	LMV1:
	CALL	SECR			;Security. ENABLES ALT+X IN LOOP
	
	MOV	BX,MVHN
	MOV	AX,4200h		;Jumps to the previous icon
	MOV	DX,WORD PTR CS:TLONG
	MOV	CX,WORD PTR CS:TLONG+2
	INT	21h
	MOV	MVAX,AX
	MOV	MVDX,DX
	SUB	TLONG,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	JNC	JMV3
	MOV	TLONG,0
	
	JMV3:
	MOV	AH,3Fh			;Read an icon
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET ICOT
	INT	21h
	
	MOV	AH,40h			;Copy icon to front
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET ICOT

	INT	21h
	
	MOV	EAX,TLONG
	CMP	EAX,SLONG		;Checks if is already in the selected icon.
	JAE	LMV1			;Jumps if false
	;----- END1 -------
	
	MOV	BX,MVHN
	MOV	AX,4200h		;Jumps to previous icon
	MOV	DX,MVAX
	MOV	CX,MVDX
	CMP	ICSL,0			;Checks if the icon must be in the end
	JNZ	JMV5			;No, jump
	CMP	CATE,0			;Checks if there's no icon in the window
	JZ	JMV5			;Yes (there's no icons), jumps the add below
	ADD	DX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	JNC	JMV5
	INC	CX
	JMV5:
	INT	21h
	
	MOV	AH,40h			;Save icon who would have be copied
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET ICOC
	INT	21h
	
	XOR	AL,AL
	CALL	MCHK			;Do a checksum
	
	MOV	AH,3Eh			;Close file MMW
	INT	21h
	
	CALL	AJPP			;Updates foreground window
	CALL	MAXL			;Maximizes limits

	JMVF:				;Ends execution of routine MOVI:


	MOV	MVIC,0			;Unmark: Moving icon
	POP	DS
	POP	ES
	POPA
	RET
	
MVHN	DW	0	;File Handle
SLONG	DD	0	;Position of selected icon
MVDX	DW	0
MVAX	DW	0

;-------------------------------------------------------------
;Nanosistemas. Routine WHIDE
;Access: CALL WHIDE / EXTERN
;
;Hides or reopens the foreground window.
;
;In:      AL : 0 = Reopen window
;         AL : 1 = Hides window
;Returns: Changes in Nanosistemas internal memory
;         Changes in MMW file

WHTI	DB	0	;Operation (0=Normal Window, 1=Hidden Window)

WHIDE:	MOV	WHTI,AL 	;Saves parameter
	CMP	AL,1		;Invalid parameter,
	JA	JWHF		;jump

	PUSHA			;Start (parameter accepted)
	
	MOV	DI,OFFSET WIN1	;Zeroes positions of foreground window
	ADD	DI,CS:INDX
	MOV	DWORD PTR CS:[DI],0
	MOV	DWORD PTR CS:[DI+4],0
	
	;---- SUBROUTINE: INIT BUFFER MMWBUF WITH THE FILENAME OF FOREGROUND WINDOW
	PUSHA				;Prepares filename to be opened
	MOV	SI,OFFSET TTLS
	ADD	SI,INDX
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET MMWBUF	;Prepares register
	PUSHA
	MOV	CX,13d
	XOR	AL,AL
	REP	STOSB
	POPA
	MOV	CX,8
	;---- LOOP1 ------
	LWHB:				;Copies filename from window
	LODSB				;buffer (CS:TTLS) to the local
	OR	AL,AL			;buffer of routine MACW
	JZ	JWHB
	STOSB
	DEC	CX
	JNZ	LWHB
	;---- END1 ------
	JWHB:
	MOV	DWORD PTR CS:[DI],'WMM.';Writes the extension MMW in the end of string
	MOV	BYTE PTR CS:[DI+5],0	;Writes the ZERO of ASCII-ZERO
	POPA
	;---- END OF SUBROUTINE

	PUSHA
	MOV	AX,3D02h		  ;Open file MMW
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MMWBUF
	INT	21h
	JC	JWH2			;Error opening the file: Jump
	MOV	BX,AX
	MOV	LHAN,BX 		;Writes handler
	
	MOV	AH,3Fh			;Read file MMW
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	INT	21h
	
	MOV	AL,WHTI 		;Read the parameter
	MOV	BYTE PTR CS:[OFFSET MMWC+17d],AL	;Mark: HIDDEN WINDOW/NORMAL WINDOW
	OR	AL,AL		;If the window is hidden,
	JNZ	JWH0		;jump
	
	MOV	AX,MMWY 	;If the window was reopened,
	MOV	BX,MMWX 	;place the positions XYXXYY in memory again
	MOV	CX,MMWYY
	MOV	DX,MMWXX

	MOV	DI,CS:INDX
	ADD	CX,AX
	ADD	DX,BX
	MOV	WORD PTR CS:[WIN1+DI],BX
	MOV	WORD PTR CS:[WIN1+DI+2],AX
	MOV	WORD PTR CS:[WIN1+DI+4],DX
	MOV	WORD PTR CS:[WIN1+DI+6],CX
	
	JWH0:
	PUSHA
	MOV	AX,4200h		;Moves SEEK to the beginning of the file
	XOR	CX,CX
	XOR	DX,DX
	MOV	BX,LHAN
	INT	21h
	POPA
	
	PUSHA	
	MOV	AH,40h			;Writes file (Update)
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	MOV	BX,LHAN
	INT	21h
	POPA
	
	XOR	AL,AL		;Recalculate checksum
	MOV	BX,LHAN
	CALL	MCHK
	
	MOV	AH,3Eh			;Close file
	MOV	BX,LHAN
	INT	21h
	POPA

	CMP	WHTI,1		;Checks if the window is closed and must be
	JNZ	JWH3		;removed from desktop. No, jump
	MOV	AX,MMWY 	;If the window is closed (hidden),
	MOV	BX,MMWX 	;remove it from desktop
	MOV	CX,MMWYY	;The reason why this wasn't done above, right
	MOV	DX,MMWXX	;when checking (OR AL,AL, JNZ JWH0) if the window
	MOV	DI,CS:INDX	;was hidden is simple: If the routine REWRITE was
	ADD	CX,AX		;called before writing the file MMW, this routine
	ADD	DX,BX		;would destroy the buffer MMWx. So, it's verified
	SUB	AX,2		;if the window was closed just to see if it must
	ADD	DX,2		;be reopened. In the truth, it's verified if
	ADD	CX,2		;the window must be reopened.
	MOV	AIX,BX
	MOV	AIY,AX
	MOV	AIXX,DX
	MOV	AIYY,CX
	MOV	AEXX,0
	MOV	WINM,0		;Flag mark: DRAW WINDOWS NORMALLY
	CALL	REWRITE
	CALL	MAXL		;Maximizes limits
	JWH3:

	XOR	BX,BX		;Prepares registers to enter in the function
	XOR	CX,CX		;MACW
	XOR	DX,DX
	MOV	SI,OFFSET TTLS
	ADD	SI,CS:INDX
	CALL	MACW		;Tells system that window was hidden
	JWH2:
	POPA
	JWHF:
	RET

;-------------------------------------------------------------
;Nanosistemas. Routine MRKI
;Access: CALL MRKI / EXTERN
;
;Read data of the selected icon to the buffer ICOT
;The data are: NAME OF WINDOW, POSITIONS XYXXYY and WINDOW SETUP
;
;In:      NOTHING
;Returns: Changes in buffer CS:ICOT

MRKI:	PUSHA
	CMP	CS:INDX,0	;Checks if there's an active window
	JNZ	JKR9		;Yes, jump
	POPA			;No, return
	RET
	
	JKR9:
	MOV	AX,CS:ICLC	;Checks if the icon that will be erased
	CMP	AX,CS:ICWA	;really exists
	JNA	JKR8		;Yes, continues
	POPA			;No, finishes the routine

	RET
	
	JKR8:
	CMP	ICWA,0		;Checks if there are icons in the current window
	JNZ	JKR7		;Yes, continues
	POPA			;No, finishes routine
	RET	
			
	JKR7:
	CMP	ICLC,0		;Checks if there's an icon selected
	JNZ	JKR6		;Yes, continues
	POPA			;No, finishes routine
	RET
	
	JKR6:
	MOV	AX,3D02h	  ;Open the file
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MMWBUF;Last window selected
	INT	21h
	JC	JKRF		;Error: Finishes routine
	MOV	BX,AX
	

	; TLONG=((ICOTS+ICOBS+ICOPS+ICODS+ICORS)*ICLC)+MMWTS+MMWXS+MMWCS
	; FPOS=TLONG

	MOV	AX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	CX,ICLC
	DEC	CX
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EAX
	ADD	EAX,(MMWTS+MMWXS+MMWCS)
	MOV	TLONG,EAX
	MOV	DX,AX
	SHR	EAX,16
	MOV	CX,AX
	MOV	AX,4200h	;Moves pointer to the beginning of icons
	INT	21h
	JC	JKRF		;Error: Finishes routine

	MOV	AH,3Fh		;Read icon
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET ICOT
	INT	21h
	
	MOV	AH,3Eh		;Close file
	INT	21h
	JKRF:
	POPA
	RET

;-------------------------------------------------------------
;Nanosistemas. Function CLKWIN

;Access: CALL CLKWIN / EXTERN
;
;Moves the selected window to priority 1 making changes in the screen
;and in the internal table of Nanosistemas.
;
;In: DI :    Window number x 8 (As counted by CS:INDX), being 0 for the first window, 1 for the second...etc.
;Returns:    Changes in the local internal memory of Nanosistemas and system screen
;	     Destroys ES and DS
DWTEMP: DQ	0	;Qword of transition (64bits)
TWTEMP: DQ	0

CLKWIN: PUSHA
	CALL	DISJ			;Unmarks selected icon in the previous window


	MOV	EAX,DWORD PTR CS:WIN1+DI	;Stores XYXXYY in transition
	MOV	DWORD PTR CS:DWTEMP,EAX 	;memory
	MOV	EAX,DWORD PTR CS:WIN1+DI+4
	MOV	DWORD PTR CS:DWTEMP+4,EAX

	MOV	EAX,DWORD PTR CS:TTLS+DI	;Stores FILE MMW in transition
	MOV	DWORD PTR CS:TWTEMP,EAX 	;memory
	MOV	EAX,DWORD PTR CS:TTLS+DI+4
	MOV	DWORD PTR CS:TWTEMP+4,EAX

	PUSHA
	MOV	CX,CS:INDX	;Rotates the buffer CS:WIN1
	SUB	CX,DI		;Like this:	(Assuming for example that
	SHR	CX,3		;		 DI is pointing to CCC)
	PUSH	CS		;	    <-----------
	POP	DS		;AAA BBB CCC DDD EEE FFF
	PUSH	CS		;	 --->		
	POP	ES		;
	ADD	DI,OFFSET WIN1	;AAA BBB DDD EEE FFF CCC
	MOV	SI,DI
	ADD	SI,8
	MOV	BX,CX
	ADD	CX,BX
	CLD
	REP	MOVSD
	POPA
	
	MOV	CX,CS:INDX	;Rotates the buffer CS:TTLS
	SUB	CX,DI		;Like this:	(Assuming for example that
	SHR	CX,3		;		 DI is pointing to CCC)
	PUSH	CS		;	    <-----------
	POP	DS		;AAA BBB CCC DDD EEE FFF
	PUSH	CS		;	 --->		
	POP	ES		;
	ADD	DI,OFFSET TTLS	;AAA BBB DDD EEE FFF CCC
	MOV	SI,DI
	ADD	SI,8 
	MOV	BX,CX
	ADD	CX,BX
	CLD
	REP	MOVSD

	PUSHA
	MOV	DI,CS:INDX			;Saves the priority window
	MOV	EAX,DWORD PTR CS:TWTEMP 	;level 1 at the end of CS:TTLS
	MOV	DWORD PTR CS:TTLS+DI,EAX
	MOV	EAX,DWORD PTR CS:TWTEMP+4
	MOV	DWORD PTR CS:TTLS+DI+4,EAX
	POPA

	MOV	DI,CS:INDX			;Saves the priority window
	MOV	EAX,DWORD PTR CS:DWTEMP 	;level 1 at the end of CS:WIN1
	MOV	DWORD PTR CS:WIN1+DI,EAX
	MOV	EAX,DWORD PTR CS:DWTEMP+4
	MOV	DWORD PTR CS:WIN1+DI+4,EAX
	
	MOV	BX,WORD PTR CS:DWTEMP		;Redraws the selected window
	MOV	AX,WORD PTR CS:[DWTEMP+2]
	MOV	DX,WORD PTR CS:[DWTEMP+4]
	SUB	DX,BX
	MOV	CX,WORD PTR CS:[DWTEMP+6]
	SUB	CX,AX
	
	PUSH	AX
	PUSH	DI
	PUSH	DX
	
	;(DI/8)*8 + OFFSET TTLS = Offset of the title buffer
	ADD	DI,OFFSET TTLS
	MOV	SI,DI
	
	POP	DX
	POP	DI
	POP	AX

	OR	CX,CX		;Checks if the window needs to be reopened
	JNZ	JNPR		;Doesn't need to reopen, jump.
	
	;Reopen the window in foreground
	XOR	AL,AL
	CALL	WHIDE
	MOV	AX,MMWY 	;Prepares registers
	MOV	BX,MMWX 	;Reassign the positions XYSXSY
	MOV	CX,MMWYY
	MOV	DX,MMWXX

	JNPR:
	PUSH	CS
	POP	DS	;In DS:SI is the title to be read

	MOV	WINM,0		;FLAG: Shows window normaly
	
	CALL	CHIDE
	CALL	MACW
	CALL	CSHOW
	POPA
	RET
	;----- END OF ROUTINE

;-------------------------------------------------------------
;Nanosistemas. Function DISJ
;Access: CALL DISJ / EXTERN
;
;Unmarks the selected icon of the window in priority 1
;
;In:      NOTHING
;Returns: Changes in video memory
;	  Doesn't changes the file MMW

DISJ:	PUSHA
	PUSH	DS
	MOV	DI,CS:INDX
	OR	DI,DI			;Verifica se ha alguma janela no desktop
	JZ	JDFF			;Negativo, pula
	MOV	BX,WORD PTR CS:WIN1+DI		 ;Redesenha janela selecionada
	MOV	AX,WORD PTR CS:[WIN1+DI+2]
	MOV	DX,WORD PTR CS:[WIN1+DI+4]
	SUB	DX,BX
	MOV	CX,WORD PTR CS:[WIN1+DI+6]
	SUB	CX,AX
	
	PUSH	AX
	PUSH	DI
	PUSH	DX
	;(DI/8)*8 + OFFSET TTLS = Offset do buffer do titulo
	ADD	DI,OFFSET TTLS
	MOV	SI,DI
	PUSH	CS
	POP	DS	;Em DS:SI esta onde deve ser lido o titulo
	
	POP	DX
	POP	DI
	POP	AX
	MOV	WINM,2		;FLAG: Atualize as icones
	CALL	CHIDE
	CALL	MACW
	CALL	CSHOW
	MOV	WINM,0
	JDFF:
	POP	DS
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao EXECP
;Acesso: CALL EXECP / EXTERNO
;
;Executa o programa (CS:ICOP contem o path\filename) da ultima icone 
;selecionada no desktop
;
;Entra: Buffer CS:ICOP = Path/Filename ASCIIZ do arquivo a executar
;Retorna (quando retorna): Refaz todo o ambiente

OLDDRV	DB	0
OFSPRM	DW	0		;Offset do parametro

;------ inicio da rotina:
EXECP:	
	MOV	WORD PTR CS:[OFFSET STAN],SP	;Grava SS e SP
	MOV	WORD PTR CS:[OFFSET STAN+2],SS
	
	CALL	CHIDE
	CALL	MAXL		;Maximiza limites
	MOV	RAI,0
	MOV	RAE,0
	MOV	BYTE PTR CS:[OFFSET OLDDIRE],'\'
	
	CLD
	MOV	AX,CS			;Prepara parametros para executar programa
	MOV	DS,AX
	MOV	ES,AX
	MOV	SI,OFFSET ICOP
	MOV	CX,79d
	
	LEXEC0: 	;LOOP		;Procura inicio da linha de parametro
	LODSB
	OR	AL,AL
	JZ	JLEXEC0A
	CMP	AL,32d
	JZ	JLEXEC0F
	LOOP	LEXEC0	;END
	
	JMP	JEXECF			;Finaliza se nao encontrou 0 nem 32
	
	JLEXEC0A:
	DEC	SI			;Se nao tiver linha de comando..
	MOV	WORD PTR CS:[OFFSET BLOCK+2],SI
	JMP	JEXEC1	
	
	JLEXEC0F:
	MOV	DI,SI
	MOV	BYTE PTR CS:[DI-1],0	;Separa PATH/FNAME da LINHA DE COMANDO
	MOV	WORD PTR CS:[OFFSET BLOCK+2],DI
	
	MOV	CX,0FFFFh		;Prepara linha de parametro
	XOR	AL,AL
	REPNZ	SCASB			;Leva DI ao final da string
	MOV	SI,DI
	DEC	SI
	NEG	CX
	DEC	CX			;CX agora contem tamanho da linha de comando
	STD
	PUSH	CX
	REP	MOVSB			;Move toda a string 1 byte para frente
	POP	AX
	STOSB				;Grava tamanho da linha de comando
	CLD
	JEXEC1:
	
	MOV	AH,3Bh			;Ajusta o diretorio atual
	MOV	DX,OFFSET ICOD
	INT	21h
	
	MOV	AH,0Eh			;Ajusta o drive atual (se necessario)
	MOV	DL,BYTE PTR CS:[OFFSET ICOD]
	OR	DL,32d
	CMP	DL,97d			;Verifica se o usuario colocou a letra
	JNAE	JEX1			;do drive antes do diretorio de trabalho
	CMP	DL,120d 		;(ex: D:\dos\norton)
	JA	JEX1			;     -
	SUB	DL,97d
	INT	21h
	JEX1:
	
	MOV	AX,3D00h		;Verifica se o arquivo existe
	MOV	DX,OFFSET ICOP
	INT	21h
	JC	JEXECF			;Erro, finaliza rotina (nao executa)
	
	MOV	BX,AX
	MOV	AX,4202h
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	PUSH	DX
	PUSH	AX
	POP	FESIZE			;Grava tamanho do arquivo
	
	MOV	AH,3Eh			;Fecha o arquivo
	INT	21h
	
	;Prepara para executar o programa
	MOV	STEX,0			;Marca: Programa ainda nao foi executado
	MOV	WORD PTR CS:[OFFSET BLOCK+4],CS ;Grava CS na memoria	
	MOV	WORD PTR CS:[OFFSET BLOCK+8],CS 
	MOV	WORD PTR CS:[OFFSET BLOCK+12],CS	
	MOV	AX,4B01h
	MOV	DX,OFFSET ICOP
	MOV	BX,OFFSET BLOCK
	INT	21h
	JC	JEXECF			;Erro, pula. Nao executa.

	CMP	STEX,1			;Verifica se o programa ja foi executado
	JZ	JEXECA			;Afirmativo, pula e nao executa novamente

	CALL	CMMP		;Verifica se e' um programa do sistema
	
	CMP	PRTP,0		;Verifica se e' um programa NSYSCODE0
	JNZ	JEXECB		;Afirmativo, pula
	
	;Prepara computador para receber programa DOS
	MOV	DX,UART
	CALL	POPP		;Restaura porta do mouse
	CALL	DALB		;Desaloca memoria desnecessaria (buffer do BMP de fundo)
	CALL	DBMC		;Desaloca buffer de 13456 bytes do manipulador de erro critico
	CALL	DMNS		;Desinstala manipuladores de interrupcao
	
	MOV	AX,0003h	;Muda para modo texto
	INT	10h
	
	JEXECB:
	;Prepara registradores de entrada para o programa
	
	MOV	AH,62h			;Poe em BX o segmento do PSP do programa
	INT	21h		
	MOV	DS,BX			;Ajusta registradores de segmento
	MOV	ES,BX
	MOV	FS,BX
	MOV	GS,BX
	XOR	AX,AX			;Zera registradores gerais
	MOV	BX,AX
	MOV	CX,AX
	MOV	DX,AX
	MOV	SI,AX
	MOV	DI,AX
	MOV	BP,AX
	MOV	AX,VERSAO		;Entra a versao em AX

	LSS	SP,ENVR 		;Prepara SS e SP
	MOV	STEX,1			;Marca: Programa ja foi executado
	CMP	CFAR,0			;Verifica se CFAR contem um endereco
	JZ	JEXECA			;Negativo, pula. Nao executa programa
	MOV	ALTX,1			;Desativa ALT+X
	CALL	ZBANKS			;Zera todos os bancos de enderecos
	JMP	CFAR			;Executa programa na memoria
	
	JEXECA:
	CALL	ZBANKS			;Zera todos os bancos de enderecos
	MOV	ALTX,0			;Reativa ALT+X
	CMP	PRTP,1			;Nao reatualiza sistema se o 
	JZ	JEXECF			;programa era um programa do sistema
	LSS	SP,STAN 		;Restaura stack
	
	MOV	AX,4F02h		;Muda o modo de video para modo grafico
	MOV	CX,CS:SRES
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET USLS
	MOV	BX,CS:SRES
	INT	10h
	
	;Retorna ao diretorio do sistema
	CALL	SPATH
	
	;Finaliza
	MOV	EXEP,0		;Marca: NAO executar programa
	CALL	NEWR		;Reinicia totalmente o Nanosistemas
	
	JEXECF:
	;Retorna ao diretorio do sistema
	LSS	SP,STAN 	;Restaura stack
	CALL	SPATH		;Retorna ao diretorio do sistema
	RET			;Finaliza e retorna

;---------------------------------
;Subrotina: Verifica se o programa carregado pela funcao EXECP
;e' um programa do sistema. Se for, altera dados do programa
;(marcando que o sistema esta carregado) e marca MMPR=1.
;Se nao for, marca MMPR=0 e retorna.

FESIZE	DD	0		;Tamanho do arquivo carregado

MMID:	DB	'SISCODE0'	;ID do sistema

;Estrutura:

;ID	9 bytes 'NSYSCODE0'
;CFAR	DWORD	Endereco para acesso as rotinas do sistema (CALL FAR CFAR)
;RESV	5 bytes RESERVADO. Para uso futuro 

CMMP:	PUSHA
	PUSH	ES
	PUSH	DS
	
	MOV	PRTP,0		;Marca: PROGRAMA DOS
	MOV	EBX,DWORD PTR CS:[OFFSET MMID]
	MOV	EDX,DWORD PTR CS:[OFFSET MMID+4]
	CLD
	LES	DI,CFAR 	;ES:DI contem o endereco do programa
	MOV	ECX,FESIZE
	MOV	AL,'N' 
	CMP	ECX,0FFFFh	;Nao permite pesquisar mais de 65536 bytes
	JNA	LCMMP0
	MOV	CX,0FFFFh
	LCMMP0:
	REPNZ	SCASB		;Procura pela 1a letra da ID.
	JCXZ	JCMMPF		;Nao encontrou, pula e finaliza
	
	;Tendo encontrado a 1a letra, verifica as outras
	CMP	DWORD PTR ES:[DI],EBX
	JNZ	LCMMP0
	CMP	DWORD PTR ES:[DI+4],EDX
	JNZ	LCMMP0
	;Passando daqui, entao a ID foi encontrada

	;Grava endereco do manipulador KERNEL
	MOV	WORD PTR ES:[DI+8],OFFSET KERNEL
	MOV	WORD PTR ES:[DI+10],CS
	MOV	PRTP,1		;Marca: PROGRAMA NSYSCODE0
	
	JCMMPF: 		;Finaliza rotina
	POP	DS
	POP	ES
	POPA
	RET
;---------------------------------

BLOCK:	;Bloco de parametro (Sempre, em qualquer programa, vai estar como abaixo)	
	DW	0		;Ambiente (0=default environm)
	DW	0		;Offset linha de parametro
	DW	0		;Seg. linha de parametro
	DW	OFFSET FCBS	;1o FCB
	DW	0
	DW	OFFSET FCBS	;2o FCB
	DW	0
ENVR	DD	0		;SSSP para o programa, se AX=4B01h
CFAR	DD	0		;CSIP - endereco do programa, se AX=4B01h
	
FCBS:	DB	20 dup (0)	;20 bytes com zero. Para o bloco de parametro
STAN	DD	0		;Stack anterior ao CALL FAR (SS e SP)
STEX	DB	0		;0 = Prog. ainda nao foi executado
				;1 = prog. ja foi executado
PRTP	DB	0		;0 = Programa DOS normal
				;1 = Programa do sistema (NSYSCODE0)
				
-------------------------------------------------------------
;Nanosistemas. Funcao MKICO
;Acesso: CALL MKICO / EXTERNO
;
;Marca a icone selecionada pelo click do mouse (da janela em 1o plano)
;A icone selecionada na janela em prioridade 1 e' a icone que esta
;em baixo do cursor do mouse (Posicoes retornadas por CS:LTR1).
;Se o botao se manter pressionado e o usuario movimentar o cursor
;arrastando a icone, o controle sera transferido a rotina CS:MOVI,
;que permitira' o usuario movimentar a icone.
;
;Entra: NADA
;Retorna: NADA

MKICO:	PUSHA
	MOV	CS:WINM,1	;FLAG: Selecionar icone da janela 1
	MOV	DI,CS:INDX		;Redesenha a janela

	MOV	BX,WORD PTR CS:[WIN1+DI]
	MOV	AX,WORD PTR CS:[WIN1+DI+2]
	MOV	DX,WORD PTR CS:[WIN1+DI+4]
	MOV	CX,WORD PTR CS:[WIN1+DI+6]
	SUB	CX,AX
	SUB	DX,BX
	MOV	SI,OFFSET TTLS
	ADD	SI,INDX
	CALL	CHIDE
	CALL	MACW		;Chama rotina da janela
	CALL	CSHOW
	
	CALL	LTR1		;Le posicoes atuais do mouse
	JMK2:
	MOV	MVOX,CX 	;Grava na memoria
	MOV	MVOY,DX
	;Signf: 10 pixels
	
	;--- LOOP1 -----	;Aguarda liberar botao do mouse
	LMK0:
	CALL	LTR1
	
	;Verifica se usuario arrastou a icone
	;Pula sempre que afirmativo
	ADD	MVOX,20 ;Testa X
	CMP	CX,MVOX
	JA	JMK1

	SUB	MVOX,40
	CMP	CX,MVOX
	JNAE	JMK1
	ADD	MVOX,20
	
	ADD	MVOY,20 ;Testa Y
	CMP	DX,MVOY
	JA	JMK1
	SUB	MVOY,40
	CMP	DX,MVOY
	JNAE	JMK1
	ADD	MVOY,20
	
	TEST	BX,00000011b	;Verifica se usuario soltou o botao do mouse
	JNZ	LMK0		;Negativo, pula e prossegue o loop
	;--- END1 -----
	LMKF:
	MOV	WINM,0		;Finaliza rotina
	POPA
	RET

	JMK1:
	CMP	ICSL,1		;Verifica se ha icone selecionada
	JNZ	JMK2		;Negativo, retorna ao LOOP
	CALL	MOVI		;Afirmativo, arrasta icone
	JMP	LMKF		;Retorna, finaliza rotina
	
-------------------------------------------------------------
;Nanosistemas. Funcao WSCRL
;Acesso: CALL WSCRL / EXTERNO
;
;Executa um Scroll Down ou um Scroll Up na janela em primeiro plano
;
;Entra:
;	AH :   0       = Scroll Up
;	AH :   1       = Scroll Down
;	AH :  >1       = Nao modifica nada
;
;Retorna:
;	Alteracoes no arquivo MMW da janela em primeiro plano
;	Flags e registradores de segmentos sao destruidos.

WSTM	DB	0	;Tmp

WSCRL:	CMP	AH,1			;Ignora, caso tenha parametro invalido
	JA	JWSF
	MOV	WSTM,AH

	;---- SUBROTINA: MONTA BUFFER MMWBUF COM O NOME DO ARQUIVO DA JANELA EM PRIMEIRO PLANO
	PUSHA				;Prepara nome do arquivo a ser aberto
	MOV	SI,OFFSET TTLS
	ADD	SI,INDX
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET MMWBUF	;Prepara registrador
	PUSHA
	MOV	CX,13d
	XOR	AL,AL
	REP	STOSB
	POPA
	MOV	CX,8
	;---- LOOP1 ------
	LWSB:				;Copia nome do arquivo do buffer
	LODSB				;das janelas (CS:TTLS) para o buffer
	OR	AL,AL			;local da rotina MACW
	JZ	JWSB
	STOSB
	DEC	CX
	JNZ	LWSB
	;---- END1 ------
	JWSB:
	MOV	DWORD PTR CS:[DI],'WMM.';Grava a extensao MMW no final da string
	MOV	BYTE PTR CS:[DI+5],0	;Grava o ZERO do ASCII-ZERO
	POPA
	;---- FIM DA SUBROTINA

	PUSHA
	MOV	AX,3D02h		  ;Abre arquivo MMW
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MMWBUF
	INT	21h
	JC	JWS2			;Erro na abertura do arquivo: Pula
	MOV	BX,AX
	MOV	LHAN,BX 		;Grava manipulador
	
	MOV	AH,3Fh			;Le arquivo MMW
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	INT	21h
	
	PUSHA
	MOV	AX,4200h		;Desloca SEEK para posicao desejada
	XOR	CX,CX
	MOV	DX,(MMWTS+MMWXS+18d)
	INT	21h
	POPA
	
	MOV	TEMP,0
	CMP	WSTM,0			;Verifica o tipo de scroll (Up/Down)
	JNZ	JWS0
	MOV	CX,CATS 		;Verifica se ira rotacionar pra cima linhas que existam
	CMP	CX,WORD PTR CS:[OFFSET MMWT+(MMWTS+MMWXS+18d)]
	JNAE	JWS0
	INC	WORD PTR CS:[OFFSET MMWT+(MMWTS+MMWXS+18d)]	;-> Scroll Down
	JMP	JWS1
	
	JWS0:							;-> Scroll Up
	MOV	TEMP,10
	CMP	WORD PTR CS:[OFFSET MMWT+(MMWTS+MMWXS+18d)],0	;Verifica se ja esta no minimo
	JZ	JWS1
	DEC	WORD PTR CS:[OFFSET MMWT+(MMWTS+MMWXS+18d)]
	MOV	TEMP,0

	JWS1:
	PUSHA

	MOV	AX,4200h		;Desloca SEEK para inicio do arquivo
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	POPA
	
	PUSHA	
	MOV	AH,40h			;Grava arquivo (Atualiza)
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	INT	21h
	POPA
	
	MOV	AH,3Eh			;Fecha arquivo
	INT	21h
	
	;--- LOOP1 -----		;Aguarda liberar botao do mouse
	LWS0:
	CALL	LTR1
	TEST	BX,00000011b
	JNZ	LWS0
	;--- END1 -----
	CMP	TEMP,10 		;Verifica se sera necessario redesenhar a janela
	JZ	JWS2			;Negativo, pula proxima rotina	
	CALL	CHIDE
	MOV	DI,CS:INDX		;Redesenha a janela
	MOV	BX,WORD PTR CS:[WIN1+DI]
	MOV	AX,WORD PTR CS:[WIN1+DI+2]
	MOV	DX,WORD PTR CS:[WIN1+DI+4]
	MOV	CX,WORD PTR CS:[WIN1+DI+6]
	MOV	AIX,BX		;Ajusta area de inclusao para o limite da janela
	MOV	AIY,AX
	MOV	AIXX,DX
	MOV	AIYY,CX
	ADD	AIX,3
	ADD	AIY,18
	SUB	AIXX,19
	SUB	AIYY,2
	SUB	CX,AX		;Prepara registradores para desenhar janela
	SUB	DX,BX
	MOV	SI,OFFSET TTLS
	ADD	SI,INDX
	MOV	WINM,0			;FLAG: Apenas redesenhar background
	CALL	MACW
	CALL	CSHOW
	MOV	AIX,0		;Maximiza a area de inclusao
	MOV	AIY,0
	MOV	AX,RX
	MOV	AIXX,AX
	MOV	AX,RY
	MOV	AIYY,AX

	JWS2:
	POPA
	JWSF:
	RET


-------------------------------------------------------------
;Nanosistemas. Funcao WMOVE
;Acesso: CALL WMOVE / EXTERNO
;
;Movimenta ou redimensiona a janela que esta em primeiro plano.
;
;Entra: CS:PMAG=1 : Move
;	CS:PMAG=2 : Redimensiona
;Retorna: Alteracoes em CS:WIN1
;	  Registradores intactos, exceto FLAGS e segmento (DS e ES)

WMTM	DQ	0	;Temporario: Armazena posicao inicial da janela

PIRX	DW	0	;Posicao Inicial Relativa X
PIRY	DW	0	;Posicao Inicial Relativa Y

WMPX	DW	0	;Posicoes exatas da janela
WMPY	DW	0
WMXX	DW	0
WMYY	DW	0

;--------------------------------------------------
;SUBROTINA INTERNA:
;Desenha um retangulo utilizando XOR BYTE,0FFh (veja rotina XORNT) ou
;movimenta a janela em primeiro plano
;Entra: CS:WMPX : Pos X
;	CS:WMPY : Pos Y
;	CS:WMXX : Pos XX
;	CS:WMYY : Pos YY
;	CS:FULL : 0 = Mover apenas bordas
;	CS:FULL : 1 = FULL MOVEMENT
;Retorna: Alteracoes na memoria de video

XRPX	DW	0	;Posicoes anteriores da janela
XRPY	DW	0
XRXX	DW	0
XRYY	DW	0

XRECT:	PUSHA
	
	MOV	AX,WMPY 	;Traca retangulo usando XOR
	MOV	BX,WMPX
	
	CMP	FULL,0		;Verifica se deve mover a janela
	JZ	LWM1		;Negativo, pula para rotina que traca as bordas da janela
				;Positivo, prossegue.	
	CMP	CS:TEMP,0	;Verifica se esta apagando a janela
	JNZ	JWM6		;Positivo, pula (para atualizar desktop)
				;Negativo, entao em WM?? temos as posicoes da janela "anterior" 
	MOV	AX,WMPX 	;GRAVA POSICOES DE INCLUSAO (JANELA A SER RETIRADA)
	MOV	BX,WMPY
	MOV	CX,WMXX
	MOV	DX,WMYY
	MOV	XRPX,AX
	MOV	XRPY,BX
	MOV	XRXX,CX
	MOV	XRYY,DX
	JMP	JWM5

	JWM6:
	MOV	AX,XRPX
	MOV	BX,XRPY
	MOV	CX,XRXX
	MOV	DX,XRYY
	SUB	BX,2		
	ADD	CX,2
	ADD	DX,2
	MOV	AIX,AX		;Ajusta area de exclusao
	MOV	AIY,BX
	MOV	AIXX,CX
	MOV	AIYY,DX
	MOV	AX,WMPX
	MOV	BX,WMPY
	MOV	CX,WMXX
	MOV	DX,WMYY
	MOV	DI,CS:INDX
	MOV	WORD PTR CS:[WIN1+DI],AX	;Atualiza na tabela CS:WIN1
	MOV	WORD PTR CS:[WIN1+DI+2],BX
	MOV	WORD PTR CS:[WIN1+DI+4],CX
	MOV	WORD PTR CS:[WIN1+DI+6],DX
	MOV	AEX,AX		;Ajusta area de exclusao
	MOV	AEY,BX
	MOV	AEXX,CX
	DEC	DX
	MOV	AEYY,DX

	MOV	WINM,3		;Marca flag: NAO ATUALIZAR ARQUIVO MMW
	CMP	TEMP,2		;E' a ultima atualizacao?
	JNZ	JXR1		;Negativo, pula
	MOV	WINM,0		;Positivo, marca: Atualizar arquivo MMW
	JXR1:
	CALL	REWRITE 	;Redesenha desktop
	JMP	JWM5
	
	;---- LOOP2 -----	;Nao usar FULLMOVEMENT? Pula pra ca'
	LWM1:
	CALL	XORNT
	ADD	BX,1
	CMP	BX,WMXX
	JNAE	LWM1
	;---- END2 -----
	;---- LOOP3 -----
	LWM2:
	CALL	XORNT
	ADD	AX,1
	CMP	AX,WMYY
	JNAE	LWM2
	;---- END3 -----
	;---- LOOP4 -----
	LWM3:
	CALL	XORNT
	SUB	BX,1
	CMP	BX,WMPX
	JAE	LWM3
	;---- END4 -----
	;---- LOOP5 -----
	LWM4:
	CALL	XORNT
	SUB	AX,1
	CMP	AX,WMPY
	JAE	LWM4
	;---- END5 -----
	JWM5:
	POPA
	RET

WMOVE:	PUSHA
	CALL	CHIDE		;Retira o cursor do mouse da tela
	
	MOV	DI,CS:INDX
	MOV	AX,WORD PTR CS:[WIN1+DI]
	MOV	BX,WORD PTR CS:[WIN1+DI+2]
	MOV	CX,WORD PTR CS:[WIN1+DI+4]
	MOV	DX,WORD PTR CS:[WIN1+DI+6]
	MOV	WMPX,AX
	MOV	WMPY,BX
	MOV	WMXX,CX
	MOV	WMYY,DX
	MOV	WORD PTR CS:WMTM,AX	;Armazena posicoes iniciais da janela.
	MOV	WORD PTR CS:WMTM+2,BX	;Deste modo, se nao foi feita modificacoes
	MOV	WORD PTR CS:WMTM+4,CX	;no tamanho da janela, nao atualiza-a
	MOV	WORD PTR CS:WMTM+6,DX
	ADD	CX,2
	ADD	DX,2
	SUB	BX,2
	MOV	AIX,AX		;Define a area de inclusao
	MOV	AIY,BX
	MOV	AIXX,CX
	MOV	AIYY,DX
	
	CALL	LTR1		;Le posicoes XY do mouse
	MOV	CS:PIRX,CX	;Grava posicoes XY do mouse
	MOV	CS:PIRY,DX
	CALL	XRECT		;Traca primeiro retangulo XOR
	
	;---- LOOP1 ------------------------------
	LWM0:
	MOV	CS:TEMP,0	;Zera "Retangulo ja apagado" flag
	CALL	LTR1		;Le novas posicoes XY do mouse
	
	CMP	CX,CS:PIRX	;Verifica se houve movimentacao X
	JZ	JWM1
	PUSHF
	CALL	XRECT		;Apaga retangulo
	MOV	CS:TEMP,1	;Marca "Retangulo ja apagado" flag
	POPF
	JA	JWA1		;Verifica movimento X
	MOV	AX,CS:PIRX	;Move janela pra esquerda
	SUB	AX,CX
	CMP	CS:PMAJ,2	;Verifica se esta redimensionando janela
	JZ	JTJ1		;Afirmativo, nao verifica limite >0 ,checado abaixo
	CMP	AX,WMPX 	;Nao permite puxar a janela para menos que 0
	JNAE	JTJ1
	MOV	AX,WMPX 	;Reajusta movimento para a esquerda
	DEC	AX

	JTJ1:
	CMP	CS:PMAJ,2	;Verifica se esta redimensionando janela
	JZ	JTR1		;Afirmativo, nao muda POS XY iniciais
	SUB	WMPX,AX
	JTR1:
	MOV	SI,WMPX 	;Verifica se a janela ficara pequena demais
	ADD	SI,150d 	
	CMP	SI,WMXX
	JAE	JWM1		;Caso afirmativo, nao modifica-a
	SUB	WMXX,AX
	JMP	JWM1
	
	JWA1:
	PUSH	CX		;Move janela pra direita
	MOV	AX,CS:PIRX
	SUB	CX,AX

	CMP	CS:PMAJ,2	;Verifica se esta redimensionando janela
	JZ	JTR2		;Afirmativo, nao muda POS XY iniciais
	ADD	WMPX,CX
	JTR2:
	ADD	WMXX,CX
	POP	CX
	JWM1:
	
	CMP	DX,CS:PIRY	;Verifica se houve movimentacao Y
	JZ	JWM2
	PUSHF
	CMP	CS:TEMP,1	;Verifica "Retangulo ja apagado" flag
	JZ	JRJA		;Estando 1, entao o retangulo ja foi apagado
	CALL	XRECT		;Estando 0, apaga o retangulo
	MOV	CS:TEMP,1
	JRJA:
	POPF
	JA	JWA2		;Verifica movimento Y
	MOV	AX,CS:PIRY	;Move janela pra cima
	SUB	AX,DX
	
	CMP	CS:PMAJ,2	;Verifica se esta redimensionando janela
	JZ	JTJ2		;Afirmativo, nao verifica limite >18 ,checado abaixo
	
	MOV	SI,WMPY
	SUB	SI,AX
	CMP	SI,18		;Nao permite puxar a janela para menos que 18
	JAE	JHD2
	MOV	WMPY,18 	;Ajusta posicao Y para 18
	ADD	SI,AX		;Ajusta posicao YY
	SUB	SI,18
	SUB	WMYY,SI
	JMP	JWM2

	JHD2:

	JTJ2:
	CMP	CS:PMAJ,2	;Verifica se esta redimensionando janela
	JZ	JTR3		;Afirmativo, nao muda POS XY iniciais
	SUB	WMPY,AX
	JTR3:
	MOV	SI,WMPY 	;Verifica se a janela ficara pequena demais
	ADD	SI,100d 	
	CMP	SI,WMYY
	JAE	JTZ2		;Caso afirmativo, nao modifica-a
	SUB	WMYY,AX
	JTZ2:
	JMP	JWM2
	JWA2:
	PUSH	DX		;Move janela pra baixo
	MOV	AX,CS:PIRY
	SUB	DX,AX
	CMP	CS:PMAJ,2	;Verifica se esta redimensionando janela
	JZ	JTR4		;Afirmativo, nao muda POS XY iniciais
	ADD	WMPY,DX
	JTR4:
	ADD	WMYY,DX
	POP	DX
	
	JWM2:
	MOV	CS:PIRX,CX	;Grava posicoes XY do mouse
	MOV	CS:PIRY,DX
	CMP	CS:TEMP,1	;Verifica se a janela foi movida e deve tracar novo retangulo
	JNZ	JNDT
	CALL	XRECT		;Desenha "XORtangulo"
	JNDT:
	TEST	BX,00000010b	;Verifica se o botao ainda esta pressionado
	JNZ	LWM0		;Afirmativo, prossegue LOOP
	;---- END1 ------------------------------
	MOV	TEMP,2
	CALL	XRECT		;Apaga retangulo
	MOV	AX,WMPX 	;Le novas posicoes
	MOV	BX,WMPY
	MOV	CX,WMXX
	MOV	DX,WMYY
	MOV	AEX,AX		;Ajusta area de exclusao
	MOV	AEY,BX
	MOV	AEXX,CX
	MOV	AEYY,DX
	MOV	DI,CS:INDX
	
	CMP	WORD PTR CS:WMTM,AX	;Compara posicoes iniciais da janela com 
	JNZ	JWM9			;as novas posicoes da janela.	
	CMP	WORD PTR CS:WMTM+2,BX	;Deste modo, se nao foi feita modificacoes
	JNZ	JWM9	
	CMP	WORD PTR CS:WMTM+4,CX	;no tamanho da janela, nao atualiza-a
	JNZ	JWM9	
	CMP	WORD PTR CS:WMTM+6,DX
	JNZ	JWM9
	JMP	JWMF			;Chegando aqui, todos sao iguais. Nao redesenha janela
	
	JWM9:
	MOV	WORD PTR CS:[WIN1+DI],AX	;Atualiza na tabela CS:WIN1
	MOV	WORD PTR CS:[WIN1+DI+2],BX
	MOV	WORD PTR CS:[WIN1+DI+4],CX
	MOV	WORD PTR CS:[WIN1+DI+6],DX

	CMP	CS:FULL,1		;FULLMOVEMENT?
	JZ	JWMF			;Pula, nao precisa atualizar desktop
	MOV	DMAL,0
	MOV	WINM,0
	DEC	AEYY
	CALL	REWRITE 		;Caso contrario, atualiza desktop
	
	JWMF:				;Maximiza limites
	CALL	MAXL
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao LINEV
;Acesso: CALL LINEV / EXTERNO
;
;Desenha uma linha vertical na tela de video grafica.
;
;Entra:
;	AX	 : Pos: Y, 
;	BX	 : Pos: X, 
;	CX	 : Tamanho
;	DL	 : Cor
;Retorna:
;	Alteracoes na memoria de video
;	Flags e registradores de segmento (DS e ES) sao destruidos

LINEV:	PUSHA	
	;AY,BX,CC

	LLV0:
	PUSH	CX
	MOV	CL,DL
	CALL	POINT
	POP	CX
	INC	AX
	DEC	CX
	JNZ	LLV0
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao LINEH
;Acesso: CALL LINEH / EXTERNO
;
;Desenha uma linha horizontal na tela de video grafica.
;
;Entra:
;	AX	 : Pos: Y, 
;	BX	 : Pos: X, 
;	CX	 : Tamanho
;	DL	 : Cor

;Retorna:
;	Alteracoes na memoria de video

;	Flags e registradores de segmento (DS e ES) sao destruidos


LIPY	DW	0	;Posicao Y

LINEH:	PUSHA
	;AY,BX,CC
	LLH0:
	PUSH	CX
	MOV	CL,DL
	CALL	POINT
	POP	CX
	INC	BX
	DEC	CX
	JNZ	LLH0
	POPA
	RET
	

-------------------------------------------------------------
;Nanosistemas. Funcao RECT
;Acesso: CALL RECT / EXTERNO
;
;Desenha um retangulo na tela de video grafica
;
;Entra:
;	AX     : Pos: Y
;	BX     : Pos: X
;	CX     : Tamanho X
;	DX     : Tamanho Y
;	SI     : Cor
;Retorna:
;	Alteracoes na memoria de video
;	Flags e registradores de segmento (DS e ES) sao destruidos

RECT:	PUSHA
	MOV	DI,DX		;X
	MOV	DX,SI
	CALL	LINEH
	ADD	AX,DI
	DEC	AX
	CALL	LINEH
	POPA
	PUSHA
	MOV	DI,CX		;Y
	MOV	CX,DX
	MOV	DX,SI
	CALL	LINEV
	ADD	BX,DI
	CALL	LINEV
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao RECF
;Acesso: CALL RECF / EXTERNO
;
;Desenha um retangulo solido na tela de video
;respeitando os limites de inclusao e exclusao, ignorando RAI e RAE.
;Rotina rapida.
;
;Entra:
;	AX	: Pos: Y
;	BX	: Pos: X
;	CX	: Tamanho X
;	DX	: Tamanho Y
;	SI	: Cor
;Retorna:
;	Alteracoes na memoria de video

RFPX	DW	0	;Pos X
RFPY	DW	0	;Pos Y
RFSX	DW	0	;Tamanho X
RFSY	DW	0	;Tamanho Y
RFCR	DW	0	;Cor
RFJS	DW	0	;RX-Tamanho X

RECF:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CMP	BX,RX		;Verifica se o retangulo estara fora da tela (EM X)
	JAE	JRFF		;Afirmativo, pula
	CMP	AX,RY		;Verifica se o retangulo estara fora da tela (EM Y)
	JAE	JRFF		;Afirmativo, pula	
	MOV	DI,BX		;Verifica se esta fora do limite X
	ADD	DI,CX
	CMP	DI,RX
	JNAE	JRF9		;Negativo, pula
	SUB	DI,RX		;Positivo, ajusta tamanho X
	SUB	CX,DI
	JRF9:
	MOV	RFPX,BX 	;Grava valores na memoria
	MOV	RFPY,AX
	MOV	RFSX,CX
	MOV	RFSY,DX
	MOV	RFCR,SI
	MOV	SI,RX
	SUB	SI,CX
	MOV	RFJS,SI
	
	INC	AX
	MUL	CS:RX		;Calcula a pagina e o offset da pagina
	ADD	AX,BX
	JNC	JRF0
	INC	DX
	JRF0:
		
	XCHG	AX,DX		;15NOV98 **********************
	MUL	GRFC
	XCHG	AX,DX

	CMP	DX,CS:OFST	;Verifica se sera necessario pular de pagina
	JE	NRFD		;Caso negativo, ignora a INT 10h
	
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	PUSH	DX
	PUSH	AX
	MOV	AX,4F05h	;Muda a pagina de video
	XOR	BH,BH
	MOV	BL,WJAN
	INT	10h
	POP	AX
	POP	DX
	
	NRFD:
	;Aponta registradores para a memoria de video
	MOV	ES,WSEG
	MOV	DI,AX
	
	MOV	CX,RFSX
	MOV	DX,RFSY
	MOV	AX,RFCR
	MOV	BX,RFPX
	MOV	SI,RFPY
	CLD

	
	;Neste ponto:
	;ES:DI	: Seg:Offset do primeiro ponto na memoria de video
	;CX	: Tamanho X
	;DX	: Tamanho Y
	;BX	: Pos X
	;SI	: Pos Y
	;AX	: Cor (AL)
	;-------- LOOP1 ----------
	;-------- LOOP2 ----------
	LRF0:
	CMP	BX,RX		;Verifica LIMITE X DA TELA
	JAE	JRF8
	CMP	BX,AIX		;Verifica AREA DE INCLUSAO
	JNAE	JRF8		;(Pula se ponto for rejentado)
	CMP	BX,AIXX
	JAE	JRF8
	CMP	SI,AIY
	JNAE	JRF8
	CMP	SI,AIYY
	JAE	JRF8
	CMP	BX,AEX		;Verifica AREA DE EXCLUSAO
	JNAE	JRF7		;(Pula se ponto for aceito)
	CMP	BX,AEXX
	JA	JRF7
	CMP	SI,AEY
	JNAE	JRF7
	CMP	SI,AEYY
	JA	JRF7
	JRF8:
	
	INC	DI		;Marca "ponto invisivel"
	JMP	JRF6		;Pula
	JRF7:
	STOSB
	JRF6:

	INC	BX
	OR	DI,DI		;Verifica se deve trocar de pagina
	JNZ	JRF4		;Nao, pula
	CALL	NEXT		;Sim, vai pra proxima pagina
	JRF4:
	
	DEC	CX		;Verifica se terminou uma linha
	JNZ	LRF0		;Negativo, prossegue o LOOP
	;-------- END2 ----------
	INC	SI
	MOV	BX,RFPX
	ADD	DI,RFJS 	;Passa DI para a proxima linha
	JNC	JRF5		;Mudar de pagina: NAO: Pula
	CALL	NEXT		;Muda de pagina
	JRF5:
	MOV	CX,RFSX 	;Recarrega CX
	DEC	DX
	JNZ	LRF0		;Ainda nao terminando, prossegue o loop
	;-------- END1 ----------
	JRFF:
	POP	ES
	POP	DS
	POPA
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao NCMS
;Acesso: CALL NCMS / EXTERNO
;
;Desenha caixa de mensagem 
;
;Entra:
;	AX     : Posicao Y (FFFFh = Centralizado)
;	BX     : Posicao X (FFFFh = Centralizado)
;	CX     : Tamanho X
;	DX     : Tamanho Y
;
;Retorna:
;	AX     : Posicao Y do inicio (sup esq) da janela
;	BX     : Posicao X do inicio (sup esq) da janela
;
;	Area de inclusao e' ajustada para a caixa de mensagem.
;
;OBS:	Se na entrada AX ou BX for igual a FFFEh (ao inves de FFFFh), 
;	esta funcao nao ira' alterar a memoria de video, mas apenas
;	retornar (em AX e BX) as posicoes Y e X da janela.
;	(0FFFEh tambem significa Centralizado nesta funcao)
;
;As cores da caixa de mensagem sao as cores definidas para o sistema.

NCMSX	DW	0d
NCMSY	DW	0d
NCMIX	DW	0
NCMIY	DW	0
NCMAX	DW	0
NCMBX	DW	0

NCMS:	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	NCMAX,AX
	MOV	NCMAX,BX
	MOV	CS:NCMSX,CX
	MOV	CS:NCMSY,DX

	CMP	BX,0FFFEh	;Centralizar em X
	JNA	JNCJY		;Negativo, pula
	
	MOV	BX,CS:RX	;Centraliza janela (Em X)
	SHR	BX,1		
	MOV	DI,NCMSX
	SHR	DI,1
	SUB	BX,DI
	
	JNCJY:
	CMP	AX,0FFFEh	;Centralizar em Y
	JNA	JNC00		;Negativo, pula
	
	MOV	AX,CS:RY	;Centraliza janela (Em Y)
	SHR	AX,1
	MOV	DI,NCMSY
	SHR	DI,1
	SUB	AX,DI
	
	JNC00:
	MOV	NCMIX,BX	;Grava posicao XY inicial (sup esq)
	MOV	NCMIY,AX
	
	CMP	NCMAX,0FFFEh	;Verifica se deve desenhar a janela
	JZ	JNCMSF		;Pula se negativo
	CMP	NCMBX,0FFFEh	
	JZ	JNCMSF		
	
	PUSHA
	
	MOV	DL,BORD 	;Desenha bordas ESQ e SUP
	MOV	CX,NCMSY
	CALL	LINEV
	PUSHA
	MOV	CX,NCMSX
	CALL	LINEH
	
	INC	BX		;Desenha retangulo preenchido
	MOV	DX,NCMSY
	MOVZX	SI,CS:TBCR
	CALL	RECF
	
	ADD	AX,DX
	MOV	DL,BORD 	;Desenha borda inferior
	CALL	LINEH
	ADD	BX,2
	DEC	CX
	INC	AX
	MOV	DL,CS:INTC	
	CALL	LINEH
	POPA
	ADD	BX,NCMSX	;Desenha borda direita
	CALL	LINEV
	INC	BX
	ADD	AX,2
	MOV	DL,CS:INTC	
	CALL	LINEV
	
	POPA
	ADD	AX,3		;Desenha retangulo interior
	ADD	BX,3
	MOV	CX,NCMSX
	SUB	CX,6
	MOV	DX,NCMSY
	SUB	DX,5
	MOVZX	SI,BORD
	CALL	RECT

	JNCMSF:
	MOV	AX,NCMIY
	MOV	BX,NCMIX
	SUB	AX,2
	SUB	BX,2
	MOV	CS:AIX,BX	;Ajusta area de inclusao
	MOV	CS:AIY,AX	;para evitar retrace geral
	ADD	BX,CS:NCMSX	;do desktop quando fechada a janela
	ADD	AX,CS:NCMSY
	ADD	AX,4
	ADD	BX,4
	MOV	CS:AIXX,BX
	MOV	CS:AIYY,AX
	
	POP	ES
	POP	DS
	POPA
	MOV	AX,NCMIY	;Restaura posicoes XY iniciais (sup esq)
	MOV	BX,NCMIX
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao BITMAP
;Acesso: CALL BITMAP / EXTERNO
;
;Desenha um BITMAP na tela grafica, usando a funcao POINT
;
;Entra:
;	AX	 : Pos: Y, 
;	BX	 : Pos: X, 
;	CX	 : Tamanho X
;	DX	 : Tamanho Y
;	DS:SI	 : Offset do bitmap
;
;Retorna:
;	Alteracoes na memoria de video.
; 
EXCX	DW	0
EXCY	DW	0
BMSX	DW	0	;Tamanho X (CX)
EPX	DW	0	;Posicoes XY do ponto sendo plotado
EPY	DW	0
BMTX	DW	0	;Tamanho X temporario

BITMAP: PUSHA
	PUSH	DS

	;Prepara registradores e memoria para inicio do LOOP principal
	
	PUSH	AX
	MOV	EXCX,CX ;Salva parametros
	MOV	EXCY,DX

	PUSH	RX	;Em BMTX, o tamanho X a ser adicionado ao
	POP	BMTX	;DI para passar para o inicio da proxima linha
	SUB	BMTX,CX 
	
	PUSH	BX
	CALL	CALXY	;Calcula coordenadas do pixel inicial
	POP	BX
	
	;Em AX o offset 
	
	MOV	ES,WSEG
	MOV	DI,AX
	POP	DX

	;Em DX a posicao Y do 1o ponto 
		
	;LOOP0
	--------------
	LBTM0:
	
	;Verifica AREA DE INCLUSAO
	CMP	RAI,1		;Respeitar area de inclusao
	JZ	JBTM6		;Negativo, pula
	
	CMP	BX,AIX		;Verifica AREA DE INCLUSAO	
	JB	JBTM3		;Pula se fails
	CMP	DX,AIY
	JB	JBTM3
	CMP	BX,AIXX
	JA	JBTM3
	CMP	DX,AIYY
	JA	JBTM3

	;Verifica AREA DE EXCLUSAO	
	JBTM6:
	CMP	RAE,1		;Respeitar area de exclusao
	JZ	JBTM4		;Negativo, pula

	CMP	BX,AEX		;Verifica AREA DE EXCLUSAO
	JB	JBTM4		;Pula se success
	CMP	DX,AEY
	JB	JBTM4
	CMP	BX,AEXX
	JA	JBTM4
	CMP	DX,AEYY
	JA	JBTM4
	
	;Nao traca ponto - Pula MOVSB
	JBTM3:			;LIMITS FAILURE: flows..
	INC	SI
	INC	DI
	JMP	JBTM5		;Pula sem copiar pixels

	;Se o ponto estiver dentro do limite X da tela, plota usando MOVSB
	JBTM4:
	CMP	BX,RX		;04MAR2001 - Nao permite pontos
	JAE	JBTM3		;apos o limite X da tela
	MOVSB

	;Prepara registradores para o proximo ponto
	JBTM5:
	OR	SI,SI		;Troca de segmento de leitura
	JNZ	JBTM0
	MOV	AX,DS
	ADD	AX,1000h
	MOV	DS,AX
	JBTM0:
	OR	DI,DI		;Troca de segmento (pagina) de video
	JNZ	JBTM1		;(escrita)
	CALL	NEXT
	JBTM1:
	INC	BX	
	
	DEC	CX
	JNZ	LBTM0		;Nao terminando uma linha, retorna ao LOOP
	--------------
	;END0 (1)

	INC	DX
	SUB	BX,EXCX
	MOV	CX,EXCX
	ADD	DI,BMTX 	;Passa para a proxima linha
	JNC	JBTM2
	CALL	NEXT		;Pula de pagina de video se necessario
	JBTM2:
	DEC	EXCY		;Verifica se ja terminou todas as linhas
	JNZ	LBTM0		;Negativo, retorna ao LOOP
	--------------
	;END0 (2)
	
	POP	DS
	POPA
	RET			;Finaliza e retorna
	
-------------------------------------------------------------
;Nanosistemas. Funcao BINMAP
;Acesso: CALL BINMAP / EXTERNO
;
;Desenha um BITMAP BINARIO na tela grafica usando a funcao POINT.
;
;Entra:
;	AX	 : Pos: Y, 
;	BX	 : Pos: X, 
;	CX	 : Tamanho X (Multiplo de 8)
;	DX	 : Tamanho Y

;	DS:SI	 : Endereco do binmap
;	DI	 : Cor do bitmap (Parte alta->Frente, Parte baixa->Fundo)
;
;Retorna:
;	Alteracoes na memoria de video.
;	Flags e registradores de segmento (DS e ES) sao destruidos
;
;OBS:	O BINMAP e' uma icone definida por bits, e nao bytes.
;	Vantagem: Menor em tamanho
;	Desvantagem: Monocromatica
;
;	Se a cor do fundo (Parte baixa de DI) for 0FFh, entao o fundo sera'
;	transparente
;
;EXEMPLO:
;
;	JMP	 JUMP1
;
;	BINICO1: DW 0011111111111100b
;		 DW 0010000000000100b
;		 DW 0010011001100100b
;		 DW 0010000110000100b
;		 DW 0010011001100100b
;		 DW 0010000000000100b
;		 DW 0011111111111100b
;	
;	JUMP1:	 MOV AX,10d
;		 MOV BX,10d
;		 MOV CX,16d
;		 MOV DX,7d
;		 MOV SI,OFFSET BINICO1
;		 CALL BINMAP
BNMB	DB	0
BNMF	DB	0

BINMAP: PUSHA
	MOV	WORD PTR CS:[BNMB],DI

	PUSH	AX
	CMP	BNMF,0FFh	;Verifica COR PADRAO DO SISTEMA
	JNZ	JBINMAP1
	MOV	AL,TCIB
	MOV	BNMF,AL
	JBINMAP1:
	POP	AX
	
	INC	AX
	MOV	CS:BMSX,CX
	MOV	DI,CX
	ADD	BX,CX
	;------ LOOP1 ----
	;------ LOOP2 ----
	LBN0:		;Le o byte, coloca em CL e chama POINT
	MOV	CL,BYTE PTR DS:[SI]
	INC	SI
	
	MOV	CH,00000001b
	LBN1:
	TEST	CL,CH
	JNZ	JBN0A
	CMP	BNMB,0FFh
	JZ	JBN0
	PUSH	CX
	MOV	CL,BNMB
	JMP	JBN0B
	JBN0A:
	PUSH	CX
	MOV	CL,BNMF
	JBN0B:
	CALL	POINT
	POP	CX
	JBN0:
	SHL	CH,1
	DEC	BX
	OR	CH,CH
	JNZ	LBN1
	
	SUB	DI,8	;Se DI=0, passa para a proxima linha
	JNZ	LBN0
	;------ END2 -----
	MOV	DI,CS:BMSX	;Reinicia Tamanho X
	ADD	BX,DI
	INC	AX	;Passa para a proxima linha
	DEC	DX
	OR	DX,DX	;Verifica se ja terminou
	JNZ	LBN0	;Negativo, volta para prosseguir
	;------ END1 -----
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao CRSMAP
;Acesso: CALL CRSMAP / EXTERNO
;
;Desenha o CURSOR do mouse na tela grafica.
;
;Entra:
;	AX	 : Pos: Y, 
;	BX	 : Pos: X, 
;	CX	 : Tamanho X
;	DX	 : Tamanho Y
;	DS:SI	 : Offset do bitmap
;Retorna:
;	Alteracoes na memoria de video.
;	Flags e registradores de segmento (DS e ES) sao destruidos
;
;OBS:	A unica diferenca desta funcao para a funcao BITMAP
;	e' que esta funcao nao plotara um ponto com a cor 0FFh,
;	isto significa que a cor 0FFh e' equivalente a cor TRANSPARENTE.

CRSMAP: PUSHA
	INC	AX
	MOV	CS:BMSX,CX
	MOV	DI,CX
	
	;------ LOOP1 ----
	;------ LOOP2 ----
	LCM0:		;Le o byte, coloca em CL e chama POINT
	MOV	CL,BYTE PTR CS:[SI]
	INC	SI
	CMP	CL,0FFh ;Se for uma parte transparente do cursor...
	JZ	JCM0	;simplesmente nao marca o ponto
	
	CMP	BX,RX	;Nao permite cursor passar do limite X da tela
	JAE	JCM0	;..nao marcando nenhum ponto alem do limite X.
	CALL	POINT	;Se o ponto esta antes do limite X, marca-o

	JCM0:
	INC	BX	
	DEC	DI	;Se DI=0, passa para a proxima linha
	JNZ	LCM0
	;------ END2 -----
	MOV	DI,CS:BMSX	;Reinicia Tamanho X
	
	SUB	BX,DI
	INC	AX	;Passa para a proxima linha
	DEC	DX
	OR	DX,DX	;Verifica se ja terminou
	JNZ	LCM0	;Negativo, volta para prosseguir
	;------ END1 -----
	MOV	CS:RAE,0	;Volte a considerar areas de inclusao e exclusao
	MOV	CS:RAI,0
	POPA
	RET


-------------------------------------------------------------
;Nanosistemas. Funcao 1Ah
;Acesso: CALL CAPMAP / EXTERNO
;
;Captura uma BITMAP da tela grafica e grava no buffer
;
;Entra:
;	AX	 : Pos: Y, 
;	BX	 : Pos: X, 
;	CX	 : Tamanho X
;	DX	 : Tamanho Y
;	ES:DI	 : Offset do buffer
;Retorna:
;	Alteracoes na memoria de video.
;	Flags e registradores de segmento (DS e ES) sao destruidos
;
;OBS:	Area de inclusao nem area de exclusao sao consideradas nesta funcao

CAPMAP: PUSHA

	PUSH	DX
	;INC	 AX
	MUL	CS:RX		;Calcula a pagina e o offset da pagina
	ADD	AX,BX
	JNC	LCC0
	INC	DX
	LCC0:
		
	XCHG	AX,DX		;15NOV98 **********************
	MUL	GRFC
	XCHG	AX,DX

	;Retirado em 28 SET 1999
	;CMP	 DX,CS:OFST	 ;Verifica se sera necessario pular de pagina
	;JE	 NCID		 ;Caso negativo, ignora a INT 10h
	
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	PUSH	DX
	PUSH	AX
	MOV	AX,4F05h	;Muda a pagina de video
	XOR	BH,BH
	MOV	BL,RJAN
	CALL	INT10H
	POP	AX
	POP	DX
	
	;NCID:
	;Aponta registradores para a memoria de video
	MOV	DS,RSEG
	MOV	SI,AX
	POP	DX
	CLD
	;SI - Fonte
	;DI - Destino
	;LOOP1
	LC00:
	PUSH	CX
	;-------- INICIO DO LOOP -------------
	LC01:
	CMP	SI,0FFFFh	;Verifica se precisa pular de pagina
	JNE	LCC2		;Caso positivo, ignora o jump
	;*** A linha de execucao so chegara aqui caso SI=0FFFFh,
	;    quando deverse-a trocar de pagina de video e zerar
	;    o valor de SI. Caso SI < 0FFFFh, entao a linha de 
	;    execucao ira direto para LSSD (para ler o ponto da tela)
	MOVSB
	CALL	NEXTR		;Proxima pagina de video
	XOR	SI,SI		;Zera SI 

	JMP	LCC1		;Continua com o LOOP				
	;*** Fim da rotina de mudanca de pagina de video
	LCC2:			;Escreve um ponto na memoria de video
	MOVSB
	LCC1:
	OR	DI,DI		;Verifica se DI passou de segmento
	JNZ	JCC1		;Negativo, pula
	MOV	AX,ES		;Afirmativo, passa ES para o proximo segmento
	ADD	AX,1000h
	MOV	ES,AX
	JCC1:
	DEC	CX		;Decrementa CX
	JNZ	LC01		;Prossegue o LOOP se CX>0
	;-------- FIM DO LOOP -------------
	POP	CX		;Restaura o tamanho da linha X
	DEC	DX		;Decrementa uma linha
	JZ	LCNX		;Ultima, finaliza
	
	MOV	BX,CS:RX	;Manda SI para a proxima linha
	SUB	BX,CX
	ADD	SI,BX		;Verifica se pulou de segmento
	JNC	LCN1		;Caso negativo, vai tracar a proxima linha
	CALL	NEXTR		;Positivo, passa para a proxima pagina de video
	LCN1:
	JMP	LC00
	;END1
	
	LCNX:
	POPA
	MOV	OFST,0FFFFh	;Forca proxima rotina atualizar pagina de video
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao CHNC
;Acesso: CALL CHNC / EXTERNO
;
;Permite ao usuario escolher uma cor (entre 0..15) e retorna
;a cor escolhida.
;
;Entra: AX	: Pos.Y do menu (0FFFFh = Centralizado)
;	BX	: Pos.X do menu (0FFFFh = Centralizado)
;Retorna:
;	AL	: 0 = Ok. Cor escolhida. 1 = Cancelado pelo usuario
;	CL	: Cor escolhida
;
NCPX	DW	0	;Pos.X
NCPY	DW	0	;Pos.Y
NCAL	DB	0	;AL na saida
NCCL	DB	0	;CL na saida

CHNC:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CALL	MAXL
	
	CALL	CHIDE
	
	MOV	MECX,BX
	MOV	MECY,AX

	MOV	CX,117d
	MOV	DX,080d
	MOV	ES,BMEC 	;Copia video para o buffer		
	XOR	DI,DI
	DEC	AX
	CALL	CAPMAP
	INC	AX
	
	MOV	CX,115d ;Desenha menu
	MOV	DX,078d
	CALL	NCMS
	MOV	NCPX,BX
	MOV	NCPY,AX
	
	ADD	AX,10d
	ADD	BX,10d
	MOV	CX,20d
	MOV	DX,10d
	XOR	SI,SI
	XOR	DI,DI
	
	;LOOP		;Desenha 16 retangulos, cada um com uma cor
	LCHNC0:
	CALL	RECF	
	INC	DI
	INC	SI
	ADD	BX,25
	
	CMP	DI,4
	JNZ	JCHNC0
	XOR	DI,DI
	ADD	AX,15d
	SUB	BX,100d
	JCHNC0:
	
	CMP	SI,16d
	JNZ	LCHNC0
	;END

	
	CALL	CSHOW
	CALL	MOUSE
	MOV	NCAL,1
	
	TEST	BX,11b		;Verifica se foi clicado dentro da janela
	JZ	JCHNC1		;Pula se negativo
	CMP	CX,NCPX
	JNA	JCHNC1
	CMP	DX,NCPY
	JNA	JCHNC1
	MOV	AX,NCPX
	ADD	AX,115d
	CMP	CX,AX
	JA	JCHNC1
	MOV	AX,NCPY
	ADD	AX,78d
	CMP	DX,AX
	JA	JCHNC1
	;Passando daqui, entao foi clicado dentro da janela
	
	MOV	NCAL,0
	MOV	AX,DX
	MOV	BX,CX
	
	MUL	CS:RX		;Calcula a pagina e o offset da pagina
	ADD	AX,BX
	JNC	$+3
	INC	DX
	
	XCHG	AX,DX		;15NOV98 **********************
	MUL	GRFC
	XCHG	AX,DX
		
	;Retirado em 28 SET 1999		
	;CMP	 DX,CS:OFST	 ;Verifica se sera necessario pular de pagina
	;JE	 CNID		 ;Caso negativo, ignora a INT 10h
	
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	PUSH	AX
	MOV	AX,4F05h	;Muda a pagina de video
	XOR	BH,BH
	MOV	BL,RJAN
	INT	10h
	POP	AX

	;CNID:
	MOV	CS:OFST,0FFFFh	;Forca outras funcoes atualizar pagina de video
	;Le o byte
	MOV	GS,RSEG
	MOV	BX,AX
	MOV	CL,BYTE PTR GS:[BX]
	MOV	NCCL,CL
	JCHNC1:
	
	CALL	CHIDE		;Retira cursor do mouse
	
	MOV	AX,MECY 	;Restaura o que estava atraz da janela
	DEC	AX
	MOV	BX,MECX
	MOV	CX,117d
	MOV	DX,080d
	MOV	DS,BMEC
	XOR	SI,SI
	CALL	BITMAP
	
	CALL	CSHOW		;Recoloca cursor do mouse
	
	POP	ES
	POP	DS
	POPA
	MOV	AL,NCAL
	MOV	CL,NCCL
	RET
	
-------------------------------------------------------------
;NANOSISTEMAS. Funcao CCSI
;Acesso: CALL CCSI
;
;Exibe um menu para configuracao das cores do sistema.
;
;Entra: Nada
;Retorna: Possiveis alteracoes na memoria do sistema e arquivo CFG
;
;
CCSIT:	DB	'˛System Color Setupˇ',2,28,' - Refresh',13
	DB	2,46,' - Factory Defaults',13
	DB	4,1,2,46,'	',140,'  RGB values',13,4,5
	DB	2,36,'	 RED',13
	DB	2,36,' GREEN',13
	DB	2,36,'	BLUE',13,5,66
	DB	'    Text',13
	DB	'    Windows',13
	DB	'    Monochrome Icons',13
	DB	'    Top Bar',13
	DB	'    Top Bar Contents',13
	DB	'    Text Boxes',13
	DB	'    Text on Text Boxes',13
	DB	'    All Borders',13
	DB	'    Background',13
	DB	'    Scroll Bar on Desktop Windows',13
	DB	'    Selection on Selected Icons',13
	DB	'    Text on Selected Icons',13
	DB	'    Text on Non-Selected Icons',13
	DB	'    Desktop Windows Background',13
	DB	'    Labels Background on Desktop Windows',13

	DB	'    Titlebar Color on Desktop Windows',13
	DB	'    Labels on Desktop Windows',13
	DB	'    Shadows (2nd border)',13,0

CCINF:	DW	0FFFFh	;Posicao X (0FFFFh = Centralizado em X)
	DW	0FFFFh	;Posicao Y (0FFFFh = Centralizado em Y)
	DW	400d	;Tamanho X da janela
	DW	370d	;Tamanho Y da janela
	DW	0	;CLICKS:OFF
	
	DW	1	;Textos
	DW	40
	DW	20
	DB 8 DUP (0)
	DB	0FFh
	DB	1
	DW OFFSET CCSIT
	DW	0
	DW 0,0,0
	
	DW	5	;Click nas cores
	DW	20
	DW	52
	DB 9 dup (0)
	DB	8
	DW	0FFFFh
	DW	0FFFFh
	DW	0FFFFh
	DW	0FFFFh
	DB	20
	DB	135
	
	DW	5	;Click nas cores
	DW	20
	DW	187
	DB 9 dup (0)
	DB	8
	DW	0FFFFh
	DW	0FFFFh
	DW	0FFFFh
	DW	0FFFFh
	DB	20
	DB	135

	DW	05		;ICONE [ F5 - Refresh ]
	DW	250
	DW	20
	DB 9 dup (0)
	DB	4h
	DW	OFFSET IFREF
	DW	0
	DB	00h
	DB	03Fh
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	16
	DB	11
	
	DW	05		;ICONE Padrao do sistema
	DW	250
	DW	35
	DB 9 dup (0)
	DB	5h
	DW	OFFSET OMNOR
	DW	0
	DB	00h
	DB	03Fh
	DB	0FFh	;COR B
	DB	0FFh	;COR F
	DB	16
	DB	11

	DW	05		;ICONE Cor a alterar RGB values
	DW	250
	DW	35+15
	DB 9 dup (0)
	DB	'R'
	DW	OFFSET SCID 
	DW	0
	DB	00h
	DB	03Fh
	DB	0FFh	;COR B
	DB	0FFh	;COR F
	DB	16
	DB	14
	
	DW	05		;ICONE Cor a alterar RGB values
	DW	250+20
	DW	35+17
	DB 9 dup (0)
	DB	'R'
	DW	OFFSET CBRR 
	DW	0
	DB	00h
	DB	03Fh
	DB	0	;COR B
NCORR:	DB	0	;COR F
	DB	16
	DB	10
	
	DW	7,250,70,0,0,0,0
	DB	5
	DB	63d
VRED:	DW	OFFSET RGBVAL,0,0,0FFFFh,0
	
	DW	7,250,70+15,0,0,0,0
	DB	5
	DB	63d
VGRE:	DW	OFFSET RGBVAL+1,0,0,0FFFFh,0
	
	DW	7,250,70+30,0,0,0,0
	DB	5
	DB	63d
VBLU:	DW	OFFSET RGBVAL+2,0,0,0FFFFh,0
	
	DW	05h	;Funcao 05h -> Poe uma icone binaria
	DW	118d	;Posicao X em relacao a esquerda da janela
	DW	330d	;Posicao Y em relacao ao topo da janela
	DB 9 dup (0)	;RESERVADO
	DB	01h	;Codigo de retorno para a icone de OK
	DW OFFSET ICNF	;Offset da icone
	DW	00h	;Segmento da icone (0=Use CS)
	DB	013d	;ASCII code da hotkey (0FFh = Nem verifique)
	DB	028d	;Scan code da hotkey (0FFh = Nem verifique)
	DB	0FFh	;Cor de fundo
	DB	0FFh	;Cor de frente
	DB	64d	;Tamanho X da icone
	DB	20d	;Tamanho Y da icone
	
	DW	05h	;Funcao 05h -> Poe uma icone binaria
	DW	208d	;Posicao X em relacao a esquerda da janela
	DW	330d	;Posicao Y em relacao ao topo da janela
	DB 9 dup (0)	;RESERVADO
	DB	02h	;Codigo de retorno para a icone de CANCEL
	DW OFFSET ICNG	;Offset da icone
	DW	00h	;Segmento da icone (0=Use CS)
	DB	027d	;ASCII code da hotkey (0FFh = Nem verifique)
	DB	001d	;Scan code da hotkey (0FFh = Nem verifique)
	DB	0FFh	;Cor de fundo
	DB	0FFh	;Cor de frente
	DB	64d	;Tamanho X da icone
	DB	20d	;Tamanho Y da icone
	
	DB	0FFh
	
CBRR:	DW	0000000000000000b	;16x11 CBRR
	DW	0111111111111110b
	DW	0111111111111110b
	DW	0111111111111110b
	DW	0111111111111110b
	DW	0111111111111110b
	DW	0111111111111110b
	DW	0111111111111110b
	DW	0111111111111110b
	DW	0000000000000000b
	
;Cores padrao do sistema
CPSM:	DB	00	;Cor de frente dos textos (em geral)
	DB	15	;Cor de fundo das caixas de mensagens
	DB	00	;Cor de frente icones binarias
	DB	15	;Cor da barra superior
	DB	00	;Cor dos textos da barra superior
	DB	15	;Cor de fundo das textboxes
	DB	00	;Cor dos textos das textboxes
	DB	00	;Cor das bordas (em geral)
	DB	07	;Cor do background
	DB	07	;Cor da scroll bar das janelas
	DB	07	;Cor de fundo - texto icones selecionadas
	DB	00	;Cor de frente - texto icones selecionadas  
	DB	00	;Cor de frente - texto icones nao selecionadas
	DB	15	;Cor de fundo da janela (area das icones)
	DB	15	;Cor das faixas superior e inferior (barra de titulo)
	DB	07	;Cor da faixa central (barra de titulo)
	DB	00	;Cor do texto da barra de titulo
	DB	08	;Cor da listra entre a barra de titulo e a janela


;Inicio dos bytes dos valores RGB das 16 cores padrao do sistema
RGBSTD: DB	0,0,0		;Definicao dos padroes do sistema
	DB	0,0,42
	DB	0,42,0
	DB	0,42,42
	DB	42,0,0
	DB	42,0,42
	DB	42,42,0
	DB	42,42,42
	DB	0,0,21
	DB	0,0,63
	DB	0,42,21
	DB	0,42,63
	DB	42,0,21
	DB	42,0,63
	DB	42,42,21
	DB	63,63,63

;Bank 5 - Atualiza cores do sistema em tempo real
BANK5:	PUSHA
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET RGBVAL	;Atualiza palette
	CALL	SYSPLT
	POP	DS
	POPA
	RETF				;Return to base

;Inicio da rotina principal
CCSI:	PUSHA
	PUSH	DS
	PUSH	ES

	MOV	BL,5		;Ajusta banco para barras RGB realtime ajust
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BANK5
	CALL	CBANK

	CALL	MAXL		;Prepara janela para a entrada na funcao MOPC
	CALL	AUSB
	
	PUSH	CS		;Copia cores para buffer temporario
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET CORST
	MOV	DI,OFFSET PROGRAM
	MOV	CX,OFFSET COREN - OFFSET CORST
	CLD
	REP	MOVSB
	MOV	SI,OFFSET CORST
	MOV	DI,OFFSET PARAMTR
	MOV	CX,OFFSET COREN - OFFSET CORST
	CLD
	REP	MOVSB

	LCCSI:
	MOV	AL,1		;Apenas mostrar menu
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET CCINF
	CALL	MOPC

	MOV	AX,OPYI
	MOV	BX,OPXI
	
	CALL	CHIDE
	ADD	AX,52		;Coloca todas as cores na janela
	ADD	BX,20
	MOV	DX,10
	MOV	CX,20
	PUSH	CS
	POP	DS
	MOV	DI,OFFSET PROGRAM
	
	;LOOP
	LCCSI0:
	MOVZX	SI,BYTE PTR DS:[DI]
	INC	DI
	DEC	DX
	CALL	RECF
	INC	DX
	XOR	SI,SI
	CALL	RECT
	ADD	AX,15d
	CMP	DI,OFFSET PROGRAM + 18
	JNAE	LCCSI0
	;END
	
	CALL	CSHOW
	JCCSI0:
	MOV	AL,2		;Inicia interacao
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET CCINF
	CALL	MOPC
	
	CMP	AL,'R'		;Mudar numero da cor para ajuste RGB
	JNZ	JCCSI2B
	CALL	AUSB		;Aguarda usuario liberar mouse
	CALL	LTR1		;Le posicoes do mouse
	MOV	AX,DX
	MOV	BX,CX
	CALL	CHNC		;Apresenta menu de cores
	CMP	AL,1
	JZ	LCCSI		;Cancel, retorna
	MOV	BYTE PTR CS:[OFFSET NCORR],CL	;No.COR
	MOV	AL,3d		;Le valore RGB do buffer RGBVAL e copia 
	MUL	CL		;para VRED, VGRE e VBLU.
	ADD	AX,OFFSET RGBVAL
	MOV	BX,AX
	MOV	WORD PTR CS:[OFFSET VRED],BX
	INC	BX
	MOV	WORD PTR CS:[OFFSET VGRE],BX
	INC	BX
	MOV	WORD PTR CS:[OFFSET VBLU],BX
	CALL	AUSB		;Aguarda usuario liberar mouse
	JMP	LCCSI		;Refresh MOPC	
	
	JCCSI2B:
	CMP	AL,1		;OK
	JNZ	JCCSI2
	PUSH	CS		;Copia cores para memoria
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET PROGRAM
	MOV	DI,OFFSET CORST
	MOV	CX,18
	CLD
	REP	MOVSB
	CALL	MAXL
	JMP	JCCSIF		;Finaliza
	
	JCCSI2:
	CMP	AL,2
	JNZ	JCCSI3		;Restaura cores iniciais
	PUSH	CS		;Copia cores para memoria
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET PARAMTR
	MOV	DI,OFFSET CORST
	MOV	CX,OFFSET COREN - OFFSET CORST
	CLD
	REP	MOVSB
	CALL	MAXL
	JMP	JCCSIF		;Finaliza
	
	JCCSI3:
	CMP	AL,4		;F5 - Refresh
	JNZ	JCCSI1
	
	PUSH	CS		;Copia cores para memoria
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET PROGRAM
	MOV	DI,OFFSET CORST
	MOV	CX,18
	CLD
	REP	MOVSB
	
	CALL	PUSHAI
	CALL	MAXL
	CALL	POPAE
	DEC	AEX
	MOV	DMAL,1
	CALL	REWRITE
	CALL	POPAI
	CALL	AUSB
	JMP	LCCSI		;Retorna ao loop	
	
	JCCSI1:
	CMP	AL,5		;CORES PADRAO DO SISTEMA
	JNZ	JCCSI4
	
	PUSH	CS		;Copia cores para memoria
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET CPSM
	MOV	DI,OFFSET PROGRAM
	MOV	CX,OFFSET COREN - OFFSET CORST
	CLD
	REP	MOVSB
	MOV	SI,OFFSET RGBSTD;Restaura a palette
	MOV	DI,OFFSET RGBVAL
	MOV	CX,16*3
	REP	MOVSB
	MOV	SI,OFFSET RGBSTD;Restaura a palette
	CALL	SYSPLT
	CALL	AUSB
	JMP	LCCSI		;Retorna ao loop	
	
	JCCSI4:
	CMP	AL,8		;Click em uma cor
	JNZ	JCCSI0		;Negativo, pula
	CALL	LTR1		;Le posicao do mouse
	MOV	AX,OPYI
	ADD	AX,52d
	
	SUB	DX,AX		;Calcula posicao clicada
	MOV	CL,15d
	MOV	AX,DX

	DIV	CL
	
	CALL	AUSB
	XOR	AH,AH		;Exibe menu para escolha de outra cor
	PUSH	AX
	CALL	LTR1
	MOV	AX,DX
	MOV	BX,CX
	CALL	CHNC
	POP	BX		;Grava cor escolhida na memoria
	OR	AL,AL		;Cancelado, retorna ao LOOP sem gravar
	JNZ	LCCSI
	MOV	BYTE PTR CS:[OFFSET PROGRAM+BX],CL
	MOV	BYTE PTR CS:[OFFSET NCORR],CL
	MOV	AL,3d		;Le valore RGB do buffer RGBVAL e copia 
	MUL	CL		;para VRED, VGRE e VBLU.
	ADD	AX,OFFSET RGBVAL
	MOV	BX,AX
	MOV	WORD PTR CS:[OFFSET VRED],BX
	INC	BX
	MOV	WORD PTR CS:[OFFSET VGRE],BX
	INC	BX
	MOV	WORD PTR CS:[OFFSET VBLU],BX
	JMP	LCCSI
		
	JCCSIF:
	CALL	REWRITE 	;******** DMAL / WINM
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET RGBVAL
	CALL	SYSPLT		;Atualiza palette
	POP	ES
	POP	DS
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao CHNI
;Acesso: CALL CHNI / EXTERNO
;
;Escolhe uma nova icone para a funcao "INSERIR ICONE NA JANELA ATUAL"
;
;Entra: NADA
;Retorna: Alteracoes no buffer ICOB

;
WCTS:	DB '*.ICO',0
IPATH:	DB 70 dup (0)
LPDT	DD	0

CHNI:	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	DWORD PTR CS:[OFFSET IPATH],'CI.*'	;Grava *.ICO
	MOV	WORD PTR CS:[OFFSET IPATH+4],0+'O'
	MOV	LPDT,0
	
	JCHNI0:
	CALL	MAXL		;Afirmativo, exibe janela de browse
	CALL	AUSB

	CALL	CHIDE
	MOV	AX,0FFFFh
	MOV	BX,AX

	MOV	DX,222
	MOV	CX,220
	CALL	NCMS
	CALL	CSHOW

	MOV	CX,BX
	MOV	DX,AX
	ADD	CX,30d
	ADD	DX,10d
	
	MOV	EBP,LPDT
	XOR	AX,AX
	INC	AL
	MOV	BH,11111111b	;Nao permitir acesso a diskete nem cdrom
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET IPATH 
	CALL	BROWSE
	MOV	LPDT,EBP
	
	TEST	AL,11110000b
	JNZ	JCHNI1		;Saiu com cancel, pula.
	
	PUSH	SI
	CLD			;Copia path
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET IPATH
	;LOOP
	LCHNI0:
	LODSB
	STOSB
	OR	AL,AL
	JNZ	LCHNI0
	;END
	
	STD
	MOV	AL,'\'		;Escreve "*.ICO" no lugar do nome do arquivo
	MOV	CX,0FFFFh
	REPNZ	SCASB
	MOV	DWORD PTR CS:[DI+2],'CI.*'	;Grava *.ICO
	MOV	WORD PTR CS:[DI+6],0+'O'
	
	POP	SI
	
	PUSH	AIX
	PUSH	AIXX
	PUSH	AIY
	PUSH	AIYY
	
	PUSH	CS
	POP	DS
	MOV	DX,SI
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET RBDT
	CALL	ICONE
	
	POP	AIYY
	POP	AIY
	POP	AIXX
	POP	AIX

	OR	AL,AL		;Cancel ou erro, retorna 
	JNZ	JCHNI0
	
	PUSH	CS		;Copia a icone para CS:bICOB 
	POP	DS
	MOV	SI,OFFSET RBDT
	MOV	DI,OFFSET BICOB
	MOV	CX,1024d
	CLD
	REP	MOVSB
	
	JCHNI1:
	POP	ES		;Finaliza e retorna
	POP	DS
	POPA
	RET
-------------------------------------------------------------
;Nanosistemas. Funcao ICONE
;Acesso: CALL ICONE / EXTERNO
;
;Exibe as icones contidas em um ICON DIRECTORY FILE e permite que
;o usuario escolha uma.
;
;Entra: DS:DX	: Endereco do nome ASCIIZ do arquivo de icones
;	ES:DI	: Endereco do buffer de 1024 bytes para colocar a icone escolhida
;Retorna:
;	AL	: 0 = Ok. Icone lida com sucesso
;	AL	: 1 = Erro. Nao foi possivel abrir o arquivo
;	AL	: 2 = Erro. Arquivo invalido
;	AL	: 3 = Erro. Icone escolhida nao existe no arquivo
;	AL	: 4 = Erro. Icone escolhida possui especificacoes nao suportadas pelo sistema
;	AL	: 5 = Cancelado pelo usuario (buffer ES:DI nao foi alterado)
;	ES:DI	: Endereco do buffer de 1024 bytes preenchido com a icone escolhida
;
;	Sempre retorna uma area de inclusao ajustada para que o menu
;	possa ser retirado atraves de uma chamada CALL REWRITE.
;
;	A icone retornada no buffer ES:DI deve ser exibida usando a funcao
;	CRSMAP, para que os pixels transparentes nao sejam apresentados.
;
;	Em caso de CANCEL pelo usuario, o buffer ES:DI sera retornado
;	conforme veio, sem altracoes.
;
;	Se o usuario escolher uma icone que possua especificacoes nao suportadas,
;	(icone apresentada em transparente no menu), a funcao ICONE retornara'
;	AL=4 e o buffer ES:DI sem alteracoes.
;

ITOTI	DW	0		;Total de icones no arquivo
ICTOP	DW	0		;Icone no topo
IRESP	DB	0		;AL/saida.
ICJPX	DW	0		;Posicao X da janela
ICJPY	DW	0		;Posicao Y da janela
ICSEL	DB	0		;Numero da icone selecionada
ICEES	DW	0		;ES inicial
ICEDI	DW	0		;DI inicial
ICEDS	DW	0		;DS inicial
ICEDX	DW	0		;DX inicial

ICDPX	DW	0
ICDPY	DW	0
ICNDS	DW	0
ICCNT	DB	0		;Contador (temp)

ICONE:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CALL	CHIDE
	
	MOV	ICEES,ES	;Grava parametros
	MOV	ICEDI,DI
	MOV	ICEDS,DS	
	MOV	ICEDX,DX
	
	MOV	CX,0		;Le primeira icone e captura informacoes sobre
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET RBDT
	CALL	ICDIR
	
	MOV	IRESP,AL
	OR	AL,AL		;Erro, pula e finaliza
	JNZ	ICONEF
	
	MOV	ITOTI,CX	;Total de icones no arquivo
	MOV	ICTOP,0 	;Icone no topo=0
	MOV	ICSEL,0 	;Icone selecionada=0 (primeira)
	
	;Inicia desenho da janela
	MOV	AX,0FFFFh
	MOV	BX,0FFFFh
	MOV	CX,150d
	MOV	DX,200d
	CALL	NCMS
	MOV	ICJPX,BX
	MOV	ICJPY,AX
	
	ADD	AX,10		;Desenha icones da esquerda
	ADD	BX,10
	MOV	DI,WORD PTR CS:[OFFSET TBCR]
	MOV	CX,16
	MOV	DX,119
	MOV	SI,OFFSET SCIA
	CALL	BINMAP
	
	ADD	BX,18d		;Desenha retangulo no interior
	INC	AX
	MOV	CX,100d
	MOV	DX,181d
	MOVZX	SI,BORD
	CALL	RECT
	CALL	CSHOW
	
	;Desenha icones dentro do menu
	LICN1:
	CALL	CHIDE
	MOV	AX,ICJPY	;Apaga icones que ja estejam no menu
	MOV	BX,ICJPX
	ADD	AX,11d
	ADD	BX,29d
	MOV	CX,98d
	MOV	DX,178d
	MOVZX	SI,TBCR
	CALL	RECF
	
	LICN4:
	CALL	CHIDE
	MOV	AX,ICJPY	;Apaga icones que ja estejam no menu
	MOV	BX,ICJPX
	ADD	AX,11d
	ADD	BX,29d
	ADD	AX,4		;Prepara para comecar a desenha as icones		
	ADD	BX,4
	MOV	CX,ICTOP
	MOV	ICNDS,CX
	MOV	ICDPX,BX
	MOV	ICDPY,AX
	
	;LOOP0
	LICN0:	
	
	MOV	ICCNT,2
	MOV	BX,ICDPX
	;LOOP1
	LICN2:
	MOV	CX,ICNDS
	MOV	DS,ICEDS
	MOV	DX,ICEDX	;Le uma icone
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET RBDT
	PUSHA			;Limpa buffer
	CLD
	MOV	CX,1024d
	MOV	AL,0FFh
	REP	STOSB
	POPA
	CALL	ICDIR		;Le a icone
	
	OR	AL,AL		;Verifica se houve erro
	JNZ	JICN0		;Afirmativo, pula
	
	MOV	CX,ICNDS
	CMP	ICSEL,CL	;Verifica se esta icone e' a selecionada
	JNZ	JICN5		;Negativo, pula
	
	MOV	AX,ICDPY	;Seleciona icone
	MOV	BX,ICDPX	;(traca um retangulo em volta)
	SUB	AX,2
	SUB	BX,2
	MOV	CX,36d
	MOV	DX,37d
	MOVZX	SI,BORD
	CALL	RECT
	
	JICN5:
	MOV	CX,32		;Desenha uma icone
	MOV	DX,32
	MOV	AX,ICDPY
	MOV	BX,ICDPX
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET RBDT
	CALL	CRSMAP
	
	INC	ICNDS		;Marca: Proxima icone
	ADD	BX,37d
	DEC	ICCNT
	JNZ	LICN2		;Retorna ao loop para tracar a icone da direita
	;END1

	ADD	ICDPY,37d	;Proxima linha
	JMP	LICN0		;Retorna ao loop
	;END0
	
	JICN0:
	CALL	AUSB		;Aguarda usuario liberar mouse
	CALL	CSHOW		;Exibe o cursor
	;Aguarda click do mouse
	;LOOP0
	LICN3:
	CALL	MOUSE
	CMP	AX,1C0Dh	;ENTER : Escolhe
	JZ	JICN6
	CMP	AX,011Bh	;ESC : Cancela
	JZ	JICN7
	TEST	BX,11b
	JZ	LICN3		;Nao houve click, retorna
	;END0
	
	MOV	AX,ICJPY	;Verifica se foi clidado nas icones
	MOV	BX,ICJPX	;Pula sempre que negativo
	ADD	AX,11d
	ADD	BX,28d
	CMP	CX,BX
	JNA	JICN1
	CMP	DX,AX
	JNA	JICN1
	ADD	AX,178d
	ADD	BX,98d
	CMP	CX,BX
	JA	JICN1
	CMP	DX,AX
	JZ	JICN1

	
	;Passando daqui, entao foi clicado na area das icones
	;Calcula numero da icone clicada
	;CX e DX contem posicoes X e Y do click
	
	SUB	CX,ICJPX
	SUB	DX,ICJPY
	SUB	CX,28d
	SUB	DX,10d		;Em CX e DX o deslocamento X e Y
	
	MOV	AX,50d
	XCHG	AX,CX
	DIV	CL		
	MOV	BH,AL		;Em BH o numero da coluna clicada (0=prim)
	
	MOV	CL,37d
	MOV	AX,DX
	DIV	CL		
	MOV	BL,AL		;Em BL o numero da linha clicada (0=prim) 
	
	SHL	BL,1
	ADD	BL,BH		;Em BL o numero da icone clicada (0=prim)
	MOV	ICSEL,BL	;Em ICSEL o numero da icone clicada (0=prim)

	TEST	MOBX,100b	;Verifica se houve doubleclick
	JNZ	JICN6		;Afirmativo, pula
	
	JMP	LICN4		;Retorna ao LOOP
	
	;Subrotina: Processa clicks nas icones da direita
	JICN1:
	MOV	AX,ICJPY	;Verifica se foi clidado nas icones da esquerda
	MOV	BX,ICJPX	;Pula sempre que negativo
	ADD	AX,10d
	ADD	BX,10d
	CMP	CX,BX
	JNA	JICN7
	CMP	DX,AX
	JNA	JICN7
	ADD	BX,16d
	ADD	AX,119d
	CMP	DX,AX
	JA	JICN7
	CMP	CX,BX
	JA	JICN7
	
	;Chegando aqui, entao foi clicado em uma das icones da esquerda
	
	SUB	DX,ICJPY
	SUB	DX,10d
	MOV	AX,DX
	MOV	CL,15d
	DIV	CL		;Em AL o numero da icone clicada

;ITOTI	DW	0		;Total de icones no arquivo
;ICTOP	DW	0		;Icone no topo

	CMP	AL,0		;ONE UP 	
	JNZ	JIC00
	CMP	ICTOP,0
	JZ	JIC00
	DEC	ICTOP
	
	JIC00:
	CMP	AL,1		;ONE DOWN
	JNZ	JIC01
	MOV	BX,ITOTI
	SHR	BX,1
	CMP	ICTOP,BX
	JZ	JIC01
	INC	ICTOP
	
	JIC01:
	CMP	AL,6		;ENTER
	JZ	JICN6
	
	CMP	AL,7		;CANCEL
	JZ	JICN7
	
	JMP	LICN4		;Retorna ao LOOP
	
	
	;Subrotina: Processa confirmacao da icone escolhida.
	;ICSEL -> Numero da icone escolhida
	;
	JICN6:
	MOVZX	CX,ICSEL
	CMP	CX,ITOTI	;Verifica se escolheu icone que nao existe
	JA	LICN3		;(clicou em um espaco branco). Afirm, retorna ao LOOP
	MOV	ES,ICEES
	MOV	DI,ICEDI
	MOV	DS,ICEDS
	MOV	DX,ICEDX	

	CALL	ICDIR		;Le a icone escolhida
	
	MOV	IRESP,0 	;Marca saida: OK. 
	JMP	ICONEF		;Finaliza
	
	;Subrotina: Processa cancel
	JICN7:
	MOV	IRESP,5 	;Marca saida: CANCEL.
	JMP	ICONEF		;Finaliza
	
	ICONEF:
	POP	ES		;Finaliza
	POP	DS
	POPA
	MOV	AL,IRESP	;Resposta em AL
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao ICONDIR
;Acesso: CALL ICDIR / EXTERNO
;
;Le uma icone selecionada de um arquivo de icones (IconDirectory)
;
;Entra: CX	: Numero da icone escolhida (0=Primeira)
;	DS:DX	: Endereco do nome ASCIIZ do arquivo de icones
;	ES:DI	: Buffer para colocar a icone
;
;Retorna:
;	AL	: 0 = Ok. Icone lida com sucesso
;	AL	: 1 = Erro. Nao foi possivel abrir o arquivo
;	AL	: 2 = Erro. Arquivo invalido
;	AL	: 3 = Erro. Icone escolhida nao existe no arquivo
;	AL	: 4 = Erro. Icone escolhida possui especificacoes nao suportadas pelo sistema
;	CX	: Numero de icones encontradas no arquivo
;	ES:DI	: Buffer preenchido com a imagem (Use CRSMAP para exibir)
;
;
IDCX	DW	0	;CX inicial
IDDS	DW	0	;DS inicial
IDDX	DW	0	;DX inicial
IDES	DW	0	;ES inicial
IDDI	DW	0	;DI inicial
IDEX	DB	0	;AL na saida
IDHN	DW	0	;Manipulador do arquivo

;Defin. ICONDIR
ICONDIR:
IDRES	DW	0	;Reservado. Deve ser ZERO
IDTYP	DW	0	;Formato do arquivo. Deve ser 1
IDCOU	DW	0	;Numero de icones no arquivo

;Defin. ICONDIRECTORYENTRY
IDIRE:
BWIDTH	DB	0	;Tamanho X.Largura em pixels: 16,32,64
BHEIGH	DB	0	;Tamanho Y.Altura em pixels: 16,32,64
BCOLOR	DB	0	;Numero de cores: 2,8,16
BRESER	DB	0	;Reservado: 0
WPLANE	DW	0	;Numero de planos
WBITCO	DW	0	;Numero de bits no Icon Bitmap
DBYTES	DD	0	;Tamanho em bytes do Icon_Image
DIMAGE	DD	0	;Offset (em bytes) do Icon Image em relacao ao inicio do arquivo

;Defin. ICON IMAGE
;Em CS:RBDT

;Offset do ICONDIRENTRY da icone escolhida:
;Eq: Retorna OFFSET em relacao ao inicio do arquivo:
;OFFSET:=6+(16*IDCX)

;Offset do inicio dos XOR bytes:
;Eq: Retorna OFFSET em relacao ao inicio do arquivo:
;OFFSET:=DIMAGE+(40d+BCOLOR*4)
;Estes bytes podem ser apresentados usando a funcao BITMAP do Nanosistemas.


ICDIR:	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	IDCX,CX 	;Grava valores iniciais
	MOV	IDDS,DS
	MOV	IDDX,DX
	MOV	IDES,ES

	MOV	IDDI,DI
	
	MOV	IDEX,1		;Marca ARQUIVO NAO ENCONTRADO
	MOV	AX,3D00h	;Abre arquivo
	INT	21h
	JC	JICDF		;Erro, finaliza
	MOV	BX,AX
	MOV	IDHN,BX 	;Em IDHN, o manipulador
	
	MOV	AH,3Fh		;Le header
	MOV	CX,6
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET ICONDIR
	INT	21h

	MOV	IDEX,2		;Marca ARQUIVO INVALIDO
	CMP	IDRES,0
	JNZ	JICDC		;Pula se o arquivo for invalido
	CMP	IDTYP,1
	JNZ	JICDC		;Pula se o arquivo for invalido
	
	MOV	IDEX,3		;Marca ICONE ESCOLHIDA NAO EXISTE
	MOV	CX,IDCX 	;Verifica se usuario pediu uma icone que existe
	INC	CX
	CMP	CX,IDCOU
	JA	JICDC		;Negativo, pula e finaliza com erro
	
	MOV	IDEX,4		;Marca ICONE ESCOLHIDA POSSUI SPECS INVALIDAS
	
	MOV	AX,16d		;Coloca em CX:DX o offset do ICONDIRENTRY da 
	MOV	CX,IDCX 	;icone escolhida pelo usuario.
	MUL	CX		;Solv.EQ: CX:DX=6+16*IDCX
	ADD	AX,6
	JNC	$+3
	INC	DX
	MOV	CX,DX
	MOV	DX,AX
	
	MOV	AX,4200h	;Encontra ICONDIRENTRY da icone escolhida
	INT	21h
	
	MOV	AH,3Fh		;Le ICONDIRENTRY da icone escolhida
	MOV	CX,16d
	MOV	DX,OFFSET IDIRE
	INT	21h
	
	MOV	AX,4200h	;Posiciona arquivo para ler Icon_Image
	PUSH	DIMAGE		
	POP	DX
	POP	CX
	INT	21h
	
	MOV	AH,3Fh		;Le Icon_Image para CS:RBDT
	MOV	ECX,DBYTES
	MOV	DX,OFFSET MVIB
	INT	21h
	
	MOVZX	CX,BCOLOR	;Calcula posicao da imagem (XOR mask)
	SHL	CX,2		;Assumindo BCOLOR=Numero real de BITSpPIXEL
	ADD	CX,40d
	MOV	DX,CX
	MOV	SI,OFFSET MVIB
	ADD	SI,CX		;Em SI o offset do inicio da imagem (XOR mask)
	MOV	TMP2,SI
	
	MOV	CX,WORD PTR CS:[OFFSET MVIB+14d]
	
	CMP	CX,4		;Verifica 4 bits por pixel
	JNZ	JICN4		;Negativo, pula 
	
	;---------------------------------------
	MOV	ECX,DBYTES	;Em CX o numero de bytes a copiar da imagem
	SUB	CX,DX

	ADD	SI,496d 	;Prepara para ler de traz pra frente
	
	MOV	BX,OFFSET MVIB	;Prepara para converter cores
	ADD	BX,40d		;BX: Offset do inicio do RGB_squad
	
	;Processa imagem 4 bits por pixel
	;ES:DI ja ajustado para o buffer
	;DS:SI ja ajustado para o inicio da imagem
	CLD
	MOV	DX,1010h	;Tamanho X de cada icone (DH e DL)
	
	;---- LOOP0 ----	
	LIC40:
	CALL	SECR
	LODSB			;Le um byte
	
	MOV	AH,AL		;AX contem os 2 pixels lidos		
	AND	AH,00001111b	;Como a icone e' de 4 bits por pixel,
	SHR	AL,4		;cada byte contem 2 pixels.

	PUSH	BX
	PUSH	CX
	PUSH	DI
	
	;-------------------------------------
	MOV	DI,SI		;Verifica se deve exibir os pixels
	DEC	DI	
	SUB	DI,OFFSET MVIB+104d	;DI: Numero de bytes entre OF.MVIB e SI
	SHL	DI,1			;DI: Numero de pixels entre OF.MVIB e SI 

	MOV	CX,DI

	AND	CL,111b 		;Em CL o numero do BIT (dentro do byte em DI)
	SHR	DI,3			;Em DI o numero do BYTE
	ADD	DI,OFFSET MVIB+616d	;Em DI o offset (em CS) do BYTE
	MOV	BX,7
	SUB	BX,CX
	MOV	CX,BX			;Em CX o numero do BIT (invertido)
	MOVZX	BX,BYTE PTR CS:[DI]	;Em BX (BL), a word (BYTE)
		  
	BT	BX,CX			;Verifica se ha o pixel 1
	JNC	JIC400
	OR	AX,0000000011111111b	;Negativo, marca transparente
	JIC400:

	DEC	CX			;Verifica se ha o pixel 2
	BT	BX,CX
	JNC	JIC401
	OR	AX,1111111100000000b	;Negativo, marca transparente
	JIC401:
	;-------------------------------------
	
	POP	DI
	POP	CX
	POP	BX

	DEC	DL		;Verifica se terminou uma linha (Escreve desinvertendo icone)
	JNZ	JIC40		;Negativo, pula
	MOV	DL,DH		;Afirmativo, pula para a linha de cima
	SUB	SI,32d		;E continua a execucao
	
	JIC40:

	;Em AL o byte solicitado
	CALL	AJAL
	STOSB
	
	JIC41:

	;Em AH o byte solicitado
	MOV	AL,AH
	;Em AL o byte ajustado	
	CALL	AJAL
	STOSB
	
	DEC	CX
	JNZ	LIC40		;Retorna ao loop, se nao terminou
	;---- END0 ---- 

	MOV	IDEX,0		;Marca CONCLUIDO COM SUCESSO
	;---------------------------------------
	JICN4:
	
	JICDC:
	MOV	AH,3Eh		;Fecha arquivo
	MOV	BX,IDHN
	INT	21h
	
	JICDF:
	POP	ES		;Finaliza
	POP	DS
	POPA
	MOV	AL,IDEX 	;Em AL codigo de erro
	MOV	CX,IDCOU	;Em CX o numero de icones no arquivo
	RET

;Subrotina: Ajusta AL de acordo com a tabela abaixo:
;
;AL IN : 0 1 2 3 4 5 6 7 8 9  10 11 12 13 14 .. acima de 14 nao muda
;AL OUT: 0 4 2 6 1 5 3 8 7 12 13 14  9 10 11 .. acima de 14 nao muda

;Translate Table
TTBL:	DB	0,4,2,6,1,5,3,8,7,12,13,14,9,10,11

AJAL:	PUSH	DS
	CMP	AL,14
	JA	JAJALF
	PUSH	CS
	POP	DS
	MOV	BX,OFFSET TTBL
	XLATB
	JAJALF:
	POP	DS
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao CLOSER
;Acesso: CALL CLOSER / EXTERNO
;
;Verifica qual cor (na placa de video) mais se aproxima
;em RGB da cor dada.
;
;Entra: CL	: Red
;	CH	: Green
;	DL	: Blue
;	DH	: Numero de cores a testar (partindo da primeira)
;
;Retorna:
;	CL	: Numero da cor que mais se aproxima
;	DX	: Similaridade (0=Cor identica. 765d=Totalmente diferente)
;
;OBS:	Esta rotina le os valores RGB (para comparar) direto da placa de video 
;	(Portas 3C7h e 3C9h)
;
CRED	DB	0	;RED   (CL)
CGRE	DB	0	;GREEN (CH)
CBLU	DB	0	;BLUE  (DL)
CCPT	DB	0	;Numero de cores para testar (DH)

CCOR	DB	0	;Cor mais proxima encontrada ate agora
CCFC	DW	0	;Menor diferenca media ate agora

CT10	DD	0	;Ultima entrada
CO10	DB	0	;Ultimo resultado
CF10	DW	0	;Ultima similaridade

CLOSER: PUSHA
	PUSH	DS
	PUSH	ES
		
	MOV	CRED,CL ;Grava valores iniciais
	MOV	CGRE,CH
	MOV	CBLU,DL
	MOV	CCPT,DH
	MOV	CCFC,0FFFFh
	
	PUSH	CX	;Verifica se o caller esta solicitando busca que
	PUSH	DX	;ja foi feita antes.
	POP	EAX
	
	CMP	EAX,CT10
	JNZ	JCLO1	;Negativo, pula
	
	MOV	CL,CO10 ;Afirmativo, ajusta saida
	MOV	CCOR,CL
	MOV	DX,CF10
	MOV	CCFC,DX
	JMP	JCLOF	;Finaliza
	
	JCLO1:
	MOV	CT10,EAX;Grava solicitacao
	
	MOV	DX,3C7h ;Ajusta para cor 0
	XOR	AL,AL
	OUT	DX,AL
	
	XOR	AH,AH	;AH: Cor atualmente em teste	

	MOV	DX,3C9h ;DX: 3C9h sempre	

	
	;---- LOOP0 ---- 
	LCLO0:
	XOR	CX,CX
	
	IN	AL,DX	;Poe em CL a diferenca (em modulo) da cor
	MOV	CL,AL
	SUB	CL,CRED
	JA	$+4
	NEG	CL

	XOR	BX,BX
	
	IN	AL,DX	;Poe em BL a diferenca (em modulo) da cor
	MOV	BL,AL
	SUB	BL,CGRE
	JA	$+4
	NEG	BL
	


	ADD	CX,BX	
	
	IN	AL,DX	;Poe em BL a diferenca (em modulo) da cor
	MOV	BL,AL
	SUB	BL,CBLU
	JA	$+4
	NEG	BL
	
	ADD	CX,BX	;Em CX a rasao de diferenca
	
	CMP	CX,CCFC ;Verifica se esta rasao e' menor que a anterior
	JA	JCLO0	;Negativo, pula
	MOV	CCFC,CX ;Afirmativo, grava esta rasao como sendo a menor
	MOV	CCOR,AH ;Grava a cor que ate agora mais se aproxima
	JCLO0:
	
	INC	AH	;Proxima cor
	DEC	CCPT	;Verifica se terminou
	JNZ	LCLO0	;Negativo, retorna ao LOOP	
	;---- END0 ---- 
	
	MOV	CL,CCOR ;Ajusta LastResult
	MOV	CO10,CL
	MOV	DX,CCFC
	MOV	CF10,DX
	
	JCLOF:
	POP	ES	;Finaliza
	POP	DS
	POPA
	
	MOV	CL,CCOR ;Em CL a cor que mais se aproxima
	MOV	DX,CCFC ;Em DX a similaridade
	
	RET

-------------------------------------------------------------
;Nanosistemas. Funcao MACW
;Acesso: CALL MACW / EXTERNO
;
;Desenha uma janela na tela de video grafica
;Entra:
;AX	: Pos: Y
;BX	: Pos: X
;CX	: Size Y
;DX	: Size X
;SI	: Offset do nome do arquivo de dados (MMW) sem extensao, 
;	  e de no maximo 8 caracteres (ASCIIZ)
;CS:WINM: 0 -> Apenas exiba normalmente, 
;	  1 -> Click em uma icone
;	  2 -> Apenas atualize as icones (nao verifique mouse)
;	  3 -> Mostre a janela normalmente, sem atualizar arquivo MMW
;Retorna:
;
;Apos chamada esta funcao com CS:WINM=0 ou 1, voce obtem:
;ICWA	 DW	 0		 ;Numero de icones na ultima janela selecionada
;ICWN	 DW	 0		 ;Numero de icones lidas (Que deve ser igual a ICWA)
;ICWX	 DW	 0		 ;Pos X da proxima icone. 
;ICWY	 DW	 0		 ;Pos Y da proxima icone.
;ICLC	 DW	 0		 ;Numero da icone selecionada
;ICSP	(WORD : Numero do Scroll Down. 
;		Isto e': Quantas linhas de icones esta para baixo
;		-> As ICSP primeiras linhas de icones NAO vao aparecer na janela
;		   devido ao Scroll Down executado pelo usuario
;

;E apos chamada com qualquer CS:WINM, voce possui:
;ICSL	 DB	 0		 ;Ha icone marcada (visualmente selecionada)? 
;				 ;0=Nao, 1=SIM
;
;E para referencia geral, as duas constantes existem:
;ICSX	 EQU	 60d		 ;Tamanho X de cada icone, incluindo texto
;ICSY	 EQU	 76d		 ;Tamanho Y de cada icone, incluindo texto
;				 ;OBS: Tamanhos X e Y sao usados pela rotina acima
;				 ;para determinar a distancia entre cada icone e
;				 ;quando uma icone deve ser desenhada na linha de baixo.
;
;Logo apos terminada a funcao, voce possui dos contadores de saida:
;CATE	 (WORD) : Numero de icones lidas do arquivo (total de icones no arquivo)
;CATS	 (WORD) : Numero de linhas (linhas de icones) na janela desenhada.
;CBTS	 (BYTE) : Numero de colunas (colunas de icones) na janela desenhada.
;
;Atencao: CATE, CATS e CBTS sao contadores gerais de entrada e saida de todo o sistema.
;	  Todas as funcoes usam eles sem restricoes. Voce deve le-los imediatamente
;	  apos a chamada a rotina MACW, ou os valores poderao ser alterados.
;	  E atencao para CBTS, que e' um BYTE. CATE e CATS sao WORDS.
;
;Alteracoes na memoria de video.
;Flags e registradores de segmento (DS e ES) sao destruidos
;
;OBS: * A janela que esta funcao se refere e' a janela padrao do
;	Nanosistemas, que de acordo com CS:WINM, inclui as icones, 
;	as bordas, barra de titulo , etc. 
;     * Para apenas atualizar a janela (ou desenha-la pela primeira vez),
;	o usuario deve chamar a funcao com CS:WINM=0.
;	As posicoes em AX,BX,CX e DX serao gravadas dentro no arquivo MMW
;	indicado por SI na entrada.
;     * A velocidade do doubleclick e' definida pela constante DCLS.
;     * Para ocultar (fechar) a janela , entre esta funcao
;	com CX=0 que a funcao nao ira exibir a janela.
;	Para recolocar esta janela no desktop com as posicoes anteriores,
;	entre esta funcao com CX>0. (OBS: Quando entra com CX=0, a funcao
;	nao altera o arquivo MMW. Apenas ENTRA,verifiqua que CX=0, e sai)
;     * Sempre que chamada MACW com CS:WINM<>3, o arquivo MMW sera alterado
;	e la sera gravado as novas posicoes (AX,BX,CX e DX).
;     * A checksum do arquivo MMW e' automaticamente atualizada apos qualquer alteracao nesses
;	arquivos ,des de que esta alteracao tenha sido feita pelo sistema (Nanosistemas).

ICNA:	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,00,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,00,07,00,07,07,07,07,07,07
	DB	07,07,07,07,07,00,07,15,07,00,07,07,07,07,07
	DB	07,07,07,07,00,07,15,07,15,07,00,07,07,07,07
	DB	07,07,07,00,07,15,07,15,07,15,07,00,07,07,07
	DB	07,07,00,07,15,07,15,07,15,07,15,07,00,07,07
	DB	07,00,00,00,00,00,07,15,07,00,00,00,00,00,07
	DB	07,07,07,07,07,00,15,07,15,00,07,07,07,07,07
	DB	07,07,07,07,07,00,07,15,07,00,07,07,07,07,07
	DB	07,07,07,07,07,00,15,07,15,00,07,07,07,07,07
	DB	07,07,07,07,07,00,07,15,07,00,07,07,07,07,07
	DB	07,07,07,07,07,00,00,00,00,00,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
ICNB:	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,00,00,00,00,00,07,07,07,07,07
	DB	07,07,07,07,07,00,15,07,15,00,07,07,07,07,07
	DB	07,07,07,07,07,00,07,15,07,00,07,07,07,07,07

	DB	07,07,07,07,07,00,15,07,15,00,07,07,07,07,07
	DB	07,07,07,07,07,00,07,15,07,00,07,07,07,07,07
	DB	07,07,07,07,07,00,15,07,15,00,07,07,07,07,07
	DB	07,00,00,00,00,00,07,15,07,00,00,00,00,00,07
	DB	07,07,00,07,15,07,15,07,15,07,15,07,00,07,07
	DB	07,07,07,00,07,15,07,15,07,15,07,00,07,07,07
	DB	07,07,07,07,00,07,15,07,15,07,00,07,07,07,07
	DB	07,07,07,07,07,00,07,15,07,00,07,07,07,07,07
	DB	07,07,07,07,07,07,00,07,00,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,00,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	
ICNC:	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,0FFH
	DB	00,15,15,15,15,15,15,15,15,15,15,15,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,07,07,00,00,00,00,00,07,07,08,00,0FFH
	DB	00,15,07,07,07,00,00,00,07,07,07,08,00,0FFH
	DB	00,15,07,07,07,07,00,07,07,07,07,08,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,08,08,08,08,08,08,08,08,08,08,00,0FFH
	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,0FFH
	
ICNC1:	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,0FFH
	DB	00,15,15,15,15,15,15,15,15,15,15,15,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,07,07,00,00,00,00,15,07,07,08,00,0FFH
	DB	00,15,07,07,00,08,08,08,15,07,07,08,00,0FFH
	DB	00,15,07,07,15,15,15,15,15,07,07,08,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,07,07,07,07,07,07,07,07,07,08,00,0FFH
	DB	00,15,08,08,08,08,08,08,08,08,08,08,00,0FFH
	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,0FFH
	
ICND:	DB	0,0,0,0,0,0,0,0,0,0,0
	DB	0,15,15,15,15,15,15,15,15,15,15
	DB	0,15,7,7,7,8,7,7,7,0,15
	DB	0,15,7,7,7,8,7,7,7,0,15
	DB	0,15,7,7,7,8,7,7,7,0,15
	DB	0,15,8,8,8,8,7,7,7,0,15
	DB	0,15,7,7,7,7,7,7,7,0,15
	DB	0,15,7,7,7,7,7,7,7,0,15
	DB	0,15,7,7,7,7,7,7,7,0,15
	DB	0,15,0,0,0,0,0,0,0,0,15
	DB	0,15,15,15,15,15,15,15,15,15,15
ICNE:	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,00,00,00,00,00,00,07,07,07,07,07,07,07
	DB	07,07,00,07,07,07,07,00,07,07,07,07,07,07,07
	DB	07,07,00,07,07,07,07,00,00,00,00,00,07,07,07
	DB	07,07,00,07,07,07,07,00,07,15,07,00,07,07,07
	DB	07,07,00,07,07,07,07,00,15,07,15,00,07,07,07
	DB	07,07,00,00,00,00,00,00,07,15,07,00,07,07,07
	DB	07,07,07,07,00,07,15,07,15,07,15,00,07,07,07
	DB	07,07,07,07,00,15,07,15,07,15,07,00,07,07,07
	DB	07,07,07,07,00,07,15,07,15,07,15,00,07,07,07
	DB	07,07,07,07,00,15,07,15,07,15,07,00,07,07,07
	DB	07,07,07,07,00,00,00,00,00,00,00,00,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	07,07,07,07,07,07,07,07,07,07,07,07,07,07,07
	DB	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	
;ICONE PAD> P/ CONFIRMACAO OK/ENTER;CANCEL/ESC
;SX: 64bits
;SY: 20lins
ICNF:	DQ	0001111111111111111111111111111111111111111111111111111111111000b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0100000000000000000000000000000000000000000000000000000000000010b
	DQ	0100000000000000000000001111000011000110000000000000000000000010b
	DQ	1000000000000000000000011001100011000110000000000000000000000001b
	DQ	1000000000000000000000110000110011001100000000000000000000000001b
	DQ	1000000000000000000000110000110011011000000000000000000000000001b
	DQ	1000000000000000000000110000110011110000000000000000000000000001b
	DQ	1000000000000000000000110000110011110000000000000000000000000001b
	DQ	1000000000000000000000110000110011011000000000000000000000000001b
	DQ	1000000000000000000000110000110011001100000000000000000000000001b

	DQ	1000000000000000000000110000110011000110000000000000000000000001b
	DQ	1000000000000000000000110000110011000110000000000000000000000001b
	DQ	1000000000000000000000011001100011000110000000000000000000000001b
	DQ	0100000000000000000000001111000011000110000000000000000000000010b
	DQ	0100000000000000000000000000000000000000000000000000000000000010b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0001111111111111111111111111111111111111111111111111111111111000b
	
ICNG:	DQ	0001111111111111111111111111111111111111111111111111111111111000b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0100000000000000000000000000000000000000000000000000000000000010b
	DQ	0100000000111000001110000110001100001110001111110011000000000010b
	DQ	1000000001100100011011000111001100011001001100000011000000000001b
	DQ	1000000011000000110001100111001100110000001100000011000000000001b
	DQ	1000000011000000110001100111101100110000001100000011000000000001b
	DQ	1000000011000000110001100110101100110000001100000011000000000001b
	DQ	1000000011000000110001100110111100110000001111110011000000000001b
	DQ	1000000011000000111111100110011100110000001100000011000000000001b
	DQ	1000000011000000110001100110011100110000001100000011000000000001b
	DQ	1000000011000000110001100110001100110000001100000011000000000001b
	DQ	1000000011000000110001100110001100110000001100000011000000000001b
	DQ	1000000001100100110001100110001100011001001100000011000000000001b
	DQ	0100000000111000110001100110001100001110001111110011111100000010b
	DQ	0100000000000000000000000000000000000000000000000000000000000010b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0010000000000000000000000000000000000000000000000000000000000100b
	DQ	0001111111111111111111111111111111111111111111111111111111111000b

WX	DW	0	;BX
WY	DW	0	;AX
WSX	DW	0	;DX
WSY	DW	0	;CX iniciais
LHAN	DW	0	;Manipulador do arquivo da janela atual
CTMA	DW	0	;TEMP
OWINM	DB	0	;WINM anterior

MACW:	PUSHA
	PUSH	AX
	
	MOV	AL,WINM ;Salva WINM
	MOV	OWINM,AL
	POP	AX
	
	CMP	AX,RY	;Verifica se a janela esta no limite Y (fora da barra de titulo)
	JNA	JMC0	;Positivo, prossegue
	MOV	AX,40	;Negativo, ajusta posicao Y
	JMC0:
	CMP	AX,TLAR ;
	JA	JMC9	;
	MOV	AX,40	;
	JMC9:		;
	
	MOV	DWORD PTR CS:[MMWBUF],0 ;Zera buffer MMWBUF 
	MOV	DWORD PTR CS:[MMWBUF+4],0
	MOV	DWORD PTR CS:[MMWBUF+8],0
	
	;Verifica se realmente sera preciso tracar a janela
	CMP	AX,CS:AIYY
	JA	MWFM
	CMP	BX,CS:AIXX
	JA	MWFM
	ADD	AX,CX
	ADD	BX,DX
	ADD	AX,4
	ADD	BX,4
	CMP	AX,CS:AIY
	JNA	MWFM
	CMP	BX,CS:AIX
	JNA	MWFM
	OR	CX,CX			;Nao pode se usar JCXZ por que
	JZ	MWFM			;o JUMP ficara' OUT OF RANGE.
	
	POPA
	MOV	CS:USEF,0		;Usar fonte grande

	MOV	CS:WY,AX		;Prepara para comecar a desenhar a janela
	MOV	CS:WX,BX		;Prepara memoria
	MOV	CS:WSY,CX
	MOV	CS:WSX,DX
	
	PUSHA				;Prepara nome do arquivo a ser aberto
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET MMWBUF	;Prepara registrador
	PUSHA				;Zera buffer do nome do arquivo
	MOV	CX,13d
	XOR	AL,AL
	REP	STOSB
	POPA
	MOV	CX,8
	;---- LOOP1 ------
	LMWB:				;Copia nome do arquivo do buffer
	LODSB				;das janelas (CS:TTLS) para o buffer
	OR	AL,AL			;local da rotina MACW
	JZ	JMWB
	STOSB
	DEC	CX
	JNZ	LMWB
	;---- END1 ------
	JMWB:
	MOV	DWORD PTR CS:[DI],'WMM.';Grava a extensao MMW no final da string
	MOV	BYTE PTR CS:[DI+5],0	;Grava o ZERO do ASCII-ZERO
	POPA
	
	PUSHA
	;Tenta abrir MMW para leitura e escrita
	MOV	AX,3D02h		;Abre arquivo MMW
	MOV	DX,OFFSET MMWBUF
	INT	21h
	JNC	JMWB1			;Ok? Pula
	
	;Nao conseguindo, tenta abrir apenas para leitura
	MOV	AX,3D00h		;Abre arquivo MMW
	MOV	DX,OFFSET MMWBUF
	INT	21h
	JC	MWFM			;ERRO, pula e nao traca janela
	
	JMWB1:
	MOV	BX,AX
	MOV	LHAN,BX 		;Grava manipulador
	
	MOV	AH,3Fh			;Le arquivo MMW
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	INT	21h
	
	MOV	EAX,DWORD PTR CS:[OFFSET WX]	;Verifica se deve atualizar disco
	MOV	EBX,DWORD PTR CS:[OFFSET WSX]
	CMP	EAX,DWORD PTR CS:[OFFSET MMWX]
	JNZ	JMWBB
	CMP	EBX,DWORD PTR CS:[OFFSET MMWXX]
	JNZ	JMWBB
	CMP	WINM,0			;So muda WINM para 3 se for = 0
	JNZ	JMWBB
	MOV	WINM,3			;Se as posicoes nao mudaram, nao atualiza disco
	JMWBB:
	MOV	DWORD PTR CS:[OFFSET MMWX],EAX	;Atualiza as posicoes para gravar no arquivo
	MOV	DWORD PTR CS:[OFFSET MMWXX],EBX
	
	CMP	WINM,1			;Click em uma icone nao precisa
	JZ	JOWF			;atualizar disco
	CMP	WINM,3			;Verifica se deve atualizar arquivo MMW
	JZ	JOWF			;Negativo, pula
	CMP	WINM,2			;Verifica se esta apenas atualizando as icones
	JZ	JOWF			;Afirmativo, pula e nao atualiza disco
	
	MOV	AX,4200h		;Afirmativo, desloca SEEK para inicio do arquivo
	MOV	BX,LHAN
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	JC	JOWF
	
	MOV	AH,40h			;Grava arquivo (Atualiza)
	MOV	BX,LHAN
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	INT	21h
	
	JOWF:
	POPA
	MOV	SI,OFFSET MMWT
	
	;---------------------------------------	
	PUSHA
	CMP	CS:WINM,1	;FLAG: Click em uma icone
	JZ	JMCI		;Afirmativo, pula para a rotina correspondente
	CMP	CS:WINM,2	;FLAG: Apenas atualize icones (nao verifica mouse)
	JZ	JMCI		;Afirmativo, pula para a rotina correspondente
	
				;Desenha a barra de titulo e o fundo da janela
	XCHG	CX,DX
	MOV	SI,AX
	ADD	SI,CS:TBSZ
	MOV	DI,DX
	ADD	DI,AX
	MOV	DH,3	
	INC	BX
	
	CMP	CS:WINM,2	;FLAG: Apenas atualizar Background
	JNZ	LW02		;Negativo, desenha barra de titulo e janela completa
	MOV	AX,SI		;Positivo, pula rotina que desenha barra de titulo
	JMP	JW03
	
	LW02:			;Desenha linha branca em cima da faixa
	MOV	SI,2
	MOV	DL,CJFE
	LW02A:
	INC	AX
	CALL	LINEH
	DEC	SI
	JNZ	LW02A
	
	MOV	DX,11d		;Desenha faixa
	MOVZX	SI,CJFC
	CALL	RECF
	
	ADD	AX,11d
	MOV	SI,2		;Desenha linha branca em baixo da faixa
	MOV	DL,CJFE
	LW02B:
	INC	AX
	CALL	LINEH
	DEC	SI
	JNZ	LW02B
	
	INC	AX
	MOV	DL,CS:INTC	;Desenha borda abaixo da BARRA DE TITULO
	CALL	LINEH
	INC	AX
	MOV	DL,8	  
	CALL	LINEH
	
	JW03:

	MOVZX	SI,CJFN 	;Desenha o fundo da janela
	SUB	CX,17d
	MOV	DX,DI
	SUB	DX,AX
	CALL	RECF
		
	POPA
	;---------------------------------------
	PUSHA			;*** Escreve o titulo da janela
	SUB	DX,70d		;Calcula o numero max de chrs na janela
	MOV	AX,DX		;DX=(DX-20)/9
	MOV	CX,09d
	XOR	DX,DX
	DIV	CX
	MOV	DX,AX
	MOV	CS:TEMP,DX	;Em CS:TEMP esta o numero maximo de chrs
	POPA
	PUSHA
	
	PUSH	SI
	PUSH	AX
	XOR	CX,CX
	
	LETJ:			;Conta quantos caracteres tem o titulo
	INC	CX
	LODSB
	OR	AL,AL
	JNZ	LETJ
	
	DEC	CX		;Verifica se vai sair dos limites da janela
	CMP	CX,CS:TEMP
	JNA	JETJ
	MOV	CX,CS:TEMP	;Caso SIM, decrementa o limite de caracteres
	
	JETJ:			;BX=BX+(DX-(NC*9))/2
	MOV	AX,09d		;9 - Largura de cada chr.
	XCHG	AX,CX
	PUSH	DX
	MUL	CX
	POP	DX
	MOV	CX,AX
	POP	AX
	SUB	DX,CX
	SHR	DX,1
	ADD	BX,DX
	ADD	AX,2
	;AX: Y, BX: X, CX: TX SIZE
	
	;OR	CX,CX		;Nao havendo texto, nao mexe no topo da janela
	;JZ	JE03
	JCXZ	JE03		;AGO99
	
	SUB	BX,4		;Preenche background do texto 
	ADD	CX,08
	MOV	DX,12d
	MOVZX	SI,CJFE
	CALL	RECF
	
	JE03:
	POP	SI

	INC	AX
	ADD	BX,4
	MOV	RETI,1		;Marca USAR RETICENCIAS
	MOV	CX,CS:TEMP	
	MOV	CH,CL
	MOV	CL,CJFT
	MOV	CS:CBGT,0FFh
	MOV	USEF,0
	CALL	TEXT		;Escreve o texto
	
	CMP	CS:TJBL,0	;Verifica se deve escrever o texto BOLD
	JZ	JTJN		;ou NORMAL
	
	INC	BX		;Reescreve (tipo BOLD)
	CALL	TEXT
	
	JTJN:			;Se houve JUMP pra ca, entao o texto foi escrito NORMAL (Nao-BOLD)
	POPA	
		
	;---------------------------------------
	PUSHA	
	MOV	DL,CS:BORD	;Borda ESQUERDA
	CALL	LINEV

	MOV	DX,CS:WSX
	XCHG	CX,DX		;Borda SUPERIOR
	MOV	DL,CS:BORD	
	CALL	LINEH
	
	ADD	AX,CS:WSY	;Borda INFERIOR
	CALL	LINEH
	ADD	BX,2
	INC	AX
	MOV	DL,CS:INTC
	CALL	LINEH

	MOV	BX,CS:WX	;Borda DIREITA
	MOV	AX,CS:WY
	ADD	BX,CS:WSX
	MOV	CX,CS:WSY
	INC	CX
	MOV	DL,CS:BORD	
	CALL	LINEV
	DEC	CX
	INC	BX
	ADD	AX,2
	MOV	DL,CS:INTC
	CALL	LINEV
	POPA
	;---------------------------------------
	;Traca scroll e title bar
	PUSHA
	
	MOV	AX,CS:WY	;Ajusta registradores iniciais
	ADD	AX,CS:TBSZ
	MOV	BX,CS:WX
	ADD	BX,CS:WSX
	SUB	BX,15
	
	PUSHA

	MOV	CX,15		;Desenha icone seta superior
	MOV	DX,20
	MOV	SI,OFFSET ICNA
	CALL	BITMAP
	
	ADD	AX,19
	MOV	DX,CS:WSY	;Pinta scrollbar
	SUB	DX,73
	MOVZX	SI,CJSB
	CALL	RECF
	ADD	AX,DX
	
	MOV	DX,19		;Desenha icone seta inferior 
	MOV	SI,OFFSET ICNB
	CALL	BITMAP
	
	ADD	AX,19		;Desenha icone resize - inferior direita
	MOV	SI,OFFSET ICNE
	CALL	BITMAP

	POPA
	DEC	BX
	MOV	CX,CS:WSY	;Desenha linha esquerda preta
	SUB	CX,15
	XOR	DL,DL
	CALL	LINEV

	POPA
	PUSHA

	ADD	AX,2		;Desenha icones da barra de titulo
	ADD	BX,6		;Icone esquerda 1
	MOV	CX,14
	MOV	DX,11
	MOV	SI,OFFSET ICNC
	CALL	CRSMAP
	
	ADD	BX,14		;Icone esquerda 2
	MOV	SI,OFFSET ICNC1
	CALL	CRSMAP
	
	POPA
	PUSHA
	;---------------------------------------
	;Coloca as icones na janela
	JMCI:
	MOV	ICSL,0		;Marca: NAO EXISTE ICONE VISUALMENTE SELECIONADA
	MOV	ICLC,0
	MOV	CBTS,0
	MOV	DWORD PTR CS:[OFFSET CATE],00010000h
	;MOV	CATE,0		;*********************
	;MOV	CATS,1		;"Zera" (inicializa) Numero de Linhas na janela
	MOV	ICWA,0		;Zera Numero De Icones Na Janela Atual
	
	MOV	DX,AIYY
	MOV	OAIYY,DX
	
	MOV	AX,CS:WY	;Ajusta area de inclusao
	ADD	AX,CS:WSY
	SUB	AX,2
	CMP	AX,AIYY 	;Verifica se realmente sera necessario ajustar
	JAE	JNPA		;a area de inclusao
	MOV	RAI,0
	MOV	AIYY,AX
	JNPA:
	
	;Le posicao do Scroll
	MOV	BX,WORD PTR CS:[(OFFSET MMWT+(MMWTS+MMWXS+18d))]
	MOV	ICSP,BX
	
	MOV	BX,LHAN 	;Restaura manipulador
	MOV	USEF,1		;Usar fonte pequena
	
	MOV	AX,4200h	;Posiciona arquivo para ler a primeira icone
	MOV	DX,(MMWTS+MMWXS+MMWCS)
	XOR	CX,CX
	INT	21h
	
	MOV	ICWN,0		;Prepara buffers
	MOV	AX,WX
	ADD	AX,7d		;Afastamento X do canto esquerdo da janela
	MOV	ICWX,AX 	;ICWX=WX
	MOV	AX,WY
	ADD	AX,25d		;Afastamento Y do topo da janela		
	MOV	ICWY,AX 	;ICWY=WY
	
	;ICSP	: Numero do Scroll Down. 
	;	  Isto e': Quantas linhas de icones esta para baixo
	;	  -> As ICSP primeiras linhas de icones NAO vao aparecer na janela
	;	     devido ao Scroll Down executado pelo usuario
	;----- LOOP1 -------
	LIC0:
	MOV	AH,3Fh		;Le uma icone
	MOV	BX,LHAN
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	DX,OFFSET ICOT
	PUSH	CS		
	POP	DS
	INT	21h
	JC	ICWF		;Se nao houver mais nada para ler, abandona
	OR	AX,AX
	JZ	ICWF
	INC	CATE		;Incrementa NUMERO DE ICONES (TOTAL) LIDAS DO ARQUIVO
	CALL	SECR		;Ativa seguranca
	
	INC	ICWN		;Marca que leu mais uma icone
	CMP	CATS,1		;Verifica se ainda esta na primeira linha
	JNZ	JCTS		;Negativo, pula
	INC	CBTS		;Positivo, incrementa contador "B" -> Numero de colunas

	JCTS:
	MOV	BX,WSX		;Verifica se deve passar para a proxima linha
	ADD	BX,WX
	SUB	BX,(ICSX+20)
	CMP	ICWX,BX 	;da janela, caso ja tenha esgotado o espaco
	JNA	JIC0		;das colunas. Se nao tiver acabado, goto JIC0

	
	;Passa para proxima linha
	INC	CATS		;Incrementa Controle de Saida (No.de linhas na janela) 
	MOV	AX,WX		;ICWX=WX+7 -> Volta a primeira coluna
	ADD	AX,7d
	MOV	ICWX,AX
	CMP	ICSP,0		;Verifica se ICPS=0 (nao mexer mais)
	JZ	JIC2		;ou se e' maior que 0 (decrementa-lo)
	DEC	ICSP		;Decrementa ICPS
	JMP	JIC0
	JIC2:
	ADD	ICWY,ICSY	;ICWY=ICWY+ICSY -> Proxima linha
	
	JIC0:
	CMP	CS:ICSP,0	;Verifica o SCROLL down pos.
	JNZ	JIC1
	
	MOV	AX,ICWY 	;Desenha icone
	MOV	BX,ICWX
	MOV	CX,32d
	MOV	DX,CX
	
	MOV	SI,OFFSET ICOB
	PUSH	CS
	POP	DS
	CMP	MVIC,1		;Verifica MOVENDO ICONE
	JZ	JIC03		;Pula caso afirmativo
	CALL	CRSMAP
	JIC03:
	INC	ICWA		;Incrementa Numero De Icones Na Janela Atual

	MOV	BH,0FFh 	;Define cor da icone nao-selecionada
	MOV	BL,CJIN
	MOV	TEMP,BX
	MOV	BL,CJFN
	MOV	CBGT,BL 	;Cor do background = cor do fundo da janela
	CMP	CS:WINM,1	;Verifica se deve verificar click do mouse
	JNZ	JMC1		;Negativo, pula proxima rotina
				;Verifica click do mouse
	CALL	LTR1		;Le posicoes do mouse
	CMP	DX,ICWY 	;Verifica se as posicoes do mouse
	JNA	JMC2		;enquadra icone
	CMP	CX,ICWX 	;Pula sempre que negativo
	JNAE	JMC2
	MOV	AX,ICWY
	MOV	BX,ICWX
	ADD	AX,ICSY+1
	ADD	BX,ICSX
	SUB	BX,1
	SUB	AX,1
	CMP	DX,AX
	JA	JMC2
	CMP	CX,BX
	JA	JMC2		;Passando daqui, entao esta icone e' a selecionada
	MOV	AH,0FFh 	;Ajusta cor para texto de icone selecionada
	MOV	AL,CJFS
	MOV	TEMP,AX
	MOV	AL,CJIS
	MOV	CBGT,AL 	;Ajusta cor de background
	MOV	ICSL,1		;Marca: EXISTE ICONE VISIVELMENTE SELECIONADA
	MOV	AX,ICWN 	;Marca numero da icone selecionada
	MOV	ICLC,AX
	
	MOV	AX,ICWX 	;Grava posicoes da icone selecionada
	MOV	ICXS,AX 	;(para verificacao de "movendo icone para o mesmo lugar") 
	MOV	AX,ICWY
	MOV	ICYS,AX

	TEST	MOBX,100b	;Verifica se houve doubleclick (Verificando ULTIMO BX EMITIDO POR MOUSE:)
	JZ	JMC2		;Negativo, pula
	MOV	CS:EXEP,1	;Afirmativo, Marca EXECUTAR PROGRAMA
	JMP	ICWF		;Termina rotina para nao alterar mais o ICOT...ICOR
	JMC2:
	
	;*** INICIO DA ROTINA DE CENTRALIZACAO E SEPARACAO DO TEXTO DA ICONE
	;TEXTO: CS:ICOT..0 ASCIIZ
	JMC1:	
	PUSHA
	PUSH	CS		;Prepara registradores para iniciar
	POP	DS		;o ajuste do texto	
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET ICOT
	JAJTX2:
	MOV	DI,SI
	MOV	CX,10d
	XOR	BL,BL
	CLD	
	;----- LOOP1 ------
	LAJTX0:
	LODSB
	CMP	AL,32d		;Verifica se encontrou um espaco
	JNZ	JAJTX0		;Negativo, pula
	MOV	BL,1		;Afirmativo, marca BL (avisando que encontrou um espaco)
	MOV	DI,SI		;Poe DI na posicao desse espaco (para por um #13d ai depois se precisar)

	JAJTX0:
	OR	AL,AL		;Verifica se cabou o texto
	JZ	JAJTXF		;Sim? Pula. Finaliza subrotina
	LOOP	LAJTX0		;DEC CX e Refaz o LOOP se CX>0
	;----- END1 ------
	CMP	BL,1		;Encontrou algum 32?
	JZ	JAJTX1		;Afirmativo, pula
	MOV	DI,SI		;Negativo, prepara registradores para por #13d na posicao atual
	DEC	DI
	MOV	AL,127d 	;Grava "..." 
	STOSB
	;----- LOOP1 ------
	LAJTX1:
	LODSB
	CMP	AL,32d		;Encontrando 32d, retorna
	JZ	JAJTX3
	OR	AL,AL		;Encontrando 0, finaliza
	JZ	JAJTXF
	MOV	AL,1d		;Grava caractere NOP no texto (para este texto nao aparecer)
	STOSB
	JMP	LAJTX1		;Retorna ao LOOP	
	;----- END1 ------
	JAJTX3:
	INC	DI
	JAJTX1:
	DEC	DI
	MOV	AL,13d		;Grava um CR+LF no texto
	STOSB
	MOV	SI,DI
	JMP	JAJTX2		;Retorna ao LOOP
	
	JAJTXF:
	POPA
	;*** FIM DA ROTINA DE CENTRALIZACAO E SEPARACAO DO TEXTO DA ICONE
	
	MOV	BX,ICWX
	MOV	AX,ICWY 	;Escreve texto
	ADD	AX,35d
	MOV	SI,OFFSET ICOT
	MOV	CX,TEMP
	PUSH	FPAL		;Ajusta altura da fonte
	MOV	FPAL,FALT
	CMP	MVIC,1		;Verifica MOVENDO ICONE
	JZ	JIC02		;Pula caso afirmativo
	CALL	TEXT
	JIC02:
	POP	FPAL
	
	JIC1:
	ADD	ICWX,ICSX	;Proxima coluna
	JMP	LIC0		
	;----- END1 -------
	;================	
	
	ICWF:
	MOV	BX,LHAN 	;Fecha arquivo
	
	CMP	CS:WINM,0	;Verifica se deve atualizar checksum 
	JNZ	JNACJ		;Pula se negativo
	XOR	AL,AL		;Recalcula a checksum do arquivo MMW
	CALL	MCHK		;Rotina SEARCH e' a unica que verifica checksum
	JNACJ:

	MOV	AH,3Eh
	INT	21h
	
	MOV	DX,OAIYY	;Restaura area de inclusao
	MOV	AIYY,DX
	
	CALL	CSHOW		;Atualiza o buffer do mouse
	MWFM:
	MOV	USEF,0		;Usar fonte normal
	MOV	CBGT,0FFh	;Marca Nao Tracar Background
	
	MOV	AL,OWINM	;Restaura WINM
	MOV	WINM,AL
	POPA
	RET
;-------------------------------------------------------------
ICWA	DW	0		;Numero de icones na ultima janela selecionada
ICWN	DW	0
ICWX	DW	0		;Posicao X da icone atualmente sendo processada
ICWY	DW	0		;Posicao Y da icone atualmente sendo processada
ICYS	DW	0		;Pos.Y da icone selecionada
ICXS	DW	0		;Pos.X da icone selecionada
ICSX	EQU	60d		;Tamanho X de cada icone, incluindo texto
ICSY	EQU	76d		;Tamanho Y de cada icone, incluindo texto
				;OBS: Tamanhos X e Y sao usados pela rotina acima
				;para determinar a distancia entre cada icone e
				;quando uma icone deve ser desenhada na linha de baixo.
ICSP	DW	0		;Scroll down position (SDP)
ICLC	DW	0		;Numero da icone selecionada
ICSL	DB	0		;Ha icone visivelmente selecionada (0=NAO,1=SIM)
	
-------------------------------------------------------------
;Nanosistemas. Funcao TEXT
;Acesso: CALL TEXT / EXTERNO
;
;Escreve um texto ASCIIZ na memoria de video utilizando 
;caracteres definidos internamente.
;
;Entra:
;	AX     : Pos: Y
;	BX     : Pos: X
;	CL     : Cor FG
;	CH     : Numero maximo de caracteres (0 = Sem limite)
;	DS:SI  : Seg:Ofs do texto ASCIIZ
;	CS:USEF: Tipo de fonte (0 = Fonte Grande, 1 = Fonte pequena)
;	CS:CBGT: Cor do fundo (0FFh = Transparente, XX = Numero da cor)
;	CS:RETI: Usar reticencias para limitar maximo de caracteres? (0=Nao, 1=Sim)
;Retorna:
;	Alteracoes na memoria de video.
;	Flags e registradores de segmento (ES e DS) alterados.
;
;OBS:	* O texto em DS:SI pode conter o caractere #13d, que causara 
;	  um CR e um LF. (Apenas o #13d. Nao precisa do #10d)
;	* Se o texto conter um #254d todos os proximos caracteres
;	  estarao UNDERLINE.
;	* #255d = NORMAL
;	* Caractere #1d nao faz absolutamente NADA. Pode ser usado para.. nada.
;	* Caractere #2d executa uma repeticao. 
;		O primeiro byte e' 2, o segundo e' o numero de vezes a
;		repetir, e o terceiro e' o caractere a repetir.
;		Exemplo:
;		#2d seguido de 10d seguido de 'A'
;		Resultado: AAAAAAAAAA ('A' dez vezes)
;	* Caractere #3d executa faz a mesma coisa que o #13d. No entando, 
;	  com este voce pode definir o numero de pontos (pixels) a pular
;	  para baixo. O primeiro byte e' #3d e o segundo e' o numero de pontos
;	  a descer. Ex: 3,10d
;	* Caractere #4d executa uma descida definida. O mesmo que o #3, mas
;	  este nao retorna para a primeira coluna.
;	* Caractere #5d executa uma subida definida. O mesmo que o #4, mas
;	  este vai para cima.
;	* Caractere #6d executa deslocamento para a direita.
;		Primeiro byte e' 6, segundo e' numero de pixels
;		a deslocar para a direita.
;	* Caractere #7d executa deslocamento para a esquerda.
;		Primeiro byte e' 7, segundo e' numero de pixels
;		a deslocar para a esquerda.
;	* Caractere #8d - Insere uma icone binaria (monocromatica) no texto
;		Formato: (5 bytes, 2 words)
;		8,CF,CB,SX,SY: Bytes 
;		SEG,OFF: Words
;		CF: Cor Frente, CB: Cor Fundo, SX: Tamanho X (sempre multiplo de 8)
;		SY: Tamanho Y, SEG: Segmento da imagem (1=DS na entrada)
;		OFF: Offset da imagem
;	* Caractere #9d - Mostra HEXADECIMAL WORD
;		Formato: 9,WORD
;		(9 = Byte, WORD = 2 bytes)
;	* Caractere #10d - Mostra HEXADECIMAL BYTE
;		Formato: 10,BYTE
;		(10 = Byte, BYTE = 1 byte)

RETI	DB	0	;Usar reticencias? 1=Sim,0=Nao
FNTS	DW	0	;Tamanho da fonte (5 ou 9)
TXFG	DB	0	;Cor do texto FOREGROUND
CMAX	DB	0	;Numero maximo de caracteres
TMP3	DW	0	;Temporarios
TMP4	DW	0
TMP5	DW	0
TLMT	DB	0	;Limitar # de caracteres? (0=SIM, 1=NAO)
TMOD	DB	0	;Modo (0=Normal,1=Underline)
FPAL	DW	0	;Altura da fonte pequena (ajustado pelo usuario)
TREP	DB	0	;Repetir proximo caractere TREP vezes (Usado pelo comando #2d no texto)
TUCL	DB	0	;Ultimo caractere lido

TEXT:	PUSHA
	CMP	CL,0FFh 	;Verifica COR PADRAO DO SISTEMA
	JNZ	JTEXT0
	MOV	CL,TXTC 	
	JTEXT0:
	
	MOV	FNTS,5		;Define a largura da fonte
	CMP	USEF,0
	JNZ	JAT4
	MOV	FNTS,9	
	JAT4:
	
	CMP	USEF,1		;Se USEF>1, entao largura da letra = USEF
	JNA	JATA4		;e usar fonte pequena
	PUSH	CX
	MOVZX	CX,USEF
	MOV	FNTS,CX
	POP	CX
	JATA4:
	
	MOV	TMOD,0		;Zera variaveis
	MOV	TREP,0
	MOV	TLMT,0
	OR	CH,CH		;Limitar # de caracteres?
	JNZ	JLNC		;Positivo, pula
	MOV	TLMT,1		;Negativo, marca flag
	
	JLNC:
	MOV	CS:CMAX,CH	;Salva n.max.chrs
	MOV	CS:TXFG,CL	;Salva as cores
	MOV	TMP3,0
	MOV	TMP4,AX
	MOV	TMP5,BX

	;-------- LOOP0 ---------
	LTX0:		;Le uma letra do buffer
	PUSH	AX
	CMP	TLMT,1	 ;Verifica se deve limitar # de caracteres
	JZ	JNLN2	 ;Negativo, pula
	CMP	CS:CMAX,0;Verifica se ultrapassou o limite de chrs
	JZ	TXFM	 ;Afirmativo, pula     
	JNLN2:
	
	CMP	TREP,0	;Verifica se deve repetir um caractere
	JNZ	JTXR0	;Afirmativo, pula
	
	CLD
	LODSB		;Le proximo caractere
	MOV	TUCL,AL ;Grava ultimo caractere lido
	
	JTXR0:
	MOV	AL,TUCL ;Le ultimo caractere lido em AL
	
	CMP	TREP,0	;Verifica se esta repetindo caractere
	JZ	JTXR1	;Negativo, pula
	DEC	TREP	;Afirmativo, decrementa 1 do contador	
	JTXR1:

	
	OR	AL,AL	;Verifica se chegou ao fim do texto
	JZ	TXFM	;Caso SIM, finaliza
	
	;Inicio das subrotinas de execucao
	;dos comandos de texto
	;---------------------------------
	CMP	AL,13d	;Verifica se o caractere lido e' um ENTER (#13d)
	JNZ	JAT0	;Negativo, pula
	MOV	AX,FPAL 	;Em AX o tamanho da fonte (altura)
	ADD	CS:TMP4,AX	;Executa CR e LF
	ADD	SP,2		;Mexe no AX que esta na pilha (SS:SP)
	PUSH	CS:TMP4
	MOV	BX,CS:TMP5
	POP	AX
	JMP	LTX0
	JAT0:
	CMP	AL,254d ;Verifica UNDERLINE COMMAND
	JNZ	JAT1	;Negativo, pula
	MOV	TMOD,1	;Afirmativo, marca TMOD=1
	POP	AX
	JMP	LTX0
	JAT1:
	CMP	AL,255d ;Verifica NORMAL COMMAND
	JNZ	JAT2	;Negativo, pula
	MOV	TMOD,0	;Afirmativo, marca TMOD=0
	POP	AX
	JMP	LTX0
	JAT2:
	CMP	AL,1d	;Verifica NOP
	JNZ	JAT3A	;Negativo, pula
	POP	AX	;Afirmativo, retorna ao LOOP como se 
	JMP	LTX0	;aquele byte nao existisse
	JAT3A:
	CMP	AL,2d	;Verifica REP
	JNZ	JAT3B	;Negativo, pula
	POP	AX	;Afirmativo, le o numero de vezes a repetir

	PUSH	AX
	LODSB
	DEC	AL
	MOV	TREP,AL ;Grava na memoria
	POP	AX	;Le caractere a repetir
	PUSH	AX
	LODSB
	MOV	TUCL,AL ;Grava na memoria
	JAT3B:
	CMP	AL,3d	;Verifica ENTER DEFINIDO
	JNZ	JAT3C	;Negativo, pula
	POP	AX	;Afirmativo, le o parametro do comando
	PUSH	AX
	LODSB
	XOR	AH,AH		;Em AX o numero de pontos a descer	
	ADD	CS:TMP4,AX	;Executa DOWN
	ADD	SP,2		;Mexe no AX que esta na pilha (SS:SP)
	PUSH	CS:TMP4
	MOV	BX,CS:TMP5
	POP	AX
	JMP	LTX0
	JAT3C:
	CMP	AL,4d	;Verifica DOWN DEFINIDO
	JNZ	JAT4A	;Negativo, pula
	POP	AX	;Afirmativo, le o parametro do comando
	PUSH	AX
	LODSB
	XOR	AH,AH		;Em AX o numero de pontos a descer	
	ADD	CS:TMP4,AX	;Executa DOWN
	ADD	SP,2		;Mexe no AX que esta na pilha (SS:SP)
	PUSH	CS:TMP4
	POP	AX
	JMP	LTX0
	JAT4A:
	CMP	AL,5d	;Verifica UP DEFINIDO
	JNZ	JAT5A	;Negativo, pula
	POP	AX	;Afirmativo, le o parametro do comando
	PUSH	AX
	LODSB
	XOR	AH,AH		;Em AX o numero de pontos a subir	
	SUB	CS:TMP4,AX	;Executa UP
	ADD	SP,2		;Mexe no AX que esta na pilha (SS:SP)
	PUSH	CS:TMP4
	POP	AX
	JMP	LTX0
	JAT5A:
	CMP	AL,6d	;Verifica RIGHT DEFINIDO
	JNZ	JAT6A	;Negativo, pula
	POP	AX	;Afirmativo, le o parametro do comando
	PUSH	AX
	LODSB
	ADD	SP,2
	XOR	AH,AH		;Em AX o numero de pontos a deslocar
	ADD	BX,AX
	PUSH	CS:TMP4
	POP	AX
	JMP	LTX0
	JAT6A:
	CMP	AL,7d	;Verifica LEFT DEFINIDO
	JNZ	JAT7A	;Negativo, pula
	POP	AX	;Afirmativo, le o parametro do comando

	PUSH	AX
	LODSB
	ADD	SP,2
	XOR	AH,AH		;Em AX o numero de pontos a deslocar
	SUB	BX,AX
	PUSH	CS:TMP4
	POP	AX
	JMP	LTX0
	JAT7A:
	CMP	AL,8d	;Verifica ICONE MONOCROMATICA
	JNZ	JAT8A	;Negativo, pula
	POP	AX
	PUSH	AX
	PUSH	SI
	PUSH	CX
	PUSH	DX
	PUSH	DS
	PUSH	AX
	;-----		;Monta parametros para passar a funcao BINMAP 
	LODSW		;(Veja funcao BINMAP, entrada dos registradores)
	MOV	DI,AX
	LODSB
	MOVZX	CX,AL
	LODSB
	MOVZX	DX,AL
	LODSW	
	CMP	AX,1	;Se SEG=1, usa segmento default do texto
	JZ	JAT8B
	MOV	DS,AX
	JAT8B:
	LODSW
	MOV	SI,AX
	POP	AX
	CALL	BINMAP
	;----
	ADD	BX,CX
	POP	DS
	POP	DX
	POP	CX
	POP	SI
	ADD	SI,8
	ADD	SP,2
	PUSH	CS:TMP4
	POP	AX
	JMP	LTX0
	JAT8A:
	CMP	AL,9	;Verifica HEXADECIMAL WORD
	JNZ	JAT9A
	POP	CX
	;Em CX a posicao Y
	MOV	BP,4
	XOR	EAX,EAX
	LODSW		;Em AX a WORD
	ROL	EAX,16d ;Prepara EAX
	;---- LOOP0 ------
	LAT90:
	ROL	EAX,4d
	ADD	AL,'0'
	CMP	AL,'9'
	JNA	JAT90
	ADD	AL,7
	JAT90:		;Em AL o caractere pronto
	PUSH	CX
	CALL	LTXT	;Exibe na tela
	POP	CX
	XOR	AX,AX
	DEC	BP	;Verifica se terminou
	JNZ	LAT90	;Negativo, retorna ao LOOP
	;---- END0 ------
	PUSH	CS:TMP4
	POP	AX
	JMP	LTX0

	JAT9A:
	CMP	AL,10d	;Verifica HEXADECIMAL BYTE
	JNZ	JAT10A
	POP	CX
	;Em CX a posicao Y
	MOV	BP,2
	XOR	EAX,EAX
	LODSB		;Em AL o byte
	ROL	EAX,24d ;Prepara EAX
	;---- LOOP0 ------
	LAT100:
	ROL	EAX,4d
	ADD	AL,'0'
	CMP	AL,'9'
	JNA	JAT100
	ADD	AL,7
	JAT100: 	;Em AL o caractere pronto
	PUSH	CX
	CALL	LTXT	;Exibe na tela
	POP	CX
	XOR	AX,AX
	DEC	BP	;Verifica se terminou
	JNZ	LAT100	;Negativo, retorna ao LOOP
	;---- END0 ------
	PUSH	CS:TMP4
	POP	AX
	JMP	LTX0
	JAT10A:
	;---------------------------------
	;Fim das subrotinas de execucao dos
	;comandos de texto.
	POP	CX
	CALL	LTXT
	JMP	LTX0
	
	;Rotina interna: Desenha um caractere.
	;Entra: AL    : Caractere ASCII
	;	BX,CX : Pos. X,Y

	LTXT:
	PUSH	CX
	CMP	AL,32d	;Verifica se e' um caractere valido
	JAE	JATX	;Caso negativo, entao substitui por espaco
	MOV	AL,32d
	JATX:
	CMP	AL,142d 
	JNA	JBTX
	MOV	AL,32d
	JBTX:
	
	CMP	TLMT,1	 ;Verifica se deve limitar # de caracteres
	JZ	JNLN	 ;Negativo, pula
	CMP	CS:CMAX,0;Verifica se ultrapassou o limite de chrs
	JNZ	JNLN	 ;Negativo, pula     
	POP	CX	 ;Afirmativo, retorna
	RET
	JNLN:
	
	MOV	CX,12d	;Calcula posicao do caractere (OFFSET)
	XOR	AH,AH
	SUB	AL,32d
	MUL	CX	

	CMP	CS:USEF,0	;Verifica qual fonte deve usar
	JNZ	JUS0
	ADD	AX,OFFSET FONT1
	JMP	JUSF
	JUS0:	
	ADD	AX,OFFSET FONT2
	JUSF:
	
	MOV	DI,AX
	POP	AX	;Em DI, o offset do caractere solicitado (FONT1)
	;*** Aqui, sera verificado cada bit do caractere escolhido
	;    e para cada bit marcado sera marcado na tela um ponto
	;    na posicao correspondida, ate que CX=0.

	
	DEC	CS:CMAX ;Verifica se ja ultrapassou o numero maximo de chrs.
	CMP	CS:CMAX,0
	JNZ	LTX1B	;Caso NAO ultrapassou, prossegue.
	
	CMP	TLMT,1	;Se nao e' para limitar numero max de catacteres,
	JZ	LTX1B	;pula. Nao grava "..."
	
	CMP	RETI,0	;Verifica se deve usar reticencias
	JZ	LTX1B	;Negativo, pula
	MOV	DI,OFFSET MORE1 ;Caso SIM, desvia DI para MORE1
	LTX1B:
	;OBS: MORE1 Ç uma fonte que indica continuidade. ê representada
	;     por tres pontos (...), e Ç usada para dizer ao usuario

	;     que o texto foi truncado, mas apesar de nao aparecer na tela,
	;     ele existe. CS:OFFSET MORE1 Ç o endereco dessa fonte.

	MOV	DH,12d
	LTX1:
	MOV	CX,8d	;Desenha a fonte na tela
	MOV	DL,1d
	;-------- LOOP1 ---------
	LTX2:
	PUSH	CX

	ROR	DL,1
	TEST	BYTE PTR CS:[DI],DL	;Verifica se Ç um ponto
	JZ	JTX0			;Se nao for, ignora a rotina POINT
	
	MOV	CL,CS:TXFG		;Se for, traca um ponto "preto"
	CALL	POINT			;Traca um ponto
	JMP	JTX1
	
	JTX0:
	CMP	CBGT,0FFh		;Verifica se deve tracar o background
	JZ	JTX1			;Negativo, ignora proxima rotina
	MOV	CL,CS:CBGT		;Positivo, traca o ponto na cor CBGT
	CALL	POINT
	
	JTX1:
	INC	BX
	POP	CX
	DEC	CX
	JNZ	LTX2	  
	;-------- END1 ---------
	
	SUB	BX,8
	INC	AX
	INC	DI
	DEC	DH
	JNZ	LTX1
	
	CMP	TMOD,1			;Deve executar o UNDERLINE?
	JNZ	JAT3			;Negativo, pula
	MOV	CX,FNTS 	
	MOV	DL,TXFG
	CALL	LINEH
	
	JAT3:
	ADD	BX,FNTS 		;BX para a direita
	SUB	AX,12d			;Levanta AX
	RET				;Retorna
	;-------- END0 ---------
	
	TXFM:
	POP	AX
	POPA
	RET

CBGT	DB	0FFh			;Cor do background do texto (0FFh = Sem BG)

-------------------------------------------------------------
;Nanosistemas. Funcao 1Dh
;Acesso: CALL REWRITE / EXTERNO
;
;Redesenha todo o perimetro enquadrado na area de inclusao, e 
;ignorando todos os pontos que estejam na area de exclusao.
;Esse perimetro inclui o bitmap de fundo e todas as janelas, icones
;e barra superior. (Nao inclui caixas de mensagens nem menus)
;O usuario desta funcao deve antes de chama-la, caso seja preciso, 
;usar a funcao CHIDE para retirar o cursor do mouse da tela, e depois de
;executada o usuario deve usar a funcao CSHOW para restaurar o cursor na tela.
;
;Entra: NADA
;Retorna: 
;Alteracoes na memoria de video
;Flags e registradores de segmento (ES e DS) alterados.
;
;OBS:	Se CS:DMAL = 0, esta rotina ira redesenhar todo o desktop
;	respeitando a area de inclusao e a area de exclusao. No entando, 
;	ira maximizar a area de inclusao e minimizar a area de exclusao
;	logo antes de desenhar a ultima janela (a janela em prioridade 1).
;	Se CS:DMAL <> 0, entao esta rotina so ira maximizar a area de inclusao
;	e minimizar a de exclusao apos desenhadas todas as janelas.

RTMP	DW	0	;Temporario
LTMP	DW	0	;Temporario

REWRITE:PUSHA

	CLD
	CALL	BARR		;Exibe barra no topo
	CALL	DOBGN		;Desenha background
	
	MOV	DI,CS:INDX	;Redesenha todas as janelas
	ADD	DI,8
	MOV	CS:RTMP,DI
	AND	CS:LTMP,0
	;----- LOOP1 -----
	LRW1:
	ADD	CS:LTMP,8	
	MOV	DI,CS:LTMP
	CMP	DI,CS:RTMP	;Verifica se ja examinou todas as janelas
	JZ	JRW0
	
	ADD	DI,8		;Verifica se deve maximizar a area de inclusao
	CMP	DI,CS:RTMP	;antes de tracar a janela de prioridade 1
	JNZ	NMAI		;Caso nao seja a ultima janela agora, ignora.
	
	CMP	DMAL,0		;Verifica se realmente deve maximizar area de inclusao
	JNZ	NMAI		;para tracar esta janela. Negativo, pula.
	
	CALL	MAXL		;Maximiza limites
	
	NMAI:
	SUB	DI,8		;Desfaz o ADD DI,8 acima
	
	MOV	EAX,DWORD PTR CS:WIN1+DI	;Armazena XYXXYY na memoria
	MOV	DWORD PTR CS:DWTEMP,EAX 	;de transicao
	MOV	EAX,DWORD PTR CS:WIN1+DI+4
	MOV	DWORD PTR CS:DWTEMP+4,EAX

	MOV	BX,WORD PTR CS:DWTEMP		;Redesenha janela selecionada
	MOV	AX,WORD PTR CS:[DWTEMP+2]
	MOV	DX,WORD PTR CS:[DWTEMP+4]
	SUB	DX,BX
	MOV	CX,WORD PTR CS:[DWTEMP+6]
	SUB	CX,AX

	PUSH	AX
	PUSH	DI
	PUSH	DX
	
	;(DI/8)*8 + OFFSET TTLS = Offset do buffer do titulo
	ADD	DI,OFFSET TTLS
	MOV	SI,DI
	PUSH	CS
	POP	DS	;Em DS:SI esta onde deve ser lido o titulo
	
	POP	DX
	POP	DI
	POP	AX
	
	CALL	MACW		;Desenha janela

	JMP	LRW1
	;----- END1 -----
	JRW0:
	CALL	CSHOW	;Retorna cursor do mouse
	CALL	MAXL	;Maximiza limites	
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Funcao 1Eh
;Acesso: CALL MBDP / EXTERNO
;
;ATUALIZA BUFFER PARA O MENU BDP
;Procura no endereco CS:TTLS os nomes dos arquivos das janelas e
;abre um a um, lendo os nomes (titulos) de todas as janelas e
;grava em ordem no buffer CS:RBDT para ser usado pela rotina
;que opera o botao direito do mouse.
;
;Entra: NADA
;Retorna: Alteracoes na memoria interna do Nanosistemas
;
;OBS: E' obrigatoria a chamada desta rotina antes que o usuario pressione
;o botao direito do mouse.
	
MBDP:	PUSHA
	PUSH	ES
	PUSH	DS
	MOV	RWDI,OFFSET RBDT
	CMP	CS:INDX,0	;Havendo alguma janela no desktop,
	JNZ	JMBI		;Pula, atualiza MBDP.
	PUSH	CS		;Nao havendo nenhuma janela,
	POP	DS		;Copia mensagem de "Nao ha janelas"...
	PUSH	CS		
	POP	ES
	MOV	DI,OFFSET RBDT
	MOV	SI,OFFSET RBOL
	MOV	CX,OFFSET RBOF - OFFSET RBOL
	CLD
	REP	MOVSB
	JMP	JMBF		;..e nao mexe mais no MBDP
	
	JMBI:
	MOV	DI,CS:INDX	;Redesenha todas as janelas
	ADD	DI,8
	MOV	CS:RTMP,DI
	AND	CS:LTMP,0
	;----- LOOP1 -----
	LMB1:
	ADD	CS:LTMP,8	
	MOV	DI,CS:LTMP
	CMP	DI,CS:RTMP	;Verifica se ja examinou todas as janelas
	JZ	JMB0
	
	;(DI/8)*8 + OFFSET TTLS = Offset do buffer do titulo
	ADD	DI,OFFSET TTLS
	MOV	SI,DI
	PUSH	CS	
	POP	DS	;Em DS:SI esta onde deve ser lido o titulo

	;*** SUBROTINA: Abre arquivo MMW e le titulo da janela
	PUSHA				;Prepara nome do arquivo a ser aberto
	PUSH	CS	
	POP	DS
	PUSH	CS			
	POP	ES
	MOV	DI,OFFSET MMWBUF	;Prepara registrador
	PUSHA				;Zera buffer do nome do arquivo
	MOV	CX,13d
	XOR	AL,AL
	REP	STOSB
	POPA
	MOV	CX,8			;Prepara registrador
	;---- LOOP1 ------
	LMBB:				;Copia nome do arquivo do buffer
	LODSB				;das janelas (CS:TTLS) para o buffer
	OR	AL,AL			;local da rotina MACW
	JZ	JMBB
	STOSB
	DEC	CX
	JNZ	LMBB
	;---- END1 ------
	JMBB:
	MOV	DWORD PTR CS:[DI],'WMM.';Grava a extensao MMW no final da string
	MOV	BYTE PTR CS:[DI+5],0	;Grava o ZERO do ASCII-ZERO
	POPA
	
	PUSHA
	MOV	AX,3D00h		;Abre arquivo MMW
	PUSH	CS			;***************************
	POP	DS
	MOV	DX,OFFSET MMWBUF
	INT	21h
	JC	JODF			;Erro: Pula
	MOV	BX,AX
	MOV	LHAN,BX 		;Grava manipulador
	
	MOV	AH,3Fh			;Le arquivo MMW
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	INT	21h
	
	MOV	AH,3Eh			;Fecha arquivo
	INT	21h
	JODF:
	POPA
	JC	LMB1			;Houve erro, nao adiciona esta janela
	
	;Em CS:MMWT, o titulo ASCIIZ da janela
	;------ LOOP1 / SUBROTINA 1 -----
	PUSHA
	PUSH	ES
	PUSH	DS
	
	PUSH	CS	
	POP	ES
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET MMWT
	MOV	DI,RWDI
	CLD
	;----- LOOP1 -----	;Copia o titulo da janela para o buffer do menu
	LRW3:
	LODSB
	OR	AL,AL		;Zero indica o final do texto
	JZ	JRW3
	CMP	DI,OFFSET RBTE
	JAE	JRW4
	STOSB
	JMP	LRW3
	;----- END1 -----
	JRW3:
	MOV	AX,0D20h	;No lugar do Zero, grava um 13d (proxima linha)
	STOSW
	JRW4:
	MOV	RWDI,DI
	POP	DS
	POP	ES
	POPA
	;------ END1 / SUBROTINA 1 ENDS -----
	JMP	LMB1
	
	;-----------
	JMB0:
	;*** INICIO DA FINALIZACAO DA ROTINA: ATUALIZA BUFFER PARA O MENU BDP
	MOV	DI,RWDI 	;Marca final do menu
	MOV	DWORD PTR CS:[DI-1],0FFFF0D00h
	;*** FIM DA FINALIZACAO DA ROTINA: ATUALIZA BUFFER PARA O MENU BDP
	

	JMBF:
	POP	DS
	POP	ES
	POPA
	
	RET
	
RWDI	DW	0		;DI. Pos Ofst MENU BDP

;SERA COPIADO PARA RBDT CASO NAO HAJA JANELAS NO DESKTOP
RBOL:	DB	'No Windows Present',0,13d,0FFh,0FFh
RBOF:

-------------------------------------------------------------
;Nanosistemas. Funcao 1Fh
;Acesso: CALL WINDOW / EXTERNO
;
;Cadastra uma janela
;Entra:
;AX	: Pos Y
;BX	: Pos X
;CX	: Size Y
;DX	: Size X
;DS:SI	: Nome ASCIIZ do arquivo de dados (MMW) da janela (8 chr max)

;Retorna:
;Alteracoes na memoria.
;Flags e registradores de segmento (ES e DS) alterados.
;
;Para saber se a janela foi cadastrada com sucesso, verifique se
;a word em CS:INDX foi incrementada. Negativo, entao ja existem muitas janelas
;no desktop.


WINDOW: PUSHA
	CMP	CS:INDX,MJAN*8	;Verifica se ja existem 49 janelas
	JAE	JWNF		;Afirmativo, nao cadastra mais nenhuma
	
	ADD	CS:INDX,8	;Cadastra a janela
	MOV	DI,CS:INDX
	ADD	CX,AX		;Anota as dimensoes da janela 
	ADD	DX,BX
	MOV	WORD PTR CS:[WIN1+DI],BX
	MOV	WORD PTR CS:[WIN1+DI+2],AX
	MOV	WORD PTR CS:[WIN1+DI+4],DX
	MOV	WORD PTR CS:[WIN1+DI+6],CX
	
	;(DI/8)*8 + OFFSET TTLS = Offset do buffer MMW
	ADD	DI,OFFSET TTLS
	PUSH	CS
	POP	ES		;Em ES:DI esta onde deve ser gravado o titulo
	
	CLD
	MOV	CX,8d		;Copia o nome do arquivo MMW para o final de TTLS
	;--- LOOP1 ---
	LWN0:
	LODSB
	OR	AL,AL
	JZ	WNFM
	STOSB
	LOOP	LWN0
	WNFM:
	;--- END1 ---
	
	JCXZ	JWNF		;Terminou? Pula
	XOR	AL,AL		;Nao gravou 8 bytes?
	REP	STOSB		;Completa com ZERO
	
	JWNF:
	POPA
	RET
	
-------------------------------------------------------------
;Desenha a barra superior
;Entra: NADA
;Retorna: Alteracoes na memoria de video apenas

NSIS:	DD	11111111111111111111111000000000b
	DD	11111111111111111111111000000000b
	DD	11011101111111111111111000000000b
	DD	11001101100010001100011000000000b
	DD	11000101011111011011111000000000b
	DD	11010001100111011100111000000000b
	DD	11011001111011011111011000000000b
	DD	11011101000110001000111000000000b
	DD	11111111111111111111111000000000b
	DD	11111111111111111111111000000000b
	
ICB1:	DQ	1111111111111001111111111111001111111111111001111111111111000000b
	DQ	1000000000001001000000000001001000000000001001000000000001000000b
	DQ	1000010000001001000010001001001001000100001001000000010001000000b
	DQ	1000011000001001000110011001001001100110001001000100110001000000b
	DQ	1000011100001001001110111001001001110111001001000101110001000000b
	DQ	1000011110001001011111111001001001111111101001000111110001000000b
	DQ	1000011100001001001110111001001001110111001001000101110001000000b
	DQ	1000011000001001000110011001001001100110001001000100110001000000b
	DQ	1000010000001001000010001001001001000100001001000000010001000000b
	DQ	1000000000001001000000000001001000000000001001000000000001000000b
	DQ	1111111111111001111111111111001111111111111001111111111111000000b

ICB2:	DQ	1111111111111001111111111111001111111111111001111111111111000000b
	DQ	1000000000001001000000000001001000000000001001000000000001000000b
	DQ	1000100000001001000000000001001000000000001001000001000001000000b
	DQ	1000110010001001000111110001001000110110001001000011100001000000b
	DQ	1000111010001001000111110001001000110110001001000111110001000000b
	DQ	1000111110001001000111110001001000110110001001000000000001000000b
	DQ	1000111010001001000111110001001000110110001001000111110001000000b
	DQ	1000110010001001000111110001001000110110001001000111110001000000b
	DQ	1000100000001001000000000001001000000000001001000000000001000000b
	DQ	1000000000001001000000000001001000000000001001000000000001000000b
	DQ	1111111111111001111111111111001111111111111001111111111111000000b

BARR:	PUSHA
	MOV	USEF,1	;Desenha barra branca no topo da tela
	
	XOR	AX,AX
	MOV	DX,AX
	ADD	DX,TLAR
	XOR	BX,BX
	MOV	CX,RX
	MOVZX	SI,TCOR
	CALL	RECF
	INC	AX
	MOVZX	SI,BORD
	CALL	RECT
	
	;Escreve opcoes do menu
	MOV	AH,TXCR 	;Desenha o CD PLAYER
	MOV	AL,TCOR
	MOV	DI,AX
	MOV	AX,3
	MOV	BX,2
	MOV	CX,32d
	MOV	DX,10d
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET NSIS
	CALL	BINMAP
	
	MOV	USEF,0
	MOV	AX,3
	MOV	BX,RX
	SUB	BX,110d
	MOV	CL,TXCR
	MOV	CH,TCOR
	CALL	DOCAL		;Exibe calendario
	
	CMP	SHCD,1	;Exibir CD PLAYER?
	JNZ	JBARR0	;Negativo, pula
	;Desenha icones no menu (CD PLAYER)
	CALL	ATCD
	JBARR0:
	
	POPA
	RET
	
	
-------------------------------------------------------------
;Nanosistemas. Rotina exclusiva
;Acesso: CALL LOAD / INTERNO
;
;Carrega a configuracao do usuario, abrindo o arquivo MM.CFG do diretorio
;atual e gravando as informacoes direto na memoria.
;
;Entra: NADA
;Retorna: CS:TEMP : 0=Erro abrindo arquivo, 1=Checksum error, 2=Ok
;	  Possiveis alteracoes na memoria
;
LOAD:	PUSHA
	PUSH	DS
	
	MOV	TEMP,0		;Marca: Arquivo nao encontrado
	MOV	AX,3D00h	;Carrega a configuracao salva (se MM.CFG existir)
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MPCTB
	INT	21h	
	JC	JBG9		;Pula se o arquivo nao existir no diretorio atual
	MOV	BX,AX
	MOV	TEMP,1		;Marca: Checksum invalida

	MOV	AL,1
	CALL	CCHK		;Verifica checksum
	OR	AL,AL
	JNZ	JLOAD0		;Incorreta, pula.
	
	MOV	TEMP,2		;Marca: Carregada com sucesso
	
	MOV	AX,4200h	;Desloca posicao do arquivo para o inicio
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	
	MOV	AH,3Fh		;Le configuracao e grava na memoria
	MOV	CX,OFFSET SAVEEND - OFFSET SAVEBGN
	MOV	DX,OFFSET SAVEBGN
	INT	21h
	
	JLOAD0:
	MOV	AH,3Eh		;Fecha arquivo CFG
	INT	21h
	
	JBG9:
	POP	DS		;Finaliza rotina
	POPA
	RET
	
--------------------------------------------------------------
;Nanosistemas. Funcao SAVE
;Acesso: CALL SAVE 
;
;Salva configuracao no arquivo MM.CFG
;
SAVE:	PUSHA
	PUSH	DS
	
	MOV	AH,3Ch	;Cria arquivo MM.CFG
	XOR	CX,CX
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MPCTB
	INT	21h
	MOV	BX,AX
	
	MOV	AH,40h	;Grava configuracao atual no arquivo CFG
	MOV	CX,OFFSET SAVEEND - OFFSET SAVEBGN
	MOV	DX,OFFSET SAVEBGN
	INT	21h
	
	XOR	AL,AL
	CALL	CCHK	;Calcula e grava checksum
	
	MOV	AH,3Eh	;Fecha arquivo CFG
	INT	21h
	
	POP	DS	;Finaliza rotina
	POPA
	RET
	
-------------------------------------------------------------
;Nanosistemas. Configuracao IMAGEM FADE

;Exclusivo do sistema
;
IFTX1:	DB	'Image fade',2,18,' Refresh Desktop',13
	DB	'   RED',13
	DB	'Pos.Y: ',13
	DB	'Back : ',13
	DB	'Steps: ',13
	DB	'SizeY: ',13
	DB	'Size : ',13
	DB	'   GREEN',13
	DB	'Pos.Y: ',13
	DB	'Back : ',13
	DB	'Steps: ',13
	DB	'SizeY: ',13
	DB	'Size : ',13
	DB	'   BLUE',13
	DB	'Pos.Y: ',13
	DB	'Back : ',13
	DB	'Steps: ',13
	DB	'SizeY: ',13

	DB	'Size : ',13
	DB	0
	
IFREF	DW	1111111111111111b
	DW	1111111111111111b
	DW	1111000110001111b
	DW	1111011110111111b

	DW	1111011110111111b
	DW	1111000110011111b
	DW	1111011111101111b
	DW	1111011111101111b

	DW	1111011110011111b
	DW	1111111111111111b
	DW	1111111111111111b

IFINF:	DW	0FFFFh	;Posicao X (0FFFFh = Centralizado em X)
	DW	0FFFFh	;Posicao Y (0FFFFh = Centralizado em Y)
	DW	300	;Tamanho X 
	DW	345	;Tamanho Y
	DW	0	;CLICKS:OFF
	
	;TEXTOS 
	DW	01
	DW	20
	DW	16
	DB 8 dup (0)
	DB	0FFh
	DB	1
	DW	OFFSET IFTX1
	DW	0
	DD	0
	DW	0
	
	;BARRS (RED)
	DW	07
	DW	100
	DW	61-15
	DB 9 dup (0)
	DB	98
	DW	OFFSET RCORI
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	89-29
	DB 9 dup (0)
	DB	63
	DW	OFFSET RINTM
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	103-29
	DB 9 dup (0)
	DB	10
	DW	OFFSET RSTEP
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	117-29
	DB 9 dup (0)
	DB	63

	DW	OFFSET RSIZY
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	131-29
	DB 9 dup (0)
	DB	10
	DW	OFFSET RCPLS
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	;BARRS (GREEN)
	DW	07
	DW	100
	DW	61-29+105
	DB 9 dup (0)
	DB	98
	DW	OFFSET GCORI

	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	89-43+105
	DB 9 dup (0)
	DB	63
	DW	OFFSET GINTM
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	103-43+105
	DB 9 dup (0)
	DB	10
	DW	OFFSET GSTEP
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	117-43+105
	DB 9 dup (0)
	DB	63
	DW	OFFSET GSIZY
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	131-43+105
	DB 9 dup (0)
	DB	10
	DW	OFFSET GCPLS
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	;BARRS (BLUE)
	DW	07
	DW	100
	DW	61-43+210
	DB 9 dup (0)
	DB	98
	DW	OFFSET BCORI
	DW	0
	DW	0
	DW	0FFFFh
	DW	0

	
	DW	07
	DW	100
	DW	89-57+210
	DB 9 dup (0)
	DB	63
	DW	OFFSET BINTM
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	103-57+210
	DB 9 dup (0)
	DB	10
	DW	OFFSET BSTEP
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	117-57+210
	DB 9 dup (0)
	DB	63
	DW	OFFSET BSIZY
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	100
	DW	131-57+210
	DB 9 dup (0)
	DB	10
	DW	OFFSET BCPLS
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	;CHECKBOXES
	DW	02
	DW	20
	DW	48-15
	DB 10 dup (0)
	DW	OFFSET EXIR
	DW	0
	DB	0FFh
	DB	0FFh
	DW	0FFFFh
	DW	0
	
	DW	02
	DW	20
	DW	153-30
	DB 10 dup (0)
	DW	OFFSET EXIG
	DW	0
	DB	0FFh
	DB	0FFh
	DW	0FFFFh
	DW	0
	
	DW	02
	DW	20
	DW	258-45
	DB 10 dup (0)
	DW	OFFSET EXIB
	DW	0
	DB	0FFh
	DB	0FFh
	DW	0FFFFh
	DW	0
	
	;BINMPS - ICONES
	DW	05		;ICONE [ F5 - Refresh ]
	DW	135
	DW	16
	DB 9 dup (0)
	DB	4h
	DW	OFFSET IFREF
	DW	0
	DB	00h
	DB	03Fh  
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	16
	DB	11
	
	DW	05		;ICONE [ OK ]
	DW	066
	DW	355-45
	DB 9 dup (0)
	DB	54h
	DW	OFFSET ICNF
	DW	0
	DB	013d
	DB	028d
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	64
	DB	20

	DW	05		;ICONE [ CANCEL ]
	DW	170
	DW	355-45
	DB 9 dup (0)
	DB	55h
	DW	OFFSET ICNG
	DW	0
	DB	027d
	DB	001d
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	64
	DB	20
	
	DW	0FFh		;Finalizacao
	
CINF:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CLD			;Copia - CANCEL BUFFER
	MOV	SI,OFFSET FADEST;Para restaurar se houver CANCEL
	MOV	CX,OFFSET FADEFIM - OFFSET FADEST
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET PROGRAM
	REP	MOVSB
	
	JCINF:
	MOV	AX,0100h	;Exibe menu: Desenha e inicia interacao
	CALL	AUSB		;Aguarda usuario liberar botoes do mouse
	MOV	SI,OFFSET IFINF
	CALL	MOPC
	
	CMP	AL,55H		;CANCEL
	JNZ	JCINF1
	
	CLD			;Restaura
	MOV	DI,OFFSET FADEST;
	MOV	CX,OFFSET FADEFIM - OFFSET FADEST
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET PROGRAM
	REP	MOVSB
	JMP	JCINF0		;Finaliza

	JCINF1:
	CMP	AL,4d		;F5 - Refresh
	JNZ	JCINF0
	
	MOV	XORC,0
	CALL	PUSHAI		;Inverte AI->AE
	CALL	MAXL
	CALL	POPAE
	CALL	REWRITE
	JMP	JCINF
	
	JCINF0:
	CALL	REWRITE 	;Retira menu
	
	POP	ES		;Finaliza
	POP	DS
	POPA
	RET
	
-------------------------------------------------------------
;Opcoes do mouse
OMINF1: DB	'˛NANOSISTEMAS - Mouse Setupˇ',13,13
	DB	'   Acceleration - for internal driver only',13
	DB	2,36,' å fast',2,17,' slow ç',13
	DB	'   Normal:',2,10,' Select :',13
	DB	13
	DB	'Double Click speed:',2,17,' å fast',2,17,' slow ç',13
	DB	'   Normal:',2,10,' Select :',13
	DB	13
	DB	'Treat skips larger than this as interference:',13
	DB	'   Normal: MAX      Select :',13
	DB	13
	DB	'To Save Config go to System Options',0 
		
OMNOR	DW	1111111111111111b
	DW	1000000000000001b
	DW	1000000001000001b
	DW	1000000001100001b
	DW	1000111111110001b
	DW	1000111111111001b
	DW	1000111111110001b
	DW	1000000001100001b
	DW	1000000001000001b
	DW	1000000000000001b
	DW	1111111111111111b

OMASC:	DB	3 dup (0),0
OMDCL:	DB	3 dup (0),0
	
OMINF:	DW	0FFFFh	;Posicao X (0FFFFh = Centralizado em X)
	DW	0FFFFh	;Posicao Y (0FFFFh = Centralizado em Y)
	DW	400	;Tamanho X 
	DW	260	;Tamanho Y 
	DW	0	;CLICKS:OFF
	
	;TEXTOS 

	DW	01
	DW	20
	DW	16
	DB 8 dup (0)
	DB	0FFh
	DB	1
	DW	OFFSET OMINF1
	DW	0
	DD	0
	DW	0
	
	;BARRS
	DW	07
	DW	199
	DW	76
	DB 9 dup (0)
	DB	98
	DW	OFFSET MNACEL
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	199
	DW	120
	DB 9 dup (0)
	DB	98
	DW	OFFSET MNVDOU
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	DW	07
	DW	199
	DW	164
	DB 9 dup (0)
	DB	128
	DW	OFFSET MNSMAX
	DW	0
	DW	0
	DW	0FFFFh
	DW	0
	
	;CHECKBOXES
	DW	02
	DW	20
	DW	48
	DB 10 dup (0)
	DW	OFFSET MNUACE
	DW	0
	DB	0FFh
	DB	0FFh
	DW	0FFFFh
	DW	0
	
	;BINMPS - ICONES
	DW	05		;ICONE NORMAL / ACELERACAO
	DW	72
	DW	76
	DB 9 dup (0)
	DB	4h
	DW	OFFSET OMNOR
	DW	0
	DB	0FFh
	DB	0FFh
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	16
	DB	11

	DW	05		;ICONE NORMAL / DOUBLECLICK
	DW	72
	DW	121
	DB 9 dup (0)
	DB	5h
	DW	OFFSET OMNOR
	DW	0
	DB	0FFh
	DB	0FFh
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	16
	DB	11
	
	DW	05		;ICONE [ OK ]
	DW	116
	DW	220
	DB 9 dup (0)
	DB	54h
	DW	OFFSET ICNF
	DW	0
	DB	013d
	DB	028d
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	64
	DB	20

	DW	05		;ICONE [ CANCEL ]
	DW	220
	DW	220
	DB 9 dup (0)
	DB	55h
	DW	OFFSET ICNG
	DW	0
	DB	027d
	DB	001d
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	64
	DB	20
	
	DW	0FFh		;Finalizacao
	
OMOUS:	PUSHA
	PUSH	ES
	PUSH	DS
	
	CALL	CFGTMP		;Le configuracao para buffer temporario

	MOV	AX,0100h	;Exibe menu: Desenha e inicia interacao

	;Exibe o menu
	JOMOUS:
	CALL	AUSB		;Aguarda usuario liberar botoes do mouse
	
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET OMINF
	CALL	MOPC
	
	CMP	AL,4h		;Click: Aceleracao normal
	JNZ	JOMOUS0
	MOV	MNACEL,15d
	MOV	AX,0102h
	JMP	JOMOUS
	
	JOMOUS0:
	CMP	AL,5h		;Click: Doubleclick speed normal
	JNZ	JOMOUS1
	MOV	MNVDOU,3
	MOV	AX,0102h
	JMP	JOMOUS
	
	JOMOUS1:
	CMP	AL,54h		;Click: Ok. Passando direto = Cancel ou ESC
	JNZ	JOMOUSF
	
	;Converte string (OMASC) para byte (MNACEL)
	CMP	MNACEL,0	;Nao deixa aceleracao ou doubleclick ser zero
	JNZ	JGCM
	INC	MNACEL
	JGCM:
	CMP	MNVDOU,0
	JNZ	JCGD
	INC	MNVDOU
	JCGD:
	CALL	TMPCFG	;Copia as informacoes do buffer temporario para a memoria do sistema
	
	JOMOUSF:
	CALL	REWRITE ;Retira menu do desktop
	
	POP	DS	;Finaliza rotina
	POP	ES
	POPA
	RET

-------------------------------------------------------------
;Teste da funcao MOPC
MINFM1: DB	'˛NANOSISTEMAS. System Options',0
MINFM2: DB	13
	DB	'Mouse Control',2,23,' Desktop',13
	DB	'   Automatic',2,27,' Full Movement',13
	DB	'   Use MOUSE DRIVER (INT 33h)',2,10,' Image BMP',13
	DB	'   Use HARDWARE PORTS',2,18,' Image Fade',13
	DB	2,39,' Background Color',13
	DB	'Mouse Port',2,29,' Show CD Player',13
	DB	'   COM˛1ˇ/3F8h',2,6,' COM˛2ˇ/2F8h',2,12,' Right Button Moves CD Player',13 
	DB	'   COM˛3ˇ/3E8h',2,6,' COM˛4ˇ/2E8h',2,12,' Do Not Show Mouse Warning Messages',13
	DB	'   AUTODETECT',2,26,' Self check file for virus',13,13,13
	DB	'˛Bˇackground Image',13,13,13
	DB	'    Save System State',13,3,10
	DB	'    Load System State',13,0
	
MSTART: ;Inicio dos bytes a serem transferidos 

	DB OFFSET FULL-OFFSET SAVEBGN dup (0)	;Para completar buffer
;Checkboxes	
MNFULL	DB	0	;FULLMOVEMENT
MNBMPY	DB	0	;IMAGEM BMP
MNSHCD	DB	0	;CD PLAYER
MNBDMC	DB	0	;BOTAO DIREITO MOVE CD PLAYER
MNBANI	DB	0	;MOSTRAR ANIMACAO NO BACKGROUND
MNBACK	DB	0	;SEM IMAGEM DE FUNDO 
MNCMSE	DB	0	;CONTROLE DO MOUSE
MNFDB1	DB	0	;NAO MOSTRAR JANELA DE ERRO DO MOUSE
MINFC1	DB	0	;Porta do mouse. COM: 1,2,3,4, 0=Autodetect
MNVIRU	DB	0	;Verificar virus? 0=Nao
;Textbox
MNBMPN: DB 79 dup (0)	;Path/Filename do arquivo BMP
MNCUST	DB 7 dup (0)	;Custom UART HEX
MNVDOU	DB	0	;Velocidade do doubleclick
MNUACE	DB	0	;Usar aceleracao em leitura direta
MNACEL	DB	0	;Aceleracao do mouse em leitura direta
MNSMAX	DB	0	;Tamanho maximo do salto do cursor

	DB OFFSET SAVEEND-OFFSET SMAX dup (0)	;Para completar buffer
MTHEND: ;Fim dos bytes a serem transferidos

MOFF	EQU	30d	;D.Y.
MOF1	EQU	30d	;D.Y1. Ajuste: Da textbox IMAGEM BMP para baixo

;X:16,Y:16 DECIMAL
BRICO:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000010000000010b
	DW	1000011000000010b
	DW	1000011100000010b
	DW	1000011110000010b
	DW	1000011111000010b
	DW	1000011111100010b
	DW	1000011110000010b
	DW	1000010010000010b
	DW	1000000011000010b
	DW	1000000001000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b

BRIC1:	DW	1111111111111110b
	DW	1100000000000010b
	DW	1100000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000111111100010b
	DW	1000100111100010b
	DW	1000100111100010b
	DW	1000100111100010b
	DW	1000100111100010b
	DW	1000100111100010b
	DW	0111111111111110b


MINFT:	DW	0FFFFh	;Posicao X (0FFFFh = Centralizado em X)
	DW	0FFFFh	;Posicao Y (0FFFFh = Centralizado em Y)
	DW	500	;Tamanho X 
	DW	360	;Tamanho Y 
	DW	0	;CLICKS:OFF
	
	;TEXTOS 
	DW	01
	DW	20
	DW	16
	DB 8 dup (0)
	DB	0FFh
	DB	1
	DW	OFFSET MINFM1
	DW	0
	DD	0
	DW	0	

	DW	01
	DW	20
	DW	40
	DB 8 dup (0)
	DB	0FFh	
	DB	1
	DW	OFFSET MINFM2
	DW	0
	DD	0
	DW	0	
	;END
	
	;BINMPS - ICONES
	DW	05		;ICONE [ OK ]
	DW	150
	DW	320
	DB 9 dup (0)
	DB	54h
	DW	OFFSET ICNF
	DW	0
	DB	013d
	DB	028d
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	64
	DB	20

	DW	05		;ICONE [ CANCEL ]
	DW	265
	DW	320
	DB 9 dup (0)
	DB	55h
	DW	OFFSET ICNG
	DW	0
	DB	027d
	DB	01d
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	64
	DB	20

	DW	05		;ICONE [ BROWSE ]
	DW	20
	DW	147+MOFF+MOF1+30d
	DB 9 dup (0)
	DB	01h
	DW	OFFSET BRICO
	DW	0
	DB	0FFh
	DB	0FFh
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	16
	DB	16

	DW	05		;ICONE [ SAVE CFG ]
	DW	20
	DW	187+MOFF+MOF1+15
	DB 9 dup (0)
	DB	02h		;Codigo de retorno: 2
	DW	OFFSET BRIC1
	DW	0
	DB	0FFh
	DB	0FFh
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	16
	DB	16

	DW	05		;ICONE [ LOAD CFG ]
	DW	20
	DW	217+MOFF+MOF1+10
	DB 9 dup (0)
	DB	03h		;Codigo de retorno: 3
	DW	OFFSET BRIC1
	DW	0
	DB	0FFh
	DB	0FFh
	DB	0FFh;COR B
	DB	0FFh ;COR	F
	DB	16
	DB	16
	;END
	
	;CHECKBOXES
	DW	02		;Fullmovement
	DW	200
	DW	42+MOFF
	DB 10 dup (0)
	DW	OFFSET MNFULL
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	

	DW	06		;Imagem de fundo
	DW	200
	DW	57+MOFF
	DB 8 dup (0)
	DB	0
	DB	9
	DW	OFFSET MNBMPY
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	

	DW	06		;Usar animacao do background
	DW	200
	DW	57+MOFF+15
	DB 8 dup (0)
	DB	0
	DB	9
	DW	OFFSET MNBANI
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	

	DW	06		;Sem imagem de fundo
	DW	200
	DW	57+MOFF+30
	DB 8 dup (0)
	DB	0
	DB	9
	DW	OFFSET MNBACK
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	

	DW	02		;CD PLAYER
	DW	200
	DW	72+MOFF+30
	DB 10 dup (0)
	DW	OFFSET MNSHCD
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	

	DW	02		;BOTAO DIREITO MOVE CD PLAYER
	DW	200
	DW	87+MOFF+30
	DB 10 dup (0)
	DW	OFFSET MNBDMC
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	
	
	DW	02		;Mensagens de erro do mouse
	DW	200
	DW	87+MOFF+45
	DB 10 dup (0)
	DW	OFFSET MNFDB1
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	
	
	DW	02		;Verificar virus
	DW	200

	DW	87+MOFF+45+15
	DB 10 dup (0)
	DW	OFFSET MNVIRU
	DW	0
	DW	0FFFFh
	DW	0FFFFh
	DW	0	
	
	DW	06		;Sistema escolhe entre
	DW	20
	DW	42+MOFF
	DB 8 dup (0)
	DB	1	;Modo 
	DB	00h
	DW	OFFSET MNCMSE
	DW	0
	DW	032ffh
	DW	0FFFFh
	DW	0	
	
	DW	06		;Mouse Driver
	DW	20
	DW	42+MOFF+15d
	DB 8 dup (0)
	DB	1	;Modo 
	DB	01h
	DW	OFFSET MNCMSE
	DW	0
	DW	032ffh
	DW	0FFFFh
	DW	0	
	
	DW	06		;Leitura Direta
	DW	20
	DW	42+MOFF+30d
	DB 8 dup (0)
	DB	1	;Modo 
	DB	02h
	DW	OFFSET MNCMSE
	DW	0
	DW	032ffh
	DW	0FFFFh
	DW	0	
	
	
	DW	06		;Com1
	DW	20
	DW	87+MOFF+MOF1
	DB 8 dup (0)
	DB	1	;Modo 
	DB	01h
	DW	OFFSET MINFC1
	DW	0
	DW	02FFh
	DW	0FFFFh
	DW	0	

	DW	06		;Com3
	DW	20
	DW	102+MOFF+MOF1
	DB 8 dup (0)
	DB	1	;Modo 
	DB	03h
	DW	OFFSET MINFC1
	DW	0
	DW	04FFh

	DW	0FFFFh
	DW	0	
	
	DW	06		;Com2
	DW	95
	DW	87+MOFF+MOF1
	DB 8 dup (0)
	DB	1	;Modo 
	DB	02h
	DW	OFFSET MINFC1
	DW	0
	DW	03FFh
	DW	0FFFFh
	DW	0	

	DW	06		;Com4
	DW	95
	DW	102+MOFF+MOF1
	DB 8 dup (0)
	DB	1	;Modo 
	DB	04h
	DW	OFFSET MINFC1
	DW	0
	DW	05FFh
	DW	0FFFFh
	DW	0	

	DW	06		;Autodetect
	DW	20
	DW	117+MOFF+MOF1
	DB 8 dup (0)
	DB	1	;Modo 
	DB	00h
	DW	OFFSET MINFC1
	DW	0
	DW	03FFh
	DW	0FFFFh
	DW	0	

	DW	06		;Custom
	DW	95
	DW	117+MOFF+MOF1
	DB 8 dup (0)
	DB	1	;Modo 
	DB	05h
	DW	OFFSET MINFC1
	DW	0
	DW	03FFh
	DW	0FFFFh
	DW	0	
	;END
	
	;TEXTBOXES
	DW	03		;Textbox -> BMP de fundo
	DW	41
	DW	150+MOFF+MOF1+30d
	DB 9 dup (0)
	DB	77d
	DW	OFFSET MNBMPN
	DW	0
	DW	030FFh
	DW	0
	DW	0	
	
	DW	03		;Textbox -> Custom: Porta do mouse
	DW	114d
	DW	117+MOFF+MOF1
	DB 9 dup (0)
	DB	6d
	DW	OFFSET MNCUST
	DW	0
	DW	030FFh
	DW	0
	DW	0	
	;END
	
	DW	0FFh
	
MPCTA:	DB	'*.BMP',0
MPCTB:	DB	'MM.CFG',0
MPCTC:	DB	'Ok. Configuration saved on disk',0
MPCTD:	DB	'   Ok. Configuration loaded',0
MPCTE:	DB	'  Error opening file: MM.CFG',0
MPCTF:	DB	'StandBy..',0
MPCTG:	DB	'     File MM.CFG corrupt',0
	
;Subrotina interna
;--------------------------------------------
TXBX:	PUSHA
	PUSH	DS
	PUSH	SI

	MOV	USEF,1		;Usar fonte normal
	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	CX,200d 	;Desenha janela
	MOV	DX,50d
	CALL	NCMS
	
	ADD	AX,18
	ADD	BX,20		;Escreve textos

	MOV	CL,TXTC
	MOV	CH,250
	POP	SI
	POP	DS
	CALL	TEXT
	
	CALL	AUSB
	CALL	MOUSE
	POPA
	RET
	
;Subrotina:
;Copia as informacoes da configuracao do sistema
;para o buffer temporario (CS:MSTART)
CFGTMP: PUSHA
	PUSH	DS
	PUSH	ES
	
	CLD			;Copia dados da memoria do sistema  
	MOV	DX,CS		;para a memoria temporaria da rotina MOPCT
	MOV	ES,DX
	MOV	DS,DX
	MOV	CX,OFFSET MTHEND - OFFSET MSTART
	MOV	DI,OFFSET MSTART
	MOV	SI,OFFSET SAVEBGN
	REP	MOVSB
	
	POP	ES
	POP	DS
	POPA
	RET
	
;Subrotina:
;Copia as informacoes do buffer temporario (CS:MSTART)
;para a memoria do sistema.
TMPCFG: PUSHA
	PUSH	DS
	PUSH	ES
	
	CLD			;Copia dados da memoria temporaria da rotina MOPCT  
	MOV	DX,CS		;para a memoria do sistema
	MOV	ES,DX
	MOV	DS,DX
	MOV	CX,OFFSET MTHEND - OFFSET MSTART
	MOV	SI,OFFSET MSTART
	MOV	DI,OFFSET SAVEBGN
	REP	MOVSB
	
	POP	ES

	POP	DS
	POPA
	RET
	

;Rotina: EXIBE E GERENCIA MENU DE OPCOES DO SISTEMA
;--------------------------------------------
MOPCT:	PUSHA
	CALL	DISJ		;Desmarca icones selecionadas

	CALL	CFGTMP		;Copia configuracao para MSTART
	
	LMPCV0:
	MOV	AX,0100h	;Exibe menu de opcoes 
	PUSH	CS		
	POP	DS
	MOV	SI,OFFSET MINFT
	CALL	MOPC
	;-----------------------

	
	CMP	AL,55h		;Verifica ICONE CANCEL
	JZ	JMPCV3		;Afirmativo, pula, finaliza rotina e nao salva nada
	
	;-----------------------
	CMP	AL,54h		;Verifica ICONE OK
	JNZ	JMPCVO0 	;Afirmativo, salva alteracoes e finaliza rotina (nao pula agora)

	CALL	TMPCFG		;Copia configuracao de MSTART para o sistema

	MOV	SI,OFFSET MPCTF ;Exibe mensagem: AGUARDE
	PUSH	DS
	PUSH	SI

	MOV	USEF,1		;Usar fonte normal
	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	CX,100d 	;Desenha janela
	MOV	DX,40d
	CALL	NCMS
	
	ADD	AX,14
	ADD	BX,31		;Escreve textos
	MOV	CL,TXTC
	MOV	CH,250
	POP	SI
	POP	DS
	CALL	TEXT
		
	;Reinicia parcialmente o sistema
	MOV	DX,UART 
	CALL	POPP		;Restaura configuracao das portas
	CALL	PUSHP		;Salva configuracao da porta do mouse
	CALL	MAXL		;Maximiza limites

	CALL	CSHOW		;Exibe cursor do mouse
	CALL	SEARCH		;Procura pelas janelas ja existentes no disco
	CALL	DALB		;Desaloca BMP anteriormente alocado
	CALL	BMP		;Le o BMP de fundo pra memoria
	MOV	WINM,3		;Marca flag: NAO ATUALIZAR DISCO
	CALL	REWRITE 	;Desenha desktop
	CALL	MCTR		;Define modo de controle do mouse
	POPA
	RET			;Retorna 

	;----------------------------------------------
	JMPCVO0:
	CMP	AL,01h		;Verifica ICONE BROWSE
	JNZ	JMPCV0		;Negativo, pula
	
	CALL	MAXL		;Afirmativo, exibe janela de browse
	CALL	AUSB

	CALL	CHIDE
	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	DX,222
	MOV	CX,220
	CALL	NCMS

	MOV	CX,BX
	MOV	DX,AX
	ADD	CX,30d
	ADD	DX,10d
	
	XOR	AX,AX
	MOV	BH,11111111b	;Nao permitir acesso a diskete nem cdrom
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET MPCTA 
	CALL	BROWSE
	
	TEST	AL,11110000b
	JNZ	JMPCV1	;Saiu com cancel, pula.
	
	PUSH	CS	;Copia novo nome do BMP
	POP	ES
	MOV	DI,OFFSET MNBMPN
	CLD
	;--- LOOP1 ---
	LMPCV1:
	LODSB
	STOSB
	OR	AL,AL
	JNZ	LMPCV1
	;--- END1 ---
	

	JMPCV1:
	JMP	LMPCV0	;Retorna ao menu			
	;----------------------------------------------
		
	JMPCV0:
	CMP	AL,2	;Verifica icone de SAVE
	JNZ	JMPCV2	;Negativo, pula
	
	;Salva configuracao
	PUSHA
	PUSH	DS
	
	MOV	AH,3Ch	;Cria arquivo MM.CFG
	XOR	CX,CX
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MPCTB
	INT	21h
	MOV	BX,AX
	
	MOV	AH,40h	;Grava configuracao atual no arquivo CFG
	MOV	CX,OFFSET SAVEEND - OFFSET SAVEBGN
	MOV	DX,OFFSET MSTART
	INT	21h
	
	XOR	AL,AL
	CALL	CCHK	;Calcula e grava checksum
	
	MOV	AH,3Eh	;Fecha arquivo CFG
	INT	21h
	
	POP	DS	;Finaliza subrotina
	POPA
		
	MOV	SI,OFFSET MPCTC
	CALL	TXBX
	
	JMP	LMPCV0	;Retorna ao menu
	;----------------------------------------------
	
	JMPCV2:
	CMP	AL,3	;Verifica icone de LOAD

	JNZ	JMPCV3	;Negativo, pula

	;Carrega configuracao do usuario para MSTART
	PUSHA
	PUSH	DS
	
	MOV	TEMP,0		;Marca: Arquivo nao encontrado
	MOV	AX,3D00h	;Carrega a configuracao salva (se MM.CFG existir)
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MPCTB
	INT	21h	
	JC	JABG9		;Pula se o arquivo nao existir no diretorio atual
	MOV	BX,AX
	MOV	TEMP,1		;Marca: Checksum invalida

	MOV	AL,1
	CALL	CCHK		;Verifica checksum
	OR	AL,AL
	JNZ	JALOAD0 	;Incorreta, pula.
	
	MOV	TEMP,2		;Marca: Carregada com sucesso
	
	MOV	AX,4200h	;Desloca posicao do arquivo para o inicio
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	
	MOV	AH,3Fh		;Le configuracao e grava na memoria
	MOV	CX,OFFSET SAVEEND - OFFSET SAVEBGN
	MOV	DX,OFFSET MSTART
	INT	21h
	
	JALOAD0:
	MOV	AH,3Eh		;Fecha arquivo CFG
	INT	21h
	
	JABG9:
	POP	DS		;Finaliza subrotina
	POPA
		
	MOV	SI,OFFSET MPCTD ;Marca: CARREGADA COM SUCESSO
	CMP	TEMP,2
	JZ	JMPCV20
	MOV	SI,OFFSET MPCTE ;Marca: ERRO ABRINDO ARQUIVO
	CMP	TEMP,0
	JZ	JMPCV20
	MOV	SI,OFFSET MPCTG ;Marca: CHECKSUM ERROR
	
	JMPCV20:
	CALL	TXBX	;Mostra mensagem
	
	JMP	LMPCV0	;Retorna ao menu
	;-------------------
	
	JMPCV3:
	CALL	REWRITE
	POPA
	RET
	
;-------------------------------------------------------------
; Shows a window with some fields for input from the user
; Acess: CALL MOPC / EXTERN
;
; In:
;     AL       : 0 = Show and allow interaction
;                1 = Only show
;                2 = Don't repaint (only interaction)
;     DS:SI    : M.Info address
; Returns:
;     AL       : Return code (if clicked on an ative icon)
;     CX       : X coordinate of the upper-left corner of the window
;     DX       : Y coordinate of the upper-left corner of the window
;
; NOTE:  When AL = 2 it is assumed that this routine has already
;        been executed with the same arguments but with AL <> 2;
;        otherwise, this routine will not work.
;
;        If you don't want to show the background, call MOPC with the
;        inclusion area minimized.
;	
;        Whenever this routine returns, an inclusion area is adjusted to
;        to the window limits, so it can be found in the next CALL REWRITE.
;        [* Is this correct? Maybe they meant "...it can be removed..." *]
;
;        Whitin M.Info, you can use CLICK2 field to create a routine
;        that would allow the user to move the menu somewhere else in the
;        screen. To do that, adjust CLICK2 to return a specific code.
;        When you get that specific code, update the position of the
;        window accordingly to the movement of the mouse. Repeat until
;        the user releases the mouse button.
;
;        The same moventation described above may be done with a bitmap or 
;        binmap icon.
;
;        Remember that you can get the mouse state anytime by calling
;        the function LTR1, wich will return imediatly with the X and Y
;        coordinates of the mouse and the state of the buttons.
;
;        In the description of the MOPC function, some fields of some
;        functions are described as "Not Used by this Function". These
;        bytes must be zero.
;	
;
; M.Info: Memory buffer wich contains:
;
; PX     : Word - X window coordinate (0FFFFh = Centralized in X)
; PY     : Word - Y window coordinate (0FFFFh = Centralized in Y)
; SX     : Word - Window width
; SY     : Word - Window height
; CLICK1 : Byte - 00 = Clicking outside the window does nothing
;                 XX = Return code, if clicked outside the window
; CLICK2 : Byte - 00 = Clicking the inative areas does nothing
;                 XX = Return code, if clicked in the inative areas
; INF1   : 26 bytes - First field (to build an INF, check the table below)
; INF2   : 26 bytes - Second field
; INF3   : 26 bytes - Third field
; INF4,5,6...
; INFX   : 26 bytes - Last field (OPERATION must be = 0FFFFh)
;
; INF fields:
; Each field has an operation. The operations are:
; NOTE: If SEG = 0, it means that it is the CS segment of Nanosistemas.
;
; --------------
; Operation 01h : Text
;	
; OPER:  BYTE    = 01h
; RESV:  BYTE    : Reserved
; XR:    WORD    : X coordinate of the text relative to the window
;                  (0FFFFh = Centralized)
; YR:    WORD    : Y coordinate of the text relative to the window
; TMP:   8 bytes : Buffer. The routine will use as needed
; COR:   BYTE    : Foreground text color (0FFh = standard, transparent
;                  background
; FONT:  BYTE    : Font (0 = Large, 1 = Small)
; OFS:   WORD    : Offset of the text (ASCIIZ)
; SEG:   WORD    : Segment of the text (ASCIIZ)
; MAX:   BYTE    : Maximum number of chars to be shown (0 = Unlimited)
; RETI:  BYTE    : Use elipsis ('...') as the last char if maximum is
;                  reached (0 = No, 1 = Yes)
; TMP2:  4 bytes : Not used by this function
;
; --------------
; Operation 02h : Checkbox (AND - Check as many as you desire)
; NOTE:  When the checkbox is checked, the byte at SEG:OFS is 1
;        When the checkbox is unchecked, the byte at SEG:OFS is 0
;	
; OPER:  BYTE    = 02h
; RESV:  BYTE    : Reserved
; XR:    WORD    : X coordinate of the checkbox relative to the window
; YR:    WORD    : Y coordinate of the checkbox relative to the window
; TMP:   9 bytes : Buffer. The routine will use as needed
; BANK:  BYTE    : Bank number to be called after clicking the
;                  checkbox (1..10)
; OFS:   WORD    : Byte offset (Used for the binary operation)
; SEG:   WORD    : Byte segment (Used for the binary operation)
; SCAN:  BYTE    : Scan code (HOTKEY) - 0FFh = Don't verify SCANCODE
; ASCII: BYTE    : ASCII code (HOTKEY) - 0FFh = Dont't verify ASCII
; CICOB: BYTE    : Background color of icon (0FFh = Standard)
; CICOF: BYTE    : Foreground color of icon (0FFh = Standard)
; TMP2:  2 bytes : Not used by this function
;
; --------------
; Operation 03h : Textbox
;	
; OPER:  BYTE    = 03h
; RESV:  BYTE    : Reserved
; XR:    WORD    : X coordinate of the textbox relative to the window
; YR:    WORD    : Y coordinate of the textbox relative to the window
; TMP:   8 bytes : Buffer. The routine will use as needed
; CVAL:  BYTE    : Chars are valid (Bit = 1 means yes)
;           (Bits 0, 1 and 2 = 0 or 1 -> All chars are valid)
;           Bit 0 - Algarisms  (ASCII 30h..39h)
;           Bit 1 - Leters     (ASCII 41h..5Ah e 61h..7Ah)
;           Bit 2 - Simbols    (ASCII 21h..2Fh, 3Ah..40h, 5Bh..60h e 7Bh..7Eh)
;           Bit 3 - Convert to lower case (Bit 3 and 4 equals = Don't convert)
;           Bit 4 - Convert to upper case (Bit 3 and 4 equals = Don't convert)
;           Bit 5 - Reserved 
;           Bit 6 - Reserved
;           Bit 7 - Reserved
;           A more advanced selection is possible by using BANK to filter
;           characters before they are written to the string. See more
;           details in the INPT function / DL input.
; CHRS:  BYTE    : Maximum number of characters
; OFS:   WORD    : Buffer offset (ASCIIZ)
; SEG:   WORD    : Buffer segment (ASCIIZ)
; SCAN:  BYTE    : Scan code (HOTKEY) - 0FFh = Don't verify SCANCODE
; ASCII: BYTE    : ASCII code (HOTKEY) - 0FFh = Don't verify ASCII

; BANK:  BYTE    : Bank number (FAR addresses) to be called on each pressed
;                  key (0 ou >10 = Off). See details in INPT function / DL input.
; BANK1: BYTE    : Bank number to be called before the checkbox gets the
;                  focus (before showing the cursor)
; BANK2: BYTE    : Bank number to be called before the checkbox loses the
;                  focus
; TMP2:  1 bytes : Not used by this function
;
; --------------
; Operation 04h : BMP Icon (BITMAP)
;	
; OPER:  BYTE    = 04h
; RESV:  BYTE    : Reserved
; XR:    WORD    : X coordinate of icon relative to the window
;                  (FFFFh = horizontaly centered)
; YR:    WORD    : Y coordinate of icon relative to the window
;                  (FFFFh = verticaly centered)
; TMP:   8 bytes : Buffer. The routine will use as needed
; TIPO:  BYTE    : Type: 0 = Bitmap (show all pixels),
;                        1 = Cursormap (0FFh points = transparent)
; STAT:  BYTE    : State: 0 = Inactive (only draw),
;                         X = Active, X = Return code
; OFS:   WORD    : BMP Buffer offset (FFFF:FFFF = Don't show the image)
; SEG:   WORD    : BMP Buffer segment (FFFF:FFFF = Don't show the image)
; SCAN:  BYTE    : Scan code (HOTKEY) - 0FFh = Don't verify SCANCODE
; ASCII: BYTE    : ASCII Code (HOTKEY) - 0FFh = Don't verify ASCII
; BANK:  BYTE    : Bank number to be called on each event, even if STAT = 0.
;                  (0 = Unactive)
; HXY:   BYTE    : High part of X and Y sizes (4bits HIGH: X, 4bits LOW: Y)
; SX:    BYTE    : X size of icon (low part)
; SY:    BYTE    : Y size of icon (low part)
;
; --------------
; Operation 05h : BINMAP Icon (0/1 monochrome)
;	
; OPER:  BYTE    = 05h
; RESV:  BYTE    : Reserved
; XR:    WORD    : X coordinate relative to the window
;                  (FFFFh = horizontaly centered)
; YR:    WORD    : Y coordinate relative to the window
;                  (FFFFh = verticaly centered)
; TMP:   8 bytes : Buffer. The routine will use as needed
; BANK:  BYTE    : Bank number to be used on each event, even if STAT = 0.
;                  (0 = Unactive)
; STAT:  BYTE    : State: 0 = Inactive (only draw),
;                  X = Active, X = Return code
; OFS:   WORD    : BINMAP buffer offset (FFFF:FFFF = Don't show the image)
; SEG:   WORD    : BINMAP buffer segment (FFFF:FFFF = Don't show the image)
;                  If SEG = 0, OFS has a standard icon number (See standard
;                  icon table)
; SCAN:  BYTE    : Scan code (HOTKEY) - 0FFh = Don't verify SCANCODE
; ASCII: BYTE    : ASCII code (HOTKEY) - 0FFh = Don't verify ASCII
; CICOB: BYTE    : Icon's foreground color (0FFh = Use standard)
; CICOF: BYTE    : Icon's background color (0FFh = Use standard)
; SX:    BYTE    : Icon's width
; SY:    BYTE    : Icon's height
;
; --------------
; Operation 06h : Checkbox (OR - Only one may be choosen)
; NOTE:  If MODO = 0 : Checkbox checked, byte in SEG:OFS = 1
;                    : Checkbox unchecked, byte in SEG:OFS = 0
;                    : Checking one checkbox, all others in the same group
;                      (GRUPO) get unchecked.
;     
;        If MODO = 1 : The checkbox will only be checked when the byte at
;                      SEG:OFS is equal to GRUPO.
;                    : When a checkbox is checked in this mode, the byte at
;                    : SEG:OFS gets equal to GRUPO
;                    : Checking a checkbox, all others that has
;                      SEG:OFS pointing to the same byte will get unchecked.
;	
; OPER:  BYTE    = 06h
; RESV:  BYTE    : Reserved
; XR:    WORD    : X coordinate of icon relative to the window
; YR:    WORD    : Y coordinate of icon relative to the window
; TMP:   8 bytes : Buffer. The routine will use as needed
; MODO:  BYTE    : Mode: 0 = More than one byte, 1 = One byte
; GRUPO: BYTE    : If mode = 0: When this chkbx is checked, all others
;                               will get unchecked
;                : If mode = 1: When this chkbx is checked, GRUPO byte
;                               will be written in the buffer
; OFS:   WORD    : Byte's buffer offset
; SEG:   WORD    : Byte's buffer segment
; SCAN:  BYTE    : Scan code (HOTKEY) - 0FFh = Don't verify SCANCODE
; ASCII: BYTE    : ASCII code (HOTKEY) - 0FFh = Don't verify ASCII
; CICOB: BYTE    : Icon's background color (0FFh = Use standard)
; CICOF: BYTE    : Icon's foreground color (0FFh = Use standard)
; BANK:  BYTE    ; Bank number to be called on each event. (0 = Unactive)
; TMP2:  1 byte  : Not used by this functionn
;
; --------------
; Operation 07h : Horizontal bar with cursor  
;	
; OPER:  BYTE    = 07h
; RESV:  BYTE    : Reserved
; XR:    WORD    : X coordinate of icon relative to the window
;                  (FFFFh = horizontaly centered)
; YR:    WORD    : Y coordinate of icon relative to the window
;                  (FFFFh = verticaly centered)
; TMP:   8 bytes : Buffer. The routine will use as needed
; BANK:  BYTE    : Bank number to be called (CALL FAR) on each cursor movement
; SIZE:  BYTE    : Bar size in pixels (RESL limit is 0..SIZE)
; OFS:   WORD    : Buffer offset of RESL byte (wich has the cursor position)
; SEG:   WORD    : Buffer segment of RESL byte (wich has the cursor position)
; TMP2:  2 bytes : Not used by this function
; CICOB: BYTE    : Icon's background color (0FFh = Use standard)
; CICOF: BYTE    : Icon's foreground color (0FFh = Use standard)
; TMP2:  2 bytes : Not used by this function
;
;        If CSEG:COFF is bigger than zero, 07h function will make a CALL FAR
;        to that address every time that the bar cursor is moved. In that 
;        address there must be a routine that returns with RETF and with
;        ALL registers unchanged.
;

;
; ----------------------
; STANDARD ICONS:
;
; For the 05h function (BINMAP), SEG may be zero and OFS have the number
; of one system standard icon. Anyway, you must define the icon's size
; See the table below:
;
; Number Description     Size (X x Y)
; 00     OK              64x20
; 01     CANCEL          64x20
; 02     RIGHT ARROW     16x11
; 03     MOUSE CURSOR    16x16
; 04     DISKETE         16x16
; 05     LEFT            16x13
; 06     RIGHT           16x13
; 07     UP              16x14
; 08     DOWN            16x14
; 09     DOUBLE UPP      16x14
; 10     DOUBLE DOWN     16x14
; 11     DOUBLE RIGHT    16x14
; 12     X               16x14
; 13     UP              16x14
; 14     DOWN            16x14
; 15     ENTER           16x14
; 16     BOXED X         16x14
; 17     CD PLAYER 1     64x11
; 18     CD PLAYER 2     64x11
; 19     AND CHECKBOX 0  8x8
; 20     AND CHECKBOX 1  8x8
; 21     OR CHECKBOX 0   8x8
; 22     OR CHECKBOX 1   8x8
; 23     F5              16x11    
;

LSTF    EQU     7       ; Last function number

CHKBO0: DB	11111111b
	DB	10000001b
	DB	10000001b
	DB	10000001b
	DB	10000001b
	DB	10000001b
	DB	10000001b
	DB	11111111b
	
CHKBO1: DB	11111111b
	DB	11000011b
	DB	10100101b
	DB	10011001b
	DB	10011001b
	DB	10100101b
	DB	11000011b
	DB	11111111b

CHKBO2: DB	00111100b
	DB	01000010b
	DB	10000001b
	DB	10000001b
	DB	10000001b
	DB	10000001b
	DB	01000010b
	DB	00111100b
	
CHKBO3: DB	00111100b
	DB	01000010b
	DB	10011001b
	DB	10111101b
	DB	10111101b
	DB	10011001b
	DB	01000010b
	DB	00111100b

OPXI	DW	0
OPYI	DW	0
OPXX	DW	0
OPYY	DW	0
OPER	DB	0
OPDE	DB	0
OPRJ	DB	0

OPDS    DW      0       ; DS: Fields' start segment 
OPSI    DW      0       ; SI: Fields' start offset

; INTERNAL SUBROUTINE: Procedes operation 01h
; In: DS:SI : Field address
;     OPER  : 1 = Only show, 0 = Allow interaction
OP001:	PUSHA
	PUSH	DS
	CALL	CHIDE
	MOV	BX,WORD PTR DS:[SI+2]	
        CMP     WORD PTR DS:[SI+2],0FFFFh       ; Check if text must be centered
        JNZ     JOP001A                         ; No, jump
        ; --------- INTERNAL SUBROUTINE: CENTER TEXT 
	PUSH	ES
	LES	DI,DWORD PTR DS:[SI+16]
	
	XOR	AX,AX
	MOV	CX,0FFFFh
	REPNZ	SCASB
	MOV	AX,0FFFFh
        SUB     AX,CX                           ; In AX, text size in characters
        MOV     CX,9                            ; Large font size
	CMP	BYTE PTR DS:[SI+15],0
	JZ	JOP001B

	INC	AX
        MOV     CX,FSIZ                         ; Small font size
	JOP001B:
        MUL     CX                              ; In AX, text width
        SHR     AX,1                            ; In AX, SX / 2
	MOV	BX,OPXX
        SUB     BX,OPXI                         ; In BX, window width
	SHR	BX,1
	SUB	BX,AX
	POP	ES
	;---------------------------------------------
	JOP001A:
	ADD	BX,OPXI
	MOV	AX,OPYI
	ADD	AX,WORD PTR DS:[SI+4]
        MOV     CX,WORD PTR DS:[SI+14]  ; Read text values
	MOV	DL,BYTE PTR DS:[SI+20]
	MOV	DH,BYTE PTR DS:[SI+21]

	
        MOV     WORD PTR DS:[SI+6],BX   ; Write X and Y positions of start of text
	MOV	WORD PTR DS:[SI+8],AX
	
	MOV	RETI,DH
	LDS	SI,DWORD PTR DS:[SI+16]
	
	MOV	USEF,CH
        MOV     CH,DL                   ; CH: Max. of characters
        CMP     CL,0FFh                 ; Adjusts standard color
	JNZ	JOP10
	MOV	CL,TXTC
	JOP10:
        CALL    TEXT                    ; Writes text
	CALL	CSHOW
	POP	DS
	POPA
	RET
	
; INTERNAL SUBROUTINE: Procedes operation 02h
; In: DS:SI : Field address
;     OPER  : 1 = Only show, 0 = Allow interaction
OP002:	PUSHA
	PUSH	DS
	PUSH	ES
	
        MOV     AX,WORD PTR DS:[SI+22]          ; Get choosen color
        CMP     AH,0FFh ; Adjusts standard system colors
	JNZ	JOP20
	MOV	AH,TCIB
	JOP20:
	CMP	AL,0FFh
	JNZ	JOP21
	MOV	AL,TBCR
	JOP21:
	MOV	WORD PTR CS:[OFFSET V7CB],AX

	MOV	BX,OPXI
	MOV	AX,OPYI
	ADD	BX,WORD PTR DS:[SI+2]
        ADD     AX,WORD PTR DS:[SI+4]   ; Calculates X and Y positions
	

        ;MOV    ES,WORD PTR DS:[SI+16]  ; Reads byte's address
	;MOV	DI,WORD PTR DS:[SI+18]
	LES	DI,DWORD PTR DS:[SI+16]
	
        CMP     OPER,1                  ; Verifies if must invert checkbox state
        JZ      JOP002B                 ; No, jump
        XOR     BYTE PTR ES:[DI],1      ; Yes, inverts (0 = 1, 1 = 0)
	
	JOP002B:
        PUSH    SI                      ; Saves DS:SI
	PUSH	DS
	
        MOV     SI,OFFSET CHKBO0        ; Checkbox = 0
        CMP     BYTE PTR ES:[DI],0      ; Verifies if checkbox = 0 or 1
	JZ	JOP002A
        MOV     SI,OFFSET CHKBO1        ; Checkbox = 1
	JOP002A:
	
	PUSH	CS
	POP	DS
	MOV	CX,8
	MOV	DX,CX
	MOV	DI,WORD PTR CS:[OFFSET V7CB]
	CALL	CHIDE
        CALL    BINMAP                  ; Draw the checkbox


	CALL	CSHOW
	

        POP     DS                      ; Restore DS:SI
	POP	SI
	
	PUSH	BX
        MOVZX   BX,BYTE PTR DS:[SI+15]  ; Run bank
	CALL	ABANK
	POP	BX
	
        MOV     WORD PTR DS:[SI+6],BX   ; Save checkbox positions
	MOV	WORD PTR DS:[SI+8],AX
	ADD	AX,8
	ADD	BX,8
	MOV	WORD PTR DS:[SI+10],BX
	MOV	WORD PTR DS:[SI+12],AX
	
        CMP     CS:OPER,1               ; Only drawing?
        JZ      JOP002D                 ; Doesn't wait releasing the mouse
        CALL    AUSB                    ; Wait releasing the mouse
	
	JOP002D:
	POP	ES
	POP	DS
	POPA
	RET
	
; INTERNAL SUBROUTINE: Procedes operation 03h
; In: DS:SI : Field address
;     OPER  : 1 = Only show, 0 = Allow interaction
TABS    DB      0       ; Out: 0 = Click, XX = Scan code of the key which got
                        ;                      out of the function
TABA    DB      0       ; Out: 0 = Click, XX = ASCII code of the key which got
                        ;                      out of the function
TABB    DW      0       ; Out: BX = 0FFFFh : Got out with a keypress,
                        ;           0 : Got out because of a mouse event

OP003:	PUSHA
	PUSH	DS
	CALL	CHIDE
	MOV	TABS,0
	MOV	TABA,0
	
	MOV	BX,OPXI
	MOV	AX,OPYI
	ADD	BX,WORD PTR DS:[SI+2]
        ADD     AX,WORD PTR DS:[SI+4]   ; Calculates X and Y positions

	LES	DI,DWORD PTR DS:[SI+16]
		
	MOV	CH,BYTE PTR DS:[SI+15]
	MOV	CL,OPER
	MOV	DH,BYTE PTR DS:[SI+14]
        MOV     DL,BYTE PTR DS:[SI+22]  ; Banks at DL
	
        PUSH    BX                      ; Access bank before the textbox
	MOVZX	BX,BYTE PTR DS:[SI+23]
	CALL	ABANK
	POP	BX
	
        CALL    INPT                    ; Draw the textbox
	
	MOV	TABB,0
        CMP     BX,0FFFFh               ; Verify the exit key
        JNZ     JOP003B                 ; There was no key, jump
        MOV     TABS,AH                 ; Save key scan code
        MOV     TABA,AL                 ; Save key ASCII code
        MOV     TABB,BX                 ; Save BX at exit
	JOP003B:
	
        PUSH    BX                      ; Access the bank after the textbox
	MOVZX	BX,BYTE PTR DS:[SI+24]
	CALL	ABANK
	POP	BX
	
        CMP     OPER,0                  ; Verify if must update positions in the field
        JZ      JOP003A                 ; No, jump
	CALL	CSHOW
	
	SUB	AX,3
        MOV     WORD PTR DS:[SI+6],BX   ; Yes, update positions in the field
        MOV     WORD PTR DS:[SI+8],AX   ; Y
        MOV     WORD PTR DS:[SI+10],CX  ; XX
        MOV     WORD PTR DS:[SI+12],DX  ; YY
	
	JOP003A:
        POP     DS                      ; Restore registers
        POPA                            ; Returns
	RET

; INTERNAL SUBROUTINE: Procedes operation 04h
; In: DS:SI : Field address
;     OPER  : 1 = Only show, 0 = Allow interaction
OP04B   DB      0       ; Temp
OP004:	PUSHA
	PUSH	DS
	CALL	CHIDE

        MOV     CL,BYTE PTR DS:[SI+24]  ; Icon's width and height at CX and DX
	MOV	DL,BYTE PTR DS:[SI+25]
	MOV	CH,BYTE PTR DS:[SI+23]
	MOV	DH,CH
	SHR	CH,4
	AND	DH,1111b
	
	MOV	AL,BYTE PTR DS:[SI+14]
	MOV	OP04B,AL

        ; X position
        MOV     BX,WORD PTR DS:[SI+2]   ; X
        CMP     BX,0FFFFh               ; Centered

        JNZ     JOP0040                 ; No, jump
        MOV     BX,OPXX                 ; Yes, center X
        SUB     BX,OPXI                 ; BX = (OPSX / 2) - (ICOSX / 2)
	SHR	BX,1
	PUSH	CX
	SHR	CX,1
	SUB	BX,CX
	POP	CX
	DEC	BX
	
        ; Y position
	JOP0040:
        MOV     AX,WORD PTR DS:[SI+4]   ; Y
        CMP     AX,0FFFFh               ; Centerd
        JNZ     JOP0041                 ; No, jump
        MOV     AX,OPYY                 ; Yes, center Y
        SUB     AX,OPYI                 ; AX = (OPSY / 2) - (ICOSY / 2)
	SHR	AX,1
	PUSH	DX
	SHR	DX,1
	SUB	AX,DX
	POP	DX
	DEC	AX
	
	JOP0041:
	
	ADD	BX,OPXI
	ADD	AX,OPYI
	
	PUSH	DS
	PUSH	SI
	
        CMP     DWORD PTR DS:[SI+16],0FFFFFFFFh ; Verify if must draw the image
        JZ      JOP004NTI                       ; No, jump
	
	LDS	SI,DWORD PTR DS:[SI+16]

        CMP     OP04B,0                 ; Verify if must use BITMAP or CRMAP
	JZ	JOP004BTM		
        CALL    CRSMAP                  ; Draw CURSORMAP
	JMP	JOP004NTI
	JOP004BTM:
        CALL    BITMAP                  ; Draw BITMAP
	JOP004NTI:
	
	POP	SI
	POP	DS
        CMP     OPER,0                  ; Verify if must update positions in the field
        JZ      JOP004A                 ; No, jump
	CALL	CSHOW

        MOV     WORD PTR DS:[SI+6],BX   ; Yes, update positions in the field
	MOV	WORD PTR DS:[SI+8],AX
	ADD	AX,DX
	ADD	BX,CX
	MOV	WORD PTR DS:[SI+10],BX
	MOV	WORD PTR DS:[SI+12],AX

        PUSH    BX                      ; Access bank
	MOVZX	BX,BYTE PTR DS:[SI+22]
	CALL	ABANK
	POP	BX
	
	JOP004A:
        POP     DS                      ; Restore registers
        POPA                            ; Returns
	RET

; INTERNA SUBROUTINE: Procedes operation 05h
; In: DS:SI : Field address
;     OPER  : 1 = Only show, 0 = Allow interaction

; Table containing standard system icons addresses
ICOSIS: DW	OFFSET ICNF
	DW	OFFSET ICNG
	DW	OFFSET OMNOR
	DW	OFFSET BRICO
	DW	OFFSET BRIC1
	DW	OFFSET LICO
	DW	OFFSET RICO
	DW	OFFSET SCIA
	DW	OFFSET SCIB
	DW	OFFSET SCIC
	DW	OFFSET SCID
	DW	OFFSET SCIJ
	DW	OFFSET SCIH
	DW	OFFSET SCIF
	DW	OFFSET SCIE
	DW	OFFSET SCIG
	DW	OFFSET SCIK
	DW	OFFSET ICB1
	DW	OFFSET ICB2
	DW	OFFSET CHKBO0
	DW	OFFSET CHKBO1
	DW	OFFSET CHKBO2
	DW	OFFSET CHKBO3
	DW	OFFSET IFREF
	DW	OFFSET FAILI

; Start of the routine
OP005:	PUSHA
	PUSH	DS
	
        MOV     AX,WORD PTR DS:[SI+22]          ; Get choosen color
        CMP     AH,0FFh ; Adjust standard system colors
        JNZ     JOP50
	MOV	AH,TCIB
	JOP50:
	CMP	AL,0FFh
	JNZ	JOP51
	MOV	AL,TBCR
	JOP51:
	MOV	DI,AX
	
	CALL	CHIDE
	
        MOVZX   CX,BYTE PTR DS:[SI+24]  ; Icon's width and height at CX and DX
	MOVZX	DX,BYTE PTR DS:[SI+25]
        ; X position
        MOV     BX,WORD PTR DS:[SI+2]   ; X

        CMP     BX,0FFFFh               ; Centered
        JNZ     JOP0050                 ; No, jump
        MOV     BX,OPXX                 ; Yes, center X
        SUB     BX,OPXI                 ; BX = (OPSX / 2) - (ICOSX / 2)
	SHR	BX,1
	PUSH	CX
	SHR	CX,1
	SUB	BX,CX
	POP	CX
	DEC	BX
	
        ; Y position
	JOP0050:
        MOV     AX,WORD PTR DS:[SI+4]   ; Y
        CMP     AX,0FFFFh               ; Centered
        JNZ     JOP0051                 ; No, jump
        MOV     AX,OPYY                 ; Yes, center Y
        SUB     AX,OPYI                 ; AX = (OPSY / 2) - (ICOSY / 2)
	SHR	AX,1
	PUSH	DX
	SHR	DX,1
	SUB	AX,DX
	POP	DX
	DEC	AX
	
	JOP0051:
	PUSH	SI
	PUSH	DS
	
	ADD	BX,OPXI
	ADD	AX,OPYI
	
        CMP     DWORD PTR DS:[SI+16],0FFFFFFFFh ; Verify if must draw the image
        JZ      JOP005NTI                       ; No, jump
	
	LDS	SI,DWORD PTR DS:[SI+16]

        PUSH    BX                 ; If DS = CS and SI < 30d, adjust standard icon
	PUSH	AX
	MOV	BX,CS
	MOV	AX,DS
	CMP	BX,AX
	JNZ	JOP005NTJ
	CMP	SI,24d
	JA	JOP005NTJ
	SHL	SI,1
	MOV	SI,WORD PTR DS:[OFFSET ICOSIS+SI]
	JOP005NTJ:
	POP	AX
	POP	BX
			
        CALL    BINMAP                  ; Draw BINMAP
	JOP005NTI:
	
	POP	DS
	POP	SI
	
        CMP     OPER,0                  ; Verify if must update positions in the field
        JZ      JOP005A                 ; No, jump
	CALL	CSHOW
	
        MOV     WORD PTR DS:[SI+6],BX   ; Yes, update positions in the field
	MOV	WORD PTR DS:[SI+8],AX
	ADD	AX,DX
	ADD	BX,CX
	MOV	WORD PTR DS:[SI+10],BX
	MOV	WORD PTR DS:[SI+12],AX
	
	JOP005A:
        POP     DS                      ; Restore registers
        POPA                            ; Returns
	RET

; INTERNAL SUBROUTINE: Procedes operation 06h
; In: DS:SI : Field address
;     OPER  : 1 = Only show, 0 = Allow interaction
OP006:	PUSHA
	PUSH	DS
	PUSH	ES
	
        MOV     AX,WORD PTR DS:[SI+22]          ; Get choosen color
        CMP     AH,0FFh ; Adjust system standard colors
	JNZ	JOP60
	MOV	AH,TCIB
	JOP60:
	CMP	AL,0FFh
	JNZ	JOP61
	MOV	AL,TBCR
	JOP61:
        MOV     WORD PTR CS:[OFFSET V7CB],AX    ; Save choosen color
	
        PUSH    DS                      ; Look for other checkboxes from the
        PUSHA                           ; same group, to uncheck them
        CMP     BYTE PTR DS:[SI+14],1   ; Verify if is MODO 1 (mode 1)
        JZ      JOP0060                 ; Yes, jump (won't touch other checkboxes)
        CMP     OPER,1                  ; Only draw?
        JZ      JOP0060                 ; Don't uncheck checkboxes
        MOV     AL,BYTE PTR DS:[SI+15]  ; Checkbox group number at AL
	MOV	DS,OPDS
	MOV	SI,OPSI
	SUB	SI,26
	;---- LOOP1 ----
	LOP0060:
	ADD	SI,26
	CMP	BYTE PTR DS:[SI],LSTF	
        JA      JOP0060                 ; If finished with all the fields, jump
        CMP     BYTE PTR DS:[SI],6d     ; Verify if is a checkbox
        JNZ     LOP0060                 ; If not a checkbox, return to the loop
        CMP     AL,BYTE PTR DS:[SI+15]  ; Verify if it is from the same group
        JNZ     LOP0060                 ; No, jump. Return to the loop
	LES	DI,DWORD PTR DS:[SI+16]
	
	MOV	BYTE PTR ES:[DI],0
        JMP     LOP0060                 ; And return to the loop
	;---- END1 ----
	JOP0060:
	POPA
	POP	DS
	
	MOV	BX,OPXI
	MOV	AX,OPYI
	ADD	BX,WORD PTR DS:[SI+2]
        ADD     AX,WORD PTR DS:[SI+4]   ; Calculate X and Y positions
	LES	DI,DWORD PTR DS:[SI+16]
	
        CMP     OPER,1                  ; Verify if must check this checkbox
        JZ      JOP006B                 ; No, jump
	
        MOV     BYTE PTR ES:[DI],1      ; Check checkbox
        CMP     BYTE PTR DS:[SI+14],1   ; Verify if must set this checkbox by
                                        ; writing the group (GRUPO) number
        JNZ     JOP006B                 ; No, jump
	PUSH	AX
        MOV     AL,BYTE PTR DS:[SI+15]  ; Yes, get group number from AL
        MOV     BYTE PTR ES:[DI],AL     ; and writes to SEG:OFS
	POP	AX
	
	JOP006B:
        PUSH    SI                      ; Save DS:SI
	PUSH	DS
	
        CMP     BYTE PTR DS:[SI+14],1   ; Verify this checkbox marking mode (MODO 0 or 1)
        JZ      JOP006B0                ; MODO = 1? Jump
	
        ; MODO 0 goes on:
        MOV     SI,OFFSET CHKBO2        ; Checkbox = 0
        CMP     BYTE PTR ES:[DI],0      ; Verify if checkbox = 0 or 1
	JZ	JOP006B1
        MOV     SI,OFFSET CHKBO3        ; Checkbox = 1
	JMP	JOP006B1
	
	JOP006B0:	
        ; MODO 1 goes on:
	PUSH	AX
        MOV     AL,BYTE PTR DS:[SI+15]  ; Group number at AL
        MOV     SI,OFFSET CHKBO2        ; Checkbox = 0
        CMP     AL,BYTE PTR ES:[DI]     ; Verify if ES:DI is equal to group
	POP	AX
        JNZ     JOP006B1                ; No, jump
        MOV     SI,OFFSET CHKBO3        ; Checkbox = 1
	
	JOP006B1:
	
	PUSH	CS
	POP	DS
	MOV	CX,8
	MOV	DX,CX
	MOV	DI,WORD PTR CS:[OFFSET V7CB]
	CALL	CHIDE
        CALL    BINMAP                  ; Draw the checkbox
	CALL	CSHOW
	
        POP     DS                      ; Restore DS:SI
	POP	SI
	
        PUSH    BX                      ; Run BX bank
        MOVZX   BX,BYTE PTR DS:[SI+24]  ; If 0 < BX < 13
        CALL    ABANK                   ; Access bank
	POP	BX
	
        MOV     WORD PTR DS:[SI+6],BX   ; Save checkbox positions
	MOV	WORD PTR DS:[SI+8],AX
	ADD	AX,8
	ADD	BX,8
	MOV	WORD PTR DS:[SI+10],BX
	MOV	WORD PTR DS:[SI+12],AX
	
        CMP     CS:OPER,1               ; Only drawing? 
        JZ      JOP006D                 ; Don't wait releasing the mouse
        CALL    AUSB                    ; Wait releasing the mouse
	
	JOP006D:
	POP	ES
	POP	DS
	POPA
	RET
	
; INTERNAL SUBROUTINE: Procedes operation 07h
; In: DS:SI : Field address
;     OPER  : 1 = Only show, 0 = Allow interaction

LICO:	DW	0111111111111110b
	DW	0100000000000010b
	DW	0100000001000010b
	DW	0100000011000010b
	DW	0100000111000010b
	DW	0100001111000010b
	DW	0100011111000010b
	DW	0100001111000010b
	DW	0100000111000010b
	DW	0100000011000010b
	DW	0100000001000010b
	DW	0100000000000010b
	DW	0111111111111110b

RICO:	DW	0111111111111110b
	DW	0100000000000010b
	DW	0100001000000010b
	DW	0100001100000010b
	DW	0100001110000010b
	DW	0100001111000010b
	DW	0100001111100010b
	DW	0100001111000010b
	DW	0100001110000010b
	DW	0100001100000010b
	DW	0100001000000010b
	DW	0100000000000010b
	DW	0111111111111110b

CICO:	DW	1111111111111111b
	DW	1000000000000011b
	DW	1000000000000011b
	DW	1000001010000011b
	DW	1000011011000011b
	DW	1000111011100011b
	DW	1000111011100011b
	DW	1000011011000011b
	DW	1000001010000011b
	DW	1000000000000011b
	DW	1000000000000011b
	DW	1111111111111111b
	DW	1111111111111111b

V7XR	DW	0
V7YR	DW	0
V7PC	DB	0
V7XX	DW	0
CFR7    DD      0       ; End.CALL FAR
OLX7    DW      0       ; X and Y previous positions
OLY7	DW	0
ALT7    DB      0       ; Changes ? 1 = yes
V7CB	DB	0
V7CF    DB      0       ; Foreground/background color

OP007:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CALL	CHIDE
	
	MOV	OLX7,0
	MOV	AX,WORD PTR DS:[SI+2]
	MOV	V7XR,AX
	MOV	AX,WORD PTR DS:[SI+4]
	MOV	V7YR,AX
	MOV	AL,BYTE PTR DS:[SI+15]
	MOV	V7PC,AL

	MOV	AX,WORD PTR DS:[SI+22]
	
        CMP     AH,0FFh ; Adjust system standard colors
	JNZ	JOP70
	MOV	AH,TCIB
	JOP70:
	CMP	AL,0FFh
	JNZ	JOP71
	MOV	AL,TBCR
	JOP71:
	
	MOV	WORD PTR CS:[OFFSET V7CB],AX
	
	MOV	CFR7,0
        MOVZX   BX,BYTE PTR DS:[SI+14]  ; Write bank address
	OR	BX,BX
	JZ	JOP007BNK
	DEC	BX
	SHL	BX,2
	MOV	EAX,DWORD PTR CS:[OFFSET BANKS+BX]
	MOV	CFR7,EAX
	JOP007BNK:
	
	PUSH	DS
	PUSH	SI

	MOV	DI,WORD PTR CS:[OFFSET V7CB]
        MOV     AX,OPYI                 ; Draw DIR/ESQ (right/left) icons
	MOV	BX,OPXI
	ADD	BX,V7XR
	ADD	AX,V7YR
	MOV	CX,16d
	MOV	DX,13d
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET LICO
	CALL	BINMAP
	
	MOVZX	BX,V7PC
	ADD	BX,V7XR
	ADD	BX,OPXI
	ADD	BX,18d+16d
	MOV	V7XX,BX
	SUB	V7XX,CX
	MOV	SI,OFFSET RICO
	CALL	BINMAP
	
        MOV     BX,V7XR                 ; Draw rectangle
	ADD	BX,OPXI
	ADD	BX,18d
	INC	AX
	MOVZX	CX,V7PC
	ADD	CX,15d
	MOVZX	SI,V7CF
	CALL	RECT
	
	POP	SI
	POP	DS
	PUSH	DS
	PUSH	SI
	
        ; Verify if must move the cursor
	LES	DI,DWORD PTR DS:[SI+16]
	CMP	OPER,1
        JZ      JOP0070         ; No, jump
	
	JOP0074:
        CALL    LTR1            ; Get mouse position
	
        TEST    BX,11b          ; Verify if mouse button is pressed
        JZ      JOP0075         ; No, jump and exit from the routine

        MOV     ALT7,0          ; Set that there were no changes
        CMP     CX,OLX7         ; Verify if there were changes in mouse position
	JNZ	JOP00742
	CMP	DX,OLY7
        JZ      JOP00743        ; No, jump without setting anything
	JOP00742:
        MOV     OLX7,CX         ; Save actual position
	MOV	OLY7,DX
        MOV     ALT7,1          ; Set that there were changes
	JOP00743:

	LES	DI,DWORD PTR DS:[SI+16]
	
        MOV     BL,V7PC                 ; Verify if byte is out of limits
	CMP	BYTE PTR ES:[DI],BL
        JNA     JOP00741                ; No, jump
        MOV     BYTE PTR ES:[DI],BL     ; Yes, adjust the byte
	JOP00741:

        MOV     BX,V7XR         ; Verify if the mouse is inside the bar
	ADD	BX,OPXI
	CMP	CX,BX
        JA      JOP0070B                ; Yes, jump
        MOV     BYTE PTR ES:[DI],0      ; No, zeroes cursor position
        JMP     JOP0070                 ; Jump over pos.cur adjustment routines
	JOP0070B:
	
	MOV	BX,V7XX
	ADD	BX,17
	CMP	CX,BX		
	JNA	JOP0070C
	
	ADD	BX,17
	CMP	CX,BX
	JA	JOP007CA
	MOV	BL,V7PC
	CMP	BYTE PTR ES:[DI],BL
	JZ	JOP0070
	INC	BYTE PTR ES:[DI]
	CALL	SDLAY
	JMP	JOP0070
	JOP007CA:
	
	MOV	BL,V7PC
	MOV	BYTE PTR ES:[DI],BL
	JMP	JOP0070
	JOP0070C:
	
	SUB	CX,OPXI
	SUB	CX,V7XR
	
        CMP     CX,17d          ; Verify if clicked on ONE DOWN
        JA      JOP0071         ; No, jump
	CMP	BYTE PTR ES:[DI],0
	JZ	JOP0070
	DEC	BYTE PTR ES:[DI]
	CALL	SDLAY
	JMP	JOP0070
	JOP0071:
	
	SUB	CX,24d

	JNC	$+4
	XOR	CX,CX
	
	MOVZX	BX,V7PC
	CMP	CX,BX
	JNA	JOP0070A
	MOV	CL,V7PC
	JOP0070A:
	MOV	BYTE PTR ES:[DI],CL

	JOP0070:
        MOV     BL,BYTE PTR ES:[DI]     ; Don't allow cursor to get out of X limit
	CMP	BL,V7PC
	JNA	JOP0070B0
	MOV	BL,V7PC
	MOV	BYTE PTR ES:[DI],BL
	JOP0070B0:

        ; Erase previous/draw new cursor
	PUSH	SI
	PUSH	DS
	
        CMP     CFR7,0          ; Verify if must execute CALL FAR
        JZ      JOP00701        ; No, jump
        CMP     ALT7,1          ; Verify if there were changes in cursor position
        JNZ     JOP00701        ; No, jump
        CALL    CFR7            ; Execute CALL FAR
	JOP00701:
	
	LES	DI,DWORD PTR DS:[SI+16]
	
	MOVZX	BX,BYTE PTR ES:[DI]
	ADD	BX,V7XR
	ADD	BX,OPXI
	ADD	BX,17d
	DEC	AX
	MOV	DI,WORD PTR CS:[OFFSET V7CB]
	MOV	CX,16
	MOV	DX,13
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET CICO
	CALL	BINMAP
	
	INC	BX
	MOV	AEX,BX
	MOV	AEXX,BX

	ADD	AEXX,15d
	MOV	AEY,1
	MOV	AEYY,0F000h	
	
	MOV	BX,V7XR
	ADD	BX,OPXI
	ADD	BX,19d
	INC	AX	
	DEC	DX
	DEC	DX

	MOVZX	CX,V7PC
	ADD	CX,14d
	MOVZX	SI,TXBF
	CALL	RECF

	POP	DS
	POP	SI
	CALL	MAXL
        CALL    AUSD            ; Wait until releasing right button
	CMP	OPER,1
	JNZ	JOP0074
	
	JOP0075:
	POP	SI
	POP	DS

        CMP     OPER,1          ; Verify if must update XYXXYY positions
        JNZ     JOP0073         ; No, jump

	MOV	AX,OPYI
	ADD	AX,V7YR
	MOV	BX,OPXI
	ADD	BX,V7XR
        MOV     WORD PTR DS:[SI+6],BX   ; Save bar positions
	MOV	WORD PTR DS:[SI+8],AX
	ADD	AX,13
	MOVZX	BX,V7PC
	ADD	BX,OPXI
	ADD	BX,V7XR
	ADD	BX,36+15
	MOV	WORD PTR DS:[SI+10],BX
	MOV	WORD PTR DS:[SI+12],AX
	
	JOP0073:

	CALL	CSHOW

	POP	ES
	POP	DS
	POPA
	RET

; Internal subroutine. Updates the fields in the screen
; In: DS:SI : First field address
; Returns: Generic use registers trashed
; ----------------------------------------------------------
;
MLSI    DW      0       ; SI of last useful field (containing valid function)

MPCA:	PUSHA
	PUSH	ES
	PUSH	DS
	PUSH	SI
        MOV     OPER,1                  ; Mark: Only draw
        ; ----- LOOP1 --------
	LOP0:
        CALL    SECR                    ; Safety. Enables ALT+X
	
        CMP     WORD PTR DS:[SI+18],1   ; Verify if must replace 1 with DS
                                        ; (CS of executer [* "executivo" *])
        JNZ     JLOP3B                  ; No, jump
        MOV     WORD PTR DS:[SI+18],DS  ; Yes, replace
	JLOP3B:
        CMP     WORD PTR DS:[SI+18],0   ; Verify if must replace 0 with CS
                                        ; in the current field
        JNZ     JLOP3                   ; No, jump
        MOV     WORD PTR DS:[SI+18],CS  ; Yes, replace 0 with CS
	
	JLOP3:
        CMP     BYTE PTR DS:[SI],01h    ; Verify if is function 01h
        JNZ     JLOP0                   ; No, jump
        CALL    OP001                   ; Yes, access function
        JMP     JLOPX                   ; Jump to the end of the loop
		

	JLOP0:
        CMP     BYTE PTR DS:[SI],02h    ; Verify if is function 02h
        JNZ     JLOP1                   ; No, jump
        CALL    OP002                   ; Yes, access function
        JMP     JLOPX                   ; Jump to the end of the loop
	
	JLOP1:
        CMP     BYTE PTR DS:[SI],03h    ; Verify if is function 03h
        JNZ     JLOP2                   ; No, jump
        CALL    OP003                   ; Yes, access function
        JMP     JLOPX                   ; Jump to the end of the loop
	
	JLOP2:
        CMP     BYTE PTR DS:[SI],04h    ; Verify if is function 04h
        JNZ     JLOP4                   ; No, jump
        CALL    OP004                   ; Yes, access function
        JMP     JLOPX                   ; Jump to the end of the loop
	
	JLOP4:

        CMP     BYTE PTR DS:[SI],05h    ; Verify if is function 05h

        JNZ     JLOP5                   ; No, jump
        CALL    OP005                   ; Yes, access function
        JMP     JLOPX                   ; Jump to the end of the loop
	
	JLOP5:
        CMP     BYTE PTR DS:[SI],06h    ; Verify if is function 06h
        JNZ     JLOP6                   ; No, jump
        CALL    OP006                   ; Yes, access function
        JMP     JLOPX                   ; Jump to the end of the loop
	
	JLOP6:
        CMP     BYTE PTR DS:[SI],07h    ; Verify if is function 07h
        JNZ     JLOP6B                  ; No, jump
        CALL    OP007                   ; Yes, access function
        JMP     JLOPX                   ; Jump to the end of the loop
	
	JLOP6B:
        CMP     BYTE PTR DS:[SI],0      ; Verify if is function 00 : NOP
        JNZ     JLOP7                   ; No, jump
        JMP     JLOPX                   ; Jump to the end of the loop
	
	JLOP7:
        JMP     JLOPF                   ; Invalid function, jump
                                        ; Finishes the routine
        JLOPX:                          ; *************************
        MOV     MLSI,SI                 ; Saves SI of last useful field
                                        ; (used in LTABS0)
        ADD     SI,26d                  ; OOOOOOOOOOOOO AQUII! E O SEGMENTO???
        JMP     LOP0                    ; Restart the LOOP
        ; ----- END1 --------
	JLOPF:
	POP	SI
	POP	DS
	POP	ES
	POPA
	RET

; --------------------------
; Start of main routine
MOPC:	PUSHA
	CALL	CHIDE
	MOV	OPDE,AL
	MOV	OPRJ,AH
	MOV	BX,WORD PTR DS:[SI]
	MOV	AX,WORD PTR DS:[SI+2]
        MOV     CX,WORD PTR DS:[SI+4]   ; Get window size
	MOV	DX,WORD PTR DS:[SI+6]
	MOV	OPXX,CX
	MOV	OPYY,DX

        CMP     OPDE,2                  ; Must draw the window (update screen)?
        JNZ     JLOPF1                  ; Yes, jump
	
	CMP	BX,0FFFFh
	JNZ	JLOPF3
	PUSH	DI
        MOV     BX,CS:RX                ; Center window (X)
	SHR	BX,1		
	MOV	DI,CX
	SHR	DI,1
	SUB	BX,DI
	POP	DI
	JLOPF3:

	CMP	AX,0FFFFh
	JNZ	JLOPF2
	PUSH	DI
        MOV     AX,CS:RY                ; Center window (Y)
	SHR	AX,1
	MOV	DI,DX
	SHR	DI,1
	SUB	AX,DI
	POP	DI
	JMP	JLOPF2
	

	JLOPF1:
        CALL    NCMS                    ; Draw window
	JLOPF2:
	
        MOV     OPXI,BX                 ; Save window positions
	MOV	OPYI,AX
	ADD	OPXX,BX
	ADD	OPYY,AX
	CALL	CSHOW

        ADD     SI,10                   ; Read each one of the fields
	MOV	OPDS,DS
	MOV	OPSI,SI
        CALL    MPCA                    ; Update fields in the screen

        CMP     OPDE,1                  ; Verify if must only update the screen
        JZ      JMPTF                   ; Yes, jump and finished the routine

        MOV     OPER,0                  ; No, start interaction with the user
	
        PUSH    SI                      ; Searches for a textbox (to start
                                        ; with the curson in it)
        ; ---- LOOP1 -----
	LTXBI0:
	CMP	BYTE PTR DS:[SI],03h
        JZ      JLP1                    ; Jump if found it
	CMP	BYTE PTR DS:[SI],LSTF
        JA      JTXBI1                  ; Jump if got to the end of the fields
                                        ; without finding the textbox
	ADD	SI,26d
        JMP     LTXBI0                  ; Return to the LOOP
        ; ---- END1 -----
	JTXBI1:
	POP	SI	
	
        ; ---- LOOP1 -----               *** START OF LOOP/INTERACTION WITH THE USER

	LOP1:
	PUSH	DS
	PUSH	SI
	CALL	MOUSE
	POP	SI
	POP	DS
	
	JMOPCC0:
        CMP     CX,OPXI                 ; Verify if clicked outside MOPC menu
        JNA     JOP1A                   ; Jump if did
	CMP	CX,OPXX
	JA	JOP1A
	CMP	DX,OPYI
	JNA	JOP1A
	CMP	DX,OPYY
	JA	JOP1A
	JMP	JOP1B
        JOP1A:                          ; Control clicks outside of the menu
        CMP     BYTE PTR DS:[SI-2],00   ; Verify if must quit execution
        JZ      JOP1B                   ; No, jump
	POPA
        MOV     AL,BYTE PTR DS:[SI-2]   ; Yes, put return code in AL
	PUSHA			
        JMP     JMOPTF                  ; Finishes execution
	
	JOP1B:
	PUSH	SI
        ; ----- LOOP2 ---------
	LOP2:	
        CMP     BYTE PTR DS:[SI],LSTF   ; Verify if already verified all the fields
        JA      JLP2F                   ; Yes, jump
        CMP     BYTE PTR DS:[SI],01h    ; Verify if if function 1 or 0 (which has no interaction)
        JBE     JLOP2F                  ; Yes, jump
	
        TEST    BX,00000011b            ; Verify if was mouse click
        JNZ     JLOP21                  ; Yes, don't check the keyboard
	
        CMP     WORD PTR DS:[SI+20],AX  ; Verify pressed key
	JZ	JLOP20
	
	CMP	BYTE PTR DS:[SI+20],AL
	JNZ	JMOPCA
	CMP	BYTE PTR DS:[SI+21],0FFh
	JZ	JLOP20
	JMOPCA:
	CMP	BYTE PTR DS:[SI+21],AH
	JNZ	JMOPCB
	CMP	BYTE PTR DS:[SI+20],0FFh
	JZ	JLOP20
	JMOPCB:
	
        JLOP21:                         ; Verify mouse position
        TEST    MOBX,11b                ; Verify if exited with CLICK
        JZ      JLOP2F                  ; No, don't check position
        CMP     CX,WORD PTR DS:[SI+6]   ; Verify which field was clicked
        JNA     JLOP2F
	CMP	DX,WORD PTR DS:[SI+8]
	JNA	JLOP2F	
	CMP	CX,WORD PTR DS:[SI+10]
	JA	JLOP2F
	CMP	DX,WORD PTR DS:[SI+12]
        JA      JLOP2F                  ; If doesn't jump, then DS:SI has
                                        ; the clicked field

	JLOP20:
        CMP     BYTE PTR DS:[SI],01h    ; Verify if is function 01h
        JNZ     JLP0                    ; No, jump
        CALL    OP001                   ; Yes, access function
	JLP0:
        CMP     BYTE PTR DS:[SI],02h    ; Verify if is function 02h
        JNZ     JLP1                    ; No, jump
        CALL    OP002                   ; Yes, access function

	JLP1:

        CMP     BYTE PTR DS:[SI],03h    ; Verify if is function 03h
        JNZ     JLP2                    ; No, jump
	JTABS0:
        CALL    OP003                   ; Yes, access function
        CMP     TABB,0FFFFh             ; Verify the exit with the pressed key
        JNZ     JLP2                    ; No, jump
	
        CMP     TABS,80d                ; DOWN - Equal to TAB
	JNZ	JNI0D
	MOV	TABS,15
	MOV	TABA,09
	JMP	JNI0E
	JNI0D:
        CMP     TABS,72d                ; UP - Equal to SHIFT TAB
	JNZ	JNI0E
	MOV	TABS,15
	MOV	TABA,0
	JNI0E:
	
        CMP     TABS,15d                ; Verify if exited with TAB
        JZ      JLP1B                   ; Yes, jump
	POP	SI
	PUSH	SI
        MOV     AH,TABS                 ; If exiting with any other key, put it
        MOV     AL,TABA                 ; in AH and AL
        XOR     BX,BX                   ; Set that it was not a mouse click
        MOV     MOBX,0                  ; Set in MOUSE function too
        JMP     LOP2                    ; And restart LOOP scaning the fields
	JLP1B:
        ; ---- LOOP1 ----               ; Yes, give control to the next textbox
        LTABS0:                         ; Search for the next textbox
        CMP     TABA,0                  ; Verify if is TAB or SHIFT TAB
	JZ	JLTABS2
        ADD     SI,26d                  ; TAB goes to the next textbox
	JMP	JLTABS3
	JLTABS2:	
        SUB     SI,26d                  ; SHIFT TAB goes to the previous textbox
        CMP     SI,OPSI                 ; Verify if is at the start of the fields
        JAE     JLTABS3                 ; No, jump
        MOV     SI,MLSI                 ; SI = SI of last field
	JLTABS3:
	
	CMP	BYTE PTR DS:[SI],03h
        JZ      JTABS0                  ; Jump if found it
        CMP     BYTE PTR DS:[SI],LSTF   ; Verify if found an invalid function (or finalization code)
        JNA     LTABS0                  ; No, jump
        POP     SI                      ; Yes, restores SI
	PUSH	SI
        JMP     LTABS0                  ; And restarts searching from the beginning of textbox
        ; ---- END1 ----
	
	JLP2:
        CMP     BYTE PTR DS:[SI],04h    ; Verify if is function 04h
        JNZ     JLP3                    ; No, jump
	PUSH	BX
        MOVZX   BX,BYTE PTR DS:[SI+22]  ; Access the bank
	CALL	ABANK
	POP	BX
        CMP     BYTE PTR DS:[SI+15],0   ; Yes, verify if function is active
        JZ      JLP3                    ; No, jump (don't do anything)
	MOV	TEMP,SI
        POP     SI                      ; Clean operational stack
        POPA                            ; Show restoring buffer
	PUSH	SI
	MOV	SI,TEMP
        MOV     AL,BYTE PTR DS:[SI+15]  ; Yes, put return code in AL
	POP	SI
        PUSHA                           ; Modifies AX inside the restoring stack,
        JMP     JMOPTF                  ; and quit the routine.
	
	JLP3:
        CMP     BYTE PTR DS:[SI],05h    ; Verify if is function 05h
        JNZ     JLP4                    ; No, jump
	PUSH	BX
        MOVZX   BX,BYTE PTR DS:[SI+14]  ; Access the bank
	CALL	ABANK
	POP	BX
        JLP4A:                                           
        CMP     BYTE PTR DS:[SI+15],0   ; Yes, verify if function is active
        JZ      JLP4                    ; No, jump (don't do anything)
	MOV	TEMP,SI
        POP     SI                      ; Clean the operational stack
        POPA                            ; Show restoring buffer
	PUSH	SI
	MOV	SI,TEMP
        MOV     AL,BYTE PTR DS:[SI+15]  ; Yes, put the return code in AL,
	POP	SI
        PUSHA                           ; Modifies AX inside the restoring stack,
        JMP     JMOPTF                  ; And quit the routine.

	JLP4:
        CMP     BYTE PTR DS:[SI],06h    ; Verify if is function 06h
        JNZ     JLP5                    ; No, jump
	MOV	OPER,0
        CALL    OP006                   ;Yes, access function
	PUSH	DS
	PUSH	SI
	MOV	DS,OPDS
	MOV	SI,OPSI
        CALL    MPCA                    ; Update the fields in the screen
	MOV	OPER,0
	POP	SI
	POP	DS
	
	JLP5:
        CMP     BYTE PTR DS:[SI],07h    ; Verify if is function 07h
        JNZ     JLP6                    ; No, jump
        CALL    OP007                   ; Access function
	JLP6:
	
	JMP	JLP2F					

	JLOP2F:
	ADD	SI,26d
	JMP	LOP2
        JLP2F:                          ; Finishes search for clicked function
        ; ----- END2 ---------
	;
	POP	SI
        CMP     BYTE PTR DS:[SI],LSTF   ; Verify if all fields were verified
        JNAE    JLP2F2                  ; No, jump
	
        CMP     CX,OPXI                 ; Verify if clicked outside MOPC menu
        JNA     JLP2F2                  ; Jump if did
	CMP	CX,OPXX
	JA	JLP2F2
	CMP	DX,OPYI
	JNA	JLP2F2
	CMP	DX,OPYY
	JA	JLP2F2
	
        ; If got here, then clicked in an inactive area
        CMP     BYTE PTR DS:[SI-1],0    ; Verify if must quit the routine
        JZ      JLP2F2                  ; No, jump
	
	POPA
        MOV     AL,BYTE PTR DS:[SI-1]   ; Yes, put the return code in AL
	PUSHA
        JMP     JMOPTF                  ; and finishes
	
	JLP2F2: 
	JMP	LOP1
        ; ---- END1 -----               *** END OF LOOP/INTERACTION WIT THE USER
	
	JMOPTF:
        CALL    CHIDE                   ; Remove cursor from the mouse
	
        MOV     AEX,0                   ; Remove exclusion area
        MOV     AX,OPYI                 ; Adjust inclusion area
	MOV	BX,OPXI
	MOV	CX,OPXX
	MOV	DX,OPYY
	DEC	AX
	ADD	CX,2
	ADD	DX,3
	MOV	AIX,BX
	MOV	AIY,AX
	MOV	AIXX,CX
	MOV	AIYY,DX
	
        JMPTF:                          ; Finishes main routine
	POPA
        MOV     CX,OPXI                 ; Adjusts registers
	MOV	DX,OPYI
        RET                             ; Returns

;-------------------------------------------------------------
; Show a menu with options in the screen
; Call with:
;   DS:SI   :      D.Info address
; Returns:
;   R1CL/CL :      Number in the interval 1..x (Number of clicked line)
;                  The first option is 1
; D.Info:
; POSX           WORD
; POSY           WORD
; MENU COLOR     BYTE (0FFh = Use standard)
; TEXT COLOR     BYTE (0FFh = Use standard)
; TYPE           BYTE (0 = Normal, XX = With title)
; RESERVED       3 BYTES
; OPTIONS        ASCII (Line separator is #13d. There is no limit on
;                       the number of lines nor their size)
; FINAL          WORD 0FFFFh
;
; Guidelines to build OPCOES-ASCII: (ATENTION! VERY IMPORTANT!)
; Never forget the final 0FFFFh
; In the last line, finish with 0d, 13d instead of only 13d. (IMPORTANT!)
; Although there is no limit on the line size, don't use more than 80 chrs/line 
; See an example of a built D.Info in MROT routine:
; Any error in the building of D.Info can crash the machine and/or cause problems
; from reseting to lost of disk data.
;
; * TYPE: 0 - Normal. Show all options in the same way.
;         1 - With title. If TIPO is > 0, then the first OPTIONS text line
;             will be the title, which will be centered in the menu, with 
;             the colors:
;             First 4 bits (highest): BACKGROUND COLOR
;             Last 4 bits (lowest): FOREGROUND COLOR
; Besides that, both the window with or without a title are exatly the same,
; even in the exit response. The title of the window counts as a menu option
; when identifying the number of the "clicked" option.

RPYT    DW      0       ; Y coordinate of title (Y.initial + FALT).
                        ; (0 = No title, > 0 = Has title)
RCAB    DB      0       ; Title colors
ROFS    DW      0       ; D.Info offset
R1LX    DW      0       ; Menu width (in pixels)
R1LY    DW      0       ; Menu height (in pixels)
R1LL    DW      1       ; Last pointing [* Ultimo apontamento *]
R1CX    DW      0       ; Menu width
R1OR    DW      0       ; Restore (uncheck)
R1LB    DB      0       ; Flag (draw or uncheck)
R1CL    DB      0       ; Line #R1CL clicked
R1TS    DW      0       ; Window title size (in pixels)

ROT1:	PUSHA
        CALL    MAXL            ; Maximizes inclusion area
	MOV	BX,WORD PTR DS:[SI]
	MOV	AX,WORD PTR DS:[SI+2]
	SUB	AX,2
	DEC	BX
        MOV     CS:AEX,BX       ; Define EXCLUSAO (exclusion) area
        MOV     CS:AEY,AX       ; (AEXX and AEYY will be defined later when
                                ; when the menu width and height are available)
	POPA
	PUSHA

	MOV	R1TS,0
	MOV	RPYT,0
        CMP     BYTE PTR DS:[SI+6],0d   ; Verify if must draw the title
        JZ      JRO3                    ; No, jump

        MOV     AX,WORD PTR DS:[SI+2]   ; Yes, prepares the memory
	ADD	AX,FALT
	MOV	RPYT,AX
	MOV	AL,BYTE PTR DS:[SI+6]
	MOV	RCAB,AL
	
        JRO3:           ; START OF COUTING ROUTINE AND PREPARATION OF THE MEMORY
	MOV	R1CL,0FFh
	CALL	CHIDE
	MOV	ROFS,SI
        XOR     AX,AX   ; Get informations about the window
        XOR     BX,BX   ; such as WIDTH, HEIGHT, etc..
        XOR     DI,DI   ; analyzing R1T1 text
	XOR	CX,CX
	ADD	SI,10
	CLD
        ; BX : Column counter
        ; CX : Highest number of columns marker
        ; DI : Row counter
        ; --- LOOP0 ----
        ; --- LOOP1 ----
        R1L0:           ; Reads until it finds a 0
	ADD	BX,FSIZ
	LODSB
	CMP	AL,13d
	JNE	R1L0	
        ; --- END1 ----
	
        CMP     BX,CX   ; Saves the highest number of columns found
	JNA	R1J0
	MOV	CX,BX
	R1J0:
	
        XOR     BX,BX   ; Goes on with the loop
        ADD     DI,FALT ; +2
	LODSB
	DEC	SI
        CMP     AL,0FFh ; Verify if already is at the end
	JNE	R1L0
        ; --- END0 ----
	ADD	CX,FSIZ
	MOV	CS:R1CX,CX
        ; ------
	MOV	R1LX,CX
	MOV	R1LY,DI
	MOV	SI,ROFS 		
	
        ; Subroutine: Adjusts X and Y positions to keep the menu completely
        ;             inside the desktop
	MOV	BX,WORD PTR DS:[SI]
	ADD	BX,CX
        CMP     BX,RX                   ; Verify if X is out of bounds
        JNA     JROT0                   ; No, jump
        MOV     BX,RX                   ; Yes, adjust X
	SUB	BX,CX
	MOV	WORD PTR DS:[SI],BX
        MOV     AEX,BX                  ; Reajdust exclusion area
	JROT0:
	
        ; Draw borders
	MOV	BX,WORD PTR DS:[SI]
	MOV	AX,WORD PTR DS:[SI+2]
	MOV	DX,R1LY
	MOV	CX,R1LX
	INC	CX
	ADD	DX,2
	MOVZX	SI,INTC
	CALL	RECT
	DEC	AX
	DEC	BX
	MOVZX	SI,BORD
	CALL	RECT
	
        MOV     SI,ROFS ; Draw menu
        MOV     BX,WORD PTR DS:[SI]     ; Draw menu base
	MOV	AX,WORD PTR DS:[SI+2]
	MOV	DL,BYTE PTR DS:[SI+4]
        CMP     DL,0FFh                 ; Defines standard color
	JNZ	JROT1C
	MOV	DL,TBCR
	JROT1C:
        CMP     RPYT,0                  ; If must draw the title, change the
        JZ      JRO4                    ; color of the beginning of the base of the menu
        MOV     DL,RCAB                 ; COLOR
	AND	DL,00001111b
	JRO4:
	MOV	CX,R1LX
	MOV	DI,R1LY
	
        ; ----- LOOP1 -----
	LRO0:
	CALL	LINEH
	INC	AX
        CMP     AX,CS:RPYT              ; Verify if must return to the base color
                                        ; (has already finished the title)
        JNZ     JLR0                    ; No, jump
        MOV     DL,8                    ; Change color: Shadow
	JLR0:
        CMP     AX,CS:RPYT              ; Change color: background menu color
	JNA	JLR1
	MOV	DL,BYTE PTR DS:[SI+4]
        CMP     DL,0FFh                 ; Defines standard color
	JNZ	JROT1E
	MOV	DL,TBCR
	JROT1E:
	JLR1:
	DEC	DI
	JNZ	LRO0
        ; ----- END1 -----
	
	MOV	USEF,1
	MOV	TMP2,SI
        MOV     BX,WORD PTR DS:[SI]     ; Prepares registers for the text
	MOV	AX,WORD PTR DS:[SI+2]
        ADD     BX,FSIZ                         ; Write texts
        XOR     CH,CH                           ; Defines margin (YAFCT)

	ADD	SI,10d
	
        CMP     RPYT,0                  ; Verify if must write the title text 

        JZ      JRO8                    ; No, jump
        PUSHA                           ; Yes, split (with 0d) the first text line
        CLD                             ;
        ; ----- LOOP1 ----
	LRO8:
        ADD     R1TS,FSIZ               ; Updates TITLE X SIZE
	LODSB
	CMP	AL,13d
	JNZ	LRO8
        ; ----- END1 ----
        MOV     BYTE PTR DS:[SI-1],0    ; Mark
	MOV	TMP1,SI
	POPA
	PUSH	BX
        PUSH    AX                      ; Start ---- "CENTER TITLE"
        MOV     AX,R1LX                 ; BX := BX + (R1LX - R1TS) / 2
	SUB	AX,R1TS
	SHR	AX,1
	ADD	BX,AX
	SUB	BX,3
        POP     AX                      ; End ------ "CENTER TITLE"
        MOV     CL,RCAB                 ; Defines text color
	SHR	CL,4
	XOR	CH,CH
        CALL    TEXT                    ; Write title text
	POP	BX
	MOV	SI,TMP1
        MOV     BYTE PTR DS:[SI-1],13d  ; Rebuild the changes
        ADD     AX,FALT                 ; Go to the next line
	
	JRO8:
	PUSH	SI
	MOV	SI,TMP2
	MOV	CL,BYTE PTR DS:[SI+5]
        CMP     CL,0FFh                 ; Adjust standard color
	JNZ	JROT1D		
	MOV	CL,TXTC
	JROT1D:
	POP	SI
	XOR	CH,CH
	CALL	TEXT
	CALL	CSHOW
	
        ; Waits until releasing the mouse button
	CALL	AUSB
	
        ; Finishes defining the inclusion area
	MOV	AX,AEY
	MOV	BX,AEX
	ADD	AX,R1LY
	ADD	BX,R1LX
	ADD	BX,2
	MOV	AEXX,BX
	MOV	AEYY,AX
	
        ; Save mouse position (avoids menu flickering when clicking in the same place)
	CALL	LTR1
	MOV	TMP1,CX
	MOV	TMP2,DX
	
        ; Waits until clicking or pressing some key
	JRO1:
	CALL	MOUSE
	
        CMP     CX,TMP1                 ; Verify if moved the mouse
        JNZ     JRO1A                   ; If clicked in the same place, return
        CMP     DX,TMP2                 ; and waits for the next click.
	JZ	JRO1
	JRO1A:
	
        CMP     AH,72d                  ; KEYBOARD ARROWS: Don't cancel the menu
	JZ	JRO1
	CMP	AH,75d
	JZ	JRO1
	CMP	AH,80d
	JZ	JRO1
	CMP	AH,77d
	JZ	JRO1
        CMP     AH,1d                   ; ESC - Cancel the menu
	JZ	JRO0
        CALL    LTR1                    ; Read mouse positions
	
        MOV     SI,ROFS                 ; Verify if clicked inside the window limits
	CMP	CX,WORD PTR DS:[SI]
	JNA	JRO0
	CMP	DX,WORD PTR DS:[SI+2]
	JNA	JRO0
	MOV	BX,WORD PTR DS:[SI]
	ADD	BX,R1LX
	CMP	CX,BX
	JA	JRO0
	MOV	BX,WORD PTR DS:[SI+2]
	ADD	BX,R1LY
	CMP	DX,BX
	JA	JRO0
        ; Clicked inside the window
        SUB     DX,WORD PTR DS:[SI+2]   ; R1CL := (MOUSEYPOS - MENUYPOS) / FALT
        MOV     AX,DX                   ; Defines margin (YAFCT)
	XOR	DX,DX
	MOV	CX,FALT
	DIV	CX
	MOV	R1CL,AL

	JRO0:
	CALL	CHIDE
        MOV     SI,ROFS                 ; Remove the menu from the screen
	MOV	AX,WORD PTR DS:[SI+2]
	MOV	BX,WORD PTR DS:[SI]
	MOV	CX,BX
	MOV	DX,AX			
	ADD	CX,R1LX
	ADD	DX,R1LY
	SUB	AX,2
	DEC	BX
	ADD	CX,2
	ADD	DX,2
	MOV	AIX,BX
	MOV	AIY,AX
	MOV	AIXX,CX
	MOV	AIYY,DX
	MOV	AEXX,0
	CALL	CSHOW

	POPA
        INC     R1CL                    ; Adjust exit value

	MOV	CL,R1CL 		
        RET                             ; Returns



; ----------------------------------------------------------
; UART:  Serial port     Port/Address
;                        COM4 = 2E8

;                        COM3 = 3E8
;                        COM2 = 2F8
;                        COM1 = 3F8
;
; Table: I/O DEFINITIONS UART H.A. - Finished with ZERO
PRES:	DW	3F8h,2F8h,3E8h,2E8h
CPRT	DW	0
	DD	0
;	
;	UART+1		IER - Interrupt enable
;	UART+3		LCR - Line Control
;	UART+4		MCR - Modem Control
;	UART+5		LSR - Line Status
;	UART+6		MSR - Modem Status
; ----------------------------------------------------------
; SPED:  Baud Rate 
;        Generic rule:   BPS = 115200 / SPED
;        or:             SPED = 115200 / BPS
;   
;        Ex: for 19200: SPED = 115200 / 19200
;                       SPED = 6
SPED:   DW  00d ; Divider. (Choose the speed by using BAUD variable)
BAUD    DW  1200d   ; Speed in BITS PER SECOND
; ----------------------------------------------------------
; LCR:   Bit state   descr.
;    7   1   DLAB 1 (Set baud rate)
;    7   0   XMIT 1 / DLAB 0 (Data xfer)
;    6   1   Enable break
;    5,4,3   x,x,0   no parity
;    5,4,3   0,0,1   odd parity
;    5,4,3   0,1,1   even parity
;    5,4,3   1,0,1   high parity
;    5,4,3   1,1,1   low parity
;    5,4,3   x,x,1   software control

;    2   0   one stop bit
;    2   1   2 stop bits ,if word length=6,7,8

;    2   1   1.5 stop bit,if word length=5
;    1,0 0,0 word length 5 bits
;    1,0 0,1 word length 6 bits
;    1,0 1,0 word length 7 bits
;    1,0 1,1 word length 8 bits
;    Bits -> 76543210    Descr.             
LCR DB  00000010b   ;XMIT 1 / DLAB 0 (Bit 7 always off)
; ----------------------------------------------------------
;
; **************************************************************
;
; >>>       ROUTINE CRASHING THE INTERRUPTION SYSTEM         <<<
;
;            BUG - DESCRIPTION OF THE PROBLEM BELOW
;
; **************************************************************
; Note:  Problem found and bug solved: 1998-07-29 
;    Problem description: When the system entered in a loop
;    reading the byte at 40:6C to measure time, it crashed.
;    The solution was to find an alternative to measure time.
;    OPTION 1: Use INT 15h, which had no problem.
;    OPTION 2: When detecting hardware, don't measure time, but count the
;              number of tries (Ex. Try to find the mouse for 200 times)
;    OPTION 3: Not yet tried, but using the PIT for time counts seems to
;              be safe and precise for this function.
;
;    Since this bug was corrected and its cause was found, a new rule for
;    the system was fixed:
;
;    THE BYTE AT 40:6C MUST NOT BE USED UNTIL WE FIND OUT THE CAUSE OF
;    THE PRECEEDING PROBLEMS.
;
;
; Nanosistemas - Function TOGGLE UART DTR 
; Acess: CALL TDTR / EXTERNO
;
; Verify if Microsoft Mouse was found at the port specified
; at CS:UART
;
; In: NOTHING
; Returns: AL = 0 : Mouse was NOT found
;          AL = 1 : Mouse was found
;
; NOTE:  This function requires that the port (CS:UART) is
;        set to 1200 7N1.
;        (CALL IRIU with MOUS = 0 to adjust it)
; 
;    Execution takes aprox. 6 x 1 / 18.2Hz (IRQ0) and hardware
;    sends 14 undefined bytes, "M" among them. 
;
;    260798 BUG: With MouseDriver loaded, detect the port
;    at which the mouse is connected at the same time it is
;    sending its coordinates.
;    RES: Interruption system is suspended.
;    SOL: Unssuceful -> Disabling IRQ 3, 4 of PIC and UART
;                       Cleaning buffer when leaving the routine
;                       Wait for 1 second reading output characters
;                       Disabling PUSHP and POPP
;                       Redirect IRQ to OUT 20h, 20h/IRET
;
;    Other operations that also cause the bug: <<< IMPORTANT!
;    ---------------------------------------
;    Eternal loop in the routine exit
;    IRQ enabled in place of loaded mouse driver
;    Not activating FIFO 14 bytes buffer in the port initialization.
;    Alien verms entering the processor and eating the OUT and IN instructions
;    Sending the commands FIFO CLEAR QUEUE/DISABLE FIFO 14B QUEUE in this order
;    Returning to the system (INT 20h) without restoring the port state (POPP)
;    Only enabling IRQ 3 in PIC. IRQ 4 had no problems.
;    The system has been invaded by the dark side of the force.
;		
;	
;
BI8D    DB  0       ; Buffer (TMP)
TDEX    DB  0       ; AL return

TDTR:	PUSHA			
	PUSH	ES
	
    MOV DX,CS:UART  ; Toggle DTR
	ADD	DX,4
	XOR	AL,AL
	OUT	DX,AL
	CALL	DLAY
	MOV	AL,3h
	OUT	DX,AL
	CALL	DLAY

    MOV TDEX,0      ; Initialy set: MOUSE NOT FOUND
    MOV CBTE,100d   ; Number of tries to find the mouse
    ; ---- LOOP1 ----
	LTR3:
    DEC CBTE        ; Verify if mouse answer timed out
    JZ  JTDTRF      ; Yes, jump
	
    CALL    SECR        ; Activate safety in the loop
	
    MOV DX,CS:UART  ; Verify if there is characters waiting
	ADD	DX,5
	IN	AL,DX
	TEST	AL,00000001b
    JZ  LTR3        ; No, return to the loop
	
    MOV DX,CS:UART  ; Read the character that is waiting
	IN	AL,DX
    CMP AL,'M'      ; "M" - Mouse ID
        JNZ     LTR3            ; No, jump and return to the loop
    ; ---- END1 ----

    ; Searching for mouse ID:
    MOV TDEX,1      ; Set: MOUSE FOUND
	
    JTDTRF:         ; Finishes the routine
	POP	ES		
	POPA
	
    MOV AL,TDEX     ; In AL - return/answer

	RET
; ----------------------------------------------------------
DLAY:   PUSHA           ; Delay - 0.0655s
	PUSHF
	MOV	AH,86h
	MOV	CX,2
	MOV	DX,01FFFh
	INT	15h
	POPF
	POPA
	RET
; ----------------------------------------------------------
IRIU:   CMP MOUS,0      ; Verify if must initialize the port
    JZ  JIR0        ; Yes, don't return
	
    MOV AX,7h       ; Adjust mouse limits (X)
	XOR	CX,CX
	MOV	DX,RX
	INT	33h
	
    MOV AX,8h       ; Adjust mouse limits (Y)
	XOR	CX,CX
	MOV	DX,RY
	INT	33h
	
    RET         ; No (must not initialize), return
    ; -------------------------
	JIR0:
	PUSHA
	
    MOV DX,1d       ; DX:AX = 115200
	MOV	AX,0C200h
	MOV	CX,CS:BAUD
	DIV	CX
	MOV	WORD PTR CS:SPED,AX
	
    MOV DX,CS:UART  ; Initialize the port
    ADD DX,4        ; Activates DTR and RTS
    MOV AL,3h       ; 3h

	OUT	DX,AL
	
    MOV AL,11000001b    ; Enables a buffer with 14 bytes
	MOV	DX,CS:UART
	ADD	DX,2
	OUT	DX,AL
	
    MOV DX,CS:UART  ; Adjust PARITY, FLOW CONTROL, BAUDRATE...
    ADD DX,3        ; Send DLAB = 1, signaling the adjustment
    MOV AL,CS:LCR   ; for baudrate
	OR	AL,128
	OUT	DX,AL
	
    MOV DX,CS:UART      ; Send requested baud rate
    MOV AL,BYTE PTR CS:[SPED]   ; Low part
	OUT	DX,AL
    MOV AL,BYTE PTR CS:[SPED+1] ; High part
	INC	DX
	OUT	DX,AL
	
    MOV DX,CS:UART  ; Send DLAB = 0 (XMIT ON) and configure the port
	ADD	DX,3
	MOV	AL,CS:LCR
	OUT	DX,AL
	
	MOV	DX,CS:UART
	IN	AL,DX
	
	MDJI:

	POPA
	RET

; ----------------------------------------------------

; SAVE PORT CONFIGURATION TO DX

; In: DX : UART # (Ex. 03F8)
; Returns: Nothing
PXF8    DB  0   ; Port
PXF9    DB  0   ; Port
PXFB    DB  0   ; Port
PXFC    DB  0   ; Port
PXTM    DB  0   ; Tmp

PUSHP:	PUSHA
	PUSH	DX
	
    ADD DX,3         ; Read port status

	IN	AL,DX
	MOV	PXTM,AL
    OR  AL,10000000b    ; Set DLAB = 1 and keep the remaining of the configuration
    OUT DX,AL       ; Send new configuration to UART (DLAB = 1)
	
	POP	DX
	PUSH	DX
    ; Read port 3F8 with DLAB = 1, 
    ; Read port 3F9 with DLAB = 1,
    ; Read port 3FB with DLAB = 1,
    ; Read port 3FC with DLAB = 1.
    IN  AL,DX       ; Read ports and write the values in the buffer above
	MOV	CS:PXF8,AL

	INC	DX
	IN	AL,DX
	MOV	CS:PXF9,AL
	
	MOV	AL,CS:PXTM
	MOV	CS:PXFB,AL
	
	ADD	DX,3
	IN	AL,DX
	MOV	CS:PXFC,AL
	
    POP DX      ; Undo changes in DLAB (beginning of the routine)
	ADD	DX,3		
	MOV	AL,PXTM
    OUT DX,AL       ; Send new configuration to UART
	
    POPA            ; Restore registers
    RET         ; Finishes routine, returns
	
; ----------------------------------------------------
; RESTORE PORT CONFIGURATION IN DX
; In: DX : UART # (Ex. 03F8)
; Returns: Changes to the ports [DX], [DX+1], [DX+3], [DX+4]

POPP:	PUSHA
	PUSH	DX

    ADD DX,3          ; Read port status
	IN	AL,DX
    OR  AL,10000000b    ; Set DLAB = 1 and keep the remaining of the configuration
    OUT DX,AL       ; Send new configuration to UART (DLAB = 1)
	
	POP	DX
	PUSH	DX
    ; Write port 3F8 with DLAB = 1, 
    ; Write port 3F9 with DLAB = 1,
    ; Write port 3FB with DLAB = 1,
    ; Write port 3FC with DLAB = 1.
    MOV AL,CS:PXF8  ; Build AL and restore the ports listed above
	OUT	DX,AL

	INC	DX
	MOV	AL,CS:PXF9
	OUT	DX,AL
	
	ADD	DX,2
	MOV	AL,CS:PXFB

	OUT	DX,AL
	
	INC	DX
	MOV	AL,CS:PXFC
	OUT	DX,AL
	
    POP DX      ; Undo changes in the DLAB (beginning of the routine)
	ADD	DX,3		
	MOV	AL,PXFB
    OUT DX,AL       ; Send new configuration to UART
	
    MOV AL,11000000b    ; Disables mouse port 14 bytes buffer
	MOV	DX,CS:UART
	ADD	DX,2
	OUT	DX,AL
	
    POPA            ; Restore registers
    RET         ; Finishes routine, returns
	
; ----------------------------------------------------
; MOUSE CONTROL
; This routine must always be called in loop, so it can
; update the X and Y mouse coordinates
; In: NOTHING
; Returns: 
;	CX : POS X
;	DX : POS Y
;   BX bit 1 : Right button down
;   BX bit 0 : Left button down

SPDM    EQU 990d    ; Highest acceleration of keyboard arrows

LTR1:	PUSH	DS
	PUSH	ES
	PUSHA
	
    MOV AH,02h      ; Verify if SCROLL LOCK is down
	INT	16h
	BT	AX,4
        JNC     JLT0            ; No, jump

    ; Start of keyboard reading routine
	;---------------------------------------
    IN  AL,60h      ; Read keyboard scan code
	MOV	AH,AL
	
    PUSH    AX      ; Causes a delay (so the mouse won't travel in the time)
	MOV	AH,86h
	XOR	CX,CX
	MOV	DX,SPDM
	INT	15h
	
	POP	AX
    MOV BX,1        ; BX = STEPSIZE
    CMP AH,72d      ; UP
	JNZ	JLT1
	SUB	CS:YPOS,BX
	JNC	JLT1
	MOV	CS:YPOS,0
	JLT1:
    CMP AH,80d      ; DOWN
	JNZ	JLT2
	ADD	CS:YPOS,BX
	MOV	BX,RY
	CMP	YPOS,BX
	JNA	JLT2
	MOV	YPOS,BX
	JLT2:
    CMP AH,77d      ; RIGHT
	JNZ	JLT3
	ADD	CS:XPOS,BX
	MOV	BX,RX
	CMP	XPOS,BX
	JNA	JLT3
	MOV	XPOS,BX
	JLT3:
    CMP AH,75d      ; LEFT
	JNZ	JLT4
	SUB	CS:XPOS,BX
	JNC	JLT4
	MOV	CS:XPOS,0
	JLT4:
    CMP AH,57d      ; LEFT BUTTON DOWN
	JNZ	JLT5
	MOV	BREF,00000011b
	JLT5:
    CMP AH,185d     ; LEFT BUTTON UP
	JNZ	JLT6
	MOV	BREF,40h
	JLT6:
    PUSH    40h     ; Zeroes keyboard buffer
    POP DS          ; by making 40:1A equal to 40:1C
	MOV	AX,WORD PTR DS:[1Ah]
	MOV	WORD PTR DS:[1Ch],AX
	
    JMP JMDE        ; Exit the routine without checking mouse position
    ; ---------------------------------------
    ; End of keyboard reading routine
	
	JLT0:
    CMP MOUS,0      ; Verify if must use UART direct access routines
    JZ  JLC0        ; Yes, jump
                    ; No, uses INT 33h

    ; Read mouse positions using INT 33h
    ; ---------------------------------------
    MOV AX,3h       ; Read informations from the mouse driver
	INT	33h
    MOV YPOS,DX     ; Writes to memory: POS.X and Y
	MOV	XPOS,CX
    AND BX,11b      ; Switch bits 0 and 1 (bit #0 = bit #1, bit #1 = bit #0)
	MOV	AL,BL
	ROR	AL,7
	SHR	BL,1
	OR	BL,AL
    MOV BREF,BL     ; Writes to memory: BUTTONS
	POPA			    
	POP	ES
	POP	DS
    JMP JRT1        ; Step over UART control routine
    ; ---------------------------------------
	
    ; Read mouse positions using direct reading
    ; ---------------------------------------
    JLC0:           ; *** Start of the direct reading routines
    MOV DX,CS:UART  ; Verify if there are characters waiting
	ADD	DX,5d
	IN	AL,DX
	TEST	AL,00000001b
    JZ  JMDE        ; If not, step over the routines below
    MOV DX,CS:UART  ; Read the character that is waiting
	IN	AL,DX

	CLD
    PUSH    CS      ; Shifts MBUF buffer and writes AL at the end
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET MBUF+1
	MOV	DI,OFFSET MBUF
	MOV	CX,2d	
	REP	MOVSB	
	STOSB
	
    MOV AH,BYTE PTR CS:[OFFSET MBUF]    ; Verify if it's a header at the first
    SHR AH,4d                           ; byte of the buffer (MBUF); if so,
    TEST    AH,100b                     ; writes the pressed buttons             
	JZ	JMDE				
	MOV	CS:BREF,AH			
	
    TEST    WORD PTR CS:[MBUF+1],4040h  ; Check if there were sync problems
    JZ  JLTRDEC                         ; No, jump
    ; Syncrony error
    MOV DWORD PTR CS:[OFFSET MBUF],0    ; Zeroes buffer
    JMP JMDE                ; Jump over decoding
	
    ; Start decoding
	JLTRDEC:
    ; Header at AX and BX
	MOVZX	AX,BYTE PTR CS:[OFFSET MBUF]
	MOV	BX,AX
	
    ; -------------------
    ; Executes X movement
    AND AL,3    ; Get the important bits
	SHL	AL,6
	ADD	AL,BYTE PTR CS:[OFFSET MBUF+1]
    CMP AL,128d             ; Positive movement?
    JNA XINC                ; Jump
	
    NEG AL              ; Executes negative movement
	
    ; Filter desyncrony
	CMP	AL,SMAX
	JA	XOK

    CALL    LDAC    ; Acceleration
	SUB	XPOS,AX
    JNC XOK         ; If there were no BORROW, jump
    MOV XPOS,0      ; Doesn't let XPOS go below 0
	JMP	XOK	
	
	XINC:

    ; Filters desyncrony
	CMP	AL,SMAX
	JA	XOK

    CALL    LDAC    ; Acceleration
    ADD XPOS,AX     ; Executes positive movement
    MOV AX,RX       ; Doens't let XPOS go above RX
	CMP	XPOS,AX
    JNA XOK         ; No, jump
    MOV XPOS,AX     ; If yes, XPOS = RX
	XOK: 
	
    ; -------------------
    ; Executes Y movement
    AND BL,12d              ; Get the most important bits
	SHL	BL,4
	ADD	BL,BYTE PTR CS:[OFFSET MBUF+2]
    CMP BL,128d             ; Positive moviment?
    JNA YINC                ; Jump
	
    NEG BL              ; Executes negative movement
	MOV	AX,BX

    ; Filters desyncrony
	CMP	AL,SMAX
	JA	YOK
	
    CALL    LDAC    ; Acceleration
	MOV	BX,AX
	SUB	YPOS,BX
    JNC YOK         ; If there was no BORROW, jump
    MOV YPOS,0      ; Doesn't let YPOS go below 0
	JMP	YOK
	
	YINC:
	MOV	AX,BX

    ; Filters desyncrony
	CMP	AL,SMAX
	JA	YOK
	
    CALL    LDAC    ; Acceleration
	MOV	BX,AX
    ADD YPOS,BX     ; Executes positive movement
    MOV BX,RY       ; Doens't let YPOS go above RY
	CMP	YPOS,BX
    JNA YOK         ; If it's not, jump
    MOV YPOS,BX     ; If is above, YPOS = RY
	YOK:
	
    ; -------------------
	JMDE:
	POPA	
	POP	ES
	POP	DS
	
	JRT1:
    CMP CS:PMAJ,1       ; Verify if it's moving a window
        JNZ     JRT2    ; No, jump
	
	MOV	DX,YPOS

    CMP DX,TLAR         ; Verify if the mouse is at the top bar
        JA      JRT2    ; No, jump
    MOV DX,TLAR         ; Yes, calculate position
	MOV	YPOS,DX
	
	JRT2:
    ; -------------------- Routine: Adjust XX and YY window positions
    ; This routine won't let the mouse return a too small size for
    ; the window which is being resized.
    ; Will only be used when one is resizing windows.
    CMP CS:PMAJ,2   ; Verify if is resizing a window
    JNZ JRT4        ; No, jump
	
    MOV CX,WMPX     ; Verify if the mouse is inside
    ADD CX,150d     ; the protected X perimeter
    CMP CX,XPOS     ; (when it's below the minimum X size)
    JNAE    JRT3    ; No (valid position), jump
	
    MOV AX,4h       ; Adjust X mouse position
	MOV	DX,YPOS
	INT	33h
    MOV XPOS,CX     ; Adjust in memory
	
	JRT3:
    MOV DX,WMPY     ; Verify if the mouse is inside
    ADD DX,100d     ; the protected X perimeter
    CMP DX,YPOS     ; (when it's below the minimum Y size)
    JNAE    JRT4    ; No (valid position), jump
	
    MOV AX,4h       ; Adjust Y mouse position
	MOV	CX,XPOS
	INT	33h  
    MOV YPOS,DX     ; Adjust in memory
    ; -------------------- End of routine
	
	JRT4:
    MOVZX   BX,CS:BREF  ; Save the pressed buttons in BX
	MOV	DX,YPOS
	MOV	CX,XPOS
	
	RET
    ; -------------------------------------

BREF    DB  40h         ; Button: (40h -> None, 60h -> Left button) 
MBUF:   DB    4 DUP (0) ; Buffer
YPOS    DW  10          ; Y pos
XPOS    DW  20          ; X pos

; Subroutine: Mouse acceleration in direct reading mode
; In: AX: Module of the movement
; Returns: AX: Accelerated movement
LDAC:	
	PUSH	DX
	PUSH	CX
	PUSHF
	
        CMP     UACE,0  ; Verify if must use acceleration
        JZ      JLDACF  ; No, jump
	
        CMP     AX,2    ; Verify if must apply acceleration (if AX is [high] enough)
        JNA     JLDACF  ; No, jump
	
        MOV     CX,AX   ; AX := (AX ^ 2) / ACEL
	MUL	CX
	MOVZX	CX,ACEL
	DIV	CX
	
	JLDACF:
	POPF
	POP	CX
	POP	DX
	
	RET

; -------------------------------------------------------------------
; Show a menu to insert another window
; Entra : AL = 0 : New window
;         AL = 1 : Edit window
; Returns: .MMW file in disk or changes in .MMW file in disk;
;          segment registers are lost.

NWTT:	DB 2,7,' New Window',13,13
	DB 'Label',13,13
	DB 'File',0
	
MWOP    DB      0               ; Operation: 0 = New window
                                ;            1 = Edit window

; M.Info definition
NWNI:   DW      0FFFFh  ; X coordinate (0FFFFh = Centered in X)
        DW      0FFFFh  ; Y coordinate (0FFFFh = Centered in Y)
        DW      300d    ; Window width
        DW      142d    ; Window Height
        DW      0       ; CLICKS:OFF
	
        DW      01h     ; Function 01h -> Write text
        DW      20d     ; X position relative to the left [edge] of the window
        DW      10d     ; Y position relative to the top [edge] of the window
        DB 8 dup (0)    ; RESERVED
        DB      0FFh    ; Color
        DB      01h     ; Font (0 = big,1 = small)

        DW OFFSET NWTT  ; ASCIIZ text offset
        DW      00h     ; ASCIIZ text offset (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED

        DW      03h     ; Function 03h -> Creates a textbox
        DW      57d     ; X position relative to the left [edge] of the window
        DW      33d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      MMWTS-1 ; Maximum number of characters
        DW OFFSET BMMWT ; ASCIIZ offset
        DW      00h     ; ASCIIZ segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED
	
        DW      03h     ; Function 03h -> Creates a textbox
        DW      57d     ; X position relative to the left [edge] of the window
        DW      55d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      08d     ; Maximum number of characters
        DW OFFSET TBF2  ; ASCIIZ offset
        DW      00h     ; ASCIIZ segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED
	
        DW      05h     ; Function 05h -> A binary icon
        DW      69d     ; X position relative to the left [edge] of the window
        DW      107d    ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      01h     ; OK icon return code
        DW OFFSET ICNF  ; Icon offset
        DW      00h     ; Icon segment (0 = Use CS)
        DB      0FFh    ; Hotkey ASCII code (0FFh = Don't verify)
        DB      028d    ; Hotkey scan code (0FFh = Don't verify)
        DB      0FFh    ; Background color
        DB      0FFh    ; Foreground color
        DB      64d     ; Icon width
        DB      20d     ; Icon height
	
        DW      05h     ; Function 05h -> A binary icon
        DW      155d    ; X position relative to the left [edge] of the window
        DW      107d    ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      02h     ; Cancel icon return code

        DW OFFSET ICNG  ; Icon offset
        DW      00h     ; Icon segment (0 = Use CS)
        DB      0FFh    ; Hotkey ASCII code (0FFh = Don't verify)
        DB      01h     ; Hotkey scan code (0FFh = Don't verify)
        DB      0FFh    ; Background color
        DB      0FFh    ; Foreground color
        DB      64d     ; Icon width
        DB      20d     ; Icon height
	
        DW      0FFh    ; Finishes M.Info
	
NWER:	DB	'Error Creating File - '
TBF2:   DB 13 dup (0)   ; Buffer for building the MMW file name
NWE1:	DB	'File Already Exist',0
NWE2:	DB	'Invalid Filename',0
NDPJ:   DB 'JNL000'     ; Standard window file name

NEWW:	PUSHA
        CALL    DISJ    ; Uncheck selected icons
        PUSH    CS      ; Clean buffers
	POP	ES
	PUSH	CS
	POP	DS
	MOV	DI,OFFSET BMMWT
	MOV	CX,MMWTS+MMWXS+MMWCS
	XOR	AL,AL
	REP	STOSB
	
	CLD
        MOV     SI,OFFSET NDPJ  ; Copy default name
	MOV	DI,OFFSET TBF2
	MOV	CX,6
	REP	MOVSB
        MOV     DWORD PTR CS:[OFFSET TBF2+6],'WMM.'     ; Write extension
	
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET TBF2
	CALL	FILEN
	
        MOV     DWORD PTR CS:[OFFSET TBF2+6],0          ; Remove extension
	
	JNEWW0:
        CALL    AUSB    ; Wait until the user releases the mouse button

	PUSH	FPAL	
        MOV     FPAL,11 ; Readjusts small font height
        PUSH    CS      ; Put the window with the fields to receive the user data
	POP	DS
	MOV	SI,OFFSET NWNI
	MOV	AX,0100h
        CALL    MOPC    ; BEGIN INTERACTION
	
	POP	FPAL

        CMP     AL,1    ; Verify if there was OK
        JNZ     NEWF    ; No, jump. Finishes the routine
        CALL    NEWMMW  ; Yes, create MMW file
        OR      AL,AL   ; Verify if there were errors during file creation
        JZ      NEWF    ; No, jump
	
        MOV     CX,200d ; Draw message box with error warning
	MOV	DX,66d
	MOV	AX,0FFFFh
	MOV	BX,AX
	CALL	NCMS
	ADD	AX,18
	ADD	BX,20
	XOR	CX,CX
	MOV	USEF,1
	MOV	SI,OFFSET NWER
	CALL	TEXT
	
	MOV	SI,OFFSET NWE2
        CMP     NWERR,1 ; Verify error message
        JZ      JNEWW1  ; INVALID NAME - Jump
        MOV     SI,OFFSET NWE1  ; Mark: FILE ALREADY EXISTS
	JNEWW1:
	ADD	AX,15d
	CALL	TEXT
	
        CALL    AUSB    ; Wait until the user releases the mouse button
        CALL    MOUSE   ; Waits for event (keyboard/mouse)
        JMP     JNEWW0  ; Return to the menu (MOPC) so the user can correct
	
        NEWF:           ; Prepares for redrawing the desktop
        MOV     WORD PTR CS:[OFFSET WINM],0     ; Zeroes WINM/DMAL
	CALL	CHIDE
        CALL    REWRITE ; Removes menu from desktop
	CALL	AJPP
        MOV     WORD PTR CS:[OFFSET WINM],0     ; Zeroes WINM/DMAL
	CALL	MAXL
        POPA            ; Finishes execution
        RET             ; Returns

;---------------------------------------------
; Internal subroutine:
; Creates new MMW file

; In: BMMWT buffer
; Returns: AL = 0 : Ok. File succefully created
;          AL = 1 : Error: Invalid name
;          AL = 2 : Error: File already exists

NEWMMW: PUSHA                            ; Create new MMW
                                         ; Will be set to 0 when successful
        MOV     CS:BMMWX,20              ; Prepares memory
	MOV	CS:BMMWY,30
	MOV	CS:BMMWXX,300
	MOV	CS:BMMWYY,200

        ; Writes file extension (.MMW)
	CLD
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES				
	MOV	DI,OFFSET TBF2		
	MOV	CX,12
	XOR	AL,AL
	REPNZ	SCASB
	MOV	DWORD PTR CS:[DI-1],'WMM.'
	
        MOV     CS:NWERR,2              ; Sets ERROR FILE ALREADY EXISTS
	MOV	DX,OFFSET TBF2
        MOV     AX,3D02h                ; Verify if file already exists
	INT	21h
        JNC     NWFM                    ; If it does, do not create
	
        MOV     NWERR,1                 ; Sets ERROR INVALID NAME
        MOV     AH,3Ch                  ; Creates file
	XOR	CX,CX
	INT	21h
        JC      NWFM                    ; If can't create file, jump to the end
	MOV	BX,AX
	
        MOV     CS:NWERR,0              ; Sets success in file creation
        MOV     AH,40h                  ; Writes file
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET BMMWT
	INT	21h

        MOV     AH,3Eh                  ; Close file
	INT	21h
	
	MOV	BYTE PTR CS:[DI-1],0
        MOV     AX,CS:BMMWY             ; Register new window
	MOV	BX,CS:BMMWX
	MOV	CX,CS:BMMWYY
	ADD	CX,AX
	MOV	DX,CS:BMMWXX
	ADD	DX,BX
	MOV	SI,OFFSET TBF2
	
	CALL	WINDOW
	
	NWFM:
        MOV     DWORD PTR CS:[DI-1],0   ; Removes .MMW from the end
	POPA
        MOV     AL,NWERR                ; Set error code
	RET

	
NWERR   DB      0       ; Error creating the window (0 = NONE,
                                                     1 = ERROR INVALID NAME,
                                                     2 = ERROR FILE ALREADY EXISTS)


; -------------------------------------------------------------------
; Show a menu for new icon
; In : AL = 0 : New icon
;      AL = 1 : Edit icon
; Returns: Changes in .MMW file in disk

NITT:	DB 'Icon in Current Window:',13
	DB 'Label',13
	DB 'Filename',13
	DB 'Diretory',13
	DB 'Icon',0
NIOP    DB      0       ; Operation: 0 = New icon, 1 = Edit icon
NIDX    DW      0       ; Temporary
NICX	DW	0

; M.Info definition
NIMI:   DW      0FFFFh  ; X coordinate (0FFFFh = Centered in X)
        DW      0FFFFh  ; Y coordinate (0FFFFh = Centered in Y)
        DW      470d    ; Window width
        DW      170d    ; Window height
        DW      0       ; CLICKS:OFF
	
        DW      01h     ; Function 01h -> Write text
        DW      20d     ; X position relative to the left [edge] of the window
        DW      10d     ; Y position relative to the top [edge] of the window
        DB 8 dup (0)    ; RESERVED
        DB      0FFh    ; Color
        DB      01h     ; Font (0 = large, 1 = small)

        DW OFFSET NITT  ; ASCIIZ text offset
        DW      00h     ; ASCIIZ text segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED

        DW      03h     ; Function 03h -> Creates a textbox
        DW      77d     ; X position relative to the left [edge] of the window
        DW      33d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      ICOTS-1 ; Maximum number of characters
        DW OFFSET BICOT ; ASCIIZ offset
        DW      00h     ; ASCIIZ segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED
	
        DW      03h     ; Function 03h -> Creates a textbox
        DW      77d     ; X position relative to the left [edge] of the window
        DW      53d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      ICOPS-1 ; Maximum number of characters
        DW OFFSET BICOP ; ASCIIZ offset
        DW      00h     ; ASCIIZ segment (0 = Use CS)
	DB	032d
	DB	100d
        DB 4 dup (0)    ; NOT NEEDED
	
        DW      03h     ; Function 03h -> Creates a textbox
        DW      77d     ; X position relative to the left [edge] of the window
        DW      73d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      ICODS-1 ; Maximum number of characters
        DW OFFSET BICOD ; ASCIIZ offset
        DW      00h     ; ASCIIZ segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED
	
        DW      04h     ; Function 04h -> Creates a BMP icon
	DW	77d
	DW	93d
	DB 8 dup (0)
        DB      1       ; Use CURSORMAP
        DB      3d      ; Return code: 3d
	DW OFFSET BICOB
	DW	0
	DW	0FFFFh
	DW	0
        DB      32      ; Icon size
	DB	32
	
        DW      05h     ; Function 05h -> Creates a binary icon
        DW      436d    ; X position relative to the left [edge] of the window
        DW      50d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      07h     ; Return code for BROWSE
        DW OFFSET BRICO ; Icon offset
        DW      00h     ; Icon segment (0 = Use CS)
        DB      0FFh    ; Hotkey ASCII code (0FFh = Don't verify)
        DB      0FFh    ; Hotkey scan code (0FFh = Don't verify)
        DB      0FFh    ; Background color
        DB      0FFh    ; Foreground color
        DB      16d     ; Icon width
        DB      16d     ; Icon height
	
        DW      05h     ; Function 05h -> Creates a binary icon
        DW      168d    ; X position relative to the left [edge] of the window
        DW      127d    ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      01h     ; Return code for OK icon
        DW OFFSET ICNF  ; Icon offset
        DW      00h     ; Icon segment (0 = Use CS)
        DB      0FFh    ; Hotkey ASCII code (0FFh = Don't verify)
        DB      028d    ; Hotkey scan code (0FFh = Don't verify)
        DB      0FFh    ; Background color
        DB      0FFh    ; Foreground color
        DB      64d     ; Icon width
        DB      20d     ; Icon height
	
        DW      05h     ; Function 05h -> Creates a binary icon
        DW      258d    ; X position relative to the left [edge] of the window
        DW      127d    ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      02h     ; Return code for CANCEL icon
        DW OFFSET ICNG  ; Icon offset
        DW      00h     ; Icon segment (0 = Use CS)
        DB      0FFh    ; Hotkey ASCII code (0FFh = Don't verify)
        DB      01h     ; Hotkey scan code (0FFh = Don't verify)
        DB      0FFh    ; Background color
        DB      0FFh    ; Foreground color
        DB      64d     ; Icon width
        DB      20d     ; Icon height
	
        DW      0FFh    ; Finishes M.Info

NEWI:	PUSHA
        CALL    AUSB            ; Wait until the user releases the mouse
        MOV     NIOP,AL         ; Writes operation
        CMP     AL,1            ; Verify if is going to edit the icon
        JNZ     JNIEA           ; No, jump
        ; Yes, goes on
        ; Verify if the icon can be edited
        CMP     CS:ICSL,1       ; Verify if there is any visibly selected icon
        JZ      JNIE5           ; Yes, jump
        POPA                    ; No, returns (finishes) 
	RET
	JNIE5:
        CALL    MRKI            ; Read information about the selected icon to ICOT buffer
	
        ; Calculates icon positions in the .MMW file
	MOV	AX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	CX,ICLC
	DEC	CX
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EAX
	ADD	EAX,(MMWTS+MMWXS+MMWCS)
	MOV	TLONG,EAX
	MOV	DX,AX
	SHR	EAX,16
	MOV	CX,AX
        MOV     NIDX,DX         ; Writes this positions to NIDX and NICX
	MOV	NICX,CX
	
        ; Prepares the window for editing/inserting the icon
	JNIEA:
        CMP     CS:INDX,0       ; Verify if there is an active window
        JNZ     JNI9            ; Yes, jump
        POPA                    ; No, jump
	RET
	
	JNI9:
        PUSH    CS      ; Copy data from ICOT buffer to BICOT buffer
	POP	ES
	PUSH	CS
	POP	DS
	MOV	DI,OFFSET BICOT
	MOV	SI,OFFSET ICOT
	MOV	CX,ICOTS+ICODS+ICOBS+ICOPS+ICORS
	CLD
	REP	MOVSB
	
        CMP     NIOP,1  ; Edit icon, don't clear buffers
        JZ      JNI2    ; Jump
	
	MOV	DI,OFFSET BICOT
	MOV	CX,ICOTS+ICODS+ICOBS+ICOPS+ICORS
	XOR	AL,AL
	REP	STOSB

        MOV     SI,OFFSET TBMP          ; Copy icon to the data area of the icon
        MOV     DI,OFFSET BICOB         ; so it can be written to the .MMW file
        MOV     CX,1024                 ; - FIRST ICON
	REP	MOVSB
	
	JNI2:
        PUSH    FPAL    ; Prepares for showing the window
        MOV     FPAL,20 ; Readjust small font height
	MOV	SI,OFFSET NIMI
	MOV	AX,0100h
        CALL    MOPC    ; START INTERACTION
	POP	FPAL

        CMP     AL,3    ; Verify: Choose new icon

	JNZ	JNI3
	PUSH	AIX
	PUSH	AIXX
	PUSH	AIY
	PUSH	AIYY
        CALL    CHNI    ; Choose new icon
	POP	AEYY
	POP	AEY
	POP	AEXX
	POP	AEX
	SUB	AEYY,3
	CALL	CHIDE
	CALL	REWRITE
	CALL	CSHOW
	CALL	MAXL
        JMP     JNI2    ; Return to menu
	
	JNI3:
        CMP     AL,7    ; Verifies BROWSE
	JNZ	JNI4
	PUSH	AIX
	PUSH	AIXX
	PUSH	AIY
	PUSH	AIYY

        CALL    MAXL            ; Yes, show browse window
	CALL	AUSB

	CALL	CHIDE
	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	DX,222
	MOV	CX,220
	CALL	NCMS
	CALL	CSHOW

	MOV	CX,BX
	MOV	DX,AX
	ADD	CX,30d
	ADD	DX,10d
	
	XOR	AX,AX
        MOV     BH,11111111b    ; Don't allow access to floppy nor cdrom
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET BEXCM 
	CALL	BROWSE
	
        TEST    AL,11110000b    ; Cancel, jump
	JNZ	JBRNIC

        PUSH    CS      ; Copy the name of the choosen program
	POP	ES
	CLD
	MOV	DI,OFFSET BICOP
	MOV	CX,79

	PUSH	SI
	REP	MOVSB
	POP	SI
	
                        ; Copy working directory
	MOV	DI,OFFSET BICOD
        ; LOOP
	LBRNI0:
	LODSB
	STOSB
	OR	AL,AL
	JNZ	LBRNI0
        ; END
	MOV	AL,'\'
	STD
	MOV	CX,79d
	REPNZ	SCASB
	MOV	BYTE PTR ES:[DI+1],0
	CLD
	
	JBRNIC:
	POP	AEYY
	POP	AEY
	POP	AEXX
	POP	AEX
	SUB	AEYY,3
	CALL	CHIDE
	CALL	REWRITE

	CALL	CSHOW
	CALL	MAXL
        JMP     JNI2    ; Return to the menu
	
	BEXCM:	DB	'*.EXE *.COM',0
	
	JNI4:
        CMP     AL,1    ; Verify if there was OK
        JNZ     NEIF    ; No, jump. Finishes the routine
        CALL    NIAF    ; Yes, create new icon
	
        NEIF:           ; Finishes routine
	CALL	REWRITE
	CALL	MAXL
	CALL	AJPP
	CALL	MAXL
        MOV     WORD PTR CS:[OFFSET WINM],0     ; Zeroes WINM/DMAL
        POPA            ; Returns
	RET

;---------------------------------------------
; Internal subroutine: Add new icon to the current window
; In: CS:ICOT has the mouse information
; Returns: changes to the current window .MMW file

NIAF:   PUSHA                           ; Prepares the name of the file to be opened
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	
	MOV	SI,OFFSET TTLS
	ADD	SI,CS:INDX
	MOV	DI,OFFSET MMWBUF
	MOV	CX,8
        ; ---- LOOP1 ------
        LNIB:                           ; Copy file name from the windows
        LODSB                           ; buffer (CS:TTLS) to the MACW
        OR      AL,AL                   ; routine local buffer
	JZ	JNIB
	STOSB
	DEC	CX
	JNZ	LNIB
        ; ---- END1 ------
	JNIB:
        MOV     DWORD PTR CS:[DI],'WMM.'; Writes the MMW extension to the end of
                                        ; the string
        MOV     BYTE PTR CS:[DI+5],0    ; Writes the ASCIIZ null terminator
	
        MOV     AX,3D02h                ; Open MMW file
	MOV	DX,OFFSET MMWBUF
	INT	21h
        JC      PFIM                    ; Error: Jump
	MOV	BX,AX
	
        MOV     AX,4202h                ; Seeks to the end of the file
	XOR	CX,CX

	XOR	DX,DX


        CMP     NIOP,0                  ; Verify if is editing the icon
        JZ      JNIEB                   ; No, jump
        MOV     AX,4200h                ; Yes, points to write over the icon
                                        ; to be edited

	MOV	DX,NIDX 		
	MOV	CX,NICX
	JNIEB:
	INT	21h
	
        MOV     AH,40h                  ; Write file
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	DX,OFFSET BICOT
	INT	21h
	
        XOR     AL,AL                   ; Redo MMW file checksum
	CALL	MCHK			
	
        MOV     AH,3Eh                  ; Close file
	INT	21h
	
	POPA
	RET
	
; -------------------------------------------------------------------
; Destroy current window
; In: NOTHING
; Returns: Changes to the .MMW file in disk
DWT0:	DB '  Permanently Erase Window?',0

; M.Info definition
DWNI:   DW      0FFFFh  ; X coordinate (0FFFFh = Centered in X)
        DW      0FFFFh  ; Y coordinate (0FFFFh = Centered in Y)
        DW      300d    ; Window width
        DW      100d    ; Window height
        DW      0       ; CLICKS:OFF
	
        DW      01h     ; Function 01h -> Write text
        DW      20d     ; X position relative to the left [edge] of the window
        DW      13d     ; Y position relative to the top [edge] of the window
        DB 8 dup (0)    ; RESERVED
        DB      0FFh    ; Color
        DB      00h     ; Font (0 = large, 1 = small)
        DW OFFSET DWT0  ; ASCIIZ text offset
        DW      00h     ; ASCIIZ text segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED

        DW      01h     ; Function 01h -> Write text

        DW      21d     ; X position relative to the left [edge] of the window
        DW      13d     ; Y position relative to the top [edge] of the window
        DB 8 dup (0)    ; RESERVED
        DB      0FFh    ; Color

        DB      00h     ; Font (0 = large, 1 = small)
        DW OFFSET DWT0  ; ASCIIZ text offset
        DW      00h     ; ASCIIZ text segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED

        DW      01h     ; Function 01h -> Write text
        DW      0FFFFh  ; X position relative to the left [edge] of the window
        DW      33d     ; Y position relative to the top [edge] of the window
        DB 8 dup (0)    ; RESERVED
        DB      0FFh    ; Color
        DB      01h     ; Font (0 = large, 1 = small)
        DW OFFSET MMWT  ; ASCIIZ text offset
        DW      00h     ; ASCIIZ text segment (0 = Use CS)
        DB 6 dup (0)    ; NOT NEEDED

        DW      05h     ; Function 05h -> Creates a binary icon
        DW      59d     ; X position relative to the left [edge] of the window
        DW      70d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      01h     ; Return code for OK icon
        DW OFFSET ICNF  ; Icon offset
        DW      00h     ; Icon segment (0 = Use CS)
        DB      0FFh    ; Hotkey ASCII code (0FFh = Don't verify)
        DB      0FFh    ; Hotkey scan code (0FFh = Don't verify)
        DB      0FFh    ; Background color
        DB      0FFh    ; Foreground color
        DB      64d     ; Icon width
        DB      20d     ; Icon height
	
        DW      05h     ; Function 05h -> Creates a binary icon
        DW      169d    ; X position relative to the left [edge] of the window
        DW      70d     ; Y position relative to the top [edge] of the window
        DB 9 dup (0)    ; RESERVED
        DB      02h     ; Return code for CANCEL icon
        DW OFFSET ICNG  ; Icon offset
        DW      00h     ; Icon segment (0 = Use CS)
        DB      0FFh    ; Hotkey ASCII code (0FFh = Don't verify)
        DB      01h     ; Hotkey scan code (0FFh = Don't verify)
        DB      0FFh    ; Background color
        DB      0FFh    ; Foreground color
        DB      64d     ; Icon width
        DB      20d     ; Icon height
	
        DW      0FFh    ; Finishes M.Info


DWIN:	PUSHA
	
        CMP     CS:INDX,0       ; Verify if there is any window to delete
        JNZ     JDW9            ; Yes, jump
        POPA                    ; No, finishes without doing anything
	RET
	
	JDW9:
        MOV     DI,INDX         ; Verify if the window is hidden
	CMP	WORD PTR CS:[OFFSET WIN1+DI+4],0
        JNZ     JDW9B           ; Yes, finishes. Does not delete hidden window
	POPA
	RET
	

	JDW9B:
        PUSH    FPAL    ; Prepares to show the window    
        MOV     FPAL,20 ; Readjust small font height
	MOV	SI,OFFSET DWNI
	MOV	AX,0100h
        CALL    MOPC    ; START INTERACTION
	CALL	REWRITE
	POP	FPAL

        CMP     AL,1    ; Verify if there was OK
        JNZ     DEIF    ; No, jump. Finishes the routine
        CALL    DWDM    ; Yes, jump. Deletes the window.
	
        DEIF:           ; Finishes the routine
        CALL    MAXL    ; Free environment
        MOV     WORD PTR CS:[OFFSET WINM],0     ; Zeroes WINM/DMAL
	CALL	AJPP
	CALL	MAXL	
        POPA            ; Returns
	RET

;--------------------------------------------------	
;Subrotina interna:
;Apaga janela em prioridade 1 do disco e do desktop
;Pede: NADA
;Retorna: Alteracoes no disco e nas tabelas internas do Nanosistemas

DWDM:	PUSHA			;Apaga a janela em prioridade 1
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET TTLS
	ADD	SI,CS:INDX
	MOV	DI,OFFSET RBDT
	MOV	CX,8
	;---- LOOP1 ------
	LDWB:				;Copia nome do arquivo do buffer
	LODSB				;das janelas (CS:TTLS) para o buffer
	OR	AL,AL			;local da rotina MACW
	JZ	JDWB
	STOSB
	DEC	CX
	JNZ	LDWB
	;---- END1 ------
	JDWB:
	MOV	DWORD PTR CS:[DI],'WMM.';Grava a extensao MMW no final da string
	MOV	BYTE PTR CS:[DI+4],0	;Grava o ZERO do ASCII-ZERO
	
	MOV	AH,41h			;Apaga MMW
	MOV	DX,OFFSET RBDT
	INT	21h
	JC	JDWF			;ERRO, pula

	MOV	DI,CS:INDX
	SUB	CS:INDX,8		;Apaga janela do video
	
	MOV	BX,WORD PTR CS:WIN1+DI

	MOV	AX,WORD PTR CS:WIN1+DI+2
	MOV	DX,WORD PTR CS:WIN1+DI+4
	MOV	CX,WORD PTR CS:WIN1+DI+6
	SUB	AX,2
	SUB	BX,2
	ADD	DX,2
	ADD	CX,2
	MOV	AIX,BX
	MOV	AIY,AX
	MOV	AIXX,DX
	MOV	AIYY,CX
	MOV	AEX,1
	MOV	AEXX,1
	CALL	REWRITE
	
	JDWF:
	POPA
	RET
	
-------------------------------------------------------------------
;Apaga a icone marcada da janela em foco
;Entra : Nada
;Retorna: Alteracoes no arquivo MMW correspondente

TLONG	DD	0	;Temporario. Armazena a posicao do arquivo MMW

DICO:	PUSHA
	
	CMP	CS:ICSL,1	;Verifica se ha alguma icone visivelmente selecionada
	JZ	JDI5		;Afirmativo, pula
	POPA			;Negativo, retorna (finaliza)	
	RET
	JDI5:
	
	MOV	AX,3D02h	  ;Abre o arquivo
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET MMWBUF;Ultima janela selecionada
	INT	21h
	JC	JDIF		;Erro: Finaliza rotina
	MOV	BX,AX
	
	;˛ TLONG=((ICOTS+ICOBS+ICOPS+ICODS+ICORS)*ICLC)+MMWTS+MMWXS+MMWCS
	;˛ FPOS=TLONG
	MOV	AX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	CX,ICLC
	DEC	CX
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EAX
	ADD	EAX,(MMWTS+MMWXS+MMWCS)
	MOV	TLONG,EAX
	MOV	DX,AX
	SHR	EAX,16
	MOV	CX,AX
	MOV	AX,4200h	;Move indicador para o inicio das icones
	INT	21h
	JC	JDIF		;Erro: Finaliza rotina

	;---- LOOP1 ------
	LDI0:
	MOV	AX,4200h	;Pos ONE ICO UP
	ADD	TLONG,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	DX,WORD PTR CS:TLONG
	MOV	CX,WORD PTR CS:TLONG+2
	INT	21h
	JC	JDI0		;Terminado arquivo, fecha
	
	MOV	AH,3Fh		;Le uma icone
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	DX,OFFSET ICOT
	INT	21h
	JC	JDI0		;Terminado arquivo, fecha
	OR	AX,AX
	JZ	JDI0
	
	MOV	AX,4200h	;Pos TWO ICO DOWN
	SUB	TLONG,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	DX,WORD PTR CS:TLONG
	MOV	CX,WORD PTR CS:TLONG+2
	INT	21h
	JC	JDI0		;Terminado arquivo, fecha
	
	MOV	AH,40h		;Write
	MOV	CX,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	DX,OFFSET ICOT
	INT	21h
	JC	JDI0		;Terminado arquivo, fecha
	
	ADD	TLONG,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	JMP	LDI0
	;---- END1 ------
	
	JDI0:
	MOV	AX,4200h	;Pos ONE ICO DOWN
	SUB	TLONG,(ICOTS+ICOBS+ICOPS+ICODS+ICORS)
	MOV	DX,WORD PTR CS:TLONG
	MOV	CX,WORD PTR CS:TLONG+2
	INT	21h
	
	MOV	AH,40h		;Trunca arquivo para tirar a ultima icone
	XOR	CX,CX
	INT	21h
	
	XOR	AL,AL
	CALL	MCHK		;Realiza checksum
	
	MOV	AH,3Eh		;Fecha arquivo
	INT	21h
	
	CMP	MVIC,1		;Verifica se esta movendo icone
	JZ	JDIF		;Afirmativo, nao atualiza janela.	
	
	CALL	AJPP		;Atualiza janela em primeiro plano	
	CALL	CSHOW
	CALL	MAXL
	MOV	WORD PTR CS:[OFFSET WINM],0	;Zera WINM/DMAL
	
	JDIF:			;Finaliza
	POPA
	RET

-------------------------------------------------------------------
;Exibe janela de Help
;Entra : NADA
;Retorna: Nada, alem de uma alteracao temporaria na memoria de video
HET0:	DB 13d
	DB 'F1	  Help',13d
	DB 'F4	  Create Window',13d
	DB 'F9	  Delete Window',13d
	DB 'HOME  Reset Window Position',13d
	DB 'INS   New Icon',13d
	DB 'DEL   Delete Icon',13d
	DB 'F5	  Refresh Desktop',13d
	DB 'SH+F5 Refresh System',13d
	DB '123.. Screen Resolution',13d
	DB 'I	  See Background Image',13d
	DB 'ALT+X Exit',0
	
HET1:	DB 13d
	DB 'E	  Edit Selected Icon',13d
	DB 'O	  System Options',13d
	DB 'CTRL  Hold When Drag to Copy Icon',13d
	DB '-/+   Screen Resolution',13d
	DB 'ALT+P Take Screenshot',13d
	DB 'SCRLK Active/Deative keyboard',13d
	DB 2,6,' cursor control',13d
	DB 2,6,' Arrows: Move cursor.',13d
	DB 2,6,' Spacebar: Click',13d
	DB 2,6,' Other keys inactive.',0

HELPM:	PUSHA
	CALL	DISJ		;Desmarca icones selecionadas

	MOV	USEF,1		;Usar fonte normal
	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	CX,400d 	;Desenha janela
	MOV	DX,210d 	;DIMENSOES DA JANELA
	CALL	MWIN
	
	ADD	BX,20		;Escreve textos

	MOV	CL,TXTC
	XOR	CH,CH
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET HET0
	CALL	TEXT
	ADD	BX,160d
	MOV	SI,OFFSET HET1
	CALL	TEXT
	
	CALL	MWINN		;Aguarda click no [  OK  ]
	CALL	AJPP
	CALL	MAXL
	POPA
	RET

-------------------------------------------------------------------
;Exibe janela IMAGEM BMP
;Entra : NADA
;Retorna: Nada, alem de uma alteracao temporaria na memoria de video
VTX1:	DB 'IMAGEM BMP',0
VTX2:	DB 'Imagem nao pode',13
	DB 'ser carregada.',0

VTB0	DB	0		;Buffers
VTB1	DB	0
VTST	DB	0

VEIW:	PUSHA
	CALL	CHIDE		;Esconde cursor
	CALL	AUSB		;Aguarda usuario liberar mouse
	CALL	DISJ		;Desmarca icones selecionadas
	MOV	AL,BMPD 	;Salva estado inicial
	MOV	VTB0,AL
	MOV	AL,BMPY
	MOV	VTB1,AL
	MOV	VTST,0		
	
	
	MOV	SI,OFFSET MPCTF ;Exibe mensagem: AGUARDE
	PUSH	DS
	PUSH	SI

	MOV	USEF,1		;Usar fonte normal
	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	CX,94d		;Desenha janela
	MOV	DX,40d
	CALL	NCMS
	
	ADD	AX,14
	ADD	BX,28		;Escreve textos
	MOV	CL,TXTC
	MOV	CH,250
	POP	SI
	POP	DS
	CALL	TEXT
	
	CMP	BMPD,1		;Verifica se a imagem BMP ja esta disponivel
	JZ	JVBM2		;Afirmativo, pula
	MOV	BMPY,1		;Marca USAR BMP
	MOV	VTST,1		;Marca BMP FOI CARREGADO. DESALOCAR DEPOIS
	CALL	BMP		;Negativo, carrega imagem para a memoria
	JVBM2:

	CALL	MAXL
	MOV	RAI,0
	MOV	RAE,0
	MOV	AX,0FFFFh	;Desenha messagebox
	MOV	BX,AX
	MOV	EDX,BHBP
	MOV	ECX,BWBP
	CMP	CX,80d
	JAE	JVBM1
	MOV	CX,80d		
	JVBM1:
	CMP	DX,30d
	JAE	JVBM1B1
	MOV	DX,30d
	JVBM1B1:
	ADD	DX,60d
	ADD	CX,14d
	MOV	DI,RX
	SUB	DI,20d
	CMP	CX,DI		;Ajusta janela para os limites da tela
	JNA	JVBM1A
	MOV	CX,DI
	JVBM1A:
	MOV	DI,RY
	SUB	DI,40
	CMP	DX,DI

	JNA	JVBM1B
	MOV	DX,DI
	JVBM1B:
	CALL	MWIN		;Desenha caixa de mensagem
	
	CALL	PUSHAI
	PUSHA
	ADD	AX,5	       ;Escreve textos
	ADD	BX,7
	MOV	AIX,BX		;Ajusta area de inclusao
	MOV	AIY,AX
	MOV	AIXX,BX
	MOV	AIYY,AX
	ADD	AIXX,CX
	ADD	AIYY,DX
	SUB	AIXX,14
	SUB	AIYY,50
	MOV	CH,0FFh
	MOV	CL,TXTC
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET VTX1
	CMP	BMPD,1
	JZ	JVBM5
	MOV	SI,OFFSET VTX2
	JVBM5:
	CALL	TEXT
	POPA


	CMP	BMPD,1		;Verifica se ha BMP disponivel
        JNZ     JVBM4           ;No, jump e nao desenha imagem
	
	MOV	DS,BSEG 	;Desenha BMP
	MOV	SI,BOFF
	ADD	AX,17
	ADD	BX,7
	MOV	ECX,BWBP
	MOV	EDX,BHBP
	CALL	BITMAP
	
	CMP	VTST,1		;Verifica se o BMP foi alocado
        JNZ     JVBM4           ;No, jump
	CALL	DALB		;Afirmativo, desaloca BMP da memoria
	JVBM4:
	MOV	AL,VTB0 	;Restaura estado inicial
	MOV	BMPD,AL 	
	MOV	AL,VTB1
	MOV	BMPY,AL
	CALL	POPAI
	CALL	MWINN		;Aguarda OK
	
	POPA			;Finaliza
	CALL	CSHOW
	JVBF:
	RET

-------------------------------------------------------------------
;Nanosistemas. Funcao MWIN / MWINN
;Acesso: CALL MWIN / CALL MWINN
;
;Exibe uma janela com apenas a opcao de OK.
;Esta janela pode ser usada para pequenos avisos durante a execucao.
;
;Entra : AX	: Posicao Y da janela (FFFFh = Centralizado em Y)
;	 BX	: Posicao X da janela (FFFFh = Centralizado em X)  
;	 CX	: Tamanho X da janela
;	 DX	: Tamanho Y da janela
;Retorna:
;	 AX	: Posicao Y inicial da janela
;	 BX	: Posicao X inicial da janela
;
;O usuario NAO necessita de chamar as funcoes CHIDE e CSHOW. A rotina ja
;possui este recurso implementado.
;
;OBS:	O usuario deve chamar esta rotina, a rotina retornara as posicoes da janela
;	para que o usuario possa preencher o conteudo da janela, e apos
;	pronta, o usuario deve executar CALL MWINN para retornar a rotina
;	que aguarda o click no OK.
;Exemplo:
;	MOV	AX,200d 		;Desenha janela
;	MOV	BX,200d
;	CALL	MWIN
;	
;	ADD	AX,10			;Escreve conteudo da janela
;	ADD	BX,10
;	MOV	CX,0FF00h
;	PUSH	CS
;	POP	DS
;	MOV	SI,OFFSET TEXTO1
;	CALL	TEXT
;
;	CALL	MWINN			;Espera OK do usuario

MWISX	DW     0d
MWISY	DW     0d
MWTM1	DW	0
MWTM2	DW	0

MWIPX	DW	0		;Temporario. Contem posicao XYXXYY da icone OK 

MWIPY	DW	0
MWIPXX	DW	0
MWIPYY	DW	0

MWIN:	PUSHA
	MOV	MWISX,CX
	MOV	MWISY,DX
	
	CALL	CHIDE
	CALL	NCMS		;Desenha caixa de mensagem
	MOV	MWTM1,AX
	MOV	MWTM2,BX

	MOV	CX,MWISX	;BX:=BX+((MWISX/2)-32)
	SHR	CX,1
	SUB	CX,32
	ADD	BX,CX
	MOV	CX,MWISY	;AX:=(MWISY+AX)-35
	ADD	CX,AX
	SUB	CX,35
	MOV	AX,CX
	MOV	CX,64
	MOV	DX,20
	MOV	SI,OFFSET ICNF
	MOV	CS:MWIPX,BX	;Cadastra objeto
	MOV	CS:MWIPY,AX
	MOV	CS:MWIPXX,BX
	ADD	CS:MWIPXX,CX
	MOV	CS:MWIPYY,AX
	ADD	CS:MWIPYY,DX
	MOV	DI,WORD PTR CS:[OFFSET TBCR]
	CALL	BINMAP
	
	POPA
	MOV	AX,MWTM1
	MOV	BX,MWTM2
	RET			;Retorna a rotina

MWINN:	PUSHA			;Prossegue com a rotina
	CALL	CSHOW
	POPA
	XOR	CL,CL
	PUSHA

	;------ LOOP1 -------
	LNW1:
	CALL	MOUSE

	CMP	AX,011Bh		;Verifica teclado (ESC = OK..neste caso)

	JZ	JNJ1
	CMP	AX,1C0Dh		;ENTER = OK
	JZ	JNJ1

	;---- Verifica clicks nos botoes OK/CANCEL
	JNW0:
	TEST	BX,00000010b
	JZ	LNW1

	CMP	CX,CS:MWIPX	;Verifica se o mouse foi clicado em cima do
	JNAE	JNW1		;botao de OK
	CMP	CX,CS:MWIPXX
	JA	JNW1
	CMP	DX,CS:MWIPY
	JNAE	JNW1
	CMP	DX,CS:MWIPYY
	JA	JNW1
	JNJ1:
	POPA
	CALL	CHIDE		;Esconde o cursor do mouse (para nao ficar marcado na tela)
	MOV	WINM,0		;Marca flag: DESENHAR JANELAS NORMALMENTE
	CALL	REWRITE
	PUSHA
	JMP	JNWF
	
	JNW1:
	JMP	LNW1
	;----- END0 --------
	
	JNWF:
	POPA
	CALL	CSHOW
	RET

-------------------------------------------------------------------
;Exibe janela de abertura
;Entra : NADA
;Retorna: Nada, alem de uma alteracao temporaria na memoria de video
INWT:	DB 2,6,' Nanosistemas',0
INWT1:	DB 2,14d,' Vitoria - Brasil',0
INWT2:	DB 13d
	DB 2,6,' Version 04.MAR.2001 for IBM PC',13d
	DB 2,7,' Programmed in 80386 Assembly',0
	
INWSX	EQU	259d
INWSY	EQU	140d	

INIW:	PUSHA
	MOV	USEF,0		;Usar fonte normal
	CALL	CHIDE

	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	DX,INWSY
	MOV	CX,INWSX
	CALL	MWIN		;Desenha caixa de mensagem

	PUSHA
	ADD	AX,17		;Escreve textos
	ADD	BX,21
	MOV	CH,0FFh
	MOV	CL,TXTC
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET INWT
	CALL	TEXT
	INC	BX
	CALL	TEXT
	DEC	BX
	MOV	USEF,1		;Usar fonte pequena
	MOV	SI,OFFSET INWT1
	ADD	AX,16
	ADD	BX,34d
	MOV	CX,150d
	MOV	DL,TXTC
	CALL	LINEH
	MOV	CH,0FFh
	MOV	CL,TXTC
	ADD	AX,3
	SUB	BX,35d
	CALL	TEXT
	
	POPA
	ADD	AX,45
	ADD	BX,21
	MOV	CH,0FFh
	MOV	CL,TXTC
	MOV	SI,OFFSET INWT2
	CALL	TEXT

	CALL	MWINN		;Aguarda OK
	
	POPA
	CALL	CSHOW
	RET

-------------------------------------------------------------------
;Exibe janela de abertura
;Entra : NADA
;Retorna: Nada, alem de uma alteracao temporaria na memoria de video
VNWT:	DB 2,6,' Nanosistemas',0
VNWT1:	DB 2,14d,' Vitoria - Brasil',0
VNWT2:	DB 13d
	DB 2,6,' Version 04.MAR.2001 for IBM PC',13d
	DB 2,7,' Programmed in 80386 Assembly',13
	DB 2,7,'     www.nanosistemas.com',13
	DB 7,3,2,7,'	contact@nanosistemas.com',0
	
VNWSX	EQU	248d
VNWSY	EQU	170d	

VNIW:	PUSHA
	MOV	USEF,0		;Usar fonte normal
	CALL	CHIDE

	MOV	AX,0FFFFh
	MOV	BX,AX
	MOV	DX,VNWSY
	MOV	CX,VNWSX
	CALL	MWIN		;Desenha caixa de mensagem

	PUSHA
	ADD	AX,17		;Escreve textos
	ADD	BX,15
	MOV	CH,0
	MOV	CL,TXTC
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET VNWT
	CALL	TEXT
	INC	BX
	CALL	TEXT
	DEC	BX
	MOV	USEF,1		;Usar fonte pequena
	MOV	SI,OFFSET VNWT1
	ADD	AX,16
	ADD	BX,34d
	MOV	CX,150d
	MOV	DL,TXTC
	CALL	LINEH
	MOV	CH,0
	MOV	CL,TXTC
	ADD	AX,3
	SUB	BX,35d
	CALL	TEXT
	
	POPA
	ADD	AX,45
	ADD	BX,15
	MOV	CH,0
	MOV	CL,TXTC
	MOV	SI,OFFSET VNWT2
	CALL	TEXT

	CALL	MWINN		;Aguarda OK
	
	POPA

	CALL	CSHOW
	RET


-------------------------------------------------------------------
;NANOSISTEMAS. Funcao INPT / SYS.EXT
;Acesso: KERNEL / EXT
;
;Le uma string do teclado
;
;Entra: AX : Pos Y
;	BX : Pos X
;	CH : Numero maximo de caracteres
;	CL : 00 = Proceda normalmente, 01 = Apenas desenhe e retorne
;	DH : Caracteres validos:
;	   Bit 0 - Algarismos (ASCII 30h..39h) (Bits 0,1 e 2=0 ou 1 -> Todos os caracteres sao validos) 
;	   Bit 1 - Letras     (ASCII 41h..5Ah e 61h..7Ah)
;	   Bit 2 - Simbolos   (ASCII 21h..2Fh, 3Ah..40h, 5Bh..60h e 7Bh..7Eh)
;	   Bit 3 - Converter para letras minusculas (Bit 3 e 4 iguais = Nao converter)
;	   Bit 4 - Converter para letras maiusculas (Bit 3 e 4 iguais = Nao converter)
;	   Bit 5 - Reservado 
;	   Bit 6 - Reservado
;	   Bit 7 - Reservado
;	DL : Numero dos bancos a serem chamados a cada tecla pressionada
;	     Dois bancos:
;	     "A" = DL parte baixa (bits 0,1,2,3) : Chamado antes de gravar a tecla na string.
;	     "B" = DL parte alta (bits 4,5,6,7) : Chamado apos gravar a tecla na string
;	     Sera executado um CALL FAR para o endereco contido nos bancos em DL (definidos
;	     pela rotina CBANK) com AX = Codigo do caractere (AH=SCAN,AL=ASCII).
;	     A rotina devera' retornar o controle atraves de um RETF com todos os registradores
;	     sem alteracoes, exeto AX, que podera' ser modificado para "mudar"
;	     a tecla pressionada. Se AX retornar 0000h, entao a tecla nao sera
;	     aceita e a string nao sera atualizada. (no caso do banco "A" - parte baixa)
;	     Se AX retornar FFFFh, o Nanosistemas forcara atualizar a textbox, como se o 
;	     usuario tivesse saido e logo apos retornado a ela.
;	ES:DI : Seg:Ofs do buffer
;
;Retorna:
;	Se a rotina foi abandonada com click do mouse:
;	CX : Pos X do click
;	DX : Pos Y do click
;	BX : Zero
;
;	Se a rotina foi abandonada por alguma tecla:
;	AH : Codigo de varredura da tecla
;	AL : Codigo ASCII da tecla
;	BX : 0FFFFh
;
;	Se a rotina foi chamada com CL=01
;	AX : Pos Y inicial da textbox
;	BX : Pos X inicial da textbox
;	CX : Pos X final da textbox
;	DX : Pos Y final da textbox
;

INDH	DB	0		;DH inicial
INCL	DB	0		;Coluna atual
ITCL	DB	0		;Total de colunas (Numero maximo de colunas possivel)
IBOF	DW	0		;Offset do buffer
IBES	DW	0		;Segmento do buffer
IRPX	DW	0		;Posicao X inicial da textbox (tudo em relacao ao 0,0 do video)
IRPY	DW	0		;Posicao Y inicial da textbox
IRSZ	DW	0		;Tamanho (X) do retangulo
ICPX	DW	0		;Posicao X do cursor
IUCU	DB	0		;Ultima coluna em uso (Zero final)
IUCX	DW	0		;Posicao X da ultima coluna em uso
IATE	DB	0		;00 = Proceda Normalmente, 01 = Apenas esboco
IPXX	DW	0		;Posicao X final da textbox
IPYY	DW	0		;Posicao Y final da textbox
IPCS	DB	0		;Primeira coluna selecionada
IPTS	DB	0		;Total de colunas (a partir da primeira) selecionadas
IPPS	DB	0		;Primeira selecionada (temporario, para uso da rotina de selecao)
IPDL	DB	0		;DL inicial

ITRT:	PUSHA			;Desenha retangulo (Textbox)
	CALL	CHIDE
	MOV	AX,CS:IRPY
	MOV	BX,CS:IRPX
	SUB	AX,2
	SUB	BX,3
	MOV	CX,CS:IRSZ
	ADD	CX,3
	MOV	DX,16
	MOV	CS:IPXX,BX
	ADD	CS:IPXX,CX
	MOV	CS:IPYY,AX
	ADD	CS:IPYY,DX
	MOVZX	SI,BORD
	CALL	RECT

	INC	BX		;Pinta interior
	SUB	CX,1
	SUB	DX,2
	MOVZX	SI,TXBF
	CALL	RECF
	
	MOV	AX,CS:IRPY	;Escreve o texto na tela
	MOV	BX,CS:IRPX
	XOR	CX,CX
	MOV	CL,TBCT
	MOV	DS,CS:IBES
	MOV	SI,CS:IBOF
	CALL	TEXT
	CALL	CSHOW
	POPA
	RET


;Traca o cursor na textbox
ITCR:	PUSHA
	PUSH	DS
	MOV	BX,CS:ICPX	;Traca o cursor
	MOV	SI,CS:IRSZ	;Verifica se o cursor ira aparecer fora dos
	SUB	SI,2
	ADD	SI,CS:IRPX	;limites do retangulo. 
	CMP	BX,SI		
	JAE	JNI1		;Afirmativo, nao traca o cursor

	MOV	SI,OFFSET CURSR ;De outro modo, procede normalmente, desenhando
	MOV	CX,8		;o cursor definido por CS:CURSR (BINMAP)
	MOV	DX,12
	DEC	BX
	MOV	AH,TBCT
	MOV	AL,0FFh
	MOV	DI,AX
	MOV	AX,CS:IRPY
	PUSH	CS
	POP	DS
	CALL	BINMAP
	
	JNI1:
	POP	DS
	POPA
	RET
	
;Inicio da rotina
INPT:	PUSHA
	MOV	CS:IRPX,BX	;Prepara memoria
	MOV	CS:IATE,CL
	MOV	CS:IRPY,AX
	MOV	CS:ITCL,CH
	MOV	CS:IBOF,DI
	MOV	CS:ICPX,BX
	MOV	CS:INDH,DH
	MOV	CS:IBES,ES
	MOV	CS:IPDL,DL
	PUSH	ES		;Prepara registradores para o loop LIN0
	POP	DS
	MOV	SI,DI
	
	PUSHA			;Calcula largura do retangulo
	SHR	CX,8		;que sera desenhado ao redor do texto
	XCHG	AX,CX
	MOV	CX,FSIZ
	MUL	CX
	ADD	AX,2
	MOV	CS:IRSZ,AX
	POPA
	CALL	ITRT		;Traca o primeiro retangulo
	
	INC	CH
	PUSH	AX		;Procura o final na string
	CLD
	MOV	CL,CH
	XOR	AL,AL
	REPNZ	SCASB
	DEC	DI

	MOV	DH,CH		;Em CH o numero de COLs
	SUB	DH,CL		;Em DH a posicao COL.END.
	POP	AX		;Em DI o offset COL.END.
	MOV	CS:INCL,DH
	MOV	CS:IUCU,DH	;Grava ultima coluna em uso	
	
	MOVZX	AX,DH		;Calcula posicao X do cursor
	DEC	AX
	MOV	CX,FSIZ
	MUL	CX
	ADD	AX,CS:IRPX
	MOV	CS:ICPX,AX
	MOV	CS:IUCX,AX
	
	MOV	CS:USEF,1	;Usar fonte pequena
	
	CMP	CS:IATE,1	;Verifica se deve apenas tracar esboco
	JNZ	JIN0		;Caso negativo, prossegue normalmente
	CALL	ITRT		;Traca esboco da Textbox (sem o cursor)
	POPA
	MOV	AX,CS:IRPY	;Prepara registradores para a saida
	MOV	BX,CS:IRPX
	MOV	CX,CS:IPXX	
	MOV	DX,CS:IPYY
	RET			;Abandona rotina
	
	;INICIO DO LOOP PARA CAPTACAO DOS CARACTERES VINDOS DO TECLADO
	;--------------------------------------------------------------
	;---- LOOP0 ------
	LIN0:
	PUSH	DS
	PUSH	40h		;Zera buffer do teclado
	POP	DS		;igualando 40:1A a 40:1C
	MOV	AX,WORD PTR DS:[1Ah]
	MOV	WORD PTR DS:[1Ch],AX
	POP	DS

	CALL	MOUSE		;Aguarda click ou tecla pressionada
	
	TEST	BX,00000011b	;Verifica se saiu com botao do mouse
	JZ	JNI0		;Negativo, verifica tecla pressionada
	;Subrotina: Processa click do mouse na textbox
	;--------------------------------------------------
	CMP	CX,IRPX 	;Afirmativo, verifica se foi clicado no texto
	JNA	JNI0A		;Sempre so pula se nao foi clicado no texto
	CMP	DX,IRPY
	JNA	JNI0A
	CMP	CX,IPXX
	JA	JNI0A
	CMP	DX,IPYY
	JA	JNI0A		;Passando daqui, entao foi clicado dentro da textbox
	SUB	CX,IRPX 	;Calcula a posicao (coluna) do click do mouse
	MOV	AX,FSIZ
	XCHG	AX,CX
	XOR	DX,DX
	DIV	CX		;Em AX o numero da coluna
	CMP	AL,INCL 	;Verifica se esta clicando na coluna atual
	JZ	LIN0		;Afirmativo, volta ao inicio do LOOP (nao opera)
	CMP	AL,IUCU 	;Verifica se a coluna clicada e' maior que a ultima coluna em uso
        JNAE    JNI1A           ;No, jump
	MOV	AL,IUCU 	;Afirmativo, poe a coluna clicada como a ultima utilizada
	DEC	AL
	CMP	AL,INCL 	;Verifica se o cursor ja estava no final da string
	JZ	LIN0		;Afirmativo, nao retraca textbox	
	JNI1A:
	MOV	DI,IBOF 	;Ajusta DI 
	ADD	DI,AX
	MOV	INCL,AL 	;Ajusta numero da coluna atual
	MOV	CX,FSIZ

	MUL	CX		;Ajusta posicao X do cursor
	ADD	AX,IRPX
	MOV	ICPX,AX
	JMP	JIN0		;Retraca a textbox e retorna ao LOOP
	;--------------------------------------------------
	JNI0A:
	JMP	JBMP		;Nao foi clicado no texto, pula pra rotina que retorna (finaliza)
	;--------------------------------------------------

	JNI0:
	;BANCO "A" - ANTES DE GRAVAR TECLA NO BUFFER
	;Verifica o CALL FAR para o banco escolhido.
	PUSH	BX
	MOVZX	BX,IPDL
	AND	BX,1111b
	CALL	ABANK		;Acessa o banco 
	POP	BX

	CMP	AX,0FFFFh	;Verifica se deve atualizar textbox
        JNZ     JNI0B           ;No, jump
	POPA
	JMP	INPT		;Retorna ao inicio da funcao
	JNI0B:
	
	;Fim da verificacao do banco "A"
	CMP	AX,0800h	;ALT+Backspace = Clear textbox
	JNZ	JNI0F
	POPA
	MOV	DWORD PTR ES:[DI],0	;Marca END OF STRING no inicio
	JMP	INPT			;e reinicia funcao
	JNI0F:
	CMP	AH,75d		;Setas para direita e esquerda,
	JZ	JNI0C		;nao sai com tecla pressionada
	CMP	AH,77d
	JZ	JNI0C
	CMP	AH,83d		;DEL, nao sai 
	JZ	JNI0C
	CMP	AH,71d		;HOME, nao sai
	JZ	JNI0C
	CMP	AH,79d		;END, nao sai
	JZ	JNI0C
	CMP	AH,1Ch		;Enter - Abandona
	JZ	JSCT
	CMP	AH,1h		;ESC - Abandona
	JZ	JSCT
	CMP	AH,15d		;TAB - Abandona
	JZ	JSCT
	OR	AL,AL		;ALT+? - Abandona
	JZ	JSCT

	JNI0C:
	;Em AH o scan code
	;Em AL o ASCII code
	
	;Inicio da verificacao dos caracteres validos / conversao
	;-------------------------------------------------------------

	TEST	INDH,111b	;Verifica se todos os tipos de caracteres sao validos
	JZ	JINDH2		;Afirmativo, pula
	
	TEST	INDH,00001b	;Verifica caractere valido: ALGARISMOS
	JNZ	JINDH0		;Sendo validos, pula
	CMP	AL,'0'
	JB	JINDH0
	CMP	AL,'9'
	JNA	LIN0		;Sendo um ALGARISMO (nao valido), retorna ao LOOP
	
	JINDH0:
	TEST	INDH,00010b	;Verifica caractere valido: LETRAS
	JNZ	JINDH1		;Sendo validos, pula
	CMP	AL,41h
	JNAE	JINDH1
	CMP	AL,5Ah
	JNA	LIN0
	CMP	AL,61h
	JNAE	JINDH1
	CMP	AL,7Ah
	JNA	LIN0
	
	JINDH1: 
	TEST	INDH,00100b	;Verifica caractere valido: SIMBOLOS
	JNZ	JINDH2		;Sendo validos, pula
	
	CMP	AL,20h
	JB	JINDH2
	CMP	AL,2Fh
	JNA	LIN0
	
	CMP	AL,3Ah
	JNAE	JINDH2
	CMP	AL,40h
	JNA	LIN0
	
	CMP	AL,5Bh
	JNAE	JINDH2
	CMP	AL,60h
	JNA	LIN0

	CMP	AL,7Bh
	JNAE	JINDH2
	CMP	AL,7Eh
	JNA	LIN0
	
	JINDH2:
	MOV	BL,INDH 	;Verifica se esta marcado para converter
	SHR	BL,3		;para maiusculas e minusculas junto.
	AND	BL,11b		;Se estiver, nao faz nada.
	CMP	BL,3d
	JZ	JINDH4
	
	CMP	AL,41h		;Verifica se e' uma letra
        JNAE    JINDH4          ;No, jump
	CMP	AL,7Ah
	JA	JINDH4
	
	TEST	INDH,01000b	;Verifica se deve converter para MINUSCULAS
        JZ      JINDH3          ;No, jump
	OR	AL,32d		;Afirmativo, converte para minusculas
	
	JINDH3:
	TEST	INDH,10000b	;Verifica se deve converter para MAIUSCULAS
        JZ      JINDH4          ;No, jump
	
	CMP	AL,60h		;Converte para maiusculas
	JNA	JLRD02		;(Converte apenas se for letra minuscula)
	CMP	AL,7Bh
	JAE	JLRD02
	AND	AL,223d 	
	JLRD02:
	
	JINDH4:
	
	;-----------------------------------------------------------------
	;Fim da verificacao dos caracteres validos
	
	
	;-----------------
	CMP	AX,4B00h	;Seta para esquerda
	JNZ	JIN5
	CMP	DI,CS:IBOF	;Verifica se esta no inicio do texto

	JZ	JIN1		;Caso afirmativo, ignora seta para esquerda
	DEC	DI

	DEC	CS:INCL
	SUB	CS:ICPX,FSIZ
	JMP	JIN1
	;-----------------
	
	;-----------------
	JIN5:
	CMP	AX,4D00h	;Seta para direita
	JNZ	JIN4
	MOV	BL,CS:INCL
	CMP	BL,CS:ITCL	;Verifica se esta no final do texto
	JZ	JIN1		;Caso afirmativo, ignora seta para direita
	CMP	BYTE PTR ES:[DI],0	;Verifica se o usuario esta estrapolando
	JZ	JIN1		;Afirmativo, ignora seta para a direita
	INC	DI
	INC	CS:INCL
	ADD	CS:ICPX,FSIZ
	JMP	JIN1
	;-----------------
	
	;-----------------
	JIN4:
	CMP	AX,5300h	;Detecta o DEL
	JNZ	JIN4A
	CMP	BYTE PTR ES:[DI],0	;Verifica se o usuario esta estrapolando
	JZ	JIN1		;Afirmativo, ignora DEL
	INC	DI		;DEL = "Pula pra proxima coluna e da um BS"
	INC	CS:INCL
	JMP	JIN2
	;-----------------
	
	;-----------------
	JIN4A:
	CMP	AX,4700h	;Detecta o HOME
	JNZ	JIN4B
	MOV	DI,IBOF 	;Ajusta DI 
	MOV	INCL,0		;Ajusta numero da coluna atual
	MOV	AX,IRPX 	;Ajusta posicao atual do cursor
	MOV	ICPX,AX
	JMP	JIN0		;Retraca a textbox e retorna ao LOOP
	;-----------------
	
	;-----------------
	JIN4B:
	CMP	AX,4F00h	;Detecta o END
	JNZ	JIN3
	MOV	AH,IUCU
	MOV	INCL,AH 	;Ajusta coluna atual
	MOVZX	DI,IUCU 
	DEC	DI
	ADD	DI,IBOF 	;Ajusta DI
	MOV	AX,IUCX 	;Ajusta posicao atual do cursor
	MOV	ICPX,AX
	JMP	JIN0		;Retraca a textbox e retorna ao LOOP
	;-----------------
	
	;-----------------
	JIN3:
	CMP	AX,0E08h	;BS volta
	JNZ	JIN1
	CMP	DI,CS:IBOF	;Verifica se o cursor esta no inicio
	JZ	JIN1		;Afirmativo, pula a rotina do BS
	SUB	CS:ICPX,FSIZ	;Decrementa posicao X do cursor
	JIN2:			;So havera JUMP pra ca oriundo de JIN4 (DELETE)
	DEC	CS:IUCU 	;Decrementa Ultima Coluna em Uso
	SUB	CS:IUCX,FSIZ	;Subtrai posicao X da ultima coluna em uso
	MOV	SI,DI		;Realiza o BS (ou o DELETE)
	DEC	DI
	PUSH	DI
	CLD
	;- LOOP1 --
	LIN1:
	LODSB
	STOSB
	OR	AL,AL
	JNZ	LIN1
	;- END1 ---
	POP	DI
	DEC	CS:INCL
	JMP	JIN0
	JIN1:
	;-----------------
	
	CMP	AL,32d		;Se nao e' um caractere valido, pula.
	JNAE	JIN0		
	CMP	AL,126d
	JA	JIN0
	
	MOV	BL,CS:ITCL	;Verifica se ja chegou no final do texto
	CMP	CS:INCL,BL
	JA	JIN0		;Afirmativo, nao grava mais
	
	MOV	BL,CS:IUCU	;Verifica se a caixa de texto ja esta cheia
	CMP	CS:ITCL,BL
	JNAE	JIN0		;Afirmativo, nao grava mais
	
	PUSHA			;Rotaciona buffer de memoria, pra frente
	MOVZX	CX,CS:ITCL
	SUB	CL,CS:INCL
	ADD	DI,CX
	MOV	SI,DI
	DEC	SI
	STD
	REP	MOVSB
	POPA
	
	INC	CS:INCL 	;Incrementa COLUNA ATUAL
	INC	CS:IUCU 	;Incrementa Ultima Coluna em Uso
	ADD	CS:IUCX,FSIZ	;Adiciona na posicao X da ultima coluna em uso
	ADD	CS:ICPX,FSIZ	;Incrementa posicao X do cursor
	CLD
	STOSB
	JIN0:
	
	;BANCO "B" - APOS GRAVAR TECLA NO BUFFER
	;Verifica o CALL FAR para o banco escolhido.
	PUSH	BX
	MOVZX	BX,IPDL
	SHR	BX,4
	CALL	ABANK		;Acessa o banco 
	POP	BX

	CMP	AX,0FFFFh	;Verifica se deve atualizar textbox
	JNZ	JNI2B		;Negativo, pula
	POPA
	JMP	INPT		;Retorna ao inicio da funcao
	JNI2B:
	;Fim da verificacao dos bancos

	CALL	CHIDE
	CALL	ITRT		;Retraca o retangulo (REFRESH)
	CALL	ITCR		;Traca cursor	
	CALL	CSHOW
	JMP	LIN0
	;---- END0 ------
	;--------------------------------------------------------------


	JBMP:		;SUBROTINA - ABANDONA COM CLICK DO MOUSE   
	CMP	CX,CS:IRPX	;Verifica se o mouse foi clicado em cima da
	JNAE	JBM0		;textbox atual
	CMP	CX,CS:IPXX
	JA	JBM0
	CMP	DX,CS:IPYY
	JA	JBM0
	ADD	DX,3
	CMP	DX,CS:IRPY
	JNAE	JBM0
	
	;CLICK EM CIMA DA TEXTBOX ATUAL
	;Espaco reservado para possivel rotina
	
	
	
	;Fim do espaco reservado
	
	JMP	LIN0		;Retorna ao LOOP
	
	JBM0:
	CALL	ITRT
	SUB	DX,3
	MOV	CS:TMP1,CX	;Prepara registradores para a saida 
	MOV	CS:TMP2,DX	;da rotina
	POPA	
	MOV	CX,CS:TMP1
	MOV	DX,CS:TMP2
	XOR	BX,BX
	RET

	;--------------
	JSCT:		;SUBROTINA - ABANDONA COM TECLA PRESSIONADA
	MOV	TEMP,AX
	CALL	ITRT		;Retira o cursor da textbox
	POPA
	MOV	BX,0FFFFh	;Prepara registradores para a saida
	MOV	AX,TEMP
	RET			;..e abandona rotina
	;--------------
	INFM:
	POPA
	RET
	
-------------------------------------------------------------------
;Nanosistemas. Rotina BROWSE
;Acesso: CALL BROWSE / EXTERNO
;
;Apresenta um menu para escolha de um ou mais arquivos do disco
;
;Entra: Sempre: 
;	AL	: 00h = DESENHAR e INICIAR interacao com menu
;	AL	: 01h = DESENHAR e CONTINUAR interacao com menu
;	AL	: 10h = NAO DESENHAR e INICIAR interacao com menu
;	AL	: 11h = NAO DESENHAR e CONTINUAR interacao com menu
;	AL	: 20h = INICIAR mas APENAS DESENHAR menu (nao ha interacao)
;	AL	: 21h = CONTINUAR mas APENAS DESENHAR menu (nao ha interacao)
;

;	AH	: 00h = NAO permitir marcar/desmarcar linhas (nem olha pra ES:DI)
;	AH	: 01h = NAO permitir marcar/desmarcar linhas mas apresentar as linhas ja marcadas em ES:DI
;	AH	: 10h = PERMITIR marcar/desmarcar linhas mantendo marcadas as linhas assim apresentadas em ES:DI
;	AH	: 11h = DESMARCAR todas as linhas e PERMITIR usuario marcar/desmarcar
;	
;	DS:SI	: Endereco ASCIIZ do PATH e WILDCATS para busca (0000h = Diretorio atual/*.*)
;	ES:DI	; Endereco do buffer para linhas marcadas
;
;	Se CX=0FFFFh: 
;	DH	: 00h = NAO permitir acesso a disketes e NAO permitir acesso a CDROM
;	DH	: 01h = PERMITIR acesso a disketes e NAO permitir acesso a CDROM
;	DH	: 10h = NAO permitir acesso a disketes e PERMITIR acesso a CDROM
;	DH	: 11h = PERMITIR acesso a disketes e PERMITIR acesso a CDROM
;	DS:BX	: Endereco do B.Inf
;
;	Se CX<0FFFFh:
;	CX	: Posicao X do menu
;	DX	: Posicao Y do menu
;	BH	: Conforme DH descrito acima	
;	
;Retorna: (Sempre)
;	AL	: 00h = Saiu com OK (ENTER)
;	AL	: 01h = Saiu com OK (ICONE)
;	AL	: 02h = Saiu com OK (DOUBLE CLICK)
;	AL	: 10h = Saiu com CANCEL (ESC)
;	AL	: 11h = Saiu com CANCEL (ICONE)
;	AL	: 12h = Saiu com CANCEL (CLICK FORA DOS LIMITES DO MENU)
;	ES:DI	: Endereco do buffer onde estao as linhas marcadas
;	DS:SI	; Endereco do PATH e FILENAME (ASCIIZ) do arquivo escolhido pelo usuario
;
;B.Inf:
;XPOS	WORD	Posicao X do menu
;YPOS	WORD	Posicao Y do menu
;YSIZE	BYTE	Numero de linhas no menu
;TOPO	WORD	Numero da linha inicialmente no topo
;SEL	WORD	Numero da linha inicialmente selecionada
;COR1	BYTE	Cor do texto normal (0FFh = Use padrao)
;COR2	BYTE	Cor do texto selecionado

;COR3	BYTE	Cor do menu normal
;COR4	BYTE	Cor do menu selecionado
;COR5	BYTE	Cor do menu marcado
;COR6	BYTE	Cor do texto marcado
;BUFFER DWORD	Endereco do buffer transitorio para fazer a montagem
;		do menu com os nomes dos diretorios. Sempre termina preenchido
;		com uma entrada B.Inf e na sequencia os nomes dos diretorios
;		e arquivos por ultimo apresentados antes do OK ou CANCEL.
;		Se BUFFER for zero, o sistema usara' um buffer interno proprio.
;		
;	
	
WILD:	DB	'*.*',0 	;Wildcat inicial
BRHD:	DW	100		;Posicao X
	DW	100		;Posicao Y
	DB	13		;Numero de linhas por tela
	DW	0		;Linha inicialmente no topo
	DW	0		;Linha inicialmente selecionada
	DB	0FFh		;Cor do texto normal
	DB	0FFh		;Cor do texto selecionado
	DB	0FFh		;Cor do menu normal
	DB	0FFh		;Cor do menu selecionado
	DB	0FFh		;Cor do menu marcado
	DB	0FFh		;Cor do texto marcado
BRHDF:	
	
BRAL	DB	0		;AL inicial
BRAH	DB	0		;AH inicial
BWES	DW	0		;ES inicial
BRDS	DW	0		;DS wildcats
BRSI	DW	0		;SI wildcats
BRPS	DW	0		;DS path/wildcats
BRPI	DW	0		;SI path/wildcats
BRDI	DW	0		;DI inicial
BRPX	DW	0		;Pos.X inicial
BRPY	DW	0		;Pos.Y inicial
BRSZ	DW	0		;Tamanho maximo do buffer RBDT
BRNW	DB	0		;Numero de wildcats encontrados
BRBH	DB	0		;BH inicial
BRMS	DB	0		;Motivo da saida
BROF	DW	0		;Offset do SCRM.Inf
BRSE	DW	0		;Segmento do SCRM.Inf
BRBUF	DD	0		;Endereco do buffer (0=Use RBDT) (B.inf+15)

BROP	DB	0		;Operacao atual: 
				;0 = Encontre apenas DIRETORIOS
				;1 = Encontre 1o wildcat
				;2 = Encontre 2o wildcat
				;3 = Encontre 3o wildcat...4,5,6..ate' 255.
BROWSE: PUSHA
	PUSH	DS
	PUSH	ES
	
	;Para CX<0FFFFh
	;------------------------
	CMP	CX,0FFFFh	;Usar B.Inf default se CX for<FFFF
	JZ	JBRZ
	MOV	BRSE,CS
	MOV	BROF,OFFSET BRHD
	MOV	BRBH,BH
	MOV	BRBUF,0
	MOV	WORD PTR CS:[OFFSET BRHD],CX
	MOV	WORD PTR CS:[OFFSET BRHD+2],DX
	JMP	JBRNZ
	;------------------------
	
	;Para CX=0FFFFh
	;------------------------
	JBRZ:			;Caso CX=0FFFFh..
	MOV	BRSE,DS 	;Endereco do bloco de parametro
	MOV	BROF,BX
	MOV	BRBH,DH
	PUSH	DWORD PTR DS:[BX+15]
	POP	BRBUF		;Em BRBUF o endereco do buffer proprio
	JBRNZ:	
	;------------------------
		
	MOV	BRAL,AL 	;Salva dados na memoria
	MOV	BRAH,AH
	MOV	BWES,ES
	MOV	BRPI,SI
	MOV	BRPS,DS
	MOV	BRDI,DI
	MOV	BRPX,CX
	MOV	BRPY,DX
	SUB	BRPX,15d
	MOV	BROP,0
	MOV	BRNW,0

	;Encontra ultima barra "\" do PATH dado pelo caller
	;-----------------------------------------------------
	CLD			
	PUSH	DS
	POP	ES
	MOV	DI,SI
	XOR	AL,AL
	MOV	CX,79d
	REPNZ	SCASB
	STD
	MOV	CX,DI
	SUB	CX,SI
	MOV	AL,'\'
	REPNZ	SCASB
	JCXZ	JBROW1		;Se nao ha "\", pula. SI e DI=Inicio da string
	ADD	DI,2		;Se ha "\", aponta SI e DI para o primeiro 
	JBROW1: 		;caractere do primeiro wildcat.
	MOV	SI,DI		;Em SI a posicao do primeiro caractere apos a ultima barra "\"
	MOV	TEMP,DI 	;CS:TEMP=SI
	;-----------------------------------------------------

	;Copia apenas os WILDCATS para CS:PROGRAM
	;Assume-se para esta rotina que os wildcats sao tudo
	;o que esta apos a "\". TUDO significa TUDO entre a "\" 
	;e o ZERO final da string ASCIIZ.
	;Atencao que pode haver mais de um grupo de wildcats.
	;Ex: "C:\DOS\*.EXE *.COM *.BAT"
	;Em CS:PROGRAM, entao, tera': "*.EXE *.COM *.BAT"
	;-----------------------------------------------------
	CLD			
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET PROGRAM
	;------ LOOP1 ------
	LBROWSEA:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	LODSB
	STOSB
	OR	AL,AL
	JNZ	LBROWSEA
	;------ END1 ------
	PUSH	CS
	POP	BRDS
	MOV	BRSI,OFFSET PROGRAM	;BRDS:BRSI aponta para os wildcats
	;-----------------------------------------------------
	
	;Segue abaixo a rotina que ajusta o diretorio
	;e o drive escolhido pelo usuario, assim como
	;a rotina que salva o diretorio atual.
	;Como o usuario entrou em DS:SI um path seguido por
	;wildcats, a rotina abaixo devera separar apenas
	;o path, assim: DS:SI = 'C:\DOS\*.*'
	;A rotina fara' assim:	'C:\DOS',0,'*.*'
	;Um ZERO e' gravado no lugar da ultima barra "\".
	;O diretorio e o drive e' ajustado e depois 
	;essa barra e' restaurada, voltando a string 
	;para 'C:\DOS\*.*' (usando PUSH e POP)
	;-----------------------------------------------------
	MOV	ES,BRPS
	MOV	DI,TEMP 		;Separa o diretorio inicial dos wildcats
	PUSH	WORD PTR ES:[DI-1]	;Salva bytes que serao alterados na string do usuario
	
	MOV	SI,BRPI 		;Verifica se deve retirar a barra "\"
	ADD	SI,3			;Nao devera caso o diretorio seja algo tipo "C:\"
	CMP	DI,SI
	JNA	JBROW0			;Pula se nao deve retirar a barra
	DEC	DI			;Retira a barra
	JBROW0:
	MOV	BYTE PTR ES:[DI],0	;Separa (da string do usuario) o diretorio (path)

	MOV	BYTE PTR CS:[OFFSET OLDDIRE],'\'
	MOV	AH,47h			;Obtem o diretorio atual
	XOR	DL,DL
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET OLDDIRE+1
	INT	21h
	
	MOV	AH,19h			;Obtem o drive atual
	INT	21h
	MOV	OLDDRV,AL
	
	MOV	DI,TEMP
	CMP	DI,BRPI 		;Nao havendo diretorio na string (apenas wildcats)..
	JNA	JBROW2			;Pula.
	
	MOV	AH,3Bh			;Ajusta o diretorio atual
	MOV	DS,BRPS

	MOV	DX,BRPI
	INT	21h

	MOV	AH,0Eh			;Ajusta o drive atual (se necessario)
	MOV	SI,BRPI
	MOV	DS,BRPS
	MOV	DL,BYTE PTR DS:[SI]
	OR	DL,32d
	CMP	DL,97d		;Verifica se o usuario colocou a letra
	JNAE	JEX1A		;do drive antes do diretorio de trabalho
	CMP	DL,120d 	;(ex: D:\dos\norton)
	JA	JEX1A		;     -
	SUB	DL,97d
	INT	21h
	JEX1A:
	JBROW2:
	MOV	DI,TEMP
	POP	WORD PTR ES:[DI-1]	;Restaura bytes alterados na string do usuario
	;-----------------------------------------------------
	
	;Na rotina abaixo, e' contado o numero de wildcats 
	;existentes na string do usuario, assumindo que CS:PROGRAM
	;aponta para o primeiro wildcat, e que o ultimo
	;termina com ZERO, e que sao separados por #32d (espaco).
	;No lugar do #32d, a rotina abaixo colocara' um 0, marcando
	;assim o final de cada wildcat.
	;O numero de wildcats encontrados e' colocado em CS:BRNW.
	;-----------------------------------------------------
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET PROGRAM
	INC	BRNW
	CLD
	;----- LOOP1 ------
	LBROW4:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	LODSB
	CMP	AL,32d
	JNZ	JBROW5
	INC	BRNW
	MOV	BYTE PTR DS:[SI-1],0
	JBROW5:
	OR	AL,AL
	JNZ	LBROW4
	;----- END1 ------
	;Neste ponto, BRNW ja guarda o numero de wildcats encontrados.
	;(LOOP0)
	;-----------------------------------------------------
	JBROWSE:
	
	MOV	AH,1Ah		;AJUSTA DTA. Em CS:DTFILE estara o nome 
	PUSH	CS		;do arquivo encontrado
	POP	DS
	MOV	DX,OFFSET DTABUF
	INT	21h
	
	;Abaixo esta a rotina principal, que encontra os 
	;arquivos definidos pelo usuario e coloca-os
	;no menu para apresentar a parte grafica (ROTINA SCRM).
	;Este label (JBROWSE:) e' o label que sera rechamado
	;cada vez que o usuario escolher um novo diretorio
	;no menu. Assim, a rotina ira' remontar todo o menu
	;com os novos arquivos que estao no novo diretorio
	;escolhido pelo usuario.
	;
	;FLOWS..
	;-----------------------------------------------------
	CALL	SECR			;Ativa seguranca/evita travar loop  
	PUSH	CS
	POP	BRDS
	MOV	BRSI,OFFSET PROGRAM	;BRDS:BRSI aponta para os wildcats
	
	PUSH	CS		;Ajusta. Prepara para gravar arquivos encontrados
	POP	ES		;no buffer CS:RBDT
	MOV	DI,OFFSET RBDT

	CMP	BRBUF,0 	;Verifica se deve usar buffer proprio
	JZ	JBRNUB		;Negativo, pula e mantem o ES:DI apontado para RBDT.
	LES	DI,BRBUF	;Afirmativo, aponta ES:DI pro buffer proprio.
	JBRNUB: 		;Copia o header para o buffer CS:RBDT
	
	LDS	SI,DWORD PTR CS:[OFFSET BROF]
	MOV	CX,OFFSET BRHDF - OFFSET BRHD
	CLD
	REP	MOVSB
	ADD	DI,CX
	;MOV	DWORD PTR CS:[OFFSET BRST],0	;Marca: Proximas chamadas comecar na primeira linha		
	
	;Inicia a rotina de montagem do menu
	;----------------------------------------
	;(LOOP1)
	LBROWSE0:
	CALL	SECR		;Ativa seguranca/evita travar loop  
	MOV	AH,4Eh		;Encontra o primeiro arquivo
	MOV	CX,110111b
	MOV	DS,BRDS
	MOV	DX,BRSI
	CMP	BROP,0		;Verifica se deve procurar pelos diretorios
	JNZ	JBROW4		;Negativo, pula
	PUSH	CS		;Afirmativo, manda int21h procurar por *.*
	POP	DS
	MOV	DX,OFFSET WILD
	JBROW4:
	INT	21h
	JC	JBROW10 	;Arquivo nao encontrado? Pula
	
	;----- LOOP2 -----
	LBROWSE1:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	CLD			;Copia o nome do arquivo de CS:DTFILE
	PUSH	CS		;para CS:RBDT
	POP	DS
	MOV	SI,OFFSET DTFILE
	
	TEST	BYTE PTR CS:[OFFSET DTABUF+15h],00010000b
	JNZ	JBROWSE0	;Pula se for atributo de diretorio
	MOV	AL,130d 	;Marca: ARQUIVO 
	MOV	AH,131d
	CMP	BROP,0		;Verifica se deve inserir os arquivos agora
	JZ	JBROWSE1	;Negativo, pula 
	JMP	JBROWSE2	
	JBROWSE0:
	MOV	AL,128d 	;Marca: DIRETORIO
	MOV	AH,129d
	CMP	BROP,1		;Verifica se deve inserir os diretorios agora
	JZ	JBROWSE1	;Negativo, pula
	JBROWSE2:
	
	STOSW
	MOV	AL,32d
	STOSB
	MOV	CX,20d
	ADD	BRSZ,3
	;----- LOOP3 -----
	LBROWSE2:		;Realiza a copia descrita mais acima.
	CALL	SECR			;Ativa seguranca/evita travar loop  
	LODSB			;Copia os byte um a um ate copiar um ZERO.
	STOSB			;Este ZERO ira finalizar o loop3.
	INC	BRSZ	
	DEC	CX
	JZ	JBROWSE1
	OR	AL,AL
	JNZ	LBROWSE2
	;----- END3 -----
	JBROWSE1:
	
	MOV	AH,4Fh		;Encontra o proximo arquivo
	INT	21h
	JNC	LBROWSE1	;Conseguindo achar o arquivo, retorna ao LOOP2
	;(END2)
	;-------------------------------------
	;Termino da rotina de montagem do menu
	JBROW10:
	
	MOV	AL,BROP 	;Verifica se ja verificou todos os wildcats
	CMP	AL,BRNW
	JAE	JBROWSE3	;Afirmativo, pula
	INC	BROP		;Negativo, volta para procurar pelos arquivos
	MOV	DS,BRDS 	;Passa BRDS:BRSI para o proximo wildcat
	MOV	SI,BRSI
	CMP	BROP,1		;Verifica se e' o primeiro wildcat
	JZ	JBROW6		;Afirmativo, nao passa pro proximo
	CLD
	;----- LOOP1 -----
	LBROW6:
	LODSB
	OR	AL,AL
	JNZ	LBROW6
	;----- END1 -----
	JBROW6:
	MOV	BRDS,DS
	MOV	BRSI,SI
	JMP	LBROWSE0	;Volta ao LOOP
	;(END1)
	;-------------------------------------
		
	JBROWSE3:
	TEST	BRBH,00001111b	;Verifica se deve permitir acesso a disketes
	JZ	JBROW9		;Negativo, pula
	
	;Ja acrescenta Disk Drive A:/B:
	MOV	DWORD PTR ES:[DI],00208786h
	MOV	DWORD PTR ES:[DI+3],'ksiD'		;Grava linha "DiskDrive A"
	MOV	DWORD PTR ES:[DI+7],'virD'
	MOV	DWORD PTR ES:[DI+11],00412065h	
	MOV	DWORD PTR ES:[DI+15],00208786h
	MOV	DWORD PTR ES:[DI+18],'ksiD'		;Grava linha "DiskDrive B"
	MOV	DWORD PTR ES:[DI+22],'virD'
	MOV	DWORD PTR ES:[DI+26],00422065h	
	ADD	DI,30
	
	;*** PROCURA E IDENTIFICA AS LETRAS DE DRIVE
	JBROW9:
	;A rotina abaixo procura pelos drives de C..Z verificando quais respondem.
	;Os que responderem, serao inseridos no menu como uma linha - "Drive X:"
	MOV	AH,19h		;Verifica qual a unidade atual
	INT	21h		;para restaurar depois
	MOV	CBTS,AL 	;Em CBTS (mesmo sendo um contador), a unidade atual
	MOV	DL,1		;Iniciar do drive C
	;--- LOOP1 ---- 
	LBROW8:
	INC	DL		;Passa pro proximo drive
	MOV	CX,25d		;Tentar 25 vezes
	;--- LOOP2 ---- 
	LBROW7:
	MOV	AH,0Eh		;Muda drive atual
	INT	21h		;DL contem novo drive
	
	MOV	AH,19h		;Obtem drive atual
	INT	21h		;AL contem drive atual
	
	DEC	CX		;Verifica se ja tentou 25 vezes
	JZ	JBROW7		;Afirmativo, pula. Drive nao existe.
	
	CMP	AL,DL		;Verifica se mudou
	JNZ	LBROW7		;Negativo, tenta denovo
	;--- END2 ----
	JBROW7:
	JCXZ	JBROW8		;Nao achou o drive? Pula, nao escreve a linha e finaliza loop
	;Numero do drive em DL (0=A,1=B..)
	PUSH	DX
	MOV	AX,150Bh	;Verifica se e' um CDROM
	MOVZX	CX,DL
	INT	2Fh
	OR	AX,AX		;Pula sempre se negativo
	JZ	JBRNOCD0
	CMP	BX,0ADADh
	JNZ	JBRNOCD0

	
	TEST	BRBH,11110000b	;Verifica se deve por CDROM na lista de drives
	JZ	JBRNOCD1	;Pula se negativo
	
	MOV	DWORD PTR ES:[DI],00208988h
	MOV	DWORD PTR [DI+3],'ordC' ;Grava linha "CDROM X"
	MOV	WORD PTR [DI+7],' m'
	JMP	JBRNOCD2			;Pula parte que grava "Drive X"
	
	JBRNOCD0:
	MOV	DWORD PTR ES:[DI],00208584h
	MOV	DWORD PTR [DI+3],'virD' ;Grava linha "Drive X"
	MOV	WORD PTR [DI+7],' e'
	
	JBRNOCD2:
	ADD	DL,65d
	MOV	BYTE PTR ES:[DI+9],DL
	MOV	BYTE PTR [DI+10],0
	ADD	DI,8+3
	JBRNOCD1:
	POP	DX
	JMP	LBROW8		;Retorna ao LOOP e procura pelo proximo drive
	;--- END1 ----
	JBROW8:
	MOV	AH,0Eh		;Restaura drive default
	MOV	DL,CBTS
	INT	21h
	

	MOV	DWORD PTR ES:[DI],0FFFFFFFFh	;Marca o final do menu (para a rotina logo abaixo)

	
	;Chamada a SCRM
	;--------------------------------------
	MOV	AX,WORD PTR CS:[OFFSET BRAL]	;Apresenta o menu com os nomes dos arquivos
	AND	AH,1111b
	MOV	BL,30d
	MOV	BH,0FFh
	PUSH	CS		;ROTINA SCRM
	POP	DS
	MOV	SI,OFFSET RBDT
	
	CMP	BRBUF,0 	;Verifica se deve usar buffer proprio
	JZ	JBRNUB1 	;Negativo, pula e mantem o DS:SI apontado para RBDT.

	LDS	SI,BRBUF	;Afirmativo, aponta DS:SI pro buffer proprio.
	JBRNUB1:		
	
	CALL	SCRM		;*** ACESSO A ROTINA SCRM ***
	;--------------------------------------
	
	MOV	BRMS,AL
	
	TEST	AL,11110000b	;Verifica se houve CANCEL
	JNZ	JBROWSEF	;Afirmativo, pula
	

	PUSH	CS
	POP	DS
	MOV	SI,OFFSET RBDT	;Aponta DS:SI para a linha selecionada
	
	CMP	BRBUF,0 	;Verifica se deve usar buffer proprio
	JZ	JBRNUB2 	;Negativo, pula e mantem o DS:SI apontado para RBDT.
	LDS	SI,BRBUF	;Afirmativo, aponta DS:SI pro buffer proprio.
	JBRNUB2:		
	
	ADD	SI,OFFSET BRHDF - OFFSET BRHD
	JNC	JBRNCSI
	PUSH	AX		;Segment override
	MOV	AX,DS
	ADD	AX,1000h
	MOV	DS,AX
	POP	AX
	JBRNCSI:
	
	OR	DX,DX
	JZ	JBROWSEA
	CLD
	;----- LOOP1 -----
	LBROWSEB:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	LODSB
	OR	AL,AL
	JNZ	LBROWSEB
	DEC	DX
	JNZ	LBROWSEB
	;----- END1 -----

	JBROWSEA:		;DS:SI aponta para a linha selecionada (ASCIIZ)
	
	CMP	BYTE PTR DS:[SI],128d	;Verifica se e' um diretorio
	JNZ	JBROWSEV1		;Pula caso negativo
	ADD	SI,3
	
	MOV	AH,3Bh		;Entra no diretorio escolhido
	MOV	DX,SI
	INT	21h
	JMP	JBROWSEVF	
	
	JBROWSEV1:		
	CMP	BYTE PTR DS:[SI],132d	;Verifica se e' um drive
	JZ	JB1			;Pula caso negativo
	CMP	BYTE PTR DS:[SI],136d	;CDROM
	JNZ	JBROWSEV2
	
	JB1:
	MOV	AH,0Eh		;Muda o drive atual
	MOV	DL,BYTE PTR DS:[SI+9]
	SUB	DL,65d
	INT	21h
	JMP	JBROWSEVF
	
	JBROWSEV2:
	CMP	BYTE PTR DS:[SI],134d	;Verifica se e' um disk drive
	JNZ	JBROWSEV3		;Pula caso negativo
	
	MOV	DL,BYTE PTR DS:[SI+13]
	SUB	DL,65d
	
	PUSH	DS		;Ajusta DEFAULT DRIVE para evitar
	PUSH	50h		;mensagem de erro:							
	POP	DS		;INSERT DISK IN DRIVE B:
	MOV	BYTE PTR DS:[4],DL
	POP	DS
	
	MOV	AH,0Eh		;Muda o drive atual
	INT	21h
	JMP	JBROWSEVF

	JBROWSEV3:
	JMP	JBROWSEF
	
	JBROWSEVF:
	MOV	BROP,0		;Retorna ao LOOP com o novo PATH e WILDCATS
	JMP	JBROWSE
	;(END0) 
	;------------------------------------------------
	JBROWSEF:
	;Monta CS:PROGRAM, onde estara' o nome do arquivo selecionado
	PUSH	SI
	
	MOV	AH,19h			;Pega o drive atual
	INT	21h
	ADD	AL,65d	

	MOV	BYTE PTR CS:[OFFSET PROGRAM],AL
	MOV	WORD PTR CS:[OFFSET PROGRAM+1],'\:'
	

	MOV	AH,47h			;Grava em CS:PROGRAM o diretorio atual
	XOR	DL,DL
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET PROGRAM+3
	INT	21h
	
	CLD				;Encontra zero final
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET PROGRAM
	MOV	CX,0FFFFh
	XOR	AL,AL

	REPNZ	SCASB
	SUB	DI,2

	
	CMP	BYTE PTR ES:[DI],'\'	;Diretorio raiz..
	JZ	JBRO0			;nao coloca barra "\"
	
	INC	DI			;Subdiretorio..
	MOV	BYTE PTR ES:[DI],'\'	;coloca a barra "\"
	
	JBRO0:
	INC	DI			;Prepara para copiar o nome do arquivo
	POP	SI			;selecionado pelo usuario
	ADD	SI,3
	;LOOP1				;Copia nome
	LBROW9:
	LODSB
	STOSB
	OR	AL,AL
	JNZ	LBROW9
	;END1
	
	;Ajusta a unidade (para a unidade de disco do mmac)
	MOV	AH,0Eh
	MOV	DL,OLDDRV
	INT	21h

	;Ajusta o diretorio (para o diretorio do mmac)
	MOV	AH,3Bh
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET OLDDIRE
	INT	21h
		
	POP	ES		;Restaura pilha
	POP	DS
	POPA
	
	MOV	AL,BRMS
	PUSH	CS		;Aponta DS:SI para a string selecionada
	POP	DS
	MOV	SI,OFFSET PROGRAM
	
	RET			;Retorna
	
-------------------------------------------------------------------
;Nanosistemas. Rotina SCRM
;Acesso: CALL SCRM / EXTERNO
;
;Exibe um menu com scroll bar
;
;Entra: AL	: 00h = DESENHAR e INICIAR interacao com menu
;	AL	: 01h = DESENHAR e CONTINUAR interacao com menu
;	AL	: 10h = NAO DESENHAR e INICIAR interacao com menu
;	AL	: 11h = NAO DESENHAR e CONTINUAR interacao com menu
;	AL	: 20h = INICIAR mas APENAS DESENHAR menu (nao ha interacao)
;	AL	: 21h = CONTINUAR mas APENAS DESENHAR menu (nao ha interacao)
;	AH	: 00h = NAO permitir usuario marcar/desmarcar linhas (nem olha pra ES:DI)
;	AH	: 01h = NAO permitir usuario marcar/desmarcar linhas mas apresentar marcadas as linhas que assim ja estiverem
;	AH	: 10h = PERMITIR usuario marcar/desmarcar linhas (manter linhas anteriormente marcadas)
;	AH	: 11h = DESMARCAR todas as linhas e PERMITIR usuario marcar/desmarcar
;	BL	: Tamanho minimo do menu (em caracteres X, colunas)
;	BH	: Tamanho maximo do menu (em caracteres X, colunas)
;	DS:SI	: Endereco do SM.Info
;	ES:DI	: Endereco da tabela de linhas marcadas (se for entrar com AH=01h)
;
;Retorna:
;	DX	: Numero da linha selecionada (primeira linha=0)
;	AL	: 00h = Saiu com OK (ENTER)
;	AL	: 01h = Saiu com OK (ICONE)
;	AL	: 02h = Saiu com OK (DOUBLE CLICK)
;	AL	: 10h = Saiu com CANCEL (ESC)
;	AL	: 11h = Saiu com CANCEL (ICONE)
;	AL	: 12h = Saiu com CANCEL (CLICK FORA DOS LIMITES DO MENU)
;	AL	: 20h = Saiu com outra tecla pressionada, exeto
;			UP/DOWN, PGUP/PGDOWN, HOME/END, ENTER/ESC
;	BH	: SCAN CODE da tecla pressionada (se AL retornar 20h)
;	BL	: ASCII CODE da tecla pressionada (se AL retornar 20h)
;
;SM.Info:
;PX	WORD	;Pos.X do menu
;PY	WORD	;Pos.Y do menu
;YMAX	BYTE	;Maximo de linhas por tela
;SCLT	WORD	;Numero da linha inicialmente no topo (Para o recurso CONTINUAR)
;SCLS	WORD	;Numero da linha inicialmente selecionada (Para o recurso CONTINUAR)
;SCCT	BYTE	;Cor do texto normal (Para todas, 0FFh = Usar padrao do sistema)
;SCTS	BYTE	;Cor do texto selecionado
;SCCM	BYTE	;Cor do menu (partes nao-selecionadas)
;SCCS	BYTE	;Cor do menu (parte selecionada)
;SCLM	BYTE	;Cor do menu (parte marcada)
;SCMT	BYTE	;Cor do texto marcado
;TEXT	ARRAY	;ARRAY. Linhas ASCIIZ. 
;0FFh	BYTE	;Ultima linha (nao sera apresentada) contem 0FFh no inicio (primeiro caractere=0FFh)

;OBS:	INICIAR, como dito acima (na entrada de AL) significa
;	ajustar o menu para a primeira linha (linha #0) no topo.
;	CONTINUAR significa usar o menu do jeito que parou antes.
;	
;	ES:DI na entrada (endereco da tabela de linhas marcadas) consiste
;	em X bytes na memoria onde cada byte corresponde a uma linha.
;	Se a linha for marcada pelo usuario, o byte passa a ser 01h.
;	Se a linha nao estiver marcada, o byte e' 00h.
;	Quem marca os bytes e' a propria rotina SCRM. Mas se o usuario 
;	desejar ajustar este buffer para que tenha inicialmente algumas 
;	linhas ja marcadas, podera faze-lo gravando 00 nas linhas desmarcadas
;	e 01 nas linhas marcadas.
;	Se o usuario entrar AH=11h, a rotina ira automaticamente zerar
;	todos os bytes da tabela de linhas marcadas. Com isso, desmacando
;	todas as linhas.
;
;	As cores deste menu serao as cores padroes do sistema
;
;DEFINICOES DAS ICONES (CADA:16SX/14SY TODAS:16SX/119SY [DECIMAL])

SCIA:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000100000010b
	DW	1000001110000010b
	DW	1000011111000010b
	DW	1000111111100010b
	DW	1001111111110010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCIB:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1001111111110010b
	DW	1000111111100010b
	DW	1000011111000010b
	DW	1000001110000010b
	DW	1000000100000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCIC:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000100000010b
	DW	1000001110000010b
	DW	1000011111000010b
	DW	1000111111100010b
	DW	1001111111110010b
	DW	1000001110000010b
	DW	1000011111000010b
	DW	1000111111100010b
	DW	1001111111110010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCID:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1001111111110010b
	DW	1000111111100010b
	DW	1000011111000010b
	DW	1000001110000010b
	DW	1001111111110010b
	DW	1000111111100010b
	DW	1000011111000010b
	DW	1000001110000010b
	DW	1000000100000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCIF:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000111111100010b
	DW	1000111111100010b
	DW	1000000100000010b
	DW	1000001110000010b
	DW	1000011111000010b
	DW	1000111111100010b
	DW	1001111111110010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0

SCIE:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1001111111110010b
	DW	1000111111100010b
	DW	1000011111000010b
	DW	1000001110000010b
	DW	1000000100000010b
	DW	1000111111100010b
	DW	1000111111100010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCIG:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000000011100010b
	DW	1000000011100010b
	DW	1000001011100010b
	DW	1000011011100010b
	DW	1000111111100010b
	DW	1001111111100010b
	DW	1000111111100010b
	DW	1000011000000010b
	DW	1000001000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCIH:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1001110001110010b
	DW	1000111011100010b
	DW	1000011111000010b
	DW	1000001110000010b

	DW	1000001110000010b

	DW	1000011111000010b
	DW	1000111011100010b
	DW	1001110001110010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCIJ:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1000100010000010b
	DW	1000110011000010b
	DW	1000111011100010b
	DW	1000111111110010b
	DW	1000111111110010b
	DW	1000111011100010b
	DW	1000110011000010b
	DW	1000100010000010b
	DW	1000000000000010b
	DW	1000000000000010b
	DW	1111111111111110b
	DW	0
	
SCIK:	DW	1111111111111110b
	DW	1000000000000010b
	DW	1011111111111010b
	DW	1010000000001010b
	DW	1010000000001010b
	DW	1010011011001010b
	DW	1010001110001010b
	DW	1010001110001010b
	DW	1010011011001010b
	DW	1010000000001010b
	DW	1010000000001010b
	DW	1011111111111010b
	DW	1000000000000010b
	DW	1111111111111110b
	
SCII:	
	DW	1111111111111110b
	DW	1000000000000110b
	DW	1000000100000110b
	DW	1000001110000110b
	DW	1000011111000110b
	DW	1000111111100110b
	DW	1000000000000110b
	DW	1000111111100110b
	DW	1000011111000110b
	DW	1000001110000110b
	DW	1000000100000110b
	DW	1111111111111110b
	DW	1111111111111110b
	

SCPX	DW	0	;Definicao do perimetro
SCPY	DW	0
SCXX	DW	0
SCYY	DW	0
SCSX	DW	0
SCSY	DW	0

SCCT	DB	0	;Cor do texto normal
SCTS	DB	0	;Cor do texto selecionado
SCCM	DB	0	;Cor do menu (partes nao-selecionadas)
SCCS	DB	0	;Cor do menu (parte selecionada)
SCLM	DB	0	;Cor do menu (parte marcada)
SCMT	DB	0	;Cor do texto marcado

SCMM	DB	0	;Tamanho minimo (em caracteres) do menu
SCTL	DW	0	;Total de linhas encontradas no menu
SCLT	DW	0	;Numero da linha no topo
SCLS	DW	0	;Numero da linha selecionada
SCYM	DB	0	;Max. de linhas por tela
SCML	DB	0	;Tamanho (em bytes) da maior linha encontrada
SCTM	DW	0	;Temporario
SCTB	DW	0	;Temporario
SCDS	DW	0	;DS:SI do inicio do texto
SCSI	DW	0	;SI descrito acima
SCBY	DW	0	;Icone movel da scroll bar (pos.Y)
SCSO	DB	0	;Operacao (scroll) : 0 = Disponivel, 1=SEEKING UP, 2=SEEKING DOWN
SCOT	DW	0	;Linha no topo anterior
SCOS	DW	0	;Linha selecionada anterior
SCL1	DW	0	;Linha 1 para atualizar (deselecionar)
SCL2	DW	0	;Linha 2 para atualizar (selecionar)
SCOY	DW	0	;Posicao Y anterior do mouse (para a rotina que rotaciona o menu)
SCOX	DW	0	;Posicao X anterior do mouse (como SCOY acima)
SCAL	DB	0	;AL inicial
SCAH	DB	0	;AH inicial
SCHH	DB	0	;AH inicial (tmp)
SCD0	DW	0	;DS inicial
SCS0	DW	0	;SI inicial
SCES	DW	0	;ES inicial
SCDI	DW	0	;DI inicial
SCBH	DB	0	;BH inicial

SCEX	DB	0	;Parametro de saida (conforme descrito no retorno de AL)
SCBX	DW	0	;BX na saida (Se AL=20h)

;SUBROTINA INTERNA: Desenha todo o menu com todas as linhas e icones
;Entra: NADA
;Retorna: NADA

JSCRM1: PUSHA				;DESENHA MENU
	CMP	AX,0C0CAh		;Tracando pela primeira vez:
	JZ	JSCRM1AL2		;nao verifica alteracoes. Traca o menu.
	
	MOV	AX,SCTL 		;Verifica se a linha selecionada existe
	CMP	AX,SCLS 		
	JA	JSCRM1CJ0		;Afirmativo, pula
	DEC	AX			;Negativo, ajusta linha selecionada
	MOV	SCLS,AX
	JSCRM1CJ0:
	
	MOV	AX,SCTL 		;Verifica se a linha no topo existe
	CMP	AX,SCLT 		
	JA	JSCRM1CJ1		;Afirmativo, pula
	DEC	AX			;Negativo, ajusta linha no topo
	MOV	SCLT,AX
	JSCRM1CJ1:
	
	MOV	AX,SCLT 		;Verifica se houve alguma mudanca
	CMP	AX,SCOT 		;Pula sempre que afirmativo
	JNZ	JSCRM1J0
	MOV	AX,SCLS
	CMP	AX,SCOS
	JNZ	JSCRM1J0		;Passando daqui, nao houve mudancas
	POPA				;e nao precisa de atualizar menu
	RET				;RETORNA AO CALLER	
	JSCRM1J0:
	MOV	AX,SCLT 		;Verifica (especialmente) se houve mudanca na linha do topo
	CMP	AX,SCOT 		;Se nao houve mudanca na linha do topo, entao
	JNZ	JSCRM1J1		;a unica mudanca ocorreu na linha selecionada. (PULA SE NAO HOUVE MUDANCA NA LT)
	MOV	AX,SCLS
	CMP	AX,SCOS
	JZ	JSCRM1J1
	
	MOV	AX,SCLS 		;Entao, marca nas variaveis SCL1 e SCL2
	MOV	SCL2,AX 		;as duas unicas linhas que deverao ser
	MOV	AX,SCOS 		;atualizadas.
	MOV	SCL1,AX
	JMP	JSCRM1J2		;E pula a parte que desmarca estas variaveis	
	JSCRM1J1:
	MOV	DWORD PTR CS:[OFFSET SCL1],0FFFFFFFFh	;0FFFFh aqui significa ATUALIZAR TODAS AS LINHAS
	JSCRM1J2:
	
	MOV	AX,SCLT 		;Atualiza LINHA SELECIONADA e LINHA NO TOPO anteriores
	MOV	SCOT,AX 		;para serem checados posteriormente na proxima
	MOV	AX,SCLS 		;chamada a esta rotina.
	MOV	SCOS,AX
	JSCRM1AL2:
	POPA
	PUSHA
	MOV	DS,SCDS 		;INICIA PREPARACAO PARA DESENHAR O MENU
	MOV	SI,SCSI
	PUSH	SI
	CALL	CHIDE
	MOV	AX,SCPY 		;Desenha retangulo (bordas) do menu
	MOV	BX,SCPX
	DEC	BX
	MOV	CX,SCSX
	INC	CX
	MOV	DX,SCSY
	MOVZX	SI,BORD
	INC	DX
	CALL	RECT
	
	SUB	BX,17			;Desenha todas as icones da esquerda
	DEC	AX
	MOV	CH,TCIB
	MOV	CL,SCCM
	MOV	DI,CX
	MOV	CX,16d
	MOV	DX,119d
	TEST	SCAH,11110000b		;Deve incluir as icones SELECT ALL/DESELECT ALL?
	JZ	JSCRM11 		;Negativo, pula
	MOV	DX,149d 		;Afirmativo, inclui as icones
	JSCRM11:
	MOV	SI,OFFSET SCIA
	PUSH	DS
	PUSH	CS
	POP	DS
	CALL	BINMAP
	
	MOV	BX,SCXX 		;Desenha icones da direita

	INC	BX
	MOV	DX,15
	MOV	SI,OFFSET SCIA
	CALL	BINMAP
	MOV	AX,SCYY
	SUB	AX,14
	MOV	SI,OFFSET SCIB

	CALL	BINMAP
	POP	DS
	
	MOVZX	AX,SCYM 		;Verifica se e' necessario icone de scroll
	CMP	AX,SCTL
	JAE	JBROW3			;Negativo, pula. Nao traca a icone
	
	MOV	AX,SCSY 		;Calcula posicao da icone na scroll bar
	SUB	AX,30
	MOV	CX,SCLT
	MUL	CX
	MOV	CX,SCTL
	MOVZX	BX,SCYM
	SUB	CX,BX
	;OR	CX,CX			;Verifica se havera divisao por ZERO
	;JZ	JSCDIVZ 		;Afirmativo, pula. Nao executa a divisao

	JCXZ	JSCDIVZ 		;AGO99
	DIV	CX			;Em AX o offset Y em relacao ao inicio da scroll bar
	JSCDIVZ:	
	
	MOV	BX,SCYY
	SUB	BX,30
	ADD	AX,SCPY 		;Desenha icone (AX=offset Y.topSCRB)
	ADD	AX,13
	CMP	AX,BX
	JNA	JSCRMSB1
	MOV	AX,BX
	INC	AX
	JSCRMSB1:
	INC	AX
	MOV	BX,SCXX
	INC	BX
	MOV	CH,TCIB
	MOV	CL,SCCM
	MOV	DI,CX
	MOV	CX,16d
	MOV	DX,13d
	MOV	SI,OFFSET SCII
	MOV	SCBY,AX 		;armazena posicao Y da icone da scroll bar
	PUSH	DS
	PUSH	CS
	POP	DS
	CALL	BINMAP
	POP	DS
	
	CALL	PUSHAE			;Salva a area de exclusao
	MOV	AEY,AX			;Ajusta uma area de exclusao para
	ADD	AX,12			;a icone de scroll
	MOV	AEYY,AX
	MOV	AEX,0
	MOV	AX,RX
	MOV	AEXX,AX
	
	JBROW3:
	MOV	BX,SCXX 		;Desenha scroll bar
	ADD	BX,3
	MOV	AX,SCPY
	ADD	AX,15
	MOV	CX,13
	MOVZX	SI,SCCM
	MOV	DX,SCYY
	SUB	DX,SCPY
	SUB	DX,31
	CALL	RECF
	DEC	BX
	INC	CX
	ADD	DX,2
	MOVZX	SI,BORD
	CALL	RECT
	
	MOVZX	SI,SCYM 		;Verifica se foi tracada a icone de scroll
	CMP	SI,SCTL
	JAE	$+5			;Negativo, pula. Nao restaura a area de exclusao
	CALL	POPAE			;Restaura a area de exclusao


	POP	SI			;PREPARA PARA ESCREVER AS LINHAS DE TEXTO
	MOVZX	CX,SCYM 		;Calcula quantas linhas devem ser executadas
	CMP	CX,SCTL
	JNA	JSCRM4
	MOV	CX,SCTL
	JSCRM4:
	MOV	SCTB,CX 		;Em SCTB, o total de linhas a serem executadas
	
	MOV	DX,SCLT
	MOV	SCTM,DX 		;Em SCTM, o numero da primeira linha a ser executada
	
	PUSH	DS
	POP	ES
	
	OR	DX,DX			;Linha do topo=0 ? Pula rotina de ajuste, abaixo.
	JZ	JSCRM5
	PUSH	AX
	CLD				;Aponta DS:SI para a primeira linha a ser executada
	MOV	DI,SI
	;--- LOOP1 ----
	LSCRM2:
	XOR	AL,AL
	MOV	CX,0FFFFh
	REPNZ	SCASB
	DEC	DX
	JNZ	LSCRM2
	;--- END1 ----
	MOV	SI,DI
	POP	AX
	JSCRM5:
	
	MOV	AX,SCPY

	MOV	BX,SCPX
	ADD	AX,3
	ADD	BX,3
	
	;------ LOOP1 --------
	LSCRM1:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	CMP	SCL1,0FFFFh		;Verifica se deve atualizar todas as linhas
	JZ	JSCRM9A 		;Afirmativo, pula
	MOV	CX,SCTM 		;Negativo, verifica quais linhas devem ser atualizadas	
	CMP	SCL1,CX 		;Pula sempre se encontrar
	JZ	JSCRM9A
	CMP	SCL2,CX
	JZ	JSCRM9A
	JMP	JSCRM9			;Nao devendo atualizar esta linha, pula 
	
	JSCRM9A:			
	;------
	PUSHA
	MOV	CX,SCSX 		;Pinta atraz do texto 
	MOV	DX,FALT 		;(desenha background)
	SUB	AX,3

	MOV	BX,SCPX

	MOVZX	SI,SCCM 		;Marca inicialmente LINHA NAO SELECIONADA E NAO MARCADA (cor)

	PUSH	ES
	PUSH	DI

	CMP	SCAH,0			;Verifica se deve considerar linhas marcadas
	JZ	JSCTM8A 		;Negativo, pula
	MOV	DI,SCDI 		;Verifica se a linha e' marcada
	MOV	ES,SCES
	ADD	DI,SCTM
	CMP	BYTE PTR ES:[DI],01h
	JNZ	JSCTM8A 		;Negativo, pula
	MOVZX	SI,SCLM 		;Afirmativo, reajusta cor
	JSCTM8A:
	POP	DI
	POP	ES
	
	MOV	DI,SCLS 		;Verifica se e' a linha selecionada

	CMP	DI,SCTM
	JNZ	JSCTM6			;Negativo, pula
	PUSHA
	TEST	SCAH,11110000b		;Permitir marcar linhas?
	JZ	JSCRM6A 		;Negativo,pula

	CALL	LTR1
	TEST	BX,01b			;Verifica se o botao direito esta pressionado
	JZ	JSCRM6A 		;Pula se negativo
	MOV	ES,SCES 		;Afirmativo, marca/desmarca linha
	MOV	DI,SCDI
	ADD	DI,SCTM
	XOR	BYTE PTR ES:[DI],1d
	JSCRM6A:
	POPA
	MOVZX	SI,SCCS 		;Afirmativo, reajusta cor
	JSCTM6:

	CALL	RECF
	POPA
	;------
	MOV	CH,SCBH
	MOV	CL,SCCT 		;Inicialmente, cor (CL=SCCT)
	
	MOV	DX,SCLS 	
	CMP	DX,SCTM 		;Verifica se esta e' a linha selecionada
	JNZ	JSCRM3
	MOV	CL,SCTS 		;Afirmativo, ajusta cor (CL)
	JSCRM3:

	PUSH	ES
	PUSH	DX
	CMP	SCAH,0			;Verifica se deve exibir linhas marcadas
	JZ	JSCR4			;Negativo, pula
	MOV	DX,SCTM
	MOV	ES,SCES 		;Verifica se e' uma linha selecionada
	MOV	DI,SCDI 
	ADD	DI,DX
	CMP	BYTE PTR ES:[DI],1d
	JNZ	JSCR4			;Negativo, pula
	MOV	CL,SCMT 		;Afirmativo, reajusta a cor
	JSCR4:
	POP	DX
	POP	ES
	
	MOV	USEF,1
	CALL	TEXT			;Escreve texto

	JSCRM9:
	PUSH	AX
	CLD
	MOV	DI,SI
	XOR	AL,AL			;Passa para a proxima linha (em SI)

	MOV	CX,0FFFFh		;procurando pelo proximo zero (0)

	REPNZ	SCASB
	MOV	SI,DI
	POP	AX
	
	ADD	AX,FALT 		;Aponta proximo texto para baixo
	CMP	BYTE PTR DS:[SI],0FFh	;Verifica se chegou ao final do texto
	JZ	JSCTM7			;Afirmativo, pula
	INC	SCTM			;Incrementa numero da primeira linha
	CMP	SCTB,0
	JZ	JSCTM7
	DEC	SCTB			;Decrementa numero de linhas a escrever
	JNZ	LSCRM1			;Ainda nao acabou? Pula e retorna ao LOOP
	;------ END1 --------
	
	JSCTM7: 
	SUB	AX,3
	MOV	CX,SCSX 		;Preenche o resto do menu 
	MOV	DX,AX
	SUB	DX,SCPY
	MOV	BX,SCSY
	SUB	BX,DX
	MOV	DX,BX
	DEC	DX
	MOV	BX,SCPX
	MOVZX	SI,SCCM
	CALL	RECF
	CALL	CSHOW
	
	POPA
	RET

;----------------------------------------------------------
;Inicio da rotina principal - SCRM
;Acesso: CALL SCRM / EXTERNO

SCRM:	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	SCD0,DS
	MOV	SCS0,SI
	MOV	SCAL,AL 
	MOV	SCAH,AH
	MOV	SCHH,AH
	MOV	SCES,ES
	MOV	SCDI,DI
	MOV	SCMM,BL
	MOV	SCBH,BH
	
	MOV	DWORD PTR CS:[OFFSET SCOT],0FFFFFFFFh	;Ajusta vars.
	MOV	DWORD PTR CS:[OFFSET SCL1],0FFFFFFFFh	;0FFFFh aqui significa ATUALIZAR TODAS AS LINHAS
	
	MOV	AX,WORD PTR DS:[SI]	;Armazena coordenadas iniciais na memoria
	MOV	SCPX,AX
	MOV	SCXX,AX
	MOV	AX,WORD PTR DS:[SI+2]
	MOV	SCPY,AX
	MOV	SCYY,AX
	MOV	AL,BYTE PTR DS:[SI+4]
	MOV	SCYM,AL
	
	MOV	EAX,DWORD PTR DS:[SI+9] ;Copia cores para a memoria
	MOV	DWORD PTR CS:[OFFSET SCCT],EAX
	MOV	AX,WORD PTR DS:[SI+13]
	MOV	WORD PTR CS:[OFFSET SCLM],AX
	
	;Ajusta cores padroes do sistema
	CMP	SCCT,0FFh
	JNZ	JCPS0
	MOV	AL,TXTC
	MOV	SCCT,AL
	
	JCPS0:
	CMP	SCTS,0FFh
	JNZ	JCPS1
	MOV	AL,TBCR
	MOV	SCTS,AL
	
	JCPS1:
	CMP	SCCM,0FFh

	JNZ	JCPS2
	MOV	AL,TBCR
	MOV	SCCM,AL
	
	JCPS2:
	CMP	SCCS,0FFh
	JNZ	JCPS3
	MOV	AL,TXTC
	MOV	SCCS,AL
	
	JCPS3:
	CMP	SCLM,0FFh
	JNZ	JCPS4
	
	JCPS4:
	CMP	SCMT,0FFh
	JNZ	JCPS5
	
	JCPS5:

;	AL	: 00h = DESENHAR e INICIAR interacao com menu
;	AL	: 01h = DESENHAR e CONTINUAR interacao com menu
;	AL	: 10h = NAO DESENHAR e INICIAR interacao com menu
;	AL	: 11h = NAO DESENHAR e CONTINUAR interacao com menu
;	AL	: 20h = INICIAR mas APENAS DESENHAR menu (nao ha interacao)
;	AL	: 21h = CONTINUAR mas APENAS DESENHAR menu (nao ha interacao)

	MOV	AX,WORD PTR DS:[SI+5]	;Marca CONTINUAR, ate ver o que deve fazer (abaixo)
	MOV	SCLT,AX
	MOV	AX,WORD PTR DS:[SI+7]
	MOV	SCLS,AX
	
	TEST	SCAL,00001111b		;Verifica se deve INICIAR ou CONTINUAR menu
	JNZ	JSCRMA			;CONTINUAR, pula.
	
	MOV	SCLT,0			;INICIA menu
	MOV	SCLS,0
	
	JSCRMA:
	MOV	SCTL,0			;Zera variaveis
	MOV	BL,SCMM
	MOV	SCML,BL
	MOV	SCTM,0
	
	ADD	SI,15			;Prepara para contagem
	PUSH	SI			;CONTA QUANDAS LINHAS E TAMANHO DA MAIOR LINHA
	CLD
	;----- LOOP1 ------
	LSCRM0:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	LODSB
	CMP	AL,0FFh 		;Achando o codigo de finalizacao
	JZ	JL0F			;Finaliza loop
	INC	SCTM			
	OR	AL,AL
	JNZ	LSCRM0			;Pula se nao encontrou o Zero (final da linha)
	;----- END1 ------
	
	MOV	AX,SCTM
	CMP	SCML,AL
	JA	JSCRM0			;Pula, se a linha lida nao for maior que a anterior
	MOV	SCML,AL 		;Ajusta variavel, se a linha lida for maior que a anterior
	JSCRM0:
	MOV	SCTM,0			;Zera variavel (contador : tamanho da linha atualmente lida)
	INC	SCTL			;Incremente "TOTAL DE LINHAS"
	JMP	LSCRM0			;Retorna ao loop.
	;----- .. GOTO LOOP1
	JL0F:
	
	MOV	AL,SCBH 		;Verifica se a maior linha encontrara 
	CMP	SCML,AL 		;e' maior que o maximo da linhas.
	JNA	JL0FA			;Afirmativo, ajusta tamanho da maior linha
	MOV	SCML,AL 		;encontrada.
	
	JL0FA:
	MOVZX	AX,SCML 		;Calcula tamanho X do menu
	MOV	CX,FSIZ
	MUL	CX
	ADD	AX,3
	MOV	SCSX,AX 		;Tamanho X em SCSX
	ADD	SCXX,AX
	
	MOVZX	AX,SCYM 		;Calcula tamanho Y do menu
	MOV	CX,FALT
	MUL	CX
	ADD	AX,3
	MOV	SCSY,AX 		;Tamanho Y em SCSY
	ADD	SCYY,AX

	CMP	SCAH,11h		;Verifica se deve desmarcar todas as linhas
	JNZ	JSC0			;Negativo, pula
	MOV	CX,SCTL 		;Afirmativo, grava 0 em todo o buffer
	XOR	AL,AL
	MOV	ES,SCES
	MOV	DI,SCDI
	CLD
	REP	STOSB
	JSC0:
	
	POP	SI
	MOV	SCDS,DS 		;Grava DS:SI, que aponta para o inicio
	MOV	SCSI,SI 		;do texto (inicio do ARRAY ASCIIZ)
	
	MOV	AL,SCAL
	SHR	AL,4
	CMP	AL,1			;Verifica se NAO deve desenhar menu
	JZ	JSCRM1B 		;Afirmativo (nao deve), pula
	PUSH	AX
	MOV	AX,0C0CAh
	CALL	JSCRM1			;DESENHA MENU (INICIALMENTE)
	POP	AX
	CMP	AL,2			;Verifica se deve APENAS DESENHAR o menu
	JZ	JSCRMF			;Afirmativo, pula e finaliza a rotina


	;---------------- IDENTIFICA CLICK DENTRO DO MENU
	JSCRM1B:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	CALL	MOUSE			;Le posicoes do mouse/tecla pressionada
	
	TEST	BX,00000011b		;Saiu com tecla pressionada?
	JZ	JSCRM8			;Pula
	
	AND	SCAH,00001111b		;Marca: NAO PERMITIR MARCAR/DESMARCAR LINHAS

	CMP	CX,SCPX 		;Saiu com click do mouse?
	JNA	JSCRMFA 		;Verifica se clicou dentro do menu
	CMP	CX,SCXX 		;Negativo, pula (finaliza rotina)
	JA	JSCRMFA
	CMP	DX,SCPY
	JNA	JSCRMFA
	CMP	DX,SCYY
	JA	JSCRMFA
	
	MOV	AH,SCHH 		;Marca SCAH conforme o usuario ajustou
	MOV	SCAH,AH
	
	MOV	AX,SCLS 		;Verifica se esta clicando em uma linha
	CMP	AX,SCTL 		;que nao existe.
	JAE	JSCRM1C 		;Negativo, pula. Nem checa doubleclick
	
	TEST	BX,00000100b		;Verifica se houve doubleclick
	JZ	JSCRM1C 		;Negativo, pula
	MOV	SCEX,02h		;Afirmativo, marca: SAIU COM OK/DOUBLECLICK
	JMP	JSCRMF			;Finaliza rotina	
	JSCRM1C:

	;ROTINA: CONTROLA CLICKS NAS LINHAS DE TEXTO
	;--------------------------------------------------------
	
	MOV	SCOY,0FFFFh
	;LOOP
	JSCRM1BB:
	CMP	DX,SCPY 		;Pula, se estiver arrastando DOWN
	JNAE	JSCRM1BA
	CMP	DX,SCYY 		;Pula, se estiver arrastando DOWN
	JA	JSCRM1BA
	
	SUB	DX,SCPY 		;VERIFICA POSICAO (CLICK)
	MOV	AX,DX			;Calcula No da linha clicada
	MOV	CX,FALT
	XOR	DX,DX
	DIV	CX
	ADD	AX,SCLT
	MOV	SCLS,AX 		
	
	;LOOP1
	JSCRM1BA:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	CALL	LTR1			;Verifica botoes do mouse
	TEST	BX,00000011b
	JZ	JSCRM1B 		;Retorna ao LOOP se botao esta liberado
	
	CMP	DX,SCOY 		;Verifica se o mouse mexeu
	JNZ	JSCRM1BA2		
	CMP	CX,SCOX
	JZ	JSCRM1BA		;Negativo, retorna ao LOOP
	;END1
	
	JSCRM1BA2:
	MOV	SCOY,DX 		;Salva posicoes que serao as anteriores
	MOV	SCOX,CX
	
	CMP	DX,SCYY 		;DOWN (arrastando, forcando pra baixo)
	JNA	JSCRM1B0
	MOVZX	AX,SCYM
	ADD	AX,SCLT
	CMP	AX,SCTL
	JZ	JSCRM1B0
	MOV	SCLS,AX
	INC	SCLT
	MOV	DWORD PTR CS:[OFFSET SCL1],0FFFFFFFFh	;0FFFFh aqui significa ATUALIZAR TODAS AS LINHAS
	
	JSCRM1B0:
	CMP	DX,SCPY 		;UP (arrastando, forcando pra cima)
	JA	JSCRM1B1
	CMP	SCLT,0
	JZ	JSCRM1B1
	DEC	SCLT
	MOV	DWORD PTR CS:[OFFSET SCL1],0FFFFFFFFh	;0FFFFh aqui significa ATUALIZAR TODAS AS LINHAS
	MOV	AX,SCLT
	MOV	SCLS,AX
	
	JSCRM1B1:
	CALL	JSCRM1			;Atualiza menu 
	JMP	JSCRM1BB
	;END
	;--------------------------------------------------------
	
	;ROTINA: IDENTIFICA E EXECUTA TECLA PRESSIONADA
	;--------------------------------------------------------
	JSCRM8: 			;VERIFICA TECLA PRESSIONADA
	JSCRMTB:
	CMP	AH,72d			;Verifica tecla para cima
	JNZ	JSCRMT0
	CMP	SCLS,0
	JZ	JSCRMT0
	DEC	SCLS
	JMP	JSCRMTF 		;Pula todas as demais comparacoes
	
	JSCRMT0:
	CMP	AH,80d			;Verifica tecla para baixo
	JNZ	JSCRMT1
	MOV	AX,SCTL
	DEC	AX
	CMP	SCLS,AX
	JZ	JSCRMT1
	INC	SCLS
	JMP	JSCRMTF 		;Pula todas as demais comparacoes

	JSCRMT1:
	CMP	AH,73d			;Verifica pgup
	JNZ	JSCRMT2
	MOVZX	AX,SCYM
	CMP	SCLS,AX
	JA	JSCRMTH
	MOV	SCLS,0
	JMP	JSCRMTF
	JSCRMTH:
	SUB	SCLS,AX
	JMP	JSCRMTF 		;Pula todas as demais comparacoes

	JSCRMT2:
	CMP	AH,81d			;Verifica pgdown

	JNZ	JSCRMT3
	MOVZX	AX,SCYM
	ADD	SCLS,AX
	MOV	AX,SCTL
	DEC	AX
	CMP	SCLS,AX
	JNA	JSCRMTF
	MOV	SCLS,AX
	JMP	JSCRMTF 		;Pula todas as demais comparacoes

	JSCRMT3:
	CMP	AH,71d			;Verifica home
	JNZ	JSCRMT4
	MOV	SCLS,0
	JMP	JSCRMTF 		;Pula todas as demais comparacoes
	
	JSCRMT4:
	CMP	AH,79d			;Verifica end
	JNZ	JSCRMT5
	MOV	AX,SCTL
	DEC	AX
	MOV	SCLS,AX
	JMP	JSCRMTF 		;Pula todas as demais comparacoes
	
	JSCRMT5:
	CMP	AH,28d			;Verifica ENTER
	JNZ	JSCRMT6
	MOV	SCEX,00h
	JMP	JSCRMF			;>>> ABANDONA
	
	JSCRMT6:
	CMP	AH,01d			;Verifica ESC
	JNZ	JSCRMT7
	MOV	SCEX,10h
	JMP	JSCRMF			;>>> ABANDONA

	JSCRMT7:
	MOV	SCEX,20h		;Verifica teclas especiais (ASCII=0)
	MOV	SCBX,AX 		;Grava a tecla pressionada
	CMP	AH,72d			;Ignora seta pra cima
	JZ	JSCRMT7B
	OR	AL,AL			
	JZ	JSCRMF			;Afirmativo, pula e finaliza com tecla pressionada
	CMP	AH,15d			;TAB, pula e abandona rotina
	JZ	JSCRMF
	
	JSCRMT7B:
	PUSH	AX			;Verifica se CNTRL ou ALT estao pressionadas
	MOV	AH,2			;Le estado do teclado usando a BIOS
	INT	16h
	MOV	DL,AL
	POP	AX
	
	TEST	DL,1100b		;Verifica CONTROL ou ALT 
	JNZ	JSCRMF			;Afirmativo, pula (finaliza)
	
	OR	AL,20h			;Transforma tudo em letras minusculas
	CMP	AL,97d			;Verifica LETRA pressionada
	JNAE	JSCRMTF 		;Se nao foi letra, pula
	CMP	AL,122d
	JA	JSCRMTF

	MOV	BL,AL			;Em BL a tecla que o usuario escolheu		
	MOV	DI,SCSI
	MOV	ES,SCDS
	MOV	DX,SCLS 		;Aponta DS:SI para a linha selecionada
	MOV	TEMP,DX 		;Em CS:TEMP o numero da linha selecionada
	OR	DX,DX			;Linha selecionada=0 ? Pula rotina de ajuste, abaixo.
	JZ	JSCT5
	CLD				;Prepara para comecar a contagem
	;--- LOOP1 ----
	LSCT2:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	XOR	AL,AL
	MOV	CX,0FFFFh
	REPNZ	SCASB
	DEC	DX
	JNZ	LSCT2
	;--- END1 ----
	JSCT5:				;Em DS:SI tudo que voce queria.
	MOV	SI,DI
	PUSH	ES
	POP	DS
	
	;--- LOOP1 ----
	LSCT0:
	INC	TEMP			;Passa TEMP para a proxima linha
	
	;--- LOOP2 ---- 		;Pula para a proxima linha
	LSCT1:
	CALL	SECR			;Evita que o loop trave
	LODSB
	
	CMP	AL,0FFh 		;Verifica se acabou todas as linhas
	JNZ	JSCT0			;Negativo, pula
	MOV	SI,SCSI 		;Afirmativo, manda SI para o inicio das linhas
	MOV	DS,SCDS
	MOV	TEMP,0			;Aponta TEMP para a primeira linha
	XOR	AL,AL

	JSCT0:
	

	OR	AL,AL
	JNZ	LSCT1
	;--- END2 ----
	
	MOV	DX,TEMP 		;Verifica se ja leu tudo e nao encontrou.
	CMP	DX,SCLS 
	JZ	JSCRMTF 		;Afirmativo, pula
	
	PUSH	SI
	;---- LOOP1 -----
	LSCT3:
	LODSB				;Le a primeira letra da linha
	CMP	AL,122d 		;Verifica se e' uma letra valida (nao uma icone)
	JA	LSCT3			;Negativo, (letra invalida), le a proxima.
	CMP	AL,42d
	JNA	LSCT3
	;---- END1 -----
	POP	SI
	
	OR	AL,20h			;Transforma pra minusculas
	CMP	AL,BL			;Verifica se e' a letra escolhida pelo usuario
	JNZ	LSCT0			;Negativo, retorna ao LOOP e vai procurar pela proxima
	;--- END1 ----
	
	JSCT2:
	PUSH	TEMP			;Grava o numero da linha selecionada
	POP	SCLS
		
	JSCRMTF:
	PUSH	AX			;Ajusta linha selecionada
	MOV	AX,SCTL
	CMP	SCLT,AX
	JNA	JSCRMTD
	MOV	SCLT,AX
	JSCRMTD:
	MOV	AX,SCTL
	CMP	SCLS,AX
	JNA	JSCRMTE
	MOV	SCLS,AX
	JSCRMTE:
	
	MOV	AX,SCLT
	MOVZX	BX,SCYM
	ADD	AX,BX
	DEC	AX
	CMP	SCLS,AX
	JNAE	JSCRMTA
	MOV	BX,SCLS
	SUB	BX,AX
	ADD	SCLT,BX
	JSCRMTA:
	
	MOV	AX,SCLT
	CMP	SCLS,AX
	JAE	JSCRMTC
	MOV	BX,SCLT
	SUB	BX,SCLS
	SUB	SCLT,BX
	JSCRMTC:
	POP	AX
		
	CALL	JSCRM1
	JMP	JSCRM1B
	

	;ROTINA: VERIFICA CLICK DO MOUSE NAS ICONES A ESQUERDA
	;----------------------------------------------------------------
	JSCRMFA:
	MOV	AX,SCPY 		;Verifica se foi clicado nas icones
	MOV	BX,SCPX 		;a esquerda do menu
	DEC	AX
	
	CMP	CX,BX
	JA	JSCRMFB
	SUB	BX,17d
	CMP	CX,BX			;Pula sempre se negativo
	JNA	JSCRMFB
	CMP	DX,AX
	JNA	JSCRMFB
	ADD	AX,150d
	CMP	DX,AX
	JA	JSCRMFB 		;Passando daqui, entao afirmativo.
	
	SUB	DX,SCPY 		;Calcula em qual icone foi clicado
	MOV	CX,15
	MOV	AX,DX
	XOR	DX,DX
	DIV	CX			;Em AL (ou AX) o numero da icone clicada
	
	OR	AL,AL			;ICONE UP
	JNZ	JSCRIA
	CMP	SCLT,0
	JZ	JSCRIA
	DEC	SCLT
	
	JSCRIA:
	CMP	AL,1			;ICONE DOWN
	JNZ	JSCRIB
	MOV	BX,SCTL
	DEC	BX
	CMP	SCLT,BX
	JZ	JSCRIB
	INC	SCLT
	
	JSCRIB:
	CMP	AL,3			;ICONE PGDOWN
	JNZ	JSCRIC
	MOVZX	BX,SCYM
	ADD	BX,SCLT
	INC	BX
	CMP	BX,SCTL
	JA	JSCRI2
	MOVZX	BX,SCYM
	ADD	SCLT,BX
	JMP	JSCRIC
	JSCRI2:
	JSCRIC:
	
	CMP	AL,2			;ICONE PGUP
	JNZ	JSCRID
	MOVZX	BX,SCYM
	CMP	SCLT,BX
	JNA	JSCRI1
	SUB	SCLT,BX
	JMP	JSCRID
	JSCRI1:
	MOV	SCLT,0
	JSCRID:
	
	CMP	AL,4			;ICONE HOME
	JNZ	JSCRIE
	MOV	SCLT,0
	
	JSCRIE:
	CMP	AL,5			;ICONE END
	JNZ	JSCRIF
	MOV	BX,SCTL
	DEC	BX
	MOVZX	CX,SCYM
	CMP	CX,BX
	JA	JSCRIF
	SUB	BX,CX
	MOV	SCLT,BX
	
	JSCRIF:
	CMP	AL,6			;ICONE ENTER
	JNZ	JSCRIG
	CALL	AUSB
	MOV	SCEX,01h
	JMP	JSCRMF			;>>> ABANDONA
	
	JSCRIG:
	CMP	AL,7			;ICONE CANCEL
	JNZ	JSCRIH
	MOV	SCEX,11h		
	JMP	JSCRMF			;>>> ABANDONA
	
	JSCRIH:
	CMP	AL,8			;ICONE SELECT ALL
	JNZ	JSCRIJ
	TEST	SCAH,11110000b		;Verifica se deve permitir usuario marcar/desmarcar icones
	JZ	JSCRIJ			;Negativo, pula
	MOV	ES,SCES 		;Afirmativo, marca todas as linhas
	MOV	DI,SCDI
	MOV	CX,SCTL
	CLD
	MOV	AL,1d
	REP	STOSB
	MOV	DWORD PTR CS:[OFFSET SCL1],0FFFFFFFFh	;0FFFFh aqui significa ATUALIZAR TODAS AS LINHAS
	MOV	SCOS,0FFFFh
	CALL	AUSB
	
	JSCRIJ:
	CMP	AL,9			;ICONE UNSELECT ALL
	JNZ	JSCRIK
	TEST	SCAH,11110000b		;Verifica se deve permitir usuario marcar/desmarcar icones
	JZ	JSCRIK			;Negativo, pula
	MOV	ES,SCES 		;Afirmativo, desmarca todas as linhas
	MOV	DI,SCDI
	MOV	CX,SCTL
	CLD

	XOR	AL,AL
	REP	STOSB
	MOV	DWORD PTR CS:[OFFSET SCL1],0FFFFFFFFh	;0FFFFh aqui significa ATUALIZAR TODAS AS LINHAS
	MOV	SCOS,0FFFFh
	CALL	AUSB
	
	JSCRIK:
	CALL	JSCRM1			;Redesenha menu
	
	MOV	AH,86h			;Suspende sistema por 0.2s aprx
	MOV	DX,16383d
	XOR	CX,CX
	INT	15h
	
	CALL	AUSD			;Aguarda usuario soltar botao direito
	JMP	JSCRM1B
	
	;ROTINA: VERIFICA CLICK DO MOUSE NA SCROLL BARR
	;----------------------------------------------------------------
	JSCRMFB:			;Verifica click na scroll bar
	
	MOV	AX,SCPY 		;Verifica se foi clicado na scroll bar
	MOV	BX,SCXX
	
	MOV	SCEX,12h		;> MARCA: CLICK FORA. Pois se passar por esta rotina 
					;  e a execucao nao for aceita, entao foi clicado fora do menu.
					
	CMP	DX,AX			;Pula sempre que negativo
	JNA	JSCRMF
	CMP	CX,BX
	JNA	JSCRMF
	ADD	BX,16d
	CMP	CX,BX
	JA	JSCRMF
	CMP	DX,SCYY
	JA	JSCRMF			;Passando daqui, entao afirmativo

	MOV	SCEX,0
	PUSH	AX	
	MOVZX	AX,SCYM 		;Verifica se deve abilitar scroll barr
	CMP	AX,SCTL 		;Isso e': Se existem linhas suficientes para isso.
	POP	AX
	JAE	JSCRM1B 		;Negativo, pula
	
	ADD	AX,14			;ICONE ROLL UP
	CMP	DX,AX
	JA	JSCRSA
	CMP	SCLT,0
	JZ	JSCRSA
	DEC	SCLT
	JMP	JSCRSF
	
	JSCRSA:
	MOV	AX,SCYY 		;ICONE ROLL DOWN
	SUB	AX,15
	CMP	DX,AX
	JNA	JSCRSB
	MOV	BX,SCTL
	DEC	BX
	CMP	SCLT,BX
	JZ	JSCRSB
	INC	SCLT
	JMP	JSCRSF
	
	;-- Inicio de subrotina -------
	JSCRSB:
	CMP	DX,SCBY 		;ICONE SCROLL (UP/DOWN. permite arrasta-la)
	JNA	JSCRSC			;Verifica se clicou na icone de scroll up/down
	MOV	AX,SCBY 	
	ADD	AX,15
	CMP	DX,AX
	JA	JSCRSC			;Pula se negativo
	
	CALL	LTR1			;Afirmativo, inicia rotina de scroll
	MOV	AX,DX
	LSCRS0:
	CALL	SECR			;Ativa seguranca/evita travar loop  
	CALL	LTR1			;Le posicao Y do mouse
	TEST	BX,00000011b		;para ajustar a barra de scroll
	JZ	JSCRS0			;de acordo com o mouse
	CMP	AX,DX
	JZ	LSCRS0
	
	MOV	AX,DX			;Limite superior quando arrastando scroll bar
	MOV	BX,SCPY
	ADD	BX,15
	CMP	DX,BX
	JA	JSCRS1
	MOV	DX,BX
	INC	DX
	JSCRS1: 	
	MOV	BX,SCYY 		;Limite inferior quando arrastando scroll bar
	SUB	BX,15
	CMP	DX,BX
	JNA	JSCRS2
	MOV	DX,BX
		
	JSCRS2: 			;AQUI TEMOS: DX : Pos.Y (APENAS ISSO E' NECESSARIO) 
	PUSH	AX
	MOV	AX,SCPY 		;Calcula nova linha no topo

	ADD	AX,15			;AX:=(DX-SCPY)*(SCTL-SCYM)/(SCSY-30)			
	SUB	DX,AX
	MOV	AX,DX
	MOV	CX,SCTL
	MOVZX	BX,SCYM
	SUB	CX,BX
	MUL	CX
	MOV	CX,SCSY
	SUB	CX,30
	DIV	CX			;Em AX o numero da linha no topo
	
	MOV	SCLT,AX
	CALL	JSCRM1
	POP	AX
	JMP	LSCRS0
	JSCRS0:
	JMP	JSCRSF
	;--- Fim de subrotina ------------
	
	JSCRSC:
	CMP	DX,SCBY 		;ESPACO SUPERIOR A ICONE DE SCROLL
	JA	JSCRSD
	MOVZX	BX,SCYM
	CMP	SCLT,BX
	JNA	JSCRS4
	CALL	AUSB
	SUB	SCLT,BX
	JMP	JSCRSD
	JSCRS4:
	MOV	SCLT,0

	JSCRSD:
	MOV	BX,SCBY 		;ESPACO INFERIOR A ICONE DE SCROLL
	ADD	SCBY,16
	CMP	DX,BX
	JNA	JSCRSE
	MOVZX	BX,SCYM
	ADD	BX,SCLT
	CMP	BX,SCTL
	JA	JSCRSE
	MOVZX	BX,SCYM
	CALL	AUSB
	ADD	SCLT,BX
		
	JSCRSE:
	
	JSCRSF:
	CALL	JSCRM1			;Redesenha menu

	CALL	SDLAY
	
	CALL	LTR1			;Verifica se o botao do mouse foi liberado
	TEST	BX,00000011b
	JNZ	JSCRSX			;Negativo, pula
	MOV	SCSO,0			;Afirmativo, marca.
	JSCRSX:
	
	CALL	AUSD			;Aguarda usuario soltar botao direito
	JMP	JSCRM1B 		;Retorna o controle a rotina principal
	
	
	;FINALIZACAO DA ROTINA PRINCIPAL

	;----------------------------------------------------------------
	JSCRMF:
	MOV	DS,SCD0 		;Grava parametros "anteriores"
	MOV	SI,SCS0 		;para ser usado pelo recurso
	MOV	AX,SCLT 		;CONTINUAR na proxima chamada a rotina
	MOV	WORD PTR DS:[SI+5],AX
	MOV	AX,SCLS
	MOV	WORD PTR DS:[SI+7],AX
	
	POP	ES			;Restaura registradores
	POP	DS
	POPA

	MOV	AL,SCEX 		;Ajusta parametros de saida
	
	CMP	AL,00h			;Verifica se saiu com ENTER	
	JNZ	JSCRMF0 		;Negativo, pula
	MOV	DX,SCTL 		;Positivo, verifica se escolheu linha invalida 
	DEC	DX
	CMP	SCLS,DX
	JNA	JSCRMF0 		;Negativo, pula
	MOV	AL,10h			;Afirmativo, marca: Saiu com CANCEL (ESC)
	
	JSCRMF0:
	CMP	AL,20h			;Verifica se saiu com alguma tecla pressionada
	JNZ	JSCRMF1 		;Negativo, pula
	MOV	BX,SCBX 		;Afirmativo, poe em BX o codigo da tecla 
	MOV	SCEX,0			;Desmarca SCEX
	JSCRMF1:

	MOV	DX,SCLS 		;Sempre em DX o numero da linha selecionada
	
	RET				;Finaliza execucao da rotina
	
-------------------------------------------------------------------
;Nanosistemas. Rotina SDLAY
;Acesso: CALL SDLAY / EXTERNO
;
;Causa o atrazo padrao do sistema
;
;Entra: NADA
;Retorna: NADA
SDLAY:	PUSHA
	PUSHF
	PUSH	DS
	PUSH	ES
	
	MOV	AH,86h			;Suspende sistema por 0.2s aprx
	MOV	DX,22383d
	XOR	CX,CX
	INT	15h
	
	POP	ES
	POP	DS
	POPF
	POPA
	RET
	
-------------------------------------------------------------------
;Exibe informacoes do sistema
;Entra: NADA
;Retorna: Alteracoes nos registradores de segmento

SIM1:	DB	'NANOSISTEMAS - Sistem Info',0

SIM2:	DB	'Background BMP file:',0
SIM3:	DB	'ACCEPTED. With'
SIM3A:	DB	' xxx colors.',0
SIM4:	DB	'SORRY, Not a MS-WINDOWS bitmap.',0
SIM4A:	DB	'SORRY, Monochrome image rejected.',0
SIM4B:	DB	'SORRY, Image has more than 240 colors',0
SIM5:	DB	'SORRY, Image has compression',0
SIM6:	DB	'SORRY, Too big',0
SIM7:	DB	'Could not open file.',0
SIM7A:	DB	'Set not to be displayed',0

SIM8:	DB	'Mouse Control:',0
SIM9:	DB	'DOS MOUSE DRIVER (INT 33h)',0
SIM10:	DB	'Hardware access via serial port '
SIM10A: DB	'XXXh',0
SIM11:	DB	'VESA ',1,1,1,'.',1,1,1,',',1,1,1,1,1,' Kb - Video OEM string:',0

HEX:	DB	'0123456789ABCDEF'

SINF:	PUSHA
	MOV	DX,190d 	;Exibe janela
	MOV	CX,300d
	MOV	AX,0FFFFh
	MOV	BX,AX

	CALL	MWIN
	MOV	USEF,1		;Usar fonte normal (grande)
	
	PUSHA			;Grava endereco da porta serial em SIM10A
	PUSH	CS
	POP	DS
	MOV	BX,OFFSET HEX
	MOV	AX,UART
	AND	AL,1111b
	XLAT
	MOV	BYTE PTR CS:[OFFSET SIM10A+2],AL
	MOV	AL,AH
	XLAT
	MOV	BYTE PTR CS:[OFFSET SIM10A],AL
	MOV	AX,UART
	SHR	AL,4
	AND	AL,1111b
	XLAT
	MOV	BYTE PTR CS:[OFFSET SIM10A+1],AL
	POPA
	
	ADD	AX,17		;Escreve texto 1
	ADD	BX,16
	
	PUSHA			;Escreve calendario
	ADD	BX,160d
	MOV	CL,TXTC
	MOV	CH,TBCR
	CALL	DOCAL
	POPA
	
	MOV	CH,0FFh 	;(texto 1 como dito acima)
	MOV	CL,TXTC
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET SIM1
	CALL	TEXT

	ADD	AX,FALT-2
	MOV	CX,265
	XOR	DX,DX
	MOV	DL,TXTC
	CALL	LINEH
	
	MOV	CH,0FFh
	MOV	CL,TXTC
	ADD	AX,FALT
	MOV	SI,OFFSET SIM2	;Escreve texto 2
	MOV	USEF,1		;Usar fonte pequena
	CALL	TEXT
	
	CMP	BMPR,0		;Escreve informacao do BMP
	JNZ	JSI0
	PUSHA
	MOV	DI,OFFSET SIM3A+3
	MOV	AX,BCTC
	SHR	AX,2
	
	LSI0:		;LOOP	;Grava numero de cores encontradas na imagem
	XOR	DX,DX
	MOV	CX,10d
	DIV	CX
	MOV	BX,DX
	MOV	DL,BYTE PTR CS:[HEX+BX]
	MOV	BYTE PTR CS:[DI],DL
	DEC	DI
	CMP	DI,OFFSET SIM3A
	JNZ	LSI0	;END
	
	POPA	
	MOV	SI,OFFSET SIM3
	JSI0:
	CMP	BMPR,1

	JNZ	JSI1
	MOV	SI,OFFSET SIM4
	JSI1:
	CMP	BMPR,2
	JNZ	JSI2
	MOV	SI,OFFSET SIM5
	JSI2:
	CMP	BMPR,3
	JNZ	JSI3
	MOV	SI,OFFSET SIM6
	JSI3:
	CMP	BMPR,4
	JNZ	JSI4
	MOV	SI,OFFSET SIM7
	JSI4:
	CMP	BMPR,5
	JNZ	JSI4A
	MOV	SI,OFFSET SIM4A
	JSI4A:
	CMP	BMPR,6
	JNZ	JSI4B
	MOV	SI,OFFSET SIM4B
	JSI4B:
	CMP	BMPR,7
	JNZ	JSI7A
	MOV	SI,OFFSET SIM7A
	JSI7A:
	ADD	AX,FALT
	CALL	TEXT
	
	MOV	SI,OFFSET SIM8	;Escreve texto "MOUSE"
	ADD	AX,FALT+4
	CALL	TEXT
	
	ADD	AX,FALT 	;Escreve tipo de acesso ao mouse
	MOV	SI,OFFSET SIM9
	CMP	MOUS,0		
	JNZ	JSI5
	MOV	SI,OFFSET SIM10
	JSI5:
	CALL	TEXT
	
	;"Imprime" a versao do VESA
	;-------------
	PUSHA
	MOV	SI,OFFSET SIM11+11
	MOV	AX,VVER
	XOR	AH,AH
	MOV	CL,10d
	LSI110: 	;LOOP
	DIV	CL
	ADD	AH,30h
	MOV	BYTE PTR CS:[SI],AH
	DEC	SI
	OR	AL,AL
	JNZ	LSI110	;END
	
	MOV	SI,OFFSET SIM11+7
	MOV	AX,VVER
	MOV	AL,AH
	XOR	AH,AH
	MOV	CL,10d
	LSI111: 	;LOOP
	DIV	CL
	ADD	AH,30h
	MOV	BYTE PTR CS:[SI],AH
	DEC	SI
	OR	AL,AL
	JNZ	LSI111	;END
	;-------------
	
	;"Imprime" total da memoria de video
	;-------------
	MOV	SI,OFFSET SIM11+17
	MOV	AX,TMVD
	SHL	AX,6
	MOV	CX,10d
	LSI112: 	;LOOP
	XOR	DX,DX
	DIV	CX
	ADD	DL,30h
	MOV	BYTE PTR CS:[SI],DL
	DEC	SI
	OR	AX,AX
	JNZ	LSI112	;END
	POPA
	;-------------
	
	ADD	AX,FALT+4	;Escreve informacoes do video
	MOV	SI,OFFSET SIM11
	CALL	TEXT
	ADD	AX,FALT
	MOV	SI,OEMO
	MOV	DS,OEMS
	MOV	CH,52d		;52 caracteres no maximo
	CALL	TEXT
	
	CALL	MWINN		;Aguarda OK
	POPA			;Retorna
	RET
	
-------------------------------------------------------------------
;Procura por todos os arquivos de extensao MMW que estejam no
;diretorio atual e cadastra-os como janelas
MMWEXT: DB	'*.MMW',0	;Extensao dos arquivos MMW

SEARCH: PUSHA
	CALL	SPATH		;Retorna ao path do sistema
	MOV	INDX,0		;Marca: NENHUMA JANELA NO DESKTOP

	MOV	AH,1Ah		;Ajusta DTA para receber nomes dos arquivos
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET DTABUF
	INT	21h

	MOV	AH,4Eh		;Procura pelo primeiro arquivo
	XOR	CX,CX		;Procura por todos os arquivos
	MOV	DX,OFFSET MMWEXT
	INT	21h
	JC	JSNE		;Se nao encontrou nenhum arquivo, mostra erro
	
	;----- LOOP1 --------
	LSN0:
	MOV	AX,3D00h	;Abre arquivo encontrado
	MOV	DX,OFFSET DTFILE
	INT	21h
	MOV	BX,AX
	
	MOV	AH,3Fh		;Le arquivo encontrado
	MOV	CX,(MMWTS+MMWXS+MMWCS)
	MOV	DX,OFFSET MMWT
	INT	21h
	
	MOV	AL,1		;Verifica checksum do arquivo MMW
	CALL	MCHK
	OR	AL,AL		
	JZ	JSE2		;Aprovada, pula
	IN	AL,60h		;Verifica INS pressionada (nao verificar checksun)
	CMP	AL,82d		;82 - Scan code tecla INS pressionada
	JZ	JSE2		;INS pressionada, aceita arquivo MMW danificado
	MOV	AH,3Eh		;Reprovada,
	INT	21h		;fecha arquivo
	JMP	JSE1		;e pula. Nao cadastra janela
	
	JSE2:	
	MOV	AH,3Eh		;Fecha arquivo, janela foi aceita
	INT	21h
	
	CLD			;Acrecenta ZERO onde deve ter
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET DTFILE
	MOV	AL,'.'
	REPNZ	SCASB
	MOV	DWORD PTR CS:[DI-1],0
	MOV	SI,OFFSET DTFILE
	XOR	AX,AX
	XOR	BX,BX
	XOR	CX,CX
	XOR	DX,DX
	CMP	BYTE PTR CS:[OFFSET MMWC+17d],1 ;Janela oculta?
	JZ	JSE0		;Sim, pula (cadastra janela em 0,0,0,0)
	MOV	AX,MMWY 	;Nao, cadastra nova janela (aberta)
	MOV	BX,MMWX
	MOV	CX,MMWYY
	MOV	DX,MMWXX
	JSE0:
	CALL	WINDOW
	
	JSE1:
	MOV	AH,4Fh		;Encontra proximo arquivo
	INT	21h
	JNC	LSN0		;Se ainda existe algum arquivo MMW, prossegue o LOOP
	;----- END1 --------
	JSNE:
	JSN0:
	POPA
	RET
	
-------------------------------------------------------------------
;Nanosistemas. Funcao FILEN
;Acesso: CALL FILEN / EXTERNO
;
;Dado um nome de arquivo (pode vir acompanhado de path), esta rotina
;verifica se este arquivo ja existe. Se ja existe, tenta colocar
;um numero no final do nome do arquivo. Esse numero e' incrementado
;ate' que o nome do arquivo se torne um nome de arquivo que ainda nao 
;existe.
;OBS: As ultimas letras do nome do arquivo sao substituidas pelos numeros.
;
;Entra:    DS:DX: Endereco do nome do arquivo a ser ajustado
;Retorna:  DS:DX: O nome alterado
;
;
;Nanosistemas. Subrotina FILEX
;Acesso: CALL FILEX / EXTERNO
;
;Verifica se o arquivo ja existe
;
;Entra:    DS:DX: Path/filename
;Retorna:  CX=0 : Nao existe
;	   CX=1 : Existe

;

FLEX	DW	0	;AL na saida

FILEX:	PUSHA
	MOV	FLEX,0		;Marca: Arquivo nao existe
	MOV	AX,3D00h	;Tenta abrir arquivo
	INT	21h
	JC	JFILEXF 	;Erro, pula. Arquivo nao existe
	
	MOV	BX,AX		;Arquivo existe e foi aberto com sucesso. Fecha.
	MOV	AH,3Eh
	INT	21h
	
	MOV	FLEX,1		;Marca arquivo existe		
	JFILEXF:
	POPA			;Finaliza
	MOV	CX,FLEX 	;Em AL a resposta
	RET

	
FNEX	DB	0	;AL na saida
FNBR	DB	0	;Numero do arquivo
;Rotina principal
FILEN:	PUSHA
	PUSH	DS
	PUSH	ES
	
	;Registradores DS:DX nunca mudam
	;LOOP
	LFILEN0:
	CLD
	CALL	FILEX		;Verifica se o arquivo ja existe
	JCXZ	JFILENF 	;Negativo, pula e finaliza rotina
	
	CLD
	PUSH	DS		;Procura final da string
	POP	ES
	MOV	DI,DX
	MOV	CX,0FFFFh
	XOR	AL,AL
	REPNZ	SCASB
	
	NEG	CX		;Procura "\" ou "."
	STD
	MOV	SI,DI
	DEC	SI
	
	;LOOP
	LFILEN1:
	LODSB
	CMP	AL,'\'		;Se encontrar "\", finaliza rotina
	JZ	JFILENF
	CMP	AL,'.'		;Se encontrar ".", prepara para acrescentar numero
	JZ	JFILEN0
	LOOP	LFILEN1 	;Retorna ao loop
	JMP	JFILENF 	;CX=0 (string nao contem "\" nem "."), finaliza
	;END
	
	;ROTINA DE AJUSTE DO NOME DO ARQUIVO
	;
	JFILEN0:		;Acrescenta numero
	CMP	BYTE PTR DS:[SI],30h	;Verifica se o ultimo byte ja e' numero
	JNAE	JFILEN1 		;Pula sempre que negativo
	CMP	BYTE PTR DS:[SI],39h
	JA	JFILEN1
	;Sendo numero...
	INC	BYTE PTR DS:[SI]	;Passa para o proximo
	CMP	BYTE PTR DS:[SI],3Ah	;Verifica se passou do 9
	JNZ	LFILEN0 		;Negativo, retorna ao LOOP e verifica se este existe
	MOV	BYTE PTR DS:[SI],30h	;Afirmativo, zera este..
	DEC	SI			;..e manda rotina processar byte anterior
	JMP	JFILEN0
	;Nao sendo numero...
	JFILEN1:
	MOV	BYTE PTR DS:[SI],30h	;Grava ZERO
	JMP	LFILEN0 		;Retorna ao LOOP e verifica se este arquivo existe
	
	;FIM DA ROTINA
	
	JFILENF:
	POP	ES
	POP	DS
	POPA
	CLD
	RET
-------------------------------------------------------------------
;Nanosistemas. Funcao SSHOT
;Acesso: CALL SSHOT / EXTERNO
;
;Salva o conteudo da tela em um arquivo formato MS-Bitmap 256 cores (8bpp)
;sem compressao.
;
;Entra:    DS:DX: Endereco do path/filename do arquivo a ser criado.
;Retorna:  AX	: 0 = Ok. Arquivo criado ou sobrescrito (caso ja exista)
;	   AX	> 0 = Erro. AX contem codigo de erro 
;
;	WINDOWS BITMAP FILE HEADER
BMPHEAD:DB	'BM'	;Assinatura do BMP
	DD	0	;Tamanho do arquivo em bytes
	DD	0	;Reservado (Deve ser zero)
	DD	1078d	;Offset onde os bytes da imagem comecam
;	WINDOWS BITMAP INFO HEADER
	DD	40d	;Tamanho do INFO HEADER
	DD	0	;Largura do BMP (RX)
	DD	0	;Altura do BMP (RY)
	DW	1	;Numero de planos
	DW	8	;Numero de bits por pixel
	DD	0	;Compressao
	DD	0	;Compressao
	DD	0	;Escala X
	DD	0	;Escala Y
	DD	256d	;Numero de cores utilizadas
	DD	256d	;Numero de cores realmente importantes

SSEX	DW	0	;AX na saida

SSHOT:	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	AH,3Ch	;Cria arquivo
	XOR	CX,CX
	INT	21h
	MOV	SSEX,AX ;Em SSEX o erro
	JC	JSSHOTF ;Erro, pula e finaliza
	MOV	TEMP,AX ;Em TEMP o manipulador
	
	MOV	AX,RX	;Calcula tamanho que o arquivo vai ter 
	MOV	CX,RY
	MOV	WORD PTR CS:[OFFSET BMPHEAD+18],AX	;Grava tamanho X
	MOV	WORD PTR CS:[OFFSET BMPHEAD+22],CX	;e Y do BMP
	MUL	CX
	PUSH	DX
	PUSH	AX
	POP	EAX
	ADD	EAX,1078
	MOV	DWORD PTR CS:[OFFSET BMPHEAD+2],EAX	;Grava tamanho do arquivo
	
	MOV	AH,40h	;Grava header do BMP no arquivo
	MOV	BX,TEMP
	MOV	CX,54d
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BMPHEAD
	INT	21h
	MOV	SSEX,AX ;Em SSEX o erro
	JC	JSSHOTCF;Pula se houve erro
	
	;Comeca a ler as cores da placa de video e gravar em RBDT
	CLD
	MOV	ES,BMEC
	XOR	DI,DI
	MOV	DX,3C8h ;Iniciar leitura da cor zero	
	XOR	AL,AL
	OUT	DX,AL
	MOV	DX,3C9h ;Comeca a ler valores RGB
	MOV	CX,0FFh
	;LOOP
	LSSHOT0:
	XOR	EAX,EAX ;Le os valores RGB da cor e poe em EAX
	IN	AL,DX
	SHL	AL,2
	SHL	EAX,8
	IN	AL,DX
	SHL	AL,2
	SHL	EAX,8
	IN	AL,DX
	SHL	AL,2
	SHL	EAX,8	
	STOSD		;Grava EAX em RBDT
	LOOP	LSSHOT0 ;Se ainda nao terminou, retorna ao LOOP.
	;END
	
	MOV	AH,40h	;Grava RGBSQUAD no arquivo
	MOV	BX,TEMP
	MOV	CX,1024d
	MOV	DS,BMEC
	MOV	DX,5
	INT	21h

	MOV	SSEX,AX ;Em SSEX o erro
	JC	JSSHOTCF;Pula se houve erro
	
	;Comeca a ler os bytes do video e gravar linha a linha no arquivo
	CLD
	MOV	AX,RY
	MOV	CX,RX
	MOV	DX,1
	MOV	BX,0
	;LOOP
	LSSHOT1:
	CALL	SECR
	
	MOV	ES,BMEC
	XOR	DI,DI
	CALL	CAPMAP	;Le uma linha e coloca em RBDT


	MOV	SI,7	;Executar 7 vezes
	;LOOP
	LSSHOT2:
	DEC	AX
	ADD	DI,RX
	CALL	CAPMAP	;Le uma linha e coloca em RBDT
	DEC	SI
	JNZ	LSSHOT2
	;END
	
	PUSHA
	MOV	AH,40h	;Grava as linhas no arquivo
	MOV	BX,TEMP
	MOV	CX,RX
	SHL	CX,3
	MOV	DS,BMEC
	XOR	DX,DX
	INT	21h
	MOV	SSEX,AX ;Em SSEX o erro
	POPA
	JC	JSSHOTCF;Pula se houve erro
	
	DEC	AX
	JNZ	LSSHOT1 ;Se ainda nao terminou, retorna ao LOOP
	;END
	
	MOV	SSEX,0	;Marca: Nao houve erros
	
	JSSHOTCF:
	MOV	AH,3Eh	;Fecha arquivo
	MOV	BX,TEMP
	INT	21h
	
	JSSHOTF:
	POP	ES	;Finaliza
	POP	DS
	POPA
	MOV	AX,SSEX ;Retorna erro (se houve)
	RET

-------------------------------------------------------------------
;Nanosistemas. Funcao SBMP
;Acesso: CALL SBMP / EXTERNO
;
;Exibe o BMP gerado pela funcao BMP preenchendo todo o limite de inclusao
;e ignorando o limite de exclusao, nao importando o estado de RAI e RAE.
;
;Entra: Area de inclusao ajustada conforme necessario  
;Retorna: Alteracoes na memoria de video.

ATSX	DW	0		;Variaveis
ATSY	DW	0
ATPX	DW	0
ATPY	DW	0
ATDX	DW	0
ATDY	DW	0
ATTX	DW	0
ATTY	DW	0
ATOI	DW	0
ATSE	DW	0
ATOF	DW	0

SBMP:	PUSHA
	PUSH	DS
	PUSHF
	
	MOV	AX,RX		;Se esta fora do limite X da tela de video,
	CMP	AIX,AX		;nao traca fundo.
	JAE	JSBE		;Pula e finaliza rotina sem fazer nada
	
	MOV	EAX,BWBP	;Em ATSX, Tamanho X do BMP
	MOV	ATSX,AX
	MOV	EAX,BHBP	;Em ATSY, tamanho Y do BMP
	DEC	AX
	DEC	AX
	MOV	ATSY,AX
	MOV	AX,AIXX
	CMP	AX,AIX		;Verifica se AIXX<AIX.
	JNA	JSBE		;Afirmativo, finaliza rotina
	CMP	AX,RX		;Verifica se vai sair do limite X da tela
	JNAE	JAT11		;Negativo, pula
	MOV	AX,RX		;Afirmativo, reajusta tamanho X
	JAT11:
	SUB	AX,AIX
	MOV	ATTX,AX 	;Em ATTX, tamanho total X
	MOV	AX,AIYY
	CMP	AX,AIY		;Verifica se AIYY<AIY
	JNA	JSBE		;Afirmativo, finaliza rotina
	SUB	AX,AIY
	MOV	ATTY,AX 	;Em ATTY, tamanho total Y
	MOV	AX,BSEG
	MOV	ATSE,AX 	;Em ATSE, o segmento da imagem
	MOV	ATOF,0		;Em ATOF, o offset da imagem
	
	;Solv EQs
	;--------------------------------------------
	;ATPX:=AIX-QUO(AIX/ATSX)*ATSX
	XOR	DX,DX
	MOV	AX,AIX
	DIV	ATSX
	MUL	ATSX
	MOV	DX,AIX

	SUB	DX,AX

	MOV	ATPX,DX
	
	;ATPY:=AIY-QUO(AIY/ATSY)*ATSY
	XOR	DX,DX
	MOV	AX,AIY
	DIV	ATSY
	MUL	ATSY
	MOV	DX,AIY
	SUB	DX,AX
	MOV	ATPY,DX
	
	;ATOI:=ATPY*ATSX+ATPX
	MOV	AX,ATPY

	INC	AX
	MUL	ATSX

	ADD	AX,ATPX
	JNC	JSB10	
	INC	DX
	JSB10:
	MOV	ATOI,AX
	MOV	AX,DX		;Calcula segmento (DX*1000h)
	MOV	CX,1000h
	MUL	CX
	ADD	ATSE,AX
	
	;ATDX:=ATSX-ATPX
	MOV	AX,ATSX
	SUB	AX,ATPX
	MOV	ATDX,AX
	

	;ATDY:=ATSY-ATPY
	MOV	AX,ATSY
	SUB	AX,ATPY
	MOV	ATDY,AX
	
	;Calcula pagina de video e posicao (offset) na pagina
	;----------------------------------------------------
	MOV	AX,AIY
	MOV	BX,AIX
	
	INC	AX
	MUL	CS:RX		;Calcula a pagina e o offset na pagina
	ADD	AX,BX
	JNC	JSB0
	INC	DX
	JSB0:
		
	XCHG	AX,DX		;15NOV98 **********************
	MUL	GRFC
	XCHG	AX,DX

	CMP	DX,CS:OFST	;Verifica se sera necessario pular de pagina
	JE	NSBD		;Caso negativo, ignora a INT 10h
	
	MOV	CS:OFST,DX	;Grava o numero da pagina na memoria
	PUSH	DX
	PUSH	AX
	MOV	AX,4F05h	;Muda a pagina de video
	XOR	BH,BH
	MOV	BL,WJAN
	INT	10h
	POP	AX
	POP	DX
	
	NSBD:
	;Aponta registradores para a memoria de video

	MOV	ES,WSEG
	MOV	DI,AX
	MOV	DS,ATSE
	MOV	SI,ATOI
	MOV	CX,ATTX
	MOV	DX,ATDX
	MOV	AX,AIY
	MOV	BX,AIX
	MOV	TEMP,0
	CLD

	
	;-------- LOOP1 ----------
	LSB0:
	CMP	BX,AEX		;Verifica AREA DE EXCLUSAO
	JNAE	JSB8		;(Pula se ponto for aceito)
	CMP	BX,AEXX
	JA	JSB8
	CMP	AX,AEY
	JNAE	JSB8
	CMP	AX,AEYY
	JA	JSB8
	INC	DI		;Ponto nao foi aceito? Incrementa DI e SI (MOVSB imaginario)
	INC	SI
	JMP	JSB9		;Pula MOVSB real
	
	JSB8:
	MOVSB			;Copia ponto do BMP para a memoria de video
	JSB9:
	INC	BX		;Incrementa posicao X
	OR	DI,DI		;Verifica se deve mudar de pagina
	JNZ	JSB1		;Negativo, pula
	CALL	NEXT		;Positivo, pula para proxima pagina
	JSB1:
	OR	SI,SI		;Verifica se deve passar para proximo 1000h segmento
	JNZ	JSB11		;Negativo, pula
	MOV	SI,DS		;Afirmativo, adiciona 1000h a DS
	ADD	SI,1000h
	MOV	DS,SI		
	XOR	SI,SI
	JSB11:
	
	;SUBROTINA: AJUSTA AS LINHAS DO BMP LADO A LADO NA MESMA LINHA DA IMAGEM
	DEC	DX		;Verifica se chegou no final da linha do BMP
	JNZ	JSB4		;Negativo, pula
	MOV	DX,ATSX 	;Afirmativo... Restaura DX (para repetir a linha do BMP)
	CMP	SI,DX		;Vai ocorrer um BORROW?
	JAE	JSB12		;Negativo, pula
	PUSH	SI		;Afirmativo, decrementa 1000h em DS (volta anterior 1000h segmento)
	MOV	SI,DS		
	SUB	SI,1000h
	MOV	DS,SI
	POP	SI
	JSB12:
	SUB	SI,DX		;Rearma SI (para ler a mesma linha)
	JSB4:
	;ENDS
	
	;SUBROTINA: PASSA PARA PROXIMA LINHA
	DEC	CX		;Verifica se chegou no final da linha (da imagem toda)
	JNZ	JSB5		;Negativo, pula
	
	INC	AX		;Incrementa posicao Y
	MOV	BX,AIX		;Rearma BX (posicao X)
	
	DEC	ATTY		;Afirmativo, verifica se ja terminou de plotar todas as linhas
	JZ	JSBE		;Afirmativo, pula (FINALIZA ROTINA)	

	DEC	ATDY		;Negativo, verifica se ja leu todas as linhas do BMP

	JNZ	JSB6		;Negativo, ainda faltam linhas, pula

	MOV	SI,ATPX 	;Afirmativo, reajusta variaveis na memoria

	MOV	ATOI,SI
	MOV	SI,ATSY
	MOV	ATDY,SI
	MOV	SI,BSEG
	MOV	ATSE,SI 
		

	JSB6:
	MOV	SI,ATSX 	;Afirmativo, manda SI para ler inicio da proxima linha
	ADD	ATOI,SI
	JNC	JSB13		;Nao sendo necessario trocar de segmento, pula
	ADD	ATSE,1000h	;Troca de segmento. Adiciona 1000h a ATSE

	JSB13:
	MOV	SI,RX		;Manda DI para o inicio da proxima linha da imagem

	SUB	SI,ATTX
	ADD	DI,SI		;Necessario troca de pagina?
	JNC	JSB7		;Negativo, pula
	CALL	NEXT		;Afirmativo, manda placa de video passar para a proxima pagina
	JSB7:
	MOV	SI,ATOI 	;Ajusta SI e demais registradores

	MOV	CX,ATTX
	MOV	DX,ATDX
	MOV	DS,ATSE 
	JSB5:
	;ENDS

	JMP	LSB0		;Retorna ao LOOP
	;-------- END1 ----------

	JSBE:	
	POPF


	POP	DS
	POPA
	RET
	
-------------------------------------------------------------------

;Nanosistemas. Funcao BMP

;Acesso: CALL BMP / EXTERNO
;
;Le o arquivo BMP do disco para a memoria alocada pela funcao ALBB.
;Uma vez chamada esta funcao, os dados existentes no buffer
;de endereco dado por bSEG:bOFF serao utilizados pela funcao SBMP
;para preencher o background.
;
;Entra: NADA
;Retorna: Alteracoes na memoria 
;	  Flags, ES e DS alterados

BSIG	DW	0	;Assinatura do BMP ("BM")
BFSZ	DD	0	;Tamanho total do arquivo em bytes
BRES	DD	0	;Reservado
BBBG	DD	0	;Offset de onde comeca os bytes da imagem (no arquivo, e em bytes)


BHSZ	DD	0	;Tamanho (em bytes) do Info Header (De BHSZ-BNCI)

BWBP	DD	0	;Largura do bitmap em pixels
BHBP	DD	0	;Altura do bitmap em pixels
BNOB	DW	0	;Numero de planos (sempre 1)
BBPP	DW	0	;Numero de bits por pixel (deve ser 1,4,8 ou 24)
BCMP	DD	0	;Tipo da compressao (deve ser 0 -> sem compressao)
BNBB	DD	0	;Numero de bytes do bmp (necessario para compressao apenas)
BPXM	DD	0	;Horizontal - Pixels por metro
BPYM	DD	0	;Vertical - Pixels por metro
BNCU	DD	0	;Numero de cores total (2,16,256 ou 4 bilhoes) 
BNCI	DD	0	;Numero de cores realmente utilizadas
BTOC:

BSEG	DW	0	;Segmento do BMP
BOFF	DW	0	;Offset do BMP
BMPH	DW	0	;Handle do arquivo
BMPS	DD	0	;Tamanho (em pixels^2 (area)) do BMP
B32B	DB	0	;Zero-padding for 32-Bit boundary (P#TA M&RDA!) 
BTMM	DD	0	;Tamanho maximo da memoria
BTMA	DD	0	;Memoria atual (tende a BTMM)
BMPR	DB	0	;0 = BMP foi aceito	
			;1 = BMP rejeitado: NAO E' UM BMP
			;2 = BMP rejeitado: POSSUI COMPRESSAO
			;3 = BMP rejeitado: NAO HA MEMORIA CONVENCIONAL SUFICIENTE
			;4 = ARQUIVO NAO ENCONTRADO
			;5 = BMP rejeitado: "BITS POR PIXEL" REJEITADO
			;6 = BMP rejeitado: MAIS DE 240 CORES
			;7 = CONFIGURADO PARA NAO EXIBIR IMAGEM BMP
;*** INICIO DA ROTINA
BMP:	PUSHA
	MOV	BMPD,0		;Marca: BMP ainda nao disponivel
	MOV	BOFF,0
	MOV	BMPR,7		;Marca: CONFIGURADO PARA NAO EXIBIR IMAGEM BMP 
	CMP	BMPY,0		;Verifica se deve mostrar BMP se estiver disponivel
	JZ	JBMPF		;Negativo, pula e finaliza

	MOV	BMPR,4		;Marca erro (potencial)
	MOV	AX,3D00h	;Abre arquivo BMP
	PUSH	CS
	POP	DS

	MOV	DX,OFFSET BMPN
	INT	21h
	JC	JBMPF		;Erro, abandona a rotina
	MOV	BX,AX		
	MOV	BMPH,BX
	
	MOV	AH,3Fh		;Le cabecalho do BMP
	MOV	CX,OFFSET BTOC - OFFSET BSIG
	MOV	DX,OFFSET BSIG
	INT	21h
	CMP	CX,AX		;Verifica se conseguiu ler
	JNZ	JBMPF		;todos os bytes solicitados. Nao, pula.
	
	MOV	EAX,BWBP	;Calcula ajuste para nao-multiplos de 32bits
	AND	AL,11b
	MOV	B32B,4
	SUB	B32B,AL
	
	MOV	EAX,BWBP	;Calcula tamanho do bmp (em pixels)
	MOV	ECX,BHBP
	MUL	CX
	MOV	WORD PTR CS:[OFFSET BMPS],AX
	MOV	WORD PTR CS:[OFFSET BMPS+2],DX
	
	;------ Verifica se o BMP e' valido ---------------
	MOV	BMPR,1		;Marca : Por que BMP foi rejeitado
	CMP	BSIG,19778d	;Verifica se realmente e' um BMP
	JNZ	JBMPN		;Negativo, pula
	

	MOV	BMPR,2		;Marca : Por que BMP foi rejeitado
	CMP	BCMP,0		;Verifica se ha compressao (nao pode)
	JNZ	JBMPN		;Afirmativo, pula
	
	MOV	BMPR,3		;Marca : Por que BMP foi rejeitado
	MOV	CS:BUFA,0	;Zera.
	CALL	ALBB		;Aloca buffer para o BMP
	CMP	CS:BUFA,0	;Nao foi alocado, pula
	JZ	JBMPN

	;Chegando aqui, o BMP e' valido.
	;------ Verifica numero de cores do BMP (bits por pixel)
	MOV	BMPR,5		;Marca : Possivel proximo motivo p/ BMP ser rejeitado
	
	CMP	BBPP,24d	;BMP 24bits por pixel
	JNZ	JBMP0		;Negativo, pula
	MOV	BMPR,0		;Marca: BMP foi aceito
	MOV	BMPD,1		;Marca: BMP disponivel
	MOV	RBCA,9999d	;Prepara memoria para entrada na rotina
	MOV	REOF,0		;Zera contador
	CALL	BMP24		;Manipula BMP 24bpp
	JMP	JBMPN		;Pula para rotina de fechamento do BMP (arquivo)
	JBMP0:
	
	CMP	BBPP,08d	;BMP 8bits por pixel
	JNZ	JBMP1		;Negativo, pula
	MOV	BMPR,0		;Marca: BMP foi aceito
	MOV	BMPD,1		;Marca: BMP disponivel
	MOV	RBCA,9999d	;Prepara memoria para entrada na rotina
	MOV	REOF,0		;Zera contador
	CALL	BMP8		;Manipula BMP 08bpp
	JMP	JBMPN		;Pula para rotina de fechamento do BMP (arquivo)
	JBMP1:
	
	CMP	BBPP,04d	;BMP 4bits por pixel
	JNZ	JBMP2		;Negativo, pula
	MOV	BMPR,0		;Marca: BMP foi aceito
	MOV	BMPD,1		;Marca: BMP disponivel

	MOV	RBCA,9999d	;Prepara memoria para entrada na rotina
	MOV	REOF,0		;Zera contador
	MOV	RB04C,0 	;Zera contador
	CALL	BMP4		;Manipula BMP 04bpp
	JMP	JBMPN		;Pula para rotina de fechamento do BMP (arquivo)
	JBMP2:
	
	JBMPN:
	CMP	BMPD,0		;Verifica se ha BMP disponivel
	JZ	JBMPNF		;Negativo, pula
	CALL	DBDM		;Afirmativo, desinverte imagem
	JBMPNF:
	;------ Fecha o arquivo para finalizar a rotina
	MOV	BX,BMPH
	MOV	AH,3Eh		;Fecha arquivo
	INT	21h
	
	JBMPF:
	
	POPA
	RET
	
;------ ROTINA: Desinverte BMP
;Entra: NADA
;Retorna: NADA
;
DBDM:	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	DS,BSEG
	MOV	SI,BOFF
	MOV	EDX,BHBP
	
	;--- LOOP1 ---
	LDBDM0:
	MOV	ECX,BWBP	;Em CX o tamanho X do BMP
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET RBDT	;DS:SI aponta para o buffer
	CLD
	
	;LOOP2
	LDBDM1: 		;Copia uma linha para o buffer RBDT
	MOVSB
	OR	SI,SI		;Carrier, atualiza DS
	JNZ	JDBDM0
	MOV	AX,DS		;Proximo segmento
	ADD	AX,1000h
	MOV	DS,AX
	JDBDM0:
	LOOP	LDBDM1
	;END2

	PUSH	DS		;ES=DS, DI=SI
	POP	ES
	MOV	DI,SI
	DEC	DI
	
	PUSH	DS
	PUSH	SI
	
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET RBDT
	MOV	ECX,BWBP
	
	;LOOP2
	LDBDM2: 		;Copia a linha de volta para o bloco de memoria.
	CLD			;Mas copia de traz pra frente

	LODSB
	STD
	STOSB
	CMP	DI,0FFFFh	;Borrow, atualiza DS
	JNZ	JDBDM1
	MOV	AX,ES		;Segmento anterior
	SUB	AX,1000h
	MOV	ES,AX
	JDBDM1:
	LOOP	LDBDM2
	;END2
	
	POP	SI
	POP	DS
	DEC	DX		;Verifica se terminou de desinverter todas as linhas
	JNZ	LDBDM0		;Negativo, pula e continua
	;--- END1 ---
	
	POP	ES
	POP	DS
	POPA
	CLD
	RET

	
;------ ROTINA: Manipula BMP com 8bits por pixel
;Entra: NADA
;Retorna: Alteracoes nos registradores de segmento, flags e memoria
;
BCRS	DB	10h		;Reservar as BCRS primeiras cores para o sistema	

BMP8:	PUSHA
	PUSH	WORD PTR CS:BSEG;Prepara memoria

	CLD			;Zera buffer LastResult (Ajuste 240 cores)
	MOV	CX,34d
	XOR	AL,AL
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET RJBF
	REP	STOSB

	MOV	EAX,BNCU
	SHL	AX,2
	MOV	BCTC,AX 	;Zera contador
	
	MOV	AH,3Fh		;Le as cores para o buffer
	MOV	BX,BMPH
	MOV	CX,1024d
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BDTC
	INT	21h

	MOV	SI,OFFSET BDTC	;REDEFINICAO DE PALETE	
	CLD
	
	CLI
	MOV	DX,3C8h 	;Prepara para mudar palete
	MOV	AL,BCRS
	OUT	DX,AL

	MOV	DX,3C9h
	MOVZX	BX,BCRS
	DEC	BX
	
	;---- LOOP1 -----
	LB082:
	ADD	SI,2
	LODSB			;Le (em ordem) os valores RGB
	SHR	AL,2		;RED
	OUT	DX,AL
	
	SUB	SI,2		;GREEN
	LODSB
	SHR	AL,2
	OUT	DX,AL

	SUB	SI,2		;BLUE
	LODSB			;Note que na memoria os bytes estao no formato
	SHR	AL,2		;BLUE GREEN RED. Os bytes estao sendo desinvertidos
	OUT	DX,AL		;(ADD's SI,2 e SUB's SI,2) para serem enviados na ordem certa.

	ADD	SI,3		;Passa para a proxima cor
	INC	BX
	
	CMP	BX,0FFh 	;Verifica se ja mudou todas as cores
	JNZ	LB082		;Nao, prossegue com o loop
	;---- END1 -----
	STI
	
	MOV	EAX,BMPS	;Manda comecar a ler do fim.
	ADD	BOFF,AX 	;A rotina ira ler de traz pra frente
	SHR	EAX,16d 	;para desinverter o BMP , que esta
	MOV	CX,1000h	;invertido no arquivo.
	MUL	CX
	ADD	BSEG,AX
	
	MOV	BX,BMPH 	;Desloca (seek) filepos para inicio do BMP
	MOV	AX,4200h
	XOR	CX,CX
	MOV	EDX,BBBG
	INT	21h
	
	MOV	EAX,BWBP	;CATE marca tamanho da linha (scanline)
	MOV	CATE,AX
	
	;---- LOOP1 -----
	LB080:
	;Subrotina: Ajusta 32-bit boundary
	;Caso BMP em X nao seja multiplo de 4
	;------------------------------------------------------------
	CMP	CATE,0		;Verifica se terminou uma linha (scanline)
	JNZ	JB085		;Negativo, pula
	MOV	EAX,BWBP	;Afirmativo, restaura CATE para a proxima linha
	MOV	CATE,AX
	CMP	B32B,4		;Verifica se o BMP (em largura) e' multiplo de 4
	JZ	JB085		;Afirmativo, pula. Nao precisa de ajuste
	MOVZX	CX,B32B 	;Manda ignorar (no arquivo) os proximos B32B bytes
	MOV	AX,1
	;LOOP
	LB083:			
	CALL RB24
	LOOP	LB083
	;END
	JB085:
	DEC	CATE
	;------------------------------------------------------------
	
	;Le um byte do arquivo BMP
	MOV	AX,1
	CALL	RB24		;Le 1 byte do arquivo e poe em BL
	MOV	AL,BL
	
	;Subrotina: Grava byte em AL no buffer da imagem
	;Entra: AL : Numero da cor
	;Retorna: Alteracoes no buffer da imagem e em DI,ES e flags
	;------------------------------------------------------------
	JB082:
	STD			;Gravar de traz pra frente
	ADD	AL,BCRS 	;Reservar as BCRS primeiras cores
	JNC	$+5		;Nao javendo carrier, pula
	CALL	REAJ		;Reajusta a cor, ja que passou das 240 primeiras
	CMP	BMPS,0		;analizando o numero de pixels lidos com RXxRY 
	JZ	JB083		;Afirmativo, pula
	MOV	ES,BSEG 	;Grava numero da cor na memoria (buffer da imagem)
	MOV	DI,BOFF
	STOSB
	CMP	DI,0FFFFh	;Verifica se ouve BORROW
	JNZ	JB084		;Nao, pula
	MOV	AX,ES		;Atualiza ES
	SUB	AX,1000h
	MOV	ES,AX
	JB084:
	CLD
	DEC	BMPS		
	MOV	BSEG,ES
	MOV	BOFF,DI
	;------------------------------------------------------------
	;Fim da subrotina
	
	JMP	LB080		;Retorna com o loop
	;---- END1 -----
	;Fim da rotina 1 (leitura do arquivo BMP)
	JB083:
	POP	WORD PTR CS:BSEG;Restaura BSEG
	POPA			;Terminou.
	RET
	
;Subrotina interna da subrotina BMP8
;Reajusta a cor em AL (0..10h)
;Entra: AL : Cor para ser reajustada
;Retorna: AL : Cor reajustada

RJBF	DB 17 dup (0)	;Buffer: Contem os LastResults
RJBS	DB 17 dup (0)	;Buffer: Contem o status (0=Ainda nao,1=Ja tem LastResult)

REAJ:	PUSHA

	MOVZX	BX,AL				;Verifica LastResult			
	CMP	BYTE PTR CS:[OFFSET RJBS+BX],1
	JNZ	JREAJ0
	MOV	AL,BYTE PTR CS:[OFFSET RJBF+BX]
	MOV	CBTE,AL
	JMP	JREAJ1
		
	JREAJ0:
	MOV	BYTE PTR CS:[OFFSET RJBS+BX],1	;Marca: Cor ja foi processada
	
	MOV	SI,OFFSET BDTC+956		;Poe SI=Offset RGBsquad da cor 
	XOR	AH,AH
	SHL	AX,2
	ADD	SI,AX

	MOV	CL,BYTE PTR CS:[SI]		;Procura pela cor mais proxima
	MOV	CH,BYTE PTR CS:[SI+1]
	MOV	DL,BYTE PTR CS:[SI+2]
	SHR	CL,2
	SHR	CH,2
	SHR	DL,2
	MOV	DH,0FFh
	CALL	CLOSER

	MOV	CBTE,CL
	MOV	BYTE PTR CS:[OFFSET RJBF+BX],CL ;Grava resultado (LastResult)
	
	JREAJ1:
	POPA
	MOV	AL,CBTE 			;Em AL o resultado
	RET

;------ ROTINA: Manipula BMP com 4bits por pixel
;Entra: NADA
;Retorna: Alteracoes nos registradores de segmento, flags e memoria
;

BMP4:	PUSHA
	PUSH	WORD PTR CS:BSEG;Prepara memoria
	
	CMP	B32B,4		;Verifica se BMP precisa de mais ajuste
	JZ	JBMP40		;(32-bit boundering). Negativo, pula
	
	MOVZX	EBX,B32B	;Ajuste p/4 bits (meio byte)
	MOV	EAX,BWBP	
	ADD	EAX,EBX
	SHR	EAX,1
	AND	AL,11b
	SHL	AL,1
	ADD	B32B,AL
	
	JBMP40:
	MOV	EAX,BNCU
	SHL	AX,2
	MOV	BCTC,AX 	;Zera contador
	
	MOV	AH,3Fh		;Le as cores para o buffer
	MOV	BX,BMPH
	MOV	CX,64d
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET BDTC
	INT	21h
	
	MOV	EAX,BMPS	;Manda comecar a ler do fim.
	ADD	BOFF,AX 	;A rotina ira ler de traz pra frente
	SHR	EAX,16d 	;para desinverter o BMP , que esta

	MOV	CX,1000h	;invertido no arquivo.
	MUL	CX
	ADD	BSEG,AX
	
	MOV	BX,BMPH 	;Desloca (seek) filepos para inicio do BMP
	MOV	AX,4200h
	XOR	CX,CX
	MOV	EDX,BBBG
	INT	21h
	
	MOV	EAX,BWBP	;CATE marca tamanho da linha (scanline)
	MOV	CATE,AX
	
	;---- LOOP1 -----
	LB040:
	;Subrotina: Ajusta 32-bit boundary
	;Caso BMP em X nao seja multiplo de 4
	;------------------------------------------------------------
	CMP	CATE,0		;Verifica se terminou uma linha (scanline)
	JNZ	JB045		;Negativo, pula
	MOV	EAX,BWBP	;Afirmativo, restaura CATE para a proxima linha
	MOV	CATE,AX
	CMP	B32B,4		;Verifica se o BMP (em largura) e' multiplo de 4
	JZ	JB045		;Afirmativo, pula. Nao precisa de ajuste
	MOVZX	CX,B32B 	;Manda ignorar (no arquivo) os proximos B32B bytes
	;LOOP
	LB043:			
	CALL	RB04
	LOOP	LB043
	;END
	JB045:
	DEC	CATE
	;------------------------------------------------------------
	
	;Le um byte do arquivo BMP
	CALL	RB04		;Le meio byte do arquivo e poe em BL
	MOV	AL,BL
	
	;Subrotina: Grava byte em AL no buffer da imagem
	;Entra: AL : Numero da cor
	;Retorna: Alteracoes no buffer da imagem e em DI,ES e flags
	;------------------------------------------------------------
	JB042:
	STD			;Gravar de traz pra frente
	ADD	AL,BCRS 	;Reservar as 16 primeiras cores
	CMP	BMPS,0		;analizando o numero de pixels lidos com RXxRY 
	JZ	JB043		;Afirmativo, pula
	MOV	ES,BSEG 	;Grava numero da cor na memoria (buffer da imagem)
	MOV	DI,BOFF
	STOSB
	CMP	DI,0FFFFh	;Verifica se ouve BORROW
	JNZ	JB044		;Nao, pula
	MOV	AX,ES		;Atualiza ES
	SUB	AX,1000h
	MOV	ES,AX
	JB044:
	CLD
	DEC	BMPS		
	MOV	BSEG,ES
	MOV	BOFF,DI
	;------------------------------------------------------------
	;Fim da subrotina
	
	JMP	LB040		;Retorna com o loop
	;---- END1 -----
	;Fim da rotina 1 (leitura do arquivo BMP)
	JB043:
	
	MOVZX	BX,BCRS 	;Prepara para ajustar as cores
	DEC	BX
	MOV	SI,OFFSET BDTC	
	CLD
	PUSH	CS
	POP	DS

	;---- LOOP1 -----
	LB042:
	LODSB			;Le (em ordem) os valores RGB
	MOV	CL,AL
	LODSB
	MOV	CH,AL
	LODSB
	MOV	DH,AL
	INC	SI		;Pula o 0 (ZERO) do RGBSQUAD
	INC	BX
	SHR	CL,2		;Divide todas as cores por 4
	SHR	CH,2
	SHR	DH,2
	MOV	AX,1010h
	INT	10h		;Muda registrador RGB da cor
	CMP	BX,0FFh 	;Verifica se ja mudou todas as cores
	JNZ	LB042		;Nao, prossegue com o loop
	;---- END1 ----- 
	
	POP	WORD PTR CS:BSEG;Restaura BSEG
	POPA			;Terminou.
	RET
	
;Subrotina interna exclusiva:
;Le meio byte para BL
RB04C	DB	0	;Contador: Numero do byte a ler
RB04B	DB	0	;Byte anteriormente lido

RB04:	PUSH	CX
	PUSH	AX

	CMP	RB04C,0 ;Verifica se e' a primeira metade do byte
	JNZ	JRB040	;Negativo (e' a segunda) pula
	
	MOV	AX,1	;Le 1 byte do disco
	CALL	RB24
	MOV	RB04B,BL
	INC	RB04C	;Marca: Para a proxima chamada, devolva a segunda metade
	AND	BL,1111b;Poe a primeira metade do byte em BL
	JMP	JRB04F	;E retorna
	
	JRB040:
	MOV	RB04C,0 ;Marca: Agora deve ler a primeira metade do proximo byte
	MOV	BL,RB04B;Grava a metade do byte solicitada em BL
	SHR	BL,4
	
	JRB04F:
	POP	AX
	POP	CX	;Retorna
	RET
	
	

;------ ROTINA: Manipula BMP com 24bits por pixel
;Acesso: CALL BMP24 (restrito)
;Entra: NADA
;Retorna: Alteracoes nos registradores de segmento, flags e memoria
;
;
;*** Para entender esta rotina, voce deve conhecer:

;------------------------------------------------------
;-> INT 10h funcao 10h subfuncao 10h (INT 10h/AX=1010h)
;Muda valores RGB de uma cor.
;Entra: AX: 1010h
;	BX: Numero da cor
;	CH: Intensidade de VERDE    (0..63d)
;	CL: Intensidade de AZUL     (0..63d)
;	DH: Intensidade de VERMELHO (0..63d)
;Retorna: NADA
;------------------------------------------------------
;Descricao do processo:
;A rotina BMP24 funciona assim:
;O Nanosistemas, em qualquer modo de video, possui 256 cores, sendo
;as primeiras 16 cores utilizadas pelo sistema para tracar as janelas,
;as icones, cursor do mouse, menus.. etc..
;Estas cores nao podem ser mudadas. Mas ainda restam 240 cores, que sao
;usadas por esta rotina para o BMP de fundo.
;Num BMP com 24bits por pixel, temos para cada pixel 3 bytes. Um e' a 
;intensidade de VERDE, outro e' a intensidade de VERMELHO e o outro e'
;a intensidade de AZUL. Mas como o Nanosistemas so' dispoe de 240 cores, 
;esta rotina verifica as cores que sao iguais dentro do BMP e da um numero
;a elas (um so' numero para todas as iguais), poe este numero como BX na 
;INT 10h/AX=1010h e muda os valores RGB (red,green,blue) desta cor.
;Tecnicamente:
;BCTC contem o numero de cores diferentes encontradas no BMP , que e' contado
;de 4 em 4. (Ex: Encontrando nenhuma cor, BCTC=0, Encontrando uma, BCTC=4, duas, BCTC=8).
;BDTC contem os valores RGB de todas as cores diferentes encontradas
;B24TM contem os valores RGB lidos por ultimo do arquivo BMP
;Inicia-se BCTC=0. Le a primeira cor do arquivo, poe em B24TM.
;B24TM e' posto em EBX. Como esta e' a primeira cor lida, e ainda nao
;existe nenhuma igual a ela, ela vai pro buffer BDTC e 'a BCTC e' adicionado
;4, marcando que foi encontrada uma nova cor.
;O numero da cor ,que e' igual a posicao da cor no buffer BDTC, e' gravado
;na memoria para onde esta indo o BMP final e o loop se repete.
;Novamente e' lida mais uma cor, que ja nao e' mais a primeira.
;Agora, esta cor (que esta em EBX) sera comparada com as cores ja existentes
;no buffer BDTC. Se ela ja estiver la', ela nao sera colocada no buffer e
;BCTC nao sera alterado, mas o seu numero (sua posicao no buffer BDTC) sera
;gravada na memoria onde esta indo o BMP final.
;O loop se repete e novamente sera lida mais uma cor.
;Posta em EBX, sera comparada com as ja existentes no buffer BDTC.
;Se esta nao estiver no buffer BDTC , entao ela e' colocada no final do buffer 
;BDTC e 'a BCTC sera adicionado 4 ,marcando que tem mais uma cor no buffer BDTC.
;Agora, o numero desta nova cor (sua posicao no buffer BDTC) sera gravado
;na memoria onde esta indo o BMP final.
;Quando terminou o arquivo, o controle e' passado a uma rotina que le todas
;as cores do buffer BDTC e muda os valores RGB de todas as cores do buffer BDTC
;na placa de video para os novos valores. (INT 10h/AX=1010h).
;Restaura registradores e retorna.
;Agora, o buffer para onde estava indo o BMP pode ser usado pela funcao BITMAP.

BMP24:	PUSHA			;Manipula BMP com 24bits por pixel
	PUSH	WORD PTR CS:BSEG;Prepara memoria

	MOV	BCTC,0		;Zera contador
	MOV	B24TM,0 	;Zera buffer
	
	MOV	EAX,BMPS	;Manda comecar a ler do fim.

	ADD	BOFF,AX 	;A rotina ira ler de traz pra frente
	SHR	EAX,16d 	;para desinverter o BMP , que esta
	MOV	CX,1000h	;invertido no arquivo.
	MUL	CX
	ADD	BSEG,AX

	MOV	BX,BMPH 	;Desloca (seek) filepos para inicio do BMP
	MOV	AX,4200h
	XOR	CX,CX
	MOV	EDX,BBBG
	INT	21h
	
	MOV	EAX,BWBP	;CATE marca tamanho da linha (scanline)
	MOV	CATE,AX
	
	;---- LOOP1 -----
	LB240:
	
	;Subrotina: Ajusta 32-bit boundary
	;Caso BMP em X nao seja multiplo de 4
	;------------------------------------------------------------
	CMP	CATE,0		;Verifica se terminou uma linha (scanline)
	JNZ	JB245		;Negativo, pula
	MOV	EAX,BWBP	;Afirmativo, restaura CATE para a proxima linha
	MOV	CATE,AX
	CMP	B32B,4		;Verifica se o BMP (em largura) e' multiplo de 4
	JZ	JB245		;Afirmativo, pula. Nao precisa de ajuste
	MOVZX	CX,B32B 	;Manda ignorar (no arquivo) os proximos B32B bytes
	MOV	AX,3
	;LOOP
	LB243:
	CALL RB24
	LOOP	LB243
	;END
	JB245:
	DEC	CATE
	;------------------------------------------------------------
	
	MOV	AX,3
	CALL	RB24		;Le 3 bytes do arquivo e poe em EBX
	
	CMP	BCTC,0		;Verifica se e' o primeiro bloco de 24bits
	JNZ	JB240		;Nao, pula
	MOV	DWORD PTR CS:[OFFSET BDTC],EBX ;Sim, grava a cor no primeiro campo
	MOV	BCTC,4		;Atualiza contador
	XOR	AL,AL
	JMP	JB242		;Marca o ponto na memoria
	
	JB240:			;Verifica se a cor ja existe	
	CMP	BCTC,960d	;Verifica se passou do limite de 240 cores
	JNA	JB247		;Nao, pula. Procura novas cores
	MOV	BMPR,6		;Sim, marca BMP rejeitado
	MOV	BMPD,0		;Marca BMP nao disponivel
	CALL	DALB		;Dealoca buffer para imagem
	POP	WORD PTR CS:[BSEG]
	POPA			;Limpa pilha
	RET			;Retorna (BMP NEGADO)
	JB247:
	MOV	SI,OFFSET BDTC	;SI contem o OFFSET INICIAL do buffer
	MOV	DI,SI
	ADD	DI,BCTC 	;DI contem o OFFSET FINAL do buffer
	CLD
	PUSH	CS
	POP	DS
	;---- LOOP2 -----
	LB241:
	LODSD
	CMP	EBX,EAX 	;Verifica se achou no buffer a cor lida
	JZ	JB241		;Sim, pula
	CMP	SI,DI		;Verifica se ja procurou no buffer inteiro
	JNZ	LB241		;Nao, pula pra continuar o loop
	;---- END2 -----
	PUSH	CS
	POP	ES
	MOV	EAX,EBX 	;Checou todo o buffer e nao achou a cor.
	STOSD			;Entao, grava a nova cor no buffer
	MOV	AX,BCTC
	SHR	AL,2
	ADD	BCTC,4		;e atualiza contador
	JMP	JB242		;Marca ponto no buffer

	JB241:			;Encontrou a cor no buffer
	SUB	SI,OFFSET BDTC+4
	SHR	SI,2		
	MOV	AX,SI		;Em AL, o numero da cor
	
	;Subrotina: Grava byte em AL no buffer da imagem
	;Entra: AL : Numero da cor
	;Retorna: Alteracoes no buffer da imagem e em DI,ES e flags
	;------------------------------------------------------------
	JB242:
	STD			;Gravar de traz pra frente
	ADD	AL,10h		;Reservar as 16 primeiras cores
	MOV	ES,BSEG 	;Grava numero da cor na memoria (buffer da imagem)
	MOV	DI,BOFF
	DEC	BMPS		
	CMP	BMPS,0		;analizando o numero de pixels lidos com RXxRY 
	JZ	JB243		;Afirmativo, pula


	STOSB

	CMP	DI,0FFFFh	;Verifica se ouve BORROW
	JNZ	JB244		;Nao, pula
	MOV	AX,ES		;Atualiza ES

	SUB	AX,1000h
	MOV	ES,AX
	JB244:
	CLD
	MOV	BSEG,ES
	MOV	BOFF,DI
	;------------------------------------------------------------
	;Fim da subrotina
	
	JMP	LB240		;Retorna com o loop
	;---- END1 -----
	;Fim da rotina 1 (leitura do arquivo BMP)
	;------------------------------------------------------------
	
	;Inicio da rotina: Ajuste dos registradores de cor 
	JB243:			;Vira pra ca em caso de EOF
	MOV	SI,OFFSET BDTC	;REDEFINICAO DE PALETE	
	CLD
	
	CLI
	MOV	DX,3C8h 	;Prepara para mudar palete
	MOV	AL,BCRS
	OUT	DX,AL

	MOV	DX,3C9h
	MOVZX	BX,BCRS
	DEC	BX
	
	;---- LOOP1 -----
	LB242:
	ADD	SI,2
	LODSB			;Le (em ordem) os valores RGB
	SHR	AL,2		;RED
	OUT	DX,AL
	
	SUB	SI,2		;GREEN
	LODSB
	SHR	AL,2
	OUT	DX,AL

	SUB	SI,2		;BLUE
	LODSB			;Note que na memoria os bytes estao no formato
	SHR	AL,2		;BLUE GREEN RED. Os bytes estao sendo desinvertidos
	OUT	DX,AL		;(ADD's SI,2 e SUB's SI,2) para serem enviados na ordem certa.

	ADD	SI,3		;Passa para a proxima cor
	INC	BX
	
	CMP	BX,0FFh 	;Verifica se ja mudou todas as cores
	JNZ	LB242		;Nao, prossegue com o loop
	;---- END1 -----
	STI

	POP	WORD PTR CS:BSEG;Restaura BSEG
	POPA			;Terminou.
	RET			;Retorna
	
----------------------------------------------------
;SUBROTINA: Acesso: CALL RB24 / EXCLUSIVO
;Entra: AX(AL) = No. de bytes para ler. MAX:3bytes
;Retorna: EBX = Byte(s) lidos

RBCA	DW	0		;Contador A : Numero da ultima WORD RGB lida (NUMERO DE BYTES JA LIDOS NESTE BLOCO DE RNBL BYTES)

REOF	DW	0		;Contador B : Offset da proxima WORD RGB a ser lida (contado de AX em AX)
RNBL	EQU	3072		;Numero de bytes para ler cada vez

RB24:	PUSHF
	PUSH	SI
	PUSH	CX

	PUSH	CS		;Prepara registradores		
	POP	DS
	PUSH	CS
	POP	ES
	
	CMP	RBCA,RNBL	;Verifica se deve atualizar buffer
	JNAE	JRB20		;Negativo, pula
	
	PUSH	AX
	CLD
	MOV	REOF,OFFSET RBDT;Positivo, reinicia contadores
	MOV	RBCA,0
	MOV	AH,3Fh		;Le RNBL bytes para o buffer (atualiza buffer)
	MOV	BX,BMPH
	MOV	CX,RNBL
	MOV	DX,OFFSET RBDT
	INT	21h
	POP	AX
	
	JRB20:			;Monta EBX
	MOV	SI,REOF
	MOV	EBX,DWORD PTR CS:[SI]
	AND	EBX,00000000111111111111111111111111b
	ADD	RBCA,AX 	;Atualiza contadores

	ADD	REOF,AX

	JRB21:
	POP	CX
	POP	SI		;Retorna
	POPF
	RET
	
----------------------------------------------------
;Subrotina exclusiva: CALL ALBB
;Aloca o buffer de memoria convencional para o BMP de fundo
;Entra: NADA
;Retorna:
;Se conseguiu alocar o buffer com sucesso:
;	CS:BUFA: Tamanho (em paragrafos) do buffer alocado
;	CS:BSEG: Segmento (para offset 0000) do buffer alocado
;Se nao houve memoria suficiente para alocar o buffer:
;	CS:BUFA: 0000
;	CS:BSEG: 0000
;
;OBS:	A rotina calcula a quantidade de memoria necessaria
;	baseando-se no tamanho X e Y do BMP que estao contidos
;	na memoria, em CS:BWBP e CS:BHBP.
;	Por isso, o usuario desta rotina deve carregar o cabecalho do 
;	BMP para a memoria antes de tentar alocar o buffer.
;
ALBB:	PUSHA	
	MOV	ECX,DWORD PTR CS:BWBP	;Verifica quanto de memoria vai precisar

	MOV	EAX,DWORD PTR CS:BHBP	;BX:=(BMPSzX*BMPSzY/16)+1
	MUL	CX
	ROL	EAX,16d
	MOV	AX,DX
	ROR	EAX,16d
	SHR	EAX,4d
	MOV	BX,AX		;Em BX o numero de paragrafos de memoria necessarios
	INC	BX		;para gravar o BMP		
	
	MOV	AH,48h		;Tenta alocar bloco de memoria
	INT	21h
	JNC	JAL0		;Conseguindo, pula
	XOR	BX,BX		;Nao conseguindo, grava 0 nas variaveis
	XOR	AX,AX		;BUFA e BSEG, indicando que houve erro na alocacao da memoria
	JAL0:
	MOV	BUFA,BX 	;Grava tamanho do bloco em BUFA
	MOV	BSEG,AX 	;Grava segmento em BSEG
	POPA
	RET

----------------------------------------------------
;Subrotina exclusiva: CALL DALB
;Desaloca o buffer de memoria convencional para o BMP de fundo
;alocado anteriormente pela funcao ALBB
;Entra: NADA
;Retorna:
;Se conseguiu desalocar o buffer com sucesso:
;	CS:BUFA: 0000
;	CS:BSEG: 0000
;Se houve algum erro e o buffer nao foi desalocado:
;	CS:BUFA: Nao muda
;	CS:BSEG: Nao muda
;
DALB:	PUSHA
	PUSH	ES
	MOV	AH,49h		;Tenta alocar bloco de memoria
	MOV	ES,BSEG 	
	INT	21h
	JC	JDL0		;Nao conseguindo, pula
	MOV	BUFA,0		;Conseguindo, zera os dois buffers		
	MOV	BSEG,0		
	JDL0:
	POP	ES
	POPA
	RET
	
-------------------------------------------------------------------
;Nanosistemas. Funcao MOUSE DETECT
;Acesso: CALL MDTC / EXTERNO
;
;Detecta a porta do Microsoft Mouse (UART/HEX)
;
;Entra: NADA
;Retorna: AL : 0 = Mouse encontrado
;	  AL : 1 = Mouse NAO foi encontrado e CS:UART nao foi alterado
;	  CS:UART: Porta onde mouse foi encontrado, de
;		   acordo com as definicoes internas de E/S
;		   UART H.A. dadas pela tabela CS:PRES (Words Zero)
;		  
MDEX	DB	0		;AL retorno

MDTC:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CLD
	PUSH	CS		;Ajusta registradores
	POP	DS
	MOV	SI,OFFSET PRES
	MOV	MDEX,1		;Marca inicialmente: MOUSE NAO ENCONTRADO
	
	;---- LOOP1 -----
	LMDTC0:
	LODSW			;Le uma porta
	OR	AX,AX		
	JZ	JMDTC0		;Cabou, pula. (Mouse nao encontrado)
	MOV	UART,AX 	
	
	MOV	DX,AX		;Salva estado da porta
	CALL	PUSHP

	CALL	IRIU		;Inicializa porta para executar a deteccao
	CALL	TDTR		;Verifica se ha MS-MOUSE nesta porta
	PUSH	AX
	
	MOV	DX,UART
	CALL	POPP		;Restaura estado da porta
	
	POP	AX
	OR	AL,AL
	JZ	LMDTC0		;Negativo, procura na proxima porta
	;---- END1 -----

	MOV	MDEX,0		;Marca: MOUSE ENCONTRADO
	
	JMDTC0: 		;Pulando pra ca, entao nenhum mouse foi encontrado
	POP	ES
	POP	DS
	POPA
	MOV	AL,MDEX 	;AL - resposta
	RET			;Finaliza rotina
	
-------------------------------------------------------------------
;Subrotina:	Exibe janela : MOUSE (UART) NAO ENCONTRADO
;Entra NADA retorna NADA
;	
MMN0:	DB	'MOUSE NOT FOUND',13
	DB	13
	DB	'Nanosistemas cannot find Microsoft-Compatible Mouse',13
	DB	'on ports COM1, COM2, COM3, COM4 and Custom port.',13
	DB	13

	DB	'The cursor is being controlled using the DOS MOUSE DRIVER',13
	DB	'(Int 33h).',13
	DB	13
	DB	3,8
	DB	'   Do Not Show Any More Mouse Warnings',13
	DB	0
	
;M.Info:
MMSI:	DW	0FFFFh	;Posicao X (0FFFFh = Centralizado em X)
	DW	0FFFFh	;Posicao Y (0FFFFh = Centralizado em Y)
	DW	322d	;X - Largura
	DW	200d	;Y - Altura
	DW	0	;CLICKS:OFF
	
	DW	1,10,10,4 dup (0),01FFh,offset MMN0,0,0,0,0		;TEXTO

	DW	2,10,140,5 dup (0),offset JMD1,0,0ff31h,0FFFFh,0	;CHECKBOX
	DW	5,0FFFFh,165d,5 dup (321),offset ICNF,0,0dffh,0FFFFh,1440h;OK
	DB	0FFh
	

MNEW:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CMP	JMD1,1		;Deve mostrar esta janela?
	JZ	JMNEWF		;Negativo, pula
	
	MOV	AX,0100h	;Exibe janela
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET MMSI
	CALL	MOPC
	
	MOV	DMAL,1		;Retira janela
	CALL	REWRITE
	CALL	MAXL		
	
	JMNEWF:
	POP	ES		;Abandona rotina
	POP	DS
	POPA
	RET

-------------------------------------------------------------------
;Subrotina:	Exibe janela : MOUSE DRIVER (INT 33h) NAO ENCONTRADO
;Entra NADA retorna NADA
;	
MDN0:	DB	'MOUSE NOT FOUND',13
	DB	13
	DB	'Nanosistemas did not find DOS MOUSE DRIVER (INT 33h).,13
	DB	13
	DB	'The cursor is being controlled using the hardware ports.',13
	DB	13
	DB	13
	DB	3,8
	DB	'   Do Not Show Any More Mouse Warnings',13
	DB	0
	
;M.Info:
MDSI:	DW	0FFFFh	;Posicao X (0FFFFh = Centralizado em X)
	DW	0FFFFh	;Posicao Y (0FFFFh = Centralizado em Y)
	DW	330d	;X - Largura
	DW	190d	;Y - Altura
	DW	0	;CLICKS:OFF
	
	DW	1,10,10,4 dup (0),01FFh,offset MDN0,0,0,0,0		;TEXTO
	DW	2,10,125,5 dup (0),offset JMD1,0,0ff31h,0FFFFh,0		;CHECKBOX
	DW	5,0FFFFh,155d,5 dup (321),offset ICNF,0,0dffh,0ffffh,1440h	;OK
	DB	0FFh
	

MDEW:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CMP	JMD1,1		;Deve mostrar esta janela?
	JZ	JMDEWF		;Negativo, pula
	
	MOV	AX,0100h	;Exibe janela
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET MDSI
	CALL	MOPC
	
	MOV	DMAL,1		;Retira janela
	CALL	REWRITE
	CALL	MAXL		
	
	JMDEWF:
	POP	ES		;Abandona rotina
	POP	DS
	POPA
	RET

-------------------------------------------------------------------
;Subrotina:	Exibe janela : MOUSE NAO ENCONTRADO
;Entra NADA retorna NADA
;	
NMN0:	DB	'MOUSE NOT FOUND',13
	DB	13
	DB	'Nanosistemas cannot find a way to access your mouse.',13
	DB	'SCROLL LOCK is now on so you can use the keyboard arrows to',13 
	DB	'control the cursor. After you click OK, the SYSTEM OPTIONS',13
	DB	'menu will pop up so you can try to enter a custom port where',13 
	DB	'the mouse may be.',13
	DB	13
	DB	'   Do Not Show Any More Mouse Warnings',0
	
	
;M.Info:
NMSI:	DW	0FFFFh	;Posicao X (0FFFFh = Centralizado em X)
	DW	0FFFFh	;Posicao Y (0FFFFh = Centralizado em Y)
	DW	330d	;X - Largura
	DW	190d	;Y - Altura
	DW	0	;CLICKS:OFF
	
	DW	1,10,10,4 dup (0),01FFh,offset NMN0,0,0,0,0		;TEXTO
	DW	2,10,(9*15)-3,5 dup (0),offset JMD1,0,0ff31h,0FFFFh,0	;CHECKBOX
	DW	5,0FFFFh,155d,5 dup (321),offset ICNF,0,0dffh,0ffffh,1440h	;OK
	DB	0FFh
	

NNEW:	PUSHA
	PUSH	DS
	PUSH	ES
	
	CMP	JMD1,1		;Deve mostrar esta janela?
	JZ	JNNEWF		;Negativo, pula
	
	PUSH	40h		;Liga SCROLL LOCK
	POP	DS
	MOV	BYTE PTR DS:[17h],30h
	
	MOV	CBTS,10h
	
	MOV	AX,0100h	;Exibe janela
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET NMSI
	CALL	MOPC
	
	MOV	DMAL,1		;Retira janela
	CALL	REWRITE

	CALL	MAXL		
	
	MOV	AH,5		;Empurra "O" para o buffer do teclado
	MOV	CH,24d
	MOV	CL,111d
	INT	16h
	
	JNNEWF:
	POP	ES		;Abandona rotina
	POP	DS
	POPA
	RET
-------------------------------------------------------------------
;Nanosistemas. Funcao CONTROL
;Acesso: CALL CNTR / EXTERNO
;
;Executa toda a verificacao e inicializacao
;para definir o modo de controle do cursor.
;
;Entra: NADA
;Retorna: NADA

MCTR:	PUSHA
	PUSH	DS
	PUSH	ES
	;Converte texto em CUSP para word em CPRT
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET CUSP
	XOR	DX,DX
	XOR	AX,AX
	CLD
	
	;LOOP
	LM0:
	LODSB
	OR	AL,AL
	JZ	JM2		;Terminando, finaliza
	OR	AL,032d 	;Converte para maiusculas
	CMP	AL,'0'		;Verifica se o caractere e' um ASCIIHEX valido
	JNAE	LM0
	CMP	AL,'f'
	JA	LM0
	CMP	AL,'9'
	JNA	JM0
	CMP	AL,'a'
	JNAE	LM0
	JM0:			;Chegando aqui, entao e' valido

	SUB	AL,48d		;Ajusta para "0" ser 0
	CMP	AL,9
	JNA	JM1
	SUB	AL,39d		;Ajusta para "A" ser 10 (0Ah)
	JM1:
	
	ROR	AX,4
	SHLD	DX,AX,4 	;INSERE o AL nos 4 primeiros bits de DX
	JMP	LM0
	;END
		
	JM2:
	MOV	CPRT,DX 	;Grava o valor convertido em CPRT
	
	;Define modo de controle do cursor
	;-------------------------------------------------
	MOV	CMIN,0		;Marca: AINDA NAO FOI DEFINIDO O CONTROLADOR DO MOUSE	
	;Verifica se deve usar MOUSE DRIVER, LEITURA DIRETA, ou se
	;o sistema que deve decidir
	CMP	CMSE,1		;Mouse driver
	JNZ	JBGC0		;Negativo, pula
	
	XOR	AX,AX		;Inicializa o mouse driver
	INT	33h
	OR	AX,AX		;Verifica se existe mouse driver
	SETNZ	CMIN		;Afirmativo, marca 1 em CMIN e MOUS

	SETNZ	MOUS
	JMP	JBG8		;Pula demais verificacoes	

	JBGC0:
	CMP	CMSE,2		;Leitura Direta
	JNZ	JBGC1		;Negativo, pula
	MOV	MOUS,0		;Afirmativo, marca: USAR LEITURA DIRETA
	JMP	JBG8		;Pula demais verificacoes	
	
	JBGC1:
	;Chegando aqui, entao o sistema ira decidir se usa
	;a INT 33h ou se le direto do hardware 
	;
	;ROTINA DE VERIFICACAO DO MOUSE DRIVER
	XOR	AX,AX
	INT	33h
	OR	AX,AX		;Verifica se existe mouse driver
	SETNZ	MOUS		;Afirmativo, marca MOUS e CMIN
	SETNZ	CMIN
	;FIM DA ROTINA
	
	JBG8:
	CMP	MOUS,1		;Verifica se deve usar INT 33h
	JZ	JBGD0		;Afirmativo, pula

	;Usar Leitura Direta
	;
	CMP	MPOR,0		;Verifica se deve autodetectar a porta do mouse
	JZ	JBGDA		;Afirmativo, pula
	MOVZX	BX,MPOR 	;Negativo, usa porta do mouse definida pelo usuario
	SHL	BX,1
	MOV	AX,WORD PTR CS:[(OFFSET PRES-2)+BX]
	MOV	UART,AX
	MOV	CMIN,1		;Marca: CONTROLADOR JA DEFINIDO
	JMP	JBGD0		;Pula
	
	;***************
	
	;Auto-deteccao da porta do mouse:
	;
	JBGDA:
	CALL	MDTC		;Detecta mouse
	
	MOV	CMIN,1		;Marca: CONTROLADOR JA DEFINIDO
	OR	AL,AL		;Verifica se encontrou o mouse
	JZ	JBGD2		;Afirmativo, pula
	;Negativo.. 
	MOV	CMIN,0		;Marca: CONTROLADOR AINDA NAO DEFINIDO
	MOV	MOUS,1		;Manda usar INT 33h
	XOR	AX,AX		;Inicializa o mouse driver
	INT	33h
	OR	AX,AX		;Verifica se ha mouse driver
	JZ	JBGD0		;Negativo, pula
	MOV	CMIN,1		;Marca: CONTROLADOR JA DEFINIDO
	CALL	IRIU		;Inicializa mouse (INT 33h)
	CALL	MNEW		;Exibe janela MOUSE NAO ENCONTRADO
	JMP	JBGD1		;Pula CALL IRIU abaixo			
	
	;Inicialicacao do mouse dentro do sistema
	JBGD0:
	CMP	CMIN,0		;Verifica se sistema encontrou um controlador de mouse
	JNZ	JBGD2		;Afirmativo, pula
	CALL	NNEW		;Negativo, exibe janela: Nenhum controlador encontrado	
	
	JBGD2:
	MOV	DX,UART
	CALL	PUSHP
	CALL	IRIU		;Inicializa porta do mouse (UART ou INT 33h)
	
	CMP	CMSE,1		;Verifica se deve mostrar janela NO INT33-USANDP UART
	JNZ	JBGD1		;Negativo, pula
	CMP	MOUS,1		;Verifica denovo
	JZ	JBGD1		;Negativo, pula
	CALL	MDEW		;Mostra janela MOUSE DRIVER NAO ENCONTRADO - USANDO UART


	JBGD1:
	POP	ES		;Finaliza e retorna
	POP	DS
	POPA
	RET

-------------------------------------------------------------------
;Nanosistemas. Funcao exclusiva do sistema.
;Acesso: CALL IMAN / CALL DMAN
;
;IMAN:
;Instala um manipulador em uma interrupcao do sistema
;
;Entra: AL	: Numero da interrupcao
;	DX	: Offset (em CS do Nanosis) do manipulador
;	SI	: Offset (em CS do Nanosis) para por o endereco real da INT
;Retorna:
;	AL	: 0 = Sucesso
;	AL	: 1 = Ja estava instalado. (nao foi feito nada)
;
;DMAN:
;Desinstala um manipulador em uma interrupcao do sistema
;
;Entra: AL	: Numero da interrupcao
;	DX	: Offset (em CS do Nanosis) do manipulador
;	SI	: Offset (em CS do Nanosis) do endereco real da INT
;Retorna:
;	AL	: 0 = Sucesso
;	AL	: 1 = Nao estava instalado (nao foi feito nada)
;
IMAN:	;Instala manipulador
	MOV	AH,35h
	INT	21h
	PUSH	ES
	PUSH	BX
	POP	ECX	;Em ECX, o endereco da INT
	PUSH	CS
	PUSH	DX
	POP	EBX	;Em EBX, o endereco do manipulador
	CMP	EBX,ECX ;Verifica se o manipulador ja esta instalado
	JZ	JBGMF			;Pula se afirmativo
	;Instala manipulador
	MOV	DWORD PTR CS:[SI],ECX	;Grava vetor real
	MOV	AH,25h			;Muda vetor da INT
	PUSH	CS
	POP	DS
	INT	21h
	XOR	AL,AL			;Retorna, com AL=0
	RET
	JBGMF:
	MOV	AL,1			;Retorna, com AL=1
	RET
	
DMAN:	;Desinstala manipulador
	MOV	AH,35h
	INT	21h
	PUSH	ES
	PUSH	BX
	POP	ECX	;Em ECX, o endereco da INT
	PUSH	CS
	PUSH	DX
	POP	EBX	;Em EBX, o endereco do manipulador
	CMP	EBX,ECX ;Verifica se o manipulador ja esta instalado
	JNZ	JBGM1F			;Pula se negativo
	;Desinstala manipulador
	MOV	AH,25h			;Muda vetor da INT
	LDS	DX,DWORD PTR CS:[SI]
	INT	21h
	XOR	AL,AL			;Retorna, com AL=0
	RET
	JBGM1F:
	MOV	AL,1			;Retorna, com AL=1
	RET

-------------------------------------------------------------------
;Nanosistemas. Rotina DMNS
;Acesso: CALL DMNS
;
;Desinstala todos os manipuladores de interrupcao do sistema
;
;Entra: NADA
;Retorna: Alteracao nos vetores de interrupcao
;
;Todos os manipuladores de interrupcao instalados pelo
;sistema serao desinstalados por esta rotina.
;
DMNS:	
	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	AL,24h		;Desinstala manipulador de erro critico
	MOV	DX,OFFSET MAERCR
	MOV	SI,OFFSET OL24
	CALL	DMAN
	
	MOV	AL,1Ch		;Desinstala manipulador na INT 1Ch
	MOV	DX,OFFSET MAIN1C
	MOV	SI,OFFSET OL1C
	CALL	DMAN
	
	MOV	AL,10h		;Desinstala manipulador na INT 10h
	MOV	DX,OFFSET MAIN10
	MOV	SI,OFFSET OL10
	CALL	DMAN
	
	MOV	AL,06h		;Desinstala manipulador na INT 06h
	MOV	DX,OFFSET MAIN06
	MOV	SI,OFFSET OL06
	CALL	DMAN
	
	MOV	AL,00h		;Desinstala manipulador na INT 00h
	MOV	DX,OFFSET MAIN00
	MOV	SI,OFFSET OL00
	CALL	DMAN
	
	MOV	AL,09h		;Desinstala manipulador na INT 09h
	MOV	DX,OFFSET MAIN09
	MOV	SI,OFFSET OL09
	CALL	DMAN
	
	POP	ES
	POP	DS
	POPA			;Finaliza
	RET			;Retorna
	
-------------------------------------------------------------------
;Nanosistemas. Rotina IMNS
;Acesso: CALL IMNS
;
;Instala todos os manipuladores de interrupcao do sistema
;
;Entra: NADA
;Retorna: Alteracao nos vetores de interrupcao
;
;Todos os manipuladores de interrupcao instalados pelo
;sistema serao instalados por esta rotina.
;
IMNS:	
	PUSHA
	PUSH	DS
	PUSH	ES
	
	MOV	XORC,0		;Marca: Zerar todas as cores
	
	MOV	AL,24h		;Instala manipulador de erro critico
	MOV	DX,OFFSET MAERCR
	MOV	SI,OFFSET OL24
	CALL	IMAN
	
	MOV	AL,1Ch		;Instala manipulador na INT 1Ch
	MOV	DX,OFFSET MAIN1C
	MOV	SI,OFFSET OL1C
	CALL	IMAN
	
	MOV	AL,10h		;Instala manipulador na INT 10h
	MOV	DX,OFFSET MAIN10
	MOV	SI,OFFSET OL10
	CALL	IMAN
	
	MOV	AL,06h		;Instala manipulador na INT 06h
	MOV	DX,OFFSET MAIN06
	MOV	SI,OFFSET OL06
	CALL	IMAN

	MOV	AL,00h		;Instala manipulador na INT 00h
	MOV	DX,OFFSET MAIN00
	MOV	SI,OFFSET OL00
	CALL	IMAN

	MOV	AL,09h		;Instala manipulador na INT 09h
	MOV	DX,OFFSET MAIN09
	MOV	SI,OFFSET OL09
	CALL	IMAN
	
	POP	ES
	POP	DS
	POPA			;Finaliza
	RET			;Retorna
	
-------------------------------------------------------------------
;FIM DAS SUBROTINAS PRINCIPAIS
;INICIO DAS ROTINAS DE INICIALIZACAO
MSGA:	DB	13,10,'Nanosistemas cannot run:'
	DB	13,10,'--------------------------------',24h

MSG0:	DB	13,10,'Error initializing video.'
	DB	13,10,'VESA identification not found.'
	DB	13,10,24h
	
MSG1:	DB	13,10,'Error initializing video.'
	DB	13,10,'Needed function not supported by your video card.'
	DB	13,10,24h

MSG2:	DB	13,10,'Self virus check. File is possibly infected.'
	DB	13,10,'Run with parameter ! to bypass.'
	DB	13,10,24h
	
MSG3:	DB	13,10,'Self virus check. File is infected.'
	DB	13,10,'Run with parameter ! to bypass.'
	DB	13,10,24h
	
MSG4:	DB	13,10,'Cannot access self file.',13,10,24h

MSG5:	DB	13,10,'Checksum error. Corrupt file.',13,10,24h

CPUER:	DB	13,10,'Needed IBM PC 80386 or above.'
	DB	13,10,24h

CMIN	DB	0	;Controle do mouse: 0 = Ainda nao encontrado controlador
			;		    1 = Mouse esta operando perfeitamente

BGIN:	CALL	ABMC	;Aloca 13456 bytes para o manipulador de erro critico
	
	MOV	DI,OFFSET VARST ;Zera buffers
	MOV	CX,(OFFSET VARSR-OFFSET VARST) 
	XOR	AL,AL
	CLD
	REP	STOSB
	
	CLI
	MOV	SSIN,SS 	;Grava pilha inicial
	MOV	SPIN,SP
	
	PUSH	CS		;Posiciona pilha
	POP	SS
	MOV	SP,OFFSET STAKB
	STI

	CMP	CCSM,0		;Verifica se usuario esta reiniciando sistema
	JNZ	JSPTHF		;Afirmativo, pula e nao le novamente o diretorio
	
	PUSH	40h		;Liga NUM LOCK e desliga demais.
	POP	DS
	MOV	AL,BYTE PTR DS:[17h]	;Salva estado do teclado
	MOV	L17H,AL
	MOV	BYTE PTR DS:[17h],20h

	;Muda diretorio atual para o diretorio do MM.COM
	;---------------------------------------------------------
	CLD
	MOV	DS,DSIN 	;Procura final do enviroment
	MOV	DS,WORD PTR DS:[2Ch]
	XOR	SI,SI
	;---- LOOP1 ------
	LBG5A:
	LODSW
	DEC	SI
	OR	AX,AX
	JNZ	LBG5A
	;---- END1 ------	
	ADD	SI,3		;Em DS:SI o inicio da string
	PUSH	CS		;Copia path\filename para CS:PROGRAM
	POP	ES
	MOV	DI,OFFSET SYSPATH
	MOV	CX,79d
	REP	MOVSB
	
	CLD
	XOR	AL,AL		;Procura final da string
	MOV	CX,79d
	MOV	DI,OFFSET SYSPATH		
	REPNZ	SCASB		;Em ES:DI o final da string
	
	STD			;Agora, procura ultima barra "\"
	MOV	AL,'\'
	MOV	CX,79d
	REPNZ	SCASB				
	
	MOV	BYTE PTR ES:[DI+1],0	;No lugar da ultima barra "\", poe ZERO 


	CALL	SPATH			;Vai pro path do sistema
	JMP	JSPTHF			;Verifica checksum

;Subfuncao: RETORNA AO PATH DO SISTEMA
;Entra NADA altera TUDO
SPATH:	PUSHA
	MOV	AH,3Bh			;Muda diretorio atual
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET SYSPATH
	INT	21h
	
	MOV	AH,0Eh			;Ajusta o drive atual 
	MOV	DL,BYTE PTR CS:[OFFSET SYSPATH]
	OR	DL,32d
	SUB	DL,97d
	INT	21h
	POPA
	RET
	;---------------------------------------------------------
	JSPTHF:
	
	;---------------------------------------------------------
	;INICIO DE ROTINA: REALIZA CHECAGEM / MONTAGEM DA CHECKSUM
	
	CMP	CCSM,0		;Verifica se deve verificar a checksum
	JNZ	JBG6		;Sera NEGATIVO caso o usuario esteja apenas reiniciando o Nanosistemas	
	
	CMP	CS:CSUM,0	;Verifica se ja existe checksum calculada
	JNZ	JBG4		;Afirmativo, pula e nao calcula checksum
	
	;CALCULA CHECKSUM (REALIZADO APENAS UMA VEZ)
	PUSH	CS		;Prepara registradores para calcular checksum
	POP	DS
	MOV	SI,OFFSET CHECKST
	XOR	EBX,EBX
	XOR	EAX,EAX
	MOV	CX,OFFSET VARST - OFFSET CHECKST
	;---- LOOP1 ------	;Soma todos os bytes do programa
	LBG2:
	CLD
	LODSB
	ADD	EBX,EAX
	DEC	CX
	JNZ	LBG2
	;---- END1 ------
	MOV	CS:CSUM,EBX	;Grava na memoria valor calculado
	CALL	OPENM
	JMP	JCOP1
	
OPENM:	;Abre arquivo do Nanosistemas (COM)
	MOV	DS,WORD PTR CS:[2Ch]
	XOR	SI,SI
	CLD
	;---- LOOP1 ------
	LBG5:
	LODSW
	DEC	SI
	OR	AX,AX
	JNZ	LBG5
	;---- END1 ------
	MOV	DX,SI
	ADD	DX,3 
	
	MOV	AX,3D02h	;Tenta abrir arquivo COM do Nanosistemas
	INT	21h		;for READ x WRITE
	JNC	JWBG

	MOV	AX,3D00h	;Tenta abrir arquivo COM do Nanosistemas
	INT	21h		;for READ ONLY
	JNC	JWBG

	MOV	DX,OFFSET MSG4	;Mostra mensagem de CANNOT ACCEESS SELF FILE
	JMP	ERRBG		;Finaliza Nanosistemas

	JWBG:
	MOV	BX,AX
	MOV	AH,3Fh		;Le 6 bytes para verificar a validade dos
	MOV	CX,6		;primeiros bytes
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET PROGRAM
	INT	21h
	
	MOV	AX,4202h	;Pega tamanho do arquivo
	XOR	CX,CX
	XOR	DX,DX
	INT	21h
	MOV	COMS,AX
	
	MOV	AX,4200h	;Posiciona (seek) arquivo para inicio da checksum
	XOR	CX,CX
	MOV	DX,OFFSET CSUM - OFFSET INIC
	INT	21h
	
	RET
	;---------------
	
	JCOP1:
	MOV	AH,40h		;Grava valor da checksum
	MOV	CX,4
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET CSUM
	INT	21h
	
	MOV	AH,3Eh		;Fecha o arquivo
	INT	21h
	
	;VERIFICACAO DA CHECKSUM
	;Realizada a toda execucao do programa.
	
	JBG4:
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET CHECKST
	XOR	EBX,EBX
	XOR	EAX,EAX
	MOV	CX,OFFSET VARST - OFFSET CHECKST
	
	;---- LOOP1 ------	;Soma todos os bytes do programa
	LBG3:
	CLD
	LODSB
	ADD	EBX,EAX
	DEC	CX
	JNZ	LBG3
	;---- END1 ------

	MOV	DX,OFFSET MSG5
	CMP	DWORD PTR CS:CSUM,EBX	;Verifica checksum
	JNZ	ERRBG		;Estando ilegal, finaliza
	
	;FIM DAS ROTINAS DE CALCULO / VERIFICACAO DA CHECKSUM
	;---------------------------------------------------------
	CALL	LOAD		;Carrega configuracao do usuario
	
	;Analiza possibilidade de programa estar contaminado por um virus
	CALL	OPENM
	MOV	AH,3Eh		;Fecha arquivo
	INT	21h
	
	CMP	BYTE PTR CS:[82h],'!'	
	JZ	JNVPAV		;Parametro "!" = Nao verifique virus
	
	CMP	VIRU,0		;Verifica se deve verificar virus
	JZ	JNVPAV		;Negativo, pula
	
	CMP	COMS,40000d	;Verifica se o arquivo esta compactado
	JNA	JNVPAV		;Afirmativo, pula e nao verifica virus.
	
	MOV	DX,OFFSET MSG2	;Verifica se sao validos
	CMP	DWORD PTR CS:[0100h],0B8BEBAB8h
	JNZ	ERRBG		;Negativo, pula
	CMP	WORD PTR CS:[0104h],0C0CAh
	JNZ	ERRBG
	
	MOV	DX,OFFSET MSG3
	CMP	DWORD PTR CS:[OFFSET PROGRAM],0B8BEBAB8h	
	JNZ	ERRBG		;Negativo, pula
	CMP	WORD PTR CS:[OFFSET PROGRAM+4],0C0CAh
	JNZ	ERRBG
	
	JNVPAV:
	JBG6:
	
	;---------------------------------------------------------
	;INICIO DAS ROTINAS DE VERIFICACAO E AJUSTE DO VIDEO
	
	MOV	CS:TEMP,0	;Zera memoria
	MOV	AX,4F00h	;Verifica se a placa de video e' VESA-COMPATIVEL
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET CTMP	;Usa buffer do cursor para uma escrita temporaria
	INT	10h
	
	MOV	AX,WORD PTR CS:[OFFSET CTMP+6]	;Grava na memoria segmento:offset
	MOV	OEMO,AX
	MOV	AX,WORD PTR CS:[OFFSET CTMP+8]	;da string de OEM do video
	MOV	OEMS,AX
	CMP	DWORD PTR CS:[OFFSET CTMP],'ASEV'
	JZ	JCBG1		;Se ha a string VESA, pula
	MOV	DX,OFFSET MSG0	;Mostra mensagem de erro e finaliza
	JMP	ERRBG
	
	;SUBROTINA INTERNA:
	;Entra: DX : Offset da mensagem de erro.
	;Retorna: Nao retorna.
	;ACESSE COM JUMP
	;
	ERRBG:
	MOV	AH,9h		
	PUSH	CS
	POP	DS
	PUSH	DX
	MOV	DX,OFFSET MSGA	;Mostra primeira mensagem (NANOSISTEMAS...)
	INT	21h
	POP	DX
	INT	21h		;Mostra mensagem de erro
	INT	20h		;e finaliza
	;
	;END

	;-- SUBFUNCAO INTERNA: 
	;Entra: DX : Word a procurar no buffer dos modos VESA suportados
	;Retorna: AX : 0FFFFh: Nao encontrado
	;	  AX = DX    : Encontrado
	CBG0:
	PUSH	SI
	PUSH	DS
	LDS	SI,DWORD PTR CS:[OFFSET CTMP+0Eh]
	CLD
	;- LOOP
	LCBG0:
	LODSW
	CMP	AX,DX		;Encontrou,
	JZ	JCBG0		;Pula
	CMP	AX,0FFFFh
	JNZ	LCBG0
	
	;- END
	JCBG0:
	POP	DS
	POP	SI
	RET
	;-- FIM DA SUBFUNCAO INTERNA
	
	;-- SUBFUNCAO INTERNA: 
	;Entra: CX : Numero da resolucao (1-8)
	;Retorna: Copia a frase numero CX para CS:R1VT
	;OBS: As frases estao em CS:RESN
	CBG1:
	PUSH	DS
	PUSH	ES
	PUSHA
	
	DEC	CX
	PUSH	CS
	POP	DS
	PUSH	CS
	POP	ES
	MOV	SI,OFFSET RESN	;SI:=OFS.RESN+(CX*19)
	MOV	AX,19d
	MUL	CX
	ADD	SI,AX
	MOV	DI,OFFSET R1VT	;DI:=OFS.R1VT+WPTR.CS:TEMP
	ADD	DI,CS:TEMP	
	CLD
	MOV	CX,19d		;Copia 19 bytes de DS:SI para ES:DI
	REP	MOVSB
	ADD	CS:TEMP,19d	;Atualiza CS:TEMP
	
	POPA			;Restaura registradores para a saida
	POP	ES
	POP	DS
	RET
	;-- FIM DA SUBFUNCAO INTERNA
	
	;VESA encontrado
	JCBG1:
	MOV	AX,WORD PTR CS:[OFFSET CTMP+4]	;Grava na memoria a VERSAO DO VESA
	MOV	VVER,AX
	MOV	AX,WORD PTR CS:[OFFSET CTMP+12h];Grava total de memoria
	MOV	TMVD,AX
	
	MOV	WORD PTR CS:BNMR,0;Zera contador
	PUSH	CS		;Verifica se todas as resolucoes VESA (words)

	POP	DS		;contidas em CS:RESB sao permitidas pela placa
	PUSH	CS		;de video do usuario.
	POP	ES		;(Ao mesmo tempo que vai encontrando as resolucoes
	MOV	DI,OFFSET RESP	;permitidas pela placa de video e pelo Nanosistemas,
	MOV	SI,OFFSET RESB	;a rotina abaixo vai atualizando o menu CS:R1VM (menu
	XOR	CX,CX		;tipo ROT1) gravando nele a frase que descreve a resolucao
	;- LOOP 		;encontrada. Para atualizar o menu
	LBG9:
	INC	CX
	LODSW			;Le word (Resolucao permitida pelo MMac)
	CMP	AX,0FFFFh	;Verifica se ja verificou todas as resolucoes
	JZ	JBG5		;Sim, pula.
	MOV	DX,AX		;Verifica se a placa de video permite
	CALL	CBG0
	CMP	AX,0FFFFh	;Nao, prossegue o LOOP
	JZ	LBG9		;Pula
	STOSW			;Sim, grava em CS:RESP
	INC	WORD PTR CS:BNMR;Atualiza NUMERO MAXIMO DE RESOLUCOES VALIDAS
	CALL	CBG1		;Atualiza menu CS:R1VM
	JMP	LBG9		;Prossegue o LOOP
	;- END
	JBG5:
	
	PUSH	CS		;Fecha menu CS:R1VM
	POP	ES
	MOV	DI,OFFSET R1VT	;DI:=OFS.R1VT+WPTR.CS:TEMP
	ADD	DI,CS:TEMP
	DEC	DI
	MOV	EAX,0FFFF0D00h
	STOSD
	
	CLD
	PUSH	CS
	POP	DS
	MOV	BX,CS:SRES	;Verifica se existe a resolucao inicial
	MOV	SI,OFFSET RESP
	;LOOP
	LBG01:
	LODSW	
	CMP	AX,BX
	JZ	JBG01		;Encontrou, pula
	CMP	AX,BX
	JNA	LBG01		;Ainda nao, continua o loop
	;END
	SUB	SI,4		;Nao existe, pega a mais proxima inferior
	LODSW
	MOV	SRES,AX
	
	JBG01:
	MOV	AX,4F01h	;Captura informacoes sobre o modo atual
	MOV	CX,CS:SRES
	PUSH	CS
	POP	ES
	MOV	DI,OFFSET USLS
	INT	10h
	MOV	DX,OFFSET MSG1	;Erro, mostra mensagem e finaliza
	CMP	AX,004Fh	
	JNZ	ERRBG
	
	MOV	AX,4F02h	;Muda o modo de video para modo grafico
	MOV	BX,CS:SRES
	INT	10h
	MOV	DX,OFFSET MSG1	;Erro, mostra mensagem e finaliza
	CMP	AX,004Fh	
	JNZ	ERRBG

	;28 SET 1999
	;Verifica qual segmento de video e qual janela
	;devera ser usada para leitura e para gravacao
	;--------------------------------------------------------
	
	MOV	AX,SEGA ;AX e BX contem os segmentos das janelas A e B
	MOV	BX,SEGB
	
	;Inicia testes com a JANELA 0 (prioridade)
	TEST	BYTE PTR CS:[OFFSET USLS+2],1
	JZ	JJAN02	;Pula se JANELA 0 nao for suportada
	
	TEST	BYTE PTR CS:[OFFSET USLS+2],10b
	JZ	JJAN01	;Pula se JANELA 0 nao pode ser LIDA
	MOV	RSEG,AX ;Marca: LER do segmento da janela 0
	MOV	RJAN,0
	JJAN01:
	
	TEST	BYTE PTR CS:[OFFSET USLS+2],100b
	JZ	JJAN02	;Pula se JANELA 0 nao pode ser ESCRITA
	MOV	WSEG,AX ;Marca: GRAVAR no segmento da janela 0
	MOV	WJAN,0
	JJAN02:
	;Fim dos testes com a JANELA 0
	
	;Inicia testes com a JANELA 1 (segunda prioridade)
	TEST	BYTE PTR CS:[OFFSET USLS+3],1
	JZ	JJAN12	;Pula se JANELA 1 nao for suportada
	
	TEST	BYTE PTR CS:[OFFSET USLS+3],10b
	JZ	JJAN11	;Pula se JANELA 1 nao pode ser LIDA
	CMP	RSEG,0	;Verifica se RSEG e RJAN ja esta ajustado para
	JNZ	JJAN11	;janela 0. Afirmativo, mantem assim.
	MOV	RSEG,BX ;Marca: LER do segmento da janela 0
	MOV	RJAN,1
	JJAN11:
	
	TEST	BYTE PTR CS:[OFFSET USLS+3],100b
	JZ	JJAN12	;Pula se JANELA 1 nao pode ser ESCRITA
	CMP	WSEG,0	;Verifica se WSEG e WJAN ja esta ajustado para
	JNZ	JJAN12	;janela 0. Afirmativo, mantem assim.
	MOV	WSEG,BX ;Marca: GRAVAR no segmento da janela 0
	MOV	WJAN,1
	JJAN12:
	;--------------------------------------------------------
	;Fim dos testes com as janelas de video
	
	MOV	AX,64d		;Calcula GranFactor (GRFC=64/GRAN)
	XOR	DX,DX
	DIV	WORD PTR CS:[OFFSET GRAN]
	;DEC	 AL		;15NOV98 ********
	MOV	CS:GRFC,AL
	;FIM DAS ROTINAS DE VERIFICACAO E AJUSTE DO VIDEO
	;---------------------------------------------------------

	CALL	IMNS		;Instala manipuladores de interrupcao
	
	;Prepara o desktop para ser apresentado ao usuario
	;-------------------------------------------------
	
	MOV	AX,CS:RX	;Posiciona o mouse no centro da tela
	SHR	AX,1
	MOV	CS:XPOS,AX
	MOV	AX,CS:RY
	SHR	AX,1
	MOV	CS:YPOS,AX

	;Ajusta palete de video
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET RGBVAL
	CALL	SYSPLT
	
	MOV	FPAL,FALT	;Ajusta tamanho da fonte pequena
	CALL	MAXL		;Maximiza limites
	CALL	CSHOW		;Exibe cursor do mouse
	CALL	SEARCH		;Procura pelas janelas ja existentes no disco
	CALL	BMP		;Le o BMP de fundo pra memoria
	MOV	WINM,3		;Marca flag: NAO ATUALIZAR DISCO
	CALL	REWRITE 	;Apresenta desktop
	
	;Define modo de controle do cursor
	CALL	MCTR
	
	CMP	CCSM,0		;Verifica se verificou a checksum 
	JNZ	JBG7		;Sera NEGATIVO caso o usuario esteja apenas reiniciando com SH+F5	
	CMP	INDX,0		;Verifica se nao encontrou nenhuma janela

	JNZ	JBG7		;Caso tenha encontrado, pula proxima rotina

	CALL	INIW		;Caso nao tenha encontrado, exibe janela de abertura
	JBG7:
	
	MOV	CCSM,1		;Marca: NAO VERIFICAR CHECKSUM / NAO EXIBIR MAIS A JANELA DE ABERTURA
	
	;Verifica parametros - Executar programa
	
	PUSH	CS		;Copia o parametro para o buffer
	POP	DS
	MOV	SI,80h
	CLD
	LODSB
	INC	SI
	CMP	AL,2		;Nao havendo parametros..
	JNA	JNEPB		;nao executa. Pula
	DEC	AL
	MOVZX	CX,AL
	PUSH	CS		;Copia parametro para o buffer da funcao EXECP
	POP	ES
	MOV	DI,OFFSET ICOP
	REP	MOVSB
	XOR	AL,AL		;Grava zero final
	STOSB
	MOV	WORD PTR CS:[OFFSET ICOD],0
	CALL	EXECP		;Executa programa
	
	JNEPB:
	;INICIA ROTINA PRINCIPAL
	;---------------------------------
	CALL	MROT		;Inicia interacao
	
	;---------------------------------------------
	PFIM:			;Finalizacao do sistema   
	CALL	DMNS		;Desinstala manipuladores de interrupcao
	
	MOV	DX,UART
	CALL	POPP		;Restaura porta do mouse
	
	MOV	AX,0003h	;Encerra o programa
	INT	10h
	
	PUSH	CS		;Restaura palette padrao 
	POP	DS
	MOV	SI,OFFSET RGBSTD
	CALL	SYSPLT

	;INT 20h fecha todos os arquivos abertos,
	;desaloca todos os buffers alocados pelo Nanosis,
	;restaura vetor e manipulador de erro (INT 24h),
	;e retira Nanosis da memoria.
	
	PUSH	40h		;Restaura estado do teclado
	POP	DS
	MOV	AL,L17H
	MOV	BYTE PTR DS:[17h],AL

	INT	20h		;Nanosistemas finaliza execucao
	
	;Controle retorna ao sistema operacional
	;..e o processador pode descansar em paz.
	
----------------------------------------------------------------------------
;Definicao das fontes correspondentes a tabela ASCII, enquadrando os 
;caracteres que vao de numero 33d ate os de numero 126d, totalizando 
;96 definicoes.

CURSR:	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111100b
	db	00000000b
	
FONT1:	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	
	db	00000000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00011000b
	db	00000000b
	db	00011000b
	db	00011000b
	db	00000000b
	
	db	00000000b
	db	00110110b
	db	00110110b
	db	00010010b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00100100b
	db	00100100b
	db	01111110b
	db	00100100b
	db	00100100b
	db	00100100b
	db	01111110b
	db	00100100b
	db	00100100b
	db	00000000b


	db	00000000b

	db	00000000b
	db	00011000b
	db	00111110b
	db	01011000b
	db	01011000b
	db	00111100b
	db	00011010b
	db	00011010b
	db	01111100b


	db	00011000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	01100000b
	db	01100010b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00010000b

	db	00100000b
	db	01000110b
	db	00000110b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00110000b
	db	01001000b
	db	01001000b
	db	01010000b
	db	00100000b
	db	01010000b
	db	01001010b
	db	01000100b
	db	00111010b
	db	00000000b
	db	00000000b

	db	00000000b
	db	01000000b
	db	01000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00010000b
	db	00001000b
	db	00000100b
	db	00000000b

	db	00000000b
	db	00100000b
	db	00010000b
	db	00001000b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	01010100b
	db	00111000b
	db	00111000b
	db	01010100b
	db	00010000b
	db	00000000b
	db	00000000b
	db	00000000b


	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00010000b
	db	01111100b
	db	00010000b
	db	00010000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	00110000b
	db	00010000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111100b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01100000b
	db	01100000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000010b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01000110b
	db	01001010b
	db	01010010b
	db	01100010b
	db	01000010b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	00001000b
	db	00011000b
	db	00101000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00000000b

	db	00000000b
	db	00011100b
	db	00100010b
	db	01000010b
	db	00000010b
	db	00000010b
	db	00000100b
	db	00001000b

	db	00010000b
	db	00100000b
	db	01111110b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	00000010b
	db	00011100b
	db	00000010b
	db	00000010b
	db	01000010b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	00000100b
	db	00001100b
	db	00010100b
	db	00100100b
	db	01000100b
	db	01111110b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000000b

	db	00000000b
	db	01111111b
	db	01000000b
	db	01000000b
	db	01111100b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	00000110b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	01111110b
	db	00000010b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b

	db	01000010b
	db	01000010b
	db	00111110b
	db	00000010b
	db	00000010b
	db	00000100b
	db	00001000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00011000b
	db	00011000b
	db	00000000b
	db	00011000b
	db	00011000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00011000b
	db	00011000b
	db	00000000b
	db	00011000b
	db	00011000b
	db	00001000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	00100000b
	db	00010000b
	db	00001000b
	db	00000100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111110b
	db	00000000b
	db	00000000b
	db	00111110b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	01000000b
	db	00100000b
	db	00010000b
	db	00001000b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	00000010b
	db	00000010b
	db	00000100b
	db	00001000b
	db	00010000b

	db	00010000b
	db	00000000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01001010b
	db	01001110b
	db	01001000b
	db	01000000b

	db	01000000b
	db	01000000b
	db	00111110b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01111110b
	db	01000010b

	db	01000010b
	db	01000010b
	db	01000010b
	db	00000000b




	db	00000000b
	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01111100b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	01111000b
	db	01000100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000100b
	db	01111000b
	db	00000000b

	db	00000000b
	db	01111110b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01111110b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01111110b
	db	00000000b

	db	00000000b
	db	01111110b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01111100b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01001110b
	db	01000010b
	db	01000010b
	db	00111110b
	db	00000000b

	db	00000000b
	db	01000010b
	db	01000010b

	db	01000010b
	db	01000010b
	db	01000010b
	db	01111110b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00000000b

	db	00000000b
	db	00111000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00011110b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000100b
	db	01000100b
	db	01000100b
	db	00111000b
	db	00000000b

	db	00000000b
	db	01000010b
	db	01000100b
	db	01001000b
	db	01010000b
	db	01100000b
	db	01010000b
	db	01001000b
	db	01000100b
	db	01000010b
	db	01000010b
	db	00000000b

	db	00000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01111110b
	db	00000000b

	db	00000000b
	db	01000001b
	db	01100011b
	db	01010101b
	db	01001001b
	db	01001001b
	db	01001001b
	db	01000001b
	db	01000001b
	db	01000001b
	db	01000001b
	db	00000000b

	db	00000000b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01100010b
	db	01010010b
	db	01001010b
	db	01000110b
	db	01000010b

	db	01000010b
	db	01000010b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b

	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01111100b
	db	01000000b
	db	01000000b
	db	01000000b

	db	01000000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01010010b
	db	01001010b
	db	01000100b
	db	00111010b
	db	00000000b

	db	00000000b
	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01111100b
	db	01010000b
	db	01001000b
	db	01000100b
	db	01000010b
	db	01000010b
	db	00000000b

	db	00000000b
	db	00111110b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00111100b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
	db	01111100b
	db	00000000b

	db	00000000b
	db	01111110b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00000000b


	db	00000000b
	db	01000010b

	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00100100b
	db	00100100b
	db	00100100b
	db	00011000b
	db	00011000b
	db	00000000b

	db	00000000b
	db	01000001b
	db	01000001b
	db	01000001b
	db	01000001b
	db	01000001b
	db	01001001b
	db	01001001b
	db	01001001b
	db	01010101b
	db	01100011b
	db	00000000b

	db	00000000b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00100100b
	db	00011000b
	db	00011000b
	db	00100100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00000000b

	db	00000000b
	db	01000100b
	db	01000100b
	db	01000100b
	db	01000100b
	db	00101000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	01111110b
	db	00000010b
	db	00000010b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	01000000b

	db	01111110b
	db	00000000b

	db	00000000b
	db	01110000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01110000b

	db	00000000b
			
	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	00100000b
	db	00010000b
	db	00001000b
	db	00000100b
	db	00000010b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	01110000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b

	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00001000b
	db	00010100b
	db	00100010b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111110b
	db	00000000b

	db	00000000b
	db	01100000b
	db	01100000b
	db	00110000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111100b
	db	00000010b
	db	00111110b
	db	01000010b
	db	01000010b
	db	00111110b
	db	00000000b

	db	00000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b

	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01111100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111110b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00111110b

	db	00000000b


	db	00000000b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00111110b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111110b
	db	00000000b

	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00111100b
	db	01000010b
	db	01111110b
	db	01000000b
	db	01000000b
	db	00111110b
	db	00000000b

	db	00000000b
	db	00011000b
	db	00100100b
	db	00100000b
	db	00100000b
	db	00100000b
	db	01110000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111110b
	db	00000010b
	db	00111100b

	db	00000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00001000b
	db	00000000b
	db	00011000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00011100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000100b
	db	00000000b
	db	00001100b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00100100b
	db	00011000b

	db	00000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01001000b
	db	01010000b
	db	01100000b
	db	01010000b
	db	01001000b
	db	01000100b
	db	01000100b
	db	00000000b

	db	00000000b
	db	00110000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01110110b
	db	01001001b
	db	01001001b
	db	01001001b
	db	01001001b
	db	01001001b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111100b
	db	00100010b
	db	00100010b
	db	00100010b
	db	00100010b
	db	00100010b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111100b
	db	01000010b
	db	01000010b
	db	01000010b
	db	01111100b
	db	01000000b
	db	01000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111110b
	db	01000010b
	db	01000010b
	db	01000010b
	db	00111110b
	db	00000010b
	db	00000010b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01011100b
	db	01100000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111110b
	db	01000000b
	db	00111100b
	db	00000010b
	db	00000010b
	db	01111100b
	db	00000000b

	db	00000000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00111000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010100b
	db	00001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	01000100b
	db	01000100b
	db	01000100b
	db	01000100b
	db	01000100b
	db	00111100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01000100b
	db	01000100b
	db	01000100b
	db	01000100b
	db	00101000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01000001b
	db	01000001b
	db	01001001b
	db	01001001b
	db	01001001b
	db	00110110b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01000100b
	db	01000100b
	db	00101000b
	db	00010000b
	db	00101000b
	db	01000100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00100010b
	db	00100010b
	db	00100010b
	db	00100010b
	db	00011110b
	db	00000010b
	db	00111100b
	
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111110b
	db	00000010b
	db	00000100b
	db	00011000b
	db	00100000b
	db	01111110b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00011100b
	db	00100000b
	db	00100000b
	db	00100000b
	db	01000000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00011100b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00000000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00111000b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00000010b
	db	00000100b
	db	00000100b
	db	00000100b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00101010b
	db	00000100b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b


;DEFINICOES DA FONTE MENOR
FONT2:	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00000000b
	db	00010000b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01101100b
	db	00100100b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01010000b

	db	01010000b
	db	11111000b
	db	01010000b
	db	01010000b
	db	11111000b
	db	01010000b
	db	01010000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b

	db	00111100b
	db	01010000b
	db	00111000b
	db	00010100b
	db	01111000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01100100b
	db	01001000b
	db	00010000b
	db	00100100b
	db	01001100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01010000b
	db	00100000b
	db	01010010b
	db	01001100b
	db	00111010b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	01000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00010000b

	db	00000000b


	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00100000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	01010100b
	db	00111000b
	db	00111000b
	db	01010100b
	db	00010000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00010000b
	db	01111100b
	db	00010000b
	db	00010000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01100000b
	db	00100000b
	db	01000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111100b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00100000b
	db	00000000b
	

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000100b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	10000000b

	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01001000b
	db	01011000b
	db	01101000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00110000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	00001000b
	db	00001000b
	db	00010000b
	db	00010000b
	db	00100000b
	db	01111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	00001000b
	db	00010000b
	db	00001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b

	db	00000000b
	db	00001000b
	db	00011000b
	db	00101000b
	db	01001000b
	db	01111100b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01111000b

	db	01000000b
	db	01000000b
	db	00110000b
	db	00001000b
	db	00001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00001000b
	db	00010000b
	db	00100000b
	db	01110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01111000b
	db	00001000b
	db	00001000b
	db	00010000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01001000b
	db	00110000b

	db	01001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00111000b
	db	00001000b
	db	00001000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00100000b
	db	00000000b
	db	00100000b
	db	01000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	00100000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111100b
	db	00000000b
	db	00000000b
	db	01111100b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	00100000b
	db	00010000b
	db	00100000b


	db	01000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	00001000b
	db	00010000b
	db	00100000b
	db	00000000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b
	db	10001000b
	db	10001000b
	db	10101000b
	db	10101000b
	db	10111000b
	db	10000000b
	db	01100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01001000b
	db	01111000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b
	db	01001000b
	db	01001000b
	db	01110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b

	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01111000b
	db	01000000b
	db	01000000b
	db	01111000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01111000b
	db	01000000b
	db	01000000b
	db	01111000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01000000b
	db	01000000b
	db	01011000b
	db	01001000b
	db	01001000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	01001000b
	db	01001000b
	db	01001000b
	db	01111000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00011100b

	db	00001000b
	db	00001000b

	db	00001000b
	db	00001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b


	db	00000000b
	db	00000000b

	db	00000000b
	db	01001000b

	db	01001000b
	db	01010000b
	db	01100000b
	db	01010000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01111000b
	db	00000000b


	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01111000b
	db	01101000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01101000b
	db	01101000b
	db	01011000b
	db	01011000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b



	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b

	db	00000000b
	db	00000000b
	db	01110000b
	db	01001000b
	db	01001000b
	db	01110000b
	db	01000000b
	db	01000000b 
	db	01000000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b

	db	01001000b
	db	01001000b
	db	01001000b
	db	01011000b
	db	01011000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b
	db	01001000b

	db	01001000b
	db	01110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00111000b
	db	01000000b
	db	01000000b
	db	00110000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	11111000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01010000b
	db	01010000b
	db	01010000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01011000b
	db	01011000b
	db	01111000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00110000b
	db	01001000b
	db	01001000b

	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01010000b
	db	01010000b
	db	01010000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01111000b
	db	00001000b

	db	00001000b
	db	00010000b
	db	00100000b
	db	01000000b
	db	01000000b
	db	01111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b
	db	01000000b
	db	01000000b

	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01110000b
	db	00000000b
			
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10000000b
	db	01000000b
	db	00100000b
	db	00010000b
	db	00001000b
	db	00000100b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00101000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111110b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	01000000b
	db	00100000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	00001000b
	db	00111000b
	db	01001000b
	db	01001000b
	db	00111000b
	db	00000000b



	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	01000000b
	db	01110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00001000b
	db	00001000b
	db	00111000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00110000b
	db	01001000b
	db	01111000b
	db	01000000b
	db	01000000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00101000b
	db	00100000b
	db	01110000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b

	db	00000000b
	db	00111000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00111000b
	db	00001000b
	db	00111000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	01000000b
	db	01110000b
	db	01001000b

	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00010000b
	db	00000000b
	db	00110000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00001000b
	db	00000000b
	db	00011000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	01001000b
	db	00110000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01001000b


	db	01010000b
	db	01100000b
	db	01010000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b

	db	00010000b
	db	00010000b
	db	00111000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01010000b
	db	01111000b
	db	01011000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01110000b
	db	01001000b
	db	01001000b

	db	01001000b
	db	01001000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	01110000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01110000b
	db	01000000b
	db	01000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00111000b
	db	00001000b
	db	00001000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01011000b
	db	01100000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00111000b
	db	01000000b
	db	01000000b

	db	00110000b
	db	00001000b
	db	01110000b
	db	00000000b

	db	00000000b
	db	00000000b

	db	00000000b
	db	00100000b
	db	00100000b
	db	01110000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00101000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b

	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00111000b
	db	00000000b

	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00101000b
	db	00010000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01101000b
	db	01101000b
	db	00110000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	00101000b
	db	00010000b
	db	00101000b
	db	01001000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00111000b

	db	00001000b
	db	00110000b
	
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	01111000b
	db	00001000b
	db	00001000b
	db	00010000b
	db	00100000b

	db	01111000b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00011000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	01000000b
	db	00100000b
	db	00100000b
	db	00100000b
	db	00011000b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00010000b	
	db	00010000b
	db	00010000b
	db	00010000b
	db	00000000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	01100000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	00001000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	01100000b
	db	00000000b

	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b 
	db	00000000b
	db	01000000b
	db	10101000b
	db	00010000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b

MORE1:	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	10010010b
	db	00000000b
	
	db	00000000b ;DIRETORIO: 128 e 129
	db	00000000b
	db	00000000b
	db	11111110b
	db	10000001b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	11111111b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111110b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
	db	11111110b
	db	00000000b
	
	db	00000000b ;ARQUIVO: 130 e 131
	db	00000000b
	db	00000000b
	db	11111111b

	db	10000000b
	db	11111111b
	db	10000000b
	db	10000000b
	db	10000000b
	db	10000000b
	db	11111111b
	db	00000000b
	
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111110b
	db	00000010b
	db	11111110b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
	db	11111110b
	db	00000000b
	

	db	00000000b ;DISCO RIGIDO: 132 e 133
	db	00000011b
	db	00000100b
	db	00001000b
	db	00010001b
	db	00010011b
	db	00010110b
	db	00001100b
	db	00111000b
	db	01110100b
	db	11100011b
	db	00000000b
	
	db	00000000b
	db	00111000b
	db	00000100b
	db	00000010b
	db	00110001b
	db	00000001b
	db	00000001b
	db	00000001b
	db	00000010b
	db	00000100b
	db	00111000b
	db	00000000b
	
	db	00000000b ;DISQUETE: 134 e 135
	db	01111111b
	db	01100000b
	db	01000000b
	db	01000000b
	db	01000000b
	db	01001111b
	db	01001000b
	db	01001000b
	db	01001000b
	db	00111111b
	db	00000000b
	
	db	00000000b

	db	11111110b
	db	00000010b
	db	00000010b
	db	00000010b
	db	00000010b
	db	11110010b
	db	01110010b
	db	01110010b
	db	01110010b
	db	11111110b
	db	00000000b
	
	db	00000000b ;CD ROM: 136 e 137
	db	00000111b
	db	00001000b
	db	00010000b

	db	00100000b
	db	00100000b
	db	00100000b
	db	00100110b
	db	00011100b
	db	00001100b 
	db	00000111b
	db	00000000b
	
	db	00000000b
	db	00111000b
	db	00001100b
	db	00001110b
	db	00011001b
	db	00100001b
	db	00100001b
	db	00000001b
	db	00000010b
	db	00000100b
	db	00111000b
	db	00000000b
	
	db	00000000b ;SETA P/ BAIXO: 138
	db	00000000b
	db	00000000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00111110b
	db	00011100b
	db	00001000b
	db	00000000b
	
	db	00000000b ;SETA P/ CIMA: 139
	db	00000000b
	db	00000000b
	db	00001000b
	db	00011100b
	db	00111110b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00001000b
	db	00000000b
	db	00000000b

	db	00000000b ;TRIANGULO LEFT: 140
	db	00000000b
	db	00000000b
	db	00001000b
	db	00011000b
	db	00111000b
	db	01111000b
	db	00111000b
	db	00011000b
	db	00001000b
	db	00000000b
	db	00000000b
	
	db	00000000b ;TRIANGULO RIGHT: 141
	db	00000000b
	db	00000000b
	db	01000000b
	db	01100000b
	db	01110000b
	db	01111000b
	db	01110000b
	db	01100000b
	db	01000000b
	db	00000000b
	db	00000000b

	db	00000000b ;UNITS "X": 142
	db	00000000b
	db	00000000b
	db	00000000b
	db	00000000b
	db	11011000b
	db	01110000b
	db	00100000b
	db	01110000b
	db	11011000b
	db	00000000b
	db	00000000b

	db	00000000b ;UNITS "X": 142
	db	00000000b
	db	00000000b
	db	00000000b
	db	11111110b
	db	10010010b
	db	11000110b
	db	11101110b
	db	11000110b
	db	10010010b
	db	11111110b
	db	00000000b
	

;ICONE PARA TESTES
TBMP:	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db	0FFh,0FFh,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	db	0FFh,0FFh,00,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,00
	db	0FFh,0FFh,00,08,08,08,08,08,08,08,08,08,07,07,07,07,07,07,07,07,07,07,08,08,08,08,08,08,08,08,08,00
	db	0FFh,0FFh,00,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,03,00
	db	0FFh,0FFh,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,15,07,00
	db	0FFh,0FFh,00,15,15,15,00,00,00,15,15,15,15,15,00,00,00,15,15,15,15,15,08,08,00,15,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,15,00,15,00,15,15,15,15,15,09,08,00,15,15,15,15,15,08,09,00,15,15,15,00,15,07,00
	db	0FFh,0FFh,00,15,15,00,00,00,00,15,15,15,15,00,00,00,00,15,15,15,15,00,08,08,00,00,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,15,00,00,00,15,15,15,15,15,00,00,00,15,15,15,15,00,00,00,00,00,15,15,00,15,07,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,00,00,00,00,15,15,15,15,00,00,00,00,00,15,15,15,15,00,00,00,00,15,15,00,15,07,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,15,07,00
	db	0FFh,0FFh,00,15,15,15,15,13,00,15,15,15,15,00,00,00,00,00,15,15,15,15,00,00,00,00,15,15,00,15,07,00
	db	0FFh,0FFh,00,15,15,15,00,15,13,15,15,15,15,00,00,14,00,15,15,15,15,15,00,03,09,00,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,13,13,13,00,15,15,15,15,15,00,00,15,15,15,15,15,15,00,00,00,00,15,15,00,15,07,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,00,00,00,00,15,15,15,15,00,00,00,00,00,15,15,15,15,00,00,00,00,15,15,00,00,00,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,07,15,00
	db	0FFh,0FFh,00,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,00,15,07,00
	db	0FFh,0FFh,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	db	0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh

;ESTRUTURA DO MENU (BDP)
RBDX	DW	10	;Pos X				+0
RBDY	DW	10	;Pos Y				+2
	DB	07	;Cor do menu			+4
	DB	0	;Cor dos textos do menu 	+5
	DB	070h	;Tipo:0=Normal,AB=Com titulo	+6 
			;(AB = Cor do titulo, sendo A=Foreground, B=Background)
	DB	3 dup (0)	;Reservado		+7
	DB	'Desktop',13d
VARST:	;Inicio das variaveis a serem "zeradas"
RBDT:	DB 4500d dup (?);Buffer RBDT. XferM of the system
	DB 4500d dup (?)
RBTE:	
MVIB:	DB 1024 dup (?) ;Icon drag movement buffer
			;Used too as a timer por the icons of the ICDIR routine
			
	;RBDT: second part of buffer
B24TM	DD	?	;BMP: Temp. Receive 24bits of file (OpSo: What is this?)
BDTC:	DD  256 dup (?) ;BMP: colors table (RGB colors of the BMP)
BCTC	DW	?	;BMP: tab counter (Indicates next level color, n x 4)
	
MMWBUF	DB   13 dup (?) ;MMW file buffer
TNIT:	DB   22 dup (?) ;Buffers of menu text "INSERT NEW ICON"
	
;JANELAS NO DESKTOP
INDX	DW	?	;Number of windows
WIN1:	DD MJAN*2 DUP (?)  ;X,Y,XX,YY (four words) window position
TTLS:	DD MJAN*2 DUP (?)  ;MMW file names

;Windows file structure (MMW)
MMWT:	DB   MMWTS dup (?)	;ASCII window title
MMWX	DW	?		;XYXXYY window position
MMWY	DW	?
MMWXX	DW	?
MMWYY	DW	?
MMWC:	DB   MMWCS dup (?)	;window configuration (colors, sizes, etc..)	
				;OFFSET MMWC+18 : WORD : SCROLL position
				;OFFSET MMWC+17 : BYTE : Flag : 0=Normal, 1=hidden
				;OFFSET MMWC+15 : WORD : Checksum of MMW

			
;Creation Window Buffer
BMMWT:	 DB   MMWTS dup (?)	;ASCII Window title
BMMWX	 DW	 ?		;XYXXYY window position
BMMWY	 DW	 ?
BMMWXX	 DW	 ?
BMMWYY	 DW	 ?
BMMWC:	 DB   MMWCS dup (?)	;Window configuration (colors, sizes, etc..)	
				;OFFSET MMWC+18 : WORD : Scroll position
				;OFFSET MMWC+17 : BYTE : Flag : 0=Normal, 1=Hidden
				;OFFSET MMWC+15 : WORD : Checksum of MMW

;Windows an Icons structure
ICOT:	DB ICOTS dup (?)	;ASCII Icon title
ICOB:	DB ICOBS dup (?)	;BMP Icon define (with colors)
ICOP:	DB ICOPS dup (?)	;ASCII Path and/or FileName
ICOD:	DB ICODS dup (?)	;ASCII Work directory
ICOR:	DB ICORS dup (?)	;Reserved

;Buffer to copy icons
ICOC:	
BICOT:	DB ICOTS dup (?)	;ASCII Icon title
BICOB:	DB ICOBS dup (?)	;BMP Icon define (with colors)
BICOP:	DB ICOPS dup (?)	;ASCII Path and/or FileName
BICOD:	DB ICODS dup (?)	;ASCII work directory
BICOR:	DB ICORS dup (?)	;reserved

;VESA1: Current Video Mode Information
GRFC	DB	?	;Factor to be increased (video granularity)
			;GRFC=(64/GRAN)-1
;Next: written for INT 10h
USLS:	DB	?,?,?,? ;Not used by the system
GRAN	DW	?	;Window 'granularity'
PSIZ	DW	?	;Page size (kilobytes)
SEGA	DW	?	;Window Segment "A" address
SEGB	DW	?	;Window Segment "B" address
POIN	DD	?	;Point to display memory function
BPSL	DW	?	;Bytes per line scan
RX	DW	?	;Horizontal resolution in pixels
RY	DW	?	;Vertical resolution in pixels
			;0FFh bytes using in the buffers at bottom
	DB 236 dup (?)			

;BUFFERS
PARAMTR:DB   79 dup (?) ;EXECP: Buffer: App Parameters to be executed
PROGRAM:DB   79 dup (?) ;EXECP: Buffer: File name to be executed (or to be run)
OLDDIRE:DB   79 dup (?) ;EXECP: Buffer
DTABUF: DB  1Eh dup (?) ;DTA: reserved(0) for the SEARCH routine
DTFILE: DB   12 dup (?) ;DTA: File name not found
CTMP:	DB  240 dup (?) ;CUR: Buffer to retrace the cursor (240 bytes of buffers used)
OAIX	DW	?	;Buffer for Inclusion Area
OAIY	DW	?	;It can be used for any routine
OAIXX	DW	?	;0:2048X/1:1024X and/or needed value
OAIYY	DW	?	;Permited limits compression
COMS	DW	?	;Size of a file in disk in bytes

STAKA	DB 512 dup (?) ;End of a operational stack
STAKB:			;Init of a operational stack

VARSR:

MMFIM:

PROG	ENDS
END	INIC
