SHMODULES = ncid-page.sh ncid-samba.sh ncid-speak.sh ncid-mythtv.sh \
            ncid-kpopup.sh ncid-skel.sh ncid-tivo.sh ncid-yac.sh
DIST      = ncidmodules.conf.dist
FILES     = README.modules Makefile $(MODULES) $(ETCFILE)

prefix    = /usr/local
prefix2   = $(prefix)

setmod    = NONE

MODULEDIR = $(prefix)/share/ncid
BIN       = $(prefix)/bin
ETC       = $(prefix2)/etc

CONFDIR   = $(ETC)/ncid

MODULES   = $(SHMODULES:.sh=)

ETCFILE   = $(DIST:.dist=)

modules: $(MODULES) $(ETCFILE)

install: install-etc install-modules

install-modules: $(MODULES)
	@if test ! -d $(MODULEDIR); then mkdir -p $(MODULEDIR); fi
	install -m 755 $(MODULES) $(MODULEDIR)

install-etc: $(ETCFILE)
	@if test -f $(CONFDIR)/$(ETCFILE); \
		then install -m 644 $(ETCFILE) $(CONFDIR)/$(ETCFILE).new; \
		else install -m 644 $(ETCFILE) $(CONFDIR); \
	fi

clean:

clobber: clean
	rm -f $(MODULES) $(ETCFILE)

distclean: clobber

files:	$(FILES)

% : %.sh
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod 755 $@

% : %.dist
	sed '/"$(setmod)"/s/#//;s,/usr/local,$(prefix),' $< > $@
