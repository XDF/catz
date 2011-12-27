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

package Catz::Ctrl::More;

use 5.12.0;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use Catz::Data::Conf;
use Catz::Data::Search;
use Catz::Data::Style;

sub contrib {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ topic } = 'contrib';
 
 $s->{ meta_follow } = 0; # links not followed

 $self->f_init or return $self->fail ( 'f_init exit' );

 $self->f_dist or return $self->fail ( 'dist exit' );

 $s->{ style } = style_get;

 $s->{ breeds } = $self->fetch ( 'related#breeds' );

 foreach my $breed ( @{ $s->{ breeds } } ) {

  $s->{ 'dist_url_' . $breed } = $self->fuseq (
   $s->{ langa },
   (
    'search?q='
     . $self->enurl (
     args2search ( @{ $s->{ dist }->{ slices }->{ nocat } }, '+breed',
      $breed )
     )
   )
  );

 }

 $s->{ cates } = $self->fetch ( 'related#cates' );

 foreach my $cate ( @{ $s->{ cates } } ) {

  $s->{ 'dist_url_' . $cate->[ 0 ] } = $self->fuseq (
   $s->{ langa },
   (
    'search?q='
     . $self->enurl (
     args2search ( @{ $s->{ dist }->{ slices }->{ nocat } }, '+cate',
      $cate->[ 0 ] )
     )
   )
  );

 }

 $self->common;

} ## end sub contrib

sub quality {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ topic } = 'quality';
 
 $s->{ meta_follow } = 0; # links not followed

 $self->f_init or return $self->fail ( 'f_init exit' );

 foreach my $item ( qw ( dt stat detail ) ) {

  my $data = $self->fetch ( "bulk#qa$item" ) // undef;

  defined $data
   or return $self->fail (
   'unable to provide quality report since there is no stored quality data' );

  $s->{ "qa$item" } = $data

 }

 $s->{ lastdata } = $self->dtexpand ( $s->{ version }, $s->{ lang } );
 $s->{ lastqa }   = $self->dtexpand ( $s->{ qadt },    $s->{ lang } );

 my $lastdata = $self->dt2epoch ( $s->{ version } );
 my $lastqa   = $self->dt2epoch ( $s->{ qadt } );

 my $secs = $lastdata - $lastqa;

 my @diff = $self->s2dhms ( $secs );

 $s->{ diffdt } = '';

 foreach my $spec ( qw ( day hour minute second ) ) {

  my $this = shift @diff;

  if ( $this > 0 ) {

   $s->{ diffdt } .=
    $this . ' '
    . (
      $this == 1
    ? $s->{ t }->{ uc ( $spec ) . 'G' }
    : $s->{ t }->{ uc ( $spec ) . 'S' }
    ) . ( $spec eq 'second' ? '' : ' ' );

  }

 }

 $self->common;

} ## end sub quality

sub common {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ urlother } = $self->fuse ( $s->{ langaother }, 'more', $s->{ topic } );

 $self->render ( template => 'page/more', format => 'html' );

}

1;
