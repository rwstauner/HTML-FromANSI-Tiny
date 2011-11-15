# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package HTML::FromANSI::Tiny;
# ABSTRACT: Easily convert command line output to html

=method new

Constructor.

Takes a hash or hash ref of options:

=for :list
* C<ansi_parser> - An instance of L<Parse::ANSIColor::Tiny>; One will be created automatically, but you can provide one if you want to configure it.
* C<html_encode> - A code ref that should encode HTML entities; See L</html_encode>.
* C<join> - A string to join the html; See L</html>.

=cut

sub new {
  my $class = shift;
  my $self = {
    @_ == 1 ? %{ $_[0] } : @_,
  };

  require HTML::Entities
    if !$self->{html_encode};

  bless $self, $class;
}

=method ansi_parser

Returns the L<Parse::ANSIColor::Tiny> instance in use.
Creates one if necessary.

=cut

sub ansi_parser {
  my ($self) = @_;
  $self->{ansi_parser} ||= do {
    require Parse::ANSIColor::Tiny;
    Parse::ANSIColor::Tiny->new();
  };
}

=method html

  my $html = $hfat->html($text);
  my @html_tags = $hfat->html($text);

Wraps the provided C<$text> in HTML.
C<$text> may be a string marked with ANSI escape sequences
or the array ref output of L<Parse::ANSIColor::Tiny>
if you already have that.

In scalar context (or if the C<join> option is set)
returns a single string of the concatenated HTML
joined by the C<join> string or C<''>.

In list context (when C<join> is not set)
returns a list of HTML tags.

=cut

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

=method html_encode

  my $html = $hfat->html_encode($text);

Encodes the text with HTML character entities.
so it can be inserted into HTML tags.

This is used internally by L</html> to encode
the contents of each tag.

By default the C<encode_entities> function of L<HTML::Entities> is used.

You may provide an alternate subroutine (code ref) to the constructor
as the C<html_encode> parameter in which case that sub will be used instead.
This allows you to set different options
or use the html entity encoder provided by your framework:

  my $hfat = HTML::FromANSI::Tiny->new(html_encode => sub { $app->h(shift) });

=cut

sub html_encode {
  my ($self, $text) = @_;
  return $self->{html_encode}->($text)
    if $self->{html_encode};
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
