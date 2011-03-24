#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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

package Catz::Action::Browse;

use strict;
use warnings;

use parent 'Catz::Action::Present';

use Catz::Data::DB;
use Catz::Model::Meta;
use Catz::Model::Photo;
use Catz::Model::Vector;

sub browse {

 my $self = shift;
 
 my $stash = $self->{stash};
   
 my ( $lower, $upper ) = split /\-/, $stash->{range};
 
 # verify the range
 ( ( $lower > 0 ) and ( $upper < meta_maxx + 1 ) and ( ( $lower + 9 ) <= $upper ) and
  ( ( $upper - $lower ) <= 49 ) and ( ( $lower - 1 ) % 5 == 0 ) and ( $upper % 5 == 0 ) )
  or $self->render(status => 404);

 $self->args; 
    
 # set this amount of photos to both stash and session
 # so session gets changed automatically by url 
 my $perpage = $upper - $lower + 1;
 $stash->{thumbsperpage} = $perpage; 
 $self->session( thumbsperpage => $perpage );
 
 my ( $total, $page, $pages, $from, $to, $first, $prev, $next, $last, $xs ) = 
  @{ vector_pager( 
   $lower, $upper, $perpage, $stash->{lang}, @{ $stash->{args_array} }  
  ) };
       
 $total == 0 and $self->render(status => 404); # no photos found by search 
 scalar @{ $xs } == 0 and $self->render(status => 404); # no photos in this page
  
 $stash->{total} = $total;
 $stash->{page} = $page;
 $stash->{pages} = $pages;
 $stash->{perpage} = $perpage;
 $stash->{from} = $from;
 $stash->{to} = $to;
 $stash->{first} = $first;
 $stash->{prev} = $prev;
 $stash->{next} = $next;
 $stash->{last} = $last;

 my $thumbs = photo_thumbs ( $stash->{lang}, $xs ) ;
        
 $self->{stash}->{thumbs} = $thumbs;
 $self->{stash}->{formation} = 'wide';
 $stash->{showmeta} = 1;
     
 $self->render( template => 'page/browse' );
    
}

1;