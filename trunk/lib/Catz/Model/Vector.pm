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
 vector_bit vector_array vector_array_rand 
 vector_pager vector_pointer vector_count
);

use Bit::Vector;
use List::Util qw ( shuffle );
use POSIX qw( floor ceil );

use Catz::Data::Cache;
use Catz::Data::DB;

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
 
 my $res;
  
 if ( $pri eq 'has' ) {
 
  $res = $db->col( "select distinct(x) from pri natural join sec natural join snip natural join _x where pri=?", $sec );
            
 } else { # no 'has'
 
  if ( ( index ( $sec, '%' ) > -1 ) or ( index ( $sec, '_' ) > -1 ) ) {
  
   # pattern matching

   $res = $db->col( "select x from pri natural join sec natural join snip natural join _x where pri=? and sec_$lang like ?", $pri, $sec );    
 
  } else {

   # exact
 
   $res = $db->col( "select x from pri natural join sec natural join snip natural join _x where pri=? and sec_$lang=?", $pri, $sec );
 
  }  

 }
 
 my $maxx = $db->one( "select max(x) from _x" ) + 1;
      
 my $bvec = Bit::Vector->new( $maxx );
   
 $bvec->Index_List_Store ( @$res );
  
 return $bvec;  
  
}   

sub vector_bit {

 my $res;

 my ( $db, $lang, @args ) = @_;
 
 my $maxx = $db->one( "select max(x) from _x" ) + 1;
     
 # OR base vector is a completely empty vector
 my $ors =  Bit::Vector->new( $maxx ); 

 # AND base vector is a completely filled vector 
 my $ands = Bit::Vector->new( $maxx );
 $ands->Fill;
  
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

 my $res;
   
 my $bvec = vector_bit( @_ );
 
 my @arr = $bvec->Index_List_Read;
   
 return \@arr;

}

sub vector_array_rand {

 my $res;

 my $arr = vector_array ( @_ );
 
 my @rand = shuffle ( @{ $arr } );
 
 return \@rand;
  
}

sub vector_pager {

 my $res;

 my ( $db, $lang, $from, $to, $perpage, @args ) = @_;
  
 my $svec = vector_array( $db, $lang, @args );
 
 my $total = scalar @{ $svec };
      
 my $pages = ceil ( $total / $perpage );
 
 my $page = floor ( ( $from - 1 ) / $perpage ) + 1;
     
 my $first = "1-$perpage";
 
 my $prev = undef;
 
 $page > 1 and $prev = ( $from - $perpage ) . '-' . ( $to - $perpage );
 
 my $next = undef; 

 $page < $pages and $next = ( $from + $perpage ) . '-' . ( $to + $perpage );
 
 my $last = ( ( ( $pages - 1 )  * $perpage ) + 1 )  . '-' . ( $pages * $perpage );  
  
 ( $to > $total ) and $to = $total;
   
 my @xs = ();
  
 do { push @xs, $svec->[$_-1] } foreach ( $from .. $to );
  
 my @out = ( $total, $page, $pages, $from, $to , $first, $prev, $next, $last, \@xs );
    
 return \@out;

}

sub vector_pointer {

 my $res;

 my ( $db, $lang, $album, $n, $perpage, @args ) = @_;

 my $svec = vector_array( $db, $lang, @args );
  
 my $total = scalar @{ $svec };
   
 my $x = $db->one( 'select x from _x where album=? and n=?', $album, $n );
    
 my $idx = bsearch( $svec, $x ); 

 #$idx == -1 and $self->render(status => 404);
   
 my $page = floor ( $idx / $perpage ) + 1;
      
 my $first = undef;
 my $prev = undef;
 
 $idx > 0 and do {

  $first = $db->one( "select album||'/'||n from _x where x=?", $svec->[0] );
  $prev = $db->one( "select album||'/'||n from _x where x=?", $svec->[$idx-1] );
  
 };

 my $last = undef;
 my $next = undef; 
  
 $idx < ( $total - 1 ) and do {

  $last = $db->one( "select album||'/'||n from _x where x=?", $svec->[$total-1] );
  $next = $db->one( "select album||'/'||n from _x where x=?", $svec->[$idx+1] );
  
 };

 my @out = ( $total, $idx+1, $x, $page, $first, $prev, $next, $last );
   
 return \@out;
    
}

sub vector_count {

 my $res;
   
 my $bvec = vector_bit( @_ );
  
 my $total = $bvec->Norm;
  
 return $total; 
 
}

1;
