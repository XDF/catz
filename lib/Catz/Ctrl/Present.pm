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
 
 my $self = shift; my $stash = $self->{stash};
 
 if ( defined $stash->{id} ) { # id was given in request
    
  $stash->{x} = $self->fetch( 'id2x', $stash->{id} ); 
  
  $stash->{x} or return 0; 
        
 } else { # no id given, must find the id of the first photo in the set
 
  $stash->{x} = $self->fetch ( 'vector_first', @{ $stash->{path_array} } );
  
  $stash->{x} or return 0;
  
  $stash->{id} = $self->fetch ( 'x2id', $stash->{x} );

  $stash->{id} or return 0; 
   
 }
 
 return 1;


}

sub process_path {

 my $self = shift; my $stash = $self->{stash};
 
 # processes the path parameter from the stash to stash
 # returns true in success, return false on reject   
 my @path = ();
 
 if ( defined $stash->{path} ) {
 
  @path =  split /\//, $stash->{path};
  
  # reject if any empty path parts
  ( all { defined $_ } @path ) or return 0;  
   
 
 }

 # arguments must come in as pairs
 scalar @path % 2 == 0 or return 0;
 
 # URL decode each element and store them to stash
 $stash->{path_array} = [ map { deurl $_ } @path ];
 $stash->{path_count} = scalar @path;
   
 return 1;

}

1;

