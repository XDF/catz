
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

package Catz::Model::Map;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Core::Model';

my $ROOT = 'ROOT';

sub _link { 
 
 # mappings for links as hashref
 # if the hashref contains a mapping then all
 # links should use the pri,sec -pair (arrayref)
 # found in the hashref

 my $self = shift; my $lang = $self->{lang};
 
 my $base = $self->dball ( qq{select 'album',sec,'folder',folder from album natural join inalbum natural join sec_$lang natural join pri where pri='album'});
 
 my %res = ();
 
 foreach my $row ( @$base ) {
  $res{$row->[0]}->{$ROOT} = $row->[2];
  $res{$row->[0]}->{$row->[1]} = [ $row->[2], $row->[3] ];
 }

 return \%res;
}

sub _view { 

 # mappings for presentations
 # if the hashref contains a mapping then all
 # values should be presented using the pri,sec -pair (arrayref)
 # found in the hashref

 my $self = shift;  my $lang = $self->{lang};
 
 my $base = $self->dball ( qq{select 'folder',folder,'album',sec from album natural join inalbum natural join sec_$lang natural join pri where pri='album'});
 
 my %res = ();
 
 foreach my $row ( @$base ) {
  $res{$row->[0]}->{$ROOT} = $row->[2];
  $res{$row->[0]}->{$row->[1]} = [ $row->[2], $row->[3] ];
 }

 return \%res;  

}

my @duals = qw ( breed feature title nation );

sub _dual {  

 # mappings for pair coupling
 # if the hashref contains a mapping then
 # value can presented with the pri,sec -pair (arrayref)
 # found in the hashref
 
 my $self = shift; my $lang = $self->{lang};
 
 my $sql = '';
 
 foreach my $tag ( @duals ) {
 
  length ( $sql ) > 0 and $sql .= ' union all ';
 
  $sql .= "select '$tag',".$tag."_$lang,'".$tag."code',".$tag."code from m$tag"; 
 
 }
 
 my $base = $self->dball ( $sql );
 
 my %res = ();
  
 foreach my $row ( @$base ) {
  $res{$row->[0]}->{$ROOT} = $row->[2];
  $res{$row->[0]}->{$row->[1]} = [ $row->[2], $row->[3] ];
  $res{$row->[2]}->{$ROOT} = $row->[0];
  $res{$row->[2]}->{$row->[3]} = [ $row->[0], $row->[1] ]; 
 } 
  
 return \%res;
 
}

sub _trans { 

 # provides translations for any pri,sec -combination
 # returns the translated sec (that can be the same)

 my ( $self, $spri, $ssec ) = @_; my $lang = $self->{lang};
 
 my $gnal = $lang eq 'fi' ? 'en' : 'fi';
 
 my $sid = $self->dbone("select sid from sec_$lang natural join pri where pri=? and sec=?",$spri,$ssec);

 return $self->dbone("select sec from sec_$gnal natural join pri where sid=?",$sid); 
 
}

1;
