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

package Catz::Ctrl::Viz;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use Catz::Data::Dist;

sub vizpre {

 # prepare visualization related stuff


 return $self->ok;

}
 
sub vizdist {

 # get stuff required by distribution visualization a.k.a the pie diagram

 my $self = shift; my $s = $self->{stash};

 $s->{dist} = dist;
 
 $s->{dist_count_all} = $self->fetch ( "all#maxx" ); 
  
 foreach my $key ( @{ $s->{dist}->{dblock_all} ) {
  
  # merge real request arguments with distribution arguments
  my @sargs = ( 
   @{ $s->{args_array} }, @{ $s->{dist}->{dblock}->{$key} }  
  );
  
  # prepare coverage counts
  ( $s->{ 'dist_count_'. $key } = $self->fetch ( "search#count", @sargs ) )
   or return $self->fail 
    'failed to retrieve count for distribution '$key'|jakauman '; 
    
  # prepare coverage drill parameters to make urls     
  $s->{ 'dist_param_'. $key } = args2search @sargs;
  
 }

 return $self->ok;  
  
}