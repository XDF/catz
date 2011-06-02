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
use Catz::Util::Time qw ( dt dtexpand );

my $matrix = list_matrix;

sub _full {

 my ( $self, $pri, $mode ) = @_; my $lang = $self->{lang};
 
 exists $matrix->{$pri} or return [ 0, undef, undef ];  
       
 my $cols = "pri,sec,cntalbum,cntphoto,first,last,null";
 
 my $cols_first = "pri,sec,cntalbum,cntphoto,substr(first,1,8)||replace(substr(first,9,6),'','000000')),last,null";  
 
 given ( $mode ) {
 
  when ( 'a2z' ) {
    
   my $res = $self->dball( qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by upper(sort)}, $pri );
   
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
  
  when ( 'date' ) {
  
   # special ordering where missing HHMMSS is assumed to be 000000 so is the first photo on that date  
   my $res = $self->dball( qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by  substr(first,1,8)||replace(substr(first,9,6),'','000000') desc}, $pri );
   
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
    
   my $res = $self->dball( qq{select $cols from sec_$lang natural join _secm natural join pri where pri=? order by cntphoto desc, cntalbum desc, sort asc}, $pri );
       
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
  
  when ( 'nat' ) {
  
   $pri ne 'breeder' and return [ 0, undef, undef ];
   
   my $res = $self->dball( qq{select $cols,nat,nat_$lang from sec_$lang natural join _secm natural join pri inner join mbreeder on (sec=breeder) natural join mnat where pri=? order by nat_$lang,sort}, $pri );
   
   my @idx = (); my @sets = (); my @set = (); my $prev = ''; my $i = 1;
   
   foreach my $row ( @$res ) {
   
    $row->[6] = $i++;
    
    if ( $prev ne $row->[8] ) {
    
     push @idx, $row->[8];
     
     scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
     
     @set = ();
     
     push @set, $row;
     
     $prev = $row->[8];
    
    } else { push @set, $row }
   
   }
     
   scalar @set > 0 and push @sets, [ $prev, [ @set ] ];
   
   return [ scalar @$res, \@idx, \@sets ];
        
  } 
 
  default { return [ 0, undef, undef ]; } # unknown mode
 
 }
 
}

sub _album {

 my $self = shift; my $lang = $self->{lang};

 my $res;

 my $albums = $self->dball('select aid,folder from album order by s desc limit 8');
          
 my @coll = ();
    
 foreach my $row ( @{ $albums } ) {
    
  my $name = $self->dbone("select sec from inalbum natural join sec_$lang natural join pri where pri='album' and aid=?",$row->[0]);
     
  my $n = $self->dbone('select max(n) from photo where aid=?', $row->[0] );
     
  push @coll, ( [ $row->[1], $name, $n ] );
    
 }
    
 \@coll;

}

sub _pris { 

 my $self = shift; my $lang = $self->{lang};
 
 # exclude photo texts and technical folder names
 my $res = $self->dball("select pri,cntpri from pri natural join _prim where pri not in ('text','folder') order by disp");
 
 return $res; 

}          

sub _find {

 my ( $self, $pattern, $count ) = @_; my $lang = $self->{lang};
 
 $pattern =~ s/[^a-zA-Z0-9åöäÅÖÄ]/_/;
 
 $pattern = '%' . $pattern . '%';
 
 $self->dball(qq{select pri,sec,cntphoto from sec_$lang natural join _secm natural join pri where sid in (select sid from _find_$lang where sec like ? collate nocase order by rowid limit $count) order by sort,cntphoto},$pattern);

}

sub _lastshow {

 my $self = shift; my $lang = $self->{lang};
 
 # find latest gallery having at least 10 photos with cat names
 
 my $latest = $self->dbone("select aid from album where folder=(select max(folder) from album where aid in ( select aid from inpos natural join sec natural join pri where pri='cat' group by aid having count(distinct n)>9 ))");
 
 # the get the photos
 
 $self->dball("select s,photo.n,folder,file,sec_en from photo natural join album natural join inpos natural join sec natural join pri where p=1 and pri='cat' and album.aid=? order by photo.n asc",$latest); 
  
}

sub _verify  {

 my ( $self, $folder ) = @_;
 
 $self->dbone('select n from album where folder=?', $folder );

}

1;