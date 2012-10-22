SHMOD     = ncid-page.sh ncid-samba.sh ncid-speak.sh \
            ncid-mythtv.sh ncid-kpopup.sh ncid-skel.sh \
            ncid-yac.sh ncid-initmodem.sh ncid-notify.sh
PLMOD     =
DIST      = ncid-notify.conf-in ncid-speak.conf-in
CONF      = ncid-kpopup.conf ncid-mythtv.conf ncid-page.conf \
            ncid-samba.conf ncid-skel.conf ncid-yac.conf
FILES     = README.modules Makefile $(SHMOD) $(PLMOD) $(DIST)

prefix    = /usr/local
prefix2   = $(prefix)
prefix3   =

setmod    = NONE
setmac    = NONE
unset     = NONE

MOD       = $(prefix)/share/ncid

BIN       = $(prefix)/bin
ETC       = $(prefix2)/etc

CONFDIR   = $(ETC)/ncid
CONFMOD   = $(ETC)/ncid/conf.d

MODULES   = $(SHMOD:.sh=) $(PLMOD:.pl=)

CONFFILE  = $(DIST:-in=)

modules: $(MODULES) $(CONFFILE)

install: install-etc install-modules

install-modules: $(MODULES)
	@if test ! -d $(MOD); then mkdir -p $(MOD); fi
	install -m 755 $(MODULES) $(MOD)

install-etc: $(CONFFILE)
	@if test ! -d $(CONFMOD); then mkdir -p $(CONFMOD); fi
	for conf in $(CONFFILE) $(CONF); do \
		test -f $(CONFMOD)/$$conf &&  \
			install -m 644 $$conf $(CONFMOD)/$$conf.new || \
			install -m 644 $$conf $(CONFMOD); \
	done

clean:

clobber: clean
	rm -f $(MODULES) $(CONFFILE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .sh .pl -in

.sh : *.sh
	sed 's,/usr/local/etc,$(ETC),; s,/usr/local/share/ncid,$(MOD),' $< > $@
	chmod 755 $@

.pl : *.pl
	sed 's,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod +x $@

-in : *-in
	sed '/$(setmod)/s/https/http/; s,/usr/local/bin,$(BIN),; s,/usr/local/etc,$(ETC),; s,/usr/local/share/ncid,$(MOD),; /$(unset)/s,^,#,; /$(setmac)/s,^#,,' $< > $@
