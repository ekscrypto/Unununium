%ifndef __MWTYPES_INC__
%define __MWTYPES_INC__

; builtin font standard names
%define MWFONT_SYSTEM_VAR	"System"	; winSystem 14x16 (ansi)
%define MWFONT_GUI_VAR		"Helvetica"	; winMSSansSerif 11x13 (ansi)
%define MWFONT_OEM_FIXED	"Terminal"	; rom8x16 (oem)
%define MWFONT_SYSTEM_FIXED	"SystemFixed"	; X6x13 (should be ansi)

; Text/GetTextSize encoding flags
%assign MWTF_ASCII		0x0000		; 8 bit packing, ascii
%assign MWTF_UTF8		0x0001		; 8 bit packing, utf8
%assign MWTF_UC16		0x0002		; 16 bit packing, unicode 16
%assign MWTF_UC32		0x0004		; 32 bit packing, unicode 32
%assign MWTF_PACKMASK		0x0007		; packing mask

; Text alignment flags
%assign MWTF_TOP		0x0010		; align on top
%assign MWTF_BASELINE		0x0020		; align on baseline
%assign MWTF_BOTTOM		0x0040		; align on bottom

; SetFontAttr flags
%assign MWTF_KERNING		0x1000		; font kerning
%assign MWTF_ANTIALIAS		0x2000		; antialiased output
%assign MWTF_UNDERLINE		0x4000		; draw underline

; Drawing modes
%assign MWMODE_COPY		0		; src
%assign MWMODE_XOR		1		; src ^ dst
%assign MWMODE_OR		2		; src | dst
%assign MWMODE_AND		3		; src & dst
%assign MWMODE_CLEAR		4		; 0
%assign MWMODE_SET		5		; 11111111, was WMMODE_SETTO1
%assign MWMODE_EQUIV		6		; ~(src ^ dst)
%assign MWMODE_NOR		7		; ~(src | dst)
%assign MWMODE_NAND		8		; ~(src & dst)
%assign MWMODE_INVERT		9		; ~dst
%assign MWMODE_COPYINVERTED	10		; ~src
%assign MWMODE_ORINVERTED	11		; ~src | dst
%assign MWMODE_ANDINVERTED	12		; ~src & dst
%assign MWMODE_ORREVERSE	13		; src | ~dst
%assign MWMODE_ANDREVERSE	14		; src & ~dst
%assign MWMODE_NOOP		15		; dst
%assign MWMODE_MAX		15

; Mouse button bits
%assign MWBUTTON_L		04
%assign MWBUTTON_M		02
%assign MWBUTTON_R		01

; Color defines
%define MWRGB(r,g,b)		((r)&0xFF) | (((g)&0xFF)<<8) | (((b)&0xFF)<<16)
%assign MWF_PALINDEX		0x01000000
%define MWPALINDEX(x)		(MWF_PALINDEX | (x))

; ROP blitter opcodes (extensions < 0x10000000 are MWMODE_xxx blit ops)
%assign MWROP_EXTENSION		0xff000000	; rop extension bits

; copy src -> dst except for transparent color in src
%assign MWROP_SRCTRANSCOPY	0x11000000

; alpha blend src -> dst with constant alpha, alpha value in low 8 bits
%assign MWROP_BLENDCONSTANT	0x12000000

; alpha blend fg/bg color -> dst with src as alpha channel
%assign MWROP_BLENDFGBG		0x13000000

; alpha blend src -> dst with separate per pixel alpha channel
%assign MWROP_BLENDCHANNEL	0x14000000

; stretch src -> dst
%assign MWROP_STRETCH		0x15000000

; blits rops based on src/dst binary operations
%define MWROP_COPY		(MWMODE_COPY << 24)
%define MWROP_XOR		(MWMODE_XOR << 24)
%define MWROP_OR		(MWMODE_OR << 24)
%define MWROP_AND		(MWMODE_AND << 24)
%define MWROP_CLEAR		(MWMODE_CLEAR << 24)
%define MWROP_SET		(MWMODE_SETTO1 << 24)
%define MWROP_EQUIV		(MWMODE_EQUIV << 24)
%define MWROP_NOR		(MWMODE_NOR << 24)
%define MWROP_NAND		(MWMODE_NAND << 24)
%define MWROP_INVERT		(MWMODE_INVERT << 24)
%define MWROP_COPYINVERTED	(MWMODE_COPYINVERTED << 24)
%define MWROP_ORINVERTED	(MWMODE_ORINVERTED << 24)
%define MWROP_ANDINVERTED	(MWMODE_ANDINVERTED << 24)
%define MWROP_ORREVERSE		(MWMODE_ORREVERSE << 24)
%define MWROP_ANDREVERSE	(MWMODE_ANDREVERSE << 24)
%define MWROP_NOOP		(MWMODE_NOOP << 24)

;%define MWROP_SRCCOPY		MWROP_COPY	; obsolete
;%define MWROP_SRCAND		MWROP_AND	; obsolete
;%define MWROP_SRCINVERT	MWROP_XOR	; obsolete
;%define MWROP_BLACKNESS	MWROP_CLEAR	; obsolete

; convert an MWROP to drawing mode MWMODE value
%define MWROP_TO_MODE(op)	((op) >> 24)
%define MWMODE_TO_ROP(op)	((op) << 24)

; Pixel formats
;
; Note the two pseudo pixel formats are never returned by display drivers,
; but rather used as a data structure type in GrArea.  The other
; types are both returned by display drivers and used as pixel packing
; specifiers.
%assign MWPF_RGB		0 ; pseudo, convert from packed 32 bit RGB
%assign MWPF_PIXELVAL		1 ; pseudo, no convert from packed PIXELVAL
%assign MWPF_PALETTE		2 ; pixel is packed 8 bits 1, 4 or 8 pal index
%assign MWPF_TRUECOLOR0888	3 ; pixel is packed 32 bits 8/8/8 truecolor
%assign MWPF_TRUECOLOR888	4 ; pixel is packed 24 bits 8/8/8 truecolor
%assign MWPF_TRUECOLOR565	5 ; pixel is packed 16 bits 5/6/5 truecolor
%assign MWPF_TRUECOLOR555	6 ; pixel is packed 16 bits 5/5/5 truecolor
%assign MWPF_TRUECOLOR332	7 ; pixel is packed 8 bits 3/3/2 truecolor

; MWPIXELVAL definition: changes based on target system
; Set using -DMWPIXEL_FORMAT=MWPF_XXX
;
; For the Nano-X server, it is important to use the correct MWPF_* value
; for the MWPIXEL_FORMAT macro in order to match the hardware,
; while the Nano-X clients that includes this file can get away with
; a default pixel format of 24-bit color as the client will either:
;
;    1) Use the MWPF_PIXELVAL native format when calling GrReadArea, in
;       which case we have to have enough spare room to hold 32-bit
;       pixlevalues (hence the default MWPF_TRUECOLOR0888 format), or
;
;    2) Will use some other PF_* format, in which case the application
;       is well aware of which pixel-format it uses and can avoid the
;       device specific RGB2PIXEL and use RGB2PIXEL565 etc. instead,
;       and specifiy the pixel fomar as MWPF_TRUECOLOR565 etc. when
;       calling the GrArea function(s).
%ifndef MWPIXEL_FORMAT
%define MWPIXEL_FORMAT		MWPF_TRUECOLOR0888
%endif


%ifidn   MWPIXEL_FORMAT, MWPF_TRUECOLOR656
 %define ___mwpixelword___
%elifidn MWPIXEL_FORMAT, MWPF_TRUECOLOR555
 %define ___mwpixelword___
%elifidn MWPIXEL_FORMAT, MWPF_TRUECOLOR332
 %define ___mwpixelbyte___
%elifidn MWPIXEL_FORMAT, MWPF_PALETTE
 %define ___mwpixelbyte___
%else
 %define ___mwpixeldword___
%endif

%macro MWPIXELVAL 0.nolist	; param: none
 %ifdef   ___mwpixeldword___
  dd 0
  %define resMWPIXELVAL resd 1
  %assign MWPIXELVAL_size 4
 %elifdef ___mwpixelword___
  dw 0
  %define resMWPIXELVAL resw 1
  %assign MWPIXELVAL_size 2
 %else
  db 0
  %define resMWPIXELVAL resb 1
  %assign MWPIXELVAL_size 1
 %endif
%endmacro
%macro MWPIXELVAL 1.nolist	; param: pixel value
 %ifdef   ___mwpixeldword___
  dd %1
 %elifdef ___mwpixelword___
  dw %1
 %else
  db %1
 %endif
%endmacro
%macro MWPIXELVAL 2.nolist	; param: label, pixel value
 %ifdef   ___mwpixeldword___
  %1: dd %2
 %elifdef ___mwpixelword___
  %1: dw %2
 %else
  %1: db %2
 %endif
%endmacro

; portrait modes
%assign MWPORTRAIT_NONE		0x00	; hw framebuffer, no rotation
%assign MWPORTRAIT_LEFT		0x01	; rotate left
%assign MWPORTRAIT_RIGHT	0x02	; rotate right
%assign MWPORTRAIT_DOWN		0x04	; upside down

; Type definitions
%define MWCOORD		dd		; device coordinates
%define resMWCOORD	resd 1		; . for unitialized data
%assign MWCOORD_size	4

%define MWBOOL		dd		; boolean value
%define resMWBOOL	resd 1		; . for unitialized data
%assign MWBOOL_size	4

%define MWUCHAR		db		; unsigned char
%define resMWUCHAR	resb 1		; . for unitialized data
%assign MWUCHAR_size	1

%define MWCOLORVAL	dd		; device-independent color value
%define resMWCOLORVAL	resd 1		; . for unitialized data
%assign MWCOLORVAL_size 4

%define MWIMAGEBITS	dw		; bitmap image unit size
%define resMWIMAGEBITS	resw 1		; . for unitialized data
%assign MWIMAGEBITS_size 2

%define MWTIMEOUT	dd		; timeout value
%define resMWTIMEOUT	resd 1		; . for unitialized data
%assign MWTIMEOUT_size	4

; double linked list data structure
  struc _mwlist
  .next				resd 1	; next item
  .prev				resd 1	; previous item
  endstruc
  %macro MWLIST 0.nolist
    istruc _mwlist
    iend
  %endmacro
  %macro MWLIST 2.nolist
    istruc _mwlist
    at _mwlist.next, 		dd %1
    at _mwlist.prev, 		dd %2
    iend
  %endmacro
  %define resMWLIST		resb _mwlist_size
  %define MWLIST_size		_mwlist_size
  %define PMWLIST		dd
  %define resPMWLIST		resd 1
  %assign PMWLIST_size		4

; double linked list head data structure
  struc _mwlisthead
  .head				resd 1	; first item
  .tail				resd 1	; last item
  endstruc
  %macro MWLISTHEAD 0.nolist
    istruc _mwlisthead
    iend
  %endmacro
  %macro MWLISTHEAD 2.nolist
    istruc _mwlisthead
    at _mwlisthead.head, 	dd %1
    at _mwlisthead.tail, 	dd %2
    iend
  %endmacro
  %define resMWLISTHEAD		resb _mwlisthead_size
  %define MWLISTHEAD_size	_mwlisthead_size
  %define PMWLISTHEAD		dd
  %define resPMWLISTHEAD	resd 1
  %assign PMWLISTHEAD_size	4

; keyboard state modifiers
%define MWKEYMOD		dd
%define resMWKEYMOD		resd 1
%assign MWKEYMOD_size		4

; GetScreenInfo structure
  struc _mwscreeninfo
  .rows			resMWCOORD	; number of rows on screen
  .cols			resMWCOORD	; number of columns on screen
  .xdpcm		resd 1		; dots/centimeter in x direction
  .ydpcm		resd 1		; dots/centimeter in y direction
  .planes		resd 1		; number of hardware planes
  .bpp			resd 1		; hardware bpp
  .ncolors		resd 1		; hardware number of colors supported
  .fonts		resd 1		; number of built-in fonts
  .buttons		resd 1		; buttons which are implemented
  .modifiers		resMWKEYMOD	; modifiers which are implemented
  .pixtype		resd 1		; format of pixel value
  .portrait		resd 1		; current portrait mode
  .fbdriver		resMWBOOL	; true if running mwin fb screen driver
  .rmask		resd 1		; red mask bits in pixel
  .gmask		resd 1		; green mask bits in pixel
  .bmask		resd 1		; blue mask bits in pixel
  .xpos			resMWCOORD	; current x mouse position
  .ypos			resMWCOORD	; current y mouse position
  
  ; items below are get/set by the window manager and not used internally
  .vs_width		resd 1		; virtual scree width
  .vs_height		resd 1		; virtual screen height
  .ws_width		resd 1		; workspace width
  .ws_height		resd 1		; workspace height
  endstruc
  %macro MWSCREENINFO 0.nolist
    istruc _mwscreeninfo
    iend
  %endmacro
  %macro MWSCREENINFO 18.nolist
    istruc _mwscreeninfo
    at _mwscreeninfo.rows,	MWCOORD %1
    at _mwscreeninfo.cols,	MWCOORD %2
    at _mwscreeninfo.xdpcm,	dd %3
    at _mwscreeninfo.ydpcm,	dd %4
    at _mwscreeninfo.planes,	dd %5
    at _mwscreeninfo.bp,	dd %6
    at _mwscreeninfo.ncolors,	dd %7
    at _mwscreeninfo.fonts,	dd %8
    at _mwscreeninfo.buttons,	dd %9
    at _mwscreeninfo.modifiers,	MWKEYMOD %10
    at _mwscreeninfo.pixtype,	dd %11
    at _mwscreeninfo.portrait,	dd %12
    at _mwscreeninfo.fbdriver,	MWBOOL %13
    at _mwscreeninfo.rmask,	dd %14
    at _mwscreeninfo.gmask,	dd %15
    at _mwscreeninfo.bmask,	dd %16
    at _mwscreeninfo.xpos,	MWCOORD %17
    at _mwscreeninfo.ypos,	MWCOORD %18
    iend
  %endmacro
  %macro MWSCREENINFO 22.nolist
    istruc _mwscreeninfo
    at _mwscreeninfo.rows,	MWCOORD %1
    at _mwscreeninfo.cols,	MWCOORD %2
    at _mwscreeninfo.xdpcm,	dd %3
    at _mwscreeninfo.ydpcm,	dd %4
    at _mwscreeninfo.planes,	dd %5
    at _mwscreeninfo.bp,	dd %6
    at _mwscreeninfo.ncolors,	dd %7
    at _mwscreeninfo.fonts,	dd %8
    at _mwscreeninfo.buttons,	dd %9
    at _mwscreeninfo.modifiers,	MWKEYMOD %10
    at _mwscreeninfo.pixtype,	dd %11
    at _mwscreeninfo.portrait,	dd %12
    at _mwscreeninfo.fbdriver,	MWBOOL %13
    at _mwscreeninfo.rmask,	dd %14
    at _mwscreeninfo.gmask,	dd %15
    at _mwscreeninfo.bmask,	dd %16
    at _mwscreeninfo.xpos,	MWCOORD %17
    at _mwscreeninfo.ypos,	MWCOORD %18
    at _mwscreeninfo.vs_width,	dd %19
    at _mwscreeninfo.vs_height,	dd %20
    at _mwscreeninfo.ws_width,	dd %21
    at _mwscreeninfo.ws_height,	dd %22
    iend
  %endmacro
  %define resMWSCREENINFO	resb _mwscreeninfo_size
  %define MWSCREENINFO_size	_mwscreeninfo_size
  %define PMWSCREENINFO		dd
  %define resPMWSCREENINFO	resd 1
  %assign PMWSCREENINFO_size	4

; client side widnow framebuffer info
  struc _mwwindowfbinfo
  .physpixels			resd 1	; address of real framebuffer
  ; note winpixels is only correct in non-portrait modes
  .winpixels			resd 1	; address of 0,0 this window in fb
  .pixtype			resd 1	; MWPF_ pixel type
  .bpp				resd 1	; bits per pixel
  .bytespp			resd 1	; bytes per pixel
  .pitch			resd 1	; bytes per scan line for window
  					;   (=fb pitch)
  ; note: not sure if x and y should not be MWCOORD instead, doing like nano-x!
  .x				resd 1	; absolute virtual window coordinates
  .y				resd 1	; ..
  .portrait_mode		resd 1	; current portrait mode
  .xres				resMWCOORD; real framebuffer resolution
  .yres				resMWCOORD; ..
  .xvirtres			resMWCOORD; virtual framebuffer resolution
  .yvirtres			resMWCOORD; ..
  endstruc
  %macro MWWINDOWFBINFO 0.nolist
  istruc _mwwindowfbinfo
  iend
  %endmacro
  %macro MWWINDOWFBINFO 13.nolist
  istruc _mwwindowfbinfo
  at _mwwindowfbinfo.physpixels,dd %1
  at _mwwindowfbinfo.winpixels,	dd %2
  at _mwwindowfbinfo.pixtype,	dd %3
  at _mwwindowfbinfo.bpp,	dd %4
  at _mwwindowfbinfo.bytespp,	dd %5
  at _mwwindowfbinfo.pitch,	dd %6
  at _mwwindowfbinfo.x,		dd %7
  at _mwwindowfbinfo.y,		dd %8
  at _mwwindowfbinfo.portrait_mode, dd %9
  at _mwwindowfbinfo.xres,	MWCOORD %10
  at _mwwindowfbinfo.yres,	MWCOORD %11
  at _mwwindowfbinfo.xvirtres,  MWCOORD %12
  at _mwwindowfbinfo.yvirtres,	MWCOORD %13
  iend
  %endmacro
  %define resMWWINDOWFBINFO	resb _mwwindowfbinfo_size
  %define MWWINDOWFBINFO_size	_mwwindowfbinfo_size
  %define PMWWINDOWFBINFO	dd
  %define resPMWWINDOWFBINFO	resd 1
  %assign PMWWINDOWFBINFO_size	4

; GetFontInfo structure
  struc _mwfontinfo
  .maxwidth	resd 1			; maximum width of any char
  .height	resd 1			; height of font in pixels
  .baseline	resd 1			; baseline (ascent) of font
  .firstchar	resd 1			; first character in font
  .lastchar	resd 1			; last character in font
  .fixed	resMWBOOL		; TRUE if font is fixed width
  .widths	resMWUCHAR * 256	; table of character widths
  endstruc
  %macro MWFONTINFO 0.nolist
  istruc _mwfontinfo
  iend
  %endmacro
  %macro MWFONTINFO 6.nolist
  istruc _mwfontinfo
  at _mwfontinfo.maxwidth,	dd %1
  at _mwfontinfo.height,	dd %2
  at _mwfontinfo.baseline,	dd %3
  at _mwfontinfo.firstchar,	dd %4
  at _mwfontinfo.lastchar,	dd %5
  at _mwfontinfo.fixed,		MWBOOL %6
  iend
  %endmacro
  %define resMWFONTINFO		resb _mwfontinfo_size
  %define MWFONTINFO_size	_mwfontinfo_size
  %define PMWFONTINFO		dd
  %define resPMWFONTINFO	resd 1
  %assign PMWFONTINFO_size	4

; GetFontList structure
  struc _mwfontlist
  .ttname	resd 1
  .mwname	resd 1
  endstruc
  %macro MWFONTLIST 0.nolist
  istruc _mwfontlist
  iend
  %endmacro
  %macro MWFONTLIST 2.nolist
  istruc _mwfontlist
  at _mwfontlist.ttname,	dd %1
  at _mwfontlist.mwname,	dd %1
  iend
  %endmacro
  %define resMWFONTLIST		resb _mwfontlist_size
  %define MWFONTLIST_size	_mwfontlist_size
  %define PMWFONTLIST		dd
  %define resPMWFONTLIST	resd 1
  %assign PMWFONTLIST_size	4

; logical font descriptor

; font classes - used internally
%assign MWLF_CLASS_BUILTIN	1	; Builtin fonts (bitmaps)
%assign MWLF_CLASS_FREETYPE	2	; FreeType fonts in TT format
%assign MWLF_CLASS_T1LIB	3	; T1LIB outlined Adobe Type 1 fonts
%assign MWLF_CLASS_ANY		4	; Any font

%assign MWLF_FACESIZE		64	; max facename size

; font type selection - lfOutPrecision
%assign MWLF_TYPE_DEFAULT	0	; any font
%assign MWLF_TYPE_SCALED	4	; outlined font (tt or adobe)
%assign MWLF_TYPE_RASTER	5	; raster only
%assign MWLF_TYPE_TRUETYPE 	7	; truetype only
%assign MWLF_TYPE_ADOBE		10	; adobe type 1 only

; font weights - lfWeight
%assign MWLF_WEIGHT_DEFAULT	0	; any weight
%assign MWLF_WEIGHT_THIN	100	; thin
%assign MWLF_WEIGHT_EXTRALIGHT	200
%assign MWLF_WEIGHT_LIGHT	300	; light
%assign MWLF_WEIGHT_NORMAL	400	; regular
%assign MWLF_WEIGHT_REGULAR	400
%assign MWLF_WEIGHT_MEDIUM	500	; medium
%assign MWLF_WEIGHT_DEMIBOLD	600
%assign MWLF_WEIGHT_BOLD	700	; bold
%assign MWLF_WEIGTH_EXTRABOLD	800
%assign MWLF_WEIGHT_BLACK	900	; black

; font charset - lfCharSet
%assign MWLF_CHARSET_ANSI	0	; win32 ansi
%assign MWLF_CHARSET_DEFAULT	1	; any charset
%assign MWLF_CHARSET_UNICODE	254	; unicode
%assign MWLF_CHARSET_OEM	255	; local hw

; font pitch - lfPitch
%assign MWLF_PITCH_DEFAULT		0	;* any pitch
%assign MWLF_PITCH_ULTRACONDENSED	10
%assign MWLF_PITCH_EXTRACONDENSED	20
%assign MWLF_PITCH_CONDENSED		30
%assign MWLF_PITCH_SEMICONDENSED	40
%assign MWLF_PITCH_NORMAL		50
%assign MWLF_PITCH_SEMIEXPANDED		60
%assign MWLF_PITCH_EXPANDED		70
%assign MWLF_PITCH_EXTRAEXPANDED	80
%assign MWLF_PITCH_ULTRAEXPANDED	90

; flags for the GdAddFont function
%assign MWLF_FLAGS_ALIAS	1

; MWLOGFONT structure
  struc _mwlogfont
  .lfHeight		resd 1		; desired height in pixels
  .lfWidth		resd 1		; desired width in pixels or 0
  .lfEscapement		resd 1		; rotation in tenths of degree
  .lfOrientation	resd 1		; not used
  .lfWeight		resd 1		; font weight
  .lfItalic		resMWUCHAR	; =1 for italic
  .lfUnderline		resMWUCHAR	; =1 for underline
  .lfStrikeOut		resMWUCHAR	; not used
  .lfCharSet		resMWUCHAR	; font character set
  .lfOutPrecision	resMWUCHAR	; font type selection
  .lfClipPrecision	resMWUCHAR	; not used
  .lfQuality		resMWUCHAR	; not used

  ; the following differs from the window font model
  .lfRoman		resMWUCHAR	; =1 for Roman letters (upright)
  .lfSerif		resMWUCHAR	; =1 for Serifed font
  .lfSansSerif		resMWUCHAR	; =1 for Sans-serif font
  .lfModern		resMWUCHAR	; =1 for Modern font
  .lfMonospace		resMWUCHAR	; =1 for Monospaced font
  .lfProportional	resMWUCHAR	; =1 for Proportional font
  .lfOblique		resMWUCHAR	; =1 for Oblique (kind of Italic)
  .lfSmallCaps		resMWUCHAR	; =1 for small caps
  .lfPitch		resMWUCHAR	; font pitch (width)
  .lfFaceName		resb MWLF_FACESIZE; font name, may be aliased
  endstruc
  %macro MWLOGFONT 0.nolist
  istruc _mwlogfont
  iend
  %endmacro
  %define resMWLOGFONT	resb _mwlogfont_size
  %define MWLOGFONT_size _mwlogfont_size
  %define PMWLOGFONT	dd
  %define resPMWLOGFONT resd 1
  %assign PMWLOGFONT_size 4

;
; Macros to initialize the MWLOGFONT structure to the most common defaults
; required by application programs and the nano-X server program.
;


;; MWLF_Clear
  %macro MWLF_Clear 2.nolist	; param:
  				; o Pointer to MWLOGFONT structure
  				; o Register that will get destroyed, scratch
  xor %2, %2
  mov [%1 + _mwlogfont.lfHeight], %2
  mov [%1 + _mwlogfont.lfWidth], %2
  mov [%1 + _mwlogfont.lfEscapement], %2
  mov [%1 + _mwlogfont.lfOrientation], %2
  mov [%1 + _mwlogfont.lfWeight], dword MWLF_WEIGHT_REGULAR
  mov [%1 + _mwlogfont.lfItalic], %2	; lfItalic,
  					; lfOblique,
					; lfRoman,
					; lfSerif
  mov [%1 + _mwlogfont.lfSansSerif], %2	; lfSansSerif,
  					; lfModern,
					; lfMonospace,
					; lfProportional
  mov [%1 + _mwlogfont.lfSmallCaps], %2	; lfSmallCaps
  					; lfPitch
					; lfFaceName[0], lfFaceName[1]
  %endmacro


;; MWLF_SetBold
  %macro MWLF_SetBold 1.nolist	; param:
				; o Pointer to MWLOGFONT structure
  mov [%1 + _mwlogfont.lfWeight], dword MWLF_WEIGHT_BOLD
  %endmacro


;; MMLF_SetRegular
  %macro MWLF_SetRegular 1.nolist; param:
  				; o Pointer to MWLOGFONT structure
  mov [%1 + _mwlogfont.lfWeight], dword MWLF_WEIGHT_REGULAR
  %endmacro


;; MWLF_SetItalics
  %macro MWLF_SetItalics 1.nolist; param:
  				; o Pointer to MWLOGFONT structure
  and [%1 + _mwlogfont.lfItalic], dword 0xFF000000
  mov [%1 + _mwlogfont.lfItalic], byte 1
  %endmacro

;; MWLF_SetRoman
  %macro MWLF_SetRoman 1.nolist	; param:
  				; o Pointer to MWLOGFONT structure
  and [%1 + _mwlogfont.lfItalic], dword 0xFF000000
  mov [%1 + _mwlogfont.lfRoman], byte 1
  %endmacro



; Rectangle and point structures.
; These structures are "inherited" in wingdi.h for
; the Win32 RECT and POINT structures, so they must match
; Microsoft's definition.

; MWPOINT used in GdPoly, GdFillPoly
  struc _mwpoint
  .x	resMWCOORD
  .y	resMWCOORD
  endstruc
  %macro MWPOINT 0.nolist
  istruc _mwpoint
  iend
  %endmacro
  %macro MWPOINT 2.nolist
  istruc _mwpoint
  at _mwpoint.x,	MWCOORD %1
  at _mwpoint.y,	MWCOORD %2
  iend
  %endmacro
  %define resMWPOINT	resb _mwpoint_size
  %define MWPOINT_size	_mwpoint_size

; MWRECT used in region routines
  struc _mwrect
  .left		resMWCOORD
  .top		resMWCOORD
  .right	resMWCOORD
  .bottom	resMWCOORD
  endstruc
  %macro MWRECT 0.nolist
  istruc _mwrect
  iend
  %endmacro
  %macro MWRECT 4.nolist
  istruc _mwrect
  at _mwrect.left,	MWCOORD %1
  at _mwrect.top,	MWCOORD %2
  at _mwrect.right,	MWCOORD %3
  at _mwrect.bottom,	MWCOORD %4
  iend
  %endmacro
  %define resMWRECT	resb _mwrect_size
  %define MWRECT_size	_mwrect_size

; dynamically allocated multi-rectangle clipping region
  struc _mwclipregion
  .size		resd 1		; malloc'd # of rectangles
  .numRects	resd 1		; # rectangles in use
  .type		resd 1		; region type
  .rects	resd 1		; rectangle array pointer
  .extents	resMWRECT	; bounding box of region
  endstruc
  %macro MWCLIPREGION 0.nolist
  istruc _mwclipregion
  iend
  %endmacro
  %macro MWCLIPREGION 4.nolist
  istruc _mwclipregion
  at _mwclipregion.size,	dd %1
  at _mwclipregion.numRects,	dd %2
  at _mwclipregion.type,	dd %3
  at _mwclipregion.rects,	dd %4
  iend
  %endmacro
  %define resMWCLIPREGION	resb _mwclipregion_size
  %define MWCLIPREGION_size	_mwclipregion_size

; region types
%assign MWREGION_ERROR		0
%assign MWREGION_NULL		1
%assign MWREGION_SIMPLE		2
%assign MWREGION_COMPLEX	3

; GdRectInRegion return codes
%assign MWRECT_OUT		0	; rectangle not in region
%assign MWRECT_ALLIN		1	; rectangle all in region
%assign MWRECT_PARTIN		2	; rectangle partly in region

; GdAllocPolyRegion types
%assign MWPOLY_EVENODD		1
%assign MWPOLY_WINDING		2

; In-core color palette structure
  struc _mwpalentry
  .r	resMWUCHAR
  .g	resMWUCHAR
  .b	resMWUCHAR
  endstruc
  %macro MWPALENTRY 0.nolist
  istruc _mwpalentry
  iend
  %endmacro
  %macro MWPALENTRY 3.nolist
  istruc _mwpalentry
  at _mwpalentry.r,	MWUCHAR %1
  at _mwpalentry.g,	MWUCHAR %2
  at _mwpalentry.b,	MWUCHAR %3
  iend
  %endmacro
  %define resMWPALENTRY		resb _mwpalentry_size
  %define MWPALENTRY_size	_mwpalentry_size

; In-core mono and color image structure
%assign MWIMAGE_UPSIDEDOWN	01	; compression flag: upside down image
%assign MWIMAGE_BGR		00	; compression flag: BGR byte order
%assign MWIMAGE_RGB		02	; compression flag: RGB not BGR bytes

  struc _mwimagehdr
  .width		resd 1		; image width in pixels
  .height		resd 1		; image height in pixels
  .planes		resd 1		; # image planes
  .bpp			resd 1		; bits per pixel (1, 4 or 8)
  .pitch		resd 1		; bytes per line
  .bytesperpixel	resd 1		; bytes per pixel
  .compression		resd 1		; compression algorithm
  .palsize		resd 1		; palette size
  .transcolor		resd 1		; transparent color or -1 if none
  .palette		resd 1		; pointer to palette (MWPALENTRY *)
  .imagebits		resd 1		; image bits (dword right aligned)
  endstruc
  %macro MWIMAGEHDR 0.nolist
  istruc _mwimagehdr
  iend
  %endmacro
  %define resMWIMAGEHDR		resb _mwimagehdr
  %define MWIMAGEHDR_size	_mwimagehdr
  %define PMWIMAGEHDR		dd
  %define resPMWIMAGEHDR	resd 1
  %assign PMWIMAGEHDR_size	4


; image information structure - returned by GdGetImageInfo
  struc _mwimageinfo
  .id			resd 1		; image id
  .width		resd 1		; image width in pixels
  .height		resd 1		; image height in pixels
  .planes		resd 1		; # image planes
  .bpp			resd 1		; bits per pixel (1, 4 or 8)
  .pitch		resd 1		; bytes per line
  .bytesperpixel	resd 1		; bytes per pixel
  .compression		resd 1		; compression algorithm
  .palsize		resd 1		; palette size
  .palette		resMWPALENTRY * 256	; palette
  endstruc
  %macro MWIMAGEINFO 0.nolist
  istruc _mwimageinfo
  iend
  %endmacro
  %define resMWIMAGEINFO	resb _mwimageinfo_size
  %define MWIMAGEINFO_size	_mwimageinfo_size
  %define PMWIMAGEINFO		dd
  %define resPMWIMAGEINFO	resd 1
  %assign PMWIMAGEINFO_size	4


%assign MWMAX_CURSOR_SIZE	16	; maximum cursor x and y size

; In-core software cursor structure
  struc _mwcursor
  .width		resd 1		; cursor width in pixels
  .height		resd 1		; cursor height in pixels
  .hotx			resMWCOORD	; relative x pos of hot spot
  .hoty			resMWCOORD	; relative y pos of hot spot
  .fgcolor		resMWCOLORVAL	; foreground color
  .bgcolor		resMWCOLORVAL	; background color
  .image		resMWIMAGEBITS * MWMAX_CURSOR_SIZE; cursor image bits
  .mask			resMWIMAGEBITS * MWMAX_CURSOR_SIZE; cursor mask bits
  endstruc
  %macro MWCURSOR 0.nolist
  istruc _mwcursor
  iend
  %endmacro
  %define resMWCURSOR		resb _mwcursor_size
  %define MWCUSOR_size		_mwcursor_size
  %define PMWCUROSR		dd
  %define resPMWCURSOR		resd 1
  %assign PMWCURSOR_size	4

  %define PMWFONT		dd
  %define resPMWFONT		resd 1
  %assign PMWFONT_size		4

; outline and filled arc and pie types
%assign MWARC		0x0001  ; arc
%assign MWOUTLINE	0x0002
%assign MWARCOUTLINE	0x0003	; arc + outline
%assign MWPIE		0x0004	; pie (filled)
%assign MWELLIPSE	0x0008	; ellipse outline
%assign MWELLIPSEFILL	0x0010	; ellipse filled

%ifdef MWINCLUDECOLORS
;
; Common colors - note any color including these may not be
; available on palettized systems, and the system will
; then use the nearest color already in the system palette,
; or allocate a new color entry.
; These colors are the first 16 entries in the std palette,
; and are written to the system palette if writable.
;
%define BLACK		MWRGB( 0  , 0  , 0   )
%define BLUE		MWRGB( 0  , 0  , 128 )
%define GREEN		MWRGB( 0  , 128, 0   )
%define CYAN		MWRGB( 0  , 128, 128 )
%define RED		MWRGB( 128, 0  , 0   )
%define MAGENTA		MWRGB( 128, 0  , 128 )
%define BROWN		MWRGB( 128, 64 , 0   )
%define LTGRAY		MWRGB( 192, 192, 192 )
%define GRAY		MWRGB( 128, 128, 128 )
%define LTBLUE		MWRGB( 0  , 0  , 255 )
%define LTGREEN		MWRGB( 0  , 255, 0   )
%define LTCYAN		MWRGB( 0  , 255, 255 )
%define LTRED		MWRGB( 255, 0  , 0   )
%define LTMAGENTA	MWRGB( 255, 0  , 255 )
%define YELLOW		MWRGB( 255, 255, 0   )
%define WHITE		MWRGB( 255, 255, 255 )

%define DKGRAY		MWRGB( 32,  32,  32)
%endif ; MWINCLUDECOLORS


; Keyboard values
%define MWKEY		dw
%define resMWKEY	resw 1
%assign MWKEY_size	2

%assign MWKEY_UNKNOWN		0
; Following special control keysyms are mapped to ASCII
%assign MWKEY_BACKSPACE		8
%assign MWKEY_TAB		9
%assign MWKEY_ENTER		13
%assign MWKEY_ESCAPE		27
; Keysyms from 32-126 are mapped to ASCII

%assign MWKEY_NONASCII_MASK	0xFF00
; Following keysyms are mapped to private use portion of Unicode-16
; arrows + home/end pad
%assign MWKEY_FIRST		0xF800
%assign MWKEY_LEFT		0xF800
%assign MWKEY_RIGHT		0xF801
%assign MWKEY_UP		0xF802
%assign MWKEY_DOWN		0xF803
%assign MWKEY_INSERT		0xF804
%assign MWKEY_DELETE		0xF805
%assign MWKEY_HOME		0xF806
%assign MWKEY_END		0xF807
%assign MWKEY_PAGEUP		0xF808
%assign MWKEY_PAGEDOWN		0xF809

; Numeric keypad
%assign MWKEY_KP0		0xF80A
%assign MWKEY_KP1		0xF80B
%assign MWKEY_KP2		0xF80C
%assign MWKEY_KP3		0xF80D
%assign MWKEY_KP4		0xF80E
%assign MWKEY_KP5		0xF80F
%assign MWKEY_KP6		0xF810
%assign MWKEY_KP7		0xF811
%assign MWKEY_KP8		0xF812
%assign MWKEY_KP9		0xF813
%assign MWKEY_KP_PERIOD		0xF814
%assign MWKEY_KP_DIVIDE		0xF815
%assign MWKEY_KP_MULTIPLY	0xF816
%assign MWKEY_KP_MINUS		0xF817
%assign MWKEY_KP_PLUS		0xF818
%assign MWKEY_KP_ENTER		0xF819
%assign MWKEY_KP_EQUALS		0xF81A

; Function keys
%assign MWKEY_F1		0xF81B
%assign MWKEY_F2		0xF81C
%assign MWKEY_F3		0xF81D
%assign MWKEY_F4		0xF81E
%assign MWKEY_F5		0xF81F
%assign MWKEY_F6		0xF820
%assign MWKEY_F7		0xF821
%assign MWKEY_F8		0xF822
%assign MWKEY_F9		0xF823
%assign MWKEY_F10		0xF824
%assign MWKEY_F11		0xF825
%assign MWKEY_F12		0xF827

; Key state modifier keys
%assign MWKEY_NUMLOCK		0xF828
%assign MWKEY_CAPSLOCK		0xF829
%assign MWKEY_SCROLLOCK		0xF82A
%assign MWKEY_LSHIFT		0xF82B
%assign MWKEY_RSHIFT		0xF82C
%assign MWKEY_LCTRL		0xF82D
%assign MWKEY_RCTRL		0xF82E
%assign MWKEY_LALT		0xF82F
%assign MWKEY_RALT		0xF830
%assign MWKEY_LMETA		0xF831
%assign MWKEY_RMETA		0xF832
%assign MWKEY_ALTGR		0xF833

; Misc function keys
%assign MWKEY_PRINT		0xF834
%assign MWKEY_SYSREQ		0xF835
%assign MWKEY_PAUSE		0xF836
%assign MWKEY_BREAK		0xF837
%assign MWKEY_QUIT		0xF838  ; virtual key
%assign MWKEY_MENU		0xF839  ; virtual key
%assign MWKEY_REDRAW		0xF83A  ; virtual key

; Handheld function keys
%assign MWKEY_RECORD		0xF840
%assign MWKEY_PLAY		0xF841
%assign MWKEY_CONTRAST		0xF842
%assign MWKEY_BRIGHTNESS	0xF843
%assign MWKEY_SELECTUP		0xF844
%assign MWKEY_SELECTDOWN	0xF845
%assign MWKEY_ACCEPT		0xF846
%assign MWKEY_CANCEL		0xF847
%assign MWKEY_APP1		0xF848
%assign MWKEY_APP2		0xF849
%assign MWKEY_LAST		0xF849

; Keyboard state modifiers
%assign MWKMOD_NONE		0x0000
%assign MWKMOD_LSHIFT		0x0001
%assign MWKMOD_RSHIFT		0x0002
%assign MWKMOD_LCTRL		0x0040
%assign MWKMOD_RCTRL		0x0080
%assign MWKMOD_LALT		0x0100
%assign MWKMOD_RALT		0x0200
%assign MWKMOD_LMETA		0x0400	; Windows key
%assign MWKMOD_RMETA		0x0800	; Windows key
%assign MWKMOD_NUM		0x1000
%assign MWKMOD_CAPS		0x2000
%assign MWKMOD_ALTGR		0x4000
%assign MWKMOD_SCR		0x8000

%assign MWKMOD_CTRL		(MWKMOD_LCTRL|MWKMOD_RCTRL)
%assign MWKMOD_SHIFT		(MWKMOD_LSHIFT|MWKMOD_RSHIFT)
%assign MWKMOD_ALT		(MWKMOD_LALT|MWKMOD_RALT)
%assign MWKMOD_META		(MWKMOD_LMETA|MWKMOD_RMETA)

%define MWKINFO_LED_MASK	(1 << 0)
%define MWKINFO_LED_MODE_MASK	(1 << 1)

; Keyboard info values 
%define MWKINFO_LED_CAP		(1 << 0)
%define MWKINFO_LED_NUM		(1 << 1)
%define MWKINFO_LED_SCR		(1 << 2)
%define MWKINFO_LED_MODE_ON	(1 << 3)
%define MWKINFO_LED_MODE_OFF	(1 << 4)


  struc _mwkbinfo
  .led		resd 1
  .led_mode	resd 1
  endstruc
  %macro MWKBINFO 0.nolist
  istruc _mwkbinfo
  iend
  %endmacro
  %macro MWKBINFO 2.nolist
  istruc _mwkbinfo
  at _mwkbinfo.led, 		dd %1
  at _mwkbinfo.led_mode,	dd %2
  iend
  %endmacro
  %define resMWKBINFO		resb _mwkbinfo_size
  %define MWKBINFO_size		_mwkbinfo_size
  %define PMWKBINFO		dd
  %define resPMWKBINFO		resd 1
  %assign PMWKBINFO_size	4

%endif ; __MWTYPES_INC__
