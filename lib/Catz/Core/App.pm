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

package Catz::Core::App;

# The Catz Mojolicious application

use 5.10.0; use strict; use warnings;

use parent 'Mojolicious';

use Mojo::Util qw ( html_escape );

use Time::HiRes qw ( time );

use Catz::Core::Cache;
use Catz::Core::Conf;
use Catz::Core::Text;

use Catz::Data::List qw ( list_matrix );
use Catz::Data::Setup;

use Catz::Util::File qw ( fileread findlatest pathcut );
use Catz::Util::Time qw( 
 dt dt2epoch dtdate dttime dtexpand dtlang epoch2http http2epoch thisyear 
);
use Catz::Util::Number qw ( fmt fullnum33 round );
use Catz::Util::String qw ( 
 clean enurl decode encode limit trim urirest 
);

my $time_page = 0;  # turns on timing on all HTTP requests

sub startup {

 my $self = shift;
 
 # template directory
 $self->renderer->root ( $ENV{MOJO_HOME}.'/tmpl' );
 
 # cookie settings from config
 $self->sessions->cookie_name( conf ('cookie_name' ) );
 $self->sessions->default_expiration( conf ( 'cookie_expir' ) );
 
  # initialize the key for cookie signing 
 $self->secret( conf ( 'cookie_key' ) );

 # map utility subs from different modules to Mojolicious helpers
 # we use dynamically generated subs as bridges
 foreach my $sub ( 
  qw ( dt dt2epoch dtdate dttime dtexpand fmt clean enurl html_escape limit 
  trim fullnum33 thisyear encode decode round urirest ) 
 ) {

  $self->helper ( $sub => eval qq{ sub {
    
  # we do 'shift' to ditch 'self' that comes in first in helper calls 
  shift;

  return $sub \@\_; # the actual pass-thru call with rest of the arguments

  } } );

 }
        
 my $r = $self->routes;
   
 $r->namespace( 'Catz::Ctrl' ); # all controllers live at Catz::Ctrl
 
 #
 # 'hold' stash var controls caching so that it sets max-age HTTP header
 # to the number of minutes the hold tells it to
 #
 # 0 disables HTTP caching and also server side page caching 
 #
 # negative value indicates that max-age should be set to abs value
 # but page caching should be bypassed 
 #
 
 ###
 ### the site's bare root gets passed to language detection mechanism
 ###

 $r->route('/')->to( "main#detect", hold => 0 );
 
 ###
 ### rerouting of old site's pages and resources
 ###
 $r->route( '/reroute/*src' )->to( 'reroute#reroute', hold => 0 );
 $r->route( '/reroute' )->to( 'reroute#reroute', hold => 0 );
 
 ###
 ### the stylesheets 
 ### 

 # a stylesheet for banners - background color as a parameter
 $r->route( '/style/banner' )->to( 'style#banner', hold => 60 );
   
 # reset
 $r->route( '/style/reset' )->to( 'style#reset', hold => 24*60 );
 
 # the single stylesheet contains all style definitions
 # it's color settings are dependent on the palette 
 $r->route( '/style/:palette', palette => qr/dark|neutral|bright/ )
  ->to( 'style#base', hold => 60 );
  
 ###
 ### www.catshow.fi itegration
 ###
  
 # the interface provided for the purposes of www.catshow.fi
 # please note that although this can be used to other purposes
 # the interface is subject to changes and cannot be relied on
 
 # basic case: latest album with sufficient number of data
 $r->route( '/lastshow' )->to( 'catshow#lastshow',  hold => 15 );
 
 # new case 2011-09-24 
 $r->route( 
  '/anyshow/:date/:loc', date => qr/\d{4}\-\d{2}\-\d{2}/,
  loc => qr/[a-zåäöA-ZÅÄÖ0-9-]{1,30}/ 
 )->to( 'catshow#anyshow', hold => 15 );
 
 # all site's true content is under /:langa where langa is 'en' or 'fi'
 # and it can be extended by magic code defining the user settings
 #
 # the language code sets the content language
 #
  my $l = $r->route ( 
   '/:dummy', 
   dummy => qr/en(?:[1-9]{6})?|fi(?:[1-9]{6})?/ 
  );
 
 # the front page is at the root under the language
 $l->route( '/' )->to( 'main#front', hold => 60 );
 
 ###
 ### the news service
 ###
 
 # the index page of all articles
 $l->route( '/news' )->to ( "news#index", hold => 60 );
 
 # single article
 $l->route( '/news/:article', article => qr/\d{14}/ )
  ->to ( "news#one", hold => 60 );

 # RSS feed    
 $l->route( '/feed' )->to ( "news#feed", hold => 60 );

 ###
 ### the lists
 ###

 # the list of lists (list index)
 $l->route( '/lists' )->to('locate#lists', hold => 60 );

 # a single list 
 $l->route( 
  '/list/:subject/:mode', 
  subject => qr/[a-z]{1,25}/,
  mode => qr/[a-z0-9]{1,25}/, 
 )->to('locate#list', hold => 60 );
 
 ###
 ### photo browsing and viewing - 3 ways
 ###
 
 ### #1: browse all & view all
 
 my $a = $l->route( '/:action', action => qr/browseall|viewall/ )
  ->to( hold => 60 );
  
 # with photo id
 $a->route( '/:id', id => qr/\d{6}/ )->to( controller => 'all' ); 
 
 # without photo id
 $a->route( '/' )->to( controller => 'all', id => undef );

 ### #2: pair browse & pair view

 my $p = $l->route( '/:action', action => qr/browse|view/ )
  ->to( hold => 60 );
  
 # with photo id
 $p->route( ':pri/:sec/:id', 
  pri => qr/[a-z]{1,25}/, sec => qr/[A-ZA-z0-9_-]{1,500}/, id => qr/\d{6}/ 
 )->to( controller => 'pair' );
 
 # without photo id
 $p->route( ':pri/:sec/', 
  pri => qr/[a-z]{1,25}/, sec => qr/[A-ZA-z0-9_-]{1,500}/ )->to( 
   controller => 'pair', id => undef 
  );

 ### #3: search browse & search view

 my $s = $l->route( '/:action', action => qr/search|display/ )
  ->to( hold => 60 );   

 # with photo id
 $s->route( '/:id', id => qr/\d{6}/ )->to( controller => 'pattern' ); 

 # without photo id
 $s->route( '/' )->to( controller => 'pattern', id => undef );
 
 ###
 ### banners
 ###

 $l->route( # the banner itself 
  '/banner/:pri/:sec/:width/:height', 
  pri => qr/[a-z]{1,25}/, 
  sec => qr/[A-ZA-z0-9_-]{1,500}/,
  width => qr/\d{2,4}/,
  height => qr/\d{2,4}/  
 )->to('banner#banner', hold => 60 );

 $l->route( # the example code for embedding 
  '/embed/:pri/:sec/:width/:height', 
  pri => qr/[a-z]{1,25}/, 
  sec => qr/[A-ZA-z0-9_-]{1,500}/,
  width => qr/\d{2,4}/,
  height => qr/\d{2,4}/  
 )->to('banner#embed', hold => 60 );
 
 $l->route( # the example code for embedding 
  '/preview/:pri/:sec/:width/:height', 
  pri => qr/[a-z]{1,25}/, 
  sec => qr/[A-ZA-z0-9_-]{1,500}/,
  width => qr/\d{2,4}/,
  height => qr/\d{2,4}/  
 )->to('banner#preview', hold => 60 );
  
 ###
 ### Visualizations
 ###

 # vkey is required to make request version unique but is not used
  
 $l->route( 
  '/viz/dist/:full:/:breed/:none/:vkey',

  full => qr/\d{1,5}/, breed => qr/\d{1,5}/, none => qr/\d{1,5}/, 
  vkey => qr/\d{14}/
 )->to( 'visualize#dist', hold => 0 );

 $l->route( 
  '/viz/rank/:pri/:sec/:vkey',
  pri => qr/[a-z]{1,25}/, sec => qr/[A-ZA-z0-9_-]{1,500}/, vkey => qr/\d{14}/
 )->to( 'visualize#rank', hold => 0 );

 $l->route( 
  '/viz/cover/:total/:vkey', total => qr/\d{1,5}/, vkey => qr/\d{14}/  
 )->to( 'visualize#cover', hold => 0 );

 $l->route( '/viz/globe/:vkey', vkey => qr/\d{14}/ )
  ->to( 'visualize#globe', hold => 0 );
 
 ###
 ### AJAX interface(s)
 ###

 # the quick find AJAX interface 
 $l->route( '/find' )->to ( "locate#find", hold => 60 );

 # the show result AJAX interface
 $l->route( '/result' )->to ( "catshow#result",  hold => -15 );
 # when 15 min is combined to maximum of 10 min on model cache
 # and to the fact that page cache is bypassed (negative hold)
 # it is 25 and so we can say that results refresh every 30 mins
 
 # the info base data provided AJAX interface
 $l->route( '/info/:cont', cont => qr/std/ )
  ->to ( "main#info", hold => 24*60 );
      
 # add hooks to methods that are to be executed before and after the dispatch
 $self->hook ( before_dispatch => \&before );  
 $self->hook ( after_dispatch => \&after );
 
}

my $static = conf ( 'static' );

sub before {

 my $self = shift; my $s = $self->{stash};
 
 $s->{url} = $self->req->url;  # let the url be in the stash also
  
 # setting the analytics keys and codes
 # must be done first and also for static requests 
 # since if a static request fails it renders a template that 
 # contains a use of the key 
 $s->{analyticskey} = undef; $s->{traffickey} = undef;
  
 conf ( 'lin' ) and do { 
  
  $s->{analyticskey} = conf ( 'key_analytics' );     
  $s->{traffickey} = conf ( 'key_traffic' );
  
 };

 $s->{isstatic} = 0;

 my $path = $self->req->url->path->to_string; 

 # static URLs server by Mojolicious must be pre-defined
 defined $static->{$path} and do {
 
  $s->{isstatic} = 1; return;
  
 };
 
 $path =~ m|^/reroute| or do { 
 
  index ( $path, '.' ) > -1 and do {
 
   # reject non-static urls having dot in path
   $self->render_not_found; return; 
 
  };
  
 }; 
  
 $s->{pkey} = conf ( 'pkey' ); # copy production enviroment key
 
 # default is not to cache so routing should set hold appropriately 
 $s->{hold} = 0; 
    
 $time_page and $s->{time_start} = time();
 
 # 
 # fetch the latest version key file
 # 
 # runs on every request and takes time
 # 
 # on slow windows workstation + USB hard drive
 # spent 15.6ms making 11 calls to 
 # Catz::Util::File::findlatest, avg 1.42ms/call
 #
 # this is a good candidate for improvement but the 
 # previous attempts have not produced reliable results
 #  
      
 my $keyf = findlatest ( $ENV{MOJO_HOME}.'/db', 'txt' );
 
 if ( $keyf and $keyf =~ m|(\d{14})\.txt$| ) { 
 
  $s->{version} = $1;
  
 } else { # panic and nothing we can do about it
 
   $s->{version} = -1;
   
   my $msg = '500 Suddenly, the dungeon collapses.'; 
   
   $self->app->log->error( "$msg Got '$keyf'." ); 
     
   $self->res->code(500);
   $self->res->body ( $msg );
   $self->res->headers->content_type ( 'text/plain' );
   
   { use bytes;    
    $self->res->headers->content_length ( length $msg );
   }
    
   $self->rendered;
   
   return;
   
 } 
 
 #
 # require urls to end with slash when there is no query params
 # you may ask why but I think this is cool
 #
 # the internals of Mojolicious was studied for this code
 # and the mechanism for redirect was copied from there
 #
 
 ( scalar @{ $self->req->query_params->params } == 0 ) and do {
 
  ( $s->{url} =~ m|^/reroute| ) or do { 
  
   $self->req->url->path->trailing_slash or do {
  
    $self->res->code(301); # a permanent redirect

    $self->res->headers->location(
     $s->{url}.'/' # add a slash
    );
   
    $self->res->headers->content_length(0); 
    $self->rendered;
    return;
    
   };

  };

 };

 # Some cache control logic
 
 # We use If-Modified-Since if present in request 
 my $since = $self->req->headers->header('If-Modified-Since');
 
 $since = $since ? http2epoch $since : 0; # convert to epoch
 
 my $curr = dt2epoch $s->{version}; # convert data version to epoch
  
 if ( $curr == $since ) {
 
  # no need to send response, the old response is still ok
 
  $self->res->code(304);
  $self->res->body('');
  $self->res->headers->content_length(0);
  $self->rendered;
  return; 
 
 }
   
 $s->{lang} = 'en'; # default to English
 $s->{langa} = 'en';

 # default is meta robots "index,follow",
 # controllers may modify these as needed
 # by setting to false sets noindex,nofollow respectively 
 $s->{meta_index} = 1;
 $s->{meta_follow} = 1;
  
 if ( $s->{url} =~ /^\/((en|fi)([1-9]{6})?)\// ) {
  
  $s->{langa} = $1; $s->{lang} = $2;
    
  $3 and do { # if running with non-default setup then no indexing, no follow
   $s->{meta_index} = 0;
  };
  
  $s->{langother} = $s->{lang} eq 'fi' ? 'en' : 'fi';
 
  $s->{langaother} = $s->{langother} . ( $3 // '' );
   
  # process and populate stash with setup data
  # returns true if success                                                                                  
  setup_init ( $self, $s->{langa} ) or do {
  
   $self->render_not_found; return; 
 
  };
    
 }
         
 # attempt to fetch from cache
 if ( my $res = cache_get ( cachekey ( $self ) ) ) {  # cache hit
 
  $self->res->code(200);
  defined $res->[0] and $self->res->headers->content_type( $res->[0] );
  defined $res->[1] and $self->res->headers->content_length( $res->[1] );
  defined $res->[2] and do {
  
   # Expires must be recalcuated to correspond the durrent date
   
   $self->res->headers->header(
    'Expires' => epoch2http ( abs ( $res->[2] ) + ( dt2epoch dt ) ) 
   );
   
  };
  defined $res->[3] and $self->res->headers->header( 'Cache-Control' => $res->[3] );
  defined $res->[4] and $self->res->headers->header( 'Last-Modified' => $res->[4] );
  $self->res->body( ${ $res->[5] } ); # scalar ref to prevent copying
  $self->rendered;
  $s->{cached} = 1; # mark that the content came from cache
  
  $time_page and $s->{time_end} = time();
 
  $time_page and warn "PAGE $s->{url} -> " . round ( ( ( $s->{time_end} - $s->{time_start}  ) * 1000 ), 0 ) . ' ms (cache)' ;
  
  return $self;

 } else {
 
  $s->{cached} = 0;

 }
      
 # let some definitions to be globally available to all controllers
 
 $s->{matrix} = list_matrix;
 
 $s->{setup_keys} = setup_keys;
 
 $s->{setup_values} = setup_values ( $s->{langa} );
 
 $s->{facebookkey} = conf ( 'key_facebook' ); 
 $s->{twitterkey} = conf ( 'key_twitter' );
  
 # the global layout separator characters
 $s->{sep} = '.';
 $s->{pathsep} = '>';

 $s->{photobase} = conf ( 'base_photo' ); # the url where the all photos are
 $s->{flagbase} = conf ( 'base_flag' );  # the url where the all flag gifs are
   
 $s->{now} = dtlang ( $s->{lang} );
 
 # fetch texts for the current language and make them available to all
 # controller and templates as variable t 
 $s->{t} = text ( $s->{lang} );
 $s->{ten} = text ( 'en' );
   
}

sub after {

 my $self = shift; my $s = $self->{stash};
 
 
 $self->res->code == 200 or do {

   ( ( $self->res->code == 404 ) or ( $self->res->code == 500 ) ) and do {
   
    # force no caching on errors
   
    $self->res->headers->header( 
     'Cache-Control' => 'max-age=0, must-revalidate' 
    );
        
    $self->res->headers->header(
     'Expires' => epoch2http ( dt2epoch dt ) 
    );
  
  };
  
  # prevent erros for further processing 
  # like more headers setting or caching 
  return;
 
 };
  
 $s->{isstatic} and do {
 
  # for static content we just mess with caching headers and exit
  
  my $age = 60*60; # the default is 1 h
  
  given ( $self->req->url->path->to_string ) {
  
   when ( [ qw ( /robots.txt /favicon.ico ) ] ) {
    $age = 60*60*24*7; # 7 d
   }

   when ( m|^/img/| ) {
    $age = 60*60*24*7; # 7 d
   }
   
   when ( m|^/js_lib/| ) {
    $age = 60*60*24; # 1 d
   }
  
  }  
   
  $self->res->headers->header(
   'Cache-Control' => 'max-age=' .  $age . ', public' 
  );

  $self->res->headers->header(
   'Expires' => epoch2http ( $age + ( dt2epoch dt ) ) 
  );
 
  return; # for static content we just set one header and exit 
 
 };

 # no recaching: if the result came from server side the cache 
 # then don't cache it again
 $s->{cached} and return;
  
 # we require the basics to be available for further processing   
 ( 
  defined $s->{controller} and defined $s->{action} and defined $s->{url} 
 ) or return;
 
 # 
 # we purify html outputs
 #
 my $ct = $self->res->headers->content_type // 'void';
 ( $ct =~ m|^text/html| ) and do {
   
  my $str = $self->res->body;
  
  $str =~ s|\r\n|\n|g; # convert windows newlines to unix newlines
  $str =~ s|\s*\n\s*|\n|g; # convert whitespace constellations to one newline 
  $str =~ s|\n\"|\"|g; # remove newlines that occur just before "
    
  $self->res->body( $str );
  
  { use bytes; $self->res->headers->content_length( length $str ) }
  
 };
   
 # from seconds to minutes, and 0 * 60 is still 0
 $s->{hold} = $s->{hold} * 60;
     
 # set cache response headers, use absolute hold (can be negative)
  
 $self->res->headers->header(
  'Cache-Control' => 'max-age=' .  abs ( $s->{hold} ) . ', public' 
 );

 $self->res->headers->header(
  'Expires' => epoch2http ( abs ( $s->{hold} ) + ( dt2epoch dt ) ) 
 );
 
 # continue only if server side page caching is needed
 $s->{hold} > 0 or return;
 # if no page caching then no Last-Modified
 
 # 
 # we use data version as last modified time
 #
 $self->res->headers->header(
  'Last-Modified' => epoch2http ( dt2epoch ( $s->{version} ) )  
 );
 #
 # this means that deployments of the system must always deploy 
 # an new data version, otherwise cache logic gets broken
 #
  
 cache_set (
   
  cachekey ( $self ),
  [ 
   $self->res->headers->content_type // undef,
   $self->res->headers->content_length // undef,
   $s->{hold} // undef,
   $self->res->headers->header('Cache-Control') // undef,
   $self->res->headers->header('Last-Modified') // undef,
   \$self->res->body # scalar ref to prevent copying
  ]
 );
  
 $time_page and $s->{time_end} = time();
 
 $time_page and warn "PAGE $s->{url} -> " . round ( ( ( $s->{time_end} - $s->{time_start}  ) * 1000 ), 0 ) . ' ms (real)' ;
   
}

# the key for page caching consists of the data version,
# namespace 'page' and the url

sub cachekey { (
 $_[0]->{stash}->{version}, 'page', $_[0]->{stash}->{url}, 
 ) }

1;