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

package Catz::Ctrl::Inspect;

use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

sub process_args {

 my $self = shift; my $s = $self->{stash};
 
 my @args = ();

 my $found = 0;

 my $pri = $self->fetch ( 'pri' );

 foreach my $key ( $self->param ) {

  any { $_ eq $key } @{ $pri } and do {

   my @vals = $self->param( $key );

   foreach my $val ( @vals ) {
 
    $found++;
    push @args, $key; 
    push @args, $val;

   }

  };

 }

 $found == 1 or return 0;

 $s->{args_string} = $args[0] . '=' . $args[1];  
 $s->{args_count} = scalar @args;
 $s->{args_array} = [ map { deurl $_ } @args ];

}

sub inspect {

 my $self = shift; my $s = $self->{stash};
  
 $self->process_args or $self->not_found and return;

 $self->render ( text => 
  $self->fetch ( 'vector_inspect', @{ $s->{args_array} } ) 
 );

}

1;