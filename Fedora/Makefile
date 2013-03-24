INIT        = ncidd.init \
              ncid2ncid.init \
              sip2ncid.init \
              wc2ncid.init \
              yac2ncid.init \
              ncid-mythtv.init \
              ncid-notify.init \
              ncid-page.init \
              ncid-samba.init \
              ncid-speak.init \
              ncid-yac.init \
              ncid-initmodem.init
SERVICE     = ncidd.service \
              ncid2ncid.service \
              sip2ncid.service \
              wc2ncid.service \
              yac2ncid.service \
              ncid-mythtv.service \
              ncid-notify.service \
              ncid-page.service \
              ncid-samba.service \
              ncid-speak.service \
              ncid-yac.service \
              ncid-initmodem.service
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
SERVICEDIR  = $(prefix)/lib/systemd/system
CONFDIR		= $(ETC)/ncid
LOG			= $(VAR)/log

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)
INITSITE    = $(INIT:.init=)

service: $(SERVICE)

init: $(INITSITE)

install: $(SERVICE) dirs
	install -m 644 $(SERVICE) $(SERVICEDIR)

install-init: $(INITSITE) initdirs
	install -m 755 $(INITSITE) $(INITDIR)

dirs:
	@if ! test -d $(SERVICEDIR); then mkdir -p $(SERVICEDIR); fi

initdirs:
	@if ! test -d $(INITDIR); then mkdir -p $(INITDIR); fi

clean:

clobber: clean
	rm -f $(INITSITE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .init

.init : *.init
	sed 's,.*/functions,. $(FUN),$(SHARP)' $< > $@
	chmod +x $@
