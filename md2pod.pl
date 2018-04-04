#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.02 - 20180404";

-d ".git" or exit 0;

my @m = stat "Checklist.md";
my @p = stat "Checklist.pod";
my @t = stat $0;

$m[9] && $p[9] && $p[9] >= $m[9] && $p[9] >= $t[9] and exit 0;

use Markdown::Pod;

open my $fh, "<", "Checklist.md";
my $md = do { local $/; <$fh> };
close $fh;

# Prepare MD to prevent md2pod errors
$md =~ s/^```\K .*//gm;
$md =~ s/(-{20,})/"\xFF" x length $1/ge;

my $mp = Markdown::Pod->new;
my $pod = $mp->markdown_to_pod (
#   encoding => "utf8",	# don't!
    dialect  => "Standard",
    markdown => $md,
    );

# And fix misformatted pod
$pod =~ s{\xFF}{-}g;
$pod =~ s{=item -\K\n\n}{ }g;
$pod =~ s{[ \t]+\n}{\n}g;
$pod =~ s{\n\n\K\n+}{}g;

open my $ph, ">", "Checklist.pod";
print $ph "=encoding utf-8\n\n";
print $ph $pod;
close $ph;
