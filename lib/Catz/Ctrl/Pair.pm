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

use Catz::Util::Number qw ( round );

sub pair_ok {

 my $self = shift; my $s = $self->{stash};

 # routing already does basic length and character class checking

 # check that pri and sec are provided 
 # directly by the routing 
 ( $s->{pri} and $s->{sec} ) or return 0;
   
 # check that pri is acceptable
 $self->fetch( 'pair#verify', $s->{pri} ) or return 0;
 
 return 1;
 
}

sub pair_pre {

 my $self = shift; my $s = $self->{stash};
 
 $s->{sec} = $self->decode ( $s->{sec} ); # using decode helper
 
 $s->{args_array} = [ $s->{pri}, $s->{sec} ];
 $s->{args_count} = 2;
 
 return 1;
 
}

sub pair_urlother {
 
 my $self = shift; my $s = $self->{stash};
 
 # get the translation for this pri-sec -pair 
 $s->{trans} = $self->fetch ( 'map#trans', $s->{pri}, $s->{sec} );

 $s->{urlother} =  
  '/' . ( join '/', $s->{langaother} , $s->{action}, $s->{pri}, 
  $self->encode( $s->{trans} ) ). '/' .
  ( $s->{origin} eq 'id' ?  $s->{id} . '/' : '' );
  
 return 1;

}


sub pair {

 my $self = shift; my $s = $self->{stash};
 
 $self->init or return 0;

 $s->{runmode} = 'pair';
  
 $self->pair_ok or return 0;
  
 # using decode helper
 $s->{sec} = $self->decode ( $s->{sec} ); 
 
 $self->load or return 0;

 $self->pair_pre or return 0;
   
 $self->origin or return 0;
 
 # get the translation for this pri-sec -pair 
 $s->{trans} = $self->fetch ( 'map#trans', $s->{pri}, $s->{sec} );
  
 ( $s->{pri} eq 'nat' ) and do {
 
  # fetch country names based on codes to be used in meta tags
  # added 2011-10-16
  
  $s->{nats} = $self->fetch ( 'map#nats' );
 
 };
 
 $self->pair_urlother or return 0;    

 # if refines are defined for this pri then fetch them 
 defined $s->{matrix}->{ $s->{pri} }->{refines} and 
  $s->{refines} = $self->fetch (
   'related#refines', 
   $s->{pri}, $s->{sec}, 
   @{ $s->{matrix}->{ $s->{pri}} ->{refines} } 
  ); 

 ( $s->{pri} eq 'breeder' ) and
  $s->{breedernat} = $self->fetch ( "related#breedermeta", $s->{sec} );

 return 1;

}

sub browse {

 my $self = shift; 

 $self->pair or return $self->render_not_found;
  
 $self->multi or return $self->render_not_found;

}

sub view { 

 my $self = shift; 

 $self->pair or return $self->render_not_found;
  
 $self->single or return $self->render_not_found;
 
}

1;