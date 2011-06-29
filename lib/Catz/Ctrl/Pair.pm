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

package Catz::Ctrl::Pair;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Ctrl::Present';

sub pair {

 my $self = shift; my $s = $self->{stash};

 $s->{runmode} = 'pair'; # set the runmode to pri-sec pair 
 
 # check that pri and sec are provided by the request  
 $s->{pri} and $s->{sec} or return 0;
 
 $self->fetch('pair#verify',$s->{pri}) or return 0;
 
 $s->{sec} = $self->decode ( $s->{sec} ); # using decode helper
 
 $s->{args_array} = [ $s->{pri}, $s->{sec} ];
 $s->{args_count} = 2;
 
 $s->{what} = undef;
 $s->{refines} = undef;
 $s->{breedernat} = undef;
 $s->{breederurl} = undef;
 $s->{origin} = 'none'; # to indiate that origin was not processed
 
 $self->pre or return 0;
 
 # get the translation for this pri-sec -pair
 $s->{trans} = $self->fetch ( 'map#trans', $s->{pri}, $s->{sec} );  

 $s->{urlother} =  
  '/' . ( join '/', $s->{langother} , $s->{action}, $s->{pri}, 
  $self->encode( $s->{trans} ) ). '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );

 # if refines are defined for this pri then fetch them 
 defined $s->{matrix}->{$s->{pri}}->{refines} and 
  $s->{refines} = $self->fetch (
   'related#refines', 
   $s->{pri}, $s->{sec}, 
   @{ $s->{matrix}->{$s->{pri}}->{refines} } 
  ); 

 if ( $s->{pri} eq 'breeder' ) {
 
  # special services for breeders
  my $xm = $self->fetch ( "related#breedermeta", $s->{sec} );
  
  defined $xm and do {
  
   $s->{breedernat} = $xm->[0]; 
   $s->{breederurl} = $xm->[1];
   
  }; 
 
 }
  
 return 1;

}

sub browse {
 
 $_[0]->pair or ( $_[0]->not_found and return );  

 $_[0]->multi or ( $_[0]->not_found and return );  

}

sub view { 

 $_[0]->pair or ( $_[0]->not_found and return );
   
 $_[0]->single or ( $_[0]->not_found and return );  
 
}

1;