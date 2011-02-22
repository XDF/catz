#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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

use Catz::DB;
use Catz::Model::Meta;
use Catz::Setup;

sub startup {

 my $self = shift;
  
 $self->secret( setup_signature );
    
 my $r = $self->routes;
 
 $self->renderer->layout_prefix( 'layout' );
 
 # All controllers are Actions 
 $r->namespace( 'Catz::Action' );

 # if the site root is requested then detect the correct language
 $r->route('/')->to( "main#detect" );
 
 $r->route( '/style/reset' )->to( 'main#reset' );
 $r->route( '/style/:palette' )->to( 'main#base' );
 
 # all site content are located under /en or /fi
 my $l = $r->route ('/:lang', lang => qr/(en|fi)/ );
 
 $l->route( '/' )->to( 'main#root' );
 
 $l->route( '/feed' )->to ( "main#feed" );
 
 $l->route( '/news' )->to ( "main#news" );
 
 $l->route('/list/:subject/:mode')->to('list#main');
 
 $l->route( '/search' )->to ( "search#main" ); 
 $l->route( '/search/(*args)' )->to ( "search#main" );

 # browse all photos
 # current setting 1,6 supports photo sets up to 999,999 photos
 $l->route('/:range', range => qr/\d{1,6}\-\d{1,6}/)->to("present#browse"); 

 # view a photo from all photos
 # expects base32 encoded photo id
 $l->route('/:photo', photo => qr/[0-9a-hjkmnp-tv-z]{1,8}/ )->to("present#view");
 
 # view a photo based on the search pattern 
 # current setting 1,6 supports photo sets up to 999,999 photos  
 $l->route( '/(*path)/:range', range => qr/\d{1,6}\-\d{1,6}/ )->to (
  "present#browse"
 ); 

 # view a photo based on the search pattern
 # expects base32 encoded photo id
 $l->route( '/(*path)/:photo', photo => qr/[0-9a-hjkmnp-tv-z]{1,8}/ )->to (
  "present#view"
 );

 # add hooks to subs that are executed before and after the dispatch
 $self->hook ( before_dispatch => \&before );  
 $self->hook( after_dispatch => \&after );
 
}

sub before {

 my $self = shift;

 my $stash = $self->{stash};
 
 # force all URLs to end with slash 
 $self->req->url->path->trailing_slash or do {
   
  # this redirect code is a modified version from Mojolicious core
  # and appears to work as expected
       
  my $res = $self->res;
  $res->code(301); # a permanent redirect

  my $headers = $res->headers;
  
  # add slash to the end of the path
  $headers->location($self->req->url->path->to_string.'/'); 
  # if there was query parameters, they get dropped on redirect
  
  $headers->content_length(0);

  $self->rendered;

  return $self;
 
 };
 
 # default to "index,follow", actions may modify it as needed 
 $stash->{meta_index} = 1;
 $stash->{meta_follow} = 1;

 #warn "url is now ".$self->req->url;
 
 # process query params, they are setup change attempts
 foreach my $key ( $self->req->url->query->param ) {
 
   # prevent indexing if parameters present
   $stash->{meta_index} = 0;

   my $value = $self->req->url->query->param ( $key ); 

   if ( setup_verify ( $key, $value ) ) {
    # verified parameters go to session
    $self->session($key => $value);
   }
   
   # all parameters are removed from the request
   $self->req->url->query->remove( $key );
 
 }
 
# warn $self->req->url; 


 # temporary hard-coded setting for initial development
 # for testing all photos are fetched from the current prod website
 $stash->{photobase} = 'http://www.heikkisiltala.com/galleries';
 
 # the language detection
 # - detect correct langauge based on the beginning of URL
 # - store the language to stash
 # - prepare the URL for language change feature
 
 if ( length ( $self->req->url ) < 3 ) {
 
  # too short to detect language
  # default to english
 
  $stash->{lang} = 'en';
  $stash->{otherlang} = '/fi/'; 
 
  } elsif ( substr ( $self->req->url, 3 ) eq '/fi' ) {
 
  $stash->{lang} = 'fi';

  $stash->{otherlang} = '/en' . substr ( $self->req->url, 3 );
  
 } elsif( substr ( $self->req->url, 3 ) eq '/en' ) {
 
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
 # templates as $t 
 $stash->{t} = meta_text( $stash->{lang} );
                                                                                
 setup_defaultize ( $self );
   
}

sub after {

 my $self = shift;
 
 # currently NOP, perhaps something here in the future
 
}

1;