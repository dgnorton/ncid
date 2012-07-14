# This Makefile requires either GNU make or BSD make
# Last Modified by jlc on Fri Jul 13, 202

###########################################################################
# make local             - builds for /usr/local and /var                 #
# make install           - installs files in /usr/local and /var          #
#                                                                         #
# make package           - builds for /usr, /etc, and /var                #
# make package-install   - installs files in /usr, /etc, and /var         #
#                                                                         #
# make fedora            - builds for Fedora (includes init.d/ files)     #
# make fedora-install    - installs in /usr, /etc, and /var               #
#                                                                         #
# make ubuntu            - builds for Ubuntu (includes init.d/ files)     #
# make ubuntu-install    - installs in /usr, /etc, and /var               #
#                                                                         #
# make mandir            - builds man text and html files                 #
#                          (no install for the *.txt and *.html files)    #
#                                                                         #
# make tivo-mips         - builds for a mips TiVo in /usr/local or prefix #
#                          can also prefix and prefix[234]                #
# make tivo-install      - installs in /usr/local                         #
#                          can also prefix and prefix[234]                #
# make tivo-s1           - builds for a ppc TiVo for /var/hack            #
# make tivo-s2           - builds for a mips TiVo for /var/hack           #
# make tivo-hack-install - basic install into /var/hack                   #
#                          uses the cross compilers at:                   #
#                          http://tivoutils.sourceforge.net/              #
#                          usr.local.powerpc-tivo.tar.bz2                 #
#                          (x86 cross compiler for Series1)               #
#                          usr.local.mips-tivo.tar.bz2                    #
#                          (x86 cross compiler for Series2)               #
#                                                                         #
# make freebsd           - builds for FreeBSD in /usr/local               #
# make freebsd-install   - installs in /usr/local                         #
#                                                                         #
# make mac               - builds for Macintosh OS X in /usr/local        #
# make mac-fat           - builds universal OS X binaries in /usr/local   #
# make mac-install       - installs in /usr/local                         #
#                                                                         #
# make cygwin            - builds for Windows using cygwin                #
#                          (does not function with modem or comm port)    #
# make cygwin-install    - installs files in /usr/local, and /var         #
###########################################################################

subdirs      = server client cidgate modules scripts tools man test \
               debian Fedora FreeBSD TiVo

Version := $(shell sed 's/.* //; 1q' VERSION)

# the prefix must end in a - (if part of a name) or a / (if part of a path)
MIPSXCOMPILE = mips-TiVo-linux-
PPCXCOMPILE  = /usr/local/tivo/bin/

# prefix and prefix2 are used on a make, install, and making a package
# prefix3 is used on install to make a package
prefix       = /usr/local
prefix2      = $(prefix)
prefix3      =

settag       = NONE
setlock      = NONE
setname      = NONE
setmod       = NONE

BIN          = $(prefix)/bin
SBIN         = $(prefix)/sbin
SHARE        = $(prefix)/share
ETC          = $(prefix2)/etc
DEV          = $(prefix3)/dev
VAR          = $(prefix3)/var

CONFDIR      = $(ETC)/ncid
MODULEDIR    = $(SHARE)/ncid
IMAGEDIR	 = $(SHARE)/pixmaps/ncid
MAN          = $(SHARE)/man
LOG          = $(VAR)/log
RUN          = $(VAR)/run

CONF         = $(CONFDIR)/ncidd.conf
ALIAS        = $(CONFDIR)/ncidd.alias
MODEMDEV     = $(DEV)/modem
CALLLOG      = $(LOG)/cidcall.log
DATALOG      = $(LOG)/ciddata.log
LOGFILE      = $(LOG)/ncidd.log
PIDFILE      = $(RUN)/ncidd.pid

WISH         = wish
TCLSH        = tclsh

# local additions to CFLAGS
MFLAGS  = -W -Wmissing-declarations \

default:
	@echo "make requires an argument, see top of Makefile for description:"
	@echo
	@echo "    make local              # builds for /usr/local and /var"
	@echo "    make install            # installs into /usr/local and /var"
	@echo "    make package            # builds for /usr and /var"
	@echo "    make package-install    # installs into for /usr and /var"
	@echo "    make fedora             # builds for Fedora, includes init.d/"
	@echo "    make fedora-install     # installs in /usr, /etc, and /var"
	@echo "    make ubuntu             # builds for Ubuntu, includes init.d/"
	@echo "    make ubuntu-install     # installs in /usr, /etc, and /var"
	@echo "    make tivo-mips          # builds for TiVo in /usr/local, /var"
	@echo "    make tivo-install       # installs in /usr/local, /var"
	@echo "    make tivo-s1            # builds for a series1 in /var/hack"
	@echo "    make tivo-s2            # builds for a series[23] in /var/hack"
	@echo "    make tivo-hack-install  # installs in /var/hack, /var"
	@echo "    make freebsd            # builds for FreeBSD in /usr/local, /var"
	@echo "    make freebsd-install    # installs in /usr/local, /var"
	@echo "    make mac                # builds for Mac in /usr/local, /var"
	@echo "    make mac-fat            # builds for Mac in /usr/local, /var"
	@echo "    make mac-install        # installs in /usr/local, /var"
	@echo "    make cygwin             # builds for windows using Cygwin"
	@echo "    make cygwin-install     # installs in /usr/local"

local: serverdir clientdir moduledir cidgatedir tooldir scriptsdir

version.h: version.h-in
	sed "s/XXX/$(Version)/" $? > $@

fedoradir:
	cd Fedora; $(MAKE) init service prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

freebsddir:
	cd FreeBSD; $(MAKE) rcd prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

ubuntudir:
	cd debian; $(MAKE) init prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

tivodir:
	cd TiVo; $(MAKE) prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
                     OSDCLIENT=$(OSDCLIENT)

moduledir:
	cd modules; $(MAKE) modules prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

cidgatedir:
	cd cidgate; $(MAKE) cidgate prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3) BIN=$(BIN) SBIN=$(SBIN) \
                      MFLAGS="$(MFLAGS)" STRIP=$(STRIP)

serverdir:
	cd server; $(MAKE) server prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3) BIN=$(BIN) SBIN=$(SBIN) \
                      MFLAGS="$(MFLAGS)" STRIP=$(STRIP)

clientdir:
	cd client; $(MAKE) client prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3) BIN=$(BIN) SBIN=$(SBIN) \
                      MFLAGS="$(MFLAGS)" STRIP=$(STRIP)

tooldir:
	cd tools; $(MAKE) tools prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3) BIN=$(BIN)

scriptsdir:
	cd scripts; $(MAKE) scripts prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

mandir:
	cd man; $(MAKE) all prefix=$(prefix) prefix2=$(prefix2) MAN=$(MAN)

package:
	$(MAKE) local prefix=/usr prefix2=

package-install:
	$(MAKE) install prefix=/usr prefix2=

fedora:
	$(MAKE) local fedoradir prefix=/usr prefix2= \
            LOCKFILE=/var/lock/lockdev/LCK..

fedora-install:
	$(MAKE) install install-fedora prefix=/usr prefix2=

ubuntu:
	$(MAKE) local ubuntudir prefix=/usr prefix2= \
            LOCKFILE=/var/lock/LCK..

ubuntu-install:
	$(MAKE) install install-ubuntu prefix=/usr prefix2=

tivo-s1:
	$(MAKE) tivo-ppc mandir prefix=/var/hack

tivo-ppc:
	$(MAKE) local tivodir \
			CC=$(PPCXCOMPILE)gcc \
			MFLAGS="-DTIVO_S1 -D__need_timeval" \
			LD=$(PPCXCOMPILE)ld \
			RANLIB=$(PPCXCOMPILE)ranlib \
			setname="TiVo requires CLOCAL" \
			settag="TiVo PPC Modem Port" \
			setlock="TiVo Modem Lockfile" \
			setmod="out2osd" OSDCLIENT=tivocid

tivo-s2:
	$(MAKE) tivo-mips mandir prefix=/var/hack

tivo-hack-install:
	$(MAKE) install-server install-client \
            install-modules install-cidgate install-tivo

tivo-mips:
	$(MAKE) local tivodir fedoradir \
			CC=$(MIPSXCOMPILE)gcc \
			MFLAGS="-std=gnu99" \
			LD=$(MIPSXCOMPILE)ld \
			RANLIB=$(MIPSXCOMPILE)ranlib \
			setname="TiVo requires CLOCAL" \
			settag="TiVo MIPS Modem Port" \
			setlock="TiVo Modem Lockfile" \
			setmod="ncid-tivo" OSDCLIENT=tivoncid

tivo-install:
	$(MAKE) install-server install-client install-modules install-cidgate \
              install-man install-scripts #install-fedora setmod=tivo

freebsd:
	$(MAKE) local freebsddir prefix=/usr/local prefix2=$(prefix) \
            LOCKFILE=/var/spool/lock/LCK.. \
            WISH=/usr/local/bin/wish*.* TCLSH=/usr/local/bin/tclsh*.* \
            BASH=/usr/local/bin/bash

freebsd-install:
	$(MAKE) install MAN=$(prefix)/man
	cd FreeBSD; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
            MAN=$(prefix)/man

mac-fat:
	$(MAKE) local settag="Macintosh OS X" \
            LOCKFILE=/var/spool/uucp/LCK.. \
            MFLAGS="-mmacosx-version-min=10.3.9 -arch ppc" STRIP=
	mv server/ncidd server/ncidd.ppc-mac
	mv cidgate/sip2ncid cidgate/sip2ncid.ppc-mac
	mv cidgate/ncid2ncid cidgate/ncid2ncid.ppc-mac
	$(MAKE) clean
	$(MAKE) local settag="Macintosh OS X" \
            LOCKFILE=/var/spool/uucp/LCK.. \
            MFLAGS="-mmacosx-version-min=10.4 -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk" STRIP=
	mv server/ncidd server/ncidd.i386-mac
	mv cidgate/sip2ncid cidgate/sip2ncid.i386-mac
	mv cidgate/ncid2ncid cidgate/ncid2ncid.i386-mac
	lipo -create server/ncidd.ppc-mac server/ncidd.i386-mac \
         -output server/ncidd
	lipo -create cidgate/sip2ncid.ppc-mac cidgate/sip2ncid.i386-mac \
         -output cidgate/sip2ncid
	lipo -create cidgate/ncid2ncid.ppc-mac cidgate/ncid2ncid.i386-mac \
         -output cidgate/ncid2ncid

mac:
	$(MAKE) local settag="Macintosh OS X" \
            LOCKFILE=/var/spool/uucp/LCK.. \
            MFLAGS="-mmacosx-version-min=10.4" STRIP=

mac-install:
	$(MAKE) install MAN=$(prefix)/man

cygwin:
	$(MAKE) local \
            MFLAGS=-IC:/WpdPack/Include \
            LDLIBS="-s -LC:/WpdPack/Lib -lwpcap" \
            SBIN=$(prefix)/bin \
            settag="set noserial" \
            MODEMDEV=$(DEV)/com1

cygwin-install:
	$(MAKE) install \
            SBIN=$(prefix)/bin \
            settag="set noserial" \
            MODEMDEV=$(DEV)/com1

install: install-server install-client install-man \
         install-modules install-cidgate install-scripts install-tools

install-fedora:
	cd Fedora; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-ubuntu:
	cd debian; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-tivo:
	cd TiVo; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-cidgate:
	cd cidgate; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-modules:
	cd modules; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
			setmod=$(setmod)

install-scripts:
	cd scripts; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-tools:
	cd tools; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) ALIAS=$(ALIAS)

install-man:
	cd man; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) MAN=$(MAN)

install-server:
	cd server; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-client:
	cd client; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

clean:
	for i in $(subdirs); do cd $$i; $(MAKE) clean; cd ..; done

clobber: clean
	rm -f version.h a.out *.log *.zip *.tar.gz *.tgz
	for i in $(subdirs); do cd $$i; $(MAKE) clobber; cd ..; done

distclean: clobber

files: $(FILES)

.PHONY: local ppc-tivo mips-tivo install install-proc \
        install-scripts install-man install-var clean clobber files
