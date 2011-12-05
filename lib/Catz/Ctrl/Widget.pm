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
  
   $s->{urlconfa} = 
    $self->fuse ( $s->{langa}, $s->{func}, $s->{pri}, $enc );
          
   $s->{urlconfb} = '/';
  
   $s->{urlembed} = $self->fuse ( 
    $s->{lang}, 'embed', $s->{pri}, $enc, $s->{widcon} 
   );

   $s->{trans} = $self->fetch ( 'map#trans', $s->{pri}, $enc );
      
   $s->{urlother} = $self->fuse ( 
    $s->{langaother}, $s->{func}, $s->{pri}, $s->{trans}, $s->{widcon} 
   );
  
  }
  
  when ( 'search' ) {

   $s->{urlconfa} = $self->fuse ( $s->{langa}, $s->{func} );   
   $s->{urlconfb} =  '?q=' . $self->enurl ( $s->{what} );

   $s->{urlembed} = $self->fuseq ( 
    $s->{lang}, 'embed', $s->{widcon} 
   ) . '?q=' . $self->enurl ( $s->{what} );
  
   $s->{urlother} = $self->fuseq ( 
    $s->{langaother}, $s->{func}, $s->{widcon} 
   ) . '?q=' . $self->enurl ( $s->{what} );
  
  }
  
  default { # default to runmode all

   $s->{urlconfa} = $self->fuse ( $s->{langa}, $s->{func} );   
   $s->{urlconfb} = '/';

   $s->{urlembed} = $self->fuse ( 
    $s->{lang}, 'embed', $s->{widcon} 
   );

   $s->{urlother} = $self->fuse ( 
    $s->{langaother}, $s->{func}, $s->{widcon} 
   );
      
  }
  
 }
 
 return $self->done;
 
}

sub start  {

 my $self = shift; my $s = $self->{stash};

 given ( $s->{func} ) {
 
  #
  # build = widget builder
  #
  
  when ( 'build' ) {
  
   if ( defined $s->{widcon} ) { 
 
    # this is not the builder's entry pages, prevent indexing
    $s->{meta_index} = 0; $s->{meta_follow} = 0;
    
   } else {
   
    # no config, load the default
    $s->{widcon} = widget_default;
   
   }
  
  }
 
  #
  # embed = widget rendering
  #
 
  when ( 'embed' ) {
  
   length $s->{langa} > 2 and return $self->fail ( 'setup set so stopping' );
   
   defined $s->{widcon} or # can't render without config 
    return $self->fail ( 'widget configuration missing' );
    
   # widget "pages" shouldn't be indexed 
   $s->{meta_index} = 0; $s->{meta_follow} = 0;
  
  }
  
  default { return $self->fail ( 'unknown widget function' ) }
 
 }
 
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
 
 ( $s->{widcons} = widget_conf ( $s->{widcon} ) )
  or $self->fail ( 'widget setup verfication failed' );
 
 $s->{total} = $self->fetch ( "$s->{runmode}#count", @{ $s->{args_array} } );
 
 $s->{total} > 0 or return $self->fail ( 'no photos' );

 $s->{func} eq 'build' and do {
 
  $self->urlothers or $self->fail ( 'urlothers exit' );
 
 };
 
 $s->{func} eq 'embed' and do {
 
  $self->photos or $self->fail ( 'phtos exit' );
 
 };
 
 # use thumbsize from widget configuration, not the global value 
 $s->{thumbsize} = $s->{widcons}->{s};
   
 $self->output ( "page/$s->{func}" );
 
}

sub photos { # the widget renderer

 my $self = shift; my $s = $self->{stash};
  
 my $n = 100; # we assume that this number of photos is always enough
 
 $s->{xs} = $self->fetch ( 
  "$s->{runmode}#array_rand_n", @{ $s->{args_array} }, $n 
 ); 
          
 scalar @{ $s->{xs} } == 0 and return $self->fail ( 'no photos found' ); 
  
 # fetch the corresponding thumbnails 
 ( $s->{thumbs}, undef, undef ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };

 # fetch photo texts  
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
   
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