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

use strict;
use warnings;

use parent 'Catz::Ctrl::Present';

sub inspect {

 my $self = shift;
  
 my $stash = $self->{stash};

 $stash->{path} and do { 
 
  my @args = split /\//, $stash->{path};
  
  ( scalar ( @args ) % 2 ) == 0 or do { $self->render_not_found; return; }; 
  
  $stash->{args} = \@args;
  
 };
          
 my $perpage =  $stash->{'thumbsperpage'};
  
 my ( $total, $pos, $x, $page, $first, $prev, $next, $last ) = 
  @{ 
     $self->fetch('vector_pointer', 
      $stash->{album}, $stash->{n}, $perpage, @{ $stash->{args} } 
     ) 
   }; 
  
 my $details = $self->fetch( 'photo_details', $x );

 my $texts =  $self->fetch( 'photo_texts', $x );

 my $image =  $self->fetch( 'photo_image', $x );
 
 $self->{stash}->{total} = $total;
 $self->{stash}->{pos} = $pos;
 $self->{stash}->{page} = $page;
 $self->{stash}->{perpage} = $perpage;
 $self->{stash}->{first} = $first;
 $self->{stash}->{prev} = $prev;
 $self->{stash}->{next} = $next;
 $self->{stash}->{last} = $last;
 
 $self->{stash}->{texts} = $texts;
 $self->{stash}->{details} = $details;
 $self->{stash}->{image} = $image;
     
 $self->render( template => 'page/inspect' );

}

sub show {

 my $self = shift;
  
 my $stash = $self->{stash};

 $stash->{path} and do { 
 
  my @args = split /\//, $stash->{path};
  
  ( scalar ( @args ) % 2 ) == 0 or do { $self->render_not_found; return; }; 
  
  $stash->{args} = \@args;
  
 };
          
 my $perpage =  $self->session('thumbsperpage');
  
 my ( $total, $pos, $x, $page, $first, $prev, $next, $last ) = 
  @{ 
     $self->fetch( 'vector_pointer', 
      $stash->{album}, $stash->{n}, $perpage, @{ $stash->{args} } 
     ) 
   }; 
  
 my $details = $self->fetch ( 'photo_details', $x );

 my $texts = $self->fetch ( 'photo_texts', $x );

 my $image = $self->fetch ( 'photo_image', $x );
 
 $self->{stash}->{total} = $total;
 $self->{stash}->{pos} = $pos;
 $self->{stash}->{page} = $page;
 $self->{stash}->{perpage} = $perpage;
 $self->{stash}->{first} = $first;
 $self->{stash}->{prev} = $prev;
 $self->{stash}->{next} = $next;
 $self->{stash}->{last} = $last;
 
 $self->{stash}->{texts} = $texts;
 $self->{stash}->{details} = $details;
 $self->{stash}->{image} = $image;
     
 $self->render( template => 'page/show' );

}

1;