#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.01 - 20180330";

BEGIN { $V::NO_EXIT = $V::NO_EXIT = 1; }
require V;

my %m;
open my $fh, "<", "META.json" or die "META.json: $!\n";
while (<$fh>) {
    my ($m, $v) = m/^\s+ "(\S+)" \s+ : \s+ "([0-9.]+)" /x or next;
    $v =~ m/[1-9]/ or next; # 0 is not something to check

    my $iv = V::get_version ($m) or next;

    $m{$m} = [ $v, $iv ];
    }
close $fh;
delete $m{version};

foreach my $m (sort keys %m) {
    my ($v, $iv) = @{$m{$m}};

    $v eq $iv and next;

    printf "%-30s %10s -> %10s\n", $m, $v, $iv;
    }
