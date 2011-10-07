package MediaWiki::Parser;

use strict;
use warnings;

use base qw( Parser::MGC );

our $debug = 0;



=head1 NAME

C<MediaWiki::Parser> - A MediaWiki page (mostly template) parser

=head1 SYNOPSIS

I'm really not good with POD... Improviements welcome!

=head1 DESCRIPTION

This is a L<Parser::MGC> based MediaWiki page (mostly template) parser
to pull appart a MediaWiki formatted wiki text and build a Perl object
representation of the templates, fields and values within the page.

The main reason for using Parser::MGC is so we can handle recursive
templates, i.e. templates who are passed templates.

=cut



=head1 CONSTRUCTOR

=head2 $parser = MediaWiki::Parser->new( )

This method is inherited from L<Parser::MGC>.

=cut



=head1 PATTERNS

=over 4

=item * ws

I want to reset this, but it screws with finding template identifiers
(the name of '{{x y}}' is identical to '{{ x  y }}' in MW), and I
can't work out how to make all whitespace 'work' as expected in all
contexts.

= item * ident

Extend the notion of an identifier to cover the values allowed by
MediaWiki, specifically "Other characters may be ASCII letters,
digits, hyphen, comma, period, apostrophe, parentheses and colon. No
other ASCII characters are allowed, and will be deleted if found (they
will probably cause a browser to misinterpret the URL)" -
L<http://www.mediawiki.org/wiki/Manual:Title.php#Article_name>

=cut

#use constant
#    pattern_ws => qr{};

use constant
    pattern_ident => qr{[[:alnum:]/_\-,.'():]+};



=head1 METHODS

=cut

sub parse {
    my $self = shift;
    $self->debug_parser('start parse');
    
    ## A wiki page is defined a 'sequence of' the following options
    my $sequence =
        $self->sequence_of( sub {
            $self->
                any_of(
		    
		    ## Currently anything else is just 'wikitext'
                    sub { $self->parse_wikitext },
		    
                    ## Templates
                    sub { $self->scope_of( '{{', \&parse_template, '}}' ) },
                );
        });
    
    return $self->
        make_page(
            elements => $sequence,
        );
}

sub parse_wikitext {
    my $self = shift;
    $self->debug_parser('parse_wikitext');
    
    ## Everything from where we are to the next template or EOS
    my $text =
        $self->substring_before( '{{' );
    
    ## This would keep returning '' until the end of time, so...
    length $text or $self->fail;
    
    return $text;
}

sub parse_template {
    my $self = shift;
    $self->debug_parser('parse_template');
    
    # The title of the template
    my $title = $self->parse_title;
    
    ## The fields of the template, the optional
    ## '[key =] value' parts, '|' separated
    
    $self->maybe( sub { $self->expect( '|' ) } );
    
    my $fields = $self->
        list_of( '|', sub{ $self->parse_field } );
    
    return $self->
        make_template(
            title  => $title,
            fields => $fields,
        );
}

sub parse_title {
    my $self = shift;
    $self->debug_parser('parse_title');
    
    my $title = $self->
        sequence_of( sub { $self->token_ident } );
    
    return join( ' ', @$title );
}

sub parse_field {
    my $self = shift;
    $self->debug_parser('parse_field');
    
    my $key = $self->
	maybe( sub {
	    ( $self->parse_title,
	      $self->expect( '=' ) )[0];
	       });
    
    my $val = $self->parse_value;
    
    return {
	key   => $key || '',
	value => $val
    };
}

sub parse_value {
    my $self = shift;
    $self->debug_parser('parse_value');
    
    $self->
        sequence_of( sub {
            $self->any_of(
                
                ## A nested template?
                sub { $self->scope_of( '{{', \&parse_template, '}}' ) },
                
                ## Anything else
                sub { $self->parse_toke },
                
                )
        });
}

sub parse_toke {
    my $self = shift;
    $self->debug_parser('parse_toke');
    
    my $toke = $self->
        substring_before( qr/}}|{{|\|/ );
    
    ## This would keep returning '' until the end of time, so...
    length $toke or $self->fail;
    
    return $toke;
}

sub debug_parser {
    my $self = shift;
    my $subr = shift || 'unknown';
    
    my ( $lineno, $col, $text ) = $self->where;
    
    print join("\t", $subr, $lineno, $col, "'". $text. "'"), "\n"
        if $debug > 0;
}



## See Tangence::Compiler::Parser

=head2 $page = $parser->make_page( %args )

Return a new instance of L<MediaWiki::Page>

=cut

sub make_page
{
   shift;
   require MediaWiki::Page;
   return MediaWiki::Page->new( @_ );
}


=head2 $template = $parser->make_template( %args )

Return a new instance of L<MediaWiki::Template>

=cut

sub make_template
{
   shift;
   require MediaWiki::Template;
   return MediaWiki::Template->new( @_ );
}



## Other page elements can be parsed and objectified similarly, for
## example, sections, lists, etc.

1;
