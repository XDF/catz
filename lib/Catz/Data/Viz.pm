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

our @EXPORT = qw ( viz_rank viz_ddist viz_globe viz_nat );

use Catz::Core::Conf;
use Catz::Data::Style;

use Catz::Util::Number qw ( fmt log2 round );
use Catz::Util::String qw ( enurl limit );

my $head = conf ( 'url_chart' ) . '?';

my $s = style_get;

sub calc {
 
 my $n = round ( ( 
  log2 ( $_[0] >= 1 ? $_[0] : 1 ) / log2 ( $_[1] > 1 ? $_[1] : 2 ) 
 ) * 100 );
 
 $n < 3 and return 3;
 
 return $n;

}

sub dis { (
 round ( ( ( $_[0] / $_[2] ) * 100 ), 1 ),
 round ( ( ( $_[1] / $_[2] ) * 100 ), 1 ),
 round ( ( ( ( $_[2] - $_[0] - $_[1] ) / $_[2] ) * 100 ), 1 ) 
) }

sub prep { 

 my $src = shift; 
 
 utf8::encode $src; 
 
 return enurl limit ( $src, 30 );
 
}

sub viz_rank {

 # creates URL for rank visualization
 
 my ( $lang, $t, $pri, $sec, $rank, $palette ) = @_;

 my $width = 200;
 my $height = 200;
    
 my $ctext = substr($s->{color}->{$palette}->{text},1);
 my $cback = substr($s->{color}->{$palette}->{back},1);
 my $chigh = substr($s->{color}->{$palette}->{high},1);
 my $cxtra = substr($s->{color}->{$palette}->{xtra},1);
 my $cdim = substr($s->{color}->{$palette}->{dim},1); 
 my $cshade = substr($s->{color}->{$palette}->{shade},1);
 
 # photos rank
 my $p = calc ( $rank->[0], $rank->[4] ); 
 
 # average photos rank
 my $pa = calc ( $rank->[2], $rank->[4] ); 

 # days rank
 my $d = calc ( $rank->[1], $rank->[5] ); 
 
 # average days rank
 my $da = calc ( $rank->[3], $rank->[5] );  
  
 my $tthis = prep $sec;
 
 my $tavg = prep $t->{VIZ_RANK_AVG}; 
 
 my $tlow = prep $t->{VIZ_RANK_LOW};
 
 my $thigh = prep $t->{VIZ_RANK_HIGH};

 my $title1 = "$t->{VIZ_RANK_PHOTO} $p/100 ($t->{VIZ_RANK_AV} $pa)";
 my $title2 = "$t->{VIZ_RANK_DAY} $d/100 ($t->{VIZ_RANK_AV} $da)";
     
 my $vurl = $head . ( join '&', (
  'cht=s', # chart type 
  'chs='.$width.'x'.$height, # chart dimensions
  "chd=t:$p,$pa|$d,$da", # the data 
  "chco=$chigh|$cshade", # data dot colors
  "chf=bg,s,$cback", # chart background
  'chg=20,20', # gridlines 
  "chdl=$tthis|$tavg", # labels
  'chdlp=b|l', # legend position (on bottom) and order 
  "chdls=$ctext,15.0", # legend text
  # low rank label placed on the canvas
  "chem=y;s=text_outline;d=$ctext,18,l,$cback,_,$tlow;po=0.02,0.02;py=-0.8".
  # high rank labelplaced on the canvas
  "|y;s=text_outline;d=$ctext,18,r,$cback,_,$thigh;po=0.99,0.90;py=-0.75"
 ) ); 
  
 [ 'rank', $vurl, $width, $height, $title1, $title2 ];
 
}

sub viz_ddist {

 # creates URL for data distribution
 
 my ( $lang, $t, $notext, $nocat, $total, $palette ) = @_;

 my $width = 180;
 my $height = 240;
    
 my $ctext = substr($s->{color}->{$palette}->{text},1);
 my $cback = substr($s->{color}->{$palette}->{back},1);
 my $chigh = substr($s->{color}->{$palette}->{high},1);
 my $cxtra = substr($s->{color}->{$palette}->{xtra},1);

 my $cdim = substr($s->{color}->{$palette}->{dim},1); 
 $palette eq 'dark' and
  $cdim = substr($s->{color}->{$palette}->{shade},1);

 my ( $none, $breed, $full ) = dis ( $notext, $nocat, $total );

 my $tfull = 
  prep "$t->{VIZ_DDIST_FULL} ".fmt($full,$lang).' %';
  
 my $tbreed = 
  prep "$t->{VIZ_DDIST_BREED} ".fmt($breed,$lang).' %'; 

 my $tnone = 
   prep "$t->{VIZ_DDIST_NONE} ".fmt($none,$lang).' %';
 
 my $vurl = $head . ( join '&', (
  'cht=p', # chart type 
  'chs='.$width.'x'.$height, # chart dimensions
  "chd=t:$full,$breed,$none", # the data 
  "chco=$cdim|$ctext|$cxtra", # data dot colors
  "chf=bg,s,$cback", # chart background
  "chdl=$tfull|$tbreed|$tnone", # labels
  'chdlp=b|l', # legend position (on bottom) and order 
  "chdls=$ctext,15.0" # legend text
 ) ); 

 [ 'ddist', $vurl, $width, $height, $full, $breed, $none ]

}

sub viz_globe {

 my ( $nats, $palette ) = @_;
 
 my $width = 300;
 my $height = 200;

 my $c0 = substr($s->{color}->{$palette}->{shade},1);
 my $c1 = substr($s->{color}->{$palette}->{xtra},1);
 my $cback = substr($s->{color}->{$palette}->{back},1);

 my $to = scalar @$nats - 1;

 my $cl = join '|', map { $c1 } ( 1 .. $to );

 my $vurl = $head . ( join '&', (
  'cht=map', # chart type 
  'chs='.$width.'x'.$height, # chart dimensions
  'chld='.(join '|',@$nats), # the countries to be shown 
  "chco=$c0|$cl", # colors
  "chf=bg,s,$cback" # chart background
 ) ); 

 [ 'globe', $vurl, $width, $height, $to + 1 ]

}

sub viz_nat {
 
 my ( $nat, $palette ) = @_;
 
 my $width = 200;
 my $height = 200;

 my $c0 = substr($s->{color}->{$palette}->{shade},1);
 my $c1 = substr($s->{color}->{$palette}->{xtra},1);
 my $cback = substr($s->{color}->{$palette}->{back},1);

 my $vurl = $head . ( join '&', (
  'cht=map', # chart type 
  'chs='.$width.'x'.$height, # chart dimensions
  "chld=$nat", # the countries to be shown 
  "chco=$c0|$c1", # colors
  "chf=bg,s,$cback" # chart background
 ) ); 

 [ 'nat', $vurl, $width, $height ]

}

1;


