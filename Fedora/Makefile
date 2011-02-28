INIT        = ncidd.init ncidsip.init ncid2ncid.init \
              sip2ncid.init yac2ncid.init ncid-mythtv.init ncid-page.init \
              ncid-samba.init ncid-speak.init ncid-yac.init \
              ncid-initmodem.init
SPEC        = ncid.spec
FILES		= README.Fedora Makefile $(INIT) $(SPEC)

Version := $(shell sed 's/.* //; 1q' ../VERSION)

prefix		= /usr/local
prefix2		= $(prefix)
prefix3     =
prefix4     =

#SHARP      = ;/\# Source networking/,/NETWORKING.*exit/{N;d}

BIN			= $(prefix)/bin
SBIN		= $(prefix)/sbin
ETC			= $(prefix2)/etc
VAR         = $(prefix3)/VAR
FUN         = $(prefix4)/etc/rc.d/init.d/functions

RCDIR       = $(ETC)/rc.d
INITDIR     = $(RCDIR)/init.d
CONFDIR		= $(ETC)/ncid
LOG			= $(VAR)/log

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)
SITE        = $(INIT:.init=)

init: $(SITE)

install: $(SITE) dirs
	install -m 755 $(SITE) $(INITDIR)

dirs:
	@if ! test -d $(INITDIR); then mkdir -p $(INITDIR); fi

clean:

clobber: clean
	rm -f $(SITE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .init -in

.init : *.init
	sed '/exec/s,/usr/local,$(prefix),;/config/s,/usr/local,$(prefix2),;s,.*/functions,. $(FUN),$(SHARP)' $< > $@
	chmod +x $@

-in : *-in
	sed 's,X.XX,$(Version),' $< > $@
