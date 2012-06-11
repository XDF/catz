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

package Catz::Ctrl::Visualize;

use 5.14.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use Catz::Data::Conf;
use Catz::Data::Dist;
use Catz::Data::Style;

sub do {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ style } = style_get;

 # special mode to get json map url instead of the image url
 my $jmap = $self->param ( 'jmap' ) // 0;
 
 # if we make HTTP call on server then we always 
 # use http instead of https 
 $s->{ charturl } = $jmap ? 
  conf ( "url_chart" ) :
  conf ( "url_chart" );

 my $vurl = $self->render (
  "viz/$s->{action}",
  format  => 'txt',
  partial => 1,
  jmap    => $jmap
 );

 if ( $jmap ) {

  # this is a pseudo parameter passed to the model that contains the
  # current dt down to hours, so this parameter changes in every
  # hour and this makes cached model data live at most one hour
  my $pseudo = substr ( $self->dt, 0, -4 );

  # so in case that data loading fails the failed data gets cleared
  # from the cache within a reasonable time
  
  # 2012-01-30
  # using "$vurl" instead of $vurl to force it to be scalar
  # fixed Can't use a Mojo::ByteStream object as a URI at ...
  
  my $json = $self->fetch ( 'net#get', "$vurl", $pseudo ) // '';

  length ( $json ) > 15 or return $self->fail ( '3rd party request failed' );

  # we return text content type on purpose

  return $self->render_text ( text => $json, format => 'text' );

 }
 else {

  return $self->moveto ( $vurl );

 }

} ## end sub do

sub dist {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ dist } = dist_conf;

 dist_prep $s;

 return $self->do;

}

sub globe {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ nats } = $self->fetch ( 'related#nats' );

 return $self->do;

}

sub rank {

 my $self = shift;
 my $s    = $self->{ stash };

 $self->fetch ( 'pair#verify', $s->{ pri } )
  or return $self->fail ( 'illegal concept' );

 $s->{ sec } = $self->decode ( $s->{ sec } );    # using decode helper

 $s->{ total } = $self->fetch ( 'pair#count', $s->{ pri }, $s->{ sec } );

 $s->{ total } == 0 and return $self->fail ( 'no data' );

 $s->{ rank } = $self->fetch ( 'related#rank', $s->{ pri }, $s->{ sec } );

 $s->{ ranks } = $self->fetch ( 'related#ranks', $s->{ pri } );

 return $self->do;

} ## end sub rank

1;
