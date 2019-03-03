INCPATH = $(CURDIR)/../../include $(CURDIR)/include 
export INCPATH


INCS = \
       macros.inc \
       errors.inc
       

AS = nasm
ASFLAGS = -w+orphan-labels -w+number-overflow -w+macro-params -w+macro-selfref $(addprefix -i,$(INCPATH))$  $(addprefix -p,$(INCS))$
export AS ASFLAGS

LIBDIR = $(CURDIR)/

LIBS = \
 appwrap \
 stdio
 
VPATH = $(INCPATH)
export VPATH

.PHONY: all

all: $(LIBS) 

.PHONY: $(LIBS)
$(LIBS):
	@$(MAKE) --directory $(LIBDIR)$@

.PHONY: clean

clean:
	@$(MAKE) --directory $(LIBDIR)$@	
