requires   "Test::More";

recommends "CPAN::Meta::Converter"	=> "2.150010";
recommends "CPAN::Meta::Validator"	=> "2.150010";
recommends "Devel::Cover"		=> "1.36";
recommends "Devel::PPPort"		=> "3.62";
recommends "JSON::PP"			=> "4.05";
recommends "Module::CPANTS::Analyse"	=> "1.01";
recommends "Module::Release"		=> "2.125";
recommends "Parse::CPAN::Meta"		=> "2.150010";
recommends "Perl::Critic"		=> "1.138";
recommends "Perl::Critic::TooMuchCode"	=> "0.14";
recommends "Perl::MinimumVersion"	=> "1.38";
recommends "Perl::Tidy"			=> "20201207";
recommends "Pod::Escapes"		=> "1.07";
recommends "Pod::Parser"		=> "1.63";
recommends "Pod::Spell"			=> "1.20";
recommends "Pod::Spell::CommonMistakes"	=> "1.002";
recommends "Test2::Harness"		=> "1.000042";
recommends "Test::CPAN::Changes"	=> "0.400002";
recommends "Test::CPAN::Meta::YAML"	=> "0.25";
recommends "Test::Kwalitee"		=> "1.28";
recommends "Test::Manifest"		=> "2.021";
recommends "Test::MinimumVersion"	=> "0.101082";
recommends "Test::MinimumVersion::Fast"	=> "0.04";
recommends "Test::More"			=> "1.302183";
recommends "Test::Perl::Critic"		=> "1.04";
recommends "Test::Perl::Critic::Policy"	=> "1.138";
recommends "Test::Pod"			=> "1.52";
recommends "Test::Pod::Coverage"	=> "1.10";
recommends "Test::Version"		=> "2.09";
recommends "Text::Aspell"		=> "0.09";
recommends "Text::Ispell"		=> "0.04";
recommends "Text::Markdown"		=> "1.000031";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";
    };
