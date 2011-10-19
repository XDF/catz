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

package Catz::Ctrl::Widget;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use List::MoreUtils qw ( any );
use List::Util qw ( shuffle );

use Catz::Data::Search;
use Catz::Data::Widget;

use Catz::Util::Number qw ( round );
use Catz::Util::String qw ( clean noxss trim );

sub strip {

 my $self = shift; my $s = $self->{stash};
 
 my $w = widget_conf;
 
 # size
 
 $s->{size} = 
  int ( $self->param( 'size' ) // $w->{strip}->{size_default} );
  
 $s->{size} < $w->{strip}->{size_min} and return $self->render_not_found;
 $s->{size} > $w->{strip}->{size_max} and return $self->render_not_found;
 
 # target
 
 $s->{limit} = 
  int ( $self->param( 'limit' ) // $w->{strip}->{limit_default} );
  
 $s->{limit} < $w->{strip}->{limit_min} and return $self->render_not_found;
 $s->{limit} > $w->{strip}->{limit_max} and return $self->render_not_found;
 
 # estimate required thumbnail count
 
 my $n = widget_tn_est ( $s->{limit}, $s->{size} );   

 # type

 $s->{type} = $self->param( 'type' ) // $w->{strip}->{type_default};
 
 any { $_ eq $s->{type} } @{ $w->{strip}->{types} }
  or return $self->render_not_found;

 # data modes: all, pair or pattern
 
 $s->{runmode} = 'all'; # default
 
 $s->{what} = $self->param('q') // undef;
 $s->{pri} = $self->param('p') // undef;
 $s->{sec} = $self->param('s') // undef;
 
 if ( $s->{pri} or $s->{sec} ) {
 
  $s->{runmode} = 'pair';

  $self->fetch ( 'pair#verify', $s->{pri} ) or
   return $self->render_not_found;
   
   $s->{sec} = $self->decode ( $s->{sec} ); # using decode helper
   
   $s->{xs} = $self->fetch ( 'pair#array_rand_n', $s->{pri}, $s->{sec}, $n );
  
 } elsif ( $s->{what} ) {
 
  $s->{runmode} = 'pattern';
  
  # sanity check
  ( length $s->{what} > 1234 ) and return $self->render_not_found;

   # it appears that browsers typcially send UTF-8 encoded 
   # data when the origin page is UTF-8 -> we decode the data now   
   utf8::decode ( $s->{what} );

   # remove all unnecessary whitespaces     
   $s->{what} = noxss clean trim $s->{what};
    
   # we don't allow '', we set it to undef
   $s->{what} eq '' and return $self->render_not_found;
   
   # convert search to argument array 
   $s->{args_array} = search2args ( $s->{what} );
  
   $s->{args_count} = scalar @{ $s->{args_array} };
  
   (
    $s->{args_count} > 0 and # there are args
    $s->{args_count} <= 50 and # max 25 pairs accepted   
    $s->{args_count} % 2 == 0 and # args come in as pairs 
    $self->fetch('search#verify_args',@{$s->{args_array}}) # all pris are ok 
   ) or return $self->render_not_found;
   
   $s->{xs} = $self->fetch ( 'search#array_rand_n', @{ $s->{args_array} }, $n ); 

 } else {
 
  $s->{runmode} = 'all';
  
  $s->{xs} = $self->fetch ( 'all#array_rand_n', $n );
 
 } 
  
 scalar @{ $s->{xs} } == 0 and return $self->render_not_found;
 
 # fetch corresponding thumbnails
 
 ( $s->{thumbs}, undef, undef ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };
 
 # thumbs come back in x order, must reshuffle to get 
 # truly random photo order
   
 $self->render_data ( 
  widget_strip ( 
   [ shuffle @{ $s->{thumbs} } ], 
   $s->{type}, $s->{size}, $s->{limit} 
  ), format => 'jpg' 
 );
  
}

1;