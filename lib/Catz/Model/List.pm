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

package Catz::Model::List;

use strict;
use warnings;

use feature qw( switch );

use parent 'Exporter';
our @EXPORT = qw ( list_general list_links );

use Catz::Data::DB;
use Catz::Util::Time qw( dtexpand );

sub list_general {

 my ( $db, $lang, $subject, $mode ) = @_;
 
 my $list;
 
 given ( $mode ) {
  
  when ( 'a2z' ) {
 
   $list = $db->all( qq{select  pri,sec,cntalbum,cntphoto,first,last from sec_$lang natural join 
    secm natural join pri where pri=? order by sec}, $subject
   );
       
  }
    
  when ( 'top' ) {
  
   $list = $db->all( qq{select pri,sec,cntalbum,cntphoto,first,last from sec_$lang natural join
    secm natural join pri where pri=? order by cntphoto desc }, $subject
   );
 
  }
  
  default { die "unknown mode '$mode' in list creation" }
 
 }

 #die scalar @$list;
 
 return $list;
 
}

sub list_links {

  my ( $db, $lang, $type ) = @_;
    
  my $links;
  
  given ( $type ) {
  
   when ( 'new' ) {
   
    $links = $db->all("select dt,dt,title_$lang from mnews order by dt desc limit 6");
     
    do { $_->[1] = dtexpand ( substr ( $_->[0], 0, 8 ), $lang ) } foreach @$links;

   }
   
   when ( 'album' ) {
   
    # first fetch the latest albums
    my $albums = $db->all("select aid,folder from album order by folder desc limit 5");
    
    my @res = ();
    
    foreach my $row ( @{ $albums } ) {
    
     my $name = $db->one("select sec from inalbum natural join sec_$lang natural join pri where pri='name' and aid=?",$row->[0]);
     
     my $n = $db->one('select max(n) from photo where aid=?', $row->[0] );
     
     push @res, ( [ $row->[1], $name, $n ] );
    
    
    }
   
    $links = \@res;
   
   }

   when ( 'pri' ) {

    $links =  $db->all("select pri,cnt from pri natural join prim where pri<>'text' order by disp");
   
   }

   default { die "unknown link list type '$type' requested" }

  }
  
  return $links; 

}

1;