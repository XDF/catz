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

our @EXPORT = qw ( style_get );

my $style = {}; # style config

$style->{font} = 'Verdana, Arial, sans-serif';

$style->{size}->{normal} = 92;

$style->{size}->{tiny} = round ( $style->{size}->{normal} * 0.70 );
$style->{size}->{small} = round ( $style->{size}->{normal} * 0.86 );
$style->{size}->{big} = round ( $style->{size}->{normal} * 1.35 );
$style->{size}->{huge} = round ( $style->{size}->{normal} * 1.85 );

do { 
 $style->{size}->{$_} = $style->{size}->{$_} . '%';
} foreach ( keys %{ $style->{size} } ); 

$style->{lineh}->{normal} = 145;
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
  area1 => '#444444',
  area2 => '#686868',
  dim => '#a3a3a3',
  text => '#c4c4c4', 
  high => '#ffffff',
  xtra => '#ff3333',
 },
  
 neutral => {
  back => '#b5b5b5',
  area1 => '#c1c1c1',
  area2 => '#d4d4d4',
  dim => '#666666',
  text => '#444444', 
  high => '#000000',
  xtra => '#cc1515', 
 },
  
 bright => {
  back => '#ffffff',
  area1 => '#c8c8c8',
  area2 => '#e2e2e2',
  dim => '#585858',
  text => '#444444', 
  high => '#000000',
  xtra => '#bb0909', 
 }
  
};

sub style_get { $style }

1;