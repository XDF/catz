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

package Catz::Ctrl::Present;

#
# an abstract base class for all present-type of contollers
# (controllers that provide photo browsing and present the large photos)  
#

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';
              
use Catz::Data::Result;
use Catz::Data::Search;
use Catz::Data::Style;
use Catz::Data::Widget;

sub single {

 # prepare a single large photo to stash for viewing
 
 my $self = shift; my $s = $self->{stash};
 
 ( $s->{total}, $s->{pos}, $s->{pin} ) = @{ 
   $self->fetch ( 
    $s->{runmode} . '#pointer', 
    $s->{x}, 
    @{ $s->{args_array} } 
   )
  };
     
 $s->{total} == 0 and 
  return $self->fail ( 'photo not found' ); 

 # fetch the photo metadata
 
 $s->{comment} = $self->fetch( 'photo#text', $s->{x} ); # comment(s)
 
 $s->{detail} = $self->fetch( 'photo#detail', $s->{x} ); # details
 
 $s->{image} = $self->fetch( 'photo#image', $s->{x} ); # the image itself
 
 # fetch the show result keys and prepare them to stash
 
 my $keys = $self->fetch ( 'photo#resultkey', $s->{x} );
 
 result_prepare ( $self, $keys );
          
 $self->output ( 'page/view' );
 
 return $self->done;

}

sub multi {

 # prepare a set of thumbnails for browsing, returns
 #  1 in success 
 #  0 on error
 
 my $self = shift; my $s = $self->{stash};
   
 ( 
  $s->{total}, $s->{page}, $s->{pages}, $s->{from}, 
  $s->{to}, $s->{pin}, $s->{xs}, $s->{xfirst}, $s->{xlast} 
 ) = @{ $self->fetch( 
   $s->{runmode} . '#pager', 
   $s->{x}, 
   $s->{perpage}, 
   @{ $s->{args_array} } 
  ) };

 $s->{total} == 0 and 
  return $self->fail ( 'no photos found' );  

 scalar @{ $s->{xs} } == 0 and 
  return $self->fail ( 'no photos for this page' ); 
  
 # fetch the thumbs and their included earliest - latest metadata
 ( $s->{thumbs}, $s->{earliest}, $s->{latest} ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };
  
  # prepare stuff for visualizations
  $self->f_vizinit or return $self->fail ( 'f_vizinit exit' );


 # generate converage counts and urls for coverage information displays
   
 if ( 
  $s->{runmode} eq 'all' or ( $s->{runmode} eq 'pair' and 
   ( $s->{pri} eq 'folder' or $s->{pri} eq 'date' ) )
  ) {  # coverage provided for limited combinations
    
  $self->f_dist or return $self->fail ( 'f_dist exit' );

 }
   
 # fetch photo texts  
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );

 # generate date jumps  

 if ( $s->{runmode} eq 'all' ) {
 
  $s->{jump2date} = $self->fetch ( 
   'related#all2date', $s->{earliest}, $s->{latest}
  );
   
 } elsif ( $s->{runmode} eq 'pair' ) {

  $s->{jump2date} = $self->fetch ( 
   'related#pair2date', $s->{pri}, $s->{sec}, $s->{earliest}, $s->{latest}  
  );

 } else {
   
  # date jumps are only available for all and pair, not for search
  $s->{jump2date} = undef;
 
 }
 
 # fetch the latest and oldest date in this whole photoset 
 # (not just on this page)
 
 $s->{fresh} = $self->fetch ( 'related#date', $s->{xfirst} );
 $s->{ancient} = $self->fetch ( 'related#date', $s->{xlast} );
 
 # prepare url for builder access
 
 given ( $s->{runmode} ) {
 
  when ( 'pair' ) {

   my $enc = $self->encode ( $s->{sec} );
         
   $s->{urlbuild} = 
    $self->fuse ( $s->{langa}, 'build', $s->{pri}, $enc );
  
  }
  
  when ( 'search' ) {

   $s->{urlembed} = $self->fuseq ( $s->{langa}, 'build' ) . 
    '?q=' . $self->enurl ( $s->{what} );  
  
  }
  
  default {
  
   $s->{urlembed} = $self->fuse (  $s->{langa}, 'build' ); 
  
  }
 
 }
      
 $self->output ( 'page/browse' );
 
 return $self->done;
 
}

1;