RCF     = ncidd.rc ncidsip.rc sip2ncid.rc yac2ncid.rc \
          ncid-mythtv.rc ncid-page.rc ncid-popup.rc ncid-samba.rc \
          ncid-speak.rc ncid-yac.rc
FILES   = README Makefile $(RCF) $(MANSRC)

prefix  = /usr/local
prefix2 = $(prefix)

ETC     = $(prefix2)/etc
RCD     = $(ETC)/rc.d
CONFDIR = $(ETC)/ncid

SITE    = $(RCF:.rc=)

rcd: $(SITE)

man: $(MANSRC1:.1=.man)
	chmod 644 *.man
	touch man

html: $(MANSRC1:.1=.html)

install: install-rcd

install-rcd: $(RCF)
	@if test ! -d $(RCD); then mkdir -p $(RCD); fi
	install -m 755 $(SITE) $(RCD)

clean:

clobber: clean
	rm -f $(SITE)

distclean: clobber

files: $(FILES)

% : %.rc
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod +x $@
