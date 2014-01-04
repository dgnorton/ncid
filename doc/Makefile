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

$(HTML): $(MD)

htmlfiles: $(DOCS:.md=.html)

clean:

clobber: clean
	rm -f NCID_Documentation.md *.html *.bak

distclean: clobber

.SUFFIXES: .md .html

.md.html : *.md $(MD)
	markdown $< > $@
