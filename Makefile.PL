#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.02";

my $mf = "Makefile";
open my $fh, ">", $mf or die "$mf: $!\n";
print $fh "V = $VERSION\n\n";
print $fh <DATA>;
close $fh;

exit 0;
__END__
.PHONY:	test doc

doc:	Checklist.html Checklist.pod

Checklist.html:	Checklist.md
	perl md2html.pl

Checklist.pod: Checklist.md
	perl md2pod.pl

test:	doc
	perl test-doc.pl
	perl scripts/pod-spell-check --aspell --ispell
	prove -w t

dist:
	perl check-versions.pl
	perl -pi -e'm/"version"/ and s{"[0-9]\.[.0-9]+"}{"$(V)"}' META.json
	tar -czv -T MANIFEST -f Release-Checklist-$(V).tgz
	cpants_lint.pl Release-Checklist-$(V).tgz

distclean:
	@echo NYI
