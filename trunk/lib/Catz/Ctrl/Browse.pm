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

use strict;
use warnings;

use parent 'Catz::Ctrl::Present';

sub browse {

 my $self = shift;
 
 my $stash = $self->{stash};
   
 my ( $lower, $upper ) = split /\-/, $stash->{range};
 
 my $maxx = $self->fetch ( 'maxx' );
 
 # verify the range
 ( ( $lower > 0 ) and ( $upper < $maxx + 1 ) and ( ( $upper - $lower ) > 8 ) and
  ( ( $upper - $lower ) < 50 ) and ( ( $lower - 1 ) % 5 == 0 ) and ( $upper % 5 == 0 ) )
  or $self->render_not_found;

 $stash->{path} and do { 
 
  my @args = split /\//, $stash->{path};
  
  ( scalar ( @args ) % 2 ) == 0 or do { $self->render_not_found; return; }; 
  
  $stash->{args} = \@args;
  
 };  
         
 # set this amount of photos to both stash and session
 # so session gets changed automatically by url 
 my $perpage = $upper - $lower + 1;
 $stash->{thumbsperpage} = $perpage; 
 $self->session( thumbsperpage => $perpage );
 
 my ( $total, $page, $pages, $from, $to, $first, $prev, $next, $last, $xs ) = 
  @{ $self->fetch('vector_pager', 
   $lower, $upper, $perpage, @{ $stash->{args} }  
  ) };
       
 $total == 0 and $self->render_not_found; # no photos found by search 
 scalar @{ $xs } == 0 and $self->render_not_found; # no photos in this page
  
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

 my $thumbs = $self->fetch('photo_thumbs', $xs ) ;
        
 $self->{stash}->{thumbs} = $thumbs;
 $self->{stash}->{formation} = 'wide';
 $stash->{showmeta} = 1;
     
 $self->render( template => 'page/browse' );
    
}

1;