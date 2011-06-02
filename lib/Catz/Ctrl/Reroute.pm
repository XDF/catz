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

package Catz::Ctrl::Reroute;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use Catz::Core::Conf qw ( conf );
use Catz::Util::Number qw ( fullnum33 );

sub z { 

 $_[0]->redirect_perm ( substr ( conf ( 'url_site' ), -1 ) . $_[1] );
 
 # at the moment we "echo" the new url as die
 die substr ( conf ( 'url_site' ), 0, -1 ) . $_[1]; 
 
 return 1; 
 
}
       
sub get {

 my $self = shift;
 
 warn 'here';
 
 # we receive the original path after /galleries as parameter 'old'
 
 my $old = $self->param('old') // undef;
 
 defined $old or $self->not_found and return;
 
 given ( $old ) {
 
  when ( '/' ) { 
   $self->z ( '/' ) and return; 
  } 

  when ( [ '/ems', '/ems/', '/ems/index.html' ] ) {
   $self->z ( '/list/bcode/a2z/' ) and return; 
  }
  
  when ( '/ems/breeders.html' ) {
   $self->z ( '/list/breeders/a2z/' ) and return;
  }
  
  when ( m|^/ems/([a-z]{3,3})\.html$| ) {
   $self->z ( '/browse/bcode/' .uc ( $1 ) . '/' ) and return;
  }
  
  when ( [ '/breeders', '/breeders/', '/breeders/index.html' ] ) {
   $self->z ( '/list/breeder/a2z/' ) and return; 
  }

  when ( m|^/breeders/([a-zA-Z0-9_-]{1,50})\.html$| ) {
   $self->z ( "/browse/breeder/$1/" ) and return;
  }

  when ( '/dates.html' ) {
   $self->z ( '/list/date/date/' ) and return; 
  }

  when ( '/locations.html' ) {
   $self->z ( '/list/loc/a2z/' ) and return; 
  }
  
  when ( '/lastshow.html' ) { $self->z ( '/lastshow/' ) and return }

  
  when ( m|^/stats| ) { $self->z ( '/' ) and return }

  when ( m|^/bestofbest| ) { $self->z ( '/' ) and return }
  
  when ( m|^/([a-z0-9]{9,50})(/index\.html|/)$| ) { # gallery root
  
   my $folder = $1;
  
   my $n = $self->fetch('locate#verify', $folder );
   
   $n or $self->not_found and return;
  
   $self->z ( "/browse/folder/$folder/" ) and return;
    
  }

  when ( m|^/stats| ) {
  #when ( m|^/([a-z0-9]{9,50})/(\d\d\d\d)-\d\d\d\d\.html$| ) { # gallery page
  
   my $folder = $1; my $s = int ( $2 );

   my $n = $self->fetch('locate#verify', $folder );

   $n or $self->not_found and return;

   $self->z ( "/browse/folder/$folder/" . fullnum33 ( $n, $s ) . '/' ) and return;
  
  }

  when ( m|^/stats| ) {
  #when ( m|^/([a-z0-9]{9,50})/(\d\d\d\d)\.html$| ) { # gallery one
  
   my $folder = $1; my $s = int ( $2 );
  
   my $n = $self->fetch('locate#verify', $folder );
   
   $n or $self->not_found and return;

   $self->z ( "/view/folder/$folder/" . fullnum33 ( $n, $s ) . '/' ) and return;
  
  }

 }
 
 $self->not_found and return;
 
}

1;