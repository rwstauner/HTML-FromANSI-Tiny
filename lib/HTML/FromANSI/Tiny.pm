# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package HTML::FromANSI::Tiny;
# ABSTRACT: Easily convert command line output to html

sub new {
  my $class = shift;
  my $self = {
    @_ == 1 ? %{ $_[0] } : @_,
  };

  require HTML::Entities
    if !$self->{html_encoder};

  bless $self, $class;
}

sub html {
  my ($self, $text) = @_;
  $text = $self->ansi_parser->parse($text)
    unless ref($text) eq 'ARRAY';

  my @html = map {
    '<span class="' .  join(' ', @{ $_->[0] }) . '">' .
      $self->html_encode($_->[1]) . '</span>'
  } @$text;

  return defined($self->{join}) || !wantarray
    ? join($self->{join}||'', @html)
    : @html;
}

sub ansi_parser {
  my ($self) = @_;
  $self->{ansi_parser} ||= do {
    require Parse::ANSIColor::Tiny;
    Parse::ANSIColor::Tiny->new();
  };
}

sub html_encode {
  my ($self, $text) = @_;
  return $self->{html_encoder}->($text)
    if $self->{html_encoder};
  return HTML::Entities::encode_entities($text);
}

1;

=head1 SYNOPSIS

  use HTML::FromANSI::Tiny;
  my $h = HTML::FromANSI::Tiny->new();

  # output from some command
  my $output = "\e[31mfoo\033[1;32mbar\033[0m";

  print $h->html($output);
  # prints '<span class="red">foo</span><span class="bold green">bar</span>'

=head1 DESCRIPTION

Convert the output from a terminal command that is decorated
with ANSI escape sequences into customizable HTML
(with a small amount of code).

This module complements L<Parse::ANSIColor::Tiny>
by providing a simple HTML markup around its output.

L<Parse::ANSIColor::Tiny> returns a data structure that's easy
to reformat into any desired output.
Reformatting to HTML seemed simple and common enough
to warrant this module as well.

=head1 COMPARISON TO HTML::FromANSI

L<HTML::FromANSI> is a bit antiquated (as of v2.03 released in 2007).
It uses C<font> tags and the C<style> attribute
and isn't very customizable.

It uses L<Term::VT102> which is probably more robust than
L<Parse::ANSIColor::Tiny> but may be overkill for simple situations.
I've also had trouble installing it in the past.

For many simple situations this module combined with L<Parse::ANSIColor::Tiny>
is likely sufficient and is considerably smaller.

=head1 SEE ALSO

=for :list
* L<Parse::ANSIColor::Tiny>
* L<HTML::FromANSI>

=cut
