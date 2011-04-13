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

package Catz::Ctrl::Locate;

use strict;
use warnings;

use parent 'Catz::Ctrl::Base';


sub find {

 my $self = shift; my $s = $self->{stash};
 
 $s->{find} = $self->fetch ( 'find', $s->{what} );

 $self->render( template => 'block/find' );

}

sub sample {

 my $self = shift; my $s = $self->{stash};
 
 my $xs; my @set;
 
 $s->{path} = undef;
 
 if ( $s->{what} ) {
 
  my $res = $self->fetch ( 'find', $s->{what} );
  
  scalar @{ $res } == 0 and $self->not_found and return; 
 
  $xs = [ map { $_->[3] } @{ $res } ];
 
  @set = @{ $xs };
  
 } else {

  $xs = $self->fetch ( 'vector_array_rand',  @{ $s->{path_array} } );
 
  @set = @{ $xs } [ 0 .. $s->{count} - 1 ];
  
 }
 
 #die join '-', @set;
 
 my $res = $self->fetch ( 'photo_thumbs', @set );
 
 $s->{thumb} = $res->[0];
    
 $self->render( template => 'block/thumb' );

}


1;
