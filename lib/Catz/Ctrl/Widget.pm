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

my @params = qw ( run height limit stripes align );

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
 # pass to widget module for the work
 
 my $self = shift; my $s = $self->{stash};

 widget_init ( $self ); 
 
 return 1;

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

sub start  {

 my $self = shift; my $s = $self->{stash};
 
 $self->init or return 0;
 
 $s->{n_estim} = 10;
  
 $s->{pri} = $self->param('p') // undef;
 $s->{sec} = $self->param('s') // undef;
 
 if ( $self->pair_ok ) {
 
  $s->{runmode} = 'pair';
  
  $self->pair_pre;
  
  $s->{total} = $self->fetch ( 'pair#count', @{ $s->{args_array} ); 
          
 } elsif ( $self->search_ok ( 'q', 'what' ) ) {
 
  $s->{runmode} = 'search';
  
  $s->{total} = $self->fetch ( 'search#count', @{ $s->{args_array} ); 
    
 } else {
 
  $s->{runmode} = 'all'; # default to all
  
  $s->{total} = $self->fetch ( 'all#count' );
  
 }

 $s->{total} == 0 and return 0;

 $self->params or return 0;
 
}

sub build { # the widget builder

 my $self = shift; my $s = $self->{stash};

 $self->start or $self->return_not_found;

 $self->build_urlother or return $self->render_not_found;
 
 # we omit the first slash, it will be added in template
 my $target = $s->{lang} . '/embed?' . widget_ser ( $s );
 
 $s->{target} = $target;
 
 $self->render( template => 'page/build', format => 'html' );
 
}

sub solver {

 my $self = shift; my $s = $self->{stash};
 
 


}

sub embed { # the widget renderer

 
 $self->start or return $self->return_not_found;
 
 given ( $s->{runmode} )

 if ( $self->pair_ok ) {
 
  $s->{runmode} = 'pair';
  
  $self->pair_pre;
  
   $s->{xs} = $self->fetch ( 'pair#array_rand_n', @{ $s->{args_array} }, $s->{n_estim} ); 
          
 } elsif ( $self->search_ok ( 'q', 'what' ) ) {
 
  $s->{runmode} = 'search';
  
  $s->{xs} = $self->fetch ( 'search#array_rand_n', @{ $s->{args_array} }, $s->{n_estim} ); 
    
 } else {
 
  $s->{runmode} = 'all'; # default to all
  
  $s->{xs} = $self->fetch ( 'all#array_rand_n', $s->{n_estim} );
  
 }

 scalar @{ $s->{xs} } == 0 and return 0; 
 # resuffle data 
 $s->{xs} = [ shuffle @{ $s->{xs} } ];
  
 # fetch corresponding thumbnails 
 ( $s->{thumbs}, undef, undef ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };
 
 # fetch photo texts  
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
   
 $self->render( template => 'page/strip', format => 'html' );
  
}

sub style { $_[0]->render ( template => 'style/widget', format => 'css' ) }

1;