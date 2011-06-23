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

package Catz::Model::Related;

use 5.10.0; use strict; use warnings;

use parent 'Catz::Model::Common';

use Catz::Data::Search;
use Catz::Data::List;

my $matrix = list_matrix;

sub _all2date {

 my $self = shift;

 $self->dball('select min(s),min(n),substr(folder,1,8) from album natural join photo group by substr(folder,1,8) order by substr(folder,1,8) desc');

}

sub _pair2date {

 my ( $self, $pri, $sec, $lower, $upper ) = @_;
 
 # _secm instead?

 $self->dball('select min(s),min(n),substr(folder,1,8) from album natural join photo natural join _sid_x where sid=(select sid from sec_en where  pid=(select pid from pri where pri=?) and sec=?) and (substr(folder,1,8)>(select substr(folder,1,8) from photo natural join album where x=?) or substr(folder,1,8)<(select substr(folder,1,8) from photo natural join album where x=?)) group by substr(folder,1,8) order by substr(folder,1,8) desc',$pri,$sec,$lower,$upper);

} 
 

sub _coverage { # how many photos have the given pri defined

 my ( $self, $pri, $sec, $target ) = @_;  my $lang = $self->{lang};
 
 $self->dbone(qq{select count(distinct x) from _sid_x natural join sec_$lang where pid=(select pid from pri where pri=?) and x in (select x from _sid_x natural join sec_$lang where pid=(select pid from pri where pri=?) and sec=?)},$target,$pri,$sec); # 2011-06-03 15 ms  

}

sub _refine {

 my ( $self, $pri, $sec, $target ) = @_;  my $lang = $self->{lang};
 
 # maximum number of items in a set, use 15 if not specific
 my $n = $matrix->{$pri}->{limit}->{$target} // 15; 

 my $sql = qq{select sec from (select s2.sec,p2.disp,s2.sort from pri p1,sec_$lang s1,_secm m, _relate r,sec_$lang s2, pri p2 where p1.pri=? and p1.pid=s1.pid and s1.sec=? and s2.sid=m.sid and s1.sid=r.source and s2.sid=r.target and s2.pid=p2.pid and p2.pri=? order by cntphoto desc limit $n) order by sort}; 

 return $self->dbcol( $sql, $pri, $sec, $target );

}

sub _refines {

 my ( $self, $pri, $sec, @targets ) = @_;

 my @res = ();
 
 foreach my $target ( @targets ) {
  
  my $data = $self->refine($pri,$sec,$target);

  push @res, [ $target, $data ]; 

 }

 return \@res;

}

sub _date {

 my ( $self, $x ) = @_;
 
 $self->dbone('select substr(folder,1,8) from album natural join photo where x=?',$x);   
 
}

sub _breedernat { 

 my ( $self, $breeder ) = @_;
 
 $self->dbone('select nat from mbreeder where breeder=?', $breeder );
 
}

sub _breederurl { 

 my ( $self, $breeder ) = @_;
 
 $self->dbone('select url from mbreeder where breeder=?', $breeder );
 
}

1;