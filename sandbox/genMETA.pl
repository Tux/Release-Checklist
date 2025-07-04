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
    my $rd = join "-" => $meta->{h}{name}, $meta->{h}{version};
    $ENV{REGEN_META} = 1;
    system $^X, "xt/50_manifest.t";
    system "cp", "-p", $_, "$rd/$_" for map { "META.$_" } qw( json yml );
    }

__END__
--- #YAML:1.0
name:                   Release-Checklist
version:                VERSION
abstract:               A QA checklist for CPAN releases
license:                perl
author:                 
  - H.Merijn Brand <hmbrand@cpan.org>
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
configure_recommends:
  ExtUtils::MakeMaker:  7.22
configure_suggests:
  ExtUtils::MakeMaker:  7.74
test_requires:
  Test::Harness:        0
  Test::More:           0.88
recommends:
  perl:                                   5.030000
  CPAN::Audit:                            20250115.001
  CPAN::Meta::Converter:                  2.150010
  CPAN::Meta::Validator:                  2.150010
  Devel::Cover:                           1.44
  Devel::PPPort:                          3.72
  JSON::PP:                               4.16
  Module::CPANTS::Analyse:                1.02
  Module::Release:                        2.136
  Parse::CPAN::Meta:                      2.150010
  Perl::Critic:                           1.156
  Perl::Critic::TooMuchCode:              0.19
  Perl::MinimumVersion:                   1.40
  Perl::Tidy:                             20250311
  Pod::Escapes:                           1.07
  Pod::Parser:                            1.67
  Pod::Spell:                             1.27
  Pod::Spell::CommonMistakes:             1.002
  Software::Security::Policy::Individual: 0.09
  Test2::Harness:                         1.000156
  Test::CPAN::Changes:                    0.500004
  Test::CPAN::Meta::YAML:                 0.25
  Test::CVE:                              0.09
  Test::Kwalitee:                         1.28
  Test::Manifest:                         2.026
  Test::MinimumVersion:                   0.101083
  Test::MinimumVersion::Fast:             0.04
  Test::More:                             1.302210
  Test::Perl::Critic:                     1.04
  Test::Perl::Critic::Policy:             1.156
  Test::Pod:                              1.52
  Test::Pod::Coverage:                    1.10
  Test::Version:                          2.09
  Text::Aspell:                           0.09
  Text::Ispell:                           0.04
  Text::Markdown:                         1.000031
resources:
  license:              http://dev.perl.org/licenses/
  repository:           https://github.com/Tux/Release-Checklist
  bugtracker:           https://github.com/Tux/Release-Checklist/issues
  xIRC:                 irc://irc.perl.org/#toolchain
meta-spec:
  version:              1.4
  url:                  http://module-build.sourceforge.net/META-spec-v1.4.html
