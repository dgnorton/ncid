MANSRC1  = ncid.1 \
           ncid2ncid.1 yac2ncid.1 \
           ncid-initmodem.1 ncid-kpopup.1 ncid-notify.1 ncid-page.1 \
           ncid-alert.1 ncid-samba.1 ncid-speak.1 ncid-mythtv.1 \
           ncid-skel.1 ncid-wakeup.1 ncid-yac.1
MANSRC5  = ncidd.blacklist.5 ncidd.whitelist.5 ncid.conf.5 \
           ncidd.conf.5 ncidd.alias.5 \
           ncidrotate.conf.5 ncid2ncid.conf.5 rn2ncid.conf.5 \
           sip2ncid.conf.5 wc2ncid.conf.5 yac2ncid.conf.5
MANSRC7  = ncid-modules.7 ncidtools.7 ncidgateways.7
MANSRC8  = ncidd.8 sip2ncid.8
PERLMAN1 = cidalias.1 cidcall.1 cidupdate.1 rn2ncid.1 wc2ncid.1 wct.1
MANSRC   = $(MANSRC1) $(MANSRC5) $(MANSRC7) $(MANSRC8) $(PERLMAN1)
FILES    = Makefile $(MANSRC)

prefix   = /usr/local
prefix2  = $(prefix)

SHARE    = $(prefix)/share

MAN      = $(SHARE)/man
MAN1     = $(MAN)/man1
MAN5     = $(MAN)/man5
MAN7     = $(MAN)/man7
MAN8     = $(MAN)/man8

man: $(PERLMAN1)

all: man txt html

txt: $(MANSRC1:.1=.1.txt) $(MANSRC5:.5=.5.txt) $(MANSRC7:.7=.7.txt) $(MANSRC8:.8=.8.txt)

html: $(MANSRC1:.1=.1.html) $(MANSRC5:.5=.5.html) $(MANSRC7:.7=.7.html) $(MANSRC8:.8=.8.html)

install: install-man

rn2ncid.1:
	pod2man ../gateway/rn2ncid.pl $@

wc2ncid.1:
	pod2man ../gateway/wc2ncid.pl $@

cidalias.1:
	pod2man ../tools/cidalias.pl $@

cidcall.1:
	pod2man ../tools/cidcall.pl $@

cidupdate.1:
	pod2man ../tools/cidupdate.pl $@

wct.1:
	pod2man ../tools/wct.pl $@

install-man: $(MANSRC) dirs
	cd $(MAN1); rm -f $(MANSRC1) $(PERLMAN1)
	cd $(MAN5); rm -f $(MANSRC5)
	cd $(MAN7); rm -f $(MANSRC7)
	cd $(MAN8); rm -f $(MANSRC8)
	install -m 644 $(MANSRC1) $(PERLMAN1) $(MAN1)
	install -m 644 $(MANSRC5) $(MAN5)
	install -m 644 $(MANSRC7) $(MAN7)
	install -m 644 $(MANSRC8) $(MAN8)

dirs:
	@if ! test -d $(MAN1); then mkdir -p $(MAN1); fi
	@if ! test -d $(MAN5); then mkdir -p $(MAN5); fi
	@if ! test -d $(MAN7); then mkdir -p $(MAN7); fi
	@if ! test -d $(MAN8); then mkdir -p $(MAN8); fi

clean:

clobber: clean
	rm -f txt *.man *.txt *.html
	rm -f *.zip *.tar.gz *.tgz
	rm -f $(PERLMAN1)

distclean: clobber

files: $(FILES)

.SUFFIXES: .1 .5 .7 .8 .1.txt .5.txt .7.txt .8.txt .1.html .5.html .7.html .8.html

.1.1.txt : *.1
	nroff -man $< | col -bx > $@

.5.5.txt : *.5
	nroff -man $< | col -bx > $@

.7.7.txt : *.7
	nroff -man $< | col -bx > $@

.8.8.txt : *.8
	nroff -man $< | col -bx > $@

.1.1.html : *.1
	man2html $< > $@

.5.5.html : *.5
	man2html $< > $@

.7.7.html : *.7
	man2html $< > $@

.8.8.html : *.8
	man2html $< > $@
