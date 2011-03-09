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

package Catz::Action::Base;

use strict;
use warnings;

use parent 'Mojolicious::Controller';

sub redirect_perm {

 # this is a modified copy from Mojolicious core

 my $self = shift;
 my $res = $self->res;
 
 $res->code(301);

 my $headers = $res->headers;
 $headers->location($self->url_for(@_)->to_abs);
 $headers->content_length(0);

 $self->rendered;

 return $self;
 
}
 
sub redirect_temp {

 # this is a modified copy from Mojolicious core  

 my $self = shift;
 my $res = $self->res;
 
 $res->code(302);

 my $headers = $res->headers;
 $headers->location($self->url_for(@_)->to_abs);
 $headers->content_length(0);

 $self->rendered;

 return $self;
 
}


1;
