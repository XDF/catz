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

package Catz::Model::Misc;

use parent 'Exporter';
our @EXPORT = qw ( album maxx news find sample search id2x x2id );

# a generic module to provide access various meta data stuff
# stored in the database

use Catz::Data::DB;
use Catz::Util::Time qw ( dtexpand );

sub maxx {

 my ( $db, $lang ) = @_;
 
 return $db->one ( 'select max(x) from _x' );
  
}

sub news {

  my ( $db, $lang, $pattern ) = @_;
  
 my $res = $db->all ( "select dt,null,title_$lang,text_$lang from mnews order by dt desc" );
   
 foreach my $row ( @$res ) {
 
  $row->[1] = dtexpand ( $row->[0], $lang );
   
 }
 
 return $res;
 
}

sub find {

 my ( $db, $lang, $pattern ) = @_;

 $pattern = '%' . $pattern . '%';

 return $db->all (qq{select pri,sec_$lang,count,x from ( select pri,sec_$lang,sort_$lang,count,x from _pri_sec_count where sec_$lang like ? order by rowid limit 15) order by sort_$lang},$pattern);

}

sub search {

 my ( $db, $lang, $search ) = @_;

 die 'locate_search not yet implemented';

}

sub id2x {

 my ( $db, $lang, $id ) = @_;
 
 return $db->one("select x from _x where id=?",$id);
 
}

sub x2id {

 my ( $db, $lang, $x ) = @_;
 
 return $db->one("select id from _x where x=?",$x);
 
}

1;

 