; Unununium Kernel

struc infoblock_memory
.process		resd 1
.process_next_infoblock	resd 1
.base			resd 1
.size			resd 1
endstruc

struc infoblock_process
.thread_count		resd 1
.first_thread		resd 1
endstruc

struc infoblock_thread
.process		resd 1
.process_next_infoblock	resd 1
.esp			resd 1
endstruc

%define MAX_SYMBOL_NAME_LENGTH 56
struc infoblock_symbol
.value			resd 1
.name			resd 0
.name_max_size		resw 1
.name_size		resw 1
.name			resb MAX_SYMBOL_NAME_LENGTH
endstruc


