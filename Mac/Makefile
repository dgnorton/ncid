PLISTD  = net.sourceforge.ncidd.plist \
          net.sourceforge.ncid2ncid.plist \
          net.sourceforge.sip2ncid.plist \
          net.sourceforge.yac2ncid.plist \
          net.sourceforge.ncid-initmodem.plist \
          net.sourceforge.ncid-page.plist \
          net.sourceforge.ncid-notify.plist \
          net.sourceforge.ncid-samba.plist \
          net.sourceforge.ncid-speak.plist \
          net.sourceforge.ncid-yac.plist
PLISTA  = net.sourceforge.ncid-gui.plist
DOC     = README.Mac

FILES   = Makefile $(PLISTD) $(PLISTA) $(DOC)

prefix  = /usr/local
prefix2 = $(prefix)
prefix3 =

SHARE   = $(prefix)/share
ETC     = $(prefix2)/etc

CONFDIR = $(ETC)/ncid
MAN     = $(SHARE)/man
MOD     = $(SHARE)/ncid
DOCDIR  = $(SHARE)/doc/ncid

LAUNCHD = $(prefix3)/Library/LaunchDaemons
LAUNCHA = $(prefix3)/Library/LaunchAgents

SITE    =

plist: $(PLISTD) $(PLISTA)

install: install-doc install-plistd install-plista

install-doc: $(DOC)
	@if ! test -d $(DOCDIR); then mkdir -p $(DOCDIR); fi
	install -m 644 $(DOC) $(DOCDIR)

install-plistd: $(PLISTD)
	@if test ! -d $(LAUNCHD); then mkdir -p $(LAUNCHD); fi
	@install -m 644 $(PLISTD) $(LAUNCHD)

install-plista: $(PLISTA)
	@if test ! -d $(LAUNCHA); then mkdir -p $(LAUNCHA); fi
	@install -m 644 $(PLISTA) $(LAUNCHA)

clean:

clobber: clean
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files: $(FILES)

.SUFFIXES: .sh

.sh : *.sh
	sed 's,/usr/local,$(prefix),' $< > $@
	chmod +x $@
