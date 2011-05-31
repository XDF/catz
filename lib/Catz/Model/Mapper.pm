
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

package Catz::Model::Mapper;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Model';

use List::MoreUtils qw ( any );

use Catz::Util::Time qw ( dtexpand );

sub _link { # provides mapping for links

 my ( $self, $spri, $ssec ) = @_; my $lang = $self->{lang};
  
 if ( $spri eq 'album' ) {

  return $self->dbrow("select 'folder',folder from album natural join inalbum natural join sec_$lang natural join pri where pri='album' and sec=?",$ssec);

 }

 return [ $spri, $ssec ]; # returns as was

}

sub _disp { # provides mapping for displaying

  my ( $self, $spri, $ssec ) = @_; my $lang = $self->{lang};
  
  if ( $spri eq 'folder' ) {
  
   return $self->dbrow("select pri,sec from album natural join inalbum natural join sec_$lang natural join pri where pri='album' and folder=?",$ssec);
      
  } elsif ( $spri eq 'date' ) { return [ 'date', dtexpand ( $ssec, $lang ) ] }

  return [ $spri, $ssec ]; # returns as was

}

my @istrans =  qw ( breed loc org umb );

sub _trans { # provides mapping for translations

 my ( $self, $spri, $ssec ) = @_; my $lang = $self->{lang};
 
 if ( any { $spri eq $_ } @istrans ) {
 
  my $ol = $lang eq 'fi' ? 'en' : 'fi';
  
  my $sid = $self->dbone("select sid from sec_$lang natural join pri where pri=? and sec=?",$spri,$ssec);
  
  return $self->dbrow("select '$spri',sec from sec_$ol where sid=?",$sid);   
  
 } else { return [ $spri,$ssec ] } # not to translate, return as is

}

1;
