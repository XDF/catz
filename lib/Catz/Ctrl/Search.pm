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

package Catz::Ctrl::Search;

use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use Catz::Model::Photo;
use Catz::Data::Search;
use Catz::Util::String qw ( deurl );


sub search {

 my $self = shift; my $s = $self->{stash};
   
 $s->{args_array} = [];
 $s->{args_count} = 0;
 $s->{found} = 0;
 $s->{args_string} = undef;
 $s->{thumb} = undef;
 
 length ( $self->param('what') ) > 2000 and $self->not_found and return;
 
 $s->{what} = $self->param('what') // undef;
   
 if ( defined $s->{what} ) {
 
  ( $s->{what}, $s->{args_array}, $s->{args_string} ) = search2args ( $s->{what} );
  
  $s->{args_count} = scalar ( @{ $s->{args_array} } );
        
  my @set = @{ $self->fetch ( 'vector_array_rand', @{ $s->{args_array} } ) };
  
  $s->{found} = scalar @set;
  
  scalar @set > 12 and @set = @set[ 0 .. 12 ];
   
  my $th = $self->fetch ( 'photo_thumb', @set );
  
  $s->{thumb} = $th->[0];
  
  $s->{earliest} = $th->[1];
  $s->{latest} = $th->[2];        
   
 }
 
 $self->render ( template => 'page/search' );

}
1;
