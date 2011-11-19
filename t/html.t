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
  [$h->html("\e[31mfoo\033[1;32mbar\033[0m")],
  ['<span class="red">foo</span>', '<span class="bold green">bar</span>'],
  'convert synopsis example in list context';

eq_or_diff
  scalar $h->html("foo\e[31mba\e[0mr\033[1;32mbaz"),
  q[<span class="">foo</span><span class="red">ba</span><span class="">r</span><span class="bold green">baz</span>],
  'slightly more complex';

$h = new_ok($mod, [ {tag => 'pre', class_prefix => 'term-'} ]);

eq_or_diff
  scalar $h->html("foo\e[31mba\e[0mr\033[1;32mbaz"),
  q[<pre class="">foo</pre><pre class="term-red">ba</pre><pre class="">r</pre><pre class="term-bold term-green">baz</pre>],
  'slightly more complex';

eq_or_diff
  [$h->html("foo\e[31mba\e[0mr\033[1;32mbaz")],
  ['<pre class="">foo</pre>', '<pre class="term-red">ba</pre>', '<pre class="">r</pre>', '<pre class="term-bold term-green">baz</pre>'],
  'slightly more complex in list context';

$h = new_ok($mod, [ {class_prefix => 't_', no_plain_tags => 1} ]);

eq_or_diff
  scalar $h->html("hey \e[7mLOOK AT THIS"),
  q[hey <span class="t_reverse">LOOK AT THIS</span>],
  'no auto_reverse; get "reverse" class';

$h = new_ok($mod, [ {class_prefix => 't_', no_plain_tags => 1, auto_reverse => 1} ]);

eq_or_diff
  scalar $h->html("hey \e[7mLOOK AT THIS"),
  q[hey <span class="t_on_white t_black">LOOK AT THIS</span>],
  'with auto_reverse get default colors';

done_testing;
