# This Makefile requires either GNU make or BSD make
# Last Modified by jlc on Thu Oct 11, 2012

###########################################################################
# make local             - builds for /usr/local and /var                 #
# make install           - installs files in /usr/local and /var          #
#                                                                         #
# make package           - builds for /usr, /etc, and /var                #
# make package-install   - installs files in /usr, /etc, and /var         #
#                                                                         #
# make fedora            - builds for Fedora with service files           #
# make fedora-install    - installs in /usr, /etc, and /var               #
#                                                                         #
# make redhat            - builds for Redhat           with init.d files  #
# make redhat-install    - installs in /usr, /etc, and /var               #
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

subdirs      = server client gateway modules logrotate tools man test \
               debian Fedora FreeBSD Mac TiVo

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
setmac       = NONE
unset        = NONE

BIN          = $(prefix)/bin
SBIN         = $(prefix)/sbin
SHARE        = $(prefix)/share
ETC          = $(prefix2)/etc
DEV          = $(prefix3)/dev
VAR          = $(prefix3)/var

CONFDIR      = $(ETC)/ncid
MODULEDIR    = $(SHARE)/ncid
DOCDIR       = $(SHARE)/doc/ncid
IMAGEDIR	 = $(SHARE)/pixmaps/ncid
MAN          = $(SHARE)/man
LOG          = $(VAR)/log
RUN          = $(VAR)/run

CONF         = $(CONFDIR)/ncidd.conf
ALIAS        = $(CONFDIR)/ncidd.alias
BLACKLIST    = $(CONFDIR)/ncidd.blacklist
WHITELIST    = $(CONFDIR)/ncidd.whitelist
TTYPORT      = $(DEV)/modem
CIDLOG       = $(LOG)/cidcall.log
DATALOG      = $(LOG)/ciddata.log
LOGFILE      = $(LOG)/ncidd.log
PIDFILE      = $(RUN)/ncidd.pid

WISH         = wish
TCLSH        = tclsh

# local additions to CFLAGS
MFLAGS  = -W -Wmissing-declarations \

# Documentation for FreeBSD, Mac, and TiVo
DOC     = doc/[A-HJ-V]* doc/INSTALL \
          server/README.server gateway/README.gateways \
          client/README.client modules/README.modules

default:
	@echo "make requires an argument, see top of Makefile for description:"
	@echo
	@echo "    make local              # builds for /usr/local and /var"
	@echo "    make install            # installs into /usr/local and /var"
	@echo "    make package            # builds for /usr and /var"
	@echo "    make package-install    # installs into for /usr and /var"
	@echo "    make fedora             # builds for Fedora/Redhat with service files/"
	@echo "    make fedora-install     # installs in /usr, /etc, and /var"
	@echo "    make redhat             # builds for Redhat/Fedora, with init files/"
	@echo "    make redhat-install     # installs in /usr, /etc, and /var"
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

local-base: serverdir clientdir moduledir gatewaydir tooldir

local: local-base logrotatedir

version.h: version.h-in
	sed "s/XXX/$(Version)/" $< > $@

fedoradir:
	cd Fedora; $(MAKE) service service prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

redhatdir:
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

macdir:
	cd Mac; $(MAKE) prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

moduledir:
	cd modules; $(MAKE) modules prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3) setmod="$(setmod)" \
                      unset="$(unset)" setmac="$(setmac)"

gatewaydir:
	cd gateway; $(MAKE) gateway prefix=$(prefix) prefix2=$(prefix2) \
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

logrotatedir:
	cd logrotate; $(MAKE) logrotate prefix=$(prefix) prefix2=$(prefix2) \
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

redhat:
	$(MAKE) local redhatdir prefix=/usr prefix2= \
            LOCKFILE=/var/lock/lockdev/LCK..

redhat-install:
	$(MAKE) install install-redhat prefix=/usr prefix2=

ubuntu:
	$(MAKE) local ubuntudir prefix=/usr prefix2= \
            LOCKFILE=/var/lock/LCK..

ubuntu-install:
	$(MAKE) install install-ubuntu prefix=/usr prefix2=

tivo-s1:
	$(MAKE) tivo-ppc mandir prefix=/var/hack

tivo-ppc:
	$(MAKE) local-base tivodir \
			CC=$(PPCXCOMPILE)gcc \
			MFLAGS="-DTIVO_S1 -D__need_timeval" \
			LD=$(PPCXCOMPILE)ld \
			RANLIB=$(PPCXCOMPILE)ranlib \
			setname="TiVo requires CLOCAL" \
			settag="TiVo PPC Modem Port" \
			setlock="TiVo Modem Lockfile" \
			setmod="TiVo" OSDCLIENT=tivocid

tivo-s2:
	$(MAKE) tivo-mips mandir prefix=/var/hack

tivo-hack-install:
	$(MAKE) install-server install-client \
            install-modules install-gateway install-tivo setmod=TiVo
	@if ! test -d $(DOCDIR)/man; then mkdir -p $(DOCDIR)/man; fi
	install -m 644 $(DOC) doc/INSTALL-TiVo $(DOCDIR)
	install -m 644 man/*.txt $(DOCDIR)/man

tivo-mips:
	$(MAKE) local tivodir fedoradir \
			CC=$(MIPSXCOMPILE)gcc \
			MFLAGS="-std=gnu99" \
			LD=$(MIPSXCOMPILE)ld \
			RANLIB=$(MIPSXCOMPILE)ranlib \
			setname="TiVo requires CLOCAL" \
			settag="TiVo MIPS Modem Port" \
			setlock="TiVo Modem Lockfile" \
			setmod="TiVo" OSDCLIENT=tivoncid

tivo-install:
	$(MAKE) install-server install-client install-modules install-gateway \
              install-man install-logrotate setmod=TiVo

freebsd:
	$(MAKE) local-base freebsddir prefix=/usr/local prefix2=$(prefix) \
            LOCKFILE=/var/spool/lock/LCK.. \
            WISH=/usr/local/bin/wish*.* TCLSH=/usr/local/bin/tclsh*.* \
            BASH=/usr/local/bin/bash

freebsd-install:
	$(MAKE) install-base MAN=$(prefix)/man
	@if ! test -d $(DOCDIR); then mkdir -p $(DOCDIR); fi
	install -m 644 $(DOC) doc/INSTALL-FreeBSD $(DOCDIR)
	cd FreeBSD; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
            MAN=$(prefix)/man

mac-fat:
	$(MAKE) local-base macdir settag="default Mac OS X" \
            unset="tts default" setmac="Mac default" \
            LOCKFILE=/var/spool/uucp/LCK.. \
            MFLAGS="-mmacosx-version-min=10.3.9 -arch ppc" STRIP=
	mv server/ncidd server/ncidd.ppc-mac
	mv gateway/sip2ncid gateway/sip2ncid.ppc-mac
	mv gateway/ncid2ncid gateway/ncid2ncid.ppc-mac
	$(MAKE) clean
	$(MAKE) local settag="default Mac OS X" \
            LOCKFILE=/var/spool/uucp/LCK.. \
            MFLAGS="-mmacosx-version-min=10.4 -arch i386 -isysroot /Developer/SDKs/MacOSX10.4u.sdk" STRIP=
	mv server/ncidd server/ncidd.i386-mac
	mv gateway/sip2ncid gateway/sip2ncid.i386-mac
	mv gateway/ncid2ncid gateway/ncid2ncid.i386-mac
	lipo -create server/ncidd.ppc-mac server/ncidd.i386-mac \
         -output server/ncidd
	lipo -create gateway/sip2ncid.ppc-mac gateway/sip2ncid.i386-mac \
         -output gateway/sip2ncid
	lipo -create gateway/ncid2ncid.ppc-mac gateway/ncid2ncid.i386-mac \
         -output gateway/ncid2ncid

mac:
	$(MAKE) local-base macdir settag="default Mac OS X" \
            unset="tts default" setmac="Mac default" \
            LOCKFILE=/var/spool/uucp/LCK.. \
            MFLAGS="-mmacosx-version-min=10.4" STRIP=

mac-install:
	@if ! test -d $(DOCDIR); then mkdir -p $(DOCDIR); fi
	install -m 644 $(DOC) doc/INSTALL-Mac $(DOCDIR)
	$(MAKE) install-base install-mac MAN=$(MAN)

cygwin:
	$(MAKE) local \
            MFLAGS=-I/cygdrive/c/WpdPack/Include \
            LDLIBS="-s -L/cygdrive/c/WpdPack/Lib -lwpcap" \
            SBIN=$(prefix)/bin \
            settag="set noserial" \
            TTYPORT=$(DEV)/com1

cygwin-install:
	$(MAKE) install \
            SBIN=$(prefix)/bin \
            settag="set noserial" \
            TTYPORT=$(DEV)/com1
	@if ! test -d $(DOCDIR); then mkdir -p $(DOCDIR); fi
	install -m 644 $(DOC) doc/INSTALL-Cygwin doc/INSTALL-Win  $(DOCDIR)

install-base: install-server install-client install-man \
         install-modules install-gateway install-tools

install: install-base install-logrotate

install-fedora:
	cd Fedora; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-redhat:
	cd Fedora; \
	$(MAKE) install-init prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-mac:
	cd Mac; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-ubuntu:
	cd debian; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-tivo:
	cd TiVo; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-gateway:
	cd gateway; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-modules:
	cd modules; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
			setmod="$(setmod)"

install-logrotate:
	cd logrotate; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-tools:
	cd tools; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
		    ALIAS=$(ALIAS)

install-man:
	cd man; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
		    MAN=$(MAN) setmod="$(setmod)"

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
        install-logrotate install-man install-var clean clobber files
