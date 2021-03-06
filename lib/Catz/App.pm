#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2021 Heikki Siltala
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

package Catz::App;

# The Catz Mojolicious application

use 5.16.2;
use strict;
use warnings;

use parent 'Mojolicious';

use Const::Fast;
use Mojo::Util qw ( xml_escape );
use Time::HiRes qw ( time );

use Catz::Data::Cache;
use Catz::Data::Conf;
use Catz::Data::List;
use Catz::Data::Setup;
use Catz::Data::Text;

use Catz::Util::File qw ( findlatest );
use Catz::Util::Time qw(
 dt dt2epoch dtdate dttime dtexpand dtlang
 epoch2http http2epoch s2dhms thisyear
);
use Catz::Util::Number qw ( fmt fullnum33 round );
use Catz::Util::String qw (
 clean dna enurl decode encode limit trim urirest fuse fuseq 
 ucc lcc ucclcc 
);

# controls emitting HTTP request timing information as warnings
const my $TIME_PAGE => 0;

sub startup {

 my $self = shift;
 
 $self->plugin('Config', file => 'lib/app.pl' );

 # template directory
 $self->renderer->paths ( [ $ENV{ MOJO_HOME } . '/tmpl' ] );

 # initialize the key for cookie signing
 # this is a stateless service and we use no 
 # cookies so this is just to suppress warnings
 $self->secrets ( conf ( 'key_cookie' ) );

 # map utility subs from different modules to Mojolicious helpers
 # we use dynamically generated subs as bridges
 foreach my $sub (
  qw ( dt dt2epoch dtdate dttime dtexpand s2dhms fmt clean
  enurl xml_escape limit trim fullnum33 thisyear encode
  decode round urirest fuse fuseq ucc lcc ucclcc )
  )
 {

  # we do shift to ditch $self that comes in first in helper calls
  # the actual pass-thru call is done with rest the of the arguments
  $self->helper ( $sub => eval qq{ sub { shift; $sub \@\_; } } ); ## no critic

 }

 my $r = $self->routes;

 # all controllers live at Catz::Ctrl
 $r->namespaces ( [ qw ( Catz::Ctrl ) ] ); 

 ###
 ### the site's bare root gets passed to language detection mechanism
 ###

 $r->any ( '/' )->to ( 'main#detect' );

 ###
 ### rerouting of old site's pages and resources
 ###
 
 $r->any ( '/reroute/*src' )->to ( 'reroute#reroute' );
 $r->any ( '/reroute' )->to      ( 'reroute#reroute' );

 ###
 ### the stylesheets
 ###

 # reset
 $r->any ( '/style/reset' )->to ( 'main#reset' );

 # widget
 $r->any ( '/style/widget' )->to ( 'widget#style' );

 # the single stylesheet contains all style definitions
 # it's color settings are dependent on the palette
 $r->any ( '/style/:palette' => [ palette => qr/dark|neutral|bright/ ] )
  ->to ( 'main#base' );

 # "lastshow" is for a remote system to fetch a list of photos
 $r->any ( '/lastshow' )->to ( 'bulk#photolist', forcefi => 1 );

 # all site's true content is under /:langa where langa is 'en' or 'fi'
 # and it can be extended by magic code defining the user settings
 #
 # the language code sets the content language
 #
 my $l =
  $r->any ( '/:dummy' => 
   [ dummy => qr/en(?:[1-9]{6})?|fi(?:[1-9]{6})?/ ] 
  );

 # the front page is at the root under the language
 $l->any ( '/' )->to ( 'main#front' );

 ###
 ### sitemap(s)
 ###

 # without langauge
 $r->any ( '/sitemap/index' )->to ( 'locate#mapidx' );

 # with langauge
 $l->any ( '/sitemap/:mapsub' )->to ( 'locate#mapsub' );

 ###
 ### content pages
 ###

 # 14.3.2021 
 # Old routing syntax no longer working with 
 # the current version of Mojolicious
 #
 # $l->any ( '/more/:action' )->to ( controller => 'more' );
 
 $l->any ( '/more/common'  )->to ( 'more#common'  );
 $l->any ( '/more/contrib' )->to ( 'more#contrib' );
 $l->any ( '/more/quality' )->to ( 'more#quality' );
 
 ###
 ### the news service
 ###

 # the index page of all articles
 $l->any ( '/news' )->to ( 'news#index' );

 # single article
 $l->any ( '/news/:article' => [ article => qr/\d{14}/ ] )->to ( 'news#one' );

 # RSS feed
 $l->any ( '/feed' )->to ( 'news#feed' );

 ###
 ### the builk interface
 ###

 # the interface provided for the purposes of www.catshow.fi
 # please note that although this can be used to other purposes
 # the interface is subject to sudden changes

 $l->any ( '/bulk/photolist' )->to ( 'bulk#photolist' );

 ###
 ### the lists
 ###

 # the list of lists (list index)
 $l->any ( '/lists' )->to ( 'locate#lists' );

 # a single list
 $l->any (
  '/list/:subject/:mode' => [
  subject => qr/[a-z]{1,25}/,
  mode    => qr/[a-z0-9]{1,25}/,
  ]
 )->to ( 'locate#list' );

 ###
 ### photo browsing and viewing - 3 ways
 ###

 ### #1: browse all & view all
 
 # 14.3.2021 
 # Old routing syntax no longer working with 
 # the current version of Mojolicious
 #
 # my $a = $l->any ( '/:action', action => qr/browseall|viewall/ );
 # $a->any ( '/:id', id => qr/\d{6}/ )->to ( controller => 'all' );
 # $a->any ( '/' )->to ( controller => 'all', id => undef );

 my $a1 = $l->any ( '/browseall' )->to ( 'all#browseall' );
 
 $a1->any ( '/:id' => [ id => qr/\d{6}/ ] );
 
 $a1->any ( '/' )->to( id => undef );

 my $a2 = $l->any ( '/viewall' )->to ( 'all#viewall' );

 $a2->any ( '/:id' => [ id => qr/\d{6}/ ] );

 $a2->any ( '/' )->to( id => undef );

 ### #2: pair browse & pair view
 
 # 14.3.2021 
 # Old routing syntax no longer working with 
 # the current version of Mojolicious
 #
 # my $p = $l->any ( '/:action', action => qr/browse|view/ );

 my $p1 = $l->any ( '/browse' )->to ( "pair#browse" );
 
 my $p2 = $l->any ( '/view' )->to ( "pair#view" );

 # with photo id
 $p1->any (
  ':pri/:sec/:id' => [
  pri => qr/[a-z]{1,25}/,
  sec => qr/[A-Za-z0-9_-]{1,500}/,
  id  => qr/\d{6}/
  ]
 );

 # without photo id
 $p1->any (
  ':pri/:sec/' => [
  pri => qr/[a-z]{1,25}/,
  sec => qr/[A-Za-z0-9_-]{1,500}/
  ]
 )->to (
  id         => undef
 );
 
 # with photo id
 $p2->any (
  ':pri/:sec/:id' => [
  pri => qr/[a-z]{1,25}/,
  sec => qr/[A-Za-z0-9_-]{1,500}/,
  id  => qr/\d{6}/
  ]
 );

 # without photo id
 $p2->any (
  ':pri/:sec/' => [
  pri => qr/[a-z]{1,25}/,
  sec => qr/[A-Za-z0-9_-]{1,500}/
  ]
 )->to (
  id         => undef
 ); 

 ### #3: search browse & search view
 
 # 14.3.2021 
 # Old routing syntax no longer working with 
 # the current version of Mojolicious
 #
 # my $s = $l->any ( '/:action', action => qr/search|display/ );
 
 my $s1 = $l->any ( '/search' )->to ( 'search#search' );

 my $s2 = $l->any ( '/display' )->to ( 'search#display' );

 # with photo id
 $s1->any ( '/:id' => [ id => qr/\d{6}/ ] );

 # without photo id
 $s1->any ( '/' )->to ( id => undef );

 # with photo id
 $s2->any ( '/:id' => [ id => qr/\d{6}/ ] );

 # without photo id
 $s2->any ( '/' )->to ( id => undef );

 ###
 ### visualizations
 ###

 # vkey is required to make request version unique but is not used later

 $l->any (
  '/viz/dist/:full/:breed/:none/:plain/:vkey' => [
  full  => qr/\d{1,5}/,
  breed => qr/\d{1,5}/,
  none  => qr/\d{1,5}/,
  plain => qr/\d{1,5}/,
  vkey  => qr/\d{14}/
  ]
 )->to ( 'visualize#dist' );

 $l->any (
  '/viz/rank/:pri/:sec/:vkey' => [
  pri  => qr/[a-z]{1,25}/,
  sec  => qr/[A-Za-z0-9_-]{1,500}/,
  vkey => qr/\d{14}/
  ]
 )->to ( 'visualize#rank' );

$l->any ( '/viz/globe/:vkey' => [ vkey => qr/\d{14}/ ] )
  ->to ( 'visualize#globe' );

 ###
 ### widget features = special graphical elements
 ###

 $l->any (
  '/widget/contact/:intent/:palette' => [
  intent  => qr/contrib|missing|margin/,
  palette => qr/dark|neutral|bright/
  ]
 )->to ( 'widget#contact' );

 ###
 ### the widget builder and renderer
 ###

  my $w = $l->any ( '/:func' => [ func => qr/build|embed/ ] );

  $w->any (
   '/:pri/:sec/:wspec' => [
   pri   => qr/[a-z]{1,25}/,
   sec   => qr/[A-Za-z0-9_-]{1,500}/,
   wspec => qr/[a-z0-9]{1,500}/
   ]
  )->to ( "widget#do" );

  $w->any (
   '/:pri/:sec' => [
   pri => qr/[a-z]{1,25}/,
   sec => qr/[A-Za-z0-9_-]{1,500}/
  ]
  )->to ( "widget#do" );

  $w->any ( '/:wspec' => [ wspec => qr/[a-z0-9]{1,500}/ ] )->to ( "widget#do" );

  $w->any ( '/' )->to ( "widget#do" );

 ###
 ### AJAX interface(s)
 ###

 # the quick find AJAX interface
 $l->any ( '/find' )->to ( 'locate#find' );

 # the show result AJAX interface
 $l->any ( '/result' )->to ( 'main#result' );

 # the info base data provider AJAX interface
$l->any ( '/info/:cont' => [ cont => qr/std/ ] )->to ( 'main#info' );

 # front page sample photos
 $l->any ( '/sample/:width' => [ width => qr/\d{3,4}/ ] )->to ( 'main#sample' );

 # show all related expand feature
 $l->any ( '/related/:width' => [ width => qr/\d{3,4}/ ] )->to ( 'main#sample' );
 
 $l->any (
   '/expand/:pri/:sec/:drill' => [
   pri   => qr/[a-z]{1,25}/,
   sec   => qr/[A-Za-z0-9_-]{1,500}/,
   drill => qr/[a-z]{1,25}/
   ]
  )->to ( "locate#expand" );


 # add Mojolicious hooks
 $self->hook ( before_dispatch => \&before );
 $self->hook ( after_dispatch  => \&after );

} ## end sub startup

sub bounce {

 my ( $ctrl, $to ) = @_;

 #
 # the internals of Mojolicious was studied for this code
 # and the mechanism for redirect was copied from there

 $ctrl->res->code ( 301 );    # a permanent redirect

 $ctrl->res->headers->location ( $to );

 $ctrl->res->headers->content_type ( 'text/html' );

 $ctrl->res->headers->content_length ( 0 );

 $ctrl->rendered;

}

my $static = conf ( 'static' );

sub before {

 my $self = shift;
 my $s    = $self->{ stash };
  
 $s->{ time_start } = time ();
  
 $s->{ env } = conf ( 'env' );    # copy production enviroment id to stash
 
 # we start the following stash keys with z to prevent 
 # crashing with Mojolicious reserved stash names

 $s->{ zurl } = $self->req->url->to_string;  # let the url be in the stash also

 $s->{ zpath } = $self->req->url->path->to_string;    # and also the path part

 $s->{ zquery } =
  $self->req->query_params->to_string;    # and also the query params

 # all static resources served must be pre-defined
 exists $static->{ $s->{ zpath } } and $s->{ isstatic } = 1;
 
 # the default is not to let pages go through the caching
 $s->{ through } = 0;
 
 # let the "lastshow" hook to go through the caching
 $s->{ zpath } =~ m|^\/lastshow| and $s->{ through } = 1;

 # let the "result" hook to go through the caching
 $s->{ zpath } =~ m/^\/(en(?:[1-9]{6})?|fi(?:[1-9]{6})?)\/result/ and $s->{ through } = 1;
 
 # mark reroutings to stash -> easy to use later
 $s->{ isrerouted } = ( $s->{ zpath } =~ m|^/reroute| ? 1 : 0 );

 # mark queries to stash -> easy t o use later
 $s->{ isquery } = length ( $s->{ zquery } ) > 0 ? 1 : 0;

 #
 # fetch the latest version key file
 #
 # we do this for every request was is static or dynamic
 # no matter if it is cached or not
 #
 # runs on every request and takes time
 #
 # on an old windows workstation + USB hard disk rive
 # spent 15.6ms making 11 calls to
 # Catz::Util::File::findlatest, avg 1.42ms/call
 #
 # this is a good candidate for improvement but the
 # attempts so far have not produced reliable results
 #

 my $keyf = findlatest ( $ENV{ MOJO_HOME } . '/db', 'txt' );

 if ( $keyf and $keyf =~ m|(\d{14})\.txt$| ) {

  $s->{ version } = $1;

 }
 else {    # panic and nothing we can do about it

  $s->{ version } = -1;

  my $msg = '500 Suddenly, the dungeon collapses';

  $self->app->log->error ( "$msg '$keyf'" );

  $self->res->code ( 500 );
  $self->res->body ( $msg );
  $self->res->headers->content_type ( 'text/plain' );

  {
   use bytes;
   $self->res->headers->content_length ( length $msg );
  }

  return $self->rendered;

 }

 # checking path validity: we accept dots in path only for rerouting
 # paths and static paths

 index ( $s->{ zpath }, '.' ) > -1 and ( not $s->{ isrerouted } ) and do {

  $s->{ isstatic } or return $self->reply->not_found;

 };

 #
 # we require paths to end with slash if there are no query params
 #
 # you may ask why but I think this is cool
 #

      ( not $s->{ isstatic } )
  and ( not $s->{ isquery } )
  and ( not $s->{ isrerouted } )
  and ( substr ( $s->{ zpath }, -1, 1 ) ne '/' )
  and return bounce ( $self, $s->{ zpath } . '/' );

 #
 #  we also require paths with query parameters not to end with slash
 #
 #  again, you may ask why but I think this is cool
 #

      ( not $s->{ isstatic } )
  and ( $s->{ isquery } )
  and ( not $s->{ isrerouted } )
  and ( substr ( $s->{ zpath }, -1, 1 ) eq '/' )
  and return bounce ( $self,
  ( substr ( $s->{ zpath }, 0, -1 ) . '?' . $s->{ zquery } ) );

 #
 # attempt to fetch from cache
 #

 if ( $s->{ cache_obj } = cache_get ( cachekey ( $self ) ) ) {

  # cache hit

  $self->tx->res ( $s->{ cache_obj }->[0] );
  
  $s->{ dna } = ( $s->{ cache_obj }->[1] );
  
  return $self->rendered;

 }

 $s->{ lang }  = 'en';    # default to English
 $s->{ langa } = 'en';

 # default is meta robots "index,follow",
 # controllers and later code may modify these as needed
 # by setting to false sets noindex,nofollow respectively
 $s->{ meta_index } = $s->{ meta_follow } = 1;
 
 # set global limit of the number of photos that must be
 # exceeded to enable widget build
 $s->{ widgetnon } = 14;

 if ( $s->{ zurl } =~ /^\/((en|fi)([1-9]{6})?)/ ) {

  $s->{ langa } = $1;
  $s->{ lang }  = $2;
  $s->{ setup } = $3 // setup_default;

  # prevent indexing of pages with non-default setup
  # also disable follow since there is no point
  $3 and ( $s->{ meta_index } = $s->{ meta_follow } = 0 );
  
  $s->{ langother } = $s->{ lang } eq 'fi' ? 'en' : 'fi';

  $s->{ langaother } = $s->{ langother } . ( $3 // '' );

  # process and populate stash with setup data
  # returns true if success
  setup_init ( $self, $s->{ setup } )
   or return $self->reply->not_found;

 }

 # let some definitions to be globally available to all controllers
     
 $s->{ now } = dtlang ( $s->{ lang } );

 $s->{ matrix } = list_matrix;

 $s->{ setup_keys } = setup_keys;

 $s->{ setup_values } = setup_values ( $s->{ setup } );

 $s->{ facebookkey } = conf ( 'key_facebook' );
 $s->{ twitterkey }  = conf ( 'key_twitter'  );

 # the global layout separator characters
 $s->{ sep }     = '.';
 $s->{ pathsep } = '>';

 # the url where the all photos are
 $s->{ photobase } = conf ( "base_photo" );

 # the url where the all flag gifs are
 $s->{ flagbase } = conf ( "base_flag" );
  
 # fetch texts for the current language and make them available to all
 # controller and templates as variable t

 $s->{ ten } = text ( 'en' );
 $s->{ tfi } = text ( 'fi' );

 $s->{ t } = $s->{ lang } eq 'fi' ? $s->{ tfi } : $s->{ ten };

} ## end sub before

sub after {

 my $self = shift;
 my $s    = $self->{ stash };

 # 2 hours initial lifetime for all content
 # was 1 hour up to 2012-12-27
 my $age = 2 * 60 * 60; 
 
 $self->res->headers->header ( 'Last-Modified' ) and do {

  # static file-based dispatchs
  
  $self->res->headers->header (
   'Cache-Control' => 'max-age=' . $age . ', public' 
  );

  $self->res->headers->header (
   'Expires' => epoch2http ( ( dt2epoch dt ) + $age ) 
  );

  $self->res->headers->header ( 'X-Catz-Origin' => 'static' );  

  return $self->rendered;

 };

 # dynamic dispatchs continue

 # purify html output, if not from cache

 my $ct = $self->res->headers->content_type // '';

 ( $ct =~ m|^text/html| and not $s->{ cache_obj } ) and do {

  my $str = $self->res->body;

  $str =~ s|\r\n|\n|g;      # convert windows newlines to unix newlines
  $str =~ s|\s*\n\s*|\n|g;  # convert whitespace constellations to one newline
  $str =~ s|\n\"|\"|g;      # remove newlines that occur just before "

  $self->res->body ( $str );

  { use bytes; $self->res->headers->content_length ( length $str ) }

 };
 
 # dna generation, if not yet in stash (not got from cache)
 
 defined $s->{ dna } or $s->{ dna } = dna ( $self->res->body // 'NONE' );

 # now we use If-None-Match if present in request

 if ( my $etag = $self->req->headers->header ( 'If-None-Match' ) ) {
 
  $etag eq qq{"$s->{ dna }"} and do {
  
   # no need to send response, the old response is still valid 

   $self->res->code ( 304 );
   $self->res->body ( '' );
   $self->res->headers->content_length ( 0 );
   return $self->rendered;
  
  };
 
 }

 my $code = $self->res->code // 0;

 #
 # write to cache if not from cache and healthy status
 #

 ( $code == 200 )
  and ( not defined $s->{ cache_obj } )
  and not ( $s->{ through } ) 
  and cache_set ( 
   cachekey ( $self ), [ $self->tx->res, $s->{ dna } ] 
  );

 if ( $code == 200 and not ( $s->{ through } ) ) {    
 
  # healthy response and allowed to be cached

  # we send dna as ETag

  $self->res->headers->header ( 'ETag' => qq{"$s->{ dna }"} );

  $self->res->headers->header (
   'Cache-Control' => 'max-age=' . $age . ', public' 
  );

  $self->res->headers->header (
   'Expires' => epoch2http ( ( dt2epoch dt ) + $age ) 
  );

 } ## end if ( $code == 200 )
 elsif ( $code > 399 or $s->{ through } ) {

  # unhealthy response, not "redirect" or "not modified"
  # not allowed to be cached
  
  # expire immediately

  $self->res->headers->header (
   'Cache-Control' => 'max-age=0, must-revalidate' );

  $self->res->headers->header ( 'Expires' => epoch2http ( ( dt2epoch dt ) ) );

 }

 # custom app headers

 $self->res->headers->header ( 'X-Catz-Version' => $s->{ version } );  

 $self->res->headers->header ( 'X-Catz-Env' => "catz$s->{env}" );
 
 $self->res->headers->header ( 'X-Catz-Origin' =>  
  defined $s->{ cache_obj } ? 'cache' : 'dynamic' 
 );
 
 # timing

 $s->{ time_end } = time ();

 my $ti = round ( ( ( $s->{ time_end } - $s->{ time_start } ) * 1000 ), 0 );

 $self->res->headers->header ( 'X-Catz-Timing' => "$ti ms" );
 
 $TIME_PAGE and warn "PAGE $s->{zurl} = $ti ms";

} ## end sub after

sub cachekey {
 (
  $_[ 0 ]->{ stash }->{ version  },
  $_[ 0 ]->{ stash }->{ zurl     }
 );
}

1;
