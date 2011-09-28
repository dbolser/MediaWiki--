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
    my $self = shift;
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



=head1 OTHERS...

=cut

=head2 undef = $page->add( $element, $index )

Adds the given page element the page at the given index (or at the
end).

=cut

sub add {
    my $self = shift;
    my $element = shift;
    my $index = shift || @{$self->{elements}};
    
    splice( @{ $self->{elements} }, $index, 0, $element,
	    splice( @{ $self->{elements} }, $index ) );
    return undef;
}

=cut

=head2 $string = $page->to_string

Makes a string from a Page object 

=cut

sub to_string {
    my $self = shift;
    my $elements = $self->elements;
    my $string;
    
    for (@$elements){
	if(0){}
	elsif( ref eq 'MediaWiki::Template' ){
	    $string .= $_->to_string;
	}
	elsif( ref eq '' ){
	    $string .= $_;
	}
    }
    return $string;
}






=head1 HORRIBLE

=cut

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

or
 { fields => [ value => [ 'x' ] ] }


When unspecified, the title, fields or values match all templates (in
theory...).

TODO: Investigate DOM and XPath?

=cut

sub template_match{
    my $self = shift;
    my $args = shift;
    my @matches;
    
  T:foreach my $template (@{$self->templates}){
      
      ## First, try to match the title
      
      if( defined $args->{title} ){
	  next T unless
	      $template->title eq $args->{title};
      }
      
      unless ( defined $args->{fields} ){
	  ## With no fields to consider, we have sucessfully matched
	  ## this template on its title...
	  push @matches, $template;
	  next T;
      }
      
      ## Next, try to match the fields
      
    F:foreach my $arg_field (@{$args->{fields}}){
	
	## First, try to match the key...
	## We call 'next T' as soon as we fail
	
	if( defined $arg_field->{key} ){
	    next T unless
		## Look up this key in the template
		defined $template->field( $arg_field->{key} );
	}
	
	## Next, we try to match the value...
	
	## Note, we either use the value for the corresponding key,
	## (and call 'next T' as soon as we fail), or *all* values in
	## the template, if no key is given.
	
	if( defined $arg_field->{value} ){
	    my $arg_val = $arg_field->{value};
	    
	    if( defined $arg_field->{key} ){
		my $tem_val = $template->field( $arg_field->{key} );
		
		next T unless
		    scalar(@$arg_val) == scalar(@$tem_val);
		
		for(my $i=0; $i<@$arg_val; $i++){
		    next T unless
			    $tem_val->[$i] eq $arg_val->[$i];
		}
	    }
	    else{
		my $tem_fields = $template->fields;
		
		for my $tem_field (@$tem_fields){
		    my $tem_val = $tem_field->{value};
		    
		    next unless scalar(@$arg_val) == scalar(@$tem_val);
		    
		    for(my $i=0; $i<@$arg_val; $i++){
			next unless
			    $tem_val->[$i] eq $arg_val->[$i];
		    }
		    
		    ## If we got here, this is a match for this arg,
		    ## we can stop searching template fields and try
		    ## the next arg field
		    next F;
		}
		## If we got here, there was no match yet
		next T;
	    }
	}
	## If we got here, the key matched and there was no value, or
	## the key and the value matched... now we just need to do
	## this F times...
    }#F
      push @matches, $template;
      next T;
  }#T
    return @matches ? \@matches : undef ;
}

1;
