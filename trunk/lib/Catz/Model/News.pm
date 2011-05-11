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

use parent 'Catz::Model::Base';

use 5.10.0;
use strict;
use warnings;

sub _all {

 my $self = shift; my $lang = $self->{lang};
     
 $self->dball( "select dt,title_$lang from mnews order by dt desc" );
 
}

sub _latest {

 my ( $self, $limit ) = @_;
   
 $limit or $limit = 5; # default is this
   
 my $res = $self->all;
 
 scalar @$res == 0 and return $res;
  
 # if less news than requested then downsize the request
 scalar @$res < $limit and $limit = scalar @$res;
  
 [ @{ $res } [ 0 .. $limit - 1 ] ];
 
}

sub _one {

 my ( $self, $dt ) = @_; my $lang = $self->{lang};
  
 my $res = $self->dbrow ( "select dt,title_$lang,text_$lang from mnews where dt=?", $dt );
 
 my $prev = $self->dbone ( "select max(dt) from mnews where dt<?", $dt );
 
 my $next = $self->dbone ( "select min(dt) from mnews where dt>?", $dt );

 # returning dt, title, text, dt to prev (if any), dt to next (if any)

 [ $res->[0], $res->[1], $res->[2], $prev, $next ]; 
 
}

1;