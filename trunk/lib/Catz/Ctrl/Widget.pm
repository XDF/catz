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

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use List::Util qw ( shuffle );

use Catz::Data::Widget;

use constant SOFT => 0; # replace illegal parameter values with default value
use constant HARD => 1; # raise an error on illegal parameter value

sub params {

 # verify / process widget parameters
 
 my ( $self, $hard ) = @_; my $s = $self->{stash};

 # pass to widget module for the work
 widget_init ( $self, $hard ) or return 0;
 
 return 1;

}

sub build_urlother {

 my $self = shift; my $s = $self->{stash};

 my $head = qq{/$s->{langaother}/$s->{action}};
 
 my $tail = widget_ser ( $self );
 
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

 my ( $self, $hard ) = @_; my $s = $self->{stash};
 
 $self->init or return 0;
 
 $s->{n_estim} = 30;
  
 $s->{pri} = $self->param('p') // undef;
 $s->{sec} = $self->param('s') // undef;
 
 if ( $self->pair_ok ) {
 
  $s->{runmode} = 'pair';
  
  $self->pair_pre ( 'widget' ) or return 0;
  
  $s->{total} = $self->fetch ( 'pair#count', @{ $s->{args_array} } ); 
          
 } elsif ( $self->search_ok ( 'q', 'what' ) ) {
 
  $s->{runmode} = 'search';
  
  $s->{total} = $self->fetch ( 'search#count', @{ $s->{args_array} } ); 
    
 } else {
 
  $s->{runmode} = 'all'; # default to all
  
  $s->{total} = $self->fetch ( 'all#count' );
  
 }

 $s->{total} == 0 and return 0;

 $self->params or return 0;
 
}

sub build { # the widget builder

 my $self = shift; my $s = $self->{stash};

 $self->start ( SOFT ) or return $self->render_not_found;

 $self->build_urlother or return $self->render_not_found;
 
 # we omit the first slash, it will be added in template
 $s->{urltarget} = $s->{lang} . '/embed?' . widget_ser ( $s );
  
 $self->render( template => 'page/build', format => 'html' );
 
}

sub embed { # the widget renderer

 my $self = shift; my $s = $self->{stash};
  
 $self->start ( HARD ) or return $self->render_not_found;
 
 if ( $s->{runmode} eq 'pair' ) {

  $self->pair_pre;
  
   $s->{xs} = $self->fetch ( 'pair#array_rand_n', @{ $s->{args_array} }, $s->{n_estim} ); 
          
 } elsif ( $s->{runmode} eq 'search' ) {
  
  $s->{xs} = $self->fetch ( 'search#array_rand_n', @{ $s->{args_array} }, $s->{n_estim} ); 
    
 } else {
  
  $s->{xs} = $self->fetch ( 'all#array_rand_n', $s->{n_estim} );
  
 }

 scalar @{ $s->{xs} } == 0 and return 0; 
  
 # fetch corresponding thumbnails 
 ( $s->{thumbs}, undef, undef ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };

 # reshuffle
 $s->{thumbs} = [ shuffle @{  $s->{thumbs} } ];
  
 my $im = 
  widget_stripe ( 
   map { $s->{ $_ } } qw ( thumbs run size limit mark ) 
  );  
   
 $self->render_data ( $im , format => 'jpeg' );
  
}

sub contact {

 my $self = shift; my $s = $self->{stash};
   
 length $s->{langa} > 2 and return $self->fail ( 'setup set so stopping' );
  
 my $im = widget_plate (
  $s->{t}->{MAILTO_TEXT}, $s->{palette}, $s->{intent}
 );

 $self->render_data ( $im , format => 'png' );

}

1;