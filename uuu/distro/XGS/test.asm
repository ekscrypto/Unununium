; This cell allow you to perform some tests.
;
; Each section is documented, if you have any question, make sure to consult
; the documentation section of our website at http://uuu.sourceforge.net/
;
; Have fun!

[bits 32]

section .c_info
  ;------------
  ; This section is used to give the version number, the cell name, author and
  ; copyrights information.  Some distros will parse this information and build
  ; up a database of the currently loaded cells in the system while some other
  ; distros will simply read this information and discard it.

  ; version:
db 1,0,0,'a'
  ;---------
  ; The version is a 4 bytes combination.
  ; offset 0:  high version number
  ;        1:  mid version number
  ;        2:  low version number
  ;        3:  revision indicator

  ; ptr to cell's name
dd str_cellname
  ;------------
  ; This is a pointer to the string that gives the name and sometime a very
  ; short description of the cell.  This string is encoded in UTF-8 and should
  ; really be kept as short as possible since it's the string that will be used
  ; when a list of all the cells is requested.

  ; ptr to author's name
dd str_author
  ;----------
  ; This is a pionter to the string that gives the author's name or the group's
  ; name.  This string is encoded in UTF-8.  Some ppl might want to coma
  ; separate a list of authors when many have contributed to the work.

  ; ptr to copyrights
dd str_copyrights
  ;--------------
  ; This is a pointer to the string containing the copyrights information. This
  ; string, like the others, is encoded in UTF-8.  It is possible but not
  ; recommended to use this string to hold the entire copyrights license.  A
  ; much more desirable option would be to give an Internet URI to the license
  ; with the license name.

str_cellname: db "Test cell - for learning purposes",0
  ;---------------------------------------------------
  ; This string gives the name and a very short description of this cell. It is
  ; encoded in UTF-8, which preserve/uses the standard US-ASCII character set.

str_author: db "EKS - Dave Poirier (futur@mad.scientist.com)",0
  ;------------------------------------------------------------
  ; This string is used to hold a list of authors.  If many authors have
  ; collaborated on the work and desire to be included, it is possible to
  ; include more names by coma separating each entry.  This is also encoded
  ; using UTF-8.

str_copyrights: db "Not copyrighted",0
  ;-----------------------------------
  ; This string hold the copyright notice or copyright license's name.  Some 
  ; people might want to include the entire copyrights license here but it is a
  ; unrecommended behaviour. As suggested earlier, an internet URI to the entire
  ; license would be more recommendable.

section .c_onetime_init
  ;--------------------
  ; This section contain specific initialization instructions that will be
  ; executed once and discarded, the cell being saved back, if possible, with
  ; the modified content.

  nop

section .c_init
  ;------------
  ; This section contain specific initialization instructions that will be
  ; executed once and discarded every time the cell is loaded in memory.

  nop

section .text
  ;----------
  ; This section '.text' is a special section recognized by most tools as being
  ; a section containing executable code and optionally read-only data.
  ;
  ; The U3Linker and the various cells will treat any name not starting with
  ; a dot exactly the same as a '.text' section.  The difference being that
  ; in our system, a '.text' section may contain not only executable code and
  ; read-only data, but also read-write data.


global __test_function.c_noclass
global FID__test_function
global CID__test_function.c_noclass

FID__test_function equ -50
CID__test_function.c_noclass equ 0

__test_function.c_noclass:

  inc edx
  retn
