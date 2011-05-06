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

package Catz::Ctrl::Browse;

use 5.12.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Args';

sub browse {

 my $self = shift; my $s = $self->{stash};
 
 #warn ( $s->{path} );
 
 $self->process_args ( 0 ) or $self->not_found and return;
 $self->process_id or $self->not_found and return;

 #warn ( join '-', @{ $s->{args_array} }  );

 #warn ( $s->{x} );
   
 my $res = $self->fetch('vector_pager', 
   $s->{x}, $s->{perpage}, @{ $s->{args_array} }  
  );
 
 $res == 0 and $self->not_found and return;

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
 
 $res = $self->fetch( 'photo_thumb', @{ $s->{xs} } ) ;
 
 $s->{thumb} = $res->[0];
 $s->{earliest} = $res->[1];
 $s->{latest} = $res->[2]; 
             
 $self->render( template => 'page/browse' );
    
}

1;