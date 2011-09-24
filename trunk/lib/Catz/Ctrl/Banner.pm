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

package Catz::Ctrl::Banner;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use Catz::Core::Conf;

sub banner {

 my $self = shift; my $s = $self->{stash};
 
 ( $s->{pri} and $s->{sec} ) or return $self->not_found;
 
 $self->fetch('pair#verify',$s->{pri}) or 
  return $self->not_found;

 # we use height parameter as thumbheight  
 $s->{thumbsize} = $s->{height};

 $s->{runmode} = 'pair';
 $s->{action} = 'browse'; # faking to make links to
 
 $s->{sec} = $self->decode ( $s->{sec} ); # using decode helper
  
 $s->{xs} = $self->fetch ( "pair#array_rand", $s->{pri}, $s->{sec} );
 
 scalar @{ $s->{xs} } < 1 and return $self->not_found;
 
 ( $s->{thumbs}, $s->{earliest}, $s->{latest} ) = 
  @{ $self->fetch( 'photo#thumb', @{ $s->{xs} } ) };
  
 # no we have enough information to detect how the banner should be made
 # and what is the default size
 
 $s->{texts} = $self->fetch ( 'photo#texts', @{ $s->{xs} } );
 
 $self->render ( template => 'page/banner' );

}

sub embed {

 my $self = shift; my $s = $self->{stash};
 
 ( $s->{pri} and $s->{sec} ) or return $self->not_found;
 
 $self->fetch('pair#verify',$s->{pri}) or 
   $self->render ( text => '' );
  
 $self->render ( template => 'block/embedder' );

}

sub preview {

 my $self = shift; my $s = $self->{stash};
 
 ( $s->{pri} and $s->{sec} ) or return $self->not_found;
 
 $self->fetch('pair#verify',$s->{pri}) or 
   $self->render ( text => '' );
  
 $self->render ( template => 'block/previewer' );

}

1;