MANSRC1 = ncid.1 ncidmodules.1 ncidrotate.1 \
          ncidtools.1 ncid2ncid.1 yac2ncid.1
MANSRCI = cidalias.1 cidcall.1 cidupdate.1 \
          ncid-initmodem.1 ncid-kpopup.1 ncid-page.1 \
          ncid-samba.1 ncid-speak.1 ncid-mythtv.1 \
          ncid-skel.1 ncid-yac.1
MANSRCT = ncid-tivo.1
MANSRC5 = ncidd.blacklist.5 ncid.conf.5 \
          ncidd.conf.5 ncidd.alias.5 ncidmodules.conf.5 \
          ncidrotate.conf.5 ncidsip.conf.5 ncid2ncid.conf.5 \
          sip2ncid.conf.5 yac2ncid.conf.5
MANSRC8 = ncidd.8 ncidsip.8 sip2ncid.8
MANSRC  = $(MANSRC1) $(MANSRCI) $(MANSRC5) $(MANSRC8)
FILES   = Makefile $(MANSRC)

prefix  = /usr/local
prefix2 = $(prefix)

setmod    = NONE

SHARE   = $(prefix)/share

MAN     = $(SHARE)/man
MAN1    = $(MAN)/man1
MAN5    = $(MAN)/man5
MAN8    = $(MAN)/man8

all: txt html

man:

txt: $(MANSRC1:.1=.1.txt) $(MANSRC5:.5=.5.txt) $(MANSRC8:.8=.8.txt)
	chmod 644 *.txt
	touch txt

html: $(MANSRC1:.1=.1.html) $(MANSRC5:.5=.5.html) $(MANSRC8:.8=.8.html)

install: install-man

install-man: $(MANSRC) dirs
	cd $(MAN1); rm -f $(MANSRC1) $(MANSRCI) $(MANSRCT)
	cd $(MAN5); rm -f $(MANSRC5)
	cd $(MAN8); rm -f $(MANSRC8)
	install -m 644 $(MANSRC1) $(MANSRCI) $(MAN1)
	@if [ "$(setmod)" != "NONE" ] ; then install -m 755 $(MANSRCT) $(MAN1); fi
	install -m 644 $(MANSRC5) $(MAN5)
	install -m 644 $(MANSRC8) $(MAN8)

dirs:
	@if ! test -d $(MAN1); then mkdir -p $(MAN1); fi
	@if ! test -d $(MAN5); then mkdir -p $(MAN5); fi
	@if ! test -d $(MAN8); then mkdir -p $(MAN8); fi

clean:

clobber: clean
	rm -f man txt *.man *.txt *.html
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files: $(FILES)

.SUFFIXES: .1 .5 .8 .1.txt .5.txt .8.txt .1.html .5.html .8.html

.1.1.txt : *.1
	nroff -man $< | col -bx > $@

.5.5.txt : *.5
	nroff -man $< | col -bx > $@

.8.8.txt : *.8
	nroff -man $< | col -bx > $@

.1.1.html : *.1
	man2html $< > $@

.5.5.html : *.5
	man2html $< > $@

.8.8.html : *.8
	man2html $< > $@
