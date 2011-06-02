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

# using a simple single static reference to the cache object
my $cache = Cache::Memcached::Fast->new({
 servers => conf ( 'cache_servers' ),
 connect_timeout => 0.2,
 io_timeout => 0.2,
 max_failures => 2,
 failure_timeout => 15,
 nowait => 1,
 compress_threshold => 10_000
});

# the cache key separator
use constant SEP => '/';

# slash is a good choice for separator since we use url encoding
# for keys and slash never exists in an encoded url

sub makekey { # prepares a cache key 

 # join url encoded key parts together with the separator
 my $key = join SEP, map { enurl $_ } @_;
 
 # url encoding was chosen since some encoding is necessary because
 # keys can't have spaces and the url encoding library we use is
 # a pretty fast one (XS-based) 
 
 if ( length ( $key ) > 250 ) {
   
  # force the cache key to be 250 characters or less (Memcached limit)
  # all characters after 228 are hashed to md5 hash in base64 encoding
  # so the key is then 228 + 22 = 250 characters - we get the longest
  # possible key to minimize the risk of key collision
   
  substr ( $key, 0 , 228 ) . md5_base64 ( substr ( $key, 228 ) )
 
 } else { $key } 

}
  
sub cache_set {

 my $time = pop @_; # time is always the last argument and must be given
 
 $time == 0 and return; # time = 0 -> no caching -> return immediately

 my $val = pop @_; # value to cache is the second last argument
 
 my $key = makekey ( @_ ); 
  
 #warn "SET $key";
 
 if ( $time == -1 ) { # -1 is infinite

  $cache->set( $key, $val );
  
 } else {
 
  $cache->set( $key, $val, $time );

 } 
        
}

sub cache_get {
 
 my $key = makekey ( @_ );
 
 #warn "GET $key";
 
 #if ( $cache->get( $key ) ) { warn "HIT $key" } else { warn "MISS $key" } 
    
 return $cache->get( $key );
   
}

1;