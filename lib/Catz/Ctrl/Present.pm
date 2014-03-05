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

package Catz::Ctrl::Present;

#
# an abstract base class for all present-type of contollers
# (controllers that provide photo browsing and present the large photos)
#

use 5.12.0;
use strict;
use warnings;
no warnings 'experimental';

use parent 'Catz::Ctrl::Base';

use Catz::Data::Result;
use Catz::Data::Search;
use Catz::Data::Style;
use Catz::Data::Widget;

# defined concepts that are skipped in basic viewing mode
my %basicskip =
 map { $_ => 1 } qw ( body code loc org umb date cate app feat nick title );

# defined concepts that are displayed without title in basic viewing mode
my %basichide =
 map { $_ => 1 } qw ( loc org umb nat fnum flen etime iso time );

sub single {

 # prepare a single large photo to stash for viewing

 my $self = shift;
 my $s    = $self->{ stash };

 ( $s->{ total }, $s->{ pos }, $s->{ pin } ) =
  @{ $self->fetch ( $s->{ runmode } . '#pointer', $s->{ x },
   @{ $s->{ args_array } } ) };
 
 $s->{ total } == 0 and do {
 
  # more analysis added 2012-01-02
  
  if ( $s->{ origin } eq 'id' ) {
  
   # id was presented in URL and it was found in the data
   # now we send a permanent redirect to same photo in all photos viewing
   
   return $self->moveto ( $self->fuse( $s->{langa}, 'viewall', $s->{ id } ) );   
   
  } 
  
  return $self->fail ( 'photo not found' );
  
 };  

 # fetch the photo metadata

 $s->{ comment } = $self->fetch ( 'photo#text', $s->{ x } );    # comment(s)

 $s->{ detail } = $self->fetch ( 'photo#detail', $s->{ x } );   # details

 $s->{ image } = $self->fetch ( 'photo#image', $s->{ x } ); # the image itself

 # fetch the show result keys and prepare them to stash

 my $keys = $self->fetch ( 'photo#resultkey', $s->{ x } );

 result_prepare ( $self, $keys );

 $s->{ basicskip } = \%basicskip;

 $s->{ basichide } = \%basichide;
 
 # turn of indexing on others than the default viewing in all mode
 $s->{ runmode } eq 'all' or $s->{ meta_index } = 0;
 
 $s->{ meta_follow } = 0; # photo viewer page is not followed
 
 $self->output ( 'page/view' );

 return $self->done;

} ## end sub single

sub multi {

 # prepare a set of thumbnails for browsing, returns
 #  1 in success
 #  0 on error

 my $self = shift;
 my $s    = $self->{ stash };

 (
  $s->{ total },
  $s->{ page },
  $s->{ pages },
  $s->{ from },
  $s->{ to },
  $s->{ pin },
  $s->{ xs },
  $s->{ xfirst },
  $s->{ xlast }
  )
  = @{
  $self->fetch (
   $s->{ runmode } . '#pager',
   $s->{ x },
   $s->{ perpage },
   @{ $s->{ args_array } }
  )
  };

 $s->{ total } == 0 and do {
 
  # more analysis added 2012-01-02
  
  if ( $s->{ origin } eq 'id' ) {
  
   # id was presented in URL and it was found in the data
   # now we send a permanent redirect to same pair / search but without the id
   
   if ( $s->{runmode} eq 'pair' ) {
   
    return $self->moveto ( $self->fuse( 
     $s->{langa}, 'browse', $s->{pri}, $self->encode( $s->{sec} ) 
    ) );
   
   } elsif ( $s->{runmode} eq 'search') {
   
    return $self->moveto ( $self->fuseq( 
     $s->{langa}, 'search', ( '?q=' . $self->enurl( $s->{what} ) ) 
    ) );
   
   }
   
  } 
  
  return $self->fail ( 'no photos found' );
  
 };

 scalar @{ $s->{ xs } } == 0
  and return $self->fail ( 'no photos for this page' );

 # fetch the thumbs in the order of x and also
 # fetch their included earliest - latest metadata
 ( $s->{ thumbs }, $s->{ earliest }, $s->{ latest } ) =
  @{ $self->fetch ( 'photo#thumb', 'x', @{ $s->{ xs } } ) };

 # prepare stuff for visualizations
 $self->f_vizinit or return $self->fail ( 'f_vizinit exit' );

 # generate converage counts and urls for coverage information displays

 if (
  $s->{ runmode } eq 'all'
  or ( $s->{ runmode } eq 'pair'
   and ( $s->{ pri } eq 'folder' or $s->{ pri } eq 'date' ) )
  )
 {    # coverage provided for limited combinations

  $self->f_dist or return $self->fail ( 'f_dist exit' );

 }

 # fetch photo texts
 $s->{ texts }    = $self->fetch ( 'photo#texts',    @{ $s->{ xs } } );
 $s->{ clusters } = $self->fetch ( 'photo#clusters', @{ $s->{ xs } } );

 # generate date jumps

 if ( $s->{ runmode } eq 'all' ) {

  $s->{ jump2date } =
   $self->fetch ( 'related#all2date', $s->{ earliest }, $s->{ latest } );

 }
 elsif ( $s->{ runmode } eq 'pair' ) {

  $s->{ jump2date } = $self->fetch (
   'related#pair2date',
   $s->{ pri },
   $s->{ sec },
   $s->{ earliest },
   $s->{ latest }
  );

 }
 else {

  # date jumps are only available for all and pair, not for search
  $s->{ jump2date } = undef;

 }

 # fetch the latest and oldest date in this whole photoset
 # (not just on this page)

 $s->{ fresh }   = $self->fetch ( 'related#date', $s->{ xfirst } );
 $s->{ ancient } = $self->fetch ( 'related#date', $s->{ xlast } );

 # prepare url for builder access

 given ( $s->{ runmode } ) {

  when ( 'pair' ) {

   my $enc = $self->encode ( $s->{ sec } );

   $s->{ urlbuild } =
    $self->fuse ( $s->{ langa }, 'build', $s->{ pri }, $enc );

   # only the 1st page is indexed, all pages are not followed
   $s->{ meta_index } =  $s->{ page } == 1 ? $s->{ meta_index } : 0;
   $s->{ meta_follow } = 0;     
  }

  when ( 'search' ) {

   $s->{ urlbuild } =
      $self->fuseq ( $s->{ langa }, 'build' ) . '?q='
    . $self->enurl ( $s->{ what } );

   # search results are not indexed nor followed
   $s->{ meta_index } = $s->{ meta_follow } = 0;

  }

  default { # runmode all

   $s->{ urlbuild } = $self->fuse ( $s->{ langa }, 'build' );

   # all photos browsing only first page is indexed
   $s->{ meta_index } = $s->{ page } == 1 ? $s->{ meta_index } : 0;

   # follow is left to the default
   
  }

 } ## end given
 


 $self->output ( 'page/browse' );

 return $self->done;

} ## end sub multi

1;
