#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use Test::More qw( no_plan );

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

my $t = "Some {{s}} wiki
    {{k|l|m=n|{{o|p}}|q={{r|s}}|{{t|u=v}}|w={{x|y=z}}}} text.";

ok( my $r = $p->from_string( $t ), 'parsed ok' );

print Dumper $r
    if $debugging > 0;

isa_ok( $r, 'MediaWiki::Page' );
    
## The result should have 5 parts, alternating text and 'template'
ok( @{$r->elements} == 5, 'got 5 parts' );

## Grab the 2 templates
ok( my @ts = @{$r->templates}, 'got templates' );

ok( @ts == 2, 'got two templates' );

for my $t ( @ts ){
    isa_ok( $t, 'MediaWiki::Template' );
}

## Check we got the second template by title
ok( $ts[1]->title eq 'k' );

## Alternative method to grab the second template...
my $t2 = $r->template( 'k' );

is_deeply( $ts[1], $t2, 'same template' );


## Grab the 6 fields of the second template
ok( my @fs = @{$t2->fields} );

ok( @fs == 6, 'got six fields' );

for my $f ( @fs ){
    isa_ok( $f, 'HASH' ); # Fields arn't fancy
    ok( exists $f->{key}, "has a 'key' slot" );
    ok( !ref   $f->{key}, 'isa SCALAR' );
    ok( exists $f->{value}, "has a 'value' slot" );
    isa_ok(    $f->{value}, 'ARRAY' );
}

## Check we got the 'm' field by key
ok( $fs[1]->{key} eq 'm' );

## Alternative method to grab the (value of the) 'm' field...
my $fm = $t2->field( 'm' );

is_deeply( $fs[1]->{value}, $fm, 'same field (value)' );





## Match!
print Dumper
    $r->template_match({title  => 'k',
			fields => [ { key   => 'l', 
				      value => [ 'x' ],
				    } ]
		       });


__END__


## Try some more complex examples

## THIS IS AN INVALID TEMPLATE! (titles may not span multiple lines)
my $t = "{{ here is  a 
 template | and here is a  value | this key = x | but
this key = y ||||| and they ain't the same
| job = 1
| job = 2
| job = 3
}}";

ok( my $r = $p->from_string( $t ), 'parsed ok' );

print Dumper $r
  if $debugging > 0;

isa_ok( $r, 'MediaWiki::Page' );

## The result should have 1 part, a 'MW:Template'
ok( @{$r->elements} == 1, 'got 1 part' );

my $e1 = ${$r->elements}[0];

isa_ok( $e1, 'MediaWiki::Template' );

ok( $e1->title eq 'here is a template' );





## Seems to fail!
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

print Dumper $r
  if $debugging > 0;

isa_ok( $r, 'MediaWiki::Page' );

## The result should have 1 part, a 'MW:Template'
ok( @{$r->elements} == 1, 'got 1 part' );

my $e1 = ${$r->elements}[0];

isa_ok( $e1, 'MediaWiki::Template' );

ok( $e1->title eq 'Cell line' );




__END__
    isa_ok( $r->[1]->{fields}, 'ARRAY' );
    ok(   @{$r->[1]->{fields}} == 0 );

    ok(     $r->[3]->{title} eq 'k' );
    isa_ok( $r->[3]->{fields}, 'ARRAY' );
    ok(   @{$r->[3]->{fields}} == 6 );
    
    ok(!exists $r->[3]->{fields}->[0]->{key} );
    ok( exists $r->[3]->{fields}->[0]->{value} );
    isa_ok(    $r->[3]->{fields}->[0]->{value}, 'ARRAY' );
    ok(      @{$r->[3]->{fields}->[0]->{value}} == 1 );
    ok(        $r->[3]->{fields}->[0]->{value}->[0] =~ /^\s*l\s*$/ );

    ok( exists $r->[3]->{fields}->[1]->{key} );
    ok( exists $r->[3]->{fields}->[1]->{value} );
    ok(        $r->[3]->{fields}->[1]->{key} eq 'm' );
    isa_ok(    $r->[3]->{fields}->[1]->{value}, 'ARRAY' );
    ok(      @{$r->[3]->{fields}->[1]->{value}} == 1 );
    ok(        $r->[3]->{fields}->[1]->{value}->[0] =~ /^\s*n\s*$/ );

    ## Enough already!
    ok( exists $r->[3]->{fields}->[5]->{key} );
    ok( exists $r->[3]->{fields}->[5]->{value} );
    ok(        $r->[3]->{fields}->[5]->{key} eq 'w' );
    isa_ok(    $r->[3]->{fields}->[5]->{value}, 'ARRAY' );
    ok(      @{$r->[3]->{fields}->[5]->{value}} == 1 );
    my $x =    $r->[3]->{fields}->[5]->{value}->[0];
    
    isa_ok( $x, 'HASH' );
    
    ok(     $x->{title} eq 'x' );
    isa_ok( $x->{fields}, 'ARRAY' );
    ok(   @{$x->{fields}} == 1 );
    
    ok( exists $x->{fields}->[0]->{key} );
    ok( exists $x->{fields}->[0]->{value} );
    ok(        $x->{fields}->[0]->{key} eq 'y' );
    isa_ok(    $x->{fields}->[0]->{value}, 'ARRAY' );
    ok(      @{$x->{fields}->[0]->{value}} == 1 );
    ok(        $x->{fields}->[0]->{value}->[0] =~ /^\s*z\s*$/ );

    $last_r = $r;
}










## OK, move on to some real examples

## Check our 'test templates' file exists
my $d = `dirname $0`; chomp($d);
my $f = "$d/templates.wxt";

ok( -e $f );


## Parse the file

ok( my $r = $p->from_file( $f ) );

isa_ok( $r, 'MediaWiki::Page' );



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
