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

use Time::HiRes qw ( time );

use Catz::Core::Cache;
use Catz::Core::Conf;
use Catz::Core::Text;

use Catz::Data::List qw ( list_matrix );
use Catz::Data::Setup;

use Catz::Util::File qw ( fileread findlatest pathcut );
use Catz::Util::Time qw( 
 dt dt2epoch dtdate dttime dtexpand dtlang epoch2http thisyear 
);
use Catz::Util::Number qw ( fmt fullnum33 round );
use Catz::Util::String qw ( 
 clean enurl etag decode encode limit trim urirest 
);

my $time_page = 0;  # turns on timing on all HTTP requests

my $version = undef; # data version

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
  qw ( dt dt2epoch dtdate dttime dtexpand fmt clean enurl limit trim 
  fullnum33 thisyear encode decode round urirest ) 
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
 #  to the number of minutes the hold tells it to
 #
 #  0 disables HTTP caching and also server side page caching 
 #

 ###
 ### the site's bare root gets passed to language detection mechanism
 ###

 $r->route('/')->to( "main#detect", hold => 0 );
 
 ###
 ### the stylesheets 
 ### 
 
 # reset
 $r->route( '/style/reset' )->to( 'main#reset', hold => 60 * 24 );
 
 # the single stylesheet contains all style definitions
 # it's color settings are dependent on the palette 
 $r->route( '/style/:palette' )->to( 'main#base', hold => 60 );
 
 ###
 ### www.catshow.fi itegration
 ###
  
 # the interface provided for the purposes of www.catshow.fi
 # please note that although this can be used to other purposes
 # the interface is subject to changes and cannot be relied on
 $r->route( '/lastshow' )->to( 'main#lastshow',  hold => 60 );
 
 ###
 ### tools
 ###
 
 # the database verifier service (simple non-destructive routine)
 $r->route( '/tools/verify/:auth', auth => qr/[a-z0-9]{8}/ )
  ->to( 'main#verify', hold => 0 );

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
 $l->route( '/' )->to( 'main#front', hold => 30 );
 
 ###
 ### the news service
 ###
 
 # the index page of all articles
 $l->route( '/news' )->to ( "news#index", hold => 15 );
 
 # single article
 $l->route( '/news/:article', article => qr/\d{14}/ )
  ->to ( "news#one", hold => 30 );

 # RSS feed    
 $l->route( '/feed' )->to ( "news#feed", hold => 15 );

 ###
 ### the lists
 ###

 # the list of lists (list index)
 $l->route( '/lists' )->to('locate#lists', hold => 30 );

 # a single list 
 $l->route( '/list/:subject/:mode' )->to('locate#list', hold => 30 );
 
 ###
 ### photo browsing and viewing - 3 ways
 ###
 
 ### #1: browse all & view all
 
 my $a = $l->route( '/:action', action => qr/browseall|viewall/ )
  ->to( hold => 30 );
  
 # with photo id
 $a->route( '/:id', id => qr/\d{6}/ )->to( controller => 'all' ); 
 
 # without photo id
 $a->route( '/' )->to( controller => 'all', id => undef );

 ### #2: pair browse & pair view

 my $p = $l->route( '/:action', action => qr/browse|view/ )
  ->to( hold => 30 );
  
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
  ->to( hold => 30 );   

 # with photo id
 $s->route( '/:id', id => qr/\d{6}/ )->to( controller => 'pattern' ); 

 # without photo id
 $s->route( '/' )->to( controller => 'pattern', id => undef );
 
 ###
 ### AJAX interface(s)
 ###

 # the quick find AJAX interface 
 $l->route( '/find' )->to ( "locate#find", hold => 30 );

 # the show result AJAX interface
 $l->route( '/result' )->to ( "main#result",  hold => 60 );
      
 # add hooks to methods that are to be executed before and after the dispatch
 $self->hook ( before_dispatch => \&before );  
 $self->hook ( after_dispatch => \&after );
 
}

sub before {

 my $self = shift; my $s = $self->{stash};

 # we skip all processing for static files
 ( $self->req->url->path->to_string  =~ /\..{2,4}$/ ) and return;
 
 $time_page and $s->{time_start} = time();
 
 my $dbp = $ENV{MOJO_HOME}.'/db';
 
 ( defined $version and ( -f "$dbp/$version.txt" ) ) or do {
 
  # version not detected earlier or no longer valid
  
  # fetch the latest key file
  my $keyf = findlatest ( $dbp, 'txt' );
  
  defined $keyf and do {
  
   # we make it very safe: if anything is wrong we continue to run
   # with the old database and data version
  
   my $newv = substr ( pathcut ( $keyf ), 0, 14 );
   
   -f "$dbp/$newv.db" and $version = $newv; 
   
  };   
  
 };
  
 $s->{version} = $version; # data version
 
 #
 # require urls to end with slash when there is no query params
 # you may ask why but I think this is cool
 #
 # the internals of Mojolicious was studied for this code
 # and the mechanism for redirect was copied from there
 #
 
  if ( scalar @{ $self->req->query_params->params } == 0 ) {
  
  $self->req->url->path->trailing_slash or do {

   $self->res->code(301); # a permanent redirect

   $self->res->headers->location(
    $self->req->url->path->to_string.'/' # add a slash
   );
   
   $self->res->headers->content_length(0); 
   $self->rendered;
   return;

  };

 }

 $s->{url} = $self->req->url;  # let the url be in the stash also

 $s->{lang} = 'en'; # default to English
 $s->{langa} = 'en';

 # default is meta robots "index,follow",
 # controllers may modify these as needed
 # by setting to false sets noindex,nofollow respectively 
 $s->{meta_index} = 1;
 $s->{meta_follow} = 1;
  
 if ( $s->{url} =~ /^\/((en|fi)([1-9]{6})?)\// ) {
  
  $s->{langa} = $1; $s->{lang} = $2;
    
  $3 and do { # if running with non-default setup then no indexing
   $s->{meta_index} = 0;
   $s->{meta_follow} = 0;
  };
  

  $s->{langother} = $s->{lang} eq 'fi' ? 'en' : 'fi';
 
  $s->{langaother} = $s->{langother} . ( $3 // '' );  
 
  # process and populate stash with setup data
  # returns true if success                                                                                  
  setup_init ( $self, $s->{langa} ) or
   ( $self->render_not_found and return );   
 
 }
 
         
 # attempt to fetch from cache
 if ( my $res = cache_get ( cachekey ( $self ) ) ) {  # cache hit
 
  $self->res->code(200);
  $self->res->headers->content_type( $res->[0] );
  defined $res->[1] and $self->res->headers->content_length( $res->[1] );
  defined $res->[2] and $self->res->headers->header( 'Cache-Control' => $res->[2] );
  defined $res->[3] and $self->res->headers->header( 'ETag' => $res->[3] );
  defined $res->[4] and $self->res->headers->header( 'Last-Modified' => $res->[4] );
  $self->res->body( ${ $res->[5] } ); # scalar ref to prevent copying
  $self->rendered;
  $s->{cached} = 1; # mark that the content came from cache
  
  $time_page and $s->{time_end} = time();
 
  $time_page and warn "PAGE $s->{url} -> " . round ( ( ( $s->{time_end} - $s->{time_start}  ) * 1000 ), 0 ) . ' ms' ;
  
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
 
 # we skip all processing for static files
 ( $self->req->url->path->to_string  =~ /\..{2,4}$/ ) and return;
 
 # we require the basics to be available for further processing   
 ( 
  defined $s->{controller} and defined $s->{action} and defined $s->{url} 
 ) or return;

 $self->res->headers->header(
  'Last-Modified' => epoch2http ( dt2epoch ( $s->{version} ) )  
 );
 
 $self->res->headers->header ( 'ETag' => etag ( $self->res->body ) );  

 my $age = 0; # lifetime in response headers, default to no lifetime 
 my $cac = 0; # server side caching  
 
 if ( $s->{hold} > 0 ) {
   
   $age = $s->{hold}*60; # convert minutes to seconds
   
   $cac = 1; # set server side page caching on
  
 }
  
 # set age back to 0 if not in production = disable browser's cache in dev
 $ENV{MOJO_MODE} eq 'production' or $age = 0;
 
 # set cache response header
 $self->res->headers->header('Cache-Control' => 'max-age=' . $age );
 
 $cac or return; # continue only if server side page caching is needed
 
 # no recaching: if the result came from the cache then don't cache it again
 $s->{cached} and return;
 
 # we cache only GET and with 200 OK to be safe
 if ( $self->req->method eq 'GET' and $self->res->code == 200 ) {

  cache_set (
   
   cachekey ( $self ),
   [ 
    $self->res->headers->content_type,
    $self->res->headers->content_length // undef,
    $self->res->headers->header('Cache-Control') // undef,
    $self->res->headers->header('ETag') // undef,
    $self->res->headers->header('Last-Modified') // undef,
    \$self->res->body # scalar ref to prevent copying
   ]
  );
   
 }
 
 $time_page and $s->{time_end} = time();
 
 $time_page and warn "PAGE $s->{url} -> " . round ( ( ( $s->{time_end} - $s->{time_start}  ) * 1000 ), 0 ) . ' ms' ;
   
}

# the key for page caching consists of namespace 'page', 
# the url and all setup values in the order of their keys

sub cachekey { (
 $_[0]->{stash}->{version}, 'page', $_[0]->{stash}->{url}, 
 map { $_[0]->{stash}->{$_} } setup_keys
) }

1;