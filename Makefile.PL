#!/usr/bin/perl

# Copyright (c) 2015-2018 H.Merijn Brand

require 5.006;
use strict;

our $VERSION = "0.09";

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

tgzdist:
	perl check-versions.pl
	perl -pi -e'm/"version"/ and s{"[0-9]\.[.0-9]+"}{"$VERSION"}' META.json
	jsn2yml < META.json > META.yml
	ln -s . Release-Checklist-$VERSION
	sed "s,^,Release-Checklist-$VERSION/," MANIFEST >Mx
	tar --format=ustar -czv -T Mx -f Release-Checklist-$VERSION.tgz
	rm -f Mx Release-Checklist-$VERSION
	cpants_lint.pl Release-Checklist-$VERSION.tgz
EOPA
    } # postamble
