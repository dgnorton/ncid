SHMODULES = ncid-hangup ncid-page.sh ncid-samba.sh ncid-speak.sh \
            ncid-mythtv.sh ncid-kpopup.sh ncid-skel.sh ncid-tivo.sh \
            ncid-yac.sh
ETCFILES  = ncid.blacklist ncid.minicom
DIST      = ncidmodules.conf.dist
FILES     = README.modules Makefile $(SHMODULES) $(ETCFILES) $(DIST)

prefix    = /usr/local
prefix2   = $(prefix)

setmod    = NONE

MODULEDIR = $(prefix)/share/ncid
BIN       = $(prefix)/bin
ETC       = $(prefix2)/etc

CONFDIR   = $(ETC)/ncid

MODULES   = $(SHMODULES:.sh=)

CONFFILE  = $(DIST:.dist=)

modules: $(MODULES) $(CONFFILE)

install: install-etc install-modules

install-modules: $(MODULES)
	@if test ! -d $(MODULEDIR); then mkdir -p $(MODULEDIR); fi
	install -m 755 $(MODULES) $(MODULEDIR)

install-etc: $(CONFFILE)
	install -m 644 $(ETCFILES)
	@if test -f $(CONFDIR)/$(CONFFILE); \
		then install -m 644 $(CONFFILE) $(CONFDIR)/$(CONFFILE).new; \
		else install -m 644 $(CONFFILE) $(CONFDIR); \
	fi

clean:

clobber: clean
	rm -f $(MODULES) $(CONFFILE)

distclean: clobber

files:	$(FILES)

% : %.sh
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod 755 $@

% : %-in
	sed '/"$(setmod)"/s/#//;s,/usr/local,$(prefix),' $< > $@
