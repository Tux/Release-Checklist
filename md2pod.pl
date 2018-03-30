#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.01 - 20180330";

-d ".git" or exit 0;

my @m = stat "Checklist.md";
my @p = stat "Checklist.pod";

$m[9] && $p[9] && $p[9] >= $m[9] and exit 0;
open STDOUT, ">", "Checklist.pod";

exec "markdown2pod", "Checklist.md";
