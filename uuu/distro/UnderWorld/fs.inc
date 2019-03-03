__lame_fs_start__:

 _fstab:
 db ".fstab"
 align 16, db 0
 dd _fstab - $$
 dd _fstab.size
 dd 0,.file0001
 
 .file0001:
 db "somefile"
 align 16, db 0
 dd (_file0001 - $$) / 512
 dd _file0001.size
 dd 0,.file0002

 .file0002:
 db "otherfile"
 align 16, db 0
 dd (_file0002 - $$) / 512
 dd _file0002.size
 dd 0,-1

 .size:
 align 512, db 0

_file0001:
 incbin "cell01"
 .size:
 align 512, db 0

_file0002:
 incbin "cell02"
 .size:
 align 512, db 0

__lame_fs_end__:

