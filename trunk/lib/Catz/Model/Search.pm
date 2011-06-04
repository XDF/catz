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

package Catz::Model::Search;

#
# Get photos by a array of search arguments
#

use 5.10.0; use strict; use warnings;

use parent 'Catz::Model::Vector';

use Bit::Vector;

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
              
  my $bvec = $self->base( $args[$i], $rest ); # make one vector by pass-thru
                
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

1;
