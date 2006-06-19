MANSRC1 = ncid.1 ncidscripts.1 ncidtools.1
MANSRC5 = ncid.conf.5 ncidd.conf.5 ncidd.alias.5 ncidscript.conf.5
MANSRC8 = ncidd.8 ncidsip.8
MANSRC  = $(MANSRC1) $(MANSRC5) $(MANSRC8)
FILES   = Makefile $(MANSRC)

prefix  = /usr/local
prefix2 = $(prefix)

MAN     = $(prefix)/share/man
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
	cd $(MAN1); rm -f $(MANSRC1)
	cd $(MAN5); rm -f $(MANSRC5)
	cd $(MAN8); rm -f $(MANSRC8)
	install -m 644 $(MANSRC1) $(MAN1)
	install -m 644 $(MANSRC5) $(MAN5)
	install -m 644 $(MANSRC8) $(MAN8)

dirs:
	@if ! test -d $(MAN1); then mkdir -p $(MAN1); fi
	@if ! test -d $(MAN5); then mkdir -p $(MAN5); fi
	@if ! test -d $(MAN8); then mkdir -p $(MAN8); fi

clean:

clobber: clean
	rm -f man txt *.man *.txt *.html

files: $(FILES)

%.1.txt : %.1
	nroff -man $< | col -bx > $@

%.5.txt : %.5
	nroff -man $< | col -bx > $@

%.8.txt : %.8
	nroff -man $< | col -bx > $@

%.1.html : %.1
	man2html $< > $@

%.5.html : %.5
	man2html $< > $@

%.8.html : %.8
	man2html $< > $@
