SHSOURCE	= startncid.sh initmodem.sh
ETCFILE     =
FILES		= Makefile $(SHSOURCE) $(MANSRC)
DIST        =

prefix		= /usr/local
prefix2		= $(prefix)
prefix3		=

BIN			= $(prefix)/bin
SBIN		= $(prefix)/sbin
SHARE       = $(prefix)/share
ETC			= $(prefix2)/etc
VAR         = $(prefix3)/var

INIT        = $(ETC)/rc.d/init.d
CONFDIR		= $(ETC)/ncid
LOG			= $(VAR)/log
MAN         = $(SHARE)/man

CONF		= $(CONFDIR)/ncidd.conf
ALIAS		= $(CONFDIR)/ncidd.alias
CALLLOG		= $(LOG)/cidcall.log
DATALOG		= $(LOG)/ciddata.log
MAN1		= $(MAN)/man1

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)
SITE        = $(DIST:-in=)

tivo: $(SHSCRIPT) $(SITE)

install: install-script

install-script: $(SHSCRIPT)
	install -m 755 $(SHSCRIPT) $(BIN)

clean:

clobber: clean
	rm -f $(SHSCRIPT) $(SITE)
	rm -f *.zip *.tar.gz *.tgz

distclean: clobber

files:	$(FILES)

.SUFFIXES: .pl .sh -in

.pl : *.pl
	sed 's,/etc/ncid/ncidd.alias,$(ALIAS),; s,/etc/ncid/ncidd.conf,$(CONF),; s,/var/log/cidcall.log,$(CALLLOG),' $< > $@
	chmod +x $@

.sh : *.sh
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
	chmod 755 $@

-in : *-in
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
