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

Return the fields of the template

=cut

sub fields
{
   my $self = shift;
   return $self->{fields};
}


=head2 $value = $template->field( $key )

Return the value of the field with the name given by $key, or undef if
no field with that name is defined.

TODO: Handle anonymous fields (using a numeric index) in the same way
      MW does. I guess the first anonymous field is always {{{1}}},
      then the next anonymous field is {{{2}}}? Or are all fields
      numbered from {{{1}}}, anonymous or not?

=cut

sub field {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    
    ## Note, fields are stored in an array to preserve their order. If
    ## I were brave, I'd build an index hash that would be updated by
    ## methods adding or removing fields (where?). Until then...
    
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



sub to_string {
    my $self = shift;
    
    ## nothing to return
    return ''
      if exists $self->{truncated};
    
    my $title  = $self->title;
    my $fields = $self->fields;
    
#    @$fields > 1 ?
#      $title .= "\n":
#      $title .=  '|';

    return '{{'. 
      join( '|', $title, map { field_to_string( $_ ) } @$fields ).
	"}}";
}

sub field_to_string {
    my $field = shift;
    
    my $key = $field->{key} ? $field->{key}. '=' : '';
    
    my @values = @{$field->{value}};
    
    ## Recurse...
    for(my $i=0; $i<@values; $i++){
	if(ref($values[$i]) eq 'MediaWiki::Template'){
	    $values[$i] = $values[$i]->to_string;
	}
    }
    
    return $key. join( '', @values );
}

sub truncate {
    my $self = shift;
    %$self = (truncated => 1);
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
