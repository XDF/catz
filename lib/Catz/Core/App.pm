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

#
# The Catz Mojolicious application
#

use 5.10.0; use strict; use warnings;

use parent 'Mojolicious';

use Time::HiRes qw ( time );

use Catz::Core::Cache;
use Catz::Core::Conf;
use Catz::Core::Text;

use Catz::Data::List qw ( list_matrix );
use Catz::Data::Setup;

use Catz::Util::File qw ( fileread findlatest pathcut );
use Catz::Util::Time qw( dt dtdate dttime dtexpand dtlang thisyear );
use Catz::Util::Number qw ( fmt fullnum33 round );
use Catz::Util::String qw ( clean enurl decode encode limit trim );

my $time_page = 0;  # turns on timing on all HTTP requests

my $ver = conf ( 'ver' ); # application version

my $version = undef; # data version

sub startup {

 my $self = shift;
 
 # template directory
 $self->renderer->root ( $ENV{MOJO_HOME}.'/tmpl' );
 
 # cookie settings from config
 $self->sessions->cookie_name( conf ('cookie_name' ) );
 $self->sessions->default_expiration( conf ( 'cookie_expir' ) );

 # map utility subs from different modules to Mojolicious helpers
 # we use dynamically generated subs as bridges
 foreach my $sub ( 
  qw ( dtdate dttime dtexpand fmt clean enurl limit trim 
  fullnum33 thisyear encode decode round ) 
 ) {

  $self->helper ( $sub => eval qq{ sub {
    
  # we do 'shift' to ditch 'self' that comes in first in helper calls 
  shift;

  return $sub \@\_; # the actual pass-thru call with rest of the arguments

  } } );

 }
 
 # route definitions       
 my $r = $self->routes;
  
 # all controllers are Catz::Ctrl 
 $r->namespace( 'Catz::Ctrl' );
 
 #
 # 'hold' controls caching 
 #
 # it has an effect both on response headers and
 # on the server side page cache
 #
 # 'off' = disable all caching
 # 'dynamic' = content changes dynamically from time to time
 # 'static' = static-type of content that changes only on data load 
 #

 # if the site's bare root is requested then pass to language detector
 $r->route('/')->to( "main#detect", hold => 'off' );

 # the stylesheets
 $r->route( '/style/reset' )->to( 'main#reset', hold => 'static' );
 $r->route( '/style/:palette' )->to( 'main#base', hold => 'static' );
 
 # set the user parameters
 $r->route( '/set' )->to( 'main#set', hold => 'off' );
 
 # the interface provided for catshow.fi service
 # please note that although you can use this for your purposes
 # the interface is subject to changes negotiated between
 # catza.net and catshow.fi and thus can change anytime
 $r->route( '/lastshow' )->to( 'main#lastshow',  hold => 'static' );

 # all site's content is under /:lang where lang is 'en' or 'fi'
 # so the content is provided in two languages
 # in the future the will be no more languages
 my $l = $r->route ('/:lang', lang => qr/en|fi/ );
 
 # the front page is in the root under the language
 $l->route( '/' )->to( 'main#front', hold => 'dynamic' );
 
 # the site's news
 $l->route( '/news' )->to ( "news#all", hold => 'static' );  
 $l->route( '/feed' )->to ( "news#feed", hold => 'static' );

 # lists 
 $l->route( '/list/:subject/:mode' )->to('locate#list', hold => 'static' );
 
 # photo browsing and viewing - 3 different ways

 # #1: browse all & view all
 
 my $a = $l->route( '/:action', action => qr/browseall|viewall/ )
  ->to( hold => 'static' );   

 $a->route( '/:id', id => qr/\d{6}/ )->to( controller => 'all' ); 
 
 $a->route( '/' )->to( controller => 'all', id => undef );

 # #2: pair browse & pair view

 my $p = $l->route( '/:action', action => qr/browse|view/ )
  ->to( hold => 'static' );   

 $p->route( ':pri/:sec/:id', 
  pri => qr/[A-ZA-z0-9_-]+/, sec => qr/[A-ZA-z0-9_-]+/, id => qr/\d{6}/ 
 )->to( controller => 'pair' );
 
 $p->route( ':pri/:sec/', 
  pri => qr/[A-ZA-z0-9_-]+/, sec => qr/[A-ZA-z0-9_-]+/ )->to( 
   controller => 'pair', id => undef 
  );

 # #3: search browse & seach view

 my $s = $l->route( '/:action', action => qr/search|display/ )
  ->to( hold => 'static' );   

 $s->route( '/:id', id => qr/\d{6}/ )->to( controller => 'pattern' ); 

 $s->route( '/' )->to( controller => 'pattern', id => undef );

 # the quick find AJAX interface 
 $l->route( '/find' )->to ( "locate#find", hold => 'static' );

 # the show result AJAX interface
 # we set this to 'dynamic' since the data is provided by catshow.fi
 # and we should re-read it regularly for any changes
 $l->route( '/result' )->to ( "main#result",  hold => 'dynamic' );
      
 # add hooks to subs that are to be executed before and after the dispatch
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
 
 $s->{ver} = $ver; # application version
 
 $s->{version} = $version; # data version
 
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

 $s->{lang} = 'en'; $s->{langother} = 'fi'; # default to English

 $s->{url} = $self->req->url;  # let the url be in the stash also

 length ( $s->{url} ) > 2 and ( substr( $s->{url}, 0, 3 ) eq '/fi' ) and do {
   $s->{lang} = 'fi'; $s->{langother} = 'en'; # Finnish
 };
  
 # process and populate session with setup parameters                                                                                  
 setup_init ( $self );
  
 # attempt to fetch from cache
 if ( my $res = cache_get ( cachekey ( $self ) ) ) {  # cache hit
 
  $self->res->code(200);
  $self->res->headers->content_type( $res->[0] );
  defined $res->[1] and $self->res->headers->content_length( $res->[1] );
  $self->res->body( ${ $res->[2] } ); # scalar ref to prevent copying
  $self->rendered;
  $s->{cached} = 1; # mark that the content came from cache
  return $self;

 } else {
 
  $s->{cached} = 0;

 }
      
 # let some definitions to be globally available to all controllers
 $s->{matrix} = list_matrix;
 $s->{setup_keys} = setup_keys;
 $s->{setup_values} = setup_values;
   
 # default to meta robots "index,follow",
 # controllers may modify these as needed 
 $s->{meta_index} = 1;
 $s->{meta_follow} = 1;

 #
 # require urls to end with slash when there is no query params
 # you may ask why but I think this is cool
 #
 # the internals of Mojolicious was studied for this code
 # and the mechanism for redirect was copied from there
 #
 
 $s->{facebookkey} = conf ( 'key_facebook' );
 $s->{twitterkey} = conf ( 'key_twitter' );
 $s->{googlekey} = undef;

 # copy Google Analytics key to stash 
 # if on linux (prod server) and in production 

 if ( ( $ENV{MOJO_MODE} eq 'production' ) and conf ( 'lin' ) ) {
       
  $s->{googlekey} = conf ( 'key_google' ); 
 
 }
  
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
 
 #
 # remove unnecessary newlines
 # WARNING: SHOULD CONTENT-LENGTH TO BE SET AFTER THIS OPERATION ???
 # my $cont = $self->res->body;
 # $cont =~ s/\n+/\n/g;
 # $self->res->body ( $cont );
 #
 
 my $age = 0; # lifetime in response headers, default to no lifetime 
 my $cac = undef; # lifetime in server side page cache
   
 given ( $s->{hold} ) {
 
  # 5 min on headers (for clients), 4 min on server
  when ( 'dynamic' ) { $age = 5*60; $cac = 4*60; } 
  
  # 5 min on headers (for clients), infinite on server
  when ( 'static' ) { $age = 5*60; $cac = -1; } 
 
  # 'off' or any other => NOP

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
    \$self->res->body # scalar ref to prevent copying
   ],
   $cac
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