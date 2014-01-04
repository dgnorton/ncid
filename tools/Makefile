PLSOURCE	= cidcall.pl cidalias.pl cidupdate.pl wct.pl ncidutil.pl
SHSOURCE	= 
ETCFILE     =
FILES		= Makefile $(PLSOURCE) $(SHSOURCE) $(MANSRC)
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
CIDLOG  	= $(LOG)/cidcall.log
DATALOG		= $(LOG)/ciddata.log
MAN1		= $(MAN)/man1

PLSCRIPT    = $(PLSOURCE:.pl=)
SHSCRIPT    = $(SHSOURCE:.sh=)
SITE        = $(DIST:-in=)

Version := $(shell sed 's/.* //; 1q' ../VERSION)

tools: $(PLSCRIPT) $(SHSCRIPT) $(SITE)

install: install-script

#install-script: $(PLSCRIPT) $(SHSCRIPT)
#	install -m 755 $(PLSCRIPT) $(SHSCRIPT) $(BIN)
install-script: $(PLSCRIPT)
	install -m 755 $(PLSCRIPT) $(BIN)

clean:

clobber: clean
	rm -f $(PLSCRIPT) $(SHSCRIPT) $(SITE)
	rm -f *.zip *.tar.gz *.tgz rm *.log

distclean: clobber

files:	$(FILES)

.SUFFIXES: .pl .sh -in

.pl : *.pl
	sed 's,/etc/ncid/ncidd.alias,$(ALIAS),; s,/etc/ncid/ncidd.conf,$(CONF),;s/XxXxX/$(Version)/;s,/var/log/cidcall.log,$(CIDLOG),' $< > $@
	chmod +x $@

.sh : *.sh
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),;s/XxXxX/$(Version)/' $< > $@
	chmod 755 $@

-in : *-in
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
