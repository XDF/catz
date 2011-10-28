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

package Catz::Ctrl::Visualize;

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use Catz::Data::Conf;
use Catz::Data::Dist;
use Catz::Data::Style;

sub do {

 my $self = shift; my $s = $self->{stash};

 $s->{style} = style_get ( $s->{palette} ); 

 $s->{charturl} = conf ( 'url_chart' );
 
 # special mode to get json map url instead of the image url
 my $jmap = $self->param ( 'jmap' ) // 0;

 my $vurl = $self->render ( 
  "viz/$s->{action}", format => 'txt', partial => 1, jmap => $jmap 
 );
 
 $jmap and return $self->render_text ( text => $vurl, format => 'text' );
 
 return $self->moveto ( $vurl );
 
}

sub dist {

 my $self = shift; my $s = $self->{stash};

 $s->{total} = $s->{full} + $s->{breed} + $s->{cate} + $s->{none};

 $s->{maxx} = $self->fetch ( 'all#maxx' );

 # the total number of photos must be less or equal to all photos
 $s->{total} <= $s->{maxx} or return $self->fail (
  [ 'distribution values mismatch', 'epäsopivat jakauman arvot' ]
 );
 
 $s->{dist} = dist_conf;
 
 foreach my $key ( @{ $s->{dist}->{keyspie} } ) {
  
  $s->{ $key . '_perc' } = $self->round ( ( 
   ( $s->{ $key } / $s->{total} ) * 100
   ), 1 );
 
  $s->{ $key . '_label' } = $self->enurl (
   $s->{t}->{ 'VIZ_DIST_' . uc ( $key ) } . ' ' .
   $self->fmt ( $s->{ $key . '_perc' }, $s->{lang} )
  );
   
 }
  
 return $self->do;
 
}

sub globe {

 my $self = shift; my $s = $self->{stash};
 
 $s->{nats} = $self->fetch ( 'related#nats' );
 
 return $self->do;

}

sub rank {

 my $self = shift; my $s = $self->{stash};

 $self->fetch( 'pair#verify',$s->{pri} ) or return $self->fail (
  [ 'the concept given is unknown', 'annettu aihe on tuntematon' ]
 );
 $s->{sec} = $self->decode ( $s->{sec} ); # using decode helper
 
 $s->{total} = $self->fetch ( 'pair#count', $s->{pri}, $s->{sec} );

 $s->{total} == 0 and return $self->fail (
  [ 'photo count is zero', 'kuvien määrä on nolla' ]
 );
 
 $s->{rank} = $self->fetch ( 'related#rank', $s->{pri}, $s->{sec} );
 
 $s->{ranks} = $self->fetch ( 'related#ranks', $s->{pri} );
  
 return $self->do;
 
}

1;

