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

#
# handles redirection of old site's urls under /galleries
#

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Ctrl';

use I18N::AcceptLanguage;

use Catz::Core::Text;
use Catz::Util::Number qw ( fullnum33 );
use Catz::Util::String qw ( enurl deurl decode encode );

my $langs = [ 'en', 'fi' ];
 
my $i18n = 
 I18N::AcceptLanguage->new( defaultLangauge => 'en', strict => 0 );
 
my %classic = map { $_ => 1 } qw (
 2004_wwe_raw_helsinki agility_200910 arokatin_e around_finland
 cesmes_a cesmes_b cesmes_c culture_trip_lake_tuusula hel_sto_hel
 keimola_oldies myllypuro nytech_nd4020_era photoart1 suviyon_a the_farm 
);

sub xdf2search { # converts old search to new search

 my $xdf = shift;

 my @parts = split / +/, $xdf;
 
 scalar @parts > 30 and return undef;
 
 do { length ( $_ ) > 30 and return undef; } foreach @parts;

 my @out = ();
  
 foreach my $part ( @parts ) {
  
  my $tgt = ''; my $oper = '';
    
  if ( substr ( $part, 0, 1 ) eq '+' ) {
    
   $oper ='+'; $part = substr ( $part, 1 );
    
  } elsif ( substr ( $part, 0, 1 ) eq '-' ) { 
    
   $oper ='-'; $part = substr ( $part, 1 );
   
  } 
  
  if ( $part =~ /\[(.+)\]/ ) {
    
   $part = $1; $tgt = 'feat=';
     
   length ( $part ) > 2 and $tgt = 'breed=';
     
  } elsif ( $part =~ /\{(.+)\}/ ) {
    
   $part = "*$1*"; $tgt = 'breeder=';
  
  } elsif ( $part =~ /\((.+)\)/ ) {
    
   $part = "*$1*"; $tgt = 'nick=';
    
  } else {
    
   $part = "*$part*";
     
  }
  
  push @out, "$oper$tgt$part";
  
 }
   
 return join ' ', @out;
    
}

sub reroute { # does the job

 my $self = shift; my $p = $self->{stash}->{src} // '/';
  
 my $lang = $i18n->accepts( $self->req->headers->accept_language, $langs );
 
 # it was noted with some wget tests that the lagn can be unset
 # so we must check it and default to English if needed 
 ( $lang and length ( $lang ) > 1 ) or $lang = 'en'; 
 
 my $t = text ( $lang );

 given ( $p ) {

  when ( [ qw ( / index.htm index.html ) ] ) {
   return $self->redirect_perm ( "/$lang/" );
  } 
 
  when ( [ qw ( dates.htm dates.html ) ] ) {  
   return $self->redirect_perm ( "/$lang/list/date/cron/" );
  } 

  when ( [ qw ( locations.htm locations.html ) ] ) {  
   return $self->redirect_perm ( "/$lang/list/loc/a2z/" );
  } 

  when ( [ qw ( lastshow.htm lastshow.html ) ] ) {  
   return $self->redirect_perm ( '/lastshow/' );
  } 

  when ( [ qw ( breeders breeders/ breeders/index.htm breeders/index.html ems/breeders.htm ems/breeders.html ) ] ) {  
   return $self->redirect_perm ( "/$lang/list/breeder/a2z/" );
  } 

  when ( m|^breeders/([a-zA-Z0-9_-]{1,200})\.html$| ) {
  
   my $br = decode ( $1 );
  
   if ( $self->fetch("reroute#isbreeder",$br) ) {

    return $self->redirect_perm ("/$lang/browse/breeder/".encode($br).'/');   
   
   } else {
   
    return $self->not_found;
   
   }
   
  }
  
  when ( [ qw ( ems ems/ ems/index.htm ems/index.html ) ] ) {  
   return $self->redirect_perm ( "/$lang/list/breed/a2z/" );
  }   

  when ( m|^ems/([a-zA-Z]{3,3})\.htm(l)?$| ) {
  
   my $br = uc $1;
      
   ( $br eq 'PKU' ) and $br = 'HCL';
   ( $br eq 'PKN' ) and $br = 'HCL';
   ( $br eq 'PKX' ) and $br = 'HCL';
   
   ( $br eq 'LKU' ) and $br = 'HCS';
   ( $br eq 'LKN' ) and $br = 'HCS';
   ( $br eq 'LKX' ) and $br = 'HCS'; 
   
   if ( $self->fetch("reroute#isbreed",$br) ) {

    return $self->redirect_perm ("/$lang/browse/breed/$br/");   
   
   } else {
   
    return $self->not_found;
   
   }  
 
  }
   
  when ( m|^bestofbest| ) {
   return $self->redirect_perm ( "/$lang/" );
  }

  when ( m|^stat| ) {
   return $self->redirect_perm ( "/$lang/" );
  }
 
  when ( [ qw ( xdf xdf/ ) ] ) {
   return $self->redirect_perm ( "/$lang/search/" ); 
  }
 
  when ( m|^xdf/(.{1,777}?)(\~\d{4})?$| ) {
  
   my $tgt = xdf2search ( $1 );
  
   $tgt or return $self->not_found; # not found if conversion failed 
  
   $tgt = enurl $tgt;
     
   return $self->redirect_perm ( "/$lang/search?q=$tgt" );
   
  }
 
  default { # process leftover folders
 
   my ( $folder, $tail ) = split /\//, $p;
   
   $tail or $tail = '';
   
   # ghost url mappings _misc _panel _gala
   
   if ( $folder =~ m|^(\d{8}[a-z]+)_misc$| ) {
   
    $folder = $1.'1';
   
   } elsif ( $folder =~ m|^(\d{8}[a-z]+)_panel$| ) {
   
    $folder = $1.'2';
   
   } elsif ( $folder =~ m|^(\d{8}[a-z]+)_gala$| ) {
   
    $folder = $1.'2';
   
   }
   
   if ( $classic{$folder} ) { # this is an classic folder still in .com
  
    return $self->redirect_perm ( "$t->{URL_AUTHOR}photos/$folder/$tail" );
    
   } elsif ( my $s = $self->fetch("reroute#folder2s",$folder) ) { # current folder
   
    if ( $tail eq '' or $tail eq 'index.htm' or $tail eq 'index.html' ) {
   
     return $self->redirect_perm ( "/$lang/browse/folder/$folder/" );
   
    } elsif ( $tail eq 'check1.htm' or $tail eq 'check1.html' ) {
   
     my $search = enurl "+folder=$folder -has=text";
    
     return $self->redirect_perm ( "/$lang/search?q=$search" );
   
    } elsif ( $tail eq 'check2.htm' or $tail eq 'check2.html' ) {
   
     my $search = enurl "+folder=$folder +has=breed -has=cat";
    
     return $self->redirect_perm ( "/$lang/search?q=$search" );
   
    } elsif ( $tail =~ /^(\d{4})\-\d{4}\.htm(l)?$/ ) {
   
     my $id = fullnum33 ( $s, int ( $1 ) );
    
     return $self->redirect_perm ( "/$lang/browse/folder/$folder/$id/" );
   
    } elsif ( $tail =~ /^(\d{4})\.htm(l)?$/ ) {

     my $id = fullnum33 ( $s, int ( $1 ) );
    
     return $self->redirect_perm ( "/$lang/view/folder/$folder/$id/" );
   
    } elsif ( $tail =~ /^(.+\.(JPG|jpg))$/ ) {
    
     my $tgt = uc $1;
   
     return $self->redirect_perm ( "$t->{URL_CATZA}static/photo/$folder/$tgt" );
   
    } else { return $self->not_found }
    
   }  
  
   return $self->not_found; 
  
  }
 
 }
  
}

1;