SHSCRIPT  = ncidrotate.sh
ETCCONF   = ncidrotate.conf
LOGCONF   = ncid.logrotate
FILES     = README.scripts Makefile $(SHSCRIPT) $(ETCCONF) $(LOGCONF)

prefix    = /usr/local
prefix2   = $(prefix)
prefix3   =

SHARE     = $(prefix)/share/ncid
ETC       = $(prefix2)/etc
CONFDIR   = $(ETC)/ncid
ROTATEDIR = $(ETC)/logrotate.d

ROTATE  = $(LOGCONF:.logrotate=)
SCRIPTS = $(SHSCRIPT:.sh=)

scripts: $(ROTATE) $(SCRIPTS)

install: install-etc install-scripts install-logrotate

install-scripts: $(SCRIPTS)
	@if test ! -d $(SHARE); then mkdir -p $(SHARE); fi
	install -m 755 $(SCRIPTS) $(SHARE)

install-etc: $(ETCCONF)
	@if test ! -d $(CONFDIR); then mkdir -p $(CONFDIR); fi
	@if test -f $(CONFDIR)/$(ETCCONF); \
		then install -m 644 $(ETCCONF) $(CONFDIR)/$(ETCCONF).new; \
		else install -m 644 $(ETCCONF) $(CONFDIR); \
	fi

install-logrotate: $(ROTATE)
	@if test ! -d $(ROTATEDIR); then mkdir -p $(ROTATEDIR); fi
	install -m 644 ncid $(ROTATEDIR)

clean:

clobber: clean
	rm -f $(ROTATE) $(SCRIPTS)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .sh .logrotate

.sh : *.sh
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod 755 $@

.logrotate : *.logrotate
	sed '/share/s,/usr/local,$(prefix),' $< > $@
