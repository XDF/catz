#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2014 Heikki Siltala
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

package Catz::Ctrl::Bulk;

use 5.14.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use Catz::Data::Conf;

use Catz::Util::String qw ( lcc );

sub photolist {

 my $self = shift;
 my $s    = $self->{ stash };

 length $s->{ langa } > 2 and return $self->fail ( 'setup set so stopped' );

 $s->{ forcefi } and $s->{ lang } = 'fi';

 $s->{ date } = $self->param ( 'd' ) // undef;
 $s->{ loc }  = $self->param ( 'l' ) // undef;
 
 $s->{ site } = conf ( "url_site" );

 if ( $s->{ date } and $s->{ loc } ) {

  utf8::decode ( $s->{ date } );
  utf8::decode ( $s->{ loc } );

  ( ( length $s->{ date } == 8 ) or ( length $s->{ date } ) == 10 )
   or return $self->fail ( 'illegal parameter value' );

  if ( length $s->{ date } == 10 ) {

   $s->{ date } =~ m|(\d{4})\-(\d{2})\-(\d{2})|;

   ( $1 and $2 and $3 ) or return $self->fail ( 'illegal parameter value' );

   $s->{ date } = "$1$2$3";

  }

  ( ( length $s->{ loc } > 100 ) or ( length $s->{ loc } < 1 ) )
   and return $self->fail ( 'illegal parameter value' );

  $s->{ loc } = lcc $s->{ loc };

  $s->{ loc } =~ tr|והצü|aaou|;

  $s->{ folder } = "$s->{date}$s->{loc}";

  $s->{ aid } = $self->fetch ( 'bulk#folder', $s->{ folder } ) // undef;

  $s->{ aid } or return $self->fail ( 'folder not found' );

  $s->{ list } = $self->fetch ( 'bulk#photolist', $s->{ aid } );

  $self->output ( 'bulk/photolist', 'txt' );

 } ## end if ( $s->{ date } and ...)
 else {    # use free list

  $s->{ date } and return $self->fail ( 'illegal parameters' );
  $s->{ loc }  and return $self->fail ( 'illegal parameters' );
  
  # this is a pseudo parameter passed to the model that contains the
  # current dt down to an hour so this parameter changes in every
  # hour and this makes cached model data live at most an hour
  my $pseudo = substr ( $self->dt, 0, -4 );

  $s->{ list } = $self->fetch ( 'bulk#freelist', $pseudo );
  
  $self->output ( 'bulk/freelist', 'txt' );

 }

} ## end sub photolist

1;
