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

use 5.12.0;
use strict;
use warnings;

#
# Notice: this module includes heavy code copy-pasting and
# this should be considered a bad example of Perl programming!
#

use parent 'Catz::Model::Common';

use Const::Fast;

use Catz::Data::List;

use Catz::Util::String qw ( lcc );
use Catz::Util::Time qw ( dt dtexpand );

const my $MATRIX => list_matrix;

sub _full {

 my ( $self, $pri, $mode ) = @_;
 my $lang = $self->{ lang };

 exists $MATRIX->{ $pri } or return [ 0, undef, undef ];

 my $cols = "pri,sec,cntdate,cntphoto,first,last,null";

 my $cols_first =
  "pri,sec,cntdate,cntphoto,substr(first,1,8)||replace(substr(first,9,6),'','000000')),last,null";

 given ( $mode ) {

  when ( 'a2z' ) {

   my $res = $self->dball (
    qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by sort collate nocase},
    $pri
   );

   my @idx  = ();
   my @sets = ();
   my @set  = ();
   my $prev = '';
   my $i    = 1;

   foreach my $row ( @$res ) {

    $row->[ 6 ] = $i++;

    my $first = uc ( substr ( $row->[ 1 ], 0, 1 ) );

    if ( $prev ne $first ) {

     push @idx, $first;

     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

     @set = ();

     push @set, $row;

     $prev = $first;

    }
    else { push @set, $row }

   } ## end foreach my $row ( @$res )

   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

   return [ scalar @$res, \@idx, \@sets ];

  } ## end when ( 'a2z' )

  when ( 'cate' ) {

   # special ordering for breeds, added 2011-10-15

   $pri eq 'breed' or die "internal error: unable to list '$pri' by category";

   my $sum  = 0;
   my @idx  = ();
   my @sets = ();

   my $cates =
    $self->dball ( "select cate,cate_$lang from mcate order by cate" );

   foreach my $cate ( @$cates ) {

    my $sub = $self->dball (
     qq { 
     select $cols from sec_$lang natural join _secm 
     natural join pri where pri='breed' and sec in (
      select breed from mbreed where cate=$cate->[0]
     ) order by sort asc 
    }
    );

    my $n = scalar @$sub;

    if ( $n > 0 ) {

     $sum += $n;

     push @idx, $cate->[ 1 ];

     push @sets, [ $cate->[ 1 ], $sub ];

    }

   } ## end foreach my $cate ( @$cates )

   return [ $sum, \@idx, \@sets ];

  } ## end when ( 'cate' )

  when ( 'cron' ) {

# special ordering where missing HHMMSS is assumed to be 000000 so is the first photo on that date
   my $res = $self->dball (
    qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by substr(first,1,8)||replace(substr(first,9,6),'','000000') desc},
    $pri
   );

   my @idx  = ();
   my @sets = ();
   my @set  = ();
   my $prev = '';
   my $i    = 1;

   foreach my $row ( @$res ) {

    $row->[ 6 ] = $i++;

    my $first = substr ( $row->[ 4 ], 0, 4 );

    if ( $prev ne $first ) {

     push @idx, $first;

     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

     @set = ();

     push @set, $row;

     $prev = $first;

    }
    else { push @set, $row }

   } ## end foreach my $row ( @$res )

   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

   return [ scalar @$res, \@idx, \@sets ];

  } ## end when ( 'cron' )

  when ( 'first' ) {

# special ordering where missing HHMMSS is assumed to be 000000 so is the first photo on that date
   my $res = $self->dball (
    qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by substr(first,1,8)||replace(substr(first,9,6),'','000000'),sort},
    $pri
   );

   my @idx  = ();
   my @sets = ();
   my @set  = ();
   my $prev = '';
   my $i    = 1;

   foreach my $row ( @$res ) {

    $row->[ 6 ] = $i++;

    my $first = substr ( $row->[ 4 ], 0, 4 );

    if ( $prev ne $first ) {

     push @idx, $first;

     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

     @set = ();

     push @set, $row;

     $prev = $first;

    }
    else { push @set, $row }

   } ## end foreach my $row ( @$res )

   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

   return [ scalar @$res, \@idx, \@sets ];

  } ## end when ( 'first' )

  when ( 'top' ) {

   my $res = $self->dball (
    qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by cntphoto desc, cntdate desc, sort asc},
    $pri
   );

   my @idx  = ();
   my @sets = ();
   my @set  = ();
   my $prev = '';
   my $i    = 0;

   my @break = qw ( 1 20 50 100 200 500 1000 2000 5000 );

   foreach my $row ( @$res ) {

    $row->[ 6 ] = ++$i;

    if ( $break[ 0 ] and $i == $break[ 0 ] ) {

     shift @break;

     push @idx, $i;

     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

     @set = ();

     push @set, $row;

     $prev = $i;

    }
    else { push @set, $row }

   } ## end foreach my $row ( @$res )

   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

   return [ scalar @$res, \@idx, \@sets ];

  } ## end when ( 'top' )

  default { return [ 0, undef, undef ]; }    # unknown mode

 } ## end given

} ## end sub _full

sub _folder {

 my ( $self, $n ) = @_;
 my $lang = $self->{ lang };

 return $self->dball (
  qq {
  select folder,max(n) from album natural join photo 
  group by folder order by s desc limit $n
 }
 );

}

sub _pris {

 my $self = shift;
 my $lang = $self->{ lang };

 # exclude photo texts and technical folder names
 my $res = $self->dball (
  "select pri,cntpri from pri natural join _prim where pri not in ('text','folder') order by disp"
 );

 return $res;

}

sub _find {

 my ( $self, $pattern, $limit ) = @_;
 my $lang = $self->{ lang };

 # escape like wildcards to prevent them going thru
 $pattern =~ s|\\|\\\\|;
 $pattern =~ s|\_|\\_|;
 $pattern =~ s|\%|\\%|;

 $pattern = '%' . $pattern . '%';

 $self->dball (
  qq { 
  select pri,sec,cntphoto,sid from (
   select p.pri,p.disp,s.sec,f.sid,s.sort,m.cntphoto 
   from pri p,sec_$lang s,_secm m,_find_$lang f 
   where 
    p.pid=s.pid and s.sid=m.sid and 
    s.sid=abs(f.sid) and f.sec like ? escape '\\' 
   order by 
    f.rowid limit $limit
  ) order by disp,lower(sort),cntphoto
 }, $pattern
 );

} ## end sub _find

sub _prims {

 my $self = shift;

 $self->dball (
  qq { 
  select pri,cntpri from pri natural join _prim 
  where pri not in ('text','folder') order by disp 
  }
 );

}

sub _secs {

 my $self = shift;
 my $lang = $self->{ lang };

 $self->dball (
  qq { 
  select pri,sec
  from sec_$lang natural join pri natural join _prim natural join _secm
  where pri not in ('text','album') and 
  cntdate > 0 and cntphoto > 0 and cntpri> 0
 }
 );

}

sub _photos {

 my $self = shift;

 return $self->dball ( qq {
  select x,s,n,dt 
  from album natural join photo inner join dna on (folder=item) 
  where class='album' order by x 
 } );

}

sub _change {

 my ( $self, $obj ) = @_;
 
 given ( $obj ) {
 
  when ( [ 'album', 'folder', 'meta' ] ) {
  
   $obj eq 'meta' and $obj = 'file';
  
   return $self->dbone ( 'select max(dt) from dna where class=?', $obj );
    
  }

  when ( 'quality' ) {

   return $self->dbone ( 'select max(dt) from crun' ); 
   
  }
    
  default {

   return $self->dbone ( 'select max(dt) from dna where item=?', $obj ); 
   
  }
 
 }

}

1;
