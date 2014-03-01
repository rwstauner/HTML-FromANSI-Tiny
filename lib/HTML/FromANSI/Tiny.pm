# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package HTML::FromANSI::Tiny;
# ABSTRACT: Easily convert colored command line output to HTML

our @COLORS = map { "#$_" }
qw(
  000  f33  2c2  bb0  55c  d3d  0cc  bbb
  555  f66  6d6  dd6  99f  f6f  6dd  fff
);

=method new

Constructor.

Takes a hash or hash ref of options:

=for :list
* C<ansi_parser> - Instance of L<Parse::ANSIColor::Tiny>; One will be created automatically, but you can provide one if you want to configure it.
* C<class_prefix> - String to prefix class names; Blank by default for brevity. See L</html>.
* C<html_encode> - Code ref that should encode HTML entities; See L</html_encode>.
* C<inline_style> - Boolean to toggle using inline C<style=""> attributes instead of C<class=""> attributes.
* C<no_plain_tags> - Boolean for omitting the C<tag> when the text has no style attributes; Defaults to false for consistency.
* C<selector_prefix> - String to prefix each css selector; Blank by default. See L</css>.
* C<styles> - Tree of hashrefs for customizing style output (for C<< <style> >> tags or C<inline_style>). See L</CUSTOM STYLES>.
* C<tag> - Alternate tag in which to wrap the HTML; Defaults to C<span>.

For convenience and consistency options to L<Parse::ANSIColor::Tiny/new>
can be specified directly including
C<auto_reverse>, C<background>, and C<foreground>.

=cut

sub new {
  my $class = shift;
  my $self = {
    class_prefix => '',
    selector_prefix => '',
    tag => 'span',
    @_ == 1 ? %{ $_[0] } : @_,
  };

  require Parse::ANSIColor::Tiny
    if !$self->{ansi_parser};
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
  return $self->{ansi_parser} ||= do {
    # hash slice
    my (@fields, %copy) = qw(auto_reverse foreground background);
    @copy{ @fields } = @$self{ @fields };
    Parse::ANSIColor::Tiny->new(%copy);
  };
}

=method css

  my $css = $hfat->css();

Returns basic CSS code for inclusion into a C<< <style> >> tag.
You can use this if you don't want to style everything yourself
or if you want something to start with.

It produces code like this:

  .bold { font-weight: bold; }
  .red { color: #f33; }

It will include the C<class_prefix> and/or C<selector_prefix>
if you've set either:

    # with {class_prefix => 'term-'}
  .term-bold { font-weight: bold; }

    # with {selector_prefix => '#output '}
  #output .bold { font-weight: bold; }

    # with {selector_prefix => '#output ', class_prefix => 'term-'}
  #output .term-bold { font-weight: bold; }

Returns a list of styles or a concatenated string depending on context.

I tried to choose default colors that are close to traditional
terminal colors but also fairly legible on black or white.

Overwrite style to taste.

B<Note>: There is no default style for C<reverse>
as CSS does not provide a simple mechanism for this.
I suggest you use C<auto_reverse>
and set C<background> and C<foreground> to appropriate colors
if you expect to process C<reverse> sequences.
See L<Parse::ANSIColor::Tiny/process_reverse> for more information.

=cut

sub css {
  my ($self) = @_;
  my $prefix = $self->{selector_prefix} . '.' . $self->{class_prefix};

  my $styles = $self->_css_class_attr;

  my @css = (
    map { "${prefix}$_ { " . $self->_css_attr_string($styles->{$_}) . " }" }
      sort keys %$styles
  );

  return wantarray ? @css : join('', @css);
}

sub _css_class_attr {
  my ($self) = @_;
  return $self->{_all_styles} ||= do {

    my $parser = $self->ansi_parser;
    my $styles = {
      bold      => { 'font-weight'      => 'bold'      },
      dark      => { 'opacity'          => '0.7'       },
      underline => { 'text-decoration'  => 'underline' },
      concealed => { 'visibility'       => 'hidden'    },
    };
    {
      my $i = 0;
      foreach my $fg ( $parser->foreground_colors ){
        $styles->{$fg} = { color => $COLORS[$i++] };
      }
      $i = 0;
      foreach my $bg ( $parser->background_colors ){
        $styles->{$bg} = { 'background-color' => $COLORS[$i++] };
      }
    }

    # return
    +{
      %$styles,
      %{ $self->{styles} || {} },
    };
  };
}

sub _css_attr_string {
  my ($self, $attr) = @_;
  return join ' ', map { "$_: $attr->{$_};" } keys %$attr;
}

=method html

  my $html = $hfat->html($text);
  my @html_tags = $hfat->html($text);

Wraps the provided C<$text> in HTML
using C<tag> for the HTML tag name
and prefixing each attribute with C<class_prefix>.
For example:

  # defaults:
  qq[<span class="red bold">foo</span>]

  # {tag => 'bar', class_prefix => 'baz-'}
  qq[<bar class="baz-red baz-bold">foo</bar>]

C<$text> may be a string marked with ANSI escape sequences
or the array ref output of L<Parse::ANSIColor::Tiny>
if you already have that.

In list context returns a list of HTML tags.

In scalar context returns a single string of concatenated HTML.

=cut

sub html {
  my ($self, $text) = @_;

  $text = $self->_exclude_cursor_escape_sequences($text);

  $text = $self->ansi_parser->parse($text)
    unless ref($text) eq 'ARRAY';

  my $tag    = $self->{tag};
  my $prefix = $self->{class_prefix};
  # Preload if needed; Don't load if not.
  my $styles = $self->{inline_style} ? $self->_css_class_attr : {};

  local $_;
  my @html = map {
    my ($attr, $text) = @$_;
    my $h = $self->html_encode($text);

    $self->{no_plain_tags} && !@$attr
      ? $h
      : do {
        sprintf q[<%s %s="%s">%s</%s>], $tag,
          ($self->{inline_style}
            ? (style => join ' ', map { $self->_css_attr_string($styles->{$_}) } @$attr)
            : (class => join ' ', map { $prefix . $_ } @$attr)
          ), $h, $tag;
      }

  } @$text;

  return wantarray ? @html : join('', @html);
}

sub _exclude_cursor_escape_sequences {
  my ($self, $text) = @_;

  $text =~ s/\e\[2j//gi; # 2J: clear screen

  # 0K: clear row to the right end from current cursor position
  # 1K: clear row to the left end from current cursor position
  # 2K: clear row
  for my $type (0..2) {
    $text =~ s/\e\[${type}k//gi;
  }

  $text =~ s/\e\[\d+?;\d+?h//gi; # %d;%dH: move cursor by lengthwise and crosswise

  # %dA: move cursor to above
  # %dB: move cursor to below
  # %dC: move cursor to right
  # %dD: move cursor to left
  for my $direction ('a'..'d') {
    $text =~ s/\e\[\d+?${direction}//gi;
  }

  return $text;
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
or use the HTML entity encoder provided by your framework:

  my $hfat = HTML::FromANSI::Tiny->new(html_encode => sub { $app->h(shift) });

The code ref provided should take the first argument as the text to process
and return the encoded result.

=cut

sub html_encode {
  my ($self, $text) = @_;
  return $self->{html_encode}->($text)
    if $self->{html_encode};
  return HTML::Entities::encode_entities($text);
}

=method style_tag

Returns the output of L</css> wrapped in a C<< <style> >> tag.

Returns a list or a concatenated string depending on context.

=cut

sub style_tag {
  my ($self) = @_;
  my @style = ('<style type="text/css">', $self->css, '</style>');
  return wantarray ? @style : join('', @style);
}

=func html_from_ansi

Function wrapped around L</html>.

=head1 EXPORTS

Everything listed in L</FUNCTIONS> is also available for export upon request.

=cut

our @EXPORT_OK = qw( html_from_ansi );
sub html_from_ansi { __PACKAGE__->new->html(@_) }

sub import {
  my $class = shift;
  return unless @_;

  my $caller = caller;
  no strict 'refs'; ## no critic (NoStrict)

  foreach my $arg ( @_ ){
    die "'$arg' is not exported by $class"
      unless grep { $arg eq $_ } @EXPORT_OK;
    *{"${caller}::$arg"} = *{"${class}::$arg"}{CODE};
  }
}

1;

=for :stopwords html

=head1 SYNOPSIS

  use HTML::FromANSI::Tiny;
  my $h = HTML::FromANSI::Tiny->new(
    auto_reverse => 1, background => 'white', foreground => 'black',
  );

  # output from some command
  my $output = "\e[31mfoo\033[1;32mbar\033[0m";

  # include the default styles if you don't want to define your own:
  print $h->style_tag(); # or just $h->css() to insert into your own stylesheet

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

=head1 CUSTOM STYLES

To override the styles output in the L</style_tag> or L</css> methods
(or the attributes when C<inline_style> is used)
pass to the constructor a tree of hashrefs as the C<styles> attribute:

  styles => {
    underline => {
      'text-decoration'  => 'underline',
      'text-shadow'      => '0 2px 2px black',
    },
    red => {
      'color'            => '#f00'
    },
    on_bright_green => {
      'background-color' => '#060',
    }
  }

Any styles that are not overridden will get the defaults.

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
