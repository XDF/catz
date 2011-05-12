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

package Catz::Model::Locate;

use 5.10.0;
use strict;
use warnings;

use parent 'Catz::Model::Base';

sub _full {

 my ( $self, $pri, $mode ) = @_; my $lang = $self->{lang};
 
 my $res;
 
 my $cols = "pri,sec,cntalbum,cntphoto,first,last";
 
 $mode eq 'a2z' and 
  return $self->dball( qq{select $cols from sec_$lang natural join secm natural join pri where pri=? order by sec}, $pri );

 $mode eq 'top' and 
  return $self->dball( qq{select $cols from sec_$lang natural join secm natural join pri where pri=? order by cntphoto desc }, $pri );
 
 die "unknown mode '$mode' in list creation"
 
}

sub _album {

 my $self = shift; my $lang = $self->{lang};

 my $res;

 my $albums = $self->dball('select aid,folder from album order by folder desc limit 8');
    
 my @coll = ();
    
 foreach my $row ( @{ $albums } ) {
    
  my $name = $self->dbone("select sec from inalbum natural join sec_$lang natural join pri where pri='name' and aid=?",$row->[0]);
     
  my $n = $self->dbone('select max(n) from photo where aid=?', $row->[0] );
     
  push @coll, ( [ $row->[1], $name, $n ] );
    
 }
   
 \@coll;

}

sub _pri { 

 my $self = shift;
 
 $self->dball("select pri,cnt from pri natural join prim where pri<>'text' order by disp");

}          


sub find {

 my ( $self, $pattern, $count ) = @_; my $lang = $self->{lang};

 $pattern = '%' . $pattern . '%';

 $self->dball (qq{select pri,sec,cnt from (select pri,sec,sort,cnt from pri natural join prim natural join sec_$lang where pri<>'text' and sec like ? order by cnt desc limit $count) order by sort,pri,cnt},$pattern);

}



1;