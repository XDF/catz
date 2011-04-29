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

package Catz;

use strict;
use warnings;

use parent 'Mojolicious';

#use Catz::Data::DB;
use Catz::Data::Text;
use Catz::Data::Setup;
use Catz::Data::Cache;
use Catz::Data::Conf;

#use Catz::Util::Time qw ( sysdate );
use Catz::Util::File qw ( fileread findlatest pathcut );

# last epoch time we checked for the database key file
my $lastcheck = 0;
my $lastdt = undef;

sub startup {

 my $self = shift;
 
 # initialize the key for cookie signing 
 $self->secret( fileread ( conf ( 'cookie_key' ) ) );
    
 my $r = $self->routes;
 
 $self->renderer->root ( conf ( 'path_tmpl' ) );
 $self->renderer->layout_prefix ( conf ( 'prefix_layout' ) );
 
 # All controllers are in Catz::Ctrl 
 $r->namespace( 'Catz::Ctrl' );

 # if the site root is requested then detect the correct language
 $r->route('/')->to( "main#detect" );
 
 # stylesheets
 $r->route( '/style/reset' )->to( 'main#reset' );
 $r->route( '/style/:palette' )->to( 'main#base' );
 
 # set user parameters
 $r->route( '/set' )->to( 'main#set' );
 
 # all site content is found under /:lang where lang is 'en' or 'fi'
 my $l = $r->route ('/:lang', lang => qr/en|fi/ );
 
 # the front page is the root under language
 $l->route( '/' )->to( 'main#front' );
  
 $l->route( '/news' )->to ( "main#news" );
 
 $l->route( '/feed' )->to ( "main#feed" );

 $l->route( '/find/:what' )->to ( "locate#find" );

 $l->route( '/sample/:what/:count', count => qr/\d{2}/ )->to (
  "locate#sample"
 );

 $l->route( '/sample/:count', count => qr/\d{2}/  )->to (
  "locate#sample", what => undef
 );

 $l->route( '/sample/:what' )->to (
  "locate#sample", count => conf ('samples')
 );
 
 $l->route( '/sample' )->to (
  "locate#sample", what => undef, count => conf ('samples')
 );

 $l->route( '/result/:key', key => qr/[A-Z2-7]{5,}/ )->to (
  "locate#result"
 );

 
 $l->route('/list/:subject/:mode')->to('list#list');
 
 $l->route( '/search' )->to ( "search#search" );   
 $l->route ( '/browse' )->to ( "present#browse" ); 
 $l->route ( '/view' )->to ( "present#view" ); 
 $l->route ( '/inspect' )->to ( "inspect#inspect" ); 
    
 # add hooks to subs that are executed before and after the dispatch
 $self->hook ( before_dispatch => \&before );  
 $self->hook ( after_dispatch => \&after );
 
}

sub before {

 my $self = shift; my $stash = $self->{stash};
  
 # default to "index,follow", actions may modify it as needed 
 $stash->{meta_index} = 1;
 $stash->{meta_follow} = 1;
 
 $stash->{photobase} = conf ( 'base_photo' );
 
 # the language detection
 # - detect correct langauge based on the beginning of URL
 # - store the language to stash
 # - prepare the URL for language change feature
 
 if ( length ( $self->req->url ) < 3 ) {
 
  # too short to detect language
  # default to english
 
  $stash->{lang} = 'en';
  $stash->{otherlang} = '/fi/'; 
 
 } elsif ( substr ( $self->req->url, 0, 3 ) eq '/fi' ) {
 
  $stash->{lang} = 'fi';

  $stash->{otherlang} = '/en' . substr ( $self->req->url, 3 );
  
 } elsif( substr ( $self->req->url, 0, 3 ) eq '/en' ) {
 
  $stash->{lang} = 'en';
 
  $stash->{otherlang} = '/fi' . substr ( $self->req->url, 3 );

 } else {
 
  # default to english
 
  $stash->{lang} = 'en';
  $stash->{otherlang} = '/fi' . substr ( $self->req->url, 3 ); 
 
 }
 
 # let the url be in the stash also
 # and there are no query params since they are dropped earlier
 $stash->{url} = $self->req->url;
 
 # fetch texts for the current language and make them available to all
 # controller and templates as variable t 
 $stash->{t} = text ( $stash->{lang} // 'en' );
                                                                                  
 setup_init ( $self );
 
 #
 # set 'the correct dt' to stash
 #
 
 $self->session->{dt} and do { 
 
  $stash->{dt} = $self->session->{dt};
  
  goto SKIP;
  
 }; 
 
 my $now = time();

 if ( $now - $lastcheck > 5 ) { # if the check has expired
 
  # find the latest key file

  my $file = findlatest ( conf ( 'path_master' ), 'txt' );
  
  defined $file or die "unable to find the latest key file";
  
  my $new = substr ( pathcut ( $file ), 0, 14 ); # get the datetime part
  
  $lastdt = $new; # store it to static variable
  
  $stash->{dt} = $new; # store it to stash

  $lastcheck = $now; # update the check time
  
 } else { # check has not expired
 
  $stash->{dt} = $lastdt; # so we just copy the latest dt to stash
 
 }
 
 SKIP:
 
 # attempt to fetch from cache
 
 if ( conf('cache_page' ) ) {
  
  if ( my $res = cache_get ( cachekey ( $self ) ) ) {
 
   $self->res->code(200);
   $self->res->headers->content_type( $res->[0] );
   $self->res->body( $res->[2] );
   $self->rendered;
   $stash->{cached} = 1;
   #warn ( "CACHE HIT $stash->{url}" );
   return $self;
  } else {
   #warn ( "CACHE MISS $stash->{url}" );
  }
 }
     
}

sub after {

 my $self = shift; my $stash = $self->{stash};
    
 ( defined $stash->{controller} and defined $stash->{action} and
 defined $stash->{url} ) or return; 
 
 # we will not cache setup change request 
 # since they must alter the session data
 $stash->{action} eq 'set' and return;

 setup_exit ( $self );
 
 # no recaching: if the result came from the cache don't cache it again
 defined $stash->{cached} and return;
 
 if ( conf('cache_page' ) ) {
 
  if ( $self->req->method eq 'GET' and $self->res->code == 200 ) {
   
   my @set = ( 
    $self->res->headers->content_type,
    $self->res->headers->content_length,
    $self->res->body 
   ); 
 
   #warn ( "CACHING $stash->{url}" );
   
   cache_set ( cachekey ( $self ), \@set );
  
  }
 }
 
}

sub cachekey {
 
 return ( 
  $_[0]->{stash}->{dt}, 
  $_[0]->{stash}->{url}, 
  map { $_[0]->{stash}->{$_} } @{ setup_keys() }
 ); 

}

1;