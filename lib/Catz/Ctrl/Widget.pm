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

package Catz::Ctrl::Widget;

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use List::Util qw ( shuffle );

use Catz::Data::Widget;
use Catz::Data::Style;


sub urlothers {

 my $self = shift; my $s = $self->{stash};
 
 # only for builder, embed has no language change link
  
 given ( $s->{runmode} ) {
 
  when ( 'pair' )  {
  
   my $enc = $self->encode ( $s->{sec} );
   
   $s->{urlback} =
    $self->fuse ( $s->{langa}, 'browse', $s->{pri}, $enc );
  
   $s->{urlconfa} = 
    $self->fuse ( $s->{langa}, $s->{func}, $s->{pri}, $enc );
          
   $s->{urlconfb} = '/';
  
   $s->{urlembed} = $self->fuse ( 
    $s->{langa}, 'embed', $s->{pri}, $enc, $s->{wspec} 
   );

   $s->{trans} = $self->fetch ( 'map#trans', $s->{pri}, $s->{sec} );
      
   $s->{urlother} = $self->fuse ( 
    $s->{langaother}, $s->{func}, $s->{pri}, 
    $self->encode( $s->{trans} ), $s->{wspec} 
   );
  
  }
  
  when ( 'search' ) {

   $s->{urlback} =
    $self->fuseq ( $s->{langa}, 'search' ) .
     '?q=' . $self->enurl ( $s->{what} );

   $s->{urlconfa} = $self->fuse ( $s->{langa}, $s->{func} );   
   $s->{urlconfb} = '?q=' . $self->enurl ( $s->{what} );

   $s->{urlembed} = $self->fuseq ( 
    $s->{langa}, 'embed', $s->{wspec} 
   ) . '?q=' . $self->enurl ( $s->{what} );
  
   $s->{urlother} = $self->fuseq ( 
    $s->{langaother}, $s->{func}, $s->{wspec} 
   ) . '?q=' . $self->enurl ( $s->{what} );
  
  }
  
  default { # default to runmode all
  
   $s->{urlback} = $self->fuse ( $s->{langa}, 'browseall' );

   $s->{urlconfa} = $self->fuse ( $s->{langa}, $s->{func} );   
   $s->{urlconfb} = '/';

   $s->{urlembed} = $self->fuse ( 
    $s->{langa}, 'embed', $s->{wspec} 
   );

   $s->{urlother} = $self->fuse ( 
    $s->{langaother}, $s->{func}, $s->{wspec} 
   );
      
  }
  
 }
 
 return $self->done;
 
}

sub start  {

 # common starting tasks for widget builder and widget renderer

 my $self = shift; my $s = $self->{stash};

 given ( $s->{func} ) {
 
  #
  # build = widget builder
  #
  
  when ( 'build' ) {
  
   if ( defined $s->{wspec} ) { 
 
    
    # this is not the builder's entry pages, prevent indexing
    $s->{meta_index} = 0; $s->{meta_follow} = 0;
    
   } else {
   
    # no config, load the default
    $s->{wspec} = widget_default;
   
   }
  
  }
 
  #
  # embed = widget rendering
  #
 
  when ( 'embed' ) {
     
   defined $s->{wspec} or # can't render without config 
    return $self->fail ( 'widget configuration missing' );
    
   # widget "pages" shouldn't be indexed 
   $s->{meta_index} = 0; $s->{meta_follow} = 0;
  
  }
  
  default { return $self->fail ( 'unknown widget function' ) }
 
 }
 
 # calling general initialization routines on base controller
 
 $self->f_init or return $self->fail ( 'f_init exit' );
 
 if ( $s->{pri} and $s->{sec} ) {
 
  $self->f_pair_start or return $self->fail ( 'f_pair_start exit' );

 } else {

  $self->f_search_ok ( 'q', 'what' ) 
   or return $self->fail ( 'illegal search' );

  if ( $s->{what} ) {

   $s->{runmode} = 'search';

   $self->f_search_args or return $self->fail ( 'f_search_args exit' );

  } else {

   $s->{runmode} = 'all';

  }

 }
 
 return $self->done; 
 
}

sub do { # the common entry point for buidler and renderer

 my $self = shift; my $s = $self->{stash};
 
 $self->start or return $self->fail ( 'start exit' );
 
 # better check and process the widget configuration now
 
 ( $s->{wrun} = widget_verify ( $s->{wspec} ) )
  or return $self->fail ( 'widget setup verfication failed' );
 
 $s->{total} = $self->fetch ( "$s->{runmode}#count", @{ $s->{args_array} } );
 
 $s->{total} > 0 or return $self->fail ( 'no photos' );
 
 $s->{total} > 9 or 
  return $self->fail ( 'building and rendering requires at least 10 photos' );

 $s->{func} eq 'build' and do {
 
  $self->f_map or $self->fail ( 'map exit' );
 
  $self->urlothers or $self->fail ( 'urlothers exit' );
  
  # widget confuration is needed in builder page rendering
  $s->{wconf} = widget_conf;
 
 };
 
 $s->{func} eq 'embed' and do {
 
  $self->photos or $self->fail ( 'photos exit' );
 
 };
 
 # use thumbsize from widget configuration, not the global value 
 $s->{thumbsize} = $s->{wrun}->{size};
   
 $self->output ( "page/$s->{func}" );
 
}

sub photos { # the widget renderer

 my $self = shift; my $s = $self->{stash};
  
 # we assume that this number of photos is always enough
 # on whatever settings the stripe is displayed
 # it is actually smart to use a fixed value so that
 # all database access and data processing is done only once
 # for one subject and the served from cache 
 my $n = 100; 
 
 my $add = '_rand'; my $order = 'random()';
  
 # change settings if latest photos requested
 $s->{wrun}->{choose} == 2 and do {
 
  $add = ''; #$order = 's asc,n desc';
   
 };
 
 # fetch the photo xs to start the processing with
 $s->{xs} = $self->fetch ( # latest photos
  "$s->{runmode}#array$add".'_n', @{ $s->{args_array} }, $n 
 ); 
         
 scalar @{ $s->{xs} } == 0 and return $self->fail ( 'no photos found' ); 
  
 # fetch the corresponding thumbnails 
 ( $s->{thumbs}, undef, undef ) = 
  @{ $self->fetch( 'photo#thumb', $order, @{ $s->{xs} } ) };

 # fetch photo texts  
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
 
 # we now have thumbs in $s->{thumbs} in browsing (x) order
 # we do reordering based on what was the image strip needs
    
}

sub contact {

 my $self = shift; my $s = $self->{stash};
   
 length $s->{langa} > 2 and return $self->fail ( 'setup set so stopping' );
  
 my $im = widget_plate (
  $s->{t}->{MAILTO_TEXT}, $s->{palette}, $s->{intent}
 );

 $self->render_data ( $im , format => 'png' );

}

sub style {

 my $self = shift; my $s = $self->{stash};
 
 $s->{st} = style_get; $s->{palette} = 'light'; 

 $self->render ( 'style/widget', format => 'css' );

}

1;