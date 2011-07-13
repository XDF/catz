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
use Catz::Util::String qw ( enurl );  

# for debugging or other needs all caching can be
# set to NOP setting this to false
my $cacheon = 1;

# we create a static cache object at compile time and this works just fine
my $cache = new Cache::Memcached::Fast { 
 servers => [ '127.0.0.1:11211' ], 
 connect_timeout => 0.1, 
 max_failures => 2, # let connect fail 2 times ...
 failure_timeout => 15, # ... and then rest for 15 seconds
 compress_threshold => 15_000,
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

sub cache_set {

 $cacheon or return; # immediate NOP if not caching
 
 my @args = @_;

 # we expect val to be the last param 
 my $val = pop @args;
  
 # we build the cache key by joining the encoded key parts
 # we map undefined key parts to string 'undef' to be safe
 my $key = 
  enurl join $sep, 
   ( 'catz', map { $_ = $_ // 'undef'; $_ =~ tr/ /_/; $_  } @args );
  # MUST BE THE SAME CODE AS IN GET
   
 # shrink too long keys
 length $key > 250 and $key = shrink $key;
   
 {
 
  # the value to be cached may well be undef since it might
  # come from an url that points to no real photos and so
  # database access returns undef photo x or similar so
  # we allow undef to go to cache without a warning
   
  no warnings qw( uninitialized );
 
  $cache->set( $key, $val ); # we use no expirity -> infinite
  
 }
 
}

sub cache_get {

 $cacheon or return; # immediate NOP if not caching
 
 my @args = @_;
 
 # we build the cache key by joining the encoded key parts
 # we map undefined key parts to string 'undef' to be safe 
 my $key = 
  enurl join $sep, 
   ( 'catz', map { $_ = $_ // 'undef'; $_ =~ tr/ /_/; $_  } @args );
  # MUST BE THE SAME CODE AS IN SET 
  
 # shrink too long keys
 length $key > 250 and $key = shrink $key;
 
 return $cache->get( $key );

}

1; 