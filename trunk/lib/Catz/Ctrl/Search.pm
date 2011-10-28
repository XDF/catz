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

use parent 'Catz::Ctrl::Base';

use Catz::Data::Search;

use Catz::Util::String qw ( clean noxss trim );

sub search_ok {

 # verifies a search pattern, returns
 #  1 in success 
 #  0 on error

 my ( $self, $par, $var ) = @_; my $s = $self->{stash};
 
 $s->{$var} = $self->param($par) // undef;
 
 # reject undefined parameter
 defined $s->{$var} or return 0;
 
 # length sanity check
 length $s->{$var} > 1234 and return 0;

 # it appears that browsers typcially send UTF-8 encoded 
 # data when the origin page is UTF-8 -> we decode the data now   
 utf8::decode ( $s->{$var} );

 # remove all unnecessary whitespaces     
 $s->{$var} = noxss clean trim $s->{$var};
    
 # we don't allow just ''
 $s->{$var} eq '' and return 0;

}

sub search_pre {

 # prepares the search to arguments, returns
 #  1 in success 
 #  0 on error
 
 my $self = shift; my $s = $self->{stash};
 
 # convert search to argument array 
 $s->{args_array} = search2args ( $s->{what} );
  
 # store argument count separately
 $s->{args_count} = scalar @{ $s->{args_array} };
 
 if ( 
  $s->{args_count} > 0 and # there are arguments
  $s->{args_count} <= 50 and # not more than 25 pairs   
  $s->{args_count} % 2 == 0 #args appear in pairs  
  ) {
  
   return 1; # ok
  
 }
 
 
 
 # clear the errorneous search to 
 # prevent troubles later
 $s->{args_array} = [];
 $s->{args_count} = 0;
  
 return 0; # error 
 
}

sub search_urlother {

 my $self = shift; my $s = $self->{stash};

 $s->{urlother} =  '/' . $s->{langaother} . '/' . $s->{action};
 
 if ( $s->{what} ) {
 
  if ( $s->{origin} eq 'id' ) {
  
   $s->{urlother} .= '/' . $s->{id} . '?q=' .  $self->enurl ( $s->{what} );
  
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
 
 return 1;

}

sub pattern {

 my $self = shift; my $s = $self->{stash};

 $self->init or return 0;
 
 $s->{runmode} = 'search';
 
 $self->search_ok ( 'q', 'what' );
 $self->search_ok ( 'i', 'init' );
 
 # no robots if init is given
 $s->{init} and do {  $s->{meta_index} = 0; $s->{meta_follow} = 0 };
 
 $s->{what} and do {
 
  $self->search_pre or return 0;
   
  $self->load or return 0;
 
  $self->origin or return 0;
  
 };
 
 $self->search_urlother or return 0;
  
 return 1; # ok
  
}

sub guide {

 # simple fallback method to provide the search page

 my $self = shift; my $s = $self->{stash};
 
 $s->{total} = 0;

 # if giving guide but search was made then it's not found -> not for robots
  
 $s->{what} and do {  $s->{meta_index} = 0; $s->{meta_follow} = 0 };
 
 $self->render( template => 'page/search', format => 'html' );

 return 1;

} 

sub search { 

 my $self = shift; my $s = $self->{stash};
 
 $self->pattern or return $self->render_not_found;
 
 if ( $s->{x} and $s->{id} ) { # we have results 
 
  $self->multi or return $self->render_not_found; 
  
 } else { # no results, fallback to search page 
  
  $self->guide or return $self->render_not_found;  

 } 

}

sub display {
 
 my $self = shift; my $s = $self->{stash};
 
 # force that q is present
 $self->param('q') or return $self->render_not_found;
 
 $self->pattern or return $self->render_not_found;
 
 if ( $s->{x} and $s->{id} ) { # we have results
 
  $self->single or return $self->render_not_found; 
  
 } else {  return $self->render_not_found }
  
}

1;