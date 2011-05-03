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

package Catz::Ctrl::Info;

use 5.12.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Args';

use Catz::Util::Time qw( dtexpand );

sub info {

 my $self = shift; my $s = $self->{stash};
  
 $self->process_args ( 1 ) or $self->not_found and return;
 $self->process_id or $self->not_found and return;
 
 my $res = 
  $self->fetch( 'vector_info', @{ $s->{args_array} } );
    
 $s->{total} = $res->[0];
  
 $s->{latest} = dtexpand ( $self->fetch ( 'x2dt', $res->[1] ), $s->{lang} );
 
 $s->{latestid} = $self->fetch ( 'x2id', $res->[1] );
   
 $s->{earliest} = dtexpand ( $self->fetch ( 'x2dt', $res->[2] ), $s->{lang} );
 
 $s->{earliestid} = $self->fetch ( 'x2id', $res->[2] );
  
 $self->render ( template => 'page/info' );

}

1;