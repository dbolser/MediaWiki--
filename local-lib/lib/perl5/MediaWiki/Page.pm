package MediaWiki::Page;

use warnings;
use strict;

=head1 NAME

MediaWiki::Page - A MediaWiki 'Page' object

=cut

=head1 CONSTRUCTOR

=cut

=head2 $page = MediaWiki::Page->new( %args )

Returns a new instance initialised by the given arguments.

=over 8

=item elements => ARRAY

ARRAY of page 'elements', currently just 'wikitext' or 'template'
objects.

=back

=cut

sub new {
    my $class = shift;
    my %args  = @_;
    
    bless \%args, $class;
}


=head1 ACCESSORS

=cut

=head2 $template = $page->template_by_title( 'title' )

Returns the template with the given title, or undef

=cut

sub template_by_title{
    my $self  = shift;
    my $title = shift;
    
    foreach (@{$self->elements}){
	next unless ref eq 'MediaWiki::Template';
	next unless $_->title eq $title;
	return $_;
    }
    return undef;
}



=head2 $template = $page->templates

Returns all the templates in the page

=cut

sub templates{
    my $self  = shift;
    
    return
	[grep { ref eq 'MediaWiki::Template' } @{$self->elements}];
}



=head2 $elements = $page->elements

Returns all the elements in the page

=cut

sub elements{
    my $self  = shift;    
    return $self->{elements};
}

1;
