SHMODULES = ncid-page.sh ncid-samba.sh ncid-speak.sh \
            ncid-mythtv.sh ncid-kpopup.sh ncid-skel.sh ncid-tivo.sh \
            ncid-yac.sh ncid-initmodem.sh
DIST      = ncidmodules.conf-in
FILES     = README.modules Makefile $(SHMODULES) $(DIST)

prefix    = /usr/local
prefix2   = $(prefix)

setmod    = NONE

MODULEDIR = $(prefix)/share/ncid
BIN       = $(prefix)/bin
ETC       = $(prefix2)/etc

CONFDIR   = $(ETC)/ncid

MODULES   = $(SHMODULES:.sh=)

CONFFILE  = $(DIST:-in=)

modules: $(MODULES) $(CONFFILE)

install: install-etc install-modules

install-modules: $(MODULES)
	@if test ! -d $(MODULEDIR); then mkdir -p $(MODULEDIR); fi
	install -m 755 $(MODULES) $(MODULEDIR)

install-etc: $(CONFFILE)
	@if test -f $(CONFDIR)/$(CONFFILE); \
		then install -m 644 $(CONFFILE) $(CONFDIR)/$(CONFFILE).new; \
		else install -m 644 $(CONFFILE) $(CONFDIR); \
	fi

clean:

clobber: clean
	rm -f $(MODULES) $(CONFFILE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .sh -in

.sh : *.sh
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod 755 $@

-in : *-in
	sed '/"$(setmod)"/s/#//;s,/usr/local,$(prefix),' $< > $@
