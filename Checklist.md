* Dependencies

Only use default pragma's

use strict;
use warnings;

Do not add useless additional dependencies like sanity, Modern::Perl,
common::sense, or nonsense, as they are unlikely to be found on all
your targeted systems and only add a chance to break.

There is no problem with you using those in your own (non-CPAN)
scripts and modules, but please do not add needless dependencies.

# Test

Test, test and test. The more you test, the lower the chance you
will break your code with small changes.

Test::More

t/
xt/

if possible, do not use Test::* modules that you do not actually
require, however fancy they may be. See the point about dependencies.

# Minimal perl support

Your Makefile.PL (or whatever build system you use) will have to state
a minimal supported perl version that ends up in META.json and META.yml

Do not guess. It is easy to check.

Test::MinimumVersion
Test::MinimumVersion::Fast
perlver --blame

# Multiple perl versions

If you have multiple perls installed on your system, test your module
or release with all of them before doing the release. Best would be to
test with a threaded perl and a non-threaded perl. If you can test with
a mixture of -Duselongdouble and 32bit/64bit perls, that would be even
better.

Module::Release

.releaserc

# XS

If you use XS, make sure you (try to) support the widest range of perl
versions.

Devel::PPPort (most recent version)

# Leak tests

Test::LeakTrace::Script
Test::Valgrind
valgrind

# Release archive

Some see CPANTS as a game, but many of the tests it puts on your
release have a reason. Before you upload, you can check most of
that to prevent unhappy users.

Module::CPANTS::Analyse
cpants_lint.pl

# Clean dist

Some problems only surface when you do a make clean or make distclean.
The develop cycle normally only adds and changes files, and if you forget
to add those to the MANIFEST, your distribution will be incomplete and
is likely to fail on other systems, whereas your tests locally still
keep passing.

MANIFEST and MANIFEST.skip are complete

    - make dist
    - make distclean

# Code style consistency

Add a CONTRIBUTING.md or similar file to guide others to consistency
that will match *your* style (or, in case of joint effort, the style
as agreed upon by the developers).

Perl::Tidy
Perl::Critic	+ plugins, lot of choices
Test::Perl::Critic
Test::Perl::Critic::Policy

.perltidyrc
.perlcriticrc

# Spelling

Not every developer is of native English tongue. And even if, they
also make (spelling) mistakes. There are enough tools available to
prevent public display of misspellings and typoes. Use them.

scripts/pod-spell-check

Pod::Aspell
Pod::Escapes
Pod::Parser
Pod::Spell
Pod::Spell::CommonMistakes
Pod::Wordlist
Text::Aspell
Text::Ispell
Text::Wrap

# META

CPAN::Meta::Converter
CPAN::Meta::Validator
JSON::PP
Parse::CPAN::Meta
Test::CPAN::Meta::YAML::Version
YAML::Syck

# Changelog

Date::Calc

# Performance

 - between different versions of perl
 - between different versions of the module

# License

# README / README.md

# Test coverage

Devel::Cover

# Downriver

scripts/used-by.pl

preferably with the previous version *and* with the version to be released
