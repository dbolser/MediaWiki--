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
representation of the templates (fields and values) and other
'objects' within the page.

The main reason for using Parser::MGC is so we can handle recursive
templates, i.e. templates who are passed templates. One advantage is
that it should allow a modular, generic parser to be built, until POM
or Lua comes along.

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
contexts...

Actually I just need to work on the template 'matching' code so that
'x y' matches ' x y ' when matching template names, etc. The advantage
of resetting this is that we can now 'round-trip' pages. i.e. {{ My
template | here = x }} doesn't get arbitrarily re-written as:

{{My template
 |here=x
}}

or whatever convention we arbitrarily decide, which would create fake
diffs between page edits that we don't want.

= item * ident

Extend the notion of an identifier to cover the values allowed by
MediaWiki, specifically, "Other characters may be ASCII letters,
digits, hyphen, comma, period, apostrophe, parentheses and colon. No
other ASCII characters are allowed, and will be deleted if found (they
will probably cause a browser to misinterpret the URL)" -
L<http://www.mediawiki.org/wiki/Manual:Title.php#Article_name>

=cut

use constant
    pattern_ws => qr{};

use constant
    pattern_ident => qr{[[:alnum:]/_\-,.'():]+};



=head1 METHODS

See L<Parser::MGC>.

TODO: Allow template keys with 'empty' values, e.g. {{x|y=}}

=cut

sub parse {
    my $self = shift;
    $self->debug_parser('start parse');
    
    ## A wiki page is defined a 'sequence of' the following 'options'
    ## (element types)
    my $sequence =
        $self->sequence_of( sub {
            $self->
                any_of(
                    
                    ## Currenlty, anything that isn't a template
                    sub { $self->parse_wikitext },
                    
                    ## Templates
                    sub { $self->scope_of( '{{', \&parse_template, '}}' ) },
                    
                    ## Other element types...
                );
        });
    
    ## Return a 'page' composed of these elements
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
    my $title_string = $self->parse_title;
    
    ## The fields of the template, the optional
    ## '[key =] value' parts, '|' separated
    
    ## Consume the first pipe (if any)
    $self->maybe( sub { $self->expect( '|' ) } );
    
    my $fields = $self->
        list_of( '|', sub{ $self->parse_field } );
    
    return $self->
        make_template(
            title_string => $title_string,
            fields       => $fields,
        );
}

sub parse_title {
    my $self = shift;
    $self->debug_parser('parse_title');
    
    $self->parse_toke;
}

sub parse_field {
    my $self = shift;
    $self->debug_parser('parse_field');
    
    ## Try to find a "key = ..."
    my $key_string = $self->
        maybe( sub { my $key = $self->parse_toke; 
                     ## If we dont find this, we're not a key, were a value!
                     $self->expect('=');
                     return $key;
               }
        );
    
    my $value = $self->parse_value;
    
    return {
        key_string => $key_string || '',
        value      => $value,
    };
}

sub parse_value {
    my $self = shift;
    $self->debug_parser('parse_value');
    
    $self->
        sequence_of( sub { $self->any_of(
                               ## A nested template?
                               sub { $self->scope_of( '{{', \&parse_template, '}}' ) },
                               
                               ## Anything else
                               sub { $self->parse_toke },
                               
                               )}
        );
}

sub parse_toke {
    my $self = shift;
    $self->debug_parser('parse_toke');

    my $toke = $self->
        ## BUG: The = here breaks when they occur in values! Try via
        #substring_before( qr/}}|{{|\||=/ );
        substring_before( qr/}}|{{|\|/ );

    ## This would keep returning '' until the end of time, so...
    length $toke or $self->fail;
    
    return $toke;
}

sub parse_value_toke {
    my $self = shift;
    $self->debug_parser('parse_toke');

    my $toke = $self->
        substring_before( qr/}}|{{|\||=/ );

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



## See 'Tangence::Compiler::Parser' as an example of what we're doing
## below

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
