#!/usr/bin/perl -w

use strict;
use Data::Dumper;

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

push @t, <<"EOX";
Some {{s}} wiki {{k|l|m=n|{{o|p}}|q={{r|s}}|{{t|u=v}}|w={{x|y=z}}}} text.
EOX

push @t, <<"EOX";
Some {{ s }} wiki {{ k | l | m = n | {{ o | p }} | q = {{ r | s }} | {{ t | u = v }} | w = {{ x | y = z }} }} text.
EOX

push @t, <<"EOX";
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
| w = {{ x|  y =z

}}
}} text.
EOX

my $last_r;

for my $t (@t){
    
    ok( my $r = $p->from_string( $t ), 'parsed ok' );
    
    print Dumper $r
      if $debugging > 0;
    
    #if(defined($last_r)){
    #   is_deeply( $r, $last_r );
    #}
    
    isa_ok( $r, 'MediaWiki::Page' );
    
    ## hack, since we now moved to objects
    $r = $r->elements;
    
    ## The result should have 5 parts, alternating text and 'template'
    ok( @$r == 5, 'got 5 parts' );
    ok( $r->[0] eq "Some " );
    ok( $r->[2] eq " wiki " );
    ok( $r->[4] eq " text.\n" );
    
    isa_ok( $r->[1], 'HASH' );
    isa_ok( $r->[3], 'HASH' );
    
    ok(     $r->[1]->{title} eq 's' );
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
