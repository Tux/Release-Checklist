# NAME

Release::Checklist - A QA checklist for CPAN releases

# Dependencies

Only use default pragma's

``` perl
 use 5.22.0;
 use strict;
 use feature "say";
 use warnings;
```

Do not add useless additional dependencies like
[sanity](https://metacpan.org/pod/sanity),
[Modern::Perl](https://metacpan.org/pod/Modern::Perl),
common::sense, or [nonsense](https://metacpan.org/pod/nonsense).
However useful they might be in your own working environment and
force you into behaving well, adding them as a requirement to a
CPAN module will increase the complexity of the requirements to
probably no good use, as they are unlikely to be found on all your
targeted systems and add a chance to break.

There is no problem with you using those in your own (non-CPAN)
scripts and modules, but please do not add needless dependencies.

[Test::Prereq](https://metacpan.org/pod/Test::Prereq)

# Test

Test, test and test. The more you test, the lower the chance you
will break your code with small changes.

``` perl
 use strict;
 use warnings;
 use Test::More;
 :
 done_testing ();
```

Separate your module tests and your author tests

```
t/
xt/
```

if possible, do not use [Test::*](https://metacpan.org/search?q=Test%3A%3A&search_type=modules)
modules that you do not actually require, however fancy they may be.
See the point about dependencies.

If you are still using any additional Test:: module, do not mix your own
code with the functionality from a/the module. Be consistent: use all or
use nothing. That is: if the module you (now) use comes with features you
had scripted yourself before using that module, replace them too.

If adding tests after a bug-fix, add at least two tests: one that tests
that the required (fixed) behavior now passes and that the invalid behavior
fails.

Check to see if your tests support running in parallel

``` sh
 $ prove -vwb -j8
```

If you have [Test2::Harness](https://metacpan.org/pod/Test2::Harness) installed,
also test with yath

``` sh
 $ yath
 $ yath -j8
```

# Documentation

Make sure that you have a clear SYNOPSIS section. This section should show
the most important code as simple and clear as possible. If you have 3500
methods in your class, do not list all of the there. Just show how to create
the object and show the 4 methods that a beginner would use.

Make sure your documentation is complete and all your methods and/or
functions are documented. If you have private functions, mentions that in the
documentation, so users can read that they might disappear without warning.

Make sure your pod is correct and can also be parsed by the pod-modules in
the lowest version of perl you support (or mention that you need at least
version whatever to read the pod as intended).

[Test::Pod](https://metacpan.org/pod/Test::Pod)
[Test::Pod::Coverage](https://metacpan.org/pod/Test::Pod::Coverage)

# Spelling

Not every developer is of native English tongue. And even if, they
also make (spelling) mistakes. There are enough tools available to
prevent public display of misspellings and typoes. Use them.

It is a good plan to have someone else proofread your documentation.
If you can, ask three readers: one who knows about what the module is
about, one who can be seen as an end-user of this modules without any
knowledge about the internals, and last someone who has no clue about
programming.  You might be surprised of what they will find in the
documentation as weird, unclear, or even plain wrong.

[pod-spell-check](scripts/pod-spell-check)

[Pod::Aspell](https://metacpan.org/pod/Pod::Aspell)
[Pod::Escapes](https://metacpan.org/pod/Pod::Escapes)
[Pod::Parser](https://metacpan.org/pod/Pod::Parser)
[Pod::Spell](https://metacpan.org/pod/Pod::Spell)
[Pod::Spell::CommonMistakes](https://metacpan.org/pod/Pod::Spell::CommonMistakes)
[Pod::Wordlist](https://metacpan.org/pod/Pod::Wordlist)
[Text::Aspell](https://metacpan.org/pod/Text::Aspell)
[Text::Ispell](https://metacpan.org/pod/Text::Ispell)
[Text::Wrap](https://metacpan.org/pod/Text::Wrap)

# Examples

Have examples of your code. Preferably both in the EXAMPLES section of the
pod, as in a folder names examples.

It is good practice to use your example code/scripts in your documentation
too, as that gives you a two-way check (additional to your tests). Even
better if the test scripts can be used as examples.

# Test coverage

Do not just test what you think would be used. There *will* be users that try
to bend the rules and invent ways for your module to be useful that you would
never think of.

If every line of your code is tested, not only do you prevent unexpected
breakage, but you also make sure that most corner cases are tested. Besides
that, it will probably confront your with questions like "What can I possibly
do to get into this part of my code?". Which may cause optimizations and other
fun.

[Devel::Cover](https://metacpan.org/pod/Devel::Cover)
[Test::TestCoverage](https://metacpan.org/pod/Test::TestCoverage)

# Version coverage

This is a hard one. If your release/dist requires specific versions of other
modules, try to create an environment where you test your distribution against
the required version *and* a version that does not meet the minimum version.

If your module requires Foo::Bar-0.123 because it supports correct UTF-8
encoding/decoding, and you wrote a test for that, your release is apt to fail
in an environment where Foo::Bar-0.023 is installed.

This gets really hard to set up if your release has different code for versions
of perl and for versions of required modules, but it pays off eventually. Note
that monitoring [CPANTESTERS](http://www.cpantesters.org) can be a huge help.

# Minimal perl support

Your Makefile.PL (or whatever build system you use) will have to state
a minimal supported perl version that ends up in META.json and META.yml

Do not guess. It is easy to check with
[Test::MinimumVersion](https://metacpan.org/pod/Test::MinimumVersion) and/or
[Test::MinimumVersion::Fast](https://metacpan.org/pod/Test::MinimumVersion::Fast).
[Perl::MinimumVersion](https://metacpan.org/release/Perl-MinimumVersion) comes with
the [perlver](https://metacpan.org/pod/distribution/Perl-MinimumVersion/script/perlver)
tool:

``` shell
$ perlver --blame test.pl

 --------------------------------------------------
 File    : test.pl
 Line    : 3
 Char    : 14
 Rule    : _perl_5010_operators
 Version : 5.010
 --------------------------------------------------
 //
 --------------------------------------------------
```

# Multiple perl versions

If you have multiple perls installed on your system, test your module
or release with all of them before doing the release. Best would be to
test with a threaded perl and a non-threaded perl. If you can test with
a mixture of -Duselongdouble and 32bit/64bit perls, that would be even
better.

 $ perl -wc lib/Foo/Bar.pm

[Module::Release](https://metacpan.org/pod/Module::Release)

[.releaserc](./.releaserc)

Repeat this on as many architectures as you can (i586, x64, IA64, PA-RISC,
Sparc, PowerPC, …)

Repeat this on as many Operating Systems as you can (Linux, NetBSD, OSX,
HP-UX, Solaris, Windows, OpenVMS, AIX, …)

Testing against a -Duselongdouble compiled perl will surface bad tests,
e.g. tests that match against NVs like 2.1:

``` perl
 use Test::More;
 my $i = 21000000000000001;
 $i /= 10e15;
 is ($i, 2.1);
 done_testing;
```

With -Uuselongdouble:

```
 ok 1
 1..1
```

with -Duselongdouble

```
 not ok 1
 #   Failed test at -e line 1.
 #          got: '2.1000000000000001'
 #     expected: '2.1'
 1..1
 # Looks like you failed 1 test of 1.
```

# XS

If you use XS, make sure you (try to) support the widest range of perl
versions.

[Devel::PPPort](https://metacpan.org/pod/Devel::PPPort) (most recent version)

# Leak tests

[Test::LeakTrace::Script](https://metacpan.org/pod/Test::LeakTrace::Script)
[Test::Valgrind](https://metacpan.org/pod/Test::Valgrind)
[valgrind](http://valgrind.org)

# Release archive

Some see [CPANTS](http://cpants.perl.org/) as a game, but many of the tests
it puts on your release have a reason. Before you upload, you can check most
of that to prevent unhappy users.

[Test::Package](....)
[Test::Kwalitee](https://metacpan.org/pod/Test::Kwalitee)
[Module::CPANTS::Analyse](https://metacpan.org/pod/Module::CPANTS::Analyse)
[cpants_lint.pl](https://metacpan.org/pod/distribution/App-CPANTS-Lint/bin/cpants_lint.pl)

``` sh
 $ perl Makefile.PL
 $ make test
 $ make dist
 $ cpants_lint.pl Foo-Bar-0.01.tar.gz
 Checked dist: Foo-Bar-0.01.tar.gz
 Score: 144.44% (26/18)
 Congratulations for building a 'perfect' distribution!
 $
```

# Clean dist

Some problems only surface when you do a make clean or make distclean.
The develop cycle normally only adds and changes files, and if you forget
to add those to the MANIFEST, your distribution will be incomplete and
is likely to fail on other systems, whereas your tests locally still
keep passing.

[MANIFEST](./MANIFEST) and [MANIFEST.skip](MANIFEST.skip) are complete

``` sh
 $ make dist
 $ make distclean
```

[Test::Manifest](https://metacpan.org/pod/Test::Manifest)
[Test::DistManifest](https://metacpan.org/pod/Test::DistManifest)

# Code style consistency

Add a [CONTRIBUTING.md](./CONTRIBUTING.md) or similar file to guide others to
consistency that will match [*your* style](http://tux.nl/style.html) (or, in
case of joint effort, the style as agreed upon by the developers).

There are helper modules to enforce a style (given a configuration) or to try
to help contributors to come up with a path/change than matches the project's
style and layout. Again: consistency helps. A lot.

[Perl::Tidy](https://metacpan.org/pod/Perl::Tidy)
[Perl::Critic](https://metacpan.org/pod/Perl::Critic) + [plugins](https://metacpan.org/search?q=Perl%3A%3ACritic%3A%3A&search_type=modules), lot of choices
[Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic)
[Test::Perl::Critic::Policy](https://metacpan.org/pod/Test::Perl::Critic::Policy)
[Test::TrailingSpace](https://metacpan.org/pod/Test::TrailingSpace)
[Perl::Lint](https://metacpan.org/pod/Perl::Lint)

[.perltidy](./.perltidyrc) and [.perlcritic](./.perlcriticrc).

# META

Make sure your meta-data matches the expected requirements. That can be achieved
by using a generator that produces conform the most recent specifications or by
using tools to check handcrafted META-files against the
[META spec 1.4 (2008)](http://module-build.sourceforge.net/META-spec-v1.4.html) or
[META spec 2.0 (2011)](http://module-build.sourceforge.net/META-spec-v2.0.html):

[CPAN::Meta::Converter](https://metacpan.org/pod/CPAN::Meta::Converter)
[CPAN::Meta::Validator](https://metacpan.org/pod/CPAN::Meta::Validator)
[JSON::PP](https://metacpan.org/pod/JSON::PP)
[Parse::CPAN::Meta](https://metacpan.org/pod/Parse::CPAN::Meta)
[Test::CPAN::Meta::JSON](https://metacpan.org/pod/Test::CPAN::Meta::JSON)
[Test::CPAN::Meta::YAML](https://metacpan.org/pod/Test::CPAN::Meta::YAML)
[Test::CPAN::Meta::YAML::Version](https://metacpan.org/pod/Test::CPAN::Meta::YAML::Version)
[YAML::Syck](https://metacpan.org/pod/YAML::Syck)

# Versions

Use a sane versioning system that the rest of the world might understand.
Do not use the MD5 of the current date and time related to the phase of the
moon or versions that include quotes or spaces. Keep it simple and clear.

[Test::Version](https://metacpan.org/pod/Test::Version)

Make sure it is a versioning system that increments

[Test::GreaterVersion](https://metacpan.org/pod/Test::GreaterVersion)

# Changelog

Make sure your [ChangeLog](./ChangeLog) or Changes file is up-to-date. Your
release procedure might check the most recent mentioned date in that

[Date::Calc](https://metacpan.org/pod/Date::Calc)
[Test::CPAN::Changes](https://metacpan.org/pod/Test::CPAN::Changes)

# Performance

Check if your release matches previous performance

 - between different versions of perl
 - between different versions of the module
 - between different versions of dependencies

# License

Make a clear statement about your license. (or choose a default, but at least
state it).

Some target areas require a license in order to allow a CPAN module to be
installed.

# README / README.md

Add a [file](./README.md) the states in short the purpose of your distribution.

Make sure your SYNOPSIS section in the pod makes sense

[Test::Synopsis](https://metacpan.org/pod/Test::Synopsis)
[Text::Markdown](https://metacpan.org/pod/Text::Markdown)

# Downriver

You have had reasons to make the changes leading up to a new distribution. If
you really care about the users of your module, you should check if your new
release would break any of the CPAN modules that (indirectly) depend on your
module by testing with your previous release and your upcoming release and see
if the new release would cause the other module to break.

[used_by.pl](scripts/used-by.pl) will check the depending modules with the
upcoming version.

# LICENSE

Copyright (C) 2015-2018 H.Merijn Brand.  All rights reserved.

This library is free software;  you can redistribute and/or modify it under
the same terms as Perl itself.
