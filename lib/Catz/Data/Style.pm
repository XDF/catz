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
 
package Catz::Data::Style;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

use Catz::Util::Number qw ( round );

our @EXPORT = qw ( style_get style_html2dec );

my $style = {}; # style config

$style->{font} = 'Verdana, Arial, sans-serif';

$style->{roundness} = '8px';

$style->{size}->{normal} = 91;

$style->{size}->{tiny} = round ( $style->{size}->{normal} * 0.70 );
$style->{size}->{small} = round ( $style->{size}->{normal} * 0.86 );
$style->{size}->{big} = round ( $style->{size}->{normal} * 1.35 );
$style->{size}->{huge} = round ( $style->{size}->{normal} * 1.60 );

do { 
 $style->{size}->{$_} = $style->{size}->{$_} . '%';
} foreach ( keys %{ $style->{size} } );

$style->{space}->{x} = '0.5em';
$style->{space}->{y} = '0.8em';
 
$style->{lineh}->{normal} = 145;
$style->{lineh}->{medium} = round ( $style->{lineh}->{normal} * 1.04 );
$style->{lineh}->{large} = round ( $style->{lineh}->{normal} * 1.15 );

do { 
 $style->{lineh}->{$_} = $style->{lineh}->{$_} . '%';
} foreach ( keys %{ $style->{lineh} } ); 

$style->{color} = {

 #
 # The grayscale palettes of the system developed by Heikki Siltala
 #
 # back = the background of the screen
 # area1 = area separated from the background by color
 # area2 = area separated from the background by color
 # dim = to dim out a text, dimmer than regular text
 # text = color of the regular text
 # high = color of the highlighted text
 # xtra = the special color 
 #
  
 dark => {
  back => '#000000',
  shade => '#454545',
  dim => '#a3a3a3',
  text => '#cbcbcb', 
  high => '#ffffff',
  xtra => '#ff3333',
  field_front => '#000000',  
  field_back => '#FFFFFF',
  
 },
  
 neutral => {
  back => '#c7c7c7',
  shade => '#a2a2a2',
  dim => '#666666',
  text => '#1C1C1C', 
  high => '#000000',
  xtra => '#cc1515',
  field_front => '#000000',  
  field_back => '#FFFFFF', 
 },
  
 bright => {
  back => '#ffffff',
  shade => '#d3d3d3',
  dim => '#585858',
  text => '#1E1E1E', 
  high => '#000000',
  xtra => '#bb0909',
  field_front => '#000000',  
  field_back => '#FFFFFF', 
 }
  
};

$style->{viz}->{cover}->{width} = 180;
$style->{viz}->{cover}->{height} = 220;

$style->{viz}->{dist}->{width} = 180;
$style->{viz}->{dist}->{height} = 220;

$style->{viz}->{globe}->{width} = 300 ;
$style->{viz}->{globe}->{height} = 170 ;

$style->{viz}->{rank}->{width} = 200 ;
$style->{viz}->{rank}->{height} = 200 ;

sub style_get { $style }

sub style_html2dec {

 # convert html color to decimals
 
 my $html = shift;
 
 $html =~ m|^.(..)(..)(..)|;
 
 hex($1), hex($2), hex($3); 

}

1;