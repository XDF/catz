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

package Catz::Cache;

#
# a simple set/get module over Cache::Memcached::Fast
#
# every package in need of caching should use this module
#
 
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( cache_get cache_set );

use Cache::Memcached::Fast;
use Digest::MD5 qw( md5_base64 );

# just using a simple static Cache::Memcached::Fast object 
my $cache = new Cache::Memcached::Fast { 
 servers => [ '127.0.0.1:11211' ], 
 connect_timeout => 0.2, 
 max_failures => 2, 
 failure_timeout => 5,
 compress_threshold => 5_000,
 nowait => 1 
};

# the cache key separator
use constant SEP => '|';

# force the cache key to be 250 characters or less
# all characters after 228 are hashed to md5 hash in base64 encoding
# so the key is 228 + 22 = 250 characters
sub shrink { substr ( $_[0], 0 , 228 ) . md5_base64 ( substr ( $_[0], 228 ) ) }
  
sub cache_set {

 my $val = pop @_;
 
 my $key = join SEP, @_;
  
 length $key > 250 and $key = shrink ( $key ); 
      
 $cache->set( $key, $val );

}

sub cache_get {
 
 my $key = join SEP, @_;
  
 length $key > 250 and $key = shrink ( $key ); 
  
 return $cache->get( $key );
   
}

1;