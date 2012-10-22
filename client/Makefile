SHSOURCE    = ncid.sh
LOGO        = ncid.gif
DIST        = ncid.conf-in
FILES       = README.clients Makefile $(SOURCE) $(SHSOURCE) $(LOGO) $(DIST)

Version := $(shell sed 's/.* //; 1q' ../VERSION)

prefix      = /usr/local
prefix2     = $(prefix)
prefix3     =

settag      = NONE
setlock     = NONE
setname     = NONE

BASH=/bin/bash

BIN         = $(prefix)/bin
SHARE       = $(prefix)/share
ETC         = $(prefix2)/etc

CONFDIR     = $(ETC)/ncid
CONFFILE    = $(CONFDIR)/ncid.conf

MODULEDIR   = $(SHARE)/ncid
IMAGEDIR    = $(SHARE)/pixmaps/ncid

WISH        = wish
TCLSH       = tclsh

SHSCRIPT    = $(SHSOURCE:.sh=)

SITE        = $(DIST:-in=)

usage:
	@echo "to build a TiVo ppc binary for /var/hack: make tivo-s1"
	@echo "to build a TiVo mips binary for /var/hack: make tivo-s2"
	@echo "to build a TiVo mips binary for /usr/local: make tivo-mips"
	@echo "to build a Win/cygwin binary: make cygwin"
	@echo "to build a Linux, BSD, or Mac binary: make local"
	@echo "to install in /usr/local: make install"

tivo-s1:
	$(MAKE) tivo-ppc prefix=/var/hack \

tivo-ppc:
	$(MAKE) client \
	touch tivo-ppc
			

tivo-s2:
	$(MAKE) tivo-mips prefix=/var/hack

tivo-mips:
	$(MAKE) client \
	touch tivo-mips

cygwin:
	$(MAKE) client prefix=/usr prefix2=

local:
	$(MAKE) client

../version.h: ../version.h-in
	sed "s/XXX/$(Version)/" $< > $@

client: $(SHSCRIPT) $(SITE)

install:dirs install-script install-etc

install-script: $(SHSCRIPT)
	install -m 755 $(SHSCRIPT) $(BIN)
	install -m 644 $(LOGO) $(IMAGEDIR)

install-tivo: install
	install -m 755 tivocid tivoncid $(BIN)

install-etc: $(SITE)
	@if test -f $(CONFDIR)/$(SHSCRIPT).conf; \
		then install -m 644 $(SHSCRIPT).conf $(CONFDIR)/$(SHSCRIPT).conf.new; \
		else install -m 644 $(SHSCRIPT).conf $(CONFDIR); \
	fi

dirs:
	@if ! test -d $(BIN); then mkdir -p $(BIN); fi
	@if ! test -d $(CONFDIR); then mkdir -p $(CONFDIR); fi
	@if ! test -d $(IMAGEDIR); then mkdir -p $(IMAGEDIR); fi

clean:
	rm -f *.o *.a

clobber: clean
	rm -f $(SHSCRIPT) $(SHSCRIPT).conf
	rm -f tivocid tivoncid tivo-mips tivo-ppc
	rm -f a.out *.log *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .init .sh -in

.init : *.init
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod +x $@

.sh : *.sh
	sed 's,/usr/local/share/ncid,$(MODULEDIR),;s,/usr/local/etc/ncid,$(CONFDIR),;s,/usr/local/share/pixmaps/ncid,$(IMAGEDIR),;s,WISH=wish,WISH=$(WISH),;s,TCLSH=tclsh,TCLSH=$(TCLSH),;s,/usr/local/bin,$(BIN),;s,XxXxX,$(Version),' $< > $@
	chmod +x $@

-in : *-in
	sed '/share/s,/usr/local,$(prefix),;/$(settag)/s/# set/set/;/$(setname)/s/# set/set/;/$(setlock)/s/# set/set/' $< > $@
