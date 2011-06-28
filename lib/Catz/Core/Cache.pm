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

use parent 'Exporter';

# the interface is simple, just set and get
our @EXPORT = qw ( cache_set cache_get );

use Cache::Memcached::Fast;
use Digest::MD5 qw( md5_hex );

use Catz::Core::Conf;
use Catz::Util::String qw ( encode );  

# caching gets activated only in production mode
# if not in production mode, cache_set and cache_get 
# can still be called as usual but are NOP
my $cacheon = $ENV{MOJO_MODE} eq 'production' ? 1 : 0;

# we create a static cache object at compile time
my $cache = new Cache::Memcached::Fast { 
 servers => [ '127.0.0.1:11211' ], 
 connect_timeout => 0.1, 
 max_failures => 2, 
 failure_timeout => 10,
 compress_threshold => 10_000,
 nowait => 1 
};

my $sep = ' '; # the string that separates cache key parts

my $app = conf ( 'app' ); # the application id

my $ver = conf ( 'ver' ); # the application version

# force the cache key to be 250 characters or less (Memcached limit)
# all characters after 218 are hashed to md5 hash in hex encoding
# so the final key is 218 + 32 = 250 characters
sub shrink { substr ( $_[0], 0 , 218 ) . md5_hex ( substr ( $_[0], 218 ) ) }

sub cache_set {

 $cacheon or return; # immediate NOP if not caching
 
 my @args = @_;

 # we expect array of key parts, value, expire in seconds
 my $exp = pop @args; 
 my $val = pop @args;
 
 # put application id and applicaiton version to key 
 unshift @args, $app.$ver;

 # we build the cache key by joining the encoded key parts
 # we map undefined key parts to string 'undef' to be safe
 my $key = encode join $sep, map { defined $_ ? $_ : 'undef' } @args;
 
 # shrink too long keys
 length $key > 250 and $key = shrink $key;
 
 if ( $exp == -1 ) {
 
   $cache->set( $key, $val ); # infinite
 
 } else {
 
  $cache->set( $key, $val, $exp ); # with expiry
 
 }  

}

sub cache_get {

 $cacheon or return; # immediate NOP if not caching
 
 my @args = @_;
 
 # put application id and applicaiton version to key 
 unshift @args, $app.$ver;
 
 # we build the cache key by joining the encoded key parts
 # we map undefined key parts to string 'undef' to be safe 
 my $key = encode join $sep, map { defined $_ ? $_ : 'undef' } @args;
 
 # shrink too long keys
 length $key > 250 and $key = shrink $key;
 
 return $cache->get( $key );

}

1; 