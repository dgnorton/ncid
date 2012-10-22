SHSCRIPT  = ncidrotate.sh
ETCCONF   = ncidrotate.conf
LOGCONF   = ncid.logrotate
MANSRC    = ncidrotate.1
FILES     = README.logrotate Makefile \
            $(SHSCRIPT) $(ETCCONF) $(LOGCONF) $(MANSRC)

prefix    = /usr/local
prefix2   = $(prefix)
prefix3   =

SHARE     = $(prefix)/share
ETC       = $(prefix2)/etc
CONFDIR   = $(ETC)/ncid
ROTATEDIR = $(ETC)/logrotate.d

MOD       = $(SHARE)/ncid
MAN       = $(SHARE)/man

MAN1      = $(MAN)/man1

ROTATE  = $(LOGCONF:.logrotate=)
SCRIPTS = $(SHSCRIPT:.sh=)

logrotate: $(ROTATE) $(SCRIPTS)

install: install-etc install-scripts install-logrotate install-man

install-scripts: $(SCRIPTS)
	@if test ! -d $(MOD); then mkdir -p $(MOD); fi
	install -m 755 $(SCRIPTS) $(MOD)

install-etc: $(ETCCONF)
	@if test ! -d $(CONFDIR); then mkdir -p $(CONFDIR); fi
	@if test -f $(CONFDIR)/$(ETCCONF); \
		then install -m 644 $(ETCCONF) $(CONFDIR)/$(ETCCONF).new; \
		else install -m 644 $(ETCCONF) $(CONFDIR); \
	fi

install-logrotate: $(ROTATE)
	@if test ! -d $(ROTATEDIR); then mkdir -p $(ROTATEDIR); fi
	install -m 644 ncid $(ROTATEDIR)

install-man: $(MANSOURCE)
	@if ! test -d $(MAN1); then mkdir -p $(MAN1); fi
	cd $(MAN1); rm -f $(MANSRC)
	install -m 644 $(MANSRC) $(MAN1)

clean:

clobber: clean
	rm -f $(ROTATE) $(SCRIPTS)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .sh .logrotate

.sh : *.sh
	sed 's,/usr/local/etc,$(ETC),' $< > $@
	chmod 755 $@

.logrotate : *.logrotate
	sed 's,/usr/local/share,$(SHARE),' $< > $@
