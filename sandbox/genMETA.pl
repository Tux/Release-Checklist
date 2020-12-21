#!/pro/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config bundling nopermute);
GetOptions (
    "c|check"		=> \ my $check,
    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or die "usage: $0 [--check]\n";

use lib "sandbox";
use genMETA;
my $meta = genMETA->new (
    from    => "Checklist.pm",
    verbose => $opt_v,
    );

$meta->from_data (<DATA>);
# This project maintains META.json manually
# META.yml is generated in xt/50_manifest.t and not kept in git

if ($check) {
    $meta->check_encoding ();
    $meta->check_required ();
    my @ef = glob "examples/*";
    $meta->check_minimum ([ "t", @ef, "Checklist.pm", "Makefile.PL" ]);
    $meta->done_testing ();
    }
elsif ($opt_v) {
    $meta->print_yaml ();
    }
else {
    system $^X, "xt/50_manifest.t";
    }

__END__
--- #YAML:1.0
name:                   Release-Checklist
version:                VERSION
abstract:               A QA checklist for CPAN releases
license:                perl
author:                 
  - H.Merijn Brand <h.m.brand@xs4all.nl>
generated_by:           Author
distribution_type:      module
release_status:         stable
provides:
  Release::Checklist:
    file:               Checklist.pm
    version:            VERSION
requires:                       
  perl:                 5.006
  Test::More:           0.88
configure_requires:
  ExtUtils::MakeMaker:  0
test_requires:
  Test::Harness:        0
  Test::More:           0.88
recommends:
  perl:                        5.030000
  CPAN::Meta::Converter:       2.150010
  CPAN::Meta::Validator:       2.150010
  Devel::Cover:                1.36
  Devel::PPPort:               3.62
  JSON::PP:                    4.05
  Module::CPANTS::Analyse:     1.01
  Module::Release:             2.125
  Parse::CPAN::Meta:           2.150010
  Perl::Critic:                1.138
  Perl::Critic::TooMuchCode:   0.14
  Perl::MinimumVersion:        1.38
  Perl::Tidy:                  20201207
  Pod::Escapes:                1.07
  Pod::Parser:                 1.63
  Pod::Spell:                  1.20
  Pod::Spell::CommonMistakes:  1.002
  Test2::Harness:              1.000042
  Test::CPAN::Changes:         0.400002
  Test::CPAN::Meta::YAML:      0.25
  Test::Kwalitee:              1.28
  Test::Manifest:              2.021
  Test::MinimumVersion:        0.101082
  Test::MinimumVersion::Fast:  0.04
  Test::More:                  1.302183
  Test::Perl::Critic:          1.04
  Test::Perl::Critic::Policy:  1.138
  Test::Pod:                   1.52
  Test::Pod::Coverage:         1.10
  Test::Version:               2.09
  Text::Aspell:                0.09
  Text::Ispell:                0.04
  Text::Markdown:              1.000031
resources:
  license:              http://dev.perl.org/licenses/
  repository:           https://github.com/Tux/Release-Checklist
  bugtracker:           https://github.com/Tux/Release-Checklist/issues
  xIRC:                 irc://irc.perl.org/#toolchain
meta-spec:
  version:              1.4
  url:                  http://module-build.sourceforge.net/META-spec-v1.4.html
