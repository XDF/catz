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

package Catz::Core::Cache;

# a simple prodedural set/get module over Cache::Memcached::Fast
# every module in a need of caching should use this module

use 5.10.0; use strict; use warnings;

use parent 'Exporter';

our @EXPORT = qw ( cache_get cache_set );

use Cache::Memcached::Fast;
use Digest::MD5 qw ( md5_base64 );

use Catz::Core::Conf;
use Catz::Util::String qw ( enurl );

my $setup = conf ( 'cache' );

# using a static reference to the cache object
my $cache = Cache::Memcached::Fast->new( $setup );

# the cache key separator
use constant SEP => '#';

# force the cache key to be 250 characters or less (Memcached limit)
# all characters after 228 are hashed to md5 hash in base64 encoding
# so the key is then 228 + 22 = 250 characters
sub shrink { substr ( $_[0], 0 , 228 ) . md5_base64 ( substr ( $_[0], 228 ) ) }
  
sub cache_set {

 my $time = pop @_; # time is the last argument
 
 $time == 0 and return; # time is 0 = no caching

 my $val = pop @_; # val is the last argument
  
 my $key = enurl ( join SEP, @_ ); # urlencode to handle spaces
 
 length ( $key ) > 250 and $key = shrink ( $key );
 
 #warn "SET $key";
 
 if ( $time == -1 ) { # -1 is infinite

  $cache->set( $key, $val );
  
 } else {
 
  $cache->set( $key, $val, $time );

 } 
        
}

sub cache_get {
 
 my $key = enurl ( join SEP, @_ ); # urlencode to handle spaces
 
 length ( $key ) > 250 and $key = shrink ( $key );
 
 warn "GET $key";
    
 return $cache->get( $key );
   
}

1;