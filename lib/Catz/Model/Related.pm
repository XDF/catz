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

use Catz::Util::Number qw ( round );

my $matrix = list_matrix;

sub _all2date {

 my ( $self, $lower, $upper ) = @_;
 
 # we fetch all dates from db (utilizing db caching more)
 
 my $res = $self->dball('select min(s),min(n),substr(folder,1,8) from album natural join photo group by substr(folder,1,8) order by substr(folder,1,8) desc');

 # filter out the not needed

 my @out = ();

 foreach my $row ( @$res ) {

  ( $row->[2] < $lower or $row->[2] > $upper ) and push @out, $row;

 }

 return \@out;

}

sub _pair2date {

 my ( $self, $pri, $sec, $lower, $upper ) = @_; my $lang = $self->{lang};
 
 # we fetch all dates from db (utilizing db caching more)

 my $res = $self->dball("select min(s),min(n),substr(folder,1,8) from album natural join photo natural join _sid_x where sid=(select sid from sec_$lang where pid=(select pid from pri where pri=?) and sec=?) group by substr(folder,1,8) order by substr(folder,1,8) desc",$pri,$sec);

 # filter out the not needed

 my @out = ();

 foreach my $row ( @$res ) {

  ( $row->[2] < $lower or $row->[2] > $upper ) and push @out, $row;

 }

 return \@out;

} 
 
sub _coverage { # how many photos have the given pri defined

 my ( $self, $pri, $sec, $target ) = @_;  my $lang = $self->{lang};
 
 $self->dbone(qq{select count(distinct x) from _sid_x natural join sec_$lang where pid=(select pid from pri where pri=?) and x in (select x from _sid_x natural join sec_$lang where pid=(select pid from pri where pri=?) and sec=?)},$target,$pri,$sec); # 2011-06-03 15 ms  

}

sub _refine {

 my ( $self, $pri, $sec, $target ) = @_; my $lang = $self->{lang};
 
 # maximum number of items in a set, use 15 if not specific
 my $n = $matrix->{$pri}->{limit}->{$target} // 15;
 
 my $me = $self->dbone ("select sid from sec_$lang where pid=(select pid from pri where pri=?) and sec=?",$pri,$sec);
 
 my $tg = $self->dbone ("select pid from pri where pri=?",$target);
 
 my $sql = qq{select sec from (select sec,sort from sec_$lang natural join _secm where sid in (select target from _relate inner join sec on (target=sid) natural join pri where source=? and pid=?) order by cntphoto desc limit 15) order by sort};
 
 return $self->dbcol( $sql, $me, $tg );

}

sub _refines {

 my ( $self, $pri, $sec, @targets ) = @_;

 my @res = ();
 
 foreach my $target ( @targets ) {
  
  my $data = $self->refine ($pri, $sec, $target );

  push @res, [ $target, $data ]; 

 }

 return \@res;

}

sub _date {

 my ( $self, $x ) = @_; 
 
 $self->dbone('select substr(folder,1,8) from album natural join photo where x=?',$x);   
 
}

sub _breedermeta { 

 my ( $self, $breeder ) = @_;
 
 $self->dbrow('select nat,url from mbreeder where breeder=?', $breeder );
 
}

sub _seccnt {

 my ( $self, $pri ) = @_;
 
 $self->dbone('select count(*) from sec natural join pri where pri=?', $pri );

}

sub _maxcntphoto {

 my ( $self, $pri ) = @_;

 my $max = $self->dbone ('select max(cntphoto) from _secm natural join sec natural join pri where pri=?',$pri);
 
 $max < 2 ? 2 : $max;

}

sub _maxcntdate {

 my ( $self, $pri ) = @_;

 my $max = $self->dbone ('select max(cntdate) from _secm natural join sec natural join pri where pri=?',$pri);
 
 $max < 2 ? 2 : $max;
 
}

sub _rank {

 my ( $self, $pri, $sec ) = @_;  my $lang = $self->{lang};
 
 my ( $cntp, $cntd ) = 
  @{ $self->dbrow ("select cntphoto,cntdate from _secm natural join sec_$lang where pid=(select pid from pri where pri=?) and sec=?",$pri,$sec) };
  
 $cntp < 1 and $cntp = 1;
 $cntd < 1 and $cntd = 1; 
   
 my $outp =  round ( ( log ( $cntp ) / log ( $self->maxcntphoto ( $pri ) ) ) * 100 );
 my $outd =  round ( ( log ( $cntd ) / log ( $self->maxcntdate ( $pri ) ) ) * 100 );
   
 return [ $outp, $outd ]; 

}

sub _ranks {

 my ( $self, $pri ) = @_;
  
 my $maxp = $self->maxcntphoto ( $pri );
 my $maxd = $self->maxcntdate ( $pri );
 
 my $arr = $self->dball("select cntphoto,cntdate from sec natural join _secm natural join pri where pri=? order by random() limit 200",$pri);
 
 my $i = -1;
 
 while ( ++$i < scalar @{ $arr } ) {
 
  $arr->[$i]->[0] < 1 and $arr->[$i]->[0] = 1;
  $arr->[$i]->[0] > $maxp and $arr->[$i]->[0] = $maxp; 
   
  $arr->[$i]->[0] = round ( ( log ( $arr->[$i]->[0] ) / log ( $maxp ) ) * 100 );
  
  $arr->[$i]->[1] < 1 and $arr->[$i]->[1] = 1;
  $arr->[$i]->[1] > $maxd and $arr->[$i]->[1] = $maxd; 
   
  $arr->[$i]->[1] = round ( ( log ( $arr->[$i]->[1] ) / log ( $maxd ) ) * 100 );

 }
  
 return $arr; 

}

sub _nats {

 my $self = shift; # not using lang, assuming nats to be language independent
 
 $self->dbcol("select sec_en from sec where pid=(select pid from pri where pri='nat')"); 
 
}

1;