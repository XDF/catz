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

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Base';

use List::MoreUtils qw ( any );

use Catz::Data::Conf;
use Catz::Data::List qw ( list_matrix );
use Catz::Data::Search;

use Catz::Util::Number qw ( round );

sub find {

 my $self = shift; my $s = $self->{stash};
  
 $s->{what} = $self->param( 's' ) // undef;
  
 # it appears that browsers typcially send UTF-8 encoded data
 # when the origin page is UTF-8 -> we decode now
 utf8::decode ( $s->{what} );
 
 $s->{find} = []; # empty result array as default
 
 ( length $s->{what} > 0 ) and ( length $s->{what} < 51 ) and   
   $s->{find} = $self->fetch ( 'locate#find', $s->{what}, 50 );

 $self->f_map or return $self->fail ( 'f_map exit' );
 
 $self->output ( 'block/find' );

}

sub list {

 my $self = shift; my $s = $self->{stash};

 $s->{matrix} = list_matrix;
  
 # verify that the subject is known
 $s->{matrix}->{$s->{subject}} 
  or return $self->fail ( 'subject not in matrix' ); 
 
 # verify that the mode is known for this subject
 ( any { $s->{mode} eq $_ } @{ $s->{matrix}->{$s->{subject}}->{modes} } )
  or return $self->fail ( 'subject and mode not in matrix' ); 
 
 $s->{urlother} = $self->fuse ( 
  $s->{langaother} , $s->{action} , $s->{subject} , $s->{mode} 
 );
   
 my $res = $self->fetch( 'locate#full', $s->{subject}, $s->{mode} );
  
 $s->{total} = $res->[0] // 0;
 $s->{idx} = $res->[1] // undef;
 $s->{sets} = $res->[2] // undef;

 $s->{total} > 0 or return $self->fail ( 'no data' );
 
 $self->f_map or return $self->fail ( 'f_map exit' );
      
 $self->output ( 'page/list1' );
 
}

sub lists {

 my $self = shift; my $s = $self->{stash};

 $s->{matrix} = list_matrix;
    
 $s->{urlother} = $self->fuse ( $s->{langaother}, $s->{action} );  
   
 ( $s->{prims} = $self->fetch( 'locate#prims' ) ) or
   return $self->fail ( 'no lists found' ); 
        
 $self->output ( 'page/lists' );
 
}

1;
