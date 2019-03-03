; VESA mode definitions
;
;


struc mode
	.mode:		resd 1		; If 00h, then list finished
	.resx:		resd 1
	.resy:		resd 1
	.colors:	resd 1
	.depth:		resd 1
endstruc

; doesn't contain 4bit-modes!
_modelist:
;  Mode  Res,  	Resy 	Col 	Depth
;---------------------------------------
dd 100h, 640, 	400, 	256,	8 
dd 101h, 640, 	480, 	256,	8   
dd 103h, 800, 	600, 	256,	8   
dd 105h, 1024, 	768, 	256,	8 
dd 107h, 1280, 	1024, 	256,	8
dd 10Eh, 320, 	200, 	65536, 	16 
dd 10Fh, 320, 	200, 	16777216,	24
dd 111h, 640, 	480, 	65536, 	16 
dd 112h, 640, 	480, 	16777216,	24
dd 114h, 800, 	600, 	65536, 	16 
dd 115h, 800, 	600, 	16777216,24 
dd 117h, 1024, 	768, 	65536, 	16
dd 118h, 1024, 	768, 	16777216,	24
dd 11Ah, 1280, 	1024, 	65536, 	16
dd 11Bh, 1280,	1024, 	16777216, 	24
.end_of_modelist:
dd 0

; Let this zero here to confirm zero :)
