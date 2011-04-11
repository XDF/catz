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

package Catz::Ctrl::View;

use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use List::MoreUtils qw ( all );

use Catz::Data::DB;
use Catz::Util::Number qw ( fullnum3 minnum );
use Catz::Util::String qw ( deurl );

sub process_id {
 
 #
 # processes the id parameter from the stash to stash
 # if id is not present then resolve it
 #
 # returns true in success, return false on reject
 #
 
 my $self = shift; my $s = $self->{stash};
  
 if ( defined $s->{id} ) { # id was given in request
  
  $s->{origin} = 'id';
    
  $s->{x} = $self->fetch( 'id2x', $s->{id} );
    
  $s->{x} or return 0;
          
 } else { # no id given, must find the id of the first photo in the set
 
  $s->{origin} = 'x';
 
  $s->{x} = $self->fetch ( 'vector_first', @{ $s->{path_array} } );
      
  $s->{x} or return 0;
  
  $s->{id} = $self->fetch ( 'x2id', $s->{x} );
  
  $s->{id} or return 0; 
   
 }
 
 return 1;


}

sub process_path {

 my $self = shift; my $s = $self->{stash};
 
 # processes the path parameter from the stash to stash
 # returns true in success, return false on reject   
 my @path = ();
 
 if ( defined $s->{path} ) {
 
  @path =  split /\//, $s->{path};
  
  # reject if any empty path parts
  ( all { defined $_ } @path ) or return 0;  
   
 }

 # arguments must come in as pairs
 scalar @path % 2 == 0 or return 0;
 
 # URL decode each element and store them to stash
 $s->{path_array} = [ map { deurl $_ } @path ];
 $s->{path_count} = scalar @path;
   
 return 1;

}

sub browse {

 my $self = shift; my $s = $self->{stash};
 
 $self->process_path or $self->not_found and return;
 
 $self->process_id or $self->not_found and return;
   
 my $res = $self->fetch('vector_pager', 
   $s->{x}, $s->{perpage}, @{ $s->{path_array} }  
  );
  
 $s->{total} = $res->[0];
 $s->{page} = $res->[1];
 $s->{pages} = $res->[2];
 $s->{from} = $res->[3];
 $s->{to} = $res->[4];
 $s->{pin} = $res->[5];
 $s->{xs} = $res->[6];
                   
 $s->{total} == 0 and $self->not_found and return; 
 # no photos found by search 
 
 scalar @{ $s->{xs} } == 0 and $self->not_found and return; 
 # no photos in this page
 
 $res = $self->fetch( 'photo_thumbs', @{ $s->{xs} } ) ;
 
 $s->{thumb} = $res->[0];
 $s->{min} = $res->[1];
 $s->{max} = $res->[2]; 
             
 $self->render( template => 'page/browse' );
    
}

sub inspect {

 my $self = shift; my $s = $self->{stash};
 
 $self->process_path or $self->not_found and return;
 
 $self->process_id or $self->not_found and return;
     
 my $res = $self->fetch('vector_pointer', $s->{x}, @{ $s->{path_array} } );
  
 $s->{total} = $res->[0];
 $s->{pos} = $res->[1];
 $s->{pin} = $res->[2];
    
 $s->{detail} = $self->fetch( 'photo_detail', $s->{x});

 $s->{comment} =  $self->fetch( 'photo_text', $s->{x} );

 $s->{image} =  $self->fetch( 'photo_image', $s->{x} );
        
 $self->render( template => 'page/inspect' );

}

sub show {

 my $self = shift; my $s = $self->{stash};
 
 $self->process_path or $self->not_found and return;
 
 $self->process_id or $self->not_found and return;
    
 my $res = $self->fetch('vector_pointer', $s->{x}, $s->{path_array}); 
 
 $s->{total} = $res->[0];
 $s->{pos} = $res->[1];
 $s->{pin} = $res->[2];
   
 $s->{details} = $self->fetch( 'photo_details', $s->{x});

 $s->{texts} =  $self->fetch( 'photo_texts', $s->{x} );

 $s->{image} =  $self->fetch( 'photo_image', $s->{x} );
            
 $self->render( template => 'page/show' );

}

sub sample {

 my $self = shift; my $s = $self->{stash};
 
 $self->process_path or $self->not_found and return;

 $self->process_id or $self->not_found and return;
    
 my $xs = $self->fetch ( 'vector_array_rand',  @{ $s->{path_array} } );
  
 my @set = @{ $xs } [ 0 .. $s->{count} - 1 ];
 
 my $res = $self->fetch ( 'photo_thumbs', @set );
 
 $s->{thumb} = $res->[0];
    
 $self->render( template => 'block/thumb' );
      
}

1;