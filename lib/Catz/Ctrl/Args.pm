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

package Catz::Ctrl::Args;

use 5.12.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use List::MoreUtils qw ( any all );

use Catz::Util::Number qw ( fullnum3 minnum );
use Catz::Util::String qw ( deurl );

sub process_id {
 
 # processes the id parameter from the request
 # sets the photo x to stash

 # returns true in success, return false on reject
 
 my $self = shift; my $s = $self->{stash};
  
 if ( defined $self->param('id') ) { # id was given in request

  my $id = $self->param('id');

  ( length ( $id ) == 6 and $id =~ /^\d+$/ )  or return 0;

  $s->{origin} = 'id'; # mark that this was request had an id
 
  $s->{id} = $id;
  
  $s->{x} = $self->fetch( 'id2x', $id );
    
  $s->{x} or return 0;
          
 } else { # no id given, must find the id of the first photo in the set
 
  $s->{origin} = 'x'; # mark that the id was resolved
 
  $s->{x} = $self->fetch ( 'vector_first', @{ $s->{args_array} } );
      
  $s->{x} or return 0;
  
  $s->{id} = $self->fetch ( 'x2id', $s->{x} );
  
  $s->{id} or return 0; 
   
 }

 $s->{id_string} = '';
 $s->{pad_string} = '';
 
 if ( $s->{origin} eq 'id' ) {
                
   $s->{pad_string} = '?';

   if ( $s->{args_string} ne '' ) {

    $s->{id_string} = '&id=' . $s->{id};

   } else {

    $s->{id_string} = 'id=' . $s->{id};

   }

 } else {
   
  if ( $s->{args_string} ne '' ) {

    $s->{pad_string}= '?';

   }

 } 

 return 1;
}

sub process_args {

 my $self = shift; my $inspect = shift; my $s = $self->{stash};
 
 # processes the get parameters of the request
 # returns true in success, false on reject
   
 my @args = ();
 my $str = '';

 my $pri = $self->fetch ( 'pri' );

 $inspect or push @{ $pri }, 'has'; # if not inspect, accept also 'has' pri

 foreach my $key ( $self->param ) {

  any { $_ eq $key } @{ $pri } and do {

   my @vals = $self->param( $key );

   foreach my $val ( @vals ) {

    $str eq '' or $str .= '&';
    $str .= "$key=$val"; 
    push @args, $key; 
    push @args, $val;

   }

  };

 }

 $s->{args_string} = $str;  
 $s->{args_count} = scalar @args;
 $s->{args_array} = [ map { deurl $_ } @args ];
 
 # inspect accepts only one key-value pair
 $inspect and $s->{args_count} != 2 and return 0;   
   
 return 1;

}





1;