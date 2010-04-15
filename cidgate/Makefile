PROG        = sip2ncid
SRC         = $(PROG).c config.c
CONF        = $(PROG).conf ncidsip.conf yac2ncid.conf
HEADER      = $(PROG).h config.h
SOURCES     = $(PROG) $(SRC) $(HEADER) $(SOURCE)
PLSOURCE    = ncidsip.pl
SHSOURCE    = yac2ncid.sh
FILES       = README Makefile $(SOURCES) $(PLSOURCE) $(SHSOURCE)

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
CONFFILE    = $(CONFDIR)/$(PROG).conf

LOGDIR      = $(VAR)/log
RUNDIR      = $(VAR)/run
PIDFILE     = $(RUNDIR)/$(PROG).pid

OBJECTS     = $(SRC:.c=.o)

DEFINES     = -D_BSD_SOURCE \
              -DCONFIG=\"$(CONFFILE)\" \
              -DPIDFILE=\"$(PIDFILE)\"

MFLAGS      =
CFLAGS      = -O $(DEFINES) -I. $(MFLAGS)

STRIP       = -s
LDFLAGS     = $(STRIP) $(MFLAGS) -lpcap

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)

OS          = host

ifeq ($(OS),tivo-ppc)
    CC = $(PPCXCOMPILE)gcc
    LD = $(PPCXCOMPILE)ld
    CFLAGS += -DTIVO_S1
else
    ifeq ($(OS),tivo-mips)
        CC = $(MIPSXCOMPILE)gcc
        LD = $(MIPSXCOMPILE)ld
        CFLAGS += -D__TIVO_S2__ -std=gnu99
    else
        ifeq ($(OS),cygwin)
            CFLAGS += -IC:/WpdPack/Include
            LDFLAGS = -s -LC:/WpdPack/Lib -lwpcap
        endif
    endif
endif

usage:
	@echo "to build a TiVo ppc binary for /var/hack: make tivo-s1"
	@echo "to build a TiVo mips binary for /var/hack: make tivo-s2"
	@echo "to build a TiVo mips binary for /usr/local: make tivo-mips"
	@echo "to build a Win/cygwin binary: make cygwin"
	@echo "to build a Linux, BSD, or Mac binary: make local"
	@echo "to install in /usr/local: make install"

tivo-s1:
	make OS=tivo-ppc cidgate prefix=/var/hack

tivo-s2:
	make OS=tivo-mips cidgate prefix=/var/hack

tivo-mips:
	make OS=tivo-mips cidgate
cygwin:
	make OS=cygwin cidgate prefix=/usr prefix2=

local:
	make cidgate

tivo: $(PROG)

$(PROG): ../version.h $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(OBJECTS): $(HEADER)

../version.h: ../version.h-in
	sed "s/XXX/$(Version)/" $? > $@

cidgate: $(PROG) $(PLSCRIPT) $(SHSCRIPT)

install: $(PROG) dirs install-script install-etc
	install -m 755 $(PROG) $(SBIN)

install-script: $(PLSCRIPT) $(SHSCRIPT)
	install -m 755 $(SHSCRIPT) $(BIN)
	install -m 755 $(PLSCRIPT) $(SBIN)

install-etc: $(CONF)
	@if test -f $(CONFDIR)/$(PROG).conf; \
		then install -m 644 $(PROG).conf $(CONFDIR)/$(PROG).conf.new; \
		else install -m 644 $(PROG).conf $(CONFDIR); \
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
	rm -f $(PROG).ppc-mac $(PROG).i386-mac
	rm -f a.out *.log *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

% : %.init
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod +x $@

% : %.pl
	#cp $< $@
	sed 's/XxXxX/$(Version)/' $< > $@
	chmod +x $@

% : %.sh
	sed '1s,/bin/bash,$(BASH),;/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),;s/XxXxX/$(Version)/' $< > $@
	chmod +x $@
