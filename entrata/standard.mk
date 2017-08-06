#############################################################################
#
# Generic Makefile for C/C++ Program
#
# Author: Alessio Colombo
# Date:    2012/09/21: file has been simplified and improved
#
# License: GPL (General Public License)
# Author:  whyglinux <whyglinux AT gmail DOT com>
# Date:    2006/03/04 (version 0.1)
#          2007/03/24 (version 0.2)
#          2007/04/09 (version 0.3)
#          2007/06/26 (version 0.4)
#          2008/04/05 (version 0.5)
#
# Description:
# ------------
# This is an easily customizable makefile template. The purpose is to
# provide an instant building environment for C/C++ programs.
#
# It searches all the C/C++ source files in the specified directories,
# makes dependencies, compiles and links to form an executable.
#
# Besides its default ability to build C/C++ programs which use only
# standard C/C++ libraries, you can customize the Makefile to build
# those using other libraries. Once done, without any changes you can
# then build programs using the same or less libraries, even if source
# files are renamed, added or removed. Therefore, it is particularly
# convenient to use it to build codes for experimental or study use.
#
# GNU make is expected to use the Makefile. Other versions of makes
# may or may not work.
#
# Usage:
# ------
# 1. Copy the Makefile to your program directory.
# 2. Customize in the "Customizable Section" only if necessary:
#    * to use non-standard C/C++ libraries, set pre-processor or compiler
#      options to <MY_CFLAGS> and linker ones to <MY_LIBS>
#      (See Makefile.gtk+-2.0 for an example)
#    * to search sources in more directories, set to <SRCDIRS>
#    * to specify your favorite program name, set to <PROGRAM>
# 3. Type make to start building your program.
#
# Make Target:
# ------------
# The Makefile provides the following targets to make:
#   $ make           compile and link
#   $ make NODEP=yes compile and link without generating dependencies
#   $ make objs      compile only (no linking)
#   $ make tags      create tags for Emacs editor
#   $ make ctags     create ctags for VI editor
#   $ make clean     clean objects and the executable file
#   $ make distclean clean objects, the executable and dependencies
#   $ make help      get the usage of the makefile
#
#===========================================================================

## Customizable Section: adapt those variables to suit your program.
##==========================================================================

# load zmq layer
include ../common/zmq.mk
include ../common/cpp_readline.mk
# log off
L=@
# log on
#L=


## Implicit Section: change the following only when necessary.
##==========================================================================

# The source file types (headers excluded).
# c indicates C source files, and others C++ ones.
SRCEXTS = cpp cc #C cc c CPP c++ cxx cp

# The header file types.
HDREXTS = h hpp #H hh hpp HPP h++ hxx hp

# The pre-processor and compiler options.
# Users can override those variables from the command line.
CFLAGS   = -std=c++17 -O3
CXXFLAGS = -std=c++17    

# The C program compiler.
#CC     = gcc

# The C++ program compiler.
CXX = g++


# Un-comment the following line to compile C programs as C++ ones.
CC = $(CXX)

# The command used to delete file.
#RM  = rm -f

ETAGS = etags
ETAGSFLAGS =

CTAGS = ctags
CTAGSFLAGS =

## Stable Section: usually no need to be changed. But you can add more.
##==========================================================================
  
SHELL   = /bin/sh
EMPTY   =
SPACE   = $(EMPTY) $(EMPTY)
ifeq ($(PROGRAM),)
	CUR_PATH_NAMES = $(subst /,$(SPACE),$(subst $(SPACE),_,$(CURDIR)))
	PROGRAM = $(word $(words $(CUR_PATH_NAMES)),$(CUR_PATH_NAMES))
	ifeq ($(PROGRAM),)
		PROGRAM = a.out
	endif
endif
ifeq ($(SRCDIRS),)
	SRCDIRS = .
endif

SOURCES = $(foreach d,$(SRCDIRS),$(wildcard $(addprefix $(d)/*.,$(SRCEXTS))))
HEADERS = $(foreach d,$(SRCDIRS),$(wildcard $(addprefix $(d)/*.,$(HDREXTS))))
SRC_CXX = $(filter-out %.c,$(SOURCES))
OBJS    = $(addsuffix .o, $(basename $(SOURCES)))
DEPS    = $(OBJS:.o=.d)

## Define some useful variables.
DEP_OPT = $(shell if `$(CC) --version | grep "GCC" >/dev/null`; then \
                  echo "-MM"; else echo "-M"; fi )
DEPENDC     = $(CC)  $(DEP_OPT)  $(MY_CFLAGS) $(CFLAGS)
DEPENDC.d   = $(subst -g ,,$(DEPENDC))
DEPENDCXX   = $(CXX)  $(DEP_OPT)  $(MY_CFLAGS) $(CXXFLAGS) $(CPPFLAGS)
DEPENDCXX.d = $(subst -g ,,$(DEPENDCXX))
COMPILE.c   = $(CC)  $(MY_CFLAGS) $(CFLAGS)   $(CPPFLAGS) -c
COMPILE.cxx = $(CXX) $(MY_CFLAGS) $(CXXFLAGS) $(CPPFLAGS) -c
LINK.c      = $(CC)  $(MY_CFLAGS) $(CFLAGS)   $(CPPFLAGS) $(LDFLAGS)
LINK.cxx    = $(CXX) $(MY_CFLAGS) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS)

# rule to generate dependency files .d
define dependency_rule
%.d:%.$(1)
	@echo '[DEPS $(1)]' $$@
ifeq ($(SRC_CXX),)              # C program  
	$(L)$(DEPENDC.d) $$< >> $$@
else                            # C++ program
	$(L)$(DEPENDCXX.d) $$< >> $$@
endif	
endef    

# rule to generate object files .o
define object_rule
%.o:%.$(1)    
	@echo '[$(1)]' $$@
ifeq ($(SRC_CXX),)              # C program
	$(L)$(COMPILE.c) $$< -o $$@
else                            # C++ program
	$(L)$(COMPILE.cxx) $$< -o $$@
endif
endef  

.PHONY: all objs tags ctags clean distclean help show

# Delete the default suffixes
.SUFFIXES:

all: $(PROGRAM)
# Rules for creating dependency files (.d).
# automatically create rule for each file extension
#------------------------------------------
$(foreach EXT,$(SRCEXTS),$(eval $(call dependency_rule,$(EXT))))

objs: $(OBJS)
# Rules for generating object files (.o).
# automatically create rule for each file extension
#------------------------------------------
$(foreach EXT,$(SRCEXTS),$(eval $(call object_rule,$(EXT))))

# Rules for generating the tags.
#-------------------------------------
tags: $(HEADERS) $(SOURCES)
	$(ETAGS) $(ETAGSFLAGS) $(HEADERS) $(SOURCES)

ctags: $(HEADERS) $(SOURCES)
	$(CTAGS) $(CTAGSFLAGS) $(HEADERS) $(SOURCES)

# Rules for generating the executable.
#-------------------------------------
$(PROGRAM):$(OBJS)
ifeq ($(SRC_CXX),)              # C program
	@echo '[LINK.c]' $@
	$(L)$(LINK.c)   $(OBJS) $(MY_LIBS) -o $@
	@echo Type ./$@ to execute the program.
else                            # C++ program
	@echo '[LINK.cxx]' $@
	$(L)$(LINK.cxx) $(OBJS) $(MY_LIBS) -o $@
	@echo Type ./$@ to execute the program.
endif

clean:
	$(RM) $(OBJS) $(PROGRAM)

distclean: clean
	$(RM) $(DEPS) $(TAGS)

# Show help.
help:
	@echo 'Generic Makefile for C/C++ Programs (gcmakefile) version 0.5'
	@echo 'Copyright (C) 2007, 2008 whyglinux <whyglinux@hotmail.com>'
	@echo
	@echo 'Usage: make [TARGET]'
	@echo 'TARGETS:'
	@echo '  all       (=make) compile and link.'
	@echo '  NODEP=yes make without generating dependencies.'
	@echo '  objs      compile only (no linking).'
	@echo '  tags      create tags for Emacs editor.'
	@echo '  ctags     create ctags for VI editor.'
	@echo '  clean     clean objects and the executable file.'
	@echo '  distclean clean objects, the executable and dependencies.'
	@echo '  show      show variables (for debug use only).'
	@echo '  help      print this message.'
	@echo
	@echo 'Report bugs to <whyglinux AT gmail DOT com>.'

# Show variables (for debug use only.)
show:
	@echo 'PROGRAM     :' $(PROGRAM)
	@echo 'SRCDIRS     :' $(SRCDIRS)
	@echo 'HEADERS     :' $(HEADERS)
	@echo 'SOURCES     :' $(SOURCES)
	@echo 'SRC_CXX     :' $(SRC_CXX)
	@echo 'OBJS        :' $(OBJS)
	@echo 'DEPS        :' $(DEPS)
	@echo 'DEPENDC     :' $(DEPENDC)
	@echo 'DEPENDC.d   :' $(DEPENDC.d)	
	@echo 'DEPENDCXX   :' $(DEPENDCXX)
	@echo 'DEPENDCXX.d :' $(DEPENDCXX.d)	
	@echo 'COMPILE.c   :' $(COMPILE.c)
	@echo 'COMPILE.cxx :' $(COMPILE.cxx)
	@echo 'link.c      :' $(LINK.c)
	@echo 'link.cxx    :' $(LINK.cxx)

## End of the Makefile ##  Suggestions are welcome  ## All rights reserved ##
#############################################################################
# DO NOT DELETE
