#########################################################################
# make local             - builds for /usr/local and /var               #
# make install           - installs files in /usr/local and /var        #
#                                                                       #
# make package           - builds for /usr, /etc, and /var              #
# make package-install   - installs files in /usr, /etc, and /var       #
#                                                                       #
# make fedora            - builds for Fedora (includes init.d/ files)   #
# make fedora-install    - installs in /usr, /etc, and /var             #
#                                                                       #
# make ubuntu            - builds for Ubuntu (includes init.d/ files)   #
# make ubuntu-install    - installs in /usr, /etc, and /var             #
#                                                                       #
# make mandir            - builds man text and html files               #
#                          (no install for the *.txt and *.html files)  #
#                                                                       #
# make tivo-mips         - builds for a mips TiVo in /usr/local         #
# make tivo-install      - installs in /usr/local                       #
# make tivo-s1           - builds for a ppc TiVo for /var/hack          #
# make tivo-s2           - builds for a mips TiVo for /var/hack         #
# make tivo-hack-install - basic install into /var/hack                 #
#                          uses the cross compilers at:                 #
#                          http://tivoutils.sourceforge.net/            #
#                          usr.local.powerpc-tivo.tar.bz2               #
#                          (x86 cross compiler for Series1)             #
#                          usr.local.mips-tivo.tar.bz2                  #
#                          (x86 cross compiler for Series2)             #
#                                                                       #
# gmake freebsd          - builds for FreeBSD in /usr/local             #
# gmake freebsd-install  - installs in /usr/local                       #
#                                                                       #
# make mac               - builds for Macintosh OS X in /usr/local      #
# make mac-fat           - builds universal OS X binaries in /usr/local #
# make mac-install       - installs in /usr/local                       #
#                                                                       #
# make cygwin            - builds for Windows using cygwin              #
#                          (does not function with modem or comm port)  #
# make cygwin-install    - installs files in /usr/local, and /var       #
#########################################################################

PROG         = ncidd
SOURCE       = $(PROG).c nciddconf.c nciddalias.c getopt_long.c poll.c
CLIENT       = ncid
LOGO         = ncid.gif
HEADER       = ncidd.h nciddconf.h nciddalias.h getopt_long.h poll.h
ETCFILE      = ncid.conf ncidd.conf ncidd.alias
DOCFILE      = doc/CHANGES doc/COPYING README doc/README-FreeBSD \
               doc/NCID-FORMAT doc/PROTOCOL VERSION
DIST         = ncidd.conf.dist ncid.conf.dist
FILES        = Makefile $(CLIENT).sh $(DIST) $(HEADER) $(SOURCE) \
               $(DOCFILE) $(ETCFILE)

# the prefix must end in a - (if part of a name) or a / (if part of a path)
MIPSXCOMPILE = mips-TiVo-linux-
PPCXCOMPILE  = /usr/local/tivo/bin/

# prefix and prefix2 are used on a make, install, and making a package
# prefix3 is used on install to make a package
prefix       = /usr/local
prefix2      = $(prefix)
prefix3      =

OS           = host

settag       = NONE
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
IMAGEDIR	 = $(SHARE)/pixmaps
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

SITE         = $(DIST:.dist=)
WISH         = wish
TCLSH        = tclsh

# local additions to CFLAGS
MFLAGS  =

DEFINES = -DCIDCONF=\"$(CONF)\" \
          -DCIDALIAS=\"$(ALIAS)\" \
          -DCIDLOG=\"$(CALLLOG)\" \
          -DTTYPORT=\"$(MODEMDEV)\" \
          -DDATALOG=\"$(DATALOG)\" \
          -DLOGFILE=\"$(LOGFILE)\" \
          -DPIDFILE=\"$(PIDFILE)\"

CFLAGS  = -O $(DEFINES) $(MFLAGS)

STRIP   = -s

LDFLAGS = $(STRIP) $(MFLAGS)

OBJECTS = $(SOURCE:.c=.o)

default:
	@echo "make requires an argument, see top of Makefile for description:"
	@echo
	@echo "    make  local             # builds for /usr/local and /var"
	@echo "    make  install           # installs into /usr/local and /var"
	@echo "    make  package           # builds for /usr and /var"
	@echo "    make  package-install   # installs into for /usr and /var"
	@echo "    make  fedora            # builds for Fedora, includes init.d/"
	@echo "    make  fedora-install    # installs in /usr, /etc, and /var"
	@echo "    make  ubuntu            # builds for Ubuntu, includes init.d/"
	@echo "    make  ubuntu-install    # installs in /usr, /etc, and /var"
	@echo "    make  tivo-mips         # builds for Tivo in /usr/local, /var"
	@echo "    make  tivo-install      # installs in /usr/local, /var"
	@echo "    make  tivo-s1           # builds for a series1 in /var/hack"
	@echo "    make  tivo-s2           # builds for a series[23] in /var/hack"
	@echo "    make  tivo-hack-install # installs in /var/hack, /var"
	@echo "    gmake freebsd           # builds for FreeBSD in /usr/local, /var"
	@echo "    gmake freebsd-install   # installs in /usr/local, /var"
	@echo "    make  mac               # builds for Mac in /usr/local, /var"
	@echo "    make  mac-fat           # builds for Mac in /usr/local, /var"
	@echo "    make  mac-install       # installs in /usr/local, /var"
	@echo "    make  cygwin            # builds for windows using Cygwin"
	@echo "    make  cygwin-install    # installs in /usr/local"

local: $(PROG) $(CLIENT) site moduledir cidgatedir tooldir scriptdir

site: $(SITE)

$(PROG): $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(OBJECTS): $(HEADER)

fedoradir:
	cd Fedora; $(MAKE) init prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

freebsddir:
	cd FreeBSD; $(MAKE) rcd prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

ubuntudir:
	cd debian; $(MAKE) init prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

moduledir:
	cd modules; $(MAKE) modules prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

cidgatedir:
	cd cidgate; $(MAKE) cidgate prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3) BIN=$(BIN) SBIN=$(SBIN) OS=$(OS) \
                      MFLAGS="$(MFLAGS)" STRIP=$(STRIP)

tooldir:
	cd tools; $(MAKE) tools prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3) BIN=$(BIN)

scriptdir:
	cd scripts; $(MAKE) scripts prefix=$(prefix) prefix2=$(prefix2) \
                      prefix3=$(prefix3)

mandir:
	cd man; $(MAKE) all prefix=$(prefix) prefix2=$(prefix2) MAN=$(MAN)

package:
	$(MAKE) local prefix=/usr prefix2=

package-install:
	$(MAKE) install prefix=/usr prefix2=

fedora:
	$(MAKE) local fedoradir prefix=/usr prefix2=

fedora-install:
	$(MAKE) install install-fedora prefix=/usr prefix2=

ubuntu:
	$(MAKE) local ubuntudir prefix=/usr prefix2=

ubuntu-install:
	$(MAKE) install install-ubuntu prefix=/usr prefix2=

tivo-s1:
	$(MAKE) tivo-ppc prefix=/var/hack

tivo-ppc:
	$(MAKE) local mandir prefix=/var/hack OS=tivo-s1 \
	        CC=$(PPCXCOMPILE)gcc \
	        MFLAGS=-D__need_timeval \
	        LD=$(PPCXCOMPILE)ld \
	        RANLIB=$(PPCXCOMPILE)ranlib \
	        setname="TiVo requires CLOCAL" \
	        settag="TiVo Modem Port" \
	        setmod="out2osd"
	ln -s ncid tivocid
	ln -s ncid tivoncid
	touch tivo-ppc

tivo-s2:
	$(MAKE) tivo-mips prefix=/var/hack

tivo-hack-install:
	$(MAKE) tivo-install-hack prefix=/var/hack prefix2=$HACK prefix3=$ROOT

tivo-install-hack: dirs install-prog install-etc install-log \
                   install-modules install-cidgate install-tools
	install -m 644 $(LOGO) $(IMAGEDIR)/.
	cp -a tivocid tivoncid $(BIN)

tivo-mips:
	$(MAKE) local mandir OS=tivo-mips \
	        CC=$(MIPSXCOMPILE)gcc \
	        LD=$(MIPSXCOMPILE)ld \
	        RANLIB=$(MIPSXCOMPILE)ranlib \
	        setname="TiVo requires CLOCAL" \
	        settag="TiVo Modem Port" \
	        setmod="ncid-tivo"
	ln -s ncid tivocid
	ln -s ncid tivoncid
	touch tivo-mips

tivo-install: dirs install-prog install-etc install-log \
              install-modules install-cidgate install-tools \
              install-man install-scripts
	install -m 644 $(LOGO) $(IMAGEDIR)/.
	cp -a tivocid tivoncid $(BIN)

freebsd:
	$(MAKE) local freebsddir prefix=/usr/local prefix2=$(prefix) \
            WISH=/usr/local/bin/wish*.* TCLSH=/usr/local/bin/tclsh*.* \
            BASH=/usr/local/bin/bash

freebsd-install:
	$(MAKE) install MAN=$(prefix)/man
	cd FreeBSD; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) \
            MAN=$(prefix)/man

mac-fat:
	$(MAKE) local settag="Macintosh OS X" \
            MFLAGS="-mmacosx-version-min=10.3.9 -arch ppc" STRIP=
	mv ncidd ncidd.ppc-mac
	mv cidgate/sip2ncid cidgate/sip2ncid.ppc-mac
	make clean
	$(MAKE) local settag="Macintosh OS X" \
            MFLAGS="-mmacosx-version-min=10.4 -arch i386" STRIP=
	mv ncidd ncidd.i386-mac
	mv cidgate/sip2ncid cidgate/sip2ncid.i386-mac
	lipo -create ncidd.ppc-mac ncidd.i386-mac -output ncidd
	lipo -create cidgate/sip2ncid.ppc-mac cidgate/sip2ncid.i386-mac \
         -output cidgate/sip2ncid

mac:
	$(MAKE) local settag="Macintosh OS X" \
            MFLAGS="-mmacosx-version-min=10.4" STRIP=

mac-install:
	$(MAKE) install MAN=$(prefix)/man

cygwin:
	$(MAKE) local OS=cygwin \
            SBIN=$(prefix)/bin \
            settag="set noserial" \
            MODEMDEV=$(DEV)/com1

cygwin-install:
	$(MAKE) install \
            SBIN=$(prefix)/bin \
            settag="set noserial" \
            MODEMDEV=$(DEV)/com1

dirs:
	@if ! test -d $(BIN); then mkdir -p $(BIN); fi
	@if ! test -d $(SBIN); then mkdir -p $(SBIN); fi
	@if ! test -d $(ETC); then mkdir -p $(ETC); fi
	@if ! test -d $(LOG); then mkdir -p $(LOG); fi
	@if ! test -d $(CONFDIR); then mkdir -p $(CONFDIR); fi
	@if ! test -d $(IMAGEDIR); then mkdir -p $(IMAGEDIR); fi

install: dirs install-prog install-man install-etc install-log \
         install-modules install-cidgate install-scripts install-tools
	install -m 644 $(LOGO) $(IMAGEDIR)/.

install-prog: $(PROG)
	install -m 755 $(PROG) $(SBIN)
	install -m 755 $(CLIENT) $(BIN)

install-etc: $(ETCFILE)
	@if test -f $(CONFDIR)/ncidd.alias; \
		then install -m 644 ncidd.alias $(CONFDIR)/ncidd.alias.new; \
		else install -m 644 ncidd.alias $(CONFDIR); \
	fi
	@if test -f $(CONFDIR)/ncidd.conf; \
		then install -m 644 ncidd.conf $(CONFDIR)/ncidd.conf.new; \
		else install -m 644 ncidd.conf $(CONFDIR); \
	fi
	@if test -f $(CONFDIR)/ncid.conf; \
		then install -m 644 ncid.conf $(CONFDIR)/ncid.conf.new; \
		else install -m 644 ncid.conf $(CONFDIR); \
	fi

install-log:
	touch $(CALLLOG)

install-fedora:
	cd Fedora; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3)

install-ubuntu:
	cd debian; \
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
	cd man; $(MAKE) install prefix=$(prefix) prefix2=$(prefix2) prefix3=$(prefix3) MAN=$(MAN)

clean:
	rm -f *.o
	cd man; $(MAKE) clean
	cd tools; $(MAKE) clean
	cd scripts; $(MAKE) clean
	cd modules; $(MAKE) clean
	cd cidgate; $(MAKE) clean
	cd Fedora; $(MAKE) clean
	cd FreeBSD; $(MAKE) clean
	cd debian; $(MAKE) clean

clobber: clean
	rm -f $(PROG) $(PROG).ppc-tivo $(PROG).mips-tivo tivo-ppc tivo-mips
	rm -f $(PROG).ppc-mac $(PROG).i386-mac
	rm -f tivocid tivoncid $(CLIENT) $(SITE)
	rm -f a.out *.log *.zip *.tar.gz
	cd man; $(MAKE) clobber
	cd tools; $(MAKE) clobber
	cd scripts; $(MAKE) clobber
	cd modules; $(MAKE) clobber
	cd cidgate; $(MAKE) clobber
	cd Fedora; $(MAKE) clobber
	cd FreeBSD; $(MAKE) clobber
	cd debian; $(MAKE) clobber

distclean: clobber

files: $(FILES)

.PHONY: local ppc-tivo mips-tivo install install-proc install-etc \
        install-logrotate install-man install-var clean clobber files

% : %.sh
	sed 's,/usr/local/share/ncid,$(MODULEDIR),;s,/usr/local/etc/ncid,$(CONFDIR),;s,/usr/local/share/pixmaps,$(IMAGEDIR),;s,WISH=wish,WISH=$(WISH),;s,TCLSH=tclsh,TCLSH=$(TCLSH),;s,/usr/local/bin,$(BIN),' $< > $@
	chmod 755 $@

% : %.dist
	sed '/share/s,/usr/local,$(prefix),;/$(settag)/s/# set/set/;/$(setname)/s/# set/set/' $< > $@
