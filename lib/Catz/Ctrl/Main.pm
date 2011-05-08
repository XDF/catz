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

package Catz::Ctrl::Main;

use 5.12.2;
use strict;
use warnings;

use parent 'Catz::Ctrl::Base';

use I18N::AcceptLanguage;
use XML::RSS;

use Catz::Data::Conf;
use Catz::Data::Setup;
use Catz::Data::Result;
use Catz::Util::Time qw ( dt );

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

sub front {

 my $self = shift; my $s = $self->{stash};
   
 foreach my $key ( qw ( new album pri ) ) {
 
  $s->{$key} = $self->fetch ( 'list_links', $key );
 
 }

 $s->{maxx} = $self->fetch ( 'maxx' );
    
 $self->render( template => 'page/front' );

}

sub reset { $_[0]->render ( template => 'style/reset', format => 'css' ) }

sub base {

 my $self = shift; my $s = $self->{stash};

 setup_verify ( 'palette', $s->{palette} ) or ( $self->not_found and return );
  
 $self->render ( template => 'style/base', format => 'css' );

}

sub set {

 my $self = shift; my $stash = $self->{stash};

 my @params = $self->param;

 my $i = 0;

 foreach my $key ( @params ) {

 setup_set ( $self, $key, $self->param( $key ) ) and $i++;
 
 }
 
 if ( $i ) { $self->render( text => 'OK' ) }  else 
  {  $self->render( text => 'FAILED' ) }
 
}

use constant FAILED => '?';

sub result {

 my $self = shift; my $s = $self->{stash};

 my $key = $self->param( 'key' ) // undef;

 ( defined $key and length $key < 2000 ) or
  $self->render( text => FAILED ) and return;

 my @keys = result_unpack ( $key );
  
 scalar @keys == 3 or $self->render( text => FAILED ) and return;

 my $res = $self->fetch ( 'result_query', @keys );

 defined $res and do {
 
  $s->{result} = $res->[0];
  $s->{attrib} = $res->[1];
 
  $self->render( template => 'prim/result' ) and return;
 
 };
 
 $self->render( text => FAILED );

}

1;