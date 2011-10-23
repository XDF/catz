#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
# 
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

use 5.10.0; use strict; use warnings;

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR; $| = 1; 
select STDOUT; $| = 1; 

use Test::More;
use Test::Mojo;

use Catz::Core::Cache;

my $t = Test::Mojo->new( 'Catz::Core::App' );

my $isup = cache_isup;

# testing headers

# page caching is tested so that first the resources are just requested
# then they are re-requested and expected to come from page cache

my @okpaths = qw (
 /favicon.ico /img/catz.png /js_lib/jquery.js /js_site/find.js
 /en/ /fi/ /en/list/lens/top/ /en/browse/folder/20110918orimattila/
 /en172211/browse/title/EP/ /fi223211/viewall/122126/ /en/feed/ 
 /fi123211/news/20111002212228/ /en/find?s=im /fi/find?s=ou 
);

foreach my $path ( @okpaths ) {

 $t->get_ok( $path )
   ->status_is(200)
   ->header_like('Cache-Control' => qr/max-age/ )
   ->header_like('Last-Modified' => qr/GMT/ )
   ->header_like('Expires' => qr/GMT/ )
   ->header_like('Date' => qr/GMT/ )
   ->header_like('X-Catz-Env' => qr/catz\d/ )
   ->header_like('X-Catz-Ver' => qr/\d{14}/ )
   ->header_like('X-Catz-Took' => qr/ms/ ); # general test


 if ( $isup ) {
 
  $t->get_ok( $path )
    ->status_is(200)
    ->header_like('Cache-Control' => qr/max-age/ )
    ->header_like('Last-Modified' => qr/GMT/ )
    ->header_like('Expires' => qr/GMT/ )
    ->header_like('Date' => qr/GMT/ )
    ->header_like('X-Catz-Env' => qr/catz\d/ )
    ->header_like('X-Catz-Ver' => qr/\d{14}/ )
    ->header_like('X-Catz-Took' => qr/cache/ ); # from cache test
 
 }
   
}

done_testing;