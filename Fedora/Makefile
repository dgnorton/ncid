INIT        = ncid.init ncidd.init ncidsip.init sip2ncid.init yac2ncid.init
FILES		= README Makefile $(DIST) ncid.spec

prefix		= /usr/local
prefix2		= $(prefix)
prefix3     =

BIN			= $(prefix)/bin
SBIN		= $(prefix)/sbin
ETC			= $(prefix2)/etc
VAR         = $(prefix3)/VAR

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

distclean: clobber

files:	$(FILES)

% : %.init
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod +x $@
