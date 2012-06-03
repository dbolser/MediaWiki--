#!/usr/bin/perl -w

use strict;

use Data::Dumper;

use lib qw( local-lib/lib/perl5 );
use MediaWiki::Parser;

my $t;

$t .= " {{ T:b_la/r/p 0-89 m,y. (t)    her'e }}\n\n";

$t .= "{{Hello|anon|yp}}

the end

";

# $t .= "{{Hello wor|my key now = * ting [http://ubers]
# |yp=xy|||
# krimple

# poing

# = 

# wimple

# |

# x

# }}
# ";

#$t .= "{{t |   |   |   |   |   |g  }}";
#$t .= "{{t |b  |c  |d  |e  |f  |g  }}";
#$t .= "{{t |b=1|c=2|d=3|e=4|f=5|g=6}}";

## Nice demo
$t .=
    '{{s}}{{t|p|q=r|{{s|t}}|u={{v|w}}|{{x|y=z}}|a={{b|c=d}}}}';

## Nice demo
$t .=
    ' {{s}} {{ t | p | q = r | {{ s | t }} | u = {{ v | w }} | {{ x | y = z }} | a = {{ b | c = d }} }} ';

## Value mixes stings and templates
#$t .=
#    "{{ t | p = One {{sny}} day {{P|Rose}} and {{P|x=Jim}} }}";

#print $t;



my $parser = MediaWiki::Parser->new;

my $page =
    $parser->from_string( $t );

#print Dumper $page;

#exit;

print $page, "\n";

print scalar( $page->templates ), "\n\n";

for (@{$page->templates}){
    print $_, "\n";
    print $_->title, "\n";
}
