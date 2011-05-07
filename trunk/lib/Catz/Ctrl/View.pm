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

use 5.12.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Args';

use Catz::Data::Result;

sub view {

 my $self = shift; my $s = $self->{stash};
  
 $self->process_args or $self->not_found and return;

 $self->process_id or $self->not_found and return;
     
 my $res = $self->fetch('vector_pointer', $s->{x}, @{ $s->{args_array} } );
 
 $res == 0 and $self->not_found and return;
  
 $s->{total} = $res->[0];
 $s->{pos} = $res->[1];
 $s->{pin} = $res->[2];
    
 $s->{detail} = $self->fetch( 'photo_detail', $s->{x});

 $s->{comment} =  $self->fetch( 'photo_text', $s->{x} );

 $s->{image} =  $self->fetch( 'photo_image', $s->{x} );

 my $keys = $self->fetch ( 'photo_resultkey', $s->{x} );

 result_prepare ( $self, $keys );
        
 $self->render( template => 'page/view' );

}

1;