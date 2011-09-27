package MediaWiki::Page;

use warnings;
use strict;

use Data::Dumper;

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

=head2 $elements = $page->elements

Returns all the elements in the page.

Not especially useful, but lets you grab the underlying page data
structure if you need.

=cut

sub elements{
    my $self  = shift;
    return $self->{elements};
}



=head2 $template = $page->templates

Returns all the templates in the page

=cut

sub templates{
    my $self  = shift;
    
    return
      [grep { ref eq 'MediaWiki::Template' } @{$self->elements}];
}



=head2 $template = $page->template_by_title( 'title' )

Returns the template with the given title, or undef

=cut

sub template{
    my $self  = shift;
    my $title = shift;
    
    foreach (@{$self->templates}){
	next unless $_->title eq $title;
	return $_;
    }
    return undef;
}



=head2 $template = $page->template_match( \%query )

Returns the templates matching the given title and fields (keys and
values), where specified, or undef.

The 'query' should resemble a single parsed template, i.e.

 { title  => 'x',
   fields => [ { key => 'y', value => [ 'z' ] },
               { key => 'j' } ]
 }

or
 { fields => [ key => 'x' ] }

or (NOT IMPLEMENTED)
 { fields => [ value => [ 'x' ] ] }


When unspecified, the title, fields or values match all templates (in
theory...).

TODO: Investigate DOM and XPath?

=cut

sub template_match{
    my $self = shift;
    my $args = shift;
    my @matches;
    
    foreach my $template (@{$self->templates}){
	if( defined $args->{title} ){
	    next unless $template->title eq $args->{title};
	}
	if( defined $args->{fields} ){
	    foreach my $field (@{$args->{fields}}){
		if( defined $field->{key} ){
		    print Dumper $field->{key}; exit;
		    #print Dumper $val_a; exit;
			
		    next unless
		      defined $template->field( $field->{key} );
		    if( defined $field->{value} ){
			my $val_t = $template->field( $field->{key} );
			my $val_a = $field->{value};
			
			print Dumper $val_t;
			print Dumper $val_a; exit;
			
			next unless scalar(@$val_t) == scalar(@$val_a);
			
			for(my $i=0; $i<@$val_t; $i++){
			    next unless $val_t->[$i] eq $val_a->[$i];
			}
		    }
		}
	    }
	}
	push @matches, $template;
    }
    return @matches;
}

1;
