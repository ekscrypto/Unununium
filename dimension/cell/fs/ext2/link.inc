

inode_link:
  ; TODO: alot
  ; ESI = pointer to filename
  ; EDI = pointer to directory entry
  call __strlen.c_dword_aligned_null_terminated
  ; ECX = string length
  
