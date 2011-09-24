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

package Catz::Ctrl::Style;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use Catz::Data::Style;

sub reset { $_[0]->render ( template => 'style/reset', format => 'css' ) }

sub base {

 my $self = shift; my $s = $self->{stash};
  
 $s->{st} = style_get; # copy style hashref to stash for stylesheet processing
  
 $self->render ( template => 'style/base', format => 'css' );

}

sub banner {

 my $self = shift; my $s = $self->{stash};
 
 $s->{palette} = 'bright';
 
 $s->{st} = style_get; # copy style hashref to stash for stylesheet processing
   
 $self->render ( template => 'style/banner', format => 'css' );

}

1;