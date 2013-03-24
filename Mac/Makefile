PLIST   = net.sourceforge.ncidd.plist \
          net.sourceforge.ncid2ncid.plist \
          net.sourceforge.sip2ncid.plist \
          net.sourceforge.wc2ncid.plist \
          net.sourceforge.yac2ncid.plist \
          net.sourceforge.ncid-initmodem.plist \
          net.sourceforge.ncid-page.plist \
          net.sourceforge.ncid-notify.plist \
          net.sourceforge.ncid-samba.plist \
          net.sourceforge.ncid-speak.plist \
          net.sourceforge.ncid-yac.plist

SCRIPT  = fix-combobox.sh ncid-gui.command.sh

COMMAND = ncid-gui.command

DOC     = README.Mac

FILES   = Makefile $(PLIST) $(DOC) $(SCRIPT)

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
APPDIR  = $(prefix3)/Applications

SITE    = fix-combobox

default: $(PLIST) $(SITE)

install: install-doc install-plist install-command

install-doc: $(DOC) $(SITE)
	@if ! test -d $(DOCDIR); then mkdir -p $(DOCDIR); fi
	install -m 644 $(DOC) $(DOCDIR)
	install -m 755 $(SITE) $(DOCDIR)

install-plist: $(PLIST)
	@if test ! -d $(LAUNCHD); then mkdir -p $(LAUNCHD); fi
	@install -m 644 $(PLIST) $(LAUNCHD)

install-command: $(COMMAND)
	@if test ! -d $(APPDIR); then mkdir -p $(APPDIR); fi
	@install -m 755 $(COMMAND) $(APPDIR)

clean:

clobber: clean
	rm -f $(COMMAND) $(SITE) *.zip *.tar.gz *.tgz

distclean: clobber

files: $(FILES)

.SUFFIXES: .sh

.sh : *.sh
	sed 's,/usr/local,$(prefix),' $< > $@
	chmod +x $@
