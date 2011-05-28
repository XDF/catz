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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Model::Common';

use Bit::Vector;
use List::Util qw ( shuffle );
use POSIX qw( floor ceil );

sub bsearch {

  # static binary search aka half-interval search method
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
  
   # not found is indicated as -1
   
   -1;
  
 }

sub _vectorize {
 
 my ( $self, $pri, $sec ) = @_;
 
 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used 
 my $size = $self->maxx  + 1;
 
 my $res;
 
 ( length ( $pri // '' ) > 0 and length ( $sec // '' ) > 0 ) or return Bit::Vector->new( $size );
  
 # create a bit vector of x indexes based on pri + sec pair
 # first we ask if this data comes from album, exif or position
 my $orig = $self->origin ( $pri, $sec );
  
 # unknown pri -> return empty vector
 $orig or return Bit::Vector->new( $size ); 
   
 if ( $pri eq 'has' ) {
    
  $res = $self->dbcol( "select x from _search_$orig where pri=?", $sec )
            
 } else { # no 'has'
 
  my $first = substr $sec, 0, 1; 
  my $last = substr $sec, -1, 1;
    
  if ( $first eq '%' ) {
  
   if ( $last eq '%') {  # %xyz%
   
    $res = $self->dbcol ( "select x from _search_$orig where pri=? and sec like ?", $pri, $sec );
   
   }  else { # %xyz
   
    $res = $self->dbcol ( "select x from _search_$orig where pri=? and (sec like ? or sec like ?)", $pri, $sec, "$sec %" );
   
   }
  
  } else {

   if ( $last eq '%') { # xyz%

    $res = $self->dbcol ( "select x from _search_$orig where pri=? and (sec like ? or sec like ?)", $pri, $sec, "% $sec" );
      
   }  else { # xyz

    $res = $self->dbcol ( "select x from _search_$orig where pri=? and (sec=? collate nocase or sec like ? or sec like ? or sec like ?)", $pri, $sec, "$sec %", "% $sec", "% $sec %" );   
   
   }

  } 
 
 }
        
 my $bvec = Bit::Vector->new( $size );
   
 $bvec->Index_List_Store ( @$res ); # store the x indexes as bits
  
 return $bvec;  
  
}   

sub _bits { # fetch a bit vector for a set of arguments

 my ( $self, @args ) = @_;
 
 my $size = $self->maxx + 1;
     
 # OR base vector is a completely empty vector
 my $ors =  Bit::Vector->new( $size ); 

 # AND base vector is a completely filled vector 
 my $ands = Bit::Vector->new( $size );
 
 $ands->Fill; # fill the vector
 
 $ands->Bit_Off(0); # 0th bit is unused as x counting start from 1
  
 my $hasor = 0; # flag to detect if any ors were present
 
 for ( my $i = 0; $i <= $#args; $i = $i + 2 ) {
  
  $args[$i+1] =~ /^(\+|\-)(.*)$/;
    
  my $oper = $1 // '0'; # the default operand is 0 = or
  my $rest = $2 // $args[$i+1]; 
  
  $rest =~ s/\?/\_/g; # user interface ? -> database interface _
  $rest =~ s/\*/\%/g; # user interface * -> database interface %
              
  my $bvec = $self->vectorize( $args[$i], $rest ); # make one vector
                
  given ( $oper ) {
  
   when ( '+' ) { $ands->And( $ands, $bvec ) ; }
      
   when ( '0' ) { $hasor++; $ors->Or( $ors, $bvec ); }
   
   when ( '-' ) { $ands->AndNot( $ands, $bvec ); }
   
   default { die "unknow vector operation '$oper'"; }
  
  }
  
 }
 
 # if ors vere present then and them with ands
 $hasor and $ands->And( $ands, $ors );
 
 return $ands;
       
}

sub _array { # vector as an array of indexes

 my ( $self, @args ) = @_;

 my $bvec = $self->bits ( @args ); 
 
 [ $bvec->Index_List_Read ];
 
}

sub _array_rand { # vector as array of indexes in random order 

 my ( $self, @args ) = @_;

 [ shuffle ( @{ $self->array ( @args ) } ) ]; 

}

sub _array_rand_n { # vector as array of indexes in random order limited 

 my ( $self, @args ) = @_;
 
 my $n = pop @args // 5;

 my $rand = $self->array_rand ( @args );
 
 scalar @$rand > $n and 
  return [ @{ $rand } [ 0 .. $n - 1 ] ];
  
 return $rand; 

}

sub _pager { # create a vector and process it to usable for browsing

 my ( $self, $x, $perpage, @args ) = @_;
 
 my $res;
     
 my $svec = $self->array ( @args );
    
 my $xfrom = bsearch( $svec, $x ); # search for the x
  
 $xfrom == -1 and return [ 0 ]; # not found -> total = 0

 my $total = scalar @{ $svec };

 my $pages = ceil ( $total / $perpage );

 my $xlast = $total - 1;

 my $page = floor ( $xfrom / $perpage ) + 1;
 
 # roll to the first photo on this page if not yet there
 $xfrom = ( ( $page - 1 ) * $perpage );  
  
 my $xto = $xfrom + $perpage - 1;
 
 $xto > $xlast and $xto = $xlast;

 my $from = $xfrom + 1; 
 
 my $to = $xto + 1;
 
 # list of xs pointing to pages
 my @roots = map { $svec->[$_*$perpage] } ( 0 .. $pages - 1  );
  
 # convert xs to id:s
 my $pins = $self->xs2ids ( @roots );

 # xs on this page         
 my $xs = [ map { $svec->[$_] } ( $xfrom .. $xto ) ];
   
 [ ( $total, $page, $pages, $from, $to , $pins, $xs ) ];
      
}

sub _pointer {

 my ( $self, $x, @args ) = @_;
 
 my $res;
    
 my $svec = $self->array ( @args ); # get an array of xs
    
 my $idx = bsearch ( $svec, $x ); # search for the x
  
 $idx == -1 and return [ 0 ]; # not found -> total = 0 
 
 my $total = scalar @{ $svec };
 
 my @pin = (); 
 
 push @pin, $self->x2id ( $svec->[0] ); # first
  
 push @pin, $self->x2id ( $svec->[ $idx > 0 ? $idx - 1  : 0 ] ); # next
  
 push @pin, $self->x2id ( 
  $svec->[ $idx < ( $total - 1 ) ? $idx+1 : ( $total - 1 ) ] 
 ); # prev
 
 push @pin, $self->x2id ( $svec->[$total-1] ); # last 
    
 return [ ( $total, $idx + 1, \@pin ) ];
    
}

# the index of the first photo in the vector

sub _first {

 my $self = shift; 

 my $svec = $self->array ( @_ );
   
 scalar @{ $svec } == 0 ? undef : $svec->[0];
   
}

# the count of items in vector

sub _count {

 my $self = shift;
  
 my $bvec = $self->bits ( @_ ); 
 
 $bvec->Norm 
 
}

1;
