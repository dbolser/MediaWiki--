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
  
  ## TODO: Should carp if we don't have a title_string
  
  ## Wikify the title_string
  $args{title} = wikify( $args{title_string}, 1 );
  
  ## Wikify the key_string for each field (if any).

  ## Note, we don't 'wikify' this in the same way as the title_string
  ## above. Instead this step could be implemented by the 'fields'
  ## function (below) when matching?
  for(@{$args{fields}}){
      $_->{key} = wikify( $_->{key_string} );
  }
  
  bless \%args, $class;
}



=head1 ACCESSORS

=cut

=head2 $title = $template->title

Returns the title of the Template.

TODO: Make getters and setters? If so, remember that updates to the
      title or string fields need to update the title_string or
      key_string fields (and vice verse).

=cut

sub title
{
   my $self = shift;
   return $self->{title};
}

=cut

=head2 $title = $template->title_string

Returns the title string for the template

=cut

sub title_string
{
   my $self = shift;
   return $self->{title_string};
}

=head2 $fields = $template->fields

Return the fields of the template

=cut

sub fields
{
   my $self = shift;
   return $self->{fields};
}


=head2 $value = $template->field( $key [, $value] )

Return (OR SET) the value of the field with the name given by $key, or
undef if no field with that name is defined.

TODO: Use the (currently unimplemented) key setter to set a new
      key=value if the given key doesn't exist and a value is given.

TODO: Handle anonymous fields (using a numeric index) in the same way
      MW does. I guess the first anonymous field is always {{{1}}},
      then the next anonymous field is {{{2}}}? Or are all fields
      numbered from {{{1}}}, anonymous or not?

=cut

sub field {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    
    ## Lookup is standardized
    $key = wikify( $key );
    
    ## Note, fields are stored in an array to preserve their order. If
    ## I were brave, I'd build an index hash that would be updated by
    ## methods adding or removing fields (where?). Until then...
    
    ## Also, fields could be objects?
    
    for my $field ( @{$self->{fields}} ){
        if ($field->{key} eq $key){
            if(defined $val){
                $field->{value} = $val;
            }
            return $field->{value}
        }
    }
    return undef;
}



=head2 $value = $template->to_string

Functions to write the template out. This should be 'round trip' safe
(by design), assuming nothing was changed.

=cut

sub to_string {
    my $self = shift;
    
    ## nothing to return
    return ''
      if exists $self->{truncated};
    
    my $title_string  = $self->title_string;
    my $fields        = $self->fields;
    
    return
        '{{'. join( '|', $title_string,
                    map { field_to_string( $_ ) } @$fields ). '}}';
}

sub field_to_string {
    my $field = shift;
    
    my $key_string = $field->{key_string} ? $field->{key_string}. '=' : '';
    
    my @values = @{$field->{value}};
    
    ## Recurse...
    for(my $i=0; $i<@values; $i++){
        if(ref($values[$i]) eq 'MediaWiki::Template'){
            $values[$i] = $values[$i]->to_string;
        }
    }
    
    return $key_string. join( '', @values );
}

=head2 $value = $template->truncate

Pseudo-delete the template (nothing is deleted, but it will be printed
as an empty string).

=cut

sub truncate {
    my $self = shift;
    %$self = (truncated => 1);
}



=head2 $value = wikify( $value string [, $is_title ] )

Convert template keys and titles into their canonical 'wiki'
form. This means that searches for a template called 'Some such' will
match templates called like 'some such ', ' Some   such', and so on.

TODO: Put this in a utility package?

=cut

sub wikify {
    my $identifier = shift;
    my $is_title   = shift || 0;
    
    ## 1) Strip leading and trailing whitespace
    $identifier =~ s/^\s*(.*\S)\s*$/$1/ms;
    
    ## If this is a template title,
    if($is_title){
        
        ## 2) compress internal whitespace (including newlines)
        $identifier =~ s/\s+/ /gms;
        
        ## 3) and enforce MediaWiki's case insensitivity in the first
        ##    character...
        $identifier =
            uc(substr($identifier,0,1)). substr($identifier,1);
    }
    
    return $identifier;
}





=head1 AUTHOR

Dan Bolser, C<< <dan.bolser [at] gfail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mediawiki-api at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MediaWiki-API>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


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

=item * Jools 'BuZz' Wills, C<< <buzz [at] exotica.org.uk> >> for MW:API

=item * Leo Nerd for P:MGC and moral support

=item * Eveyone in irc://irc.freenode.net/#perl

=back

=head1 COPYRIGHT & LICENSE

CopyLeft

=cut

1;
