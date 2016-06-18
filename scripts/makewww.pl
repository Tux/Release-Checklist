#!/usr/bin/env perl

use 5.20.0;
use warnings;

our $VERSION = "1.25 - 2016-06-18";

sub usage {
    my $err = shift and select STDERR;
    say "usage: $0 [-v] [--git=author] [--travis=id] AUTHOR\n";
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling);
my $opt_v = 0;
GetOptions (
    "help|?"		=> sub { usage (0); },
    "v|verbose:1"	=> \$opt_v,
      "time!"		=> \my $opt_t,
    "g|git=s"		=> \my $git_id,
    "t|travis=s"	=> \my $travis_id,
    ) or usage (1);

my $author = shift or usage (1);
   $author = uc $author;
my $auid1  = substr $author, 0, 1;
my $auid3  = "$auid1/" . substr $author, 0, 2;

use LWP;
use JSON::XS;
use YAML::Tiny;
use Data::Peek;
use LWP::UserAgent;
use HTML::TreeBuilder;
use Encode qw( encode decode );
use Date::Calc qw( Parse_Date Date_to_Time );
use Time::HiRes qw( gettimeofday tv_interval );

use MetaCPAN::Client;
use CPAN::Testers::WWW::Reports::Query::AJAX;

my $mcpan   = MetaCPAN::Client->new ();
my $mauthor = $mcpan->author ($author);

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
my $ua = LWP::UserAgent->new;
$ua->agent ("Opera/30");

my %mod;

$opt_v and say "Fetch releases from $author";
{   my $ar = $mauthor->releases;
    while (my $rr = $ar->next) {
	my $mod = $rr->distribution =~ s{-}{::}gr; # Yeah, not 100% correct

	$opt_v > 1 and say " $mod";
	$mod{$mod} = { git => "" };

	my $repo = "";
	if (my $rrr = $rr->{resources}{repository}) {
	    ref $rrr eq "HASH" and $repo = $rrr->{web} || $rrr->{url} || "";
	    }

	if ($repo =~ m{\bgithub\.com\b}) {
	    $repo =~ s{^git\@github.com:}{https://github.com/};
	    $repo =~ s{^git:}{https:};
	    $repo =~ s{\.git$}{};
	    $repo =~ m{github.com/([^/]+)} and $git_id //= $1;
	    }
	$mod{$mod}{git} = $repo;
	$opt_v > 2 and say "  $repo";

	$mod{$mod}{data} = $rr->{data} // {};
	}
    }

$git_id     //= lc $author;
$travis_id  //= $git_id;

my $buffer = "";
open my $html, ">:encoding(utf-8)", \$buffer;
header ();
modules ();
footer ();
close $html;
open  $html, ">", "$author.html";
print $html $buffer;
close $html;

sub href {
    my ($txt, $ref, $ttl, $dtl) = (@_, "", "", "");
    if (ref $txt eq "HASH") {
	$ttl = $txt->{title};
	$dtl = $txt->{dtitle};
	$txt = $txt->{text};
	}
    $ttl //= "";
    $dtl //= "";
    $txt //= "";
    $ttl and $ttl  =      qq{ title="$ttl"};
    $dtl and $ttl .= qq{ data-title="$dtl"};
    $ref && $ref ne "-" ? qq{<a href="$ref"$ttl>$txt</a>} : $txt // "-";
    } # href

sub dta {
    my ($tag, %attr, @arg) = ("td");
    for (@_) {
	if (ref $_ eq "ARRAY") {
	    local $" = " ";
	    $tag .= qq{ class="@$_"};
	    next;
	    }
	push @arg, $_;
	}
    my $info = @arg > 2 ? join " ", "", splice @arg, 2 : "";
    my $link = href (@arg);
    if ($tag =~ m{class=".*\b(pass|na|warn|fail|gray)[ "]}) {
	my $c = $1;
	$link =~ s{<a \K}{class="$c" };
	}
    say $html "            <$tag>$link$info</td>";
    } # dta

my $t0;
my %time;
sub t_used {
    my $now = [ gettimeofday ];
    my $d = tv_interval ($t0, $now);
    $t0 = $now;
    return $d;
    } # t_used

sub show_times {
    say STDERR "--- cumulative times used";
    printf STDERR "%-11s : %7.3f\n", $_, $time{$_} for sort keys %time;
    } # show_times

sub modules {
    print $html <<"EOH";

  <tr class="boxed">
    <td class="boxed">
      <p class="header">${author}'s modules</p>
      <table>
        <thead>
          <tr>
            <th><a href="https://metacpan.org/author/$author">Distribution</a></th>
            <th>vsn</th>
            <th class="rhdr">released</th>
            <th class="tci" colspan="4"><a href="https://github.com/$git_id">repo</a></th>
            <th class="rhdr"><a href="http://rt.cpan.org/Public/Dist/ByMaintainer.html?Name=$author">RT</a></th>
            <th class="center">doc</th>
            <th class="tci"><a href="https://travis-ci.org/profile/$travis_id">TravisCI</a></th>
            <th class="cpants"><a href="http://cpants.perl.org/author/$author">kwalitee</a></th>
            <th class="rhdr"><a href="http://cpancover.com">cover</a></th>
            <th class="rhdr" colspan="3"><a href="http://www.cpantesters.org/author/$auid1/$author.html">cpantesters</a></th>
            <th class="rhdr"><span style="color: green">&#x2714;</span><span style="color: red">&#x2718;</span></th>
            <th class="rhdr"><a href="http://deps.cpantesters.org">&#x219d;</a></th>
            <th class="rhdr" style="color: red">&#x2665;</th>
            <th class="rhdr" style="color: black">&#x2605;</th>
            </tr>
          </thead>
        <tbody>
EOH

    my $coverage = {};
    my $r;
    $r = $ua->get ("http://cpancover.com/latest/cpancover.json") and $r->is_success and
	$coverage = eval { decode_json ($r->content) } // {};

    my $do_dr = 1; # Count downriver. Disable if it takes too long

    my $eo = 0;
    foreach my $mod (sort keys %mod) {

	$opt_v and say $mod;

	my $m    = $mod{$mod}; $m->{skip} and next;
	my $dist = $mod =~ s/::/-/gr;

	$t0 = [ gettimeofday ];

	$opt_v > 1 and warn " Base CPAN data\n";
	my $data = eval { $mcpan->module ($mod)->{data} } || {};
	if ($m->{data}) {
	    $data->{$_} = $m->{data}{$_} for keys %{$m->{data}};
	    }
	$time{init} += t_used;

	$data->{fav} = $mcpan->favorite ({ distribution => $dist })->{total} || "-";
	$time{favorite} += t_used;

	my $rating = "";
	$data->{rating} = { text => "-" };
	if (my $rs = $mcpan->rating ({ distribution => $dist })->scroller) {
	    $opt_v > 1 and warn " Fetch rating\n";
	    my $n = $rs->total;
	    if ($r = $rs->next) {
		$rating = "http://cpanratings.perl.org/d/$dist";
		$data->{rating} = {
		    text   => $r->{_source}{rating},
		    dtitle => "$n votes",
		    };
		}
	    }
	$time{rating} += t_used;

	$data->{version} //= "*";

	# Kwalitee
	my $kwtc = "none";
	unless (defined $data->{kwalitee}) {
	    $opt_v > 1 and warn " Fetch kwalitee\n";
	    ($r = $ua->get ("http://cpants.cpanauthors.org/dist/$dist")) &&
	     $r->is_success && $r->content =~ m{
		<dt> [\s\r\n]*  Kwalitee          [\s\r\n]* </dt> [\s\r\n]*
		<dd> [\s\r\n]* ([0-9.]+)          [\s\r\n]* </dd> [\s\r\n]*
		<dt> [\s\r\n]*  Core \s* Kwalitee [\s\r\n]* </dt> [\s\r\n]*
		<dd> [\s\r\n]* ([0-9.]+)          [\s\r\n]* </dd>
		}xi and ($data->{kwk}, $data->{kwc}) = ($1, $2);
	     $data->{kwalitee} = join " / " =>
		 $data->{kwc} // "-", $data->{kwk} // "&nbsp;&nbsp;&nbsp;-&nbsp;&nbsp;";
	     $data->{kwc} and $kwtc = $data->{kwc} >= 100 ? "pass"
				    : $data->{kwc} >=  80 ? "na"
				    : $data->{kwc} >=  60 ? "warn" : "fail";
	     }
	$time{kwalitee} += t_used;

	# GIT repo and last commit
	my $git = $m->{git}; # // "https://github.com/$git_id/$dist",
	my $git_tag = {
	    text   => "git",
	    dtitle => "",
	    };
	my $git_clss = [ "git" ];
	if ($git =~ m/\b github.com \b/x) {
	    $opt_v > 1 and warn " Fetch github master commits\n";
	    $r = $ua->get ("$git/commits/master");
	    my $tree = HTML::TreeBuilder->new;
	    $tree->parse_content ($r && $r->is_success ? decode ("utf-8", $r->content) : "");
	    # Get most recent commit date
	    for ($tree->look_down (_tag => "div", class => "commit-group-title")) {
		# Commits on Apr 24, 2015
		my ($y, $m, $d) = Parse_Date ($_->as_text =~ s/^\s*Commits\s+on\s*//r) or next;
		$git_tag->{dtitle} = sprintf "%4d-%02d-%02d", $y, $m, $d;
		my $t = Date_to_Time ($y, $m, $d, 0, 0, 0) or next;
		my $span = int ((time - $t) / 86400);
		push @$git_clss,
		    $span <=   7 ? "pass" : # green,  <=  1 week
		    $span <=  30 ? "na"   : # yellow, <= 30 days
		    $span <= 182 ? "warn" : # orange, <=  6 months
				   "fail" ; # red
		#warn sprintf "%4d-%02d-%02d %3d %s\n", $y, $m, $d, $span, $dist;
		last;
		}
	    }
	$git eq "" && !$git_tag->{dtitle} and $git_tag = "-";
	$time{git} += t_used;

	# CPANTESTER results
	$opt_v > 1 and warn " Fetch cpantesters\n";
	!defined $data->{cptst} and
	    $data->{cptst} =
	      ($r = CPAN::Testers::WWW::Reports::Query::AJAX->new (dist => $dist))
		? [ $r->pass, $r->na, $r->fail, $r->unknown ]
		: [ "", "", "", "" ];
	$opt_v > 7 and warn "  (@{$data->{cptst}})\n";
	$time{cpantesters} += t_used;

	# RT tickets
	my $rt = $m->{rt} // "http://rt.cpan.org/Public/Dist/Display.html?Name=$dist";
	# http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist"; - does not work anymore
	# https://rt.cpan.org/Dist/Display.html?Name=$dist";
	# https://rt.cpan.org/Dist/Display.html?Queue=DBD%3A%3ACSV
	my $rt_tag = "*";
	if ($rt =~ m{/rt.cpan.org/}) {
	    $opt_v > 1 and warn " Fetching RT ticket list\n";
	    $opt_v > 2 and warn "  $rt\n";
	    if ($r = $ua->get ($rt) and $r->is_success) {
		my $tree = HTML::TreeBuilder->new;
		$tree->parse_content (decode ("utf-8", $r->content));
		#$opt_v > 8 and warn $tree->as_HTML (undef, "  ", {});
		my %id;
		$id{$_->attr ("href")}++ for
		    $tree->look_down (_tag => "a", href => qr{^/Ticket/Display.html\?id=[0-9]+$});
		$opt_v > 8 and DDumper \%id;
		$rt_tag = scalar keys %id;
		}
	    else {
		warn $r->status_line;
		}
	    }
	$time{rt} += t_used;

	# Github issues
	my $issues;
	my $issues_tag  = $git ? "-" : "";
	my $issue_class = [ "date" ];
	my %pr = (
	    "open"	=> [ "-", undef ],
	    "closed"	=> [ "-", undef ],
	    );
	if ($git =~ m/\b github.com \b/x) {
	    $opt_v > 1 and warn " Fetch github issues\n";
	    my $il = "$git/issues";
	    $r = $ua->get ($il);
	    my $tree = HTML::TreeBuilder->new;
	    if ($r && $r->is_success) {
		$issues     = $il;
		$issues_tag = "0";
		$tree->parse_content (decode ("utf-8", $r->content));
		# Get most recent commit date
		my $ib = $il =~ s{^https?://github.com}{}r;
		$rt_tag eq "*" and $rt_tag = 0;
		for ($tree->look_down (_tag => "a",
				       href => qr{$ib\?q=is(?:%3A|:)open\+is(?:%3A|:)issue$})) {
		    $_->as_text =~ m/^\s*([0-9]+)\s+Open/i or next;
		    $issues_tag = $1;
		    push @$issue_class, (
			$1 == 0 ? "pass" :
			$1 < 10 ? "na"   :
			$1 < 25 ? "warn" : "fail");
		    }
		}

	    $tree = HTML::TreeBuilder->new;
	    $r = $ua->get ("$git/pulls");
	    $tree->parse_content ($r && $r->is_success ? decode ("utf-8", $r->content) : "");
	    foreach my $a ($tree->look_down (_tag => "a", href => qr{/issues\?q=is%3A})) {
		my $t = lc $a->as_text;
		$t =~ m/^\s* ([0-9]+) \s+ ( open | closed ) \s*$/x or next;
		$pr{$2} = [ $1 + 0, "$git/pulls?q=is%3Apr+is%3A$2" ];
		}
	    }
	$time{github} += t_used;
	$rt_tag =~ m/^[-0-9]?$/ or
	    $rt_tag = $mcpan->distribution ($dist)->bugs->{active} || "*";
	$time{rt_tag} += t_used;

	# Downriver deps
	my $rd = $data->{rd} // ($do_dr ? do {
	    $r = $ua->get ("http://deps.cpantesters.org/depended-on-by.pl?module=$mod");
	    my $tree = HTML::TreeBuilder->new;
	    $tree->parse_content ($r && $r->is_success ? $r->content : "");
	    my $x = 0;
	    $x++ for $tree->look_down (_tag => "li");
	    $x || "-";
	    } : "\x{2241}");
	$time{downriver} += do {
	    my $tdr = t_used;
	    $tdr > 120 and $do_dr = 0;	# On FAIL this takes 180+ seconds
	    $tdr;
	    };

	my $cos       = "-";
	my $cos_class = [ "rd" ];
	{   $r = $ua->get ("http://deps.cpantesters.org/?module=$mod&perl=5.22.0&os=any+OS");
	    my $tree = HTML::TreeBuilder->new;
	    $tree->parse_content ($r && $r->is_success ? $r->content : "");
	    foreach my $tr ($tree->look_down (_tag => "tr", class => "results_chances")) {
		my @td = $tr->look_down (_tag => "td");
		if (@td && $td[-1]->as_text =~ m/\b([0-9]+)\s*%/) {
		    $cos = $1 + 0;
		    push @$cos_class,
			$cos < 50 ? "fail" :
			$cos < 75 ? "warn" :
			$cos < 95 ? "na"   : "pass";
		    }
		}
	    }
	$time{success} += t_used;

	# Release date
	my $rel_date = ($data->{date} // " ") =~ s/T.*//r;
	my $rel_clss = [ "date" ];
	if (my ($y, $m, $d) = ($rel_date =~ m/^(\d+)-(\d+)-(\d+)\b/)) {
	    my $t = Date_to_Time ($y, $m, $d, 0, 0, 0) or next;
	    my $span = int ((time - $t) / 86400);
	    push @$rel_clss,
		$span <=   30 ? "pass" : # green,  <= 30 days
		$span <=  182 ? "na"   : # yellow, <=  6 months
		$span <=  365 ? "warn" : # orange, <=  1 year
				"fail" ; # red
	    }
	$time{release} += t_used;

	# Travis CI
	my $tci       = $m->{tci} // ($git ? "https://travis-ci.org/$travis_id/$dist/builds" : "");
	my $tci_tag   = $tci ?  "*" : "";
	my $tci_class = [ "tci" ];
	if ($tci =~ m/travis-ci/ and $r = $ua->get ($tci =~ s{/builds$}{.svg}r) and $r->is_success) {
	    my %bs = map { $_ => 1 } ($r->content =~ m{<text[^>]+>([^<]+)</text>}g);
	    delete $bs{build};
	    $tci_tag = join "/" => sort keys %bs;
	    push @$tci_class,
		$bs{passing} ? "pass" :
		$bs{failing} ? "fail" :
		$bs{error}   ? "warn" : "na";
	    }
	$time{travis} += t_used;
	if ($tci_tag =~ m{^(?:unknown|\*|)$} && $git =~ m{\b github\.com \b}x) {
	    $tci       = "$git/settings/hooks/new?service=travis";
	    $tci_tag   = "add";
	    $tci_class = [ "tci", "gray" ];
	    }

	# ChangeLog
	$m->{cpan} //= "https://metacpan.org/release/$dist";
	my $cll = $m->{cpan} =~ m/metacpan/ ? "https://metacpan.org/changes/distribution/$dist" : "";
	$time{changelog} += t_used;

	# Coverage
	# http://cpancover.com/latest//Text-CSV_XS-1.18/index.html
	$data->{cover} //= {
	    branch	=> "-",
	    condition	=> "-",
	    pod		=> "-",
	    statement	=> "&x#237d;", # SHOULDERED OPEN BOX (uncovered)
	    subroutine	=> "-",
	    total	=> "-",
	    };
	my $cvrr;
	if (my $c = $coverage->{$dist}{$data->{version}}{coverage}{total}) {
	    $data->{cover}{$_} = $c->{$_} for keys %$c;
	    $cvrr = "http://cpancover.com/latest/$dist-$data->{version}/index.html";
	    }
	my $cvrl = join " \n" => map {
	    (sprintf "%-10s: %6s", $_, $data->{cover}{$_}) =~ s/ /\&nbsp;/gr;
	    } sort keys %{$data->{cover}};
	my $cvrt = { text => $data->{cover}{statement}, dtitle => $cvrl };
	my $cvrc = $data->{cover}{total} eq "-"        ? "none"
	         : $data->{cover}{total} eq "&x#237d;" ? "none"
	         : $data->{cover}{total} eq "n/a"      ? "none"
		 : $data->{cover}{total} >= 90         ? "pass"
		 : $data->{cover}{total} >= 70         ? "na"
		 : $data->{cover}{total} >= 50         ? "warn" : "fail";
	$time{coverage} += t_used;

	my $trc = $eo++ % 2 ? q{ class="other"} : "";
	say $html qq{          <tr$trc>};
	dta (                { text => $dist, title => $data->{abstract} // $mod }, $m->{cpan});
	dta (["version"   ], $data->{version},        $cll);
	dta ($rel_clss,      $rel_date);
	dta ($git_clss,      $git_tag || "-",         $git);
	dta ($issue_class,   $issues_tag,             $issues);
	dta ($issue_class,   $pr{"open"}[0],          $pr{"open"}[1]);
	dta ($issue_class,   $pr{"closed"}[0],        $pr{"closed"}[1]);
	dta (["rt"        ], $rt_tag,                 $rt);
	dta (["center"    ], "doc",                   $m->{doc}    // "https://metacpan.org/module/$mod");
	dta ($tci_class,     $tci_tag || "-",         $tci);
	dta (["kwt",$kwtc ], $data->{kwalitee},       $m->{cpants} // "http://cpants.perl.org/dist/overview/$dist");
	dta (["cvr",$cvrc ], $cvrt,                   $cvrr);
	dta (["cpt","pass"], $data->{cptst}[0] // "", $m->{ct}     // "http://www.cpantesters.org/show/$dist.html");
	dta (["cpt","na"  ], $data->{cptst}[1] // "");
	dta (["cpt","fail"], $data->{cptst}[2] // "", $m->{ctm}    // "http://matrix.cpantesters.org/?dist=$dist");
	dta ($cos_class,     $cos,                                    "http://deps.cpantesters.org/?module=$mod&amp;perl=5.22.0&amp;os=Any+OS");
	dta (["rd"        ], $rd,                     $m->{rd}     // "http://deps.cpantesters.org/depended-on-by.pl?module=$mod");
	dta (["kwt"       ], $data->{fav},
					$data->{fav} eq "-" ? undef : "https://metacpan.org/release/$dist/plussers");
	dta (["kwt"       ], $data->{rating},         $rating);
	say $html qq{            </tr>};

	$opt_t && $opt_v and show_times;
	}

    print $html <<"EOH";

          <tr><td colspan="19"><hr></td></tr>
          <tr>
            <td><a href="http://backpan.perl.org/authors/id/$auid3/$author/">BackPAN</a></td>
            <td colspan="11"><a href="http://analysis.cpantesters.org/?author=$author&amp;age=91.3&amp;SUBMIT_xxx=Submit">CPANTESTERS analysis</a></td>
            <td colspan="3" class="center"><a href="http://matrix.cpantesters.org/?author=$author">matrix</a></td>
            <td colspan="4"></td>
            </tr>
          </tbody>
        </table>
      </td>
    </tr>
EOH

    $opt_t && !$opt_v and show_times;
    } # modules

sub header {
    print $html <<"EOH";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="Generator"          content="makewww.pl">
  <meta name="Author"             content="H.Merijn Brand">
  <meta name="Description"        content="Perl">
  <title>$author Perl QA page</title>

  <link rel="stylesheet" type="text/css"  href="tux.css">
  </head>
<body>

<table>
EOH
    } # header

sub footer {
    my @d = localtime;
    my $stamp = sprintf "%02d-%02d-%04d", $d[3], $d[4] + 1, $d[5] + 1900;
    print $html <<"EOH";

  <tr class="boxed">
    <td class="boxed">
      <p class="header">Perl resources:</p>

      <table>
        <tr>
	  <td><a href="http://amsterdam.pm.org/">Amsterdam Perl Mongers</a></td>
	  <td><a href="http://www.perl.org">perl.org</a></td>
	  </tr>
        <tr>
	  <td><a href="https://metacpan.org">CPAN</a></td>
	  <td><a href="http://backpan.perl.org">BackPAN</a></td>
	  </tr>
        <tr>
	  <td><a href="http://www.perlmonks.org">Perl Monks</a></td>
	  <td><a href="http://use.perl.org">use perl;</a></td>
	  </tr>
        <tr>
	  <td><a href="http://www.cpantesters.org">cpantesters</a></td>
	  <td><a href="http://matrix.cpantesters.org">matrix</a></td>
	  </tr>
        <tr>
	  <td><a href="http://blogs.perl.org">perl blogs</a></td>
	  <td><a href="http://p3rl.org">p3rl</a></td>
	  </tr>
        <tr>
	  <td><a href="http://doc.perl6.org">perl6 documentation</a></td>
	  <td><a href="http://modules.perl6.org">perl6 modules</a></td>
	  </tr>
        <tr>
	  <td><a href="http://www.perl.org/docs.html">perl5 documentation</a></td>
	  <td><a href="http://www.perl.org/learn.html">learning perl</a></td>
	  </tr>
	</table>
      </td>
    </tr>
  </table>

<table>
  <tr>
    <td class="footer">&nbsp;</td>
    <td class="footer" style="text-align:center">
      last update: $stamp
      </td>
    <td></td>
    </tr>
  </table>
</body>
</html>
EOH
    } # footer
