# makefile to produce html documentation

DOCS  = Documentation.md \
		GettingStarted.md \
		Devices.md \
		Modems.md \
		Gateways.md \
		FAQ.md \
		INSTALL.md \
		INSTALL-Cygwin.md \
		INSTALL-Fedora.md \
		INSTALL-FreeBSD.md \
		INSTALL-Mac.md \
		INSTALL-Raspbian.md \
		INSTALL-Redhat.md \
		INSTALL-TiVo.md \
		INSTALL-Ubuntu.md \
		INSTALL-Win.md \
		Verbose.md \
		CONTRIBUTORS.md \
		TODO.md

API   = NCID-API.odt

MD    = NCID_Documentation.md
HTML  = $(MD:.md=.html)

FILES = Makefile $(DOCS)

prefix   = /usr/local
prefix2  = $(prefix)
prefix3  =

SHARE    = $(prefix)/share

doc: $(MD)

$(MD): $(DOCS)
	# Removed the Last Edited Date from the top of the individual files
	sed '/^Last edited/d' $(DOCS) > $@

html: $(MD)
	# markdown is required to convert .md files into .html files
	# see README.docdir for more information
	@if type markdown; then make $(HTML); \
	else echo markdown is required to convert .md files into .html files; \
	echo see README.docdir for more information; fi

epub: $(MD)
	sh mk-epub

$(HTML): $(MD)

htmlfiles: $(DOCS:.md=.html)

NCID-API.pdf: $(API)
	soffice --headless --convert-to pdf $(API)

sdk: NCID-API.pdf NCID-SDK.md test
	tar -czf NCID-SDK.tar.gz NCID-API.pdf NCID-SDK.md test

test:
	cp -a ../test .

clean:

clobber: clean
	rm -f NCID_Documentation.md *.epub *.html *.bak *.pdf *.gz
	rm -fr test

distclean: clobber

.SUFFIXES: .md .html

.md.html : *.md $(MD)
	markdown $< > $@
