#!/pro/bin/perl

use 5.20.0;
use warnings;

our $VERSION = "1.19 - 2015-10-19";

sub usage
{
  my $err = shift and select STDERR;
  say "usage: $0 [-v] [--git=author] AUTHOR\n";
  exit $err;
  } # usage

use Getopt::Long qw(:config bundling);
my $opt_v = 0;
GetOptions (
  "help|?"	=> sub { usage (0); },
  "v|verbose:1"	=> \$opt_v,
  "g|git=s"	=> \my $git_id,
  ) or usage (1);

my $author = shift or usage (1);
   $author = uc $author;
my $auid1  = substr $author, 0, 1;
my $auid3  = "$auid1/" . substr $author, 0, 2;

use Data::Peek;
use LWP;
use JSON::XS;
use YAML::Tiny;
use LWP::UserAgent;
use HTML::TreeBuilder;
use Encode qw( encode decode );
use Date::Calc qw( Parse_Date Date_to_Time );

use MetaCPAN::Client;
use CPAN::Testers::WWW::Reports::Query::AJAX;

my $ua = LWP::UserAgent->new;
$ua->agent ("Opera/30");

my %mod;
$opt_v and say "Fetch releases from $author";
{   my $r = $ua->get ("https://metacpan.org/author/$author");
    $r->is_success or die "Cannot fetch release list for $author\n";
    my $tree = HTML::TreeBuilder->new;
    $tree->parse_content (decode ("utf-8", $r->content));
    foreach my $tbl ($tree->look_down (_tag => "table", id => "author_releases")) {
	for ($tbl->look_down (_tag => "a", class => "ellipsis")) {
	    my $ttl = $_->attr ("title");
	    my $mod = $_->attr ("href");
	       $mod =~ s{^/release/}{} or next;
	       $mod =~ s/-/::/g;
	    $opt_v > 1 and say " $mod";
	    $mod{$mod} = { git => "-" };

	    my $repo = "-";
	    my $j = $ua->get ("https://api.metacpan.org/source/$ttl/META.json");
	    if ($j->is_success) {
		my $meta = decode_json ($j->content);
		$repo = $meta->{resources}{repository} || "-";
		ref $repo eq "HASH" and
		    $repo = $repo->{web} || $repo->{url} || "-";
		}
	    else {
		$j = $ua->get ("https://api.metacpan.org/source/$ttl/META.yml");
		if ($j->is_success) {
		    my $meta = YAML::Tiny->read_string ($j->content);
		    $repo = $meta->[0]{resources}{repository} || "-";
		    }
		}
	    if ($repo =~ m{\bgithub\.com\b}) {
		$repo =~ s{^git\@github.com:}{https://github.com/};
		$repo =~ s{^git:}{https:};
		$repo =~ s{\.git$}{};
		$repo =~ m{github.com/([^/]+)} and $git_id //= $1;
		}
	    $mod{$mod}{git} = $repo;
	    $opt_v > 2 and say "  $repo";
	    }
	}
    }
#$git_id  //= lc $author;

my $buffer = "";
open my $html, ">", \$buffer;
header ();
modules ();
footer ();
close $html;
open  $html, ">:encoding(utf-8)", "myperl.html";
print $html $buffer;
close $html;

sub href
{
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
    $ref ? qq{<a href="$ref"$ttl>$txt</a>} : $txt // "-";
    } # href

sub dta
{
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
    if ($tag =~ m{class=".*\b(pass|na|warn|fail)[ "]}) {
	my $c = $1;
	$link =~ s{<a \K}{class="$c" };
	}
    say $html "            <$tag>$link$info</td>";
    } # dta

sub modules
{
    print $html <<"EOH";

  <tr class="boxed">
    <td class="boxed" colspan="2">
      <p class="header">My modules</p>
      <table>
        <thead>
          <tr>
            <th><a href="http://metacpan.org/author/$author">Distribution</a></th>
            <th>vsn</th>
            <th class="rhdr">released</th>
            <th class="tci" colspan="2"><a href="https://github.com/$git_id">repo</a></th>
            <th class="rhdr"><a href="http://rt.cpan.org/Public/Dist/ByMaintainer.html?Name=$author">RT</a></th>
            <th class="center">doc</th>
            <th class="tci"><a href="https://travis-ci.org/profile/$git_id">TravisCI</a></th>
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

    my $mcpan = MetaCPAN::Client->new ();

    my $coverage = {};
    $_ = $ua->get ("http://cpancover.com/latest/cpancover.json") and $_->is_success and
	$coverage = decode_json ($_->content);

    foreach my $mod (sort keys %mod) {

	$opt_v and say $mod;

	my $m    = $mod{$mod}; $m->{skip} and next;
	my $dist = $mod =~ s/::/-/gr;
	my $data = eval { $mcpan->module ($mod)->{data} } || {};
	if ($m->{data}) {
	    $data->{$_} = $m->{data}{$_} for keys %{$m->{data}};
	    }

	$data->{fav} = $mcpan->favorite ({ distribution => $dist })->{total} || "-";

	my $rating = "";
	$data->{rating} = { text => "-" };
	if (my $rs = $mcpan->rating ({ distribution => $dist })->scroller) {
	    my $n = $rs->total;
	    if (my $r = $rs->next) {
		$rating = "http://cpanratings.perl.org/d/$dist";
		$data->{rating} = {
		    text   => $r->{_source}{rating},
		    dtitle => "$n votes",
		    };
		}
	    }

	$data->{version} //= "*";

	# Kwalitee
	my $kwtc = "none";
	unless (defined $data->{kwalitee}) {
	    ($_ = $ua->get ("http://cpants.cpanauthors.org/dist/$dist")) &&
	     $_->is_success && $_->content =~ m{
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

	# GIT repo and last commit
	my $git = $m->{git}; # // "https://github.com/$git_id/$dist",
	my $git_tag = {
	    text   => "git",
	    dtitle => "",
	    };
	my $git_clss = [ "git" ];
	if ($git =~ m/\b github.com \b/x) {
	    $_ = $ua->get ("$git/commits/master");
	    my $tree = HTML::TreeBuilder->new;
	    $tree->parse_content ($_ && $_->is_success ? decode ("utf-8", $_->content) : "");
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

	# CPANTESTER results
	!defined $data->{tests} and
	    $data->{tests} =
	      ($_ = CPAN::Testers::WWW::Reports::Query::AJAX->new (dist => $dist))
		? [ $_->pass, $_->na, $_->fail, $_->unknown ]
		: [ "", "", "", "" ];

	# RT tickets
	my $rt = $m->{rt} // "http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist";
	#                    "https://rt.cpan.org/Dist/Display.html?Name=$dist";
	my $rt_tag = "*";
	if ($rt =~ m{/rt.cpan.org/}) {
	    if ($_ = $ua->get ($rt) and $_->is_success) {
		my $tree = HTML::TreeBuilder->new;
		$tree->parse_content (decode ("utf-8", $_->content));
		my %id;
		$id{$_->attr ("href")}++ for
		    $tree->look_down (_tag => "a", href => qr{^/Ticket/Display.html\?id=[0-9]+$});
		$rt_tag = scalar keys %id;
		}
	    }

	# Github issues
	my $issues;
	my $issues_tag  = "-";
	my $issue_class = [ "date" ];
	if ($git =~ m/\b github.com \b/x) {
	    my $il = "$git/issues";
	    $_ = $ua->get ($il);
	    my $tree = HTML::TreeBuilder->new;
	    if ($_ && $_->is_success) {
		$issues     = $il;
		$issues_tag = "0";
		$tree->parse_content (decode ("utf-8", $_->content));
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
	    }
	unless ($rt_tag =~ m/^[-0-9]?$/) {
	    $rt_tag =
		(($_ = $ua->get ("https://api.metacpan.org/distribution/$dist")) &&
		  $_->is_success && decode_json ($_->content)->{bugs}{active}) || "*";
	    }

	# Downriver deps
	my $rd = $data->{rd} // do {
	    $_ = $ua->get ("http://deps.cpantesters.org/depended-on-by.pl?module=$mod");
	    my $tree = HTML::TreeBuilder->new;
	    $tree->parse_content ($_ && $_->is_success ? $_->content : "");
	    my $x = 0;
	    $x++ for $tree->look_down (_tag => "li");
	    $x || "-";
	    };
	my $cos       = "-";
	my $cos_class = [ "rd" ];
	{   $_ = $ua->get ("http://deps.cpantesters.org/?module=$mod&perl=5.22.0&os=any+OS");
	    my $tree = HTML::TreeBuilder->new;
	    $tree->parse_content ($_ && $_->is_success ? $_->content : "");
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

	# Travis CI
	my $tci = $m->{tci} // "https://travis-ci.org/$git_id/$dist/builds";
	my $tci_tag = $tci ?  "*" : "";
	$tci =~ m/travis-ci/ and $_ = $ua->get ($tci =~ s{/builds$}{.svg}r) and $_->is_success and
	    $tci_tag = $_->content;

	# ChangeLog
	$m->{cpan} //= "http://metacpan.org/release/$dist";
	my $cll = $m->{cpan} =~ m/metacpan/ ? "https://metacpan.org/changes/distribution/$dist" : "";

	# Coverage
	# http://cpancover.com/latest//Text-CSV_XS-1.18/index.html
	$data->{cover} //= {
	    branch	=> "-",
	    condition	=> "-",
	    pod		=> "-",
	    statement	=> "-",
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
	my $cvrc = $data->{cover}{total} eq "-"   ? "none"
	         : $data->{cover}{total} eq "n/a" ? "none"
		 : $data->{cover}{total} >= 90    ? "pass"
		 : $data->{cover}{total} >= 70    ? "na"
		 : $data->{cover}{total} >= 50    ? "warn" : "fail";

	say $html qq{          <tr>};
	dta (                { text => $dist, title => $data->{abstract} // $mod }, $m->{cpan});
	dta (["version"   ], $data->{version},        $cll);
	dta ($rel_clss,      $rel_date);
	dta ($git_clss,      $git_tag,                $git);
	dta ($issue_class,   $issues_tag,             $issues);
	dta (["rt"        ], $rt_tag,                 $rt);
	dta (["center"    ], "doc",                   $m->{doc}    // "http://metacpan.org/module/$mod");
	dta (["tci"       ], $tci_tag,                $tci);
	dta (["kwt",$kwtc ], $data->{kwalitee},       $m->{cpants} // "http://cpants.perl.org/dist/overview/$dist");
	dta (["cvr",$cvrc ], $cvrt,                   $cvrr);
	dta (["cpt","pass"], $data->{tests}[0] // "", $m->{ct}     // "http://www.cpantesters.org/show/$dist.html");
	dta (["cpt","na"  ], $data->{tests}[1] // "");
	dta (["cpt","fail"], $data->{tests}[2] // "", $m->{ctm}    // "http://matrix.cpantesters.org/?dist=$dist");
	dta ($cos_class,     $cos,                                    "http://deps.cpantesters.org/?module=$mod&amp;perl=5.22.0&amp;os=Any+OS");
	dta (["rd"        ], $rd,                     $m->{rd}     // "http://deps.cpantesters.org/depended-on-by.pl?module=$mod");
	dta (["kwt"       ], $data->{fav},
					$data->{fav} eq "-" ? undef : "https://metacpan.org/release/$dist/plussers");
	dta (["kwt"       ], $data->{rating},         $rating);
	say $html qq{            </tr>};
	}

    print $html <<"EOH";

          <tr><td colspan="17"><hr /></td></tr>
          <tr>
            <td><a href="http://backpan.perl.org/authors/id/$auid3/$author/">BackPAN</a></td>
            <td colspan="8"><a href="http://analysis.cpantesters.org/?author=$author&amp;age=91.3&amp;SUBMIT_xxx=Submit">CPANTESTERS analysis</a></td>
            <td colspan="3" class="center"><a href="http://matrix.cpantesters.org/?author=$author">matrix</a></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            </tr>
          </tbody>
        </table>
      </td>
    </tr>
EOH
    } # modules

sub header
{
    print $html <<"EOH";
<?xml version="1.0" encoding="utf-8"?>  
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">       
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <title>My Perl QA page</title>
  <meta name="Generator"     content="makewww.pl" />
  <meta name="Author"        content="H.Merijn Brand" />
  <meta name="Description"   content="Perl" />

  <link rel="stylesheet" type="text/css"  href="tux.css" />
  </head>
<body>

<table>
EOH
    } # header

sub footer
{
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
	  <td><a href="http://metacpan.org">CPAN</a></td>
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
  <colgroup>
    <col width="33%" />
    <col width="33%" />
    </colgroup>
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
