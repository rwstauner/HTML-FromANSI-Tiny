use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod);

my $text = "foo\e[31mbar\033[1;32mbaz";

eq_or_diff
  scalar $h->html($text),
  q[<span class="">foo</span><span class="red">bar</span><span class="bold green">baz</span>],
  'convert simple ansi to html';

done_testing;
