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

use 5.12.0;
use strict;
use warnings;

use parent 'Catz::Ctrl::Present';

use Catz::Data::Search;

sub urlother {

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ urlother } = $self->fuseq ( $s->{ langaother }, $s->{ action } );

 if ( $s->{ what } ) {

  if ( defined $s->{ origin } and ( $s->{ origin } eq 'id' ) ) {

   $s->{ urlother } .= "/$s->{id}?q=" . $self->enurl ( $s->{ what } );

  }
  else {

   $s->{ urlother } .= '?q=' . $self->enurl ( $s->{ what } );

  }

 }
 elsif ( $s->{ init } ) {

  $s->{ urlother } .= '?i=' . $self->enurl ( $s->{ init } );

 }
 else {

  $s->{ urlother } .= (
   ( $s->{ origin } and $s->{ origin } eq 'id' )
   ? '/' . $s->{ id } . '/'
   : '/'
  );

 }

 return $self->done;

} ## end sub urlother

sub pattern {

 my $self = shift;
 my $s    = $self->{ stash };

 $self->f_init or return $self->fail ( 'f_init exit' );

 $s->{ runmode } = 'search';

 $self->f_search_ok ( 'q', 'what' )
  or return $self->fail ( 'illegal parameter' );

 if ( $s->{ action } eq 'display' ) {

  $s->{ what } or return $self->fail ( 'no search' );

 }

 $self->f_search_ok ( 'i', 'init' )
  or return $self->fail ( 'illegal init parameter' );

 $s->{ what } and do {    # if a search is available

  $self->f_map or return $self->fail ( 'f_map exit' );

  $self->f_search_args or return $self->fail ( 'search_args exit' );

  if (
   $s->{ args_count } > 0   and    # there are arguments
   $s->{ args_count } <= 50 and    # not more than 25 pairs
   $s->{ args_count } % 2 == 0     # args must appear in pairs
   )
  {
   $self->f_origin or return $self->fail ( 'illegal search' );
  }
  else { $s->{ x } = undef; $s->{ id } = undef; }

 };

 $self->urlother or return $self->fail ( 'urlother exit' );

 return $self->done;

} ## end sub pattern

sub guide {

 # a simple fallback sub to provide the search page

 my $self = shift;
 my $s    = $self->{ stash };

 $s->{ total } = 0;

 # if giving guide but search was made then it's not found -> not for robots
 $s->{ what } and do { $s->{ meta_index } = 0; $s->{ meta_follow } = 0 };

 # no robots if init is given
 $s->{ init } and do { $s->{ meta_index } = 0; $s->{ meta_follow } = 0 };

 $self->output ( 'page/search' );

 return $self->done;

}

sub search {

 my $self = shift;
 my $s    = $self->{ stash };

 $self->pattern or return $self->fail ( 'pattern exit' );

 if ( $s->{ x } and $s->{ id } ) {    # we have results

  $self->multi or return $self->fail ( 'multi exit' );

 }
 else {

  # no results, the fallback is to show the search page

  $self->guide or return $self->fail ( 'guide exit' );

 }

} ## end sub search

sub display {

 my $self = shift;
 my $s    = $self->{ stash };

 $self->pattern or return $self->fail ( 'pattern exit' );

 if ( $s->{ x } and $s->{ id } ) {    # we have results

  $self->single or return $self->fail ( 'single exit' );

 }
 else { return $self->fail ( 'no data' ) }

}

1;
