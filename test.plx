#!/usr/bin/perl -w

use strict;

use Data::Dumper;

#use MediaWiki::Template;
use MediaWiki::Parser;

# my $t1 = MediaWiki::Template->
#     new([ 'culture conditions',
# 	  [
# 	   [ 'id', 'id1' ],
# 	   [ 'code', 'code1' ],
# 	   [ 'name', 'name1' ],
# 	#   [ 'blibble', [ 'x', 
# 	#		  [[ 'j', 'jump' ]]
# 	#		]
# 	#   ],
# 	  ],
# 	 ]
# 	);

# print Dumper $t1;


# __END__
# my $t2 = MediaWiki::Template->
#   new({ name => 'cult',
# 	fields => {'d' => 'id2',
# 		   'na' => 'n2',
# 		  }
#       });

# my $t3 = MediaWiki::Template->
#   new({ name => 'cultureculture conditions',
# 	fields => {'idxxx' => '99',
# 		   'coddddde' => 'wibble',
# 		  }
#       });

# my $t1_text = $t1->to_text;
# my $t2_text = $t2->to_text;
# my $t3_text = $t3->to_text;


my $t;
#  "yonkers 
#  $t1_text. "\n were \n weisbe \n".
#  $t2_text. "\n were \n weisbe \n".
#  $t3_text. "x boing ping \n

#$t .= " txt
#
#moar  {{
# blarp 
#  }} web de beb 
#";

#$t .= "{{Template:b_la/r/p}}";

#$t .= "{{Hello|anon|yp}}";

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

#$t .= "{{t |b  |c  |d  |e  |f  |g  }}";
#$t .= "{{t|b=1|c=2|d=3|e=4|f=5|g=6}}";

## Nice demo
$t .=
    "{{s}}{{t|p|q=r|{{s|t}}|u={{v|w}}|{{x|y=z}}|a={{b|c=d}}}}";

## Value mixes stings and templates
#$t .=
#    "{{ t | p = One {{sny}} day {{P|Rose}} and {{P|x=Jim}} }}";


#print $t;



my $parser = MediaWiki::Parser->new;

my $page =
    $parser->from_string( $t );

print Dumper $page;

print $page, "\n";

print scalar $page->templates, "\n";

for (@{$page->templates}){
    print $_, "\n";
    print $_->title, "\n";
}

__END__



#my $tx = MediaWiki::Template->
#  new_from_text( $t );


my @tx;

while($t =~ /{{.*?}}/gs){
  my $beg = $-[0];
  my $end = $+[0];
  my $len = $end - $beg;
  
  #print "got one from $beg to $end ($len)\n";
  
  push @tx, \substr($t, $beg, $len);
}


print "'", ${$tx[1]}, "'", "\n";

${$tx[1]} = 'nooo';

print "'", ${$tx[1]}, "'", "\n";

#print $t;

exit;


__END__

my $k = ${$tx->[2]};

my $j = \substr($k, 10,20);

$$j= 'jesus is lord';

print "'", $k, "'", "\n";

$tx->[2] = $k;

print $t;


