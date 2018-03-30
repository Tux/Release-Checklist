#!/pro/bin/perl

my $mf = "Makefile";
open my $fh, ">", $mf or die "$mf: $!\n";
print $fh <DATA>;
close $fh;

exit 0;
__END__
.PHONY:	test doc

V = $(shell perl -ne'if (s/^[.0-9]+\K.*//s) { print; exit }' ChangeLog)

all:	doc test

doc:	Checklist.html Checklist.pod test

Checklist.html:	Checklist.md
	@echo '<?xml version="1.0" encoding="iso-8859-1"?>' >Checklist.html
	@echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">' >>Checklist.html
	@echo '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">' >>Checklist.html
	@echo '<head>' >>Checklist.html
	@echo '  <title>Release Checklist</title>' >>Checklist.html
	@echo '  </head>' >>Checklist.html
	@echo '<body>' >>Checklist.html
	multimarkdown Checklist.md >> Checklist.html
	@echo '</body></html>' >>Checklist.html

Checklist.pod: Checklist.md
	markdown2pod  Checklist.md >  Checklist.pod

test:
	-@make Checklist.pod
	pod-spell-check --aspell --ispell
	# No idea if this really *checks* if the .md is valid
	perl -MText::Markdown=markdown -0 -wE'for(glob"*.md"){say;@ARGV=$$_;markdown (<>)}'

dist:
	perl -pi -e'm/"version"/ and s{"[0-9]\.[.0-9]+"}{"$(V)"}' META.json
	tar -czv -T MANIFEST -f Release-Checklist-$(V).tgz
	cpants_lint.pl Release-Checklist-$(V).tgz
