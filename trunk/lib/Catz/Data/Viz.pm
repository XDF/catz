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

package Catz::Data::Viz;

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( viz_rank );

use Catz::Core::Conf;
use Catz::Data::Style;

use Catz::Util::Number qw ( log2 round );
use Catz::Util::String qw ( enurl );

my $head = conf ( 'url_chart' ) . '?';

my $s = style_get;

sub viz_rank {

 # creates URL for rank visualization
 
 my ( $t, $pri, $sec, $rank, $palette ) = @_;
  
 my $width = 350;
 my $height = 250;
 
 my $ctext = substr($s->{color}->{$palette}->{text},1);
 my $cback = substr($s->{color}->{$palette}->{back},1);
 my $cxtra = substr($s->{color}->{$palette}->{xtra},1);
 my $cdim = substr($s->{color}->{$palette}->{dim},1);
 
 my $p = round ( ( 
  log2 ( $rank->[0] >= 1 ? $rank->[0] : 1 ) / 
  log2 ( $rank->[2] > 1 ? $rank->[2] : 2 ) 
 ) * 100 );
 
 $p < 3 and $p = 3;

 my $pa = round ( ( 
  log2 ( $rank->[1] >= 1 ? $rank->[1] : 1 ) / 
  log2 ( $rank->[2] > 1 ? $rank->[2] : 2 ) 
 ) * 100 ); 
 
 my $d = round ( ( 
  log2 ( $rank->[3] >= 1 ? $rank->[3] : 1 ) / 
  log2 ( $rank->[5] > 1 ? $rank->[5] : 2 ) 
 ) * 100 );

 $d < 3 and $d = 3;

 my $da = round ( ( 
  log2 ( $rank->[4] >= 1 ? $rank->[4] : 1 ) / 
  log2 ( $rank->[5] > 1 ? $rank->[5] : 2 ) 
 ) * 100 );
 
 my $tmain =  $t->{uc($pri).'G'} . ' ' . $t->{VIZ_RANK_NAME};
 utf8::encode $tmain; $tmain = enurl $tmain;

 my $tthis = $t->{VIZ_RANK_THIS}.' '.$t->{uc($pri)};
 utf8::encode $tthis; $tthis = enurl $tthis;
 
 my $tavg = $t->{VIZ_RANK_AVG}.' '.$t->{uc($pri)}; 
 utf8::encode $tavg; $tavg = enurl $tavg;
 
 my $tlow = $t->{VIZ_RANK_LOW};
 utf8::encode $tlow; $tlow = enurl $tlow;
 
 my $thigh = $t->{VIZ_RANK_HIGH};
 utf8::encode $thigh; $thigh = enurl $thigh;
     
 my $vurl = $head . ( join '&', (
  'cht=s', # chart type 
  'chs='.$width.'x'.$height, # chart dimensions
  "chtt=$tmain", # chart main title 
  "chts=$ctext,18,c", # chart main title layout
  "chd=t:$p,$pa|$d,$da", # the data 
  "chco=$cxtra|$cdim", # data dot colors
  "chf=bg,s,$cback".'00', # chart background
  'chg=20,20', 
  "chdl=$tthis|$tavg",
  'chdlp=bv', # legend position (on bottom vertically) 
  "chdls=$ctext,15.0",
  "chem=y;s=text_outline;d=$ctext,18,l,$cback,_,$tlow;po=0.02,0.02;py=-0.8|y;s=text_outline;d=$ctext,18,r,$cback,_,$thigh;po=0.99,0.88;py=-0.75"
 ) ); 
 
 
 
 return [ $vurl, $width, $height ];
 
}

1;

