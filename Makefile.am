#  Copyright (C) 2016 Tobias Oetiker

AUTOMAKE_OPTIONS =  foreign

SUBDIRS = thirdparty lib

BIN = bin/$(SCRIPT_NAME)

MAN = man/$(SCRIPT_NAME).1
POD = doc/$(SCRIPT_NAME).pod

#PERLTESTS := $(shell find t -name "*.t")

THIRDPARTY_DIR := $(shell pwd)/thirdparty

EXTRA_DIST = VERSION PERL_MODULES COPYRIGHT LICENSE CHANGES AUTHORS bootstrap $(wildcard t/*.t) $(BIN) $(PERLTESTS) $(MAN) $(POD)

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)

datadir = $(prefix)

README COPYRIGHT : VERSION
	$(PERL) -i -p -e 's/(#VERSION#|\d+\.\d+\.\d+\S+)/$(PACKAGE_VERSION)/g;s/(#YEAR#|20[1-4]\d)/$(YEAR)/g;s/(#DATE#|20[1-9]\d-[01]\d-[0-3]\d)/$(DATE)/g;' $@

imandir = $(mandir)/man1
iman_DATA = $(MAN)

doc/%.pod: bin/% VERSION
	$(AM_V_GEN)mkdir -p doc;grep -A100000 '=head1 NAME' $< > $@

man/%.1: bin/% VERSION
	$(AM_V_GEN)mkdir -p man; test $(POD2MAN) = "no" || $(POD2MAN) --release=$(VERSION) --center=$(PACKAGE_NAME) $<  > $@

dist_bin_SCRIPTS = $(BIN)

dist-hook: thirdparty
	$(PERL) -i -p -e 's/^our\s+\$$VERSION\s*=\s*".+?";/our \$$VERSION = "$(PACKAGE_VERSION)";/;'  $(distdir)/lib/$(CLASS_NAME)/*.pm

install-exec-hook:
	[ "$(PERL5LIB)" == "" ] || cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# PERL5LIB}{use lib qw($(PERL5LIB)); # PERL5LIB}' $(BIN) || true
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{.*# LIBDIR}{use lib qw($(libdir)); # LIBDIR}' $(BIN)
	cd "$(DESTDIR)$(exec_prefix)" && $(PERL) -i -p -e 's{^#!.*perl.*}{#!$(PERL)};' $(BIN)
	[ ! -d $(THIRDPARTY_DIR)/lib/perl5 ] || cp -fr $(THIRDPARTY_DIR)/lib/perl5/* $(DESTDIR)$(libdir)

#test:
#	$(PERL) "-MExtUtils::Command::MM" "-e" "test_harness(0, 'lib','thirdparty/lib/perl5')" t/*.t

