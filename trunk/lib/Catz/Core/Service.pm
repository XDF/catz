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

package Catz::Core::Service;

use 5.12.2;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw ( run );

use Plack::Request;

use Catz::Brick::Style;
use Catz::Core::System;

my $brick = {
 'style' => Catz::Brick::Style->new()
};

my $model = {
 'vector' => Catz::Vault::Vector->new()


};

my $language = [ ( 'en', 'fi' ) ];
 
my $acceptor = I18N::AcceptLanguage->new( 
 defaultLangauge => 'en', strict => 0 
);


 
  
}


sub run {

 my $env = shift;

 #my $req = Plack::Request->new( $env );

 my $sys = Catz::Core::Sys->new();

 # we must use raw unprocessed URI to get for example encoded slashes right
 my $uri = $env->{REQUEST_URI};

 length ( $uri ) > 4000 and return $sys->not_found ( 'URI too long' );
 
 my ( undef, $lang, $action, @args ) = split /\//, $uri;

 ( ( not defined $uri ) or $uri eq '' or $uri eq '/' )  and do {
           
  # bare root requested -> detect the language and redirect  
  
  my $lang = $acceptor->accepts( $env->{HTTP_ACCEPT_LANGUAGE}, $languages );
  
  return $sys->redirect_temp( "/$lang/" ); 

 };

 ( defined $lang and defined $action ) or
   return $sys->not_found ( 'URI too simple' );
 
 scalar ( @args ) > 200 and return $sys->not_found ( 'URI has too many arguments' ); 



 ( $lang eq 'fi' or $lang eq 'en' ) or do {

   $lang = 'en';
   $action = $lang;

 };
    
 defined $brick->{$action}

 return [ 
  200, 
  [ 'Content-Type' => 'text/html' ],
  [ $out ]
 ];

}

1;                                       