struc VbeInfoBlock
	.VbeSignature: 		resd 1 		; VBE Signature
	.VbeVersion: 		resw 1 		; VBE Version
	.OemStringPtr: 		resd 1 		; VbeFarPtr to OEM String
	.Capabilities: 		resb 4 		; Capabilities of graphics controller
	.VideoModePtr: 		resd 1 		; VbeFarPtr to VideoModeList
	.TotalMemory: 		resw 1 		; Number of 64kb memory blocks
	.OemSoftwareRev:	resw 1 		; VBE implementation Software revision
	.OemVendorNamePtr: 	resd 1 		; VbeFarPtr to Vendor Name String
	.OemProductNamePtr: resd 1 		; VbeFarPtr to Product Name String
	.OemProductRevPtr: 	resd 1 		; VbeFarPtr to Product Revision String
	.Reserved: 			resb 222   	; Reserved for VBE implementation scratch
	.OemData: 			resb 256  	; Data Area for OEM Strings
endstruc




struc ModeInfoBlock 
; Mandatory information for all VBE revisions
	.ModeAttributes: 		resw 1; mode attributes
	.WinAAttributes: 		resb 1 ; window A attributes
	.WinBAttributes: 		resb 1 ; window B attributes
	.WinGranularity: 		resw 1 ; window granularity
	.WinSize: 				resw 1 ; window size
	.WinASegment: 			resw 1 ; window A start segment
	.WinBSegment: 			resw 1 ; window B start segment
	.WinFuncPtr: 			resd 1 ; real mode pointer to window function
	.BytesPerScanLine: 		resw 1 ; bytes per scan line

; Mandatory information for VBE 1.2 and above
	.XResolution: 			resw 1 ; horizontal resolution in pixels or characters3
	.YResolution: 			resw 1 ; vertical resolution in pixels or characters
	.XCharSize: 			resb 1 ; character cell width in pixels
	.YCharSize: 			resb 1 ; character cell height in pixels
	.NumberOfPlanes: 		resb 1 ; number of memory planes
	.BitsPerPixel: 			resb 1 ; bits per pixel
	.NumberOfBanks:			resb 1 ; number of banks
	.MemoryModel: 			resb 1 ; memory model type
	.BankSize:				resb 1 ; bank size in KB
	.NumberOfImagePages:	resb 1 ; number of images
	.Reserved0: 			resb 1 ; reserved for page function

; Direct Color fields (required for direct/6 and YUV/7 memory models)
	.RedMaskSize: 			resb 1 ; size of direct color red mask in bits
	.RedFieldPosition: 		resb 1 ; bit position of lsb of red mask
	.GreenMaskSize: 		resb 1 ; size of direct color green mask in bits
	.GreenFieldPosition: 	resb 1 ; bit position of lsb of green mask
	.BlueMaskSize: 			resb 1 ; size of direct color blue mask in bits
	.BlueFieldPosition:		resb 1 ; bit position of lsb of blue mask
	.RsvdMaskSize: 			resb 1 ; size of direct color reserved mask in bits
	.RsvdFieldPosition: 	resb 1 ; bit position of lsb of reserved mask
	.DirectColorModeInfo: 	resb 1 ; direct color mode attributes

; Mandatory information for VBE 2.0 and above
	.PhysBasePtr: 			resd 1 ; physical address for flat memory frame buffer
	.Reserved1: 			resd 1 ; Reserved - always set to 0
	.Reserved2: 			resd 1 ; Reserved - always set to 0

; Mandatory information for VBE 3.0 and above
	.LinBytesPerScanLine: 	resw 1 ; bytes per scan line for linear modes
	.BnkNumberOfImagePages:	resb 1 ; number of images for banked modes
	.LinNumberOfImagePages:	resb 1 ; number of images for linear modes
	.LinRedMaskSize: 		resb 1 ; size of direct color red mask (linear modes)
	.LinRedFieldPosition: 	resb 1 ; bit position of lsb of red mask (linear modes)
	.LinGreenMaskSize: 		resb 1 ; size of direct color green mask (linear modes)
	.LinGreenFieldPosition:	resb 1 ; bit position of lsb of green mask (linear modes)
	.LinBlueMaskSize: 		resb 1 ; size of direct color blue mask (linear modes)
	.LinBlueFieldPosition: 	resb 1 ; bit position of lsb of blue mask (linear modes)
	.LinRsvdMaskSize:	 	resb 1 ; size of direct color reserved mask (linear modes)
	.LinRsvdFieldPosition: 	resb 1 ; bit position of lsb of reserved mask (linear modes)
	.MaxPixelClock: 		resd 1 ; maximum pixel clock (in Hz) for graphics mode
	.Reserved5:				resb 189
endstruc
