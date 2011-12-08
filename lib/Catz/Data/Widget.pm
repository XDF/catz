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

our @EXPORT = qw ( widget_conf widget_default widget_verify widget_plate );

use GD;
use List::MoreUtils qw ( any );

use Catz::Data::Style;
use Catz::Data::Text;

use Catz::Util::Number qw ( round );
use Catz::Util::String qw ( enurl );
use Catz::Util::Time qw ( dtlang );

# widget short and long keys as pairs in a single array
my $wpairs = [ qw ( t type c choose a align f float l limit s size g gap ) ];

# extract short and long keys and
# create short -> long and long -> short translations

my $wshorts = []; my $wlongs = [];  my $wtrans = {}; 

foreach ( my $i = 0; $i < scalar @{ $wpairs }; $i += 2 ) {

 push @{ $wshorts }, $wpairs->[ $i ];
 push @{ $wlongs }, $wpairs->[ $i + 1 ];

 $wtrans->{ $wpairs->[ $i ] } = $wpairs->[ $i + 1 ]; 
 $wtrans->{ $wpairs->[ $i + 1 ] } = $wpairs->[ $i ];

}

# widget setup configuration as a single hashref

my $wconf = {

 shorts => $wshorts,
 longs => $wlongs,
 trans => $wtrans,
 
 defaults => 
  { t => 1, c => 2, a => 1, f => 1, l => 1000, s => 100, g => 0},
 
 values => {
  type => [ 1 ],
  choose => [ 1, 2, 3 ],
  align => [ 1, 2 ],
  float => [ 1, 2, 3 ],
  limit => [ map { 300 + ( $_ * 100 ) } ( 1 .. 17 ) ],
  size => [ map { $_ * 10 } ( 5 .. 20 ) ],
  gap => [ 0, 2, 4, 6, 8, 10 ],
 },

};

# prepare the default setup string

my $wdefault = 
 join '', map { $_.$wconf->{defaults}->{$_} } @{ $wconf->{shorts} };
   
sub widget_conf { $wconf }

sub widget_verify { 

 my $wspec = shift;
   
 my $wrun = {}; # target
   
 length $wspec > 500 and return undef;
 
 my @wc = split /([a-z])/, $wspec;
 
 # the first value is undef, remove it
 shift @wc; 
 
 # must be key-value pairs   
 ( scalar @wc % 2 ) == 0 or return undef; 
 
 for ( my $i = 0; $i < scalar @wc; $i += 2 ) {
  
  defined $wc[ $i ] or return undef;
  defined $wc[ $i+1 ] or return undef;
  
  ( my $key = $wconf->{trans}->{ $wc[ $i ] } // undef ) or return undef;
 
  ( any { $_ eq $wc[ $i + 1 ] } @{ $wconf->{values}->{$key} } )
   or return undef;
     
  $wrun->{$key} = $wc[ $i + 1 ];
   
 }

 do { exists $wrun->{ $_ } or return undef } foreach @{ $wconf->{longs} };
  
 return $wrun;
 
}

sub widget_default { $wdefault }

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