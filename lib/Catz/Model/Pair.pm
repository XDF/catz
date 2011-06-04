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

package Catz::Model::Pair;

#
# Get photos by pri-sec pair
#

use 5.10.0; use strict; use warnings;

use parent 'Catz::Model::Vector';

use Bit::Vector;

sub _bits { 

 # create a bit vector of xs for a pri-sec pair
 # language dependent

 my ( $self, $pri, $sec ) = @_;

 if ( 
  $pri eq 'has' or $pri eq 'any' or $sec eq 'text' or $sec eq 'album' or
  index ( $sec, '*' ) > -1 or index ( $sec, '?' ) > -1 
 ) { # reject

  return Bit::Vector->new( $self->maxx + 1 ); # empty vector

 } else { # pass-thru

  return $self->base( $pri, $sec );

 }
}

1;
