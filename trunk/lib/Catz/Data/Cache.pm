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

package Catz::Data::Cache;

#
# The systemwide cache module for all caching purposes
#
# This is used to cache at least
# * rendered pages and images
# * Model responses
# * database result sets
#

use 5.12.0; use strict; use warnings;

use parent 'Exporter';

# the interface is simple, just set and get
our @EXPORT = qw ( cache_set cache_get cache_isup );

use Cache::Memcached::Fast;
use Digest::MD5 qw( md5_hex );

use Catz::Data::Conf;

use Catz::Util::String qw ( enurl );  

# for debugging or other needs all caching can be
# set to NOP setting this to false
my $cacheon = 1;

# set on/off cache tracing as warnings
my $cache_trace = 0;

# we create a static cache object at compile time and this works just fine
# also the hard-coded values are practically fine for all the environments
my $cache = new Cache::Memcached::Fast { 
 servers => [ '127.0.0.1:11211' ], 
 connect_timeout => 0.1, 
 max_failures => 2, # let connect fail 2 times ...
 failure_timeout => 15, # ... and then rest for 15 seconds
 compress_threshold => 30_000,
 nowait => 1 # should speed up set by not waiting for confirmation for success
};

# the string that separates cache key parts
# since we use URL encoding with cache keys this
# should be an URL safe character and the encoding of it
# doesn't add unnecessary length to the cache keys
my $sep = '~'; 

# force the cache key to be 250 characters or less (Memcached limit)
# all characters after 218 are hashed to md5 hash in hex encoding
# so the final key is 218 + 32 = 250 characters
sub shrink { substr ( $_[0], 0 , 218 ) . md5_hex ( substr ( $_[0], 218 ) ) }

# preparing of the cache key by joining the parts
sub keyer {

 my @args = @_;

 # we map undefined key parts to string 'undef' to be safe
 my $key = enurl join $sep,
   map { $_ = $_ // 'undef'; $_ =~ tr/ /_/; $_  } @args;
   
 length $key > 250 and return shrink $key;
 
 return $key;
      
}

sub cache_set {

 $cacheon or return; # immediate NOP if not caching
 
 my @args = @_;

 # we expect val to be the last param 
 my $val = pop @args;
 
 my $key = keyer ( @args );
 
 $cache_trace and warn "CACHE SET $key";
  
 {
 
  # the value to be cached may well be undef since it might
  # come from an url that points to no real photos and so
  # database access returns undef photo x or similar so
  # we allow undef to go to cache without a warning
   
  no warnings qw( uninitialized );
 
  #
  # we use no expirity -> infinite caching
  #
  # Memcached automatically discards LRU items
  # and when app or data changes, version id 
  # changes and so all keys change rendering
  # old cache entries unused and to LRU

  $cache->set( keyer ( @args ), $val ); 
  
  
 }
 
}

sub cache_get {

 $cacheon or return; # immediate NOP if not caching
 
 my @args = @_;
 
 my $key = keyer @args;
  
 my $ret = $cache->get( keyer @args );
 
 $cache_trace and do {
 
 if ( defined $ret ) { warn "CACHE HIT $key" }
  else { warn "CACHE MISS $key" }
 
 };
 
 return $ret; 

}

my @chars = ('a'..'z','A'..'Z','0'..'9' );

sub cache_isup {

 # test if memcached server is up and working

 # generate a random key and value, the idea is from
 # http://th.atguy.com/mycode/generate_random_string/


 my $ckey; my $ival;

 foreach (  1 .. 200 ) { 

  $ckey .= $chars [ rand @chars ];
  $ival .= $chars [ rand @chars ];

 }
 
 $ckey .= 'Catz::Core::Cache::cache_isup::';

 cache_set ( $ckey, $ival );

 my $oval = cache_get ( $ckey ) // '0';

 return $ival eq $oval ? 1 : 0; 

}

1; 