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

package Catz::Core::Cache;

use 5.10.0; use strict; use warnings;

use CHI;

use parent 'Exporter';

our @EXPORT = qw ( cache_set cache_get );

my $cacheon = $ENV{MOJO_MODE} eq 'production' ? 1 : 0;

my $cache = {};

foreach my $nspace ( qw ( db model page ) ) {

 $cache->{$nspace} = CHI->new ( 
  driver => 'File', namespace => $nspace,
  root_dir => $ENV{MOJO_HOME}.'/cache', depth => 2
 );

}

my $sep = '_';

sub cache_set {

 $cacheon or return;

 my $space = shift; my $exp = pop; my $val = pop;

 $cache->{$space} or return; 

 my $key = join $sep, @_;

 $cache->{$space}->set( $key, $val, $exp );

}

sub cache_get {

 $cacheon or return; 

 my $space = shift; 

 $cache->{$space} or return; 
 
 $cache->{$space}->get( join $sep, @_ );

}

1; 