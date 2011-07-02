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
    
  my ( $self, $a, $x ) = @_; # search for x in arrayref a
    
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
 
sub _base {
 
 my ( $self, $pri, $sec ) = @_;
  
 my $res;
 
 # sql statements returning photo x don't use distinct or group by to
 # remove duplicats since it appears to faster to just pass them
 # Bit::Vector Index_List_Store that doesn't mind the duplicats
       
 if ( $pri eq 'has' ) { 
 
   # get all photos that have a subject of subject class $sec defined
    
  $res = $self->dbcol("select x from sec natural join _sid_x where pid=(select pid from pri where pri=?)", $sec);
            
 } else {
 
  # we execute all searches as like instead of = since this appears to give us
  # the closest behavior of case-insensitivitiness with äÄ and öÖ without
  # being sure why (collate nocase with = doesn't give the same result)
 
  if ( $pri eq 'any' ) {
           
   $res = $self->dbcol("select x from _sid_x where sid in (select sid from sec where (sec_en like ? or sec_fi like ?))", $sec, $sec);
   
  } else {
   
   $res = $self->dbcol("select x from _sid_x where sid in (select sid from sec where pid=(select pid from pri where pri=?) and (sec_en like ? or sec_fi like ?))", $pri, $sec,$sec);
   
  }
    
 }
  
 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used      
 my $vec = Bit::Vector->new( $self->maxx  + 1 );
   
 $vec->Index_List_Store ( @$res ); # store the x indexes as bits
  
 return $vec;  
  
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
     
 my $xfrom = $self->bsearch( $svec, $x ); # search for the x
  
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
   
 [ ( $total, $page, $pages, $from, $to , $pins, $xs, $svec->[0], $svec->[$#{$svec}] ) ];
      
}

sub _pointer {

 my ( $self, $x, @args ) = @_;
 
 my $res;
    
 my $svec = $self->array ( @args ); # get an array of xs
    
 my $idx = $self->bsearch ( $svec, $x ); # search for the x
  
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
