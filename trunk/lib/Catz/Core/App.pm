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

use 5.10.0; use strict; use warnings;

use parent 'Mojolicious';

use Catz::Core::Cache;
use Catz::Core::Conf;
use Catz::Core::Text;
use Catz::Data::List qw ( list_matrix );
use Catz::Data::Setup;
use Catz::Util::File qw ( fileread findlatest pathcut );
use Catz::Util::Time qw( dt dtdate dttime dtexpand dtlang thisyear );
use Catz::Util::Number qw ( fmt fullnum33 );
use Catz::Util::String qw ( enurl decode encode );

sub startup {

 my $self = shift;
 
 $self->plugin('default_helpers');
 
 $self->renderer->root ( conf ( 'path_template' ) );
 $self->renderer->layout_prefix ( conf ( 'prefix_layout' ) );
 
 $self->sessions->cookie_name( conf ( 'cookie_name' ) );
 $self->sessions->default_expiration( conf ( 'cookie_expir' ) );
  
 # initialize the key for cookie signing 
 $self->secret( conf ( 'cookie_key' ) );
 
 $self->helper ( dtdate => sub { shift; dtdate $_[0] } );
 $self->helper ( dttime => sub { shift; dttime $_[0] } );
 $self->helper ( dtexpand => sub { shift; dtexpand $_[0], $_[1] } ); 
 $self->helper ( fmt => sub { shift; fmt $_[0], $_[1] } );
 $self->helper ( enurl => sub { shift; enurl $_[0] } );
 $self->helper ( fullnum33 => sub { shift; fullnum33 $_[0], $_[1] } );
 $self->helper ( thisyear => sub { shift; thisyear } );
 $self->helper ( encode => sub { shift; encode $_[0] } );
 $self->helper ( decode => sub { shift; decode $_[0] } );
      
 my $r = $self->routes;
  
 # All controllers are in Catz::Ctrl 
 $r->namespace( 'Catz::Ctrl' );

 # if the site root is requested then detect the correct language
 $r->route('/')->to( "main#detect", hold => 0 );
 
 # stylesheets
 $r->route( '/style/reset' )->to( 'main#reset', hold => 60 );
 $r->route( '/style/:palette' )->to( 'main#base', hold => 60 );
 
 # set user parameters
 $r->route( '/set' )->to( 'main#set', hold => 0 );
 
 # classic lastshow interface
 $r->route( '/lastshow' )->to( 'main#lastshow', hold => 15 );

 # all site content is found under /:lang where lang is 'en' or 'fi'
 my $l = $r->route ('/:lang', lang => qr/en|fi/ );
 
 # the front page is the root under language
 $l->route( '/' )->to( 'main#front', hold => 15 );

 $l->route( '/result',  )->to ( "main#result", hold => 5 );
 $l->route( '/link',  )->to ( "main#link", hold => 60 ); # not yet implemented
 
 $l->route( '/news/feed' )->to ( "news#feed", hold => 15  );
 $l->route( '/news' )->to ( "news#all", hold => 15 );
 
 $l->route( '/find' )->to ( "locate#find", hold => 15 );
  
 $l->route(
  '/list/:subject/:mode', subject => qr/[a-z0-9]{1,15}/ 
 )->to('locate#list', hold => 15 );
     
 my $bv = $l->route ('/:action', action => qr/browse|view/ );
 
 $bv->route ( '/:id', id => qr/\d{6}/ )->to( controller => 'present' );

 $bv->route ( 
  ':pri/:sec', 
   pri => qr/[a-z0-9]{1,15}/, 
   sec => qr/[A-Za-z0-9\-\_]{1,1000}/ 
 )->to( controller => 'present' );
 
 $bv->route ( 
  '/:pri/:sec/:id', 
   pri => qr/[a-z0-9]{1,15}/, 
   sec => qr/[A-Za-z0-9\-\_]{1,1000}/, 
   id => qr/\d{6}/
 )->to( controller => 'present' );
 
 $bv->route ( '/' )->to( controller => 'present' );

 my $sd = $r->route ('/:action', action => qr/search|display/ );
  
 $sd->route ( '/:id', id => qr/\d{6}/ )->to( controller => 'present' );

 $sd->route ( '/' )->to( controller => 'present' ); 
     
 # add hooks to subs that are executed before and after the dispatch
 $self->hook ( before_dispatch => \&before );  
 $self->hook ( after_dispatch => \&after );
 
}

sub urio {

 my ( $self, $lang ) = @_;
 
 return 
  "/$lang" . 
  substr ( $self->req->url->path->to_string, 3 ) . 
  ( $self->req->query_params->to_string ? 
   '?' . $self->req->query_params->to_string : 
   '' 
  ); 

}

sub before {

 my $self = shift; my $s = $self->{stash};
 
 $s->{matrix} = list_matrix;
   
 # default to "index,follow", actions may modify it as needed 
 $s->{meta_index} = 1;
 $s->{meta_follow} = 1;

 # Google Analytics key to stash 

 if ( $^O =~ /^MS/ ) {
 
  $s->{googlekey} = undef; # windows = dev = no analytics 
 
 } else {
 
  $s->{googlekey} = conf ( 'google_key' );
  
 }
 
 $s->{setup_keys} = setup_keys;
 $s->{setup_values} = setup_values;
 
 # the layout separator character from conf to stash
 $s->{sep} = conf ( 'sep' );

 # the layout path separator character from conf to stash
 $s->{pathsep} = conf ( 'sep_path' );

 # the url where the images get fetched from
 $s->{photobase} = conf ( 'base_photo' );
 
 $s->{flagbase} = conf ( 'base_flag' );
  
 my $url = $self->req->url;
 
 #warn ".....";
 #warn $url;
 #warn $self->req->query_params->params;
 #warn $self->req->url->path->trailing_slash;
 
 #
 # require url to end with slash
 #
 
  $self->req->url->path->trailing_slash or # a trailing slash 
  scalar @{ $self->req->query_params->params } > 0 or # or query param(s) 
  ( $self->req->url->path->to_string  =~ /\..{2,4}$/ ) # or static file request
  or do {
      
  # this redirect code is a modified version from Mojolicious core
  # and appears to work as expected
       
  my $res = $self->res;
  $res->code(301); # a permanent redirect

  my $headers = $res->headers;
  
  # add slash to the end of the path
  $headers->location($self->req->url->path->to_string.'/'); 
  # if there was query parameters, they get dropped on redirect
  # since this code is not executed with query params, it is ok
  
  $headers->content_length(0); $self->rendered; return $self;
 
 };
  
 # the language detection
 # - detect correct langauge based on the beginning of URL
 # - store the language to stash
 # - prepare the URL for language change feature

 if ( length ( $url ) < 3 ) {
 
  # too short to detect language
  # default to english
 
  $s->{lang} = 'en';
  $s->{langother} = '/fi/'; 
 
 } elsif ( substr ( $url, 0, 3 ) eq '/fi' ) {
 
  $s->{lang} = 'fi'; $s->{langother} = urio ( $self, 'en' ); 
  
 } elsif( substr ( $url, 0, 3 ) eq '/en' ) {
 
  $s->{lang} = 'en'; $s->{langother} = urio ( $self, 'fi' );

 } else {
 
  # default to english
 
  $s->{lang} = 'en'; $s->{langother} = urio ( $self, 'fi' );
 }

 # let the url be in the stash also
 $s->{url} = $url;
 
 $s->{now} = dtlang ( $s->{lang} );
 
 # fetch texts for the current language and make them available to all
 # controller and templates as variable t 
 $s->{t} = text ( $s->{lang} // 'en' );
 

 # VITAL STEP: process and populate session                                                                                  
 setup_init ( $self );
    
 my $now = time();
 
 if ( $self->session ( 'peek' ) ne '0' ) { # version is set in peek

  # force use of the user's set version
  $s->{version} = $self->session ( 'peek' );
  
  # reset session version & checked
  $self->session ( version => 0 );
  $self->session ( checked => 0 );
 
 } else {

  
  if ( 
   ( $now - $self->session('checked') ) > conf ( 'version_check_delay' )
  ) { # check no often than every 'version_check_delay' seconds 
   
   # find the latest key file
   my $file = findlatest ( conf ( 'path_db' ), 'txt' );
   
   # if key file not found then find the latest database file
   $file or $file = findlatest ( conf ( 'path_db' ), 'db' );
   
   # key file or db file must be found else it is a fatal error
   $file or die "tried twice but database not found";
         
   my $new = substr ( pathcut ( $file ), 0, 14 ); # get the datetime part
    
   $self->session ( version => $new ); $s->{version} = $new;

   $self->session ( checked => $now );
        
  } else { # the check has not yet expired
    
   $s->{version} =  $self->session('version');
 
  }
 
 }
  
 # attempt to fetch from cache
 
 if ( conf('cache_page' ) ) {
  
  if ( my $res = cache_get ( cachekey ( $self ) ) ) {
 
   $self->res->code(200);
   $self->res->headers->content_type( $res->[0] );
   $self->res->body( $res->[2] );
   $self->rendered;
   $s->{cached} = 1;
   #warn ( "CACHE HIT $s->{url}" );
   return $self;
  } else {
   #warn ( "CACHE MISS $s->{url}" );
  }
 }
     
}

sub after {

 my $self = shift; my $s = $self->{stash};
    
 ( defined $s->{controller} and defined $s->{action} and
 defined $s->{url} ) or return; 
 
 # we will not cache setup change request 
 # since they must alter the session data
 # we also don't send out the default cookies
 $s->{action} eq 'set' and return;
 
 my $val = 0;
 
 exists $s->{hold} and $s->{hold} > 0 and $val = $s->{hold}*60;
    
 $self->res->headers->header('Cache-Control' => "max-age=$val");
 
 # no recaching: if the result came from the cache don't cache it again
 defined $s->{cached} and return;
 
 if ( conf('cache_page' ) ) {
 
  if ( $self->req->method eq 'GET' and $self->res->code == 200 ) {
   
   my $set = [ 
    $self->res->headers->content_type,
    $self->res->headers->content_length,
    $self->res->body 
   ]; 
 
   #warn ( "CACHING $s->{url}" );
   
   cache_set ( cachekey ( $self ), $set );
  
  }
 }
    
}

sub cachekey {
 
 return ( 
  $_[0]->{stash}->{version}, 
  $_[0]->{stash}->{url}, 
  map { $_[0]->{stash}->{$_} } @{ setup_keys() }
 ); 

}

1;