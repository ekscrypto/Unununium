%define	_NANO_X_H
;/* Copyright (c) 1999, 2000 Greg Haerr <greg@censoft.com>
; * Copyright (c) 2000 Alex Holden <alex@linuxhacker.org>
; * Copyright (c) 1991 David I. Bell
; * Permission is granted to use, distribute, or modify this source,
; * provided that this copyright notice remains intact.
; *
; * Nano-X public definition header file:  user applications should
; * include only this header file.
; */

%include "mwtypes.h"			;/* exported engine MW* types*/

;/*
; * The following typedefs are inherited from the Microwindows
; * engine layer.
; */

;every seconde %define here is an version to use it as a type for inside a structure

%define GR_COORD	dd	;	/* coordinate value */
%define resGR_COORD	resd 1;	
%define GR_SIZE		dd	;	/* size value */
%define resGR_SIZE	resd 1;
%define GR_COLOR	dd	;	/* full color value */
%define resGR_COLOR	resd 1
%define GR_PIXELVAL	dd	;	/* hw pixel value*/
%define resGR_PIXELVAL  resd 1
%define GR_BITMAP	dw	;	/* bitmap unit */
%define resGR_BITMAP	resw 1
%assign GR_BITMAP_size  2
%define GR_CHAR		dd	;	/* filename, window title */
%define resGR_CHAR	resd 1	
%define GR_KEY		dd	;	/* keystroke value*/
%define resdGR_KEY	resd 1
%define GR_SCANCODE	dd	;	/* oem keystroke scancode value*/
%define resdGR_SCANCODE resd 1
%define GR_KEYMOD	dd	;	/* keystroke modifiers*/
%define resGR_KEYMOD	resd 1
%define GR_SCREEN_INFO	dd	;	/* screen information*/
%define resdGR_SCREEN_INFO  resd 1
%define GR_WINDOW_FB_INFO  dd	; /* direct client-mapped window info*/
%define resdGR_WINDOW_FB_INFO  resd 1
%define GR_FONT_INFO	dd	;	/* font information*/
%define resdGR_FONT_INFO  resd  1
%define GR_IMAGE_INFO	dd	;	/* image information*/
%define resdGR_IMAGE_INFO  resd 1
%define GR_IMAGE_HDR	dd	;	/* multicolor image representation*/
%define resdGR_IMAGE_HDR   resd 1
%define GR_LOGFONT	dd	;	/* logical font descriptor*/
%define resdGR_LOGFONT  resd 1
%define GR_PALENTRY	dd	;	/* palette entry*/
%define resdGR_PALENTRY  resd 1
%define GR_POINT	dd	;	/* definition of a point*/
%define resdGR_POINT	resd 1
%define GR_TIMEOUT	dd	;	/* timeout value */
%define resdGR_TIMEOUT 	resd 1
%define GR_FONTLIST	dd	;	/* list of fonts */
%define resdGR_FONTLIST  resd 1
%define GR_KBINFO	dd	;	/* keyboard information  */
%define resdGR_KBINFO	resd 1

;/* Basic typedefs. */
%define GR_COUNT	dd	;	/* number of items */
%define resGR_COUNT	resd 1
%define GR_CHAR_WIDTH	db	;	/* width of character */
%define resdGR_CHAR_WIDTH resb 1
%define GR_ID		dd	;	/* resource ids */
%define resGR_ID	resd 1
%define GR_DRAW_ID	dd	;	/* drawable id */
%define resdGR_DRAW_ID	resd 1
%define GR_WINDOW_ID	dd	;	/* window or pixmap id */
%define resGR_WINDOW_ID resd 1
%define GR_GC_ID	dd	;	/* graphics context id */
%define resGR_GC_ID	resd 1
%define GR_REGION_ID	dd	;	/* region id */
%define resGR_REGION_ID resd 1
%define GR_FONT_ID	dd	;	/* font id */
%define resGR_FONT_ID   resd 1
%define GR_IMAGE_ID	dd	;	/* image id */
%define resdGR_IMAGE_ID resd 1
%define GR_TIMER_ID	dd	;	/* timer id */
%define resdGR_TIMER_ID resd 1
%define GR_CURSOR_ID	dd	;	/* cursor id */
%define resGR_CURSOR_ID resd 1
%define GR_BOOL		db	;	/* boolean value */
%define resGR_BOOL	resb 1
%define GR_ERROR	dd	;	/* error types*/
%define resGR_ERROR	resd 1
%define GR_EVENT_TYPE	dd	;	/* event types */
%define resGR_EVENT_TYPE  resd 1
%define GR_UPDATE_TYPE	dd	;	/* window update types */
%define resdGR_UPDATE_TYPE resd 1
%define GR_EVENT_MASK	dd	;	/* event masks */
%define resGR_EVENT_MASK  resd 1
%define GR_FUNC_NAME times 25 db 0;
%define resGR_FUNC_NAME resb 25
%define GR_FUNC_NAME_size 25	;	/* function name */
%define GR_WM_PROPS	dd	;	/* window property flags */
%define GR_WM_PROPS	resd 1
%define GR_SERIALNO	dd	;	/* Selection request ID number */
%define resdGR_SERIALNO resd 1
%define GR_MIMETYPE	dw	;	/* Index into mime type list */
%define resdGR_MIMETYPE resw 1
%define GR_LENGTH	dd	;	/* Length of a block of data */
%define resdGR_LENGTH	resd 1
%define GR_BUTTON	dd	;	/* mouse button value*/
%define resdGR_GR_BUTTON resd 1

;/* Rick's custom Defines */   (flashy C comments included. :P )
%define resGR_EVENT  resb 1 * _GR_EVENT_size


;/* Nano-X rectangle, different from MWRECT*/

	struc _GR_RECT
.x:	resGR_COORD	
.y:	resGR_COORD	
.width:	resGR_SIZE	
.height: resGR_SIZE	
	endstruc

%macro GR_RECT 0.nolist
    istruc _GR_RECT
    iend
%endmacro
%macro GR_RECT 4.nolist
    istruc _GR_RECT
    at _GR_RECT.x,	GR_COORD %1
    at _GR_RECT.y,	GR_COORD %2
    at _GR_RECT.width,   GR_SIZE  %3
    at _GR_RECT.height,  GR_SIZE  %4
    iend
%endmacro

;typedef struct {
;	GR_COORD x;
;	GR_COORD y;
;	GR_SIZE  width;
;	GR_SIZE  height;
;} GR_RECT;

;/* The root window id. */
%define	GR_ROOT_WINDOW_ID	 1

/* GR_COLOR color constructor*/
%define GR_RGB(r,g,b)		MWRGB(r,g,b)

/* Drawing modes for GrSetGCMode*/
%define	GR_MODE_COPY		MWMODE_COPY		;/* src*/
;%define	GR_MODE_SET		MWMODE_COPY	;/* obsolete, use GR_MODE_COPY*/
%define	GR_MODE_XOR		MWMODE_XOR		;/* src ^ dst*/
%define	GR_MODE_OR		MWMODE_OR		;/* src | dst*/
%define	GR_MODE_AND		MWMODE_AND		;/* src & dst*/
%define	GR_MODE_CLEAR 		MWMODE_CLEAR		;/* 0*/
%define	GR_MODE_SETTO1		MWMODE_SETTO1		;/* 11111111*/ /* will be GR_MODE_SET*/
%define	GR_MODE_EQUIV		MWMODE_EQUIV		;/* ~(src ^ dst)*/
%define	GR_MODE_NOR		MWMODE_NOR		;/* ~(src | dst)*/
%define	GR_MODE_NAND		MWMODE_NAND		;/* ~(src & dst)*/
%define	GR_MODE_INVERT		MWMODE_INVERT		;/* ~dst*/
%define	GR_MODE_COPYINVERTED	MWMODE_COPYINVERTED	;/* ~src*/
%define	GR_MODE_ORINVERTED	MWMODE_ORINVERTED	;/* ~src | dst*/
%define	GR_MODE_ANDINVERTED	MWMODE_ANDINVERTED	;/* ~src & dst*/
%define GR_MODE_ORREVERSE	MWMODE_ORREVERSE	;/* src | ~dst*/
%define	GR_MODE_ANDREVERSE	MWMODE_ANDREVERSE	;/* src & ~dst*/
%define	GR_MODE_NOOP		MWMODE_NOOP		;/* dst*/

%define GR_MODE_DRAWMASK	0x00FF
%define GR_MODE_EXCLUDECHILDREN	0x0100		;/* exclude children on clip*/

;/* builtin font std names*/
%define GR_FONT_SYSTEM_VAR	MWFONT_SYSTEM_VAR
%define GR_FONT_GUI_VAR		MWFONT_GUI_VAR
%define GR_FONT_OEM_FIXED	MWFONT_OEM_FIXED
%define GR_FONT_SYSTEM_FIXED	MWFONT_SYSTEM_FIXED

;/* GrText/GrGetTextSize encoding flags*/
%define GR_TFASCII		MWTF_ASCII
%define GR_TFUTF8		MWTF_UTF8
%define GR_TFUC16		MWTF_UC16
%define GR_TFUC32		MWTF_UC32
%define GR_TFPACKMASK		MWTF_PACKMASK

;/* GrText alignment flags*/
%define GR_TFTOP		MWTF_TOP
%define GR_TFBASELINE		MWTF_BASELINE
%define GR_TFBOTTOM		MWTF_BOTTOM

;/* GrSetFontAttr flags*/
%define GR_TFKERNING		MWTF_KERNING
%define GR_TFANTIALIAS		MWTF_ANTIALIAS
%define GR_TFUNDERLINE		MWTF_UNDERLINE

;/* GrArc, GrArcAngle types*/
%define GR_ARC		MWARC		;/* arc only*/
%define GR_ARCOUTLINE	MWARCOUTLINE	;/* arc + outline*/
%define GR_PIE		MWPIE		;/* pie (filled)*/

;/* Booleans */
%define	GR_FALSE		0
%define	GR_TRUE			1

;/* Loadable Image support definition */
%define GR_IMAGE_MAX_SIZE	(-1)

;/* Button flags */
%define	GR_BUTTON_R		MWBUTTON_R 	;/* right button*/
%define	GR_BUTTON_M		MWBUTTON_M	;/* middle button*/
%define	GR_BUTTON_L		MWBUTTON_L	;/* left button */
%define	GR_BUTTON_ANY		(MWBUTTON_R|MWBUTTON_M|MWBUTTON_L) ;/* any*/

;/* GrSetBackgroundPixmap flags */
%define GR_BACKGROUND_TILE	0	;/* Tile across the window */
%define GR_BACKGROUND_CENTER	1	;/* Draw in center of window */
%define GR_BACKGROUND_TOPLEFT	2	;/* Draw at top left of window */
%define GR_BACKGROUND_STRETCH	4	;/* Stretch image to fit window*/
%define GR_BACKGROUND_TRANS	8	;/* Don't fill in gaps */

;/* GrNewPixmapFromData flags*/
%define GR_BMDATA_BYTEREVERSE	01	;/* byte-reverse bitmap data*/
%define GR_BMDATA_BYTESWAP	02	;/* byte-swap bitmap data*/

%ifdef 0 ;/* don't define unimp'd flags*/
;/* Window property flags */
%define GR_WM_PROP_NORESIZE	0x04	;/* don't let user resize window */
%define GR_WM_PROP_NOICONISE	0x08	;/* don't let user iconise window */
%define GR_WM_PROP_NOWINMENU	0x10	;/* don't display a window menu button */
%define GR_WM_PROP_NOROLLUP	0x20	;/* don't let user roll window up */
%define GR_WM_PROP_ONTOP	0x200	;/* try to keep window always on top */
%define GR_WM_PROP_STICKY	0x400	;/* keep window after desktop change */
%define GR_WM_PROP_DND		0x2000	;/* accept drag and drop icons */
%endif

;/* Window properties*/
%define GR_WM_PROPS_NOBACKGROUND 0x00000001 ;/* Don't draw window background*/
%define GR_WM_PROPS_NOFOCUS	 0x00000002 ;/* Don't set focus to this window*/
%define GR_WM_PROPS_NOMOVE	 0x00000004 ;/* Don't let user move window*/
%define GR_WM_PROPS_NORAISE	 0x00000008 ;/* Don't let user raise window*/
%define GR_WM_PROPS_NODECORATE	 0x00000010 ;/* Don't redecorate window*/
%define GR_WM_PROPS_NOAUTOMOVE	 0x00000020 ;/* Don't move window on 1st map*/
%define GR_WM_PROPS_NOAUTORESIZE 0x00000040 ;/* Don't resize window on 1st map*/

;/* default decoration style*/
%define GR_WM_PROPS_APPWINDOW	0x00000000 ;/* Leave appearance to WM*/
%define GR_WM_PROPS_APPMASK	0xF0000000 ;/* Appearance mask*/
%define GR_WM_PROPS_BORDER	0x80000000 ;/* Single line border*/
%define GR_WM_PROPS_APPFRAME	0x40000000 ;/* 3D app frame (overrides border)*/
%define GR_WM_PROPS_CAPTION	0x20000000 ;/* Title bar*/
%define GR_WM_PROPS_CLOSEBOX	0x10000000 ;/* Close box*/
%define GR_WM_PROPS_MAXIMIZE	0x08000000 ;/* Application is maximized*/

;/* Flags for indicating valid bits in GrSetWMProperties call*/
%define GR_WM_FLAGS_PROPS	0x0001	;/* Properties*/
%define GR_WM_FLAGS_TITLE	0x0002	;/* Title*/
%define GR_WM_FLAGS_BACKGROUND	0x0004	;/* Background color*/
%define GR_WM_FLAGS_BORDERSIZE	0x0008	;/* Border size*/
%define GR_WM_FLAGS_BORDERCOLOR	0x0010	;/* Border color*/

;/* Window manager properties used by the Gr[GS]etWMProperties calls. */
;/* NOTE: this struct must be hand-packed to a DWORD boundary for nxproto.h*/
struc _GR_WM_PROPERTIES
.flags:		resGR_WM_PROPS
.props: 	resGR_WM_PROPS
.title:		resGR_CHAR
.backcolor:	resGR_COLOR
.bordersize:	resGR_SIZE
.bordercolor:	resGR_COLOR
endstruc

%macro GR_WM_PROPERTIES 0.nolist
   istruc _GR_WM_PROPERTIES
   iend
%endmacro
%macro GR_WM_PROPERTIES 6.nolist
   istruc _GR_WM_PROPERTIES
   at _GR_WM_PROPERTIES.flags, 	GR_WM_PROPS  %1
   at _GR_WM_PROPERTIES.props, 	GR_WM_PROPS  %2
   at _GR_WM_CHAR.title, 	GR_WM_CHAR   %3
   at _GR_WM_COLOR.backcolor, 	GR_WM_COLOR  %4
   at _GR_WM_SIZE.bordersize, 	GR_WM_SIZE   %5
   at _GR_WM_COLOR.bordercolor, GR_WM_COLOR  %6
   iend
%endmacro

;typedef struct {
;  GR_WM_PROPS flags;		/* Which properties valid in struct for set*/
;  GR_WM_PROPS props;		/* Window property bits*/
;  GR_CHAR *title;		/* Window title*/
;  GR_COLOR background;		/* Window background color*/
;  GR_SIZE bordersize;		/* Window border size*/
;  GR_COLOR bordercolor;		/* Window border color*/
;} GR_WM_PROPERTIES;

;/* Window properties returned by the GrGetWindowInfo call. */
struc _GR_WINDOW_INFO
.wid:		resGR_WINDOW_ID
.parent:	resGR_WINDOW_ID
.child:		resGR_WINDOW_ID
.sibling:	resGR_WINDOW_ID
.inputonly:	resGR_BOOL
.mapped:	resGR_BOOL
.unmapcount:	resGR_COUNT
.x:		resGR_COORD
.y:		resGR_COORD
.width:		resGR_SIZE
.height:	resGR_SIZE
.bordersize:	resGR_SIZE
.background:	resGR_COLOR
.eventmask:	resGR_EVENT_MASK
.props:		resGR_WM_PROPS
.cursor:	resGR_CURSOR_ID
.processid:	resd 	1
endstruc

%macro GR_WINDOW_INFO 0.nolist
   istruc _GR_WINDOW_INFO
   iend
%endmacro
%macro GR_WINDOW_INFO 17.nolist
   istruc _GR_WINDOW_INFO
   at _GR_WINDOW_INFO.wid,		GR_WINDOW_ID	%1
   at _GR_WINDOW_INFO.parent,		GR_WINDOW_ID	%2
   at _GR_WINDOW_INFO.child,		GR_WINDOW_ID	%3
   at _GR_WINDOW_INFO.sibling,		GR_WINDOW_ID	%4
   at _GR_WINDOW_INFO.inputonly,	GR_BOOL		%5
   at _GR_WINDOW_INFO.mapped,		GR_BOOL		%6
   at _GR_WINDOW_INFO.unmapcount,	GR_COUNT	%7
   at _GR_WINDOW_INFO.x,		GR_COORD	%8
   at _GR_WINDOW_INFO.y,		GR_COORD	%9
   at _GR_WINDOW_INFO.width,		GR_SIZE		%10
   at _GR_WINDOW_INFO.height,		GR_SIZE		%11
   at _GR_WINDOW_INFO.bordersize,	GR_SIZE		%12
   at _GR_WINDOW_INFO.background,	GR_COLOR	%13
   at _GR_WINDOW_INFO.eventmask,	GR_EVENT_MASK	%14
   at _GR_WINDOW_INFO.props,		GR_WM_PROPS	%15
   at _GR_WINDOW_INFO.cursor,		GR_CURSOR_ID	%16
   at _GR_WINDOW_INFO.processid,	dd 		%17
   iend
%endmacro

;typedef struct {
;  GR_WINDOW_ID wid;		/* window id (or 0 if no such window) */
;  GR_WINDOW_ID parent;		/* parent window id */
;  GR_WINDOW_ID child;		/* first child window id (or 0) */
;  GR_WINDOW_ID sibling;		/* next sibling window id (or 0) */
;  GR_BOOL inputonly;		/* TRUE if window is input only */
;  GR_BOOL mapped;		/* TRUE if window is mapped */
;  GR_COUNT unmapcount;		/* reasons why window is unmapped */
;  GR_COORD x;			/* absolute x position of window */
;  GR_COORD y;			/* absolute y position of window */
;  GR_SIZE width;		/* width of window */
;  GR_SIZE height;		/* height of window */
;  GR_SIZE bordersize;		/* size of border */
;  GR_COLOR bordercolor;		/* color of border */
;  GR_COLOR background;		/* background color */
;  GR_EVENT_MASK eventmask;	/* current event mask for this client */
;  GR_WM_PROPS props;		/* window properties */
;  GR_CURSOR_ID cursor;		/* cursor id*/
;  unsigned long processid;	/* process id of owner*/
;} GR_WINDOW_INFO;

;/* Graphics context properties returned by the GrGetGCInfo call. */

struc _GR_GC_INFO
.gcid: 		resGR_GC_ID
.mode:		resd 1
.region:	resGR_REGION_ID
.xoff:		resd 1
.yoff:		resd 1
.font:		resGR_FONT_ID
.foreground:	resGR_COLOR
.background:	resGR_COLOR
.usebackground:	resGR_BOOL
endstruc

%macro GR_GC_INFO 0.nolist
   istruc _GR_GC_INFO
   iend
%endmacro
%macro GR_GC_INFO 9.nolist
   istruc _GR_GC_INFO
   at _GR_GC_INFO.gcid, 		GR_GC_ID	%1
   at _GR_GC_INFO.mode,			resd 1		%2
   at _GR_GC_INFO.region,		GR_REGION_ID	%3
   at _GR_GC_INFO.xoff,			resd 1		%4
   at _GR_GC_INFO.yoff,			resd 1		%5
   at _GR_GC_INFO.font,			GR_FONT_ID	%6
   at _GR_GC_INFO.foreground,		GR_COLOR	%7
   at _GR_GC_INFO.background,		GR_COLOR	%8
   at _GR_GC_INFO.usebackground,	GR_BOOL		%9
   iend
%endmacro

;typedef struct {
;  GR_GC_ID gcid;		/* GC id (or 0 if no such GC) */
;  int mode;			/* drawing mode */
;  GR_REGION_ID region;		/* user region */
;  int xoff;			/* x offset of user region*/
;  int yoff;			/* y offset of user region*/
;  GR_FONT_ID font;		/* font number */
;  GR_COLOR foreground;		/* foreground color */
;  GR_COLOR background;		/* background color */
;  GR_BOOL usebackground;	/* use background in bitmaps */
;} GR_GC_INFO;

;/* color palette*/
struc _GR_PALETTE
.count:		resGR_COUNT
.palette: 	resGR_PALENTRY * 256
endstruc

%macro GR_PALETTE 0.nolist
   istruc _GR_PALETTE
   iend
%endmacro

;typedef struct {
;  GR_COUNT count;		/* # valid entries*/
;  GR_PALENTRY palette[256];	/* palette*/
;} GR_PALETTE;

;/* Error codes */
%define	GR_ERROR_BAD_WINDOW_ID		1
%define	GR_ERROR_BAD_GC_ID		2
%define	GR_ERROR_BAD_CURSOR_SIZE	3
%define	GR_ERROR_MALLOC_FAILED		4
%define	GR_ERROR_BAD_WINDOW_SIZE	5
%define	GR_ERROR_KEYBOARD_ERROR		6
%define	GR_ERROR_MOUSE_ERROR		7
%define	GR_ERROR_INPUT_ONLY_WINDOW	8
%define	GR_ERROR_ILLEGAL_ON_ROOT_WINDOW	9
%define	GR_ERROR_TOO_MUCH_CLIPPING	10
%define	GR_ERROR_SCREEN_ERROR		11
%define	GR_ERROR_UNMAPPED_FOCUS_WINDOW	12
%define	GR_ERROR_BAD_DRAWING_MODE	13

;/* Event types.
; * Mouse motion is generated for every motion of the mouse, and is used to
; * track the entire history of the mouse (many events and lots of overhead).
; * Mouse position ignores the history of the motion, and only reports the
; * latest position of the mouse by only queuing the latest such event for
; * any single client (good for rubber-banding).
; */
%define	GR_EVENT_TYPE_ERROR		(-1)
%define	GR_EVENT_TYPE_NONE		0
%define	GR_EVENT_TYPE_EXPOSURE		1
%define	GR_EVENT_TYPE_BUTTON_DOWN	2
%define	GR_EVENT_TYPE_BUTTON_UP		3
%define	GR_EVENT_TYPE_MOUSE_ENTER	4
%define	GR_EVENT_TYPE_MOUSE_EXIT	5
%define	GR_EVENT_TYPE_MOUSE_MOTION	6
%define	GR_EVENT_TYPE_MOUSE_POSITION	7
%define	GR_EVENT_TYPE_KEY_DOWN		8
%define	GR_EVENT_TYPE_KEY_UP		9
%define	GR_EVENT_TYPE_FOCUS_IN		10
%define	GR_EVENT_TYPE_FOCUS_OUT		11
%define GR_EVENT_TYPE_FDINPUT		12
%define GR_EVENT_TYPE_UPDATE		13
%define GR_EVENT_TYPE_CHLD_UPDATE	14
%define GR_EVENT_TYPE_CLOSE_REQ		15
%define GR_EVENT_TYPE_TIMEOUT		16
%define GR_EVENT_TYPE_SCREENSAVER	17
%define GR_EVENT_TYPE_CLIENT_DATA_REQ	18
%define GR_EVENT_TYPE_CLIENT_DATA	19
%define GR_EVENT_TYPE_SELECTION_CHANGED 20
%define GR_EVENT_TYPE_TIMER             21
%define GR_EVENT_TYPE_PORTRAIT_CHANGED  22

;/* Event masks */
%define	GR_EVENTMASK(n)			((1) << (n))

%define	GR_EVENT_MASK_NONE		GR_EVENTMASK(GR_EVENT_TYPE_NONE)
%define	GR_EVENT_MASK_ERROR		0x80000000
%define	GR_EVENT_MASK_EXPOSURE		GR_EVENTMASK(GR_EVENT_TYPE_EXPOSURE)
%define	GR_EVENT_MASK_BUTTON_DOWN	GR_EVENTMASK(GR_EVENT_TYPE_BUTTON_DOWN)
%define	GR_EVENT_MASK_BUTTON_UP		GR_EVENTMASK(GR_EVENT_TYPE_BUTTON_UP)
%define	GR_EVENT_MASK_MOUSE_ENTER	GR_EVENTMASK(GR_EVENT_TYPE_MOUSE_ENTER)
%define	GR_EVENT_MASK_MOUSE_EXIT	GR_EVENTMASK(GR_EVENT_TYPE_MOUSE_EXIT)
%define	GR_EVENT_MASK_MOUSE_MOTION	GR_EVENTMASK(GR_EVENT_TYPE_MOUSE_MOTION)
%define	GR_EVENT_MASK_MOUSE_POSITION	GR_EVENTMASK(GR_EVENT_TYPE_MOUSE_POSITION)
%define	GR_EVENT_MASK_KEY_DOWN		GR_EVENTMASK(GR_EVENT_TYPE_KEY_DOWN)
%define	GR_EVENT_MASK_KEY_UP		GR_EVENTMASK(GR_EVENT_TYPE_KEY_UP)
%define	GR_EVENT_MASK_FOCUS_IN		GR_EVENTMASK(GR_EVENT_TYPE_FOCUS_IN)
%define	GR_EVENT_MASK_FOCUS_OUT		GR_EVENTMASK(GR_EVENT_TYPE_FOCUS_OUT)
%define	GR_EVENT_MASK_FDINPUT		GR_EVENTMASK(GR_EVENT_TYPE_FDINPUT)
%define	GR_EVENT_MASK_UPDATE		GR_EVENTMASK(GR_EVENT_TYPE_UPDATE)
%define	GR_EVENT_MASK_CHLD_UPDATE	GR_EVENTMASK(GR_EVENT_TYPE_CHLD_UPDATE)
%define	GR_EVENT_MASK_CLOSE_REQ		GR_EVENTMASK(GR_EVENT_TYPE_CLOSE_REQ)
%define	GR_EVENT_MASK_TIMEOUT		GR_EVENTMASK(GR_EVENT_TYPE_TIMEOUT)
%define GR_EVENT_MASK_SCREENSAVER	GR_EVENTMASK(GR_EVENT_TYPE_SCREENSAVER)
%define GR_EVENT_MASK_CLIENT_DATA_REQ	GR_EVENTMASK(GR_EVENT_TYPE_CLIENT_DATA_REQ)
%define GR_EVENT_MASK_CLIENT_DATA	GR_EVENTMASK(GR_EVENT_TYPE_CLIENT_DATA)
%define GR_EVENT_MASK_SELECTION_CHANGED GR_EVENTMASK(GR_EVENT_TYPE_SELECTION_CHANGED)
%define GR_EVENT_MASK_TIMER             GR_EVENTMASK(GR_EVENT_TYPE_TIMER)
%define GR_EVENT_MASK_PORTRAIT_CHANGED  GR_EVENTMASK(GR_EVENT_TYPE_PORTRAIT_CHANGED)
%define	GR_EVENT_MASK_ALL		( -1)

;/* update event types */
%define GR_UPDATE_MAP		1
%define GR_UPDATE_UNMAP		2
%define GR_UPDATE_MOVE		3
%define GR_UPDATE_SIZE		4
%define GR_UPDATE_UNMAPTEMP	5	;/* unmap during window move/resize*/
%define GR_UPDATE_ACTIVATE	6	;/* toplevel window [de]activate*/
%define GR_UPDATE_DESTROY	7

;/* Event for errors detected by the server.
; * These events are not delivered to GrGetNextEvent, but instead call
; * the user supplied error handling function.  Only the first one of
; * these errors at a time is saved for delivery to the client since
; * there is not much to be done about errors anyway except complain
; * and exit.
; */

struc _GR_EVENT_ERROR
.type: 		resGR_EVENT_TYPE
.name:		resGR_FUNC_NAME
.code:		resGR_ERROR
.id:		resGR_ID
endstruc

%macro GR_EVENT_ERROR  0.nolist
   istruc _GR_EVENT_ERROR
   iend
%endmacro

%macro GR_EVENT_ERROR  4.nolist
   istruc _GR_EVENT_ERROR
   at _GR_EVENT_ERROR.type, 		GR_EVENT_TYPE	%1
   at _GR_EVENT_ERROR.name,		GR_FUNC_NAME	%2
   at _GR_EVENT_ERROR.code,		GR_ERROR	%3
   at _GR_EVENT_ERROR.id,		GR_ID		%4
   iend
%endmacro

;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_FUNC_NAME name;		/* function name which failed */
;  GR_ERROR code;		/* error code */
;  GR_ID id;			/* resource id (maybe useless) */
;} GR_EVENT_ERROR;

struc _GR_EVENT_BUTTON
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.subwid: 	resGR_WINDOW_ID
.rootx:		resGR_COORD
.rooty: 	resGR_COORD
.x:		resGR_COORD
.y:		resGR_COORD
.buttons:	resGR_BUTTON
.changebuttons:	resGR_BUTTON
.modifiers:	resGR_KEYMOD
.time:		resGR_TIMEOUT
endstruc

%macro GR_EVENT_BUTTON  0.nolist
   istruc _GR_EVENT_BUTTON
   iend
%endmacro

%macro GR_EVENT_BUTTON  11.nolist
   istruc _GR_EVENT_BUTTON
   at _GR_EVENT_BUTTON.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_BUTTON.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_BUTTON.subwid, 		GR_WINDOW_ID	%3
   at _GR_EVENT_BUTTON.rootx,		GR_COORD	%4
   at _GR_EVENT_BUTTON.rooty, 		GR_COORD	%5
   at _GR_EVENT_BUTTON.x,		GR_COORD	%6
   at _GR_EVENT_BUTTON.y,		GR_COORD	%7
   at _GR_EVENT_BUTTON.buttons,		GR_BUTTON	%8
   at _GR_EVENT_BUTTON.changebuttons,	GR_BUTTON	%9
   at _GR_EVENT_BUTTON.modifiers,	GR_KEYMOD	%10
   at _GR_EVENT_BUTTON.time,		GR_TIMEOUT	%11
   iend
%endmacro

;/* Event for a mouse button pressed down or released. */
;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* window id event delivered to */
;  GR_WINDOW_ID subwid;		/* sub-window id (pointer was in) */
;  GR_COORD rootx;		/* root window x coordinate */
;  GR_COORD rooty;		/* root window y coordinate */
;  GR_COORD x;			/* window x coordinate of mouse */
;  GR_COORD y;			/* window y coordinate of mouse */
;  GR_BUTTON buttons;		/* current state of all buttons */
;  GR_BUTTON changebuttons;	/* buttons which went down or up */
;  GR_KEYMOD modifiers;		/* modifiers (MWKMOD_SHIFT, etc)*/
;  GR_TIMEOUT time;		/* tickcount time value*/
;} GR_EVENT_BUTTON;


struc _GR_EVENT_KEYSTROKE
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.subwid: 	resGR_WINDOW_ID
.rootx:		resGR_COORD
.rooty: 	resGR_COORD
.x:		resGR_COORD
.y:		resGR_COORD
.buttons:	resGR_BUTTON
.modifiers:	resGR_KEYMOD
.ch:		resGR_KEY
.scancode:	resGR_SCANCODE
endstruc

%macro GR_EVENT_KEYSTROKE  0.nolist
   istruc _GR_EVENT_KEYSTROKE
   iend
%endmacro

%macro GR_EVENT_KEYSTROKE  11.nolist
   istruc _GR_EVENT_KEYSTROKE
   at _GR_EVENT_KEYSTROKE.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_KEYSTROKE.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_KEYSTROKE.subwid, 	GR_WINDOW_ID	%3
   at _GR_EVENT_KEYSTROKE.rootx,	GR_COORD	%4
   at _GR_EVENT_KEYSTROKE.rooty, 	GR_COORD	%5
   at _GR_EVENT_KEYSTROKE.x,		GR_COORD	%6
   at _GR_EVENT_KEYSTROKE.y,		GR_COORD	%7
   at _GR_EVENT_KEYSTROKE.buttons,	GR_BUTTON	%8
   at _GR_EVENT_KEYSTROKE.modifiers,	GR_KEYMOD	%9
   at _GR_EVENT_KEYSTROKE.ch,		GR_KEY		%10
   at _GR_EVENT_KEYSTROKE.scancode,	GR_SCANCODE	%11
   iend
%endmacro


;/* Event for a keystroke typed for the window with has focus. */
;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* window id event delived to */
;  GR_WINDOW_ID subwid;		/* sub-window id (pointer was in) */
;  GR_COORD rootx;		/* root window x coordinate */
;  GR_COORD rooty;		/* root window y coordinate */
;  GR_COORD x;			/* window x coordinate of mouse */
;  GR_COORD y;			/* window y coordinate of mouse */
;  GR_BUTTON buttons;		/* current state of buttons */
;  GR_KEYMOD modifiers;		/* modifiers (MWKMOD_SHIFT, etc)*/
;  GR_KEY ch;			/* 16-bit unicode key value, MWKEY_xxx */
;  GR_SCANCODE scancode;		/* OEM scancode value if available*/
;} GR_EVENT_KEYSTROKE


struc _GR_EVENT_EXPOSURE
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.x:		resGR_COORD
.y:		resGR_COORD
.width:		resGR_SIZE
.height: 	resGR_SIZE
endstruc

%macro GR_EVENT_EXPOSURE  0.nolist
   istruc _GR_EVENT_EXPOSURE
   iend
%endmacro

%macro GR_EVENT_EXPOSURE  6.nolist
   istruc _GR_EVENT_EXPOSURE
   at _GR_EVENT_EXPOSURE.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_EXPOSURE.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_EXPOSURE.x,		GR_COORD	%3
   at _GR_EVENT_EXPOSURE.y, 		GR_COORD	%4
   at _GR_EVENT_EXPOSURE.width,		GR_SIZE		%5
   at _GR_EVENT_EXPOSURE.height, 	GR_SIZE		%6
   iend
%endmacro

;/* Event for exposure for a region of a window. */
;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* window id */
;  GR_COORD x;			/* window x coordinate of exposure */
;  GR_COORD y;			/* window y coordinate of exposure */
;  GR_SIZE width;		/* width of exposure */
;  GR_SIZE height;		/* height of exposure */
;} GR_EVENT_EXPOSURE;


struc _GR_EVENT_GENERAL
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.otherid:	resGR_WINDOW_ID
endstruc

%macro GR_EVENT_GENERAL  0.nolist
   istruc _GR_EVENT_GENERAL
   iend
%endmacro

%macro GR_EVENT_GENERAL  3.nolist
   istruc _GR_EVENT_GENERAL
   at _GR_EVENT_GENERAL.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_GENERAL.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_GENERAL.otherid,	GR_WINDOW_ID	%3
   iend
%endmacro

;/* General events for focus in or focus out for a window, or mouse enter
; * or mouse exit from a window, or window unmapping or mapping, etc.
; * Server portrait mode changes are also sent using this event to
; * all windows that request it.
; */
;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* window id */
;  GR_WINDOW_ID otherid;		/* new/old focus id for focus events*/
;} GR_EVENT_GENERAL;


struc _GR_EVENT_MOUSE
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.subwid: 	resGR_WINDOW_ID
.rootx:		resGR_COORD
.rooty: 	resGR_COORD
.x:		resGR_COORD
.y:		resGR_COORD
.buttons:	resGR_BUTTON
.modifiers:	resGR_KEYMOD
endstruc

%macro GR_EVENT_MOUSE  0.nolist
   istruc _GR_EVENT_MOUSE
   iend
%endmacro

%macro GR_EVENT_MOUSE  9.nolist
   istruc _GR_EVENT_MOUSE
   at _GR_EVENT_MOUSE.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_MOUSE.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_MOUSE.subwid, 		GR_WINDOW_ID	%3
   at _GR_EVENT_MOUSE.rootx,		GR_COORD	%4
   at _GR_EVENT_MOUSE.rooty, 		GR_COORD	%5
   at _GR_EVENT_MOUSE.x,		GR_COORD	%6
   at _GR_EVENT_MOUSE.y,		GR_COORD	%7
   at _GR_EVENT_MOUSE.buttons,		GR_BUTTON	%8
   at _GR_EVENT_MOUSE.modifiers,	GR_KEYMOD	%9
   iend
%endmacro

;/* Events for mouse motion or mouse position. */
;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* window id event delivered to */
;  GR_WINDOW_ID subwid;		/* sub-window id (pointer was in) */
;  GR_COORD rootx;		/* root window x coordinate */
;  GR_COORD rooty;		/* root window y coordinate */
;  GR_COORD x;			/* window x coordinate of mouse */
;  GR_COORD y;			/* window y coordinate of mouse */
;  GR_BUTTON buttons;		/* current state of buttons */
;  GR_KEYMOD modifiers;		/* modifiers (MWKMOD_SHIFT, etc)*/
;} GR_EVENT_MOUSE;


struc _GR_EVENT_FDINPUT
.type:	resGR_EVENT_TYPE
.fd:	resd 1
endstruc

%macro GR_EVENT_FDINPUT 0.nolist
   istruc _GR_EVENT_FDINPUT
   iend
%endmacro

%macro GR_EVENT_FDINPUT 2.nolist
   istruc _GR_EVENT_FDINPUT
   at _GR_EVENT_FDINPUT.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_FDINPUT.fd,		dd	%2
   iend
%endmacro

;/* GrRegisterInput event*/
;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  int		fd;		/* input fd*/
;} GR_EVENT_FDINPUT;


;/* GR_EVENT_TYPE_UPDATE */
struc _GR_EVENT_TYPE_UPDATE
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.subwid:	resGR_WINDOW_ID
.x:		resGR_COORD
.y:		resGR_COORD
.width:		resGR_SIZE
.height: 	resGR_SIZE
.utype:		resGR_UPDATE_TYPE	
endstruc

%macro GR_EVENT_EXPOSURE  0.nolist
   istruc _GR_EVENT_TYPE_UPDATE
   iend
%endmacro

%macro GR_EVENT_TYPE_UPDATE  8.nolist
   istruc _GR_EVENT_TYPE_UPDATE
   at _GR_EVENT_EXPOSURE.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_EXPOSURE.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_EXPOSURE.subwid,	GR_WINDOW_ID	%3
   at _GR_EVENT_EXPOSURE.x,		GR_COORD	%4
   at _GR_EVENT_EXPOSURE.y, 		GR_COORD	%5
   at _GR_EVENT_EXPOSURE.width,		GR_SIZE		%6
   at _GR_EVENT_EXPOSURE.height, 	GR_SIZE		%7
   at _GR_EVENT_EXPOSURE.utype, 	GR_UPDATE_TYPE	%8
   iend
%endmacro

;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* select window id*/
;  GR_WINDOW_ID subwid;		/* update window id (=wid for UPDATE event)*/
;  GR_COORD x;			/* new window x coordinate */
;  GR_COORD y;			/* new window y coordinate */
;  GR_SIZE width;		/* new width */
;  GR_SIZE height;		/* new height */
;  GR_UPDATE_TYPE utype;		/* update_type */
;} GR_EVENT_UPDATE;



;/* GR_EVENT_TYPE_SCREENSAVER */

struc _GR_EVENT_SCREENSAVER
.type:		resGR_EVENT_TYPE
.activate:	resGR_BOOL
endstruc

%macro  GR_EVENT_SCREENSAVER  0.nolist
   istruc _GR_EVENT_SCREENSAVER
   iend
%endmacro

%macro GR_EVENT_SCREENSAVER 2.nolist
   istruc _GR_EVENT_SCREENSAVER
   at _GR_EVENT_SCREENSAVER.type, 	GR_EVENT_TYPE	%1
   at _GR_EVENT_SCREENSAVER.activate,	GR_BOOL		%2
   iend
%endmacro

;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_BOOL activate;		/* true = activate, false = deactivate */
;} GR_EVENT_SCREENSAVER;


;/* GR_EVENT_TYPE_CLIENT_DATA_REQ */
struc _GR_EVENT_CLIENT_DATA_REQ
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.rid:		resGR_WINDOW_ID
.serial:	resGR_SERIALNO
.mimetype:	resGR_MIMETYPE
endstruc

%macro GR_EVENT_CLIENT_DATA_REQ  0.nolist
   istruc _GR_EVENT_CLIENT_DATA_REQ
   iend 
%endmacro

%macro GR_EVENT_CLIENT_DATA_REQ 5.nolist
   istruc _GR_EVENT_CLIENT_DATA_REQ
   at _GR_EVENT_CLIENT_DATA_REQ.type,		GR_EVENT_TYPE 	%1
   at _GR_EVENT_CLIENT_DATA_REQ.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_CLIENT_DATA_REQ.rid,		GR_WINDOW_ID	%3
   at _GR_EVENT_CLIENT_DATA_REQ.serial,		GR_SERIALNO	%4
   at _GR_EVENT_CLIENT_DATA_REQ.mimetype,	GR_MIMETYPE	%5
   iend
%endmacro

;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* ID of requested window */
;  GR_WINDOW_ID rid;		/* ID of window to send data to */
;  GR_SERIALNO serial;		/* Serial number of transaction */
;  GR_MIMETYPE mimetype;		/* Type to supply data as */
;} GR_EVENT_CLIENT_DATA_REQ;


/* GR_EVENT_TYPE_CLIENT_DATA */
struc _GR_EVENT_CLIENT_DATA
.type:		resGR_EVENT_TYPE
.wid:		resGR_WINDOW_ID
.rid:		resGR_WINDOW_ID
.serial:	resGR_SERIALNO
.len:		resd 1
.datalen:	resd 1
.data:		resd 1
endstruc

%macro GR_EVENT_CLIENT_DATA  0.nolist
   istruc _GR_EVENT_CLIENT_DATA
   iend 
%endmacro

%macro GR_EVENT_CLIENT_DATA 5.nolist
   istruc _GR_EVENT_CLIENT_DATA
   at _GR_EVENT_CLIENT_DATA.type,		GR_EVENT_TYPE 	%1
   at _GR_EVENT_CLIENT_DATA.wid,		GR_WINDOW_ID	%2
   at _GR_EVENT_CLIENT_DATA.rid,		GR_WINDOW_ID	%3
   at _GR_EVENT_CLIENT_DATA.serial,		GR_SERIALNO	%4
   at _GR_EVENT_CLIENT_DATA.len,		dd		%5
   at _GR_EVENT_CLIENT_DATA.datalen,	dd		%6
   at _GR_EVENT_CLIENT_DATA.data,		dd		%7
   iend
%endmacro

;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID wid;		/* ID of window data is destined for */
;  GR_WINDOW_ID rid;		/* ID of window data is from */
;  GR_SERIALNO serial;		/* Serial number of transaction */
;  unsigned long len;		/* Total length of data */
;  unsigned long datalen;	/* Length of following data */
;  void *data;			/* Pointer to data (filled in on client side) */
;} GR_EVENT_CLIENT_DATA;

;/* GR_EVENT_TYPE_SELECTION_CHANGED */
struc _GR_EVENT_SELECTION_CHANGED
.type:		resGR_EVENT_TYPE
.new_owner:	resGR_WINDOW_ID
endstruc

%macro GR_EVENT_SELECTION_CHANGED  0.nolist
   istruc _GR_EVENT_SELECTIN_CHANGED
   iend
%endmacro

%macro GR_EVENT_SELECTION_CHANGED 2.nolist
   istruc _GR_EVENT_SELECTION_CHANGED
   at _GR_EVENT_SELECTION_CHANGED.type,		GR_EVENT_TYPE	%1
   at _GR_EVENT_SELECTION_CHANGED.new_owner, 	GR_WINDOW_ID	%2
   iend
%endmacro

;typedef struct {
;  GR_EVENT_TYPE type;		/* event type */
;  GR_WINDOW_ID new_owner;	/* ID of new selection owner */
;} GR_EVENT_SELECTION_CHANGED;


;/* GR_EVENT_TYPE_TIMER */

struc _GR_EVENT_TIMER
.type:	resGR_EVENT_TYPE
.wid:	resGR_WINDOW_ID
.tid:	resGR_TIMER_ID
endstruc

%macro GR_EVENT_TIMER  0.nolist
    istruc _GR_EVENT_TIMER
    iend
%endmacro

%macro GR_EVENT_TIMER  3.nolist
   istruc _GR_EVENT_TIMER
   at _GR_EVENT_TIMER.type:	GR_EVENT_TYPE	%1
   at _GR_EVENT_TIMER.wid:	GR_WINDOW_ID	%2
   at _GR_EVENT_TIMER.tid:	GR_TIMER_ID	%3
   iend
%endmacro

;typedef struct {
;  GR_EVENT_TYPE  type;		/* event type, GR_EVENT_TYPE_TIMER */
;  GR_WINDOW_ID   wid;		/* ID of window timer is destined for */
;  GR_TIMER_ID    tid;		/* ID of expired timer */
;} GR_EVENT_TIMER;

;/*
; * Union of all possible event structures.
; * This is the structure returned by the GrGetNextEvent and similar routines.
; */
struc _GR_EVENT
.type:	resGR_EVENT_TYPE
.error:	resGR_EVENT_ERROR
.general:	resGR_EVENT_GENERAL
.button:	resGR_EVENT_BUTTON
.keystroke:	resGR_EVENT_KEYSTROKE
.exposure:	resGR_EVENT_EXPOSURE
.mouse:		resGR_EVENT_MOUSE
.fdinput:	resGR_EVENT_FDINPUT
.update:	resGR_EVENT_UPDATE
.screensaver:	resGR_EVENT_SCREENSAVER
.clientdatareq:	resGR_EVENT_CLIENT_DATA_REQ
.clientdata:	resGR_EVENT_CLIENT_DATA
.selectionchanged:	resGR_EVENT_SELECTION_CHANGED
.timer:		resGR_EVENT_TIMER
endstruc

%macro  GR_EVENT  0.nolist
   istruc _GR_EVENT
   iend
%endmacro

%macro GR_EVENT  14.nolist
   istruc _GR_EVENT
   at _GR_EVENT.type,			GR_EVENT_TYPE			%1
   at _GR_EVENT.error,			GR_EVENT_ERROR			%2
   at _GR_EVENT.general,		GR_EVENT_GENERAL		%3
   at _GR_EVENT.button,			GR_EVENT_BUTTON			%4
   at _GR_EVENT.keystroke,		GR_EVENT_KEYSTROKE		%5
   at _GR_EVENT.exposure,		GR_EVENT_EXPOSURE		%6
   at _GR_EVENT.mouse,			GR_EVENT_MOUSE			%7
   at _GR_EVENT.fdinput,		GR_EVENT_FDINPUT		%8
   at _GR_EVENT.update,			GR_EVENT_UPDATE			%9
   at _GR_EVENT.screensaver,		GR_EVENT_SCREENSAVER		%10
   at _GR_EVENT.clientdatareq,		GR_EVENT_CLIENT_DATA_REQ	%11
   at _GR_EVENT.clientdata,		GR_EVENT_CLIENT_DATA		%12
   at _GR_EVENT.selectionchanged,	GR_EVENT_SELECTION_CHANGED	%13
   at _GR_EVENT.timer,			GR_EVENT_TIMER			%14
   iend
%endmacro


;typedef union {
;  GR_EVENT_TYPE type;			/* event type */
;  GR_EVENT_ERROR error;			/* error event */
;  GR_EVENT_GENERAL general;		/* general window events */
;  GR_EVENT_BUTTON button;		/* button events */
;  GR_EVENT_KEYSTROKE keystroke;		/* keystroke events */
;  GR_EVENT_EXPOSURE exposure;		/* exposure events */
;  GR_EVENT_MOUSE mouse;			/* mouse motion events */
;  GR_EVENT_FDINPUT fdinput;		/* fd input events*/
;  GR_EVENT_UPDATE update;		/* window update events */
;  GR_EVENT_SCREENSAVER screensaver; 	/* Screen saver events */
;  GR_EVENT_CLIENT_DATA_REQ clientdatareq; /* Request for client data events */
;  GR_EVENT_CLIENT_DATA clientdata;	/* Client data events */
;  GR_EVENT_SELECTION_CHANGED selectionchanged; /* Selection owner changed */
;  GR_EVENT_TIMER timer;
;} GR_EVENT;

;--!!!----!!!---NOTE!  this next one was not translated!
;typedef void (*GR_FNCALLBACKEVENT)(GR_EVENT *);

/* Pixel packings within words. */
%define	GR_BITMAPBITS	((GR_BITMAP_size) * 8)
%define	GR_ZEROBITS	((GR_BITMAP) 0x0000)
%define	GR_ONEBITS	((GR_BITMAP) 0xffff)
%define	GR_FIRSTBIT	((GR_BITMAP) 0x8000)
%define	GR_LASTBIT	((GR_BITMAP) 0x0001)
%define	GR_BITVALUE(n)	(1<<(n))
%define	GR_SHIFTBIT(m)	(((m) << 1))
%define	GR_NEXTBIT(m)	(((m) >> 1))
;%define	GR_TESTBIT(m)	(((m) & GR_FIRSTBIT) != 0)

%macro GR_TESTBIT 1.nolist
   and %1, GR_FIRSTBIT
   test %1, %1
%endmacro

/* Size of bitmaps. */
%define GR_BITMAP_SIZE(width,height) ((height)*((width)/(GR_BITMAP_size*8)))


%define	GR_MAX_BITMAP_SIZE  GR_BITMAP_SIZE(MWMAX_CURSOR_SIZE, MWMAX_CURSOR_SIZE)

;/* GrGetSysColor colors*/
;/* desktop background*/
%define GR_COLOR_DESKTOP           0

;/* caption colors*/
%define GR_COLOR_ACTIVECAPTION     1
%define GR_COLOR_ACTIVECAPTIONTEXT 2
%define GR_COLOR_INACTIVECAPTION   3
%define GR_COLOR_INACTIVECAPTIONTEXT 4

;/* 3d border shades*/
%define GR_COLOR_WINDOWFRAME       5
%define GR_COLOR_BTNSHADOW         6
%define GR_COLOR_3DLIGHT           7
%define GR_COLOR_BTNHIGHLIGHT      8

;/* top level application window backgrounds/text*/
%define GR_COLOR_APPWINDOW         9
%define GR_COLOR_APPTEXT           10

;/* button control backgrounds/text (usually same as app window colors)*/
%define GR_COLOR_BTNFACE           11
%define GR_COLOR_BTNTEXT           12

;/* edit/listbox control backgrounds/text, selected highlights*/
%define GR_COLOR_WINDOW            13
%define GR_COLOR_WINDOWTEXT        14
%define GR_COLOR_HIGHLIGHT         15
%define GR_COLOR_HIGHLIGHTTEXT     16
%define GR_COLOR_GRAYTEXT          17

;/* menu backgrounds/text*/
%define GR_COLOR_MENUTEXT          18
%define GR_COLOR_MENU              19


;/* Error strings per error number*/
%macro GR_ERROR_STRINGS  0.nolist
   dd GR_ERROR_STRINGS_1
   dd GR_ERROR_STRINGS_2
   dd GR_ERROR_STRINGS_3
   dd GR_ERROR_STRINGS_4
   dd GR_ERROR_STRINGS_5
   dd GR_ERROR_STRINGS_6
   dd GR_ERROR_STRINGS_7
   dd GR_ERROR_STRINGS_8
   dd GR_ERROR_STRINGS_9
   dd GR_ERROR_STRINGS_10
   dd GR_ERROR_STRINGS_11
   dd GR_ERROR_STRINGS_12
   dd GR_ERROR_STRINGS_13
   dd GR_ERROR_STRINGS_14
GR_ERROR_STRINGS_1: db "",0
GR_ERROR_STRINGS_2: db "Bad window id: ", 0x0A,0
GR_ERROR_STRINGS_3: db "Bad graphics context: ",0x0A, 0
GR_ERROR_STRINGS_4: db "Bad cursor size: ", 0x0A, 0
GR_ERROR_STRINGS_5: db "Out of server memory", 0x0A, 0
GR_ERROR_STRINGS_6: db "Bad window size: ", 0x0A, 0
GR_ERROR_STRINGS_7: db "Keyboard error",0x0A, 0
GR_ERROR_STRINGS_8: db "Mouse error", 0x0A, 0
GR_ERROR_STRINGS_9: db "Input only window: ", 0x0A, 0
GR_ERROR_STRINGS_10: db "Illegal on root window: ", 0x0A, 0
GR_ERROR_STRINGS_11: db "Clipping overflow", 0x0A, 0
GR_ERROR_STRINGS_12: db "Screen error", 0x0A, 0
GR_ERROR_STRINGS_13: db "Unmapped focus window: ", 0x0A, 0
GR_ERROR_STRINGS_14: db "Bad drawing mode gc: ", 0x0A, 0
%endmacro

;%define GR_ERROR_STRINGS		\
;	"",				\
;	"Bad window id: %d\n",		\
;	"Bad graphics context: %d\n",	\
;	"Bad cursor size\n",		\
;	"Out of server memory\n",	\
;	"Bad window size: %d\n",	\
;	"Keyboard error\n",		\
;	"Mouse error\n",		\
;	"Input only window: %d\n",	\
;	"Illegal on root window: %d\n",	\
;	"Clipping overflow\n",		\
;	"Screen error\n",		\
;	"Unmapped focus window: %d\n",	\
;	"Bad drawing mode gc: %d\n"
;
extern nxErrorStrings;

;/* Public graphics routines. */
;void		GrFlush(void);
;int		GrOpen(void);
;void		GrClose(void);
;void		GrDelay(GR_TIMEOUT msecs);
;void		GrGetScreenInfo(GR_SCREEN_INFO *sip);
;GR_COLOR	GrGetSysColor(int index);
;GR_WINDOW_ID	GrNewWindow(GR_WINDOW_ID parent, GR_COORD x, GR_COORD y,
;			GR_SIZE width, GR_SIZE height, GR_SIZE bordersize,
;			GR_COLOR background, GR_COLOR bordercolor);
;GR_WINDOW_ID    GrNewPixmap(GR_SIZE width, GR_SIZE height, void * addr);
;GR_WINDOW_ID	GrNewInputWindow(GR_WINDOW_ID parent, GR_COORD x, GR_COORD y,
;				GR_SIZE width, GR_SIZE height);
;void		GrDestroyWindow(GR_WINDOW_ID wid);
;GR_GC_ID	GrNewGC(void);
;GR_GC_ID	GrCopyGC(GR_GC_ID gc);
;void		GrGetGCInfo(GR_GC_ID gc, GR_GC_INFO *gcip);
;void		GrDestroyGC(GR_GC_ID gc);
;GR_REGION_ID	GrNewRegion(void);
;GR_REGION_ID	GrNewPolygonRegion(int mode, GR_COUNT count, GR_POINT *points);
;void		GrDestroyRegion(GR_REGION_ID region);
;void		GrUnionRectWithRegion(GR_REGION_ID region, GR_RECT *rect);
;void		GrUnionRegion(GR_REGION_ID dst_rgn, GR_REGION_ID src_rgn1,
;			GR_REGION_ID src_rgn2);
;void		GrIntersectRegion(GR_REGION_ID dst_rgn, GR_REGION_ID src_rgn1,
;			GR_REGION_ID src_rgn2);
;void		GrSubtractRegion(GR_REGION_ID dst_rgn, GR_REGION_ID src_rgn1,
;			GR_REGION_ID src_rgn2);
;void		GrXorRegion(GR_REGION_ID dst_rgn, GR_REGION_ID src_rgn1,
;			GR_REGION_ID src_rgn2);
;void		GrSetGCRegion(GR_GC_ID gc, GR_REGION_ID region);
;void		GrSetGCClipOrigin(GR_GC_ID gc, int x, int y);
;GR_BOOL		GrPointInRegion(GR_REGION_ID region, GR_COORD x, GR_COORD y);
;int		GrRectInRegion(GR_REGION_ID region, GR_COORD x, GR_COORD y,
;			GR_COORD w, GR_COORD h);
;GR_BOOL		GrEmptyRegion(GR_REGION_ID region);
;GR_BOOL		GrEqualRegion(GR_REGION_ID rgn1, GR_REGION_ID rgn2);
;void		GrOffsetRegion(GR_REGION_ID region, GR_SIZE dx, GR_SIZE dy);
;int		GrGetRegionBox(GR_REGION_ID region, GR_RECT *rect);
;void		GrMapWindow(GR_WINDOW_ID wid);
;void		GrUnmapWindow(GR_WINDOW_ID wid);
;void		GrRaiseWindow(GR_WINDOW_ID wid);
;void		GrLowerWindow(GR_WINDOW_ID wid);
;void		GrMoveWindow(GR_WINDOW_ID wid, GR_COORD x, GR_COORD y);
;void		GrResizeWindow(GR_WINDOW_ID wid, GR_SIZE width, GR_SIZE height);
;void		GrReparentWindow(GR_WINDOW_ID wid, GR_WINDOW_ID pwid,
;			GR_COORD x, GR_COORD y);
;void		GrGetWindowInfo(GR_WINDOW_ID wid, GR_WINDOW_INFO *infoptr);
;void		GrSetWMProperties(GR_WINDOW_ID wid, GR_WM_PROPERTIES *props);
;void		GrGetWMProperties(GR_WINDOW_ID wid, GR_WM_PROPERTIES *props);
;GR_FONT_ID	GrCreateFont(GR_CHAR *name, GR_COORD height,
;			GR_LOGFONT *plogfont);
;void		GrGetFontList(GR_FONTLIST ***fonts, int *numfonts);
;void		GrFreeFontList(GR_FONTLIST ***fonts, int num);
;void		GrSetFontSize(GR_FONT_ID fontid, GR_COORD size);
;void		GrSetFontRotation(GR_FONT_ID fontid, int tenthsdegrees);
;void		GrSetFontAttr(GR_FONT_ID fontid, int setflags, int clrflags);
;void		GrDestroyFont(GR_FONT_ID fontid);
;void		GrGetFontInfo(GR_FONT_ID font, GR_FONT_INFO *fip);
;GR_WINDOW_ID	GrGetFocus(void);
;void		GrSetFocus(GR_WINDOW_ID wid);
;void		GrClearArea(GR_WINDOW_ID wid, GR_COORD x, GR_COORD y, GR_SIZE width,
;			GR_SIZE height, GR_BOOL exposeflag);
;void		GrSelectEvents(GR_WINDOW_ID wid, GR_EVENT_MASK eventmask);
;void		GrGetNextEvent(GR_EVENT *ep);
;void		GrGetNextEventTimeout(GR_EVENT *ep, GR_TIMEOUT timeout);
;void		GrCheckNextEvent(GR_EVENT *ep);
;int		GrPeekEvent(GR_EVENT *ep);
;void		GrPeekWaitEvent(GR_EVENT *ep);
;void		GrLine(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x1, GR_COORD y1,
;			GR_COORD x2, GR_COORD y2);
;void		GrPoint(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y);
;void		GrPoints(GR_DRAW_ID id, GR_GC_ID gc, GR_COUNT count,
;			GR_POINT *pointtable);
;void		GrRect(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE width, GR_SIZE height);
;void		GrFillRect(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE width, GR_SIZE height);
;void		GrPoly(GR_DRAW_ID id, GR_GC_ID gc, GR_COUNT count,
;			GR_POINT *pointtable);
;void		GrFillPoly(GR_DRAW_ID id, GR_GC_ID gc, GR_COUNT count,
;			GR_POINT *pointtable);
;void		GrEllipse(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE rx, GR_SIZE ry);
;void		GrFillEllipse(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x,
;			GR_COORD y, GR_SIZE rx, GR_SIZE ry);
;void		GrArc(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE rx, GR_SIZE ry, GR_COORD ax, GR_COORD ay,
;			GR_COORD bx, GR_COORD by, int type);
;void		GrArcAngle(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE rx, GR_SIZE ry, GR_COORD angle1,
;			GR_COORD angle2, int type); /* floating point required*/
;void		GrSetGCForeground(GR_GC_ID gc, GR_COLOR foreground);
;void		GrSetGCBackground(GR_GC_ID gc, GR_COLOR background);
;void		GrSetGCUseBackground(GR_GC_ID gc, GR_BOOL flag);
;void		GrSetGCMode(GR_GC_ID gc, int mode);
;void		GrSetGCFont(GR_GC_ID gc, GR_FONT_ID font);
;void		GrGetGCTextSize(GR_GC_ID gc, void *str, int count, int flags,
;			GR_SIZE *retwidth, GR_SIZE *retheight,GR_SIZE *retbase);
;void		GrReadArea(GR_DRAW_ID id, GR_COORD x, GR_COORD y, GR_SIZE width,
;			GR_SIZE height, GR_PIXELVAL *pixels);
;void		GrArea(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE width,GR_SIZE height,void *pixels,int pixtype);
;void            GrCopyArea(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE width, GR_SIZE height, GR_DRAW_ID srcid,
;			GR_COORD srcx, GR_COORD srcy, int op);
;void		GrBitmap(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			GR_SIZE width, GR_SIZE height, GR_BITMAP *imagebits);
;void		GrDrawImageBits(GR_DRAW_ID id,GR_GC_ID gc,GR_COORD x,GR_COORD y,
;			GR_IMAGE_HDR *pimage);
;void		GrDrawImageFromFile(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x,
;			GR_COORD y, GR_SIZE width, GR_SIZE height,
;			char *path, int flags);
;GR_IMAGE_ID	GrLoadImageFromFile(char *path, int flags);
;void		GrDrawImageFromBuffer(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x,
;			GR_COORD y, GR_SIZE width, GR_SIZE height,
;			void *buffer, int size, int flags);
;GR_IMAGE_ID	GrLoadImageFromBuffer(void *buffer, int size, int flags);
;void		GrDrawImageToFit(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x,
;			GR_COORD y, GR_SIZE width, GR_SIZE height,
;			GR_IMAGE_ID imageid);
;void		GrFreeImage(GR_IMAGE_ID id);
;void		GrGetImageInfo(GR_IMAGE_ID id, GR_IMAGE_INFO *iip);
;void		GrText(GR_DRAW_ID id, GR_GC_ID gc, GR_COORD x, GR_COORD y,
;			void *str, GR_COUNT count, int flags);
;GR_CURSOR_ID	GrNewCursor(GR_SIZE width, GR_SIZE height, GR_COORD hotx,
;			GR_COORD hoty, GR_COLOR foreground, GR_COLOR background,
;			GR_BITMAP *fgbitmap, GR_BITMAP *bgbitmap);
;void		GrDestroyCursor(GR_CURSOR_ID cid);
;void		GrSetWindowCursor(GR_WINDOW_ID wid, GR_CURSOR_ID cid);
;void		GrMoveCursor(GR_COORD x, GR_COORD y);
;void		GrGetSystemPalette(GR_PALETTE *pal);
;void		GrSetSystemPalette(GR_COUNT first, GR_PALETTE *pal);
;void		GrFindColor(GR_COLOR c, GR_PIXELVAL *retpixel);
;void		GrReqShmCmds(long shmsize);
;void		GrInjectPointerEvent(MWCOORD x, MWCOORD y,
;			int button, int visible);
;void		GrInjectKeyboardEvent(GR_WINDOW_ID wid, GR_KEY keyvalue,
;			GR_KEYMOD modifiers, GR_SCANCODE scancode,
;			GR_BOOL pressed);
;void		GrCloseWindow(GR_WINDOW_ID wid);
;void		GrKillWindow(GR_WINDOW_ID wid);
;void		GrSetScreenSaverTimeout(GR_TIMEOUT timeout);
;void		GrSetSelectionOwner(GR_WINDOW_ID wid, GR_CHAR *typelist);
;GR_WINDOW_ID	GrGetSelectionOwner(GR_CHAR **typelist);
;void		GrRequestClientData(GR_WINDOW_ID wid, GR_WINDOW_ID rid,
;			GR_SERIALNO serial, GR_MIMETYPE mimetype);
;void		GrSendClientData(GR_WINDOW_ID wid, GR_WINDOW_ID did,
;			GR_SERIALNO serial, GR_LENGTH len, GR_LENGTH thislen,
;			void *data);
;void		GrBell(void);
;void		GrSetBackgroundPixmap(GR_WINDOW_ID wid, GR_WINDOW_ID pixmap,
;			int flags);
;void		GrQueryTree(GR_WINDOW_ID wid, GR_WINDOW_ID *parentid, GR_WINDOW_ID **children,
;			GR_COUNT *nchildren);
;GR_TIMER_ID	GrCreateTimer(GR_WINDOW_ID wid, GR_TIMEOUT period);
;void		GrDestroyTimer(GR_TIMER_ID tid);
;void		GrSetPortraitMode(int portraitmode);
;
;void		GrRegisterInput(int fd);
;void		GrUnregisterInput(int fd);
;void		GrMainLoop(GR_FNCALLBACKEVENT fncb);
;GR_FNCALLBACKEVENT GrSetErrorHandler(GR_FNCALLBACKEVENT fncb);
;void		GrDefaultErrorHandler(GR_EVENT *ep);

;/* passive library entry points - available with client/server only*/
;void		GrPrepareSelect(int *maxfd,void *rfdset);
;void		GrServiceSelect(void *rfdset, GR_FNCALLBACKEVENT fncb);
;
;/* nxutil.c - utility routines*/
;GR_WINDOW_ID	GrNewWindowEx(GR_WM_PROPS props, GR_CHAR *title,
;			GR_WINDOW_ID parent, GR_COORD x, GR_COORD y,
;			GR_SIZE width, GR_SIZE height, GR_COLOR background);
;void		GrDrawLines(GR_DRAW_ID w, GR_GC_ID gc, GR_POINT *points,
;			GR_COUNT count);
;GR_BITMAP *	GrNewBitmapFromData(GR_SIZE width, GR_SIZE height, GR_SIZE bits_width,
;			GR_SIZE bits_height, void *bits, int flags);
;GR_WINDOW_ID    GrNewPixmapFromData(GR_SIZE width, GR_SIZE height, 
;			GR_COLOR foreground, GR_COLOR background, void * bits,
;			int flags);
;
;/* direct client-side framebuffer mapping routines*/
;unsigned char * GrOpenClientFramebuffer(void);
;void		GrCloseClientFramebuffer(void);
;void		GrGetWindowFBInfo(GR_WINDOW_ID wid, GR_WINDOW_FB_INFO *fbinfo);

;/* retrofit - no longer used*/
;GR_CURSOR_ID	GrSetCursor(GR_WINDOW_ID wid, GR_SIZE width, GR_SIZE height,
;			GR_COORD hotx, GR_COORD hoty, GR_COLOR foreground,
;			GR_COLOR background, GR_BITMAP *fbbitmap,
;			GR_BITMAP *bgbitmap);

%define GrSetBorderColor		GrSetWindowBorderColor	/* retrofit*/
%define GrClearWindow(wid,exposeflag)	GrClearArea(wid,0,0,0,0,exposeflag) /* retrofit*/

/* useful function macros*/
%macro GrSetWindowBackgroundColor 2.nolist
	sub esp, byte GR_WM_PROPERTIES_size
	push edi
	mov edi, esp		;edi now ptr to our GR_WM_PROPERTIES struc
	mov [edi + GR_WM_PROPERTIES.flags], dword GR_WM_FLAGS_BACKGROUND
	mov [edi + GR_WM_PROPERTIES.background], dword %2
	push eax
	mov eax, %1
	call GrSetWMProperties
	pop eax
	add esp, byte GR_WM_PROPERTIES_size
	pop edi
%endmacro
;
;#define GrSetWindowBackgroundColor(wid,color) \
;		{	GR_WM_PROPERTIES props;	\
;			props.flags = GR_WM_FLAGS_BACKGROUND; \
;			props.background = color; \
;			GrSetWMProperties(wid, &props); \
;		}

%macro GrSetWindowBorderSize 2.nolist
	sub esp, byte GR_WM_PROPERTIES_size
	push edi
	mov edi, esp		;edi now ptr to our GR_WM_PROPERTIES struc
	mov [edi + GR_WM_PROPERTIES.flags], dword GR_WM_FLAGS_BORDERSIZE
	mov [edi + GR_WM_PROPERTIES.bordersize], dword %2
	push eax
	mov eax, %1
	call GrSetWMProperties
	pop eax
	add esp, byte GR_WM_PROPERTIES_size
	pop edi
%endmacro
	
;#define GrSetWindowBorderSize(wid,width) \
;		{	GR_WM_PROPERTIES props;	\
;			props.flags = GR_WM_FLAGS_BORDERSIZE; \
;			props.bordersize = width; \
;			GrSetWMProperties(wid, &props); \
;		}

%macro GrSetWindowBorderColor 2.nolist
	sub esp, byte GR_WM_PROPERTIES_size
	push edi
	mov edi, esp		;edi now ptr to our GR_WM_PROPERTIES struc
	mov [edi + GR_WM_PROPERTIES.flags], dowrd GR_WM_FLAGS_BORDERCOLOR
	mov [edi + GR_WM_PROPERTIES.bordercolor], dword %2
	push eax
	mov eax, %1
	call GrSetWMProperties
	pop eax
	add esp, byte GR_WM_PROPERTIES_size
	pop edi
%endmacro

;#define GrSetWindowBorderColor(wid,color) \
;		{	GR_WM_PROPERTIES props;	\
;			props.flags = GR_WM_FLAGS_BORDERCOLOR; \
;			props.bordercolor = color; \
;			GrSetWMProperties(wid, &props); \
;		}

%macro GrSetWindowTitle 2.nolist
	sub esp, byte GR_WM_PROPERTIES_size
	push edi
	mov edi, esp		;edi now ptr to our GR_WM_PROPERTIES struc
	mov [edi + GR_WM_PROPERTIES.flags], dword GR_WM_FLAGS_TITLE
	mov [edi + GR_WM_PROPERTIES.title], dword %2
	push eax
	mov eax, %1
	call GrSetWMProperties
	pop eax
	add esp, byte GR_WM_PROPERTIES_size
	pop edi
%endmacro

#define GrSetWindowTitle(wid,name) \
		{	GR_WM_PROPERTIES props;	\
			props.flags = GR_WM_FLAGS_TITLE; \
			props.title = (GR_CHAR *)name; \
			GrSetWMProperties(wid, &props); \
		}

;#ifdef __cplusplus
;}
;#endif


;/* client side event queue (client.c local)*/
struc event_list
.next:	resd	1
.event:	resGR_EVENT
endstruc

%macro EVENT_LIST  0.nolist
   istruc event_list
   iend 
%macro

%macro EVENT_LIST 2.nolist
   istruc event_list
   at event_list.next, 	dd	%1
   at event_list.event, resGR_EVENT %2
   iend
%endstruc

;typedef struct event_list EVENT_LIST;
;struct event_list {
;	EVENT_LIST *	next;
;	GR_EVENT	event;
;};

struc _REQ_BUF
.bufptr:	resd 1
.bufmax:	resd 1
.buffer:	resd 1
endstruc

%macro REQ_BUF 0.nolist 
   istruc _REQ_BUF
   iend
%endmacro

%macro REQ_BUF 3.nolist
   istruc _REQ_BUF
   at _REQ_BUF.bufptr, 	dd  %1
   at _REQ_BUF.bufmax,  dd  %2
   at _REQ_BUF.buffer,  dd  %3
   iend
%endmacro

;/* queued request buffer (nxproto.c local)*/
;typedef struct {
;	unsigned char *bufptr;		/* next unused buffer location*/
;	unsigned char *bufmax;		/* max buffer location*/
;	unsigned char *buffer;		/* request buffer*/
;} REQBUF;



;%endif ;/* _NANO_X_H*/
