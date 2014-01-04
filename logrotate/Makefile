SHSCRIPT  = ncidrotate.sh
ETCCONF   = ncidrotate.conf
LOGCONF   = ncid.logrotate
MANSRC1   = ncidrotate.1
MANSRC5   = ncidrotate.conf.5
MANSRC    = $(MANSRC1) $(MANSRC5)
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
MAN5      = $(MAN)/man5

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

install-man: $(MANSRC1) $(MANSRC5)
	@if ! test -d $(MAN1); then mkdir -p $(MAN1); fi
	cd $(MAN1); rm -f $(MANSRC1)
	install -m 644 $(MANSRC1) $(MAN1)
	@if ! test -d $(MAN5); then mkdir -p $(MAN5); fi
	cd $(MAN5); rm -f $(MANSRC5)
	install -m 644 $(MANSRC5) $(MAN5)

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
