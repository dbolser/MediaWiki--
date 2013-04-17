#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use lib qw( local-lib/lib/perl5 );

use Test::More qw( no_plan );
#tests => 6;

our $debugging = 0;


## It's recommended that you run use_ok() inside a BEGIN block so its
## functions are exported at compile-time and prototypes are properly
## honored. http://search.cpan.org/~mschwern/Test-Simple/lib/Test/More.pm

BEGIN{
    use_ok( 'MediaWiki::Parser' );
    
    ## This lets us actually use the module below?
    require_ok( 'MediaWiki::Parser' );
}

## Get a parser
my $p = MediaWiki::Parser->new;

isa_ok( $p, 'MediaWiki::Parser' );



## Warm up by parsing some simple cases, and varous topological
## variants (i.e. cases that look different, but are the same.

my @t;

push @t, <<"EOP";
Some {{s}} wiki {{k|l|m=n|{{o|p}}|q={{r|s}}|{{t|u=v}}|w={{x|y=z=a}}}} text.
EOP

push @t, <<"EOP";
Some {{ s }} wiki {{ k | l | m = n | {{ o | p }} | q = {{ r | s }} | {{ t | u = v }} | w = {{ x | y = z = a }} }} text.
EOP

push @t, <<"EOP";
Some {{ S }} wiki {{ K | l | m = n | {{ O | p }} | q = {{ R | s }} | {{ T | u = v }} | w = {{ X | y = z = a }} }} text.
EOP

push @t, <<"EOP";
Some {{
s
}} wiki {{
k
|
l
|
m
=
n
|
{{o
|
p
}}
|
q
=
{{
r
|
s
}}
|
{{
t
|
u
=
v
}}
|
w
=
{{
x
|
y
=
z
=
a
}}
}} text.
EOP

push @t, <<"EOP";
Some {{
 s 


}} wiki {{   k 

|l    

 | 

m = 

n

|

    {{   o   
   |p
}}
| q                 = {{ r | s }} | {{
 t | u =   v }}
| w = {{ x|  y =
                 z=a

}}
}} text.
EOP



my $last_r;

for my $t (@t){

    ## Parse the page (string)
    ok( my $r = $p->from_string( $t ), 'parsed ok' );

    isa_ok( $r, 'MediaWiki::Page' );

    ## Test that we can round trip the page
    ok( $r->to_string eq $t, 'printed ok' );

    ## Check that each version has the same underlying structure as
    ## the last
    # if(defined($last_t)){
    #    ...
    # }

    ## hack, since we now moved to objects... all the rest of the loop
    ## is a hack...
    $r = $r->elements;

    ## The result should have 5 parts, alternating text and 'template'
    ok( @$r == 5, 'got 5 parts' );

    ## Test the (invariant) text parts
    ok( ! ref $r->[0] );
    ok( $r->[0] eq "Some " );

    ok( ! ref $r->[2] );
    ok( $r->[2] eq " wiki " );

    ok( ! ref $r->[4] );
    ok( $r->[4] eq " text.\n" );


    ## Test the template parts
    isa_ok( $r->[1], 'HASH' );
    isa_ok( $r->[1], 'MediaWiki::Template' );

    isa_ok( $r->[3], 'HASH' );
    isa_ok( $r->[3], 'MediaWiki::Template' );


    ## Deeper
    ok(     $r->[1]->title eq 'S' );
    isa_ok( $r->[1]->fields, 'ARRAY' );
    ok(   @{$r->[1]->fields} == 0 );

    ok(     $r->[3]->title eq 'K' );
    isa_ok( $r->[3]->fields, 'ARRAY' );
    ok(   @{$r->[3]->fields} == 6 );

    ## Each field is a simple 'key (key_string) = value' HASH
    foreach my $field ( @{$r->[3]->fields} ){
        isa_ok( $field, 'HASH' );
        ok( exists $field->{key} );
        ok( exists $field->{key_string} );
        ok( exists $field->{value} );
    }

    ## Test each (of the first three) field(s) explicitly...
    my $l = ${$r->[3]->fields}[0]; ## Key only
    my $m = ${$r->[3]->fields}[1]; ## Key = value
    my $o = ${$r->[3]->fields}[2]; ## Key = template

    #print Dumper $r; exit;

    ok(     $l->{key} eq '', 'key is blank');
    isa_ok( $l->{value}, 'ARRAY' );
    ok(   @{$l->{value}} == 1 );
    ok(     $l->{value}->[0] =~ /^\s*l\s*$/ );

    ok(     $m->{key} eq 'm' );
    isa_ok( $m->{value}, 'ARRAY' );
    ok(   @{$m->{value}} == 1 );
    ok(     $m->{value}->[0] =~ /^\s*n\s*$/ );

    ## The third field is a nested template...
    ok(     $o->{key} eq '', 'key is blank' );
    isa_ok( $o->{value}, 'ARRAY' );

    ## The template has up to three parts, the string before, the
    ## template object, and the string after... but either the before
    ## or after string can be null....

    ## Grab the template part
    my $p = (grep( ref($_) eq 'MediaWiki::Template', @{$o->{value}} ))[0];

    isa_ok( $p, 'HASH' );
    isa_ok( $p, 'MediaWiki::Template' );

    ## We stop here before we get too recursive...

    # ## BUT WHY DOES THIS FAIL? (key/value are undef)
    # print Dumper $p;
    # print Dumper $p->{key};
    # print Dumper $p->{value};
}



## Try some more complex examples (using the object interfacd now,
## insead of the 'elements' hack above).

## This is an invalid template! (Titles may not span multiple
## lines)... 'Unfortunately' we handle it fine (should be considered
## as a string, but treating it as a valid template isn't so bad I
## guess?)

my $t = "{{ here is  a 
 template | and here is a  value | this key = x | but
this key = y ||||| and they ain't the same
| job = 1
| job = 2
| job = 3
}}";

ok( my $r = $p->from_string( $t ), 'parsed ok' );

isa_ok( $r, 'MediaWiki::Page' );

ok( $r->to_string eq $t, 'printed ok' );

## The result should have 1 part, a 'MW:Template'
ok( @{$r->elements} == 1, 'got 1 part' );

## TODO: Use object interface here!
my $e1 = ${$r->elements}[0];

isa_ok( $e1, 'MediaWiki::Template' );

ok( $e1->title eq 'Here is a template' );



## Another test...
$t = "{{Cell line
|id=1146
|name=EHEB
|laboratory code=DSMZ
|catalog code=ACC 67
|origin=human
|tissue type=peripheral blood
|tumor type=leukemia, chronic, B cell
|export flag=Y
}}";

ok( $r = $p->from_string( $t ), 'parsed ok' );

isa_ok( $r, 'MediaWiki::Page' );

ok( $r->to_string eq $t, 'printed ok' );

## The result should have 1 part, a 'MW:Template'
ok( @{$r->elements} == 1, 'got 1 part' );

## TODO: Use object interface here!
$e1 = ${$r->elements}[0];

isa_ok( $e1, 'MediaWiki::Template' );

ok( $e1->title eq 'Cell line' );



## OK, move on to some real examples

## Check our 'test templates' file exists
my $d = `dirname $0`; chomp($d);
my $f = "$d/templates.wxt";

ok( -e $f );


## Parse the file

ok( $r = $p->from_file( $f ) );

isa_ok( $r, 'MediaWiki::Page' );

__END__

# print "got ", scalar @$r, " pieces\n";

# for(@$r){
#     if(ref($_)){
# 	if(ref($_) eq 'HASH'){
# 	    ## Every template has a title;
# 	    ok( length $_->{'title'} > 0 );
# 	    print "\t", $_->{'title'}, "\n";
# 	}
# 	else{ ok( 0 ) }
#     }
#     else{
# 	print "\tlen:", length $_, "\n";
#     }
# }


# #print Dumper $r->[-5];
