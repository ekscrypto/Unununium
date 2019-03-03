; $Header: /cvsroot/uuu/dimension/include/errors.inc,v 1.1.1.1 2002/01/17 04:31:40 instinc Exp $
; vim: syntax=uuu

%ifdef __GLOBALINCLUDE__
  %error "Trying to include error_codes.inc twice. Aborting."
%else

  ;=- declare control constant -=
  %define __GLOBALINCLUDE__

  ;=- declare all other system constants -=
  %define __ERROR_UNSUPPORTED_OPTION__		1
  %define __ERROR_INVALID_PARAMETERS__		2
  %define __ERROR_INSUFFICIENT_MEMORY__		3
  %define __ERROR_INTERNAL_FAILURE__		4
  %define __ERROR_INVALID_FILESYSTEM__		5
  %define __ERROR_FS_INVALID_FILENAME__		6
  %define __ERROR_FS_NOT_A_DIRECTORY__		7
  %define __ERROR_FS_NOT_A_FILE__		8
  %define __ERROR_FS_ACCESS_DENIED__		9
  %define __ERROR_FS_OUT_OF_SPACE__		10
  %define __ERROR_FS_DAMAGED_FILE__		11
  %define __ERROR_FS_END_OF_FILE_REACHED__	12
  %define __ERROR_FS_INVALID_OR_CORRUPTED_FS__	13
  %define __ERROR_DEV_REGISTRATION_FAILED__	14
  %define __ERROR_DEV_NOT_DETECTED__		15
  %define __ERROR_DEV_TIMEOUT__			16
  %define __ERROR_FILE_NOT_FOUND__		17
  %define __ERROR_OPERATION_NOT_SUPPORTED__	18
  %define __ERROR_FILE_EXISTS__			19
  %define __ERROR_VID_EXISTS__			20
  %define __ERROR_UNKNOWN_FS_TYPE__		21
  %define __ERROR_VID_NOT_FOUND__		22
  %define __ERROR_UBF_BAD_SECTION_TYPE__	23
  %define __ERROR_GDT_FULL__			24
  %define __ERROR_FS_TYPE_ALREADY_REGISTERED__	25
  %define __ERROR_ENV_VAR_NOT_FOUND__		26
  %define __ERROR_NO_SUCH_CONSOLE__		27
  

%endif	; else __GLOBALINCLUDE__
