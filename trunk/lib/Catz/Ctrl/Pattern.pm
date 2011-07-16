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

package Catz::Ctrl::Pattern;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Ctrl::Present';

use Catz::Data::Search;

use Catz::Util::String qw ( clean trim );

sub pattern {

 my $self = shift; my $s = $self->{stash};

 $s->{runmode} = 'search';
  
 $s->{pri} = undef; $s->{sec} = undef;
 
 $s->{refines} = undef;
 $s->{breedernat} = undef;
 $s->{breederurl} = undef;
 $s->{origin} = 'none';  # to indiate that origin was not processed
 $s->{trans} = undef; 
 $s->{viz_rank} = undef;
 
 # defaults
 $s->{args_array} = [];
 $s->{args_count} = 0;

 # search-related input parameters are fetched 
 $s->{what} = $self->param('q') // undef;
 $s->{init} = $self->param('i') // undef;
 
 $s->{what} and do {
 
  # sanity check
  ( length $s->{what} > 1234 ) and return 0;

  # remove all unnecessary spaces   
  $s->{what} = clean trim $s->{what};
  
  # it appears that browsers typcially send UTF-8 encoded 
  # data when the origin page is UTF-8 -> we decode the data now   
  utf8::decode ( $s->{what} );
  
  # we don't allow '', we set it to undef
  $s->{what} eq '' and $s->{what} = undef;
 
 };
 
 $s->{init} and do {
 
  # sanity check
  ( length $s->{init} > 1234 ) and return 0;

  # remove all unnecessary spaces   
  $s->{init} = clean trim $s->{init};
  
  # it appears that browsers typcially send UTF-8 encoded 
  # data when the origin page is UTF-8 -> we decode the data now   
  utf8::decode ( $s->{init} );

  # not for robots when with init parameter
  $s->{init} and do {  $s->{meta_index} = 0; $s->{meta_follow} = 0 };

  # we don't allow '', we set it to undef
  $s->{init} eq '' and $s->{init} = undef;
 
 };
    
 if ( $s->{what} ) { # search was given
  
  # convert search to argument array 
  $s->{args_array} = search2args ( $s->{what} );
  
  $s->{args_count} = scalar @{ $s->{args_array} };
  
  if ( 
   $s->{args_count} > 0 and # there are args
   $s->{args_count} <= 50 and # max 25 pairs accepted   
   $s->{args_count} % 2 == 0 and # args come in as pairs 
   $self->fetch('search#verify_args',@{$s->{args_array}}) # all pris are ok 
  ) {
  
   $self->pre or return 0;
  
  } else {
  
   # if illegal pris given in the search then "reset" the search to empty
   $s->{args_array} = [];
   $s->{args_count} = 0;
   
  }

 }
  
 # prepare the url for the page of the other language
 
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

 return 1; # ok
  
}

sub guide {

 # simple fallback method to provide the search page

 my $self = shift; my $s = $self->{stash};
 
 $s->{total} = 0;

 # if giving guide but search was made then it's not found -> not for robots 
 $s->{what} and do {  $s->{meta_index} = 0; $s->{meta_follow} = 0 };
 
 $self->render( template => 'page/search' );

 return 1;

} 

sub search { 

 my $self = shift; my $s = $self->{stash};
 
 $self->pattern or ( $self->not_found and return );
 
 if ( $s->{x} and $s->{id} ) { # we have results 
 
  $self->multi or ( $self->not_found and return ); 
  
 } else { # no results, fallback to search page 
  
  $self->guide or ( $self->not_found and return );  

 } 

}

sub display {
 
 my $self = shift; my $s = $self->{stash};
 
 # display requires always a query
 $self->param('q') or ( $self->not_found and return );
 
 $self->pattern or ( $self->not_found and return );
 
 if ( $s->{x} and $s->{id} ) { # we have results
 
  $self->single or ( $self->not_found and return ); 
  
 } else { $self->not_found and return }
  
}

1;