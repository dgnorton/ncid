MANSRC1     =
MANSRC      = $(MANSRC1)
SCRIPTS     = ncidd.sh ncid.sh
FILES       = Makefile $(SCRIPTS) $(MANSRC) README

prefix  = /usr/local
prefix2 = $(prefix)

MAN     = $(prefix)/man
MAN1    = $(MAN)/man1
ETC     = $(prefix2)/etc
RC      = $(ETC)/rc.d

default: $(SCRIPTS)

man: $(MANSRC1:.1=.man)
	chmod 644 *.man
	touch man

html: $(MANSRC1:.1=.html)

install: install-scripts

install-scripts: $(SCRIPTS)
	@if test ! -d $(RC); then mkdir -p $(RC); fi
	install -m 755 $(SCRIPTS) $(RC)

install-man: $(MAN)
	cd $(MAN1); rm -f $(MANSRC1)
	install -m 644 $(MANSRC1) $(MAN1)

clean:

clobber: clean
	rm -f man *.man install-*

files: $(FILES)

%.man : %.1
	nroff -man $< | col -bx > $@

%.html : %.1
	man2html $< > $@
