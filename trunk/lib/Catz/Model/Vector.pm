#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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
our @EXPORT = qw( vector_bit vector_array vector_pager vector_pointer vector_count vector_array_random );

use Bit::Vector;
use List::Util qw ( shuffle );
use POSIX qw( floor ceil );

use Catz::Cache;
use Catz::DB;
use Catz::Model::Meta;

my $empty =  Bit::Vector->new( meta_maxx ); 

my $full = Bit::Vector->new( meta_maxx );
$full->Fill;

sub bsearch {

  # modified from
  # http://staff.washington.edu/jon/dsa-perl/dsa-perl.html
  # http://staff.washington.edu/jon/dsa-perl/bsearch-copy
    
  my ( $a, $x ) = @_; # search for x in array a
    
  my ( $l, $u ) = ( 0, scalar(@$a)-1 ); # search interval
 
  my $i; # index of probe
      
  while ($l <= $u) {
  
   $i = int(($l + $u)/2);
    	 
   if ($a->[$i] > $x) { $u = $i - 1; } 
   
    elsif ($a->[$i] < $x) { $l = $i + 1; } 
    
    else { return $i; } # found
 
  }
  
  return -1; # not found
 
 }


sub vectorize {

 my $res;

 if( $res = cache_get( (caller(0))[3], @_ ) ) { return $res } 
 
 my ( $lang, $pri, $sec ) = @_;
  
 if ( $pri eq 'has' ) {
 
  $res = db_col( "select distinct(x) from snip natural join x where pri=?", $sec );
            
 } else { # no 'has'
 
  if ( ( index ( $sec, '%' ) > -1 ) or ( index ( $sec, '_' ) > -1 ) ) {
  
   # pattern matching

   $res = db_col( "select x from snip natural join x where pri=? and sec_$lang like ?", $pri, $sec );    
 
  } else {

   # exact
 
   $res = db_col( "select x from snip natural join x where pri=? and sec_$lang=?", $pri, $sec );
 
  }  

 }
      
 my $bvec = Bit::Vector->new( meta_maxx );
   
 $bvec->Index_List_Store ( @$res );
 
 cache_set( (caller(0))[3], @_, $bvec ); 
 
 return $bvec;  
  
}   

sub vector_bit {

 my $res;

 if( $res = cache_get( (caller(0))[3], @_ ) ) { return $res } 

 my ( $lang, @args ) = @_;
     
 # OR base vector is a completely empty vector
 my $ors = $empty->Clone;
 
 # AND base vector is a completely filled vector 
 my $ands = $full->Clone;
  
 # flag to detect if any or's were present
 my $hasor = 0;
 
 for (my $i = 0; $i <= $#args; $i=$i+2 ) {
  
  $args[$i+1] =~ /^(\+|\-)(.*)$/;
    
  my $oper = $1 // '0'; # the default operand is 0 = or
  
  my $rest = $2 // $args[$i+1]; 
  
  $rest =~ s/\?/\_/g; # user interface ? -> database interface _
  $rest =~ s/\*/\%/g; # user interface * -> database interface %
  
  #warn $rest;
            
  my $bvec = vectorize( $lang, $args[$i], $rest );
              
  given ( $oper ) {
  
   when ( '+' ) { $ands->And( $ands, $bvec) ; }
      
   when ( '0' ) { $hasor++; $ors->Or( $ors, $bvec ); }
   
   when ( '-' ) { $ands->AndNot( $ands, $bvec ); }
   
   default { die "unknow bit vector operation '$oper'"; }
  
  }
  
 }
 
 $hasor and $ands->And( $ands, $ors );
 
 cache_set( (caller(0))[3], @_, $ands );

 return $ands;
       
}

sub vector_array {

 my $res;

 if( $res = cache_get( (caller(0))[3], @_ ) ) { return $res } 
   
 my $bvec = vector_bit( @_ );
 
 my @arr = $bvec->Index_List_Read;
 
 cache_set( (caller(0))[3], @_, \@arr );
  
 return \@arr;

}

sub vector_array_random {

 my $res;

 if( $res = cache_get( (caller(0))[3], @_ ) ) { return $res } 

 my $arr = vector_array ( @_ );
 
 my @rand = shuffle ( @{ $arr } );

 cache_set( (caller(0))[3], @_, \@rand );
 
 return \@rand;
  
}



sub vector_pager {

 my $res;

 if( $res = cache_get( (caller(0))[3], @_ ) ) { return $res } 

 # lower maps to from, upper maps to to and this is the purpose
 my ( $from, $to, $perpage, @args ) = @_;
 
 #die join "\n", @args;
 
 my $svec = vector_array( @args );
 
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
  
 cache_set( (caller(0))[3], @_, \@out );
  
 return \@out;

}

sub vector_pointer {

 my $res;

 if( $res = cache_get( (caller(0))[3], @_ ) ) { return $res } 

 my ( $album, $n, $perpage, @args ) = @_;

 my $svec = vector_array( @args );
  
 my $total = scalar @{ $svec };
   
 my $x = db_one( 'select x from x where album=? and n=?', $album, $n );
    
 my $idx = bsearch( $svec, $x ); 

 #$idx == -1 and $self->render(status => 404);
   
 my $page = floor ( $idx / $perpage ) + 1;
      
 my $first = undef;
 my $prev = undef;
 
 $idx > 0 and do {

  $first = db_one( "select album||'/'||n from x where x=?", $svec->[0] );

  $prev = db_one( "select album||'/'||n from x where x=?", $svec->[$idx-1] );
  
 };

 my $last = undef;
 my $next = undef; 
  
 $idx < ( $total - 1 ) and do {

  $last = db_one( "select album||'/'||n from x where x=?", $svec->[$total-1] );

  $next = db_one( "select album||'/'||n from x where x=?", $svec->[$idx+1] );
  
 };

 my @out = ( $total, $idx+1, $x, $page, $first, $prev, $next, $last );
 
 cache_set( (caller(0))[3], @_, \@out );
  
 return \@out;
    
}

sub vector_count {

 my $res;

 if( $res = cache_get( (caller(0))[3], @_ ) ) { return $res } 
   
 my $bvec = vector_bit( @_ );
  
 my $total = $bvec->Norm;
 
 cache_set( (caller(0))[3], @_, $total );
 
 return $total; 
 
}

1;
