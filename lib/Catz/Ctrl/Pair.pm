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

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Present';

sub pair {

 my $self = shift; my $s = $self->{stash};
 
 $self->f_init or return $self->fail ( 'f_init exit' );

 $s->{runmode} = 'pair';

 # routing already does basic existence, length and character class checking

 # check that pri is acceptable
 $self->fetch( 'pair#verify', $s->{pri} ) or return $self->fail ( 'illegal concept' );
 
 $s->{sec} = $self->decode ( $s->{sec} );

 $self->f_map or return $self->fail ( 'f_map exit' );

 $s->{args_array} = [ $s->{pri}, $s->{sec} ];
 $s->{args_count} = 2;
   
 $self->f_origin or return $self->fail ( 'f_origin exit' );
 
 # get the translation for this pri-sec -pair 
 ( $s->{trans} = $self->fetch ( 'map#trans', $s->{pri}, $s->{sec} ) )
  or return $self->fail ( 'translation error' );
  
 $s->{urlother} = $self->fuse (
  $s->{langaother}, $s->{action}, $s->{pri}, $self->encode( $s->{trans} )
 );
  
 $s->{origin} eq 'id' and $s->{urlother} .= $s->{id} . '/';

 # fetch country names based on codes to be used in meta tags
 # added 2011-10-16  
 $s->{pri} eq 'nat' and  $s->{nats} = $self->fetch ( 'map#nats' );
 
 # if refines are defined for this pri then fetch them 
 defined $s->{matrix}->{ $s->{pri} }->{refines} and 
  $s->{refines} = $self->fetch (
   'related#refines', 
   $s->{pri}, $s->{sec}, 
   @{ $s->{matrix}->{ $s->{pri}} ->{refines} } 
  ); 

 # fetch the extra information for breeder
 ( $s->{pri} eq 'breeder' ) and
  $s->{breedernat} = $self->fetch ( "related#breedermeta", $s->{sec} );

 return $self->done;

}

sub browse {

 my $self = shift; 

 $self->pair or return $self->fail ( 'pair exit' );
 
 $self->multi or return $self->fail ( 'multi exit' );
 
}

sub view { 

 my $self = shift; 

 $self->pair or return $self->fail ( 'pair exit' );
   
 $self->single or return $self->fail ( 'single exit' );
  
}

1;