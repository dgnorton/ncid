SCRIPTS = ncidrotate ncid-page ncid-samba ncid-speak
CONFIG  = ncidrotate.conf ncidscript.conf
FILES   = Makefile $(SCRIPTS) $(CONFIG) $(MANSRC) README

prefix  = /usr/local
prefix2 = $(prefix)

SHARE   = $(prefix)/share/ncid
ETC     = $(prefix2)/etc
CONFDIR = $(ETC)/ncid

scripts: $(SCRIPTS)

install: install-etc install-scripts

install-scripts: $(SCRIPTS)
	@if test ! -d $(SHARE); then mkdir $(SHARE); fi
	install -m 755 $(SCRIPTS) $(SHARE)
	install -m 644 README $(SHARE)/.

install-etc: $(CONFIG)
	@if test -f $(CONFDIR)/ncidrotate.conf; \
		then install -m 644 ncidrotate.conf $(CONFDIR)/ncidrotate.conf.new; \
		else install -m 644 ncidrotate.conf $(CONFDIR)/.; \
	fi
	@if test -f $(CONFDIR)/ncidscript.conf; \
		then install -m 644 ncidscript.conf $(CONFDIR)/ncidscript.conf.new; \
		else install -m 644 ncidscript.conf $(CONFDIR)/.; \
	fi

clean:

clobber: clean
	rm -f $(SCRIPTS)

files:	$(FILES)

% : %.sh
	sed '/ConfigDir/s,/usr/local,$(prefix2),' $< > $@
	chmod 755 $@
