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
use Catz::Model::Vector;
use Catz::Data::Search;
use Catz::Util::String qw ( enurl );

sub search {

 my $self = shift;
 
 my $stash = $self->{stash};
 
 my $what = $stash->{what};
 
 $stash->{what} = $stash->{what} // '';
 $stash->{args} = undef;
 $stash->{found} = 0;
 
 if ( $what ) {
 
  $stash->{args} = search2args ( $what );
  
  $stash->{found} = vector_count ( $stash->{lang}, @{ $stash->{args} } );
  
  my $xs = vector_array_random ( $stash->{lang}, @{ $stash->{args} } );
  
  # limit random samples to 30 by slicing the arrayref
  ( scalar ( @{ $xs } ) > 30 ) and $xs = [ @$xs[0..29] ];
      
  $stash->{thumbs} = photo_thumbs ( $stash->{lang}, $xs );
  $stash->{formation} = 'asdfasdf';
  $stash->{path} = join '/', map { enurl $_ } @{ $stash->{args} }; 
 
 } else {
 
  $stash->{thumbs} = undef;
 
 }
 
 
 
 $self->render ( template => 'page/search' );

}
1;
