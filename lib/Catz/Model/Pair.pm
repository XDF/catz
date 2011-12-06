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

use 5.12.0; use strict; use warnings;

use parent 'Catz::Model::Vector';

use Bit::Vector;

sub _bits { 

 # create a bit vector of xs for a pri-sec pair
 # language dependent

 my ( $self, $pri, $sec ) = @_; my $lang = $self->{lang};
  
 my $res = $self->dbcol ( qq {
  select x from _sid_x where sid in ( 
   select sid from sec_$lang where pid = ( 
    select pid from pri where pri=?
   ) and sec=? ) 
 }, $pri, $sec );

 # creating an empty bit vector one larger than there are photos
 # since 0 index in not used      
 my $vec = Bit::Vector->new( $self->maxx  + 1 );
   
 $vec->Index_List_Store ( @$res ); # store the x indexes as bits
  
 return $vec;    

}

sub verify {

 # verify a pri that it is an allowed pri-sec pri
 
 my ( $self, $pri ) = @_;
 
 defined $pri or return 0;
 
 ( $pri eq 'album' or $pri eq 'text' ) and return 0;
 
 $self->dbone ( 'select 1 from pri where pri=?', $pri ) ? 1 : 0;

}

1;


 
