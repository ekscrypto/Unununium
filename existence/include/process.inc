; $Header: /cvsroot/uuu/existence/include/process.inc,v 1.5 2003/01/12 02:55:09 instinc Exp $


struc process_info
  .stdin:	resd 1
  .stdout:	resd 1
  .stderr:	resd 1
  .env:		resd 1	; ptr to the environment
  .argv:	resd 1	; ptr to orig. argv used
  .cleanup:	resd 1	; ptr to cleanup info; used by process.exec
  .padding:	resd 2
endstruc

