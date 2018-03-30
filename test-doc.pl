#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.01 - 20180330";

-d ".git" or exit 0;

eval "use Text::Markdown qw( markdown )" or exit 0;
$@ and exit 0;

foreach my $md (sort glob "*.md") {
    print "$md\n";
    open my $fh, "<", $md or next;
    local $/;
    # No idea if this really *checks* if the .md is valid
    markdown (<$fh>);
    close $fh;
    }
