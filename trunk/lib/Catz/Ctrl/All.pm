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

package Catz::Ctrl::All;

use 5.12.0;
use strict;
use warnings;

use parent 'Catz::Ctrl::Present';

sub all {

 my $self = shift;
 my $s    = $self->{ stash };

 $self->f_init or return $self->fail ( 'init exit' );

 $s->{ runmode } = 'all';

 $self->f_map or return $self->fail ( 'f_map exit' );

 $self->f_origin or return $self->fail ( 'f_origin exit' );

 if ( $s->{ origin } eq 'id' ) {

  $s->{ urlother } =
   $self->fuse ( $s->{ langaother }, $s->{ action }, $s->{ id } );

 }
 else {

  $s->{ urlother } = $self->fuse ( $s->{ langaother }, $s->{ action } );

 }

 return $self->done;

} ## end sub all

sub browseall {

 my $self = shift;

 $self->all or return $self->fail ( 'all exit' );

 $self->multi or return $self->fail ( 'multi exit' );
}

sub viewall {

 my $self = shift;

 $self->all or return $self->fail ( 'all exit' );

 $self->single or return $self->fail ( 'single exit' );

}

1;
