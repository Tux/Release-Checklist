#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use YAML::Syck;
use JSON;

eval "use Test::DistManifest";
plan skip_all => "Test::DistManifest required for testing MANIFEST" if $@;

my ($mj, $my) = map { "META.$_" } qw( json yml );
if (!-f $my || -M $mj <= -M $my) {
    open my $fj, "<", $mj or die "$mj: $!\n";
    open my $fy, ">", $my or die "$my: $!\n";
    local $/;
    print $fy Dump (decode_json (<$fj>));
    close $fy;
    close $fj;
    }

manifest_ok ();
done_testing;
