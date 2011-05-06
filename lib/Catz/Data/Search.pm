#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
# 
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

package Catz::Data::Search;

use 5.12.2;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( search2args args2search );

use Text::ParseWords;

use Catz::Util::String qw ( enurl );

sub search2args {
 
 # parses a search pattern string into key-value -pairs
 
 my $str = shift;
 
 $str =~ s/\s+/ /; # convert all multiple white spaces to one space
 
 my $fixed = $str;
    
 # smart split to words allowing quotation marks    
 my @args = quotewords ( ' ', 0, $str );
   
 my @out = ();
 
 my $path = '';
 
 foreach my $arg ( @args ) {
 
  my $key = undef; my $val = undef;
   
  if ( $arg =~ /^([-+a-z0-9][a-z0-9]{2,}?)\=(.*)$/ ) {
     
   length $2 > 0 and do { $key = $1; $val = $2 }; 
 
  } else { $key = 'out'; $val = $arg; }
  
  defined $key and defined $val and do {
 
   my $fkey = substr ( $key, 0, 1 );
   my $fval = substr ( $val, 0, 1 );
  
   ( $fkey eq '+' or $fkey eq '-' ) and $fval ne '+' and $fval ne '-' and do {
  
    # if key begins with + or - and the value don't then move the char
    # to the beginning of the val
  
    $key = substr ( $key, 1 );
    $val = $fkey . $val;
  
   };
   
   push @out, $key; push @out, $val;
   
   length $path > 0 and $path = $path . "&";
   
   $path .= $key . '=' . enurl ( $val );
   
  };
       
 }
  
 return $fixed, \@out, $path;

}

sub args2search {

 my $args = shift;
 
 my @arr = @{ $args }; # we will mungle the array so we make a copy of it

 my $str = ''; my $c = 0;
 
 while ( scalar @arr > 0 ) { # consume the whole array
 
  my $key = shift @arr; my $val = shift @arr;
 
  # values containing spaces are put into "s 
  index ( $val, ' ' ) > -1 and $val = '"' . $val . '"';

  # if not the first param then put a space to separate from the previous param
  $c > 0 and $str = $str . ' '; 
  
  if ( $key eq 'text' ) { $str = $str . $val } 
   else { $str = $str . $key . '=' . $val }
  
  $c++; 
 
 } 
 
 return $str;

}

1;