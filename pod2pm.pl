#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.01 - 20180330";

-d ".git" or exit 0;

my @d = stat "Checklist.pod";
my @m = stat "Checklist.pm";

$d[9] && $m[9] && $m[9] >= $d[9] and exit 0;

my $V;
open my $mh, "<", "Makefile.PL"  or die "No Makefile.PL\n";
while (<$mh>) {
    m/VERSION \s*=\s* "?(\S+)"? \s* ;? $/x or next;
    $V = $1;
    last;
    }
close $mh;

$V or die "Cannot extract version from Makefile.PL\n";

open my $fh, ">", "Checklist.pm" or die "Cannot create pm: $!\n";
print $fh <<"EOPM";
package Release::Checklist;

use strict;
use warnings;

our \$VERSION = "$V";

1;

EOPM
print $fh "__END__\n";

open my $ph, "<", "Checklist.pod" or die "No pod\n";
print $fh (<$ph>);
close $ph;

close $fh;
