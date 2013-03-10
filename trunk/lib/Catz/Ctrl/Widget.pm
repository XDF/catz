#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2013 Heikki Siltala
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

package Catz::Ctrl::Widget;

use 5.16.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use Const::Fast;
use List::Util qw ( shuffle );

use Catz::Data::Widget;
use Catz::Data::Style;

sub urlothers {

 my $self = shift;
 my $s    = $self->{ stash };

 # only for builder, embed has none of these links

 given ( $s->{ runmode } ) {

  when ( 'pair' ) {

   my $enc = $self->encode ( $s->{ sec } );

   $s->{ urldefault } =
    $self->fuse ( $s->{ langa }, 'build', $s->{ pri }, $enc );

   $s->{ urlback } =
    $self->fuse ( $s->{ langa }, 'browse', $s->{ pri }, $enc );

   $s->{ urlconfa } =
    $self->fuse ( $s->{ langa }, $s->{ func }, $s->{ pri }, $enc );

   $s->{ urlconfb } = '/';

   $s->{ urlembed } =
    $self->fuse ( $s->{ lang }, 'embed', $s->{ pri }, $enc, $s->{ wspec } );

   $s->{ trans } = $self->fetch ( 'map#trans', $s->{ pri }, $s->{ sec } );

   $s->{ urlother } = $self->fuse (
    $s->{ langaother },
    $s->{ func },
    $s->{ pri },
    $self->encode ( $s->{ trans } ),
    $s->{ wspec }
   );

  } ## end when ( 'pair' )

  when ( 'search' ) {

   $s->{ urldefault } =
      $self->fuseq ( $s->{ langa }, 'build' ) . '?q='
    . $self->enurl ( $s->{ what } );

   $s->{ urlback } =
      $self->fuseq ( $s->{ langa }, 'search' ) . '?q='
    . $self->enurl ( $s->{ what } );

   $s->{ urlconfa } = $self->fuse ( $s->{ langa }, $s->{ func } );
   $s->{ urlconfb } = '?q=' . $self->enurl ( $s->{ what } );

   $s->{ urlembed } =
      $self->fuseq ( $s->{ lang }, 'embed', $s->{ wspec } ) . '?q='
    . $self->enurl ( $s->{ what } );

   $s->{ urlother } =
      $self->fuseq ( $s->{ langaother }, $s->{ func }, $s->{ wspec } ) . '?q='
    . $self->enurl ( $s->{ what } );

  } ## end when ( 'search' )

  default {    # default to runmode all

   $s->{ urldefault } = $self->fuse ( $s->{ langa }, 'build' );
   $s->{ urlback }    = $self->fuse ( $s->{ langa }, 'browseall' );
   $s->{ urlconfa }   = $self->fuse ( $s->{ langa }, $s->{ func } );
   $s->{ urlconfb }   = '/';
   $s->{ urlembed }   = $self->fuse ( $s->{ lang }, 'embed', $s->{ wspec } );
   $s->{ urlother } =
    $self->fuse ( $s->{ langaother }, $s->{ func }, $s->{ wspec } );

  }

 } ## end given

 return $self->done;

} ## end sub urlothers

sub start {

 # common starting tasks for widget builder and widget renderer

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ func } eq 'build'
  or $s->{ func } eq 'embed'
  or return $self->fail ( 'unknown widget function' );
  
 $s->{ func } eq 'embed' and length ( $s->{ langa } ) > 2 and 
  return $self->fail ( 'setup set so stopping' );

 # the default for builder and embed is not to index or follow
 $s->{ meta_index } = $s->{ meta_follow } = 0;
 
 $s->{ wspec_loaded } = 0;

 exists $s->{ wspec } or do {

  $s->{ func } eq 'embed' and return
   $self->fail ( 'widget rendering not possible without parameters' );
  
  $s->{ wspec } = widget_default;
  $s->{ wspec_loaded } = 1; 

 };

 # calling general initialization routines on base controller

 $self->f_init or return $self->fail ( 'f_init exit' );

 if ( $s->{ pri } and $s->{ sec } ) {

  $self->f_pair_start or return $self->fail ( 'f_pair_start exit' );

 }
 else {

  $self->f_search_ok ( 'q', 'what' )
   or return $self->fail ( 'illegal search' );

  if ( $s->{ what } ) {

   $s->{ runmode } = 'search';

   $self->f_search_args or return $self->fail ( 'f_search_args exit' );

  }
  else {

   $s->{ runmode } = 'all';
   
   # restore indexing of all photos default mode builder
   
   $s->{ wspec_loaded } and 
    length $s->{ langa } == 2 and 
     $s->{ meta_index } = 1;
   
  }

 } ## end else [ if ( $s->{ pri } and $s...)]

 return $self->done;

} ## end sub start

sub photos {    # the widget renderer

 my $self = shift;
 my $s    = $self->{ stash };
 
 # randomizing on each call

 # we assume that this number of photos is always enough
 # on whatever settings the stripe is displayed
 
 my $n = 120 + int ( rand ( 10 ) );
 
 # a photo picking order that will be used 
 # when the photos are presented in a widget
 
 # created by picking a different sequencing
 # each time to add more randomness

 my @ord = shuffle ( 0, 1, 2, 3 );

 $s->{ thumbspicks } = [ (
 
  ( grep { $_ % 4 == $ord[0] } ( 0 .. $n - 1 ) ),

  ( grep { $_ % 4 == $ord[1] } ( 0 .. $n - 1 ) ),

  ( grep { $_ % 4 == $ord[2] } ( 0 .. $n - 1 ) ),

  ( grep { $_ % 4 == $ord[3] } ( 0 .. $n - 1 ) ),
 
 ) ];

 my $add;
 my $order;
 
 given ( $s->{ wrun }->{ choose } ) {

  when ( 1 ) { $add = ''; $order = 'latest' }    # latest photos

  when ( 2 ) { $add = '_rand'; $order = 'x' }   # rand photos weight on latest

  when ( 3 ) { $add = '_rand'; $order = 'rand' }    # totally rand photos

  default { die "internal error: unknown photo choosing method id '$_'" }

 }

 # fetch the photo xs to start the processing with
 $s->{ xs } = $self->fetch (                        
  "$s->{runmode}#array$add" . '_n', @{ $s->{ args_array } }, $n
 );

 scalar @{ $s->{ xs } } == 0 
  and return $self->fail ( 'no photos found' );

 # fetch the corresponding thumbnails
 ( $s->{ thumbs }, undef, undef ) =
  @{ $self->fetch ( 'photo#thumb', $order, @{ $s->{ xs } } ) };
  
 # fetch photo texts
 $s->{ texts } = $self->fetch ( 'photo#texts', @{ $s->{ xs } } );

} ## end sub photos

sub do {    # the common entry point for buidler and renderer

 my $self = shift;
 my $s    = $self->{ stash };

 $self->start or return $self->fail ( 'start exit' );

 # better check and process the widget configuration now

 ( $s->{ wrun } = widget_verify ( $s->{ wspec } ) )
  or return $self->fail ( 'widget setup verfication failed' );

 $s->{ total } =
  $self->fetch ( "$s->{runmode}#count", @{ $s->{ args_array } } );

 $s->{ total } > 0 or return $self->fail ( 'no photos' );

 if ( $s->{ func } eq 'build' ) {
 
  $s->{ total } > $s->{ widgetnon } or
   return $self->fail ( 
    "building requires more than $s->{ widgetnon } photos" 
   );

 }

 $s->{ func } eq 'build' and do {

  $self->f_map or return $self->fail ( 'map exit' );

  $self->urlothers or return $self->fail ( 'urlothers exit' );

  # widget confuration is needed in builder page rendering
  $s->{ wconf } = widget_conf;
  
  # widget confuration is needed in comparing to wspec
  # to decide should settings reset be displayed or not
  $s->{ wdefault } = widget_default;

 };

 $s->{ func } eq 'embed' and do {

  $self->photos or return $self->fail ( 'photos exit' );

 };

 # use thumbsize from widget configuration, not the global value
 $s->{ thumbsize } = $s->{ wrun }->{ size };

 $self->output ( "page/$s->{func}" );

} ## end sub do

sub contact {

 my $self = shift;
 my $s    = $self->{ stash };

 length $s->{ langa } > 2 and return $self->fail ( 'setup set so stopping' );

 my $im =
  widget_plate ( $s->{ t }->{ MAILTO_TEXT }, $s->{ palette },
  $s->{ intent } );

 $self->render_data ( $im, format => 'png' );

}

sub style {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ st }      = style_get;
 $s->{ palette } = 'light';

 $self->render ( 'style/widget', format => 'css' );

}

1;
