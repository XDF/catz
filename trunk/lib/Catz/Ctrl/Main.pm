#
# Catz - the world's most advanced cat show photo engine
# Copyright (c) 2010-2011 Heikki Siltala
# Licensed under The MIT License
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

package Catz::Ctrl::Main;

use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use I18N::AcceptLanguage;
use XML::RSS;

use Catz::Model::List;
use Catz::Model::Meta;
use Catz::Data::Setup;
use Catz::Util::Time qw ( dt );

use Catz::Data::Conf;

use Data::Dumper;

my $languages = [ ( 'en', 'fi' ) ];
 
my $acceptor = I18N::AcceptLanguage->new( 
 defaultLangauge => 'en', strict => 0 
);

sub detect {
  
 my $self = shift;
 
 #warn "url is now at detect ".$self->req->url;
 
 my $lang = $acceptor->accepts(
  $self->req->headers->accept_language, $languages
 );
  
 $self->redirect_temp( "/$lang/" ); 
  
}

sub front {

 my $self = shift; my $stash = $self->{stash};
   
 foreach my $key ( qw ( news albums pris ) ) {
 
  $stash->{$key} = list_links ( $stash->{lang}, $key );
 
 }
    
 $self->render( template => 'page/front' );

}

sub news {

 my $self = shift; my $stash = $self->{stash};
 
 $stash->{news} = meta_news ( $stash->{lang} );
     
 $self->render( template => 'page/news' );

}

sub reset {

 my $self = shift;
  
 $self->render ( template => 'style/reset', format => 'css' );

}

sub base {

 my $self = shift; my $stash = $self->{stash};

 my $palette = $stash->{palette};

 my $color = setup_colors;

 defined $color->{$palette} or do { $self->render_not_found; return };
  
 $self->render ( 
  template => 'style/base', 
  color => $color,
  format => 'css' 
 );

}

sub set {

 my $self = shift; my $stash = $self->{stash};
 
 $stash->{key} eq 'dt' and do { # special case for 'dt'
 
  $stash->{val} eq '0' and do {
  
   delete $self->session->{dt}; 
   
   $self->render( text => 'OK' );
   
   return;                      
  
  };
 
  ( $stash->{val} =~ /^\d{14}$/ ) or do {
 
   $self->render( text => 'FAILED' );
    
   return;
  
  };
 
  if ( conf( 'path_master ') . '/' . $stash->{val} . 'db' ) {
   
   # the db file exists
   
    $self->session( dt => $stash->{val} );
   
    $self->render( text => 'OK' );
   
  } else {
  
   $self->render( text => 'FAILED' );
  
  }  
 
  return;
  
 };
   
 if ( setup_set ( $self, $stash->{key}, $stash->{val} ) ) { 

  $self->render( text => 'OK' );
  
 } else {
 
  $self->render( text => 'FAILED' );
 
 }
 
}

sub feed {

 my $self = shift; my $stash = $self->{stash};
 
 my $news = meta_news ( $stash->{lang} );
   
 my $rss = XML::RSS->new( version => '2.0' );

 $rss->channel(
  title => $stash->{t}->{SITE},
  link => 'http://' . $stash->{t}->{SITE} . '/',
  lastBuildDate => dt,
  managingEditor => $stash->{t}->{AUTHOR}
 );
  
 foreach my $item (@$news) {
  $rss->add_item(
   title =>  $item->[2],
   link => 'http://' . $stash->{t}->{SITE} . '/' . $stash->{lang} . '/news/#'.$item->[0],
   description => $item->[3],
   pubDate => $item->[1],
  );
 }
 
 $self->render ( text => $rss->as_string, format => 'xml' )
 


}