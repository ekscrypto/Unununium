; $Header: /cvsroot/uuu/existence/include/errors.inc,v 1.4 2003/01/11 22:11:43 instinc Exp $

%ifndef __ERRORS_INC__
%define __ERRORS_INC__

%macro def_err 3.nolist
__ERROR__%{1}__ EQU (%{2} << 16)+%{3}
%endmacro

%macro set_err 2.nolist
  mov %{1}, __ERROR__%{2}__
%endmacro


def_err 	UNSUPPORTED_OPTION	,0	,1
def_err		INVALID_PARAMETERS	,0	,2
def_err		INTERNAL_FAILURE	,0	,3
def_err		OUT_OF_MEMORY		,0	,4
def_err		OUT_OF_THREADS		,1	,1
def_err		FAILED_SCHEDULING	,1	,2
def_err		LOCK_FAILED		,1	,3

%endif
