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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use List::MoreUtils qw ( any );

use Catz::Core::Conf;
use Catz::Data::List qw ( list_matrix );
use Catz::Data::Search;
use Catz::Util::Number qw ( round );

sub find {

 my $self = shift; my $s = $self->{stash};

 $s->{what} = $self->param( 'what' ) // undef;
 
 # it appears that browsers typcially send UTF-8 encoded data
 # when the origin page is UTF-8 -> we decode now
 utf8::decode ( $s->{what} );

 $s->{mapdual} = $self->fetch ( 'map#dual' );
 
 if ( length $s->{what} > 50 ) {
 
  $s->{find} = [];
 
 } else {
     
  $s->{find} = $self->fetch ( 'locate#find', $s->{what}, 50 );

 }

 $self->render( template => 'block/find' );

}

sub list {

 my $self = shift; my $s = $self->{stash};

 $s->{matrix} = list_matrix;
  
 # verify that the subject is known
 $s->{matrix}->{$s->{subject}} or ( $self->not_found and return );
 
 # verify that the mode is known for this subject
 ( any { $s->{mode} eq $_ } @{ $s->{matrix}->{$s->{subject}}->{modes} } )
  or ( $self->not_found and return );
  
 $s->{urlother} =  
  '/' . $s->{langother} . '/' . $s->{action} . '/' . 
  $s->{subject} . '/' . $s->{mode} . '/';
   
 my $res = $self->fetch( 'locate#full', $s->{subject}, $s->{mode} );
  
 $s->{total} = $res->[0];
 $s->{idx} = $res->[1];
 $s->{sets} = $res->[2];

 $s->{total} > 0 or ( $self->not_found and return );
 
 $s->{maplink} = $self->fetch ( 'map#link' );
 $s->{mapview} = $self->fetch ( 'map#view' );
 $s->{mapdual} = $self->fetch ( 'map#dual' );
      
 $self->render(template => 'page/list');
 
}

1;
