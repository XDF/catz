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

use 5.10.0;
use strict;
use warnings;

use parent 'Catz::Model::Common';

use Bit::Vector;
use List::Util qw ( shuffle );
use POSIX qw( floor ceil );

sub bsearch {

  # binary search aka half-interval search
  # http://en.wikipedia.org/wiki/Binary_search_algorithm
 
  # this code is a modified version of
  # http://staff.washington.edu/jon/dsa-perl/dsa-perl.html
  # http://staff.washington.edu/jon/dsa-perl/bsearch-copy
    
  my ( $a, $x ) = @_; # search for x in arrayref a
    
  my ( $l, $u ) = ( 0, scalar(@$a)-1 ); # search interval $l - $u
 
  my $i; # index of probe
      
  while ($l <= $u) {
  
   $i = int(($l + $u)/2);
    	 
   if ($a->[$i] > $x) { $u = $i - 1; } 
   
    elsif ($a->[$i] < $x) { $l = $i + 1; } 
    
    else { return $i; } # found
 
  }
  
   # not found indicated as -1
   # -1 is never found in search since array indexes are always > -1 

  return -1;
  
 }

sub _vectorize {
 
 my ( $self, $pri, $sec ) = @_; my $lang = $self->{lang};
 
 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used 
 my $size = $self->maxx  + 1;
 
 my $res;
 
 # create a bit vector of x indexes based on pri + sec pair
 # first we ask if this data comes from album, exif or position
 my $orig = $self->origin ( $pri, $sec );
  
 # unknown pri -> return empty vector
 $orig or return Bit::Vector->new( $size ); 
 
 # we use exif view INEXIFF, not INEXIF
 $orig eq 'exif' and $orig .= 'f'; 
  
 if ( $pri eq 'has' ) {
    
  $res = $self->dbcol( "select x from photo natural join in$orig where sid in (select sid from sec natural join pri where pri=? )", $sec )
            
 } else { # no 'has'
 
  if ( ( index ( $sec, '%' ) > -1 ) or ( index ( $sec, '_' ) > -1 ) ) {
  
   # pattern matching, always from both languages to make site's language change feature work smoothly

   $res = $self->dbcol ( "select x from photo natural join in$orig where sid in ( select sid from sec natural join pri where pri=? and (sec_en like ? or sec_fi like ?) )", $pri, $sec, $sec )
       
  } else {

   # exact, always from both languages to make site's language change feature work smoothly
 
   $res = $self->dbcol ( "select x from photo natural join in$orig where sid in ( select sid from sec natural join pri where pri=? and (sec_en=? or sec_fi=?) )", $pri, $sec, $sec )
 
  }  

 }
       
 my $bvec = Bit::Vector->new( $size );
   
 $bvec->Index_List_Store ( @$res ); # store the x indexes as bits
  
 return $bvec;  
  
}   

sub _bits { # fetch a bit vector for a set of arguments

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

sub _array { # vector as an array of indexes

 my ( $self, @args ) = @_;

 my $bvec = $self->vectorize ( @args ); 
 
 [ $bvec->Index_List_Read ];
 
}

sub _array_rand { # vector as array of indexes in random order 

 my ( $self, @args ) = @_;

 [ shuffle ( @{ $self->array ( @args ) } ) ]; 

}

sub _array_rand_n { # vector as array of indexes in random order limited 

 my ( $self, @args ) = @_;
 
 my $n = pop @args // 5;

 my $rand = $self->array_rand ( @args, $n );
 
 scalar @$rand > $n and 
  return [ @{ $rand } [ 0 .. $n - 1 ] ];
  
 return $rand; 

}

sub _pager { # create a vector and process it to usable for browsing

 my $res;

 my ( $self, $db, $lang, $x, $perpage, @args ) = @_;
     
 my $svec = $self->digg ( $db, $lang, 'array', @args );
   
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

sub _pointer {

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

# the index of the first photo in the vector

sub _first { 

 my $svec = vector_array ( @_ );
   
 scalar @{ $svec } == 0 ? undef : $svec->[0];
   
}

# the count of items in vector

sub _count { my $bvec = vector_bit( @_ ); $bvec->Norm }

1;
