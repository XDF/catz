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

package Catz::Data::Cache;

#
# a simple set/get module over Cache::Memcached::Fast
#
# every package in need of caching should use this module
#
 
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT = qw ( cache_get cache_set );

use DBI;
use CHI;

use Catz::Data::Conf;
use Catz::Util::Time qw ( thisweek thisyear );

# all data in Catz can live in the same CHI namespace since
# * models use sub name as a key
# * pages use url name as a key
# * SQL? ???????????????????????????????
# and since sub never starts with '/' and urls always
# start with '/' there will be no key crashes

my %setup = %{ conf ('cache' ) };

$setup{dbh} = DBI->connect (
 conf ( 'dbconn' ) . conf ( 'path_cache' ) . '/' . 
 thisyear . sprintf ( "%02d", thisweek ) . '.db',
 undef, undef, conf( 'dbargs_cache' )
);

# using a static reference to the real cache object
my $cache = CHI->new( %setup );

# the cache key separator
use constant SEP => '#';
  
sub cache_set {

 #return; # DEBUGGING / DEV - skip caching

 my $val = pop @_; # val is the last argument
 
 my $key = join SEP, @_;
      
 $cache->set( $key, $val );

}

sub cache_get {
 
 my $key = join SEP, @_;
    
 return $cache->get( $key );
   
}

1;