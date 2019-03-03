;; Dummy Guest FS cell

section .text

_mount:
  stc
  retn


;section .c_init
global __init_entry_point
__init_entry_point:

  mov edx, __FS_TYPE_EXT2__
  mov eax, _mount
  externfunc vfs.register_fs_driver
  retn

  
