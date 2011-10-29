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

use 5.12.0; use strict; use warnings;

use parent 'Catz::Ctrl::Present';

use Catz::Data::Search;

use Catz::Util::String qw ( clean noxss trim );

sub search_ok {

 # verifies and processed a search parameter
 # and copies it to stash

 my ( $self, $par, $var ) = @_; my $s = $self->{stash};
 
 $s->{$var} = $self->param ( $par ) // undef;
 
 defined $s->{ $var } or return $self->done;
 
 # length sanity check 1/2
 length $s->{ $var } > 2000 and return $self->fail ( 'SEARCH_LONG' );

 # it appears that browsers typcially send UTF-8 encoded 
 # data when the origin page is UTF-8 -> we decode the data now   
 utf8::decode ( $s->{$var} );

 # length sanity check 2/2
 length $s->{ $var } > 1234 and return $self->fail ( 'SEARCH_LONG' );
 
 # remove all unnecessary whitespaces     
 $s->{ $var } = noxss clean trim $s->{ $var };
    
 $s->{ $var } eq '' and $s->{ $var } = undef; 

 return $self->done;

}

sub search_args {

 # prorcess a search string to arguments
 
 my $self = shift; my $s = $self->{stash};
 
 # convert search to an argument array 
 $s->{args_array} = search2args ( $s->{what} );
  
 # store argument count separately to stash
 $s->{args_count} = scalar @{ $s->{args_array} };
 
 return $self->done;  
 
}

sub urlother {

 my $self = shift; my $s = $self->{stash};
 
 $s->{urlother} = $self->fuseq ( $s->{langaother}, $s->{action} );
 
 if ( $s->{what} ) {
 
  if ( defined $s->{origin} and ( $s->{origin} eq 'id' ) ) {
  
   $s->{urlother} .= "/$s->{id}?q=" . $self->enurl ( $s->{what} );
  
  } else {
  
   $s->{urlother} .= '?q=' .  $self->enurl ( $s->{what} );
  
  } 
 
 } elsif ( $s->{init} ) {

  $s->{urlother} .= '?i=' .  $self->enurl ( $s->{init} );
 
 } else {

  $s->{urlother} .=  ( 
   ( $s->{origin} and $s->{origin} eq 'id' ) ?  '/' . $s->{id} . '/' : '/' 
  );
  
 }
 
 return $self->done;

}

sub pattern {

 my $self = shift; my $s = $self->{stash};

 $self->f_init or return $self->fail;
 
 $s->{runmode} = 'search';
 
 $self->search_ok ( 'q', 'what' ) 
  or return $self->fail ( 'PARAM', 'q' );
 
 if ( $s->{action} eq 'display' ) {
 
  $s->{what} or return $self->fail ( 'SEARCH' );
 
 }
 
 $self->search_ok ( 'i', 'init' ) or 
  return $self->fail ( 'PARAM', 'i' );
  
 $s->{what} and do { # if a search is available

  $self->f_map or return $self->fail;
 
  $self->search_args or return $self->fail;
      
  if ( 
   $s->{args_count} > 0 and # there are arguments
   $s->{args_count} <= 50 and # not more than 25 pairs   
   $s->{args_count} % 2 == 0 # args must appear in pairs  
  ) {
   $self->f_origin or return $self->fail ( 'ORIGIN' );  
  } else { $s->{x} = undef; $s->{id} = undef; }

 };
 
 $self->urlother or return $self->fail;
  
 return $self->done;
  
}

sub guide {

 # a simple fallback sub to provide the search page

 my $self = shift; my $s = $self->{stash};
 
 $s->{total} = 0;

 # if giving guide but search was made then it's not found -> not for robots  
 $s->{what} and do { $s->{meta_index} = 0; $s->{meta_follow} = 0 };
 
 # no robots if init is given
 $s->{init} and do {  $s->{meta_index} = 0; $s->{meta_follow} = 0 };
 
 $self->output ( 'page/search' );

 return $self->done;

} 

sub search { 

 my $self = shift; my $s = $self->{stash};
 
 $self->pattern or return $self->fail ( 'SEARCH_LOAD' );
  
 if ( $s->{x} and $s->{id} ) { # we have results 
 
  $self->multi or return $self->fail ( 'MULTI_LOAD' );
 
 } else { # no results, the fallback is to show the search page 
  
  $self->guide or return $self->fail;  

 } 

}

sub display {
 
 my $self = shift; my $s = $self->{stash};
  
 $self->pattern or return $self->fail ( 'SEARCH_LOAD' );
 
 if ( $s->{x} and $s->{id} ) { # we have results
 
  $self->single or return $self->fail ( 'SINGLE_LOAD' );
  
 } else {  
 
  return $self->fail ( 'NODATA' );
 
 }
  
}

1;