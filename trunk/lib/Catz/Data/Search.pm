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

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( search2args args2search );

use Text::ParseWords;

use Catz::Util::String qw ( enurl trim clean );

# the default pri key used if none is given in the query
use constant DEFAULT => 'any';

sub search2args { # covert a search parameter to argument list

 my $str = shift;
    
 $str =~ s|\"\"|\\\"|g; # " are input as "" and now converted to \"
 $str =~ s|\'|\\\'|g; # ' can't be passed to Text::ParseWords without \ before
 
 # smart split to words allowing quotation marks on the outer edges   
 my @args = quotewords ( '\s+', 0, $str );
  
 my @out = ();
  
 foreach my $arg ( @args ) {
  
  my $oper = ''; my $key = DEFAULT; my $val = undef; 
  
  if ( $arg =~ /^([+-])(.*)$/ ) { $oper = $1; $arg = $2 }
   
  if ( $arg =~ /^([a-z]+?)\=(.+)$/ ) {
     
   $key = $1; $val = $2; 
 
  } else {
  
   $val = $arg; 

  }
    
  defined $key and defined $val and do {
     
   push @out, "$oper$key"; push @out, $val;
   
  };
       
 }
  
 return \@out;

}

sub args2search { # convert argument list to a search parameter
 
 my $str = ''; my $c = 0;
 
 while ( scalar @_ > 0 ) { # consume the whole array
 
  my $key = shift @_; my $val = shift @_;
  
  # if value has space(s) then put quotation marks around it
  index ( $val, ' ' ) > -1  and $val = qq{"$val"}; 
 
  # if not the first param then put a space to separate from the previous param
  $c > 0 and $str = $str . ' '; 
  
  if ( $key eq DEFAULT ) { $str = $str . $val } 
   else { $str = $str . $key . '=' . $val }
  
  $c++; 
 
 } 
 
 return $str;

}

1;