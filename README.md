# Release-Checklist

A checklist for releasing a CPAN module

This module aims to state a list of subjects describing best practices
in the process of releasing a (CPAN) distribution

There is no functionality in the module itself, but just serves a pure
documantation purpose.

You can still do this, if you want to have `Checklist` available for
`perldoc` when you type `perldoc Release::Checklist`.

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

The distribution comes with the checklist in MarkDown [`Checklist.md`](Checklist.md),
HTML [`Checklist.html`](Checklist.html), POD [`Checklist.pod`](Checklist.pod), and a module Release::Checklist
[`Checklist.md`](lib/Release/Checklist.pm).

## LICENSE

The Artistic License 2.0

Copyright (c) 2015-2019 H.Merijn Brand
