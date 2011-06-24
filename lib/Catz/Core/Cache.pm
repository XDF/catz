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

# all caching is based on the awesome CHI module
# CHI will allow backend changes without changing the code

use CHI;  

use parent 'Exporter';

# the interface is simple, just set and get
our @EXPORT = qw ( cache_set cache_get );

# caching is activated only production mode
# if not in production mode, cache_set and cache_get 
# are still called but are NOP
my $cacheon = $ENV{MOJO_MODE} eq 'production' ? 1 : 0;

# we create a static set of CHI objects at compile and store them to hashref
my $cache = {};

# creating cache objects for our namespaces 
foreach my $nspace ( qw ( db model page ) ) {

 # we use file backend for the reason that every instance
 # of the application should run completely under its base dir
 # and this is true since we use SQLite + file-based caching

 $cache->{$nspace} = CHI->new ( 
  driver => 'File', namespace => $nspace,
  root_dir => $ENV{MOJO_HOME}.'/cache', depth => 3 
  # depth 3 is based on preliminary tests, 2 was not enough
 );

}

my $sep = '_'; # the string that separates cache key parts

sub cache_set {

 $cacheon or return; # immediate NOP if not caching

 # we expect: namespace, array of key parts, value, expire
 my $space = shift; my $exp = pop; my $val = pop;

 # verify that the namespace exists
 $cache->{$space} or die "unknown cache_set namespace '$space'";  

 # we build the cache key by joining the key parts
 # we also map undefined key parts to string 'undef' to be safe
 my $key = join $sep, map { defined $_ ? $_ : 'undef' } @_;

 # the actual set operation is just a call to CHI interface
 $cache->{$space}->set( $key, $val, $exp );

}

sub cache_get {

 $cacheon or return; # immediate NOP if not caching 

 # we expect: namespace, array of key parts
 my $space = shift; 

 # verify that the namespace exists
 $cache->{$space} or die "unknown cache_get namespace '$space'";  
 
 # the actual get operation is just a call to CHI interface
 # we map undefined key parts to 'undef' to be safe
 return
  $cache->{$space}->get( join $sep, map { defined $_ ? $_ : 'undef' } @_ );

}

1; 