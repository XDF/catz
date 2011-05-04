#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#  

package Catz::Model::Vector;

use strict;
use warnings;

use feature qw( switch );

use parent 'Exporter';
our @EXPORT = qw( 
 vector_bit vector_array vector_array_rand vector_first 
 vector_pager vector_pointer vector_count vector_info
);

use Bit::Vector;
use List::Util qw ( shuffle );
use POSIX qw( floor ceil );

use Catz::Data::Cache;
use Catz::Data::DB;
use Catz::Util::Number qw( fullnum33 );

sub bsearch {

  # binary search aka half-interval search
  # http://en.wikipedia.org/wiki/Binary_search_algorithm
 
  # this Perl code is modified from
  # http://staff.washington.edu/jon/dsa-perl/dsa-perl.html
  # http://staff.washington.edu/jon/dsa-perl/bsearch-copy
    
  my ( $a, $x ) = @_; # search for x in arrayref a
    
  my ( $l, $u ) = ( 0, scalar(@$a)-1 ); # search interval
 
  my $i; # index of probe
      
  while ($l <= $u) {
  
   $i = int(($l + $u)/2);
    	 
   if ($a->[$i] > $x) { $u = $i - 1; } 
   
    elsif ($a->[$i] < $x) { $l = $i + 1; } 
    
    else { return $i; } # found
 
  }
  
   # not found indicated as -1
   # this can never happen if a match is found since matches
   # are array indexes thus 0 or positive
  return -1;
  
 
 }

sub vectorize {
 
 my ( $db, $lang, $pri, $sec ) = @_;
 
 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used 
 my $maxx = $db->one( "select max(x) from photo" ) + 1;
 
 # create a bit vector of x indexes based on pri + sec pair
 my $res;
 
 # first we ask if this data comes from album, exif or position
 my $orig = $db->one (
  'select origin from pri where pri=?', 
  $pri ne 'has' ? $pri : $sec 
 );
  
 $orig or return Bit::Vector->new( $maxx ); # unknown pri -> return empty vector
 
 $orig eq 'exif' and $orig .= 'f'; # we use exif view INEXIFF, not INEXIF
  
 if ( $pri eq 'has' ) {
    
  $res = $db->col( "select x from photo natural join in$orig where sid in (select sid from sec natural join pri where pri=? )", $sec )
            
 } else { # no 'has'
 
  if ( ( index ( $sec, '%' ) > -1 ) or ( index ( $sec, '_' ) > -1 ) ) {
  
   # pattern matching

   $res = $db->col ( "select x from photo natural join in$orig where sid in ( select sid from sec_$lang natural join pri where pri=? and sec like ? )", $pri, $sec )
       
  } else {

   # exact
 
   $res = $db->col ( "select x from photo natural join in$orig where sid in ( select sid from sec_$lang natural join pri where pri=? and sec=? )", $pri, $sec )
 
  }  

 }
       
 my $bvec = Bit::Vector->new( $maxx );
   
 $bvec->Index_List_Store ( @$res ); # store the x indexes as bits
  
 return $bvec;  
  
}   

sub vector_bit { # fetch a bit vector for a set of arguments

 my $res;

 my ( $db, $lang, @args ) = @_;
 
 my $maxx = $db->one( "select max(x) from photo" ) + 1;
     
 # OR base vector is a completely empty vector
 my $ors =  Bit::Vector->new( $maxx ); 

 # AND base vector is a completely filled vector 
 my $ands = Bit::Vector->new( $maxx );
 $ands->Fill;
 $ands->Bit_Off(0); # 0th bit is unused as xs start from 1
  
 my $hasor = 0; # flag to detect if any ors were present
 
 for ( my $i = 0; $i <= $#args; $i = $i + 2 ) {
  
  $args[$i+1] =~ /^(\+|\-)(.*)$/;
    
  my $oper = $1 // '0'; # the default operand is 0 = or
  my $rest = $2 // $args[$i+1]; 
  
  $rest =~ s/\?/\_/g; # user interface ? -> database interface _
  $rest =~ s/\*/\%/g; # user interface * -> database interface %
  
  #warn $rest;
            
  my $bvec = vectorize( $db, $lang, $args[$i], $rest );
                
  given ( $oper ) {
  
   when ( '+' ) { $ands->And( $ands, $bvec) ; }
      
   when ( '0' ) { $hasor++; $ors->Or( $ors, $bvec ); }
   
   when ( '-' ) { $ands->AndNot( $ands, $bvec ); }
   
   default { die "unknow bit vector operation '$oper'"; }
  
  }
  
 }
 
 # if ors vere present then and them with ands
 $hasor and $ands->And( $ands, $ors );
 
 return $ands;
       
}

sub vector_array { # get vector as array of indexes
   
 my $bvec = vector_bit( @_ );
 
 my @arr = $bvec->Index_List_Read;
   
 return \@arr;

}

sub vector_array_rand {

 my $arr = vector_array ( @_ );
 
 my @rand = shuffle ( @{ $arr } );
 
 return \@rand;
  
}

sub vector_pager {

 my $res;

 my ( $db, $lang, $x, $perpage, @args ) = @_;
     
 my $svec = vector_array( $db, $lang, @args ); # get an array of xs
   
 my $xfrom = bsearch( $svec, $x ); # search for the x
 
 $xfrom == -1 and return 0; # total = 0 = nothing found

 my $total = scalar @{ $svec };

 my $pages = ceil ( $total / $perpage );

 my $xlast = $total - 1;

 my $page = floor ( $xfrom / $perpage ) + 1;
 
 # silently roll to the first photo on this page if not yet there
 $xfrom = ( ( $page - 1 ) * $perpage );  
  
 my $xto = $xfrom + $perpage - 1;
 
 $xto > $xlast and $xto = $xlast;

 my $from = $xfrom + 1; 
 
 my $to = $xto + 1;
 
 my @root = map { $svec->[$_*$perpage] } ( 0 .. $pages - 1  );
 
 #warn ( scalar @root );
 
 my @pin = map { fullnum33 ( $_->[0], $_->[1] ) }  
  @{ $db->all(
  qq{select s,n from album natural join photo where x in (} . ( join ',', @root ) . ') order by x' 
 ) };
         
 my @xs = map { $svec->[$_] } ( $xfrom .. $xto );
   
 return [ ( $total, $page, $pages, $from, $to , \@pin, \@xs ) ];
      
}

sub vector_pointer {

 my $res;

 my ( $db, $lang, $x, @args ) = @_;
     
 my $svec = vector_array ( $db, $lang, @args ); # get an array of xs
    
 my $idx = bsearch( $svec, $x ); # search for the x
 
  
 $idx == -1 and return 0; # total = 0 = nothing found
 
 my $total = scalar @{ $svec };
 
 my @pin;
 my $sql = 'select s,n from album natural join photo where x=?'; 
 
 # first
 push @pin, fullnum33 ( @{ $db->row( 
  $sql,
  $svec->[0]
 )});
 
 # previous
 push @pin, fullnum33 ( @{ $db->row( 
  $sql,
  $svec->[ $idx > 0 ? $idx - 1  : 0 ]
 )});
 
 # next
 push @pin, fullnum33 ( @{ $db->row( 
  $sql,
  $svec->[ $idx < ( $total - 1 ) ? $idx+1 : ( $total - 1 ) ]
 )});
 
 # last
 push @pin, fullnum33 ( @{ $db->row( 
  $sql,
  $svec->[$total-1]
 )});
   
 return [ ( $total, $idx + 1, \@pin ) ];
    
}

sub vector_first {

 # return the index of the first photo in the vector

 my ( $db, $lang, @args ) = @_;

 my $svec = vector_array ( $db, $lang, @args );
   
 scalar @{ $svec } == 0 and return undef;
  
 return $svec->[0];
  
}

sub vector_count {

 my $res;
   
 my $bvec = vector_bit( @_ );
  
 my $total = $bvec->Norm;
  
 return $total; 
 
}

1;
