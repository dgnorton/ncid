SCRIPTS     = ncidd.sh ncid.sh ncidsip.sh yac2ncid.sh
FILES       = README Makefile $(SCRIPTS) $(MANSRC)

prefix  = /usr/local
prefix2 = $(prefix)

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

clean:

clobber: clean

distclean: clobber

files: $(FILES)
