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

package Catz::Model::News;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Model';

use Catz::Util::Time qw ( dtexpand );

sub _all {

 my $self = shift; my $lang = $self->{lang};
      
 $self->dball( 
  "select dt,title_$lang,text_$lang,url from mnews order by dt desc" 
 );
  
}

sub _latest {

 my ( $self, $limit ) = @_;
      
 my $res = $self->all;
   
 # if less news than requested then downsize the request
 scalar @$res < $limit and $limit = scalar @$res;
  
 [ @{ $res } [ 0 .. $limit - 1 ] ];
 
}

1;