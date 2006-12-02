SOURCE		= cidcall.pl cidalias.pl cidupdate.pl ncidsip.pl
FILES		= Makefile $(SOURCE) $(MANSRC)
DIST        = ncidsip.init.dist

prefix		= /usr/local
prefix2		= $(prefix)
prefix3		=

BIN			= $(prefix)/bin
SBIN		= $(prefix)/sbin
ETC			= $(prefix2)/etc
INIT        = $(ETC)/rc.d/init.d
LOG			= /var/log

CONFDIR		= $(ETC)/ncid
CONF		= $(CONFDIR)/ncidd.conf
ALIAS		= $(CONFDIR)/ncidd.alias
CALLLOG		= $(LOG)/cidcall.log
DATALOG		= $(LOG)/ciddata.log
MAN1		= $(MAN)/man1

SCRIPT      = $(SOURCE:.pl=)
SITE        = $(DIST:.dist=)

tools: $(SCRIPT) $(SITE)

install: install-script install-etc install-init

install-script: $(SCRIPT)
	install -m 755 $(SCRIPT) $(BIN)
	rm -f $(BIN)/ncidsip
	install -m 755 ncidsip $(SBIN)
	touch install-script

install-etc: ncidsip.conf
	@if test -f $(CONFDIR)/ncidsip.conf; \
		then install -m 644 ncidsip.conf $(CONFDIR)/ncidsip.conf.new; \
		else install -m 644 ncidsip.conf $(CONFDIR); \
	fi

install-init: ncidsip.init
	@if test -d $(INIT); then \
		install -m 755 ncidsip.init $(INIT)/ncidsip; \
		else echo "skipping ncidsip.init install, no directory: $(INIT)"; \
	fi

clean:

clobber: clean
	rm -f $(SCRIPT) $(SITE)
	rm -f man *.man install-*

files:	$(FILES)

% : %.pl
	sed 's,/etc/ncid/ncidd.alias,$(ALIAS),; s,/etc/ncid/ncidd.conf,$(CONF),; s,/var/log/cidcall.log,$(CALLLOG),' $< > $@
	chmod +x $@

% : %.dist
	sed '/ConfigDir/s,/usr/local/etc/ncid,$(CONFDIR),' $< > $@
