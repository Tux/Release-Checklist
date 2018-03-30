#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.01 - 20180330";

-d ".git" or exit 0;

my @m = stat "Checklist.md";
my @h = stat "Checklist.html";

$m[9] && $h[9] && $h[9] >= $m[9] and exit 0;
open STDOUT, ">", "Checklist.html";

print <<"EOH";
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <title>Release Checklist</title>
  </head>
<body>
EOH

system "multimarkdown", "Checklist.md";

print "</body></html>\n"
