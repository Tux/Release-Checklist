# Test

Test::More

# Minimal perl support

Test::MinimumVersion
Test::MinimumVersion::Fast
perlver --blame

# Multiple perl versions

Module::Release

.releaserc

# XS

Devel::PPPort (most recent version)

# Leak tests

Test::LeakTrace::Script
Test::Valgrind
valgrind

# Release archive

Module::CPANTS::Analyse
cpants_lint.pl

# Clean dist

MANIFEST and MANIFEST.skip are complete

    - make dist
    - make distclean

# Code style consistency

Perl::Tidy
Perl::Critic	+ plugins, lot of choices
Test::Perl::Critic
Test::Perl::Critic::Policy

.perltidyrc
.perlcriticrc

# Spelling

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
