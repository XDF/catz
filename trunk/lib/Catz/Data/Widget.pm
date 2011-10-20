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
 
package Catz::Data::Widget;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( widget_conf widget_strip widget_tn_est );

use List::MoreUtils qw ( any );

use Catz::Util::Number qw ( round );

my $widget = {}; # widget config

# defines what widgets are available
$widget->{widgets} = [ qw ( strip ) ];

$widget->{strip}->{width_min} = 50;
$widget->{strip}->{width_default} = 800;
$widget->{strip}->{width_max} = 2000;

$widget->{strip}->{height_min} = 50;
$widget->{strip}->{height_default} = 200;
$widget->{strip}->{height_max} = 200;

sub widget_conf { $widget }

sub widget_tn_est {

 my ( $widht, $height ) = @_;
 
 # the safe (= far too large) estimate of the needed thumbnails

 return 100;

}

sub widget_strip {

 my ( $thumbs, $type, $size, $limit, $width, $height ) = @_;
   
 my $use = -1; my $curr = 0; my @widths = (); my @heights = ();
 
 foreach my $th ( @{ $thumbs } ) {
 
  my ( $width, $height );
  
  if ( $type eq 'topdown' ) {
 
   $width = $size;
   $height = round ( $th->[6] * ( $size / $th->[5] ) );
      
   } else {
  
   $width = round ( ( $size / $th->[6] ) * $th->[5] );
   $height = $size;
   
  } 
  
  if ( 
   ( $type eq 'topdown' and ( $curr + $height < $limit ) )
    or ( $type ne 'topdown' and  ( $curr + $width < $limit ) ) 
  ) { 
 
   push @widths, $width;  
   push @heights, $height;
   
   if ( $type eq 'topdown' ) { $curr += $height } else { $curr += $width } 
   
   $use++;
   
   
  }
 
 }
  
 my $gd;
   
 if ( $type eq 'topdown' ) {
 
  $gd = new GD::Image( $size, $curr, 1 ); # 1 = TrueColor 
 
 } else {
  
  $gd = new GD::Image( $curr, $size, 1 ); # 1 = TrueColor
  
 } 
 
 
 my $currx = 0; my $curry = 0;
  
 foreach my $i ( 0 .. $use ) {
 
  my $nd = newFromJpeg GD::Image( 
   "/catz/static/photo/$thumbs->[$i]->[3]/$thumbs->[$i]->[4]", 1 
  );
  
  $gd->copyResampled ( 
   $nd, $currx, $curry, 0, 0, $widths[$i], $heights[$i],
   $thumbs->[$i]->[5], $thumbs->[$i]->[6]
  );

  if ( $type eq 'topdown' ) { $curry +=  $heights[$i] } 
   else { $currx +=  $widths[$i] } 

 }
       
 return $gd->jpeg(95);

}


1;