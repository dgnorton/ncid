MANSRC1		= ncidtools.1
SOURCE		= cidlog.pl cidalias.pl cidlogupd.pl
FILES		= Makefile $(SOURCE) $(MANSRC)

prefix		= /usr/local
prefix2		= $(prefix)
prefix3		=

BIN			= $(prefix)/bin
MAN			= $(prefix)/share/man
ETC			= $(prefix2)/etc
LOG			= $(prefix3)/var/log

CONFDIR		= $(ETC)/ncid
CONF		= $(CONFDIR)/ncidd.conf
ALIAS		= $(CONFDIR)/ncidd.alias
CALLLOG		= $(LOG)/cidcall.log
DATALOG		= $(LOG)/ciddata.log
MAN1		= $(MAN)/man1

SCRIPT = $(SOURCE:.pl=)

default: $(SCRIPT)

all: $(SCRIPT) man

man:	$(MANSRC1)
	nroff -man ncidtools.1 | col -bx > ncidtools.man
	chmod 644 *.man
	touch man

install: install-script install-man

install-script: $(SCRIPT)
	install -m 755 $(SCRIPT) $(BIN)
	touch install-script

install-man:	$(MANSRC1)
	cd $(MAN1); rm -f $(MANSRC1)
	install -m 644 $(MANSRC1) $(MAN1)
	touch install-man

clean:

clobber: clean
	rm -f $(SCRIPT)
	rm -f man *.man install-*

files:	$(FILES)

% : %.pl
	sed 's,/etc/ncid/ncidd.alias,$(ALIAS),; s,/etc/ncid/ncidd.conf,$(CONF),; s,/var/log/cidcall.log,$(CALLLOG),' $< > $@
	chmod +x $@
