#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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

package Catz::Search;

use strict;
use warnings;

use parent 'Exporter';

use Text::ParseWords;

our @EXPORT = qw ( search2args args2search );

sub search2args {
 
 # parses a search string into a key-value pairs
 # in case of an error, emits standard error tags
 
 # returns two values, the key-pair string and error tag
 
 my $str = shift;
 
 $str =~ s/ +/ /g; # remove multiple adjacent spaces
 $str =~ s/\t+/ /g; # replace multiple adjacent tabs by one space
    
 # smart split to words allowing quotation marks    
 my @args = quotewords ( ' ', 0, $str );
   
 my @out = ();
 
 foreach my $arg ( @args ) {
 
  my $key = undef; my $val = undef;
   
  if ( $arg =~ /^([-+a-z0-9][a-z0-9]{2,}?)\=(.*)$/ ) {
     
   length $2 > 0 and do { $key = $1; $val = $2 }; 
 
  } else { $key = 'text'; $val = $arg; }
  
  defined $key and defined $val and do {
 
   my $fkey = substr ( $key, 0, 1 );
   my $fval = substr ( $val, 0, 1 );
  
   ( $fkey eq '+' or $fkey eq '-' ) and $fval ne '+' and $fval ne '-' and do {
  
    # if key begins with + or - and the value don't then move the char
    # to the beginning of the key
  
    $key = substr ( $key, 1 );
    $val = $fkey . $val;
  
   };
   
   push @out, $key; push @out, $val;
   
  };
   
  
  
     
 }
  
 return \@out;

}

sub args2search {

 my $args = shift;
 
 my @arr = @{ $args }; # we will mungle the array so make a copy of it

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