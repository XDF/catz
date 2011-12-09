
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

package Catz::Model::Common;

use 5.12.0;
use strict;
use warnings;

use parent 'Catz::Model::Base';

use Catz::Util::Number qw ( fullnum33 minnum33 );

# adding some general small methods

sub _maxx { $_[ 0 ]->dbone ( 'select max(x) from photo' ) }

sub _id2x {

 my ( $self, $id ) = @_;

 my ( $s, $n ) = minnum33 ( $id );

 $self->dbone ( 'select x from album natural join photo where s=? and n=?',
  $s, $n );

}

sub _x2id {

 my ( $self, $x ) = @_;

 my $res =
  $self->dbrow ( 'select s,n from album natural join photo where x=?', $x );

      defined $res
  and defined $res->[ 0 ]
  and defined $res->[ 1 ]
  and return ( fullnum33 ( $res->[ 0 ], $res->[ 1 ] ) );

 return undef;

}

sub _xs2ids {

 my ( $self, @xs ) = @_;

 [
  map { fullnum33 ( $_->[ 0 ], $_->[ 1 ] ) } @{
   $self->dball (
       'select s,n from album natural join photo where x in ('
     . ( join ',', @xs )
     . ') order by x'
   )
   }
 ];

}

1;
