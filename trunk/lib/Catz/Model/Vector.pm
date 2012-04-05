#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2012 Heikki Siltala
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

use 5.14.2;
use strict;
use warnings;

use parent 'Catz::Model::Common';

use Const::Fast;
use Bit::Vector;
use List::Util qw ( shuffle );

use Catz::Util::Number qw( floor ceil );

sub full {

 # returns all photos vector = filled bit vector

 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used
 my $vec = Bit::Vector->new ( $_[ 0 ]->maxx + 1 );

 $vec->Fill;

 $vec->Bit_Off ( 0 );    # 0th bit is unused as x counting start from 1

 return $vec;

}

sub empty {

 # returns a base empty vector (all bits 0)

 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used

 return Bit::Vector->new ( $_[ 0 ]->maxx + 1 );

}

sub bsearch {

 # binary search aka half-interval search method
 # http://en.wikipedia.org/wiki/Binary_search_algorithm

 # this code is a modified version of
 # http://staff.washington.edu/jon/dsa-perl/dsa-perl.html
 # http://staff.washington.edu/jon/dsa-perl/bsearch-copy

 my ( $self, $a, $x ) = @_;    # search for x in arrayref a

 my ( $l, $u ) = ( 0, scalar ( @$a ) - 1 );    # search interval $l - $u

 my $i;                                        # index of probe

 while ( $l <= $u ) {

  $i = int ( ( $l + $u ) / 2 );

  if ( $a->[ $i ] > $x ) { $u = $i - 1; }

  elsif ( $a->[ $i ] < $x ) { $l = $i + 1; }

  else { return $i; }                          # found

 }

 # not found is indicated as -1

 -1;

} ## end sub bsearch

# we define the SQLs here to make sure that they are literally
# same to take full advantage on database result set caching

const my $SQL_GENERAL => qq {
 select x from _sid_x where sid in (
  select sid from sec where (sec_en like ? or sec_fi like ?)
 )   
};

const my $SQL_ID =>
 'select x from album natural join photo where fullnum33(s,n) like ?';

const my $SQL_FILE => 'select x from photo where file like ?';

sub _base {

 my ( $self, $pri, $sec ) = @_;

 # handling of secs "id "and "file" added separately 2011-12

 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used
 my $vec = Bit::Vector->new ( $self->maxx + 1 );

 my $res = [];

 # sql statements returning photo x don't use distinct or group by to
 # remove duplicates since it is tested to be faster to just pass them to
 # Bit::Vector Index_List_Store and it doesn't mind the duplicates

 given ( $pri ) {

  when ( 'has' ) {

   # get all photos that have a subject of subject class $sec defined

   if ( $sec eq 'id' or $sec eq 'file' ) {

    # every photo has 'id' and 'file' so we just return a filled vector

    # 0th bit is unused as x counting start from 1
    $vec->Fill;
    $vec->Bit_Off ( 0 );
    return $vec;

   }
   else {

    $res = $self->dbcol (
     qq { 
     select x from sec natural join _sid_x 
     where pid=(select pid from pri where pri=?) 
    }, $sec
    );

   }

  } ## end when ( 'has' )

  # we execute all searches as like instead of = since this appears to give us
  # the closest behavior of case-insensitivitiness with äÄ and öÖ without
  # being sure why (collate nocase with = doesn't give the same result)

  when ( 'any' ) {

   # search all concepts, remember to union the special cases 'id' and
   # 'file' - we do it piece by piece to utilize database result set
   # caching more efficiently

   # 1/3: general

   $res = $self->dbcol ( $SQL_GENERAL, $sec, $sec );

   $vec->Index_List_Store ( @$res );

   # 2/3: id

   # optimize so that if $sec has any other characters than
   # digits, _s and %s it can't match an id
   $sec =~ /^[0-9_\%]*$/ and do {

    $res = $self->dbcol ( $SQL_ID, $sec );

    $vec->Index_List_Store ( @$res );

   };

   # 3/3: file

   # remove endings like "_LR.JPG" and ".JPG" if present
   $sec =~ s|(\_lr)?\.jpg$||i;

   # optimize so that if $sec hasn't got digits, _ or % it can't
   # match a filename since a filename has always at least 4 digits
   $sec =~ /[0-9_\%]/ and do {

    $res = $self->dbcol ( $SQL_FILE, $sec );

    $vec->Index_List_Store ( @$res );

   };

   return $vec;

  } ## end when ( 'any' )

  when ( 'id' ) {

   # special handling for file id searches added 2011-12-06

   # optimize so that if $sec any other characters than
   # digits, _s and %s it can't match an id
   ( $sec =~ /^[0-9_\%]*$/ )
    and $res = $self->dbcol ( $SQL_ID, $sec );

  }

  when ( 'file' ) {

   # special handling for file name searches added 2011-12-06

   # remove endings like "_LR.JPG" and ".JPG" if present
   $sec =~ s|(\_lr)?\.jpg$||i;

   # optimize so that if $sec hasn't got digits, _ or % it can't
   # match a filename since a filename has always at least 4 digits
   $sec =~ /[0-9_\%]/
    and $res = $self->dbcol ( 'select x from photo where file like ?', $sec );

  }

  default {

   # search a within a single concept

   $res = $self->dbcol (
    qq { 
    select x from _sid_x where sid in ( 
     select sid from sec where 
      pid=(select pid from pri where pri=?) and 
      (sec_en like ? or sec_fi like ?)
    ) }, $pri, $sec, $sec
   );

  }

 } ## end given

 $vec->Index_List_Store ( @$res );

 return $vec;

} ## end sub _base

sub _array {    # vector as an array of indexes

 my ( $self, @args ) = @_;

 my $bvec = $self->bits ( @args );

 [ $bvec->Index_List_Read ];

}

sub _array_n {    # vector as an array limited

 my ( $self, @args ) = @_;

 my $n = pop @args // 5;

 my $bvec = $self->array ( @args );

 scalar @$bvec > $n
  and return [ @{ $bvec }[ 0 .. $n - 1 ] ];

 return $bvec;

}

sub _array_rand {    # vector as array of indexes in random order

 my ( $self, @args ) = @_;

 [ shuffle ( @{ $self->array ( @args ) } ) ];

}

sub _array_rand_n {    # vector as array of indexes in random order limited

 my ( $self, @args ) = @_;

 my $n = pop @args // 5;

 my $rand = $self->array_rand ( @args );

 scalar @$rand > $n
  and return [ @{ $rand }[ 0 .. $n - 1 ] ];

 return $rand;

}

sub _pager {    # create a vector and process it to usable for browsing

 my ( $self, $x, $perpage, @args ) = @_;

 my $res;

 my $svec = $self->array ( @args );

 my $xfrom = $self->bsearch ( $svec, $x );    # search for the x

 $xfrom == -1 and return [ 0 ];               # not found -> total = 0

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
 my @roots = map { $svec->[ $_ * $perpage ] } ( 0 .. $pages - 1 );

 # convert xs to id:s
 my $pins = $self->xs2ids ( @roots );

 # xs on this page
 my $xs = [ map { $svec->[ $_ ] } ( $xfrom .. $xto ) ];

 [
  (
   $total, $page, $pages, $from, $to, $pins, $xs,
   $svec->[ 0 ],
   $svec->[ $#{ $svec } ]
  )
 ];

} ## end sub _pager

sub _pointer {

 my ( $self, $x, @args ) = @_;

 my $res;

 my $svec = $self->array ( @args );    # get an array of xs

 my $idx = $self->bsearch ( $svec, $x );    # search for the x

 $idx == -1 and return [ 0 ];               # not found -> total = 0

 my $total = scalar @{ $svec };

 my @pin = ();

 push @pin, $self->x2id ( $svec->[ 0 ] );    # first

 push @pin, $self->x2id ( $svec->[ $idx > 0 ? $idx - 1 : 0 ] );    # next

 push @pin,
  $self->x2id (
  $svec->[ $idx < ( $total - 1 ) ? $idx + 1 : ( $total - 1 ) ] );    # prev

 push @pin, $self->x2id ( $svec->[ $total - 1 ] );                   # last

 return [ ( $total, $idx + 1, \@pin ) ];

} ## end sub _pointer

# the index of the first photo in the vector

sub _first {

 my $self = shift;

 my $svec = $self->array ( @_ );

 scalar @{ $svec } == 0 ? undef : $svec->[ 0 ];

}

# the count of items in vector

sub _count {

 my $self = shift;

 my $bvec = $self->bits ( @_ );

 $bvec->Norm

}

1;
