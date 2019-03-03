	struc config_entry
.next:		resd 1
.ram:		resd 1
.root:		resb 32
.label:		resb 32
.filename:	resb 128
	endstruc
