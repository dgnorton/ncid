########################################################################
# make local            - builds for /usr/local and /var               #
# make package          - builds for /usr, /etc, and /var              #
# make install          - installs files                               #
# make mandir           - builds man text and html files               #
#                         (no install for the *.txt and *.html files)  #
#                                                                      #
# make tivo-series1     - builds for a ppc TiVo for /var/hack          #
# make tivo-series2     - builds for a mips TiVo for /var/hack         #
#   uses the cross compilers at: http://tivoutils.sourceforge.net/     #
#   usr.local.powerpc-tivo.tar.bz2 (x86 cross compiler for Series1)    #
#   usr.local.mips-tivo.tar.bz2 (x86 cross compiler for Series2)       #
#                                                                      #
# make freebsd          - builds for FreeBSD in /usr/local             #
# make install-freebsd  - installs in /usr/local                       #
#                                                                      #
# make mac              - builds for Macintosh OS X in /usr/local      #
# make install-mac      - installs in /usr/local                       #
#                                                                      #
# make cygwin           - builds for Windows using cygwin              #
#                         (does not function yet)                      #
########################################################################

PROG        = ncidd
SOURCE      = $(PROG).c nciddconf.c nciddalias.c getopt_long.c poll.c
CLIENT      = ncid
HEADER      = ncidd.h nciddconf.h nciddalias.h getopt_long.h poll.h
ETCFILE     = ncid.spec
DOCFILE     = doc/CHANGES doc/COPYING README doc/README-FreeBSD \
              doc/NCID-FORMAT doc/PROTOCOL VERSION
DIST        = $(CLIENT).dist ncidd.logrotate.dist ncidd.conf.dist \
              ncid.init.dist ncid.conf.dist
FILES       = Makefile $(DIST) $(HEADER) $(SOURCE) \
              $(DOCFILE) $(ETCFILE)

prefix      = /usr/local
prefix2     = $(prefix)
settag      = NONE
setname     = NONE

BIN         = $(prefix)/bin
SBIN        = $(prefix)/sbin
SCRIPT      = $(prefix)/share/ncid
ETC         = $(prefix2)/etc
ROTATE      = $(ETC)/logrotate.d
INIT        = $(ETC)/rc.d/init.d
CONFDIR     = $(ETC)/ncid
DEV         = /dev
LOG         = /var/log

CONF        = $(CONFDIR)/ncidd.conf
ALIAS       = $(CONFDIR)/ncidd.alias
MODEMDEV    = $(DEV)/modem
CALLLOG     = $(LOG)/cidcall.log
DATALOG     = $(LOG)/ciddata.log

SITE        = $(DIST:.dist=)
WISH        = wish
TCLSH       = tclsh

# local additions to CFLAGS
MFLAGS  =

DEFINES = -DCIDCONF=\"$(CONF)\" \
          -DCIDALIAS=\"$(ALIAS)\" \
          -DCIDLOG=\"$(CALLLOG)\" \
          -DTTYPORT=\"$(MODEMDEV)\" \
          -DDATALOG=\"$(DATALOG)\"

CFLAGS  = -O $(DEFINES) $(MFLAGS)

LDFLAGS = -s

OBJECTS = $(SOURCE:.c=.o)

default:
	@echo "make requires an argument, see top of Makefile for description:"
	@echo "    make local"
	@echo "    make package"
	@echo "    make install"
	@echo "    make tivo-series1"
	@echo "    make tivo-series2"
	@echo "    make freebsd"
	@echo "    make install-freebsd"
	@echo "    make mac"
	@echo "    make install-mac"
	@echo "    make cygwin"

local: $(SITE) $(PROG) tooldir scriptdir

$(PROG): $(OBJECTS)
	$(CC) $(CFLAGS) $(OBJECTS) $(LDFLAGS) -o $@

$(OBJECTS): $(HEADER)

tooldir:
	cd tools; $(MAKE) tools prefix=$(prefix) prefix2=$(prefix2) MAN=$(MAN)

scriptdir:
	cd scripts; $(MAKE) scripts prefix=$(prefix) prefix2=$(prefix2) MAN=$(MAN)

package:
	$(MAKE) local prefix=/usr prefix2=

tivo-series1: $(PROG).ppc-tivo mandir

$(PROG).ppc-tivo:
	$(MAKE) local prefix=/var/hack \
	CC="/usr/local/tivo/bin/gcc" \
	MFLAGS=-D__need_timeval \
	LD="/usr/local/tivo/bin/ld" \
	RANLIB=/usr/local/tivo/bin/ranlib \
	setname="TiVo requires CLOCAL" \
	settag="TiVo Modem Port"
	mv $(PROG) $(PROG).ppc-tivo

tivo-series2: $(PROG).mips-tivo mandir

$(PROG).mips-tivo:
	$(MAKE) local prefix=/var/hack \
	CC="/usr/local/mips-tivo/bin/gcc" \
	LD="/usr/local/mips-tivo/bin/ld" \
	RANLIB=/usr/local/mips-tivo/bin/ranlib \
	setname="TiVo requires CLOCAL" \
	settag="TiVo Modem Port"
	mv $(PROG) $(PROG).mips-tivo

freebsd:
	$(MAKE) local WISH=/usr/local/bin/wish*.* TCLSH=/usr/local/bin/tclsh*.*

install-freebsd:
	$(MAKE) install-base MAN=$(prefix)/man
	cd FreeBSD; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) MAN=$(prefix)/man

mac:
	$(MAKE) local settag="Macintosh OS X"

install-mac:
	$(MAKE) install-base MAN=$(prefix)/man

cygwin:
	$(MAKE) local LOG=c:/ncid CONF=c:/ncid/ncidd.conf MODEMDEV=/dev/com1 \
	$(PROG)

mandir:
	cd man; $(MAKE) all prefix=$(prefix) prefix2=$(prefix2) MAN=$(MAN)

$(FILES):
	@if test -x $(BIN)/sccs; then $(BIN)/sccs $(GET) $@; fi

dirs:
	@if ! test -d $(BIN); then mkdir -p $(BIN); fi
	@if ! test -d $(SBIN); then mkdir -p $(SBIN); fi
	@if ! test -d $(ETC); then mkdir -p $(ETC); fi
	@if ! test -d $(LOG); then mkdir -p $(LOG); fi
	@if ! test -d $(ROTATE); then mkdir -p $(ROTATE); fi
	@if ! test -d $(INIT); then mkdir -p $(INIT); fi
	@if ! test -d $(SCRIPT); then mkdir -p $(SCRIPT); fi
	@if ! test -d $(CONFDIR); then mkdir -p $(CONFDIR); fi

install-base: dirs install-prog install-man install-etc install-log \
         install-scripts install-tools

install: install-base install-init install-logrotate

install-prog: $(PROG)
	install -m 755 $(PROG) $(SBIN)
	install -m 755 $(CLIENT) $(BIN)

install-etc: ncid.conf ncidd.conf ncidd.alias
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

install-init: ncid.init ncidd.init
	@if test -d $(INIT); then \
		install -m 755 ncidd.init $(INIT)/ncidd; \
		install -m 755 ncid.init $(INIT)/ncid; \
		else echo "skipping ncidd.init install, no directory: $(INIT)"; \
	fi

install-logrotate: ncidd.logrotate
	@if test -d $(ROTATE); \
		then install -m 644 ncidd.logrotate $(ROTATE)/ncidd; \
		else echo "skipping ncidd.logrotate install, no directory: $(ROTATE)";\
	fi

install-log:
	touch $(CALLLOG)

install-scripts:
	cd scripts; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) CONF=$(CONF)

install-tools:
	cd tools; \
	$(MAKE) install prefix=$(prefix) prefix2=$(prefix2) CONF=$(CONF) ALIAS=$(ALIAS)

install-man:
	cd man; $(MAKE) install prefix=$(prefix) prefix2=$(prefix2) MAN=$(MAN)

clean:
	rm -f *.o
	cd man; $(MAKE) clean
	cd tools; $(MAKE) clean
	cd scripts; $(MAKE) clean

clobber: clean
	rm -f $(PROG) $(PROG).ppc-tivo $(PROG).mips-tivo $(PROG).tivo a.out
	rm -f $(CLIENT) ncidd.logrotate ncid.conf ncidd.conf ncid.init *.zip
	rm -f *.log
	cd man; $(MAKE) clobber
	cd tools; $(MAKE) clobber
	cd scripts; $(MAKE) clobber

files: $(FILES)

.PHONY: local ppc-tivo mips-tivo install install-proc install-etc \
        install-init install-logrotate install-man install-var \
        clean clobber files

% : %.sh
	sed '/ConfigDir/s,/usr/local,$(prefix2),;s,WISH=wish,WISH=$(WISH),;s,TCLSH=tclsh,TCLSH=$(TCLSH),' $< > $@
	chmod 755 $@

% : %.dist
	sed '/share/s,/usr/local,$(prefix),;/ConfigDir/s,/usr/local,$(prefix2),;/$(settag)/s/# set/set/;/$(setname)/s/# set/set/' $< > $@
