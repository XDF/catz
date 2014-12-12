#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2012 Heikki Siltala
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

use 5.14.2;
use strict;
use warnings;

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR;
$| = 1;
select STDOUT;
$| = 1;

use Test::More;
use Test::Mojo;

use Catz::Data::Cache;
use Catz::Data::Conf;

my $t = Test::Mojo->new ( conf ( 'app' ) );

my $isup = cache_isup;

# testing headers

# page caching is tested so that first the resources are just requested
# then they are re-requested and expected to come from page cache

my @okstatics = qw (
 /favicon.ico /img/catz.png /js_lib/jquery.js /js_site/find.js
);

my @okpaths = qw (
 /en/ /fi/ /en/list/lens/top/ /en/browse/folder/20110918orimattila/
 /en172211/browse/title/EP/ /fi223211/viewall/122126/ /en/feed/
 /fi123211/news/20111002212228/ /en/find?s=im /fi/find?s=ou
 /fi112211/search/182007?q=%2Bhas%3Dbreed%20-has%3Dcat%20date%3D2011*
 /en162112/search?q=%2BMCO%20d%20e%20f
);

my @badpaths = qw ( /xyz/ /this/is/a/test/ );

foreach my $path ( @okstatics ) {

 $t->get_ok ( $path )->status_is ( 200 )
  ->header_is   ( 'X-Catz-Origin'  => 'static' )
  ->header_like ( 'Cache-Control'  => qr/max-age/ )
  ->header_like ( 'Last-Modified'  => qr/GMT/ )
  ->header_like ( 'Expires'        => qr/GMT/ )
  ->header_like ( 'Date'           => qr/GMT/ );

}

foreach my $path ( @okpaths ) {

 #<<<
 
 $t->get_ok ( $path )->status_is ( 200 )
   ->header_like ( 'Cache-Control'    => qr/max-age/ )
   ->header_like ( 'Expires'          => qr/GMT/ )
   ->header_like ( 'Date'             => qr/GMT/ )
   ->header_like ( 'X-Catz-Env'       => qr/^catz\d$/ )
   ->header_like ( 'X-Catz-Version'   => qr/^\d{14}$/ )
   ->header_like ( 'X-Catz-Timing'    => qr/^\d+ ms$/ )
   ->header_like ( 'X-Catz-Origin'    => qr/^[a-z]+$/ )
   ->header_like ( 'ETag'             => qr/^.{24}$/ );

 #>>>
 
 if ( $isup ) {

  # test that the content is served from cache and
  # also that all the headers are still present

  #<<<

  $t->get_ok ( $path )->status_is ( 200 )
    ->header_like ( 'Cache-Control'  => qr/max-age/ )
    ->header_like ( 'Expires'        => qr/GMT/ )
    ->header_like ( 'Date'           => qr/GMT/ )
    ->header_like ( 'X-Catz-Env'     => qr/^catz\d$/ )
    ->header_like ( 'X-Catz-Version' => qr/^\d{14}$/ )
    ->header_like ( 'X-Catz-Timing'  => qr/^\d+ ms$/ )
    ->header_is   ( 'X-Catz-Origin'  => 'cache' )
    ->header_like ( 'ETag'           => qr/^.{24}$/ ); 

  #>>>

 }

}

foreach my $path ( @badpaths ) {

 #<<<

 $t->get_ok ( $path )->status_is ( 404 )
   ->header_like ( 'Cache-Control' => qr/max-age/ )
   ->header_like ( 'Cache-Control' => qr/must-revalidate/ );

 #>>>

} ## end foreach my $path ( @okpaths)

done_testing;
