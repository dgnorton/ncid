RCF     = ncidd.rc ncid2ncid.rc rn2ncid.rc sip2ncid.rc wc2ncid.rc \
          yac2ncid.rc ncid-mythtv.rc ncid-notify.rc ncid-page.rc \
          ncid-samba.rc ncid-speak.rc ncid-yac.rc ncid-initmodem.rc
DOC     = README.FreeBSD
FILES   = Makefile $(RCF) $(DOC)

prefix  = /usr/local
prefix2 = $(prefix)
prefix3 =

SHARE   = $(prefix)/share
ETC     = $(prefix2)/etc

RCD     = $(ETC)/rc.d
CONFDIR = $(ETC)/ncid
MAN     = $(SHARE)/man
MOD     = $(SHARE)/ncid
DOCDIR  = $(SHARE)/doc/ncid

SITE    = $(RCF:.rc=)

rcd: $(SITE)

install: install-rcd install-doc

install-rcd: $(RCF)
	@if test ! -d $(RCD); then mkdir -p $(RCD); fi
	install -m 755 $(SITE) $(RCD)

install-doc: $(DOC)
	@if ! test -d $(DOCDIR); then mkdir -p $(DOCDIR); fi
	install -m 644 $(DOC) $(DOCDIR)

clean:

clobber: clean
	rm -f $(SITE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files: $(FILES)

.SUFFIXES: .rc

.rc : *.rc
	sed 's,/usr/local/etc,$(ETC),' $< > $@
	chmod +x $@
