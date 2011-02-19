#
# The MIT License
# 
# Copyright (c) 1994-2011 Heikki Siltala
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
use Catz::Setup;

my $t_en;
my $t_fi;

sub startup {

 my $self = shift;
 
 $self->secret( setup_signature );
    
 my $r = $self->routes;
 
 $self->renderer->layout_prefix( 'layout' );
  
 $r->namespace( 'Catz::Action' );

 $r->route('/')->to( "main#detect" );
 
 $r->route( '/style/reset' )->to( 'main#reset' );
 $r->route( '/style/:palette' )->to( 'main#base' );
 
 my $l = $r->route ('/:lang', lang => qr/(en|fi)/ );
 
 $l->route( '/' )->to( 'main#root' );
 
 $l->route( '/setup' )->to ( "main#setup" );
 $l->route( '/setup/reset' )->to ( "main#setup", reset => 1 );
 $l->route( '/setup/:key/:value' )->to ( "main#setup" );

 $l->route('/list/:subject/:mode')->to('list#main');
 
 $l->route( '/search' )->to ( "search#main" ); 
 $l->route( '/search/(*args)' )->to ( "search#main" );

 # browse all photos
 $l->route('/:range', range => qr/\d{1,5}\-\d{1,5}/)->to("present#browse"); 

 # view a photo from all photos
 # expects base32 encoded photo id
 $l->route('/:photo', photo => qr/[0-9a-hjkmnp-tv-z]{1,8}/ )->to("present#view");
  
 # current setting 1,6 supports photo sets up to 999,999 photos  
 $l->route( '/(*path)/:range', range => qr/\d{1,6}\-\d{1,6}/ )->to (
  "present#browse"
 ); 


 $l->route( '/(*path)/:photo', photo => qr/[0-9a-hjkmnp-tv-z]{1,8}/ )->to (
  "present#view"
 );

 $self->hook ( before_dispatch => \&before );
  
 $self->hook( after_dispatch => \&after );

 #do { $t_en->{$_->[0]} = $_->[1] } foreach 
 # @{ $self->fetch_all( 'select tag,text_en from metatext' ) };

 #do { $t_en->{fi}->{$_->[0]} = $_->[1] } foreach 
 # @{ $self->fetch_all( 'select tag,text_fi from metatext' ) }; 
 
 
}

sub before {

 my $self = shift;
 
 my $stash = $self->{stash};
  
 $stash->{robots} = 'index,follow';

 $stash->{base_photo} = 'http://www.heikkisiltala.com/galleries';
 
 #die substr ( $self->req->url, 3 );
   
 if ( substr ( $self->req->url, 3 ) eq '/fi' ) {
 
  $stash->{lang} = 'fi';

  $stash->{otherlang} = '/en' . substr ( $self->req->url, 3 );
  
 } elsif( substr ( $self->req->url, 3 ) eq '/en' ) {
 
  $stash->{lang} = 'en';
 
  $stash->{otherlang} = '/fi' . substr ( $self->req->url, 3 );

 } else {
 
  $stash->{lang} = 'en';
  $stash->{otherlang} = '/fi' . substr ( $self->req->url, 3 ); 
 
 }
  
 $stash->{t} = $stash->{lang} eq 'fi' ? $T_FI : $T_EN;
                                                                                
 setup_defaultize ( $self );
   
}

sub after {

 my $self = shift;
 
}

1;