SOURCE		= cidlog.pl cidalias.pl cidlogupd.pl
FILES		= Makefile $(SOURCE) $(MANSRC)

prefix		= /usr/local
prefix2		= $(prefix)
prefix3		=

BIN			= $(prefix)/bin
ETC			= $(prefix2)/etc
LOG			= $(prefix3)/var/log

CONFDIR		= $(ETC)/ncid
CONF		= $(CONFDIR)/ncidd.conf
ALIAS		= $(CONFDIR)/ncidd.alias
CALLLOG		= $(LOG)/cidcall.log
DATALOG		= $(LOG)/ciddata.log

SCRIPT = $(SOURCE:.pl=)

tools: $(SCRIPT)

install: install-script

install-script: $(SCRIPT)
	install -m 755 $(SCRIPT) $(BIN)

clean:

clobber: clean
	rm -f $(SCRIPT)

files:	$(FILES)

% : %.pl
	sed 's,/etc/ncid/ncidd.alias,$(ALIAS),; s,/etc/ncid/ncidd.conf,$(CONF),; s,/var/log/cidcall.log,$(CALLLOG),' $< > $@
	chmod +x $@
