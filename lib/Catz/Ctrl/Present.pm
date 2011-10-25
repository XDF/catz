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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';
              
use Catz::Data::Result;
use Catz::Data::Search;
use Catz::Data::Style;

# disbled 2011-10-25
# use Catz::Data::Widget;

sub init {

 # general initalization for controller actions

 my $self = shift; my $s = $self->{stash};
 
 foreach my $var ( qw ( 
  runmode origin what refines breedernat viz_rank trans nats
  cover_notext cover_nocat url_notext url_nocat maxx total
 ) ) { $s->{$var} = undef }
 
 defined $s->{pri} or $s->{pri} = undef;
 defined $s->{sec} or $s->{sec} = undef;
   
 $s->{args_array} = []; 
 $s->{args_count} = 0;

 return 1;
            
}

sub origin {

 # processes incoming photo id or resolves it from data, returns
 #  1 in success 
 #  0 on error
 
 my $self = shift; my $s = $self->{stash};
 
 if ( $s->{id} ) { 

  # mark that this request had an id
  $s->{origin} = 'id';
  
  # fetch the corresponding x 
  $s->{x} = $self->fetch( $s->{runmode} . '#id2x', $s->{id} );
    
  $s->{x} or return 0; # should be found
          
 } else { 
 
  # no id was given in the request
  # must find the id of the first photo in the set
 
  # mark that the id was resolved
  $s->{origin} = 'x'; 
  
  # fetch the first x of the photo set
  $s->{x} = $self->fetch ( $s->{runmode} . '#first', @{ $s->{args_array} } );
  
  # if no first x then it is an error as default
  # allow the system to continue if a search returns no hits
  $s->{runmode} ne 'search' and ( $s->{x} or return 0 );            
 
  # fetch the id corresponding the x 
  $s->{x} and do { 
   $s->{id} = $self->fetch ( $s->{runmode} . '#x2id', $s->{x} ) 
  };
  
  # if no id was found then it is an error but
  # allow the system to continue if a search returns no hit
  $s->{runmode} ne 'search' and ( $s->{id} or return 0 ); 
   
 }
 
 return 1; # ok

}


sub load {

 # load general stuff to stash

 my $self = shift; my $s = $self->{stash};
 
 $s->{maxx} = $self->fetch ( 'all#maxx' );
 
 # read common mappings from model to stash

 $s->{maplink} = $self->fetch ( 'map#link' );
 $s->{mapview} = $self->fetch ( 'map#view' );
 $s->{mapdual} = $self->fetch ( 'map#dual' );
 
}

sub single {

 # prepare a single large photo for viewing, returns
 #  1 in success 
 #  0 on success
 
 my $self = shift; my $s = $self->{stash};
 
 ( $s->{total}, $s->{pos}, $s->{pin} ) = 
  @{ 
   $self->fetch( 
    $s->{runmode} . '#pointer', 
    $s->{x}, 
    @{ $s->{args_array} } 
   )
  };
     
 $s->{total} == 0 and return 0; # no photo found 

 # fetch the photo metadata

 $s->{comment} =  $self->fetch( 'photo#text', $s->{x} ); # comment(s)
 
 $s->{detail} = $self->fetch( 'photo#detail', $s->{x}); # details
 
 $s->{image} =  $self->fetch( 'photo#image', $s->{x} ); # the image itself
 
 # fetch the result keys and prepare them to stash
 
 my $keys = $self->fetch ( 'photo#resultkey', $s->{x} );
 
 result_prepare ( $self, $keys );
          
 $self->render( template => 'page/view', format => 'html' );
 
 return 1;

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

 $s->{total} == 0 and return 0; ; # no photos found 

 scalar @{ $s->{xs} } == 0 and return 0; # no photos for this page 
 
 # fetch the thumbs and their included earliest - latest metadata
 ( $s->{thumbs}, $s->{earliest}, $s->{latest} ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };

 # generate converage counts and urls for coverage information displays
   
 if ( 
  $s->{runmode} eq 'all' or ( $s->{runmode} eq 'pair' and 
   ( $s->{pri} eq 'folder' or $s->{pri} eq 'date' ) )
  ) {  # coverage provided for limited combinations  
  # 1/2: the textless photos
  
  my @extra = qw ( -has text );

  # make a new search for those that have no text, get the count of photos
  $s->{cover_notext} = 
   $self->fetch ( "search#count", @{ $s->{args_array} }, @extra );
  
  # if there where those then prepare the url to see them
  $s->{cover_notext} > 0 and
  $s->{url_notext} = args2search ( @{ $s->{args_array} }, @extra );
  
  # 2/2: the photos with breed but without a cat
  
  @extra = qw ( +has breed -has cat );
  
  # make a new search for those and get the count of photos
  $s->{cover_nocat} = 
   $self->fetch ( "search#count", @{ $s->{args_array} }, @extra );
  
  # if there where those then prepare the url to see them
  $s->{cover_nocat} > 0 and
  $s->{url_nocat} =
   args2search ( @{ $s->{args_array} }, @extra );
  
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
 
 $s->{fresh} = $self->fetch ( 'related#date', $s->{xfirst} );
 $s->{ancient} = $self->fetch ( 'related#date', $s->{xlast} );
 
 $s->{vizmode} = 'none';
 
 if ( $s->{runmode} eq 'all' ) {
 
  $s->{vizmode} = 'dist'; 
 
 } elsif ( $s->{runmode} eq 'pair' ) { 
 
  if ( $s->{pri} eq 'folder' or $s->{pri} eq 'date' ) {
  
   $s->{vizmode} = 'dist';
  
  } else {

   ( $self->fetch ( 'related#seccnt', $s->{pri} ) > 9 ) and
    $s->{vizmode} = 'rank';
   
  }

 }
 
 # load style (for viz img tags)
 $s->{style} = style_get ( $s->{palette} );
 
 # disabled 2011-10-15
 # prepare url for builder access
 # $s->{urlbuild} = '/' . $s->{langaother} . '/build?' . widget_ser ( $s );
 
 # 2011-10-15
 $s->{urlbuild} = undef; 
    
 $self->render( template => 'page/browse', format => 'html' );
 
 return 1;

}

1;