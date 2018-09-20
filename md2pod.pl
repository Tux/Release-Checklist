#!/pro/bin/perl

use 5.12.0;
use warnings;

our $VERSION = "0.03 - 20180920";

-d ".git" or exit 0;

my $fmd  = "Checklist.md";
my $fpod = $fmd =~ s/md$/pod/r;

my @m = stat $fmd;
my @p = stat $fpod;
my @t = stat $0;

$m[9] && $p[9] && $p[9] >= $m[9] && $p[9] >= $t[9] and exit 0;

use Markdown::Pod;

say "Converting $fmd to $fpod";

open my $fh, "<", $fmd;
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

open my $ph, ">", $fpod;
print $ph "=encoding utf-8\n\n";
print $ph $pod;
close $ph;
