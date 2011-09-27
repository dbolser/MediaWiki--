package MediaWiki::Template;

use warnings;
use strict;

use Carp;

use Data::Dumper;

=head1 NAME

MediaWiki::Template - A MediaWiki template object

=cut

=head1 SYNOPSIS

This module provides an object interface for MediaWiki templates,
using references to the text of the page. Functions on the resulting
template objects are immediately reflected in the page text, because
we use references.

  use MediaWiki::API;
  use MediaWiki::Template;

  my $mw = MediaWiki::API->new();
  $mw->{config}->{api_url} = 'http://en.wikipedia.org/w/api.php';

  # get an article somehow
  my $article = ...

  my $templates = MediaWiki::Template->
    new_from_text( \$article->text )

    ...

  my $template = MediaWiki::Template->new( $ARRAY_REF );

  $template->getters_and_setters();
  $template->manipulate();
  ...


=head1 DESCRIPTION

...

=cut

=head1 CONSTRUCTOR

=cut

=head2 $template = MediaWiki::Template->new( %args )

Returns a new instance initialised by the given arguments.

=over 8

=item title => STRING

Name title of the template

=item fields => ARRAY

Optional ARRAY references containing the template fields

=back

=cut

sub new {
  my $class = shift;
  my %args  = @_;
  
  bless \%args, $class;
}


=head1 ACCESSORS

=cut

=head2 $title = $template->title

Returns the title of the template

=cut

sub title
{
   my $self = shift;
   return $self->{title};
}

=head2 $fields = $template->fields

Return the fields, or undef if no fields are defined.

=cut

sub fields
{
   my $self = shift;
   return undef
       unless length @{$self->{fields}};
   return $self->{fields};
}


=head2 $fields = $template->field( $key )

Return the value of the field with the name given by $key, or undef if
no field with that name is defined.

TODO: Handle anonymous fields (using a numeric index) in the same way
      MW does. I guess the first anonymous field is always {{{1}}},
      then the next anonymous field is {{{2}}}? Or are all fields
      numbered from {{{1}}}, anonymous or not?

=cut

sub field
{
   my $self = shift;
   my $key  = shift;
   
   ## Note, fields are stored in an array to preserve their order. If
   ## I were brave, I'd build an index hash that would be updated by
   ## methods adding or removing fields. Until then...
   
   for my $field ( @{$self->{fields}} ){
       return $field->{value}
	 if $field->{key} eq $key;
   }
   return undef;
}



1;

__END__

, $name ) = @_;
  #print "\n", Dumper $template;
  
  my $name;   # The template name (mandatory)
  my @fields; # The template fields (optional)
  
  ## I should croak?
  die unless
    ref($template) eq 'ARRAY';
  
  die scalar @$template, "\n" unless
    @$template <= 2;
  
  $name = $template->[0];
  
  if(@$template>1){
    die unless
      ref($template->[1]) eq 'ARRAY';
    
    @fields = @{$template->[1]};
  }
  
  ## Check fields
  for my $field (@fields){
    _check_fields($field)
      or die;
  }
  
  my $self =
    { 'name'   => $name,
      'fields' => @fields,
    };
  
  bless ($self, $class);
  
  return $self;
}



sub _check_fields {
  my $field = shift;
  #print "\n", Dumper $field;
  
  ## I should croak?
  die $field unless
    ref($field) eq 'ARRAY';
  
  die scalar @$field, "\n" unless
    @$field <= 2;
  
  $field->[-1] = MediaWiki::Template->new( $field->[-1] )
    if ref($field->[-1]);
  
  return 1;
}





sub to_text {
  my $self = shift;

  my $name   = $self->name;
  my $fields = $self->fields;

  my @fields =
    map "$_=". $fields->{$_},
      keys %$fields;

  my $text = '{{'.
    join("\n|", $name, @fields).
      (@fields ? "\n}}" : "}}");

  return $text;
}

sub name {
  my $self = shift;
  $self->{name} = shift if @_;
  return $self->{name};
}

sub fields {
  my $self = shift;
  $self->{fields} = shift if @_;
  return $self->{fields};
}



sub new_from_text {
  my ($class, $text) = @_;

  my @templates;

  while($text =~ /{{.*?}}/gs){
    my $beg = $-[0];
    my $end = $+[0];
    my $len = $end - $beg;

    #print "got one from $beg to $end ($len)\n";

    push @templates, \substr($text, $beg, $len);
  }

  return \
@templates;
}


sub _template_from_text {
  my $text = shift;

  $text =~ /{{(.*?)}}/s
    or die "foff\n";
    
  my @data = split(/\|/, $1);
    
    
}








__END__

=head1 AUTHOR

Jools 'BuZz' Wills, C<< <buzz [at] exotica.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mediawiki-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MediaWiki-API>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MediaWiki::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MediaWiki-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MediaWiki-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MediaWiki-API>

=item * Search CPAN

L<http://search.cpan.org/dist/MediaWiki-API>

=back


=head1 ACKNOWLEDGEMENTS

=over

=item * Carl Beckhorn (cbeckhorn [at] fastmail.fm) for ideas and support

=item * Stuart 'Kyzer' Caie (kyzer [at] 4u.net) for UnExoticA perl code and support

=item * Edward Chernenko (edwardspec [at] gmail.com) for his earlier MediaWiki module

=item * Dan Collins (EN.WP.ST47 [at] gmail.com) for bug reports and patches

=item * Jonas 'Spectral' Nyren (spectral [at] ludd.luth.se) for hints and tips!

=item * Jason 'XtC' Skelly (xtc [at] amigaguide.org) for moral support

=item * Nikolay Shaplov (n [at] shaplov.ru) for utf-8 patches and testing

=item * Jeremy Muhlich (jmuhlich [at] bitflood.org) for utf-8 patches and testing for api upload support patch

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2011 Jools Wills, all rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1; # End of MediaWiki::API
