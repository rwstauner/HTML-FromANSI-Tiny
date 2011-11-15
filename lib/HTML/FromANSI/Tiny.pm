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

=head1 DESCRIPTION

=cut
