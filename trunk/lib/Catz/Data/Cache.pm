#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2013 Heikki Siltala
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
# This is used to cache (at least)
# * rendered pages and images
# * Model responses
# * database result sets
#

use 5.16.2;
use strict;
use warnings;

use parent 'Exporter';

# the interface is simple, just set and get
our @EXPORT = qw ( cache_set cache_get cache_isup );

use CHI;
use Const::Fast;

# we "use Storable" just to set it's static variables to
# allow storage of CODE references - this appears to be
# required for Mojo response caching after ugrading to
# Mojolicious 2.32
#
# 2013-05-02: tested and we still need this
#
use Storable;
$Storable::Deparse = 1;
$Storable::Eval    = 1;

use Catz::Data::Conf;

# for debugging or other needs all caching can be
# set to NOP setting this to false
const my $CACHEON => 1;

# set on/off cache tracing as warnings
const my $CACHETRC => 0;

# set the cache namespace for the Catz application
const my $SPACE => 'cache_catz';

# we create a static cache object at compile time and this works just fine
# also the hard-coded values are practically fine for all the environments
my $cache = CHI->new(
 namespace => $SPACE,
 driver => 'File',
 root_dir  => conf ( 'lin' ) ? '/tmp' : '/temp',
 depth => 4,
 compress_threshold => 15_000,
); 

# the string that separates cache key parts
my $sep = '_';

# force the cache key to be 250 characters or less (Memcached limit)

# preparing of the cache key by joining the parts
sub keyer {

 return join $sep, ( map { $_ // 'undef' } @_ );

}

sub cache_set {

 $CACHEON or return;    # immediate NOP if not caching

 my @args = @_;

 # we expect val to be the last param
 my $val = pop @args;

 my $key = keyer ( @args );

 $CACHETRC and warn "CACHE SET  $key";

 {

  # the value to be cached may well be undef since it might
  # come from an url that points to no real photos and so
  # database access returns undef photo x or similar so
  # we allow undef to go to cache without a warning

  no warnings qw( uninitialized );

  #
  # we use 'never' -> infinite caching
  # we rely on external file cleaning
  #

  $cache->set ( $key, $val, 'never' );

 }

} ## end sub cache_set

sub cache_get {

 $CACHEON or return;    # immediate NOP if not caching

 my @args = @_;

 my $key = keyer @args;

 my $ret = $cache->get ( $key );

 $CACHETRC and do {

  if   ( defined $ret ) { warn "CACHE HIT  $key" }
  else                  { warn "CACHE MISS $key" }

 };

 return $ret;

}

const my @CHARS => ( 'a' .. 'z', 'A' .. 'Z', '0' .. '9' );

sub cache_isup {

 # test if memcached server is up and working

 # generate a random key and value, the idea is from
 # http://th.atguy.com/mycode/generate_random_string/

 my $ckey;
 my $ival;

 foreach ( 1 .. 200 ) {

  $ckey .= $CHARS[ rand @CHARS ];
  $ival .= $CHARS[ rand @CHARS ];

 }

 $ckey .= 'Catz::Core::Cache::cache_isup::';

 cache_set ( $ckey, $ival );

 my $oval = cache_get ( $ckey ) // '0';

 return $ival eq $oval ? 1 : 0;

} ## end sub cache_isup

1;
