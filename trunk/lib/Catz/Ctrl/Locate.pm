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

use 5.12.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use Catz::Data::Conf;
use Catz::Util::Number qw ( round );

sub process_width {

 my $self = shift; my $s = $self->{stash};

 my $width = $self->param( 'width' ) // 1200;

 $width =~ /^\d{3,4}$/ or $width = 1200;
  
 $width > 599 or $width = 600;
 
 $width < 2001 or $width = 2000;

 $s->{count_thumb} = 30 + 
  round ( ( ( $width - 600 ) / ( 2000 - 600 ) ) * 50 );

 $s->{count_find} = $s->{count_thumb};

}

sub find {

 my $self = shift; my $s = $self->{stash};

 $self->process_width;

 $s->{what} = $self->param( 'what' ) // undef;

 $s->{what} or ( $self->not_found and return );
 
 $s->{find} = $self->fetch ( 'find', $s->{what}, $s->{count_find} );

 $self->render( template => 'block/find' );

}

sub sample {

 my $self = shift; my $s = $self->{stash};

 $self->process_width;

 $s->{what} = $self->param( 'what' ) // undef;

 my @set = ();

 if ( $s->{what} ) {
 
  my $res = $self->fetch ( 'find', $s->{what}, $s->{count_find} );
  
  scalar @$res > 0 and do {

   foreach my $i ( 0 .. ( scalar @$res - 1 ) ) {

    if ( scalar @set < $s->{count_thumb} ) {

     push @set, @{ 
      $self->fetch ( 'vector_array_rand', $res->[$i]->[0], $res->[$i]->[1] )
     };

    }   

   }

  };
  
 } else {

  @set = @{ $self->fetch ( 'vector_array_rand' ) };
     
 }

 if ( scalar @set > $s->{count_thumb} ) {

  @set = @set[ 0 .. $s->{count_thumb} - 1 ];

 }
 
 my $th = $self->fetch ( 'photo_thumb', @set );

 $s->{thumb} = $th->[0];

 $self->render( template => 'block/sample' );

}

sub result {

  my $self = shift; my $s = $self->{stash};
  
  

}


1;
