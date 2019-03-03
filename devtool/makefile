# $Header: /cvsroot/uuu/devtool/makefile,v 1.1.1.1 2002/11/29 23:48:12 instinc Exp $

#specify te c compiler to use. If you intend to use another c-compiler, also 
#check the flags
CC=gcc
export CC


# This defines the directory where the devtools lie. For now, it is assumed to be
# the current directory, because the makefile lies there.
DEVTOOLDIR = $(CURDIR)/
export DEVTOOLDIR


#If you need include files other than the standard ones, specify the directory here
INCLUDES=$(DEVTOOLDIR)/include/
export INCLUDES


#The flags for the c compiler
CFLAGS= -Wall -O3 -I$(INCLUDES)
export CFLAGS


#by default, tools will be installed in $(PREFIX)/bin
PREFIX=/usr/local
export PREFIX



# This defines what devtools need to be compiled and installed.
#
# A friendly note to developers: if you add a devtool to the CVS makefile and it
# is broken, I'll slow you down with my VESA cell! :-)
DEVTOOLS = \
u3fd_gen \
elf2ubf \
u3l


# *** nothing below this line should have to be modified ***


.PHONY: build_apps


build_apps:
	echo $(CURDIR)
	@$(foreach dir,$(DEVTOOLS),$(MAKE) -C $(DEVTOOLDIR) -C $(dir);)
	
install: build_apps
	@$(foreach dir,$(DEVTOOLS),$(MAKE) -C $(DEVTOOLDIR) -C $(dir) install;)


.PHONY: $(DEVTOOLS)

$(DEVTOOLS):
	@$(MAKE) --directory $(DEVTOOLDIR)$@

.PHONY: clean

clean:
	@$(foreach dir,$(DEVTOOLS),$(MAKE) -C $(DEVTOOLDIR) -C $(dir) clean;)
