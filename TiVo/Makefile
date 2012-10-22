SHSRC       = startncid.sh stopncid.sh initmodem.sh
SYMLINKS    = tivocid tivoncid
MODSRC      = ncid-tivo.sh
MANSRC      = ncid-tivo.1
CONF        = ncid-tivo.conf
DIST        =
DOC         = README.TiVo
FILES       = Makefile $(SHSRC) $(MODSRC) $(MANSRC) $(CONF)

prefix      = /usr/local
prefix2     = $(prefix)
prefix3     =

BIN         = $(prefix)/bin
SBIN        = $(prefix)/sbin
SHARE       = $(prefix)/share
ETC         = $(prefix2)/etc
VAR         = $(prefix3)/var

CONFDIR     = $(ETC)/ncid
MAN         = $(SHARE)/man
MOD         = $(SHARE)/ncid
DOCDIR      = $(SHARE)/doc/ncid

CONFMOD     = $(CONFDIR)/conf.d
MAN1        = $(MAN)/man1

SHSCRIPT    = $(SHSRC:.sh=)
MODULE      = $(MODSRC:.sh=)
SITE        = $(DIST:-in=)

OSDCLIENT   = tivoncid

tivo: $(SHSCRIPT) $(MODULE) $(CONF) $(SITE) $(SYMLINKS) txt 

$(SYMLINKS):
	touch ncid
	ln -s ncid $@

txt: $(MANSRC:.1=.1.txt)

html: $(MANSRC:.1=.1.html)

install: install-script install-conf install-mod install-doc

install-script: $(SHSCRIPT)
	@if ! test -d $(BIN); then mkdir -p $(BIN); fi
	install -m 755 $(SHSCRIPT) $(BIN)
	cp -a $(SYMLINKS) $(BIN)

install-conf: $(CONF)
	@if ! test -d $(CONFMOD); then mkdir -p $(CONFMOD); fi
	install -m 644 $(CONF) $(CONFMOD)

install-mod: $(MODULE)
	@if ! test -d $(MOD); then mkdir -p $(MOD); fi
	install -m 755 $(MODULE) $(MOD)

install-man: $(MANSRC)
	@if ! test -d $(MAN1); then mkdir -p $(MAN1); fi
	cd $(MAN1); rm -f $(MANSRC)
	install -m 644 $(MANSRC) $(MAN1)

install-doc: $(DOC)
	@if ! test -d $(DOCDIR); then mkdir -p $(DOCDIR); fi
	install -m 644 $(DOC) $(DOCDIR)

clean:

clobber: clean
	rm -f $(SHSCRIPT) $(MODULE) $(SITE) $(SYMLINKS) ncid *.txt *.html
	rm -f *.txt *.html *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .sh -in .1 .1.txt .1.html

.sh : *.sh
	sed '/OSDCLIENT/s,^OSDCLIENT=tivo,\#OSDCLIENT=tivo,;s,^\#OSDCLIENT=$(OSDCLIENT),OSDCLIENT=$(OSDCLIENT),' $< > $@
	chmod 755 $@

-in : *-in
	sed 's/https/http/; s,/usr/local/bin,$(BIN),; s,/usr/local/etc,$(ETC),; s,/usr/local/share/ncid,$(MOD),' $< > $@

.1.1.txt : *.1
	nroff -man $< | col -bx > $@

.1.1.html : *.1
	man2html $< > $@
