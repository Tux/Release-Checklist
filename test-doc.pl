#!/pro/bin/perl

use strict;
use warnings;

use Test::More;

our $VERSION = "0.02 - 20180409";

-d ".git" or exit 0;

my $tmd = eval { require Text::Markdown;          1; };
my $tmh = eval { require Text::Markdown::Hoedown;
    Text::Markdown::Hoedown::HOEDOWN_EXT_AUTOLINK ()
  | Text::Markdown::Hoedown::HOEDOWN_EXT_STRIKETHROUGH ()
  | Text::Markdown::Hoedown::HOEDOWN_EXT_UNDERLINE ()
  | Text::Markdown::Hoedown::HOEDOWN_EXT_HIGHLIGHT ()
  | Text::Markdown::Hoedown::HOEDOWN_EXT_NO_INTRA_EMPHASIS ();
  };

foreach my $mdf (sort glob "*.md") {
    ok (my $md = do {
	open my $fh, "<", $mdf or next;
	local $/;
	<$fh>;
	}, $mdf);
    # No idea if this really *checks* if the .md is valid
    if ($tmd) {
	my $html = Text::Markdown::markdown          ($md);
	like ($html, qr{^<\w+}, "Got html with Text::Markdown          for $mdf");
	}
    if ($tmh) {
	my $html = Text::Markdown::Hoedown::markdown ($md, extensions => $tmh);
	like ($html, qr{^<\w+}, "Got html with Text::Markdown::Hoedown for $mdf");
	}
    }

done_testing ();
