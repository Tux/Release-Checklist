#!/usr/bin/perl

# Copyright (c) 2015-2019 H.Merijn Brand

require 5.006;
use strict;

our $VERSION = "0.10";

use ExtUtils::MakeMaker;

my %wm = (
    NAME      => "Release::Checklist",
    DISTNAME  => "Release-Checklist",
    ABSTRACT  => "A QA checklist for CPAN releases",
    AUTHOR    => "H.Merijn Brand <h.merijn\@xs4all.nl>",
    VERSION   => $VERSION,
    PREREQ_PM => { "Test::More" => 0.88                      },
    macro     => { TARFLAGS     => "--format=ustar -c -v -f" },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble {
    <<"EOPA";
VERSION = $VERSION

.PHONY:	test doc

all::		Checklist.pm

doc:		Checklist.html Checklist.pod

Checklist.html:	Checklist.md
	perl md2html.pl

Checklist.pod:	Checklist.md
	perl md2pod.pl

Checklist.pm:	doc
	perl pod2pm.pl

test::		doc
	perl scripts/pod-spell-check --aspell --ispell

spellcheck:
	pod-spell-check --aspell --ispell

checkmeta:	spellcheck
	perl sandbox/genMETA.pl -c

fixmeta:	distmeta
	perl sandbox/genMETA.pl

tgzdist:	checkmeta fixmeta \$(DISTVNAME).tar.gz distcheck
	-\@mv -f \$(DISTVNAME).tar.gz \$(DISTVNAME).tgz
	-\@cpants_lint.pl \$(DISTVNAME).tgz
	-\@rm -f Debian_CPANTS.txt
EOPA
    } # postamble
