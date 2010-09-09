PROG1       = sip2ncid
PROG2       = ncid2ncid
PROG        = $(PROG1) $(PROG2)
SRC1        = $(PROG1).c config.c
SRC2        = $(PROG2).c
SRC         = $(SRC1) $(SRC2)
CONF        = $(PROG1).conf ncidsip.conf yac2ncid.conf \
              ncid2ncid.conf ncid2ncid.conf
HEADER1     = $(PROG1).h config.h
HEADER2     = $(PROG2).h
HEADER      = $(HEADER1) $(HEADER2)
SOURCE      = $(SRC) $(CONF) $(HEADER)
PLSOURCE    = ncidsip.pl
SHSOURCE    = yac2ncid.sh
FILES       = README.gateways Makefile $(SOURCE ) $(PLSOURCE) $(SHSOURCE)

Version := $(shell sed 's/.* //; 1q' ../VERSION)

# the prefix must end in a - (if part of a name) or a / (if part of a path)
MIPSXCOMPILE = mips-TiVo-linux-
PPCXCOMPILE  = /usr/local/tivo/bin/

prefix      = /usr/local
prefix2     = $(prefix)
prefix3     =

BASH=/bin/bash

BIN         = $(prefix)/bin
SBIN        = $(prefix)/sbin
ETC         = $(prefix2)/etc
VAR         = $(prefix3)/var

CONFDIR     = $(ETC)/ncid
CONFFILE1   = $(CONFDIR)/$(PROG1).conf
CONFFILE2   = $(CONFDIR)/$(PROG2).conf

LOGDIR      = $(VAR)/log
RUNDIR      = $(VAR)/run
PIDFILE1    = $(RUNDIR)/$(PROG1).pid
PIDFILE2     = $(RUNDIR)/$(PROG2).pid

OBJECT1     = $(SRC1:.c=.o)
OBJECT2     = $(SRC2:.c=.o)

DEFINE1     = -D_BSD_SOURCE \
              -DCONFIG=\"$(CONFFILE1)\" \
              -DPIDFILE=\"$(PIDFILE1)\"

DEFINE2     = -DCONFIG=\"$(CONFFILE2)\" \
              -DPIDFILE=\"$(PIDFILE2)\"

MFLAGS      = -W -Wmissing-declarations

CFLAGS      = -O2 -I. -I.. $(MFLAGS)

STRIP       = -s
LDFLAGS     = $(STRIP)
LDLIBS      = -lpcap

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)

usage:
	@echo "to build a TiVo ppc binary for /var/hack: make tivo-s1"
	@echo "to build a TiVo mips binary for /var/hack: make tivo-s2"
	@echo "to build a TiVo mips binary for /usr/local: make tivo-mips"
	@echo "to build a Win/cygwin binary: make cygwin"
	@echo "to build a Linux, BSD, or Mac binary: make local"
	@echo "to install in /usr/local: make install"

tivo-s1:
	$(MAKE) cidgate prefix=/var/hack \
			CC="$(PPCXCOMPILE)gcc" \
			LD="$(PPCXCOMPILE)LD" \
			MFLAGS= \
			CFLAGS="$(CFLAGS) -DTIVO_S1"
			

tivo-s2:
	$(MAKE) cidgate prefix=/var/hack \
			CC="$(MIPSXCOMPILE)gcc" \
			LD="$(MIPSXCOMPILE)LD" \
			MFLAGS= \
			CFLAGS="$(CFLAGS) -D__TIVO_S2__"

tivo-mips:
	$(MAKE) cidgate \
			CC="$(MIPSXCOMPILE)gcc" \
			LD="$(MIPSXCOMPILE)LD" \
			MFLAGS= \
			CFLAGS="$(CFLAGS) -D__TIVO_S2__"

cygwin:
	$(MAKE) cidgate prefix=/usr prefix2= \
			CFLAGS="$(CFLAGS) -IC:/WpdPack/Include" \
			LDLIBS="$(LDLIBS) -LC:/WpdPack/Lib -lwpcap"

local:
	$(MAKE) cidgate

tivo: $(PROG)

$(PROG1): $(SRC1) $(HEADER1) ../version.h
	$(CC) $(DEFINE1) $(CFLAGS) -c $(SRC1)
	$(CC) -o $@ $(OBJECT1) $(CFLAGS) $(LDFLAGS) $(LDLIBS)

$(PROG2): $(SRC2) $(HEADER2) ../version.h
	$(CC) $(DEFINE2) $(CFLAGS) -c $(SRC2)
	$(CC) -o $@ $(OBJECT2) $(CFLAGS) $(LDFLAGS)

$(OBJECTS): $(HEADER)

../version.h: ../version.h-in
	sed "s/XXX/$(Version)/" $? > $@

cidgate: $(PROG) $(PLSCRIPT) $(SHSCRIPT)

install: $(PROG) dirs install-script install-etc
	install -m 755 $(PROG1) $(SBIN)
	install -m 755 $(PROG2) $(BIN)

install-script: $(PLSCRIPT) $(SHSCRIPT)
	install -m 755 $(SHSCRIPT) $(BIN)
	install -m 755 $(PLSCRIPT) $(SBIN)

install-etc: $(CONF)
	@if test -f $(CONFDIR)/$(PROG1).conf; \
		then install -m 644 $(PROG1).conf $(CONFDIR)/$(PROG1).conf.new; \
		else install -m 644 $(PROG1).conf $(CONFDIR); \
	fi
	@if test -f $(CONFDIR)/$(PROG2).conf; \
		then install -m 644 $(PROG2).conf $(CONFDIR)/$(PROG2).conf.new; \
		else install -m 644 $(PROG2).conf $(CONFDIR); \
	fi
	@if test -f $(CONFDIR)/ncidsip.conf; \
		then install -m 644 ncidsip.conf $(CONFDIR)/ncidsip.conf.new; \
		else install -m 644 ncidsip.conf $(CONFDIR); \
	fi
	@if test -f $(CONFDIR)/yac2ncid.conf; \
		then install -m 644 yac2ncid.conf $(CONFDIR)/yac2ncid.conf.new; \
		else install -m 644 yac2ncid.conf $(CONFDIR); \
	fi

dirs:
	@if ! test -d $(SBIN); then mkdir -p $(SBIN); fi
	@if ! test -d $(CONFDIR); then mkdir -p $(CONFDIR); fi
	@if ! test -d $(MAN8); then mkdir -p $(MAN8); fi

clean:
	rm -f *.o *.a

clobber: clean
	rm -f $(PROG) $(PLSCRIPT) $(SHSCRIPT)
	rm -f $(PROG1).ppc-mac $(PROG1).i386-mac
	rm -f $(PROG2).ppc-mac $(PROG2).i386-mac
	rm -f a.out *.log *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .init .pl .sh

.init : *.init
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod +x $@

.pl : *.pl
	#cp $< $@
	sed 's/XxXxX/$(Version)/' $< > $@
	chmod +x $@

.sh : *.sh
	sed '1s,/bin/bash,$(BASH),;/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),;s/XxXxX/$(Version)/' $< > $@
	chmod +x $@
