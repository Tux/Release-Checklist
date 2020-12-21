#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use JSON;
use YAML;
use CPAN::Meta::Converter;

my ($mj, $my) = map { "META.$_" } qw( json yml );
if (!-f $my || -M $mj <= -M $my) {

    open my $fj, "<", $mj or die "$mj: $!\n";
    open my $fy, ">", $my or die "$my: $!\n";
    local $/;

    my $jsn = decode_json (do { local $/; <$fj> });
    my $yml = CPAN::Meta::Converter->new ($jsn)->convert (version => "1.4");

    $yml->{requires}{perl} //= $jsn->{prereqs}{runtime}{requires}{perl}
			   //  "5.006";
    $yml->{build_requires} && !keys %{$yml->{build_requires}} and
	delete $yml->{build_requires};
    print $fy Dump ($yml);
    close $fy;
    close $fj;
    }

if ($ENV{REGEN_META}) {
    ok (1, "META.yml is now up to date");
    }
else {
    eval "use Test::DistManifest";
    plan skip_all => "Test::DistManifest required for testing MANIFEST" if $@;

    manifest_ok ();
    }

done_testing;
