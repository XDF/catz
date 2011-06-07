
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

sub _map { 

 # provides mappings for 
 #  album -> folder
 #  folder -> album
 #  breed -> bcode
 #  bcode -> breed

 my $self = shift; my $lang = $self->{lang};
 
 my $base = $self->dball("select folder,sec from album natural join inalbum natural join sec_$lang natural join pri where pri='album' union all select bcode,breed_$lang from mbreed");

 my %res = ();
  
 # make both folder -> album and album -> folder mapping to same has
 do { $res{$_->[0]} = $_->[1]; $res{$_->[1]} = $_->[0] } foreach ( @$base );
  
 return \%res;
 
}

my %istrans = map { $_ => 1 } qw ( breed loc org umb );

sub _trans { # provides mapping for translations

 my ( $self, $spri, $ssec ) = @_; my $lang = $self->{lang};
 
 if ( $istrans{$spri} ) {
 
  my $ol = $lang eq 'fi' ? 'en' : 'fi';
  
  my $sid = $self->dbone("select sid from sec_$lang natural join pri where pri=? and sec=?",$spri,$ssec);
  
  return $self->dbone("select sec from sec_$ol where sid=?",$sid);   
  
 } else { return $ssec } # not to translate, return as is

}

1;
