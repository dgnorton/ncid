MANSRC		= 
SCRIPTS		= ncidd.sh ncid.sh
FILES		= Makefile $(SCRIPTS) $(MANSRC) README

prefix		= /usr/local
prefix2     = $(prefix)

MAN			= $(prefix)/share/man
MAN1		= $(MAN)/man1
ETC			= $(prefix2)/etc
RC			= $(ETC)/rc.d

default: $(SCRIPTS)

man:	$(MANSRC)
	nroff -man $(MANSRC) | col -bx > ncidscripts.man
	chmod 644 ncidscripts.man
	touch man

install: install-scripts

install-scripts: $(SCRIPTS)
	@if test ! -d $(RC); then mkdir -p $(RC); fi
	install -m 755 $(SCRIPTS) $(RC)
	touch install-script

install-man:	$(MAN)
	cd $(MAN1); rm -f $(MANSRC)
	install -m 644 $(MANSRC) $(MAN1)
	touch install-man

clean:

clobber: clean
	rm -f man *.man install-*

files:	$(FILES)
