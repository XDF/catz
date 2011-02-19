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

package Catz::Action::Main;

use strict;
use warnings;

use parent 'Catz::Action::Base';

use Catz::Model::List;
use Catz::Model::Meta;
use Catz::Setup;

use I18N::AcceptLanguage;

my $languages = [ ( 'en', 'fi' ) ];
 
my $acceptor = I18N::AcceptLanguage->new( 
 defaultLangauge => 'en', strict => 0 
);

sub detect {
  
 my $self = shift;
  
 my $lang = $acceptor->accepts(
  $self->req->headers->accept_language, $languages
 );
  
 $self->redirect_temp( "/$lang/" ); 
  
}

sub root {

 my $self = shift;
 
 my $stash = $self->{stash};
 
 foreach my $key ( qw ( news albums pris ideas ) ) {
 
  $stash->{$key} = list_links ( $stash->{lang}, $key );
 
 }
    
 $self->render( template => 'page/root' );

}

sub reset {

 my $self = shift;
  
 $self->render ( template => 'style/reset', format => 'css' );

}

sub base {

 my $self = shift;

 my $palette = $self->stash->{palette};

 my $colors = setup_colors;

 defined $colors->{$palette} or $self->render(status => 404);
  
 $self->render ( 
  template => 'style/base', 
  color => $colors->{$palette},
  format => 'css' 
 );

}

sub setup {

 my $self = shift;
  
 my $stash = $self->{stash};
 
 $stash->{robots} = 'index,nofollow';
  
 defined $stash->{reset} and do {
  $stash->{robots} = 'noindex,nofollow';
  setup_reset ( $self ); 
 }; 
 
 defined $stash->{key} and 
 defined $stash->{value} and do {
  setup_verify ( $stash->{key}, $stash->{value} ) or $self->render ( status => 404 );
  $self->session( $stash->{key} => $stash->{value} );
  $stash->{$stash->{key}} = $stash->{value};
  $stash->{robots} = 'noindex,nofollow';
 }; 
 
 $stash->{values} = setup_values;

 $self->render ( template => 'page/setup' );

}