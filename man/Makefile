MANSRC1  = ncid.1 \
           ncid2ncid.1 yac2ncid.1 \
           ncid-initmodem.1 ncid-kpopup.1 ncid-notify.1 ncid-page.1 \
           ncid-alert.1 ncid-samba.1 ncid-speak.1 ncid-mythtv.1 \
           ncid-skel.1 ncid-wakeup.1 ncid-yac.1
MANSRC5  = ncidd.blacklist.5 ncidd.whitelist.5 ncid.conf.5 \
           ncidd.conf.5 ncidd.alias.5 \
           ncid2ncid.conf.5 rn2ncid.conf.5 \
           sip2ncid.conf.5 wc2ncid.conf.5 yac2ncid.conf.5
MANSRC7  = ncid-modules.7 ncidtools.7 ncidgateways.7
MANSRC8  = ncidd.8 sip2ncid.8
PERLMAN1 = cidalias.1 cidcall.1 cidupdate.1 rn2ncid.1 wc2ncid.1 wct.1 ncidutil.1
INDEX    = index.md
INDEXADD = index-add.md
IMAGE    = ncid.gif
MANSRC   = $(MANSRC1) $(MANSRC5) $(MANSRC7) $(MANSRC8) $(PERLMAN1)
FILES    = Makefile $(MANSRC) $(MARKDOWN)

prefix   = /usr/local
prefix2  = $(prefix)
prefix3  =

SHARE    = $(prefix)/share

MANMD    = man.md

MAN      = $(SHARE)/man
MAN1     = $(MAN)/man1
MAN5     = $(MAN)/man5
MAN7     = $(MAN)/man7
MAN8     = $(MAN)/man8

man: $(MANSRC)

html: man index $(MANSRC1:.1=.1.html) $(MANSRC5:.5=.5.html) $(MANSRC7:.7=.7.html) $(MANSRC8:.8=.8.html) $(PERLMAN1:.1=.1.html)
	man2html -M man.html ../logrotate/ncidrotate.1 > ncidrotate.1.html
	man2html -M man.html ../logrotate/ncidrotate.conf.5 > ncidrotate.conf.5.html
	man2html -M man.html ../TiVo/ncid-tivo.1 > ncid-tivo.1.html

allhtml: html bigindex
	pod2man ../../lcdncid/lcdncid.pl | man2html -M man.html > lcdncid.1.html
	man2html -M man.html ../../lcdncid/lcdncid.conf.5 > lcdncid.conf.5.html
	man2html -M man.html ../../out2osd/out2osd.1 > out2osd.1.html

txt: $(MANSRC1:.1=.1.txt) $(MANSRC5:.5=.5.txt) $(MANSRC7:.7=.7.txt) $(MANSRC8:.8=.8.txt)
	nroff -man ../logrotate/ncidrotate.1 | col -bx > ncidrotate.1.txt
	nroff -man ../logrotate/ncidrotate.conf.5 | col -bx > ncidrotate.conf.5.txt
	nroff -man ../TiVo/ncid-tivo.1 | col -bx > ncid-tivo.1.txt

$(IMAGE):
	cp -a ../client/ncid.gif .

$(MANMD): $(INDEX) $(IMAGE)
	cat $(INDEX) $(INDEXADD) > $(MANMD)

index: $(INDEX) $(IMAGE)
	cat $(INDEX) > $(MANMD)
	@if type markdown; then make md2html; \
	else echo markdown is required to convert .md files into .html files; \
	echo see README.docdir for more information; fi \

bigindex: $(INDEX) $(INDEXADD) $(IMAGE)
	cat $(INDEX) $(INDEXADD) > $(MANMD)
	@if type markdown; then make md2html; \
	else echo markdown is required to convert .md files into .html files; \
	echo see README.docdir for more information; fi \

md2html: $(MANMD:.md=.html)

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

ncidutil.1:
	pod2man ../tools/ncidutil.pl $@

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
	rm -f $(PERLMAN1) $(IMAGE) $(MANMD)

distclean: clobber

files: $(FILES)

.SUFFIXES: .1 .5 .7 .8 .1.txt .5.txt .7.txt .8.txt .1.html .5.html .7.html .8.html .md .html

.1.1.txt : *.1
	nroff -man $< | col -bx > $@

.5.5.txt : *.5
	nroff -man $< | col -bx > $@

.7.7.txt : *.7
	nroff -man $< | col -bx > $@

.8.8.txt : *.8
	nroff -man $< | col -bx > $@

.1.1.html : *.1
	man2html -M man.html $< > $@

.5.5.html : *.5
	man2html -M man.html $< > $@

.7.7.html : *.7
	man2html -M man.html $< > $@

.8.8.html : *.8
	man2html -M man.html $< > $@

.md.html : *.md
	markdown $< > $@
