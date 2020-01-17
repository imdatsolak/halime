# Generated automatically from Makefile.in by configure.
#
#
# ============================================================================
#
# Makefile for the Tcl/Tk stuff of UUDeview
#
# ============================================================================
#
# $Id: Makefile.in,v 1.4 2001/06/04 16:26:57 fp Exp $
#
# your make might need this
#
SHELL	=	/bin/sh
# 
# Source and Installation Paths
#
prefix	=	/usr/local
exec_prefix =	${prefix}
srcdir =	.
#
# Where you want the binaries and the manual pages installed
#
BINDIR	=	${exec_prefix}/bin
MANDIR	=	${prefix}/man
#
# install program. use our own, as AC_PROG_INSTALL doesn't work reliably
#
INSTALL	=		./install-sh
INSTALL_PROGRAM =	${INSTALL} -c
INSTALL_DATA =		${INSTALL} -c -m 644
#
# If you don't have the GNU C compiler installed, set CC=cc here
#
CC	=	gcc
#
# C Compiler Options
#
CFLAGS	=	-D_REENTRANT -g -O2 -I.   -DHAVE_CONFIG_H
#
# Libraries to link and their paths
#
LIBS	=	    -lpthread -framework CoreFoundation 
#
# the ranlib program
#
RANLIB =	ranlib
#
# shared library stuff, if available. not yet active. i first need to
# find someone who can really explain this to me.
#
SHLIB_CFLAGS =	@SHLIB_CFLAGS@
SHLIB_LD =	@SHLIB_LD@
SHLIB_SUFFIX =	@SHLIB_SUFFIX@
SHLIB_VERSION =	@SHLIB_VERSION@
#
###############################################################################
# You shouldn't have to change anything below.
###############################################################################
#

#

SOURCE	=	uuwish.c uutcl.c
OBJ	=	${SOURCE:.c=.o}

#
# make stuff
#

.SUFFIXES:
.SUFFIXES: .c .o

all:		uuwish xdeview

clean:
	rm -f uuwish
	rm -f *.o *.a *.so core *~ TAGS

distclean:	clean
	rm -f config.status config.cache config.log Makefile config.h
	rm -f uudeview-*tar* uudeview-sfx

realclean:	distclean

install: 	all
	for d in $(PROGS) ; do \
		$(INSTALL_PROGRAM) $(srcdir)/$$d $(BINDIR)/$$d ; \
	done
	-for d in $(MPAGES) ; do \
		$(INSTALL_DATA) $(srcdir)/$$d $(MANDIR)/man1/$$d ; \
	done

new:		clean
	rm -f uuwish
	make all

uuwish:		$(OBJ) ../uulib/libuu.a
	$(CC) -o $@ $(OBJ) -L../uulib -luu $(LIBS)

xdeview:
	chmod 755 $@

.c.o:
	$(CC) -c $(CFLAGS) -I../uulib $(VDEF) $<

uuwish.o:	uuwish.c config.h
uutcl.o:	uutcl.c config.h

