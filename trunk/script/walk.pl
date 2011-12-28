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

use 5.12.0;
use strict;
use warnings;

use lib '../lib';

use WWW::Mechanize;

use Catz::Data::Conf;

my @urls = 
 map { "http://localhost:300" . conf ( 'env' ) . $_ } qw( 
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
 
  $m = WWW::Mechanize->new( autcheck => 1 );

  # at least Wikipedia doesn't like the default
  $m->agent_alias( 'Linux Konqueror' );

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
 
 foreach my $link ( sort $u->links )  {

  my $lin = $link->url_abs();
 
  say "checking link $lin";

  my $l = getobj ( $lin );

 }

 say '';

 foreach my $image ( sort $u->images ) {

  my $ima = $image->url_abs();

  # viz redirects take ages, skip them by grep
  not ( $ima =~ m|/viz/| ) and do { 
 
   say "checking image $ima";

   my $i = getobj ( $ima );

  };

 }

}

say '';
say ':-D walk done, no erros';