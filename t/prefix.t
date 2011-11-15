use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $text = "foo\e[31m&\033[1;32mb<a>r";

my $h = new_ok($mod);

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="red">&amp;</span><span class="bold green">b&lt;a&gt;r</span>',
  'default prefix';

$h = new_ok($mod, [tag => 'rum', prefix => '']);

eq_or_diff
  scalar $h->html($text),
  '<rum class="">foo</rum><rum class="red">&amp;</rum><rum class="bold green">b&lt;a&gt;r</rum>',
  'blank prefix';

$h = new_ok($mod, [prefix => 'term-']);

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="term-red">&amp;</span><span class="term-bold term-green">b&lt;a&gt;r</span>',
  'custom prefix';

$h = new_ok($mod, [prefix => 'ansi:']);

eq_or_diff
  [$h->html($text)],
  ['<span class="">foo</span>', '<span class="ansi:red">&amp;</span>', '<span class="ansi:bold ansi:green">b&lt;a&gt;r</span>'],
  'custom prefix';

$h = new_ok($mod, [prefix => '0']);

eq_or_diff
  [$h->html($text)],
  ['<span class="">foo</span>', '<span class="0red">&amp;</span>', '<span class="0bold 0green">b&lt;a&gt;r</span>'],
  'custom false prefix';

done_testing;
