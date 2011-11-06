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

use 5.12.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw (
 widget_conf widget_init widget_ser widget_params widget_stripe widget_plate
);

use GD;
use List::MoreUtils qw ( any );

use Catz::Data::Style;
use Catz::Data::Text;

use Catz::Util::Number qw ( round );
use Catz::Util::String qw ( enurl );
use Catz::Util::Time qw ( dtlang );

my $widget = {}; # widget config

my $t = text ( 'en' );

$widget->{params} = [ qw ( type run size limit back ) ];

$widget->{defaults} = {
 type => 'stripe',
 run => 'leftright',
 size => 100,
 limit => 600,
 back => 'yes',
};

$widget->{limits} = {
 size => { min => 50, max => 200 },
 limit => { min => 200, max => 2000 },
};

$widget->{allowed} = {
 type => [ qw ( stripe ) ],
 run => [ qw ( leftright topdown ) ],
 back => [ qw ( yes no ) ], 
};

sub widget_conf { $widget }

sub widget_params { @{ $widget->{params} } }

sub widget_init {

 my ( $app, $strict ) = @_; my $s = $app->{stash};
 
 $s->{widget} = $widget;
 
 foreach my $par ( @{ $widget->{params} } ) {

  # embed mode = image rendering doesn't reguire back parameter
  $s->{action} eq 'embed' and $par eq 'back' and goto SKIP_THIS;
 
  $s->{ $par } = $app->param ( $par ) // undef;
 
  defined $s->{ $par } or do {
   $strict and return 0; 
   $s->{$par} = $widget->{defaults}->{ $par };
  };

  if ( exists $widget->{limits}->{ $par } ) {
    
   ( 
    $s->{ $par } =~ m|^\d{1,4}$| and
    $s->{ $par } >= $widget->{limits}->{ $par }->{min} and
    $s->{ $par } <= $widget->{limits}->{ $par }->{max} 
   ) or do { 
    $strict and return 0; $s->{$par} = $widget->{defaults}->{ $par } 
   }; 
  
  } elsif ( exists $widget->{allowed}->{ $par } ) {
  
   ( any { $s->{$par} eq $_ } @{  $widget->{allowed}->{ $par } } )
    or do {
     $strict and return 0; 
     $s->{$par} = $widget->{defaults}->{ $par };
    };
  
  } else { die "interal error: not enough information for parameter '$par'" }
  
  SKIP_THIS:
  
 }
 
 return 1;

}

sub widget_ser {

 my ( $s, $intent ) = @_;
 
 my @coll = ();
 
 if ( $s->{runmode} eq 'pair' ) {
 
  push @coll, 'p=' . $s->{pri};  
  push @coll, 's=' . enurl $s->{sec}; 
 
 } elsif ( $s->{runmode} eq 'search' ) {
 
  push @coll, 'q=' . enurl $s->{what};
  
 }
 
 $intent eq 'entry' and goto SKIP_PARAMS;
 
 foreach my $par ( @{ $widget->{params} } ) {
 
  my $val = $widget->{defaults}->{ $par };

  defined $s->{ $par } and $val = $s->{ $par };
  
  $intent eq 'embed' and ( $par ne 'back' ) and  
   push @coll, "$par=" . enurl $val; 
 
 }
 
 SKIP_PARAMS:
 
 return join '&', @coll;

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

my $plate = {

 width_contrib => 129,
 width_margin => 115,
 width_missing => 115,
 
 height_contrib => 22,
 height_margin => 18,
 height_missing => 18,
 
 x_contrib => 2,
 x_margin => 0,
 x_missing => 1,
 
 y_contrib => 2,
 y_margin => 0,
 y_missing => 1,
 
 font_contrib => gdGiantFont,
 font_margin => gdLargeFont,
 font_missing => gdLargeFont,
 
};

my $plate_width = 129;
my $plate_height = 22;

sub widget_plate {

 my ( $text, $palette, $intent ) = @_;
 
 my $style = style_get;
 
 my @front = style_html2dec $style->{color}->{$palette}->{text};
    
 my @back = $intent eq 'margin' ?
   style_html2dec $style->{color}->{$palette}->{shade} 
 : style_html2dec $style->{color}->{$palette}->{back};

  
 my $im = new GD::Image ( 
  $plate->{'width_'.$intent}, $plate->{'height_'.$intent} 
 );
  
 my $c_front = $im->colorAllocate ( @front ); 
 
 my $c_back = $im->colorAllocate ( @back );
 
 $im->filledRectangle ( 
  0, 0, $plate->{'width_'.$intent}, $plate->{'height_'.$intent}, $c_back 
 );
 
 $im->string( 
  $plate->{'font_'.$intent},
  $plate->{'x_'.$intent}, $plate->{'y_'.$intent},
  $text, $c_front 
 );
 
 $im->png;
 
}

1;