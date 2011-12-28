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

# unbuffered outputs
# from http://perldoc.perl.org/functions/open.html
select STDERR;
$| = 1;
select STDOUT;
$| = 1;

use Test::More;
use Test::Mojo;

use Catz::Data::Conf;

my $t = Test::Mojo->new ( conf ( 'app' ) );

#
# general
#

my @oksetups = qw ( en fi en211211 fi171212 en394211 fi211111 );

my @okpages = qw ( 
 / /build/ /news/ /news/20111215232708/ /lists/ /list/code/top/ /more/contrib/
 /more/quality/ /search/ /browseall/043156/ /viewall/125111/
 /browse/app/d_09/051110/ /view/app/d_09/118105/
 /search/183044?q=%2Bflen%3D%2285%20mm%22%20%2Bfnum%3Df%2F1.8 
 /display/182008?q=%2Bflen%3D%2285%20mm%22%20%2Bfnum%3Df%2F1.8  
);

foreach my $page ( @okpages ) {

 my $setup = $oksetups [ rand @oksetups ];
 
 $t->get_ok ( "/$setup$page" )
  ->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )
  ->content_like ( qr/link rel=\"shortcut icon\"/ )
  ->content_like ( qr/link rel=\"image_src\"/ )
  ->content_like ( qr/meta name=\"og:image\"/ )
  ->content_like ( qr/meta name=\"author\"/ )
  ->content_like ( qr/meta name=\"copyright\"/ )
  ->content_like ( qr/link rel=\"copyright\"/ )
  ->content_like ( qr/meta name=\"og:site_name\"/ )
  ->content_like ( qr/meta name=\"robots\"/ )
  ->content_like ( qr/link rel=\"canonical\"/ )
  ->content_like ( qr/meta name=\"og:url\"/ )
  ->content_like ( qr/link rel=\"alternate\"/ )
  ->content_like ( qr/meta name=\"fb:admins\"/ )
  ->content_like ( qr/link rel=\"me\"/ )
  ->content_like ( qr/meta name=\"generator\"/ )
  ->content_like ( qr/meta name=\"credits\"/ )
  ->content_like ( qr/meta name=\"robots\"/ )
  ->content_like ( qr/meta name=\"og:title\" / )
  ->content_like ( qr/meta name=\"og:type\" / );

}

#
# social media integration
#

# these pages should have social media integration

my @hassmi = qw (
 /fi/ /en/ /en/news/20111215232708/ /en394211/list/lens/top/
 /fi/browse/app/a_21/ /en394211/browse/app/a_21/
 /fi/browseall/ /en/browseall/ /fi394211/search?q=*mini*
 /en/viewall/ /fi/viewall/084157/ /en394211/view/breed/AMS/
 /en394211/view/breed/AMS/171106/ /fi/display/126129?q=text%3D*panel*
 /fi/display?q=text%3D*panel* /en/search/ /fi211111/search/
 /en/more/contrib/ /fi171212/more/contrib/ /fi/build/ /en323321/build/
);

foreach my $page ( @hassmi ) {

 $t->get_ok ( $page )
  ->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )
  ->content_like ( qr/facebook.com\/sharer\.php/ )
  ->content_like ( qr/twitter.com\/share/ )
  ->content_like ( qr/\<g\:plusone / );
  
}

# these pages shouldn't have social media integration

my @hasnosmi = qw (
 /fi/news/ /fi171212/lists/ /fi/browse/etime/1-047200_s/018175/
 /en/browse/folder/20110417helsinki/171076/
 /fi394211/browseall/007043/ /fi/browseall/068212/
 /fi211111/search/083230?q=*mini*
 /en/search?i=text%3D*panel* /en/search?q=ZZZZZZZZZ
 /en/more/quality/ /fi171212/more/quality/
 /fi323321/build/c3a1f1l1000s100g0/
 /en323321/build/title/CH/ /fi323321/build/title/CH/c2a2f1l1000s100g0/
 /fi171212/build?q=%2Bhas%3Dbreed%20-has%3Dcat%20date%3D2011*
);

foreach my $page ( @hasnosmi ) {

 $t->get_ok ( $page )
  ->status_is ( 200 )
  ->content_type_like ( qr/text\/html/ )
  ->content_unlike ( qr/facebook.com\/sharer\.php/ )
  ->content_unlike ( qr/twitter.com\/share/ )
  ->content_unlike ( qr/\<g\:plusone / );
  
}

#
# testing robots
#

# front

$t->get_ok ( '/fi/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,follow\"/ );

$t->get_ok ( '/en/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,follow\"/ );

$t->get_ok ( '/en211111/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# news

$t->get_ok ( '/en/news/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,follow\"/ );
  
# new1

$t->get_ok ( '/fi/news/20110707014512/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,follow\"/ );

$t->get_ok ( '/fi171212/news/20110707014512/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# lists

$t->get_ok ( '/fi/lists/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,follow\"/ );

# list1

$t->get_ok ( '/fi/list/body/a2z/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,follow\"/ );

$t->get_ok ( '/en/list/cat/top/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,follow\"/ );

$t->get_ok ( '/en171212/list/cat/top/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );
  
# browse all

$t->get_ok ( '/fi/browseall/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/en/browseall/047277/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/fi211111/browseall/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# browse pair

$t->get_ok ( '/en/browse/feat/09/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/en/browse/feat/09/010031/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/en211111/browse/feat/09/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# browse search

$t->get_ok ( '/en/search?q=%22MCO%20%3F%20%3F%3F%22%20%22NFO%20%3F%20%3F%3F%22' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/en/search/026035?q=%22MCO%20%3F%20%3F%3F%22%20%22NFO%20%3F%20%3F%3F%22' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/fi394211/search/026035?q=%22MCO%20%3F%20%3F%3F%22%20%22NFO%20%3F%20%3F%3F%22' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );
  
# view all

$t->get_ok ( '/en/viewall/187006/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/fi/viewall/187006/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/fi394211/viewall/187006/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# view pair

$t->get_ok ( '/fi/view/body/Canon_EOS_40D/134100/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# view search

$t->get_ok ( '/fi/display/131041?q=*miis*' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# search

$t->get_ok ( '/fi/search/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/en/search/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/en391211/search/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/en/search?i=*miis*' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/fi/search?q=*XXXXYYYYZZZZKSKSKKS*' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# more

$t->get_ok ( '/fi/more/contrib/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,follow\"/ );

$t->get_ok ( '/fi/more/quality/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,follow\"/ );

$t->get_ok ( '/fi394211/more/quality/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/en/more/contrib/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,follow\"/ );

$t->get_ok ( '/en/more/quality/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,follow\"/ );

$t->get_ok ( '/en394211/more/quality/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

# build

$t->get_ok ( '/fi/build/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/en/build/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"index\,nofollow\"/ );

$t->get_ok ( '/en211111/build/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

$t->get_ok ( '/fi/build/c2a2f1l600s100g4/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );
  
$t->get_ok ( '/fi/build/cat/Peku/' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );
  
$t->get_ok ( '/en/build?q=text%3D*panel*' )
  ->status_is ( 200 )
  ->content_like ( qr/\"noindex\,nofollow\"/ );

#  
# various custom fields
#

$t->get_ok ( '/en394111/' )
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / );

$t->get_ok ( '/fi394111/news/' )
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / );

$t->get_ok ( '/en/news/20110707014512/' )
  ->status_is ( 200 )
  ->content_like ( qr/link rel=\"index\"/ )
  ->content_like ( qr/link rel=\"next\"/ )  
  ->content_like ( qr/link rel=\"prev\"/ );

$t->get_ok ( '/fi/lists/' )
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / );

$t->get_ok ( '/en394111/list/breeder/a2z/' )
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/link rel=\"index\"/ );
  
$t->get_ok ( '/en/search/026035?q=%22MCO%20%3F%20%3F%3F%22%20%22NFO%20%3F%20%3F%3F%22' )  
  ->status_is ( 200 )
  ->content_like ( qr/link rel=\"start\"/ )
  ->content_like ( qr/link rel=\"next\"/ )  
  ->content_like ( qr/link rel=\"prev\"/ );

$t->get_ok ( '/fi394111/browse/loc/Helsinki/' )  
  ->status_is ( 200 )
  ->content_like ( qr/link rel=\"start\"/ )
  ->content_like ( qr/link rel=\"next\"/ )  
  ->content_like ( qr/meta name=\"og:locality\" / )
  ->content_like ( qr/meta name=\"og:country-name\" / )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / );

$t->get_ok ( '/en394111/viewall/026035/' )  
  ->status_is ( 200 )
  ->content_like ( qr/link rel=\"index\"/ )
  ->content_like ( qr/link rel=\"start\"/ )
  ->content_like ( qr/link rel=\"next\"/ ) 
  ->content_like ( qr/link rel=\"prev\"/ )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / ); 

$t->get_ok ( '/en394111/view/loc/Helsinki/180016/' )  
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"og:locality\" / )
  ->content_like ( qr/meta name=\"og:country-name\" / ) 
  ->content_like ( qr/link rel=\"index\"/ )
  ->content_like ( qr/link rel=\"start\"/ )
  ->content_like ( qr/link rel=\"next\"/ ) 
  ->content_like ( qr/link rel=\"prev\"/ );
  
$t->get_ok ( '/en/search/' )  
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / );

$t->get_ok ( '/fi/more/contrib/' )  
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / );

$t->get_ok ( '/en/more/quality/' )  
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / );

$t->get_ok ( '/en111111/build/' )  
  ->status_is ( 200 )
  ->content_like ( qr/meta name=\"description\" / )
  ->content_like ( qr/meta name=\"og:description\" / )
  ->content_like ( qr/meta name=\"keywords\" / );
      
done_testing;