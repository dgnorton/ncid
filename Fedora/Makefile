INIT        = ncidd.init \
              ncidsip.init \
              ncid2ncid.init \
              sip2ncid.init \
              yac2ncid.init \
              ncid-mythtv.init \
              ncid-notify.init \
              ncid-page.init \
              ncid-samba.init \
              ncid-speak.init \
              ncid-yac.init \
              ncid-initmodem.init
SERVICE     = ncidd.service-in \
              ncidsip.service-in \
              ncid2ncid.service-in \
              sip2ncid.service-in \
              yac2ncid.service-in \
              ncid-mythtv.service-in \
              ncid-notify.service-in \
              ncid-page.service-in \
              ncid-samba.service-in \
              ncid-speak.service-in \
              ncid-yac.service-in \
              ncid-initmodem.service-in
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
SITE        = $(SERVICE:-in=)

service: $(SITE)
init: $(INITSITE)

install: $(SITE) dirs
	install -m 644 $(SITE) $(SERVICEDIR)

install-init: $(INITSITE) initdirs
	install -m 755 $(INITSITE) $(INITDIR)

dirs:
	@if ! test -d $(SERVICEDIR); then mkdir -p $(SERVICEDIR); fi

initdirs:
	@if ! test -d $(INITDIR); then mkdir -p $(INITDIR); fi

clean:

clobber: clean
	rm -f $(SITE) $(INITSITE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .init -in

.init : *.init
	sed '/exec/s,/usr/local,$(prefix),;/config/s,/usr/local,$(prefix2),;s,.*/functions,. $(FUN),$(SHARP)' $< > $@
	chmod +x $@

-in : *-in
	sed '/EnvironmentFile/s,/usr/local,$(prefix2),' $< > $@
