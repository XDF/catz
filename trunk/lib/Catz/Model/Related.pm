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

sub _coverage { # how many photos have the given pri defined

 my ( $self, $pri, $sec, $target ) = @_;  my $lang = $self->{lang};
 
 $self->dbone(qq{select count(distinct x) from _sid_x natural join sec_$lang where pid=(select pid from pri where pri=?) and x in (select x from _sid_x natural join sec_$lang where pid=(select pid from pri where pri=?) and sec=?)},$target,$pri,$sec); # 2011-06-03 15 ms  

}

sub _common { # the most common subjects for the given pri

 my ( $self, $pri, $sec, $target, $n ) = @_;  my $lang = $self->{lang}; 

 $self->dball(qq{select sec,cntphoto from sec_$lang natural join _secm where sid in (select s1.sid from sec_$lang s1,inpos i1,inpos i2,sec_en s2 where i1.aid=i2.aid and i1.n=i2.n and i1.p=i2.p and s1.sid=i1.sid and s2.sid=i2.sid and s1.pid=(select pid from pri where pri=?) and s2.sec=? and s2.pid=(select pid from pri where pri=?)) order by cntphoto desc limit $n},$target,$sec,$pri); # 2011-06-03 120 ms  

}

sub _basic { # first, last



}

sub _dates {

 my ( $self, $pri, $sec ) = @_;  my $lang = $self->{lang}; 

 $self->dball(qq{select substr(folder,1,8),min(s),min(n) from album natural join photo natural join _sid_x where sid=(select sid from sec_$lang where pid=(select pid from pri where pri=?) and sec=?) group by substr(folder,1,8) order by substr(folder,1,8) desc}); # 2011-06-03 47 ms 

}


1;