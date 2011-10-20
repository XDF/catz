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

# we inherit from all controller types to be 
# able to use all three runmode's methods

use parent qw ( Catz::Ctrl::All Catz::Ctrl::Pair Catz::Ctrl::Search );

use List::MoreUtils qw ( any );
use List::Util qw ( shuffle );

use Catz::Data::Widget;

my @params = qw ( width height );

use Catz::Util::Number qw ( round );

sub serialize {

 my $self = shift;

 # serialize query parameter
 
 my @pairs = ();
 
 foreach my $par ( @params ) {
 
  my $val = $self->param ( $par ) // undef;
  
  defined $val and
   push @pairs, "$par=" . $self->enurl ( $val );
    
 }
 
 scalar @pairs == 0 and return ''; 
 
 return join '&', @pairs; 
 
}

sub params {

 # verify / process widget parameters
 
 my $self = shift; my $s = $self->{stash};
 
 $s->{widget} = widget_conf;
 
 foreach my $pa ( @params ) {
 
  #$s->{$pa} = 
  #int ( $self->param( $pa ) // $s->{widget}->{strip}->{$pa.'_default'} );

  #$s->{$pa} < $s->{widget}->{strip}->{{$pa.'_default'} and
  #$s->{width} = $s->{widget}->{strip}->{width_default};
 
 }
 
  
 $s->{width} < $s->{widget}->{strip}->{width_min} and
  $s->{width} = $s->{widget}->{strip}->{width_default};

 $s->{width} > $s->{widget}->{strip}->{width_max} and
  $s->{width} = $s->{widget}->{strip}->{width_default};
 
 # target
 
 $s->{height} = 
  int ( $self->param( 'height' ) // $s->{widget}->{strip}->{height_default} );
  
 #$s->{height} < $w->{strip}->{height_min} and return $self->render_not_found;
 #$s->{height} > $w->{strip}->{heigth_max} and return $self->render_not_found; 

}

sub build_urlother {

 my $self = shift; my $s = $self->{stash};

 my $head = qq{/$s->{langaother}/$s->{action}};
 
 my $tail = $self->serialize;
 
 given ( $s->{runmode} ) {
 
  when ( 'pair' )  {
  
   $s->{trans} = $self->fetch ( 'map#trans', $s->{pri}, $s->{sec} );
      
   $s->{urlother} =
    $head . '?' . 'p=' . $s->{pri} . '&s=' . 
    $self->enurl ( $s->{trans} ) . "&$tail";
  
  }
  
  when ( 'search' ) {

   $s->{urlother} =
    $head . '?' . 'q=' . $self->enurl ( $s->{what} ) . "&$tail";
  
  }
  
  default { # default to all

   $s->{urlother} =
    length ( $tail ) > 0 ?
      $head . '?' . $tail :
      $head . '/';
   
  }
  
 }
 
 return 1;

}

sub build { # the widget builder

 my $self = shift; my $s = $self->{stash};
 
 $self->init or return $self->return_not_found;
  
 $s->{pri} = $self->param('p') // undef;
 $s->{sec} = $self->param('s') // undef;
 
 if ( $self->pair_ok ) {
 
  $s->{runmode} = 'pair';
  
  $self->pair_pre;
          
 } elsif ( $self->search_ok ( 'q', 'what' ) ) {
 
  $s->{runmode} = 'search';
    
 } else {
 
  $s->{runmode} = 'all'; # default to all
  
 }

 
 $self->build_urlother or return $self->render_not_found;

 $s->{width} = 500;
 $s->{height} = 500;
 
 my $target = $s->{url};
 
 $target =~ s|/build|/embed|;
 
 $s->{target} = $target;
 
 $self->render( template => 'page/build', format => 'html' );
 
}

sub embed { # the widget renderer

 my $self = shift; my $s = $self->{stash};
 
 my $w = widget_conf;
 
 # size
 
 $s->{width} = 
  int ( $self->param( 'width' ) // $w->{strip}->{width_default} );
  
# $s->{width} < $w->{strip}->{width_min} and return $self->render_not_found;
# $s->{width} > $w->{strip}->{width_max} and return $self->render_not_found;
 
 # target
 
 $s->{height} = 
  int ( $self->param( 'height' ) // $w->{strip}->{height_default} );
  
 #$s->{height} < $w->{strip}->{height_min} and return $self->render_not_found;
 #$s->{height} > $w->{strip}->{heigth_max} and return $self->render_not_found;
 
 my $n = 100;
 
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
 
 # fetch photo texts  
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
   
  $self->render( template => 'page/strip', format => 'html' );
  
}

sub style { $_[0]->render ( template => 'style/widget', format => 'css' ) }

1;