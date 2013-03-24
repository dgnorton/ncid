DIST        = ncidd.init ncid2ncid.init wc2ncid.init \
              sip2ncid.init yac2ncid.init ncid-mythtv.init ncid-page.init \
              ncid-notify.init ncid-samba.init ncid-speak.init ncid-yac.init \
              ncid-initmodem.init
FILES		= README Makefile.Debain $(DIST)

prefix		= /usr/local
prefix2		= $(prefix)
prefix3     =

BIN			= $(prefix)/bin
SBIN		= $(prefix)/sbin
ETC			= $(prefix2)/etc
VAR         = $(prefix3)/VAR

INIT        = $(ETC)/init.d
CONFDIR		= $(ETC)/ncid
LOG			= $(VAR)/log

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)
SITE        = $(DIST:.init=)

init: $(SITE)

install: $(SITE) dirs
	install -m 755 $(SITE) $(INIT)

dirs:
	@if ! test -d $(INIT); then mkdir -p $(INIT); fi

clean:

clobber: clean
	rm -f $(SITE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .init

.init : *.init
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod +x $@
