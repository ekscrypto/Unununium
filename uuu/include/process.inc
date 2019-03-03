; $Header: /cvsroot/uuu/uuu/include/process.inc,v 1.3 2001/12/18 02:00:20 daboy Exp $

struc process_info
  .stdin:	resd 1
  .stdout:	resd 1
  .stderr:	resd 1
  .env:		resd 1	; ptr to the environment
  .argv:	resd 1	; ptr to orig. argv used
  .cleanup:	resd 1	; ptr to cleanup info; used by process.exec
endstruc
