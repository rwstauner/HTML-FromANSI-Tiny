use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod);

eq_or_diff
  scalar $h->html("\e[31mfoo\033[1;32mbar\033[0m"),
  '<span class="red">foo</span><span class="bold green">bar</span>',
  'convert synopsis example';

eq_or_diff
  scalar $h->html("foo\e[31mba\e[0mr\033[1;32mbaz"),
  q[<span class="">foo</span><span class="red">ba</span><span class="">r</span><span class="bold green">baz</span>],
  'slightly more complex';

done_testing;
