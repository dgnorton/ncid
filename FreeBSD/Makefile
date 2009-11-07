RCF     = ncidd.rc ncidsip.rc sip2ncid.rc yac2ncid.rc \
          ncid-kpopup.rc ncid-mythtv.rc ncid-page.rc ncid-samba.rc \
          ncid-speak.rc ncid-yac.rc ncid-hangup.rc
FILES   = README.FreeBSD Makefile $(RCF)

prefix  = /usr/local
prefix2 = $(prefix)

ETC     = $(prefix2)/etc
RCD     = $(ETC)/rc.d
CONFDIR = $(ETC)/ncid

SITE    = $(RCF:.rc=)

rcd: $(SITE)

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
