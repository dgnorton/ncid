MANSRC1     = ncidscripts.1
MANSRC5     = ncidscript.conf.5
MANSRC		= $(MANSRC1) $(MANSRC2)
SCRIPTS		= ncidrotate ncid-page ncid-samba ncid-speak
CONFIG		= ncidrotate.conf ncidscript.conf
FILES		= Makefile $(SCRIPTS) $(CONFIG) $(MANSRC) README

prefix		= /usr/local
prefix2     = $(prefix)

MAN			= $(prefix)/share/man
MAN1		= $(MAN)/man1
MAN5		= $(MAN)/man5
SHARE		= $(prefix)/share/ncid
ETC			= $(prefix2)/etc
CONFDIR		= $(ETC)/ncid

default: $(SCRIPTS) man

man:	$(MANSRC)
	nroff -man ncidscripts.1 | col -bx > ncidscripts.man
	nroff -man ncidscript.conf.5 | col -bx > ncidscript.conf.man
	chmod 644 *.man
	touch man

install: install-etc install-scripts install-man

install-scripts: $(SCRIPTS)
	@if test ! -d $(SHARE); then mkdir $(SHARE); fi
	install -m 755 $(SCRIPTS) $(SHARE)
	install -m 644 README $(SHARE)/.
	touch install-script

install-etc: $(CONFIG)
	@if test -f $(CONFDIR)/ncidrotate.conf; \
		then install -m 644 ncidrotate.conf $(CONFDIR)/ncidrotate.conf.new; \
		else install -m 644 ncidrotate.conf $(CONFDIR)/.; \
	fi
	@if test -f $(CONFDIR)/ncidscript.conf; \
		then install -m 644 ncidscript.conf $(CONFDIR)/ncidscript.conf.new; \
		else install -m 644 ncidscript.conf $(CONFDIR)/.; \
	fi

install-man:	$(MANSRC)
	cd $(MAN1); rm -f $(MANSRC1)
	cd $(MAN5); rm -f $(MANSRC5)
	install -m 644 $(MANSRC1) $(MAN1)
	install -m 644 $(MANSRC5) $(MAN5)
	touch install-man

clean:

clobber: clean
	rm -f man *.man install-*
	rm -f $(SCRIPTS)

files:	$(FILES)

% : %.sh
	sed '/ConfigDir/s,/usr/local,$(prefix2),' $< > $@
	chmod 755 $@
