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

use 5.10.0; use strict; use warnings;

use parent 'Catz::Model::Common';

use List::MoreUtils qw ( any );

use Catz::Data::List qw ( list_matrix );
use Catz::Util::String qw ( lcc );
use Catz::Util::Time qw ( dt dtexpand );

my $matrix = list_matrix;

sub _full {

 my ( $self, $pri, $mode ) = @_; my $lang = $self->{lang};
 
 exists $matrix->{$pri} or return [ 0, undef, undef ];
        
 my $cols = "pri,sec,cntdate,cntphoto,first,last,null";
 
 my $cols_first = "pri,sec,cntdate,cntphoto,substr(first,1,8)||replace(substr(first,9,6),'','000000')),last,null";  
 
 given ( $mode ) {
 
  when ( 'a2z' ) {
    
   my $res = $self->dball( qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by sort collate nocase}, $pri );
   
   my @idx = (); my @sets = (); my @set = (); my $prev = ''; my $i = 1;
   
   foreach my $row ( @$res ) {
   
    $row->[6] = $i++;
    
    my $first = uc(substr( $row->[1], 0, 1 )); 
    
    if ( $prev ne $first ) {
    
     push @idx, $first;
     
     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
     
     @set = ();
     
     push @set, $row;
 
     $prev = $first;
    
    } else { push @set, $row }
   
   }
     
   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
   
   return [ scalar @$res, \@idx, \@sets ];
        
  }
  
  when ( 'cron' ) {
  
   # special ordering where missing HHMMSS is assumed to be 000000 so is the first photo on that date  
   my $res = $self->dball( qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by substr(first,1,8)||replace(substr(first,9,6),'','000000') desc}, $pri );
   
   my @idx = (); my @sets = (); my @set = (); my $prev = ''; my $i = 1;
   
   foreach my $row ( @$res ) {
   
    $row->[6] = $i++;
    
    my $first = substr( $row->[4], 0, 4 ); 
    
    if ( $prev ne $first ) {
    
     push @idx, $first;
     
     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
     
     @set = ();
     
     push @set, $row;
 
     $prev = $first;
    
    } else { push @set, $row }
   
   }
     
   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
   
   return [ scalar @$res, \@idx, \@sets ];
        
  }  
    
  when ( 'first' ) {
  
   # special ordering where missing HHMMSS is assumed to be 000000 so is the first photo on that date
   my $res = $self->dball( qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by substr(first,1,8)||replace(substr(first,9,6),'','000000'),sort}, $pri );
   
   my @idx = (); my @sets = (); my @set = (); my $prev = ''; my $i = 1;
   
   foreach my $row ( @$res ) {
   
    $row->[6] = $i++;
    
    my $first = substr( $row->[4], 0, 4 ); 
    
    if ( $prev ne $first ) {
    
     push @idx, $first;
     
     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
     
     @set = ();
     
     push @set, $row;
 
     $prev = $first;
    
    } else { push @set, $row }
   
   }
     
   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
   
   return [ scalar @$res, \@idx, \@sets ];  
  
  
  }
  
  when ( 'top' ) {
    
   my $res = $self->dball( qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by cntphoto desc, cntdate desc, sort asc}, $pri );
       
   my @idx = (); my @sets = (); my @set = (); my $prev = ''; my $i = 0;
   
   my @break = qw ( 1 20 50 100 200 500 1000 2000 5000 );
   
   foreach my $row ( @$res ) {

    $row->[6] = ++$i;
   
    if ( $break[0] and $i == $break[0] ) {
    
     shift @break;

     push @idx, $i;
     
     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];

     @set = ();
     
     push @set, $row;
     
     $prev = $i;
        
    } else { push @set, $row }
   
   }
     
   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
      
   return [ scalar @$res, \@idx, \@sets ];
  
  }
   
  default { return [ 0, undef, undef ]; } # unknown mode
 
 }
 
}

sub _folder {

 my ( $self, $n ) = @_; my $lang = $self->{lang};

 return $self->dball("select folder,max(n) from album natural join photo group by folder order by s desc limit $n");
              
}

sub _pris { 

 my $self = shift; my $lang = $self->{lang};
 
 # exclude photo texts and technical folder names
 my $res = $self->dball("select pri,cntpri from pri natural join _prim where pri not in ('text','folder') order by disp");
 
 return $res; 

}          

sub _find {

 my ( $self, $pattern, $limit ) = @_; my $lang = $self->{lang};
 
 # escape like wildcards to prevent them going thru
 $pattern =~ s|\_|\\_|; 
 $pattern =~ s|\%|\\%|;
 
 $pattern = '%' . $pattern . '%';
   
 $self->dball(qq{select pri,sec,cntphoto,sid from (select p.pri,s.sec,m.cntphoto,f.sid,s.sort from pri p,sec_fi s,_secm m,_find_$lang f where p.pid=s.pid and s.sid=m.sid and s.sid=abs(f.sid) and f.sec like ? escape '\\' order by f.rowid limit $limit) order by lower(sort),cntphoto},$pattern);

}

sub _prims {

 my $self = shift;
 
 return $self->dball("select pri,cntpri from pri natural join _prim where pri not in ('text','folder') order by disp");

}

1;