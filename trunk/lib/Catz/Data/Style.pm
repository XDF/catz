#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2012 Heikki Siltala
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

use 5.14.2;
use strict;
use warnings;

use parent 'Exporter';

use Const::Fast;

use Catz::Util::Number qw ( round );

our @EXPORT = qw ( style_get style_html2dec );

const my $SIZE_BASE => 91;
const my $LINE_BASE => 139;

const my $STYLE => {

 font => 'Verdana, Arial, sans-serif',

 roundness => '8px',

 size => {
  normal => $SIZE_BASE . '%',
  tiny   => round ( $SIZE_BASE * 0.70 ) . '%',
  small  => round ( $SIZE_BASE * 0.86 ) . '%',
  big    => round ( $SIZE_BASE * 1.39 ) . '%',
  huge   => round ( $SIZE_BASE * 1.64 ) . '%',
 },

 space => { x => '0.5em', y => '0.8em' },

 lineh => {
  normal => $LINE_BASE . '%',
  medium => round ( $LINE_BASE * 1.04 ) . '%',
  large  => round ( $LINE_BASE * 1.15 ) . '%',
 },

 color => {

  #
  # The grayscale palettes design by Heikki Siltala
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
   back        => '#000000',
   shade       => '#454545',
   dim         => '#a3a3a3',
   text        => '#cbcbcb',
   high        => '#ffffff',
   xtra        => '#ff3333',
   field_front => '#000000',
   field_back  => '#FFFFFF',
  },

  neutral => {
   back        => '#c7c7c7',
   shade       => '#a2a2a2',
   dim         => '#666666',
   text        => '#1C1C1C',
   high        => '#000000',
   xtra        => '#cc1515',
   field_front => '#000000',
   field_back  => '#FFFFFF',
  },

  bright => {
   back        => '#ffffff',
   shade       => '#d3d3d3',
   dim         => '#585858',
   text        => '#1E1E1E',
   high        => '#000000',
   xtra        => '#bb0909',
   field_front => '#000000',
   field_back  => '#FFFFFF',
   }

 },
 viz => {
  dist  => { width => 190, height => 240 },
  globe => { width => 270, height => 153 },
  rank  => { width => 200, height => 200 },
  }

};

sub style_get { $STYLE }

sub style_html2dec {

 # convert html color to decimals

 my $htmlc = shift;

 $htmlc =~ m|^.(..)(..)(..)|;

 hex ( $1 ), hex ( $3 ), hex ( $3 );

}

1;
