SHSOURCE    = startncid.sh stopncid.sh initmodem.sh
SYMLINKS    = tivocid tivoncid
ETCFILE     =
FILES       = Makefile $(SHSOURCE) $(MANSRC)
DIST        =

prefix      = /usr/local
prefix2     = $(prefix)
prefix3     =

BIN         = $(prefix)/bin
SBIN        = $(prefix)/sbin
SHARE       = $(prefix)/share
ETC         = $(prefix2)/etc
VAR         = $(prefix3)/var

INIT        = $(ETC)/rc.d/init.d
CONFDIR     = $(ETC)/ncid
LOG         = $(VAR)/log
MAN         = $(SHARE)/man

CONF        = $(CONFDIR)/ncidd.conf
ALIAS       = $(CONFDIR)/ncidd.alias
CALLLOG     = $(LOG)/cidcall.log
DATALOG     = $(LOG)/ciddata.log
MAN1        = $(MAN)/man1

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)
SITE        = $(DIST:-in=)

OSDCLIENT   = tivoncid

tivo: $(SHSCRIPT) $(SITE) $(SYMLINKS)

$(SYMLINKS):
	touch ncid
	ln -s ncid $@

install: install-script

install-script: $(SHSCRIPT)
	install -m 755 $(SHSCRIPT) $(BIN)
	cp -a $(SYMLINKS) $(BIN)

clean:

clobber: clean
	rm -f $(SHSCRIPT) $(SITE) $(SYMLINKS) ncid
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .sh

.sh : *.sh
	sed '/OSDCLIENT/s,^OSDCLIENT=tivo,\#OSDCLIENT=tivo,;s,^\#OSDCLIENT=$(OSDCLIENT),OSDCLIENT=$(OSDCLIENT),' $< > $@
	chmod 755 $@
