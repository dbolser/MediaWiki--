#!/usr/bin/perl -w

use strict;

use Data::Dumper;

use lib qw( local-lib/lib/perl5 );
use MediaWiki::Parser;

my $t = "Here begins our page!\n\n\n";

$t .= qq(

{{cite journal | author = White MB, Shen AL, Word CJ, Tucker PW, Blattner FR | title = Human immunoglobulin D: genomic sequence of the delta heavy chain | journal = Science | volume = 228 | issue = 4700 | pages = 733–7 | year = 1985 | month = May | pmid = 3922054 | pmc =  | doi =10.1126/science.3922054  }}</ref><ref name="entrez">{{cite web | title = Entrez Gene: IGHD immunoglobulin heavy constant delta| url = http://www.ncbi.nlm.nih.gov/sites/entrez?Db=gene&Cmd=ShowDetailView&TermToSearch=3495| accessdate = }}


);


$t .= " {{ T:b_la/r/p 0-89 m,y. (t)    her'e }}\n\n";

$t .= "{{Hello|anon|yp}}";

$t .= "{{Hello|

wibble 

pibble

=

bibble}}";

$t .= "{{Hello|anon|yp}}\n\n";

$t .= "{{Hello wor|my key now = * ting [http://ubers]
|yp=xy|||
krimple

poing

= 

wimple

|

x

}}
";

$t .= "{{t |   |   |   |   |   |g  }}";
$t .= "{{t |b  |c  |d  |e  |f  |g  }}";
$t .= "{{t |b=1|c=2|d=3|e=4|f=5|g=6}}";
$t .= "{{ t | b = 1 | c = 2 | d = 3 | e = 4 | f = 5 | g = 6 }}";

## Nice demo
$t .=
    "{{t|p|q=r|{{s|t}}|u={{v|w}}|{{x|y=z}}|a={{b|c=d}}}}\n\n";

## Nice demo
$t .=
    ' {{ t | p | q = r | {{ s | t }} | u = {{ v | w }} | {{ x | y = z }} | a = {{ b | c = d }} }} ';

## Nice demo
$t .=
    '{{s}} {{ s }} {{s }} {{ s}}
{{t
 | p
 | q = r
 | {{ s
    | t
   }}
 | u = {{ v
        | w }}
 | {{ x
    | y = z
   }}
 | a = {{ b
        | c = d
       }}
}}

';

## Value mixes stings and templates
$t .=
    "{{ t | p = One {{sny}} day {{P|Rose}} and {{P|x=Jim}} }}\n\n\n";

## 
print $t;



my $parser = MediaWiki::Parser->new;

my $page =
    $parser->from_string( $t );

print Dumper $page;

#exit;

print "The parsed page is '$page'\n";

print "There are ", scalar( @{$page->templates} ), " templates in it.\n\n";

#exit;

# for (@{$page->templates}){
#     print $_, "\n";
#     print $_->title, "\n";
# }

my $x = $page->to_string;
#print $t;
#print $x;

print "Neeeeee!\n" if $t ne $x;

print "we successfuly round-tripped our page\n"
    if $t eq $x;

