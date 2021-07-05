#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.03 - 20190829";

my $fmd  = "Checklist.md";
my $fpod = "Checklist.pod";
my $fpm  = "Checklist.pm";
my $mpl  = "Makefile.PL";

-d ".git" or exit 0;

my @d = stat $fpod;
my @m = stat $fpm;
my @M = stat $mpl;
my @t = stat $0;

$d[9] && $m[9] && $m[9] - $d[9] > 2 and
    die "Did you edit $fpm instead of $fmd\n";

my $T = $d[9] || 0;
$M[9] > $T and $T = $M[9];
$t[9] > $T and $T = $t[9];
if ($m[9] && $m[9] >= $T) {
    print "$fpm seems up to date\n";
    exit 0;
    }

my $V;
open my $mh, "<", "Makefile.PL"  or die "No Makefile.PL\n";
while (<$mh>) {
    m/VERSION \s*=\s* "?(\S+?)"? \s* ;? $/x or next;
    $V = $1;
    last;
    }
close $mh;

$V or die "Cannot extract version from Makefile.PL\n";

print "Writing $fpm version $V\n";

open my $fh, ">", $fpm or die "Cannot create $fpm: $!\n";
print $fh <<"EOPM";
package Release::Checklist;

use strict;
use warnings;

our \$VERSION = "$V";

1;

EOPM
print $fh "__END__\n";

open my $ph, "<", $fpod or die "No pod\n";
print $fh (<$ph>);
close $ph;

close $fh;

utime $T,     $T,     $fpod;
utime $T + 1, $T + 1, $fpm;
