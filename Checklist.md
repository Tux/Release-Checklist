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

# Test coverage

Do not just test what you think would be used. There *will* be users that try
to bend the rules and invent ways for your module to be useful that you would
never think of.

If every line of your code is tested, not only do you prevent unexpected
breakage, but you also make sure that most corner cases are tested. Besides
that, it will probably confront your with questions like "What can I possibly
do to get into this part of my code?". Which may cause optimisations and other
fun.

[Devel::Cover](https://metacpan.org/pod/Devel::Cover)
[Test::TestCoverage](https://metacpan.org/pod/Test::TestCoverage)

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

 ------------------------------------------------------------
 File    : test.pl
 Line    : 3
 Char    : 14
 Rule    : _perl_5010_operators
 Version : 5.010
 ------------------------------------------------------------
 //
 ------------------------------------------------------------
```

# Multiple perl versions

If you have multiple perls installed on your system, test your module
or release with all of them before doing the release. Best would be to
test with a threaded perl and a non-threaded perl. If you can test with
a mixture of -Duselongdouble and 32bit/64bit perls, that would be even
better.

[Module::Release](https://metacpan.org/pod/Module::Release)

[.releaserc](./.releaserc)

Repeat this on as many architectures as you can (i586, x64, IA64, PA-RISC,
Sparc, PowerPC, …)

Repeat this on as many Operating Systems as you can (Linux, NetBSD, OSX,
HP-UX, Solaris, Windows, OpenVMS, AIX, …)

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

[.perltidy](./.perltidyrc) and [.perlcritic](./.perlcriticrc).

# Spelling

Not every developer is of native English tongue. And even if, they
also make (spelling) mistakes. There are enough tools available to
prevent public display of misspellings and typoes. Use them.

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

# META

Make sure your meta-data matches the expected requirements. That can be achived
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

# Changelog

Make sure your [ChangeLog](./ChangeLog) or Changes file is up-todate. Your
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

Some target areas require a licence in order to allow a CPAN module to be
installed.

# README / README.md

Add a [file](./README.md) the states in short the purpose of your distribution.

# Downriver

You have had reasons to make the changes leading up to a new distribution. If
you really care about the users of your module, you should check if your new
release would break any of the CPAN modules that (indirectly) depend on your
module by testing with your previous release and your upcoming release and see
if the new release would cause the other module to break.

[used_by.pl](scripts/used-by.pl) will check the depending modules with the
upcoming version.
