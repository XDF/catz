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

our @EXPORT = qw ( widget_conf widget_init widget_ser widget_params widget_stripe );

use GD;
use List::MoreUtils qw ( any );

use Catz::Core::Text;

use Catz::Util::Number qw ( round );
use Catz::Util::String qw ( enurl );
use Catz::Util::Time qw ( dtlang );

my $widget = {}; # widget config

my $t = text ( 'en' );

$widget->{params} = [ qw ( type run size limit mark back ) ];

$widget->{defaults} = {
 type => 'stripe',
 run => 'leftright',
 size => 100,
 limit => 600,
 mark => 'yes',
 back => 'yes',
};

$widget->{limits} = {
 size => { min => 50, max => 200 },
 limit => { min => 200, max => 2000 },
};

$widget->{allowed} = {
 type => [ qw ( strip ) ],
 run => [ qw ( leftright topdown ) ],
 mark => [ qw ( yes no ) ],
 back => [ qw ( yes no ) ], 
};

sub widget_conf { $widget }

sub widget_params { @{ $widget->{params} } }

sub widget_init {

 my ( $app, $hard ) = @_; my $s = $app->{stash};
 
 $s->{widget} = $widget;
 
 foreach my $par ( @{ $widget->{params} } ) {
 
  $s->{ $par } = $app->param ( $par ) // undef;
 
  defined $s->{ $par } or do {
   $hard and return 0; 
   $s->{$par} = $widget->{defaults}->{ $par };
  };

  if ( exists $widget->{limits}->{ $par } ) {
    
   ( 
    $s->{ $par } =~ m|^\d{1,4}$| and
    $s->{ $par } >= $widget->{limits}->{ $par }->{min} and
    $s->{ $par } <= $widget->{limits}->{ $par }->{max} 
   ) or do { 
    $hard and return 0; $s->{$par} = $widget->{defaults}->{ $par } 
   }; 
  
  } elsif ( exists $widget->{allowed}->{ $par } ) {
  
   ( any { $s->{$par} eq $_ } @{  $widget->{allowed}->{ $par } } )
    or do {
     $hard and return 0; 
     $s->{$par} = $widget->{defaults}->{ $par };
    };
  
  } else { die "interal error: not enough information for parameter '$par'" }
  
 }
 
 return 1;

}

sub widget_ser {

 my $s = shift; # Mojolicious stash
 
 my $out;
 
 my @coll = ();
 
 if ( $s->{runmode} eq 'pair' ) {
 
  push @coll, 'p=' . $s->{pri};  
  push @coll, 's=' . enurl $s->{sec}; 
 
 } elsif ( $s->{runmode} eq 'search' ) {
 
  push @coll, 'q=' . enurl $s->{what};
  
 }

 foreach my $par ( @{ $widget->{params} } ) {
 
  my $val = $widget->{defaults}->{ $par };

  defined $s->{ $par } and $val = $s->{ $par };

  push @coll, "$par=" . enurl $val; 
 
 }

 return join '&', @coll;

}

sub widget_tn_est {

 my ( $widht, $height ) = @_;
 
 # the safe (= far too large) estimate of the needed thumbnails

 return 100;

}

sub widget_stripe {

 use Time::HiRes qw ( time );
 
 my $time_start = time();

 my ( $thumbs, $run, $size, $limit, $mark ) = @_;
   
 my $use = -1; my $curr = 0; my @widths = (); my @heights = ();
 
 foreach my $th ( @{ $thumbs } ) {
 
  my ( $width, $height );
  
  if ( $run eq 'topdown' ) {
 
   $width = $size;
   $height = round ( $th->[6] * ( $size / $th->[5] ) );
      
   } else {
  
   $width = round ( ( $size / $th->[6] ) * $th->[5] );
   $height = $size;
   
  } 
  
  if ( 
   ( $run eq 'topdown' and ( $curr + $height < $limit ) )
    or ( $run ne 'topdown' and  ( $curr + $width < $limit ) ) 
  ) { 
 
   push @widths, $width;  
   push @heights, $height;
   
   if ( $run eq 'topdown' ) { $curr += $height } else { $curr += $width } 
   
   $use++;
   
   
  }
 
 }
  
 my $gd =
  $run eq 'topdown' ?
  new GD::Image( $size, $curr, 1 ) : 
  new GD::Image( $curr, $size, 1 ); 
  # 1 = TrueColor
   
 my $currx = 0; my $curry = 0;
  
 foreach my $i ( 0 .. $use ) {
 
 #
 # we use a relative path here
 #
 # due to the fact that the directory structure is fixed
 # in all environments this appers to work without hassle
 #
 
  my $nd = newFromJpeg GD::Image ( 
   "../../static/photo/$thumbs->[$i]->[3]/$thumbs->[$i]->[4]", 1 
  );
  
  $gd->copyResampled ( 
   $nd, $currx, $curry, 0, 0, $widths[$i], $heights[$i],
   $thumbs->[$i]->[5], $thumbs->[$i]->[6]
  );

  if ( $run eq 'topdown' ) { $curry +=  $heights[$i] } 
   else { $currx +=  $widths[$i] } 

 }
         
 my $gdd = $gd->jpeg(95);
   
 my $time_end = time();
 
 my $timing = round ( 
 ( ( $time_end - $time_start  ) * 1000 ), 0 
 ) . ' ms';
 
 warn $timing;
  
 return $gdd;

}


1;