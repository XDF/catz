#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2012 Heikki Siltala
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

use 5.14.2;
use strict;
use warnings;

use lib '../lib';

use WWW::Mechanize;

use Catz::Data::Conf;
use Catz::Data::Text;

my $text = text ( 'en' );

my @urls = 
 map { 'http://127.0.0.1:3' . conf ( 'env' ) . '00' . $_ } qw( 
  /en/ /fi264311/ /en365312/browseall/ /fi/browseall/ 
  /en/viewall/ /fi264311/viewall/ /en/news/ /fi/news/ 
  /en/lists/ /fi/lists/ /fi/list/lens/a2z/
  /fi264311/search/ /en365312/search?q=Peku /fi/more/contrib/
 );

my $ocache = {}; # cache an object for each URL

sub getobj {

 my $url = shift;

 my $m;

 if ( exists $ocache->{ $url } )  {

  $m = $ocache->{ $url };

 } else {
 
  $m = WWW::Mechanize->new( autocheck => 1 );

  # at least Wikipedia doesn't like the default
  $m->agent( $text->{SITE} . ' link verifier' );

  $m->get( $url );

  $ocache->{ $url } = $m;
 
 }

 return $m;

}

foreach my $url ( @urls ) {

 say '';
 say "********************************************";
 say "checking url $url";
 say "********************************************";
 say '';

 my $u = getobj ( $url );
 
 my @links = $u->links;
 
 foreach my $link ( @links )  {

  my $lin = $link->url_abs();
 
  say "checking link $lin";

  my $l = getobj ( $lin );

 }

 say '';

 foreach my $image ( sort $u->images ) {

  my $ima = $image->url_abs();

  # viz redirects take ages, skip them
  not ( $ima =~ m|/viz/| ) and do { 
 
   say "checking image $ima";

   my $i = getobj ( $ima );

  };

 }

}

say '';
say ':-D walk done, no erros';