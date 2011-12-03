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

package Catz::Model::Bulk;

use 5.12.0; use strict; use warnings;

use parent 'Catz::Model::Common';

sub _latest {

 my $self = shift;
 
 # find latest album having at least 10 photos with cat names
 
 return $self->dbone ( qq { 
  select aid from album where s=(
   select max(s) from album where aid in (
    select aid from inpos natural join sec natural join pri
    where pri='cat' group by aid having count(distinct n)>9
   )
  )
 } );
 
}

sub _folder {
 
 my ( $self, $folder ) = @_;
 
 # find aid
 
 my $aid = 
  $self->dbone( 'select aid from album where folder=?', $folder ) // 0;
 
 return $aid if $aid > 0;
 
 # second attempt with album number
 return 
  $self->dbone( 'select aid from album where folder=?', $folder . '1' );
 
}

sub _photolist {

 my ( $self, $aid ) = @_; 
 
 # get the photos by aid
 
 $self->dball( qq { 
  select s,photo.n,folder,file,sec_en 
  from 
   photo natural join album natural join inpos
   natural join sec natural join pri 
  where p=1 and pri='cat' and album.aid=? 
  order by photo.n asc
 }, $aid ); 
  
}

sub _qadt { $_[0]->dbone ( 'select dt from crun' ) }

sub _qadetail {

 my $self = shift; 

 my $classes = 
  $self->dball ( 'select class,cntitem,cntskip from cclass order by disp' );
  
 foreach my $class ( @$classes ) {
 
  $class->[3] = 
   $self->dball ( qq { 
    select pri,sec1,sec2 from citem where class=? order by sort 
   }, $class->[0] );

  foreach my $row ( @{ $class->[3] } ) { # add skipkeys
   
   $row->[3] = defined $row->[2] ? 
   join ';', ( $class->[0], @{ $row } ) :
   join ';', ( $class->[0], @{ $row }[0,1] ) 
     
  } 
 
 }
 
 
 return $classes;
  
}

1;