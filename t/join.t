use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'HTML::FromANSI::Tiny';
eval "require $mod" or die $@;

my $h = new_ok($mod, []);

my $text = "foo\e[31m&\033[1;32mb<a>r";

eq_or_diff
  scalar $h->html($text),
  '<span class="">foo</span><span class="red">&amp;</span><span class="bold green">b&lt;a&gt;r</span>',
  'joined sting in scalar context';

eq_or_diff
  [$h->html($text)],
  ['<span class="">foo</span>', '<span class="red">&amp;</span>', '<span class="bold green">b&lt;a&gt;r</span>'],
  'list of tags in list context';

my $h = new_ok($mod, [join => "\n"]);

eq_or_diff
  scalar $h->html($text),
  qq[<span class="">foo</span>\n<span class="red">&amp;</span>\n<span class="bold green">b&lt;a&gt;r</span>],
  'custom join string in scalar context';

eq_or_diff
  [$h->html($text)],
  [qq[<span class="">foo</span>\n<span class="red">&amp;</span>\n<span class="bold green">b&lt;a&gt;r</span>]],
  'respect join string in list context';

done_testing;
