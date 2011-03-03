#
# The MIT License
# 
# Copyright (c) 2010-2011 Heikki Siltala
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
our @EXPORT = qw ( list_list list_links );

use Catz::DB;
use Catz::Util qw( expand_ts );

sub list_list {

 my ( $lang, $subject, $mode ) = @_;
 
 my $list;
 
 given ( $mode ) {
  
  when ( 'a2z' ) {
 
   $list = db_all( "select null,sec_$lang,count(distinct x),min(x) from snip
   natural join x where pri=? group by sec_$lang order by sec_$lang", $subject
   );
      
   my $last = 'XXXXXXXXX';
   
   foreach my $row ( @$list ) {
   
    my $first = substr( $row->[2], 0, 1 );

    $last eq $first or do {

     $row->[0] = $first;
     
     $last = $row->[0];   
   
   };
   
  }
  
 }
  
  when ( 'top' ) {
  
   $list = db_all( "select null,sec_$lang,count(distinct x),min(x) from snip
   natural join x where pri=? group by sec_$lang order by count(distinct x) desc", $subject
   );

   my $last = 999999999;
   my $ord = 0;

   foreach my $row ( @$list ) {
   
    $last == $row->[3] or do {
    
     $row->[0] = ++$ord . '.';
     
     $last = $row->[3]; 
    
    };
   
   }
  
  }
  
  default { die "unknown mode '$mode' in list creation" }
 
 }

 #die scalar @$list;
 
 return $list;
 
}

sub list_links {

  my ( $lang, $type ) = @_;
    
  my $links;
  
  given ( $type ) {
  
   when ( 'news' ) {
   
    $links = db_all("select dt,dt,title_$lang from metanews order by dt desc limit 10");
     
    do { $_->[1] = expand_ts ( substr ( $_->[0], 0, 8 ), $lang ) } foreach @$links;

   }
   
   when ( 'albums' ) {
   
    $links = db_all("select album.album,name_$lang,count(distinct x) from album natural join x group by album.album order by album desc limit 6");
   
   }

   when ( 'pris' ) {

    $links =  db_all("select pri,count(distinct sec_$lang) from snip where pri not in ('out','dt') group by pri order by pri_sort");
   
   }

   when ( 'ideas' ) {

    $links = db_all("select pri,sec_$lang,count(distinct x) from snip natural join x group by pri,sec_$lang order by random() limit 20");
  
   }

   default { die "unknown link list type '$type' requested" }

  }
  
  return $links; 

}

1;